import mongoose from "mongoose";

const WorkingHoursSchema = new mongoose.Schema(
  {
    day: { type: Number, min: 0, max: 6 }, // 0=Pazartesi ... 6=Pazar
    open: { type: String }, // "09:00"
    close: { type: String }, // "18:00"
    isClosed: { type: Boolean, default: false },
  },
  { _id: false }
);

const VeterinarySchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true, maxlength: 200 },
    address: { type: String, trim: true },
    phone: { type: String, trim: true },
    email: { type: String, trim: true, lowercase: true },
    website: { type: String, trim: true },
    description: { type: String, trim: true, maxlength: 1000 },
    photos: { type: [String], default: [] },

    location: {
      type: { type: String, enum: ["Point"], default: "Point" },
      coordinates: { type: [Number], default: [0, 0] },
    },

    // Kaynak takibi
    source: {
      type: String,
      enum: ["google_places", "manual"],
      default: "manual",
    },
    googlePlaceId: { type: String, unique: true, sparse: true },
    googleRating: { type: Number, min: 0, max: 5 },
    googleReviewCount: { type: Number, default: 0 },

    // Manuel kayit alanlari
    registeredBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
    // Klinigi sahiplenen kullanici hesabi (mesajlasma, randevu yonetimi icin)
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", default: null },
    isVerified: { type: Boolean, default: false },
    isActive: { type: Boolean, default: true },

    // Sunulan hizmetler
    services: {
      type: [String],
      default: [],
    },

    // Randevu destegi
    acceptsOnlineAppointments: { type: Boolean, default: false },
    appointmentSlotMinutes: { type: Number, default: 30 },
    workingHours: { type: [WorkingHoursSchema], default: [] },

    // Hizmet verilen turler
    speciesServed: {
      type: [String],
      enum: ["dog", "cat", "bird", "fish", "rodent", "other"],
      default: ["dog", "cat", "bird", "fish", "rodent", "other"],
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

VeterinarySchema.index({ location: "2dsphere" });
VeterinarySchema.index({ name: "text", address: "text" });
VeterinarySchema.index({ source: 1, isActive: 1 });

export default mongoose.model("Veterinary", VeterinarySchema);
