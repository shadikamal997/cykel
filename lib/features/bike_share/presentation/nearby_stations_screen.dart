/// CYKEL — Nearby Stations Screen
/// List view of bike share stations sorted by distance

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../application/bike_share_providers.dart';
import '../domain/bike_share_station.dart';
import 'station_detail_screen.dart';

class NearbyStationsScreen extends ConsumerWidget {
  const NearbyStationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userLocation = ref.watch(userLocationProvider);
    final radius = ref.watch(searchRadiusProvider);

    if (userLocation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nearby Stations')),
        body: const Center(
          child: Text('Location unavailable. Allow location access to find nearby stations.'),
        ),
      );
    }

    final nearbyParams = NearbyStationsParams(
      location: userLocation,
      radiusKm: radius,
    );
    final nearbyAsync = ref.watch(nearbyStationsProvider(nearbyParams));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Stations'),
        actions: [
          PopupMenuButton<double>(
            icon: const Icon(Icons.tune),
            initialValue: radius,
            onSelected: (value) {
              ref.read(searchRadiusProvider.notifier).state = value;
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 0.5, child: Text('500m radius')),
              const PopupMenuItem(value: 1.0, child: Text('1 km radius')),
              const PopupMenuItem(value: 2.0, child: Text('2 km radius')),
              const PopupMenuItem(value: 5.0, child: Text('5 km radius')),
            ],
          ),
        ],
      ),
      body: nearbyAsync.when(
        data: (stations) {
          if (stations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🚲', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  const Text(
                    'No stations found',
                    style: AppTextStyles.headline3,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try increasing the search radius',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stations.length,
            itemBuilder: (context, index) {
              final station = stations[index];
              return _StationCard(
                station: station,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => StationDetailScreen(station: station),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}

// ─── Station Card ────────────────────────────────────────────────────────────

class _StationCard extends StatelessWidget {
  const _StationCard({
    required this.station,
    required this.onTap,
  });

  final BikeShareStation station;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Provider icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      station.provider.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Station name & distance
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (station.distance != null)
                          Text(
                            '${(station.distance! * 1000).toInt()}m away',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Availability indicator
                  _AvailabilityBadge(station: station),
                ],
              ),

              const SizedBox(height: 12),

              // Vehicle counts
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (station.availableBikes != null && station.availableBikes! > 0)
                    _VehicleCount(
                      icon: '🚲',
                      label: 'Bikes',
                      count: station.availableBikes!,
                    ),
                  if (station.availableEBikes != null && station.availableEBikes! > 0)
                    _VehicleCount(
                      icon: '⚡',
                      label: 'E-Bikes',
                      count: station.availableEBikes!,
                    ),
                  if (station.availableScooters != null && station.availableScooters! > 0)
                    _VehicleCount(
                      icon: '🛴',
                      label: 'Scooters',
                      count: station.availableScooters!,
                    ),
                  if (station.provider.requiresDocking && station.availableDocks != null)
                    _VehicleCount(
                      icon: '🅿️',
                      label: 'Docks',
                      count: station.availableDocks!,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Availability Badge ──────────────────────────────────────────────────────

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.station});

  final BikeShareStation station;

  @override
  Widget build(BuildContext context) {
    final availability = station.availability;
    Color color;
    
    switch (availability) {
      case StationAvailability.high:
        color = AppColors.success;
        break;
      case StationAvailability.medium:
        color = AppColors.warning;
        break;
      case StationAvailability.low:
        color = AppColors.error;
        break;
      case StationAvailability.empty:
      case StationAvailability.offline:
        color = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        availability.label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ─── Vehicle Count ───────────────────────────────────────────────────────────

class _VehicleCount extends StatelessWidget {
  const _VehicleCount({
    required this.icon,
    required this.label,
    required this.count,
  });

  final String icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
