// src/models/CouponUsage.js
// Her kupon kullanımını kullanıcı bazında takip eder.
// Compound index sayesinde "bu kişi bu kuponu kaç kez kullandı?" sorusu O(log n) maliyetle cevaplanır.

import mongoose from 'mongoose';

const { Schema } = mongoose;

const couponUsageSchema = new Schema(
  {
    couponId: {
      type: Schema.Types.ObjectId,
      ref: 'Coupon',
      required: true,
    },
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    orderId: {
      type: Schema.Types.ObjectId,
      ref: 'Order',
      required: true,
    },
    discountAmount: {
      type: Number,
      required: true,
      min: 0,
    },
    originalAmount: {
      type: Number,
      required: true,
      min: 0,
    },
    finalAmount: {
      type: Number,
      required: true,
      min: 0,
    },
  },
  { timestamps: true }
);

// Bileşik index: belirli bir kuponu belirli bir kullanıcının kaç kez kullandığını hızla bul
couponUsageSchema.index({ couponId: 1, userId: 1 });
// Kupon bazlı toplam kullanım sorgusu için
couponUsageSchema.index({ couponId: 1, createdAt: -1 });
// Kullanıcı sipariş geçmişi için
couponUsageSchema.index({ userId: 1, createdAt: -1 });

export default mongoose.model('CouponUsage', couponUsageSchema);
