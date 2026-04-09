// src/routes/couponRoutes.js

import express from 'express';
import mongoose from 'mongoose';
import * as couponController from '../controllers/couponController.js';
import { protect, authRequired } from '../middlewares/auth.js';
import Coupon from '../models/Coupon.js';
import CouponUsage from '../models/CouponUsage.js';
import { sendOk, sendError } from '../utils/apiResponse.js';

const router = express.Router();

// POST /api/coupons/validate — Flutter checkout uyumlu (body: { code, cartTotal })
router.post('/coupons/validate', authRequired(), async (req, res) => {
  try {
    const { code, cartTotal } = req.body;
    if (!code) return sendError(res, 400, 'Kupon kodu gerekli', 'validation_error');
    if (!cartTotal) return sendError(res, 400, 'Sepet tutarı gerekli', 'validation_error');

    const now = new Date();
    const coupon = await Coupon.findOne({ code: code.toUpperCase().trim(), isActive: true });
    if (!coupon) return sendError(res, 404, 'Kupon bulunamadı veya aktif değil', 'not_found');

    if (coupon.validFrom > now || coupon.validUntil < now)
      return sendError(res, 410, 'Kuponun geçerlilik süresi dolmuş', 'coupon_expired');

    if (coupon.usageLimit && coupon.usageCount >= coupon.usageLimit)
      return sendError(res, 400, 'Kupon kullanım limiti dolmuş', 'usage_limit_exceeded');

    if (coupon.minPurchaseAmount && parseFloat(cartTotal) < coupon.minPurchaseAmount)
      return sendError(res, 400, `Minimum ${coupon.minPurchaseAmount}₺ sepet tutarı gerekli`, 'min_amount_required');

    const userId = req.user?.sub || req.user?._id;
    if (userId && coupon.perUserLimit) {
      const used = await CouponUsage.countDocuments({ couponId: coupon._id, userId });
      if (used >= coupon.perUserLimit)
        return sendError(res, 400, `Bu kuponu en fazla ${coupon.perUserLimit} kez kullanabilirsiniz`, 'usage_limit_exceeded');
    }

    let discountAmount = coupon.discountType === 'percentage'
      ? (parseFloat(cartTotal) * coupon.discountValue) / 100
      : coupon.discountValue;
    if (coupon.maxDiscountAmount) discountAmount = Math.min(discountAmount, coupon.maxDiscountAmount);
    discountAmount = Math.min(discountAmount, parseFloat(cartTotal));

    return sendOk(res, 200, {
      valid: true,
      discountAmount: parseFloat(discountAmount.toFixed(2)),
      couponId: coupon._id,
      code: coupon.code,
      description: coupon.description,
      discountType: coupon.discountType,
      discountValue: coupon.discountValue,
      finalAmount: parseFloat((parseFloat(cartTotal) - discountAmount).toFixed(2)),
    });
  } catch (err) {
    return sendError(res, 500, 'Kupon doğrulanırken hata oluştu', 'internal_error', err.message);
  }
});

// Auth gerekli: kişi başı limit ve firstOrderOnly kontrolü için kullanıcı kimliği lazım
router.get('/coupons/:code/validate', authRequired(), couponController.validateCoupon);

// GET /api/coupons/available — tüm aktif kuponlar (hem platform hem satıcı kuponları)
// Her kupon için kullanıcının kalan kullanım hakkı da döner
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

    // Her kupon için kullanıcının kalan kullanım hakkını hesapla
    const usageCounts = userId ? await CouponUsage.aggregate([
      { $match: { userId, couponId: { $in: coupons.map(c => c._id) } } },
      { $group: { _id: '$couponId', count: { $sum: 1 } } },
    ]) : [];
    const usageMap = {};
    usageCounts.forEach(u => { usageMap[u._id.toString()] = u.count; });

    const result = coupons.map(c => ({
      ...c.toJSON(),
      remainingUses: Math.max(0, (c.perUserLimit || 1) - (usageMap[c._id.toString()] || 0)),
      usedByMe: usageMap[c._id.toString()] || 0,
    })).filter(c => c.remainingUses > 0); // Tükenmiş kuponları filtrele

    return sendOk(res, 200, { coupons: result });
  } catch (err) {
    return sendError(res, 500, 'Kuponlar alınamadı.', 'internal_error', err.message);
  }
});

// GET /api/coupon-usage/my — kullanıcının kupon kullanım geçmişi
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
    return sendError(res, 500, 'Kullanım geçmişi alınamadı.', 'internal_error', err.message);
  }
});

// Protected routes
router.use(protect);

// Seller routes - manage coupons
router.get('/seller/coupons', couponController.getSellerCoupons);
router.post('/seller/coupons', couponController.createCoupon);
router.put('/seller/coupons/:couponId', couponController.updateCoupon);
router.delete('/seller/coupons/:couponId', couponController.deleteCoupon);
router.patch('/seller/coupons/:couponId/toggle', couponController.toggleCouponStatus);

export default router;
