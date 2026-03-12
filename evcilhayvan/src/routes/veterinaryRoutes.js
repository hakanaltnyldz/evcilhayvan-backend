import { Router } from "express";
import { authRequired } from "../middlewares/auth.js";
import {
  listVets,
  getNearbyVets,
  googleSearchVets,
  getVet,
  createVet,
  updateVet,
  deleteVet,
  verifyVet,
  claimVetProfile,
  startVetConversation,
} from "../controllers/veterinaryController.js";

const router = Router();

router.get("/nearby", getNearbyVets);
router.get("/google-search", authRequired(), googleSearchVets);
router.get("/", listVets);
router.get("/:id", getVet);
router.post("/", authRequired(), createVet);
router.put("/:id", authRequired(), updateVet);
router.delete("/:id", authRequired(["admin"]), deleteVet);
router.patch("/:id/verify", authRequired(["admin"]), verifyVet);
router.post("/:id/claim", authRequired(), claimVetProfile);
router.post("/:id/conversation", authRequired(), startVetConversation);

export default router;
