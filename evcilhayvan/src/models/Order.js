// src/models/Order.js

import mongoose from 'mongoose';

const { Schema } = mongoose;

const orderItemSchema = new Schema({
  product: {
    type: Schema.Types.ObjectId,
    ref: 'Product',
    required: true,
  },
  quantity: {
    type: Number,
    required: true,
    min: 1,
  },
  price: {
    type: Number,
    required: true,
    min: 0,
  },
  name: String,
  image: String,
  variantName: { type: String, default: null },
  variantLabel: { type: String, default: null },
});

const orderSchema = new Schema(
  {
    user: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: false,   // misafir siparişlerde null olabilir
      index: true,
    },
    // Misafir (giriş yapmamış) kullanıcı bilgileri
    guestInfo: {
      name:       { type: String },
      phone:      { type: String },
      email:      { type: String },      // takip maili için
      nationalId: { type: String },      // AES-256-CBC şifreli TC
      address: {
        city:      String,
        district:  String,
        street:    String,
        buildingNo: String,
      },
    },
    items: [orderItemSchema],
    totalAmount: {
      type: Number,
      required: true,
      min: 0,
    },
    status: {
      type: String,
      enum: ['pending', 'processing', 'shipped', 'delivered', 'cancelled'],
      default: 'pending',
    },
    shippingAddress: {
      street: String,
      city: String,
      state: String,
      zipCode: String,
      country: String,
    },
    paymentMethod: {
      type: String,
      enum: ['credit_card', 'debit_card', 'cash', 'transfer'],
      default: 'credit_card',
    },
    paymentStatus: {
      type: String,
      enum: ['pending', 'paid', 'failed', 'refunded'],
      default: 'pending',
    },
    notes: String,
    // Kupon alanları
    couponCode: { type: String, uppercase: true, trim: true },
    originalAmount: { type: Number, min: 0 },  // iskonto öncesi tutar
    discountAmount: { type: Number, default: 0, min: 0 },
    // Durum geçmiş kaydı (max ~10 giriş/sipariş, hafif)
    statusHistory: [
      {
        status: String,
        note: String,
        updatedAt: { type: Date, default: Date.now },
      },
    ],
    trackingNumber: { type: String, trim: true },
    carrier: {
      type: String,
      enum: ['Yurtiçi', 'MNG', 'Aras', 'PTT', 'Sürat', 'UPS', 'DHL', 'Diğer'],
    },
    estimatedDelivery: { type: Date },
  },
  {
    timestamps: true,
  }
);

// Index for user queries
orderSchema.index({ user: 1, createdAt: -1 });

// Index for user+status compound queries
orderSchema.index({ user: 1, status: 1 });

// Index for admin/status queries sorted by date
orderSchema.index({ status: 1, createdAt: -1 });

// Method to check if user purchased a specific product
orderSchema.statics.hasPurchased = async function (userId, productId) {
  const order = await this.findOne({
    user: userId,
    'items.product': productId,
    paymentStatus: 'paid',
    status: { $in: ['processing', 'shipped', 'delivered'] },
  });
  return !!order;
};

// Ensure virtuals are included in JSON
orderSchema.set('toJSON', { virtuals: true });
orderSchema.set('toObject', { virtuals: true });

export default mongoose.model('Order', orderSchema);
