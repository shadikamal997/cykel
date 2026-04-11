/// CYKEL — Wind Service
/// Fetches current wind data from Open-Meteo (free, no API key required).
/// Used to display headwind/tailwind warnings on the route summary card.

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Wind conditions relative to the route direction.
enum WindCondition { calm, tailwind, crosswind, headwind }

/// Wind data at a geographic point.
class WindData {
  const WindData({required this.speedMs, required this.directionDeg});

  /// Wind speed in metres per second.
  final double speedMs;

  /// Meteorological wind direction — the compass bearing the wind is coming FROM.
  final double directionDeg;

  double get speedKmh => speedMs * 3.6;

  /// Headwind score for a given route bearing [0–360°, clockwise from north].
  /// Returns +1.0 = perfect tailwind, −1.0 = perfect headwind, 0 = crosswind.
  double headwindScore(double routeBearing) {
    // Wind vector: where the wind is going TO (opposite of met. direction)
    final windGoesTo = (directionDeg + 180) % 360;
    var diff = (routeBearing - windGoesTo) % 360;
    if (diff > 180) diff -= 360;
    return math.cos(diff * math.pi / 180);
  }

  /// Classify the wind condition for [routeBearing].
  WindCondition condition(double routeBearing) {
    if (speedKmh < 8) return WindCondition.calm;
    final score = headwindScore(routeBearing);
    if (score > 0.5) return WindCondition.tailwind;
    if (score < -0.5) return WindCondition.headwind;
    return WindCondition.crosswind;
  }
}

class WindService {
  /// Fetches the current wind at [location].
  /// Returns null on any network or parse error.
  Future<WindData?> getWind(LatLng location) async {
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': location.latitude.toStringAsFixed(4),
        'longitude': location.longitude.toStringAsFixed(4),
        'current': 'wind_speed_10m,wind_direction_10m',
        'wind_speed_unit': 'ms',
        'timezone': 'auto',
        'forecast_days': '1',
      });
      final response = await http
          .get(uri, headers: {'User-Agent': 'CYKELApp/1.0'})
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final body = json.decode(response.body) as Map<String, dynamic>;
      final current = body['current'] as Map<String, dynamic>?;
      if (current == null) return null;
      final speed = (current['wind_speed_10m'] as num?)?.toDouble();
      final dir = (current['wind_direction_10m'] as num?)?.toDouble();
      if (speed == null || dir == null) return null;
      return WindData(speedMs: speed, directionDeg: dir);
    } catch (e) {
      debugPrint('WindService error: $e');
      return null;
    }
  }
}

final windServiceProvider = Provider<WindService>((ref) => WindService());
