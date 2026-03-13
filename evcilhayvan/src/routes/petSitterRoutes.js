import { Router } from "express";
import { body } from "express-validator";
import { authRequired } from "../middlewares/auth.js";
import {
  createSitter, listSitters, mySitterProfile, getSitter, updateSitter, toggleAvailability,
} from "../controllers/petSitterController.js";

const router = Router();

router.post(
  "/",
  authRequired(),
  [
    body("displayName").notEmpty().withMessage("Gorunen ad gerekli"),
    body("services").isArray({ min: 1 }).withMessage("En az bir hizmet gerekli"),
  ],
  createSitter
);

router.get("/me", authRequired(), mySitterProfile);
router.get("/", listSitters);
router.get("/:id", getSitter);
router.put("/:id", authRequired(), updateSitter);
router.patch("/:id/availability", authRequired(), toggleAvailability);

export default router;
