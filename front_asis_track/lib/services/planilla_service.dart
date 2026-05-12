import '../models/planilla.dart';

/// Servicio para comunicación con el microservicio de planillas.
///
/// TODO: Conectar al backend cuando esté listo.
///   Base URL: AppConfig.baseUrl/api/v1/planilla-service
///   Headers: Content-Type + ngrok-skip-browser-warning
///
/// Temporalmente se usan datos mock para validar el diseño de las pantallas.
class PlanillaService {
  // ══════════════════════════════════════════════════════════════════════════
  // PLANILLAS
  // ══════════════════════════════════════════════════════════════════════════

  /// Obtiene todas las planillas del usuario autenticado.
  ///
  /// TODO: Reemplazar mock por llamada real al backend.
  ///   GET /api/v1/planilla-service/planillas
  static Future<List<Planilla>> obtenerPlanillas() async {
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Reemplazar por llamada real al backend
    // final uri = Uri.parse('${AppConfig.baseUrl}/api/v1/planilla-service/planillas');
    // final response = await http.get(uri, headers: _headers);

    return [
      Planilla(
        id: 1,
        nombreEvento: 'Clase de Programación',
        fechaCreacion: DateTime.now(),
        totalFilas: 35,
        origen: 'Digital',
      ),
      Planilla(
        id: 2,
        nombreEvento: 'Taller de Flutter',
        fechaCreacion: DateTime.now().subtract(const Duration(days: 2)),
        totalFilas: 20,
        origen: 'Digital',
      ),
      Planilla(
        id: 3,
        nombreEvento: 'Laboratorio de Redes',
        fechaCreacion: DateTime.now().subtract(const Duration(days: 5)),
        totalFilas: 42,
        origen: 'Físico',
      ),
    ];
  }

  /// Obtiene una planilla por ID.
  ///
  /// TODO: Reemplazar mock por llamada real al backend.
  ///   GET /api/v1/planilla-service/planillas/{id}
  static Future<Planilla> obtenerPlanilla(int id) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: Reemplazar por llamada real al backend
    return Planilla(
      id: id,
      nombreEvento: 'Evento de prueba',
      fechaCreacion: DateTime.now(),
      totalFilas: 10,
      origen: 'Digital',
    );
  }

  /// Crea una nueva planilla.
  ///
  /// TODO: Reemplazar mock por llamada real al backend.
  ///   POST /api/v1/planilla-service/planillas
  static Future<Planilla> crearPlanilla(Map<String, dynamic> payload) async {
    await Future.delayed(const Duration(seconds: 2));

    // TODO: Reemplazar por llamada real al backend
    // final uri = Uri.parse('${AppConfig.baseUrl}/api/v1/planilla-service/planillas');
    // final response = await http.post(uri, headers: _headers, body: jsonEncode(payload));

    return Planilla(
      id: DateTime.now().millisecondsSinceEpoch,
      nombreEvento: 'Evento creado',
      fechaCreacion: DateTime.now(),
      totalFilas: 1,
      origen: 'Digital',
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EVENTOS
  // ══════════════════════════════════════════════════════════════════════════

  /// Obtiene eventos para el selector.
  ///
  /// TODO: Reemplazar mock por llamada real al backend.
  ///   GET /api/v1/planilla-service/eventos
  static Future<List<EventoPlanilla>> obtenerEventos() async {
    await Future.delayed(const Duration(milliseconds: 800));

    // TODO: Reemplazar por llamada real al backend
    // final uri = Uri.parse('${AppConfig.baseUrl}/api/v1/planilla-service/eventos');
    // final response = await http.get(uri, headers: _headers);

    return [
      EventoPlanilla(
        id: 1,
        nombre: 'Clase de Programación',
        descripcion: 'Asistencia diaria',
        fechaCreacion: DateTime.now(),
      ),
      EventoPlanilla(
        id: 2,
        nombre: 'Taller de Flutter',
        descripcion: 'Workshop práctico',
        fechaCreacion: DateTime.now().subtract(const Duration(days: 2)),
      ),
      EventoPlanilla(
        id: 3,
        nombre: 'Laboratorio de Redes',
        descripcion: 'Práctica de configuración',
        fechaCreacion: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FILAS
  // ══════════════════════════════════════════════════════════════════════════

  /// Agrega filas a una planilla.
  ///
  /// TODO: Reemplazar mock por llamada real al backend.
  ///   POST /api/v1/planilla-service/filas/batch
  static Future<bool> agregarFilas({
    required int planillaId,
    required List<FilaPlanilla> filas,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Reemplazar por llamada real al backend
    // final uri = Uri.parse('${AppConfig.baseUrl}/api/v1/planilla-service/filas/batch');
    // final response = await http.post(uri, headers: _headers, body: jsonEncode(payload));

    return true;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ESTADÍSTICAS
  // ══════════════════════════════════════════════════════════════════════════

  /// Obtiene estadísticas completas de un evento.
  ///
  /// TODO: Reemplazar mock por llamada real al backend.
  ///   GET /api/v1/planilla-service/reportes/evento/{eventoId}/estadisticas-completas
  static Future<EstadisticasEvento> obtenerEstadisticas(int eventoId,
      {int bins = 10}) async {
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Reemplazar por llamada real al backend
    // final uri = Uri.parse('${AppConfig.baseUrl}/api/v1/planilla-service/reportes/evento/$eventoId/estadisticas-completas?bins=$bins');
    // final response = await http.get(uri, headers: _headers);

    return EstadisticasEvento.fromJson({
      "totalPlanillas": 2,
      "totalFilas": 55,
      "campos": [
        {
          "campo": "Nombres",
          "tipoCampo": "text",
          "estadisticas": {
            "valorMasComun": "Pedro",
            "valoresUnicos": 5,
            "frecuencias": {
              "Ana": 8,
              "Luis": 4,
              "Pedro": 10,
              "Juan": 5,
              "Maria": 8
            }
          }
        },
        {
          "campo": "Apellidos",
          "tipoCampo": "text",
          "estadisticas": {
            "valorMasComun": "Lopez",
            "valoresUnicos": 5,
            "frecuencias": {
              "Lopez": 10,
              "Martinez": 8,
              "Gonzalez": 6,
              "Garcia": 5,
              "Rodriguez": 6
            }
          }
        }
      ]
    });
  }
}
