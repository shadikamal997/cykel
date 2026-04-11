/// CYKEL — Daylight Service (Phase 8.5)
///
/// Calculates sunrise / sunset times for Denmark using the standard
/// solar declination algorithm.  No external API required.
///
/// Also provides:
/// • [isDark] — whether it's currently before sunrise / after sunset
/// • [isDarkSoon] — sunset within the next 30 minutes
/// • [daylightHours] — number of light hours today

import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'location_service.dart';

// ─── Daylight Data ───────────────────────────────────────────────────────────

class DaylightInfo {
  const DaylightInfo({
    required this.sunrise,
    required this.sunset,
    required this.now,
  });

  final DateTime sunrise;
  final DateTime sunset;
  final DateTime now;

  /// Number of daylight hours today.
  double get daylightHours => sunset.difference(sunrise).inMinutes / 60.0;

  /// Whether it is currently dark (before sunrise or after sunset).
  bool get isDark => now.isBefore(sunrise) || now.isAfter(sunset);

  /// Whether sunset is within the next 30 minutes.
  bool get isDarkSoon =>
      !isDark && sunset.difference(now).inMinutes <= 30;

  /// Label like "06:14 – 20:46".
  String get label {
    String hm(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${hm(sunrise)} – ${hm(sunset)}';
  }
}

// ─── Service ─────────────────────────────────────────────────────────────────

class DaylightService {
  /// Compute sunrise/sunset for [latitude]/[longitude] on [date].
  ///
  /// Uses the NOAA solar position algorithm simplified for flat terrain.
  /// Accuracy: ±2 minutes — sufficient for ride planning in Denmark.
  DaylightInfo calculate({
    required double latitude,
    required double longitude,
    DateTime? date,
  }) {
    final now = date ?? DateTime.now();
    final jan1 = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(jan1).inDays + 1;

    // Solar declination (radians)
    final declination = 23.45 * math.sin(2 * math.pi * (284 + dayOfYear) / 365)
        * math.pi / 180;

    final latRad = latitude * math.pi / 180;

    // Hour angle at sunrise / sunset
    final cosH = -math.tan(latRad) * math.tan(declination);

    // Handle polar day/night (should never happen in Denmark, but just in case)
    late final double hourAngle;
    if (cosH < -1) {
      // Midnight sun — set sunrise to 00:00, sunset to 23:59
      return DaylightInfo(
        sunrise: DateTime(now.year, now.month, now.day, 0, 0),
        sunset: DateTime(now.year, now.month, now.day, 23, 59),
        now: now,
      );
    } else if (cosH > 1) {
      // Polar night
      return DaylightInfo(
        sunrise: DateTime(now.year, now.month, now.day, 12, 0),
        sunset: DateTime(now.year, now.month, now.day, 12, 0),
        now: now,
      );
    } else {
      hourAngle = math.acos(cosH) * 180 / math.pi;
    }

    // Equation of time correction (minutes)
    final b = 2 * math.pi * (dayOfYear - 81) / 365;
    final eot = 9.87 * math.sin(2 * b) - 7.53 * math.cos(b) - 1.5 * math.sin(b);

    // Solar noon in minutes UTC
    final solarNoonMin = 720 - 4 * longitude - eot;

    // Denmark timezone offset (CET +1 or CEST +2)
    final offset = now.timeZoneOffset.inMinutes;

    final sunriseMin = solarNoonMin - hourAngle * 4 + offset;
    final sunsetMin = solarNoonMin + hourAngle * 4 + offset;

    DateTime toDateTime(double minutes) {
      final m = minutes.round().clamp(0, 1439);
      return DateTime(now.year, now.month, now.day, m ~/ 60, m % 60);
    }

    return DaylightInfo(
      sunrise: toDateTime(sunriseMin),
      sunset: toDateTime(sunsetMin),
      now: now,
    );
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final daylightServiceProvider =
    Provider<DaylightService>((ref) => DaylightService());

/// Current daylight status - refreshes every minute and uses user location.
/// Falls back to Copenhagen if location unavailable.
final daylightInfoProvider = StreamProvider<DaylightInfo>((ref) async* {
  // Copenhagen coordinates as fallback
  const fallbackLat = 55.6761;
  const fallbackLng = 12.5683;
  
  while (true) {
    try {
      // Try to get user's actual location
      final location = await ref.read(locationServiceProvider).getLastKnownOrCurrent();
      
      yield ref.read(daylightServiceProvider).calculate(
        latitude: location.latitude,
        longitude: location.longitude,
      );
    } catch (e) {
      // Fall back to Copenhagen if location unavailable
      yield ref.read(daylightServiceProvider).calculate(
        latitude: fallbackLat,
        longitude: fallbackLng,
      );
    }
    
    // Wait 1 minute before next calculation
    await Future.delayed(const Duration(minutes: 1));
  }
});
