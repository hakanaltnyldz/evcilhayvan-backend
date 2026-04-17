import { Router } from "express";
import { body, param, query } from "express-validator";
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
    const unique = Date.now() + "-" + Math.round(Math.random() * 1e9);
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

export default router;
