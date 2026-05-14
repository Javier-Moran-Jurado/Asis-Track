// lib/widgets/digitized_data_panel.dart
import 'package:flutter/material.dart';

import '../models/planilla_field_def.dart';
import '../models/student_record.dart';
import 'record_card.dart';

class DigitizedDataPanel extends StatelessWidget {
  final List<StudentRecord> records;
  final int? targetIndex;
  final bool hasSignatureField;
  final List<PlanillaFieldDef> fieldDefs;
  final ValueChanged<int> onSignatureTap;
  final void Function(int index, StudentRecord updated) onRecordChanged;

  const DigitizedDataPanel({
    super.key,
    required this.records,
    required this.targetIndex,
    required this.hasSignatureField,
    required this.fieldDefs,
    required this.onSignatureTap,
    required this.onRecordChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Center(
        child: Text(
          'No se detectaron registros',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = records[index];
        return RecordCard(
          record: record,
          index: index,
          selected: targetIndex == index,
          hasSignatureField: hasSignatureField,
          fieldDefs: fieldDefs,
          onSignatureTap: () => onSignatureTap(index),
          onRecordChanged: (updated) => onRecordChanged(index, updated),
        );
      },
    );
  }
}
