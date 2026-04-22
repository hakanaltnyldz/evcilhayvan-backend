class SitterFinancePoint {
  final String key;
  final String label;
  final double revenue;
  final int bookings;

  const SitterFinancePoint({
    required this.key,
    required this.label,
    required this.revenue,
    required this.bookings,
  });

  factory SitterFinancePoint.fromJson(Map<String, dynamic> json) {
    return SitterFinancePoint(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      bookings: (json['bookings'] as num?)?.toInt() ?? 0,
    );
  }
}

class SitterServiceBreakdown {
  final String serviceType;
  final String serviceLabel;
  final double revenue;
  final int bookings;

  const SitterServiceBreakdown({
    required this.serviceType,
    required this.serviceLabel,
    required this.revenue,
    required this.bookings,
  });

  factory SitterServiceBreakdown.fromJson(Map<String, dynamic> json) {
    return SitterServiceBreakdown(
      serviceType: json['serviceType']?.toString() ?? '',
      serviceLabel: json['serviceLabel']?.toString() ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      bookings: (json['bookings'] as num?)?.toInt() ?? 0,
    );
  }
}

class SitterRecentCompletedItem {
  final String id;
  final String serviceType;
  final String serviceLabel;
  final double revenue;
  final DateTime? completedAt;
  final String ownerName;
  final String petName;

  const SitterRecentCompletedItem({
    required this.id,
    required this.serviceType,
    required this.serviceLabel,
    required this.revenue,
    this.completedAt,
    required this.ownerName,
    required this.petName,
  });

  factory SitterRecentCompletedItem.fromJson(Map<String, dynamic> json) {
    return SitterRecentCompletedItem(
      id: json['id']?.toString() ?? '',
      serviceType: json['serviceType']?.toString() ?? '',
      serviceLabel: json['serviceLabel']?.toString() ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
      ownerName: json['ownerName']?.toString() ?? 'Musteri',
      petName: json['petName']?.toString() ?? 'Pet',
    );
  }
}

class SitterFinancialSummaryModel {
  final double totalRevenue;
  final double thisMonthRevenue;
  final double pipelineRevenue;
  final double pausedRevenue;
  final int totalBookings;
  final int pendingBookings;
  final int acceptedBookings;
  final int activeBookings;
  final int completedBookings;
  final int cancelledBookings;
  final int pausedBookings;
  final List<SitterFinancePoint> dailyTrend;
  final List<SitterFinancePoint> monthlyTrend;
  final List<SitterServiceBreakdown> serviceBreakdown;
  final List<SitterRecentCompletedItem> recentCompleted;

  const SitterFinancialSummaryModel({
    required this.totalRevenue,
    required this.thisMonthRevenue,
    required this.pipelineRevenue,
    required this.pausedRevenue,
    required this.totalBookings,
    required this.pendingBookings,
    required this.acceptedBookings,
    required this.activeBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.pausedBookings,
    this.dailyTrend = const [],
    this.monthlyTrend = const [],
    this.serviceBreakdown = const [],
    this.recentCompleted = const [],
  });

  factory SitterFinancialSummaryModel.fromJson(Map<String, dynamic> json) {
    final summary = (json['summary'] as Map<String, dynamic>?) ?? json;
    return SitterFinancialSummaryModel(
      totalRevenue: (summary['totalRevenue'] as num?)?.toDouble() ?? 0,
      thisMonthRevenue: (summary['thisMonthRevenue'] as num?)?.toDouble() ?? 0,
      pipelineRevenue: (summary['pipelineRevenue'] as num?)?.toDouble() ?? 0,
      pausedRevenue: (summary['pausedRevenue'] as num?)?.toDouble() ?? 0,
      totalBookings: (summary['totalBookings'] as num?)?.toInt() ?? 0,
      pendingBookings: (summary['pendingBookings'] as num?)?.toInt() ?? 0,
      acceptedBookings: (summary['acceptedBookings'] as num?)?.toInt() ?? 0,
      activeBookings: (summary['activeBookings'] as num?)?.toInt() ?? 0,
      completedBookings: (summary['completedBookings'] as num?)?.toInt() ?? 0,
      cancelledBookings: (summary['cancelledBookings'] as num?)?.toInt() ?? 0,
      pausedBookings: (summary['pausedBookings'] as num?)?.toInt() ?? 0,
      dailyTrend:
          (json['dailyTrend'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(SitterFinancePoint.fromJson)
              .toList() ??
          const [],
      monthlyTrend:
          (json['monthlyTrend'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(SitterFinancePoint.fromJson)
              .toList() ??
          const [],
      serviceBreakdown:
          (json['serviceBreakdown'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(SitterServiceBreakdown.fromJson)
              .toList() ??
          const [],
      recentCompleted:
          (json['recentCompleted'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(SitterRecentCompletedItem.fromJson)
              .toList() ??
          const [],
    );
  }
}
