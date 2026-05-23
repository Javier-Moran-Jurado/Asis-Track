import 'package:flutter/foundation.dart';

import 'app_config_web.dart'
    if (dart.library.io) 'app_config_io.dart';

/// Configuracion centralizada de URLs.
///
/// En web, lee la variable de entorno inyectada en runtime via env-config.js.
/// En mobile/desktop, usa un fallback local.
class AppConfig {
  static String get apiBaseUrl => getApiBaseUrl();

  @Deprecated('Usa apiBaseUrl')
  static String get authUrl => apiBaseUrl;

  @Deprecated('Usa apiBaseUrl')
  static String get usuarioUrl => apiBaseUrl;

  @Deprecated('Usa apiBaseUrl')
  static String get planillaUrl => apiBaseUrl;

  @Deprecated('Usa apiBaseUrl')
  static String get baseUrl => apiBaseUrl;
}
