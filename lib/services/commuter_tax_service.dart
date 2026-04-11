/// CYKEL — Commuter Tax Tracking Service (Phase 8.6)
///
/// Auto-detects commute rides (Home ↔ Work pattern) and calculates
/// annual km for Danish commuter tax deduction (kørselsfradrag).
///
/// Denmark rule: tax deduction applies after 24 km/day (round trip).
/// Rate: 2.25 DKK/km (2026) for km above the threshold.
///
/// Data stored locally in SharedPreferences; users can export a yearly report.

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/denmark_constants.dart';
import '../features/activity/domain/ride.dart';

const _kCommuteLogKey = 'cykel_commute_log_v1';

// ─── Domain Models ───────────────────────────────────────────────────────────

class CommuteTrip {
  const CommuteTrip({
    required this.date,
    required this.distanceKm,
    required this.rideId,
    required this.direction,
  });

  final DateTime date;
  final double distanceKm;
  final String rideId;
  final CommuteDirection direction;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'distanceKm': distanceKm,
        'rideId': rideId,
        'direction': direction.name,
      };

  factory CommuteTrip.fromJson(Map<String, dynamic> m) => CommuteTrip(
        date: DateTime.parse(m['date'] as String),
        distanceKm: (m['distanceKm'] as num).toDouble(),
        rideId: m['rideId'] as String,
        direction: CommuteDirection.values.firstWhere(
          (d) => d.name == m['direction'],
          orElse: () => CommuteDirection.toWork,
        ),
      );
}

enum CommuteDirection { toWork, toHome }

class TaxDeductionSummary {
  const TaxDeductionSummary({
    required this.year,
    required this.totalCommuteDays,
    required this.totalCommuteKm,
    required this.deductibleKm,
    required this.estimatedDeductionDkk,
    required this.trips,
  });

  final int year;
  final int totalCommuteDays;
  final double totalCommuteKm;
  /// Km eligible for deduction (after 24 km/day threshold per day).
  final double deductibleKm;
  /// Estimated tax deduction in DKK.
  final double estimatedDeductionDkk;
  final List<CommuteTrip> trips;

  /// CSV export for annual tax filing.
  String toCsv() {
    final sb = StringBuffer();
    sb.writeln('Date,Distance (km),Direction,Ride ID');
    for (final t in trips) {
      sb.writeln(
          '${t.date.toIso8601String().substring(0, 10)},${t.distanceKm.toStringAsFixed(1)},${t.direction.name},${t.rideId}');
    }
    sb.writeln();
    sb.writeln('Year,$year');
    sb.writeln('Total commute days,$totalCommuteDays');
    sb.writeln('Total commute km,${totalCommuteKm.toStringAsFixed(1)}');
    sb.writeln('Deductible km,${deductibleKm.toStringAsFixed(1)}');
    sb.writeln('Estimated deduction DKK,${estimatedDeductionDkk.toStringAsFixed(0)}');
    return sb.toString();
  }
}

// ─── Service ─────────────────────────────────────────────────────────────────

class CommuterTaxService {
  /// Proximity threshold: consider a ride endpoint "at" home/work
  /// if within 500 m.
  static const double _proximityKm = 0.5;

  /// Check if a completed ride is a commute trip and record it.
  ///
  /// Returns the detected [CommuteTrip] or null if not a commute ride.
  Future<CommuteTrip?> detectAndRecord({
    required Ride ride,
    required LatLng? homeLocation,
    required LatLng? workLocation,
  }) async {
    if (homeLocation == null || workLocation == null) return null;
    if (ride.path.length < 2) return null;

    final start = ride.path.first;
    final end = ride.path.last;

    // Home → Work
    if (_isNear(start, homeLocation) && _isNear(end, workLocation)) {
      final trip = CommuteTrip(
        date: ride.startTime,
        distanceKm: ride.distanceMeters / 1000,
        rideId: ride.id,
        direction: CommuteDirection.toWork,
      );
      await _saveTrip(trip);
      return trip;
    }

    // Work → Home
    if (_isNear(start, workLocation) && _isNear(end, homeLocation)) {
      final trip = CommuteTrip(
        date: ride.startTime,
        distanceKm: ride.distanceMeters / 1000,
        rideId: ride.id,
        direction: CommuteDirection.toHome,
      );
      await _saveTrip(trip);
      return trip;
    }

    return null;
  }

  /// Get all commute trips for a given year.
  Future<List<CommuteTrip>> getTrips({int? year}) async {
    final y = year ?? DateTime.now().year;
    final all = await _loadAll();
    return all.where((t) => t.date.year == y).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Calculate the tax deduction summary for a given year.
  Future<TaxDeductionSummary> calculateDeduction({int? year}) async {
    final y = year ?? DateTime.now().year;
    final trips = await getTrips(year: y);

    // Group trips by date (day) to compute daily round-trip distances.
    final Map<String, double> dailyKm = {};
    for (final t in trips) {
      final dayKey =
          '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
      dailyKm[dayKey] = (dailyKm[dayKey] ?? 0) + t.distanceKm;
    }

    double totalKm = 0;
    double deductibleKm = 0;
    for (final entry in dailyKm.entries) {
      totalKm += entry.value;
      // Deduction only applies to km above the 24 km/day threshold.
      if (entry.value > DenmarkConstants.taxDeductionMinKmPerDay) {
        deductibleKm +=
            entry.value - DenmarkConstants.taxDeductionMinKmPerDay;
      }
    }

    return TaxDeductionSummary(
      year: y,
      totalCommuteDays: dailyKm.length,
      totalCommuteKm: totalKm,
      deductibleKm: deductibleKm,
      estimatedDeductionDkk:
          deductibleKm * DenmarkConstants.taxDeductionRateKm,
      trips: trips,
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCommuteLogKey);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  bool _isNear(LatLng a, LatLng b) {
    return _distanceKm(a, b) <= _proximityKm;
  }

  /// Haversine distance in km.
  static double _distanceKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final sinLat = math.sin(dLat / 2);
    final sinLng = math.sin(dLng / 2);
    final h = sinLat * sinLat +
        math.cos(a.latitude * math.pi / 180) *
            math.cos(b.latitude * math.pi / 180) *
            sinLng *
            sinLng;
    return 2 * r * math.asin(math.sqrt(h));
  }

  Future<void> _saveTrip(CommuteTrip trip) async {
    final all = await _loadAll();
    // Prevent duplicate ride IDs.
    if (all.any((t) => t.rideId == trip.rideId)) return;
    all.add(trip);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kCommuteLogKey, json.encode(all.map((t) => t.toJson()).toList()));
  }

  Future<List<CommuteTrip>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCommuteLogKey);
    if (raw == null) return [];
    try {
      final decoded = json.decode(raw) as List;
      return decoded
          .map((e) => CommuteTrip.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('CommuterTaxService load error: $e');
      return [];
    }
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final commuterTaxServiceProvider =
    Provider<CommuterTaxService>((_) => CommuterTaxService());

/// Current-year tax deduction summary.
final taxDeductionProvider =
    FutureProvider.autoDispose<TaxDeductionSummary>((ref) async {
  return ref.read(commuterTaxServiceProvider).calculateDeduction();
});

/// Monthly deduction estimate (deduction so far ÷ months elapsed × 12).
final monthlyDeductionEstimateProvider =
    FutureProvider.autoDispose<double>((ref) async {
  final summary = await ref.watch(taxDeductionProvider.future);
  final now = DateTime.now();
  final months = now.month;
  if (months == 0 || summary.estimatedDeductionDkk == 0) return 0;
  return summary.estimatedDeductionDkk / months * 12;
});
