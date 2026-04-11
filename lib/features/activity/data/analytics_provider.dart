/// CYKEL — Analytics Provider
/// Weekly, monthly and yearly ride summaries + personal records.
/// Computed from the local ride history stored by RideRepository.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/ride.dart';
import 'ride_recording_provider.dart';

// ─── Period Summaries ────────────────────────────────────────────────────────

class RideSummary {
  const RideSummary({
    this.distanceKm = 0,
    this.durationMinutes = 0,
    this.rideCount = 0,
    this.elevationGainM = 0,
    this.caloriesBurned = 0,
    this.co2SavedKg = 0,
    this.fuelSavedDkk = 0,
  });

  final double distanceKm;
  final int durationMinutes;
  final int rideCount;
  final double elevationGainM;
  final int caloriesBurned;
  final double co2SavedKg;
  final double fuelSavedDkk;

  bool get isEmpty => rideCount == 0;

  String get distanceLabel {
    if (distanceKm < 1) return '${(distanceKm * 1000).round()} m';
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get durationLabel {
    if (durationMinutes < 60) return '${durationMinutes}min';
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return '${h}h ${m}min';
  }

  String get elevationLabel => elevationGainM > 0
      ? '${elevationGainM.round()} m'
      : '— m';

  String get dkkLabel => '${fuelSavedDkk.toStringAsFixed(0)} kr';

  RideSummary operator +(RideSummary other) => RideSummary(
        distanceKm: distanceKm + other.distanceKm,
        durationMinutes: durationMinutes + other.durationMinutes,
        rideCount: rideCount + other.rideCount,
        elevationGainM: elevationGainM + other.elevationGainM,
        caloriesBurned: caloriesBurned + other.caloriesBurned,
        co2SavedKg: co2SavedKg + other.co2SavedKg,
        fuelSavedDkk: fuelSavedDkk + other.fuelSavedDkk,
      );

  static RideSummary fromRides(List<Ride> rides) {
    const dkkPerLitre = 14.5;
    double dist = 0;
    int dur = 0;
    double elev = 0;
    int cal = 0;
    double co2 = 0;
    double dkk = 0;
    for (final r in rides) {
      dist += r.distanceMeters / 1000;
      dur += r.duration.inMinutes;
      elev += r.elevationGainM;
      cal += r.caloriesBurned;
      co2 += r.co2SavedKg;
      dkk += r.fuelSavedLiters * dkkPerLitre;
    }
    return RideSummary(
      distanceKm: dist,
      durationMinutes: dur,
      rideCount: rides.length,
      elevationGainM: elev,
      caloriesBurned: cal,
      co2SavedKg: co2,
      fuelSavedDkk: dkk,
    );
  }
}

// ─── Weekly summary (Mon–Sun of the current week) ────────────────────────────

final weeklyRideSummaryProvider = FutureProvider<RideSummary>((ref) async {
  final rides = await ref.watch(rideHistoryProvider.future);
  final now = DateTime.now();
  // Monday = weekday 1
  final weekStart = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));
  final weekly = rides
      .where((r) => !r.startTime.isBefore(weekStart))
      .toList();
  return RideSummary.fromRides(weekly);
});

// ─── Monthly summary ─────────────────────────────────────────────────────────

final monthlyRideSummaryProvider = FutureProvider<RideSummary>((ref) async {
  final rides = await ref.watch(rideHistoryProvider.future);
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final monthly = rides
      .where((r) => !r.startTime.isBefore(monthStart))
      .toList();
  return RideSummary.fromRides(monthly);
});

// ─── Yearly summary ──────────────────────────────────────────────────────────

final yearlyRideSummaryProvider = FutureProvider<RideSummary>((ref) async {
  final rides = await ref.watch(rideHistoryProvider.future);
  final now = DateTime.now();
  final yearStart = DateTime(now.year, 1, 1);
  final yearly = rides
      .where((r) => !r.startTime.isBefore(yearStart))
      .toList();
  return RideSummary.fromRides(yearly);
});

// ─── Weekly day-by-day breakdown (for sparkline / bar chart) ─────────────────

/// Returns 7-element list [Mon, Tue, Wed, Thu, Fri, Sat, Sun] of daily
/// distance in km for the current week.
final weeklyDailyDistanceProvider =
    FutureProvider<List<double>>((ref) async {
  final rides = await ref.watch(rideHistoryProvider.future);
  final now = DateTime.now();
  final weekStart = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));

  final daily = List<double>.filled(7, 0.0);
  for (final r in rides) {
    final rideDay = DateTime(
        r.startTime.year, r.startTime.month, r.startTime.day);
    final dayIdx = rideDay.difference(weekStart).inDays;
    if (dayIdx >= 0 && dayIdx < 7) {
      daily[dayIdx] += r.distanceMeters / 1000;
    }
  }
  return daily;
});

// ─── Personal Records ─────────────────────────────────────────────────────────

class PersonalRecords {
  const PersonalRecords({
    this.longestRide,
    this.fastestRide,
    this.mostElevation,
    this.mostCalories,
    this.longestStreak = 0,
    this.totalRides = 0,
    this.totalDistanceKm = 0,
  });

  final Ride? longestRide;       // by distance
  final Ride? fastestRide;       // by avg speed
  final Ride? mostElevation;     // by elevation gain
  final Ride? mostCalories;      // by calories
  final int longestStreak;       // days in a row
  final int totalRides;
  final double totalDistanceKm;

  bool get hasRecords => longestRide != null;
}

final personalRecordsProvider = FutureProvider<PersonalRecords>((ref) async {
  final rides = await ref.watch(rideHistoryProvider.future);
  if (rides.isEmpty) {
    return const PersonalRecords();
  }

  Ride? longest;
  Ride? fastest;
  Ride? mostElev;
  Ride? mostCal;

  for (final r in rides) {
    if (longest == null || r.distanceMeters > longest.distanceMeters) {
      longest = r;
    }
    if (fastest == null || r.avgSpeedKmh > fastest.avgSpeedKmh) {
      fastest = r;
    }
    if (mostElev == null || r.elevationGainM > mostElev.elevationGainM) {
      mostElev = r;
    }
    if (mostCal == null || r.caloriesBurned > mostCal.caloriesBurned) {
      mostCal = r;
    }
  }

  // Calculate longest streak
  final streak = _longestStreak(rides);
  final totalDist =
      rides.fold<double>(0, (s, r) => s + r.distanceMeters / 1000);

  return PersonalRecords(
    longestRide: longest,
    fastestRide: fastest,
    mostElevation: mostElev,
    mostCalories: mostCal,
    longestStreak: streak,
    totalRides: rides.length,
    totalDistanceKm: totalDist,
  );
});

int _longestStreak(List<Ride> rides) {
  if (rides.isEmpty) return 0;

  // Collect unique ride dates
  final dates = <DateTime>{};
  for (final r in rides) {
    dates.add(DateTime(
        r.startTime.year, r.startTime.month, r.startTime.day));
  }
  final sorted = dates.toList()..sort();

  int longest = 1;
  int current = 1;
  for (int i = 1; i < sorted.length; i++) {
    if (sorted[i].difference(sorted[i - 1]).inDays == 1) {
      current++;
      if (current > longest) longest = current;
    } else {
      current = 1;
    }
  }
  return longest;
}
