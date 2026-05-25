
import 'app_config_web.dart'
    if (dart.library.io) 'app_config_io.dart';

/// Configuracion centralizada de URLs.
///
/// En web, lee la variable de entorno inyectada en runtime via env-config.js.
/// En mobile/desktop, usa un fallback local.
class AppConfig {
  static String get apiBaseUrl => getApiBaseUrl();

  static String get authUrl => 'https://usuario-production-df89.up.railway.app';

  static String get usuarioUrl => 'https://usuario-production-df89.up.railway.app';

  static String get planillaUrl => 'https://planilla-production-89a5.up.railway.app';

  static String get seguridadUrl => 'https://seguridad-production-e075.up.railway.app';
}
