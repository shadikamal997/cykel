/// CYKEL — Wind Overlay Provider
/// Provides wind direction and intensity data for map overlay

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../services/location_service.dart';
import '../../../services/weather_service.dart';
import '../../home/data/weather_provider.dart';

/// Wind overlay data for map display
final windOverlayProvider = FutureProvider<WindOverlayData?>((ref) async {
  final weatherAsync = await ref.watch(homeWeatherProvider.future);
  LatLng userPos;
  try {
    userPos = await ref.read(locationServiceProvider).getLastKnownOrCurrent();
  } catch (e) {
    debugPrint('windOverlayProvider: location failed, using Copenhagen: $e');
    userPos = const LatLng(55.6761, 12.5683);
  }
  return WindOverlayData.fromWeather(weatherAsync, userPosition: userPos);
});

class WindOverlayData {
  const WindOverlayData({
    required this.windSpeedMs,
    required this.windDirectionDeg,
    required this.markers,
  });

  final double windSpeedMs;
  final int windDirectionDeg;
  final Set<Marker> markers;

  static Future<WindOverlayData?> fromWeather(
    WeatherData weather, {
    required LatLng userPosition,
  }) async {
    // Create wind direction markers at strategic locations
    final markers = <Marker>{};

    // Only show wind overlay if wind speed is significant (>5 km/h)
    if (weather.windSpeedMs < 1.4) return null;

    // Create a few wind direction markers around the user's area
    // In a real implementation, you'd fetch wind data for a grid
    // For now, we'll show a single wind indicator

    final windMarker = Marker(
      markerId: const MarkerId('wind_indicator'),
      position: userPosition,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(
        title: 'Wind: ${(weather.windSpeedMs * 3.6).round()} km/h',
        snippet: _getWindDirection(weather.windDirectionDeg),
      ),
    );

    markers.add(windMarker);

    return WindOverlayData(
      windSpeedMs: weather.windSpeedMs,
      windDirectionDeg: weather.windDirectionDeg,
      markers: markers,
    );
  }

  static String _getWindDirection(int degrees) {
    const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                       'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final index = ((degrees + 11.25) / 22.5).round() % 16;
    return directions[index];
  }
}