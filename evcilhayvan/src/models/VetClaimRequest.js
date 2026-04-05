import mongoose from "mongoose";

const VetClaimRequestSchema = new mongoose.Schema(
  {
    vetId: { type: mongoose.Schema.Types.ObjectId, ref: "Veterinary", required: true },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    // Kullanıcının sunduğu kanıt bilgileri
    fullName: { type: String, required: true },
    phone: { type: String, required: true },
    role: { type: String, required: true }, // e.g. "veteriner", "klinik sahibi", "çalışan"
    note: { type: String, default: "" }, // ek açıklama
    // Admin kararı
    status: { type: String, enum: ["pending", "approved", "rejected"], default: "pending" },
    adminNote: { type: String, default: "" },
    reviewedBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
    reviewedAt: { type: Date },
  },
  { timestamps: true }
);

// Aynı vet için birden fazla bekleyen talep olamaz
VetClaimRequestSchema.index({ vetId: 1, userId: 1 }, { unique: true });

export default mongoose.model("VetClaimRequest", VetClaimRequestSchema);
