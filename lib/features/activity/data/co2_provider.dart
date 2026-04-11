/// CYKEL — CO₂ & climate impact providers (Phase 1-CO2)

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ride_recording_provider.dart';

/// Average petrol price in Denmark (DKK / litre, approximate).
const _kDieselPriceDkk = 14.5;

/// Aggregated CO₂ / impact across all saved rides.
class Co2Stats {
  const Co2Stats({
    required this.totalCo2SavedKg,
    required this.totalFuelSavedLiters,
    required this.totalCaloriesBurned,
    required this.totalRides,
  });

  final double totalCo2SavedKg;
  final double totalFuelSavedLiters;
  final int totalCaloriesBurned;
  final int totalRides;

  /// Fuel money saved in DKK.
  double get totalFuelSavedDkk => totalFuelSavedLiters * _kDieselPriceDkk;

  /// Fuel money saved formatted label.
  String get fuelSavedDkkLabel => '${totalFuelSavedDkk.toStringAsFixed(0)} kr';
}

final co2StatsProvider = FutureProvider<Co2Stats>((ref) async {
  final rides = await ref.watch(rideHistoryProvider.future);
  double co2 = 0;
  double fuel = 0;
  int cal = 0;
  for (final r in rides) {
    co2 += r.co2SavedKg;
    fuel += r.fuelSavedLiters;
    cal += r.caloriesBurned;
  }
  return Co2Stats(
    totalCo2SavedKg: co2,
    totalFuelSavedLiters: fuel,
    totalCaloriesBurned: cal,
    totalRides: rides.length,
  );
});
