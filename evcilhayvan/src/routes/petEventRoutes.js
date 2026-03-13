import { Router } from "express";
import { body } from "express-validator";
import { authRequired } from "../middlewares/auth.js";
import {
  createEvent, listEvents, getEvent, updateEvent, cancelEvent,
  attendEvent, myAttendance, myAttendingEvents, myOrganizedEvents,
} from "../controllers/petEventController.js";

const router = Router();

router.post(
  "/",
  authRequired(),
  [
    body("title").notEmpty().withMessage("Baslik gerekli"),
    body("description").notEmpty().withMessage("Aciklama gerekli"),
    body("category").isIn(["park_meetup", "adoption_day", "training", "competition", "grooming", "health", "other"])
      .withMessage("Gecersiz kategori"),
    body("startDate").isISO8601().withMessage("Gecerli baslangic tarihi girin"),
    body("endDate").isISO8601().withMessage("Gecerli bitis tarihi girin"),
  ],
  createEvent
);

router.get("/me/attending", authRequired(), myAttendingEvents);
router.get("/me/organized", authRequired(), myOrganizedEvents);
router.get("/", listEvents);
router.get("/:id", getEvent);
router.put("/:id", authRequired(), updateEvent);
router.patch("/:id/cancel", authRequired(), cancelEvent);
router.post("/:id/attend", authRequired(), attendEvent);
router.get("/:id/attendance", authRequired(), myAttendance);

export default router;
