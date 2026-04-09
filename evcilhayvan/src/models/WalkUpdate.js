import mongoose from "mongoose";

const WalkUpdateSchema = new mongoose.Schema(
  {
    bookingId: { type: mongoose.Schema.Types.ObjectId, ref: "SitterBooking", required: true, index: true },
    sitterUserId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    type: {
      type: String,
      enum: ["location", "photo", "note", "arrived", "walk_started", "walk_ended"],
      required: true,
    },
    coordinates: {
      type: [Number], // [lng, lat]
      default: undefined,
    },
    photoUrl: { type: String },
    message: { type: String, trim: true, maxlength: 300 },
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

WalkUpdateSchema.index({ bookingId: 1, timestamp: 1 });

export default mongoose.model("WalkUpdate", WalkUpdateSchema);
