/// CYKEL — Route Cache Service
///
/// Persists the active navigation state (route + step index + destination) to
/// SharedPreferences.  Used for two purposes:
///
///   1. **Offline continuation** — if the rider loses network mid-ride the app
///      already has the complete polyline and step list in memory; this cache
///      lets it survive an app restart too.
///
///   2. **Resume navigation** — if the app is killed and reopened during a
///      ride, the rider is prompted to continue from where they left off.
///
/// Data format: JSON encoded under key [_kKey].

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/discover/domain/route_result.dart';

const _kKey = 'nav_cache_v2';

/// Snapshot of the in-progress navigation state.
class CachedNavState {
  const CachedNavState({
    required this.route,
    required this.stepIndex,
    required this.destText,
    required this.destLat,
    required this.destLng,
    required this.cachedAt,
  });

  final RouteResult route;
  final int stepIndex;
  final String destText;
  final double destLat;
  final double destLng;
  final DateTime cachedAt;

  /// Returns false if the cache is older than [maxAge] (default 6 hours).
  bool isStillValid({Duration maxAge = const Duration(hours: 6)}) =>
      DateTime.now().difference(cachedAt) < maxAge;

  Map<String, dynamic> toJson() => {
        'route': route.toJson(),
        'stepIndex': stepIndex,
        'destText': destText,
        'destLat': destLat,
        'destLng': destLng,
        'cachedAt': cachedAt.toIso8601String(),
      };

  factory CachedNavState.fromJson(Map<String, dynamic> j) => CachedNavState(
        route: RouteResult.fromJson(j['route'] as Map<String, dynamic>),
        stepIndex: (j['stepIndex'] as num).toInt(),
        destText: j['destText'] as String? ?? '',
        destLat: (j['destLat'] as num).toDouble(),
        destLng: (j['destLng'] as num).toDouble(),
        cachedAt: DateTime.parse(j['cachedAt'] as String),
      );
}

// ─── Service ──────────────────────────────────────────────────────────────────

class RouteCacheService {
  /// Writes (or overwrites) the active navigation state.
  Future<void> save({
    required RouteResult route,
    required int stepIndex,
    required String destText,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final state = CachedNavState(
        route: route,
        stepIndex: stepIndex,
        destText: destText,
        destLat: destLat,
        destLng: destLng,
        cachedAt: DateTime.now(),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kKey, json.encode(state.toJson()));
    } catch (e) {
      debugPrint('RouteCacheService.save error: $e');
    }
  }

  /// Updates only the step index (cheap — avoids re-encoding the whole route).
  Future<void> updateStep(int stepIndex) async {
    try {
      final existing = await load();
      if (existing == null) return;
      await save(
        route: existing.route,
        stepIndex: stepIndex,
        destText: existing.destText,
        destLat: existing.destLat,
        destLng: existing.destLng,
      );
    } catch (e) {
      debugPrint('RouteCacheService.updateStep error: $e');
    }
  }

  /// Loads the last saved navigation state. Returns null if none / expired.
  Future<CachedNavState?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kKey);
      if (raw == null) return null;
      final state =
          CachedNavState.fromJson(json.decode(raw) as Map<String, dynamic>);
      return state.isStillValid() ? state : null;
    } catch (e) {
      debugPrint('RouteCacheService.load error: $e');
      return null;
    }
  }

  /// Deletes the cached navigation state (call when navigation ends normally).
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKey);
  }
}

final routeCacheServiceProvider =
    Provider<RouteCacheService>((ref) => RouteCacheService());
