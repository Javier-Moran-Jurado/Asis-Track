// lib/models/planilla_field_def.dart
class PlanillaFieldDef {
  final String key;
  final String label;
  final String type;
  final int? originalCampoId;

  const PlanillaFieldDef({
    required this.key,
    required this.label,
    required this.type,
    this.originalCampoId,
  });

  factory PlanillaFieldDef.fromJson(Map<String, dynamic> json) {
    return PlanillaFieldDef(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      originalCampoId: (json['originalCampoId'] as num?)?.toInt(),
    );
  }
}
