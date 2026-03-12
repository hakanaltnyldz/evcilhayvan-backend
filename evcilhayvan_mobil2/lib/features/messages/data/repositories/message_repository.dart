// lib/features/messages/data/repositories/message_repository.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evcilhayvan_mobil2/core/http.dart';
import 'package:evcilhayvan_mobil2/features/messages/domain/models/conservation_model.dart';
import '../../domain/models/message_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final client = ApiClient();
  return MessageRepository(client);
});

final conversationsProvider = FutureProvider.autoDispose<List<Conversation>>((ref) async {
  final repo = ref.watch(messageRepositoryProvider);
  final currentUser = ref.watch(authProvider);
  if (currentUser == null) return [];
  return repo.getMyConversations(currentUser.id);
});

final messagesProvider = FutureProvider.autoDispose.family<List<Message>, String>((ref, conversationId) async {
  final repo = ref.watch(messageRepositoryProvider);
  return repo.getMessages(conversationId);
});

class MessageRepository {
  MessageRepository(this._client);
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

  Future<List<Conversation>> getMyConversations(String currentUserId) {
    return _guard(() async {
      final response = await _dio.get('/api/conversations');
      final data = response.data as Map<String, dynamic>;
      final List<dynamic> jsonList = (data['conversations'] as List?) ?? (data['data'] as List?) ?? const [];

      // SAFE PARSING: Parse each conversation with try-catch to avoid crashing the entire list
      final List<Conversation> conversations = [];
      for (final json in jsonList.whereType<Map<String, dynamic>>()) {
        try {
          final conv = Conversation.fromJson(json, currentUserId);
          conversations.add(conv);
        } catch (e, stackTrace) {
          print('⚠️ Failed to parse conversation: $e');
          print('   JSON: $json');
          print('   Stack: $stackTrace');
          // Skip this conversation and continue with others
        }
      }

      print('✅ Successfully parsed ${conversations.length} of ${jsonList.length} conversations');
      return conversations;
    });
  }

  Future<List<Message>> getMessages(String conversationId) {
    return _guard(() async {
      final response = await _dio.get('/api/conversations/$conversationId/messages');
      final data = response.data as Map<String, dynamic>;
      final List<dynamic> jsonList = (data['messages'] as List?) ?? (data['data'] as List?) ?? const [];

      // SAFE PARSING: Parse each message with try-catch to avoid crashing
      final List<Message> messages = [];
      for (final json in jsonList.whereType<Map<String, dynamic>>()) {
        try {
          final msg = Message.fromJson(json);
          messages.add(msg);
        } catch (e) {
          print('⚠️ Failed to parse message: $e');
          // Skip this message and continue
        }
      }

      return messages;
    });
  }

  Future<Message> sendMessage({required String conversationId, required String text}) {
    return _guard(() async {
      final response = await _dio.post('/api/conversations/$conversationId/messages', data: {'text': text});
      final data = response.data as Map<String, dynamic>;
      final payload = (data['message'] as Map<String, dynamic>?) ?? data;
      return Message.fromJson(payload);
    });
  }

  Future<Conversation> createOrGetConversation({
    required String participantId,
    required String currentUserId,
    String? relatedPetId,
  }) {
    return _guard(() async {
      final payload = {
        'participantId': participantId,
        if (relatedPetId != null) 'relatedPetId': relatedPetId,
        if (relatedPetId != null) 'advertId': relatedPetId,
      };
      final response = await _dio.post('/api/conversations', data: payload);

      final responseBody = response.data as Map<String, dynamic>;
      final data = (responseBody['conversation'] as Map<String, dynamic>?) ?? responseBody;
      return Conversation.fromJson(
        data,
        currentUserId,
      );
    });
  }

  Future<void> deleteConversation(String conversationId) {
    return _guard(() async {
      await _dio.delete('/api/conversations/$conversationId');
    });
  }


  Future<void> markAsRead(String conversationId) {
    return _guard(() async {
      await _dio.patch('/api/conversations//read');
    });
  }
  Future<void> deleteMessageForMe(String messageId) {
    return _guard(() async {
      await _dio.patch('/api/conversations/message/$messageId/for-me');
    });
  }

  /// Tek bir conversation'ı ID ile getir
  Future<Conversation> getConversationById(String conversationId, String currentUserId) {
    return _guard(() async {
      final response = await _dio.get('/api/conversations/$conversationId');
      final data = response.data as Map<String, dynamic>;
      final convData = (data['conversation'] as Map<String, dynamic>?) ?? data;
      return Conversation.fromJson(convData, currentUserId);
    });
  }

  /// Resim mesajı gönder
  Future<Message> sendImageMessage({
    required String conversationId,
    required File imageFile,
    String? caption,
  }) {
    return _guard(() async {
      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
        if (caption != null && caption.isNotEmpty) 'text': caption,
        'type': 'IMAGE',
      });

      final response = await _dio.post(
        '/api/conversations/$conversationId/messages/image',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      final data = response.data as Map<String, dynamic>;
      final payload = (data['message'] as Map<String, dynamic>?) ?? data;
      return Message.fromJson(payload);
    });
  }
}
