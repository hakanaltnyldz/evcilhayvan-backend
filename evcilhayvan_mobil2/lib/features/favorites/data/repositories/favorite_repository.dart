// lib/features/favorites/data/repositories/favorite_repository.dart

import 'package:dio/dio.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/features/favorites/domain/models/favorite_model.dart';

class FavoriteRepository {
  final Dio _dio = ApiClient().dio;

  // Get all favorites with optional type filter
  Future<List<FavoriteModel>> getFavorites({String? type}) async {
    try {
      final queryParams = type != null ? {'type': type} : null;
      final response = await _dio.get(
        '/api/favorites',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> favorites = response.data['favorites'] ?? [];
        return favorites.map((json) => FavoriteModel.fromJson(json)).toList();
      }

      throw Exception('Favoriler yüklenemedi');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Favoriler yüklenemedi');
    }
  }

  // Add item to favorites
  Future<FavoriteModel> addFavorite({
    required String itemType,
    required String itemId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/favorites',
        data: {
          'itemType': itemType,
          'itemId': itemId,
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return FavoriteModel.fromJson(response.data['favorite']);
      }

      throw Exception('Favorilere eklenemedi');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Favorilere eklenemedi');
    }
  }

  // Remove item from favorites
  Future<void> removeFavorite({
    required String itemType,
    required String itemId,
  }) async {
    try {
      final response = await _dio.delete(
        '/api/favorites',
        data: {
          'itemType': itemType,
          'itemId': itemId,
        },
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception('Favorilerden kaldırılamadı');
      }
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Favorilerden kaldırılamadı');
    }
  }

  // Check if item is favorited
  Future<bool> checkFavorite({
    required String itemType,
    required String itemId,
  }) async {
    try {
      final response = await _dio.get(
        '/api/favorites/check',
        queryParameters: {
          'itemType': itemType,
          'itemId': itemId,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['isFavorite'] ?? false;
      }

      return false;
    } on DioException catch (_) {
      return false;
    }
  }

  // Get favorites count by type
  Future<Map<String, int>> getFavoritesCount() async {
    try {
      final response = await _dio.get('/api/favorites/count');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final counts = response.data['counts'];
        return {
          'pet': counts['pet'] ?? 0,
          'product': counts['product'] ?? 0,
          'store': counts['store'] ?? 0,
          'total': counts['total'] ?? 0,
        };
      }

      return {'pet': 0, 'product': 0, 'store': 0, 'total': 0};
    } on DioException catch (_) {
      return {'pet': 0, 'product': 0, 'store': 0, 'total': 0};
    }
  }
}
