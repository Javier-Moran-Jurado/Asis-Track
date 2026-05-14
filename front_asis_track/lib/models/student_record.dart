import 'dart:typed_data';

class StudentRecord {
  /// Dynamic key→value map for ALL text fields from the planilla template.
  final Map<String, String> fields;
  final String? signatureSource;
  final int? filaId;
  Uint8List? signatureBytes;

  StudentRecord({
    Map<String, String>? fields,
    // Legacy named params — kept for backward compatibility.
    String cedula = '',
    String nombres = '',
    String apellidos = '',
    String codigo = '',
    String dependencia = '',
    this.signatureBytes,
    this.signatureSource,
    this.filaId,
  }) : fields = fields ??
            <String, String>{
              if (cedula.isNotEmpty) 'cedula': cedula,
              if (nombres.isNotEmpty) 'nombres': nombres,
              if (apellidos.isNotEmpty) 'apellidos': apellidos,
              if (codigo.isNotEmpty) 'codigo': codigo,
              if (dependencia.isNotEmpty) 'dependencia': dependencia,
            };

  // ── Legacy getters for code that still references named fields ──
  String get cedula => fields['cedula'] ?? '';
  String get nombres => fields['nombres'] ?? '';
  String get apellidos => fields['apellidos'] ?? '';
  String get codigo => fields['codigo'] ?? '';
  String get dependencia => fields['dependencia'] ?? '';

  /// Display name: first non-empty text field value, or first two values joined.
  String get nombreCompleto {
    final vals = fields.values.where((v) => v.isNotEmpty).toList();
    if (vals.isEmpty) return '';
    if (vals.length == 1) return vals.first;
    return '${vals[0]} ${vals[1]}'.trim();
  }

  StudentRecord copyWith({
    Map<String, String>? fields,
    String? cedula,
    String? nombres,
    String? apellidos,
    String? codigo,
    String? dependencia,
    Uint8List? signatureBytes,
    String? signatureSource,
    int? filaId,
  }) {
    final newFields = Map<String, String>.from(fields ?? this.fields);
    if (cedula != null) newFields['cedula'] = cedula;
    if (nombres != null) newFields['nombres'] = nombres;
    if (apellidos != null) newFields['apellidos'] = apellidos;
    if (codigo != null) newFields['codigo'] = codigo;
    if (dependencia != null) newFields['dependencia'] = dependencia;
    return StudentRecord(
      fields: newFields,
      signatureBytes: signatureBytes ?? this.signatureBytes,
      signatureSource: signatureSource ?? this.signatureSource,
      filaId: filaId ?? this.filaId,
    );
  }
}
