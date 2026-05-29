import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'api_client.dart';

class FilaService {
  static String get _url => AppConfig.planillaUrl;

  /// GET /api/v1/planilla-service/filas/planilla/{planillaId}
  static Future<List<Map<String, dynamic>>> obtenerFilas(int planillaId) async {
    final uri = Uri.parse('$_url/api/v1/planilla-service/filas/planilla/$planillaId');
    final response = await ApiClient.get(uri, requiresAuth: false);
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>).cast<Map<String, dynamic>>();
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  /// POST /api/v1/planilla-service/filas
  static Future<Map<String, dynamic>> crearFila(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$_url/api/v1/planilla-service/filas');
    final response = await ApiClient.post(
      uri,
      body: jsonEncode(payload),
      requiresAuth: false,
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  /// PUT /api/v1/planilla-service/filas/{id}
  static Future<Map<String, dynamic>> actualizarFila(int id, Map<String, dynamic> payload) async {
    final uri = Uri.parse('$_url/api/v1/planilla-service/filas/$id');
    final response = await ApiClient.put(
      uri,
      body: jsonEncode(payload),
      requiresAuth: false,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  /// DELETE /api/v1/planilla-service/filas/{id}
  static Future<void> eliminarFila(int id) async {
    final uri = Uri.parse('$_url/api/v1/planilla-service/filas/$id');
    final response = await ApiClient.delete(uri, requiresAuth: false);
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(ApiClient.extractErrorMessage(response));
    }
  }

  /// POST /api/v1/planilla-service/filas/{filaId}/firma
  static Future<Map<String, dynamic>> subirFirma(
    int filaId,
    int campoId,
    List<int> imageBytes, {
    String filename = 'firma.png',
  }) async {
    final request = await ApiClient.multipartRequest(
      'POST',
      Uri.parse('$_url/api/v1/planilla-service/filas/$filaId/firma?campoId=$campoId'),
    );
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
    throw Exception(ApiClient.extractErrorMessage(response));
  }
}
