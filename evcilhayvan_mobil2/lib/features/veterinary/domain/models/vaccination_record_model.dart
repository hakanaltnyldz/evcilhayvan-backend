class VaccinationRecordModel {
  final String id;
  final String petId;
  final String userId;
  final String? veterinaryId;
  final String vaccineName;
  final String? vaccineCode;
  final String? batchNumber;
  final DateTime dateAdministered;
  final DateTime? nextDueDate;
  final bool reminderSent;
  final String? notes;
  final DateTime? createdAt;

  // Populated
  final String? vetName;

  VaccinationRecordModel({
    required this.id,
    required this.petId,
    required this.userId,
    this.veterinaryId,
    required this.vaccineName,
    this.vaccineCode,
    this.batchNumber,
    required this.dateAdministered,
    this.nextDueDate,
    this.reminderSent = false,
    this.notes,
    this.createdAt,
    this.vetName,
  });

  factory VaccinationRecordModel.fromJson(Map<String, dynamic> json) {
    String? vetName;
    String? vetId;
    final vetRaw = json['veterinaryId'];
    if (vetRaw is Map<String, dynamic>) {
      vetId = vetRaw['_id']?.toString() ?? vetRaw['id']?.toString();
      vetName = vetRaw['name'] as String?;
    } else {
      vetId = vetRaw?.toString();
    }

    // petId may be a populated object when returned from reminders endpoint
    String petId = '';
    final petRaw = json['petId'];
    if (petRaw is Map<String, dynamic>) {
      petId = petRaw['_id']?.toString() ?? petRaw['id']?.toString() ?? '';
    } else {
      petId = petRaw?.toString() ?? '';
    }

    return VaccinationRecordModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      petId: petId,
      userId: json['userId']?.toString() ?? '',
      veterinaryId: vetId,
      vaccineName: json['vaccineName'] ?? '',
      vaccineCode: json['vaccineCode'] as String?,
      batchNumber: json['batchNumber'] as String?,
      dateAdministered: DateTime.tryParse(json['dateAdministered']?.toString() ?? '') ?? DateTime.now(),
      nextDueDate: json['nextDueDate'] != null ? DateTime.tryParse(json['nextDueDate'].toString()) : null,
      reminderSent: json['reminderSent'] == true,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      vetName: vetName,
    );
  }

  Map<String, dynamic> toJson() => {
        'petId': petId,
        'vaccineName': vaccineName,
        if (vaccineCode != null) 'vaccineCode': vaccineCode,
        if (batchNumber != null) 'batchNumber': batchNumber,
        'dateAdministered': dateAdministered.toIso8601String(),
        if (nextDueDate != null) 'nextDueDate': nextDueDate!.toIso8601String(),
        if (veterinaryId != null) 'veterinaryId': veterinaryId,
        if (notes != null) 'notes': notes,
      };

  bool get isOverdue => nextDueDate != null && nextDueDate!.isBefore(DateTime.now());
  bool get isDueSoon =>
      nextDueDate != null &&
      !isOverdue &&
      nextDueDate!.difference(DateTime.now()).inDays <= 7;
}
