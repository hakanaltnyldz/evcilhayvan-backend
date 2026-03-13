import mongoose from "mongoose";

const CategorySchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    slug: { type: String, required: true, trim: true },
    icon: { type: String, trim: true, default: null },
    color: { type: String, trim: true, default: "#6C5CE7" },
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
    toObject: { virtuals: true },
  }
);

// Unique index'leri ayrı tanımla (MongoDB'de var olanları kontrol eder)
CategorySchema.index({ name: 1 }, { unique: true, background: true });
CategorySchema.index({ slug: 1 }, { unique: true, background: true });

export default mongoose.model("Category", CategorySchema);
