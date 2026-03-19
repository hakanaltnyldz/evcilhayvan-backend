class SitterService {
  final String type;
  final double pricePerHour;
  final double pricePerDay;

  const SitterService({required this.type, this.pricePerHour = 0, this.pricePerDay = 0});

  String get label {
    switch (type) {
      case 'walking': return 'Gezdirme';
      case 'home_sitting': return 'Ev Bakimi';
      case 'boarding': return 'Pansiyonda Bakim';
      case 'daycare': return 'Gunduz Bakimi';
      case 'grooming': return 'Timar/Bakim';
      default: return type;
    }
  }

  factory SitterService.fromJson(Map<String, dynamic> json) => SitterService(
        type: json['type']?.toString() ?? '',
        pricePerHour: _pd(json['pricePerHour']),
        pricePerDay: _pd(json['pricePerDay']),
      );

  Map<String, dynamic> toJson() => {'type': type, 'pricePerHour': pricePerHour, 'pricePerDay': pricePerDay};
}

class SitterReview {
  final String? ownerName;
  final String? ownerAvatar;
  final double rating;
  final String? comment;
  final DateTime? date;

  const SitterReview({this.ownerName, this.ownerAvatar, required this.rating, this.comment, this.date});

  factory SitterReview.fromJson(Map<String, dynamic> json) => SitterReview(
        ownerName: json['ownerName']?.toString(),
        ownerAvatar: json['ownerAvatar']?.toString(),
        rating: _pd(json['rating']),
        comment: json['comment']?.toString(),
        date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
      );
}

class PetSitterModel {
  final String id;
  final String? userId;
  final String displayName;
  final String? bio;
  final String? avatar;
  final List<String> photos;
  final List<SitterService> services;
  final List<String> speciesServed;
  final String? experience;
  final double? latitude;
  final double? longitude;
  final String? address;
  final bool availability;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final double? distanceKm;
  final DateTime? createdAt;

  const PetSitterModel({
    required this.id,
    this.userId,
    required this.displayName,
    this.bio,
    this.avatar,
    this.photos = const [],
    this.services = const [],
    this.speciesServed = const [],
    this.experience,
    this.latitude,
    this.longitude,
    this.address,
    this.availability = true,
    this.rating = 0,
    this.reviewCount = 0,
    this.isVerified = false,
    this.distanceKm,
    this.createdAt,
  });

  double get minPrice {
    if (services.isEmpty) return 0;
    final prices = services.map((s) => s.pricePerHour > 0 ? s.pricePerHour : s.pricePerDay).where((p) => p > 0);
    return prices.isEmpty ? 0 : prices.reduce((a, b) => a < b ? a : b);
  }

  String get speciesLabel => speciesServed.map((s) {
    switch (s) {
      case 'dog': return 'Kopek';
      case 'cat': return 'Kedi';
      case 'bird': return 'Kus';
      case 'rabbit': return 'Tavsan';
      default: return 'Diger';
    }
  }).join(', ');

  factory PetSitterModel.fromJson(Map<String, dynamic> json) {
    double? lat, lng;
    final loc = json['location'];
    if (loc is Map<String, dynamic>) {
      final coords = loc['coordinates'];
      if (coords is List && coords.length >= 2) {
        lng = _pd(coords[0]);
        lat = _pd(coords[1]);
      }
    }

    final userId = json['userId'];
    String? uid;
    if (userId is Map) uid = userId['_id']?.toString() ?? userId['id']?.toString();
    else if (userId is String) uid = userId;

    return PetSitterModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      userId: uid,
      displayName: json['displayName']?.toString() ?? '',
      bio: json['bio']?.toString(),
      avatar: json['avatar']?.toString(),
      photos: (json['photos'] is List) ? (json['photos'] as List).map((e) => e.toString()).toList() : [],
      services: (json['services'] is List)
          ? (json['services'] as List).map((s) => SitterService.fromJson(Map<String, dynamic>.from(s))).toList()
          : [],
      speciesServed: (json['speciesServed'] is List) ? (json['speciesServed'] as List).map((e) => e.toString()).toList() : [],
      experience: json['experience']?.toString(),
      latitude: lat,
      longitude: lng,
      address: json['address']?.toString(),
      availability: json['availability'] != false,
      rating: _pd(json['rating']),
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      isVerified: json['isVerified'] == true,
      distanceKm: _pd(json['distanceKm']),
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
