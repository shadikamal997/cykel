/// CYKEL — Bike domain model
/// Stored in Firestore: users/{uid}/bikes/{bikeId}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/l10n/l10n.dart';

enum BikeType { city, road, ebike, cargo, mountain }

extension BikeTypeX on BikeType {
  String get key => switch (this) {
        BikeType.city => 'city',
        BikeType.road => 'road',
        BikeType.ebike => 'ebike',
        BikeType.cargo => 'cargo',
        BikeType.mountain => 'mountain',
      };

  String get label => switch (this) {
        BikeType.city => 'City',
        BikeType.road => 'Road',
        BikeType.ebike => 'E-Bike',
        BikeType.cargo => 'Cargo',
        BikeType.mountain => 'Mountain',
      };

  String localizedLabel(BuildContext context) {
    final l10n = context.l10n;
    switch (this) {
      case BikeType.city: return l10n.bikeTypeCityBike;
      case BikeType.road: return l10n.bikeTypeRoadBike;
      case BikeType.ebike: return l10n.bikeTypeEbike;
      case BikeType.cargo: return l10n.bikeTypeCargoBike;
      case BikeType.mountain: return l10n.bikeTypeMtb;
    }
  }

  String get emoji => switch (this) {
        BikeType.city => '🚲',
        BikeType.road => '🏎️',
        BikeType.ebike => '⚡',
        BikeType.cargo => '📦',
        BikeType.mountain => '⛰️',
      };

  static BikeType fromKey(String s) => switch (s) {
        'road' => BikeType.road,
        'ebike' => BikeType.ebike,
        'cargo' => BikeType.cargo,
        'mountain' => BikeType.mountain,
        _ => BikeType.city,
      };
}

class Bike {
  const Bike({
    required this.id,
    required this.name,
    required this.type,
    this.brand,
    this.year,
    this.batteryCapacityWh,
    this.totalKm,
    required this.createdAt,
  });

  final String id;
  final String name;
  final BikeType type;
  final String? brand;
  final int? year;
  /// Battery capacity in Wh (e-bikes / cargo only).
  final double? batteryCapacityWh;
  /// Total kilometers ridden on this bike (for maintenance tracking).
  final double? totalKm;
  final DateTime createdAt;

  /// Whether this bike has an electric motor.
  bool get isElectric => type == BikeType.ebike || type == BikeType.cargo;

  factory Bike.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return Bike(
      id: doc.id,
      name: m['name'] as String? ?? '',
      type: BikeTypeX.fromKey(m['type'] as String? ?? 'city'),
      brand: m['brand'] as String?,
      year: m['year'] as int?,
      batteryCapacityWh: (m['batteryCapacityWh'] as num?)?.toDouble(),
      totalKm: (m['totalKm'] as num?)?.toDouble(),
      createdAt: m['createdAt'] is Timestamp
          ? (m['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'type': type.key,
        if (brand != null && brand!.isNotEmpty) 'brand': brand,
        if (year != null) 'year': year,
        if (batteryCapacityWh != null) 'batteryCapacityWh': batteryCapacityWh,
        if (totalKm != null) 'totalKm': totalKm,
        'createdAt': Timestamp.fromDate(createdAt),
      };
  
  Bike copyWith({
    String? id,
    String? name,
    BikeType? type,
    String? brand,
    int? year,
    double? batteryCapacityWh,
    double? totalKm,
    DateTime? createdAt,
  }) {
    return Bike(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      brand: brand ?? this.brand,
      year: year ?? this.year,
      batteryCapacityWh: batteryCapacityWh ?? this.batteryCapacityWh,
      totalKm: totalKm ?? this.totalKm,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
