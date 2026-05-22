import 'package:flutter/foundation.dart';

/// Configuración de URLs del backend.
///
/// En desarrollo local (por defecto) apunta a localhost:8080 / :8084.
/// En producción se sobreescribe vía --dart-define al compilar:
///
///   flutter build web --release \
///     --dart-define=AUTH_URL=https://tu-url-ngrok.com \
///     --dart-define=PLANILLA_URL=https://tu-url-ngrok.com
///
/// Si no se pasan las variables, el fallback es localhost.
class AppConfig {
  static const String _defaultAuthUrl = 'http://localhost:8080';
  static const String _defaultPlanillaUrl = 'http://localhost:8084';

  static String get authUrl =>
      const String.fromEnvironment('AUTH_URL', defaultValue: _defaultAuthUrl);

  static String get usuarioUrl =>
      const String.fromEnvironment('AUTH_URL', defaultValue: _defaultAuthUrl);

  static String get planillaUrl => const String.fromEnvironment(
        'PLANILLA_URL',
        defaultValue: _defaultPlanillaUrl,
      );

  @Deprecated('Usa authUrl, usuarioUrl o planillaUrl según corresponda')
  static String get baseUrl => authUrl;
}
