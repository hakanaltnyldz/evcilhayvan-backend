class StoreOwner {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? city;

  StoreOwner({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.city,
  });

  factory StoreOwner.fromJson(Map<String, dynamic> json) {
    return StoreOwner(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Satıcı',
      avatarUrl: json['avatarUrl'] as String?,
      city: json['city'] as String?,
    );
  }
}

class StoreModel {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final bool isActive;
  final StoreOwner? owner;
  final String? bannerUrl;
  final String? phone;
  final String? website;
  final String? instagram;
  final String? twitter;
  final String? facebook;
  final String? workingHours;

  StoreModel({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.owner,
    this.isActive = true,
    this.bannerUrl,
    this.phone,
    this.website,
    this.instagram,
    this.twitter,
    this.facebook,
    this.workingHours,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? json['storeName'] ?? 'Mağaza',
      description: json['description'] ?? json['storeDescription'],
      logoUrl: json['logoUrl'] ?? json['storeLogo'],
      isActive: json['isActive'] != null ? json['isActive'] as bool : true,
      owner: json['owner'] != null && json['owner'] is Map<String, dynamic>
          ? StoreOwner.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
      bannerUrl: json['bannerUrl'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      instagram: json['instagram'] as String?,
      twitter: json['twitter'] as String?,
      facebook: json['facebook'] as String?,
      workingHours: json['workingHours'] as String?,
    );
  }
}
