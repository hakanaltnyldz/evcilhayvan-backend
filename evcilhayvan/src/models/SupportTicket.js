// src/models/SupportTicket.js
import mongoose from 'mongoose';

const { Schema } = mongoose;

const supportTicketSchema = new Schema(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    category: {
      type: String,
      enum: ['app_bug', 'content_complaint', 'user_complaint', 'payment_issue', 'account_issue', 'other'],
      required: true,
    },
    message: {
      type: String,
      required: true,
      trim: true,
      maxlength: 1000,
    },
    status: {
      type: String,
      enum: ['open', 'reviewing', 'closed'],
      default: 'open',
    },
    adminNote: {
      type: String,
      trim: true,
      maxlength: 500,
    },
  },
  { timestamps: true }
);

supportTicketSchema.index({ status: 1, createdAt: -1 });
supportTicketSchema.index({ userId: 1, createdAt: -1 });

export default mongoose.model('SupportTicket', supportTicketSchema);
