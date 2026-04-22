class VetEarningsPoint {
  final String key;
  final String label;
  final double revenue;
  final int appointments;

  const VetEarningsPoint({
    required this.key,
    required this.label,
    required this.revenue,
    required this.appointments,
  });

  factory VetEarningsPoint.fromJson(Map<String, dynamic> json) {
    return VetEarningsPoint(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      appointments: (json['appointments'] as num?)?.toInt() ?? 0,
    );
  }
}

class VetEarningsBreakdownItem {
  final String type;
  final String label;
  final double revenue;
  final int appointments;

  const VetEarningsBreakdownItem({
    required this.type,
    required this.label,
    required this.revenue,
    required this.appointments,
  });

  factory VetEarningsBreakdownItem.fromJson(Map<String, dynamic> json) {
    return VetEarningsBreakdownItem(
      type: json['type']?.toString() ?? 'clinic',
      label: json['label']?.toString() ?? 'Klinik',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      appointments: (json['appointments'] as num?)?.toInt() ?? 0,
    );
  }
}

class VetRecentCompletedItem {
  final String id;
  final String petName;
  final String ownerName;
  final String type;
  final double feeAmount;
  final DateTime? completedAt;

  const VetRecentCompletedItem({
    required this.id,
    required this.petName,
    required this.ownerName,
    required this.type,
    required this.feeAmount,
    this.completedAt,
  });

  factory VetRecentCompletedItem.fromJson(Map<String, dynamic> json) {
    return VetRecentCompletedItem(
      id: json['id']?.toString() ?? '',
      petName: json['petName']?.toString() ?? 'Pet',
      ownerName: json['ownerName']?.toString() ?? 'Musteri',
      type: json['type']?.toString() ?? 'clinic',
      feeAmount: (json['feeAmount'] as num?)?.toDouble() ?? 0,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
    );
  }
}

class VetEarningsSummaryModel {
  final String vetId;
  final String vetName;
  final double totalRevenue;
  final double thisMonthRevenue;
  final double upcomingRevenue;
  final double averageCompletedFee;
  final int totalAppointments;
  final int pendingAppointments;
  final int confirmedAppointments;
  final int completedAppointments;
  final int cancelledAppointments;
  final int noShowAppointments;
  final double clinicConsultationFee;
  final double onlineConsultationFee;
  final List<VetEarningsPoint> dailyTrend;
  final List<VetEarningsPoint> monthlyTrend;
  final List<VetEarningsBreakdownItem> typeBreakdown;
  final List<VetRecentCompletedItem> recentCompleted;

  const VetEarningsSummaryModel({
    required this.vetId,
    required this.vetName,
    required this.totalRevenue,
    required this.thisMonthRevenue,
    required this.upcomingRevenue,
    required this.averageCompletedFee,
    required this.totalAppointments,
    required this.pendingAppointments,
    required this.confirmedAppointments,
    required this.completedAppointments,
    required this.cancelledAppointments,
    required this.noShowAppointments,
    required this.clinicConsultationFee,
    required this.onlineConsultationFee,
    this.dailyTrend = const [],
    this.monthlyTrend = const [],
    this.typeBreakdown = const [],
    this.recentCompleted = const [],
  });

  factory VetEarningsSummaryModel.fromJson(Map<String, dynamic> json) {
    final summary = (json['summary'] as Map<String, dynamic>?) ?? json;
    return VetEarningsSummaryModel(
      vetId: summary['vetId']?.toString() ?? '',
      vetName: summary['vetName']?.toString() ?? '',
      totalRevenue: (summary['totalRevenue'] as num?)?.toDouble() ?? 0,
      thisMonthRevenue: (summary['thisMonthRevenue'] as num?)?.toDouble() ?? 0,
      upcomingRevenue: (summary['upcomingRevenue'] as num?)?.toDouble() ?? 0,
      averageCompletedFee:
          (summary['averageCompletedFee'] as num?)?.toDouble() ?? 0,
      totalAppointments: (summary['totalAppointments'] as num?)?.toInt() ?? 0,
      pendingAppointments:
          (summary['pendingAppointments'] as num?)?.toInt() ?? 0,
      confirmedAppointments:
          (summary['confirmedAppointments'] as num?)?.toInt() ?? 0,
      completedAppointments:
          (summary['completedAppointments'] as num?)?.toInt() ?? 0,
      cancelledAppointments:
          (summary['cancelledAppointments'] as num?)?.toInt() ?? 0,
      noShowAppointments: (summary['noShowAppointments'] as num?)?.toInt() ?? 0,
      clinicConsultationFee:
          (summary['clinicConsultationFee'] as num?)?.toDouble() ?? 0,
      onlineConsultationFee:
          (summary['onlineConsultationFee'] as num?)?.toDouble() ?? 0,
      dailyTrend:
          (json['dailyTrend'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(VetEarningsPoint.fromJson)
              .toList() ??
          const [],
      monthlyTrend:
          (json['monthlyTrend'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(VetEarningsPoint.fromJson)
              .toList() ??
          const [],
      typeBreakdown:
          (json['typeBreakdown'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(VetEarningsBreakdownItem.fromJson)
              .toList() ??
          const [],
      recentCompleted:
          (json['recentCompleted'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(VetRecentCompletedItem.fromJson)
              .toList() ??
          const [],
    );
  }
}
