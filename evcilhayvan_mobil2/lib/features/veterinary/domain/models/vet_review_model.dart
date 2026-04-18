class VetSubRatings {
  final int? cleanliness;
  final int? communication;
  final int? value;

  const VetSubRatings({this.cleanliness, this.communication, this.value});

  factory VetSubRatings.fromJson(Map<String, dynamic> j) {
    return VetSubRatings(
      cleanliness:   j['cleanliness']   != null ? (j['cleanliness']   as num).toInt() : null,
      communication: j['communication'] != null ? (j['communication'] as num).toInt() : null,
      value:         j['value']         != null ? (j['value']         as num).toInt() : null,
    );
  }

  bool get hasAny => cleanliness != null || communication != null || value != null;
}

class VetReview {
  final String id;
  final String vetId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final VetSubRatings? subRatings;

  const VetReview({
    required this.id,
    required this.vetId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.subRatings,
  });

  factory VetReview.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>?;
    return VetReview(
      id: j['id'] ?? j['_id'] ?? '',
      vetId: (j['vet'] is String ? j['vet'] : j['vet']?['id'] ?? j['vet']?['_id'] ?? '') as String,
      userId: user?['id'] ?? user?['_id'] ?? '',
      userName: user?['name'] ?? 'Kullanıcı',
      userAvatarUrl: user?['avatarUrl'] as String?,
      rating: (j['rating'] as num).toInt(),
      comment: j['comment'] as String?,
      createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
      subRatings: j['subRatings'] is Map<String, dynamic>
          ? VetSubRatings.fromJson(j['subRatings'])
          : null,
    );
  }
}
