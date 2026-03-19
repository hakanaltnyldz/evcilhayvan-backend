class SitterBookingModel {
  final String id;
  final String? petOwnerId;
  final String? ownerName;
  final String? ownerAvatar;
  final String? sitterId;
  final String? sitterName;
  final String? sitterAvatar;
  final String? petId;
  final String? petName;
  final String? petPhoto;
  final String serviceType;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String? notes;
  final String status;
  final double? reviewRating;
  final String? reviewComment;
  final DateTime? createdAt;

  const SitterBookingModel({
    required this.id,
    this.petOwnerId,
    this.ownerName,
    this.ownerAvatar,
    this.sitterId,
    this.sitterName,
    this.sitterAvatar,
    this.petId,
    this.petName,
    this.petPhoto,
    required this.serviceType,
    required this.startDate,
    required this.endDate,
    this.totalPrice = 0,
    this.notes,
    this.status = 'pending',
    this.reviewRating,
    this.reviewComment,
    this.createdAt,
  });

  String get serviceLabel {
    switch (serviceType) {
      case 'walking': return 'Gezdirme';
      case 'home_sitting': return 'Ev Bakimi';
      case 'boarding': return 'Pansiyonda Bakim';
      case 'daycare': return 'Gunduz Bakimi';
      case 'grooming': return 'Timar/Bakim';
      default: return serviceType;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'pending': return 'Bekliyor';
      case 'accepted': return 'Kabul Edildi';
      case 'rejected': return 'Reddedildi';
      case 'cancelled': return 'Iptal';
      case 'completed': return 'Tamamlandi';
      default: return status;
    }
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isCompleted => status == 'completed';
  bool get hasReview => reviewRating != null;

  factory SitterBookingModel.fromJson(Map<String, dynamic> json) {
    // Populate edilmis sitter
    final sitterRaw = json['sitterId'];
    String? sitterId, sitterName, sitterAvatar;
    if (sitterRaw is Map<String, dynamic>) {
      sitterId = sitterRaw['_id']?.toString() ?? sitterRaw['id']?.toString();
      sitterName = sitterRaw['displayName']?.toString();
      sitterAvatar = sitterRaw['avatar']?.toString();
    } else if (sitterRaw is String) {
      sitterId = sitterRaw;
    }

    // Populate edilmis owner
    final ownerRaw = json['petOwnerId'];
    String? petOwnerId, ownerName, ownerAvatar;
    if (ownerRaw is Map<String, dynamic>) {
      petOwnerId = ownerRaw['_id']?.toString() ?? ownerRaw['id']?.toString();
      ownerName = ownerRaw['name']?.toString();
      ownerAvatar = ownerRaw['avatarUrl']?.toString();
    } else if (ownerRaw is String) {
      petOwnerId = ownerRaw;
    }

    // Populate edilmis pet
    final petRaw = json['petId'];
    String? petId, petName, petPhoto;
    if (petRaw is Map<String, dynamic>) {
      petId = petRaw['_id']?.toString() ?? petRaw['id']?.toString();
      petName = petRaw['name']?.toString();
      final imgs = petRaw['images'] ?? petRaw['photos'];
      if (imgs is List && imgs.isNotEmpty) petPhoto = imgs.first.toString();
    } else if (petRaw is String) {
      petId = petRaw;
    }

    final review = json['ownerReview'];
    double? reviewRating;
    String? reviewComment;
    if (review is Map<String, dynamic>) {
      reviewRating = (review['rating'] as num?)?.toDouble();
      reviewComment = review['comment']?.toString();
    }

    return SitterBookingModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      petOwnerId: petOwnerId,
      ownerName: ownerName,
      ownerAvatar: ownerAvatar,
      sitterId: sitterId,
      sitterName: sitterName,
      sitterAvatar: sitterAvatar,
      petId: petId,
      petName: petName,
      petPhoto: petPhoto,
      serviceType: json['serviceType']?.toString() ?? '',
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now() : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'].toString()) ?? DateTime.now() : DateTime.now(),
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      notes: json['notes']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      reviewRating: reviewRating,
      reviewComment: reviewComment,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}
