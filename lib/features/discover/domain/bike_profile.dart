/// CYKEL — Bike Profile
/// Defines speed profiles that adjust OSRM route duration estimates
/// for different bike types commonly used in Denmark.

import 'package:flutter/material.dart';

enum BikeProfile { city, eBike, road, cargo, family }

extension BikeProfileX on BikeProfile {
  /// Multiplier applied to raw OSRM duration.
  /// < 1.0 = faster than OSRM baseline (~15 km/h city)
  /// > 1.0 = slower than baseline
  double get durationMultiplier => switch (this) {
        BikeProfile.city   => 1.00, // ~15 km/h — OSRM baseline
        BikeProfile.eBike  => 0.63, // ~24 km/h — e-bike assist
        BikeProfile.road   => 0.80, // ~19 km/h — road/sport bike
        BikeProfile.cargo  => 1.30, // ~12 km/h — cargo/heavy
        BikeProfile.family => 1.45, // ~10 km/h — family/children on board
      };

  /// Estimated range in km for different battery levels (for e-bikes)
  Map<int, double> get estimatedRangeKm => switch (this) {
        BikeProfile.city   => {100: 80, 75: 60, 50: 40, 25: 20},   // City bike
        BikeProfile.eBike  => {100: 80, 75: 60, 50: 40, 25: 20},   // E-bike
        BikeProfile.road   => {100: 100, 75: 75, 50: 50, 25: 25},  // Road bike
        BikeProfile.cargo  => {100: 60, 75: 45, 50: 30, 25: 15},   // Cargo bike
        BikeProfile.family => {100: 55, 75: 40, 50: 26, 25: 13},   // Family bike (with children)
      };

  /// Maintenance intervals in km
  int get maintenanceIntervalKm => switch (this) {
        BikeProfile.city   => 2000,
        BikeProfile.eBike  => 1500, // More frequent due to motor
        BikeProfile.road   => 2500,
        BikeProfile.cargo  => 1000, // Heavy use
        BikeProfile.family => 1500, // Regular checks when carrying children
      };

  IconData get icon => switch (this) {
        BikeProfile.city   => Icons.directions_bike_rounded,
        BikeProfile.eBike  => Icons.electric_bike_rounded,
        BikeProfile.road   => Icons.pedal_bike_rounded,
        BikeProfile.cargo  => Icons.delivery_dining_rounded,
        BikeProfile.family => Icons.family_restroom_rounded,
      };

  String get persistKey => name;
}
