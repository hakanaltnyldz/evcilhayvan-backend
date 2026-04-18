// src/routes/couponRoutes.js

import express from 'express';
import mongoose from 'mongoose';
import { body, param, query, validationResult } from 'express-validator';
import * as couponController from '../controllers/couponController.js';
import { protect, authRequired } from '../middlewares/auth.js';
import Coupon from '../models/Coupon.js';
import CouponUsage from '../models/CouponUsage.js';
import {
  buildCouponContextFromUserCart,
  evaluateCouponByCode,
} from '../services/couponValidationService.js';
import { sendOk, sendError } from '../utils/apiResponse.js';

const router = express.Router();

function validateRequest(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return sendError(res, 400, 'Dogrulama hatasi', 'validation_error', errors.array());
  }
  return next();
}

// POST /api/coupons/validate
router.post(
  '/coupons/validate',
  authRequired(),
  [
    body('code').trim().notEmpty().withMessage('Kupon kodu gerekli'),
    body('cartTotal').isFloat({ gt: 0 }).withMessage('Sepet tutari 0\'dan buyuk olmali'),
  ],
  validateRequest,
  async (req, res) => {
  try {
    const { code, cartTotal } = req.body;

    const userId = req.user?.sub || req.user?._id;
    const cartContext = await buildCouponContextFromUserCart(userId);
    const result = await evaluateCouponByCode({
      code,
      userId,
      totalAmount: cartContext.totalAmount > 0 ? cartContext.totalAmount : Number(cartTotal),
      items: cartContext.items,
    });

    return sendOk(res, 200, {
      valid: true,
      discountAmount: parseFloat(result.discountAmount.toFixed(2)),
      couponId: result.coupon._id,
      code: result.coupon.code,
      description: result.coupon.description,
      discountType: result.coupon.discountType,
      discountValue: result.coupon.discountValue,
      finalAmount: parseFloat(result.finalAmount.toFixed(2)),
      eligibleSubtotal: parseFloat(result.eligibleSubtotal.toFixed(2)),
      remainingUses: result.remainingUses,
    });
  } catch (err) {
    if (err.statusCode) {
      return sendError(res, err.statusCode, err.message, err.code || 'coupon_invalid', err.details);
    }
    return sendError(res, 500, 'Kupon dogrulanirken hata olustu', 'internal_error', err.message);
  }
});

// Auth gerekli: kisi basi limit ve firstOrderOnly kontrolu icin kullanici kimligi lazim
router.get(
  '/coupons/:code/validate',
  authRequired(),
  [
    param('code').trim().notEmpty().withMessage('Kupon kodu gerekli'),
    query('amount').isFloat({ gt: 0 }).withMessage('Tutar 0\'dan buyuk olmali'),
    query('storeId').optional().isMongoId().withMessage('Gecersiz magaza ID'),
  ],
  validateRequest,
  couponController.validateCoupon
);

// GET /api/coupons/available
router.get('/coupons/available', authRequired(), async (req, res) => {
  try {
    const rawUserId = req.user._id || req.user.id || req.user.sub;
    const userId = mongoose.Types.ObjectId.isValid(rawUserId)
      ? new mongoose.Types.ObjectId(rawUserId)
      : null;
    const now = new Date();
    const coupons = await Coupon.find({
      isActive: true,
      validFrom: { $lte: now },
      validUntil: { $gte: now },
    }).select('-applicableProducts -applicableCategories -store').sort({ createdAt: -1 });

    const usageCounts = userId
      ? await CouponUsage.aggregate([
          { $match: { userId, couponId: { $in: coupons.map((coupon) => coupon._id) } } },
          { $group: { _id: '$couponId', count: { $sum: '$count' } } },
        ])
      : [];
    const usageMap = {};
    usageCounts.forEach((usage) => {
      usageMap[usage._id.toString()] = usage.count;
    });

    const result = coupons
      .map((coupon) => ({
        ...coupon.toJSON(),
        remainingUses: Math.max(
          0,
          (coupon.perUserLimit || 1) - (usageMap[coupon._id.toString()] || 0),
        ),
        usedByMe: usageMap[coupon._id.toString()] || 0,
      }))
      .filter((coupon) => coupon.remainingUses > 0);

    return sendOk(res, 200, { coupons: result });
  } catch (err) {
    return sendError(res, 500, 'Kuponlar alinamadi.', 'internal_error', err.message);
  }
});

// GET /api/coupon-usage/my
router.get('/coupon-usage/my', authRequired(), async (req, res) => {
  try {
    const userId = req.user._id || req.user.id || req.user.sub;
    const usages = await CouponUsage.find({ userId })
      .populate('couponId', 'code discountType discountValue description')
      .populate('orderId', 'totalAmount originalAmount status createdAt')
      .sort({ createdAt: -1 })
      .limit(50);
    return sendOk(res, 200, { usages });
  } catch (err) {
    return sendError(res, 500, 'Kullanim gecmisi alinamadi.', 'internal_error', err.message);
  }
});

// Protected routes
router.use(protect);

// Seller routes - manage coupons
router.get('/seller/coupons', couponController.getSellerCoupons);
router.post(
  '/seller/coupons',
  [
    body('code').trim().notEmpty().withMessage('Kupon kodu gerekli'),
    body('discountType').isIn(['percentage', 'fixed']).withMessage('Gecersiz indirim tipi'),
    body('discountValue').isFloat({ gt: 0 }).withMessage('Indirim degeri 0\'dan buyuk olmali'),
    body('validFrom').isISO8601().withMessage('Gecersiz baslangic tarihi'),
    body('validUntil').isISO8601().withMessage('Gecersiz bitis tarihi'),
    body('minPurchaseAmount').optional().isFloat({ min: 0 }).withMessage('Min tutar gecersiz'),
    body('maxDiscountAmount').optional().isFloat({ min: 0 }).withMessage('Maks indirim gecersiz'),
    body('usageLimit').optional().isInt({ min: 1 }).withMessage('Kullanim limiti en az 1 olmali'),
    body('perUserLimit').optional().isInt({ min: 1 }).withMessage('Kisi basi limit en az 1 olmali'),
    body('applicableProducts').optional().isArray().withMessage('Urun listesi dizi olmali'),
    body('applicableCategories').optional().isArray().withMessage('Kategori listesi dizi olmali'),
  ],
  validateRequest,
  couponController.createCoupon
);
router.put(
  '/seller/coupons/:couponId',
  [
    param('couponId').isMongoId().withMessage('Gecersiz kupon ID'),
    body('code').optional().trim().notEmpty().withMessage('Kupon kodu bos olamaz'),
    body('discountType').optional().isIn(['percentage', 'fixed']).withMessage('Gecersiz indirim tipi'),
    body('discountValue').optional().isFloat({ gt: 0 }).withMessage('Indirim degeri 0\'dan buyuk olmali'),
    body('validFrom').optional().isISO8601().withMessage('Gecersiz baslangic tarihi'),
    body('validUntil').optional().isISO8601().withMessage('Gecersiz bitis tarihi'),
    body('minPurchaseAmount').optional().isFloat({ min: 0 }).withMessage('Min tutar gecersiz'),
    body('maxDiscountAmount').optional().isFloat({ min: 0 }).withMessage('Maks indirim gecersiz'),
    body('usageLimit').optional().isInt({ min: 1 }).withMessage('Kullanim limiti en az 1 olmali'),
    body('perUserLimit').optional().isInt({ min: 1 }).withMessage('Kisi basi limit en az 1 olmali'),
    body('applicableProducts').optional().isArray().withMessage('Urun listesi dizi olmali'),
    body('applicableCategories').optional().isArray().withMessage('Kategori listesi dizi olmali'),
  ],
  validateRequest,
  couponController.updateCoupon
);
router.delete('/seller/coupons/:couponId', [param('couponId').isMongoId()], validateRequest, couponController.deleteCoupon);
router.patch('/seller/coupons/:couponId/toggle', [param('couponId').isMongoId()], validateRequest, couponController.toggleCouponStatus);

export default router;
