import { Router } from "express";
import { body } from "express-validator";
import { randomBytes } from "crypto";
import fs from "fs";
import path from "path";
import multer from "multer";
import rateLimit from "express-rate-limit";
import {
  register,
  login,
  refreshToken,
  me,
  uploadAvatar,
  verifyEmail,
  forgotPassword,
  resetPassword,
  updateMe,
  getAllUsers,
  loginWithGoogle,
  loginWithFacebook,
  getUserPublicProfile,
  registerFcmToken,
  unregisterFcmToken,
} from "../controllers/authController.js";
import { authRequired } from "../middlewares/auth.js";
import { config } from "../config/config.js";

const router = Router();

const emailVerificationLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  max: 8,
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: true,
  keyGenerator: (req) => `${req.ip}:${String(req.body?.email || "").toLowerCase()}`,
  message: {
    success: false,
    message: "Cok fazla dogrulama denemesi. Lutfen daha sonra tekrar deneyin.",
    code: "too_many_verification_attempts",
  },
});

/* ---------- Multer (Avatar Upload) ---------- */
const uploadDir = config.uploadDir || path.join(process.cwd(), "uploads");
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadDir),
  filename: (_req, file, cb) => {
    const unique = Date.now() + "-" + randomBytes(8).toString("hex");
    const ext = path.extname(file.originalname || "");
    cb(null, "avatar-" + unique + ext);
  },
});
const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (file.mimetype.startsWith("image/")) cb(null, true);
    else cb(new Error("Sadece resim dosyaları yüklenebilir"));
  },
});
/* ------------------------------------------- */

// === KAYIT / GIRIS / SIFIRLAMA ===
router.post(
  "/register",
  [
    body("name").notEmpty().withMessage("Isim gerekli"),
    body("email").isEmail().withMessage("Gecerli email gerekli"),
    body("password").isLength({ min: 6 }).withMessage("Sifre en az 6 karakter olmali"),
  ],
  register
);

router.post("/oauth/google", [body("idToken").notEmpty().withMessage("Google idToken gerekli")], loginWithGoogle);

router.post(
  "/oauth/facebook",
  [body("accessToken").notEmpty().withMessage("Facebook accessToken gerekli")],
  loginWithFacebook
);

router.post(
  "/verify-email",
  emailVerificationLimiter,
  [
    body("email").isEmail().withMessage("Gecerli email gerekli"),
    body("code").isLength({ min: 6, max: 6 }).withMessage("Dogrulama kodu 6 haneli olmali"),
  ],
  verifyEmail
);

router.post(
  "/login",
  [
    body("email").isEmail().withMessage("Gecerli email gerekli"),
    body("password").notEmpty().withMessage("Sifre gerekli"),
  ],
  login
);

router.post("/refresh", refreshToken);

router.post("/forgot-password", [body("email").isEmail().withMessage("Gecerli email gerekli")], forgotPassword);

router.post(
  "/reset-password",
  [
    body("email").isEmail().withMessage("Gecerli email gerekli"),
    body("code").isLength({ min: 6, max: 6 }).withMessage("Dogrulama kodu 6 haneli olmali"),
    body("newPassword").isLength({ min: 6 }).withMessage("Yeni sifre en az 6 karakter olmali"),
  ],
  resetPassword
);

// === GIRIS GEREKTIREN ISLEMLER ===
router.get("/me", authRequired(), me);

router.put(
  "/me",
  authRequired(),
  [body("name").optional().notEmpty().withMessage("Isim bos olamaz"), body("city").optional().trim(), body("about").optional().trim()],
  updateMe
);

router.post("/avatar", authRequired(), upload.single("avatar"), uploadAvatar);

router.get("/users", authRequired(), getAllUsers);

router.get("/users/:userId", authRequired(), getUserPublicProfile);

// === TAKİP SİSTEMİ ===

// POST /api/auth/users/:userId/follow — takip et
router.post("/users/:userId/follow", authRequired(), async (req, res) => {
  try {
    const { sendOk, sendError } = await import("../utils/apiResponse.js");
    const User = (await import("../models/User.js")).default;
    const { sendPush } = await import("../utils/fcm.js");
    const { io } = await import("../../server.js");

    const followerId = req.user.sub;
    const { userId } = req.params;

    if (String(followerId) === String(userId)) {
      return sendError(res, 400, "Kendinizi takip edemezsiniz", "validation_error");
    }

    const [follower, target] = await Promise.all([
      User.findById(followerId),
      User.findById(userId),
    ]);
    if (!target) return sendError(res, 404, "Kullanıcı bulunamadı", "not_found");

    await Promise.all([
      User.findByIdAndUpdate(followerId, { $addToSet: { following: userId } }),
      User.findByIdAndUpdate(userId, { $addToSet: { followers: followerId } }),
    ]);

    // Bildirim
    sendPush([String(userId)], {
      title: `${follower?.name || 'Biri'} sizi takip etmeye başladı`,
      body: '',
      data: { type: "new_follower", userId: String(followerId) },
    }).catch(() => {});
    if (io?.to) {
      io.to(`user:${String(userId)}`).emit("user:followed", { followerId: String(followerId) });
    }

    const updatedTarget = await User.findById(userId).select("followers following");
    return sendOk(res, 200, {
      isFollowing: true,
      followersCount: updatedTarget?.followers?.length ?? 0,
    });
  } catch (err) {
    const { sendError } = await import("../utils/apiResponse.js");
    return sendError(res, 500, "Takip işlemi başarısız", "internal_error", err.message);
  }
});

// DELETE /api/auth/users/:userId/follow — takipten çık
router.delete("/users/:userId/follow", authRequired(), async (req, res) => {
  try {
    const { sendOk, sendError } = await import("../utils/apiResponse.js");
    const User = (await import("../models/User.js")).default;

    const followerId = req.user.sub;
    const { userId } = req.params;

    await Promise.all([
      User.findByIdAndUpdate(followerId, { $pull: { following: userId } }),
      User.findByIdAndUpdate(userId, { $pull: { followers: followerId } }),
    ]);

    const updatedTarget = await User.findById(userId).select("followers");
    return sendOk(res, 200, {
      isFollowing: false,
      followersCount: updatedTarget?.followers?.length ?? 0,
    });
  } catch (err) {
    const { sendError } = await import("../utils/apiResponse.js");
    return sendError(res, 500, "Takipten çıkma başarısız", "internal_error", err.message);
  }
});

// GET /api/auth/users/:userId/followers
router.get("/users/:userId/followers", authRequired(), async (req, res) => {
  try {
    const { sendOk, sendError } = await import("../utils/apiResponse.js");
    const User = (await import("../models/User.js")).default;
    const user = await User.findById(req.params.userId)
      .populate("followers", "name avatarUrl city")
      .lean();
    if (!user) return sendError(res, 404, "Kullanıcı bulunamadı", "not_found");
    return sendOk(res, 200, { followers: user.followers || [] });
  } catch (err) {
    const { sendError } = await import("../utils/apiResponse.js");
    return sendError(res, 500, "Takipçiler alınamadı", "internal_error", err.message);
  }
});

// GET /api/auth/users/:userId/following
router.get("/users/:userId/following", authRequired(), async (req, res) => {
  try {
    const { sendOk, sendError } = await import("../utils/apiResponse.js");
    const User = (await import("../models/User.js")).default;
    const user = await User.findById(req.params.userId)
      .populate("following", "name avatarUrl city")
      .lean();
    if (!user) return sendError(res, 404, "Kullanıcı bulunamadı", "not_found");
    return sendOk(res, 200, { following: user.following || [] });
  } catch (err) {
    const { sendError } = await import("../utils/apiResponse.js");
    return sendError(res, 500, "Takip edilenler alınamadı", "internal_error", err.message);
  }
});

router.post("/fcm-token", authRequired(), registerFcmToken);
router.delete("/fcm-token", authRequired(), unregisterFcmToken);

// === BİLDİRİM TERCİHLERİ ===
router.get("/me/notification-preferences", authRequired(), async (req, res) => {
  try {
    const { sendOk, sendError } = await import("../utils/apiResponse.js");
    const User = (await import("../models/User.js")).default;
    const user = await User.findById(req.user.sub, "notificationPreferences");
    if (!user) return sendError(res, 404, "Kullanici bulunamadi");
    return sendOk(res, 200, { preferences: user.notificationPreferences ?? {} });
  } catch (err) {
    const { sendError } = await import("../utils/apiResponse.js");
    return sendError(res, 500, "Hata", "internal_error", err.message);
  }
});

router.patch("/me/notification-preferences", authRequired(), async (req, res) => {
  try {
    const { sendOk, sendError } = await import("../utils/apiResponse.js");
    const User = (await import("../models/User.js")).default;
    const allowed = ["messages","matches","adoptions","vaccinations","orderUpdates","sitterBookings","lostFoundNearby","events","birthdays"];
    const update = {};
    for (const key of allowed) {
      if (typeof req.body[key] === "boolean") update[`notificationPreferences.${key}`] = req.body[key];
    }
    await User.findByIdAndUpdate(req.user.sub, { $set: update });
    return sendOk(res, 200, { message: "Güncellendi" });
  } catch (err) {
    const { sendError } = await import("../utils/apiResponse.js");
    return sendError(res, 500, "Hata", "internal_error", err.message);
  }
});

// === PROFİL İSTATİSTİKLERİ ===
router.get("/me/stats", authRequired(), async (req, res) => {
  try {
    const { sendOk, sendError } = await import("../utils/apiResponse.js");
    const Post = (await import("../models/Post.js")).default;
    const Appointment = (await import("../models/Appointment.js")).default;
    const SitterBooking = (await import("../models/SitterBooking.js")).default;
    const mongoose = (await import("mongoose")).default;

    const userId = req.user.sub;
    const userObjId = new mongoose.Types.ObjectId(userId);

    const [postCount, likeAgg, appointmentCount, bookingCount] = await Promise.all([
      Post.countDocuments({ userId: userObjId, isActive: true }),
      Post.aggregate([
        { $match: { userId: userObjId } },
        { $group: { _id: null, total: { $sum: "$likeCount" } } },
      ]),
      Appointment.countDocuments({ userId: userObjId }),
      SitterBooking.countDocuments({ petOwnerId: userObjId }),
    ]);

    return sendOk(res, 200, {
      postCount,
      totalLikes: likeAgg[0]?.total ?? 0,
      appointmentCount,
      bookingCount,
    });
  } catch (err) {
    const { sendError } = await import("../utils/apiResponse.js");
    return sendError(res, 500, "İstatistikler alınamadı", "internal_error", err.message);
  }
});

export default router;
