import { Router } from "express";
import { param } from "express-validator";
import { authRequired } from "../middlewares/auth.js";
import {
  createBooking, myBookings, incomingBookings, getBooking, updateBookingStatus,
} from "../controllers/sitterBookingController.js";

const router = Router();

router.post("/", authRequired(), createBooking);
router.get("/me", authRequired(), myBookings);
router.get("/incoming", authRequired(), incomingBookings);
router.get("/:id", authRequired(), [param("id").isMongoId()], getBooking);
router.patch("/:id/status", authRequired(), [param("id").isMongoId()], updateBookingStatus);

export default router;
