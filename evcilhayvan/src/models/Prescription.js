import mongoose from "mongoose";

const MedicationSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true, maxlength: 120 },
    dosage: { type: String, trim: true, maxlength: 120 },
    frequency: { type: String, trim: true, maxlength: 120 },
    durationDays: { type: Number, min: 1, max: 365 },
    instructions: { type: String, trim: true, maxlength: 300 },
  },
  { _id: false }
);

const PrescriptionSchema = new mongoose.Schema(
  {
    appointmentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Appointment",
      required: true,
      index: true,
    },
    petId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Pet",
      required: true,
      index: true,
    },
    veterinaryId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Veterinary",
      required: true,
      index: true,
    },
    vetUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    ownerUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    diagnosis: { type: String, required: true, trim: true, maxlength: 500 },
    medications: { type: [MedicationSchema], default: [] },
    notes: { type: String, trim: true, maxlength: 1500 },
    followUpDate: { type: Date },
    status: {
      type: String,
      enum: ["active", "completed", "cancelled"],
      default: "active",
    },
    issuedAt: { type: Date, default: Date.now },
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

PrescriptionSchema.index({ appointmentId: 1, createdAt: -1 });
PrescriptionSchema.index({ petId: 1, createdAt: -1 });
PrescriptionSchema.index({ ownerUserId: 1, createdAt: -1 });

export default mongoose.model("Prescription", PrescriptionSchema);
