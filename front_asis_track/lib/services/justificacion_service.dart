import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

String _msg(http.Response r) {
  try {
    final b = jsonDecode(r.body) as Map<String, dynamic>?;
    if (b == null) return 'Error ${r.statusCode}';
    if (b['mensaje'] != null) return b['mensaje'].toString();
    if (b['message'] != null) return b['message'].toString();
    if (b['error'] != null) return b['error'].toString();
    return 'Error ${r.statusCode}';
  } catch (_) {
    return 'Error ${r.statusCode}';
  }
}

/// Servicio para la gestión de justificaciones.
///
/// Conecta con el backend real: /api/v1/planilla-service/justificaciones
class JustificacionService {
  static String get _url => AppConfig.planillaUrl;

  static Future<String?> _token() async {
    final t = await AuthService.getAccessToken();
    if (t == null || t.isEmpty) throw Exception('No hay sesión activa.');
    return t;
  }

  static Map<String, String> _h(String t) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $t',
    'ngrok-skip-browser-warning': 'true',
  };

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
    final t = await _token();
    final body = <String, dynamic>{
      'eventoId': eventoId,
      'codigoEstudiante': codigoEstudiante,
      'motivo': motivo,
    };
    if (documentoUrl != null && documentoUrl.isNotEmpty) {
      body['documentoUrl'] = documentoUrl;
    }
    final r = await http
        .post(
          Uri.parse('$_url/api/v1/planilla-service/justificaciones/solicitar'),
          headers: _h(t!),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 201 || r.statusCode == 200) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    throw Exception(_msg(r));
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
    final t = await _token();
    final body = <String, dynamic>{
      'codigoDecano': codigoDecano,
    };
    if (observaciones != null && observaciones.isNotEmpty) {
      body['observaciones'] = observaciones;
    }
    final r = await http
        .post(
          Uri.parse('$_url/api/v1/planilla-service/justificaciones/$id/aprobar'),
          headers: _h(t!),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 200) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    throw Exception(_msg(r));
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
    final t = await _token();
    final body = <String, dynamic>{
      'codigoDecano': codigoDecano,
    };
    if (observaciones != null && observaciones.isNotEmpty) {
      body['observaciones'] = observaciones;
    }
    final r = await http
        .post(
          Uri.parse('$_url/api/v1/planilla-service/justificaciones/$id/rechazar'),
          headers: _h(t!),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 200) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    throw Exception(_msg(r));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // OBTENER POR ID
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/v1/planilla-service/justificaciones/{id}
  static Future<Map<String, dynamic>> obtenerJustificacion(int id) async {
    final t = await _token();
    final r = await http
        .get(
          Uri.parse('$_url/api/v1/planilla-service/justificaciones/$id'),
          headers: _h(t!),
        )
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 200) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    throw Exception(_msg(r));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // OBTENER POR ESTUDIANTE
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/v1/planilla-service/justificaciones/estudiante/{codigoEstudiante}
  static Future<List<Map<String, dynamic>>> obtenerPorEstudiante(int codigoEstudiante) async {
    final t = await _token();
    final r = await http
        .get(
          Uri.parse('$_url/api/v1/planilla-service/justificaciones/estudiante/$codigoEstudiante'),
          headers: _h(t!),
        )
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 200) {
      final list = jsonDecode(r.body) as List<dynamic>;
      return list.map((e) => e as Map<String, dynamic>).toList();
    }
    throw Exception(_msg(r));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // OBTENER POR EVENTO
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/v1/planilla-service/justificaciones/evento/{eventoId}
  static Future<List<Map<String, dynamic>>> obtenerPorEvento(int eventoId) async {
    final t = await _token();
    final r = await http
        .get(
          Uri.parse('$_url/api/v1/planilla-service/justificaciones/evento/$eventoId'),
          headers: _h(t!),
        )
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 200) {
      final list = jsonDecode(r.body) as List<dynamic>;
      return list.map((e) => e as Map<String, dynamic>).toList();
    }
    throw Exception(_msg(r));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // OBTENER POR ESTADO
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/v1/planilla-service/justificaciones/estado/{estado}
  static Future<List<Map<String, dynamic>>> obtenerPorEstado(String estado) async {
    final t = await _token();
    final r = await http
        .get(
          Uri.parse('$_url/api/v1/planilla-service/justificaciones/estado/$estado'),
          headers: _h(t!),
        )
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 200) {
      final list = jsonDecode(r.body) as List<dynamic>;
      return list.map((e) => e as Map<String, dynamic>).toList();
    }
    throw Exception(_msg(r));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // OBTENER TODAS
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/v1/planilla-service/justificaciones/all
  static Future<List<Map<String, dynamic>>> obtenerTodas() async {
    final t = await _token();
    final r = await http
        .get(
          Uri.parse('$_url/api/v1/planilla-service/justificaciones/all'),
          headers: _h(t!),
        )
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 200) {
      final list = jsonDecode(r.body) as List<dynamic>;
      return list.map((e) => e as Map<String, dynamic>).toList();
    }
    throw Exception(_msg(r));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ELIMINAR
  // ══════════════════════════════════════════════════════════════════════════

  /// DELETE /api/v1/planilla-service/justificaciones/{id}
  static Future<void> eliminar(int id) async {
    final t = await _token();
    final r = await http
        .delete(
          Uri.parse('$_url/api/v1/planilla-service/justificaciones/$id'),
          headers: _h(t!),
        )
        .timeout(const Duration(seconds: 30));
    if (r.statusCode != 204 && r.statusCode != 200) throw Exception(_msg(r));
  }
}
