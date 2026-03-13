import { Router } from "express";
import { authRequired } from "../middlewares/auth.js";
import { chatWithAI, getDiseases } from "../controllers/aiController.js";

const router = Router();
router.use(authRequired);

router.post("/chat", chatWithAI);
router.get("/diseases", getDiseases); // hastalık listesi (auth gerekli)

export default router;
