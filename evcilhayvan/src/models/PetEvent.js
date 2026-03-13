import mongoose from "mongoose";

const PetEventSchema = new mongoose.Schema(
  {
    organizerId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
    title: { type: String, required: true, trim: true, maxlength: 150 },
    description: { type: String, required: true, trim: true, maxlength: 3000 },
    category: {
      type: String,
      enum: ["park_meetup", "adoption_day", "training", "competition", "grooming", "health", "other"],
      required: true,
    },
    photos: { type: [String], default: [] },
    coverPhoto: { type: String },
    location: {
      type: { type: String, enum: ["Point"], default: "Point" },
      coordinates: {
        type: [Number],
        default: [0, 0],
        validate: {
          validator: (c) => Array.isArray(c) && c.length === 2 && c.every((n) => typeof n === "number"),
          message: "coordinates must be [lng, lat]",
        },
      },
    },
    address: { type: String, trim: true, maxlength: 300 },
    venueName: { type: String, trim: true, maxlength: 150 },
    startDate: { type: Date, required: true },
    endDate: { type: Date, required: true },
    maxAttendees: { type: Number, min: 1 },
    attendeeCount: { type: Number, default: 0 },
    isFree: { type: Boolean, default: true },
    price: { type: Number, min: 0, default: 0 },
    speciesAllowed: { type: [String], enum: ["dog", "cat", "bird", "rabbit", "other", "all"], default: ["all"] },
    tags: { type: [String], default: [] },
    isActive: { type: Boolean, default: true },
    isCancelled: { type: Boolean, default: false },
    externalLink: { type: String, trim: true },
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

PetEventSchema.index({ location: "2dsphere" });
PetEventSchema.index({ startDate: 1, isActive: 1 });
PetEventSchema.index({ category: 1, startDate: 1 });

export default mongoose.model("PetEvent", PetEventSchema);
