import mongoose from "mongoose";
import VetReview from "../models/VetReview.js";
import { sendOk, sendError } from "../utils/apiResponse.js";

function getAuthUserId(req) {
  return req.user?.sub || req.user?.id || req.user?._id || null;
}

// GET /api/veterinaries/:vetId/reviews
export async function getVetReviews(req, res) {
  try {
    const { vetId } = req.params;
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 20;

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

    return sendOk(res, 200, {
      reviews,
      total,
      page,
      averageRating: Math.round((avgResult[0]?.avg ?? 0) * 10) / 10,
      ratingCount: avgResult[0]?.count ?? 0,
    });
  } catch {
    return sendError(res, 500, "Veteriner yorumlari alinamadi", "internal_error");
  }
}

// POST /api/veterinaries/:vetId/reviews
export async function addVetReview(req, res) {
  try {
    const { vetId } = req.params;
    const { rating, comment, subRatings } = req.body;
    const userId = getAuthUserId(req);

    if (!userId) {
      return sendError(res, 401, "Oturum gerekli", "unauthorized");
    }

    if (!rating || rating < 1 || rating > 5) {
      return sendError(res, 400, "Puan 1-5 arasinda olmalidir", "validation_error");
    }

    const subRatingsData = subRatings ? {
      cleanliness:   subRatings.cleanliness   ? Math.min(5, Math.max(1, Number(subRatings.cleanliness)))   : undefined,
      communication: subRatings.communication ? Math.min(5, Math.max(1, Number(subRatings.communication))) : undefined,
      value:         subRatings.value         ? Math.min(5, Math.max(1, Number(subRatings.value)))         : undefined,
    } : undefined;

    const existing = await VetReview.findOne({ vet: vetId, user: userId });
    if (existing) {
      existing.rating = rating;
      if (comment !== undefined) existing.comment = comment;
      if (subRatingsData) existing.subRatings = subRatingsData;
      await existing.save();
      await existing.populate("user", "name avatarUrl");
      return sendOk(res, 200, { review: existing });
    }

    const review = await VetReview.create({ vet: vetId, user: userId, rating, comment, subRatings: subRatingsData });
    await review.populate("user", "name avatarUrl");
    return sendOk(res, 201, { review });
  } catch (err) {
    if (err.code === 11000) {
      return sendError(res, 409, "Bu veterinere zaten yorum yaptiniz", "duplicate_review");
    }
    return sendError(res, 500, "Veteriner yorumu kaydedilemedi", "internal_error");
  }
}

// DELETE /api/veterinaries/reviews/:reviewId
export async function deleteVetReview(req, res) {
  try {
    const { reviewId } = req.params;
    const userId = getAuthUserId(req);

    if (!userId) {
      return sendError(res, 401, "Oturum gerekli", "unauthorized");
    }

    const review = await VetReview.findById(reviewId);
    if (!review) {
      return sendError(res, 404, "Yorum bulunamadi", "not_found");
    }

    if (review.user.toString() !== String(userId)) {
      return sendError(res, 403, "Bu yorumu silemezsiniz", "forbidden");
    }

    await VetReview.findByIdAndDelete(reviewId);
    return sendOk(res, 200, { message: "Yorum silindi" });
  } catch {
    return sendError(res, 500, "Veteriner yorumu silinemedi", "internal_error");
  }
}
