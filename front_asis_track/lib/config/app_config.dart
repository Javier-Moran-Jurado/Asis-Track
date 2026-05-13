import 'package:flutter/foundation.dart';

class AppConfig {
  // URL de produccion / ngrok
  static const String _prodUrl = 'https://ambush-goal-narrow.ngrok-free.dev';

  // URL local para desarrollo (backend en localhost:8080)
  static const String _devUrl = 'http://localhost:8080';

  static String get baseUrl {
    // En modo debug o web, usar localhost para pruebas locales
    if (kDebugMode) {
      return _devUrl;
    }
    return _prodUrl;
  }
}
