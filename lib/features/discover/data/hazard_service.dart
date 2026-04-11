/// CYKEL — Hazard Service
///
/// Fetches current weather conditions at a route midpoint from Open-Meteo
/// (free, no API key) and converts them into a list of [HazardAlert]s.
///
/// Variables used:
///   temperature_2m         — air temp at 2 m (°C)
///   apparent_temperature   — feels-like temp (°C)
///   precipitation          — precipitation (mm/h)
///   snowfall               — snowfall (cm/h)
///   wind_speed_10m         — wind at 10 m (m/s)
///   weather_code           — WMO code (45/48 = fog, etc.)
///
/// Darkness is determined via a lightweight sun-elevation formula so that
/// no additional network call is required.

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../domain/hazard_alert.dart';

class HazardService {
  Future<List<HazardAlert>> getHazards(LatLng location) async {
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': location.latitude.toStringAsFixed(4),
        'longitude': location.longitude.toStringAsFixed(4),
        'current': [
          'temperature_2m',
          'apparent_temperature',
          'precipitation',
          'snowfall',
          'wind_speed_10m',
          'weather_code',
        ].join(','),
        'timezone': 'auto',
        'forecast_days': '1',
      });

      final response = await http
          .get(uri, headers: {'User-Agent': 'CYKELApp/1.0'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return [];

      final body = json.decode(response.body) as Map<String, dynamic>;
      final current = body['current'] as Map<String, dynamic>?;
      if (current == null) return [];

      final tempC = (current['temperature_2m'] as num?)?.toDouble() ?? 20.0;
      final feelsC = (current['apparent_temperature'] as num?)?.toDouble() ?? 20.0;
      final precipMm = (current['precipitation'] as num?)?.toDouble() ?? 0.0;
      final snowCm = (current['snowfall'] as num?)?.toDouble() ?? 0.0;
      final windMs = (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0;
      final windKmh = windMs * 3.6;
      final weatherCode = (current['weather_code'] as num?)?.toInt() ?? 0;

      final alerts = <HazardAlert>[];

      // ── Ice: near-freezing temp + precipitation ─────────────────────────────
      if (tempC <= 2.0 && precipMm > 0.1) {
        final sev = ((2.0 - tempC) / 4.0).clamp(0.0, 1.0);
        alerts.add(HazardAlert(type: HazardType.ice, severity: sev));
      }

      // ── Freeze: feels-like below 0 °C ───────────────────────────────────────
      if (feelsC < 0.0 && alerts.none((a) => a.type == HazardType.ice)) {
        alerts.add(HazardAlert(
          type: HazardType.freeze,
          severity: ((-feelsC) / 10.0).clamp(0.0, 1.0),
        ));
      }

      // ── Snow ─────────────────────────────────────────────────────────────────
      if (snowCm > 0.05) {
        alerts.add(HazardAlert(
          type: HazardType.snow,
          severity: (snowCm / 2.0).clamp(0.0, 1.0),
        ));
      }

      // ── Strong wind: ≥ 28 km/h for cyclists ─────────────────────────────────
      if (windKmh >= 28) {
        alerts.add(HazardAlert(
          type: HazardType.strongWind,
          severity: ((windKmh - 28) / 30.0).clamp(0.0, 1.0),
        ));
      }

      // ── Heavy rain ── ──────────────────────────────────────────────────────
      if (precipMm >= 3.0 && snowCm < 0.05) {
        alerts.add(HazardAlert(
          type: HazardType.heavyRain,
          severity: ((precipMm - 3.0) / 10.0).clamp(0.0, 1.0),
        ));
      }

      // ── Wet surface: any precip near zero (not icy) ─────────────────────────
      if (precipMm >= 0.5 && tempC > 2.0 && tempC <= 8.0 &&
          alerts.none((a) =>
              a.type == HazardType.heavyRain || a.type == HazardType.snow)) {
        alerts.add(const HazardAlert(type: HazardType.wetSurface, severity: 0.3));
      }

      // ── Fog: WMO codes 45 = fog, 48 = rime fog ───────────────────────────────
      if (weatherCode == 45 || weatherCode == 48) {
        alerts.add(HazardAlert(
          type: HazardType.fog,
          severity: weatherCode == 48 ? 0.75 : 0.55,
        ));
      }

      // ── Darkness check using sun elevation ────────────────────────────────────
      if (_isDark(location)) {
        alerts.add(const HazardAlert(type: HazardType.darkness, severity: 0.4));
      }

      return alerts;
    } catch (e) {
      debugPrint('HazardService error: $e');
      return [];
    }
  }
}

extension _ListNone<T> on List<T> {
  bool none(bool Function(T) test) => !any(test);
}

/// Returns true when the sun is below –6° elevation (civil twilight / darkness).
/// Uses the NOAA simplified formula — accurate enough for cycling safety.
bool _isDark(LatLng location) {
  final now = DateTime.now().toUtc();
  final jd = _julianDay(now);
  final sunElevDeg = _sunElevation(
    julianDay: jd,
    latDeg: location.latitude,
    lngDeg: location.longitude,
  );
  return sunElevDeg < -6.0;
}

double _julianDay(DateTime utc) {
  final a = (14 - utc.month) ~/ 12;
  final y = utc.year + 4800 - a;
  final m = utc.month + 12 * a - 3;
  final jdn = utc.day + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - y ~/ 100 + y ~/ 400 - 32045;
  return jdn.toDouble() - 0.5 + utc.hour / 24.0 + utc.minute / 1440.0;
}

double _sunElevation({
  required double julianDay,
  required double latDeg,
  required double lngDeg,
}) {
  const toRad = math.pi / 180.0;
  const toDeg = 180.0 / math.pi;

  final n = julianDay - 2451545.0;
  final L = (280.460 + 0.9856474 * n) % 360;
  final g = (357.528 + 0.9856003 * n) % 360;
  final lambda = L + 1.915 * math.sin(g * toRad) + 0.020 * math.sin(2 * g * toRad);
  final sinDec = math.sin(23.439 * toRad) * math.sin(lambda * toRad);
  final dec = math.asin(sinDec);
  final ut = (julianDay - julianDay.floor()) * 24.0;
  final ha = (ut - 12.0) * 15.0 + lngDeg;
  final sinAlt = math.sin(latDeg * toRad) * sinDec +
      math.cos(latDeg * toRad) * math.cos(dec) * math.cos(ha * toRad);
  return math.asin(sinAlt) * toDeg;
}

final hazardServiceProvider =
    Provider<HazardService>((ref) => HazardService());
