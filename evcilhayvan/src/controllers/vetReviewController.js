import mongoose from "mongoose";
import VetReview from "../models/VetReview.js";

// GET /api/veterinaries/:vetId/reviews
export async function getVetReviews(req, res) {
  try {
    const { vetId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;

    const [reviews, total] = await Promise.all([
      VetReview.find({ vet: vetId })
        .populate("user", "name avatarUrl")
        .sort({ createdAt: -1 })
        .skip((page - 1) * limit)
        .limit(limit),
      VetReview.countDocuments({ vet: vetId }),
    ]);

    const avgResult = await VetReview.aggregate([
      { $match: { vet: new mongoose.Types.ObjectId(vetId) } },
      { $group: { _id: null, avg: { $avg: "$rating" }, count: { $sum: 1 } } },
    ]);

    res.json({
      reviews,
      total,
      page,
      averageRating: Math.round((avgResult[0]?.avg ?? 0) * 10) / 10,
      ratingCount: avgResult[0]?.count ?? 0,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

// POST /api/veterinaries/:vetId/reviews
export async function addVetReview(req, res) {
  try {
    const { vetId } = req.params;
    const { rating, comment } = req.body;

    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({ error: "Puan 1-5 arasında olmalıdır." });
    }

    const existing = await VetReview.findOne({ vet: vetId, user: req.user.id });
    if (existing) {
      existing.rating = rating;
      if (comment !== undefined) existing.comment = comment;
      await existing.save();
      await existing.populate("user", "name avatarUrl");
      return res.json({ review: existing });
    }

    const review = await VetReview.create({ vet: vetId, user: req.user.id, rating, comment });
    await review.populate("user", "name avatarUrl");
    res.status(201).json({ review });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(409).json({ error: "Bu veterinere zaten yorum yaptınız." });
    }
    res.status(500).json({ error: err.message });
  }
}

// DELETE /api/veterinaries/reviews/:reviewId
export async function deleteVetReview(req, res) {
  try {
    const { reviewId } = req.params;
    const review = await VetReview.findById(reviewId);
    if (!review) return res.status(404).json({ error: "Yorum bulunamadı." });
    if (review.user.toString() !== req.user.id) {
      return res.status(403).json({ error: "Bu yorumu silemezsiniz." });
    }
    await VetReview.findByIdAndDelete(reviewId);
    res.json({ message: "Yorum silindi." });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}
