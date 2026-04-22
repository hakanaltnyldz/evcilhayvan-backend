class CareReportModel {
  final String id;
  final String bookingId;
  final int day;
  final String mood;
  final List<String> photos;
  final String? notes;
  final List<String> activities;
  final bool foodEaten;
  final DateTime timestamp;
  final DateTime? sharedWithOwnerAt;

  const CareReportModel({
    required this.id,
    required this.bookingId,
    required this.day,
    required this.mood,
    this.photos = const [],
    this.notes,
    this.activities = const [],
    this.foodEaten = true,
    required this.timestamp,
    this.sharedWithOwnerAt,
  });

  bool get sharedWithOwner => sharedWithOwnerAt != null;

  factory CareReportModel.fromJson(Map<String, dynamic> json) {
    return CareReportModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      day: (json['day'] as num?)?.toInt() ?? 1,
      mood: json['mood']?.toString() ?? 'good',
      photos:
          (json['photos'] as List<dynamic>?)?.whereType<String>().toList() ??
          const [],
      notes: json['notes']?.toString(),
      activities:
          (json['activities'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      foodEaten: json['foodEaten'] != false,
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      sharedWithOwnerAt: json['sharedWithOwnerAt'] != null
          ? DateTime.tryParse(json['sharedWithOwnerAt'].toString())
          : null,
    );
  }
}
