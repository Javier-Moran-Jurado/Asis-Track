import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/app_config.dart';
import '../models/planilla.dart';
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

class PlanillaService {
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

  /// GET /api/v1/planilla-service/planillas
  static Future<List<Planilla>> obtenerPlanillas() async {
    final t = await _token();
    final r = await http
        .get(Uri.parse('$_url/api/v1/planilla-service/planillas'), headers: _h(t!))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 200) {
      final List<dynamic> data = jsonDecode(r.body) as List<dynamic>;
      return data.map((j) => Planilla.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception(_msg(r));
  }

  /// GET /api/v1/planilla-service/planillas/{id}
  static Future<Planilla> obtenerPlanilla(int id) async {
    final t = await _token();
    final r = await http
        .get(Uri.parse('$_url/api/v1/planilla-service/planillas/$id'), headers: _h(t!))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 200) {
      return Planilla.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    }
    throw Exception(_msg(r));
  }

  /// POST /api/v1/planilla-service/planillas
  static Future<Planilla> crearPlanilla(Map<String, dynamic> payload) async {
    final t = await _token();
    final r = await http
        .post(Uri.parse('$_url/api/v1/planilla-service/planillas'),
            headers: _h(t!), body: jsonEncode(payload))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 201 || r.statusCode == 200) {
      return Planilla.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    }
    throw Exception(_msg(r));
  }

  /// GET /api/v1/planilla-service/eventos
  static Future<List<EventoPlanilla>> obtenerEventos() async {
    final t = await _token();
    final r = await http
        .get(Uri.parse('$_url/api/v1/planilla-service/eventos'), headers: _h(t!))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 200) {
      final List<dynamic> data = jsonDecode(r.body) as List<dynamic>;
      return data.map((j) => EventoPlanilla.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception(_msg(r));
  }

  /// POST /api/v1/planilla-service/filas/batch
  static Future<bool> agregarFilas({
    required int planillaId,
    required List<FilaPlanilla> filas,
  }) async {
    final t = await _token();
    final body = filas.map((f) => {
      'planillaId': planillaId,
      'datos': [
        {'campoId': f.campoCedulaId, 'posicion': 0, 'informacion': f.cedula},
        {'campoId': f.campoNombresId, 'posicion': 0, 'informacion': f.nombres},
        {'campoId': f.campoApellidosId, 'posicion': 0, 'informacion': f.apellidos},
      ],
    }).toList();
    final r = await http
        .post(Uri.parse('$_url/api/v1/planilla-service/filas/batch'),
            headers: _h(t!), body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 201 || r.statusCode == 200) return true;
    throw Exception(_msg(r));
  }

  /// PUT /api/v1/planilla-service/planillas/{id}
  static Future<Planilla> actualizarPlanilla(int id, Map<String, dynamic> payload) async {
    final t = await _token();
    final r = await http
        .put(Uri.parse('$_url/api/v1/planilla-service/planillas/$id'),
            headers: _h(t!), body: jsonEncode(payload))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 200) {
      return Planilla.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    }
    throw Exception(_msg(r));
  }

  /// DELETE /api/v1/planilla-service/planillas/{id}
  static Future<void> eliminarPlanilla(int id) async {
    final t = await _token();
    final r = await http
        .delete(Uri.parse('$_url/api/v1/planilla-service/planillas/$id'), headers: _h(t!))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode != 204 && r.statusCode != 200) throw Exception(_msg(r));
  }

  /// GET /api/v1/planilla-service/reportes/evento/{eventoId}/estadisticas-completas
  static Future<EstadisticasEvento> obtenerEstadisticas(int eventoId, {int bins = 10}) async {
    final t = await _token();
    final r = await http
        .get(Uri.parse('$_url/api/v1/planilla-service/reportes/evento/$eventoId/estadisticas-completas?bins=$bins'),
            headers: _h(t!))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 200) {
      return EstadisticasEvento.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    }
    throw Exception(_msg(r));
  }

  /// POST /api/v1/planilla-service/planillas/digitalizar
  static Future<Planilla> digitalizarPlanilla({
    required int planillaId,
    required List<int> fileBytes,
    required String filename,
    required String estructuraJson,
    required String contentType,
  }) async {
    final t = await _token();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_url/api/v1/planilla-service/planillas/digitalizar'),
    );
    request.headers['Authorization'] = 'Bearer $t';
    request.headers['ngrok-skip-browser-warning'] = 'true';
    request.fields['planillaId'] = planillaId.toString();
    request.fields['estructuraJson'] = estructuraJson;
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: filename,
      contentType: MediaType.parse(contentType),
    ));

    final streamedResponse = await request.send().timeout(const Duration(seconds: 120));
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Planilla.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(_msg(response));
  }

  /// POST /api/v1/planilla-service/planillas/generar-propuesta
  /// Sends a text description to the AI and receives a fully-generated planilla
  /// (with campos already saved) from the backend.
  static Future<Planilla> generarPropuestaIA({
    required String descripcion,
    int? lugarId,
    int? eventoId,
  }) async {
    final t = await _token();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_url/api/v1/planilla-service/planillas/generar-propuesta'),
    );
    request.headers['Authorization'] = 'Bearer $t';
    request.headers['ngrok-skip-browser-warning'] = 'true';
    request.fields['descripcion'] = descripcion;
    if (lugarId != null) request.fields['lugarId'] = lugarId.toString();
    if (eventoId != null) request.fields['eventoId'] = eventoId.toString();

    final streamedResponse = await request.send().timeout(const Duration(seconds: 120));
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Planilla.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(_msg(response));
  }

  /// POST /api/v1/planilla-service/planillas/{planillaId}/proponer-estructura
  static Future<List<CampoPreviewModel>> proponerEstructura({
    required int planillaId,
    required List<int> fileBytes,
    required String filename,
    required String contentType,
  }) async {
    final t = await _token();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_url/api/v1/planilla-service/planillas/$planillaId/proponer-estructura'),
    );
    request.headers['Authorization'] = 'Bearer $t';
    request.headers['ngrok-skip-browser-warning'] = 'true';
    request.files.add(http.MultipartFile.fromBytes(
      'imagen',
      fileBytes,
      filename: filename,
      contentType: MediaType.parse(contentType),
    ));

    final streamedResponse = await request.send().timeout(const Duration(seconds: 120));
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((j) => CampoPreviewModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw Exception(_msg(response));
  }
}
