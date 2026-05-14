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

/// Servicio de reportes y estadísticas.
///
/// Conecta con: /api/v1/planilla-service/reportes
class ReporteService {
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
  // RESUMEN DE JUSTIFICACIONES
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/v1/planilla-service/reportes/justificaciones/resumen
  /// Retorna: { "pendientes": int, "aprobadas": int, "rechazadas": int, "total": int }
  static Future<Map<String, dynamic>> resumenJustificaciones() async {
    final t = await _token();
    final r = await http
        .get(
          Uri.parse('$_url/api/v1/planilla-service/reportes/justificaciones/resumen'),
          headers: _h(t!),
        )
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 200) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    throw Exception(_msg(r));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ESTADÍSTICAS COMPLETAS DE UN EVENTO
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/v1/planilla-service/reportes/evento/{eventoId}/estadisticas-completas
  static Future<Map<String, dynamic>> estadisticasCompletasEvento(
    int eventoId, {
    int? bins,
  }) async {
    final t = await _token();
    final query = bins != null ? '?bins=$bins' : '';
    final r = await http
        .get(
          Uri.parse('$_url/api/v1/planilla-service/reportes/evento/$eventoId/estadisticas-completas$query'),
          headers: _h(t!),
        )
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 200) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    throw Exception(_msg(r));
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
    final t = await _token();
    final query = bins != null ? '?bins=$bins' : '';
    final r = await http
        .get(
          Uri.parse('$_url/api/v1/planilla-service/reportes/evento/$eventoId/campo/$nombreCampo/estadisticas$query'),
          headers: _h(t!),
        )
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 200) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    throw Exception(_msg(r));
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
    final t = await _token();
    final camposParam = campos.map((c) => 'campos=$c').join('&');
    final binsParam = bins != null ? '&bins=$bins' : '';
    final r = await http
        .get(
          Uri.parse('$_url/api/v1/planilla-service/reportes/evento/$eventoId/comparativa?$camposParam$binsParam'),
          headers: _h(t!),
        )
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 200) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    throw Exception(_msg(r));
  }
}
