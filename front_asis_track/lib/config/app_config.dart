import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _prodUrl = 'https://ambush-goal-narrow.ngrok-free.dev';
  static const String _devAuthUrl = 'http://localhost:8080';
  static const String _devPlanillaUrl = 'http://localhost:8084';

  static String get authUrl => kDebugMode ? _devAuthUrl : _prodUrl;
  static String get usuarioUrl => kDebugMode ? _devAuthUrl : _prodUrl;
  static String get planillaUrl => kDebugMode ? _devPlanillaUrl : _prodUrl;

  @Deprecated('Usa authUrl, usuarioUrl o planillaUrl según corresponda')
  static String get baseUrl => authUrl;
}
