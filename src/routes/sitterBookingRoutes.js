import { Router } from "express";
import { authRequired } from "../middlewares/auth.js";
import {
  createBooking, myBookings, incomingBookings, getBooking, updateBookingStatus,
} from "../controllers/sitterBookingController.js";

const router = Router();

router.post("/", authRequired(), createBooking);
router.get("/me", authRequired(), myBookings);
router.get("/incoming", authRequired(), incomingBookings);
router.get("/:id", authRequired(), getBooking);
router.patch("/:id/status", authRequired(), updateBookingStatus);

export default router;
