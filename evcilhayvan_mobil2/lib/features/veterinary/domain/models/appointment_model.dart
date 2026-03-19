class AppointmentModel {
  final String id;
  final String userId;
  final String petId;
  final String veterinaryId;
  final DateTime date;
  final DateTime? endDate;
  final String? reason;
  final String? notes;
  final String status;
  final String? vetNotes;
  final DateTime? createdAt;

  // Populated
  final AppointmentPet? pet;
  final AppointmentVet? vet;

  AppointmentModel({
    required this.id,
    required this.userId,
    required this.petId,
    required this.veterinaryId,
    required this.date,
    this.endDate,
    this.reason,
    this.notes,
    this.status = 'pending',
    this.vetNotes,
    this.createdAt,
    this.pet,
    this.vet,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      petId: _extractId(json['petId']),
      veterinaryId: _extractId(json['veterinaryId']),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'].toString()) : null,
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] ?? 'pending',
      vetNotes: json['vetNotes'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      pet: json['petId'] is Map<String, dynamic> ? AppointmentPet.fromJson(json['petId']) : null,
      vet: json['veterinaryId'] is Map<String, dynamic> ? AppointmentVet.fromJson(json['veterinaryId']) : null,
    );
  }

  static String _extractId(dynamic val) {
    if (val is Map<String, dynamic>) return val['_id']?.toString() ?? val['id']?.toString() ?? '';
    return val?.toString() ?? '';
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';
  bool get canCancel => status == 'pending' || status == 'confirmed';

  String get statusText {
    switch (status) {
      case 'pending': return 'Beklemede';
      case 'confirmed': return 'Onaylandi';
      case 'cancelled': return 'Iptal Edildi';
      case 'completed': return 'Tamamlandi';
      case 'no_show': return 'Gelmedi';
      default: return status;
    }
  }
}

class AppointmentPet {
  final String id;
  final String name;
  final String? species;
  final List<String> photos;

  AppointmentPet({required this.id, required this.name, this.species, this.photos = const []});

  factory AppointmentPet.fromJson(Map<String, dynamic> json) {
    return AppointmentPet(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      species: json['species'] as String?,
      photos: (json['photos'] as List<dynamic>?)?.whereType<String>().toList() ?? [],
    );
  }
}

class AppointmentVet {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final List<String> photos;

  AppointmentVet({required this.id, required this.name, this.address, this.phone, this.photos = const []});

  factory AppointmentVet.fromJson(Map<String, dynamic> json) {
    return AppointmentVet(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      photos: (json['photos'] as List<dynamic>?)?.whereType<String>().toList() ?? [],
    );
  }
}
