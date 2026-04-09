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
router.get("/", listSitters);
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
