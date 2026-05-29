import 'dart:convert';
import '../config/app_config.dart';
import 'api_client.dart';

/// Servicio para la gestión de justificaciones.
///
/// Conecta con el backend real: /api/v1/planilla-service/justificaciones
class JustificacionService {
  static String get _url => AppConfig.planillaUrl;

  // ══════════════════════════════════════════════════════════════════════════
  // SOLICITAR JUSTIFICACIÓN
  // ══════════════════════════════════════════════════════════════════════════

  /// POST /api/v1/planilla-service/justificaciones/solicitar
  static Future<Map<String, dynamic>> solicitarJustificacion({
    required int eventoId,
    required int codigoEstudiante,
    required String motivo,
    String? documentoUrl,
  }) async {
    final body = <String, dynamic>{
      'eventoId': eventoId,
      'codigoEstudiante': codigoEstudiante,
      'motivo': motivo,
    };
    if (documentoUrl != null && documentoUrl.isNotEmpty) {
      body['documentoUrl'] = documentoUrl;
    }

    final uri = Uri.parse('$_url/api/v1/planilla-service/justificaciones/solicitar');
    final response = await ApiClient.post(uri, body: jsonEncode(body));
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // APROBAR JUSTIFICACIÓN
  // ══════════════════════════════════════════════════════════════════════════

  /// POST /api/v1/planilla-service/justificaciones/{id}/aprobar
  static Future<Map<String, dynamic>> aprobarJustificacion({
    required int id,
    required int codigoDecano,
    String? observaciones,
  }) async {
    final body = <String, dynamic>{
      'codigoDecano': codigoDecano,
    };
    if (observaciones != null && observaciones.isNotEmpty) {
      body['observaciones'] = observaciones;
    }

    final uri = Uri.parse('$_url/api/v1/planilla-service/justificaciones/$id/aprobar');
    final response = await ApiClient.post(uri, body: jsonEncode(body));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // RECHAZAR JUSTIFICACIÓN
  // ══════════════════════════════════════════════════════════════════════════

  /// POST /api/v1/planilla-service/justificaciones/{id}/rechazar
  static Future<Map<String, dynamic>> rechazarJustificacion({
    required int id,
    required int codigoDecano,
    String? observaciones,
  }) async {
    final body = <String, dynamic>{
      'codigoDecano': codigoDecano,
    };
    if (observaciones != null && observaciones.isNotEmpty) {
      body['observaciones'] = observaciones;
    }

    final uri = Uri.parse('$_url/api/v1/planilla-service/justificaciones/$id/rechazar');
    final response = await ApiClient.post(uri, body: jsonEncode(body));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // OBTENER POR ID
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/v1/planilla-service/justificaciones/{id}
  static Future<Map<String, dynamic>> obtenerJustificacion(int id) async {
    final uri = Uri.parse('$_url/api/v1/planilla-service/justificaciones/$id');
    final response = await ApiClient.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // OBTENER POR ESTUDIANTE
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/v1/planilla-service/justificaciones/estudiante/{codigoEstudiante}
  static Future<List<Map<String, dynamic>>> obtenerPorEstudiante(int codigoEstudiante) async {
    final uri = Uri.parse('$_url/api/v1/planilla-service/justificaciones/estudiante/$codigoEstudiante');
    final response = await ApiClient.get(uri);
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => e as Map<String, dynamic>).toList();
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // OBTENER POR EVENTO
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/v1/planilla-service/justificaciones/evento/{eventoId}
  static Future<List<Map<String, dynamic>>> obtenerPorEvento(int eventoId) async {
    final uri = Uri.parse('$_url/api/v1/planilla-service/justificaciones/evento/$eventoId');
    final response = await ApiClient.get(uri);
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => e as Map<String, dynamic>).toList();
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // OBTENER POR ESTADO
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/v1/planilla-service/justificaciones/estado/{estado}
  static Future<List<Map<String, dynamic>>> obtenerPorEstado(String estado) async {
    final uri = Uri.parse('$_url/api/v1/planilla-service/justificaciones/estado/$estado');
    final response = await ApiClient.get(uri);
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => e as Map<String, dynamic>).toList();
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // OBTENER TODAS
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/v1/planilla-service/justificaciones/all
  static Future<List<Map<String, dynamic>>> obtenerTodas() async {
    final uri = Uri.parse('$_url/api/v1/planilla-service/justificaciones/all');
    final response = await ApiClient.get(uri);
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => e as Map<String, dynamic>).toList();
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ELIMINAR
  // ══════════════════════════════════════════════════════════════════════════

  /// DELETE /api/v1/planilla-service/justificaciones/{id}
  static Future<void> eliminar(int id) async {
    final uri = Uri.parse('$_url/api/v1/planilla-service/justificaciones/$id');
    final response = await ApiClient.delete(uri);
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(ApiClient.extractErrorMessage(response));
    }
  }
}
