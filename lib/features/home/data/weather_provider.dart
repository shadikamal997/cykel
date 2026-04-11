/// CYKEL — Home Weather Provider
/// Auto-disposing FutureProvider so [ref.invalidate] triggers a fresh fetch
/// on pull-to-refresh.  Used by [_RideConditionCard] on the home screen.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../services/location_service.dart';
import '../../../services/weather_service.dart';

final homeWeatherProvider =
    FutureProvider.autoDispose<WeatherData>((ref) async {
  // Use last-known position so the card loads instantly on warm GPS.
  // Falls back to fresh fix, then Copenhagen if GPS is unavailable.
  LatLng loc;
  try {
    loc = await ref.read(locationServiceProvider).getLastKnownOrCurrent();
  } catch (e) {
    debugPrint('homeWeatherProvider: location failed, using Copenhagen: $e');
    loc = const LatLng(55.6761, 12.5683);
  }

  try {
    return await ref.read(weatherServiceProvider).fetchCurrentConditions(
      latitude: loc.latitude,
      longitude: loc.longitude,
    );
  } catch (e) {
    debugPrint('homeWeatherProvider: weather fetch failed, using fallback: $e');
    // Return a neutral placeholder so the card renders instead of crashing.
    return WeatherData(
      temperatureC: 12.0,
      feelsLikeC: 10.0,
      precipitationMm: 0.0,
      windSpeedMs: 3.0,
      windDirectionDeg: 0,
      weatherCode: 0,
      fetchedAt: DateTime.now(),
      isFallback: true,
    );
  }
});

/// 24-hour hourly forecast for the user's location.
final hourlyForecastProvider =
    FutureProvider.autoDispose<List<HourlyForecast>>((ref) async {
  LatLng loc;
  try {
    loc = await ref.read(locationServiceProvider).getLastKnownOrCurrent();
  } catch (e) {
    debugPrint('hourlyForecastProvider: location failed, using Copenhagen');
    loc = const LatLng(55.6761, 12.5683);
  }
  try {
    return await ref.read(weatherServiceProvider).fetchHourlyForecast(
      latitude: loc.latitude,
      longitude: loc.longitude,
    );
  } catch (e) {
    debugPrint('hourlyForecastProvider: fetch failed: $e');
    return [];
  }
});
