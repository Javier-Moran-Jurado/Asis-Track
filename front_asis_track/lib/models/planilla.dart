class Planilla {
  final int? id;
  final int? eventoId;
  final String? nombreEvento;
  final String? eventoCoordenadas;
  final String? eventoLugarNombre;
  final String? origen;
  final String? urlReferencia;
  final String? qrUrl;
  final DateTime? fechaCreacion;
  final int? totalFilas;
  final int? totalCampos;
  final List<CampoPreviewModel>? campos;
  final List<FilaDigitalizada>? filas;

  const Planilla({
    this.id,
    this.eventoId,
    this.nombreEvento,
    this.eventoCoordenadas,
    this.eventoLugarNombre,
    this.origen,
    this.urlReferencia,
    this.qrUrl,
    this.fechaCreacion,
    this.totalFilas,
    this.totalCampos,
    this.campos,
    this.filas,
  });

  factory Planilla.fromJson(Map<String, dynamic> json) {
    final ev = json['evento'];
    final filasJson = json['filas'] as List<dynamic>?;
    final camposJson = json['campos'] as List<dynamic>?;
    final filas = filasJson != null
      ? filasJson
        .map((f) => FilaDigitalizada.fromJson(f as Map<String, dynamic>))
        .toList()
      : null;
    final campos = camposJson != null
      ? camposJson
        .map((c) => CampoPreviewModel.fromJson(c as Map<String, dynamic>))
        .toList()
      : null;
    return Planilla(
      id: json['id'] as int?,
      eventoId: json['eventoId'] != null
          ? json['eventoId'] as int
          : (ev is Map ? ev['id'] as int? : null),
      nombreEvento: json['nombreEvento'] as String? ?? (ev is Map ? ev['nombre'] as String? : null),
      eventoCoordenadas: json['eventoCoordenadas'] as String?,
      eventoLugarNombre: json['eventoLugarNombre'] as String?,
      origen: json['origen'] is Map
          ? (json['origen'] as Map)['origen'] as String?
          : null,
      urlReferencia: json['urlReferencia'] as String?,
      qrUrl: json['qrUrl'] as String?,
      fechaCreacion: json['fechaCreacion'] != null
          ? DateTime.tryParse(json['fechaCreacion'].toString())
          : null,
      totalFilas: filasJson != null ? filasJson.length : json['totalFilas'] as int?,
      totalCampos: camposJson != null ? camposJson.length : json['totalCampos'] as int?,
      campos: campos,
      filas: filas,
    );
  }
}

class FilaDigitalizada {
  final int? id;
  final int? planillaId;
  final int? codigoUsuario;
  final int? indice;
  final DateTime? fechaRegistro;
  final List<DatoDigitalizado> datos;

  const FilaDigitalizada({
    this.id,
    this.planillaId,
    this.codigoUsuario,
    this.indice,
    this.fechaRegistro,
    this.datos = const [],
  });

  factory FilaDigitalizada.fromJson(Map<String, dynamic> json) => FilaDigitalizada(
    id: (json['id'] as num?)?.toInt(),
    planillaId: (json['planillaId'] as num?)?.toInt(),
    codigoUsuario: (json['codigoUsuario'] as num?)?.toInt(),
    indice: (json['indice'] as num?)?.toInt(),
    fechaRegistro: json['fechaRegistro'] != null
        ? DateTime.tryParse(json['fechaRegistro'].toString())
        : null,
    datos: json['datos'] is List
        ? (json['datos'] as List)
            .map((d) => DatoDigitalizado.fromJson(d as Map<String, dynamic>))
            .toList()
        : const [],
  );
}

class DatoDigitalizado {
  final int? id;
  final int? campoId;
  final int? filaId;
  final int? posicion;
  final String? informacion;

  const DatoDigitalizado({
    this.id,
    this.campoId,
    this.filaId,
    this.posicion,
    this.informacion,
  });

  factory DatoDigitalizado.fromJson(Map<String, dynamic> json) => DatoDigitalizado(
    id: (json['id'] as num?)?.toInt(),
    campoId: (json['campoId'] as num?)?.toInt(),
    filaId: (json['filaId'] as num?)?.toInt(),
    posicion: (json['posicion'] as num?)?.toInt(),
    informacion: json['informacion']?.toString(),
  );
}

class EventoPlanilla {
  final int id;
  final String nombre;
  final String? descripcion;
  final DateTime? fechaCreacion;

  const EventoPlanilla({required this.id, required this.nombre, this.descripcion, this.fechaCreacion});

  factory EventoPlanilla.fromJson(Map<String, dynamic> json) => EventoPlanilla(
    id: json['id'] as int,
    nombre: json['nombre'] as String? ?? '',
    descripcion: json['descripcion'] as String?,
    fechaCreacion: json['fechaCreacion'] != null ? DateTime.tryParse(json['fechaCreacion'].toString()) : null,
  );
}

class FilaPlanilla {
  final String? campoCedulaId;
  final String? campoNombresId;
  final String? campoApellidosId;
  final String cedula;
  final String nombres;
  final String apellidos;

  const FilaPlanilla({this.campoCedulaId, this.campoNombresId, this.campoApellidosId, required this.cedula, required this.nombres, required this.apellidos});
}

class TipoCampoModel {
  final int id;
  final String tipo;

  const TipoCampoModel({required this.id, required this.tipo});

  factory TipoCampoModel.fromJson(Map<String, dynamic> json) => TipoCampoModel(
    id: json['id'] as int,
    tipo: json['tipo'] as String? ?? '',
  );

  String get nombreEspanol {
    switch (tipo) {
      case 'text': return 'Texto';
      case 'numeric': return 'Numérico';
      case 'date': return 'Fecha';
      case 'email': return 'Correo';
      case 'secret': return 'Contraseña';
      case 'checkbox': return 'Casilla';
      case 'multivaluecheckbox': return 'Selección múltiple';
      case 'combo': return 'Lista desplegable';
      case 'radio': return 'Opción única';
      case 'signature_file': return 'Firma digital';
      case 'file': return 'Archivo';
      default: return tipo;
    }
  }

  bool get requiereOpciones => tipo == 'combo' || tipo == 'radio' || tipo == 'multivaluecheckbox';
}

class CampoPreviewModel {
  final int? id;
  final int planillaId;
  final String nombreCampo;
  final bool obligatorio;
  final TipoCampoModel tipoCampo;
  final List<String> opciones;

  const CampoPreviewModel({
    this.id,
    required this.planillaId,
    required this.nombreCampo,
    required this.obligatorio,
    required this.tipoCampo,
    this.opciones = const [],
  });

  factory CampoPreviewModel.fromJson(Map<String, dynamic> json) => CampoPreviewModel(
    id: json['id'] as int?,
    planillaId: json['planillaId'] as int? ?? 0,
    nombreCampo: json['nombreCampo'] as String? ?? '',
    obligatorio: json['obligatorio'] as bool? ?? false,
    tipoCampo: json['tipoCampo'] != null
        ? TipoCampoModel.fromJson(json['tipoCampo'] as Map<String, dynamic>)
        : const TipoCampoModel(id: 0, tipo: 'text'),
    opciones: json['opciones'] is List ? (json['opciones'] as List).cast<String>() : [],
  );

  Map<String, dynamic> toRequest() => {
    'planillaId': planillaId,
    'tipoCampoId': tipoCampo.id,
    'nombreCampo': nombreCampo,
    'obligatorio': obligatorio,
    'opciones': opciones,
  };
}

class EstadisticasEvento {
  final int? eventoId;
  final String? nombreEvento;
  final int totalPlanillas;
  final int totalFilas;
  final List<EstadisticasCampo> campos;

  const EstadisticasEvento({this.eventoId, this.nombreEvento, required this.totalPlanillas, required this.totalFilas, required this.campos});

  factory EstadisticasEvento.fromJson(Map<String, dynamic> json) => EstadisticasEvento(
    eventoId: json['eventoId'] as int?,
    nombreEvento: json['nombreEvento'] as String?,
    totalPlanillas: (json['totalPlanillas'] as num?)?.toInt() ?? 0,
    totalFilas: (json['totalFilas'] as num?)?.toInt() ?? 0,
    campos: (json['campos'] as List<dynamic>?)?.map((c) => EstadisticasCampo.fromJson(c as Map<String, dynamic>)).toList() ?? [],
  );
}

class EstadisticasCampo {
  final String campo;
  final String tipoCampo;
  final Map<String, dynamic>? estadisticas;

  const EstadisticasCampo({required this.campo, required this.tipoCampo, this.estadisticas});

  factory EstadisticasCampo.fromJson(Map<String, dynamic> json) => EstadisticasCampo(
    campo: json['campo'] as String? ?? '',
    tipoCampo: json['tipoCampo'] as String? ?? '',
    estadisticas: json['estadisticas'] as Map<String, dynamic>?,
  );
}
