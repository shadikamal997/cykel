/// API Keys Configuration
/// Provides API keys from environment configuration

import 'app_config.dart';

class ApiKeys {
  /// Google Maps API key
  static String get googleMapsApiKey => AppConfig.googleMapsApiKey;

  /// OpenWeatherMap API key
  static String get openWeatherMapApiKey => AppConfig.openWeatherMapApiKey;
}
