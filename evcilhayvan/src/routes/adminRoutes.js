// src/routes/adminRoutes.js
import { Router } from "express";
import { param, query } from "express-validator";
import mongoose from "mongoose";
import rateLimit from "express-rate-limit";
import { authRequired } from "../middlewares/auth.js";
import { sendOk, sendError } from "../utils/apiResponse.js";
import User from "../models/User.js";
import Pet from "../models/Pet.js";
import Order from "../models/Order.js";
import Post from "../models/Post.js";
import UserReport from "../models/UserReport.js";
import Coupon from "../models/Coupon.js";
import CouponUsage from "../models/CouponUsage.js";
import SupportTicket from "../models/SupportTicket.js";
import PetSitter from "../models/PetSitter.js";
import Appointment from "../models/Appointment.js";
import VetClaimRequest from "../models/VetClaimRequest.js";
import Veterinary from "../models/Veterinary.js";
import VetReview from "../models/VetReview.js";
import WalkUpdate from "../models/WalkUpdate.js";
import CareReport from "../models/CareReport.js";
import SitterBooking from "../models/SitterBooking.js";
import SellerApplication from "../models/SellerApplication.js";
import Store from "../models/Store.js";
import { sendPush } from "../utils/fcm.js";
import { recordAudit } from "../utils/audit.js";
import { decrypt, maskNationalId } from "../utils/fieldCrypto.js";

const router = Router();

// Hassas PII endpoint'leri için rate limiter (15 dakikada 10 istek)
const sensitiveDataLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: { success: false, message: "Çok fazla istek. Lütfen 15 dakika sonra tekrar deneyin." },
  standardHeaders: true,
  legacyHeaders: false,
});

const DEFAULT_PAGE_SIZE = 20;
const MAX_PAGE = 1000;
const MAX_PAGE_SIZE = 100;

function escapeRegex(value) {
  return String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function getPagination(req, res, { defaultLimit = DEFAULT_PAGE_SIZE, maxLimit = MAX_PAGE_SIZE } = {}) {
  const rawPage = req.query.page;
  const rawLimit = req.query.limit;

  const page = rawPage === undefined ? 1 : Number(rawPage);
  const limit = rawLimit === undefined ? defaultLimit : Number(rawLimit);

  if (!Number.isInteger(page) || page < 1 || page > MAX_PAGE) {
    sendError(res, 400, `page 1 ile ${MAX_PAGE} arasinda olmali`, "validation_error");
    return null;
  }

  if (!Number.isInteger(limit) || limit < 1 || limit > maxLimit) {
    sendError(res, 400, `limit 1 ile ${maxLimit} arasinda olmali`, "validation_error");
    return null;
  }

  return { page, limit, skip: (page - 1) * limit };
}

function parseDateOnly(value, { endOfDay = false } = {}) {
  if (!value) return null;
  if (!/^\d{4}-\d{2}-\d{2}$/.test(String(value))) return null;
  const date = new Date(endOfDay ? `${value}T23:59:59.999Z` : `${value}T00:00:00.000Z`);
  return Number.isNaN(date.getTime()) ? null : date;
}

function formatTimelineLabel(date, granularity) {
  return new Intl.DateTimeFormat("tr-TR", granularity === "day"
    ? { day: "2-digit", month: "short", timeZone: "UTC" }
    : { month: "short", year: "2-digit", timeZone: "UTC" }).format(date);
}

function buildTimelineBuckets({ fromDate, toDate, now = new Date() }) {
  const endDate = toDate || now;
  const explicitRangeDays = fromDate && toDate
    ? Math.max(1, Math.ceil((toDate.getTime() - fromDate.getTime()) / 86400000) + 1)
    : null;
  const granularity = explicitRangeDays && explicitRangeDays <= 45 ? "day" : "month";

  const buckets = [];
  if (granularity === "day") {
    const startDate = new Date(Date.UTC(fromDate.getUTCFullYear(), fromDate.getUTCMonth(), fromDate.getUTCDate()));
    const finalDate = new Date(Date.UTC(toDate.getUTCFullYear(), toDate.getUTCMonth(), toDate.getUTCDate(), 23, 59, 59, 999));
    for (let cursor = new Date(startDate); cursor <= finalDate; cursor.setUTCDate(cursor.getUTCDate() + 1)) {
      const point = new Date(cursor);
      buckets.push({
        key: point.toISOString().slice(0, 10),
        label: formatTimelineLabel(point, "day"),
      });
    }
    return {
      granularity,
      mongoFormat: "%Y-%m-%d",
      startDate,
      endDate: finalDate,
      buckets,
    };
  }

  const seedDate = fromDate || new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - 5, 1));
  const startDate = new Date(Date.UTC(seedDate.getUTCFullYear(), seedDate.getUTCMonth(), 1));
  const finalMonth = new Date(Date.UTC(endDate.getUTCFullYear(), endDate.getUTCMonth(), 1));

  for (let cursor = new Date(startDate); cursor <= finalMonth; cursor.setUTCMonth(cursor.getUTCMonth() + 1)) {
    const point = new Date(cursor);
    buckets.push({
      key: `${point.getUTCFullYear()}-${String(point.getUTCMonth() + 1).padStart(2, "0")}`,
      label: formatTimelineLabel(point, "month"),
    });
  }

  return {
    granularity,
    mongoFormat: "%Y-%m",
    startDate,
    endDate,
    buckets,
  };
}

// Tüm admin endpointleri admin rolü gerektirir
router.use(authRequired(["admin"]));

// GET /api/admin/stats?from=YYYY-MM-DD&to=YYYY-MM-DD
router.get("/stats", async (req, res) => {
  try {
    const now = new Date();
    // Tarih filtresi — from/to verilmezse all-time
    const hasFrom = req.query.from !== undefined;
    const hasTo = req.query.to !== undefined;
    const fromDate = hasFrom ? parseDateOnly(req.query.from) : null;
    const toDate = hasTo ? parseDateOnly(req.query.to, { endOfDay: true }) : null;
    if ((hasFrom && !fromDate) || (hasTo && !toDate)) {
      return sendError(res, 400, "from/to YYYY-MM-DD formatinda olmali", "validation_error");
    }
    if (fromDate && toDate && fromDate > toDate) {
      return sendError(res, 400, "from tarihi to tarihinden sonra olamaz", "validation_error");
    }
    const dateFilter = {};
    if (fromDate) dateFilter.$gte = fromDate;
    if (toDate) dateFilter.$lte = toDate;
    const hasDateFilter = fromDate || toDate;
    const timeline = buildTimelineBuckets({ fromDate, toDate, now });

    const commerceFilter = {
      status: { $ne: "cancelled" },
      paymentStatus: { $ne: "failed" },
    };
    if (hasDateFilter) {
      commerceFilter.createdAt = dateFilter;
    }

    const returnsDateFilter = {};
    if (fromDate) returnsDateFilter.$gte = fromDate;
    if (toDate) returnsDateFilter.$lte = toDate;
    const hasReturnsDateFilter = Object.keys(returnsDateFilter).length > 0;

    const [
      allTimeUsers,
      totalUsers,
      allTimeOrders,
      newUsersThisMonth,
      newUsersInRange,
      totalPets,
      activePets,
      totalOrders,
      ordersInRange,
      pendingReports,
      totalActiveCoupons,
      openSupportTickets,
      pendingSellerApplications,
      pendingReturns,
      approvedReturns,
      rejectedReturns,
      revenueSummaryRaw,
      revenueTrendRaw,
      userGrowthRaw,
      topProductsRaw,
    ] = await Promise.all([
      User.countDocuments({}),
      User.countDocuments(hasDateFilter ? { createdAt: dateFilter } : {}),
      Order.countDocuments({}).catch(() => 0),
      User.countDocuments({
        createdAt: { $gte: new Date(new Date().setDate(1)) },
      }),
      hasDateFilter ? User.countDocuments({ createdAt: dateFilter }) : Promise.resolve(null),
      Pet.countDocuments(hasDateFilter ? { createdAt: dateFilter } : {}),
      Pet.countDocuments({ isActive: true }),
      Order.countDocuments(hasDateFilter ? { createdAt: dateFilter } : {}).catch(() => 0),
      hasDateFilter ? Order.countDocuments({ createdAt: dateFilter }).catch(() => 0) : Promise.resolve(null),
      UserReport.countDocuments({ status: "pending" }),
      Coupon.countDocuments({ isActive: true, validUntil: { $gte: now } }).catch(() => 0),
      SupportTicket.countDocuments({ status: "open" }).catch(() => 0),
      SellerApplication.countDocuments({ status: "pending" }).catch(() => 0),
      Order.countDocuments({
        "returnRequest.status": "pending",
        ...(hasReturnsDateFilter ? { "returnRequest.requestedAt": returnsDateFilter } : {}),
      }).catch(() => 0),
      Order.countDocuments({
        "returnRequest.status": "approved",
        ...(hasReturnsDateFilter ? { "returnRequest.requestedAt": returnsDateFilter } : {}),
      }).catch(() => 0),
      Order.countDocuments({
        "returnRequest.status": "rejected",
        ...(hasReturnsDateFilter ? { "returnRequest.requestedAt": returnsDateFilter } : {}),
      }).catch(() => 0),
      Order.aggregate([
        { $match: commerceFilter },
        {
          $group: {
            _id: null,
            grossRevenue: { $sum: "$totalAmount" },
            averageOrderValue: { $avg: "$totalAmount" },
            deliveredOrders: {
              $sum: { $cond: [{ $eq: ["$status", "delivered"] }, 1, 0] },
            },
          },
        },
      ]).catch(() => []),
      Order.aggregate([
        {
          $match: {
            status: { $ne: "cancelled" },
            paymentStatus: { $ne: "failed" },
            createdAt: {
              $gte: timeline.startDate,
              $lte: timeline.endDate,
            },
          },
        },
        {
          $group: {
            _id: {
              $dateToString: {
                format: timeline.mongoFormat,
                date: "$createdAt",
                timezone: "UTC",
              },
            },
            revenue: { $sum: "$totalAmount" },
            orders: { $sum: 1 },
          },
        },
        { $sort: { _id: 1 } },
      ]).catch(() => []),
      User.aggregate([
        {
          $match: {
            createdAt: {
              $gte: timeline.startDate,
              $lte: timeline.endDate,
            },
          },
        },
        {
          $group: {
            _id: {
              $dateToString: {
                format: timeline.mongoFormat,
                date: "$createdAt",
                timezone: "UTC",
              },
            },
            users: { $sum: 1 },
          },
        },
        { $sort: { _id: 1 } },
      ]).catch(() => []),
      Order.aggregate([
        { $match: commerceFilter },
        { $unwind: "$items" },
        {
          $group: {
            _id: {
              productId: "$items.product",
              name: { $ifNull: ["$items.name", "Urun"] },
            },
            totalSold: { $sum: "$items.quantity" },
            revenue: {
              $sum: { $multiply: ["$items.price", "$items.quantity"] },
            },
          },
        },
        { $sort: { totalSold: -1, revenue: -1 } },
        { $limit: 6 },
      ]).catch(() => []),
    ]);

    const revenueSummary = revenueSummaryRaw?.[0] || {};
    const revenueTrendMap = new Map(
      (revenueTrendRaw || []).map((item) => [
        item._id,
        {
          revenue: Math.round((item.revenue || 0) * 100) / 100,
          orders: item.orders || 0,
        },
      ])
    );
    const userGrowthMap = new Map(
      (userGrowthRaw || []).map((item) => [item._id, item.users || 0])
    );
    const revenueTrend = timeline.buckets.map((bucket) => ({
      key: bucket.key,
      label: bucket.label,
      revenue: revenueTrendMap.get(bucket.key)?.revenue || 0,
      orders: revenueTrendMap.get(bucket.key)?.orders || 0,
    }));
    const userGrowthTrend = timeline.buckets.map((bucket) => ({
      key: bucket.key,
      label: bucket.label,
      users: userGrowthMap.get(bucket.key) || 0,
    }));
    const topProducts = (topProductsRaw || []).map((item) => ({
      _id: item._id?.productId?.toString() || null,
      name: item._id?.name || "Urun",
      totalSold: item.totalSold || 0,
      revenue: Math.round((item.revenue || 0) * 100) / 100,
    }));

    return sendOk(res, 200, {
      stats: {
        allTimeUsers,
        totalUsers,
        allTimeOrders,
        newUsersThisMonth,
        ...(hasDateFilter && { newUsersInRange }),
        totalPets,
        activePets,
        totalOrders,
        ...(hasDateFilter && { ordersInRange }),
        pendingReports,
        totalActiveCoupons,
        openSupportTickets,
        pendingSellerApplications,
        pendingReturns,
        approvedReturns,
        rejectedReturns,
        grossRevenue: Math.round((revenueSummary.grossRevenue || 0) * 100) / 100,
        averageOrderValue: Math.round((revenueSummary.averageOrderValue || 0) * 100) / 100,
        deliveredOrders: revenueSummary.deliveredOrders || 0,
        revenueTrend,
        userGrowthTrend,
        topProducts,
        trendGranularity: timeline.granularity,
        dateFilter: hasDateFilter ? { from: req.query.from, to: req.query.to } : null,
      },
    });
  } catch (err) {
    return sendError(res, 500, "İstatistikler alınamadı", "internal_error", err.message);
  }
});

// GET /api/admin/users?page=1&q=
router.get("/users", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const q = req.query.q?.trim();

    const filter = q
      ? {
          $or: [
            { name: { $regex: escapeRegex(q), $options: "i" } },
            { email: { $regex: escapeRegex(q), $options: "i" } },
          ],
        }
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

      await recordAudit("admin.user.ban", {
        userId: req.user.sub,
        entityType: "User",
        entityId: user._id.toString(),
        metadata: { newRole: user.role },
      });

      return sendOk(res, 200, {
        message: user.role === "banned" ? "Kullanıcı banlandı" : "Ban kaldırıldı",
        user: { id: user._id, name: user.name, role: user.role },
      });
    } catch (err) {
      return sendError(res, 500, "İşlem başarısız", "internal_error", err.message);
    }
  }
);

// DELETE /api/admin/users/:id
router.delete(
  "/users/:id",
  [param("id").isMongoId().withMessage("Geçersiz kullanıcı ID")],
  async (req, res) => {
    try {
      const user = await User.findById(req.params.id);
      if (!user) return sendError(res, 404, "Kullanıcı bulunamadı", "user_not_found");
      if (user.role === "admin") return sendError(res, 403, "Admin silinemez", "forbidden");
      // Kullanicinin aktif ilanlarini pasifleştir (orphan önleme)
      await Pet.updateMany({ ownerId: user._id }, { isActive: false });
      await user.deleteOne();
      await recordAudit("admin.user.delete", {
        userId: req.user.sub,
        entityType: "User",
        entityId: req.params.id,
        metadata: { name: user.name, email: user.email },
      });
      return sendOk(res, 200, { deleted: true, id: req.params.id });
    } catch (err) {
      return sendError(res, 500, "Silme başarısız", "internal_error", err.message);
    }
  }
);

// GET /api/admin/pets?page=1&type=adoption|mating|all
router.get("/pets", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const type = req.query.type;

    const filter = {};
    if (type && ["adoption", "mating"].includes(type)) filter.advertType = type;
    if (req.query.q) {
      const escaped = req.query.q.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      filter.$or = [
        { name: { $regex: escaped, $options: "i" } },
      ];
    }

    // Sahip adı/emailine göre arama — q varsa ownerId listesi çek
    let ownerFilter = null;
    if (req.query.q) {
      const escaped = req.query.q.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      const matchingOwners = await (await import("../models/User.js")).default
        .find({ $or: [{ name: { $regex: escaped, $options: "i" } }, { email: { $regex: escaped, $options: "i" } }] })
        .select("_id");
      const ownerIds = matchingOwners.map(u => u._id);
      if (ownerIds.length) {
        filter.$or = [...(filter.$or || []), { ownerId: { $in: ownerIds } }];
      }
    }

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

// PATCH /api/admin/pets/:id — Alan güncelleme (name, description, species, breed, gender, ageMonths, isActive)
router.patch(
  "/pets/:id",
  [param("id").isMongoId().withMessage("Geçersiz ilan ID")],
  async (req, res) => {
    try {
      const allowed = ["name", "description", "species", "breed", "gender", "ageMonths", "isActive"];
      const update = {};
      for (const key of allowed) {
        if (req.body[key] !== undefined) update[key] = req.body[key];
      }
      if (Object.keys(update).length === 0) {
        return sendError(res, 400, "Güncellenecek alan yok", "no_fields");
      }
      const pet = await Pet.findByIdAndUpdate(req.params.id, { $set: update }, { new: true })
        .select("name species breed gender ageMonths advertType isActive createdAt")
        .populate("ownerId", "name email");
      if (!pet) return sendError(res, 404, "İlan bulunamadı", "pet_not_found");
      return sendOk(res, 200, { pet, message: "İlan güncellendi" });
    } catch (err) {
      return sendError(res, 500, "Güncelleme başarısız", "internal_error", err.message);
    }
  }
);

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

// GET /api/admin/reports?page=1&status=pending|reviewed|all&reason=spam|harassment|...
router.get("/reports", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const status = req.query.status;
    const reason = req.query.reason;

    const filter = {};
    if (status && ["pending", "reviewed", "dismissed"].includes(status)) filter.status = status;
    else filter.status = "pending"; // default: only pending
    if (reason && ["spam", "harassment", "inappropriate_content", "fake_profile", "other"].includes(reason)) {
      filter.reason = reason;
    }

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

// GET /api/admin/orders/export?status=&format=csv
router.get("/orders/export", async (req, res) => {
  try {
    const status = req.query.status;
    const filter = {};
    const validStatuses = ["pending", "processing", "shipped", "delivered", "cancelled"];
    if (status && validStatuses.includes(status)) filter.status = status;

    const orders = await Order.find(filter)
      .populate("user", "name email")
      .select("user totalAmount status paymentStatus trackingNumber carrier createdAt guestInfo")
      .sort({ createdAt: -1 })
      .limit(5000);

    const rows = orders.map((o) => {
      const userName = o.user?.name || o.guestInfo?.name || "—";
      const userEmail = o.user?.email || o.guestInfo?.email || "—";
      const date = new Date(o.createdAt).toLocaleDateString("tr-TR");
      return [
        `"${o._id}"`,
        `"${userName.replace(/"/g, '""')}"`,
        `"${userEmail.replace(/"/g, '""')}"`,
        `"${o.totalAmount ?? 0}"`,
        `"${o.status}"`,
        `"${o.paymentStatus || "—"}"`,
        `"${o.trackingNumber || "—"}"`,
        `"${o.carrier || "—"}"`,
        `"${date}"`,
      ].join(",");
    });

    const csv = [
      "Sipariş ID,Müşteri,Email,Tutar,Durum,Ödeme,Takip No,Kargo,Tarih",
      ...rows,
    ].join("\n");

    res.setHeader("Content-Type", "text/csv; charset=utf-8");
    res.setHeader("Content-Disposition", `attachment; filename="orders-${Date.now()}.csv"`);
    return res.send("\uFEFF" + csv); // BOM for Excel UTF-8
  } catch (err) {
    return sendError(res, 500, "Export başarısız", "internal_error", err.message);
  }
});

// GET /api/admin/orders?page=1&status=all|pending|processing|shipped|delivered|cancelled
router.get("/orders", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const status = req.query.status;

    const filter = {};
    const validStatuses = ["pending", "processing", "shipped", "delivered", "cancelled"];
    if (status && validStatuses.includes(status)) filter.status = status;

    const [orders, total] = await Promise.all([
      Order.find(filter)
        .populate("user", "name email")
        .select("user guestInfo totalAmount status paymentStatus items trackingNumber carrier estimatedDelivery createdAt returnRequest")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      Order.countDocuments(filter),
    ]);

    return sendOk(res, 200, { orders, total, page, hasMore: skip + orders.length < total });
  } catch (err) {
    return sendError(res, 500, "Siparişler alınamadı", "internal_error", err.message);
  }
});

// GET /api/admin/posts?page=1
router.get("/posts", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;

    const [posts, total] = await Promise.all([
      Post.find()
        .populate("userId", "name avatarUrl")
        .select("userId userName content photos likes comments isActive createdAt")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      Post.countDocuments(),
    ]);

    return sendOk(res, 200, { posts, total, page, hasMore: skip + posts.length < total });
  } catch (err) {
    return sendError(res, 500, "Gönderiler alınamadı", "internal_error", err.message);
  }
});

// PATCH /api/admin/posts/:id/hide
router.patch(
  "/posts/:id/hide",
  [param("id").isMongoId().withMessage("Geçersiz gönderi ID")],
  async (req, res) => {
    try {
      const post = await Post.findById(req.params.id);
      if (!post) return sendError(res, 404, "Gönderi bulunamadı", "post_not_found");

      post.isActive = !post.isActive;
      await post.save();

      await recordAudit("admin.post.visibility", {
        userId: req.user.sub,
        entityType: "Post",
        entityId: post._id.toString(),
        metadata: { isActive: post.isActive },
      });

      return sendOk(res, 200, {
        message: post.isActive ? "Gönderi yayında" : "Gönderi gizlendi",
        post: { id: post._id, isActive: post.isActive },
      });
    } catch (err) {
      return sendError(res, 500, "İşlem başarısız", "internal_error", err.message);
    }
  }
);

// DELETE /api/admin/posts/:id
router.delete(
  "/posts/:id",
  [param("id").isMongoId().withMessage("Geçersiz gönderi ID")],
  async (req, res) => {
    try {
      const post = await Post.findByIdAndDelete(req.params.id);
      if (!post) return sendError(res, 404, "Gönderi bulunamadı", "post_not_found");
      await recordAudit("admin.post.delete", {
        userId: req.user.sub,
        entityType: "Post",
        entityId: req.params.id,
      });
      return sendOk(res, 200, { deleted: true, id: req.params.id });
    } catch (err) {
      return sendError(res, 500, "Silme başarısız", "internal_error", err.message);
    }
  }
);

// PATCH /api/admin/users/:id/role
router.patch(
  "/users/:id/role",
  [param("id").isMongoId().withMessage("Geçersiz kullanıcı ID")],
  async (req, res) => {
    try {
      const { id } = req.params;
      const { role } = req.body;
      const allowed = ["user", "admin", "seller", "vet"];
      if (!role || !allowed.includes(role)) {
        return sendError(res, 400, `Geçersiz rol. İzin verilenler: ${allowed.join(", ")}`, "validation_error");
      }
      const user = await User.findByIdAndUpdate(
        id,
        { role },
        { new: true, select: "name email role" }
      );
      if (!user) return sendError(res, 404, "Kullanıcı bulunamadı", "not_found");
      await recordAudit("admin.user.role_change", {
        userId: req.user.sub,
        entityType: "User",
        entityId: id,
        metadata: { newRole: role },
      });
      return sendOk(res, 200, { user });
    } catch (err) {
      return sendError(res, 500, "İşlem başarısız", "internal_error");
    }
  }
);

// PATCH /api/admin/orders/:id/tracking
router.patch("/orders/:id/tracking", async (req, res) => {
  try {
    const { trackingNumber, carrier, estimatedDelivery } = req.body;
    const order = await Order.findById(req.params.id).populate("user", "_id");
    if (!order) return sendError(res, 404, "Sipariş bulunamadı.");

    const prevStatus = order.status;
    if (trackingNumber !== undefined) order.trackingNumber = trackingNumber;
    if (carrier !== undefined) order.carrier = carrier;
    if (estimatedDelivery !== undefined) order.estimatedDelivery = estimatedDelivery ? new Date(estimatedDelivery) : undefined;

    // Kargo bilgisi girilince processing → shipped otomatik geçiş
    if (trackingNumber && order.status === "processing") order.status = "shipped";

    // Durum geçmişine kayıt
    if (order.status !== prevStatus || trackingNumber) {
      order.statusHistory = order.statusHistory || [];
      order.statusHistory.push({
        status: order.status,
        note: trackingNumber
          ? `${carrier || 'Kargo'} - Takip No: ${trackingNumber}`
          : `Durum güncellendi: ${order.status}`,
        updatedAt: new Date(),
      });
    }

    await order.save();

    // Socket.io — uygulama açıkken anlık güncelleme
    const io = req.app.get("io");
    if (io && order.user?._id) {
      io.to(`user:${String(order.user._id)}`).emit("order:status_update", {
        orderId: String(order._id),
        status: order.status,
        trackingNumber: order.trackingNumber,
        carrier: order.carrier,
        estimatedDelivery: order.estimatedDelivery,
      });
    }

    // FCM push — uygulama kapalıyken bildirim
    if (order.user?._id && trackingNumber) {
      sendPush(order.user._id, {
        title: "Siparişiniz Kargoya Verildi",
        body: `${carrier || "Kargo"} - Takip No: ${trackingNumber}`,
        data: { type: "order_shipped", orderId: order._id.toString() },
      }).catch(() => {});
    }

    return sendOk(res, 200, { order });
  } catch (err) {
    return sendError(res, 500, "İşlem başarısız", "internal_error", err.message);
  }
});

// GET /api/admin/coupons?page=1&status=active|expired|all
router.get("/coupons", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const filter = {};
    if (req.query.status === "active") filter.isActive = true;
    if (req.query.status === "expired") filter.validUntil = { $lt: new Date() };
    const [coupons, total] = await Promise.all([
      Coupon.find(filter)
        .populate("seller", "name email")
        .populate("store", "name")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      Coupon.countDocuments(filter),
    ]);
    return sendOk(res, 200, { coupons, total, page, hasMore: skip + coupons.length < total });
  } catch (err) {
    return sendError(res, 500, "Kuponlar alınamadı", "internal_error", err.message);
  }
});

// POST /api/admin/coupons
router.post("/coupons", async (req, res) => {
  try {
    const {
      code, description, discountType, discountValue,
      minPurchaseAmount, maxDiscountAmount, validFrom, validUntil,
      usageLimit, perUserLimit, firstOrderOnly,
      store, applicableCategories,
    } = req.body;
    if (!code || !discountType || !discountValue || !validFrom || !validUntil)
      return sendError(res, 400, "Zorunlu alanlar eksik.");
    if (!["percentage", "fixed"].includes(discountType)) {
      return sendError(res, 400, "Gecersiz indirim tipi", "validation_error");
    }
    if (Number(discountValue) <= 0) {
      return sendError(res, 400, "Indirim degeri 0'dan buyuk olmali", "validation_error");
    }
    if (discountType === "percentage" && Number(discountValue) > 100) {
      return sendError(res, 400, "Yuzde indirimi 100'u gecemez", "validation_error");
    }
    if (minPurchaseAmount !== undefined && Number(minPurchaseAmount) < 0) {
      return sendError(res, 400, "Minimum tutar negatif olamaz", "validation_error");
    }
    if (maxDiscountAmount !== undefined && Number(maxDiscountAmount) < 0) {
      return sendError(res, 400, "Maksimum indirim negatif olamaz", "validation_error");
    }
    if (usageLimit !== undefined && Number(usageLimit) < 1) {
      return sendError(res, 400, "Kullanim limiti en az 1 olmali", "validation_error");
    }
    if (perUserLimit !== undefined && Number(perUserLimit) < 1) {
      return sendError(res, 400, "Kisi basi limit en az 1 olmali", "validation_error");
    }
    const fromDate = new Date(validFrom);
    const untilDate = new Date(validUntil);
    if (Number.isNaN(fromDate.getTime()) || Number.isNaN(untilDate.getTime()) || untilDate < fromDate) {
      return sendError(res, 400, "Bitis tarihi baslangictan sonra olmali", "validation_error");
    }
    const coupon = await Coupon.create({
      code: code.toUpperCase(),
      description,
      discountType,
      discountValue: Number(discountValue),
      minPurchaseAmount: minPurchaseAmount ? Number(minPurchaseAmount) : 0,
      maxDiscountAmount: maxDiscountAmount ? Number(maxDiscountAmount) : undefined,
      validFrom: fromDate,
      validUntil: (() => { const d = new Date(untilDate); d.setHours(23, 59, 59, 999); return d; })(),
      usageLimit: usageLimit ? Number(usageLimit) : undefined,
      perUserLimit: perUserLimit ? Number(perUserLimit) : 1,
      firstOrderOnly: firstOrderOnly || false,
      store: store || undefined,
      applicableCategories: Array.isArray(applicableCategories) && applicableCategories.length > 0
        ? applicableCategories : undefined,
    });
    return sendOk(res, 201, { coupon });
  } catch (err) {
    if (err.code === 11000) return sendError(res, 409, "Bu kupon kodu zaten kullanılıyor.");
    return sendError(res, 500, "Kupon oluşturulamadı", "internal_error", err.message);
  }
});

// PATCH /api/admin/coupons/:id  — kupon güncelleme
router.patch("/coupons/:id", async (req, res) => {
  try {
    const { id } = req.params;
    if (!id.match(/^[a-f\d]{24}$/i)) return sendError(res, 400, "Geçersiz kupon ID", "validation_error");
    const allowed = ["code", "description", "discountType", "discountValue",
      "minPurchaseAmount", "maxDiscountAmount", "validFrom", "validUntil",
      "usageLimit", "perUserLimit", "firstOrderOnly", "store", "applicableCategories"];
    const update = {};
    for (const key of allowed) {
      if (req.body[key] !== undefined) update[key] = req.body[key];
    }
    if (update.discountType && !["percentage", "fixed"].includes(update.discountType)) {
      return sendError(res, 400, "Gecersiz indirim tipi", "validation_error");
    }
    if (update.discountValue !== undefined && Number(update.discountValue) <= 0) {
      return sendError(res, 400, "Indirim degeri 0'dan buyuk olmali", "validation_error");
    }
    if (update.discountType === "percentage" && update.discountValue !== undefined && Number(update.discountValue) > 100) {
      return sendError(res, 400, "Yuzde indirimi 100'u gecemez", "validation_error");
    }
    if (update.minPurchaseAmount !== undefined && Number(update.minPurchaseAmount) < 0) {
      return sendError(res, 400, "Minimum tutar negatif olamaz", "validation_error");
    }
    if (update.maxDiscountAmount !== undefined && Number(update.maxDiscountAmount) < 0) {
      return sendError(res, 400, "Maksimum indirim negatif olamaz", "validation_error");
    }
    if (update.usageLimit !== undefined && Number(update.usageLimit) < 1) {
      return sendError(res, 400, "Kullanim limiti en az 1 olmali", "validation_error");
    }
    if (update.perUserLimit !== undefined && Number(update.perUserLimit) < 1) {
      return sendError(res, 400, "Kisi basi limit en az 1 olmali", "validation_error");
    }
    if (update.code) update.code = String(update.code).toUpperCase().trim();
    if (update.validUntil) { const d = new Date(update.validUntil); d.setHours(23, 59, 59, 999); update.validUntil = d; }
    if (update.validFrom && Number.isNaN(new Date(update.validFrom).getTime())) {
      return sendError(res, 400, "Gecersiz baslangic tarihi", "validation_error");
    }
    if (update.validUntil && Number.isNaN(new Date(update.validUntil).getTime())) {
      return sendError(res, 400, "Gecersiz bitis tarihi", "validation_error");
    }
    const coupon = await Coupon.findByIdAndUpdate(id, update, { new: true, runValidators: true });
    if (!coupon) return sendError(res, 404, "Kupon bulunamadı", "not_found");
    return sendOk(res, 200, { coupon });
  } catch (err) {
    return sendError(res, 500, "Kupon güncellenemedi", "internal_error");
  }
});

// PATCH /api/admin/coupons/:id/toggle
router.patch("/coupons/:id/toggle", async (req, res) => {
  try {
    const coupon = await Coupon.findById(req.params.id);
    if (!coupon) return sendError(res, 404, "Kupon bulunamadı.");
    coupon.isActive = !coupon.isActive;
    await coupon.save();
    return sendOk(res, 200, { coupon });
  } catch (err) {
    return sendError(res, 500, "İşlem başarısız", "internal_error", err.message);
  }
});

// DELETE /api/admin/coupons/:id
router.delete("/coupons/:id", async (req, res) => {
  try {
    const coupon = await Coupon.findByIdAndDelete(req.params.id);
    if (!coupon) return sendError(res, 404, "Kupon bulunamad?.");
    await recordAudit("admin.coupon.delete", {
      userId: req.user.sub,
      entityType: "Coupon",
      entityId: coupon._id.toString(),
      metadata: { code: coupon.code },
    });
    return sendOk(res, 200, { message: "Kupon silindi." });
  } catch (err) {
    return sendError(res, 500, "??lem ba?ar?s?z", "internal_error", err.message);
  }
});

// GET /api/admin/stores — kupon formu için tüm mağaza listesi
router.get("/stores", async (req, res) => {
  try {
    const stores = await Store.find({}).select("_id name").sort({ name: 1 }).limit(200);
    return sendOk(res, 200, { stores });
  } catch (err) {
    return sendError(res, 500, "Mağazalar alınamadı", "internal_error", err.message);
  }
});

// GET /api/admin/support?page=1&status=open|reviewing|closed
router.get("/support", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const filter = {};
    if (["open", "reviewing", "closed"].includes(req.query.status)) filter.status = req.query.status;
    const [tickets, total] = await Promise.all([
      SupportTicket.find(filter)
        .populate("userId", "name email avatarUrl")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      SupportTicket.countDocuments(filter),
    ]);
    return sendOk(res, 200, { tickets, total, page });
  } catch (err) {
    return sendError(res, 500, "Destek ticketları alınamadı.", "internal_error", err.message);
  }
});

// PATCH /api/admin/support/:id
router.patch("/support/:id", async (req, res) => {
  try {
    const { status, adminNote } = req.body;
    const allowed = ["open", "reviewing", "closed"];
    if (status && !allowed.includes(status)) return sendError(res, 400, "Ge?ersiz durum.");
    if (adminNote !== undefined && typeof adminNote !== "string") {
      return sendError(res, 400, "Admin notu metin olmali", "validation_error");
    }
    const trimmedAdminNote = typeof adminNote === "string" ? adminNote.trim() : adminNote;
    if (typeof trimmedAdminNote === "string" && trimmedAdminNote.length > 500) {
      return sendError(res, 400, "Admin notu en fazla 500 karakter olabilir", "validation_error");
    }
    const ticket = await SupportTicket.findById(req.params.id);
    if (!ticket) return sendError(res, 404, "Ticket bulunamad?.");
    if (status) ticket.status = status;
    if (trimmedAdminNote !== undefined) ticket.adminNote = trimmedAdminNote;
    await ticket.save();
    return sendOk(res, 200, { ticket });
  } catch (err) {
    return sendError(res, 500, "??lem ba?ar?s?z.", "internal_error", err.message);
  }
});

// GET /api/admin/coupons/:id/usage?page=1
// Bir kuponu kim, ne zaman, hangi sipariş üzerinden kullandı?
router.get("/coupons/:id/usage", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const couponId = req.params.id;

    const [usages, total, coupon] = await Promise.all([
      CouponUsage.find({ couponId })
        .populate("userId", "name email avatarUrl")
        .populate("orderId", "totalAmount originalAmount status createdAt")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      CouponUsage.aggregate([
        { $match: { couponId: new mongoose.Types.ObjectId(couponId) } },
        { $group: { _id: null, total: { $sum: "$count" } } },
      ]),
      Coupon.findById(couponId).select("code discountType discountValue usageCount usageLimit"),
    ]);

    if (!coupon) return sendError(res, 404, "Kupon bulunamadı.");
    await recordAudit("admin.coupon.delete", {
      userId: req.user.sub,
      entityType: "Coupon",
      entityId: coupon._id.toString(),
      metadata: { code: coupon.code },
    });

    // Toplam kazandırılan indirim tutarı
    const totalDiscount = await CouponUsage.aggregate([
      { $match: { couponId: coupon._id } },
      { $group: { _id: null, total: { $sum: "$discountAmount" } } },
    ]);

    return sendOk(res, 200, {
      coupon,
      usages,
      total: total[0]?.total ?? 0,
      page,
      totalDiscountGiven: totalDiscount[0]?.total ?? 0,
    });
  } catch (err) {
    return sendError(res, 500, "Kullanım geçmişi alınamadı", "internal_error", err.message);
  }
});

// === VETERİNER YÖNETİMİ ===

// GET /api/admin/vets?page=1
router.get("/vets", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const [vets, total] = await Promise.all([
      Veterinary.find()
        .select("name address phone photos googlePlaceId googleRating googleReviewCount isVerified isActive userId source createdAt")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      Veterinary.countDocuments(),
    ]);
    return sendOk(res, 200, { vets, total, page });
  } catch (err) {
    return sendError(res, 500, "Veterinerler alinamadi", "internal_error", err.message);
  }
});

router.get("/vets/:id/insights", async (req, res) => {
  try {
    const vetId = req.params.id;
    if (!mongoose.Types.ObjectId.isValid(vetId)) {
      return sendError(res, 400, "Gecersiz veteriner ID", "validation_error");
    }

    const [vet, reviewStatsRaw, recentReviews, appointmentStatsRaw, upcomingAppointments] =
      await Promise.all([
        Veterinary.findById(vetId).populate("userId", "name email avatarUrl"),
        VetReview.aggregate([
          { $match: { vet: new mongoose.Types.ObjectId(vetId) } },
          {
            $group: {
              _id: null,
              averageRating: { $avg: "$rating" },
              reviewCount: { $sum: 1 },
            },
          },
        ]),
        VetReview.find({ vet: vetId })
          .populate("user", "name email avatarUrl")
          .sort({ createdAt: -1 })
          .limit(5)
          .lean(),
        Appointment.aggregate([
          { $match: { veterinaryId: new mongoose.Types.ObjectId(vetId) } },
          {
            $group: {
              _id: "$status",
              count: { $sum: 1 },
            },
          },
        ]),
        Appointment.find({
          veterinaryId: vetId,
          date: { $gte: new Date() },
          status: { $in: ["pending", "confirmed"] },
        })
          .sort({ date: 1 })
          .limit(5)
          .populate("userId", "name email")
          .populate("petId", "name species")
          .lean(),
      ]);

    if (!vet) return sendError(res, 404, "Veteriner bulunamadi", "not_found");

    const reviewStats = reviewStatsRaw?.[0] || {};
    const appointmentStats = {
      total: 0,
      pending: 0,
      confirmed: 0,
      completed: 0,
      cancelled: 0,
      no_show: 0,
    };
    for (const item of appointmentStatsRaw || []) {
      appointmentStats[item._id] = item.count || 0;
      appointmentStats.total += item.count || 0;
    }

    return sendOk(res, 200, {
      vet,
      insights: {
        reviewStats: {
          averageRating: Math.round((reviewStats.averageRating || 0) * 10) / 10,
          reviewCount: reviewStats.reviewCount || 0,
        },
        recentReviews: recentReviews.map((review) => ({
          _id: review._id,
          rating: review.rating,
          comment: review.comment || "",
          createdAt: review.createdAt,
          user: review.user
            ? {
                name: review.user.name,
                email: review.user.email,
                avatarUrl: review.user.avatarUrl,
              }
            : null,
        })),
        appointmentStats,
        upcomingAppointments: upcomingAppointments.map((appointment) => ({
          _id: appointment._id,
          date: appointment.date,
          status: appointment.status,
          type: appointment.type,
          user: appointment.userId
            ? {
                name: appointment.userId.name,
                email: appointment.userId.email,
              }
            : null,
          pet: appointment.petId
            ? {
                name: appointment.petId.name,
                species: appointment.petId.species,
              }
            : null,
        })),
      },
    });
  } catch (err) {
    return sendError(res, 500, "Veteriner detaylari alinamadi", "internal_error", err.message);
  }
});

// GET /api/admin/vet-claims?page=1&status=pending|approved|rejected
router.get("/vet-claims", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const filter = {};
    if (["pending", "approved", "rejected"].includes(req.query.status)) filter.status = req.query.status;
    else filter.status = "pending";
    const [claims, total] = await Promise.all([
      VetClaimRequest.find(filter)
        .populate("vetId", "name address phone isVerified")
        .populate("userId", "name email avatarUrl")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      VetClaimRequest.countDocuments(filter),
    ]);
    return sendOk(res, 200, { claims, total, page });
  } catch (err) {
    return sendError(res, 500, "Talepler alinamadi", "internal_error", err.message);
  }
});

// PATCH /api/admin/vet-claims/:id/review
// body: { action: "approved"|"rejected", adminNote? }
router.patch("/vet-claims/:id/review", async (req, res) => {
  try {
    const { action, adminNote } = req.body;
    if (!["approved", "rejected"].includes(action)) {
      return sendError(res, 400, "action 'approved' veya 'rejected' olmali", "validation_error");
    }
    const trimmedAdminNote = typeof adminNote === "string" ? adminNote.trim() : "";
    if (action === "rejected" && !trimmedAdminNote) {
      return sendError(res, 400, "Reddetme icin admin notu zorunlu", "validation_error");
    }
    const claim = await VetClaimRequest.findById(req.params.id);
    if (!claim) return sendError(res, 404, "Talep bulunamadi", "not_found");
    if (claim.status !== "pending") {
      return sendError(res, 409, "Bu talep zaten incelendi", "already_reviewed");
    }

    claim.status = action;
    claim.adminNote = trimmedAdminNote;
    claim.reviewedBy = req.user.sub;
    claim.reviewedAt = new Date();
    await claim.save();

    if (action === "approved") {
      // Vet profiline userId ata ve doğrula
      await Veterinary.findByIdAndUpdate(claim.vetId, {
        userId: claim.userId,
        isVerified: true,
      });
      // Admin kullaniciyi vet'e dusurme; diger hesaplar vet olabilir.
      const claimantUser = await User.findById(claim.userId).select("role");
      if (claimantUser && claimantUser.role !== "admin") {
        await User.findByIdAndUpdate(claim.userId, { role: "vet" });
      }
    }

    await recordAudit("admin.vet_claim.review", {
      userId: req.user.sub,
      entityType: "VetClaimRequest",
      entityId: claim._id.toString(),
      metadata: { action, vetId: claim.vetId?.toString() },
    });

    return sendOk(res, 200, { claim, message: action === "approved" ? "Talep onaylandi" : "Talep reddedildi" });
  } catch (err) {
    return sendError(res, 500, "Inceleme basarisiz", "internal_error", err.message);
  }
});

// === BAKICI YÖNETİMİ ===

// GET /api/admin/pet-sitters?page=1&verified=all|true|false
router.get("/pet-sitters", async (req, res) => {
  try {
    const { verified = "all" } = req.query;
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const filter = {};
    if (verified === "true") filter.isVerified = true;
    if (verified === "false") filter.isVerified = false;
    const [sitters, total] = await Promise.all([
      PetSitter.find(filter)
        .populate("userId", "name email avatarUrl")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      PetSitter.countDocuments(filter),
    ]);
    return sendOk(res, 200, { sitters, total, page });
  } catch (err) {
    return sendError(res, 500, "Bakicilar alinamadi", "internal_error", err.message);
  }
});

router.get("/pet-sitters/:id/insights", async (req, res) => {
  try {
    const sitterId = req.params.id;
    if (!mongoose.Types.ObjectId.isValid(sitterId)) {
      return sendError(res, 400, "Gecersiz bakici ID", "validation_error");
    }

    const [sitter, statsRaw, serviceBreakdownRaw, recentReviews] = await Promise.all([
      PetSitter.findById(sitterId).populate("userId", "name email avatarUrl"),
      SitterBooking.aggregate([
        { $match: { sitterId: new mongoose.Types.ObjectId(sitterId) } },
        {
          $group: {
            _id: null,
            totalBookings: { $sum: 1 },
            pending: { $sum: { $cond: [{ $eq: ["$status", "pending"] }, 1, 0] } },
            accepted: { $sum: { $cond: [{ $eq: ["$status", "accepted"] }, 1, 0] } },
            active: { $sum: { $cond: [{ $eq: ["$status", "active"] }, 1, 0] } },
            completed: { $sum: { $cond: [{ $eq: ["$status", "completed"] }, 1, 0] } },
            cancelled: { $sum: { $cond: [{ $eq: ["$status", "cancelled"] }, 1, 0] } },
            rejected: { $sum: { $cond: [{ $eq: ["$status", "rejected"] }, 1, 0] } },
            totalRevenue: {
              $sum: {
                $cond: [
                  { $eq: ["$status", "completed"] },
                  { $ifNull: ["$earnings.payableAmount", "$totalPrice"] },
                  0,
                ],
              },
            },
          },
        },
      ]),
      SitterBooking.aggregate([
        { $match: { sitterId: new mongoose.Types.ObjectId(sitterId) } },
        {
          $group: {
            _id: "$serviceType",
            count: { $sum: 1 },
          },
        },
        { $sort: { count: -1 } },
      ]),
      SitterBooking.find({
        sitterId,
        "ownerReview.rating": { $exists: true },
      })
        .populate("petOwnerId", "name email avatarUrl")
        .sort({ updatedAt: -1 })
        .limit(5)
        .lean(),
    ]);

    if (!sitter) return sendError(res, 404, "Bakici bulunamadi", "not_found");

    const stats = statsRaw?.[0] || {};
    const monthlyRevenue = await SitterBooking.aggregate([
      {
        $match: {
          sitterId: new mongoose.Types.ObjectId(sitterId),
          status: "completed",
          completedAt: {
            $gte: new Date(Date.UTC(new Date().getUTCFullYear(), new Date().getUTCMonth(), 1)),
          },
        },
      },
      {
        $group: {
          _id: null,
          total: {
            $sum: { $ifNull: ["$earnings.payableAmount", "$totalPrice"] },
          },
        },
      },
    ]);

    return sendOk(res, 200, {
      sitter,
      insights: {
        performance: {
          totalBookings: stats.totalBookings || 0,
          pending: stats.pending || 0,
          accepted: stats.accepted || 0,
          active: stats.active || 0,
          completed: stats.completed || 0,
          cancelled: stats.cancelled || 0,
          rejected: stats.rejected || 0,
          totalRevenue: Math.round((stats.totalRevenue || 0) * 100) / 100,
          monthlyRevenue: Math.round((monthlyRevenue?.[0]?.total || 0) * 100) / 100,
        },
        serviceBreakdown: (serviceBreakdownRaw || []).map((item) => ({
          serviceType: item._id,
          count: item.count || 0,
        })),
        recentReviews: recentReviews.map((booking) => ({
          _id: booking._id,
          rating: booking.ownerReview?.rating || 0,
          comment: booking.ownerReview?.comment || "",
          createdAt: booking.ownerReview?.createdAt || booking.updatedAt,
          owner: booking.petOwnerId
            ? {
                name: booking.petOwnerId.name,
                email: booking.petOwnerId.email,
                avatarUrl: booking.petOwnerId.avatarUrl,
              }
            : null,
          serviceType: booking.serviceType,
          totalPrice: booking.totalPrice || 0,
        })),
      },
    });
  } catch (err) {
    return sendError(res, 500, "Bakici detaylari alinamadi", "internal_error", err.message);
  }
});

// PATCH /api/admin/pet-sitters/:id/verify
router.patch("/pet-sitters/:id/verify", async (req, res) => {
  try {
    const { isVerified } = req.body;
    const sitter = await PetSitter.findByIdAndUpdate(
      req.params.id,
      { isVerified: Boolean(isVerified) },
      { new: true }
    ).populate("userId", "name email");
    if (!sitter) return sendError(res, 404, "Bakici bulunamadi", "not_found");
    return sendOk(res, 200, { sitter });
  } catch (err) {
    return sendError(res, 500, "Guncellenemedi", "internal_error", err.message);
  }
});

// PATCH /api/admin/vets/:id/verify — Veteriner onaylama/reddetme (KRİTİK: Admin paneli bunu çağırıyor)
router.patch("/vets/:id/verify", async (req, res) => {
  try {
    const { isVerified } = req.body;
    const vet = await Veterinary.findByIdAndUpdate(
      req.params.id,
      { isVerified: Boolean(isVerified) },
      { new: true }
    ).select("name address phone isVerified isActive userId");
    if (!vet) return sendError(res, 404, "Veteriner bulunamadi", "not_found");

    await recordAudit("admin.vet.verify", {
      userId: req.user.sub,
      entityType: "Veterinary",
      entityId: vet._id.toString(),
      metadata: { isVerified: Boolean(isVerified) },
    });

    return sendOk(res, 200, { vet });
  } catch (err) {
    return sendError(res, 500, "Guncellenemedi", "internal_error", err.message);
  }
});

// PATCH /api/admin/pet-sitters/:id/ban — Bakıcı banlama
router.patch("/pet-sitters/:id/ban", async (req, res) => {
  try {
    const { isBanned, reason } = req.body;
    // isBanned=true → isActive=false (hesabı devre dışı bırak)
    const sitter = await PetSitter.findByIdAndUpdate(
      req.params.id,
      { isActive: !Boolean(isBanned) },
      { new: true }
    ).populate("userId", "name email avatarUrl");
    if (!sitter) return sendError(res, 404, "Bakici bulunamadi", "not_found");

    await recordAudit("admin.sitter.ban", {
      userId: req.user.sub,
      entityType: "PetSitter",
      entityId: sitter._id.toString(),
      metadata: { isBanned: Boolean(isBanned), reason },
    });

    return sendOk(res, 200, { sitter });
  } catch (err) {
    return sendError(res, 500, "Guncellenemedi", "internal_error", err.message);
  }
});

// GET /api/admin/walk-updates?page=1 — Yürüyüş güncellemelerini listele
router.get("/walk-updates", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const [updates, total] = await Promise.all([
      WalkUpdate.find()
        .populate({ path: "bookingId", select: "serviceType startDate status petOwnerId", populate: { path: "petOwnerId", select: "name email" } })
        .sort({ timestamp: -1 })
        .skip(skip)
        .limit(limit),
      WalkUpdate.countDocuments(),
    ]);
    return sendOk(res, 200, { updates, total, page });
  } catch (err) {
    return sendError(res, 500, "Walk güncellemeleri alinamadi", "internal_error", err.message);
  }
});

// GET /api/admin/care-reports?page=1 — Bakım raporlarını listele
router.get("/care-reports", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const [reports, total] = await Promise.all([
      CareReport.find()
        .populate({ path: "bookingId", select: "serviceType startDate status petOwnerId", populate: { path: "petOwnerId", select: "name email" } })
        .sort({ timestamp: -1 })
        .skip(skip)
        .limit(limit),
      CareReport.countDocuments(),
    ]);
    return sendOk(res, 200, { reports, total, page });
  } catch (err) {
    return sendError(res, 500, "Bakim raporlari alinamadi", "internal_error", err.message);
  }
});

// GET /api/admin/sitter-bookings?page=1&status= — Rezervasyonları listele
router.get("/sitter-bookings", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const filter = {};
    if (req.query.status) filter.status = req.query.status;
    const [bookings, total] = await Promise.all([
      SitterBooking.find(filter)
        .populate("petOwnerId", "name email avatarUrl")
        .populate("sitterUserId", "name email avatarUrl")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      SitterBooking.countDocuments(filter),
    ]);
    return sendOk(res, 200, { bookings, total, page });
  } catch (err) {
    return sendError(res, 500, "Rezervasyonlar alinamadi", "internal_error", err.message);
  }
});

// GET /api/admin/users/:id/sensitive — TC + telefon şifre ile açılır
router.get("/users/:id/sensitive", sensitiveDataLimiter, authRequired(["admin"]), async (req, res) => {
  try {
    const adminPass = req.headers["x-admin-data-password"];
    if (!adminPass || adminPass !== process.env.ADMIN_DATA_PASSWORD) {
      return sendError(res, 403, "Ek yetki gerekli", "extra_auth_required");
    }
    const user = await User.findById(req.params.id).select("+nationalId +phone");
    if (!user) return sendError(res, 404, "Kullanici bulunamadi", "not_found");
    return sendOk(res, 200, {
      phone: user.phone || null,
      nationalId: user.nationalId ? decrypt(user.nationalId) : null,
    });
  } catch (err) {
    return sendError(res, 500, "Veriler alinamadi", "internal_error", err.message);
  }
});

// GET /api/admin/orders/:id/guest-sensitive — misafir TC şifre ile açılır
router.get("/orders/:id/guest-sensitive", sensitiveDataLimiter, authRequired(["admin"]), async (req, res) => {
  try {
    const adminPass = req.headers["x-admin-data-password"];
    if (!adminPass || adminPass !== process.env.ADMIN_DATA_PASSWORD) {
      return sendError(res, 403, "Ek yetki gerekli", "extra_auth_required");
    }
    const order = await Order.findById(req.params.id).select("guestInfo");
    if (!order) return sendError(res, 404, "Siparis bulunamadi", "not_found");
    return sendOk(res, 200, {
      name: order.guestInfo?.name,
      phone: order.guestInfo?.phone,
      email: order.guestInfo?.email,
      nationalId: order.guestInfo?.nationalId ? decrypt(order.guestInfo.nationalId) : null,
    });
  } catch (err) {
    return sendError(res, 500, "Veriler alinamadi", "internal_error", err.message);
  }
});

// PATCH /api/admin/orders/:id/return-status
// body: { status: "approved"|"rejected", note? }
import { resolveReturnRequest } from "../controllers/orderController.js";
router.patch("/orders/:id/return-status", async (req, res) => {
  return resolveReturnRequest(req, res);
});

// GET /api/admin/orders/returns  — İade talep listesi (admin)
router.get("/orders/returns", async (req, res) => {
  try {
    const pagination = getPagination(req, res, { defaultLimit: 20, maxLimit: 20 });
    if (!pagination) return;
    const { page, limit, skip } = pagination;
    const statusFilter = req.query.status;
    const filter = { 'returnRequest': { $exists: true, $ne: null } };
    if (statusFilter && ['pending', 'approved', 'rejected'].includes(statusFilter)) {
      filter['returnRequest.status'] = statusFilter;
    }
    const [returns, total] = await Promise.all([
      Order.find(filter)
        .populate('user', 'name email avatarUrl')
        .select('_id user guestInfo items totalAmount createdAt returnRequest status')
        .sort({ 'returnRequest.requestedAt': -1 })
        .skip(skip)
        .limit(limit),
      Order.countDocuments(filter),
    ]);
    return sendOk(res, 200, { returns, total, page });
  } catch (err) {
    return sendError(res, 500, 'İade talepleri alınamadı', 'internal_error', err.message);
  }
});

export default router;
