class ApiConfig {
  ApiConfig._();

  static const String rootUrl = String.fromEnvironment(
    'API_ROOT_URL',
    defaultValue: 'https://agrasen-mess.onrender.com',
  );

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://agrasen-mess.onrender.com/api/v1',
  );

  static const Duration timeout = Duration(seconds: 20);
}
