import 'dart:convert';

class LostFoundPet {
  final String id;
  final String? userId;
  final String? userName;
  final String? userAvatar;
  final String type; // lost | found
  final String status; // active | reunited | cancelled
  final String? petName;
  final String species;
  final String? breed;
  final String gender;
  final String color;
  final String? ageApprox;
  final String description;
  final List<String> photos;
  final double? latitude;
  final double? longitude;
  final DateTime lastSeenDate;
  final String? lastSeenAddress;
  final String? contactPhone;
  final String? contactNote;
  final double reward;
  final double? distanceKm;
  final DateTime? resolvedAt;
  final DateTime? createdAt;

  const LostFoundPet({
    required this.id,
    this.userId,
    this.userName,
    this.userAvatar,
    required this.type,
    required this.status,
    this.petName,
    required this.species,
    this.breed,
    this.gender = 'unknown',
    required this.color,
    this.ageApprox,
    required this.description,
    this.photos = const [],
    this.latitude,
    this.longitude,
    required this.lastSeenDate,
    this.lastSeenAddress,
    this.contactPhone,
    this.contactNote,
    this.reward = 0,
    this.distanceKm,
    this.resolvedAt,
    this.createdAt,
  });

  bool get isLost => type == 'lost';
  bool get isFound => type == 'found';
  bool get isActive => status == 'active';
  bool get isReunited => status == 'reunited';
  bool get hasReward => reward > 0;
  String get firstPhoto => photos.isNotEmpty ? photos.first : '';

  String get speciesLabel {
    switch (species) {
      case 'dog': return 'Kopek';
      case 'cat': return 'Kedi';
      case 'bird': return 'Kus';
      case 'rabbit': return 'Tavsan';
      default: return 'Diger';
    }
  }

  String get genderLabel {
    switch (gender) {
      case 'male': return 'Erkek';
      case 'female': return 'Disi';
      default: return 'Bilinmiyor';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'active': return isLost ? 'Kayip' : 'Bulunan';
      case 'reunited': return 'Kavusturuldu';
      case 'cancelled': return 'Iptal';
      default: return status;
    }
  }

  factory LostFoundPet.fromJson(Map<String, dynamic> json) {
    // Extract location
    double? lat, lng;
    final loc = json['location'];
    if (loc is Map<String, dynamic>) {
      final coords = loc['coordinates'];
      if (coords is List && coords.length >= 2) {
        lng = _parseDouble(coords[0]);
        lat = _parseDouble(coords[1]);
      }
    }

    // Parse user info
    String? userName = json['userName'];
    String? userAvatar = json['userAvatar'];
    String? userId;

    final rawUser = json['userId'];
    if (rawUser is Map<String, dynamic>) {
      userId = rawUser['_id']?.toString() ?? rawUser['id']?.toString();
      userName ??= rawUser['name']?.toString();
      userAvatar ??= rawUser['avatarUrl']?.toString();
    } else if (rawUser is String) {
      userId = rawUser;
    }

    return LostFoundPet(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      userId: userId,
      userName: userName != null ? _fixText(userName) : null,
      userAvatar: userAvatar,
      type: json['type']?.toString() ?? 'lost',
      status: json['status']?.toString() ?? 'active',
      petName: json['petName'] != null ? _fixText(json['petName'].toString()) : null,
      species: json['species']?.toString() ?? 'other',
      breed: json['breed']?.toString(),
      gender: json['gender']?.toString() ?? 'unknown',
      color: _fixText(json['color']?.toString() ?? ''),
      ageApprox: json['ageApprox']?.toString(),
      description: _fixText(json['description']?.toString() ?? ''),
      photos: (json['photos'] is List)
          ? (json['photos'] as List).map((e) => e.toString()).toList()
          : [],
      latitude: lat,
      longitude: lng,
      lastSeenDate: json['lastSeenDate'] != null
          ? DateTime.tryParse(json['lastSeenDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastSeenAddress: json['lastSeenAddress']?.toString(),
      contactPhone: json['contactPhone']?.toString(),
      contactNote: json['contactNote']?.toString(),
      reward: _parseDouble(json['reward']) ?? 0,
      distanceKm: _parseDouble(json['distanceKm']),
      resolvedAt: json['resolvedAt'] != null ? DateTime.tryParse(json['resolvedAt'].toString()) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'petName': petName,
    'species': species,
    'breed': breed,
    'gender': gender,
    'color': color,
    'ageApprox': ageApprox,
    'description': description,
    'photos': photos,
    'lastSeenDate': lastSeenDate.toIso8601String(),
    'lastSeenAddress': lastSeenAddress,
    'contactPhone': contactPhone,
    'contactNote': contactNote,
    'reward': reward,
    if (latitude != null && longitude != null)
      'location': {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      },
  };

  static String _fixText(dynamic value) {
    final raw = value?.toString() ?? '';
    try {
      return utf8.decode(latin1.encode(raw));
    } catch (_) {
      return raw;
    }
  }
}

double? _parseDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
