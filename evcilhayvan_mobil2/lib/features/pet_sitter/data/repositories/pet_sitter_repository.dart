import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import '../../domain/models/care_report_model.dart';
import '../../domain/models/pet_sitter_model.dart';
import '../../domain/models/sitter_booking_model.dart';
import '../../domain/models/sitter_financial_summary_model.dart';

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
    double radiusKm = 500,
    String? service,
    String? species,
  }) => _guard(() async {
    final r = await _dio.get(
      '/api/pet-sitters',
      queryParameters: {
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (lat != null && lng != null) 'radiusKm': radiusKm,
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

  Future<SitterFinancialSummaryModel> getMyFinancialSummary() =>
      _guard(() async {
        final r = await _dio.get('/api/sitter-bookings/financial-summary');
        return SitterFinancialSummaryModel.fromJson(
          Map<String, dynamic>.from(r.data as Map),
        );
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

  Future<SitterBookingModel> getBooking(String id) => _guard(() async {
    final r = await _dio.get('/api/sitter-bookings/$id');
    return SitterBookingModel.fromJson(
      Map<String, dynamic>.from(r.data['booking'] as Map),
    );
  });

  // Walk güncelleme gönder (bakıcı → evcil hayvan sahibine)
  Future<void> sendWalkUpdate(String bookingId, {String? note, String? type}) =>
      _guard(() async {
        await _dio.post(
          '/api/sitter-bookings/$bookingId/updates',
          data: {'type': type ?? 'note', if (note != null) 'message': note},
        );
      });

  // Walk güncellemelerini getir
  Future<List<Map<String, dynamic>>> getWalkUpdates(String bookingId) =>
      _guard(() async {
        final r = await _dio.get('/api/sitter-bookings/$bookingId/updates');
        final list = r.data['updates'] as List? ?? [];
        return list.map((j) => Map<String, dynamic>.from(j as Map)).toList();
      });

  // Bakım raporu oluştur
  Future<CareReportModel> createCareReport(
    String bookingId,
    Map<String, dynamic> report,
  ) => _guard(() async {
    final r = await _dio.post(
      '/api/sitter-bookings/$bookingId/care-reports',
      data: report,
    );
    return CareReportModel.fromJson(
      Map<String, dynamic>.from(r.data['report'] as Map),
    );
  });

  // Bakım raporlarını getir
  Future<List<CareReportModel>> getCareReports(String bookingId) => _guard(
    () async {
      final r = await _dio.get('/api/sitter-bookings/$bookingId/care-reports');
      final list = r.data['reports'] as List? ?? [];
      return list
          .map(
            (j) =>
                CareReportModel.fromJson(Map<String, dynamic>.from(j as Map)),
          )
          .toList();
    },
  );

  Future<String> uploadCarePhoto(String bookingId, File photo) =>
      _guard(() async {
        final formData = FormData.fromMap({
          'photo': await MultipartFile.fromFile(
            photo.path,
            filename: photo.path.split('/').last,
          ),
        });
        final r = await _dio.post(
          '/api/sitter-bookings/$bookingId/upload-care-photo',
          data: formData,
        );
        return r.data['photoUrl']?.toString() ?? '';
      });

  // Blocked dates güncelle
  Future<void> updateBlockedDates(
    String sitterId, {
    List<String> add = const [],
    List<String> remove = const [],
  }) => _guard(() async {
    await _dio.patch(
      '/api/pet-sitters/$sitterId/blocked-dates',
      data: {'add': add, 'remove': remove},
    );
  });

  // Sitter request ilanlarını listele (evcil hayvan sahiplerinin açtığı)
  Future<List<Map<String, dynamic>>> listSitterRequests({
    double? lat,
    double? lng,
    String? serviceType,
  }) => _guard(() async {
    final r = await _dio.get(
      '/api/sitter-requests',
      queryParameters: {
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (serviceType != null) 'serviceType': serviceType,
      },
    );
    final list = r.data['requests'] as List? ?? [];
    return list.map((j) => Map<String, dynamic>.from(j as Map)).toList();
  });

  // Kendi sitter request ilanlarım
  Future<List<Map<String, dynamic>>> mySitterRequests() => _guard(() async {
    final r = await _dio.get('/api/sitter-requests/me');
    final list = r.data['requests'] as List? ?? [];
    return list.map((j) => Map<String, dynamic>.from(j as Map)).toList();
  });

  // Bakıcı olarak ilana başvur (konuşma başlat)
  Future<String> contactSitterRequestOwner(String requestId) =>
      _guard(() async {
        final r = await _dio.post('/api/sitter-requests/$requestId/contact');
        return r.data['conversationId']?.toString() ??
            r.data['conversation']?['_id']?.toString() ??
            '';
      });

  // İlan durumunu değiştir (kapat/aç)
  Future<void> updateSitterRequestStatus(String requestId, String status) =>
      _guard(() async {
        await _dio.patch(
          '/api/sitter-requests/$requestId/status',
          data: {'status': status},
        );
      });

  // Bakıcı ilanı oluştur
  Future<Map<String, dynamic>> createSitterRequest(Map<String, dynamic> data) =>
      _guard(() async {
        final r = await _dio.post('/api/sitter-requests', data: data);
        return Map<String, dynamic>.from(r.data['request'] as Map);
      });

  // Walk fotoğrafı yükle (bakıcı)
  Future<String> uploadWalkPhoto(
    String bookingId,
    File photo, {
    String? caption,
  }) => _guard(() async {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(
        photo.path,
        filename: photo.path.split('/').last,
      ),
      if (caption != null && caption.isNotEmpty) 'caption': caption,
    });
    final r = await _dio.post(
      '/api/sitter-bookings/$bookingId/walk-photos',
      data: formData,
    );
    return r.data['photo']?['url']?.toString() ?? '';
  });

  // Walk fotoğraflarını getir
  Future<List<Map<String, dynamic>>> getWalkPhotos(String bookingId) =>
      _guard(() async {
        final r = await _dio.get('/api/sitter-bookings/$bookingId/walk-photos');
        final list = r.data['photos'] as List? ?? [];
        return list.map((j) => Map<String, dynamic>.from(j as Map)).toList();
      });

  // Canlı takibi başlat/durdur
  Future<void> toggleTracking(
    String bookingId, {
    required bool active,
    String? reason,
  }) => _guard(() async {
    await _dio.patch(
      '/api/sitter-bookings/$bookingId/tracking',
      data: {
        'active': active,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
  });

  // Bakıcıya yorum/puan ekle
  Future<void> addSitterReview(
    String sitterId, {
    required int rating,
    String? comment,
  }) => _guard(() async {
    await _dio.post(
      '/api/pet-sitters/$sitterId/reviews',
      data: {
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
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
