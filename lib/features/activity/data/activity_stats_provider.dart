/// CYKEL — Activity Stats Providers
/// Calculates today's activity stats and riding streaks

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../activity/data/ride_recording_provider.dart';
import '../../activity/domain/ride.dart';

/// Today's activity stats
final todayStatsProvider = FutureProvider.autoDispose<TodayStats>((ref) async {
  final rides = await ref.watch(rideHistoryProvider.future);
  return _calculateTodayStats(rides);
});

/// Riding streak counter
final ridingStreakProvider = FutureProvider.autoDispose<int>((ref) async {
  final rides = await ref.watch(rideHistoryProvider.future);
  return _calculateStreak(rides);
});

class TodayStats {
  const TodayStats({
    this.distanceKm = 0,
    this.durationMinutes = 0,
    this.rideCount = 0,
  });

  final double distanceKm;
  final int durationMinutes;
  final int rideCount;

  String get distanceLabel {
    if (distanceKm < 1) return '${(distanceKm * 1000).round()}m';
    return '${distanceKm.toStringAsFixed(1)}km';
  }

  String get durationLabel {
    if (durationMinutes < 60) return '${durationMinutes}min';
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    return '${hours}h ${mins}min';
  }
}

TodayStats _calculateTodayStats(List<Ride> rides) {
  final today = DateTime.now();
  final todayStart = DateTime(today.year, today.month, today.day);

  double totalDistance = 0;
  int totalDuration = 0;
  int rideCount = 0;

  for (final ride in rides) {
    if (ride.startTime.isAfter(todayStart)) {
      totalDistance += ride.distanceMeters / 1000;
      totalDuration += ride.duration.inMinutes;
      rideCount++;
    }
  }

  return TodayStats(
    distanceKm: totalDistance,
    durationMinutes: totalDuration,
    rideCount: rideCount,
  );
}

int _calculateStreak(List<Ride> rides) {
  if (rides.isEmpty) return 0;

  // Sort rides by date (newest first)
  final sortedRides = rides.toList()
    ..sort((a, b) => b.startTime.compareTo(a.startTime));

  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);

  int streak = 0;
  DateTime currentDate = todayDate;

  // Check if user rode today
  bool rodeToday = sortedRides.any((ride) {
    final rideDate = DateTime(ride.startTime.year, ride.startTime.month, ride.startTime.day);
    return rideDate == todayDate;
  });

  if (!rodeToday) {
    // If no ride today, check yesterday
    currentDate = todayDate.subtract(const Duration(days: 1));
    final rodeYesterday = sortedRides.any((ride) {
      final rideDate = DateTime(ride.startTime.year, ride.startTime.month, ride.startTime.day);
      return rideDate == currentDate;
    });
    if (!rodeYesterday) return 0; // No recent activity
  }

  // Count consecutive days
  while (true) {
    final rodeOnDate = sortedRides.any((ride) {
      final rideDate = DateTime(ride.startTime.year, ride.startTime.month, ride.startTime.day);
      return rideDate == currentDate;
    });

    if (rodeOnDate) {
      streak++;
      currentDate = currentDate.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }

  return streak;
}