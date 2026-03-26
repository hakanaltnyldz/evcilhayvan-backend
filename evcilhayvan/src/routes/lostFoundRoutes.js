import { Router } from "express";
import { body, param } from "express-validator";
import { authRequired } from "../middlewares/auth.js";
import {
  createReport,
  listReports,
  nearbyReports,
  getReport,
  updateReport,
  updateStatus,
  deleteReport,
  myReports,
} from "../controllers/lostFoundController.js";

const router = Router();

// POST / - Yeni ilan olustur
router.post(
  "/",
  authRequired(),
  [
    body("type").isIn(["lost", "found"]).withMessage("Tip lost veya found olmali"),
    body("species").isIn(["dog", "cat", "bird", "rabbit", "other"]).withMessage("Gecersiz tur"),
    body("color").notEmpty().withMessage("Renk/fiziksel tanim gerekli"),
    body("description").notEmpty().withMessage("Aciklama gerekli"),
    body("lastSeenDate").isISO8601().withMessage("Gecerli bir tarih girin"),
    body("location.coordinates").optional().isArray({ min: 2, max: 2 }),
  ],
  createReport
);

// GET /me - Kendi ilanlarim (MUST be before /:id)
router.get("/me", authRequired(), myReports);

// GET /near - Yakin ilanlar
router.get("/near", nearbyReports);

// GET / - Ilan listesi
router.get("/", listReports);

// GET /:id - Detay
router.get("/:id", [param("id").isMongoId()], getReport);

// PUT /:id - Guncelle
router.put("/:id", authRequired(), [param("id").isMongoId()], updateReport);

// PATCH /:id/status - Durum guncelle
router.patch("/:id/status", authRequired(), [param("id").isMongoId()], updateStatus);

// DELETE /:id
router.delete("/:id", authRequired(), [param("id").isMongoId()], deleteReport);

export default router;
