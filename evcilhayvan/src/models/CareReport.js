import mongoose from "mongoose";

const CareReportSchema = new mongoose.Schema(
  {
    bookingId: { type: mongoose.Schema.Types.ObjectId, ref: "SitterBooking", required: true, index: true },
    sitterUserId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    day: { type: Number, required: true, min: 1 }, // kaçıncı gün (1, 2, 3...)
    mood: { type: String, enum: ["great", "good", "okay", "tired"], default: "good" },
    photos: { type: [String], default: [] },
    notes: { type: String, trim: true, maxlength: 500 },
    activities: {
      type: [String],
      enum: ["walk", "play", "grooming", "vet_visit", "bath", "training"],
      default: [],
    },
    foodEaten: { type: Boolean, default: true },
    timestamp: { type: Date, default: Date.now },
  },
  {
    toJSON: {
      virtuals: true,
      transform(_doc, ret) {
        ret.id = ret._id;
        delete ret.__v;
      },
    },
  }
);

CareReportSchema.index({ bookingId: 1, day: 1 });

export default mongoose.model("CareReport", CareReportSchema);
