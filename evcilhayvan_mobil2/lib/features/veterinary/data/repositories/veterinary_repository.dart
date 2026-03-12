import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import '../../domain/models/veterinary_model.dart';

final veterinaryRepositoryProvider = Provider<VeterinaryRepository>((ref) {
  return VeterinaryRepository(ApiClient());
});

final nearbyVetsProvider = FutureProvider.autoDispose.family<List<VeterinaryModel>, NearbyVetsParams>((ref, params) {
  final repo = ref.watch(veterinaryRepositoryProvider);
  return repo.searchVets(lat: params.lat, lng: params.lng, radiusKm: params.radiusKm, query: params.query);
});

final vetDetailProvider = FutureProvider.autoDispose.family<VeterinaryModel, String>((ref, id) {
  final repo = ref.watch(veterinaryRepositoryProvider);
  return repo.getVetDetail(id);
});

class NearbyVetsParams {
  final double? lat;
  final double? lng;
  final double radiusKm;
  final String? query;

  const NearbyVetsParams({this.lat, this.lng, this.radiusKm = 10, this.query});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NearbyVetsParams &&
          lat == other.lat &&
          lng == other.lng &&
          radiusKm == other.radiusKm &&
          query == other.query;

  @override
  int get hashCode => Object.hash(lat, lng, radiusKm, query);
}

class VeterinaryRepository {
  final ApiClient _client;
  VeterinaryRepository(this._client);
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

  Future<List<VeterinaryModel>> searchVets({
    double? lat,
    double? lng,
    double radiusKm = 10,
    String? query,
    String? species,
  }) {
    return _guard(() async {
      final params = <String, dynamic>{
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'radiusKm': radiusKm,
        if (query != null && query.isNotEmpty) 'q': query,
        if (species != null) 'species': species,
      };
      final response = await _dio.get('/api/veterinaries', queryParameters: params);
      final List<dynamic> list = (response.data['vets'] as List?) ?? [];
      return list.whereType<Map<String, dynamic>>().map(VeterinaryModel.fromJson).toList();
    });
  }

  Future<List<VeterinaryModel>> googleSearch({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) {
    return _guard(() async {
      final response = await _dio.get('/api/veterinaries/google-search', queryParameters: {
        'lat': lat,
        'lng': lng,
        'radiusKm': radiusKm,
      });
      final List<dynamic> list = (response.data['vets'] as List?) ?? [];
      return list.whereType<Map<String, dynamic>>().map(VeterinaryModel.fromJson).toList();
    });
  }

  Future<VeterinaryModel> getVetDetail(String id) {
    return _guard(() async {
      final response = await _dio.get('/api/veterinaries/$id');
      return VeterinaryModel.fromJson(response.data['vet']);
    });
  }

  Future<VeterinaryModel> claimVetProfile(String vetId) {
    return _guard(() async {
      final response = await _dio.post('/api/veterinaries/$vetId/claim');
      return VeterinaryModel.fromJson(response.data['vet']);
    });
  }

  // Vet ile conversation başlat veya mevcut olanı getir → conversationId döner
  Future<String> startConversationWithVet(String vetId) {
    return _guard(() async {
      final response = await _dio.post('/api/veterinaries/$vetId/conversation');
      final conv = response.data['conversation'] as Map<String, dynamic>;
      return conv['_id']?.toString() ?? conv['id']?.toString() ?? '';
    });
  }

  Future<VeterinaryModel> registerVet({
    required String name,
    required String address,
    String? phone,
    String? email,
    String? description,
    double? lat,
    double? lng,
    List<String>? services,
    List<String>? speciesServed,
  }) {
    return _guard(() async {
      final data = <String, dynamic>{
        'name': name,
        'address': address,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (description != null) 'description': description,
        if (lat != null && lng != null)
          'location': {
            'type': 'Point',
            'coordinates': [lng, lat],
          },
        if (services != null) 'services': services,
        if (speciesServed != null) 'speciesServed': speciesServed,
      };
      final response = await _dio.post('/api/veterinaries', data: data);
      return VeterinaryModel.fromJson(response.data['vet']);
    });
  }
}
