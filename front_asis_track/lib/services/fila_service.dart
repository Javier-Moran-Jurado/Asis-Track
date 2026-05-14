import 'dart:async';
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

class FilaService {
  static String get _url => AppConfig.planillaUrl;

  static Future<String?> _token() async {
    final t = await AuthService.getAccessToken();
    if (t == null || t.isEmpty) throw Exception('No hay sesion activa.');
    return t;
  }

  static Map<String, String> _h(String t) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $t',
    'ngrok-skip-browser-warning': 'true',
  };

  /// GET /api/v1/planilla-service/filas/planilla/{planillaId}
  static Future<List<Map<String, dynamic>>> obtenerFilas(int planillaId) async {
    final t = await _token();
    final r = await http
        .get(Uri.parse('$_url/api/v1/planilla-service/filas/planilla/$planillaId'), headers: _h(t!))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 200) {
      return (jsonDecode(r.body) as List<dynamic>).cast<Map<String, dynamic>>();
    }
    throw Exception(_msg(r));
  }

  /// POST /api/v1/planilla-service/filas
  /// Crea una fila con sus datos.
  /// payload: { planillaId, codigoUsuario?, indice?, datos: [{campoId, posicion, informacion}] }
  static Future<Map<String, dynamic>> crearFila(Map<String, dynamic> payload) async {
    final t = await _token();
    final r = await http
        .post(Uri.parse('$_url/api/v1/planilla-service/filas'),
            headers: _h(t!), body: jsonEncode(payload))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 201 || r.statusCode == 200) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    throw Exception(_msg(r));
  }

  /// PUT /api/v1/planilla-service/filas/{id}
  static Future<Map<String, dynamic>> actualizarFila(int id, Map<String, dynamic> payload) async {
    final t = await _token();
    final r = await http
        .put(Uri.parse('$_url/api/v1/planilla-service/filas/$id'),
            headers: _h(t!), body: jsonEncode(payload))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 200) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    throw Exception(_msg(r));
  }

  /// DELETE /api/v1/planilla-service/filas/{id}
  static Future<void> eliminarFila(int id) async {
    final t = await _token();
    final r = await http
        .delete(Uri.parse('$_url/api/v1/planilla-service/filas/$id'), headers: _h(t!))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode != 204 && r.statusCode != 200) throw Exception(_msg(r));
  }

  /// POST /api/v1/planilla-service/filas/{filaId}/firma
  static Future<Map<String, dynamic>> subirFirma(int filaId, int campoId, List<int> imageBytes, {String filename = 'firma.png'}) async {
    final t = await _token();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_url/api/v1/planilla-service/filas/$filaId/firma?campoId=$campoId'),
    );
    request.headers['Authorization'] = 'Bearer $t';
    request.files.add(http.MultipartFile.fromBytes(
      'firmaImage',
      imageBytes,
      filename: filename,
    ));
    
    final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_msg(response));
  }
}
