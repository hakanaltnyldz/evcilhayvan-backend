// lib/features/messages/domain/models/conversation_model.dart

import '../../../auth/domain/user_model.dart';
import '../../../pets/domain/models/pet_model.dart';

class Conversation {
  final String id;
  final User otherParticipant;
  final Pet? relatedPet;
  final String? relatedPetId;
  final String? advertType;
  final String lastMessage;
  final String? contextType;
  final String? contextId;
  final DateTime lastMessageAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.otherParticipant,
    this.relatedPet,
    this.relatedPetId,
    this.advertType,
    required this.lastMessage,
    this.contextType,
    this.contextId,
    required this.lastMessageAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json, String currentUserId) {
    final participants = (json['participants'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        const <Map<String, dynamic>>[];

    // Güvenli bir şekilde otherParticipant bul
    Map<String, dynamic>? otherParticipantJson;

    if (participants.isNotEmpty) {
      try {
        otherParticipantJson = participants.firstWhere(
          (p) => (p['_id'] ?? p['id']) != currentUserId,
          orElse: () => participants.first,
        );
      } catch (e) {
        print('❌ Error finding other participant: $e');
        otherParticipantJson = participants.first;
      }
    }

    // Eğer participant bulunamadıysa, fallback bir User objesi oluştur
    if (otherParticipantJson == null || otherParticipantJson.isEmpty) {
      otherParticipantJson = {
        '_id': 'unknown',
        'id': 'unknown',
        'name': 'Kullanıcı',
        'email': '',
        'avatarUrl': null,
      };
    }

    final relatedPetData = json['relatedPet'];
    Pet? relatedPet;
    String? relatedPetId;

    if (relatedPetData is Map<String, dynamic>) {
      try {
        relatedPet = Pet.fromJson(relatedPetData);
        relatedPetId = relatedPetData['_id']?.toString();
      } catch (e) {
        print('Error parsing relatedPet: $e');
        relatedPetId = relatedPetData['_id']?.toString();
      }
    } else if (relatedPetData is String) {
      relatedPetId = relatedPetData;
    }

    final dynamic lastMessageData = json['lastMessage'];
    String lastMessageText = '';
    if (lastMessageData is Map<String, dynamic>) {
      lastMessageText = lastMessageData['text']?.toString() ?? '';
    } else if (lastMessageData is String) {
      lastMessageText = lastMessageData;
    }

    final lastMessageAt = _parseDateTime(
      json['lastMessageAt'] ??
          json['updatedAt'] ??
          (lastMessageData is Map<String, dynamic>
              ? lastMessageData['createdAt'] ?? lastMessageData['updatedAt']
              : null),
    );
    final contextIdValue = json['contextId'];
    final contextId = contextIdValue == null
        ? null
        : contextIdValue is Map<String, dynamic>
            ? (contextIdValue['_id']?.toString() ?? contextIdValue['id']?.toString())
            : contextIdValue.toString();

    // Try to parse User with error handling
    User otherParticipantUser;
    try {
      otherParticipantUser = User.fromJson(otherParticipantJson);
    } catch (e) {
      print('❌ User.fromJson failed: $e');
      // Create fallback user
      otherParticipantUser = User(
        id: otherParticipantJson['_id']?.toString() ??
            otherParticipantJson['id']?.toString() ??
            'unknown',
        name: otherParticipantJson['name']?.toString() ?? 'Kullanıcı',
        email: otherParticipantJson['email']?.toString() ?? 'email@unknown.com',
        role: 'user',
        avatarUrl: otherParticipantJson['avatarUrl']?.toString(),
      );
    }

    return Conversation(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      otherParticipant: otherParticipantUser,
      relatedPet: relatedPet,
      relatedPetId: relatedPetId,
      advertType: json['advertType']?.toString(),
      lastMessage: lastMessageText,
      contextType: json['contextType']?.toString(),
      contextId: contextId,
      lastMessageAt: lastMessageAt,
      updatedAt: lastMessageAt,
    );
  }
}

DateTime _parseDateTime(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is double) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  return DateTime.now();
}
