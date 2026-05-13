import 'dart:async' show TimeoutException;
import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

/// Servicio de autenticacion con Google OAuth2.
///
/// Responsabilidades:
///   • Iniciar sesion con Google (multiplataforma: Web, Android, iOS).
///   • Enviar el idToken al backend para validacion y emision de JWT propios.
///   • Manejar errores de dominio no institucional y usuario no registrado.
class GoogleAuthService {
  static String get _baseUrl => AppConfig.baseUrl;

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'openid',
      'email',
      'profile',
    ],
    // Client ID para Web (obligatorio en Flutter Web).
    clientId: kIsWeb
        ? '655549064856-hn07fp0osk2c2luodfo679020gt4od1d.apps.googleusercontent.com'
        : null,
    // ServerClientId para Android/iOS: permite obtener un idToken valido
    // verificable contra el backend.
    serverClientId:
        '655549064856-hn07fp0osk2c2luodfo679020gt4od1d.apps.googleusercontent.com',
  );

  /// Inicia el flujo de Google Sign-In, valida el token con el backend
  /// y retorna un [UserModel] si todo es exitoso.
  ///
  /// Retorna `null` si el usuario cancela el picker de cuentas.
  /// Lanza [Exception] con mensaje amigable en caso de error.
  static Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      // Usuario cancelo el picker
      if (account == null) {
        return null;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception(
            'No se pudo obtener el token de identidad de Google. Intenta de nuevo.');
      }

      // Llamar al backend con el idToken
      final uri = Uri.parse('$_baseUrl/api/v1/auth/oauth2/google');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode({'idToken': idToken}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accessToken = data['access_token'] as String;
        final refreshToken = data['refresh_token'] as String;

        // Guardar tokens en SecureStorage (reutiliza AuthService)
        await AuthService.saveTokens(accessToken, refreshToken);

        // Decodificar JWT para extraer datos basicos
        final claims = AuthService.decodeJwtPayload(accessToken);
        final codigo = claims['jti']?.toString() ?? '';
        final nombreCompleto = claims['nombre_completo']?.toString() ?? '';
        final rol = claims['rol']?.toString() ?? '';

        // Obtener correo desde el perfil del usuario
        String correo = '';
        try {
          final profile =
              await AuthService.getUserProfile(codigo, accessToken);
          correo = profile.correo;
        } catch (_) {
          // Si el perfil no se puede obtener, usar el del token de Google
          correo = account.email;
        }

        // Guardar datos no sensibles en SharedPreferences
        final user = UserModel(
          codigo: codigo,
          nombreCompleto: nombreCompleto,
          correo: correo,
          rol: rol,
        );
        await AuthService.saveUserData(user);

        return user;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final body = jsonDecode(response.body) as Map<String, dynamic>?;
        final message = body?['message']?.toString() ??
            body?['error']?.toString() ??
            'Acceso denegado. Verifica tu correo institucional.';
        throw Exception(message);
      } else {
        throw Exception(
            'Error al iniciar sesion con Google (${response.statusCode}).');
      }
    } on TimeoutException {
      throw Exception(
          'Sin respuesta del servidor. Verifica tu conexion e intentalo de nuevo.');
    } on SocketException {
      throw Exception(
          'No se puede conectar al servidor. Verifica que estes en la red correcta.');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception(
          'Error inesperado al iniciar sesion con Google. Intenta de nuevo.');
    }
  }

  /// Cierra la sesion de Google (revoca los permisos locales).
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
