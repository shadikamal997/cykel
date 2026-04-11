/// CYKEL — Ride domain model (Phase 4)

import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Ride {
  Ride({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.distanceMeters,
    required this.maxSpeedKmh,
    required this.avgSpeedKmh,
    required this.path,
    this.elevationGainM = 0,
  });

  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final double distanceMeters;
  final double maxSpeedKmh;
  final double avgSpeedKmh;
  final List<LatLng> path;

  /// Total elevation gain in metres (cumulative ascent only).
  final double elevationGainM;

  Duration get duration => endTime.difference(startTime);

  // ── CO₂ / climate impact ──────────────────────────────────────────────────

  /// CO₂ saved versus driving the same distance by car.
  /// Based on average EU passenger car: 0.21 kg CO₂ / km.
  double get co2SavedKg => (distanceMeters / 1000) * 0.21;

  /// Petrol saved versus driving the same distance by car.
  /// Average car: ~8 L / 100 km  →  0.08 L/km.
  double get fuelSavedLiters => (distanceMeters / 1000) * 0.08;

  /// Approximate calories burned cycling.
  /// Rough average: ~40 kcal / km at moderate pace, plus elevation bonus.
  /// Every 100 m of climb ≈ 30 kcal extra.
  int get caloriesBurned =>
      ((distanceMeters / 1000) * 40 + (elevationGainM / 100) * 30).round();

  // ── Labels ────────────────────────────────────────────────────────────────

  String get distanceLabel {
    if (distanceMeters < 1000) return '${distanceMeters.round()} m';
    return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
  }

  String get durationLabel {
    final m = duration.inMinutes;
    if (m < 60) return '${m}min';
    return '${m ~/ 60}h ${m % 60}min';
  }

  String get dateLabel {
    final d = startTime;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}  '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  String get elevationLabel {
    if (elevationGainM == 0) return '— m';
    return '${elevationGainM.round()} m';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'distanceMeters': distanceMeters,
        'maxSpeedKmh': maxSpeedKmh,
        'avgSpeedKmh': avgSpeedKmh,
        'elevationGainM': elevationGainM,
        'path': path
            .map((p) => {'lat': p.latitude, 'lng': p.longitude})
            .toList(),
      };

  factory Ride.fromJson(Map<String, dynamic> json) => Ride(
        id: json['id'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        distanceMeters: (json['distanceMeters'] as num).toDouble(),
        maxSpeedKmh: (json['maxSpeedKmh'] as num).toDouble(),
        avgSpeedKmh: (json['avgSpeedKmh'] as num).toDouble(),
        elevationGainM: (json['elevationGainM'] as num?)?.toDouble() ?? 0,
        path: (json['path'] as List)
            .map((p) =>
                LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()))
            .toList(),
      );

  factory Ride.fromJsonString(String s) => Ride.fromJson(
        jsonDecode(s) as Map<String, dynamic>,
      );

  String toJsonString() => jsonEncode(toJson());
}
