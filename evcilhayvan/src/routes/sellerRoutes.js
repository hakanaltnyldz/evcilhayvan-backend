import { Router } from "express";
import { randomBytes } from "crypto";
import multer from "multer";
import path from "path";
import fs from "fs";
import mongoose from "mongoose";
import { body } from "express-validator";
import { authRequired } from "../middlewares/auth.js";
import { handleValidation } from "../middlewares/validate.js";
import { applySeller } from "../controllers/sellerApplicationController.js";
import {
  createSellerProduct,
  createSellerProductWithImages,
  deleteSellerProduct,
  getSellerProducts,
  updateSellerProduct,
  uploadProductImages,
  updateStock,
  toggleProductActive,
  getSellerStats,
  seedDemoProducts,
} from "../controllers/sellerProductController.js";
import Review from "../models/Review.js";
import Product from "../models/Product.js";
import Coupon from "../models/Coupon.js";
import CouponUsage from "../models/CouponUsage.js";
import { sendOk, sendError } from "../utils/apiResponse.js";

const router = Router();

// Multer config for product images
const productStorage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    const dir = "uploads/products";
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    cb(null, dir);
  },
  filename: (_req, file, cb) => {
    const unique = Date.now() + "-" + randomBytes(8).toString("hex");
    const ext = path.extname(file.originalname);
    cb(null, "product-" + unique + ext);
  },
});

const productUpload = multer({
  storage: productStorage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter: (_req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|webp|gif/;
    const ext = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mime = allowedTypes.test(file.mimetype);
    if (ext && mime) {
      cb(null, true);
    } else {
      cb(new Error("Sadece resim dosyalari yuklenebilir"));
    }
  },
});

router.post("/seller/apply", authRequired(), applySeller);

const productValidators = [
  body("name").notEmpty().trim().isLength({ max: 200 }).withMessage("Ürün adı gerekli (max 200 karakter)"),
  body("price").isFloat({ min: 0.01, max: 999999 }).withMessage("Geçerli bir fiyat giriniz"),
  body("stock").isInt({ min: 0, max: 99999 }).withMessage("Stok 0 veya daha büyük olmalı"),
  body("category").optional().isMongoId().withMessage("Geçersiz kategori ID"),
];

// Product routes
router.post("/seller/products", authRequired(["seller", "admin"]), productValidators, handleValidation, createSellerProduct);
router.post("/seller/products/with-images", authRequired(["seller", "admin"]), productUpload.array("images", 5), createSellerProductWithImages);
router.post("/seller/products/:id/images", authRequired(["seller", "admin"]), productUpload.array("images", 5), uploadProductImages);
router.get("/seller/products", authRequired(["seller", "admin"]), getSellerProducts);
router.patch("/seller/products/:id", authRequired(["seller", "admin"]), productUpload.array("images", 5), updateSellerProduct);
router.delete("/seller/products/:id", authRequired(["seller", "admin"]), deleteSellerProduct);

// Stock & Status management
router.patch("/seller/products/:id/stock", authRequired(["seller", "admin"]), updateStock);
router.patch("/seller/products/:id/toggle-active", authRequired(["seller", "admin"]), toggleProductActive);

// Seller stats
router.get("/seller/stats", authRequired(["seller", "admin"]), getSellerStats);

// Demo products seed
router.post("/seller/seed-demo-products", authRequired(["seller", "admin"]), seedDemoProducts);

// ─── Seller Reviews ───────────────────────────────────────────────────────────
// GET /api/seller/reviews?page=1&limit=20&rating=5
router.get("/seller/reviews", authRequired(["seller", "admin"]), async (req, res) => {
  try {
    const sellerId = req.user?.sub;
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(50, parseInt(req.query.limit) || 20);
    const skip = (page - 1) * limit;
    const ratingFilter = req.query.rating ? parseInt(req.query.rating) : null;

    // Find seller's product IDs
    const products = await Product.find({ seller: sellerId }, "_id name");
    const productIds = products.map(p => p._id);

    if (productIds.length === 0) {
      return sendOk(res, 200, {
        reviews: [],
        total: 0,
        page,
        totalPages: 0,
        avgRating: 0,
        ratingBreakdown: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 },
      });
    }

    const matchStage = { product: { $in: productIds } };
    if (ratingFilter) matchStage.rating = ratingFilter;

    // Parallel: paginated reviews + summary stats
    const [reviews, summaryAgg] = await Promise.all([
      Review.aggregate([
        { $match: matchStage },
        { $sort: { createdAt: -1 } },
        { $skip: skip },
        { $limit: limit },
        {
          $lookup: {
            from: "users",
            localField: "user",
            foreignField: "_id",
            as: "userDoc",
          },
        },
        {
          $lookup: {
            from: "products",
            localField: "product",
            foreignField: "_id",
            as: "productDoc",
          },
        },
        {
          $project: {
            _id: 1,
            rating: 1,
            comment: 1,
            verifiedPurchase: 1,
            createdAt: 1,
            userName: { $ifNull: [{ $arrayElemAt: ["$userDoc.displayName", 0] }, "Kullanıcı"] },
            userAvatar: { $arrayElemAt: ["$userDoc.avatar", 0] },
            productName: { $ifNull: [{ $arrayElemAt: ["$productDoc.name", 0] }, "Ürün"] },
            productId: "$product",
          },
        },
      ]),
      Review.aggregate([
        { $match: { product: { $in: productIds } } },
        {
          $group: {
            _id: null,
            avgRating: { $avg: "$rating" },
            total: { $sum: 1 },
            r1: { $sum: { $cond: [{ $eq: ["$rating", 1] }, 1, 0] } },
            r2: { $sum: { $cond: [{ $eq: ["$rating", 2] }, 1, 0] } },
            r3: { $sum: { $cond: [{ $eq: ["$rating", 3] }, 1, 0] } },
            r4: { $sum: { $cond: [{ $eq: ["$rating", 4] }, 1, 0] } },
            r5: { $sum: { $cond: [{ $eq: ["$rating", 5] }, 1, 0] } },
          },
        },
      ]),
    ]);

    const totalFiltered = ratingFilter
      ? await Review.countDocuments(matchStage)
      : summaryAgg[0]?.total ?? 0;

    const summary = summaryAgg[0] ?? { avgRating: 0, total: 0, r1: 0, r2: 0, r3: 0, r4: 0, r5: 0 };

    return sendOk(res, 200, {
      reviews,
      total: totalFiltered,
      page,
      totalPages: Math.ceil(totalFiltered / limit),
      avgRating: Math.round((summary.avgRating || 0) * 10) / 10,
      ratingBreakdown: { 1: summary.r1, 2: summary.r2, 3: summary.r3, 4: summary.r4, 5: summary.r5 },
    });
  } catch (err) {
    console.error("[seller/reviews]", err);
    return sendError(res, 500, "Yorumlar alınamadı", "internal_error", err.message);
  }
});

// ─── Seller Coupon Performance ────────────────────────────────────────────────
// GET /api/seller/coupons/performance
router.get("/seller/coupons/performance", authRequired(["seller", "admin"]), async (req, res) => {
  try {
    const sellerId = new mongoose.Types.ObjectId(req.user?.sub);

    // Get coupons belonging to this seller
    const sellerCoupons = await Coupon.find({ seller: sellerId }, "_id code discountType discountValue usageLimit usageCount isActive validUntil");
    const couponIds = sellerCoupons.map(c => c._id);

    if (couponIds.length === 0) {
      return sendOk(res, 200, { coupons: [] });
    }

    // Aggregate usage stats per coupon
    const usageAgg = await CouponUsage.aggregate([
      { $match: { couponId: { $in: couponIds } } },
      {
        $group: {
          _id: "$couponId",
          usageCount: { $sum: "$count" },
          totalDiscount: { $sum: "$discountAmount" },
          totalOrderValue: { $sum: "$originalAmount" },
        },
      },
    ]);

    const usageMap = {};
    for (const u of usageAgg) {
      usageMap[u._id.toString()] = {
        usageCount: u.usageCount,
        totalDiscount: Math.round(u.totalDiscount * 100) / 100,
        totalOrderValue: Math.round(u.totalOrderValue * 100) / 100,
      };
    }

    const coupons = sellerCoupons.map(c => ({
      couponId: c._id,
      code: c.code,
      discountType: c.discountType,
      discountValue: c.discountValue,
      usageLimit: c.usageLimit,
      isActive: c.isActive,
      validUntil: c.validUntil,
      usageCount: usageMap[c._id.toString()]?.usageCount ?? c.usageCount ?? 0,
      totalDiscount: usageMap[c._id.toString()]?.totalDiscount ?? 0,
      totalOrderValue: usageMap[c._id.toString()]?.totalOrderValue ?? 0,
    }));

    return sendOk(res, 200, { coupons });
  } catch (err) {
    console.error("[seller/coupons/performance]", err);
    return sendError(res, 500, "Kupon istatistikleri alınamadı", "internal_error", err.message);
  }
});

export default router;
