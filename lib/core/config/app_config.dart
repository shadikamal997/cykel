/// Application configuration loaded from environment variables.
///
/// Values are provided via --dart-define flags during build/run:
/// ```
/// flutter run --dart-define=GOOGLE_MAPS_API_KEY=your_key_here
/// ```
class AppConfig {
  /// Google Maps API key for both iOS and Android.
  ///
  /// Required for:
  /// - google_maps_flutter
  /// - Places API
  /// - Geocoding API
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  /// Firebase Web API key (if needed for web builds).
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );

  /// OpenWeatherMap API key for weather data.
  ///
  /// Required for:
  /// - Weather forecasts
  /// - Weather-adaptive routing
  static const String openWeatherMapApiKey = String.fromEnvironment(
    'OPENWEATHERMAP_API_KEY',
    defaultValue: '',
  );

  /// Validates that all required configuration values are present.
  ///
  /// Call this in main() before runApp() to fail fast if config is missing.
  static void validate() {
    if (googleMapsApiKey.isEmpty) {
      throw Exception(
        'GOOGLE_MAPS_API_KEY is not configured. '
        'Please provide it via --dart-define during build/run.',
      );
    }
    if (openWeatherMapApiKey.isEmpty) {
      throw Exception(
        'OPENWEATHERMAP_API_KEY is not configured. '
        'Please provide it via --dart-define during build/run.',
      );
    }
  }

  /// Returns true if all configuration is present and valid.
  static bool get isValid => 
      googleMapsApiKey.isNotEmpty && openWeatherMapApiKey.isNotEmpty;
}
