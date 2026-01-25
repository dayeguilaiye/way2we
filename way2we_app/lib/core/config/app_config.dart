/// Application configuration loaded from environment variables.
///
/// Use `--dart-define` to override values at build time:
/// ```bash
/// flutter run --dart-define=API_BASE_URL=https://api.way2we.com
/// ```
class AppConfig {
  const AppConfig._();

  /// Base URL for the API.
  /// Defaults to localhost for development.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// Whether the app is running in production mode.
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
}
