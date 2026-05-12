/// Modelo para una planilla.
class Planilla {
  final int? id;
  final int? eventoId;
  final String? nombreEvento;
  final String? origen;
  final String? urlReferencia;
  final DateTime? fechaCreacion;
  final int? totalFilas;
  final int? totalCampos;
  final String? estado;

  const Planilla({
    this.id,
    this.eventoId,
    this.nombreEvento,
    this.origen,
    this.urlReferencia,
    this.fechaCreacion,
    this.totalFilas,
    this.totalCampos,
    this.estado,
  });

  factory Planilla.fromJson(Map<String, dynamic> json) {
    return Planilla(
      id: json['id'] as int?,
      eventoId: json['evento'] != null
          ? (json['evento'] is Map
              ? (json['evento'] as Map)['id'] as int?
              : json['evento'] as int?)
          : null,
      nombreEvento: json['evento'] is Map
          ? (json['evento'] as Map)['nombre'] as String?
          : null,
      origen: json['origen'] is Map
          ? (json['origen'] as Map)['origen'] as String?
          : null,
      urlReferencia: json['urlReferencia'] as String?,
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.tryParse(json['fechaCreacion'].toString())
          : null,
      totalFilas: json['totalFilas'] as int?,
      totalCampos: json['totalCampos'] as int?,
      estado: json['estado'] as String?,
    );
  }
}

/// Modelo para un evento (backup para selector).
class EventoPlanilla {
  final int id;
  final String nombre;
  final String? descripcion;
  final DateTime? fechaCreacion;

  const EventoPlanilla({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.fechaCreacion,
  });

  factory EventoPlanilla.fromJson(Map<String, dynamic> json) {
    return EventoPlanilla(
      id: json['id'] as int,
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.tryParse(json['fechaCreacion'].toString())
          : null,
    );
  }
}

/// DTO para una fila de planilla.
class FilaPlanilla {
  final String cedula;
  final String nombres;
  final String apellidos;

  const FilaPlanilla({
    required this.cedula,
    required this.nombres,
    required this.apellidos,
  });

  Map<String, dynamic> toJson() => {
        'cedula': cedula,
        'nombres': nombres,
        'apellidos': apellidos,
      };
}

// ════════════════════════════════════════════════════════════════════════════
// DTOs de estadísticas (dashboard)
// ════════════════════════════════════════════════════════════════════════════

class EstadisticasEvento {
  final int? eventoId;
  final String? nombreEvento;
  final int totalPlanillas;
  final int totalFilas;
  final List<EstadisticasCampo> campos;

  const EstadisticasEvento({
    this.eventoId,
    this.nombreEvento,
    required this.totalPlanillas,
    required this.totalFilas,
    required this.campos,
  });

  factory EstadisticasEvento.fromJson(Map<String, dynamic> json) {
    return EstadisticasEvento(
      eventoId: json['eventoId'] as int?,
      nombreEvento: json['nombreEvento'] as String?,
      totalPlanillas: (json['totalPlanillas'] as num?)?.toInt() ?? 0,
      totalFilas: (json['totalFilas'] as num?)?.toInt() ?? 0,
      campos: (json['campos'] as List<dynamic>?)
              ?.map((c) =>
                  EstadisticasCampo.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class EstadisticasCampo {
  final String campo;
  final String tipoCampo;
  final Map<String, dynamic>? estadisticas;

  const EstadisticasCampo({
    required this.campo,
    required this.tipoCampo,
    this.estadisticas,
  });

  factory EstadisticasCampo.fromJson(Map<String, dynamic> json) {
    return EstadisticasCampo(
      campo: json['campo'] as String? ?? '',
      tipoCampo: json['tipoCampo'] as String? ?? '',
      estadisticas: json['estadisticas'] as Map<String, dynamic>?,
    );
  }
}
