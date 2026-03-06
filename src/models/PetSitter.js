import mongoose from "mongoose";

const ServiceSchema = new mongoose.Schema(
  {
    type: { type: String, enum: ["walking", "home_sitting", "boarding", "daycare", "grooming"], required: true },
    pricePerHour: { type: Number, min: 0, default: 0 },
    pricePerDay: { type: Number, min: 0, default: 0 },
  },
  { _id: false }
);

const WorkingHourSchema = new mongoose.Schema(
  {
    day: { type: Number, min: 0, max: 6 }, // 0=Paz, 1=Pzt...
    start: { type: String, default: "09:00" },
    end: { type: String, default: "18:00" },
  },
  { _id: false }
);

const PetSitterSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, unique: true, index: true },
    displayName: { type: String, required: true, trim: true, maxlength: 80 },
    bio: { type: String, trim: true, maxlength: 1000 },
    avatar: { type: String },
    photos: { type: [String], default: [] },
    services: { type: [ServiceSchema], default: [] },
    speciesServed: {
      type: [String],
      enum: ["dog", "cat", "bird", "rabbit", "other"],
      default: ["dog", "cat"],
    },
    experience: { type: String, trim: true, maxlength: 500 },
    location: {
      type: { type: String, enum: ["Point"], default: "Point" },
      coordinates: {
        type: [Number],
        default: [0, 0],
        validate: {
          validator: (coords) => Array.isArray(coords) && coords.length === 2 && coords.every((n) => typeof n === "number"),
          message: "coordinates must be [lng, lat]",
        },
      },
    },
    address: { type: String, trim: true, maxlength: 300 },
    availability: { type: Boolean, default: true },
    workingHours: { type: [WorkingHourSchema], default: [] },
    rating: { type: Number, default: 0, min: 0, max: 5 },
    reviewCount: { type: Number, default: 0 },
    isVerified: { type: Boolean, default: false },
    isActive: { type: Boolean, default: true },
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

PetSitterSchema.index({ location: "2dsphere" });
PetSitterSchema.index({ isActive: 1, availability: 1 });

export default mongoose.model("PetSitter", PetSitterSchema);
