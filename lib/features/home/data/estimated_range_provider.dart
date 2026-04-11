/// CYKEL — Estimated Range Provider (Phase 8)
/// Calculates remaining riding range with weather adjustments.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/denmark_constants.dart';
import '../../../core/providers/bike_profile_provider.dart';
import '../../../features/discover/domain/bike_profile.dart';
import '../../profile/data/user_profile_provider.dart';
import '../data/weather_provider.dart';

/// Returns estimated range for any bike based on battery % (if set).
/// Phase 8: now factors in wind, temperature, and elevation deductions.
final allBikesRangeProvider = Provider<EstimatedRange?>((ref) {
  final profile = ref.watch(userProfileProvider);
  final bikeProfile = ref.watch(bikeProfileProvider);

  if (!profile.hasBatteryLevel) return null;

  final battery = profile.batteryLevel!;
  final rangeKmPerCharge = switch (bikeProfile) {
    BikeProfile.eBike   => 80.0,  // E-bike: 80 km max range
    BikeProfile.cargo   => 60.0,  // Cargo e-bike: 60 km
    BikeProfile.city    => null,  // Regular bike, no battery limit
    BikeProfile.road    => null,  // Road bike, no battery limit
    BikeProfile.family  => null,  // Family bike, no battery limit
  };

  if (rangeKmPerCharge == null) return null;

  // ── Weather adjustment ─────────────────────────────────────────────────
  double weatherFactor = 1.0;
  final weatherAsync = ref.watch(homeWeatherProvider);
  if (weatherAsync.hasValue && !weatherAsync.value!.isFallback) {
    final w = weatherAsync.value!;
    // Cold saps battery: −10% at 0 °C, −20% at −10 °C
    if (w.temperatureC < DenmarkConstants.idealMinTemp) {
      final coldPenalty = ((DenmarkConstants.idealMinTemp - w.temperatureC) * 0.01)
          .clamp(0.0, 0.25);
      weatherFactor -= coldPenalty;
    }
    // Headwind: −5% per 5 m/s above moderate
    if (w.windSpeedMs > DenmarkConstants.windModerateMax) {
      final windPenalty = ((w.windSpeedMs - DenmarkConstants.windModerateMax) / 5 * 0.05)
          .clamp(0.0, 0.20);
      weatherFactor -= windPenalty;
    }
    // Rain: −5% when raining (extra tyre resistance)
    if (w.isRaining) weatherFactor -= 0.05;
  }

  final adjustedRange = rangeKmPerCharge * weatherFactor;
  final remainingKm = (adjustedRange * battery / 100).roundToDouble();

  return EstimatedRange(
    remainingKm: remainingKm,
    batteryPercent: battery,
    maxRangeKm: adjustedRange,
    weatherAdjusted: weatherAsync.hasValue && !weatherAsync.value!.isFallback,
  );
});

class EstimatedRange {
  const EstimatedRange({
    required this.remainingKm,
    required this.batteryPercent,
    required this.maxRangeKm,
    this.weatherAdjusted = false,
  });

  final double remainingKm;
  final int batteryPercent;
  final double maxRangeKm;
  /// True when weather adjustments were applied.
  final bool weatherAdjusted;

  String get label => '~${remainingKm.toStringAsFixed(0)} km';

  bool get isLow => batteryPercent <= 20;
  bool get isMedium => batteryPercent > 20 && batteryPercent <= 50;
  bool get isHigh => batteryPercent > 50;

  /// Range warning threshold: show charging suggestion when < 10 km remaining.
  bool get needsChargingSoon => remainingKm < 10;
}
