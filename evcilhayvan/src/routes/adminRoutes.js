// src/routes/adminRoutes.js
import { Router } from "express";
import { param, query } from "express-validator";
import mongoose from "mongoose";
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
import VetClaimRequest from "../models/VetClaimRequest.js";
import Veterinary from "../models/Veterinary.js";
import Store from "../models/Store.js";
import { sendPush } from "../utils/fcm.js";
import { recordAudit } from "../utils/audit.js";
import { decrypt, maskNationalId } from "../utils/fieldCrypto.js";

const router = Router();

// Tüm admin endpointleri admin rolü gerektirir
router.use(authRequired(["admin"]));

// GET /api/admin/stats
router.get("/stats", async (req, res) => {
  try {
    const now = new Date();
    const [
      totalUsers,
      newUsersThisMonth,
      totalPets,
      activePets,
      totalOrders,
      pendingReports,
      totalActiveCoupons,
      openSupportTickets,
    ] = await Promise.all([
      User.countDocuments(),
      User.countDocuments({
        createdAt: { $gte: new Date(new Date().setDate(1)) },
      }),
      Pet.countDocuments(),
      Pet.countDocuments({ isActive: true }),
      Order.countDocuments().catch(() => 0),
      UserReport.countDocuments({ status: "pending" }),
      Coupon.countDocuments({ isActive: true, validUntil: { $gte: now } }).catch(() => 0),
      SupportTicket.countDocuments({ status: "open" }).catch(() => 0),
    ]);

    return sendOk(res, 200, {
      stats: {
        totalUsers,
        newUsersThisMonth,
        totalPets,
        activePets,
        totalOrders,
        pendingReports,
        totalActiveCoupons,
        openSupportTickets,
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

// GET /api/admin/orders?page=1&status=all|pending|processing|shipped|delivered|cancelled
router.get("/orders", async (req, res) => {
  try {
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = 20;
    const skip = (page - 1) * limit;
    const status = req.query.status;

    const filter = {};
    const validStatuses = ["pending", "processing", "shipped", "delivered", "cancelled"];
    if (status && validStatuses.includes(status)) filter.status = status;

    const [orders, total] = await Promise.all([
      Order.find(filter)
        .populate("user", "name email")
        .select("user totalAmount status paymentStatus items trackingNumber carrier estimatedDelivery createdAt")
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
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = 20;
    const skip = (page - 1) * limit;

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
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = 20;
    const filter = {};
    if (req.query.status === "active") filter.isActive = true;
    if (req.query.status === "expired") filter.validUntil = { $lt: new Date() };
    const [coupons, total] = await Promise.all([
      Coupon.find(filter)
        .populate("seller", "name email")
        .populate("store", "name")
        .sort({ createdAt: -1 })
        .skip((page - 1) * limit)
        .limit(limit),
      Coupon.countDocuments(filter),
    ]);
    return sendOk(res, 200, { coupons, total, page });
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
    const coupon = await Coupon.create({
      code: code.toUpperCase(),
      description,
      discountType,
      discountValue: Number(discountValue),
      minPurchaseAmount: minPurchaseAmount ? Number(minPurchaseAmount) : 0,
      maxDiscountAmount: maxDiscountAmount ? Number(maxDiscountAmount) : undefined,
      validFrom: new Date(validFrom),
      validUntil: (() => { const d = new Date(validUntil); d.setHours(23, 59, 59, 999); return d; })(),
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
    if (update.code) update.code = String(update.code).toUpperCase().trim();
    if (update.validUntil) { const d = new Date(update.validUntil); d.setHours(23, 59, 59, 999); update.validUntil = d; }
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
    if (!coupon) return sendError(res, 404, "Kupon bulunamadı.");
    return sendOk(res, 200, { message: "Kupon silindi." });
  } catch (err) {
    return sendError(res, 500, "İşlem başarısız", "internal_error", err.message);
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
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = 20;
    const filter = {};
    if (["open", "reviewing", "closed"].includes(req.query.status)) filter.status = req.query.status;
    const [tickets, total] = await Promise.all([
      SupportTicket.find(filter)
        .populate("userId", "name email avatarUrl")
        .sort({ createdAt: -1 })
        .skip((page - 1) * limit)
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
    if (status && !allowed.includes(status)) return sendError(res, 400, "Geçersiz durum.");
    const ticket = await SupportTicket.findById(req.params.id);
    if (!ticket) return sendError(res, 404, "Ticket bulunamadı.");
    if (status) ticket.status = status;
    if (adminNote !== undefined) ticket.adminNote = adminNote;
    await ticket.save();
    return sendOk(res, 200, { ticket });
  } catch (err) {
    return sendError(res, 500, "İşlem başarısız.", "internal_error", err.message);
  }
});

// GET /api/admin/coupons/:id/usage?page=1
// Bir kuponu kim, ne zaman, hangi sipariş üzerinden kullandı?
router.get("/coupons/:id/usage", async (req, res) => {
  try {
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = 20;
    const couponId = req.params.id;

    const [usages, total, coupon] = await Promise.all([
      CouponUsage.find({ couponId })
        .populate("userId", "name email avatarUrl")
        .populate("orderId", "totalAmount originalAmount status createdAt")
        .sort({ createdAt: -1 })
        .skip((page - 1) * limit)
        .limit(limit),
      CouponUsage.countDocuments({ couponId }),
      Coupon.findById(couponId).select("code discountType discountValue usageCount usageLimit"),
    ]);

    if (!coupon) return sendError(res, 404, "Kupon bulunamadı.");

    // Toplam kazandırılan indirim tutarı
    const totalDiscount = await CouponUsage.aggregate([
      { $match: { couponId: coupon._id } },
      { $group: { _id: null, total: { $sum: "$discountAmount" } } },
    ]);

    return sendOk(res, 200, {
      coupon,
      usages,
      total,
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
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = 20;
    const skip = (page - 1) * limit;
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

// GET /api/admin/vet-claims?page=1&status=pending|approved|rejected
router.get("/vet-claims", async (req, res) => {
  try {
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = 20;
    const filter = {};
    if (["pending", "approved", "rejected"].includes(req.query.status)) filter.status = req.query.status;
    else filter.status = "pending";
    const [claims, total] = await Promise.all([
      VetClaimRequest.find(filter)
        .populate("vetId", "name address phone isVerified")
        .populate("userId", "name email avatarUrl")
        .sort({ createdAt: -1 })
        .skip((page - 1) * limit)
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
    const claim = await VetClaimRequest.findById(req.params.id);
    if (!claim) return sendError(res, 404, "Talep bulunamadi", "not_found");
    if (claim.status !== "pending") {
      return sendError(res, 409, "Bu talep zaten incelendi", "already_reviewed");
    }

    claim.status = action;
    claim.adminNote = adminNote || "";
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
    const { page = 1, verified = "all" } = req.query;
    const filter = {};
    if (verified === "true") filter.isVerified = true;
    if (verified === "false") filter.isVerified = false;
    const limit = 20;
    const skip = (Number(page) - 1) * limit;
    const [sitters, total] = await Promise.all([
      PetSitter.find(filter)
        .populate("userId", "name email avatarUrl")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      PetSitter.countDocuments(filter),
    ]);
    return sendOk(res, 200, { sitters, total, page: Number(page) });
  } catch (err) {
    return sendError(res, 500, "Bakicilar alinamadi", "internal_error", err.message);
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

// GET /api/admin/users/:id/sensitive — TC + telefon şifre ile açılır
router.get("/users/:id/sensitive", authRequired(["admin"]), async (req, res) => {
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
router.get("/orders/:id/guest-sensitive", authRequired(["admin"]), async (req, res) => {
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

export default router;
