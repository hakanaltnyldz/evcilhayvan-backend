import { Router } from "express";
import path from "path";
import fs from "fs";
import multer from "multer";
import { body, param, validationResult } from "express-validator";
import { authRequired } from "../middlewares/auth.js";
import {
  createBooking, myBookings, incomingBookings, getBooking, updateBookingStatus,
} from "../controllers/sitterBookingController.js";
import { sendOk, sendError } from "../utils/apiResponse.js";
import WalkUpdate from "../models/WalkUpdate.js";
import CareReport from "../models/CareReport.js";
import SitterBooking from "../models/SitterBooking.js";
import {
  cancelTrackingGrace,
  computePayableAmount,
  markTrackingOffline,
  markTrackingOnline,
  scheduleTrackingGrace,
} from "../services/sitterTrackingService.js";

const router = Router();

function validateRequest(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return sendError(res, 400, "Dogrulama hatasi", "validation_error", errors.array());
  }
  return next();
}

// ─── Yürüyüş fotoğrafı upload için multer ────────────────────────────────────
const walkUploadDir = path.join(process.cwd(), "uploads", "walk");
if (!fs.existsSync(walkUploadDir)) fs.mkdirSync(walkUploadDir, { recursive: true });

const walkStorage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, walkUploadDir),
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase() || ".jpg";
    cb(null, `walk_${Date.now()}${ext}`);
  },
});
const walkUpload = multer({
  storage: walkStorage,
  fileFilter: (_req, file, cb) => {
    if (file.mimetype.startsWith("image/")) cb(null, true);
    else cb(new Error("Yalnızca resim dosyası yüklenebilir"));
  },
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
});

// ─── Mevcut route'lar ─────────────────────────────────────────────────────────
router.post(
  "/",
  authRequired(),
  [
    body("sitterId").isMongoId().withMessage("Gecersiz bakici ID"),
    body("petId").isMongoId().withMessage("Gecersiz pet ID"),
    body("serviceType")
      .isIn(["walking", "home_sitting", "boarding", "daycare", "grooming"])
      .withMessage("Gecersiz hizmet tipi"),
    body("startDate").isISO8601().withMessage("Gecersiz baslangic tarihi"),
    body("endDate").isISO8601().withMessage("Gecersiz bitis tarihi"),
    body("notes").optional().isString().isLength({ max: 500 }).withMessage("Not en fazla 500 karakter olabilir"),
  ],
  validateRequest,
  createBooking
);
router.get("/me", authRequired(), myBookings);
router.get("/incoming", authRequired(), incomingBookings);
router.get("/:id", authRequired(), [param("id").isMongoId()], getBooking);
router.patch(
  "/:id/status",
  authRequired(),
  [
    param("id").isMongoId().withMessage("Gecersiz rezervasyon ID"),
    body("status")
      .optional()
      .isIn(["accepted", "active", "rejected", "cancelled", "completed"])
      .withMessage("Gecersiz durum"),
    body("review.rating").optional().isInt({ min: 1, max: 5 }).withMessage("Puan 1 ile 5 arasinda olmali"),
    body("review.comment")
      .optional()
      .isString()
      .isLength({ max: 1000 })
      .withMessage("Yorum en fazla 1000 karakter olabilir"),
  ],
  validateRequest,
  updateBookingStatus
);

// ─── Walk Updates ─────────────────────────────────────────────────────────────

// POST /api/sitter-bookings/:id/updates — bakıcı konum/foto/not gönderir
router.post(
  "/:id/updates",
  authRequired(),
  [
    param("id").isMongoId().withMessage("Gecersiz rezervasyon ID"),
    body("type")
      .isIn(["location", "photo", "note", "arrived", "walk_started", "walk_ended"])
      .withMessage("Gecersiz guncelleme tipi"),
    body("coordinates")
      .optional()
      .isArray({ min: 2, max: 2 })
      .withMessage("Koordinatlar [lng, lat] formatinda olmali"),
    body("coordinates.*").optional().isFloat().withMessage("Koordinatlar sayi olmali"),
    body("photoUrl").optional().isString().isLength({ max: 500 }).withMessage("Fotograf yolu gecersiz"),
    body("message").optional().isString().isLength({ max: 300 }).withMessage("Mesaj en fazla 300 karakter olabilir"),
  ],
  validateRequest,
  async (req, res) => {
  try {
    const booking = await SitterBooking.findById(req.params.id);
    if (!booking) return sendError(res, 404, "Rezervasyon bulunamadı", "not_found");

    const userId = req.user.sub || req.user._id || req.user.id;
    if (String(booking.sitterUserId) !== String(userId))
      return sendError(res, 403, "Yalnızca bakıcı güncelleme gönderebilir", "forbidden");

    const { type, coordinates, photoUrl, message } = req.body;
    if (!type) return sendError(res, 400, "type alanı gerekli", "validation_error");

    const update = await WalkUpdate.create({
      bookingId: booking._id,
      sitterUserId: userId,
      type,
      coordinates: coordinates || undefined,
      photoUrl: photoUrl || undefined,
      message: message || undefined,
    });
    if (type === "location" && Array.isArray(coordinates) && coordinates.length === 2) {
      cancelTrackingGrace(booking._id);
      markTrackingOnline(booking, {
        now: new Date(),
        lng: Number(coordinates[0]),
        lat: Number(coordinates[1]),
      });
      await booking.save();
    }

    // Socket.io ile owner'a anlık bildirim
    const io = req.app.get("io");
    if (io) {
      io.to(`user:${booking.petOwnerId}`).emit("booking:update", {
        bookingId: booking._id,
        update: update.toJSON(),
      });
    }

    return sendOk(res, 201, { update });
  } catch (err) {
    return sendError(res, 500, "Güncelleme gönderilemedi", "internal_error", err.message);
  }
});

// GET /api/sitter-bookings/:id/updates — tüm güncellemeleri listele
router.get("/:id/updates", authRequired(), async (req, res) => {
  try {
    const booking = await SitterBooking.findById(req.params.id);
    if (!booking) return sendError(res, 404, "Rezervasyon bulunamadı", "not_found");

    const userId = req.user.sub || req.user._id || req.user.id;
    const isOwner = String(booking.petOwnerId) === String(userId);
    const isSitter = String(booking.sitterUserId) === String(userId);
    if (!isOwner && !isSitter) return sendError(res, 403, "Erişim reddedildi", "forbidden");

    const updates = await WalkUpdate.find({ bookingId: booking._id }).sort({ timestamp: 1 });
    return sendOk(res, 200, { updates });
  } catch (err) {
    return sendError(res, 500, "Güncellemeler alınamadı", "internal_error", err.message);
  }
});

// POST /api/sitter-bookings/:id/upload-photo — yürüyüş fotoğrafı yükle
router.post("/:id/upload-photo", authRequired(), (req, res, next) => {
  walkUpload.single("photo")(req, res, (err) => {
    if (err) return sendError(res, 400, err.message, "upload_error");
    next();
  });
}, async (req, res) => {
  try {
    if (!req.file) return sendError(res, 400, "Dosya bulunamadı", "validation_error");
    const photoUrl = `/uploads/walk/${req.file.filename}`;
    return sendOk(res, 200, { photoUrl });
  } catch (err) {
    return sendError(res, 500, "Fotoğraf yüklenemedi", "internal_error", err.message);
  }
});

// ─── Care Reports ─────────────────────────────────────────────────────────────

// POST /api/sitter-bookings/:id/care-reports — bakıcı günlük rapor ekler
router.post(
  "/:id/care-reports",
  authRequired(),
  [
    param("id").isMongoId().withMessage("Gecersiz rezervasyon ID"),
    body("day").optional().isInt({ min: 1 }).withMessage("Gun en az 1 olmali"),
    body("mood").optional().isIn(["great", "good", "okay", "tired"]).withMessage("Gecersiz ruh hali"),
    body("photos").optional().isArray().withMessage("Fotograflar dizi olmali"),
    body("photos.*").optional().isString().isLength({ max: 500 }).withMessage("Fotograf yolu gecersiz"),
    body("notes").optional().isString().isLength({ max: 500 }).withMessage("Not en fazla 500 karakter olabilir"),
    body("activities").optional().isArray().withMessage("Aktiviteler dizi olmali"),
    body("activities.*")
      .optional()
      .isIn(["walk", "play", "grooming", "vet_visit", "bath", "training"])
      .withMessage("Gecersiz aktivite"),
    body("foodEaten").optional().isBoolean().withMessage("foodEaten boolean olmali"),
  ],
  validateRequest,
  async (req, res) => {
  try {
    const booking = await SitterBooking.findById(req.params.id);
    if (!booking) return sendError(res, 404, "Rezervasyon bulunamadı", "not_found");

    const userId = req.user.sub || req.user._id || req.user.id;
    if (String(booking.sitterUserId) !== String(userId))
      return sendError(res, 403, "Yalnızca bakıcı rapor ekleyebilir", "forbidden");

    const { day, mood, photos, notes, activities, foodEaten } = req.body;
    const report = await CareReport.create({
      bookingId: booking._id,
      sitterUserId: userId,
      day: day || 1,
      mood: mood || "good",
      photos: photos || [],
      notes,
      activities: activities || [],
      foodEaten: foodEaten !== false,
    });

    // Owner'a bildirim
    const io = req.app.get("io");
    if (io) {
      io.to(`user:${booking.petOwnerId}`).emit("booking:care_report", {
        bookingId: booking._id,
        report: report.toJSON(),
      });
    }

    return sendOk(res, 201, { report });
  } catch (err) {
    return sendError(res, 500, "Rapor eklenemedi", "internal_error", err.message);
  }
});

// GET /api/sitter-bookings/:id/care-reports — raporları listele
router.get("/:id/care-reports", authRequired(), async (req, res) => {
  try {
    const booking = await SitterBooking.findById(req.params.id);
    if (!booking) return sendError(res, 404, "Rezervasyon bulunamadı", "not_found");

    const userId = req.user.sub || req.user._id || req.user.id;
    const isOwner = String(booking.petOwnerId) === String(userId);
    const isSitter = String(booking.sitterUserId) === String(userId);
    if (!isOwner && !isSitter) return sendError(res, 403, "Erişim reddedildi", "forbidden");

    const reports = await CareReport.find({ bookingId: booking._id }).sort({ day: 1 });
    return sendOk(res, 200, { reports });
  } catch (err) {
    return sendError(res, 500, "Raporlar alınamadı", "internal_error", err.message);
  }
});

// POST /api/sitter-bookings/:id/upload-care-photo — bakım raporu fotoğrafı yükle
router.post("/:id/upload-care-photo", authRequired(), (req, res, next) => {
  walkUpload.single("photo")(req, res, (err) => {
    if (err) return sendError(res, 400, err.message, "upload_error");
    next();
  });
}, async (req, res) => {
  try {
    if (!req.file) return sendError(res, 400, "Dosya bulunamadı", "validation_error");
    const photoUrl = `/uploads/walk/${req.file.filename}`;
    return sendOk(res, 200, { photoUrl });
  } catch (err) {
    return sendError(res, 500, "Fotoğraf yüklenemedi", "internal_error", err.message);
  }
});

// ─── Walk Photos (Fotoğraf Günlüğü) ─────────────────────────────────────────

// POST /api/sitter-bookings/:id/walk-photos — bakıcı gezinti fotoğrafı paylaşır
router.post("/:id/walk-photos", authRequired(), (req, res, next) => {
  walkUpload.single("photo")(req, res, (err) => {
    if (err) return sendError(res, 400, err.message, "upload_error");
    next();
  });
}, async (req, res) => {
  try {
    if (!req.file) return sendError(res, 400, "Dosya bulunamadı", "validation_error");

    const booking = await SitterBooking.findById(req.params.id);
    if (!booking) return sendError(res, 404, "Rezervasyon bulunamadı", "not_found");

    const userId = req.user.sub || req.user._id || req.user.id;
    if (String(booking.sitterUserId) !== String(userId)) {
      return sendError(res, 403, "Yalnızca bakıcı fotoğraf paylaşabilir", "forbidden");
    }
    if (!["active", "completed"].includes(booking.status)) {
      return sendError(res, 400, "Yalnızca aktif rezervasyona fotoğraf eklenebilir", "invalid_status");
    }

    const photoUrl = `/uploads/walk/${req.file.filename}`;
    const caption = req.body.caption || "";
    booking.walkPhotos = booking.walkPhotos || [];
    booking.walkPhotos.push({ url: photoUrl, caption, takenAt: new Date() });
    await booking.save();

    // Pet sahibine socket bildirimi
    const io = req.app.get("io");
    if (io) {
      io.to(`user:${String(booking.petOwnerId)}`).emit("sitter:walk_photo", {
        bookingId: booking._id,
        photoUrl,
        caption,
        takenAt: new Date(),
      });
    }

    // Pet sahibine FCM push
    const { sendPush } = await import("../utils/fcm.js");
    sendPush([String(booking.petOwnerId)], {
      title: "Yeni Fotoğraf",
      body: "Bakıcınız gezintiden yeni bir fotoğraf paylaştı 📷",
      data: { type: "walk_photo", bookingId: String(booking._id) },
    }).catch(() => {});

    return sendOk(res, 201, {
      photo: { url: photoUrl, caption, takenAt: new Date() },
      totalPhotos: booking.walkPhotos.length,
    });
  } catch (err) {
    return sendError(res, 500, "Fotoğraf yüklenemedi", "internal_error", err.message);
  }
});

// GET /api/sitter-bookings/:id/walk-photos — fotoğraf listesi
router.get("/:id/walk-photos", authRequired(), async (req, res) => {
  try {
    const booking = await SitterBooking.findById(req.params.id);
    if (!booking) return sendError(res, 404, "Rezervasyon bulunamadı", "not_found");

    const userId = req.user.sub || req.user._id || req.user.id;
    const isOwner = String(booking.petOwnerId) === String(userId);
    const isSitter = String(booking.sitterUserId) === String(userId);
    if (!isOwner && !isSitter) return sendError(res, 403, "Erişim reddedildi", "forbidden");

    return sendOk(res, 200, { photos: booking.walkPhotos || [] });
  } catch (err) {
    return sendError(res, 500, "Fotoğraflar alınamadı", "internal_error", err.message);
  }
});

// ─── Live Tracking ────────────────────────────────────────────────────────────

// PATCH /api/sitter-bookings/:id/tracking — konum takibini başlat/durdur
router.patch("/:id/tracking", authRequired(), async (req, res) => {
  try {
    const booking = await SitterBooking.findById(req.params.id);
    if (!booking) return sendError(res, 404, "Rezervasyon bulunamadı", "not_found");

    const userId = req.user.sub || req.user._id || req.user.id;
    if (String(booking.sitterUserId) !== String(userId)) {
      return sendError(res, 403, "Yalnızca bakıcı konumu paylaşabilir", "forbidden");
    }

    const active = req.body.active === true || req.body.active === "true";
    const reason = req.body.reason?.toString().trim() || "tracking_manually_disabled";
    const io = req.app.get("io");

    if (active) {
      cancelTrackingGrace(booking._id);
      markTrackingOnline(booking, { now: new Date() });
    } else {
      markTrackingOffline(booking, {
        now: new Date(),
        reason,
      });
      if (booking.status === "active") {
        scheduleTrackingGrace({ io, bookingId: booking._id });
      }
    }

    booking.earnings = booking.earnings || {};
    booking.earnings.payableAmount = computePayableAmount(booking);
    await booking.save();

    if (io) {
      const event = active ? "sitter:tracking_started" : "sitter:tracking_ended";
      io.to(`user:${String(booking.petOwnerId)}`).emit(event, {
        bookingId: booking._id,
        liveTracking: booking.liveTracking,
        earningsStatus: booking.earnings?.status || "pending",
        payableAmount: booking.earnings?.payableAmount ?? booking.totalPrice,
      });
    }

    return sendOk(res, 200, {
      liveTracking: booking.liveTracking,
      earnings: booking.earnings,
    });
  } catch (err) {
    return sendError(res, 500, "Takip durumu güncellenemedi", "internal_error", err.message);
  }
});

export default router;
