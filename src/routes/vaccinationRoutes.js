import { Router } from "express";
import { authRequired } from "../middlewares/auth.js";
import {
  getSchedules,
  createSchedule,
  getPetVaccinations,
  addVaccinationRecord,
  updateVaccinationRecord,
  deleteVaccinationRecord,
  getVaccinationCalendar,
  getReminders,
} from "../controllers/vaccinationController.js";

const router = Router();

router.get("/schedules", getSchedules);
router.post("/schedules", authRequired(["admin"]), createSchedule);
router.get("/reminders", authRequired(), getReminders);
router.get("/pet/:petId", authRequired(), getPetVaccinations);
router.get("/pet/:petId/calendar", authRequired(), getVaccinationCalendar);
router.post("/records", authRequired(), addVaccinationRecord);
router.put("/records/:id", authRequired(), updateVaccinationRecord);
router.delete("/records/:id", authRequired(), deleteVaccinationRecord);

export default router;
