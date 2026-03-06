import mongoose from "mongoose";

const ReviewSchema = new mongoose.Schema(
  {
    rating: { type: Number, min: 1, max: 5, required: true },
    comment: { type: String, trim: true, maxlength: 1000 },
    createdAt: { type: Date, default: Date.now },
  },
  { _id: false }
);

const SitterBookingSchema = new mongoose.Schema(
  {
    petOwnerId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
    sitterId: { type: mongoose.Schema.Types.ObjectId, ref: "PetSitter", required: true },
    sitterUserId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
    petId: { type: mongoose.Schema.Types.ObjectId, ref: "Pet", required: true },
    serviceType: {
      type: String,
      enum: ["walking", "home_sitting", "boarding", "daycare", "grooming"],
      required: true,
    },
    startDate: { type: Date, required: true },
    endDate: { type: Date, required: true },
    totalPrice: { type: Number, min: 0, default: 0 },
    notes: { type: String, trim: true, maxlength: 500 },
    status: {
      type: String,
      enum: ["pending", "accepted", "rejected", "cancelled", "completed"],
      default: "pending",
    },
    ownerReview: { type: ReviewSchema },
    respondedAt: { type: Date },
    completedAt: { type: Date },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform(_doc, ret) {
        ret.id = ret._id;
        delete ret.__v;
      },
    },
  }
);

SitterBookingSchema.index({ petOwnerId: 1, status: 1 });
SitterBookingSchema.index({ sitterUserId: 1, status: 1 });

export default mongoose.model("SitterBooking", SitterBookingSchema);
