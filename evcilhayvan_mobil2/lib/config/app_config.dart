class AppConfig {
  final String apiBaseUrl;
  final String flavor;

  const AppConfig._({
    required this.apiBaseUrl,
    required this.flavor,
  });

  static AppConfig current = AppConfig._(
    apiBaseUrl: const String.fromEnvironment('API_BASE', defaultValue: 'https://evcilhayvan-backend.onrender.com'),
    flavor: const String.fromEnvironment('FLAVOR', defaultValue: 'dev'),
  );

  static void init({required String apiBaseUrl, required String flavor}) {
    current = AppConfig._(apiBaseUrl: apiBaseUrl, flavor: flavor);
  }
}
