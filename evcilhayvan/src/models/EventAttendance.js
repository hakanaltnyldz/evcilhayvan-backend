import mongoose from "mongoose";

const EventAttendanceSchema = new mongoose.Schema(
  {
    eventId: { type: mongoose.Schema.Types.ObjectId, ref: "PetEvent", required: true },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    petIds: [{ type: mongoose.Schema.Types.ObjectId, ref: "Pet" }],
    status: { type: String, enum: ["going", "interested", "not_going"], default: "going" },
    note: { type: String, trim: true, maxlength: 200 },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform(_doc, ret) { ret.id = ret._id; delete ret.__v; },
    },
  }
);

EventAttendanceSchema.index({ eventId: 1, userId: 1 }, { unique: true });
EventAttendanceSchema.index({ userId: 1 });

export default mongoose.model("EventAttendance", EventAttendanceSchema);
