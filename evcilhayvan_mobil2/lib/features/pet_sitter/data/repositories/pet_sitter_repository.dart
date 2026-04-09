import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import '../../domain/models/pet_sitter_model.dart';
import '../../domain/models/sitter_booking_model.dart';

final petSitterRepositoryProvider = Provider<PetSitterRepository>(
  (ref) => PetSitterRepository(ApiClient()),
);

class PetSitterRepository {
  PetSitterRepository(this._client);
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

  Future<List<PetSitterModel>> listSitters({
    double? lat,
    double? lng,
    double radiusKm = 20,
    String? service,
    String? species,
  }) => _guard(() async {
    final r = await _dio.get(
      '/api/pet-sitters',
      queryParameters: {
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'radiusKm': radiusKm,
        if (service != null) 'service': service,
        if (species != null) 'species': species,
      },
    );
    final list = r.data['sitters'] as List? ?? [];
    return list
        .map((j) => PetSitterModel.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  });

  Future<Map<String, dynamic>> getSitter(String id) => _guard(() async {
    final r = await _dio.get('/api/pet-sitters/$id');
    return {
      'sitter': PetSitterModel.fromJson(
        Map<String, dynamic>.from(r.data['sitter']),
      ),
      'reviews': (r.data['reviews'] as List? ?? [])
          .map((j) => SitterReview.fromJson(Map<String, dynamic>.from(j)))
          .toList(),
    };
  });

  Future<PetSitterModel?> mySitterProfile() => _guard(() async {
    try {
      final r = await _dio.get('/api/pet-sitters/me');
      return PetSitterModel.fromJson(
        Map<String, dynamic>.from(r.data['sitter']),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  });

  Future<PetSitterModel> createSitter(Map<String, dynamic> data) =>
      _guard(() async {
        final r = await _dio.post('/api/pet-sitters', data: data);
        return PetSitterModel.fromJson(
          Map<String, dynamic>.from(r.data['sitter']),
        );
      });

  Future<PetSitterModel> updateSitter(String id, Map<String, dynamic> data) =>
      _guard(() async {
        final r = await _dio.put('/api/pet-sitters/$id', data: data);
        return PetSitterModel.fromJson(
          Map<String, dynamic>.from(r.data['sitter']),
        );
      });

  Future<bool> toggleAvailability(String id) => _guard(() async {
    final r = await _dio.patch('/api/pet-sitters/$id/availability');
    return r.data['availability'] == true;
  });

  // Bookings
  Future<SitterBookingModel> createBooking(Map<String, dynamic> data) =>
      _guard(() async {
        final r = await _dio.post('/api/sitter-bookings', data: data);
        return SitterBookingModel.fromJson(
          Map<String, dynamic>.from(r.data['booking']),
        );
      });

  Future<List<SitterBookingModel>> myBookings() => _guard(() async {
    final r = await _dio.get('/api/sitter-bookings/me');
    final list = r.data['bookings'] as List? ?? [];
    return list
        .map((j) => SitterBookingModel.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  });

  Future<List<SitterBookingModel>> incomingBookings() => _guard(() async {
    final r = await _dio.get('/api/sitter-bookings/incoming');
    final list = r.data['bookings'] as List? ?? [];
    return list
        .map((j) => SitterBookingModel.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  });

  Future<void> updateBookingStatus(
    String id,
    String status, {
    double? rating,
    String? comment,
  }) => _guard(() async {
    await _dio.patch(
      '/api/sitter-bookings/$id/status',
      data: {
        'status': status,
        if (rating != null) 'review': {'rating': rating, 'comment': comment},
      },
    );
  });
}

// Providers
class SitterSearchParams {
  final double? lat;
  final double? lng;
  final String? service;
  final String? species;
  const SitterSearchParams({this.lat, this.lng, this.service, this.species});
  @override
  bool operator ==(Object o) =>
      o is SitterSearchParams &&
      lat == o.lat &&
      lng == o.lng &&
      service == o.service &&
      species == o.species;
  @override
  int get hashCode => Object.hash(lat, lng, service, species);
}

final sitterListProvider = FutureProvider.autoDispose
    .family<List<PetSitterModel>, SitterSearchParams>(
      (ref, p) => ref
          .watch(petSitterRepositoryProvider)
          .listSitters(
            lat: p.lat,
            lng: p.lng,
            service: p.service,
            species: p.species,
          ),
    );

final sitterDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>(
      (ref, id) => ref.watch(petSitterRepositoryProvider).getSitter(id),
    );

final myBookingsProvider = FutureProvider.autoDispose<List<SitterBookingModel>>(
  (ref) => ref.watch(petSitterRepositoryProvider).myBookings(),
);

final incomingBookingsProvider =
    FutureProvider.autoDispose<List<SitterBookingModel>>(
      (ref) => ref.watch(petSitterRepositoryProvider).incomingBookings(),
    );

final mySitterProfileProvider = FutureProvider.autoDispose<PetSitterModel?>(
  (ref) => ref.watch(petSitterRepositoryProvider).mySitterProfile(),
);
