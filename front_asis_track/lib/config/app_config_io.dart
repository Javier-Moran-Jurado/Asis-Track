String getIoApiBaseUrl() {
  // Fallback para mobile/desktop (no soporta env-config.js)
  return 'http://localhost';
}
