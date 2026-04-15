/// CYKEL — Bike Share Providers
/// Riverpod providers for bike share state management

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../domain/bike_share_station.dart';
import 'bike_share_service.dart';

// ─── Service Provider ────────────────────────────────────────────────────────

final bikeShareServiceProvider = Provider<BikeShareService>((ref) {
  final service = BikeShareService();
  ref.onDispose(() => service.dispose());
  return service;
});

// ─── Station Providers ───────────────────────────────────────────────────────

/// Stream of all bike share stations
final allStationsProvider = StreamProvider.autoDispose<List<BikeShareStation>>((ref) {
  final service = ref.watch(bikeShareServiceProvider);
  // Trigger initial fetch
  service.getAllStations();
  // Start auto-refresh
  service.startAutoRefresh();
  ref.onDispose(() => service.stopAutoRefresh());
  return service.stationsStream;
});

/// Get stations by provider
final stationsByProviderProvider =
    FutureProvider.autoDispose.family<List<BikeShareStation>, BikeShareProvider>(
  (ref, provider) async {
    final service = ref.watch(bikeShareServiceProvider);
    return await service.getStationsByProvider(provider);
  },
);

/// Get nearby stations
final nearbyStationsProvider = FutureProvider.autoDispose
    .family<List<BikeShareStation>, NearbyStationsParams>(
  (ref, params) async {
    final service = ref.watch(bikeShareServiceProvider);
    return await service.getNearbyStations(
      userLocation: params.location,
      radiusKm: params.radiusKm,
      limit: params.limit,
    );
  },
);

/// Get single station by ID
final stationByIdProvider =
    FutureProvider.autoDispose.family<BikeShareStation?, String>(
  (ref, stationId) async {
    final service = ref.watch(bikeShareServiceProvider);
    return await service.getStationById(stationId);
  },
);

// ─── Filter & Selection State ────────────────────────────────────────────────

/// Selected providers filter
final selectedProvidersProvider =
    StateProvider<Set<BikeShareProvider>>((ref) => BikeShareProvider.values.toSet());

/// Show only stations with available bikes
final showOnlyAvailableProvider = StateProvider<bool>((ref) => false);

/// Selected station for detail view
final selectedStationProvider = StateProvider<BikeShareStation?>((ref) => null);

/// User location for distance calculation
final userLocationProvider = StateProvider<LatLng?>((ref) => null);

/// Search radius in km
final searchRadiusProvider = StateProvider<double>((ref) => 1.0);

// ─── Filtered Stations ───────────────────────────────────────────────────────

/// Stations filtered by user preferences
final filteredStationsProvider = Provider.autoDispose<AsyncValue<List<BikeShareStation>>>((ref) {
  final allStationsAsync = ref.watch(allStationsProvider);
  final selectedProviders = ref.watch(selectedProvidersProvider);
  final showOnlyAvailable = ref.watch(showOnlyAvailableProvider);

  return allStationsAsync.whenData((stations) {
    return stations.where((station) {
      // Filter by provider
      if (!selectedProviders.contains(station.provider)) {
        return false;
      }

      // Filter by availability if enabled
      if (showOnlyAvailable && !station.hasAvailableVehicles) {
        return false;
      }

      return true;
    }).toList();
  });
});

// ─── Statistics ──────────────────────────────────────────────────────────────

/// Calculate total available vehicles across all stations
final totalAvailableVehiclesProvider = Provider.autoDispose<int>((ref) {
  final stationsAsync = ref.watch(allStationsProvider);
  
  return stationsAsync.when(
    data: (stations) => stations.fold<int>(
      0,
      (total, station) => total + station.totalAvailable,
    ),
    loading: () => 0,
    error: (error, s) => 0,
  );
});

/// Count of active stations
final activeStationsCountProvider = Provider.autoDispose<int>((ref) {
  final stationsAsync = ref.watch(allStationsProvider);
  
  return stationsAsync.when(
    data: (stations) => stations.where((s) => s.isActive).length,
    loading: () => 0,
    error: (error, s) => 0,
  );
});

/// Stations grouped by provider
final stationsByProviderGroupProvider =
    Provider.autoDispose<AsyncValue<Map<BikeShareProvider, List<BikeShareStation>>>>((ref) {
  final stationsAsync = ref.watch(allStationsProvider);
  
  return stationsAsync.whenData((stations) {
    final grouped = <BikeShareProvider, List<BikeShareStation>>{};
    
    for (final provider in BikeShareProvider.values) {
      grouped[provider] = stations.where((s) => s.provider == provider).toList();
    }
    
    return grouped;
  });
});

// ─── Helper Classes ──────────────────────────────────────────────────────────

class NearbyStationsParams {
  const NearbyStationsParams({
    required this.location,
    this.radiusKm = 1.0,
    this.limit,
  });

  final LatLng location;
  final double radiusKm;
  final int? limit;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NearbyStationsParams &&
        other.location == location &&
        other.radiusKm == radiusKm &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(location, radiusKm, limit);
}
