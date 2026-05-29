import 'dart:convert';
import '../config/app_config.dart';
import 'api_client.dart';

class EventService {
  static String get _baseUrl => AppConfig.planillaUrl;

  static Future<List<dynamic>> listEvents() async {
    final uri = Uri.parse('$_baseUrl/api/v1/planilla-service/eventos');
    final response = await ApiClient.get(uri);
    if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  static Future<Map<String, dynamic>> createEvent({
    required String nombre,
    String? descripcion,
    required String lugarId,
    required String codigoUsuario,
    required String fechaHoraInicio,
    required String fechaHoraFin,
  }) async {
    final body = <String, dynamic>{
      'nombre': nombre,
      'lugarId': int.parse(lugarId),
      'fechaHoraInicio': fechaHoraInicio,
      'fechaHoraFin': fechaHoraFin,
    };
    if (codigoUsuario.isNotEmpty) body['codigoUsuario'] = int.parse(codigoUsuario);
    if (descripcion != null && descripcion.isNotEmpty) body['descripcion'] = descripcion;

    final uri = Uri.parse('$_baseUrl/api/v1/planilla-service/eventos');
    final response = await ApiClient.post(uri, body: jsonEncode(body));
    if (response.statusCode == 201) return jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(ApiClient.extractErrorMessage(response));
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
    final body = <String, dynamic>{
      'nombre': nombre,
      'lugarId': int.parse(lugarId),
      'fechaHoraInicio': fechaHoraInicio,
      'fechaHoraFin': fechaHoraFin,
    };
    if (codigoUsuario.isNotEmpty) body['codigoUsuario'] = int.parse(codigoUsuario);
    if (descripcion != null && descripcion.isNotEmpty) body['descripcion'] = descripcion;

    final uri = Uri.parse('$_baseUrl/api/v1/planilla-service/eventos/$id');
    final response = await ApiClient.put(uri, body: jsonEncode(body));
    if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  static Future<void> deleteEvent(String id) async {
    final uri = Uri.parse('$_baseUrl/api/v1/planilla-service/eventos/$id');
    final response = await ApiClient.delete(uri);
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(ApiClient.extractErrorMessage(response));
    }
  }

  static Future<List<dynamic>> listPlaces() async {
    final uri = Uri.parse('$_baseUrl/api/v1/planilla-service/lugares');
    final response = await ApiClient.get(uri);
    if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  static Future<Map<String, dynamic>> createPlace({
    required String nombre,
    String? coordenadas,
  }) async {
    final body = <String, dynamic>{'nombre': nombre};
    if (coordenadas != null && coordenadas.isNotEmpty) body['coordenadas'] = coordenadas;

    final uri = Uri.parse('$_baseUrl/api/v1/planilla-service/lugares');
    final response = await ApiClient.post(uri, body: jsonEncode(body));
    if (response.statusCode == 201) return jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  static Future<Map<String, dynamic>> updatePlace({
    required String id,
    required String nombre,
    String? coordenadas,
  }) async {
    final body = <String, dynamic>{'nombre': nombre};
    if (coordenadas != null && coordenadas.isNotEmpty) body['coordenadas'] = coordenadas;

    final uri = Uri.parse('$_baseUrl/api/v1/planilla-service/lugares/$id');
    final response = await ApiClient.put(uri, body: jsonEncode(body));
    if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  static Future<void> deletePlace(String id) async {
    final uri = Uri.parse('$_baseUrl/api/v1/planilla-service/lugares/$id');
    final response = await ApiClient.delete(uri);
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(ApiClient.extractErrorMessage(response));
    }
  }
}
