// lib/widgets/record_card.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/planilla_field_def.dart';
import '../models/student_record.dart';
import '../themes/app_theme.dart';

class RecordCard extends StatefulWidget {
  final StudentRecord record;
  final int index;
  final bool selected;
  final bool hasSignatureField;
  final List<PlanillaFieldDef> fieldDefs;
  final VoidCallback onSignatureTap;
  final ValueChanged<StudentRecord> onRecordChanged;

  const RecordCard({
    super.key,
    required this.record,
    required this.index,
    required this.selected,
    required this.hasSignatureField,
    required this.fieldDefs,
    required this.onSignatureTap,
    required this.onRecordChanged,
  });

  @override
  State<RecordCard> createState() => _RecordCardState();
}

class _RecordCardState extends State<RecordCard> {
  String? _editingField;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _startEdit(String field, String currentValue) {
    _controllers[field] = TextEditingController(text: currentValue);
    setState(() => _editingField = field);
  }

  void _finishEditWithValue(String field, String val) {
    final newFields = Map<String, String>.from(widget.record.fields);
    newFields[field] = val;
    final updated = widget.record.copyWith(fields: newFields);
    widget.onRecordChanged(updated);
  }

  void _finishEdit(String field) {
    final ctrl = _controllers[field];
    if (ctrl == null) return;
    final val = ctrl.text.trim();
    if (val.isEmpty) {
      setState(() => _editingField = null);
      return;
    }
    _finishEditWithValue(field, val);
    setState(() => _editingField = null);
  }

  Future<void> _handleTap(PlanillaFieldDef def, String value) async {
    if (def.type == 'date') {
      DateTime initialDate = DateTime.now();
      try {
        final parts = value.split(RegExp(r'[/-\s]'));
        if (parts.length >= 3) {
          final yearStr = parts.firstWhere((p) => p.length == 4, orElse: () => '');
          if (yearStr.isNotEmpty) {
             // Basic fallback parsing if year is found
             final parsed = DateTime.tryParse(value);
             if (parsed != null) initialDate = parsed;
          }
        }
      } catch (_) {}

      final date = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
      );
      if (date != null) {
        final dateStr = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
        _finishEditWithValue(def.key, dateStr);
      }
    } else {
      _startEdit(def.key, value);
    }
  }

  Widget _buildField({
    required PlanillaFieldDef def,
    required String value,
  }) {
    final fieldKey = def.key;
    final label = def.label;
    final editing = _editingField == fieldKey;
    
    TextInputType keyboardType = TextInputType.text;
    if (def.type == 'number' || def.type == 'int') {
      keyboardType = TextInputType.number;
    } else if (def.type == 'email') {
      keyboardType = TextInputType.emailAddress;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: editing
                ? TextFormField(
                    controller: _controllers[fieldKey],
                    textInputAction: TextInputAction.done,
                    keyboardType: keyboardType,
                    autofocus: true,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (_) => _finishEdit(fieldKey),
                    onTapOutside: (_) => _finishEdit(fieldKey),
                  )
                : GestureDetector(
                    onTap: () => _handleTap(def, value),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            value.isEmpty ? '—' : value,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          def.type == 'date' ? Icons.calendar_today_outlined : Icons.edit_outlined,
                          size: 14,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rec = widget.record;
    final inEdit = _editingField != null;

    // Build the list of visible (non-signature) fields from fieldDefs
    final visibleDefs = widget.fieldDefs
        .where((d) => d.type != 'signature_file')
        .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.selected
              ? AppTheme.primaryColor
              : inEdit
                  ? AppTheme.primaryColor
                  : Colors.grey.shade200,
          width: inEdit ? 3 : (widget.selected ? 1.6 : 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${widget.index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  rec.nombreCompleto,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.gray900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Render fields dynamically from fieldDefs
          for (final def in visibleDefs)
            _buildField(
              def: def,
              value: rec.fields[def.key] ?? '',
            ),
          const SizedBox(height: 10),
          if (widget.hasSignatureField)
            GestureDetector(
              onTap: widget.onSignatureTap,
              child: _SignatureSlot(signatureBytes: rec.signatureBytes),
            ),
        ],
      ),
    );
  }
}

class _SignatureSlot extends StatelessWidget {
  final Uint8List? signatureBytes;

  const _SignatureSlot({this.signatureBytes});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: signatureBytes == null
          ? CustomPaint(
              painter: _DashedBorderPainter(color: Colors.grey.shade400, radius: 8),
              child: const Center(
                child: Text(
                  'Sin firma — toca para recortar',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(signatureBytes!, fit: BoxFit.contain),
            ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const dashLength = 6.0;
    const dashGap = 4.0;
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        final segment = metric.extractPath(distance, end);
        canvas.drawPath(segment, paint);
        distance += dashLength + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
