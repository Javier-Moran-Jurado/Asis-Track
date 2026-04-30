/// Modelo que representa los datos embebidos en el QR generado por el docente.
/// El QR contiene un token firmado; el backend lo decodifica y devuelve este objeto.
class EventoQr {
  final String tokenQr;
  final String materia;
  final String actividad;
  final String fecha;
  final String hora;
  final String lugar;

  const EventoQr({
    required this.tokenQr,
    required this.materia,
    required this.actividad,
    required this.fecha,
    required this.hora,
    required this.lugar,
  });

  factory EventoQr.fromJson(Map<String, dynamic> json) {
    return EventoQr(
      tokenQr: json['tokenQr'] as String? ?? '',
      materia: json['materia'] as String? ?? '',
      actividad: json['actividad'] as String? ?? '',
      fecha: json['fecha'] as String? ?? '',
      hora: json['hora'] as String? ?? '',
      lugar: json['lugar'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'tokenQr': tokenQr,
        'materia': materia,
        'actividad': actividad,
        'fecha': fecha,
        'hora': hora,
        'lugar': lugar,
      };
}
