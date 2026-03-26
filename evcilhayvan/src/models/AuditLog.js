import mongoose from "mongoose";

const AuditLogSchema = new mongoose.Schema(
  {
    action: { type: String, required: true },
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: false },
    entityType: { type: String, required: false },
    entityId: { type: String, required: false },
    metadata: { type: mongoose.Schema.Types.Mixed },
  },
  {
    timestamps: true,
    toJSON: {
      transform(_doc, ret) {
        ret.id = ret._id;
        delete ret._id;
        delete ret.__v;
        return ret;
      },
    },
  }
);

AuditLogSchema.index({ action: 1, createdAt: -1 });  // Aksiyon bazlı sorgular
AuditLogSchema.index({ user: 1, createdAt: -1 });    // Kullanıcı bazlı sorgular
AuditLogSchema.index({ entityType: 1, entityId: 1 }); // Entity bazlı sorgular

export default mongoose.model("AuditLog", AuditLogSchema);
