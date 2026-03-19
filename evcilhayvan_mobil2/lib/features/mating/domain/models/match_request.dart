import '../../../auth/domain/user_model.dart';

class ListingSummary {
  final String id;
  final String name;
  final String? species;
  final List<String> images;
  final String? advertType;

  const ListingSummary({
    required this.id,
    required this.name,
    this.species,
    this.images = const [],
    this.advertType,
  });

  factory ListingSummary.fromJson(Map<String, dynamic> json) {
    final imagesRaw = json['images'] ?? json['photos'];
    final images = imagesRaw is List ? imagesRaw.map((e) => e.toString()).toList() : <String>[];

    return ListingSummary(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      species: json['species']?.toString(),
      images: images,
      advertType: json['advertType']?.toString(),
    );
  }
}

class MatchRequest {
  final String id;
  final String listingId;
  final ListingSummary? listing;
  final String fromPetId;
  final ListingSummary? fromPet;
  final User? fromUser;
  final User? toUser;
  final String status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? conversationId;

  const MatchRequest({
    required this.id,
    required this.listingId,
    required this.fromPetId,
    this.listing,
    this.fromPet,
    this.fromUser,
    this.toUser,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.conversationId,
  });

  factory MatchRequest.fromJson(Map<String, dynamic> json) {
    User? parseUser(dynamic value) {
      if (value is Map<String, dynamic>) {
        return User.fromJson(value);
      }
      return null;
    }

    DateTime parseDate(dynamic value) {
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    final listingJson = json['listing'] as Map<String, dynamic>?;
    final fromPetJson = json['fromPet'] as Map<String, dynamic>?;

    final listingId = json['listingId']?.toString() ??
        json['advertId']?.toString() ??
        listingJson?['id']?.toString() ??
        listingJson?['_id']?.toString() ??
        '';
    final fromPetId = json['fromPetId']?.toString() ??
        json['fromAdvertId']?.toString() ??
        json['requesterPet']?.toString() ??
        fromPetJson?['id']?.toString() ??
        fromPetJson?['_id']?.toString() ??
        '';

    // Normalize status to UPPERCASE for consistency
    final rawStatus = json['status']?.toString() ?? 'PENDING';
    final normalizedStatus = rawStatus.toUpperCase();

    // Parse advert/listing objects if present
    final advertJson = json['advert'] as Map<String, dynamic>?;
    final fromAdvertJson = json['fromAdvert'] as Map<String, dynamic>?;
    final listing = listingJson ?? advertJson;
    final fromPet = fromPetJson ?? fromAdvertJson;

    return MatchRequest(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      listingId: listingId,
      fromPetId: fromPetId,
      listing: listing != null ? ListingSummary.fromJson(listing) : null,
      fromPet: fromPet != null ? ListingSummary.fromJson(fromPet) : null,
      fromUser: parseUser(json['fromUser']),
      toUser: parseUser(json['toUser']),
      status: normalizedStatus,
      createdAt: parseDate(json['createdAt']),
      respondedAt: json['respondedAt'] != null ? parseDate(json['respondedAt']) : null,
      conversationId: json['conversationId']?.toString(),
    );
  }
}
