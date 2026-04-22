/// CYKEL — Location Detail Screen
/// Shows full info for a charging station, shop, service, or rental.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/place.dart';

// ─── Design Colors ─────────────────────────────────────────────────────────────
const _kPrimaryColor = AppColors.primary;

class LocationDetailScreen extends StatelessWidget {
  const LocationDetailScreen({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: _typeColor(place.type),
            leading: IconButton(
              tooltip: 'Go back',
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: _typeColor(place.type),
                child: Center(
                  child: Icon(
                    _typeIcon(place.type),
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
              title: Text(
                place.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding:
                EdgeInsets.fromLTRB(20, 24, 20, bottomPad + 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Type badge
                Row(
                  children: [
                    _TypeBadge(place.type),
                    if (place.distanceMeters != null) ...[
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.near_me_rounded,
                        label: place.distanceLabel,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // Address
                if (place.address != null)
                  _InfoRow(
                    icon: Icons.location_on_rounded,
                    text: place.address!,
                  ),

                // Opening hours
                if (place.openingHours != null)
                  _InfoRow(
                    icon: Icons.access_time_rounded,
                    text: place.openingHours!,
                  ),

                const SizedBox(height: 24),

                // Action buttons
                _ActionButton(
                  icon: Icons.directions_bike_rounded,
                  label: context.l10n.getDirections,
                  color: _kPrimaryColor,
                  onTap: () => Navigator.of(context).pop({'navigate': place}),
                ),

                if (place.phone != null)
                  _ActionButton(
                    icon: Icons.phone_rounded,
                    label: place.phone!,
                    color: AppColors.info,
                    onTap: () =>
                        launchUrl(Uri.parse('tel:${place.phone}')),
                  ),

                if (place.website != null)
                  _ActionButton(
                    icon: Icons.language_rounded,
                    label: context.l10n.visitWebsite,
                    color: AppColors.success,
                    onTap: () =>
                        launchUrl(Uri.parse(place.website!)),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Color _typeColor(PlaceType type) {
    switch (type) {
      case PlaceType.charging:
        return const Color(0xFF2E7D32);
      case PlaceType.service:
        return AppColors.info;
      case PlaceType.shop:
        return _kPrimaryColor;
      case PlaceType.rental:
        return const Color(0xFF6A1B9A);
    }
  }

  IconData _typeIcon(PlaceType type) {
    switch (type) {
      case PlaceType.charging:
        return Icons.bolt_rounded;
      case PlaceType.service:
        return Icons.build_rounded;
      case PlaceType.shop:
        return Icons.storefront_rounded;
      case PlaceType.rental:
        return Icons.pedal_bike_rounded;
    }
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge(this.type);
  final PlaceType type;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = {
      PlaceType.charging: l10n.chargingStation,
      PlaceType.service: l10n.servicePoint,
      PlaceType.shop: l10n.bikeShop,
      PlaceType.rental: l10n.rental,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _kPrimaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        labels[type] ?? '',
        style: AppTextStyles.labelSmall.copyWith(color: _kPrimaryColor),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _kPrimaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(label,
                  style:
                      AppTextStyles.bodyMedium.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
