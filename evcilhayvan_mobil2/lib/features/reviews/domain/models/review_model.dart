// lib/features/reviews/domain/models/review_model.dart

import 'package:evcilhayvan_mobil2/features/auth/domain/user_model.dart';

class ReviewModel {
  final String id;
  final String productId;
  final User user;
  final int rating;
  final String comment;
  final bool verifiedPurchase;
  final int helpfulCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReviewModel({
    required this.id,
    required this.productId,
    required this.user,
    required this.rating,
    required this.comment,
    this.verifiedPurchase = true,
    this.helpfulCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      productId: json['product'] is String
          ? json['product']
          : (json['product']?['_id']?.toString() ?? json['product']?['id']?.toString() ?? ''),
      user: json['user'] is Map<String, dynamic>
          ? User.fromJson(json['user'])
          : User.fromJson({'_id': json['user']?.toString() ?? ''}),
      rating: json['rating']?.toInt() ?? 0,
      comment: json['comment']?.toString() ?? '',
      verifiedPurchase: json['verifiedPurchase'] == true,
      helpfulCount: json['helpfulCount']?.toInt() ?? 0,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'comment': comment,
    };
  }

  static DateTime _parseDateTime(dynamic value) {
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
}

class ReviewStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> distribution;

  ReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.distribution,
  });

  factory ReviewStats.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] ?? json;
    final distData = stats['distribution'] as Map<String, dynamic>? ?? {};

    final distribution = <int, int>{};
    for (int i = 1; i <= 5; i++) {
      // Try both string and int keys
      final value = distData['$i'] ?? distData[i] ?? 0;
      distribution[i] = value is int ? value : (value as num?)?.toInt() ?? 0;
    }

    return ReviewStats(
      averageRating: (stats['averageRating'] ?? 0).toDouble(),
      totalReviews: (stats['totalReviews'] ?? 0) is int
          ? stats['totalReviews']
          : (stats['totalReviews'] as num?)?.toInt() ?? 0,
      distribution: distribution,
    );
  }

  double getPercentage(int rating) {
    if (totalReviews == 0) return 0;
    return (distribution[rating] ?? 0) / totalReviews * 100;
  }
}
