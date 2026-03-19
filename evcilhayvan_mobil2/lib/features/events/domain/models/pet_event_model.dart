class PetEventModel {
  final String id;
  final String? organizerId;
  final String? organizerName;
  final String? organizerAvatar;
  final String title;
  final String description;
  final String category;
  final List<String> photos;
  final String? coverPhoto;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? venueName;
  final DateTime startDate;
  final DateTime endDate;
  final int? maxAttendees;
  final int attendeeCount;
  final bool isFree;
  final double price;
  final List<String> speciesAllowed;
  final List<String> tags;
  final bool isCancelled;
  final String? externalLink;
  final double? distanceKm;
  final DateTime? createdAt;

  // Client-side: kullanicinin katilim durumu
  final String? myAttendanceStatus;

  const PetEventModel({
    required this.id,
    this.organizerId,
    this.organizerName,
    this.organizerAvatar,
    required this.title,
    required this.description,
    required this.category,
    this.photos = const [],
    this.coverPhoto,
    this.latitude,
    this.longitude,
    this.address,
    this.venueName,
    required this.startDate,
    required this.endDate,
    this.maxAttendees,
    this.attendeeCount = 0,
    this.isFree = true,
    this.price = 0,
    this.speciesAllowed = const ['all'],
    this.tags = const [],
    this.isCancelled = false,
    this.externalLink,
    this.distanceKm,
    this.createdAt,
    this.myAttendanceStatus,
  });

  String get categoryLabel {
    switch (category) {
      case 'park_meetup': return 'Park Bulusmasi';
      case 'adoption_day': return 'Sahiplendirme Gunu';
      case 'training': return 'Egitim';
      case 'competition': return 'Yaris/Gosterim';
      case 'grooming': return 'Bakim Gunu';
      case 'health': return 'Saglik/Asi';
      default: return 'Diger';
    }
  }

  bool get isUpcoming => startDate.isAfter(DateTime.now());
  bool get isGoing => myAttendanceStatus == 'going';
  bool get isFull => maxAttendees != null && attendeeCount >= maxAttendees!;
  String get firstPhoto => coverPhoto ?? (photos.isNotEmpty ? photos.first : '');

  PetEventModel copyWith({String? myAttendanceStatus}) => PetEventModel(
        id: id,
        organizerId: organizerId,
        organizerName: organizerName,
        organizerAvatar: organizerAvatar,
        title: title,
        description: description,
        category: category,
        photos: photos,
        coverPhoto: coverPhoto,
        latitude: latitude,
        longitude: longitude,
        address: address,
        venueName: venueName,
        startDate: startDate,
        endDate: endDate,
        maxAttendees: maxAttendees,
        attendeeCount: attendeeCount,
        isFree: isFree,
        price: price,
        speciesAllowed: speciesAllowed,
        tags: tags,
        isCancelled: isCancelled,
        externalLink: externalLink,
        distanceKm: distanceKm,
        createdAt: createdAt,
        myAttendanceStatus: myAttendanceStatus ?? this.myAttendanceStatus,
      );

  factory PetEventModel.fromJson(Map<String, dynamic> json) {
    double? lat, lng;
    final loc = json['location'];
    if (loc is Map<String, dynamic>) {
      final coords = loc['coordinates'];
      if (coords is List && coords.length >= 2) {
        lng = _pd(coords[0]);
        lat = _pd(coords[1]);
      }
    }

    String? organizerId, organizerName, organizerAvatar;
    final org = json['organizerId'];
    if (org is Map<String, dynamic>) {
      organizerId = org['_id']?.toString() ?? org['id']?.toString();
      organizerName = org['name']?.toString();
      organizerAvatar = org['avatarUrl']?.toString();
    } else if (org is String) {
      organizerId = org;
    }

    return PetEventModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      organizerId: organizerId,
      organizerName: organizerName,
      organizerAvatar: organizerAvatar,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'other',
      photos: (json['photos'] is List) ? (json['photos'] as List).map((e) => e.toString()).toList() : [],
      coverPhoto: json['coverPhoto']?.toString(),
      latitude: lat,
      longitude: lng,
      address: json['address']?.toString(),
      venueName: json['venueName']?.toString(),
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now() : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'].toString()) ?? DateTime.now() : DateTime.now(),
      maxAttendees: (json['maxAttendees'] as num?)?.toInt(),
      attendeeCount: (json['attendeeCount'] as num?)?.toInt() ?? 0,
      isFree: json['isFree'] != false,
      price: _pd(json['price']),
      speciesAllowed: (json['speciesAllowed'] is List) ? (json['speciesAllowed'] as List).map((e) => e.toString()).toList() : ['all'],
      tags: (json['tags'] is List) ? (json['tags'] as List).map((e) => e.toString()).toList() : [],
      isCancelled: json['isCancelled'] == true,
      externalLink: json['externalLink']?.toString(),
      distanceKm: _pd(json['distanceKm']) == 0 ? null : _pd(json['distanceKm']),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}

double _pd(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}
