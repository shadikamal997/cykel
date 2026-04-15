/// CYKEL — Bike Share Map Screen
/// Interactive map showing all bike share stations

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../application/bike_share_providers.dart';
import '../domain/bike_share_station.dart';
import 'station_detail_screen.dart';
import 'nearby_stations_screen.dart';

class BikeShareMapScreen extends ConsumerStatefulWidget {
  const BikeShareMapScreen({super.key});

  @override
  ConsumerState<BikeShareMapScreen> createState() => _BikeShareMapScreenState();
}

class _BikeShareMapScreenState extends ConsumerState<BikeShareMapScreen> {
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(55.6761, 12.5683); // Copenhagen center

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final userLocation = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _center = userLocation;
      });
      
      ref.read(userLocationProvider.notifier).state = userLocation;
      
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(userLocation, 14),
      );
    } catch (e) {
      // Use default Copenhagen location if location unavailable
    }
  }

  Set<Marker> _buildMarkers(List<BikeShareStation> stations) {
    return stations.map((station) {
      return Marker(
        markerId: MarkerId(station.id),
        position: station.location,
        icon: _getMarkerIcon(station.provider),
        infoWindow: InfoWindow(
          title: station.name,
          snippet: '${station.totalAvailable} bikes available',
          onTap: () => _onStationTapped(station),
        ),
      );
    }).toSet();
  }

  BitmapDescriptor _getMarkerIcon(BikeShareProvider provider) {
    // In production, would use custom marker icons
    return BitmapDescriptor.defaultMarkerWithHue(
      _getProviderHue(provider),
    );
  }

  double _getProviderHue(BikeShareProvider provider) {
    switch (provider) {
      case BikeShareProvider.bycyklen:
        return BitmapDescriptor.hueBlue;
      case BikeShareProvider.donkey:
        return BitmapDescriptor.hueOrange;
      case BikeShareProvider.lime:
        return BitmapDescriptor.hueGreen;
      case BikeShareProvider.tier:
        return BitmapDescriptor.hueViolet;
      case BikeShareProvider.voi:
        return BitmapDescriptor.hueRed;
      case BikeShareProvider.swapfiets:
        return BitmapDescriptor.hueCyan;
    }
  }

  void _onStationTapped(BikeShareStation station) {
    ref.read(selectedStationProvider.notifier).state = station;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StationDetailScreen(station: station),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(filteredStationsProvider);
    final selectedProviders = ref.watch(selectedProvidersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bike Share Stations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getUserLocation,
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NearbyStationsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          stationsAsync.when(
            data: (stations) => GoogleMap(
              onMapCreated: (controller) => _mapController = controller,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 13,
              ),
              markers: _buildMarkers(stations),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text('Error loading stations: $error'),
            ),
          ),

          // Provider filter chips
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: BikeShareProvider.values.map((provider) {
                  final isSelected = selectedProviders.contains(provider);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(provider.icon),
                          const SizedBox(width: 4),
                          Text(provider.displayName),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        final newSelection = Set<BikeShareProvider>.from(selectedProviders);
                        if (selected) {
                          newSelection.add(provider);
                        } else {
                          newSelection.remove(provider);
                        }
                        ref.read(selectedProvidersProvider.notifier).state = newSelection;
                      },
                      backgroundColor: AppColors.surface,
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Stats card at bottom
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: stationsAsync.when(
              data: (stations) => _StatsCard(stations: stations),
              loading: () => const SizedBox.shrink(),
              error: (error, s) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Card ──────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stations});

  final List<BikeShareStation> stations;

  @override
  Widget build(BuildContext context) {
    final totalBikes = stations.fold<int>(
      0,
      (sum, s) => sum + (s.availableBikes ?? 0),
    );
    final totalEBikes = stations.fold<int>(
      0,
      (sum, s) => sum + (s.availableEBikes ?? 0),
    );
    final totalScooters = stations.fold<int>(
      0,
      (sum, s) => sum + (s.availableScooters ?? 0),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: '🚲',
              label: 'Bikes',
              count: totalBikes,
            ),
            _StatItem(
              icon: '⚡',
              label: 'E-Bikes',
              count: totalEBikes,
            ),
            _StatItem(
              icon: '🛴',
              label: 'Scooters',
              count: totalScooters,
            ),
            _StatItem(
              icon: '📍',
              label: 'Stations',
              count: stations.where((s) => s.isActive).length,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.count,
  });

  final String icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: AppTextStyles.headline3,
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
