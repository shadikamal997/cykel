/// CYKEL — Location List Screen
/// Shows all locations owned by the current provider with quick toggles.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/location_service.dart';
import '../domain/provider_enums.dart';
import '../domain/provider_location.dart';
import '../providers/provider_providers.dart';

class LocationListScreen extends ConsumerWidget {
  const LocationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locationsAsync = ref.watch(myLocationsProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        title: Text(l10n.locationsTitle, style: AppTextStyles.headline3),
      ),
      body: locationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(l10n.changesSaveError(e.toString()),
              style: AppTextStyles.bodySmall),
        ),
        data: (locations) {
          if (locations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_off_outlined,
                        size: 56, color: context.colors.textSecondary),
                    const SizedBox(height: 16),
                    Text(l10n.noLocationsYet,
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: context.colors.textSecondary),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () =>
                          context.push(AppRoutes.providerLocationAdd),
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: Text(l10n.addLocation),
                      style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                          elevation: 0),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: locations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) =>
                _LocationCard(location: locations[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.providerLocationAdd),
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
        foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
        elevation: 0,
        child: const Icon(Icons.add_location_alt_outlined),
      ),
    );
  }
}

// ─── Location Card ──────────────────────────────────────────────────────────

class _LocationCard extends ConsumerWidget {
  const _LocationCard({required this.location});
  final ProviderLocation location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    final typeColor = switch (location.providerType) {
      ProviderType.repairShop => AppColors.layerService,
      ProviderType.bikeShop => AppColors.layerShop,
      ProviderType.chargingLocation => AppColors.layerCharging,
      ProviderType.servicePoint => AppColors.layerService,
      ProviderType.rental => AppColors.layerShop,
    };

    final typeLabel = switch (location.providerType) {
      ProviderType.repairShop => l10n.providerTypeRepairShop,
      ProviderType.bikeShop => l10n.providerTypeBikeShop,
      ProviderType.chargingLocation => l10n.providerTypeChargingLocation,
      ProviderType.servicePoint => l10n.providerTypeServicePoint,
      ProviderType.rental => l10n.providerTypeRental,
    };

    final statusLabel = location.temporarilyClosed
        ? l10n.providerTemporarilyClosed
        : location.isActive
            ? l10n.providerActive
            : l10n.providerInactive;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;
    final statusColor = location.temporarilyClosed
        ? baseColor.withValues(alpha: 0.7)
        : location.isActive
            ? baseColor.withValues(alpha: 1.0)
            : context.colors.textSecondary;

    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => context.push(
          AppRoutes.providerLocationEdit,
          extra: location,
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.location_on_rounded,
                        color: typeColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(location.name,
                            style: AppTextStyles.labelLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(typeLabel,
                            style: AppTextStyles.labelSmall
                                .copyWith(color: typeColor)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(statusLabel,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: statusColor)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 14, color: context.colors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(location.fullAddress,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: context.colors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 20, color: context.colors.textSecondary),
                ],
              ),
              // Quick actions
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _ActionChip(
                    icon: location.isActive
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    label: location.isActive
                        ? l10n.pauseLabel
                        : l10n.activateLabel,
                    onTap: () async {
                      await ref
                          .read(locationServiceProvider)
                          .setActive(location.id, active: !location.isActive);
                    },
                  ),
                  const SizedBox(width: 8),
                  _ActionChip(
                    icon: Icons.delete_outline_rounded,
                    label: l10n.deleteLabel,
                    isDestructive: true,
                    onTap: () => _confirmDelete(context, ref),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteLocationTitle),
        content: Text(l10n.deleteLocationConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
              elevation: 0),
            child: Text(l10n.deleteLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(locationServiceProvider).deleteLocation(location);
    }
  }
}

// ─── Action Chip ────────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
        : context.colors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: AppTextStyles.labelSmall.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
