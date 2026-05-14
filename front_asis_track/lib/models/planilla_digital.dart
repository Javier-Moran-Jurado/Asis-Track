// lib/models/planilla_digital.dart
import 'dart:ui' as ui;

import 'planilla_field_def.dart';
import 'student_record.dart';

class PlanillaDigital {
  final String eventId;
  final String eventName;
  final DateTime date;
  final ui.Image referenceImage;
  final List<StudentRecord> records;
  final List<PlanillaFieldDef> fieldDefs;
  final bool isSaved;

  const PlanillaDigital({
    required this.eventId,
    required this.eventName,
    required this.date,
    required this.referenceImage,
    required this.records,
    this.fieldDefs = const [],
    this.isSaved = false,
  });

  bool get hasSignatureField => fieldDefs.any((f) => f.type == 'signature_file');

  PlanillaDigital copyWith({
    String? eventId,
    String? eventName,
    DateTime? date,
    ui.Image? referenceImage,
    List<StudentRecord>? records,
    List<PlanillaFieldDef>? fieldDefs,
    bool? isSaved,
  }) {
    return PlanillaDigital(
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      date: date ?? this.date,
      referenceImage: referenceImage ?? this.referenceImage,
      records: records ?? this.records,
      fieldDefs: fieldDefs ?? this.fieldDefs,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}
