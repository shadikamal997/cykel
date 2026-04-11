/// CYKEL — Provider List Screen
/// Shows a list of providers filtered by type with event-card style.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/location_service.dart';
import '../domain/provider_enums.dart';
import '../domain/provider_model.dart';
import '../providers/provider_providers.dart';

// ─── Design Colors ────────────────────────────────────────────────────────────
const _kPrimaryColor = Color(0xFF4A7C59);
const _kPrimaryPressed = Color(0xFF3D6B4A);
const _kPrimaryText = Color(0xFF1A1A1A);
const _kSecondaryText = Color(0xFF6B6B6B);
const _kBackground = Color(0xFFFFFFFF);
const _kCardBackground = Color(0xFFF4F5F2);

// ─── User Location Provider ───────────────────────────────────────────────────
final _userPositionProvider = FutureProvider<LatLng?>((ref) async {
  try {
    final locService = ref.read(locationServiceProvider);
    return await locService.getLastKnownOrCurrent();
  } catch (_) {
    return null;
  }
});

class ProviderListScreen extends ConsumerWidget {
  const ProviderListScreen({
    super.key,
    required this.providerType,
  });

  final ProviderType providerType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final providersAsync = ref.watch(allApprovedProvidersProvider);
    final userPosition = ref.watch(_userPositionProvider).valueOrNull;

    final title = _getTitle(l10n, providerType);

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimaryText),
          onPressed: () => context.pop(),
        ),
        title: Text(
          title,
          style: AppTextStyles.headline3.copyWith(color: _kPrimaryText),
        ),
      ),
      body: providersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _kPrimaryColor),
        ),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: _kSecondaryText),
              const SizedBox(height: 12),
              Text(l10n.noPlacesFound,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: _kSecondaryText)),
            ],
          ),
        ),
        data: (allProviders) {
          // Filter by type
          final filtered = allProviders
              .where((p) => p.providerType == providerType)
              .toList();

          // Sort by distance if user location available
          if (userPosition != null) {
            filtered.sort((a, b) {
              final distA = _calculateDistance(
                userPosition.latitude,
                userPosition.longitude,
                a.latitude,
                a.longitude,
              );
              final distB = _calculateDistance(
                userPosition.latitude,
                userPosition.longitude,
                b.latitude,
                b.longitude,
              );
              return distA.compareTo(distB);
            });
          }

          if (filtered.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getIcon(providerType),
                        size: 64, color: _kSecondaryText.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      _getEmptyMessage(l10n, providerType),
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: _kSecondaryText),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final provider = filtered[index];
              final distance = userPosition != null
                  ? _calculateDistance(
                      userPosition.latitude,
                      userPosition.longitude,
                      provider.latitude,
                      provider.longitude,
                    )
                  : null;
              return _ProviderCard(
                provider: provider,
                distance: distance,
                onTap: () => _openProviderDetail(context, ref, provider),
              );
            },
          );
        },
      ),
    );
  }

  String _getTitle(dynamic l10n, ProviderType type) {
    return switch (type) {
      ProviderType.repairShop => l10n.providerTypeRepairShop,
      ProviderType.bikeShop => l10n.providerTypeBikeShop,
      ProviderType.chargingLocation => l10n.providerTypeChargingLocation,
      ProviderType.servicePoint => l10n.providerTypeServicePoint,
      ProviderType.rental => l10n.providerTypeRental,
    };
  }

  IconData _getIcon(ProviderType type) {
    return switch (type) {
      ProviderType.repairShop => Icons.build_circle_rounded,
      ProviderType.bikeShop => Icons.store_rounded,
      ProviderType.chargingLocation => Icons.ev_station_rounded,
      ProviderType.servicePoint => Icons.handyman_rounded,
      ProviderType.rental => Icons.pedal_bike_rounded,
    };
  }

  String _getEmptyMessage(dynamic l10n, ProviderType type) {
    return switch (type) {
      ProviderType.chargingLocation => l10n.noChargingStationsNearby,
      _ => l10n.noProvidersNearby,
    };
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0; // km
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);
}

void _openProviderDetail(BuildContext context, WidgetRef ref, CykelProvider provider) {
  // Navigate to provider detail screen
  context.push(AppRoutes.providerDetail, extra: provider);
}

// ─── Provider Card (Event-style) ──────────────────────────────────────────────

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.provider,
    required this.distance,
    required this.onTap,
  });

  final CykelProvider provider;
  final double? distance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image or gradient
            if (provider.coverPhotoUrl != null &&
                provider.coverPhotoUrl!.isNotEmpty)
              Image.network(
                provider.coverPhotoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildGradientBackground(),
              )
            else
              _buildGradientBackground(),

            // Gradient overlay for text readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
            ),

            // Provider type tag (top-left)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getTypeIcon(provider.providerType),
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getTypeLabel(l10n, provider.providerType),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Open/Closed status (top-right)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: provider.isOpen
                      ? const Color(0xFF4A7C59).withValues(alpha: 0.9)
                      : Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  provider.isOpen
                      ? l10n.providerDetailOpen
                      : l10n.providerDetailClosed,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

            // Verified badge
            if (provider.isVerified)
              Positioned(
                top: 12,
                right: provider.isOpen ? 90 : 75,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _kPrimaryColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),

            // Content (bottom)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Provider name
                  Text(
                    provider.businessName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Address and distance
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${provider.streetAddress}, ${provider.city}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (distance != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatDistance(distance!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Logo overlay (bottom-right)
            if (provider.logoUrl != null && provider.logoUrl!.isNotEmpty)
              Positioned(
                bottom: 60,
                right: 16,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    provider.logoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: _kCardBackground,
                      child: Icon(
                        _getTypeIcon(provider.providerType),
                        color: _kPrimaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kPrimaryColor, _kPrimaryPressed],
        ),
      ),
    );
  }

  IconData _getTypeIcon(ProviderType type) {
    return switch (type) {
      ProviderType.repairShop => Icons.build_circle_rounded,
      ProviderType.bikeShop => Icons.store_rounded,
      ProviderType.chargingLocation => Icons.ev_station_rounded,
      ProviderType.servicePoint => Icons.handyman_rounded,
      ProviderType.rental => Icons.pedal_bike_rounded,
    };
  }

  String _getTypeLabel(dynamic l10n, ProviderType type) {
    return switch (type) {
      ProviderType.repairShop => l10n.providerTypeRepairShop,
      ProviderType.bikeShop => l10n.providerTypeBikeShop,
      ProviderType.chargingLocation => l10n.providerTypeChargingLocation,
      ProviderType.servicePoint => l10n.providerTypeServicePoint,
      ProviderType.rental => l10n.providerTypeRental,
    };
  }

  String _formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).round()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }
}
