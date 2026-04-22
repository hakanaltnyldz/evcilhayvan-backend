import mongoose from "mongoose";

const { Schema } = mongoose;

const platformConfigSchema = new Schema(
  {
    key: {
      type: String,
      required: true,
      unique: true,
      default: "default",
    },
    fees: {
      storeCommissionRate: { type: Number, min: 0, max: 100, default: 12 },
      sitterCommissionRate: { type: Number, min: 0, max: 100, default: 10 },
      vetCommissionRate: { type: Number, min: 0, max: 100, default: 8 },
      payoutReserveDays: { type: Number, min: 0, max: 90, default: 7 },
      returnWindowDays: { type: Number, min: 0, max: 60, default: 14 },
      freeShippingThreshold: { type: Number, min: 0, max: 1000000, default: 750 },
    },
    features: {
      storeEnabled: { type: Boolean, default: true },
      sitterMatchingEnabled: { type: Boolean, default: true },
      vetAppointmentsEnabled: { type: Boolean, default: true },
      socialFeedEnabled: { type: Boolean, default: true },
      maintenanceMode: { type: Boolean, default: false },
    },
    moderation: {
      autoHideReportThreshold: { type: Number, min: 1, max: 50, default: 3 },
      reviewSlaHours: { type: Number, min: 1, max: 168, default: 24 },
      careReportReviewWindowHours: { type: Number, min: 1, max: 168, default: 48 },
      escalateUserComplaintThreshold: { type: Number, min: 1, max: 50, default: 5 },
    },
    contact: {
      supportEmail: { type: String, trim: true, maxlength: 200, default: "" },
      supportPhone: { type: String, trim: true, maxlength: 40, default: "" },
      supportWhatsapp: { type: String, trim: true, maxlength: 40, default: "" },
    },
    announcement: {
      enabled: { type: Boolean, default: false },
      tone: {
        type: String,
        enum: ["info", "warning", "success"],
        default: "info",
      },
      message: { type: String, trim: true, maxlength: 240, default: "" },
    },
    updatedBy: {
      type: Schema.Types.ObjectId,
      ref: "User",
    },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform(_doc, ret) {
        ret.id = ret._id;
        delete ret._id;
        delete ret.__v;
        return ret;
      },
    },
  }
);

export default mongoose.model("PlatformConfig", platformConfigSchema);
