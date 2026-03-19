// lib/features/reviews/providers/review_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evcilhayvan_mobil2/features/reviews/data/repositories/review_repository.dart';
import 'package:evcilhayvan_mobil2/features/reviews/domain/models/review_model.dart';

// Repository provider
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository();
});

// Get product reviews
final productReviewsProvider = FutureProvider.autoDispose
    .family<List<ReviewModel>, String>((ref, productId) async {
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.getProductReviews(productId: productId);
});

// Get review stats
final reviewStatsProvider = FutureProvider.autoDispose
    .family<ReviewStats, String>((ref, productId) async {
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.getReviewStats(productId: productId);
});

// Get user's review
final userReviewProvider = FutureProvider.autoDispose
    .family<ReviewModel?, String>((ref, productId) async {
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.getUserReview(productId: productId);
});

// Check if user can review
final canReviewProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, productId) async {
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.canReview(productId: productId);
});
