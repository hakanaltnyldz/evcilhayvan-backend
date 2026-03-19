class VetReview {
  final String id;
  final String vetId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const VetReview({
    required this.id,
    required this.vetId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.rating,
    this.comment,
    required this.createdAt,
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
    );
  }
}
