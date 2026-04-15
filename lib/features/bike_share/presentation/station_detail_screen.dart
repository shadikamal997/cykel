/// CYKEL — Station Detail Screen
/// Detailed view of a single bike share station

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/bike_share_station.dart';

class StationDetailScreen extends ConsumerWidget {
  const StationDetailScreen({
    super.key,
    required this.station,
  });

  final BikeShareStation station;

  Future<void> _openInMaps() async {
    final lat = station.location.latitude;
    final lng = station.location.longitude;
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Provider badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    station.provider.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.provider.displayName,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        station.name,
                        style: AppTextStyles.headline3,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Address
            Row(
              children: [
                const Icon(Icons.location_on, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    station.address,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Availability status
            _AvailabilityCard(station: station),

            const SizedBox(height: 24),

            // Vehicle availability
            const Text('Available Vehicles', style: AppTextStyles.labelLarge),
            const SizedBox(height: 12),
            _VehicleGrid(station: station),

            if (station.provider.requiresDocking) ...[
              const SizedBox(height: 24),
              const Text('Parking', style: AppTextStyles.labelLarge),
              const SizedBox(height: 12),
              _ParkingInfo(station: station),
            ],

            const SizedBox(height: 24),

            // Station info
            if (station.lastUpdated != null) ...[
              const Text('Last Updated', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              Text(
                _formatLastUpdated(station.lastUpdated!),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openInMaps,
                    icon: const Icon(Icons.directions),
                    label: const Text('Get Directions'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastUpdated(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minutes ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else {
      return '${diff.inDays} days ago';
    }
  }
}

// ─── Availability Card ───────────────────────────────────────────────────────

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({required this.station});

  final BikeShareStation station;

  @override
  Widget build(BuildContext context) {
    final availability = station.availability;
    Color color;
    IconData icon;

    switch (availability) {
      case StationAvailability.high:
        color = AppColors.success;
        icon = Icons.check_circle;
        break;
      case StationAvailability.medium:
        color = AppColors.warning;
        icon = Icons.warning;
        break;
      case StationAvailability.low:
        color = AppColors.error;
        icon = Icons.error;
        break;
      case StationAvailability.empty:
        color = AppColors.textSecondary;
        icon = Icons.cancel;
        break;
      case StationAvailability.offline:
        color = AppColors.textSecondary;
        icon = Icons.power_off;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  availability.label,
                  style: AppTextStyles.labelLarge.copyWith(color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  '${station.totalAvailable} vehicles available',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Vehicle Grid ────────────────────────────────────────────────────────────

class _VehicleGrid extends StatelessWidget {
  const _VehicleGrid({required this.station});

  final BikeShareStation station;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (station.availableBikes != null)
          Expanded(
            child: _VehicleTypeCard(
              icon: '🚲',
              label: 'Bikes',
              count: station.availableBikes!,
            ),
          ),
        if (station.availableEBikes != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _VehicleTypeCard(
              icon: '⚡',
              label: 'E-Bikes',
              count: station.availableEBikes!,
            ),
          ),
        ],
        if (station.availableScooters != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _VehicleTypeCard(
              icon: '🛴',
              label: 'Scooters',
              count: station.availableScooters!,
            ),
          ),
        ],
      ],
    );
  }
}

class _VehicleTypeCard extends StatelessWidget {
  const _VehicleTypeCard({
    required this.icon,
    required this.label,
    required this.count,
  });

  final String icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
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
      ),
    );
  }
}

// ─── Parking Info ────────────────────────────────────────────────────────────

class _ParkingInfo extends StatelessWidget {
  const _ParkingInfo({required this.station});

  final BikeShareStation station;

  @override
  Widget build(BuildContext context) {
    final docks = station.availableDocks ?? 0;
    final capacity = station.totalCapacity ?? 0;
    final occupancy = capacity > 0
        ? ((capacity - docks) / capacity * 100).toInt()
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$docks docks available',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$occupancy% full',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: occupancy / 100,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(
              occupancy > 80 ? AppColors.error : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
