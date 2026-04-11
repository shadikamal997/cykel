/// CYKEL — Route result domain model
/// Wraps a Google Directions API cycling route response.

import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteResult {
  const RouteResult({
    required this.polylinePoints,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.steps,
    required this.originAddress,
    required this.destinationAddress,
  });

  final List<LatLng> polylinePoints;
  final int distanceMeters;
  final int durationSeconds;
  final List<RouteStep> steps;
  final String originAddress;
  final String destinationAddress;

  // ── Serialization ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'points': polylinePoints.map((p) => [p.latitude, p.longitude]).toList(),
        'distanceMeters': distanceMeters,
        'durationSeconds': durationSeconds,
        'steps': steps.map((s) => s.toJson()).toList(),
        'originAddress': originAddress,
        'destinationAddress': destinationAddress,
      };

  factory RouteResult.fromJson(Map<String, dynamic> json) => RouteResult(
        polylinePoints: (json['points'] as List)
            .map((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()))
            .toList(),
        distanceMeters: (json['distanceMeters'] as num).toInt(),
        durationSeconds: (json['durationSeconds'] as num).toInt(),
        steps: (json['steps'] as List)
            .map((s) => RouteStep.fromJson(s as Map<String, dynamic>))
            .toList(),
        originAddress: json['originAddress'] as String? ?? '',
        destinationAddress: json['destinationAddress'] as String? ?? '',
      );

  static String encode(RouteResult r) => json.encode(r.toJson());
  static RouteResult decode(String raw) =>
      RouteResult.fromJson(json.decode(raw) as Map<String, dynamic>);

  // ── Labels ─────────────────────────────────────────────────────────────────

  String get distanceLabel {
    if (distanceMeters < 1000) return '$distanceMeters m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get durationLabel {
    final mins = (durationSeconds / 60).round();
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  /// Remaining distance from [stepIndex] onwards (metres).
  int remainingDistanceFrom(int stepIndex) =>
      steps.skip(stepIndex).fold(0, (s, e) => s + e.distanceMeters);

  /// Remaining duration from [stepIndex] onwards (seconds).
  int remainingDurationFrom(int stepIndex) =>
      steps.skip(stepIndex).fold(0, (s, e) => s + e.durationSeconds);

  String remainingDistanceLabel(int stepIndex) {
    final m = remainingDistanceFrom(stepIndex);
    if (m < 1000) return '$m m';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }

  String remainingDurationLabel(int stepIndex) {
    final mins = (remainingDurationFrom(stepIndex) / 60).round();
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }
}

class RouteStep {
  const RouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.startLocation,
    required this.endLocation,
    required this.maneuver,
  });

  final String instruction;
  final int distanceMeters;
  final int durationSeconds;
  final LatLng startLocation;
  final LatLng endLocation;
  final String maneuver; // e.g. "turn-left", "turn-right", "straight"

  // ── Serialization ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'instruction': instruction,
        'distanceMeters': distanceMeters,
        'durationSeconds': durationSeconds,
        'startLat': startLocation.latitude,
        'startLng': startLocation.longitude,
        'endLat': endLocation.latitude,
        'endLng': endLocation.longitude,
        'maneuver': maneuver,
      };

  factory RouteStep.fromJson(Map<String, dynamic> json) => RouteStep(
        instruction: json['instruction'] as String,
        distanceMeters: (json['distanceMeters'] as num).toInt(),
        durationSeconds: (json['durationSeconds'] as num).toInt(),
        startLocation: LatLng(
          (json['startLat'] as num).toDouble(),
          (json['startLng'] as num).toDouble(),
        ),
        endLocation: LatLng(
          (json['endLat'] as num).toDouble(),
          (json['endLng'] as num).toDouble(),
        ),
        maneuver: json['maneuver'] as String? ?? '',
      );

  // ── Labels ─────────────────────────────────────────────────────────────────

  String get distanceLabel {
    if (distanceMeters < 1000) return '$distanceMeters m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }
}
