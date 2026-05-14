enum EstadoJustificacion {
  ninguna,
  pendiente,
  aprobada,
  rechazada,
}

class HistorialAsistencia {
  final String id;
  final DateTime fecha;
  final String materia;
  final String tipoEvento;
  final bool asistio;
  final EstadoJustificacion estadoJustificacion;
  final String? motivoJustificacion;
  final String? archivoAdjunto;
  final String docente;
  final String ubicacion;

  const HistorialAsistencia({
    required this.id,
    required this.fecha,
    required this.materia,
    required this.tipoEvento,
    required this.asistio,
    this.estadoJustificacion = EstadoJustificacion.ninguna,
    this.motivoJustificacion,
    this.archivoAdjunto,
    required this.docente,
    required this.ubicacion,
  });
}
