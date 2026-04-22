class SitterBookingModel {
  final String id;
  final String? petOwnerId;
  final String? ownerName;
  final String? ownerAvatar;
  final String? sitterId;
  final String? sitterUserId;
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
  final double? ownerReviewRating;
  final String? ownerReviewComment;
  final DateTime? ownerReviewAt;
  final double? sitterReviewRating;
  final String? sitterReviewComment;
  final DateTime? sitterReviewAt;
  final DateTime? createdAt;
  final bool liveTrackingActive;
  final double? lastLat;
  final double? lastLng;
  final DateTime? lastLocationAt;
  final DateTime? trackingGraceEndsAt;
  final String earningsStatus;
  final DateTime? earningsPausedAt;
  final double payableAmount;

  const SitterBookingModel({
    required this.id,
    this.petOwnerId,
    this.ownerName,
    this.ownerAvatar,
    this.sitterId,
    this.sitterUserId,
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
    this.ownerReviewRating,
    this.ownerReviewComment,
    this.ownerReviewAt,
    this.sitterReviewRating,
    this.sitterReviewComment,
    this.sitterReviewAt,
    this.createdAt,
    this.liveTrackingActive = false,
    this.lastLat,
    this.lastLng,
    this.lastLocationAt,
    this.trackingGraceEndsAt,
    this.earningsStatus = 'pending',
    this.earningsPausedAt,
    this.payableAmount = 0,
  });

  String get serviceLabel {
    switch (serviceType) {
      case 'walking':
        return 'Gezdirme';
      case 'home_sitting':
        return 'Ev Bakimi';
      case 'boarding':
        return 'Pansiyonda Bakim';
      case 'daycare':
        return 'Gunduz Bakimi';
      case 'grooming':
        return 'Timar/Bakim';
      default:
        return serviceType;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Bekliyor';
      case 'accepted':
        return 'Kabul Edildi';
      case 'active':
        return 'Bakim Aktif';
      case 'rejected':
        return 'Reddedildi';
      case 'cancelled':
        return 'Iptal';
      case 'completed':
        return 'Tamamlandi';
      default:
        return status;
    }
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get hasReview => ownerReviewRating != null;
  bool get hasOwnerReview => ownerReviewRating != null;
  bool get hasSitterReview => sitterReviewRating != null;
  bool get canTrackLive => status == 'active' || liveTrackingActive;
  bool get needsPickup => status == 'accepted';
  bool get earningsPaused => earningsStatus == 'paused';

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
    double? ownerReviewRating;
    String? ownerReviewComment;
    DateTime? ownerReviewAt;
    if (review is Map<String, dynamic>) {
      ownerReviewRating = (review['rating'] as num?)?.toDouble();
      ownerReviewComment = review['comment']?.toString();
      ownerReviewAt = review['createdAt'] != null
          ? DateTime.tryParse(review['createdAt'].toString())
          : null;
    }

    final sitterReview = json['sitterReview'];
    double? sitterReviewRating;
    String? sitterReviewComment;
    DateTime? sitterReviewAt;
    if (sitterReview is Map<String, dynamic>) {
      sitterReviewRating = (sitterReview['rating'] as num?)?.toDouble();
      sitterReviewComment = sitterReview['comment']?.toString();
      sitterReviewAt = sitterReview['createdAt'] != null
          ? DateTime.tryParse(sitterReview['createdAt'].toString())
          : null;
    }

    return SitterBookingModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      petOwnerId: petOwnerId,
      ownerName: ownerName,
      ownerAvatar: ownerAvatar,
      sitterId: sitterId,
      sitterUserId: json['sitterUserId']?.toString(),
      sitterName: sitterName,
      sitterAvatar: sitterAvatar,
      petId: petId,
      petName: petName,
      petPhoto: petPhoto,
      serviceType: json['serviceType']?.toString() ?? '',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      notes: json['notes']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      ownerReviewRating: ownerReviewRating,
      ownerReviewComment: ownerReviewComment,
      ownerReviewAt: ownerReviewAt,
      sitterReviewRating: sitterReviewRating,
      sitterReviewComment: sitterReviewComment,
      sitterReviewAt: sitterReviewAt,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      liveTrackingActive: json['liveTracking']?['isActive'] == true,
      lastLat: (json['liveTracking']?['lastLat'] as num?)?.toDouble(),
      lastLng: (json['liveTracking']?['lastLng'] as num?)?.toDouble(),
      lastLocationAt: json['liveTracking']?['lastUpdated'] != null
          ? DateTime.tryParse(json['liveTracking']['lastUpdated'].toString())
          : null,
      trackingGraceEndsAt: json['liveTracking']?['graceEndsAt'] != null
          ? DateTime.tryParse(json['liveTracking']['graceEndsAt'].toString())
          : null,
      earningsStatus: json['earnings']?['status']?.toString() ?? 'pending',
      earningsPausedAt: json['earnings']?['pausedAt'] != null
          ? DateTime.tryParse(json['earnings']['pausedAt'].toString())
          : null,
      payableAmount:
          (json['earnings']?['payableAmount'] as num?)?.toDouble() ??
          (json['totalPrice'] as num?)?.toDouble() ??
          0,
    );
  }
}
