/// CYKEL — Elevation Service
/// Calculates elevation gain along a GPS path using the
/// Open-Elevation API (https://api.open-elevation.com — free, no API key).
///
/// Only the cumulative ascent (positive gain) is returned so that we match
/// the convention used by cycling apps (e.g. Strava "elevation gained").

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class ElevationService {
  static const _base = 'https://api.open-elevation.com/api/v1/lookup';

  /// Computes total elevation gain in metres for [path].
  ///
  /// Samples up to [maxPoints] along the path to keep the request fast.
  /// Returns 0 on any network / parse error so callers can always use the value.
  Future<double> getElevationGain(
    List<LatLng> path, {
    int maxPoints = 50,
  }) async {
    if (path.length < 2) return 0;

    // Down-sample to at most [maxPoints] evenly spaced points.
    final step = (path.length / maxPoints).ceil().clamp(1, path.length);
    final samples = <LatLng>[];
    for (int i = 0; i < path.length; i += step) {
      samples.add(path[i]);
    }
    if (samples.last != path.last) samples.add(path.last);

    try {
      final body = jsonEncode({
        'locations': samples
            .map((p) => {'latitude': p.latitude, 'longitude': p.longitude})
            .toList(),
      });

      final response = await http
          .post(
            Uri.parse(_base),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        debugPrint('ElevationService: HTTP ${response.statusCode}');
        return 0;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return 0;

      // Sum only positive ascent deltas.
      double gain = 0;
      for (int i = 1; i < results.length; i++) {
        final prev = (results[i - 1]['elevation'] as num?)?.toDouble() ?? 0;
        final curr = (results[i]['elevation'] as num?)?.toDouble() ?? 0;
        final delta = curr - prev;
        if (delta > 0) gain += delta;
      }
      return gain.roundToDouble();
    } catch (e) {
      debugPrint('ElevationService error (non-fatal): $e');
      return 0;
    }
  }

  /// Returns minimum samples needed to get a reasonable elevation profile
  /// for rides of varying lengths.
  static int samplesForDistance(double distanceMeters) {
    if (distanceMeters < 2000) return 20;
    if (distanceMeters < 10000) return 40;
    return 60;
  }

  /// Converts elevation gain to approximate extra calories burned (rough model).
  /// Every 100 m of climb ≈ 30 kcal extra for an average 75 kg rider.
  static int extraCaloriesFromElevation(double gainMeters) =>
      ((gainMeters / 100) * 30).round();

  /// Elevation-adjusted range correction for e-bikes.
  /// Every 100 m of ascent costs approx. 2 km of extra battery range.
  static double rangeDeductionKm(double gainMeters) => (gainMeters / 100) * 2;
}

final elevationServiceProvider =
    Provider<ElevationService>((ref) => ElevationService());
