import { Router } from "express";
import { param } from "express-validator";
import { authRequired } from "../middlewares/auth.js";
import { likePet, passPet } from "../controllers/interactionController.js";

const router = Router();

router.use(authRequired());

router.post("/like/:petId", [param("petId").isMongoId()], likePet);
router.post("/pass/:petId", [param("petId").isMongoId()], passPet);

export default router;
