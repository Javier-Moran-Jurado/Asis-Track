String getApiBaseUrl() {
  const url = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost',
  );
  return url;
}
