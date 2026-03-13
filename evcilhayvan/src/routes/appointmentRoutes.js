import { Router } from "express";
import { authRequired } from "../middlewares/auth.js";
import {
  createAppointment,
  getMyAppointments,
  getAppointment,
  updateAppointmentStatus,
  getAvailableSlots,
} from "../controllers/appointmentController.js";

const router = Router();

router.post("/", authRequired(), createAppointment);
router.get("/me", authRequired(), getMyAppointments);
router.get("/vet/:veterinaryId/slots", authRequired(), getAvailableSlots);
router.get("/:id", authRequired(), getAppointment);
router.patch("/:id/status", authRequired(), updateAppointmentStatus);

export default router;
