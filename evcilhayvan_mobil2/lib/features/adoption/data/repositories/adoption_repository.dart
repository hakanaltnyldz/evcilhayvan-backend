import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/http.dart';
import '../../domain/models/adoption_application.dart';

class AdoptionApplicationException implements Exception {
  final String message;
  final String? code;

  const AdoptionApplicationException(this.message, {this.code});

  @override
  String toString() => message;
}

class AdoptionApplicationUpdateResult {
  final AdoptionApplication application;
  final String? conversationId;

  const AdoptionApplicationUpdateResult({required this.application, this.conversationId});
}

final adoptionRepositoryProvider = Provider<AdoptionRepository>((ref) {
  final client = ApiClient();
  return AdoptionRepository(client.dio);
});

final inboxAdoptionApplicationsProvider = FutureProvider.autoDispose<List<AdoptionApplication>>((ref) async {
  final repository = ref.watch(adoptionRepositoryProvider);
  return repository.fetchInbox();
});

final sentAdoptionApplicationsProvider = FutureProvider.autoDispose<List<AdoptionApplication>>((ref) async {
  final repository = ref.watch(adoptionRepositoryProvider);
  return repository.fetchSent();
});

final adoptionApplicationForListingProvider =
    FutureProvider.autoDispose.family<AdoptionApplication?, String>((ref, listingId) async {
  final repository = ref.watch(adoptionRepositoryProvider);
  final items = await repository.fetchSent();
  for (final app in items) {
    if (app.adoptionListingId == listingId) return app;
  }
  return null;
});

class AdoptionRepository {
  final Dio _dio;
  AdoptionRepository(this._dio);

  Future<AdoptionApplication> createApplication(String listingId, {String? note}) async {
    try {
      final payload = {
        'adoptionListingId': listingId,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      };
      final response = await _dio.post('/api/adoption-applications', data: payload);
      final Map<String, dynamic> body = response.data as Map<String, dynamic>;
      final Map<String, dynamic> data = (body['application'] ?? body) as Map<String, dynamic>;
      return AdoptionApplication.fromJson(data);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Basvuru gonderilemedi';
      final code = e.response?.data?['code']?.toString();
      throw AdoptionApplicationException(message, code: code);
    }
  }

  Future<List<AdoptionApplication>> fetchInbox() async {
    try {
      final response = await _dio.get('/api/adoption-applications/inbox');
      final List<dynamic> raw = response.data['items'] ?? response.data['applications'] ?? [];
      return raw.whereType<Map<String, dynamic>>().map(AdoptionApplication.fromJson).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Basvurular alinamadi';
      throw AdoptionApplicationException(message);
    }
  }

  Future<List<AdoptionApplication>> fetchSent() async {
    try {
      final response = await _dio.get('/api/adoption-applications/sent');
      final List<dynamic> raw = response.data['items'] ?? response.data['applications'] ?? [];
      return raw.whereType<Map<String, dynamic>>().map(AdoptionApplication.fromJson).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Basvurular alinamadi';
      throw AdoptionApplicationException(message);
    }
  }

  Future<AdoptionApplicationUpdateResult> respondToApplication(String applicationId, String action) async {
    try {
      final normalized = action.toLowerCase();
      if (normalized != 'accept' && normalized != 'reject') {
        throw AdoptionApplicationException('Gecersiz islem');
      }
      final response = await _dio.post('/api/adoption-applications/$applicationId/$normalized');
      final Map<String, dynamic> body = response.data as Map<String, dynamic>;
      final Map<String, dynamic> data = (body['application'] ?? body) as Map<String, dynamic>;
      final dynamic rawConversationId = body['conversationId'] ?? data['conversationId'];
      final String? conversationId = (rawConversationId is String && rawConversationId.isNotEmpty)
          ? rawConversationId
          : rawConversationId?.toString();
      return AdoptionApplicationUpdateResult(
        application: AdoptionApplication.fromJson(data),
        conversationId: (conversationId != null && conversationId.isNotEmpty) ? conversationId : null,
      );
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Basvuru guncellenemedi';
      throw AdoptionApplicationException(message);
    }
  }
}
