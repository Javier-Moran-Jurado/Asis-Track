import 'dart:convert';
import '../config/app_config.dart';
import 'api_client.dart';

/// Servicio de reportes y estadísticas.
///
/// Conecta con: /api/v1/planilla-service/reportes
class ReporteService {
  static String get _url => AppConfig.planillaUrl;

  // ══════════════════════════════════════════════════════════════════════════
  // RESUMEN DE JUSTIFICACIONES
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/v1/planilla-service/reportes/justificaciones/resumen
  static Future<Map<String, dynamic>> resumenJustificaciones() async {
    final uri = Uri.parse('$_url/api/v1/planilla-service/reportes/justificaciones/resumen');
    final response = await ApiClient.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ESTADÍSTICAS COMPLETAS DE UN EVENTO
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/v1/planilla-service/reportes/evento/{eventoId}/estadisticas-completas
  static Future<Map<String, dynamic>> estadisticasCompletasEvento(
    int eventoId, {
    int? bins,
  }) async {
    final query = bins != null ? '?bins=$bins' : '';
    final uri = Uri.parse(
        '$_url/api/v1/planilla-service/reportes/evento/$eventoId/estadisticas-completas$query');
    final response = await ApiClient.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ESTADÍSTICAS POR CAMPO
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/v1/planilla-service/reportes/evento/{eventoId}/campo/{nombreCampo}/estadisticas
  static Future<Map<String, dynamic>> estadisticasPorCampo(
    int eventoId,
    String nombreCampo, {
    int? bins,
  }) async {
    final query = bins != null ? '?bins=$bins' : '';
    final uri = Uri.parse(
        '$_url/api/v1/planilla-service/reportes/evento/$eventoId/campo/$nombreCampo/estadisticas$query');
    final response = await ApiClient.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // COMPARATIVA DE CAMPOS
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/v1/planilla-service/reportes/evento/{eventoId}/comparativa
  static Future<Map<String, dynamic>> comparativaCampos(
    int eventoId,
    List<String> campos, {
    int? bins,
  }) async {
    final camposParam = campos.map((c) => 'campos=$c').join('&');
    final binsParam = bins != null ? '&bins=$bins' : '';
    final uri = Uri.parse(
        '$_url/api/v1/planilla-service/reportes/evento/$eventoId/comparativa?$camposParam$binsParam');
    final response = await ApiClient.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }
}
