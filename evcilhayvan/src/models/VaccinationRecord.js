import mongoose from "mongoose";

const VaccinationRecordSchema = new mongoose.Schema(
  {
    petId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Pet",
      required: true,
      index: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    veterinaryId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Veterinary",
    },

    vaccineName: { type: String, required: true, trim: true },
    vaccineCode: { type: String, trim: true },
    batchNumber: { type: String, trim: true },

    dateAdministered: { type: Date, required: true },
    nextDueDate: { type: Date },
    reminderSent: { type: Boolean, default: false },

    notes: { type: String, trim: true, maxlength: 500 },
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

VaccinationRecordSchema.index({ petId: 1, dateAdministered: -1 });
VaccinationRecordSchema.index({ nextDueDate: 1, reminderSent: 1 });

export default mongoose.model("VaccinationRecord", VaccinationRecordSchema);
