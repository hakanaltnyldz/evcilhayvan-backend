// src/models/Address.js

import mongoose from 'mongoose';

const { Schema } = mongoose;

const addressSchema = new Schema(
  {
    user: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    title: {
      type: String,
      required: true,
      trim: true,
    },
    fullName: {
      type: String,
      required: true,
      trim: true,
    },
    phone: {
      type: String,
      required: true,
      trim: true,
    },
    city: {
      type: String,
      required: true,
      trim: true,
    },
    district: {
      type: String,
      required: true,
      trim: true,
    },
    neighborhood: {
      type: String,
      trim: true,
    },
    street: {
      type: String,
      required: true,
      trim: true,
    },
    buildingNo: {
      type: String,
      trim: true,
    },
    floor: {
      type: String,
      trim: true,
    },
    apartmentNo: {
      type: String,
      trim: true,
    },
    postalCode: {
      type: String,
      trim: true,
    },
    isDefault: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

// Ensure virtuals are included in JSON
addressSchema.set('toJSON', { virtuals: true });
addressSchema.set('toObject', { virtuals: true });

export default mongoose.model('Address', addressSchema);