import mongoose from "mongoose";

const VaccinationScheduleSchema = new mongoose.Schema(
  {
    species: {
      type: String,
      enum: ["dog", "cat", "bird", "fish", "rodent", "other"],
      required: true,
    },
    vaccineName: { type: String, required: true, trim: true },
    vaccineCode: { type: String, required: true, trim: true },
    description: { type: String, trim: true },

    firstDoseMonths: { type: Number, required: true },
    secondDoseMonths: { type: Number },
    repeatIntervalMonths: { type: Number },

    isRequired: { type: Boolean, default: true },
    isActive: { type: Boolean, default: true },
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

VaccinationScheduleSchema.index({ species: 1, isActive: 1 });

export default mongoose.model("VaccinationSchedule", VaccinationScheduleSchema);
