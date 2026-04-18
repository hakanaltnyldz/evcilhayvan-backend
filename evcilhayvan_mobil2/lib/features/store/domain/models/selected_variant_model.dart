class SelectedVariantModel {
  final String name;
  final String label;

  const SelectedVariantModel({required this.name, required this.label});

  factory SelectedVariantModel.fromJson(Map<String, dynamic> json) {
    return SelectedVariantModel(
      name: (json['name'] as String? ?? '').trim(),
      label: (json['label'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'label': label};

  String get signature => '$name::$label';
  String get displayText => '$name: $label';

  static List<SelectedVariantModel> fromSelectionsMap(
    Map<String, String> selections,
  ) {
    return selections.entries
        .map(
          (entry) => SelectedVariantModel(
            name: entry.key.trim(),
            label: entry.value.trim(),
          ),
        )
        .where((variant) => variant.name.isNotEmpty && variant.label.isNotEmpty)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  static List<SelectedVariantModel> fromJsonList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(SelectedVariantModel.fromJson)
        .where((variant) => variant.name.isNotEmpty && variant.label.isNotEmpty)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  static List<SelectedVariantModel> fromLegacy({
    String? variantName,
    String? variantLabel,
  }) {
    final name = variantName?.trim() ?? '';
    final label = variantLabel?.trim() ?? '';
    if (name.isEmpty || label.isEmpty) return const [];
    return [SelectedVariantModel(name: name, label: label)];
  }

  static String signatureOf(List<SelectedVariantModel> variants) {
    final normalized = [...variants]..sort((a, b) => a.name.compareTo(b.name));
    return normalized.map((variant) => variant.signature).join('|');
  }
}
