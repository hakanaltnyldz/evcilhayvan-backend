// src/controllers/couponController.js

import Coupon from '../models/Coupon.js';
import Store from '../models/Store.js';
import {
  buildCouponContextFromUserCart,
  evaluateCouponByCode,
} from '../services/couponValidationService.js';
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

    const cartContext = await buildCouponContextFromUserCart(userId);
    const result = await evaluateCouponByCode({
      code,
      userId,
      totalAmount: cartContext.totalAmount > 0 ? cartContext.totalAmount : Number(amount),
      items: cartContext.items,
      storeId,
    });

    return sendOk(res, 200, {
      valid: true,
      coupon: {
        code: result.coupon.code,
        description: result.coupon.description,
        discountType: result.coupon.discountType,
        discountValue: result.coupon.discountValue,
        firstOrderOnly: result.coupon.firstOrderOnly,
      },
      discount: result.discountAmount,
      finalAmount: result.finalAmount,
      remainingUses: result.remainingUses,
    });
  } catch (error) {
    console.error('Validate coupon error:', error);
    if (error.statusCode) {
      return sendError(res, error.statusCode, error.message, error.code || 'coupon_invalid', error.details);
    }
    return sendError(res, 500, 'Kupon dogrulanirken hata olustu', 'internal_error', error.message);
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
