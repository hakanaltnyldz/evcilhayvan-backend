import { Router } from "express";
import { param, query } from "express-validator";
import { authRequired } from "../middlewares/auth.js";
import {
  getMatchingProfiles,
  createMatchRequest,
  getInboxRequests,
  getOutboxRequests,
  updateMatchRequestStatus,
} from "../controllers/matchingController.js";

const router = Router();

router.use(authRequired());

// Eslesme profilleri (swipe karti)
router.get(
  "/profiles",
  [
    query("species").optional().isString(),
    query("gender").optional().isString(),
    query("maxDistanceKm").optional().isNumeric(),
    query("minAgeMonths").optional().isNumeric(),
    query("maxAgeMonths").optional().isNumeric(),
    query("breed").optional().isString(),
    query("vaccinated").optional().isBoolean(),
  ],
  getMatchingProfiles
);

// Eslesme istekleri
router.post("/requests", createMatchRequest);
router.get("/requests/inbox", getInboxRequests);
router.get("/requests/outbox", getOutboxRequests);
router.patch("/requests/:id", [param("id").isMongoId()], updateMatchRequestStatus);

export default router;
