/// CYKEL — Bike Share Station Domain Models
/// Integration with bike sharing systems in Copenhagen

import 'dart:math' show sin, cos, sqrt, asin;
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ─── Bike Share Provider ─────────────────────────────────────────────────────

enum BikeShareProvider {
  bycyklen,    // Copenhagen City Bikes (electric)
  donkey,      // Donkey Republic (traditional + e-bikes)
  lime,        // Lime bikes and scooters
  tier,        // TIER e-scooters
  voi,         // Voi e-scooters
  swapfiets;   // Swapfiets subscription bikes

  String get displayName {
    switch (this) {
      case BikeShareProvider.bycyklen:
        return 'Bycyklen';
      case BikeShareProvider.donkey:
        return 'Donkey Republic';
      case BikeShareProvider.lime:
        return 'Lime';
      case BikeShareProvider.tier:
        return 'TIER';
      case BikeShareProvider.voi:
        return 'Voi';
      case BikeShareProvider.swapfiets:
        return 'Swapfiets';
    }
  }

  String get icon {
    switch (this) {
      case BikeShareProvider.bycyklen:
        return '🚲'; // Official Copenhagen bikes
      case BikeShareProvider.donkey:
        return '🐴'; // Donkey branding
      case BikeShareProvider.lime:
        return '🟢'; // Lime green
      case BikeShareProvider.tier:
        return '⚡'; // Electric scooter
      case BikeShareProvider.voi:
        return '🛴'; // Scooter
      case BikeShareProvider.swapfiets:
        return '🔄'; // Subscription service
    }
  }

  /// Whether this provider requires docking stations
  bool get requiresDocking {
    switch (this) {
      case BikeShareProvider.bycyklen:
        return true; // Bycyklen has fixed stations
      case BikeShareProvider.donkey:
        return true; // Donkey has lock stations
      case BikeShareProvider.lime:
        return false; // Dockless
      case BikeShareProvider.tier:
        return false; // Dockless
      case BikeShareProvider.voi:
        return false; // Dockless
      case BikeShareProvider.swapfiets:
        return false; // Personal subscription
    }
  }

  /// Vehicle type
  BikeShareVehicleType get vehicleType {
    switch (this) {
      case BikeShareProvider.bycyklen:
        return BikeShareVehicleType.eBike;
      case BikeShareProvider.donkey:
        return BikeShareVehicleType.both;
      case BikeShareProvider.lime:
        return BikeShareVehicleType.both;
      case BikeShareProvider.tier:
        return BikeShareVehicleType.scooter;
      case BikeShareProvider.voi:
        return BikeShareVehicleType.scooter;
      case BikeShareProvider.swapfiets:
        return BikeShareVehicleType.bike;
    }
  }
}

// ─── Vehicle Type ─────────────────────────────────────────────────────────────

enum BikeShareVehicleType {
  bike,      // Traditional bike
  eBike,     // Electric bike
  scooter,   // E-scooter
  both;      // Supports both bikes and e-bikes

  String get displayName {
    switch (this) {
      case BikeShareVehicleType.bike:
        return 'Bike';
      case BikeShareVehicleType.eBike:
        return 'E-Bike';
      case BikeShareVehicleType.scooter:
        return 'E-Scooter';
      case BikeShareVehicleType.both:
        return 'Bike & E-Bike';
    }
  }

  String get icon {
    switch (this) {
      case BikeShareVehicleType.bike:
        return '🚲';
      case BikeShareVehicleType.eBike:
        return '⚡🚲';
      case BikeShareVehicleType.scooter:
        return '🛴';
      case BikeShareVehicleType.both:
        return '🚲⚡';
    }
  }
}

// ─── Bike Share Station ──────────────────────────────────────────────────────

class BikeShareStation {
  const BikeShareStation({
    required this.id,
    required this.name,
    required this.provider,
    required this.location,
    required this.address,
    this.totalCapacity,
    this.availableBikes,
    this.availableEBikes,
    this.availableScooters,
    this.availableDocks,
    this.isActive = true,
    this.lastUpdated,
    this.distance,
  });

  final String id;
  final String name;
  final BikeShareProvider provider;
  final LatLng location;
  final String address;
  final int? totalCapacity; // Total docking capacity (for docking stations)
  final int? availableBikes; // Available traditional bikes
  final int? availableEBikes; // Available e-bikes
  final int? availableScooters; // Available e-scooters
  final int? availableDocks; // Available empty docks for parking
  final bool isActive; // Station operational status
  final DateTime? lastUpdated; // Last availability update
  final double? distance; // Distance from user (km)

  /// Total available vehicles across all types
  int get totalAvailable {
    return (availableBikes ?? 0) + 
           (availableEBikes ?? 0) + 
           (availableScooters ?? 0);
  }

  /// Whether the station has any available vehicles
  bool get hasAvailableVehicles => totalAvailable > 0;

  /// Whether the station has available docks for parking
  bool get hasAvailableDocks {
    if (!provider.requiresDocking) return true; // Dockless always has space
    return (availableDocks ?? 0) > 0;
  }

  /// Station availability status
  StationAvailability get availability {
    if (!isActive) return StationAvailability.offline;
    if (totalAvailable == 0) return StationAvailability.empty;
    if (totalAvailable >= 5) return StationAvailability.high;
    if (totalAvailable >= 2) return StationAvailability.medium;
    return StationAvailability.low;
  }

  /// Calculate distance from a given point in kilometers
  /// Uses Haversine formula for accurate distance calculation
  double distanceFromPoint(LatLng point) {
    const earthRadiusKm = 6371.0;
    const pi = 3.14159265359;
    
    final lat1 = location.latitude * (pi / 180);
    final lat2 = point.latitude * (pi / 180);
    final dLat = (point.latitude - location.latitude) * (pi / 180);
    final dLon = (point.longitude - location.longitude) * (pi / 180);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
              cos(lat1) * cos(lat2) *
              sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * asin(sqrt(a));
    
    return earthRadiusKm * c;
  }

  /// Color for UI display based on availability
  String get availabilityColor {
    switch (availability) {
      case StationAvailability.high:
        return '#4CAF50'; // Green
      case StationAvailability.medium:
        return '#FF9800'; // Orange
      case StationAvailability.low:
        return '#F44336'; // Red
      case StationAvailability.empty:
        return '#9E9E9E'; // Grey
      case StationAvailability.offline:
        return '#424242'; // Dark grey
    }
  }

  BikeShareStation copyWith({
    String? id,
    String? name,
    BikeShareProvider? provider,
    LatLng? location,
    String? address,
    int? totalCapacity,
    int? availableBikes,
    int? availableEBikes,
    int? availableScooters,
    int? availableDocks,
    bool? isActive,
    DateTime? lastUpdated,
    double? distance,
  }) {
    return BikeShareStation(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      location: location ?? this.location,
      address: address ?? this.address,
      totalCapacity: totalCapacity ?? this.totalCapacity,
      availableBikes: availableBikes ?? this.availableBikes,
      availableEBikes: availableEBikes ?? this.availableEBikes,
      availableScooters: availableScooters ?? this.availableScooters,
      availableDocks: availableDocks ?? this.availableDocks,
      isActive: isActive ?? this.isActive,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      distance: distance ?? this.distance,
    );
  }
}

// ─── Station Availability ─────────────────────────────────────────────────────

enum StationAvailability {
  high,      // 5+ vehicles available
  medium,    // 2-4 vehicles available
  low,       // 1 vehicle available
  empty,     // No vehicles available
  offline;   // Station not operational

  String get label {
    switch (this) {
      case StationAvailability.high:
        return 'Good availability';
      case StationAvailability.medium:
        return 'Limited availability';
      case StationAvailability.low:
        return 'Very low';
      case StationAvailability.empty:
        return 'Empty';
      case StationAvailability.offline:
        return 'Offline';
    }
  }
}
