/// CYKEL Route Heat Map Service
/// Generates heat maps showing popular cycling routes based on user activity
/// Uses ride history data to visualize frequently used paths

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class RouteHeatPoint {
  final LatLng location;
  final int frequency; // How many times this point was used
  final double intensity; // 0.0 to 1.0

  RouteHeatPoint({
    required this.location,
    required this.frequency,
    required this.intensity,
  });

  Color get heatColor {
    // Blue (cold) -> Green -> Yellow -> Red (hot)
    if (intensity < 0.2) return const Color(0xFF0000FF).withOpacity(0.3);
    if (intensity < 0.4) return const Color(0xFF00FFFF).withOpacity(0.4);
    if (intensity < 0.6) return const Color(0xFF00FF00).withOpacity(0.5);
    if (intensity < 0.8) return const Color(0xFFFFFF00).withOpacity(0.6);
    return const Color(0xFFFF0000).withOpacity(0.7);
  }
}

class RouteHeatMapService {
  RouteHeatMapService._();
  static final instance = RouteHeatMapService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate heat map from saved routes (Quick Routes, Favorite Routes)
  /// Since ride tracking is not yet implemented, use saved destinations
  Future<List<RouteHeatPoint>> generateHeatMap({
    required LatLng center,
    double radiusKm = 25.0,
  }) async {
    try {
      // Get all saved routes for all users (or current user only)
      // For MVP, use quick routes and frequent destinations
      final quickRoutesSnapshot = await _firestore
          .collection('users')
          .get();

      final heatPoints = <String, int>{}; // Grid cell ID -> frequency
      
      for (final userDoc in quickRoutesSnapshot.docs) {
        final userData = userDoc.data();
        
        // Check Quick Routes (home, work, etc.)
        final quickRoutes = userData['quickRoutes'] as Map<String, dynamic>?;
        if (quickRoutes != null) {
          for (final route in quickRoutes.values) {
            if (route is Map<String, dynamic>) {
              final lat = route['lat'] as double?;
              final lng = route['lng'] as double?;
              if (lat != null && lng != null) {
                final cellId = _getCellId(LatLng(lat, lng), gridSizeMeters: 100);
                heatPoints[cellId] = (heatPoints[cellId] ?? 0) + 1;
              }
            }
          }
        }
      }

      // Convert to heat points with intensity
      final maxFrequency = heatPoints.values.isEmpty 
          ? 1 
          : heatPoints.values.reduce(math.max);

      final results = <RouteHeatPoint>[];
      
      for (final entry in heatPoints.entries) {
        final location = _getCellCenter(entry.key);
        if (_isWithinRadius(location, center, radiusKm)) {
          results.add(RouteHeatPoint(
            location: location,
            frequency: entry.value,
            intensity: entry.value / maxFrequency,
          ));
        }
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  /// Generate heat map polylines for route visualization
  List<Polyline> getHeatMapPolylines(List<RouteHeatPoint> heatPoints) {
    if (heatPoints.length < 2) return [];

    final polylines = <Polyline>[];
    
    // Group nearby points and create polylines
    final sorted = List<RouteHeatPoint>.from(heatPoints)
      ..sort((a, b) => b.intensity.compareTo(a.intensity));

    for (int i = 0; i < sorted.length - 1; i++) {
      final current = sorted[i];
      final next = sorted[i + 1];

      // Only connect very close points (same route segment)
      final distance = _calculateDistance(current.location, next.location);
      if (distance < 200) { // 200m max connection
        polylines.add(Polyline(
          polylineId: PolylineId('heat_$i'),
          points: [current.location, next.location],
          color: current.heatColor,
          width: 4,
          endCap: Cap.roundCap,
          startCap: Cap.roundCap,
        ));
      }
    }

    return polylines;
  }

  /// Get heat map as circles (alternative to polylines)
  Set<Circle> getHeatMapCircles(List<RouteHeatPoint> heatPoints) {
    return heatPoints.map((point) {
      final radius = 50.0 + (point.intensity * 150.0); // 50-200m radius

      return Circle(
        circleId: CircleId('heat_${point.location.latitude}_${point.location.longitude}'),
        center: point.location,
        radius: radius,
        fillColor: point.heatColor,
        strokeWidth: 0,
      );
    }).toSet();
  }

  /// Get popular routes from provider navigation requests
  Future<List<RouteHeatPoint>> getPopularDestinations({
    required LatLng center,
    double radiusKm = 25.0,
    int minVisits = 3,
  }) async {
    try {
      // Get provider locations weighted by navigation requests
      final providersSnapshot = await _firestore
          .collection('providers')
          .where('isActive', isEqualTo: true)
          .get();

      final results = <RouteHeatPoint>[];
      int maxNavRequests = 1;

      for (final doc in providersSnapshot.docs) {
        final data = doc.data();
        final lat = data['latitude'] as double?;
        final lng = data['longitude'] as double?;
        final navRequests = data['navigationRequests'] as int? ?? 0;

        if (lat != null && lng != null && navRequests >= minVisits) {
          final location = LatLng(lat, lng);
          
          if (_isWithinRadius(location, center, radiusKm)) {
            if (navRequests > maxNavRequests) {
              maxNavRequests = navRequests;
            }

            results.add(RouteHeatPoint(
              location: location,
              frequency: navRequests,
              intensity: 0, // Will be calculated after finding max
            ));
          }
        }
      }

      // Normalize intensity
      return results.map((point) => RouteHeatPoint(
        location: point.location,
        frequency: point.frequency,
        intensity: point.frequency / maxNavRequests,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  // ─── Private Helpers ──────────────────────────────────────────────────────

  String _getCellId(LatLng location, {required double gridSizeMeters}) {
    // Create grid cells in degrees (approximate)
    final cellSizeDegrees = gridSizeMeters / 111000; // ~111km per degree
    final latCell = (location.latitude / cellSizeDegrees).floor();
    final lngCell = (location.longitude / cellSizeDegrees).floor();
    return '$latCell,$lngCell';
  }

  LatLng _getCellCenter(String cellId) {
    final parts = cellId.split(',');
    final latCell = int.parse(parts[0]);
    final lngCell = int.parse(parts[1]);
    const cellSizeDegrees = 100 / 111000;
    
    return LatLng(
      latCell * cellSizeDegrees + cellSizeDegrees / 2,
      lngCell * cellSizeDegrees + cellSizeDegrees / 2,
    );
  }

  bool _isWithinRadius(LatLng point, LatLng center, double radiusKm) {
    return _calculateDistance(point, center) <= radiusKm * 1000;
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
