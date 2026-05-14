import 'dart:async' show TimeoutException;
import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

/// Servicio de autenticacion con Google OAuth2.
class GoogleAuthService {
  static String get _baseUrl => AppConfig.authUrl;

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['openid', 'email', 'profile'],
    clientId: kIsWeb
        ? '655549064856-hn07fp0osk2c2luodfo679020gt4od1d.apps.googleusercontent.com'
        : null,
    serverClientId: kIsWeb
        ? null
        : '655549064856-hn07fp0osk2c2luodfo679020gt4od1d.apps.googleusercontent.com',
  );

  static GoogleSignIn get instance => _googleSignIn;

  /// Flujo tradicional para mobile (popup nativo).
  static Future<UserModel?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;
      return await authenticateWithIdTokenFromAccount(account);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('popup_closed')) {
        throw Exception(
            'La ventana de Google se cerro. Asegurate de permitir ventanas emergentes en tu navegador.');
      }
      debugPrint('[GoogleAuthService] Error signIn: $e');
      throw Exception(
          'Error al iniciar sesion con Google: ${e.toString().replaceFirst("Exception: ", "")}');
    }
  }

  /// Autentica con un idToken directo (usado por GIS web).
  static Future<UserModel> authenticateWithIdToken(String idToken) async {
    return await _authenticate(idToken, '');
  }

  /// Autentica una cuenta de Google mobile.
  static Future<UserModel> authenticateWithIdTokenFromAccount(
      GoogleSignInAccount account) async {
    final googleAuth = await account.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('No se pudo obtener el token de identidad de Google.');
    }
    return await _authenticate(idToken, account.email);
  }

  static Future<UserModel> _authenticate(
      String idToken, String fallbackEmail) async {
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

      await AuthService.saveTokens(accessToken, refreshToken);

      final claims = AuthService.decodeJwtPayload(accessToken);
      final codigo = claims['jti']?.toString() ?? '';
      final nombreCompleto = claims['nombre_completo']?.toString() ?? '';
      final rol = claims['rol']?.toString() ?? '';

      String correo = '';
      try {
        final profile = await AuthService.getUserProfile(codigo, accessToken);
        correo = profile.correo;
      } catch (_) {
        correo = fallbackEmail;
      }

      final user = UserModel(
        codigo: codigo,
        nombreCompleto: nombreCompleto,
        correo: correo,
        rol: rol,
      );
      await AuthService.saveUserData(user);

      return user;
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      final message = body?['message']?.toString() ??
          body?['error']?.toString() ??
          'Error al iniciar sesion con Google (${response.statusCode}).';
      throw Exception(message);
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
