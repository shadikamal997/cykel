/// CYKEL — Advanced Route Service
/// Route optimization, waypoint management, and route creation

import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../domain/advanced_route.dart';
import 'elevation_service.dart';
import 'weather_service.dart';

enum RouteOptimizationStrategy {
  shortest,       // Minimize distance
  fastest,        // Minimize time
  easiest,        // Minimize elevation gain
  scenic,         // Prioritize scenic routes
  weatherOptimal; // Optimize for weather conditions

  String get displayName {
    switch (this) {
      case RouteOptimizationStrategy.shortest:
        return 'Shortest Distance';
      case RouteOptimizationStrategy.fastest:
        return 'Fastest Route';
      case RouteOptimizationStrategy.easiest:
        return 'Easiest (Less Climbing)';
      case RouteOptimizationStrategy.scenic:
        return 'Most Scenic';
      case RouteOptimizationStrategy.weatherOptimal:
        return 'Weather Optimal';
    }
  }

  String get icon {
    switch (this) {
      case RouteOptimizationStrategy.shortest:
        return '📏';
      case RouteOptimizationStrategy.fastest:
        return '⚡';
      case RouteOptimizationStrategy.easiest:
        return '🧘';
      case RouteOptimizationStrategy.scenic:
        return '🌄';
      case RouteOptimizationStrategy.weatherOptimal:
        return '🌤️';
    }
  }
}

class AdvancedRouteService {
  AdvancedRouteService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required this.elevationService,
    required this.weatherService,
  })  : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ElevationService elevationService;
  final WeatherService weatherService;

  String? get _currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _routesCollection =>
      _firestore.collection('advancedRoutes');

  // ─── Route Creation ─────────────────────────────────────────────────────────

  /// Create a new advanced route
  Future<AdvancedRoute> createRoute({
    required String name,
    required List<Waypoint> waypoints,
    bool isRoundTrip = false,
    List<String> tags = const [],
    String? notes,
    bool calculateElevation = true,
    bool fetchWeather = true,
  }) async {
    if (waypoints.length < 2) {
      throw ArgumentError('Route must have at least 2 waypoints (start and end)');
    }

    // Calculate total distance
    double totalDistance = 0.0;
    for (int i = 1; i < waypoints.length; i++) {
      totalDistance += _calculateDistance(
        waypoints[i - 1].location,
        waypoints[i].location,
      );
    }

    // Extract path points for elevation/weather
    final pathPoints = waypoints.map((w) => w.location).toList();

    // Calculate elevation profile if requested
    ElevationProfile? elevationProfile;
    if (calculateElevation) {
      elevationProfile = await elevationService.calculateElevationProfile(
        pathPoints: pathPoints,
      );
    }

    // Estimate duration
    final estimatedDuration = elevationProfile != null
        ? elevationService.estimateTime(
            distanceKm: totalDistance,
            elevationGainM: elevationProfile.totalElevationGainM,
          )
        : ((totalDistance / 18) * 60).round(); // Default: 18 km/h

    // Get weather forecast if requested
    WeatherForecast? weatherForecast;
    if (fetchWeather && pathPoints.isNotEmpty) {
      weatherForecast = await weatherService.getCurrentWeather(pathPoints.first);
    }

    final route = AdvancedRoute(
      id: '', // Will be set by Firestore
      name: name,
      waypoints: waypoints,
      totalDistanceKm: totalDistance,
      estimatedDurationMinutes: estimatedDuration,
      elevationProfile: elevationProfile,
      weatherForecast: weatherForecast,
      isRoundTrip: isRoundTrip,
      createdByUserId: _currentUserId,
      tags: tags,
      notes: notes,
      createdAt: DateTime.now(),
    );

    // Save to Firestore
    final docRef = await _routesCollection.add(route.toFirestore());
    return AdvancedRoute.fromFirestore(await docRef.get());
  }

  /// Update an existing route
  Future<void> updateRoute(AdvancedRoute route) async {
    await _routesCollection.doc(route.id).update(route.toFirestore());
  }

  /// Delete a route
  Future<void> deleteRoute(String routeId) async {
    await _routesCollection.doc(routeId).delete();
  }

  /// Get a route by ID
  Future<AdvancedRoute?> getRoute(String routeId) async {
    final doc = await _routesCollection.doc(routeId).get();
    if (!doc.exists) return null;
    return AdvancedRoute.fromFirestore(doc);
  }

  /// Get all routes for current user
  Stream<List<AdvancedRoute>> getUserRoutes() {
    if (_currentUserId == null) return Stream.value([]);

    return _routesCollection
        .where('createdByUserId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AdvancedRoute.fromFirestore(doc)).toList());
  }

  /// Get routes by tag
  Stream<List<AdvancedRoute>> getRoutesByTag(String tag) {
    if (_currentUserId == null) return Stream.value([]);

    return _routesCollection
        .where('createdByUserId', isEqualTo: _currentUserId)
        .where('tags', arrayContains: tag)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AdvancedRoute.fromFirestore(doc)).toList());
  }

  // ─── Waypoint Management ────────────────────────────────────────────────────

  /// Add a waypoint to a route
  Future<AdvancedRoute> addWaypoint({
    required AdvancedRoute route,
    required Waypoint waypoint,
  }) async {
    final updatedWaypoints = List<Waypoint>.from(route.waypoints);
    updatedWaypoints.add(waypoint);

    // Recalculate route with new waypoint
    return _recalculateRoute(route, updatedWaypoints);
  }

  /// Remove a waypoint from a route
  Future<AdvancedRoute> removeWaypoint({
    required AdvancedRoute route,
    required int waypointIndex,
  }) async {
    if (waypointIndex < 0 || waypointIndex >= route.waypoints.length) {
      throw ArgumentError('Invalid waypoint index');
    }

    final updatedWaypoints = List<Waypoint>.from(route.waypoints);
    updatedWaypoints.removeAt(waypointIndex);

    if (updatedWaypoints.length < 2) {
      throw ArgumentError('Route must have at least 2 waypoints');
    }

    return _recalculateRoute(route, updatedWaypoints);
  }

  /// Reorder waypoints
  Future<AdvancedRoute> reorderWaypoints({
    required AdvancedRoute route,
    required List<int> newOrder,
  }) async {
    if (newOrder.length != route.waypoints.length) {
      throw ArgumentError('New order must contain all waypoints');
    }

    final updatedWaypoints = newOrder
        .map((index) => route.waypoints[index].copyWith(order: newOrder.indexOf(index)))
        .toList();

    return _recalculateRoute(route, updatedWaypoints);
  }

  /// Update a waypoint
  Future<AdvancedRoute> updateWaypoint({
    required AdvancedRoute route,
    required int waypointIndex,
    required Waypoint updatedWaypoint,
  }) async {
    if (waypointIndex < 0 || waypointIndex >= route.waypoints.length) {
      throw ArgumentError('Invalid waypoint index');
    }

    final updatedWaypoints = List<Waypoint>.from(route.waypoints);
    updatedWaypoints[waypointIndex] = updatedWaypoint;

    return _recalculateRoute(route, updatedWaypoints);
  }

  // ─── Route Optimization ─────────────────────────────────────────────────────

  /// Optimize waypoint order using specified strategy
  Future<AdvancedRoute> optimizeRoute({
    required AdvancedRoute route,
    required RouteOptimizationStrategy strategy,
  }) async {
    // Extract start and end waypoints
    final start = route.waypoints.firstWhere((w) => w.type == WaypointType.start);
    final end = route.waypoints.firstWhere((w) => w.type == WaypointType.end);
    
    // Get intermediate waypoints (excluding start and end)
    final intermediateWaypoints = route.waypoints
        .where((w) => w.type != WaypointType.start && w.type != WaypointType.end)
        .toList();

    if (intermediateWaypoints.isEmpty) {
      return route; // Nothing to optimize
    }

    // Optimize intermediate waypoints based on strategy
    List<Waypoint> optimizedIntermediates;

    switch (strategy) {
      case RouteOptimizationStrategy.shortest:
        optimizedIntermediates = await _optimizeForDistance(
          start: start.location,
          end: end.location,
          waypoints: intermediateWaypoints,
        );
        break;

      case RouteOptimizationStrategy.fastest:
        // For fastest, we'll use similar logic to shortest but could
        // incorporate traffic data in the future
        optimizedIntermediates = await _optimizeForDistance(
          start: start.location,
          end: end.location,
          waypoints: intermediateWaypoints,
        );
        break;

      case RouteOptimizationStrategy.easiest:
        // Optimize to minimize total elevation gain
        // For now, use distance-based optimization
        // TODO: Incorporate elevation data
        optimizedIntermediates = await _optimizeForDistance(
          start: start.location,
          end: end.location,
          waypoints: intermediateWaypoints,
        );
        break;

      default:
        optimizedIntermediates = intermediateWaypoints;
    }

    // Reconstruct waypoints with correct order
    final optimizedWaypoints = <Waypoint>[
      start.copyWith(order: 0),
      ...optimizedIntermediates.asMap().entries.map((e) => 
        e.value.copyWith(order: e.key + 1)),
      end.copyWith(order: optimizedIntermediates.length + 1),
    ];

    return _recalculateRoute(route, optimizedWaypoints);
  }

  /// Optimize waypoints for shortest total distance (Traveling Salesman Problem)
  /// 
  /// Uses nearest neighbor heuristic for efficiency
  /// For small number of waypoints (<10), this gives good results
  Future<List<Waypoint>> _optimizeForDistance({
    required LatLng start,
    required LatLng end,
    required List<Waypoint> waypoints,
  }) async {
    if (waypoints.isEmpty) return [];
    if (waypoints.length == 1) return waypoints;

    final optimized = <Waypoint>[];
    final remaining = List<Waypoint>.from(waypoints);
    LatLng currentLocation = start;

    // Nearest neighbor algorithm
    while (remaining.isNotEmpty) {
      double minDistance = double.infinity;
      int nearestIndex = 0;

      for (int i = 0; i < remaining.length; i++) {
        final distance = _calculateDistance(currentLocation, remaining[i].location);
        if (distance < minDistance) {
          minDistance = distance;
          nearestIndex = i;
        }
      }

      final nearest = remaining.removeAt(nearestIndex);
      optimized.add(nearest);
      currentLocation = nearest.location;
    }

    return optimized;
  }

  /// Recalculate route metrics after waypoint changes
  Future<AdvancedRoute> _recalculateRoute(
    AdvancedRoute route,
    List<Waypoint> newWaypoints,
  ) async {
    // Calculate new total distance
    double totalDistance = 0.0;
    for (int i = 1; i < newWaypoints.length; i++) {
      totalDistance += _calculateDistance(
        newWaypoints[i - 1].location,
        newWaypoints[i].location,
      );
    }

    // Recalculate elevation if it existed
    ElevationProfile? elevationProfile;
    if (route.hasElevationData) {
      final pathPoints = newWaypoints.map((w) => w.location).toList();
      elevationProfile = await elevationService.calculateElevationProfile(
        pathPoints: pathPoints,
      );
    }

    // Estimate duration
    final estimatedDuration = elevationProfile != null
        ? elevationService.estimateTime(
            distanceKm: totalDistance,
            elevationGainM: elevationProfile.totalElevationGainM,
          )
        : ((totalDistance / 18) * 60).round();

    final updatedRoute = route.copyWith(
      waypoints: newWaypoints,
      totalDistanceKm: totalDistance,
      estimatedDurationMinutes: estimatedDuration,
      elevationProfile: elevationProfile,
    );

    // Update in Firestore
    await updateRoute(updatedRoute);

    return updatedRoute;
  }

  // ─── Weather Integration ────────────────────────────────────────────────────

  /// Refresh weather data for a route
  Future<AdvancedRoute> refreshWeather(AdvancedRoute route) async {
    final pathPoints = route.waypoints.map((w) => w.location).toList();
    
    if (pathPoints.isEmpty) return route;

    final weatherForecast = await weatherService.getCurrentWeather(pathPoints.first);

    final updatedRoute = route.copyWith(weatherForecast: weatherForecast);
    await updateRoute(updatedRoute);

    return updatedRoute;
  }

  /// Get weather along entire route
  Future<List<WeatherForecast>> getRouteWeather(AdvancedRoute route) async {
    final pathPoints = route.waypoints.map((w) => w.location).toList();
    
    return weatherService.getWeatherAlongRoute(
      routePoints: pathPoints,
      departureTime: DateTime.now(),
    );
  }

  /// Get weather recommendations for a route
  Future<List<String>> getWeatherRecommendations(AdvancedRoute route) async {
    final forecasts = await getRouteWeather(route);
    return weatherService.getWeatherRecommendations(forecasts);
  }

  // ─── Utilities ──────────────────────────────────────────────────────────────

  /// Calculate distance between two points (Haversine formula)
  double _calculateDistance(LatLng point1, LatLng point2) {
    const earthRadiusKm = 6371.0;

    final lat1Rad = point1.latitude * (math.pi / 180);
    final lat2Rad = point2.latitude * (math.pi / 180);
    final deltaLat = (point2.latitude - point1.latitude) * (math.pi / 180);
    final deltaLng = (point2.longitude - point1.longitude) * (math.pi / 180);

    final a = math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.pow(math.sin(deltaLng / 2), 2);
    final c = 2 * math.asin(math.sqrt(a));

    return earthRadiusKm * c;
  }
}
