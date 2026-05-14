import 'dart:async' show TimeoutException;
import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

/// Extrae un mensaje legible del response body del backend.
String _extractErrorMessage(http.Response response) {
  try {
    final body = jsonDecode(response.body) as Map<String, dynamic>?;
    if (body == null) return 'Error ${response.statusCode}';

    // Busca campos comunes de mensaje de error
    if (body['mensaje'] != null) return body['mensaje'].toString();
    if (body['message'] != null) return body['message'].toString();
    if (body['error'] != null) return body['error'].toString();

    // Si hay errores de validación (BindingResult), extrae el primero
    if (body['errors'] is List && (body['errors'] as List).isNotEmpty) {
      final first = (body['errors'] as List).first;
      if (first is Map) {
        return first['defaultMessage']?.toString() ??
               first['message']?.toString() ??
               'Error de validacion';
      }
      return first.toString();
    }

    return 'Error ${response.statusCode}: ${response.body}';
  } catch (_) {
    return 'Error ${response.statusCode}: ${response.reasonPhrase ?? 'Desconocido'}';
  }
}

/// Servicio para operaciones CRUD de usuarios (requiere rol admin/administrativo).
class UserService {
  static String get _baseUrl => AppConfig.usuarioUrl;

  static Future<String?> _getToken() async {
    final token = await AuthService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesion activa.');
    }
    return token;
  }

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      };

  /// GET /api/v1/usuario-service/usuarios
  static Future<List<dynamic>> listUsers() async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/v1/usuario-service/usuarios');

    final response = await http
        .get(uri, headers: _headers(token!))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['usuarios'] as List<dynamic>? ?? [];
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// POST /api/v1/usuario-service/usuarios
  static Future<Map<String, dynamic>> createUser({
    required String codigo,
    required String nombreCompleto,
    required String correo,
    required String contrasena,
    required String cedula,
    required String telefono,
    required String rolId,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/v1/usuario-service/usuarios');

    final response = await http
        .post(
          uri,
          headers: _headers(token!),
          body: jsonEncode({
            'codigo': int.parse(codigo),
            'nombreCompleto': nombreCompleto,
            'correo': correo,
            'contrasena': contrasena,
            'cedula': int.parse(cedula),
            'telefono': int.parse(telefono),
            'rol': {'id': int.parse(rolId)},
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// PUT /api/v1/usuario-service/usuarios
  static Future<Map<String, dynamic>> updateUser({
    required String codigo,
    required String nombreCompleto,
    required String correo,
    String? contrasena,
    required String cedula,
    required String telefono,
    required String rolId,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/v1/usuario-service/usuarios');

    final body = <String, dynamic>{
      'codigo': int.parse(codigo),
      'nombreCompleto': nombreCompleto,
      'correo': correo,
      'cedula': int.parse(cedula),
      'telefono': int.parse(telefono),
      'rol': {'id': int.parse(rolId)},
    };
    if (contrasena != null && contrasena.isNotEmpty) {
      body['contrasena'] = contrasena;
    }

    final response = await http
        .put(uri, headers: _headers(token!), body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// DELETE /api/v1/usuario-service/usuarios
  static Future<void> deleteUser(String codigo) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/v1/usuario-service/usuarios');

    final response = await http
        .delete(
          uri,
          headers: _headers(token!),
          body: jsonEncode({'codigo': int.parse(codigo)}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// GET /api/v1/usuario-service/usuarios/{id}
  static Future<Map<String, dynamic>> getUserById(String id) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/v1/usuario-service/usuarios/$id');

    final response = await http
        .get(uri, headers: _headers(token!))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['usuario'] as Map<String, dynamic>;
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }
}
