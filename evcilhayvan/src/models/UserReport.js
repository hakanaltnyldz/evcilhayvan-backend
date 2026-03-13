import mongoose from "mongoose";

const UserReportSchema = new mongoose.Schema(
  {
    reporterId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    reportedId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    reason: {
      type: String,
      enum: ["spam", "harassment", "inappropriate_content", "fake_profile", "other"],
      required: true,
    },
    description: { type: String, trim: true, maxlength: 500 },
    status: { type: String, enum: ["pending", "reviewed", "dismissed"], default: "pending" },
  },
  { timestamps: true }
);

UserReportSchema.index({ reporterId: 1, reportedId: 1 }, { unique: true });
UserReportSchema.index({ reportedId: 1, status: 1 });

export default mongoose.model("UserReport", UserReportSchema);
