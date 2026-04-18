import { Router } from "express";
import { param } from "express-validator";
import { authRequired } from "../middlewares/auth.js";
import {
  createAppointment,
  getMyAppointments,
  getAppointment,
  updateAppointmentStatus,
  getAvailableSlots,
  rescheduleAppointment,
  getAppointmentPrescriptions,
  createAppointmentPrescription,
} from "../controllers/appointmentController.js";

const router = Router();

router.post("/", authRequired(), createAppointment);
router.get("/me", authRequired(), getMyAppointments);
router.get("/vet/:veterinaryId/slots", authRequired(), [param("veterinaryId").isMongoId()], getAvailableSlots);
router.get("/:id/prescriptions", authRequired(), [param("id").isMongoId()], getAppointmentPrescriptions);
router.post("/:id/prescriptions", authRequired(), [param("id").isMongoId()], createAppointmentPrescription);
router.patch("/:id/reschedule", authRequired(), [param("id").isMongoId()], rescheduleAppointment);
router.get("/:id", authRequired(), [param("id").isMongoId()], getAppointment);
router.patch("/:id/status", authRequired(), [param("id").isMongoId()], updateAppointmentStatus);

export default router;
