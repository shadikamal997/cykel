/// CYKEL — Advanced Route Planning Providers
/// Riverpod providers for advanced route features

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/config/api_keys.dart';
import '../domain/advanced_route.dart';
import 'advanced_route_service.dart';
import 'elevation_service.dart';
import 'weather_service.dart';

// ─── Service Providers ──────────────────────────────────────────────────────

final elevationServiceProvider = Provider<ElevationService>((ref) {
  return ElevationService(
    apiKey: ApiKeys.googleMapsApiKey,
  );
});

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService(
    apiKey: ApiKeys.openWeatherMapApiKey,
  );
});

final advancedRouteServiceProvider = Provider<AdvancedRouteService>((ref) {
  return AdvancedRouteService(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    elevationService: ref.watch(elevationServiceProvider),
    weatherService: ref.watch(weatherServiceProvider),
  );
});

// ─── Route Providers ────────────────────────────────────────────────────────

/// Stream of all routes for current user
final userRoutesProvider = StreamProvider<List<AdvancedRoute>>((ref) {
  final service = ref.watch(advancedRouteServiceProvider);
  return service.getUserRoutes();
});

/// Stream of routes filtered by tag
final routesByTagProvider = StreamProvider.family<List<AdvancedRoute>, String>((ref, tag) {
  final service = ref.watch(advancedRouteServiceProvider);
  return service.getRoutesByTag(tag);
});

/// Get a specific route by ID
final routeProvider = FutureProvider.family<AdvancedRoute?, String>((ref, routeId) async {
  final service = ref.watch(advancedRouteServiceProvider);
  return service.getRoute(routeId);
});

/// Get all unique tags from user's routes
final routeTagsProvider = Provider<List<String>>((ref) {
  final routesAsync = ref.watch(userRoutesProvider);
  
  return routesAsync.when(
    data: (routes) {
      final allTags = <String>{};
      for (final route in routes) {
        allTags.addAll(route.tags);
      }
      return allTags.toList()..sort();
    },
    loading: () => [],
    error: (_, _) => [],
  );
});

// ─── Weather Providers ──────────────────────────────────────────────────────

/// Get weather forecasts for a route
final routeWeatherProvider = FutureProvider.family<List<WeatherForecast>, String>(
  (ref, routeId) async {
    final service = ref.watch(advancedRouteServiceProvider);
    final route = await service.getRoute(routeId);
    
    if (route == null) return [];
    
    return service.getRouteWeather(route);
  },
);

/// Get weather recommendations for a route
final routeWeatherRecommendationsProvider = FutureProvider.family<List<String>, String>(
  (ref, routeId) async {
    final service = ref.watch(advancedRouteServiceProvider);
    final route = await service.getRoute(routeId);
    
    if (route == null) return [];
    
    return service.getWeatherRecommendations(route);
  },
);

// ─── Statistics Providers ───────────────────────────────────────────────────

/// Get route statistics for current user
final routeStatisticsProvider = Provider<RouteStatistics>((ref) {
  final routesAsync = ref.watch(userRoutesProvider);
  
  return routesAsync.when(
    data: (routes) {
      if (routes.isEmpty) {
        return const RouteStatistics(
          totalRoutes: 0,
          totalDistanceKm: 0,
          totalElevationGainM: 0,
          averageDistanceKm: 0,
          averageDurationMinutes: 0,
        );
      }

      final totalDistance = routes.map((r) => r.totalDistanceKm).reduce((a, b) => a + b);
      final totalElevationGain = routes
          .where((r) => r.elevationProfile != null)
          .map((r) => r.elevationProfile!.totalElevationGainM)
          .fold(0.0, (a, b) => a + b);
      final totalDuration = routes
          .map((r) => r.estimatedDurationMinutes)
          .reduce((a, b) => a + b);

      return RouteStatistics(
        totalRoutes: routes.length,
        totalDistanceKm: totalDistance,
        totalElevationGainM: totalElevationGain,
        averageDistanceKm: totalDistance / routes.length,
        averageDurationMinutes: totalDuration ~/ routes.length,
      );
    },
    loading: () => const RouteStatistics(
      totalRoutes: 0,
      totalDistanceKm: 0,
      totalElevationGainM: 0,
      averageDistanceKm: 0,
      averageDurationMinutes: 0,
    ),
    error: (_, _) => const RouteStatistics(
      totalRoutes: 0,
      totalDistanceKm: 0,
      totalElevationGainM: 0,
      averageDistanceKm: 0,
      averageDurationMinutes: 0,
    ),
  );
});

// ─── Route Statistics Model ─────────────────────────────────────────────────

class RouteStatistics {
  const RouteStatistics({
    required this.totalRoutes,
    required this.totalDistanceKm,
    required this.totalElevationGainM,
    required this.averageDistanceKm,
    required this.averageDurationMinutes,
  });

  final int totalRoutes;
  final double totalDistanceKm;
  final double totalElevationGainM;
  final double averageDistanceKm;
  final int averageDurationMinutes;

  String get formattedTotalDistance {
    if (totalDistanceKm < 1) {
      return '${(totalDistanceKm * 1000).round()}m';
    }
    return '${totalDistanceKm.toStringAsFixed(1)}km';
  }

  String get formattedAverageDistance {
    if (averageDistanceKm < 1) {
      return '${(averageDistanceKm * 1000).round()}m';
    }
    return '${averageDistanceKm.toStringAsFixed(1)}km';
  }

  String get formattedAverageDuration {
    final hours = averageDurationMinutes ~/ 60;
    final minutes = averageDurationMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get formattedTotalElevationGain {
    return '${totalElevationGainM.round()}m';
  }
}
