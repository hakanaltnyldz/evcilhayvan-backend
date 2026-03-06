import mongoose from "mongoose";

const LostFoundPetSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
    type: { type: String, enum: ["lost", "found"], required: true },
    status: { type: String, enum: ["active", "reunited", "cancelled"], default: "active" },
    petName: { type: String, trim: true, maxlength: 80 },
    species: { type: String, enum: ["dog", "cat", "bird", "rabbit", "other"], required: true },
    breed: { type: String, trim: true },
    gender: { type: String, enum: ["male", "female", "unknown"], default: "unknown" },
    color: { type: String, required: true, trim: true, maxlength: 100 },
    ageApprox: { type: String, trim: true },
    description: { type: String, required: true, trim: true, maxlength: 2000 },
    photos: { type: [String], default: [] },
    location: {
      type: { type: String, enum: ["Point"], default: "Point" },
      coordinates: {
        type: [Number],
        default: [0, 0],
        validate: {
          validator: function (coords) {
            return Array.isArray(coords) && coords.length === 2 && coords.every((n) => typeof n === "number");
          },
          message: "location.coordinates must be an array of two numbers [lng, lat]",
        },
      },
    },
    lastSeenDate: { type: Date, required: true },
    lastSeenAddress: { type: String, trim: true, maxlength: 300 },
    contactPhone: { type: String, trim: true },
    contactNote: { type: String, trim: true, maxlength: 500 },
    reward: { type: Number, min: 0, default: 0 },
    resolvedAt: { type: Date },
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

LostFoundPetSchema.index({ location: "2dsphere" });
LostFoundPetSchema.index({ type: 1, status: 1, createdAt: -1 });

export default mongoose.model("LostFoundPet", LostFoundPetSchema);
