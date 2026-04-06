// src/routes/couponRoutes.js

import express from 'express';
import mongoose from 'mongoose';
import * as couponController from '../controllers/couponController.js';
import { protect, authRequired } from '../middlewares/auth.js';
import Coupon from '../models/Coupon.js';
import CouponUsage from '../models/CouponUsage.js';
import { sendOk, sendError } from '../utils/apiResponse.js';

const router = express.Router();

// Auth gerekli: kişi başı limit ve firstOrderOnly kontrolü için kullanıcı kimliği lazım
router.get('/coupons/:code/validate', authRequired(), couponController.validateCoupon);

// GET /api/coupons/available — platform geneli aktif kuponlar (satıcısız)
// Her kupon için kullanıcının kalan kullanım hakkı da döner
router.get('/coupons/available', authRequired(), async (req, res) => {
  try {
    const rawUserId = req.user._id || req.user.id || req.user.sub;
    const userId = mongoose.Types.ObjectId.isValid(rawUserId)
      ? new mongoose.Types.ObjectId(rawUserId)
      : null;
    const now = new Date();
    const coupons = await Coupon.find({
      $or: [{ seller: null }, { seller: { $exists: false } }],
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
