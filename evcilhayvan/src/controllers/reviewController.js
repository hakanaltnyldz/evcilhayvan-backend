// src/controllers/reviewController.js

import Review from '../models/Review.js';
import Product from '../models/Product.js';
import Order from '../models/Order.js';
import mongoose from 'mongoose';
import { sendOk, sendError } from '../utils/apiResponse.js';

// Get all reviews for a product
export const getProductReviews = async (req, res) => {
  try {
    const { productId } = req.params;
    const { page = 1, limit = 10, sort = '-createdAt' } = req.query;

    const reviews = await Review.find({ product: productId })
      .populate('user', 'name profilePicture avatarUrl')
      .sort(sort)
      .limit(parseInt(limit))
      .skip((parseInt(page) - 1) * parseInt(limit));

    const total = await Review.countDocuments({ product: productId });

    return sendOk(res, 200, {
      reviews,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / parseInt(limit)),
      },
    });
  } catch (error) {
    console.error('Get product reviews error:', error);
    return sendError(res, 500, 'Yorumlar yüklenirken hata oluştu', 'internal_error', error.message);
  }
};

// Create a review
export const createReview = async (req, res) => {
  try {
    const { productId } = req.params;
    const { rating, comment = '' } = req.body;
    const userId = req.user.sub || req.user._id;

    // Validate rating
    if (!rating || rating < 1 || rating > 5) {
      return sendError(res, 400, 'Geçersiz puan. 1-5 arası bir değer giriniz.', 'validation_error');
    }

    // Check if product exists
    const product = await Product.findById(productId);
    if (!product) {
      return sendError(res, 404, 'Ürün bulunamadı', 'product_not_found');
    }

    // Check if user has purchased the product
    const hasPurchased = await Order.hasPurchased(userId, productId);
    if (!hasPurchased) {
      return sendError(res, 403, 'Bu ürünü satın almadığınız için yorum yapamazsınız', 'not_purchased');
    }

    // Check if user already reviewed this product
    const existingReview = await Review.findOne({
      product: productId,
      user: userId,
    });

    if (existingReview) {
      return sendError(res, 400, 'Bu ürün için zaten yorum yaptınız', 'already_reviewed');
    }

    // Create review
    const review = await Review.create({
      product: productId,
      user: userId,
      rating: parseInt(rating),
      comment: comment.trim(),
      verifiedPurchase: true,
    });

    const populatedReview = await Review.findById(review._id).populate(
      'user',
      'name profilePicture avatarUrl'
    );

    return sendOk(res, 201, { message: 'Yorum başarıyla eklendi', review: populatedReview });
  } catch (error) {
    console.error('Create review error:', error);
    return sendError(res, 500, 'Yorum eklenirken hata oluştu', 'internal_error', error.message);
  }
};

// Update a review
export const updateReview = async (req, res) => {
  try {
    const { reviewId } = req.params;
    const { rating, comment } = req.body;
    const userId = req.user.sub || req.user._id;

    // Find review
    const review = await Review.findById(reviewId);
    if (!review) {
      return sendError(res, 404, 'Yorum bulunamadı', 'review_not_found');
    }

    // Check ownership
    if (review.user.toString() !== userId.toString()) {
      return sendError(res, 403, 'Bu yorumu güncelleme yetkiniz yok', 'forbidden');
    }

    // Validate rating if provided
    if (rating !== undefined && (rating < 1 || rating > 5)) {
      return sendError(res, 400, 'Geçersiz puan. 1-5 arası bir değer giriniz.', 'validation_error');
    }

    // Update fields
    if (rating !== undefined) review.rating = parseInt(rating);
    if (comment !== undefined) review.comment = comment.trim();

    await review.save();

    const populatedReview = await Review.findById(review._id).populate(
      'user',
      'name profilePicture avatarUrl'
    );

    return sendOk(res, 200, { message: 'Yorum başarıyla güncellendi', review: populatedReview });
  } catch (error) {
    console.error('Update review error:', error);
    return sendError(res, 500, 'Yorum güncellenirken hata oluştu', 'internal_error', error.message);
  }
};

// Delete a review
export const deleteReview = async (req, res) => {
  try {
    const { reviewId } = req.params;
    const userId = req.user.sub || req.user._id;

    // Find review
    const review = await Review.findById(reviewId);
    if (!review) {
      return sendError(res, 404, 'Yorum bulunamadı', 'review_not_found');
    }

    // Check ownership
    if (review.user.toString() !== userId.toString()) {
      return sendError(res, 403, 'Bu yorumu silme yetkiniz yok', 'forbidden');
    }

    await Review.findByIdAndDelete(reviewId);

    return sendOk(res, 200, { message: 'Yorum başarıyla silindi' });
  } catch (error) {
    console.error('Delete review error:', error);
    return sendError(res, 500, 'Yorum silinirken hata oluştu', 'internal_error', error.message);
  }
};

// Get user's review for a product
export const getUserReview = async (req, res) => {
  try {
    const { productId } = req.params;
    const userId = req.user.sub || req.user._id;

    const review = await Review.findOne({
      product: productId,
      user: userId,
    }).populate('user', 'name profilePicture avatarUrl');

    return sendOk(res, 200, { review: review || null });
  } catch (error) {
    console.error('Get user review error:', error);
    return sendError(res, 500, 'Yorum yüklenirken hata oluştu', 'internal_error', error.message);
  }
};

// Check if user can review a product
export const canReview = async (req, res) => {
  try {
    const { productId } = req.params;
    const userId = req.user.sub || req.user._id;

    // Check if product exists
    const product = await Product.findById(productId);
    if (!product) {
      return sendError(res, 404, 'Ürün bulunamadı', 'product_not_found');
    }

    // Check if already reviewed
    const existingReview = await Review.findOne({
      product: productId,
      user: userId,
    });

    if (existingReview) {
      return sendOk(res, 200, {
        canReview: false,
        reason: 'already_reviewed',
        existingReview,
      });
    }

    // Check if purchased
    const hasPurchased = await Order.hasPurchased(userId, productId);
    if (!hasPurchased) {
      return sendOk(res, 200, {
        canReview: false,
        reason: 'not_purchased',
      });
    }

    return sendOk(res, 200, { canReview: true });
  } catch (error) {
    console.error('Can review error:', error);
    return sendError(res, 500, 'Kontrol yapılırken hata oluştu', 'internal_error', error.message);
  }
};

// Get review statistics for a product
export const getReviewStats = async (req, res) => {
  try {
    const { productId } = req.params;

    const stats = await Review.aggregate([
      { $match: { product: new mongoose.Types.ObjectId(productId) } },
      {
        $group: {
          _id: '$rating',
          count: { $sum: 1 },
        },
      },
      { $sort: { _id: -1 } },
    ]);

    const total = await Review.countDocuments({ product: productId });
    const product = await Product.findById(productId);

    // Format stats
    const ratingDistribution = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 };
    stats.forEach((stat) => {
      ratingDistribution[stat._id] = stat.count;
    });

    return sendOk(res, 200, {
      stats: {
        averageRating: product?.averageRating || 0,
        totalReviews: total,
        distribution: ratingDistribution,
      },
    });
  } catch (error) {
    console.error('Get review stats error:', error);
    return sendError(res, 500, 'İstatistikler yüklenirken hata oluştu', 'internal_error', error.message);
  }
};
