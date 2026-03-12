// lib/features/pets/domain/models/pet_model.dart
import 'dart:convert';

class PetOwner {
  final String id;
  final String name;
  final String? avatarUrl;

  PetOwner({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  static String _fixText(dynamic value) {
    final raw = value?.toString() ?? '';
    try {
      // Decode common mojibake (UTF-8 bytes read as Latin1)
      final fixed = utf8.decode(latin1.encode(raw));
      return fixed.isNotEmpty ? fixed : raw;
    } catch (_) {
      return raw;
    }
  }

  factory PetOwner.fromJson(Map<String, dynamic> json) {
    return PetOwner(
      id: json['_id'] ?? json['id'] ?? '',
      name: _fixText(json['name'] ?? 'Bilinmeyen Kullanici'),
      avatarUrl: json['avatarUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarUrl': avatarUrl,
      };
}

class Pet {
  final String id;
  final PetOwner? owner;
  final String name;
  final String species;
  final String breed;
  final String gender;
  final int ageMonths;
  final String? bio;
  final List<String> photos;
  final List<String> images;
  final List<String> videos;
  final String advertType;
  final bool vaccinated;
  final Map<String, dynamic> location;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? birthDate;
  final int viewCount;

  const Pet({
    required this.id,
    this.owner,
    required this.name,
    required this.species,
    required this.breed,
    required this.gender,
    required this.ageMonths,
    this.bio,
    required this.photos,
    required this.images,
    required this.videos,
    required this.advertType,
    required this.vaccinated,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.isActive,
    this.createdAt,
    this.birthDate,
    this.viewCount = 0,
  });

  static String _fixText(dynamic value) {
    final raw = value?.toString() ?? '';
    try {
      return utf8.decode(latin1.encode(raw));
    } catch (_) {
      return raw;
    }
  }

  factory Pet.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> defaultLocation = {
      'type': 'Point',
      'coordinates': [0.0, 0.0],
    };

    final locationData = json['location'];
    Map<String, dynamic> locationMap = defaultLocation;
    double? latitude;
    double? longitude;

    if (locationData is Map<String, dynamic>) {
      locationMap = Map<String, dynamic>.from(locationData);
      final coords = locationData['coordinates'];
      if (coords is List && coords.length >= 2) {
        longitude = _parseDouble(coords[0]);
        latitude = _parseDouble(coords[1]);
      }
    }

    final ageValue = json['ageMonths'];
    final int parsedAge = ageValue is int
        ? ageValue
        : ageValue is String
            ? int.tryParse(ageValue) ?? 0
            : 0;

    final photosList =
        (json['photos'] as List?)?.whereType<String>().toList(growable: false) ??
            const <String>[];
    final imagesList =
        (json['images'] as List?)?.whereType<String>().toList(growable: false) ??
            photosList;
    final videosList =
        (json['videos'] as List?)?.whereType<String>().toList(growable: false) ??
            const <String>[];

    // Safely parse owner
    PetOwner? ownerObj;
    try {
      if (json['ownerId'] != null) {
        if (json['ownerId'] is Map<String, dynamic>) {
          ownerObj = PetOwner.fromJson(json['ownerId']);
        } else if (json['ownerId'] is String) {
          // ownerId is just an ID string, not populated
          ownerObj = null;
        }
      }
    } catch (e) {
      print('⚠️ Failed to parse Pet owner: $e');
      ownerObj = null;
    }

    return Pet(
      id: json['id'] ?? json['_id'] ?? '',
      owner: ownerObj,
      name: _fixText(json['name'] ?? 'Bilinmeyen Evcil'),
      species: _fixText(json['species'] ?? 'Bilinmiyor'),
      breed: _fixText(json['breed'] ?? 'Bilinmiyor'),
      gender: _fixText(json['gender'] ?? 'Bilinmiyor'),
      photos: photosList,
      images: imagesList,
      videos: videosList,
      advertType: json['advertType']?.toString() ?? 'adoption',
      ageMonths: parsedAge,
      bio: json['bio'] != null ? _fixText(json['bio']) : null,
      vaccinated: json['vaccinated'] == true,
      location: locationMap,
      latitude: latitude,
      longitude: longitude,
      isActive: json['isActive'] != false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      birthDate: json['birthDate'] != null
          ? DateTime.tryParse(json['birthDate'].toString())
          : null,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'breed': breed,
      'gender': gender,
      'ageMonths': ageMonths,
      'bio': bio,
      'vaccinated': vaccinated,
      'advertType': advertType,
      'photos': photos,
      'images': images,
      'videos': videos,
      'location': location,
      'isActive': isActive,
      if (owner != null)
        'ownerId': {
          'id': owner!.id,
          'name': owner!.name,
          'avatarUrl': owner!.avatarUrl,
        },
    };
  }
}

double? _parseDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
