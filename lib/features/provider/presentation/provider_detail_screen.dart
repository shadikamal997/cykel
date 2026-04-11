/// CYKEL — Provider Detail Screen
/// Professional profile page for bike shops, repair shops, and charging stations

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/app_router.dart';
import '../../../core/providers/pending_route_provider.dart';
import '../../../core/l10n/l10n.dart';
import '../../../services/location_service.dart';
import '../../discover/data/places_service.dart';
import '../domain/provider_enums.dart';
import '../domain/provider_model.dart';

// ─── Design Colors ────────────────────────────────────────────────────────────
const _kPrimaryColor = Color(0xFF4A7C59);
const _kPrimaryText = Color(0xFF1A1A1A);
const _kSecondaryText = Color(0xFF6B6B6B);
const _kBackground = Color(0xFFFFFFFF);
const _kCardBackground = Color(0xFFF4F5F2);
const _kSoftElements = Color(0xFFE9ECE6);
const _kVerifiedGreen = Color(0xFF10B981);

class ProviderDetailScreen extends ConsumerWidget {
  const ProviderDetailScreen({
    super.key,
    required this.provider,
  });

  final CykelProvider provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: CustomScrollView(
        slivers: [
          // ── App Bar with Cover Photo ──
          _buildSliverAppBar(context),

          // ── Content ──
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildHeader(context),
                const SizedBox(height: 20),
                _buildQuickActions(context, ref),
                const SizedBox(height: 24),
                _buildAddressSection(context),

                if (provider.openingHours.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildOpeningHours(context),
                ],

                if (provider.shopDescription != null &&
                    provider.shopDescription!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildDescription(context),
                ],

                const SizedBox(height: 24),
                _buildTypeSpecificInfo(context),

                if (provider.galleryUrls.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildGallery(context),
                ],

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildGetDirectionsButton(context, ref),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ── Sliver App Bar ────────────────────────────────────────────────────────────

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _kPrimaryColor,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: _kPrimaryText, size: 20),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (provider.coverPhotoUrl != null)
              Image.network(
                provider.coverPhotoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _defaultCoverGradient(),
              )
            else
              _defaultCoverGradient(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
            if (provider.logoUrl != null)
              Positioned(
                left: 20,
                bottom: 20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kSoftElements, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      provider.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        _getProviderIcon(),
                        color: _kPrimaryColor,
                        size: 40,
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

  Widget _defaultCoverGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _kPrimaryColor,
            _kPrimaryColor.withValues(alpha: 0.7),
          ],
        ),
      ),
    );
  }

  IconData _getProviderIcon() {
    return switch (provider.providerType) {
      ProviderType.bikeShop => Icons.pedal_bike_rounded,
      ProviderType.repairShop => Icons.build_circle_rounded,
      ProviderType.chargingLocation => Icons.ev_station_rounded,
      _ => Icons.store_rounded,
    };
  }

  // ── Header ────────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final isVerified =
        provider.verificationStatus == VerificationStatus.approved;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  provider.businessName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: _kPrimaryText,
                    height: 1.2,
                  ),
                ),
              ),
              if (isVerified)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kVerifiedGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kVerifiedGreen, width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 16, color: _kVerifiedGreen),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kVerifiedGreen,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getProviderTypeLabel(),
            style: const TextStyle(
              fontSize: 15,
              color: _kSecondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (provider.reviewCount > 0)
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  provider.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _kPrimaryText,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${provider.reviewCount} reviews)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: _kSecondaryText,
                  ),
                ),
              ],
            ),
          if (provider.specialNotice != null &&
              provider.specialNotice!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade600, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.amber.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.specialNotice!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getProviderTypeLabel() {
    return switch (provider.providerType) {
      ProviderType.bikeShop => 'Bike Shop',
      ProviderType.repairShop => 'Repair Shop',
      ProviderType.chargingLocation => 'E-Bike Charging Station',
      _ => 'Service Provider',
    };
  }

  // ── Quick Actions ─────────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kSoftElements, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _CompactActionButton(
              icon: Icons.phone_rounded,
              label: 'Call',
              onTap: () => _makePhoneCall(provider.phone),
            ),
            if (provider.website != null) ...  [
              Container(
                width: 1,
                height: 40,
                color: _kSoftElements,
              ),
              _CompactActionButton(
                icon: Icons.language_rounded,
                label: 'Website',
                onTap: () => _openWebsite(provider.website!),
              ),
            ],
            Container(
              width: 1,
              height: 40,
              color: _kSoftElements,
            ),
            _CompactActionButton(
              icon: Icons.directions_rounded,
              label: 'Directions',
              color: _kPrimaryColor,
              onTap: () => _openDirections(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openWebsite(String website) async {
    var url = website;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openDirections(BuildContext context, WidgetRef ref) {
    // Guard against invalid coordinates (0,0 = Gulf of Guinea, routing will fail)
    if (provider.latitude == 0.0 && provider.longitude == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available for this provider'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    ref.read(pendingRouteProvider.notifier).state = PlaceResult(
      placeId: 'cykel_${provider.id}',
      text: provider.businessName,
      subtitle: '${provider.streetAddress}, ${provider.city}',
      lat: provider.latitude,
      lng: provider.longitude,
    );
    context.go(AppRoutes.map);
  }

  // ── Address ───────────────────────────────────────────────────────────────────

  Widget _buildAddressSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Address',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kPrimaryText,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kCardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kSoftElements, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kPrimaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: _kPrimaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.streetAddress,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _kPrimaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${provider.postalCode} ${provider.city}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: _kSecondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Opening Hours ─────────────────────────────────────────────────────────────

  Widget _buildOpeningHours(BuildContext context) {
    final today = _getTodayKey();
    final todayHours = provider.openingHours[today];
    final isOpen = _isCurrentlyOpen(todayHours);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Opening Hours',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kPrimaryText,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOpen
                      ? _kVerifiedGreen.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOpen ? 'Open' : 'Closed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isOpen ? _kVerifiedGreen : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kCardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kSoftElements, width: 1),
            ),
            child: Column(
              children: _buildHoursRows(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHoursRows() {
    final days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final dayLabels = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    final rows = <Widget>[];
    for (var i = 0; i < days.length; i++) {
      final hours = provider.openingHours[days[i]];
      final isToday = days[i] == _getTodayKey();

      if (i > 0) rows.add(const SizedBox(height: 8));

      rows.add(
        Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(
                dayLabels[i],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  color: isToday ? _kPrimaryColor : _kSecondaryText,
                ),
              ),
            ),
            const Spacer(),
            Text(
              hours?.closed ?? false
                  ? 'Closed'
                  : '${hours?.open ?? '09:00'} - ${hours?.close ?? '17:00'}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                color: _kPrimaryText,
              ),
            ),
          ],
        ),
      );
    }

    return rows;
  }

  String _getTodayKey() {
    final weekday = DateTime.now().weekday;
    return switch (weekday) {
      1 => 'mon',
      2 => 'tue',
      3 => 'wed',
      4 => 'thu',
      5 => 'fri',
      6 => 'sat',
      7 => 'sun',
      _ => 'mon',
    };
  }

  bool _isCurrentlyOpen(DayHours? hours) {
    if (hours == null || hours.closed) return false;
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return currentTime.compareTo(hours.open) >= 0 &&
        currentTime.compareTo(hours.close) < 0;
  }

  // ── Description ───────────────────────────────────────────────────────────────

  Widget _buildDescription(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kPrimaryText,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            provider.shopDescription!,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: _kPrimaryText,
            ),
          ),
        ],
      ),
    );
  }

  // ── Type-Specific Info ────────────────────────────────────────────────────────

  Widget _buildTypeSpecificInfo(BuildContext context) {
    return switch (provider.providerType) {
      ProviderType.repairShop => _buildRepairShopInfo(context),
      ProviderType.bikeShop => _buildBikeShopInfo(context),
      ProviderType.chargingLocation => _buildChargingLocationInfo(context),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildRepairShopInfo(BuildContext context) {
    if (provider.servicesOffered.isEmpty &&
        !provider.mobileRepair &&
        !provider.acceptsWalkIns) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (provider.servicesOffered.isNotEmpty) ...[
            const Text(
              'Services Offered',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kPrimaryText,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: provider.servicesOffered.map((service) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _kPrimaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kPrimaryColor, width: 1),
                  ),
                  child: Text(
                    _getServiceLabel(service),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kPrimaryColor,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (provider.mobileRepair)
            const _InfoChip(
              icon: Icons.directions_car_rounded,
              label: 'Mobile Repair Available',
            ),
          if (provider.mobileRepair && provider.acceptsWalkIns)
            const SizedBox(height: 8),
          if (provider.acceptsWalkIns)
            const _InfoChip(
              icon: Icons.person_pin_rounded,
              label: 'Walk-ins Accepted',
            ),
        ],
      ),
    );
  }

  Widget _buildBikeShopInfo(BuildContext context) {
    if (provider.productsAvailable.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Products Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kPrimaryText,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: provider.productsAvailable.map((product) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kPrimaryColor, width: 1),
                ),
                child: Text(
                  _getProductLabel(product),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimaryColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChargingLocationInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Charging Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kPrimaryText,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _kPrimaryColor.withValues(alpha: 0.05),
                  _kPrimaryColor.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kPrimaryColor.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Column(
              children: [
                if (provider.numberOfPorts != null)
                  _ModernInfoRow(
                    icon: Icons.power_rounded,
                    label: 'Charging Ports',
                    value: '${provider.numberOfPorts} available',
                  ),
                if (provider.numberOfPorts != null && provider.chargingType != null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: _kSoftElements, height: 1),
                  ),
                if (provider.chargingType != null)
                  _ModernInfoRow(
                    icon: Icons.bolt_rounded,
                    label: 'Charger Type',
                    value: _getChargingTypeLabel(provider.chargingType!),
                  ),
                if (provider.chargingType != null && provider.maxChargingDurationMinutes != null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: _kSoftElements, height: 1),
                  ),
                if (provider.maxChargingDurationMinutes != null)
                  _ModernInfoRow(
                    icon: Icons.timer_rounded,
                    label: 'Max Duration',
                    value: '${provider.maxChargingDurationMinutes} minutes',
                  ),
              ],
            ),
          ),
          if (provider.indoorCharging || provider.weatherProtected) ... [
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (provider.indoorCharging)
                  const _FeatureBadge(
                    icon: Icons.roofing_rounded,
                    label: 'Indoor Charging',
                  ),
                if (provider.weatherProtected)
                  const _FeatureBadge(
                    icon: Icons.umbrella_rounded,
                    label: 'Weather Protected',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Gallery ───────────────────────────────────────────────────────────────────

  Widget _buildGallery(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Photos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kPrimaryText,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: provider.galleryUrls.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                    right: index < provider.galleryUrls.length - 1 ? 12 : 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    provider.galleryUrls[index],
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 120,
                      height: 120,
                      color: _kCardBackground,
                      child: const Icon(Icons.broken_image_rounded,
                          color: _kSecondaryText),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Get Directions Button ─────────────────────────────────────────────────────

  Widget _buildGetDirectionsButton(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: () async {
          // Ensure we have location permission before navigating
          final locService = ref.read(locationServiceProvider);
          try {
            await locService.getCurrentLocation();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.locationDisabled),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
          if (context.mounted) {
            _openDirections(context, ref);
          }
        },
        style: FilledButton.styleFrom(
          backgroundColor: _kPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.navigation_rounded, size: 22),
            SizedBox(width: 10),
            Text(
              'Get Directions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper Methods ────────────────────────────────────────────────────────────

  String _getServiceLabel(RepairService service) {
    return switch (service) {
      RepairService.flatTireRepair => 'Flat Tire Repair',
      RepairService.brakeService => 'Brake Service',
      RepairService.gearAdjustment => 'Gear Adjustment',
      RepairService.chainReplacement => 'Chain Replacement',
      RepairService.wheelTruing => 'Wheel Truing',
      RepairService.suspensionService => 'Suspension Service',
      RepairService.ebikeDiagnostics => 'E-Bike Diagnostics',
      RepairService.fullTuneUp => 'Full Tune-Up',
      RepairService.emergencyRepair => 'Emergency Repair',
      RepairService.safetyInspection => 'Safety Inspection',
      RepairService.mobileRepair => 'Mobile Repair',
    };
  }

  String _getProductLabel(ProductCategory product) {
    return switch (product) {
      ProductCategory.cityBikes => 'City Bikes',
      ProductCategory.ebikes => 'E-Bikes',
      ProductCategory.cargoBikes => 'Cargo Bikes',
      ProductCategory.roadBikes => 'Road Bikes',
      ProductCategory.kidsBikes => 'Kids Bikes',
      ProductCategory.helmets => 'Helmets',
      ProductCategory.locks => 'Locks',
      ProductCategory.lights => 'Lights',
      ProductCategory.tires => 'Tires',
      ProductCategory.spareParts => 'Spare Parts',
      ProductCategory.clothing => 'Clothing',
    };
  }

  String _getChargingTypeLabel(ChargingType type) {
    return switch (type) {
      ChargingType.standardOutlet => 'Standard Outlet',
      ChargingType.dedicatedCharger => 'Dedicated Charger',
      ChargingType.batterySwapStation => 'Battery Swap',
    };
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? _kPrimaryText;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: buttonColor, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: buttonColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info Chip ────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kSoftElements, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: _kPrimaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _kPrimaryText,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────

class _ModernInfoRow extends StatelessWidget {
  const _ModernInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _kPrimaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _kPrimaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _kSecondaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kPrimaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  const _FeatureBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kPrimaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kPrimaryColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _kPrimaryColor, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _kPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
