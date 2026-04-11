/// CYKEL — AI Route Suggestions Provider
/// Smart route recommendations using rule-based AI

import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../auth/providers/auth_providers.dart';
import '../domain/route_suggestion.dart';

// ─── Route AI Service ─────────────────────────────────────────────────────────

class RouteAIService {
  RouteAIService(this._firestore);

  final FirebaseFirestore _firestore;

  // ─── Route History ──────────────────────────────────────────────────────────

  /// Track a completed route
  Future<void> trackRoute({
    required String uid,
    required LatLng startLocation,
    required LatLng endLocation,
    required int durationMinutes,
    String? startAddress,
    String? endAddress,
    String? polyline,
  }) async {
    final timeOfDay = TimeOfDay.fromHour(DateTime.now().hour);
    
    // Check if similar route exists (within ~200m start and end)
    final existing = await _findSimilarRoute(uid, startLocation, endLocation);
    
    if (existing != null) {
      // Update existing route
      final newAvgDuration = ((existing.averageDurationMinutes * existing.usageCount) + durationMinutes) ~/ (existing.usageCount + 1);
      final todCounts = Map<TimeOfDay, int>.from(existing.timeOfDayCounts);
      todCounts[timeOfDay] = (todCounts[timeOfDay] ?? 0) + 1;

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('routeHistory')
          .doc(existing.id)
          .update({
        'usageCount': FieldValue.increment(1),
        'lastUsedAt': FieldValue.serverTimestamp(),
        'averageDurationMinutes': newAvgDuration,
        'timeOfDayCounts': todCounts.map((k, v) => MapEntry(k.name, v)),
      });
    } else {
      // Create new route history entry
      final history = RouteHistory(
        id: '',
        startLocation: startLocation,
        endLocation: endLocation,
        startAddress: startAddress,
        endAddress: endAddress,
        usageCount: 1,
        lastUsedAt: DateTime.now(),
        averageDurationMinutes: durationMinutes,
        polyline: polyline,
        timeOfDayCounts: {timeOfDay: 1},
      );

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('routeHistory')
          .add(history.toFirestore());
    }
  }

  Future<RouteHistory?> _findSimilarRoute(String uid, LatLng start, LatLng end) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('routeHistory')
        .get();

    for (final doc in snapshot.docs) {
      final history = RouteHistory.fromFirestore(doc);
      final startDist = _haversineDistance(start, history.startLocation);
      final endDist = _haversineDistance(end, history.endLocation);

      // Within 200m for both start and end
      if (startDist < 0.2 && endDist < 0.2) {
        return history;
      }
    }
    return null;
  }

  /// Get user's route history
  Stream<List<RouteHistory>> watchRouteHistory(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('routeHistory')
        .orderBy('lastUsedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(RouteHistory.fromFirestore).toList());
  }

  // ─── Route Settings ─────────────────────────────────────────────────────────

  /// Get user's route settings
  Future<RouteSettings> getRouteSettings(String uid) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('routes')
        .get();

    if (!doc.exists) return const RouteSettings();
    return RouteSettings.fromFirestore(doc.data()!);
  }

  /// Update route settings
  Future<void> updateRouteSettings(String uid, RouteSettings settings) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('routes')
        .set(settings.toFirestore());
  }

  // ─── AI Suggestions ─────────────────────────────────────────────────────────

  /// Generate route suggestions based on context
  Future<List<RouteSuggestion>> getSuggestions({
    required String uid,
    required LatLng currentLocation,
    WeatherCondition? weather,
    int? windSpeedKmh,
    double? windDirectionDeg,
  }) async {
    final settings = await getRouteSettings(uid);
    final historySnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('routeHistory')
        .orderBy('usageCount', descending: true)
        .limit(20)
        .get();

    final histories = historySnapshot.docs.map(RouteHistory.fromFirestore).toList();
    final currentHour = DateTime.now().hour;
    final currentTimeOfDay = TimeOfDay.fromHour(currentHour);

    final suggestions = <RouteSuggestion>[];

    // Generate suggestions from history
    for (final history in histories) {
      final score = _calculateScore(
        history: history,
        currentLocation: currentLocation,
        currentTimeOfDay: currentTimeOfDay,
        settings: settings,
        weather: weather,
      );

      if (score > 30) {
        final reasons = _determineReasons(
          history: history,
          currentTimeOfDay: currentTimeOfDay,
          settings: settings,
          weather: weather,
        );

        suggestions.add(RouteSuggestion(
          id: history.id,
          name: _generateRouteName(history),
          startLocation: history.startLocation,
          endLocation: history.endLocation,
          startAddress: history.startAddress,
          endAddress: history.endAddress,
          estimatedDurationMinutes: history.averageDurationMinutes,
          estimatedDistanceKm: _haversineDistance(history.startLocation, history.endLocation) * 1.3, // Adjust for road distance
          reasons: reasons,
          score: score,
          polyline: history.polyline,
        ));
      }
    }

    // Sort by score
    suggestions.sort((a, b) => b.score.compareTo(a.score));
    return suggestions.take(5).toList();
  }

  double _calculateScore({
    required RouteHistory history,
    required LatLng currentLocation,
    required TimeOfDay currentTimeOfDay,
    required RouteSettings settings,
    WeatherCondition? weather,
  }) {
    double score = 0;

    // Base score from usage (max 30 points)
    score += math.min(history.usageCount * 5.0, 30);

    // Recency bonus (max 20 points)
    final daysSince = DateTime.now().difference(history.lastUsedAt).inDays;
    if (daysSince <= 7) {
      score += 20 - (daysSince * 2);
    }

    // Time of day match (max 25 points)
    if (settings.timeBasedSuggestions) {
      final todCount = history.timeOfDayCounts[currentTimeOfDay] ?? 0;
      final totalCount = history.usageCount;
      if (totalCount > 0) {
        final todPercentage = todCount / totalCount;
        score += todPercentage * 25;
      }
    }

    // Proximity to current location (max 15 points)
    final startDist = _haversineDistance(currentLocation, history.startLocation);
    if (startDist < 0.5) {
      score += 15;
    } else if (startDist < 1.0) {
      score += 10;
    } else if (startDist < 2.0) {
      score += 5;
    }

    // Weather considerations (max 10 points)
    if (settings.weatherBasedSuggestions && weather != null) {
      final distance = _haversineDistance(history.startLocation, history.endLocation);
      
      if (weather == WeatherCondition.rainy || weather == WeatherCondition.snowy) {
        // Prefer shorter routes in bad weather
        if (distance < 3) {
          score += 10;
        } else if (distance < 5) {
          score += 5;
        }
      } else if (weather == WeatherCondition.sunny) {
        // Might prefer scenic routes
        if (settings.preferences.contains(RoutePreference.scenic)) {
          score += 5;
        }
      }
    }

    return math.min(score, 100);
  }

  List<SuggestionReason> _determineReasons({
    required RouteHistory history,
    required TimeOfDay currentTimeOfDay,
    required RouteSettings settings,
    WeatherCondition? weather,
  }) {
    final reasons = <SuggestionReason>[];

    // Frequently used
    if (history.usageCount >= 5) {
      reasons.add(SuggestionReason.frequentlyUsed);
    }

    // Time-based
    final todCount = history.timeOfDayCounts[currentTimeOfDay] ?? 0;
    if (todCount >= 3 && history.usageCount > 0) {
      final percentage = todCount / history.usageCount;
      if (percentage > 0.4) {
        reasons.add(SuggestionReason.commuteTime);
      }
    }

    // Weather-based
    if (weather != null && settings.weatherBasedSuggestions) {
      final distance = _haversineDistance(history.startLocation, history.endLocation);
      if ((weather == WeatherCondition.rainy || weather == WeatherCondition.windy) && distance < 5) {
        reasons.add(SuggestionReason.optimalForWeather);
      }
    }

    // Based on history
    if (history.usageCount >= 3) {
      reasons.add(SuggestionReason.basedOnHistory);
    }

    // Night time - prefer lit routes
    if ((currentTimeOfDay == TimeOfDay.night || currentTimeOfDay == TimeOfDay.evening) &&
        settings.preferLitRoutes) {
      reasons.add(SuggestionReason.wellLit);
    }

    // Quickest (if user prefers fastest)
    if (settings.preferences.contains(RoutePreference.fastest)) {
      reasons.add(SuggestionReason.quickest);
    }

    // Bike lanes
    if (settings.preferBikeLanes) {
      reasons.add(SuggestionReason.moreBikeLanes);
    }

    // Ensure at least one reason
    if (reasons.isEmpty) {
      reasons.add(SuggestionReason.basedOnHistory);
    }

    return reasons.take(3).toList();
  }

  String _generateRouteName(RouteHistory history) {
    if (history.startAddress != null && history.endAddress != null) {
      final start = _shortenAddress(history.startAddress!);
      final end = _shortenAddress(history.endAddress!);
      return '$start → $end';
    }
    return 'Rute ${history.id.substring(0, 6)}';
  }

  String _shortenAddress(String address) {
    // Get first meaningful part
    final parts = address.split(',');
    if (parts.isEmpty) return address;
    return parts.first.trim();
  }

  // ─── Saved Routes ───────────────────────────────────────────────────────────

  /// Save a route
  Future<void> saveRoute({
    required String uid,
    required String name,
    required LatLng startLocation,
    required LatLng endLocation,
    String? startAddress,
    String? endAddress,
    String? polyline,
    double? distanceKm,
    int? estimatedDurationMinutes,
    String? notes,
    List<String> tags = const [],
  }) async {
    final route = SavedRoute(
      id: '',
      name: name,
      startLocation: startLocation,
      endLocation: endLocation,
      startAddress: startAddress,
      endAddress: endAddress,
      polyline: polyline,
      distanceKm: distanceKm,
      estimatedDurationMinutes: estimatedDurationMinutes,
      createdAt: DateTime.now(),
      notes: notes,
      tags: tags,
    );

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('savedRoutes')
        .add(route.toFirestore());
  }

  /// Get user's saved routes
  Stream<List<SavedRoute>> watchSavedRoutes(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('savedRoutes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(SavedRoute.fromFirestore).toList());
  }

  /// Delete saved route
  Future<void> deleteSavedRoute(String uid, String routeId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('savedRoutes')
        .doc(routeId)
        .delete();
  }

  // ─── Helper Functions ───────────────────────────────────────────────────────

  /// Calculate distance between two points using Haversine formula
  double _haversineDistance(LatLng point1, LatLng point2) {
    const earthRadius = 6371.0; // km

    final lat1 = point1.latitude * math.pi / 180;
    final lat2 = point2.latitude * math.pi / 180;
    final dLat = (point2.latitude - point1.latitude) * math.pi / 180;
    final dLon = (point2.longitude - point1.longitude) * math.pi / 180;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final routeAIServiceProvider = Provider<RouteAIService>((ref) {
  return RouteAIService(FirebaseFirestore.instance);
});

/// User's route history
final routeHistoryProvider = StreamProvider<List<RouteHistory>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(routeAIServiceProvider).watchRouteHistory(user.uid);
});

/// User's saved routes
final savedRoutesProvider = StreamProvider<List<SavedRoute>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(routeAIServiceProvider).watchSavedRoutes(user.uid);
});

/// Route settings
final routeSettingsProvider = FutureProvider<RouteSettings>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const RouteSettings();
  return ref.watch(routeAIServiceProvider).getRouteSettings(user.uid);
});

/// Route suggestions (computed on demand)
final routeSuggestionsProvider = FutureProvider.family<List<RouteSuggestion>, LatLng>((ref, currentLocation) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  // TODO: Get actual weather data
  return ref.watch(routeAIServiceProvider).getSuggestions(
    uid: user.uid,
    currentLocation: currentLocation,
    weather: WeatherCondition.sunny, // Default for now
  );
});
