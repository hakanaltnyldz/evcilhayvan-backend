import '../../../auth/domain/user_model.dart';

class AdoptionListingSummary {
  final String id;
  final String name;
  final String? species;
  final List<String> images;
  final String? advertType;

  const AdoptionListingSummary({
    required this.id,
    required this.name,
    this.species,
    this.images = const [],
    this.advertType,
  });

  factory AdoptionListingSummary.fromJson(Map<String, dynamic> json) {
    final imagesRaw = json['images'] ?? json['photos'];
    final images = imagesRaw is List ? imagesRaw.map((e) => e.toString()).toList() : <String>[];

    return AdoptionListingSummary(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      species: json['species']?.toString(),
      images: images,
      advertType: json['advertType']?.toString(),
    );
  }
}

class AdoptionApplication {
  final String id;
  final String adoptionListingId;
  final AdoptionListingSummary? listing;
  final User? applicantUser;
  final String status;
  final String? note;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? conversationId;

  const AdoptionApplication({
    required this.id,
    required this.adoptionListingId,
    this.listing,
    this.applicantUser,
    required this.status,
    this.note,
    required this.createdAt,
    this.respondedAt,
    this.conversationId,
  });

  factory AdoptionApplication.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    final listingJson = json['listing'] as Map<String, dynamic>?;
    final applicantJson = json['applicantUser'] as Map<String, dynamic>?;

    final listingId = json['adoptionListingId']?.toString() ??
        listingJson?['id']?.toString() ??
        listingJson?['_id']?.toString() ??
        '';

    return AdoptionApplication(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      adoptionListingId: listingId,
      listing: listingJson != null ? AdoptionListingSummary.fromJson(listingJson) : null,
      applicantUser: applicantJson != null ? User.fromJson(applicantJson) : null,
      status: json['status']?.toString() ?? 'PENDING',
      note: json['note']?.toString(),
      createdAt: parseDate(json['createdAt']),
      respondedAt: json['respondedAt'] != null ? parseDate(json['respondedAt']) : null,
      conversationId: json['conversationId']?.toString(),
    );
  }
}
