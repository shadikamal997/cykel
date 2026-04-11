/// CYKEL — Saved Route domain model

import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SavedRoute {
  const SavedRoute({
    required this.id,
    required this.name,
    required this.originAddress,
    required this.destAddress,
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
    required this.savedAt,
    this.distanceMeters = 0,
    this.durationSeconds = 0,
  });

  final String id;
  final String name;
  final String originAddress;
  final String destAddress;
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;
  final DateTime savedAt;
  final int distanceMeters;
  final int durationSeconds;

  LatLng get originLatLng => LatLng(originLat, originLng);
  LatLng get destLatLng   => LatLng(destLat, destLng);

  String get distanceLabel {
    if (distanceMeters < 1000) return '$distanceMeters m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'originAddress': originAddress,
        'destAddress': destAddress,
        'originLat': originLat,
        'originLng': originLng,
        'destLat': destLat,
        'destLng': destLng,
        'savedAt': savedAt.toIso8601String(),
        'distanceMeters': distanceMeters,
        'durationSeconds': durationSeconds,
      };

  factory SavedRoute.fromJson(Map<String, dynamic> json) => SavedRoute(
        id: json['id'] as String,
        name: json['name'] as String,
        originAddress: json['originAddress'] as String,
        destAddress: json['destAddress'] as String,
        originLat: (json['originLat'] as num).toDouble(),
        originLng: (json['originLng'] as num).toDouble(),
        destLat: (json['destLat'] as num).toDouble(),
        destLng: (json['destLng'] as num).toDouble(),
        savedAt: DateTime.parse(json['savedAt'] as String),
        distanceMeters: (json['distanceMeters'] as num?)?.toInt() ?? 0,
        durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      );

  static List<SavedRoute> decodeList(String raw) {
    final list = json.decode(raw) as List;
    return list
        .map((e) => SavedRoute.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String encodeList(List<SavedRoute> routes) =>
      json.encode(routes.map((r) => r.toJson()).toList());
}
