import 'dart:convert';
import '../config/app_config.dart';
import '../models/planilla.dart';
import 'api_client.dart';

class CampoService {
  static String get _url => AppConfig.planillaUrl;

  static Future<List<TipoCampoModel>> obtenerTiposCampo() async {
    final uri = Uri.parse('$_url/api/v1/planilla-service/tipos-campo');
    final response = await ApiClient.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((j) => TipoCampoModel.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  static Future<List<CampoPreviewModel>> obtenerCampos(int planillaId) async {
    final uri = Uri.parse('$_url/api/v1/planilla-service/campos/planilla/$planillaId');
    final response = await ApiClient.get(uri, requiresAuth: false);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((j) => CampoPreviewModel.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  static Future<CampoPreviewModel> crearCampo(CampoPreviewModel campo) async {
    final uri = Uri.parse('$_url/api/v1/planilla-service/campos');
    final response = await ApiClient.post(
      uri,
      body: jsonEncode(campo.toRequest()),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return CampoPreviewModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  static Future<CampoPreviewModel> actualizarCampo(int id, CampoPreviewModel campo) async {
    final uri = Uri.parse('$_url/api/v1/planilla-service/campos/$id');
    final response = await ApiClient.put(
      uri,
      body: jsonEncode(campo.toRequest()),
    );
    if (response.statusCode == 200) {
      return CampoPreviewModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  static Future<void> eliminarCampo(int id) async {
    final uri = Uri.parse('$_url/api/v1/planilla-service/campos/$id');
    final response = await ApiClient.delete(uri);
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(ApiClient.extractErrorMessage(response));
    }
  }
}
