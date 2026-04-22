import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:evcilhayvan_mobil2/core/http.dart';
import '../../domain/models/veterinary_model.dart';
import '../../domain/models/vet_review_model.dart';

final veterinaryRepositoryProvider = Provider<VeterinaryRepository>((ref) {
  return VeterinaryRepository(ApiClient());
});

final nearbyVetsProvider = FutureProvider.autoDispose
    .family<List<VeterinaryModel>, NearbyVetsParams>((ref, params) {
      final repo = ref.watch(veterinaryRepositoryProvider);
      return repo.searchVets(
        lat: params.lat,
        lng: params.lng,
        radiusKm: params.radiusKm,
        query: params.query,
      );
    });

final vetDetailProvider = FutureProvider.autoDispose
    .family<VeterinaryModel, String>((ref, id) {
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
      final response = await _dio.get(
        '/api/veterinaries',
        queryParameters: params,
      );
      final List<dynamic> list = (response.data['vets'] as List?) ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(VeterinaryModel.fromJson)
          .toList();
    });
  }

  Future<List<VeterinaryModel>> googleSearch({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) {
    return _guard(() async {
      final response = await _dio.get(
        '/api/veterinaries/google-search',
        queryParameters: {'lat': lat, 'lng': lng, 'radiusKm': radiusKm},
      );
      final List<dynamic> list = (response.data['vets'] as List?) ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(VeterinaryModel.fromJson)
          .toList();
    });
  }

  Future<VeterinaryModel> getVetDetail(String id) {
    return _guard(() async {
      final response = await _dio.get('/api/veterinaries/$id');
      return VeterinaryModel.fromJson(response.data['vet']);
    });
  }

  Future<VeterinaryModel> getMyClinic() {
    return _guard(() async {
      final response = await _dio.get('/api/veterinaries/my-clinic');
      return VeterinaryModel.fromJson(response.data['vet']);
    });
  }

  Future<List<Map<String, dynamic>>> getMyClaimStatus() {
    return _guard(() async {
      final response = await _dio.get('/api/veterinaries/my-claim-status');
      final List<dynamic> list = (response.data['claims'] as List?) ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(Map<String, dynamic>.from)
          .toList();
    });
  }

  Future<Map<String, dynamic>> getMyClinicAvailability({int days = 14}) {
    return _guard(() async {
      final response = await _dio.get(
        '/api/veterinaries/my-clinic/availability',
        queryParameters: {'days': days},
      );

      final overrides =
          (response.data['availabilityOverrides'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(AvailabilityOverrideModel.fromJson)
              .toList();

      final bookingLoad =
          (response.data['bookingLoad'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(Map<String, dynamic>.from)
              .toList();

      return {
        'availabilityOverrides': overrides,
        'bookingLoad': bookingLoad,
        'appointmentSlotMinutes':
            (response.data['appointmentSlotMinutes'] as num?)?.toInt() ?? 30,
      };
    });
  }

  Future<List<AvailabilityOverrideModel>> updateMyClinicAvailability(
    List<Map<String, dynamic>> overrides,
  ) {
    return _guard(() async {
      final response = await _dio.put(
        '/api/veterinaries/my-clinic/availability',
        data: {'availabilityOverrides': overrides},
      );
      final list =
          (response.data['availabilityOverrides'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(AvailabilityOverrideModel.fromJson)
              .toList();
      return list;
    });
  }

  Future<VeterinaryModel> updateVetProfile(
    String id,
    Map<String, dynamic> data,
  ) {
    return _guard(() async {
      final response = await _dio.put('/api/veterinaries/$id', data: data);
      return VeterinaryModel.fromJson(response.data['vet']);
    });
  }

  Future<void> claimVetProfile(
    String vetId, {
    required Map<String, String> claimData,
  }) {
    return _guard(() async {
      await _dio.post('/api/veterinaries/$vetId/claim', data: claimData);
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

  // ── Vet Reviews ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getVetReviews(String vetId, {int page = 1}) {
    return _guard(() async {
      final res = await _dio.get(
        '/api/veterinaries/$vetId/reviews',
        queryParameters: {'page': page, 'limit': 20},
      );
      final reviews = (res.data['reviews'] as List)
          .map((j) => VetReview.fromJson(Map<String, dynamic>.from(j)))
          .toList();
      return {
        'reviews': reviews,
        'total': res.data['total'] ?? 0,
        'averageRating': (res.data['averageRating'] ?? 0).toDouble(),
        'ratingCount': res.data['ratingCount'] ?? 0,
      };
    });
  }

  Future<VetReview> addVetReview(
    String vetId,
    int rating, {
    String? comment,
    Map<String, dynamic>? subRatings,
  }) {
    return _guard(() async {
      final res = await _dio.post(
        '/api/veterinaries/$vetId/reviews',
        data: {
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
          if (subRatings != null) 'subRatings': subRatings,
        },
      );
      return VetReview.fromJson(Map<String, dynamic>.from(res.data['review']));
    });
  }

  Future<void> deleteVetReview(String reviewId) {
    return _guard(() async {
      await _dio.delete('/api/veterinaries/reviews/$reviewId');
    });
  }
}
