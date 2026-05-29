import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/app_config.dart';
import '../models/planilla.dart';
import 'api_client.dart';

class PlanillaService {
  static String get _url => AppConfig.planillaUrl;

  /// GET /api/v1/planilla-service/planillas
  static Future<List<Planilla>> obtenerPlanillas() async {
    final uri = Uri.parse('$_url/api/v1/planilla-service/planillas');
    final response = await ApiClient.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((j) => Planilla.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  /// GET /api/v1/planilla-service/planillas/publicas (sin autenticación)
  static Future<List<Planilla>> obtenerPlanillasPublicas() async {
    final uri = Uri.parse('$_url/api/v1/planilla-service/planillas/publicas');
    final response = await ApiClient.get(uri, requiresAuth: false);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((j) => Planilla.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  /// GET /api/v1/planilla-service/planillas/{id}
  static Future<Planilla> obtenerPlanilla(int id) async {
    final uri = Uri.parse('$_url/api/v1/planilla-service/planillas/$id');
    final response = await ApiClient.get(uri, requiresAuth: false);
    if (response.statusCode == 200) {
      return Planilla.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  /// POST /api/v1/planilla-service/planillas
  static Future<Planilla> crearPlanilla(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$_url/api/v1/planilla-service/planillas');
    final response = await ApiClient.post(
      uri,
      body: jsonEncode(payload),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return Planilla.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  /// GET /api/v1/planilla-service/eventos
  static Future<List<EventoPlanilla>> obtenerEventos() async {
    final uri = Uri.parse('$_url/api/v1/planilla-service/eventos');
    final response = await ApiClient.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((j) => EventoPlanilla.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  /// POST /api/v1/planilla-service/filas/batch
  static Future<bool> agregarFilas({
    required int planillaId,
    required List<FilaPlanilla> filas,
  }) async {
    final body = filas.map((f) => {
      'planillaId': planillaId,
      'datos': [
        {'campoId': f.campoCedulaId, 'posicion': 0, 'informacion': f.cedula},
        {'campoId': f.campoNombresId, 'posicion': 0, 'informacion': f.nombres},
        {'campoId': f.campoApellidosId, 'posicion': 0, 'informacion': f.apellidos},
      ],
    }).toList();

    final uri = Uri.parse('$_url/api/v1/planilla-service/filas/batch');
    final response = await ApiClient.post(
      uri,
      body: jsonEncode(body),
    );
    if (response.statusCode == 201 || response.statusCode == 200) return true;
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  /// PUT /api/v1/planilla-service/planillas/{id}
  static Future<Planilla> actualizarPlanilla(int id, Map<String, dynamic> payload) async {
    final uri = Uri.parse('$_url/api/v1/planilla-service/planillas/$id');
    final response = await ApiClient.put(
      uri,
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200) {
      return Planilla.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  /// DELETE /api/v1/planilla-service/planillas/{id}
  static Future<void> eliminarPlanilla(int id) async {
    final uri = Uri.parse('$_url/api/v1/planilla-service/planillas/$id');
    final response = await ApiClient.delete(uri);
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(ApiClient.extractErrorMessage(response));
    }
  }

  /// GET /api/v1/planilla-service/reportes/evento/{eventoId}/estadisticas-completas
  static Future<EstadisticasEvento> obtenerEstadisticas(int eventoId, {int bins = 10}) async {
    final uri = Uri.parse(
        '$_url/api/v1/planilla-service/reportes/evento/$eventoId/estadisticas-completas?bins=$bins');
    final response = await ApiClient.get(uri);
    if (response.statusCode == 200) {
      return EstadisticasEvento.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  /// POST /api/v1/planilla-service/planillas/digitalizar
  static Future<Planilla> digitalizarPlanilla({
    required int planillaId,
    required List<int> fileBytes,
    required String filename,
    required String estructuraJson,
    required String contentType,
  }) async {
    final request = await ApiClient.multipartRequest(
      'POST',
      Uri.parse('$_url/api/v1/planilla-service/planillas/digitalizar'),
    );
    request.fields['planillaId'] = planillaId.toString();
    request.fields['estructuraJson'] = estructuraJson;
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: filename,
      contentType: MediaType.parse(contentType),
    ));

    final streamedResponse = await request.send().timeout(const Duration(seconds: 600));
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Planilla.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  /// POST /api/v1/planilla-service/planillas/generar-propuesta
  static Future<Planilla> generarPropuestaIA({
    required String descripcion,
    int? lugarId,
    int? eventoId,
  }) async {
    final request = await ApiClient.multipartRequest(
      'POST',
      Uri.parse('$_url/api/v1/planilla-service/planillas/generar-propuesta'),
    );
    request.fields['descripcion'] = descripcion;
    if (lugarId != null) request.fields['lugarId'] = lugarId.toString();
    if (eventoId != null) request.fields['eventoId'] = eventoId.toString();

    final streamedResponse = await request.send().timeout(const Duration(seconds: 600));
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Planilla.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  /// POST /api/v1/planilla-service/planillas/{planillaId}/proponer-estructura
  static Future<List<CampoPreviewModel>> proponerEstructura({
    required int planillaId,
    required List<int> fileBytes,
    required String filename,
    required String contentType,
  }) async {
    final request = await ApiClient.multipartRequest(
      'POST',
      Uri.parse('$_url/api/v1/planilla-service/planillas/$planillaId/proponer-estructura'),
    );
    request.files.add(http.MultipartFile.fromBytes(
      'imagen',
      fileBytes,
      filename: filename,
      contentType: MediaType.parse(contentType),
    ));

    final streamedResponse = await request.send().timeout(const Duration(seconds: 600));
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((j) => CampoPreviewModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }
}
