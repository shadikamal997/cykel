/// CYKEL — Ride Repository
/// Persists rides locally via SharedPreferences (JSON list, max 100 rides).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/ride.dart';

class RideRepository {
  static const _key = 'cykel_rides_v1';
  static const _maxRides = 100;

  Future<List<Ride>> getRides() async {
    final prefs = await SharedPreferences.getInstance();
    final strings = prefs.getStringList(_key) ?? [];
    return strings
        .map((s) {
          try {
            return Ride.fromJsonString(s);
          } catch (e) {
            // Log corrupted ride data for debugging
            debugPrint('[RideRepository] Failed to parse ride: $e');
            return null;
          }
        })
        .whereType<Ride>()
        .toList();
  }

  Future<void> saveRide(Ride ride) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];
    existing.insert(0, ride.toJsonString());
    await prefs.setStringList(_key, existing.take(_maxRides).toList());
  }

  Future<void> deleteRide(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];
    existing.removeWhere((s) {
      try {
        return Ride.fromJsonString(s).id == id;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_key, existing);
  }
}

final rideRepositoryProvider = Provider<RideRepository>(
  (_) => RideRepository(),
);
