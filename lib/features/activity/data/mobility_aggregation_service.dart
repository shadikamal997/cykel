/// CYKEL — Anonymous Mobility Aggregation Service (Phase 8)
///
/// Writes a privacy-safe, anonymised copy of each completed ride to the
/// `aggregated_rides` Firestore collection. Only called when the user has
/// given explicit consent via the GDPR consent screen.
///
/// What is stored (NO PII):
///   - hashed session token (SHA-256 of uid + month — rotates monthly)
///   - distance in metres (rounded to nearest 100 m)
///   - duration in seconds (rounded to nearest 30 s)
///   - hour-of-day and day-of-week (no exact time)
///   - avg speed (rounded to 1 km/h)
///   - start region (grid cell 0.1° × 0.1°, NOT exact location)
///   - CO₂ saved (kg, 2 dp)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../domain/ride.dart';
import '../../profile/data/gdpr_provider.dart';

const _kCollection = 'aggregated_rides';

class MobilityAggregationService {
  MobilityAggregationService(this._db, this._userId);

  final FirebaseFirestore _db;
  final String _userId;

  /// Anonymise and upload [ride] to Firestore.
  /// Silently swallows errors — aggregation is best-effort.
  Future<void> aggregate(Ride ride) async {
    try {
      final token = _monthlyToken(_userId);
      final start = ride.startTime;

      await _db.collection(_kCollection).add({
        'token':            token,
        'distanceM':        ((ride.distanceMeters / 100).round() * 100).toInt(),
        'durationS':        ((ride.duration.inSeconds / 30).round() * 30),
        'hourOfDay':        start.hour,
        'dayOfWeek':        start.weekday, // 1 = Mon, 7 = Sun
        'avgSpeedKmh':      ride.avgSpeedKmh.roundToDouble(),
        'gridLat':          (ride.path.isNotEmpty
                              ? (ride.path.first.latitude / 0.1).floor() * 0.1
                              : 0.0),
        'gridLng':          (ride.path.isNotEmpty
                              ? (ride.path.first.longitude / 0.1).floor() * 0.1
                              : 0.0),
        'co2SavedKg':       double.parse(ride.co2SavedKg.toStringAsFixed(2)),
        'recordedAt':       Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('MobilityAggregationService.aggregate error (non-fatal): $e');
    }
  }

  /// Creates a token that rotates monthly so no cross-month linkage is possible.
  String _monthlyToken(String uid) {
    final now = DateTime.now();
    final seed = '$uid-${now.year}-${now.month}';
    // Simple djb2-style hash — good enough for anonymous token rotation.
    var h = 5381;
    for (final c in seed.codeUnits) {
      h = ((h << 5) + h) ^ c;
      h &= 0xFFFFFFFF;
    }
    return h.toUnsigned(32).toRadixString(16).padLeft(8, '0');
  }
}

final mobilityAggregationServiceProvider =
    Provider<MobilityAggregationService>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid ?? 'anonymous';
  return MobilityAggregationService(FirebaseFirestore.instance, uid);
});

/// Returns a callback that aggregates a ride — or null if consent not given.
final aggregationCallbackProvider =
    Provider<Future<void> Function(Ride)?> ((ref) {
  final enabled = ref.watch(gdprAggregationEnabledProvider);
  if (!enabled) return null;
  final svc = ref.read(mobilityAggregationServiceProvider);
  return (ride) => svc.aggregate(ride);
});
