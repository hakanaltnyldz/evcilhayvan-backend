import 'package:dio/dio.dart';
import 'package:evcilhayvan_mobil2/features/messages/domain/models/conservation_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/http.dart';
import '../../domain/models/mating_profile.dart';
import '../../domain/models/match_request.dart';

@immutable
class MatingQuery {
  final String? species;
  final String? gender;
  final double? maxDistanceKm;

  const MatingQuery({this.species, this.gender, this.maxDistanceKm});

  MatingQuery copyWith({String? species, String? gender, double? maxDistanceKm}) {
    return MatingQuery(
      species: species ?? this.species,
      gender: gender ?? this.gender,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};
    if (species != null && species!.isNotEmpty) params['species'] = species;
    if (gender != null && gender!.isNotEmpty) params['gender'] = gender;
    if (maxDistanceKm != null && maxDistanceKm! > 0) params['maxDistanceKm'] = maxDistanceKm;
    return params;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatingQuery && other.species == species && other.gender == gender && other.maxDistanceKm == maxDistanceKm;

  @override
  int get hashCode => Object.hash(species, gender, maxDistanceKm);
}

class MatchRequestException implements Exception {
  final String message;
  final String? code;

  const MatchRequestException(this.message, {this.code});

  @override
  String toString() => message;
}

class MatchRequestResult {
  final bool success;
  final bool didMatch;
  final String message;
  final MatchRequest? request;

  const MatchRequestResult({
    required this.success,
    required this.didMatch,
    required this.message,
    this.request,
  });

  factory MatchRequestResult.fromJson(Map<String, dynamic> json) {
    final successValue = json['success'] ?? true;
    final didMatchValue = json['match'] ?? json['didMatch'] ?? json['isMatch'] ?? false;
    final messageValue = json['message'] ?? 'Eslestirme istegi gonderildi.';
    final MatchRequest? request = json['request'] is Map<String, dynamic>
        ? MatchRequest.fromJson(json['request'] as Map<String, dynamic>)
        : null;

    return MatchRequestResult(
      success: successValue is bool ? successValue : true,
      didMatch: didMatchValue == true,
      message: messageValue.toString(),
      request: request,
    );
  }
}

class MatchRequestUpdateResult {
  final MatchRequest request;
  final String? conversationId;

  const MatchRequestUpdateResult({required this.request, this.conversationId});
}

final matingRepositoryProvider = Provider<MatingRepository>((ref) {
  final dio = HttpClient().dio;
  return MatingRepository(dio);
});

final matingProfilesProvider =
    FutureProvider.autoDispose.family<List<MatingProfile>, MatingQuery>((ref, query) async {
  final repository = ref.watch(matingRepositoryProvider);
  return repository.fetchProfiles(query: query);
});

final inboxMatchRequestsProvider = FutureProvider.autoDispose<List<MatchRequest>>((ref) async {
  final repository = ref.watch(matingRepositoryProvider);
  return repository.fetchInboxRequests();
});

final outboxMatchRequestsProvider = FutureProvider.autoDispose<List<MatchRequest>>((ref) async {
  final repository = ref.watch(matingRepositoryProvider);
  return repository.fetchOutboxRequests();
});

final matchRequestForAdvertProvider =
    FutureProvider.autoDispose.family<MatchRequest?, String>((ref, advertId) async {
  final repository = ref.watch(matingRepositoryProvider);
  return repository.findMyRequestForAdvert(advertId);
});

class MatingRepository {
  final Dio _dio;
  MatingRepository(this._dio);

  Future<List<MatingProfile>> fetchProfiles({MatingQuery query = const MatingQuery()}) async {
    try {
      final response = await _dio.get('/api/matching/profiles', queryParameters: query.toQueryParameters());
      final List<dynamic> rawList = response.data['profiles'] ?? response.data['items'] ?? response.data['data'] ?? [];
      return rawList.whereType<Map<String, dynamic>>().map(MatingProfile.fromJson).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Veri alinamadi.';
      throw Exception('Eslestirme listesi alinamadi: $message');
    }
  }

  Future<MatchRequestResult> sendMatchRequest(String advertId, {String? requesterPetId}) async {
    try {
      if (requesterPetId == null || requesterPetId.isEmpty) {
        throw MatchRequestException('Eslestirme icin pet secmelisin.');
      }
      final payload = {
        'advertId': advertId,
        'fromAdvertId': requesterPetId,
      };
      final response = await _dio.post('/api/matching/requests', data: payload);
      return MatchRequestResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Eslesme istegi basarisiz';
      final code = e.response?.data?['code']?.toString();
      throw MatchRequestException(message, code: code);
    }
  }

  Future<List<MatchRequest>> fetchInboxRequests() async {
    try {
      final response = await _dio.get('/api/matching/requests/inbox');
      final List<dynamic> raw = response.data['items'] ?? response.data['requests'] ?? [];
      return raw.whereType<Map<String, dynamic>>().map(MatchRequest.fromJson).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Istekler alinamadi';
      throw Exception(message);
    }
  }

  Future<List<MatchRequest>> fetchOutboxRequests() async {
    try {
      final response = await _dio.get('/api/matching/requests/outbox');
      final List<dynamic> raw = response.data['items'] ?? response.data['requests'] ?? [];
      return raw.whereType<Map<String, dynamic>>().map(MatchRequest.fromJson).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Istekler alinamadi';
      throw Exception(message);
    }
  }

  Future<MatchRequest?> findMyRequestForAdvert(String advertId) async {
    final outbox = await fetchOutboxRequests();
    for (final request in outbox) {
      if (request.listingId == advertId) return request;
    }
    return null;
  }

  Future<MatchRequestUpdateResult> updateRequestStatus(String requestId, String action) async {
    try {
      final normalized = action.toLowerCase();
      if (normalized != 'accept' && normalized != 'reject' && normalized != 'cancel') {
        throw Exception('Gecersiz islem');
      }
      final response = await _dio.patch('/api/matching/requests/$requestId', data: {'action': normalized});
      final Map<String, dynamic> body = response.data as Map<String, dynamic>;
      final Map<String, dynamic> data = (body['request'] ?? body) as Map<String, dynamic>;
      final dynamic rawConversationId = body['conversationId'] ?? data['conversationId'];
      final String? conversationId = (rawConversationId is String && rawConversationId.isNotEmpty)
          ? rawConversationId
          : rawConversationId?.toString();
      return MatchRequestUpdateResult(
        request: MatchRequest.fromJson(data),
        conversationId: (conversationId != null && conversationId.isNotEmpty) ? conversationId : null,
      );
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Istek guncellenemedi';
      throw Exception(message);
    }
  }

  Future<Conversation> createOrGetConversation({
    required String participantId,
    required String currentUserId,
    String? relatedPetId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/conversations',
        data: {
          'participantId': participantId,
          'relatedPetId': relatedPetId,
          'advertId': relatedPetId,
        },
      );

      final convoJson = response.data['conversation'] ?? response.data;
      return Conversation.fromJson(convoJson, currentUserId);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Sohbet baslatilamadi.';
      throw Exception(message);
    }
  }
}
