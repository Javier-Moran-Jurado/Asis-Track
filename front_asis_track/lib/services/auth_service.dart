import 'dart:async' show TimeoutException;
import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';

/// Servicio de autenticación.
///
/// En web, usa SharedPreferences como fallback para tokens debido a
/// limitaciones de flutter_secure_storage_web con el Web Crypto API.
class AuthService {
  static String get _authUrl => AppConfig.authUrl;
  static String get _usuarioUrl => AppConfig.usuarioUrl;

  // ── Keys ──
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyNombreCompleto = 'user_nombre_completo';
  static const String _keyCorreo = 'user_correo';
  static const String _keyCodigo = 'user_codigo';
  static const String _keyRol = 'user_rol';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // TOKENS — web fallback con SharedPreferences
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAccessToken, accessToken);
      await prefs.setString(_keyRefreshToken, refreshToken);
      return;
    }
    await Future.wait([
      _secureStorage.write(key: _keyAccessToken, value: accessToken),
      _secureStorage.write(key: _keyRefreshToken, value: refreshToken),
    ]);
  }

  static Future<String?> getAccessToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyAccessToken);
    }
    return _secureStorage.read(key: _keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRefreshToken);
    }
    return _secureStorage.read(key: _keyRefreshToken);
  }

  static Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // USER DATA
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> saveUserData(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_keyCodigo, user.codigo),
      prefs.setString(_keyNombreCompleto, user.nombreCompleto),
      prefs.setString(_keyCorreo, user.correo),
      prefs.setString(_keyRol, user.rol),
    ]);
  }

  static Future<UserModel?> getUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final codigo = prefs.getString(_keyCodigo);
    if (codigo == null || codigo.isEmpty) return null;

    return UserModel(
      codigo: codigo,
      nombreCompleto: prefs.getString(_keyNombreCompleto) ?? '',
      correo: prefs.getString(_keyCorreo) ?? '',
      rol: prefs.getString(_keyRol) ?? '',
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOGOUT
  // ══════════════════════════════════════════════════════════════════════════

  static Future<void> clearAllStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      _secureStorage.delete(key: _keyAccessToken),
      _secureStorage.delete(key: _keyRefreshToken),
      prefs.remove(_keyAccessToken),
      prefs.remove(_keyRefreshToken),
      prefs.remove(_keyCodigo),
      prefs.remove(_keyNombreCompleto),
      prefs.remove(_keyCorreo),
      prefs.remove(_keyRol),
    ]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // API CALLS
  // ══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, String>> login(
    String codigo,
    String contrasena,
  ) async {
    final uri = Uri.parse('$_authUrl/api/v1/auth/login');

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode({
              'codigo': int.parse(codigo),
              'contrasena': contrasena,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'access_token': data['access_token'] as String,
          'refresh_token': data['refresh_token'] as String,
        };
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final body = jsonDecode(response.body) as Map<String, dynamic>?;
        final msg = body?['message']?.toString() ?? 'Código o contraseña incorrectos.';
        throw Exception(msg);
      } else {
        throw Exception('Error al iniciar sesión (${response.statusCode}).');
      }
    } on TimeoutException {
      throw Exception(
          'Sin respuesta del servidor. Verifica tu conexión e inténtalo de nuevo.');
    } on SocketException {
      throw Exception(
          'No se puede conectar al servidor. Verifica que estés en la red correcta y que el servidor esté activo.');
    } catch (e) {
      throw Exception(
          'Error de conexión inesperado. Verifica tu red e inténtalo de nuevo.');
    }
  }

  static Future<UserModel> getUserProfile(
    String codigo,
    String accessToken,
  ) async {
    final uri = Uri.parse('$_usuarioUrl/api/v1/usuario-service/usuarios/$codigo');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return UserModel.fromJson(data['usuario'] as Map<String, dynamic>);
      } else {
        throw Exception(
            'Error al obtener el perfil del usuario (${response.statusCode}).');
      }
    } on TimeoutException {
      throw Exception(
          'Sin respuesta del servidor. Verifica tu conexión e inténtalo de nuevo.');
    } on SocketException {
      throw Exception(
          'No se puede conectar al servidor. Verifica que estés en la red correcta.');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // JWT DECODE
  // ══════════════════════════════════════════════════════════════════════════

  static Map<String, dynamic> decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Token JWT malformado: se esperaban 3 segmentos.');
    }

    String payload = parts[1];
    final int padLength = (4 - payload.length % 4) % 4;
    payload += '=' * padLength;

    final decoded = utf8.decode(base64Url.decode(payload));
    return jsonDecode(decoded) as Map<String, dynamic>;
  }
}
