// lib/features/messages/domain/models/message_model.dart

import '../../../auth/domain/user_model.dart';
import '../../../pets/domain/models/pet_model.dart';

class Message {
  final String id;
  final String conversationId;
  final User sender;
  final String text;
  final String type;
  final List<String> readBy;
  final DateTime createdAt;
  final bool isDeletedForMe;
  final Pet? relatedPet; // İlan bilgisi için
  final String? petId; // İlan ID'si
  final String? imageUrl; // Resim mesajı için
  final Map<String, List<String>> reactions; // emoji -> [userId]

  Message({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.text,
    this.type = 'TEXT',
    this.readBy = const [],
    required this.createdAt,
    this.isDeletedForMe = false,
    this.relatedPet,
    this.petId,
    this.imageUrl,
    this.reactions = const {},
  });

  Message copyWith({Map<String, List<String>>? reactions}) {
    return Message(
      id: id,
      conversationId: conversationId,
      sender: sender,
      text: text,
      type: type,
      readBy: readBy,
      createdAt: createdAt,
      isDeletedForMe: isDeletedForMe,
      relatedPet: relatedPet,
      petId: petId,
      imageUrl: imageUrl,
      reactions: reactions ?? this.reactions,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    final senderData = json['sender'] ?? json['senderId'];
    final readByRaw = json['readBy'];

    // İlan bilgisi parse et - GÜVENLİ PARSE
    Pet? relatedPet;
    String? petId;
    final relatedPetData = json['relatedPet'] ?? json['petId'];

    if (relatedPetData is Map<String, dynamic>) {
      try {
        relatedPet = Pet.fromJson(relatedPetData);
        petId = relatedPetData['_id']?.toString() ?? relatedPetData['id']?.toString();
      } catch (e) {
        print('⚠️ Message.fromJson: Failed to parse relatedPet: $e');
        petId = relatedPetData['_id']?.toString() ?? relatedPetData['id']?.toString();
      }
    } else if (relatedPetData is String) {
      petId = relatedPetData;
    }

    // Sender parse et - GÜVENLİ PARSE
    User sender;
    try {
      sender = senderData is Map<String, dynamic>
          ? User.fromJson(senderData)
          : senderData is String
              ? User.fromJson({'_id': senderData, 'name': 'Kullanıcı', 'email': 'unknown@email.com', 'role': 'user'})
              : User.fromJson({'_id': 'unknown', 'name': 'Kullanıcı', 'email': 'unknown@email.com', 'role': 'user'});
    } catch (e) {
      print('⚠️ Message.fromJson: Failed to parse sender: $e');
      sender = User(
        id: 'unknown',
        name: 'Kullanıcı',
        email: 'unknown@email.com',
        role: 'user',
      );
    }

    return Message(
      id: json['_id'] ?? json['id'] ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      sender: sender,
      text: json['text'] ?? '',
      type: json['type']?.toString() ?? 'TEXT',
      readBy: readByRaw is List
          ? readByRaw.map((e) => e.toString()).toList()
          : const [],
      createdAt: _parseDateTime(json['createdAt']),
      isDeletedForMe: json['isDeletedForMe'] == true,
      relatedPet: relatedPet,
      petId: petId,
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString(),
      reactions: _parseReactions(json['reactions']),
    );
  }
}

Map<String, List<String>> _parseReactions(dynamic raw) {
  if (raw == null) return const {};
  if (raw is Map) {
    final result = <String, List<String>>{};
    for (final entry in raw.entries) {
      final key = entry.key.toString();
      final val = entry.value;
      if (val is List) {
        result[key] = val.map((e) => e.toString()).toList();
      }
    }
    return result;
  }
  return const {};
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
