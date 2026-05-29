import 'dart:async' show TimeoutException;
import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Cliente HTTP centralizado con connection pooling y auth interceptor.
///
/// Usa un [http.Client] singleton para mantener conexiones TCP/TLS abiertas
/// entre peticiones (keep-alive), reduciendo la latencia de DNS + handshake.
class ApiClient {
  /// Cliente persistente; reutiliza conexiones subyacentes.
  static final http.Client _client = http.Client();

  // ──────────────────────────────────────────────────────────────────────────
  // Headers comunes
  // ──────────────────────────────────────────────────────────────────────────

  static Future<Map<String, String>> _headers({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (requiresAuth) {
      final token = await AuthService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HTTP verbs con auth automática y manejo de 401
  // ──────────────────────────────────────────────────────────────────────────

  static Future<http.Response> get(
    Uri uri, {
    bool requiresAuth = true,
    Duration? timeout,
  }) async {
    final response = await _client
        .get(uri, headers: await _headers(requiresAuth: requiresAuth))
        .timeout(timeout ?? const Duration(seconds: 30));
    if (response.statusCode == 401) await AuthService.handleUnauthorized();
    return response;
  }

  static Future<http.Response> post(
    Uri uri, {
    String? body,
    bool requiresAuth = true,
    Duration? timeout,
  }) async {
    final response = await _client
        .post(uri, headers: await _headers(requiresAuth: requiresAuth), body: body)
        .timeout(timeout ?? const Duration(seconds: 30));
    if (response.statusCode == 401) await AuthService.handleUnauthorized();
    return response;
  }

  static Future<http.Response> put(
    Uri uri, {
    String? body,
    bool requiresAuth = true,
    Duration? timeout,
  }) async {
    final response = await _client
        .put(uri, headers: await _headers(requiresAuth: requiresAuth), body: body)
        .timeout(timeout ?? const Duration(seconds: 30));
    if (response.statusCode == 401) await AuthService.handleUnauthorized();
    return response;
  }

  static Future<http.Response> delete(
    Uri uri, {
    String? body,
    bool requiresAuth = true,
    Duration? timeout,
  }) async {
    final response = await _client
        .delete(uri, headers: await _headers(requiresAuth: requiresAuth), body: body)
        .timeout(timeout ?? const Duration(seconds: 30));
    if (response.statusCode == 401) await AuthService.handleUnauthorized();
    return response;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Multipart (uploads)
  // ──────────────────────────────────────────────────────────────────────────

  static Future<http.MultipartRequest> multipartRequest(
    String method,
    Uri uri, {
    bool requiresAuth = true,
  }) async {
    final request = http.MultipartRequest(method, uri);
    if (requiresAuth) {
      final token = await AuthService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }
    return request;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Utilidades compartidas
  // ──────────────────────────────────────────────────────────────────────────

  /// Extrae un mensaje legible del body de error del backend.
  static String extractErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      if (body == null) return 'Error ${response.statusCode}';
      if (body['mensaje'] != null) return body['mensaje'].toString();
      if (body['message'] != null) return body['message'].toString();
      if (body['error'] != null) return body['error'].toString();
      if (body['errors'] is List && (body['errors'] as List).isNotEmpty) {
        final first = (body['errors'] as List).first;
        if (first is Map) {
          return first['defaultMessage']?.toString() ??
              first['message']?.toString() ??
              'Error de validación';
        }
        return first.toString();
      }
      return 'Error ${response.statusCode}';
    } catch (_) {
      return 'Error ${response.statusCode}';
    }
  }

  /// Envuelve timeouts y socket exceptions en mensajes amigables.
  static Exception wrapError(Object error) {
    if (error is TimeoutException) {
      return Exception(
          'Sin respuesta del servidor. Verifica tu conexión e inténtalo de nuevo.');
    }
    if (error is SocketException) {
      return Exception(
          'No se puede conectar al servidor. Verifica tu red.');
    }
    if (error is Exception) return error;
    return Exception('Error inesperado: $error');
  }
}
