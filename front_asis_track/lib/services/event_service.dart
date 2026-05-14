import 'dart:async' show TimeoutException;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

String _extractMessage(http.Response response) {
  try {
    final body = jsonDecode(response.body) as Map<String, dynamic>?;
    if (body == null) return 'Error ${response.statusCode}';
    if (body['message'] != null) return body['message'].toString();
    if (body['mensaje'] != null) return body['mensaje'].toString();
    if (body['error'] != null) return body['error'].toString();
    return 'Error ${response.statusCode}';
  } catch (_) {
    return 'Error ${response.statusCode}';
  }
}

class EventService {
  static String get _baseUrl => AppConfig.planillaUrl;

  static Future<String?> _token() async {
    final t = await AuthService.getAccessToken();
    if (t == null || t.isEmpty) throw Exception('No hay sesion activa.');
    return t;
  }

  static Map<String, String> _headers(String t) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $t',
    'ngrok-skip-browser-warning': 'true',
  };

  static Future<List<dynamic>> listEvents() async {
    final t = await _token();
    final r = await http
        .get(Uri.parse('$_baseUrl/api/v1/planilla-service/eventos'), headers: _headers(t!))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 200) return jsonDecode(r.body) as List<dynamic>;
    throw Exception(_extractMessage(r));
  }

  static Future<Map<String, dynamic>> createEvent({
    required String nombre,
    String? descripcion,
    required String lugarId,
    required String codigoUsuario,
    required String fechaHoraInicio,
    required String fechaHoraFin,
  }) async {
    final t = await _token();
    final body = <String, dynamic>{
      'nombre': nombre,
      'lugarId': int.parse(lugarId),
      'fechaHoraInicio': fechaHoraInicio,
      'fechaHoraFin': fechaHoraFin,
    };
    if (codigoUsuario.isNotEmpty) body['codigoUsuario'] = int.parse(codigoUsuario);
    if (descripcion != null && descripcion.isNotEmpty) body['descripcion'] = descripcion;

    final r = await http
        .post(Uri.parse('$_baseUrl/api/v1/planilla-service/eventos'),
            headers: _headers(t!), body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 201) return jsonDecode(r.body) as Map<String, dynamic>;
    throw Exception(_extractMessage(r));
  }

  static Future<Map<String, dynamic>> updateEvent({
    required String id,
    required String nombre,
    String? descripcion,
    required String lugarId,
    required String codigoUsuario,
    required String fechaHoraInicio,
    required String fechaHoraFin,
  }) async {
    final t = await _token();
    final body = <String, dynamic>{
      'nombre': nombre,
      'lugarId': int.parse(lugarId),
      'fechaHoraInicio': fechaHoraInicio,
      'fechaHoraFin': fechaHoraFin,
    };
    if (codigoUsuario.isNotEmpty) body['codigoUsuario'] = int.parse(codigoUsuario);
    if (descripcion != null && descripcion.isNotEmpty) body['descripcion'] = descripcion;

    final r = await http
        .put(Uri.parse('$_baseUrl/api/v1/planilla-service/eventos/$id'),
            headers: _headers(t!), body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    throw Exception(_extractMessage(r));
  }

  static Future<void> deleteEvent(String id) async {
    final t = await _token();
    final r = await http
        .delete(Uri.parse('$_baseUrl/api/v1/planilla-service/eventos/$id'), headers: _headers(t!))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode != 204 && r.statusCode != 200) throw Exception(_extractMessage(r));
  }

  static Future<List<dynamic>> listPlaces() async {
    final t = await _token();
    final r = await http
        .get(Uri.parse('$_baseUrl/api/v1/planilla-service/lugares'), headers: _headers(t!))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 200) return jsonDecode(r.body) as List<dynamic>;
    throw Exception(_extractMessage(r));
  }

  static Future<Map<String, dynamic>> createPlace({
    required String nombre,
    String? coordenadas,
  }) async {
    final t = await _token();
    final body = <String, dynamic>{'nombre': nombre};
    if (coordenadas != null && coordenadas.isNotEmpty) body['coordenadas'] = coordenadas;
    final r = await http
        .post(Uri.parse('$_baseUrl/api/v1/planilla-service/lugares'), headers: _headers(t!), body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 201) return jsonDecode(r.body) as Map<String, dynamic>;
    throw Exception(_extractMessage(r));
  }

  static Future<Map<String, dynamic>> updatePlace({
    required String id,
    required String nombre,
    String? coordenadas,
  }) async {
    final t = await _token();
    final body = <String, dynamic>{'nombre': nombre};
    if (coordenadas != null && coordenadas.isNotEmpty) body['coordenadas'] = coordenadas;
    final r = await http
        .put(Uri.parse('$_baseUrl/api/v1/planilla-service/lugares/$id'), headers: _headers(t!), body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    throw Exception(_extractMessage(r));
  }

  static Future<void> deletePlace(String id) async {
    final t = await _token();
    final r = await http
        .delete(Uri.parse('$_baseUrl/api/v1/planilla-service/lugares/$id'), headers: _headers(t!))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode != 204 && r.statusCode != 200) throw Exception(_extractMessage(r));
  }
}
