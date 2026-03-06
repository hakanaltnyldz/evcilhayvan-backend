import mongoose from "mongoose";

const HealthRecordSchema = new mongoose.Schema(
  {
    petId: { type: mongoose.Schema.Types.ObjectId, ref: "Pet", required: true, index: true },
    ownerId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    type: {
      type: String,
      enum: ["weight", "medication", "vet_visit", "note"],
      required: true,
    },
    date: { type: Date, required: true },
    // Weight
    weightKg: { type: Number, min: 0 },
    // Medication
    medicationName: { type: String, trim: true, maxlength: 100 },
    dosage: { type: String, trim: true, maxlength: 100 },
    frequency: { type: String, trim: true, maxlength: 100 },
    // Vet visit
    vetName: { type: String, trim: true, maxlength: 100 },
    diagnosis: { type: String, trim: true, maxlength: 500 },
    // General note / all types
    notes: { type: String, trim: true, maxlength: 1000 },
  },
  { timestamps: true }
);

HealthRecordSchema.index({ petId: 1, date: -1 });
HealthRecordSchema.index({ petId: 1, type: 1 });

export default mongoose.model("HealthRecord", HealthRecordSchema);
