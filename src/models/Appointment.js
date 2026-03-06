import mongoose from "mongoose";

const AppointmentSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    petId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Pet",
      required: true,
    },
    veterinaryId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Veterinary",
      required: true,
      index: true,
    },

    date: { type: Date, required: true },
    endDate: { type: Date },
    reason: { type: String, trim: true, maxlength: 500 },
    notes: { type: String, trim: true, maxlength: 1000 },

    status: {
      type: String,
      enum: ["pending", "confirmed", "cancelled", "completed", "no_show"],
      default: "pending",
    },

    cancelledBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
    cancelReason: { type: String, trim: true },
    vetNotes: { type: String, trim: true, maxlength: 2000 },
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

AppointmentSchema.index({ userId: 1, date: -1 });
AppointmentSchema.index({ veterinaryId: 1, date: 1 });
AppointmentSchema.index({ petId: 1, date: -1 });
AppointmentSchema.index({ status: 1 });

export default mongoose.model("Appointment", AppointmentSchema);
