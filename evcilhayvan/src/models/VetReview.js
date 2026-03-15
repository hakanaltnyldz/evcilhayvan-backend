import mongoose from "mongoose";

const VetReviewSchema = new mongoose.Schema(
  {
    vet: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Veterinary",
      required: true,
    },
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    rating: { type: Number, required: true, min: 1, max: 5 },
    comment: { type: String, trim: true, maxlength: 500 },
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

// Her kullanıcı bir vete yalnızca bir yorum yapabilir
VetReviewSchema.index({ vet: 1, user: 1 }, { unique: true });

// Yorum eklenince/silinince veteriner ortalama puanını güncelle
async function updateVetRating(vetId) {
  const result = await mongoose.model("VetReview").aggregate([
    { $match: { vet: new mongoose.Types.ObjectId(vetId) } },
    { $group: { _id: "$vet", avg: { $avg: "$rating" }, count: { $sum: 1 } } },
  ]);
  const avg = result[0]?.avg ?? 0;
  const count = result[0]?.count ?? 0;
  await mongoose
    .model("Veterinary")
    .findByIdAndUpdate(vetId, { averageRating: Math.round(avg * 10) / 10, reviewCount: count });
}

VetReviewSchema.post("save", async function () {
  await updateVetRating(this.vet);
});

VetReviewSchema.post("findOneAndDelete", async function (doc) {
  if (doc) await updateVetRating(doc.vet);
});

export default mongoose.model("VetReview", VetReviewSchema);
