import mongoose from "mongoose";

const SitterRequestSchema = new mongoose.Schema(
  {
    owner: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
    petTypes: {
      type: [String],
      enum: ["dog", "cat", "bird", "rabbit", "other"],
      default: ["dog"],
    },
    serviceType: {
      type: String,
      enum: ["walking", "home_sitting", "boarding", "daycare", "grooming"],
      required: true,
    },
    startDate: { type: Date, required: true },
    endDate: { type: Date, required: true },
    location: {
      type: { type: String, enum: ["Point"], default: "Point" },
      coordinates: {
        type: [Number], // [lng, lat]
        default: [0, 0],
      },
      address: { type: String, trim: true, maxlength: 300 },
    },
    description: { type: String, trim: true, maxlength: 500 },
    status: { type: String, enum: ["open", "closed"], default: "open" },
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

SitterRequestSchema.index({ location: "2dsphere" });
SitterRequestSchema.index({ status: 1, createdAt: -1 });

export default mongoose.model("SitterRequest", SitterRequestSchema);
