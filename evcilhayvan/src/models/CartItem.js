import mongoose from "mongoose";

const SelectedVariantSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    label: { type: String, required: true, trim: true },
  },
  { _id: false }
);

const CartItemSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
    product: { type: mongoose.Schema.Types.ObjectId, ref: "Product", required: true },
    quantity: { type: Number, required: true, min: 1 },
    selectedVariants: { type: [SelectedVariantSchema], default: [] },
    variantKey: { type: String, default: "default", trim: true },
  },
  {
    timestamps: true,
    toJSON: {
      transform(_doc, ret) {
        ret.id = ret._id;
        if (!Array.isArray(ret.selectedVariants)) ret.selectedVariants = [];
        const primaryVariant = ret.selectedVariants[0] || null;
        ret.variantName = primaryVariant?.name || null;
        ret.variantLabel = primaryVariant?.label || null;
        delete ret.variantKey;
        delete ret._id;
        delete ret.__v;
        return ret;
      },
    },
  }
);

CartItemSchema.index({ user: 1, product: 1, variantKey: 1 }, { unique: true });

export default mongoose.model("CartItem", CartItemSchema);
