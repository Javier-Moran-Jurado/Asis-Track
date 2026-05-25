import 'dart:js' as js;

String getApiBaseUrl() {
  try {
    final env = js.context['env'];
    if (env != null) {
      final url = env['API_BASE_URL'];
      if (url != null) {
        return url as String;
      }
    }
  } catch (_) {
    // Si algo falla, usar fallback
  }
  return 'http://localhost';
}
