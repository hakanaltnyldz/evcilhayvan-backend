import { Router } from "express";
import path from "path";
import fs from "fs";
import multer from "multer";
import { param } from "express-validator";
import { authRequired } from "../middlewares/auth.js";
import {
  createBooking, myBookings, incomingBookings, getBooking, updateBookingStatus,
} from "../controllers/sitterBookingController.js";
import { sendOk, sendError } from "../utils/apiResponse.js";
import WalkUpdate from "../models/WalkUpdate.js";
import CareReport from "../models/CareReport.js";
import SitterBooking from "../models/SitterBooking.js";

const router = Router();

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
router.post("/", authRequired(), createBooking);
router.get("/me", authRequired(), myBookings);
router.get("/incoming", authRequired(), incomingBookings);
router.get("/:id", authRequired(), [param("id").isMongoId()], getBooking);
router.patch("/:id/status", authRequired(), [param("id").isMongoId()], updateBookingStatus);

// ─── Walk Updates ─────────────────────────────────────────────────────────────

// POST /api/sitter-bookings/:id/updates — bakıcı konum/foto/not gönderir
router.post("/:id/updates", authRequired(), async (req, res) => {
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
router.post("/:id/care-reports", authRequired(), async (req, res) => {
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

export default router;
