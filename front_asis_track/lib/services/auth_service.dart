import 'dart:async' show TimeoutException;
import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';

/// Servicio de autenticación.
///
/// Responsabilidades:
///   • Llamadas HTTP a los endpoints de auth y perfil de usuario.
///   • Codificación/decodificación del JWT sin dependencias externas.
///   • Persistencia segura de tokens (flutter_secure_storage).
///   • Persistencia de datos no sensibles del usuario (shared_preferences).
class AuthService {
  // ──────────────────────────────────────────────────────────────────────────
  static String get _baseUrl => AppConfig.baseUrl;

  // ──────────────────────────────────────────────────────────────────────────
  // SecureStorage — SOLO tokens sensibles
  // ──────────────────────────────────────────────────────────────────────────
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ──────────────────────────────────────────────────────────────────────────
  // SharedPreferences — datos no sensibles del usuario
  // ──────────────────────────────────────────────────────────────────────────
  static const String _keyNombreCompleto = 'user_nombre_completo';
  static const String _keyCorreo = 'user_correo';
  static const String _keyCodigo = 'user_codigo';
  static const String _keyRol = 'user_rol';

  // ══════════════════════════════════════════════════════════════════════════
  // API CALLS
  // ══════════════════════════════════════════════════════════════════════════

  /// POST /api/v1/auth/login
  ///
  /// Retorna `{ "access_token": ..., "refresh_token": ... }`.
  /// Lanza [Exception] con mensaje amigable en caso de error.
  static Future<Map<String, String>> login(
    String codigo,
    String contrasena,
  ) async {
    final uri = Uri.parse('$_baseUrl/api/v1/auth/login');

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
        throw Exception('Código o contraseña incorrectos.');
      } else {
        throw Exception('Error al iniciar sesión (${response.statusCode}).');
      }
    } on TimeoutException {
      throw Exception(
          'Sin respuesta del servidor. Verifica tu conexión e inténtalo de nuevo.');
    } on SocketException {
      throw Exception(
          'No se puede conectar al servidor. Verifica que estés en la red correcta y que el servidor esté activo.');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception(
          'Error de conexión inesperado. Verifica tu red e inténtalo de nuevo.');
    }
  }

  /// GET /api/v1/usuario-service/usuarios/{codigo}
  ///
  /// Requiere el [accessToken] en el header Authorization.
  /// Retorna [UserModel] deserializado del campo `usuario`.
  /// El caller es responsable de manejar posibles excepciones.
  static Future<UserModel> getUserProfile(
    String codigo,
    String accessToken,
  ) async {
    final uri = Uri.parse('$_baseUrl/api/v1/usuario-service/usuarios/$codigo');

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
  // JWT DECODE — sin librería externa (solo base64url estándar de Dart)
  // ══════════════════════════════════════════════════════════════════════════

  /// Decodifica el payload de un JWT sin verificar su firma.
  ///
  /// Divide el token por `.`, toma el segmento en índice 1, normaliza el
  /// padding base64url y retorna el JSON decodificado como [Map].
  static Map<String, dynamic> decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Token JWT malformado: se esperaban 3 segmentos.');
    }

    // Normalizar padding: base64url no requiere `=` pero Dart sí.
    String payload = parts[1];
    final int padLength = (4 - payload.length % 4) % 4;
    payload += '=' * padLength;

    final decoded = utf8.decode(base64Url.decode(payload));
    return jsonDecode(decoded) as Map<String, dynamic>;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SECURE STORAGE — tokens
  // ══════════════════════════════════════════════════════════════════════════

  /// Persiste el par de tokens en almacenamiento seguro.
  static Future<void> saveTokens(
    String accessToken,
    String refreshToken,
  ) async {
    await Future.wait([
      _secureStorage.write(key: _keyAccessToken, value: accessToken),
      _secureStorage.write(key: _keyRefreshToken, value: refreshToken),
    ]);
  }

  /// Lee el access token almacenado. Devuelve `null` si no existe.
  static Future<String?> getAccessToken() =>
      _secureStorage.read(key: _keyAccessToken);

  /// Lee el refresh token almacenado. Devuelve `null` si no existe.
  static Future<String?> getRefreshToken() =>
      _secureStorage.read(key: _keyRefreshToken);

  /// Devuelve `true` si existe un access token no vacío en secure storage.
  static Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHARED PREFERENCES — datos no sensibles del usuario
  // ══════════════════════════════════════════════════════════════════════════

  /// Persiste los campos no sensibles del [UserModel] en SharedPreferences.
  static Future<void> saveUserData(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_keyCodigo, user.codigo),
      prefs.setString(_keyNombreCompleto, user.nombreCompleto),
      prefs.setString(_keyCorreo, user.correo),
      prefs.setString(_keyRol, user.rol),
    ]);
  }

  /// Reconstituye un [UserModel] desde SharedPreferences.
  /// Retorna `null` si no hay datos almacenados (primera ejecución o logout).
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
  // LOGOUT — limpieza total de tokens y datos de usuario
  // ══════════════════════════════════════════════════════════════════════════

  /// Elimina todos los datos de sesión:
  ///   • access_token y refresh_token de SecureStorage.
  ///   • Los 4 campos de usuario de SharedPreferences.
  static Future<void> clearAllStorage() async {
    final prefs = await SharedPreferences.getInstance();

    await Future.wait([
      // SecureStorage
      _secureStorage.delete(key: _keyAccessToken),
      _secureStorage.delete(key: _keyRefreshToken),
      // SharedPreferences
      prefs.remove(_keyCodigo),
      prefs.remove(_keyNombreCompleto),
      prefs.remove(_keyCorreo),
      prefs.remove(_keyRol),
    ]);
  }
}
