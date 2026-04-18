import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import '../../domain/models/lost_found_model.dart';

final lostFoundRepositoryProvider = Provider<LostFoundRepository>((ref) {
  final client = ApiClient();
  return LostFoundRepository(client);
});

class LostFoundRepository {
  LostFoundRepository(this._client);
  final ApiClient _client;
  Dio get _dio => _client.dio;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw ApiError.fromDio(e);
    } catch (e) {
      throw ApiError(e.toString());
    }
  }

  Future<List<LostFoundPet>> listReports({
    String? type,
    String? species,
    double? lat,
    double? lng,
    double radiusKm = 50,
    int page = 1,
  }) {
    return _guard(() async {
      final response = await _dio.get('/api/lost-found', queryParameters: {
        if (type != null) 'type': type,
        if (species != null) 'species': species,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'radiusKm': radiusKm,
        'status': 'active',
        'page': page,
        'limit': 20,
      });
      final List<dynamic> list = response.data['reports'] ?? [];
      return list.map((j) => LostFoundPet.fromJson(Map<String, dynamic>.from(j))).toList();
    });
  }

  Future<List<LostFoundPet>> nearbyReports({
    required double lat,
    required double lng,
    double radiusKm = 20,
  }) {
    return _guard(() async {
      final response = await _dio.get('/api/lost-found/near', queryParameters: {
        'lat': lat,
        'lng': lng,
        'radiusKm': radiusKm,
      });
      final List<dynamic> list = response.data['reports'] ?? [];
      return list.map((j) => LostFoundPet.fromJson(Map<String, dynamic>.from(j))).toList();
    });
  }

  Future<LostFoundPet> getReport(String id) {
    return _guard(() async {
      final response = await _dio.get('/api/lost-found/$id');
      return LostFoundPet.fromJson(Map<String, dynamic>.from(response.data['report']));
    });
  }

  Future<LostFoundPet> createReport(Map<String, dynamic> data) {
    return _guard(() async {
      final response = await _dio.post('/api/lost-found', data: data);
      return LostFoundPet.fromJson(Map<String, dynamic>.from(response.data['report']));
    });
  }

  Future<LostFoundPet> updateReport(String id, Map<String, dynamic> data) {
    return _guard(() async {
      final response = await _dio.put('/api/lost-found/$id', data: data);
      return LostFoundPet.fromJson(Map<String, dynamic>.from(response.data['report']));
    });
  }

  Future<void> updateStatus(String id, String status) {
    return _guard(() async {
      await _dio.patch('/api/lost-found/$id/status', data: {'status': status});
    });
  }

  Future<void> deleteReport(String id) {
    return _guard(() async {
      await _dio.delete('/api/lost-found/$id');
    });
  }

  Future<List<LostFoundPet>> myReports() {
    return _guard(() async {
      final response = await _dio.get('/api/lost-found/me');
      final List<dynamic> list = response.data['reports'] ?? [];
      return list.map((j) => LostFoundPet.fromJson(Map<String, dynamic>.from(j))).toList();
    });
  }
}

// Providers
class LostFoundListParams {
  final String? type;
  final double? lat;
  final double? lng;

  const LostFoundListParams({this.type, this.lat, this.lng});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LostFoundListParams && type == other.type && lat == other.lat && lng == other.lng;

  @override
  int get hashCode => Object.hash(type, lat, lng);
}

final lostFoundListProvider =
    FutureProvider.autoDispose.family<List<LostFoundPet>, LostFoundListParams>((ref, params) {
  final repo = ref.watch(lostFoundRepositoryProvider);
  return repo.listReports(type: params.type, lat: params.lat, lng: params.lng);
});

final lostFoundDetailProvider =
    FutureProvider.autoDispose.family<LostFoundPet, String>((ref, id) {
  final repo = ref.watch(lostFoundRepositoryProvider);
  return repo.getReport(id);
});

final myLostFoundReportsProvider = FutureProvider.autoDispose<List<LostFoundPet>>((ref) {
  final repo = ref.watch(lostFoundRepositoryProvider);
  return repo.myReports();
});
