import { Router } from "express";
import { body } from "express-validator";
import fs from "fs";
import path from "path";
import multer from "multer";
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
  getMyStats,
  getAllUsers,
  followUser,
  unfollowUser,
  getUserFollowers,
  getUserFollowing,
  loginWithGoogle,
  loginWithFacebook,
  getUserPublicProfile,
  registerFcmToken,
  unregisterFcmToken,
} from "../controllers/authController.js";
import { authRequired } from "../middlewares/auth.js";
import { config } from "../config/config.js";

const router = Router();

/* ---------- Multer (Avatar Upload) ---------- */
const uploadDir = config.uploadDir || path.join(process.cwd(), "uploads");
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadDir),
  filename: (_req, file, cb) => {
    const unique = Date.now() + "-" + Math.round(Math.random() * 1e9);
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
router.get("/me/stats", authRequired(), getMyStats);

router.put(
  "/me",
  authRequired(),
  [body("name").optional().notEmpty().withMessage("Isim bos olamaz"), body("city").optional().trim(), body("about").optional().trim()],
  updateMe
);

router.post("/avatar", authRequired(), upload.single("avatar"), uploadAvatar);

router.get("/users", authRequired(), getAllUsers);

router.get("/users/:userId/followers", authRequired(), getUserFollowers);
router.get("/users/:userId/following", authRequired(), getUserFollowing);
router.post("/users/:userId/follow", authRequired(), followUser);
router.delete("/users/:userId/follow", authRequired(), unfollowUser);
router.get("/users/:userId", authRequired(), getUserPublicProfile);

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

export default router;
