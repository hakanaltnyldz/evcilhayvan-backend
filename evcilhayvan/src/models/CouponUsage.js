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
    },
    // Atomik kullanım sayacı — perUserLimit race condition önler ($inc ile güncellenir)
    count: {
      type: Number,
      default: 1,
      min: 1,
    },
    discountAmount: {
      type: Number,
      min: 0,
      default: 0,
    },
    originalAmount: {
      type: Number,
      min: 0,
      default: 0,
    },
    finalAmount: {
      type: Number,
      min: 0,
      default: 0,
    },
  },
  { timestamps: true }
);

// Unique bileşik index: aynı kullanıcı + kupon için tek kayıt (upsert + $inc ile count artırılır)
couponUsageSchema.index({ couponId: 1, userId: 1 }, { unique: true });
// Kupon bazlı toplam kullanım sorgusu için
couponUsageSchema.index({ couponId: 1, createdAt: -1 });
// Kullanıcı sipariş geçmişi için
couponUsageSchema.index({ userId: 1, createdAt: -1 });

export default mongoose.model('CouponUsage', couponUsageSchema);
