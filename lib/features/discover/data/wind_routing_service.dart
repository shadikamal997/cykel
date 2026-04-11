/// CYKEL — Wind-Aware Routing Service (Phase 8.3)
///
/// Scores route alternatives by sampling wind at multiple points along the
/// polyline and computing a net headwind/tailwind score.  The route with the
/// best (most tailwind) score wins.
///
/// Premium feature — gated by [isPremiumProvider].

import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'wind_service.dart';
import '../domain/route_result.dart';

// ─── Route Wind Score ────────────────────────────────────────────────────────

class RouteWindScore {
  const RouteWindScore({
    required this.routeIndex,
    required this.netScore,
    required this.avgWindSpeedMs,
    required this.samples,
    required this.overallCondition,
  });

  /// Index in the list of alternatives.
  final int routeIndex;

  /// Net headwind score: +1 = tailwind, −1 = headwind, 0 = crosswind.
  /// This is the average across all sample points.
  final double netScore;

  /// Average wind speed across sample points (m/s).
  final double avgWindSpeedMs;

  /// Number of sample points used.
  final int samples;

  /// Overall wind condition for the route.
  final WindCondition overallCondition;

  /// Human-readable effort label.
  String get effortLabel {
    if (netScore > 0.3) return 'Low effort';
    if (netScore > -0.3) return 'Moderate effort';
    return 'High effort';
  }
}

// ─── Service ─────────────────────────────────────────────────────────────────

class WindRoutingService {
  WindRoutingService(this._windService);
  final WindService _windService;

  /// Score a single route by sampling wind at [sampleCount] points along it.
  ///
  /// Returns null if wind data is unavailable.
  Future<RouteWindScore?> scoreRoute(
    RouteResult route, {
    int routeIndex = 0,
    int sampleCount = 5,
  }) async {
    final pts = route.polylinePoints;
    if (pts.length < 2) return null;

    // Choose evenly-spaced sample points along the polyline.
    final indices = <int>[];
    for (int i = 0; i < sampleCount; i++) {
      indices.add((i * (pts.length - 1) / (sampleCount - 1)).round());
    }

    // Use the midpoint for a single wind fetch (Open-Meteo rate limit).
    final mid = pts[pts.length ~/ 2];
    final wind = await _windService.getWind(mid);
    if (wind == null) return null;

    // Compute headwind score per segment.
    double totalScore = 0;
    int segCount = 0;
    for (int i = 0; i < indices.length - 1; i++) {
      final bearing = _bearing(pts[indices[i]], pts[indices[i + 1]]);
      totalScore += wind.headwindScore(bearing);
      segCount++;
    }
    if (segCount == 0) return null;

    final netScore = totalScore / segCount;
    final condition = netScore > 0.3
        ? WindCondition.tailwind
        : netScore < -0.3
            ? WindCondition.headwind
            : WindCondition.crosswind;

    return RouteWindScore(
      routeIndex: routeIndex,
      netScore: netScore,
      avgWindSpeedMs: wind.speedMs,
      samples: segCount,
      overallCondition: condition,
    );
  }

  /// Score all route alternatives and return them sorted by best effort
  /// (highest net score first = most tailwind).
  Future<List<RouteWindScore>> scoreAlternatives(
    List<RouteResult> routes,
  ) async {
    final scores = <RouteWindScore>[];
    for (int i = 0; i < routes.length; i++) {
      final s = await scoreRoute(routes[i], routeIndex: i);
      if (s != null) scores.add(s);
    }
    scores.sort((a, b) => b.netScore.compareTo(a.netScore));
    return scores;
  }

  /// Bearing between two LatLng points (0-360° clockwise from north).
  static double _bearing(LatLng a, LatLng b) {
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final windRoutingServiceProvider = Provider<WindRoutingService>((ref) {
  return WindRoutingService(ref.read(windServiceProvider));
});
