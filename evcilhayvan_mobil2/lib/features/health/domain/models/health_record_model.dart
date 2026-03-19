class HealthRecord {
  final String id;
  final String petId;
  final String type; // weight | medication | vet_visit | note
  final DateTime date;
  final double? weightKg;
  final String? medicationName;
  final String? dosage;
  final String? frequency;
  final String? vetName;
  final String? diagnosis;
  final String? notes;
  final DateTime? createdAt;

  const HealthRecord({
    required this.id,
    required this.petId,
    required this.type,
    required this.date,
    this.weightKg,
    this.medicationName,
    this.dosage,
    this.frequency,
    this.vetName,
    this.diagnosis,
    this.notes,
    this.createdAt,
  });

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    return HealthRecord(
      id: json['_id'] ?? json['id'] ?? '',
      petId: json['petId']?.toString() ?? '',
      type: json['type'] ?? 'note',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      medicationName: json['medicationName'],
      dosage: json['dosage'],
      frequency: json['frequency'],
      vetName: json['vetName'],
      diagnosis: json['diagnosis'],
      notes: json['notes'],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
