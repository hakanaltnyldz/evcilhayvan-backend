class WorkingHours {
  final int day;
  final String? open;
  final String? close;
  final bool isClosed;

  WorkingHours({
    required this.day,
    this.open,
    this.close,
    this.isClosed = false,
  });

  factory WorkingHours.fromJson(Map<String, dynamic> json) {
    return WorkingHours(
      day: (json['day'] as num?)?.toInt() ?? 0,
      open: json['open'] as String?,
      close: json['close'] as String?,
      isClosed: json['isClosed'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'day': day,
    'open': open,
    'close': close,
    'isClosed': isClosed,
  };

  String get dayName {
    const days = [
      'Pazartesi',
      'Sali',
      'Carsamba',
      'Persembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    return days[day.clamp(0, 6)];
  }
}

class AvailabilityOverrideModel {
  final DateTime date;
  final String? open;
  final String? close;
  final bool isClosed;

  const AvailabilityOverrideModel({
    required this.date,
    this.open,
    this.close,
    this.isClosed = false,
  });

  factory AvailabilityOverrideModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityOverrideModel(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      open: json['open'] as String?,
      close: json['close'] as String?,
      isClosed: json['isClosed'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': _formatDateOnly(date),
    'open': open,
    'close': close,
    'isClosed': isClosed,
  };
}

class VeterinaryModel {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final String? description;
  final List<String> photos;
  final double? latitude;
  final double? longitude;
  final String source;
  final String? googlePlaceId;
  final double? googleRating;
  final int googleReviewCount;
  final bool isVerified;
  final bool isActive;
  final List<String> services;
  final bool acceptsOnlineAppointments;
  final int appointmentSlotMinutes;
  final double clinicConsultationFee;
  final double onlineConsultationFee;
  final List<WorkingHours> workingHours;
  final List<AvailabilityOverrideModel> availabilityOverrides;
  final List<String> speciesServed;
  final String? userId;
  final String? registeredBy;

  VeterinaryModel({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.description,
    this.photos = const [],
    this.latitude,
    this.longitude,
    this.source = 'manual',
    this.googlePlaceId,
    this.googleRating,
    this.googleReviewCount = 0,
    this.isVerified = false,
    this.isActive = true,
    this.services = const [],
    this.acceptsOnlineAppointments = false,
    this.appointmentSlotMinutes = 30,
    this.clinicConsultationFee = 0,
    this.onlineConsultationFee = 0,
    this.workingHours = const [],
    this.availabilityOverrides = const [],
    this.speciesServed = const [],
    this.userId,
    this.registeredBy,
  });

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    if (address != null) 'address': address,
    if (phone != null) 'phone': phone,
    if (email != null) 'email': email,
    if (website != null) 'website': website,
    if (description != null) 'description': description,
    'photos': photos,
    'location': (latitude != null && longitude != null)
        ? {
            'type': 'Point',
            'coordinates': [longitude, latitude],
          }
        : null,
    'source': source,
    if (googlePlaceId != null) 'googlePlaceId': googlePlaceId,
    if (googleRating != null) 'googleRating': googleRating,
    'googleReviewCount': googleReviewCount,
    'isVerified': isVerified,
    'isActive': isActive,
    'services': services,
    'acceptsOnlineAppointments': acceptsOnlineAppointments,
    'appointmentSlotMinutes': appointmentSlotMinutes,
    'clinicConsultationFee': clinicConsultationFee,
    'onlineConsultationFee': onlineConsultationFee,
    'workingHours': workingHours.map((e) => e.toJson()).toList(),
    'availabilityOverrides': availabilityOverrides
        .map((e) => e.toJson())
        .toList(),
    'speciesServed': speciesServed,
    if (userId != null) 'userId': userId,
    if (registeredBy != null) 'registeredBy': registeredBy,
  };

  factory VeterinaryModel.fromJson(Map<String, dynamic> json) {
    final loc = json['location'];
    double? lat, lng;
    if (loc is Map<String, dynamic>) {
      final coords = loc['coordinates'];
      if (coords is List && coords.length == 2) {
        lng = (coords[0] as num?)?.toDouble();
        lat = (coords[1] as num?)?.toDouble();
      }
    }

    return VeterinaryModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      description: json['description'] as String?,
      photos:
          (json['photos'] as List<dynamic>?)?.whereType<String>().toList() ??
          [],
      latitude: lat,
      longitude: lng,
      source: json['source'] ?? 'manual',
      googlePlaceId: json['googlePlaceId'] as String?,
      googleRating: (json['googleRating'] as num?)?.toDouble(),
      googleReviewCount: (json['googleReviewCount'] as num?)?.toInt() ?? 0,
      isVerified: json['isVerified'] == true,
      isActive: json['isActive'] != false,
      services:
          (json['services'] as List<dynamic>?)?.whereType<String>().toList() ??
          [],
      acceptsOnlineAppointments: json['acceptsOnlineAppointments'] == true,
      appointmentSlotMinutes:
          (json['appointmentSlotMinutes'] as num?)?.toInt() ?? 30,
      clinicConsultationFee:
          (json['clinicConsultationFee'] as num?)?.toDouble() ?? 0,
      onlineConsultationFee:
          (json['onlineConsultationFee'] as num?)?.toDouble() ?? 0,
      workingHours:
          (json['workingHours'] as List<dynamic>?)
              ?.map((e) => WorkingHours.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      availabilityOverrides:
          (json['availabilityOverrides'] as List<dynamic>?)
              ?.map(
                (e) => AvailabilityOverrideModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList() ??
          [],
      speciesServed:
          (json['speciesServed'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          [],
      userId: _extractId(json['userId']),
      registeredBy: _extractId(json['registeredBy']),
    );
  }
}

String? _extractId(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value['_id']?.toString() ?? value['id']?.toString();
  }
  return value?.toString();
}

String _formatDateOnly(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
