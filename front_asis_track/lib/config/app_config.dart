class AppConfig {
  // URL activa de ngrok (VM)
  static const String _baseUrl = 'https://ambush-goal-narrow.ngrok-free.dev';

  // Misma URL para web y móvil
  static String get baseUrl => _baseUrl;
}
