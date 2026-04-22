class PrescriptionMedicationModel {
  final String name;
  final String? dosage;
  final String? frequency;
  final int? durationDays;
  final String? instructions;

  const PrescriptionMedicationModel({
    required this.name,
    this.dosage,
    this.frequency,
    this.durationDays,
    this.instructions,
  });

  factory PrescriptionMedicationModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionMedicationModel(
      name: json['name']?.toString() ?? '',
      dosage: json['dosage']?.toString(),
      frequency: json['frequency']?.toString(),
      durationDays: (json['durationDays'] as num?)?.toInt(),
      instructions: json['instructions']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (dosage != null) 'dosage': dosage,
    if (frequency != null) 'frequency': frequency,
    if (durationDays != null) 'durationDays': durationDays,
    if (instructions != null) 'instructions': instructions,
  };
}

class AppointmentPrescriptionModel {
  final String id;
  final String appointmentId;
  final String diagnosis;
  final String? notes;
  final DateTime? followUpDate;
  final String status;
  final DateTime? issuedAt;
  final List<PrescriptionMedicationModel> medications;

  const AppointmentPrescriptionModel({
    required this.id,
    required this.appointmentId,
    required this.diagnosis,
    this.notes,
    this.followUpDate,
    this.status = 'active',
    this.issuedAt,
    this.medications = const [],
  });

  factory AppointmentPrescriptionModel.fromJson(Map<String, dynamic> json) {
    return AppointmentPrescriptionModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      appointmentId: json['appointmentId']?.toString() ?? '',
      diagnosis: json['diagnosis']?.toString() ?? '',
      notes: json['notes']?.toString(),
      followUpDate: json['followUpDate'] != null
          ? DateTime.tryParse(json['followUpDate'].toString())
          : null,
      status: json['status']?.toString() ?? 'active',
      issuedAt: json['issuedAt'] != null
          ? DateTime.tryParse(json['issuedAt'].toString())
          : null,
      medications:
          (json['medications'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(PrescriptionMedicationModel.fromJson)
              .toList() ??
          const [],
    );
  }
}
