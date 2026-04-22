/// CYKEL — Elevation Service
/// Calculates elevation gain along a GPS path using the
/// Open-Elevation API (https://api.open-elevation.com — free, no API key).
///
/// Only the cumulative ascent (positive gain) is returned so that we match
/// the convention used by cycling apps (e.g. Strava "elevation gained").

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

enum GradientLevel {
  flat,      // 0-3%
  gentle,    // 3-6%
  moderate,  // 6-10%
  steep,     // 10-15%
  verySteep, // 15%+
}

class ElevationPoint {
  final LatLng location;
  final double elevationMeters;
  final double? gradientPercent; // null for first point
  final GradientLevel? gradientLevel;

  ElevationPoint({
    required this.location,
    required this.elevationMeters,
    this.gradientPercent,
    this.gradientLevel,
  });

  Color get gradientColor {
    if (gradientLevel == null) return const Color(0xFF4CAF50);
    switch (gradientLevel!) {
      case GradientLevel.flat:
        return const Color(0xFF4CAF50); // Green
      case GradientLevel.gentle:
        return const Color(0xFF8BC34A); // Light green
      case GradientLevel.moderate:
        return const Color(0xFFFFC107); // Yellow
      case GradientLevel.steep:
        return const Color(0xFFFF9800); // Orange
      case GradientLevel.verySteep:
        return const Color(0xFFF44336); // Red
    }
  }

  String get gradientLabel {
    if (gradientPercent == null) return 'Flat';
    return '${gradientPercent!.abs().toStringAsFixed(1)}%';
  }
}

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

  // ─── NEW: Gradient Visualization ──────────────────────────────────────────

  /// Get elevation profile with gradient data for route visualization
  Future<List<ElevationPoint>> getRouteProfile(List<LatLng> routePoints, {
    int maxPoints = 100,
  }) async {
    if (routePoints.length < 2) return [];

    final sampledPoints = _samplePoints(routePoints, maxPoints: maxPoints);
    final results = <ElevationPoint>[];

    try {
      final body = jsonEncode({
        'locations': sampledPoints
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

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final elevationResults = data['results'] as List?;
      if (elevationResults == null || elevationResults.isEmpty) return [];

      // Calculate gradients between points
      for (int i = 0; i < sampledPoints.length; i++) {
        final elevation = (elevationResults[i]['elevation'] as num?)?.toDouble();
        if (elevation == null) continue;

        double? gradient;
        GradientLevel? level;

        if (i > 0) {
          final prevElevation =
              (elevationResults[i - 1]['elevation'] as num?)?.toDouble();
          if (prevElevation != null) {
            final distance = _calculateDistance(
              sampledPoints[i - 1],
              sampledPoints[i],
            );

            if (distance > 0) {
              final rise = elevation - prevElevation;
              gradient = (rise / distance) * 100; // Percentage
              level = _getGradientLevel(gradient.abs());
            }
          }
        }

        results.add(ElevationPoint(
          location: sampledPoints[i],
          elevationMeters: elevation,
          gradientPercent: gradient,
          gradientLevel: level,
        ));
      }

      return results;
    } catch (e) {
      debugPrint('ElevationService profile error: $e');
      return [];
    }
  }

  /// Get gradient-colored polyline segments for route
  List<Polyline> getGradientPolylines(List<ElevationPoint> profile, {
    String idPrefix = 'gradient',
  }) {
    if (profile.length < 2) return [];

    final polylines = <Polyline>[];

    for (int i = 0; i < profile.length - 1; i++) {
      final current = profile[i];
      final next = profile[i + 1];

      // Use the gradient of the next point (uphill from current)
      final color = next.gradientColor;

      polylines.add(Polyline(
        polylineId: PolylineId('${idPrefix}_$i'),
        points: [current.location, next.location],
        color: color,
        width: 6,
        endCap: Cap.roundCap,
        startCap: Cap.roundCap,
      ));
    }

    return polylines;
  }

  /// Calculate total elevation gain/loss and other stats
  Map<String, double> calculateElevationStats(List<ElevationPoint> profile) {
    if (profile.isEmpty) {
      return {'gain': 0, 'loss': 0, 'min': 0, 'max': 0};
    }

    double totalGain = 0;
    double totalLoss = 0;
    double minElevation = profile.first.elevationMeters;
    double maxElevation = profile.first.elevationMeters;

    for (int i = 0; i < profile.length; i++) {
      final elevation = profile[i].elevationMeters;

      if (elevation < minElevation) minElevation = elevation;
      if (elevation > maxElevation) maxElevation = elevation;

      if (i > 0) {
        final diff = elevation - profile[i - 1].elevationMeters;
        if (diff > 0) {
          totalGain += diff;
        } else {
          totalLoss += diff.abs();
        }
      }
    }

    return {
      'gain': totalGain,
      'loss': totalLoss,
      'min': minElevation,
      'max': maxElevation,
    };
  }

  // ─── Private Helpers ──────────────────────────────────────────────────────

  List<LatLng> _samplePoints(List<LatLng> points, {required int maxPoints}) {
    if (points.length <= maxPoints) return points;

    final sampled = <LatLng>[];
    final step = points.length / maxPoints;

    for (int i = 0; i < maxPoints; i++) {
      final index = (i * step).floor();
      if (index < points.length) {
        sampled.add(points[index]);
      }
    }

    // Always include last point
    if (sampled.isNotEmpty && sampled.last != points.last) {
      sampled.add(points.last);
    }

    return sampled;
  }

  GradientLevel _getGradientLevel(double gradientPercent) {
    if (gradientPercent >= 15) return GradientLevel.verySteep;
    if (gradientPercent >= 10) return GradientLevel.steep;
    if (gradientPercent >= 6) return GradientLevel.moderate;
    if (gradientPercent >= 3) return GradientLevel.gentle;
    return GradientLevel.flat;
  }

  double _calculateDistance(LatLng from, LatLng to) {
    const earthRadiusKm = 6371.0;

    final dLat = _degToRad(to.latitude - from.latitude);
    final dLon = _degToRad(to.longitude - from.longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(from.latitude)) *
            math.cos(_degToRad(to.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c * 1000; // Return in meters
  }

  double _degToRad(double deg) => deg * (math.pi / 180);
}

final elevationServiceProvider =
    Provider<ElevationService>((ref) => ElevationService());
