import mongoose from "mongoose";

const interactionSchema = new mongoose.Schema(
  {
    fromUser: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    toPet:    { type: mongoose.Schema.Types.ObjectId, ref: "Pet",  required: true },
    type:     { type: String, enum: ["like", "pass"], required: true },
  },
  { timestamps: true }
);

interactionSchema.index({ fromUser: 1, toPet: 1 }, { unique: true });

export default mongoose.model("Interaction", interactionSchema);
