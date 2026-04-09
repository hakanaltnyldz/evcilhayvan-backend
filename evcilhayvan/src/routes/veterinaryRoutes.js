import { Router } from "express";
import { authRequired } from "../middlewares/auth.js";
import VetClaimRequest from "../models/VetClaimRequest.js";
import Veterinary from "../models/Veterinary.js";
import User from "../models/User.js";
import { sendOk, sendError } from "../utils/apiResponse.js";
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
  getVetClaimStatus,
  startVetConversation,
  fetchVetPhotosFromGoogle,
} from "../controllers/veterinaryController.js";
import {
  getVetReviews,
  addVetReview,
  deleteVetReview,
} from "../controllers/vetReviewController.js";

const router = Router();

router.get("/nearby", getNearbyVets);
router.get("/google-search", authRequired(), googleSearchVets);
router.get("/", listVets);
// Yorum silme (specific route before :id)
router.delete("/reviews/:reviewId", authRequired(), deleteVetReview);
router.get("/:id", getVet);
router.post("/", authRequired(), createVet);
router.put("/:id", authRequired(), updateVet);
router.delete("/:id", authRequired(["admin"]), deleteVet);
router.patch("/:id/verify", authRequired(["admin"]), verifyVet);
router.post("/:id/claim", authRequired(), claimVetProfile);
router.get("/:id/claim-status", authRequired(), getVetClaimStatus);
router.post("/:id/fetch-photos", authRequired(["admin"]), fetchVetPhotosFromGoogle);
router.post("/:id/conversation", authRequired(), startVetConversation);
// Yorumlar
router.get("/:vetId/reviews", getVetReviews);
router.post("/:vetId/reviews", authRequired(), addVetReview);

// POST /api/veterinaries/claims/:claimId/self-approve
// Kullanicinin kendi pending claim'ini onaylamasina izin verir (demo/dev)
router.post("/claims/:claimId/self-approve", authRequired(), async (req, res) => {
  try {
    const userId = req.user.sub;
    const claim = await VetClaimRequest.findById(req.params.claimId);
    if (!claim) return sendError(res, 404, "Talep bulunamadi", "not_found");
    if (String(claim.userId) !== String(userId)) {
      return sendError(res, 403, "Bu talep size ait degil", "forbidden");
    }
    if (claim.status !== "pending") {
      return sendError(res, 409, "Bu talep zaten incelendi", "already_reviewed");
    }
    claim.status = "approved";
    claim.reviewedAt = new Date();
    await claim.save();
    await Veterinary.findByIdAndUpdate(claim.vetId, { userId: claim.userId, isVerified: true });
    await User.findByIdAndUpdate(claim.userId, { role: "vet" });
    return sendOk(res, 200, { message: "Klinik profilinize basariyla atandi" });
  } catch (err) {
    return sendError(res, 500, "Islem basarisiz", "internal_error", err.message);
  }
});

export default router;
