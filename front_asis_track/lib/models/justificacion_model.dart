/// Modelo que representa una justificación de inasistencia.
///
/// Mapea la respuesta del endpoint:
///   GET /api/v1/planilla-service/justificaciones/estudiante/{codigo}
class JustificacionModel {
  final int id;
  final int? eventoId;
  final int? codigoEstudiante;
  final String motivo;
  final String? documentoUrl;
  final String estado;
  final String? observaciones;
  final DateTime? fechaSolicitud;
  final DateTime? fechaRespuesta;

  const JustificacionModel({
    required this.id,
    this.eventoId,
    this.codigoEstudiante,
    required this.motivo,
    this.documentoUrl,
    this.estado = 'PENDIENTE',
    this.observaciones,
    this.fechaSolicitud,
    this.fechaRespuesta,
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Deserialización
  // ──────────────────────────────────────────────────────────────────────────
  factory JustificacionModel.fromJson(Map<String, dynamic> json) {
    return JustificacionModel(
      id: _toInt(json['id']) ?? 0,
      eventoId: _toInt(json['eventoId']),
      codigoEstudiante: _toInt(json['codigoEstudiante']),
      motivo: json['motivo'] as String? ?? '',
      documentoUrl: json['documentoUrl'] as String?,
      estado: json['estado'] as String? ?? 'PENDIENTE',
      observaciones: json['observaciones'] as String?,
      fechaSolicitud: _parseDate(json['fechaSolicitud']),
      fechaRespuesta: _parseDate(json['fechaRespuesta'] ?? json['fechaRevision']),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Serialización
  // ──────────────────────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
        'id': id,
        'eventoId': eventoId,
        'codigoEstudiante': codigoEstudiante,
        'motivo': motivo,
        'documentoUrl': documentoUrl,
        'estado': estado,
        'observaciones': observaciones,
        'fechaSolicitud': fechaSolicitud?.toIso8601String(),
        'fechaRespuesta': fechaRespuesta?.toIso8601String(),
      };

  // ──────────────────────────────────────────────────────────────────────────
  // Alias para compatibilidad con vistas existentes
  // ──────────────────────────────────────────────────────────────────────────
  DateTime? get fechaRevision => fechaRespuesta;
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
