/// CYKEL — User Profile Domain Model
/// Extended user data including bike battery, home/work locations, plan, etc.

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Subscription plan tier.
enum CykelPlan { free, premium }

class UserProfile {
  const UserProfile({
    this.homeLocation,
    this.workLocation,
    this.homeAddress,
    this.workAddress,
    this.batteryLevel, // 0-100, null if not set
    this.lastMaintenanceKm, // km reading at last service
    this.totalDistanceKm = 0, // total km ridden
    this.plan = CykelPlan.free,
    this.monthlyGoalKm = 100, // default 100km/month
  });

  final LatLng? homeLocation;
  final LatLng? workLocation;
  final String? homeAddress;
  final String? workAddress;
  final int? batteryLevel;
  final double? lastMaintenanceKm;
  final double totalDistanceKm;

  /// Current subscription plan.
  final CykelPlan plan;

  /// Monthly cycling goal in km (for challenge card).
  final int monthlyGoalKm;

  bool get hasHomeLocation => homeLocation != null;
  bool get hasWorkLocation => workLocation != null;
  bool get hasBatteryLevel => batteryLevel != null;
  bool get isPremium => plan == CykelPlan.premium;

  // Maintenance reminder logic
  bool get needsMaintenance {
    if (lastMaintenanceKm == null) return false;
    return totalDistanceKm - lastMaintenanceKm! >= 1500; // 1500km service interval
  }

  UserProfile copyWith({
    LatLng? homeLocation,
    LatLng? workLocation,
    String? homeAddress,
    String? workAddress,
    int? batteryLevel,
    double? lastMaintenanceKm,
    double? totalDistanceKm,
    CykelPlan? plan,
    int? monthlyGoalKm,
  }) {
    return UserProfile(
      homeLocation: homeLocation ?? this.homeLocation,
      workLocation: workLocation ?? this.workLocation,
      homeAddress: homeAddress ?? this.homeAddress,
      workAddress: workAddress ?? this.workAddress,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      lastMaintenanceKm: lastMaintenanceKm ?? this.lastMaintenanceKm,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      plan: plan ?? this.plan,
      monthlyGoalKm: monthlyGoalKm ?? this.monthlyGoalKm,
    );
  }

  Map<String, dynamic> toJson() => {
        if (homeLocation != null) 'homeLat': homeLocation!.latitude,
        if (homeLocation != null) 'homeLng': homeLocation!.longitude,
        if (workLocation != null) 'workLat': workLocation!.latitude,
        if (workLocation != null) 'workLng': workLocation!.longitude,
        if (homeAddress != null) 'homeAddress': homeAddress,
        if (workAddress != null) 'workAddress': workAddress,
        if (batteryLevel != null) 'batteryLevel': batteryLevel,
        if (lastMaintenanceKm != null) 'lastMaintenanceKm': lastMaintenanceKm,
        'totalDistanceKm': totalDistanceKm,
        'plan': plan.name,
        'monthlyGoalKm': monthlyGoalKm,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        homeLocation: json['homeLat'] != null && json['homeLng'] != null
            ? LatLng(json['homeLat'] as double, json['homeLng'] as double)
            : null,
        workLocation: json['workLat'] != null && json['workLng'] != null
            ? LatLng(json['workLat'] as double, json['workLng'] as double)
            : null,
        homeAddress: json['homeAddress'] as String?,
        workAddress: json['workAddress'] as String?,
        batteryLevel: json['batteryLevel'] as int?,
        lastMaintenanceKm: json['lastMaintenanceKm'] as double?,
        totalDistanceKm: (json['totalDistanceKm'] as num?)?.toDouble() ?? 0,
        plan: CykelPlan.values.firstWhere(
          (p) => p.name == (json['plan'] as String?),
          orElse: () => CykelPlan.free,
        ),
        monthlyGoalKm: (json['monthlyGoalKm'] as int?) ?? 100,
      );
}