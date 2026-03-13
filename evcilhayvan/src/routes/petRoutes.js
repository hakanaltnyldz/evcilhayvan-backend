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

const mediaUpload = multer({
  storage: _storage,
  limits: { fileSize: 20 * 1024 * 1024 },
});

// Public
router.get("/feed", authRequired(), getPetFeed);
router.get("/", listPets);
router.get("/me", authRequired(), [query("type").optional().isIn(["adoption", "mating"])], myAdverts);
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
    body("location.coordinates").optional().isArray({ min: 2, max: 2 }),
  ],
  createPet
);

router.put(
  "/:id",
  authRequired(),
  [
    param("id").isMongoId(),
    body("species").optional().isIn(["dog", "cat", "bird", "fish", "rodent", "other"]),
    body("ageMonths").optional().isInt({ min: 0 }),
    body("advertType").optional().isIn(["adoption", "mating"]),
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
  ],
  updatePet
);

router.delete("/:id", authRequired(), [param("id").isMongoId()], deletePet);

router.post(
  "/:id/images",
  authRequired(),
  [param("id").isMongoId()],
  mediaUpload.single("image"),
  uploadPetImage
);

router.post(
  "/:id/videos",
  authRequired(),
  [param("id").isMongoId()],
  mediaUpload.single("video"),
  uploadPetVideo
);

export default router;
