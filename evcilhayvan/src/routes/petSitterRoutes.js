import { Router } from "express";
import path from "path";
import fs from "fs";
import multer from "multer";
import { body } from "express-validator";
import { authRequired } from "../middlewares/auth.js";
import {
  createSitter, listSitters, mySitterProfile, getSitter, updateSitter, toggleAvailability,
} from "../controllers/petSitterController.js";
import { sendOk, sendError } from "../utils/apiResponse.js";
import PetSitter from "../models/PetSitter.js";

const router = Router();

// ─── Portfolio fotoğraf upload multer ────────────────────────────────────────
const sitterUploadDir = path.join(process.cwd(), "uploads", "sitters");
if (!fs.existsSync(sitterUploadDir)) fs.mkdirSync(sitterUploadDir, { recursive: true });

const sitterStorage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, sitterUploadDir),
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase() || ".jpg";
    cb(null, `sitter_${Date.now()}${ext}`);
  },
});
const sitterUpload = multer({
  storage: sitterStorage,
  fileFilter: (_req, file, cb) => {
    if (file.mimetype.startsWith("image/")) cb(null, true);
    else cb(new Error("Yalnızca resim dosyası yüklenebilir"));
  },
  limits: { fileSize: 10 * 1024 * 1024 },
});

// ─── Mevcut route'lar ─────────────────────────────────────────────────────────
router.get("/", listSitters);
router.post(
  "/",
  authRequired(),
  [
    body("displayName").notEmpty().withMessage("Gorunen ad gerekli"),
    body("services").isArray({ min: 1 }).withMessage("En az bir hizmet gerekli"),
  ],
  createSitter
);
router.get("/me", authRequired(), mySitterProfile);
router.get("/:id", getSitter);
router.put("/:id", authRequired(), updateSitter);
router.patch("/:id/availability", authRequired(), toggleAvailability);

// ─── Blocked Dates ────────────────────────────────────────────────────────────

// PATCH /api/pet-sitters/:id/blocked-dates
// Body: { add: ['2026-04-15', ...], remove: ['2026-04-10', ...] }
router.patch("/:id/blocked-dates", authRequired(), async (req, res) => {
  try {
    const sitter = await PetSitter.findById(req.params.id);
    if (!sitter) return sendError(res, 404, "Bakıcı bulunamadı", "not_found");

    const userId = req.user.sub || req.user._id || req.user.id;
    if (String(sitter.userId) !== String(userId))
      return sendError(res, 403, "Yalnızca kendi profilinizi düzenleyebilirsiniz", "forbidden");

    const { add = [], remove = [] } = req.body;

    // Mevcut blocked dates'i normalize et (sadece gün bazında karşılaştır)
    const existing = (sitter.blockedDates || []).map(d => new Date(d).toISOString().substring(0, 10));

    // Ekle
    const toAdd = add
      .map(d => new Date(d).toISOString().substring(0, 10))
      .filter(d => !existing.includes(d));

    // Çıkar
    const toRemove = remove.map(d => new Date(d).toISOString().substring(0, 10));

    const updated = [...existing, ...toAdd]
      .filter(d => !toRemove.includes(d))
      .map(d => new Date(d));

    sitter.blockedDates = updated;
    await sitter.save();

    return sendOk(res, 200, {
      blockedDates: sitter.blockedDates.map(d => d.toISOString().substring(0, 10)),
    });
  } catch (err) {
    return sendError(res, 500, "Güncelleme başarısız", "internal_error", err.message);
  }
});

// ─── Reviews ─────────────────────────────────────────────────────────────────

// POST /api/pet-sitters/:id/reviews — bakıcıya yorum ekle (tamamlanmış booking gerekir)
router.post("/:id/reviews", authRequired(), async (req, res) => {
  try {
    const { rating, comment } = req.body;
    if (!rating || rating < 1 || rating > 5) {
      return sendError(res, 400, "Geçerli bir puan girin (1-5)", "validation_error");
    }

    const userId = req.user.sub || req.user._id || req.user.id;
    const { default: SitterBooking } = await import("../models/SitterBooking.js");

    // Kullanıcının bu bakıcıyla tamamlanmış, henüz yorumsuz bookingini bul
    const booking = await SitterBooking.findOne({
      sitterId: req.params.id,
      petOwnerId: userId,
      status: "completed",
      ownerReview: { $exists: false },
    });

    if (!booking) {
      return sendError(res, 404, "Yorum yapılabilecek tamamlanmış bir rezervasyon bulunamadı", "not_found");
    }

    booking.ownerReview = {
      rating: Math.min(5, Math.max(1, Number(rating))),
      comment: comment || "",
    };
    await booking.save();

    // Bakıcı ortalama puanını güncelle
    const allReviewed = await SitterBooking.find({
      sitterId: req.params.id,
      status: "completed",
      ownerReview: { $exists: true },
    }).lean();
    const total = allReviewed.reduce((s, b) => s + (b.ownerReview?.rating || 0), 0);
    const avg = Number((total / allReviewed.length).toFixed(1));
    await PetSitter.findByIdAndUpdate(req.params.id, { rating: avg, reviewCount: allReviewed.length });

    return sendOk(res, 201, { message: "Yorum kaydedildi", rating: avg, reviewCount: allReviewed.length });
  } catch (err) {
    return sendError(res, 500, "Yorum kaydedilemedi", "internal_error", err.message);
  }
});

// ─── Portfolio Fotoğraf Upload ────────────────────────────────────────────────

// POST /api/pet-sitters/:id/photos — çoklu fotoğraf ekle
router.post("/:id/photos", authRequired(), (req, res, next) => {
  sitterUpload.array("photos", 8)(req, res, (err) => {
    if (err) return sendError(res, 400, err.message, "upload_error");
    next();
  });
}, async (req, res) => {
  try {
    const sitter = await PetSitter.findById(req.params.id);
    if (!sitter) return sendError(res, 404, "Bakıcı bulunamadı", "not_found");

    const userId = req.user.sub || req.user._id || req.user.id;
    if (String(sitter.userId) !== String(userId))
      return sendError(res, 403, "Yalnızca kendi profilinizi düzenleyebilirsiniz", "forbidden");

    if (!req.files || req.files.length === 0)
      return sendError(res, 400, "Dosya bulunamadı", "validation_error");

    const newUrls = req.files.map(f => `/uploads/sitters/${f.filename}`);
    sitter.photos = [...(sitter.photos || []), ...newUrls].slice(0, 12); // Maks 12 fotoğraf
    await sitter.save();

    return sendOk(res, 200, { photos: sitter.photos });
  } catch (err) {
    return sendError(res, 500, "Fotoğraflar yüklenemedi", "internal_error", err.message);
  }
});

// DELETE /api/pet-sitters/:id/photos — fotoğraf sil
router.delete("/:id/photos", authRequired(), async (req, res) => {
  try {
    const sitter = await PetSitter.findById(req.params.id);
    if (!sitter) return sendError(res, 404, "Bakıcı bulunamadı", "not_found");

    const userId = req.user.sub || req.user._id || req.user.id;
    if (String(sitter.userId) !== String(userId))
      return sendError(res, 403, "Yalnızca kendi profilinizi düzenleyebilirsiniz", "forbidden");

    const { photoUrl } = req.body;
    if (!photoUrl) return sendError(res, 400, "photoUrl gerekli", "validation_error");

    sitter.photos = (sitter.photos || []).filter(p => p !== photoUrl);
    await sitter.save();

    return sendOk(res, 200, { photos: sitter.photos });
  } catch (err) {
    return sendError(res, 500, "Fotoğraf silinemedi", "internal_error", err.message);
  }
});

export default router;
