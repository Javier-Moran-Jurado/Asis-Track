import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
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

class CampoService {
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

  static Future<List<TipoCampoModel>> obtenerTiposCampo() async {
    final t = await _token();
    final r = await http
        .get(Uri.parse('$_url/api/v1/planilla-service/tipos-campo'), headers: _h(t!))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 200) {
      final List<dynamic> data = jsonDecode(r.body) as List<dynamic>;
      return data.map((j) => TipoCampoModel.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception(_msg(r));
  }

  static Future<List<CampoPreviewModel>> obtenerCampos(int planillaId) async {
    final t = await _token();
    final r = await http
        .get(Uri.parse('$_url/api/v1/planilla-service/campos/planilla/$planillaId'), headers: _h(t!))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 200) {
      final List<dynamic> data = jsonDecode(r.body) as List<dynamic>;
      return data.map((j) => CampoPreviewModel.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception(_msg(r));
  }

  static Future<CampoPreviewModel> crearCampo(CampoPreviewModel campo) async {
    final t = await _token();
    final r = await http
        .post(Uri.parse('$_url/api/v1/planilla-service/campos'),
            headers: _h(t!), body: jsonEncode(campo.toRequest()))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 201 || r.statusCode == 200) {
      return CampoPreviewModel.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    }
    throw Exception(_msg(r));
  }

  static Future<CampoPreviewModel> actualizarCampo(int id, CampoPreviewModel campo) async {
    final t = await _token();
    final r = await http
        .put(Uri.parse('$_url/api/v1/planilla-service/campos/$id'),
            headers: _h(t!), body: jsonEncode(campo.toRequest()))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode == 200) {
      return CampoPreviewModel.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    }
    throw Exception(_msg(r));
  }

  static Future<void> eliminarCampo(int id) async {
    final t = await _token();
    final r = await http
        .delete(Uri.parse('$_url/api/v1/planilla-service/campos/$id'), headers: _h(t!))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode != 204 && r.statusCode != 200) throw Exception(_msg(r));
  }
}
