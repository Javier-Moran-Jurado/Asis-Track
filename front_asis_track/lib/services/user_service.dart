import 'dart:convert';
import '../config/app_config.dart';
import 'api_client.dart';

/// Servicio para operaciones CRUD de usuarios (requiere rol admin/administrativo).
class UserService {
  static String get _baseUrl => AppConfig.usuarioUrl;

  /// GET /api/v1/usuario-service/usuarios
  static Future<List<dynamic>> listUsers() async {
    final uri = Uri.parse('$_baseUrl/api/v1/usuario-service/usuarios');
    final response = await ApiClient.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['usuarios'] as List<dynamic>? ?? [];
    }
    throw Exception(ApiClient.extractErrorMessage(response));
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
    final uri = Uri.parse('$_baseUrl/api/v1/usuario-service/usuarios');
    final response = await ApiClient.post(
      uri,
      body: jsonEncode({
        'codigo': int.parse(codigo),
        'nombreCompleto': nombreCompleto,
        'correo': correo,
        'contrasena': contrasena,
        'cedula': int.parse(cedula),
        'telefono': int.parse(telefono),
        'rol': {'id': int.parse(rolId)},
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(ApiClient.extractErrorMessage(response));
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

    final response = await ApiClient.put(uri, body: jsonEncode(body));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }

  /// DELETE /api/v1/usuario-service/usuarios
  static Future<void> deleteUser(String codigo) async {
    final uri = Uri.parse('$_baseUrl/api/v1/usuario-service/usuarios');
    final response = await ApiClient.delete(
      uri,
      body: jsonEncode({'codigo': int.parse(codigo)}),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(ApiClient.extractErrorMessage(response));
    }
  }

  /// GET /api/v1/usuario-service/usuarios/{id}
  static Future<Map<String, dynamic>> getUserById(String id) async {
    final uri = Uri.parse('$_baseUrl/api/v1/usuario-service/usuarios/$id');
    final response = await ApiClient.get(uri);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['usuario'] as Map<String, dynamic>;
    }
    throw Exception(ApiClient.extractErrorMessage(response));
  }
}
