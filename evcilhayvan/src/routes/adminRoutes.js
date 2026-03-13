// src/routes/adminRoutes.js
import { Router } from "express";
import { param, query } from "express-validator";
import mongoose from "mongoose";
import { authRequired } from "../middlewares/auth.js";
import { sendOk, sendError } from "../utils/apiResponse.js";
import User from "../models/User.js";
import Pet from "../models/Pet.js";
import Order from "../models/Order.js";
import UserReport from "../models/UserReport.js";

const router = Router();

// Tüm admin endpointleri admin rolü gerektirir
router.use(authRequired(["admin"]));

// GET /api/admin/stats
router.get("/stats", async (req, res) => {
  try {
    const [
      totalUsers,
      newUsersThisMonth,
      totalPets,
      activePets,
      totalOrders,
      pendingReports,
    ] = await Promise.all([
      User.countDocuments(),
      User.countDocuments({
        createdAt: { $gte: new Date(new Date().setDate(1)) },
      }),
      Pet.countDocuments(),
      Pet.countDocuments({ isActive: true }),
      Order.countDocuments().catch(() => 0),
      UserReport.countDocuments({ status: "pending" }),
    ]);

    return sendOk(res, 200, {
      stats: {
        totalUsers,
        newUsersThisMonth,
        totalPets,
        activePets,
        totalOrders,
        pendingReports,
      },
    });
  } catch (err) {
    return sendError(res, 500, "İstatistikler alınamadı", "internal_error", err.message);
  }
});

// GET /api/admin/users?page=1&q=
router.get("/users", async (req, res) => {
  try {
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = 20;
    const skip = (page - 1) * limit;
    const q = req.query.q?.trim();

    const filter = q
      ? { $or: [{ name: { $regex: q, $options: "i" } }, { email: { $regex: q, $options: "i" } }] }
      : {};

    const [users, total] = await Promise.all([
      User.find(filter)
        .select("name email role city avatarUrl isSeller isVerified createdAt")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      User.countDocuments(filter),
    ]);

    return sendOk(res, 200, { users, total, page, hasMore: skip + users.length < total });
  } catch (err) {
    return sendError(res, 500, "Kullanıcılar alınamadı", "internal_error", err.message);
  }
});

// PATCH /api/admin/users/:id/ban
router.patch(
  "/users/:id/ban",
  [param("id").isMongoId().withMessage("Geçersiz kullanıcı ID")],
  async (req, res) => {
    try {
      const user = await User.findById(req.params.id);
      if (!user) return sendError(res, 404, "Kullanıcı bulunamadı", "user_not_found");
      if (user.role === "admin") return sendError(res, 403, "Admin banlanamaz", "forbidden");

      // role: 'user' ↔ 'banned' toggle
      user.role = user.role === "banned" ? "user" : "banned";
      await user.save();

      return sendOk(res, 200, {
        message: user.role === "banned" ? "Kullanıcı banlandı" : "Ban kaldırıldı",
        user: { id: user._id, name: user.name, role: user.role },
      });
    } catch (err) {
      return sendError(res, 500, "İşlem başarısız", "internal_error", err.message);
    }
  }
);

// GET /api/admin/pets?page=1&type=adoption|mating|all
router.get("/pets", async (req, res) => {
  try {
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = 20;
    const skip = (page - 1) * limit;
    const type = req.query.type;

    const filter = {};
    if (type && ["adoption", "mating"].includes(type)) filter.advertType = type;

    const [pets, total] = await Promise.all([
      Pet.find(filter)
        .select("name species breed gender ageMonths advertType isActive photos createdAt")
        .populate("ownerId", "name email")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      Pet.countDocuments(filter),
    ]);

    return sendOk(res, 200, { pets, total, page, hasMore: skip + pets.length < total });
  } catch (err) {
    return sendError(res, 500, "İlanlar alınamadı", "internal_error", err.message);
  }
});

// PATCH /api/admin/pets/:id/toggle
router.patch(
  "/pets/:id/toggle",
  [param("id").isMongoId().withMessage("Geçersiz ilan ID")],
  async (req, res) => {
    try {
      const pet = await Pet.findById(req.params.id);
      if (!pet) return sendError(res, 404, "İlan bulunamadı", "pet_not_found");

      pet.isActive = !pet.isActive;
      await pet.save();

      return sendOk(res, 200, {
        message: pet.isActive ? "İlan aktifleştirildi" : "İlan devre dışı bırakıldı",
        pet: { id: pet._id, name: pet.name, isActive: pet.isActive },
      });
    } catch (err) {
      return sendError(res, 500, "İşlem başarısız", "internal_error", err.message);
    }
  }
);

// GET /api/admin/reports?page=1&status=pending|reviewed|all
router.get("/reports", async (req, res) => {
  try {
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = 20;
    const skip = (page - 1) * limit;
    const status = req.query.status;

    const filter = {};
    if (status && ["pending", "reviewed", "dismissed"].includes(status)) filter.status = status;
    else filter.status = "pending"; // default: only pending

    const [reports, total] = await Promise.all([
      UserReport.find(filter)
        .populate("reporterId", "name email avatarUrl")
        .populate("reportedId", "name email avatarUrl")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      UserReport.countDocuments(filter),
    ]);

    return sendOk(res, 200, { reports, total, page, hasMore: skip + reports.length < total });
  } catch (err) {
    return sendError(res, 500, "Şikayetler alınamadı", "internal_error", err.message);
  }
});

// PATCH /api/admin/reports/:id/resolve
router.patch(
  "/reports/:id/resolve",
  [param("id").isMongoId().withMessage("Geçersiz şikayet ID")],
  async (req, res) => {
    try {
      const { action } = req.body; // 'reviewed' | 'dismissed'
      const status = action === "dismissed" ? "dismissed" : "reviewed";

      const report = await UserReport.findByIdAndUpdate(
        req.params.id,
        { status },
        { new: true }
      );
      if (!report) return sendError(res, 404, "Şikayet bulunamadı", "report_not_found");

      return sendOk(res, 200, { message: "Şikayet güncellendi", report });
    } catch (err) {
      return sendError(res, 500, "İşlem başarısız", "internal_error", err.message);
    }
  }
);

export default router;
