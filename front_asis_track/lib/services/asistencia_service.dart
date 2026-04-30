import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/evento_qr.dart';

/// Servicio que se comunica con el microservicio de asistencia.
/// BASE_URL apunta al gateway/backend real; ajústala según el entorno.
class AsistenciaService {
  static const String _baseUrl =
      'http://10.0.2.2:8080'; // localhost para emulador Android

  // ─────────────────────────────────────────────────────────────────────────
  // Valida el token del QR contra el backend y devuelve los detalles del evento.
  // Lanza [Exception] si el QR está expirado o es inválido.
  // ─────────────────────────────────────────────────────────────────────────
  static Future<EventoQr> validarQr(String tokenQr) async {
    final uri = Uri.parse('$_baseUrl/asistencia/qr/validar');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'tokenQr': tokenQr}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return EventoQr.fromJson({...data, 'tokenQr': tokenQr});
    } else if (response.statusCode == 410) {
      throw Exception('El código QR ha expirado.');
    } else {
      throw Exception('QR inválido (código ${response.statusCode}).');
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

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['mensaje'] as String? ?? 'Asistencia registrada exitosamente.';
    } else if (response.statusCode == 409) {
      throw Exception('Ya registraste tu asistencia para este evento.');
    } else if (response.statusCode == 410) {
      throw Exception('El código QR ha expirado.');
    } else {
      throw Exception('Error al registrar asistencia (${response.statusCode}).');
    }
  }
}
