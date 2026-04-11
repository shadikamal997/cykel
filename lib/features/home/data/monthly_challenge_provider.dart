/// CYKEL — Monthly Challenge Provider
/// Provides data for the monthly cycling challenge.
/// Goals: ride a set number of km in the current calendar month.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../activity/data/analytics_provider.dart';
import '../../profile/data/user_profile_provider.dart';

class MonthlyChallenge {
  const MonthlyChallenge({
    required this.goalKm,
    required this.completedKm,
    required this.rideCount,
  });

  final double goalKm;
  final double completedKm;
  final int rideCount;

  double get progress => (completedKm / goalKm).clamp(0.0, 1.0);
  double get remainingKm => (goalKm - completedKm).clamp(0, goalKm);
  bool get isComplete => completedKm >= goalKm;

  String get progressLabel =>
      '${completedKm.toStringAsFixed(1)} / ${goalKm.toStringAsFixed(0)} km';

  String get statusLabel {
    if (isComplete) return '🏆 Challenge complete!';
    final pct = (progress * 100).round();
    return '$pct% done · ${remainingKm.toStringAsFixed(1)} km to go';
  }
}

final monthlyChallengeProvider = FutureProvider<MonthlyChallenge>((ref) async {
  final summary = await ref.watch(monthlyRideSummaryProvider.future);
  final profile = ref.watch(userProfileProvider);
  return MonthlyChallenge(
    goalKm: profile.monthlyGoalKm.toDouble(),
    completedKm: summary.distanceKm,
    rideCount: summary.rideCount,
  );
});
