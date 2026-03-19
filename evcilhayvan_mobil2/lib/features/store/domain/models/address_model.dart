// lib/features/store/domain/models/address_model.dart

class AddressModel {
  final String id;
  final String title;
  final String fullName;
  final String phone;
  final String city;
  final String district;
  final String? neighborhood;
  final String street;
  final String? buildingNo;
  final String? floor;
  final String? apartmentNo;
  final String? postalCode;
  final bool isDefault;
  final DateTime createdAt;

  AddressModel({
    required this.id,
    required this.title,
    required this.fullName,
    required this.phone,
    required this.city,
    required this.district,
    this.neighborhood,
    required this.street,
    this.buildingNo,
    this.floor,
    this.apartmentNo,
    this.postalCode,
    this.isDefault = false,
    required this.createdAt,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      neighborhood: json['neighborhood']?.toString(),
      street: json['street']?.toString() ?? '',
      buildingNo: json['buildingNo']?.toString(),
      floor: json['floor']?.toString(),
      apartmentNo: json['apartmentNo']?.toString(),
      postalCode: json['postalCode']?.toString(),
      isDefault: json['isDefault'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'fullName': fullName,
      'phone': phone,
      'city': city,
      'district': district,
      'neighborhood': neighborhood,
      'street': street,
      'buildingNo': buildingNo,
      'floor': floor,
      'apartmentNo': apartmentNo,
      'postalCode': postalCode,
      'isDefault': isDefault,
    };
  }

  String get fullAddress {
    final parts = <String>[];
    parts.add(street);
    if (buildingNo != null && buildingNo!.isNotEmpty) parts.add('No: $buildingNo');
    if (floor != null && floor!.isNotEmpty) parts.add('Kat: $floor');
    if (apartmentNo != null && apartmentNo!.isNotEmpty) parts.add('Daire: $apartmentNo');
    if (neighborhood != null && neighborhood!.isNotEmpty) parts.add(neighborhood!);
    parts.add(district);
    parts.add(city);
    return parts.join(', ');
  }

  AddressModel copyWith({
    String? id,
    String? title,
    String? fullName,
    String? phone,
    String? city,
    String? district,
    String? neighborhood,
    String? street,
    String? buildingNo,
    String? floor,
    String? apartmentNo,
    String? postalCode,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      title: title ?? this.title,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      district: district ?? this.district,
      neighborhood: neighborhood ?? this.neighborhood,
      street: street ?? this.street,
      buildingNo: buildingNo ?? this.buildingNo,
      floor: floor ?? this.floor,
      apartmentNo: apartmentNo ?? this.apartmentNo,
      postalCode: postalCode ?? this.postalCode,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}