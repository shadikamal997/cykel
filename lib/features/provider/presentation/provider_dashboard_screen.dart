/// CYKEL — Provider Dashboard Home Screen
/// Shows verification status banner, analytics overview cards,
/// and quick-action tiles for managing the provider listing.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_providers.dart';
import '../domain/provider_enums.dart';
import '../domain/provider_model.dart';
import '../providers/provider_providers.dart';

class ProviderDashboardScreen extends ConsumerWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final provider = ref.watch(myProviderProvider);
    final analyticsAsync = ref.watch(myProviderAnalyticsProvider);

    if (provider == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: Text(l10n.dashboardTitle, style: AppTextStyles.headline3),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storefront_outlined,
                    size: 56, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  l10n.noProviderFound,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.provider),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    foregroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white,
                    elevation: 0,
                  ),
                  child: Text(l10n.becomeProvider),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final analytics = analyticsAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.surface,
            pinned: true,
            title: Text(l10n.dashboardTitle, style: AppTextStyles.headline3),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push(AppRoutes.providerSettings),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Welcome ───────────────────────────────────────────────
                Text(
                  l10n.dashboardWelcome(
                      user?.displayName ?? provider.contactName),
                  style: AppTextStyles.headline3,
                ),
                const SizedBox(height: 4),
                _StatusChip(provider: provider),
                const SizedBox(height: 16),

                // ── Verification banner ───────────────────────────────────
                if (provider.verificationStatus ==
                    VerificationStatus.pending)
                  _Banner(
                    icon: Icons.hourglass_top_rounded,
                    text: l10n.dashboardVerificationBanner,
                  ),
                if (provider.verificationStatus ==
                    VerificationStatus.rejected)
                  _Banner(
                    icon: Icons.error_outline_rounded,
                    text: l10n.dashboardRejectedBanner,
                  ),
                if (provider.verificationStatus != VerificationStatus.approved)
                  const SizedBox(height: 16),

                // ── Analytics cards ───────────────────────────────────────
                Text(l10n.dashboardOverview,
                    style: AppTextStyles.labelMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.visibility_outlined,
                        label: l10n.dashboardProfileViews,
                        value: '${analytics?.profileViews ?? 0}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.navigation_outlined,
                        label: l10n.dashboardNavRequests,
                        value: '${analytics?.navigationRequests ?? 0}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.bookmark_outline_rounded,
                        label: l10n.dashboardSavedBy,
                        value: '${analytics?.savedByUsersCount ?? 0}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Quick actions ─────────────────────────────────────────
                Text(l10n.dashboardQuickActions,
                    style: AppTextStyles.labelMedium),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.edit_outlined,
                  label: l10n.editBusinessInfo,
                  onTap: () => context.push(AppRoutes.providerEdit),
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.schedule_outlined,
                  label: l10n.manageHours,
                  onTap: () => context.push(AppRoutes.providerHours),
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.photo_library_outlined,
                  label: l10n.managePhotos,
                  onTap: () => context.push(AppRoutes.providerPhotos),
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.location_on_outlined,
                  label: l10n.manageLocations,
                  onTap: () => context.push(AppRoutes.providerLocations),
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.sell_outlined,
                  label: l10n.manageListings,
                  onTap: () => context.push(AppRoutes.providerListings),
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.settings_outlined,
                  label: l10n.providerSettings,
                  onTap: () => context.push(AppRoutes.providerSettings),
                ),

                const SizedBox(height: 24),

                // ── Business card preview ─────────────────────────────────
                _BusinessCard(provider: provider),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status Chip ──────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.provider});
  final CykelProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final label = switch (provider.verificationStatus) {
      VerificationStatus.pending => l10n.verificationPending,
      VerificationStatus.approved => provider.temporarilyClosed
          ? l10n.providerTemporarilyClosed
          : provider.isActive
              ? l10n.providerActive
              : l10n.providerInactive,
      VerificationStatus.rejected => l10n.verificationRejected,
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: isDark ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}

// ─── Banner ───────────────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.text,
  });
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: isDark ? Colors.white : Colors.black, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: AppTextStyles.bodySmall.copyWith(color: isDark ? Colors.white : Colors.black)),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isDark ? Colors.white : Colors.black, size: 22),
          const SizedBox(height: 10),
          Text(value, style: AppTextStyles.headline2),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Action Tile ──────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: isDark ? Colors.black : Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label, style: AppTextStyles.bodyMedium),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Business Card Preview ────────────────────────────────────────────────────

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({required this.provider});
  final CykelProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final typeLabel = switch (provider.providerType) {
      ProviderType.repairShop => l10n.providerTypeRepairShop,
      ProviderType.bikeShop => l10n.providerTypeBikeShop,
      ProviderType.chargingLocation => l10n.providerTypeChargingLocation,
      ProviderType.servicePoint => l10n.providerTypeServicePoint,
      ProviderType.rental => l10n.providerTypeRental,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Logo or placeholder
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: provider.logoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          provider.logoUrl!,
                          fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                              Icon(Icons.storefront_rounded,
                                  color: isDark ? Colors.white : Colors.white, size: 24),
                        ),
                      )
                    : Icon(Icons.storefront_rounded,
                        color: isDark ? Colors.white : Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.businessName,
                        style: AppTextStyles.headline3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(typeLabel,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.7))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          _InfoRow(Icons.location_on_outlined,
              '${provider.streetAddress}, ${provider.postalCode} ${provider.city}'),
          const SizedBox(height: 6),
          _InfoRow(Icons.phone_outlined, provider.phone),
          const SizedBox(height: 6),
          _InfoRow(Icons.email_outlined, provider.email),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
