import { Router } from "express";
import { body, param, query } from "express-validator";
import { randomBytes } from "crypto";
import multer from "multer";
import path from "path";
import { authRequired } from "../middlewares/auth.js";
import { storageService } from "../services/storageService.js";
import {
  getPetFeed,
  createPet,
  myAdverts,
  updatePet,
  listPets,
  getPet,
  getPetTimeline,
  getPetHealthSummary,
  deletePet,
  uploadPetImage,
  uploadPetVideo,
} from "../controllers/petController.js";

const router = Router();

const _storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, storageService.uploadDir),
  filename: (_req, file, cb) => {
    const unique = Date.now() + "-" + randomBytes(8).toString("hex");
    cb(null, unique + path.extname(file.originalname || ""));
  },
});

const imageUpload = multer({
  storage: _storage,
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (file.mimetype.startsWith("image/")) cb(null, true);
    else cb(new Error("Sadece resim dosyaları yüklenebilir"));
  },
});

const videoUpload = multer({
  storage: _storage,
  limits: { fileSize: 50 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (file.mimetype.startsWith("video/")) cb(null, true);
    else cb(new Error("Sadece video dosyaları yüklenebilir"));
  },
});

// Public
router.get("/feed", authRequired(), getPetFeed);
router.get("/", listPets);
router.get("/me", authRequired(), [query("type").optional().isIn(["adoption", "mating"])], myAdverts);
router.get("/health-summary", authRequired(), getPetHealthSummary);
router.get("/:id/timeline", authRequired(), [param("id").isMongoId()], getPetTimeline);
router.get("/:id", [param("id").isMongoId()], getPet);

// Protected
router.post(
  "/",
  authRequired(),
  [
    body("name").notEmpty().withMessage("Isim gerekli"),
    body("species").isIn(["dog", "cat", "bird", "fish", "rodent", "other"]).withMessage("Gecersiz tur"),
    body("ageMonths").optional().isInt({ min: 0 }),
    body("advertType").optional().isIn(["adoption", "mating"]),
    body("location.coordinates").optional().isArray({ min: 2, max: 2 }).custom((coords) => {
      if (!Array.isArray(coords)) return true;
      const [lng, lat] = coords.map(Number);
      if (isNaN(lng) || isNaN(lat)) throw new Error("Koordinatlar sayı olmalı");
      if (lng < -180 || lng > 180) throw new Error("Boylam -180 ile 180 arasında olmalı");
      if (lat < -90 || lat > 90) throw new Error("Enlem -90 ile 90 arasında olmalı");
      return true;
    }),
  ],
  createPet
);

const locationCoordsValidator = body("location.coordinates").optional().isArray({ min: 2, max: 2 }).custom((coords) => {
  if (!Array.isArray(coords)) return true;
  const [lng, lat] = coords.map(Number);
  if (isNaN(lng) || isNaN(lat)) throw new Error("Koordinatlar sayı olmalı");
  if (lng < -180 || lng > 180) throw new Error("Boylam -180 ile 180 arasında olmalı");
  if (lat < -90 || lat > 90) throw new Error("Enlem -90 ile 90 arasında olmalı");
  return true;
});

router.put(
  "/:id",
  authRequired(),
  [
    param("id").isMongoId(),
    body("species").optional().isIn(["dog", "cat", "bird", "fish", "rodent", "other"]),
    body("ageMonths").optional().isInt({ min: 0 }),
    body("advertType").optional().isIn(["adoption", "mating"]),
    locationCoordsValidator,
  ],
  updatePet
);

router.patch(
  "/:id",
  authRequired(),
  [
    param("id").isMongoId(),
    body("species").optional().isIn(["dog", "cat", "bird", "fish", "rodent", "other"]),
    body("ageMonths").optional().isInt({ min: 0 }),
    body("advertType").optional().isIn(["adoption", "mating"]),
    locationCoordsValidator,
  ],
  updatePet
);

router.delete("/:id", authRequired(), [param("id").isMongoId()], deletePet);

router.post(
  "/:id/images",
  authRequired(),
  [param("id").isMongoId()],
  imageUpload.single("image"),
  uploadPetImage
);

router.post(
  "/:id/videos",
  authRequired(),
  [param("id").isMongoId()],
  videoUpload.single("video"),
  uploadPetVideo
);

// GET /api/pets/health-summary — Tüm petlerin sağlık özeti
import Pet from "../models/Pet.js";
import { sendOk, sendError } from "../utils/apiResponse.js";

router.get("/health-summary", authRequired(), async (req, res) => {
  try {
    const userId = req.user.sub || req.user._id || req.user.id;
    const [
      { default: VaccinationRecord },
      { default: Appointment },
    ] = await Promise.all([
      import("../models/VaccinationRecord.js"),
      import("../models/Appointment.js"),
    ]);

    const pets = await Pet.find({ ownerId: userId }).lean();
    const now = new Date();
    const in30Days = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
    const in7Days  = new Date(now.getTime() +  7 * 24 * 60 * 60 * 1000);

    const summary = await Promise.all(
      pets.map(async (pet) => {
        const [upcomingVaccinations, nextAppointment] = await Promise.all([
          VaccinationRecord.find({
            petId: pet._id,
            nextDueDate: { $gte: now, $lte: in30Days },
          }).sort({ nextDueDate: 1 }).lean(),
          Appointment.findOne({
            petId: pet._id,
            date: { $gte: now },
            status: { $in: ["pending", "confirmed"] },
          }).sort({ date: 1 }).lean(),
        ]);

        const alerts = [];
        for (const v of upcomingVaccinations) {
          const daysLeft = Math.ceil((new Date(v.nextDueDate) - now) / (1000 * 60 * 60 * 24));
          alerts.push({ type: "vaccination", label: v.vaccineName || "Aşı", daysLeft });
        }
        if (nextAppointment) {
          const daysLeft = Math.ceil((new Date(nextAppointment.date) - now) / (1000 * 60 * 60 * 24));
          alerts.push({ type: "appointment", label: "Veteriner randevusu", daysLeft });
        }

        // healthStatus: acil < 7 gün, dikkat < 30 gün, iyi
        let healthStatus = "iyi";
        if (alerts.some(a => a.daysLeft <= 7))  healthStatus = "acil";
        else if (alerts.length > 0)              healthStatus = "dikkat";

        return {
          petId: String(pet._id),
          petName: pet.name,
          photo: (pet.photos || [])[0] || null,
          species: pet.species,
          healthStatus,
          alerts,
          currentWeight: pet.currentWeight || null,
        };
      })
    );

    return sendOk(res, 200, { summary });
  } catch (err) {
    return sendError(res, 500, "Sağlık özeti alınamadı", "internal_error", err.message);
  }
});

// GET /api/pets/:id/health-card — Sağlık kartı (QR için veri)

router.get("/:id/health-card", authRequired(), [param("id").isMongoId()], async (req, res) => {
  try {
    const { default: HealthRecord } = await import("../models/HealthRecord.js");
    const pet = await Pet.findById(req.params.id).lean();
    if (!pet) return sendError(res, 404, "Pet bulunamadi", "not_found");

    // Yalnızca sahibi erişebilir
    if (String(pet.ownerId) !== String(req.user.sub)) {
      return sendError(res, 403, "Bu hayvanın sağlık kartına erişim yetkiniz yok", "forbidden");
    }

    const healthRecords = await HealthRecord.find({ petId: pet._id })
      .sort({ date: -1 })
      .limit(10)
      .lean();

    return sendOk(res, 200, {
      pet: {
        id: pet._id,
        name: pet.name,
        species: pet.species,
        breed: pet.breed,
        gender: pet.gender,
        birthDate: pet.birthDate,
        ageMonths: pet.ageMonths,
        photos: pet.photos || [],
      },
      healthRecords: healthRecords.map(r => ({
        id: r._id,
        type: r.type,
        title: r.title,
        date: r.date,
        notes: r.notes,
        weight: r.weight,
        medication: r.medication,
        nextDueDate: r.nextDueDate,
      })),
    });
  } catch (err) {
    return sendError(res, 500, "Sağlık kartı alınamadı", "internal_error", err.message);
  }
});

// PATCH /api/pets/:id/feeding — Beslenme takvimi + kilo güncelle
router.patch("/:id/feeding", authRequired(), [param("id").isMongoId()], async (req, res) => {
  try {
    const userId = req.user.sub || req.user._id || req.user.id;
    const Pet = (await import("../models/Pet.js")).default;
    const pet = await Pet.findById(req.params.id);
    if (!pet) return sendError(res, 404, "Pet bulunamadı", "not_found");
    if (String(pet.ownerId) !== String(userId))
      return sendError(res, 403, "Erişim reddedildi", "forbidden");

    const { feedingSchedule, currentWeight, targetWeight } = req.body;
    if (feedingSchedule !== undefined) pet.feedingSchedule = feedingSchedule;
    if (currentWeight !== undefined) pet.currentWeight = currentWeight;
    if (targetWeight !== undefined) pet.targetWeight = targetWeight;
    await pet.save();

    return sendOk(res, 200, { pet });
  } catch (err) {
    return sendError(res, 500, "Beslenme takvimi güncellenemedi", "internal_error", err.message);
  }
});

// GET /api/pets/:id/timeline — Pet aktivite geçmişi
router.get("/:id/timeline", authRequired(), [param("id").isMongoId()], async (req, res) => {
  try {
    const pet = await Pet.findById(req.params.id).lean();
    if (!pet) return sendError(res, 404, "Pet bulunamadi", "not_found");

    const petObjId = pet._id;

    const [
      { default: HealthRecord },
      { default: Appointment },
      { default: SitterBooking },
    ] = await Promise.all([
      import("../models/HealthRecord.js"),
      import("../models/Appointment.js"),
      import("../models/SitterBooking.js"),
    ]);

    const [healthRecords, appointments, bookings] = await Promise.all([
      HealthRecord.find({ petId: petObjId }).sort({ date: -1 }).limit(20).lean(),
      Appointment.find({ petId: petObjId }).sort({ dateTime: -1 }).limit(10).lean(),
      SitterBooking.find({ petId: petObjId }).sort({ startDate: -1 }).limit(10).lean(),
    ]);

    const timeline = [
      ...healthRecords.map(r => ({
        id: String(r._id),
        type: 'health',
        title: r.title || r.type || 'Sağlık kaydı',
        date: r.date || r.createdAt,
        notes: r.notes,
      })),
      ...appointments.map(a => ({
        id: String(a._id),
        type: 'appointment',
        title: a.notes || 'Veteriner randevusu',
        date: a.dateTime || a.date || a.createdAt,
        notes: a.notes,
      })),
      ...bookings.map(b => ({
        id: String(b._id),
        type: 'booking',
        title: 'Bakıcı rezervasyonu',
        date: b.startDate || b.createdAt,
        notes: null,
      })),
    ].sort((a, b) => new Date(b.date) - new Date(a.date));

    return sendOk(res, 200, { timeline });
  } catch (err) {
    return sendError(res, 500, "Zaman çizelgesi alınamadı", "internal_error", err.message);
  }
});

export default router;
