import { Router } from "express";
import { param } from "express-validator";
import { authRequired } from "../middlewares/auth.js";
import {
  createAppointment,
  getMyAppointments,
  getVetSchedule,
  getAppointment,
  updateAppointmentStatus,
  updateAppointmentClinicalRecord,
  getAvailableSlots,
  rescheduleAppointment,
  getAppointmentPrescriptions,
  createAppointmentPrescription,
  getVetEarningsSummary,
} from "../controllers/appointmentController.js";

const router = Router();

router.post("/", authRequired(), createAppointment);
router.get("/me", authRequired(), getMyAppointments);
router.get("/vet-schedule", authRequired(), getVetSchedule);
router.get("/vet-earnings", authRequired(), getVetEarningsSummary);
router.get("/vet/:veterinaryId/slots", authRequired(), [param("veterinaryId").isMongoId()], getAvailableSlots);
router.get("/:id/prescriptions", authRequired(), [param("id").isMongoId()], getAppointmentPrescriptions);
router.post("/:id/prescriptions", authRequired(), [param("id").isMongoId()], createAppointmentPrescription);
router.patch("/:id/clinical-record", authRequired(), [param("id").isMongoId()], updateAppointmentClinicalRecord);
router.patch("/:id/reschedule", authRequired(), [param("id").isMongoId()], rescheduleAppointment);
router.get("/:id", authRequired(), [param("id").isMongoId()], getAppointment);
router.patch("/:id/status", authRequired(), [param("id").isMongoId()], updateAppointmentStatus);

export default router;
