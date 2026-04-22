/// CYKEL — Commuter Tax Tracking Service
///
/// Auto-detects commute rides (Home ↔ Work pattern) and calculates
/// annual km for Danish commuter tax deduction (befordringsfradrag).
///
/// Denmark 2026 rules:
/// - Minimum: 24 km/day (round trip) to qualify
/// - Standard rate: 1.98 DKK/km for 24-120 km/day
/// - Higher distance rate: 0.99 DKK/km for above 120 km/day
/// - Tax savings: Deduction × marginal tax rate (~42% average)
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
    required this.estimatedTaxSavingsDkk,
    required this.trips,
  });

  final int year;
  final int totalCommuteDays;
  final double totalCommuteKm;
  /// Km eligible for deduction (after 24 km/day threshold per day).
  final double deductibleKm;
  /// Estimated tax deduction amount in DKK (before applying tax rate).
  final double estimatedDeductionDkk;
  /// Estimated actual tax savings in DKK (deduction × marginal tax rate).
  final double estimatedTaxSavingsDkk;
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
    sb.writeln('Estimated tax savings DKK,${estimatedTaxSavingsDkk.toStringAsFixed(0)}');
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
  /// Uses 2026 tiered rates: 1.98 DKK/km (24-120km), 0.99 DKK/km (above 120km).
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
    double totalDeductionDkk = 0;
    
    for (final entry in dailyKm.entries) {
      final dayKm = entry.value;
      totalKm += dayKm;
      
      // Deduction only applies to km above the 24 km/day threshold.
      if (dayKm > DenmarkConstants.taxDeductionMinKmPerDay) {
        final deductibleForDay = dayKm - DenmarkConstants.taxDeductionMinKmPerDay;
        deductibleKm += deductibleForDay;
        
        // Apply tiered rates
        if (dayKm <= DenmarkConstants.taxDeductionHigherThreshold) {
          // All deductible distance at standard rate
          totalDeductionDkk += deductibleForDay * DenmarkConstants.taxDeductionStandardRate;
        } else {
          // Split between standard and higher rate
          const standardTierKm = DenmarkConstants.taxDeductionHigherThreshold - DenmarkConstants.taxDeductionMinKmPerDay;
          final higherTierKm = dayKm - DenmarkConstants.taxDeductionHigherThreshold;
          
          totalDeductionDkk += (standardTierKm * DenmarkConstants.taxDeductionStandardRate) +
                               (higherTierKm * DenmarkConstants.taxDeductionHigherRate);
        }
      }
    }
    
    // Calculate estimated tax savings (deduction × marginal tax rate)
    final estimatedSavings = totalDeductionDkk * DenmarkConstants.averageMarginalTaxRate;

    return TaxDeductionSummary(
      year: y,
      totalCommuteDays: dailyKm.length,
      totalCommuteKm: totalKm,
      deductibleKm: deductibleKm,
      estimatedDeductionDkk: totalDeductionDkk,
      estimatedTaxSavingsDkk: estimatedSavings,
      trips: trips,
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCommuteLogKey);
  }

  /// Calculate potential annual savings by switching from car to bike
  /// 
  /// [oneWayDistanceKm] - Distance from home to work (one way)
  /// [workDaysPerYear] - Number of commuting days per year (default 220)
  /// [carCostPerKm] - Cost per km for car (fuel, maintenance, depreciation)
  ///                  Default: 2.50 DKK/km (Danish average)
  /// 
  /// Returns map with annual costs and savings breakdown
  static Map<String, double> calculateCarVsBikeSavings({
    required double oneWayDistanceKm,
    int workDaysPerYear = 220,
    double carCostPerKm = 2.50,
  }) {
    final dailyRoundTripKm = oneWayDistanceKm * 2;
    final annualDistanceKm = dailyRoundTripKm * workDaysPerYear;
    
    // Annual car operating costs
    final annualCarCost = annualDistanceKm * carCostPerKm;
    
    // Calculate tax savings using tiered rates
    double taxDeduction = 0;
    if (dailyRoundTripKm > DenmarkConstants.taxDeductionMinKmPerDay) {
      final deductiblePerDay = dailyRoundTripKm - DenmarkConstants.taxDeductionMinKmPerDay;
      
      double dailyDeduction = 0;
      if (dailyRoundTripKm <= DenmarkConstants.taxDeductionHigherThreshold) {
        dailyDeduction = deductiblePerDay * DenmarkConstants.taxDeductionStandardRate;
      } else {
        const standardTierKm = DenmarkConstants.taxDeductionHigherThreshold - DenmarkConstants.taxDeductionMinKmPerDay;
        final higherTierKm = dailyRoundTripKm - DenmarkConstants.taxDeductionHigherThreshold;
        dailyDeduction = (standardTierKm * DenmarkConstants.taxDeductionStandardRate) +
                        (higherTierKm * DenmarkConstants.taxDeductionHigherRate);
      }
      
      taxDeduction = dailyDeduction * workDaysPerYear;
    }
    
    final taxSavings = taxDeduction * DenmarkConstants.averageMarginalTaxRate;
    final totalAnnualSavings = annualCarCost + taxSavings;
    
    return {
      'annualCarCost': annualCarCost,
      'annualTaxSavings': taxSavings,
      'totalAnnualSavings': totalAnnualSavings,
      'monthlySavings': totalAnnualSavings / 12,
    };
  }

  /// Format currency amount in Danish Kroner
  static String formatDKK(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k kr';
    }
    return '${amount.toStringAsFixed(0)} kr';
  }

  /// Get informational text about the Danish tax deduction system
  static String getDeductionInfo() {
    return '''
Danish Commuter Tax Deduction (Befordringsfradrag)

Qualification:
• Minimum 24 km round trip per day (12 km each way)
• Only distance above 24 km is deductible

Rates (2026):
• Standard: ${DenmarkConstants.taxDeductionStandardRate} DKK/km (24-120 km/day)
• Higher distance: ${DenmarkConstants.taxDeductionHigherRate} DKK/km (above 120 km/day)

Tax Savings:
• Deduction reduces your taxable income
• Actual savings depend on your tax rate (typically 37-55%)
• CYKEL estimates savings at ${(DenmarkConstants.averageMarginalTaxRate * 100).toStringAsFixed(0)}% marginal rate

How It Works:
• CYKEL automatically detects commute rides based on your home and work locations
• Year-to-date totals are tracked and can be exported for tax filing
• Report your total on Årsopgørelse (annual tax return)

Notes:
• Consult SKAT (Danish Tax Agency) for official guidance
• CYKEL provides estimates only - not official tax advice
''';
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
