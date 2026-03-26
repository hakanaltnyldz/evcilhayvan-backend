// src/controllers/couponController.js

import Coupon from '../models/Coupon.js';
import Store from '../models/Store.js';
import { sendOk, sendError } from '../utils/apiResponse.js';

// Get all coupons for a seller
export const getSellerCoupons = async (req, res) => {
  try {
    const sellerId = req.user.sub;
    const { status } = req.query;

    const query = { seller: sellerId };
    if (status === 'active') {
      query.isActive = true;
      query.validUntil = { $gte: new Date() };
    } else if (status === 'expired') {
      query.validUntil = { $lt: new Date() };
    }

    const coupons = await Coupon.find(query)
      .populate('applicableProducts', 'name title')
      .populate('applicableCategories', 'name')
      .sort({ createdAt: -1 });

    return sendOk(res, 200, { coupons });
  } catch (error) {
    console.error('Get seller coupons error:', error);
    return sendError(res, 500, 'Kuponlar yüklenirken hata oluştu', 'internal_error', error.message);
  }
};

// Create a coupon (sellers only)
export const createCoupon = async (req, res) => {
  try {
    const sellerId = req.user.sub;
    const {
      code,
      description,
      discountType,
      discountValue,
      minPurchaseAmount,
      maxDiscountAmount,
      validFrom,
      validUntil,
      usageLimit,
      perUserLimit,
      applicableProducts,
      applicableCategories,
    } = req.body;

    // Verify seller has a store
    const store = await Store.findOne({ owner: sellerId });
    if (!store) {
      return sendError(res, 403, 'Kupon oluşturmak için mağazanız olmalı', 'store_required');
    }

    // Validate required fields
    if (!code || !discountType || !discountValue || !validFrom || !validUntil) {
      return sendError(res, 400, 'Gerekli alanları doldurun', 'validation_error');
    }

    // Validate discount value
    if (discountType === 'percentage' && (discountValue <= 0 || discountValue > 100)) {
      return sendError(res, 400, 'Yüzde indirimi 1-100 arasında olmalıdır', 'validation_error');
    }
    if (discountType === 'fixed' && discountValue <= 0) {
      return sendError(res, 400, "Sabit indirim 0'dan büyük olmalıdır", 'validation_error');
    }

    // Validate dates
    const from = new Date(validFrom);
    const until = new Date(validUntil);
    if (until <= from) {
      return sendError(res, 400, 'Bitiş tarihi başlangıç tarihinden sonra olmalıdır', 'validation_error');
    }

    // Check if code already exists
    const existingCoupon = await Coupon.findOne({ code: code.toUpperCase() });
    if (existingCoupon) {
      return sendError(res, 400, 'Bu kupon kodu zaten kullanılıyor', 'code_exists');
    }

    // Create coupon
    const coupon = await Coupon.create({
      code: code.toUpperCase(),
      description,
      discountType,
      discountValue,
      minPurchaseAmount: minPurchaseAmount || 0,
      maxDiscountAmount,
      validFrom: from,
      validUntil: until,
      usageLimit,
      perUserLimit: perUserLimit || 1,
      seller: sellerId,
      store: store._id,
      applicableProducts: applicableProducts || [],
      applicableCategories: applicableCategories || [],
    });

    const populatedCoupon = await Coupon.findById(coupon._id)
      .populate('applicableProducts', 'name title')
      .populate('applicableCategories', 'name');

    return sendOk(res, 201, { message: 'Kupon başarıyla oluşturuldu', coupon: populatedCoupon });
  } catch (error) {
    console.error('Create coupon error:', error);
    return sendError(res, 500, 'Kupon oluşturulurken hata oluştu', 'internal_error', error.message);
  }
};

// Update a coupon
export const updateCoupon = async (req, res) => {
  try {
    const { couponId } = req.params;
    const sellerId = req.user.sub;
    const updates = req.body;

    const coupon = await Coupon.findById(couponId);
    if (!coupon) {
      return sendError(res, 404, 'Kupon bulunamadı', 'not_found');
    }

    if (coupon.seller.toString() !== sellerId.toString()) {
      return sendError(res, 403, 'Bu kuponu güncelleme yetkiniz yok', 'forbidden');
    }

    // Validate discount value if being updated
    if (updates.discountValue !== undefined) {
      const discountType = updates.discountType || coupon.discountType;
      if (discountType === 'percentage' && (updates.discountValue <= 0 || updates.discountValue > 100)) {
        return sendError(res, 400, 'Yüzde indirimi 1-100 arasında olmalıdır', 'validation_error');
      }
      if (discountType === 'fixed' && updates.discountValue <= 0) {
        return sendError(res, 400, "Sabit indirim 0'dan büyük olmalıdır", 'validation_error');
      }
    }

    // Validate dates if being updated
    if (updates.validFrom || updates.validUntil) {
      const from = updates.validFrom ? new Date(updates.validFrom) : coupon.validFrom;
      const until = updates.validUntil ? new Date(updates.validUntil) : coupon.validUntil;
      if (until <= from) {
        return sendError(res, 400, 'Bitiş tarihi başlangıç tarihinden sonra olmalıdır', 'validation_error');
      }
    }

    const updatedCoupon = await Coupon.findByIdAndUpdate(
      couponId,
      { $set: updates },
      { new: true, runValidators: true }
    )
      .populate('applicableProducts', 'name title')
      .populate('applicableCategories', 'name');

    return sendOk(res, 200, { message: 'Kupon başarıyla güncellendi', coupon: updatedCoupon });
  } catch (error) {
    console.error('Update coupon error:', error);
    return sendError(res, 500, 'Kupon güncellenirken hata oluştu', 'internal_error', error.message);
  }
};

// Delete a coupon
export const deleteCoupon = async (req, res) => {
  try {
    const { couponId } = req.params;
    const sellerId = req.user.sub;

    const coupon = await Coupon.findById(couponId);
    if (!coupon) {
      return sendError(res, 404, 'Kupon bulunamadı', 'not_found');
    }

    if (coupon.seller.toString() !== sellerId.toString()) {
      return sendError(res, 403, 'Bu kuponu silme yetkiniz yok', 'forbidden');
    }

    await Coupon.findByIdAndDelete(couponId);
    return sendOk(res, 200, { message: 'Kupon başarıyla silindi' });
  } catch (error) {
    console.error('Delete coupon error:', error);
    return sendError(res, 500, 'Kupon silinirken hata oluştu', 'internal_error', error.message);
  }
};

// Validate a coupon code (for customers — auth required to enforce per-user limits)
export const validateCoupon = async (req, res) => {
  try {
    const { code } = req.params;
    const { amount, storeId } = req.query;
    const userId = req.user?.sub;

    if (!amount) {
      return sendError(res, 400, 'Tutar belirtilmelidir', 'validation_error');
    }

    const coupon = await Coupon.findOne({ code: code.toUpperCase(), isActive: true });
    if (!coupon) {
      return sendError(res, 404, 'Kupon bulunamadı veya aktif değil', 'not_found');
    }

    // Mağaza kısıtlaması
    if (coupon.store && storeId && coupon.store.toString() !== storeId) {
      return sendError(res, 400, 'Bu kupon bu mağaza için geçerli değil', 'store_mismatch');
    }

    const validity = coupon.isValid();
    if (!validity.valid) {
      return sendError(res, 400, validity.reason, 'coupon_invalid');
    }

    // Kişi başı limit kontrolü
    if (userId && coupon.perUserLimit) {
      const { default: CouponUsage } = await import('../models/CouponUsage.js');
      const userUsageCount = await CouponUsage.countDocuments({ couponId: coupon._id, userId });
      if (userUsageCount >= coupon.perUserLimit) {
        return sendError(res, 400, `Bu kuponu en fazla ${coupon.perUserLimit} kez kullanabilirsiniz (kalan: 0)`, 'usage_limit_exceeded');
      }
    }

    // İlk sipariş kuponu kontrolü
    if (coupon.firstOrderOnly && userId) {
      const { default: Order } = await import('../models/Order.js');
      const pastPaidOrders = await Order.countDocuments({ user: userId, paymentStatus: 'paid' });
      if (pastPaidOrders > 0) {
        return sendError(res, 400, 'Bu kupon sadece ilk sipariş için geçerlidir', 'first_order_only');
      }
    }

    const calculation = coupon.calculateDiscount(parseFloat(amount));
    if (calculation.error) {
      return sendError(res, 400, calculation.error, 'discount_error');
    }

    // Kişi başı kalan kullanım sayısı
    let remainingUses = null;
    if (userId && coupon.perUserLimit) {
      const { default: CouponUsage } = await import('../models/CouponUsage.js');
      const used = await CouponUsage.countDocuments({ couponId: coupon._id, userId });
      remainingUses = coupon.perUserLimit - used;
    }

    return sendOk(res, 200, {
      valid: true,
      coupon: {
        code: coupon.code,
        description: coupon.description,
        discountType: coupon.discountType,
        discountValue: coupon.discountValue,
        firstOrderOnly: coupon.firstOrderOnly,
      },
      discount: calculation.discount,
      finalAmount: calculation.finalAmount,
      remainingUses,
    });
  } catch (error) {
    console.error('Validate coupon error:', error);
    return sendError(res, 500, 'Kupon doğrulanırken hata oluştu', 'internal_error', error.message);
  }
};

// Toggle coupon active status
export const toggleCouponStatus = async (req, res) => {
  try {
    const { couponId } = req.params;
    const sellerId = req.user.sub;

    const coupon = await Coupon.findById(couponId);
    if (!coupon) {
      return sendError(res, 404, 'Kupon bulunamadı', 'not_found');
    }

    if (coupon.seller.toString() !== sellerId.toString()) {
      return sendError(res, 403, 'Bu kuponu güncelleme yetkiniz yok', 'forbidden');
    }

    coupon.isActive = !coupon.isActive;
    await coupon.save();

    return sendOk(res, 200, {
      message: `Kupon ${coupon.isActive ? 'aktif' : 'pasif'} hale getirildi`,
      coupon,
    });
  } catch (error) {
    console.error('Toggle coupon status error:', error);
    return sendError(res, 500, 'Kupon durumu değiştirilirken hata oluştu', 'internal_error', error.message);
  }
};
