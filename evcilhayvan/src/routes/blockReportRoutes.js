import { Router } from "express";
import { authRequired } from "../middlewares/auth.js";
import {
  blockUser,
  unblockUser,
  getBlockedUsers,
  isBlocked,
  reportUser,
  getReports,
} from "../controllers/blockReportController.js";

const router = Router();

router.use(authRequired);

router.post("/block/:userId", blockUser);
router.delete("/block/:userId", unblockUser);
router.get("/blocked", getBlockedUsers);
router.get("/is-blocked/:userId", isBlocked);
router.post("/report/:userId", reportUser);

// Admin
router.get("/admin/reports", getReports);

export default router;
