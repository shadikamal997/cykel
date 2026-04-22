/// CYKEL Weather Radar Service
/// Provides precipitation and weather radar data for map overlay
/// Uses Open-Meteo API (free, no API key required)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum PrecipitationType {
  none,
  drizzle,
  rain,
  heavyRain,
  snow,
}

class WeatherRadarData {
  final double precipitationMm;
  final PrecipitationType type;
  final LatLng location;
  final DateTime timestamp;
  final double cloudCoverPercent;
  final bool isThunderstorm;

  WeatherRadarData({
    required this.precipitationMm,
    required this.type,
    required this.location,
    required this.timestamp,
    required this.cloudCoverPercent,
    this.isThunderstorm = false,
  });

  bool get hasRain => precipitationMm > 0;
  bool get isSevere => precipitationMm > 5.0 || isThunderstorm;
}

class WeatherRadarService {
  WeatherRadarService._();
  static final instance = WeatherRadarService._();

  static const _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  /// Get current precipitation data for a location
  Future<WeatherRadarData?> getCurrentWeather(LatLng center) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?'
        'latitude=${center.latitude}&'
        'longitude=${center.longitude}&'
        'current=precipitation,cloud_cover,weather_code&'
        'timezone=auto',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>?;
      if (current == null) return null;

      final precipMm = (current['precipitation'] as num?)?.toDouble() ?? 0.0;
      final cloudCover = (current['cloud_cover'] as num?)?.toDouble() ?? 0.0;
      final weatherCode = current['weather_code'] as int? ?? 0;

      return WeatherRadarData(
        precipitationMm: precipMm,
        type: _precipitationTypeFromCode(weatherCode, precipMm),
        location: center,
        timestamp: DateTime.now(),
        cloudCoverPercent: cloudCover,
        isThunderstorm: _isThunderstorm(weatherCode),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get precipitation forecast for next 3 hours (grid of points)
  Future<List<WeatherRadarData>> getRadarGrid({
    required LatLng center,
    double radiusKm = 25.0,
    int gridPoints = 9, // 3x3 grid
  }) async {
    final results = <WeatherRadarData>[];
    
    // Create grid of points around center
    final step = radiusKm / (gridPoints / 3);
    
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        final offsetLat = (i - 1) * step / 111.0; // ~111 km per degree latitude
        final offsetLng = (j - 1) * step / (111.0 * 0.7); // Adjust for longitude
        
        final point = LatLng(
          center.latitude + offsetLat,
          center.longitude + offsetLng,
        );
        
        final weather = await getCurrentWeather(point);
        if (weather != null) {
          results.add(weather);
        }
        
        // Rate limiting
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    
    return results;
  }

  /// Get precipitation overlay markers for map
  Set<Circle> getPrecipitationCircles(List<WeatherRadarData> radarData) {
    return radarData.where((d) => d.hasRain).map((data) {
      final intensity = data.precipitationMm;
      const radius = 5000.0; // 5km radius per grid point
      
      // Color based on intensity
      final color = _getRainColor(data.type, intensity);
      
      return Circle(
        circleId: CircleId('rain_${data.location.latitude}_${data.location.longitude}'),
        center: data.location,
        radius: radius,
        fillColor: color.withOpacity(0.4),
        strokeColor: color.withOpacity(0.6),
        strokeWidth: 1,
      );
    }).toSet();
  }

  PrecipitationType _precipitationTypeFromCode(int code, double precipMm) {
    if (precipMm == 0) return PrecipitationType.none;
    
    // WMO Weather codes
    if (code >= 71 && code <= 77) return PrecipitationType.snow;
    if (code >= 61 && code <= 67) return PrecipitationType.heavyRain;
    if (code >= 51 && code <= 57) return PrecipitationType.drizzle;
    if (code == 80 || code == 81 || code == 82) return PrecipitationType.rain;
    
    if (precipMm > 5.0) return PrecipitationType.heavyRain;
    if (precipMm > 1.0) return PrecipitationType.rain;
    return PrecipitationType.drizzle;
  }

  bool _isThunderstorm(int code) {
    return code == 95 || code == 96 || code == 99;
  }

  Color _getRainColor(PrecipitationType type, double intensity) {
    switch (type) {
      case PrecipitationType.drizzle:
        return const Color(0xFF64B5F6); // Light blue
      case PrecipitationType.rain:
        return const Color(0xFF1976D2); // Blue
      case PrecipitationType.heavyRain:
        return const Color(0xFF0D47A1); // Dark blue
      case PrecipitationType.snow:
        return const Color(0xFFE3F2FD); // Very light blue
      case PrecipitationType.none:
        return Colors.transparent;
    }
  }
}
