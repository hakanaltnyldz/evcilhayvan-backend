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
    diagnosis: { type: String, trim: true, maxlength: 500 },
    treatmentSummary: { type: String, trim: true, maxlength: 2000 },
    followUpDate: { type: Date },
    feeAmount: { type: Number, default: 0, min: 0 },
    completedAt: { type: Date },

    status: {
      type: String,
      enum: ["pending", "confirmed", "cancelled", "completed", "no_show"],
      default: "pending",
    },

    cancelledBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
    cancelReason: { type: String, trim: true },
    rescheduledAt: { type: Date },
    rescheduledBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
    rescheduleReason: { type: String, trim: true, maxlength: 500 },
    vetNotes: { type: String, trim: true, maxlength: 2000 },
    clinicalRecordUpdatedAt: { type: Date },

    reminderSent: { type: Boolean, default: false },

    type: { type: String, enum: ['clinic', 'online'], default: 'clinic' },
    meetingUrl: { type: String, default: null },
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
AppointmentSchema.index(
  { veterinaryId: 1, date: 1 },
  {
    unique: true,
    partialFilterExpression: {
      status: { $in: ["pending", "confirmed"] },
    },
  }
);
AppointmentSchema.index({ petId: 1, date: -1 });
AppointmentSchema.index({ status: 1 });

export default mongoose.model("Appointment", AppointmentSchema);
