class VaccinationScheduleModel {
  final String id;
  final String species;
  final String vaccineName;
  final String vaccineCode;
  final String? description;
  final int firstDoseMonths;
  final int? secondDoseMonths;
  final int? repeatIntervalMonths;
  final bool isRequired;

  VaccinationScheduleModel({
    required this.id,
    required this.species,
    required this.vaccineName,
    required this.vaccineCode,
    this.description,
    required this.firstDoseMonths,
    this.secondDoseMonths,
    this.repeatIntervalMonths,
    this.isRequired = true,
  });

  factory VaccinationScheduleModel.fromJson(Map<String, dynamic> json) {
    return VaccinationScheduleModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      species: json['species'] ?? '',
      vaccineName: json['vaccineName'] ?? '',
      vaccineCode: json['vaccineCode'] ?? '',
      description: json['description'] as String?,
      firstDoseMonths: (json['firstDoseMonths'] as num?)?.toInt() ?? 0,
      secondDoseMonths: (json['secondDoseMonths'] as num?)?.toInt(),
      repeatIntervalMonths: (json['repeatIntervalMonths'] as num?)?.toInt(),
      isRequired: json['isRequired'] != false,
    );
  }
}

class VaccinationCalendarItem {
  final VaccinationScheduleModel schedule;
  final String status; // completed, overdue, due_soon, upcoming, not_started
  final DateTime? lastDate;
  final DateTime? nextDueDate;
  final List<VaccinationCalendarRecord> records;

  VaccinationCalendarItem({
    required this.schedule,
    required this.status,
    this.lastDate,
    this.nextDueDate,
    this.records = const [],
  });

  factory VaccinationCalendarItem.fromJson(Map<String, dynamic> json) {
    return VaccinationCalendarItem(
      schedule: VaccinationScheduleModel.fromJson(
        Map<String, dynamic>.from(json['schedule'] ?? {}),
      ),
      status: json['status'] ?? 'not_started',
      lastDate: json['lastDate'] != null ? DateTime.tryParse(json['lastDate'].toString()) : null,
      nextDueDate: json['nextDueDate'] != null ? DateTime.tryParse(json['nextDueDate'].toString()) : null,
      records: (json['records'] as List<dynamic>?)
              ?.map((e) => VaccinationCalendarRecord.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  bool get isOverdue => status == 'overdue';
  bool get isDueSoon => status == 'due_soon';
  bool get isCompleted => status == 'completed';

  String get statusText {
    switch (status) {
      case 'completed':
        return 'Tamamlandi';
      case 'overdue':
        return 'Gecikti';
      case 'due_soon':
        return 'Yaklasıyor';
      case 'upcoming':
        return 'Gelecek';
      case 'not_started':
        return 'Baslamadi';
      default:
        return status;
    }
  }
}

class VaccinationCalendarRecord {
  final String id;
  final DateTime dateAdministered;
  final String? notes;

  VaccinationCalendarRecord({
    required this.id,
    required this.dateAdministered,
    this.notes,
  });

  factory VaccinationCalendarRecord.fromJson(Map<String, dynamic> json) {
    return VaccinationCalendarRecord(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      dateAdministered: DateTime.tryParse(json['dateAdministered']?.toString() ?? '') ?? DateTime.now(),
      notes: json['notes'] as String?,
    );
  }
}
