import 'dart:convert';
import 'dart:async' show TimeoutException;
import 'dart:io' show SocketException;
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/evento_qr.dart';
import '../models/zona.dart';

/// Servicio que se comunica con el microservicio de asistencia.
/// BASE_URL apunta al gateway/backend real; ajústala según el entorno.
class AsistenciaService {
  // Ajustado para funcionar en dispositivo físico (moto g52), web o escritorio.
  static String get _baseUrl => AppConfig.planillaUrl;


  // ─────────────────────────────────────────────────────────────────────────
  // Valida el token del QR contra el backend y devuelve los detalles del evento.
  // Lanza [Exception] si el QR está expirado o es inválido.
  // ─────────────────────────────────────────────────────────────────────────
  static Future<EventoQr> validarQr(String tokenQr) async {
    final uri = Uri.parse('$_baseUrl/asistencia/qr/validar');
    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode({'tokenQr': tokenQr}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return EventoQr.fromJson({...data, 'tokenQr': tokenQr});
      } else if (response.statusCode == 410) {
        throw Exception('El código QR ha expirado.');
      } else {
        throw Exception('QR inválido (código ${response.statusCode}).');
      }
    } on TimeoutException {
      throw Exception(
          'Sin respuesta del servidor. Verifica tu conexión e inténtalo de nuevo.');
    } on SocketException {
      throw Exception(
          'No se puede conectar al servidor. Verifica tu red.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Registra la asistencia del estudiante.
  // Incluye ubicación GPS opcional.
  // Devuelve el mensaje de éxito del backend.
  // ─────────────────────────────────────────────────────────────────────────
  static Future<String> registrarAsistencia({
    required String tokenQr,
    required String estudianteId,
    double? latitud,
    double? longitud,
  }) async {
    final uri = Uri.parse('$_baseUrl/asistencia/registrar');
    final body = <String, dynamic>{
      'tokenQr': tokenQr,
      'estudianteId': estudianteId,
    };
    if (latitud != null && longitud != null) {
      body['latitud'] = latitud;
      body['longitud'] = longitud;
    }

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['mensaje'] as String? ??
            'Asistencia registrada exitosamente.';
      } else if (response.statusCode == 409) {
        throw Exception('Ya registraste tu asistencia para este evento.');
      } else if (response.statusCode == 410) {
        throw Exception('El código QR ha expirado.');
      } else {
        throw Exception(
            'Error al registrar asistencia (${response.statusCode}).');
      }
    } on TimeoutException {
      throw Exception(
          'Sin respuesta del servidor. Verifica tu conexión e inténtalo de nuevo.');
    } on SocketException {
      throw Exception(
          'No se puede conectar al servidor. Verifica tu red.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Obtiene el listado de zonas geográficas disponibles.
  // ─────────────────────────────────────────────────────────────────────────
  static Future<List<Zona>> fetchZonas() async {
    final uri = Uri.parse('$_baseUrl/asistencia/zonas');
    try {
      final response = await http.get(
        uri,
        headers: {'ngrok-skip-browser-warning': 'true'},
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((z) => Zona.fromJson(z)).toList();
      } else {
        throw Exception('Error al cargar zonas (${response.statusCode})');
      }
    } on TimeoutException {
      throw Exception(
          'Sin respuesta del servidor. Verifica tu conexión e inténtalo de nuevo.');
    } on SocketException {
      throw Exception(
          'No se puede conectar al servidor. Verifica tu red.');
    } catch (e) {
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Crea un nuevo evento y devuelve los detalles (incluyendo el token QR).
  // ─────────────────────────────────────────────────────────────────────────
  static Future<EventoQr> crearEvento(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$_baseUrl/asistencia/crear');
    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return EventoQr.fromJson(data);
      } else {
        throw Exception('Error al crear el evento (${response.statusCode})');
      }
    } on TimeoutException {
      throw Exception(
          'Sin respuesta del servidor. Verifica tu conexión e inténtalo de nuevo.');
    } on SocketException {
      throw Exception(
          'No se puede conectar al servidor. Verifica tu red.');
    }
  }
}
