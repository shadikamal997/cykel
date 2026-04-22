/// CYKEL — Provider Type Selection Screen
/// First step: Choose between Repair Shop, Bike Shop, or Charging Location.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/provider_enums.dart';

class ProviderTypeSelectionScreen extends StatefulWidget {
  const ProviderTypeSelectionScreen({super.key});

  @override
  State<ProviderTypeSelectionScreen> createState() =>
      _ProviderTypeSelectionScreenState();
}

class _ProviderTypeSelectionScreenState
    extends State<ProviderTypeSelectionScreen> {
  ProviderType? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        title: Text(l10n.providerOnboardingTitle,
            style: AppTextStyles.headline3),
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.providerSelectTypeTitle,
                      style: AppTextStyles.headline2),
                  const SizedBox(height: 8),
                  Text(l10n.providerSelectTypeSubtitle,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: context.colors.textSecondary)),
                  const SizedBox(height: 28),
                  _TypeCard(
                    type: ProviderType.repairShop,
                    icon: Icons.build_rounded,
                    title: l10n.providerTypeRepairShop,
                    description: l10n.providerTypeRepairShopDesc,
                    color: AppColors.layerService,
                    isSelected: _selected == ProviderType.repairShop,
                    onTap: () =>
                        setState(() => _selected = ProviderType.repairShop),
                  ),
                  const SizedBox(height: 12),
                  _TypeCard(
                    type: ProviderType.bikeShop,
                    icon: Icons.storefront_rounded,
                    title: l10n.providerTypeBikeShop,
                    description: l10n.providerTypeBikeShopDesc,
                    color: AppColors.layerShop,
                    isSelected: _selected == ProviderType.bikeShop,
                    onTap: () =>
                        setState(() => _selected = ProviderType.bikeShop),
                  ),
                  const SizedBox(height: 12),
                  _TypeCard(
                    type: ProviderType.chargingLocation,
                    icon: Icons.ev_station_rounded,
                    title: l10n.providerTypeChargingLocation,
                    description: l10n.providerTypeChargingLocationDesc,
                    color: AppColors.layerCharging,
                    isSelected: _selected == ProviderType.chargingLocation,
                    onTap: () => setState(
                        () => _selected = ProviderType.chargingLocation),
                  ),
                  const SizedBox(height: 12),
                  _TypeCard(
                    type: ProviderType.servicePoint,
                    icon: Icons.handyman_rounded,
                    title: l10n.providerTypeServicePoint,
                    description: l10n.providerTypeServicePointDesc,
                    color: AppColors.layerService,
                    isSelected: _selected == ProviderType.servicePoint,
                    onTap: () =>
                        setState(() => _selected = ProviderType.servicePoint),
                  ),
                  const SizedBox(height: 12),
                  _TypeCard(
                    type: ProviderType.rental,
                    icon: Icons.pedal_bike_rounded,
                    title: l10n.providerTypeRental,
                    description: l10n.providerTypeRentalDesc,
                    color: AppColors.layerShop,
                    isSelected: _selected == ProviderType.rental,
                    onTap: () =>
                        setState(() => _selected = ProviderType.rental),
                  ),
                ],
              ),
            ),
          ),
          // Bottom button
          SafeArea(
            child: Padding(
              padding:
                  EdgeInsets.fromLTRB(20, 12, 20, bottomPad > 0 ? 0 : 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _selected != null
                      ? () => context.push(
                            AppRoutes.providerOnboarding,
                            extra: _selected,
                          )
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                    disabledBackgroundColor: context.colors.border,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(l10n.continueLabel),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Type Card ────────────────────────────────────────────────────────────────

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.type,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final ProviderType type;
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.labelLarge
                          .copyWith(color: context.colors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(description,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: context.colors.textSecondary)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 24)
            else
              Icon(Icons.radio_button_off_rounded,
                  color: context.colors.border, size: 24),
          ],
        ),
      ),
    );
  }
}
