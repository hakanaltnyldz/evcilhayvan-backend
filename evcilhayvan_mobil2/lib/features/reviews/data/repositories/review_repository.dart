// lib/features/reviews/data/repositories/review_repository.dart

import 'package:dio/dio.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/features/reviews/domain/models/review_model.dart';

class ReviewRepository {
  final Dio _dio = ApiClient().dio;

  // Get all reviews for a product
  Future<List<ReviewModel>> getProductReviews({
    required String productId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/api/products/$productId/reviews',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> reviews = response.data['reviews'] ?? [];
        return reviews.map((json) => ReviewModel.fromJson(json)).toList();
      }

      throw Exception('Yorumlar yüklenemedi');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Yorumlar yüklenemedi');
    }
  }

  // Get review statistics
  Future<ReviewStats> getReviewStats({required String productId}) async {
    try {
      final response = await _dio.get('/api/products/$productId/reviews/stats');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ReviewStats.fromJson(response.data);
      }

      throw Exception('İstatistikler yüklenemedi');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'İstatistikler yüklenemedi');
    }
  }

  // Check if user can review a product
  Future<Map<String, dynamic>> canReview({required String productId}) async {
    try {
      final response = await _dio.get('/api/products/$productId/reviews/can-review');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'canReview': response.data['canReview'] ?? false,
          'reason': response.data['reason'],
          'existingReview': response.data['existingReview'] != null
              ? ReviewModel.fromJson(response.data['existingReview'])
              : null,
        };
      }

      throw Exception('Kontrol yapılamadı');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Kontrol yapılamadı');
    }
  }

  // Get user's review for a product
  Future<ReviewModel?> getUserReview({required String productId}) async {
    try {
      final response = await _dio.get('/api/products/$productId/reviews/my-review');

      if (response.statusCode == 200 && response.data['success'] == true) {
        if (response.data['review'] != null) {
          return ReviewModel.fromJson(response.data['review']);
        }
        return null;
      }

      throw Exception('Yorum yüklenemedi');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Yorum yüklenemedi');
    }
  }

  // Create a review
  Future<ReviewModel> createReview({
    required String productId,
    required int rating,
    String comment = '',
  }) async {
    try {
      final response = await _dio.post(
        '/api/products/$productId/reviews',
        data: {
          'rating': rating,
          'comment': comment,
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return ReviewModel.fromJson(response.data['review']);
      }

      throw Exception('Yorum eklenemedi');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Yorum eklenemedi');
    }
  }

  // Update a review
  Future<ReviewModel> updateReview({
    required String reviewId,
    required int rating,
    String comment = '',
  }) async {
    try {
      final response = await _dio.put(
        '/api/reviews/$reviewId',
        data: {
          'rating': rating,
          'comment': comment,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ReviewModel.fromJson(response.data['review']);
      }

      throw Exception('Yorum güncellenemedi');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Yorum güncellenemedi');
    }
  }

  // Delete a review
  Future<void> deleteReview({required String reviewId}) async {
    try {
      final response = await _dio.delete('/api/reviews/$reviewId');

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception('Yorum silinemedi');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Yorum silinemedi');
    }
  }
}
