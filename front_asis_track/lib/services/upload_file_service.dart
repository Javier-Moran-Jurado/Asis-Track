import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'api_client.dart';

/// Servicio para subir archivos al backend y obtener una URL pública.
///
/// Conecta con: POST /api/v1/planilla-service/upload
class UploadFileService {
  static String get _url => AppConfig.planillaUrl;

  /// Sube un archivo (bytes + nombre) al storage del backend.
  /// Retorna la URL pública del archivo subido.
  static Future<String> uploadFile({
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) async {
    final uri = Uri.parse('$_url/api/v1/planilla-service/upload');
    final request = await ApiClient.multipartRequest('POST', uri);

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
    ));

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final url = data['url'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('La respuesta del servidor no contiene URL.');
      }
      return url;
    }

    throw Exception(ApiClient.extractErrorMessage(response));
  }
}
