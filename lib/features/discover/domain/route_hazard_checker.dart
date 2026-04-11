/// CYKEL — Route Hazard Checker (Phase 3)
///
/// Given a list of route polyline points and a list of crowd-reported hazard
/// reports, returns the subset of hazards that fall within [thresholdMeters]
/// of any point on the route.

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../discover/domain/crowd_hazard.dart';

/// Distance threshold in metres for a hazard to be considered "on route".
const double kRouteHazardThresholdMeters = 200.0;

/// Returns all [hazards] whose position is within [threshold] metres of at
/// least one point in [routePoints].
List<CrowdHazardReport> hazardsOnRoute({
  required List<LatLng> routePoints,
  required List<CrowdHazardReport> hazards,
  double threshold = kRouteHazardThresholdMeters,
}) {
  if (routePoints.isEmpty || hazards.isEmpty) return const [];

  return hazards.where((hazard) {
    for (final point in routePoints) {
      final dist = Geolocator.distanceBetween(
        point.latitude,
        point.longitude,
        hazard.lat,
        hazard.lng,
      );
      if (dist <= threshold) return true;
    }
    return false;
  }).toList();
}
