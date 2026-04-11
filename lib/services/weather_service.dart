/// CYKEL — Weather Service
/// Fetches Danish weather data from Open-Meteo (free, no API key).
/// Phase 8: 30-minute cache, hourly forecast, UV index, visibility.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/denmark_constants.dart';

class WeatherService {
  WeatherService()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
          ),
        );

  final Dio _dio;

  // ── Cache ──────────────────────────────────────────────────────────────────
  WeatherData? _cachedCurrent;
  List<HourlyForecast>? _cachedHourly;
  DateTime? _cacheTimeCurrent;
  DateTime? _cacheTimeHourly;
  double? _cacheLat;
  double? _cacheLng;

  bool _cacheValidCurrent(double lat, double lng) {
    if (_cacheTimeCurrent == null || _cacheLat == null || _cacheLng == null) {
      return false;
    }
    final age = DateTime.now().difference(_cacheTimeCurrent!).inMinutes;
    final sameLoc =
        (_cacheLat! - lat).abs() < 0.01 && (_cacheLng! - lng).abs() < 0.01;
    return age < AppConstants.weatherCacheMinutes && sameLoc;
  }

  bool _cacheValidHourly(double lat, double lng) {
    if (_cacheTimeHourly == null || _cacheLat == null || _cacheLng == null) {
      return false;
    }
    final age = DateTime.now().difference(_cacheTimeHourly!).inMinutes;
    final sameLoc =
        (_cacheLat! - lat).abs() < 0.01 && (_cacheLng! - lng).abs() < 0.01;
    return age < AppConstants.weatherCacheMinutes && sameLoc;
  }

  // ── Current conditions ─────────────────────────────────────────────────────

  /// Fetch current weather conditions for a given lat/lng.
  /// Uses a 30-minute cache; returns cached data if still fresh.
  Future<WeatherData> fetchCurrentConditions({
    required double latitude,
    required double longitude,
  }) async {
    if (_cacheValidCurrent(latitude, longitude) && _cachedCurrent != null) {
      return _cachedCurrent!;
    }
    try {
      final response = await _dio.get(
        DenmarkConstants.openMeteoBaseUrl,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'current': [
            'temperature_2m',
            'apparent_temperature',
            'precipitation',
            'wind_speed_10m',
            'wind_direction_10m',
            'weather_code',
            'uv_index',
            'visibility',
          ].join(','),
          'wind_speed_unit': 'ms',
          'timezone': 'Europe/Copenhagen',
        },
      );
      final data = WeatherData.fromJson(
        response.data['current'] as Map<String, dynamic>,
      );
      _cachedCurrent = data;
      _cacheTimeCurrent = DateTime.now();
      _cacheLat = latitude;
      _cacheLng = longitude;
      return data;
    } on DioException catch (e) {
      debugPrint('WeatherService fetch failed: ${e.type} — ${e.message}');
      // Return stale cache on network error if available.
      if (_cachedCurrent != null) return _cachedCurrent!;
      rethrow;
    }
  }

  // ── 24-hour forecast ───────────────────────────────────────────────────────

  /// Returns hourly forecast for the next 24 hours.
  /// Shares the same 30-minute cache as [fetchCurrentConditions].
  Future<List<HourlyForecast>> fetchHourlyForecast({
    required double latitude,
    required double longitude,
  }) async {
    if (_cacheValidHourly(latitude, longitude) && _cachedHourly != null) {
      return _cachedHourly!;
    }
    try {
      final response = await _dio.get(
        DenmarkConstants.openMeteoBaseUrl,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'hourly': [
            'temperature_2m',
            'precipitation_probability',
            'precipitation',
            'wind_speed_10m',
            'wind_direction_10m',
            'weather_code',
          ].join(','),
          'wind_speed_unit': 'ms',
          'timezone': 'Europe/Copenhagen',
          'forecast_hours': '24',
        },
      );
      final hourly = response.data['hourly'] as Map<String, dynamic>;
      final times = hourly['time'] as List;
      final temps = hourly['temperature_2m'] as List;
      final precipProb = hourly['precipitation_probability'] as List;
      final precip = hourly['precipitation'] as List;
      final winds = hourly['wind_speed_10m'] as List;
      final windDirs = hourly['wind_direction_10m'] as List;
      final codes = hourly['weather_code'] as List;

      final results = <HourlyForecast>[];
      for (int i = 0; i < times.length; i++) {
        results.add(HourlyForecast(
          time: DateTime.parse(times[i] as String),
          temperatureC: (temps[i] as num).toDouble(),
          precipitationProbability: (precipProb[i] as num).toInt(),
          precipitationMm: (precip[i] as num).toDouble(),
          windSpeedMs: (winds[i] as num).toDouble(),
          windDirectionDeg: (windDirs[i] as num).toInt(),
          weatherCode: (codes[i] as num).toInt(),
        ));
      }

      _cachedHourly = results;
      _cacheTimeHourly = DateTime.now();
      _cacheLat = latitude;
      _cacheLng = longitude;
      return results;
    } on DioException catch (e) {
      debugPrint('WeatherService hourly fetch failed: ${e.type}');
      if (_cachedHourly != null) return _cachedHourly!;
      rethrow;
    }
  }
}

// ─── Weather Data Model ───────────────────────────────────────────────────────

class WeatherData {
  const WeatherData({
    required this.temperatureC,
    required this.feelsLikeC,
    required this.precipitationMm,
    required this.windSpeedMs,
    required this.windDirectionDeg,
    required this.weatherCode,
    required this.fetchedAt,
    this.uvIndex,
    this.visibilityM,
    this.isFallback = false,
  });

  final double temperatureC;
  final double feelsLikeC;
  final double precipitationMm;
  final double windSpeedMs;
  final int windDirectionDeg;
  final int weatherCode;
  final DateTime fetchedAt;
  final double? uvIndex;
  final double? visibilityM;
  /// True when live API call failed and placeholder values are shown.
  final bool isFallback;

  bool get isIceRisk => temperatureC <= DenmarkConstants.iceRiskTemp;
  bool get isCold => temperatureC <= DenmarkConstants.coldRidingTemp;
  bool get isWindy => windSpeedMs >= DenmarkConstants.windStrongMax;
  bool get isRaining => precipitationMm > 0;
  bool get isFoggy => weatherCode == 45 || weatherCode == 48;
  bool get isLowVisibility => (visibilityM ?? 10000) < 1000;

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperatureC: (json['temperature_2m'] as num).toDouble(),
      feelsLikeC: (json['apparent_temperature'] as num).toDouble(),
      precipitationMm: (json['precipitation'] as num).toDouble(),
      windSpeedMs: (json['wind_speed_10m'] as num).toDouble(),
      windDirectionDeg: (json['wind_direction_10m'] as num).toInt(),
      weatherCode: json['weather_code'] as int,
      uvIndex: (json['uv_index'] as num?)?.toDouble(),
      visibilityM: (json['visibility'] as num?)?.toDouble(),
      fetchedAt: DateTime.now(),
    );
  }
}

// ─── Hourly Forecast Model ───────────────────────────────────────────────────

class HourlyForecast {
  const HourlyForecast({
    required this.time,
    required this.temperatureC,
    required this.precipitationProbability,
    required this.precipitationMm,
    required this.windSpeedMs,
    required this.windDirectionDeg,
    required this.weatherCode,
  });

  final DateTime time;
  final double temperatureC;
  final int precipitationProbability;     // 0–100 %
  final double precipitationMm;
  final double windSpeedMs;
  final int windDirectionDeg;
  final int weatherCode;

  bool get isIceRisk => temperatureC <= DenmarkConstants.iceRiskTemp;
  bool get isRainy => precipitationProbability > 50;
}

final weatherServiceProvider =
    Provider<WeatherService>((ref) => WeatherService());
