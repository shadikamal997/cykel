/// CYKEL — Profile & Settings Screen
/// Phase 2: User profile, saved places, bikes, account management.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/optimized_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/providers/auth_providers.dart';
import '../../provider/providers/provider_providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cykel_button.dart';
import '../../../services/auto_theme_service.dart';
import '../../../services/subscription_providers.dart';
import '../data/bikes_provider.dart';
import '../data/gdpr_provider.dart';
import '../../../core/services/consent_manager.dart';
import '../../../core/services/data_export_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final l10n = context.l10n;
    final topPad = MediaQuery.of(context).padding.top;
    final bikeCount =
        ref.watch(bikesProvider).valueOrNull?.length ?? 0;
    final locale = ref.watch(localeProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final planLabel = isPremium ? l10n.premiumPlan : l10n.freePlan;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: context.colors.surface,
              padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 16),
              child: Column(
                children: [
                  // Back + title + settings row
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.arrow_back_rounded, size: 24, color: context.colors.textPrimary),
                        tooltip: l10n.goBack,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(l10n.profile, style: AppTextStyles.headline2),
                      ),
                      IconButton(
                        onPressed: () => context.push(AppRoutes.profileEdit),
                        icon: Icon(Icons.edit_outlined, size: 22, color: context.colors.textSecondary),
                        tooltip: l10n.editProfile,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // ── Modern Profile Card ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: Theme.of(context).brightness == Brightness.dark
                            ? [const Color(0xFF2D3748), const Color(0xFF1A202C)]
                            : [const Color(0xFF4A7C59), const Color(0xFF3D6B4A)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (Theme.of(context).brightness == Brightness.dark
                              ? Colors.black
                              : const Color(0xFF4A7C59)).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Avatar with ring
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: user?.photoUrl != null
                                ? ClipOval(
                                    child: OptimizedAvatarImage(
                                      imageUrl: user!.photoUrl!,
                                      radius: 36,
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      (user?.displayName.isNotEmpty == true)
                                          ? user!.displayName[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? const Color(0xFF2D3748)
                                            : const Color(0xFF4A7C59),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // User info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? l10n.defaultRiderName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              // Plan badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isPremium 
                                      ? Colors.amber.shade600
                                      : Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isPremium) ...[
                                      const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      planLabel,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
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
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // ── Quick Stats Row ─────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _QuickStatCard(
                          icon: Icons.directions_bike_rounded,
                          value: bikeCount.toString(),
                          label: l10n.myBikes,
                          isDark: Theme.of(context).brightness == Brightness.dark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickStatCard(
                          icon: Icons.route_rounded,
                          value: '0',
                          label: l10n.ridesLabel,
                          isDark: Theme.of(context).brightness == Brightness.dark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickStatCard(
                          icon: Icons.bookmark_rounded,
                          value: '0',
                          label: l10n.marketplaceSaved,
                          isDark: Theme.of(context).brightness == Brightness.dark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Settings Sections ───────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Upgrade to Premium banner (Free users only)
                if (!isPremium)
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.profileSubscription),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.buttonPrimary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.workspace_premium_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.upgradeToPremium,
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.premiumBannerSubtitle,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: Colors.white70, size: 22),
                        ],
                      ),
                    ),
                  ),

                // Account section
                _SettingsSection(
                  title: l10n.account,
                  tiles: [
                    _SettingsTile(
                      icon: Icons.person_outline_rounded,
                      label: l10n.editProfile,
                      onTap: () => context.push(AppRoutes.profileEdit),
                    ),
                    _SettingsTile(
                      icon: Icons.place_outlined,
                      label: l10n.savedPlaces,
                      onTap: () => context.push(AppRoutes.profileSavedPlaces),
                    ),
                    _SettingsTile(
                      icon: Icons.directions_bike_outlined,
                      label: l10n.myBikes,
                      trailing: _Badge('$bikeCount'),
                      onTap: () => context.push(AppRoutes.profileBikes),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Community & Gamification section
                _SettingsSection(
                  title: l10n.community,
                  tiles: [
                    _SettingsTile(
                      icon: Icons.emoji_events_outlined,
                      label: l10n.challenges,
                      onTap: () => context.push(AppRoutes.challenges),
                    ),
                    _SettingsTile(
                      icon: Icons.workspace_premium_outlined,
                      label: l10n.badges,
                      onTap: () => context.push(AppRoutes.badges),
                    ),
                    _SettingsTile(
                      icon: Icons.leaderboard_outlined,
                      label: l10n.leaderboard,
                      onTap: () => context.push(AppRoutes.leaderboard),
                    ),
                    _SettingsTile(
                      icon: Icons.warning_amber_outlined,
                      label: l10n.theftAlerts,
                      onTap: () => context.push(AppRoutes.theftAlerts),
                    ),
                    _SettingsTile(
                      icon: Icons.people_outline,
                      label: l10n.community,
                      onTap: () => context.push(AppRoutes.social),
                    ),
                    _SettingsTile(
                      icon: Icons.route_outlined,
                      label: l10n.aiRouteSuggestions,
                      onTap: () => context.push(AppRoutes.routeSuggestions),
                    ),
                    _SettingsTile(
                      icon: Icons.download_outlined,
                      label: l10n.offlineMaps,
                      onTap: () => context.push(AppRoutes.offlineMaps),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Provider section
                _ProviderSection(),
                const SizedBox(height: 16),

                // Preferences section
                _SettingsSection(
                  title: l10n.preferencesSection,
                  tiles: [
                    _SettingsTile(
                      icon: Icons.notifications_none_rounded,
                      label: l10n.notificationSettings,
                      onTap: () => context.push(AppRoutes.profileNotifications),
                    ),
                    const _ThemeTile(),
                    _SettingsTile(
                      icon: Icons.dashboard_rounded,
                      label: l10n.dashboardLabel,
                      onTap: () => context.push(AppRoutes.profileDashboard),
                    ),
                    _SettingsTile(
                      icon: Icons.record_voice_over_rounded,
                      label: l10n.voiceNavLabel,
                      onTap: () => context.push(AppRoutes.profileVoice),
                    ),
                    _SettingsTile(
                      icon: Icons.receipt_long_rounded,
                      label: l10n.commuterTaxSettings,
                      onTap: () => context.push(AppRoutes.profileCommuterTax),
                    ),
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      label: l10n.languageSettings,
                      trailing: _Badge(
                          locale.languageCode.toUpperCase()),
                      onTap: () => context.push(AppRoutes.profileLanguage),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Subscription section
                _SettingsSection(
                  title: l10n.subscriptionSection,
                  tiles: [
                    _SubscriptionTile(
                      plan: planLabel,
                      isPremium: isPremium,
                      onUpgrade: () =>
                          context.push(AppRoutes.profileSubscription),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Privacy & GDPR section
                _GdprSection(),
                const SizedBox(height: 16),

                // Support section
                _SettingsSection(
                  title: l10n.moreSection,
                  tiles: [
                    _SettingsTile(
                      icon: Icons.help_outline_rounded,
                      label: l10n.helpAndSupport,
                      onTap: () => context.push(AppRoutes.profileHelp),
                    ),
                    _SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      label: l10n.privacySettings,
                      onTap: () => context.push(AppRoutes.profilePrivacy),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Sign out
                CykelButton(
                  label: l10n.signOut,
                  variant: CykelButtonVariant.outline,
                  onPressed: () async {
                    try {
                      await ref
                          .read(authNotifierProvider.notifier)
                          .signOut();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.signOutFailed('$e'))));
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Delete account (destructive)
                TextButton(
                  onPressed: () => _confirmDeleteAccount(context, ref),
                  child: Text(
                    l10n.deleteAccount,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text(l10n.deleteAccountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _doDeleteAccount(context, ref);
            },
            child: Text(
              l10n.yes,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doDeleteAccount(BuildContext context, WidgetRef ref) async {
    // Show loading dialog
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Deleting account...'),
          ],
        ),
      ),
    );

    try {
      await ref.read(authNotifierProvider.notifier).deleteAccount();
      // Success - user will be automatically signed out, so no need to dismiss dialog
    } catch (e) {
      // Dismiss loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.deleteAccountFailed('$e')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

// ─── Settings Section ──────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.tiles});
  final String title;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.0),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.border, width: 0.8),
          ),
          child: Column(
            children: List.generate(tiles.length, (i) {
              return Column(
                children: [
                  tiles[i],
                  if (i < tiles.length - 1)
                    Divider(
                      height: 1,
                      indent: 52,
                      color: context.colors.border,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ─── Settings Tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: AppTextStyles.bodyMedium),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: context.colors.textHint),
          ],
        ),
      ),
    );
  }
}

// ─── Subscription Tile ─────────────────────────────────────────────────────────

class _SubscriptionTile extends StatelessWidget {
  const _SubscriptionTile({
    required this.plan,
    required this.onUpgrade,
    this.isPremium = false,
  });
  final String plan;
  final VoidCallback onUpgrade;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            isPremium
                ? Icons.workspace_premium_rounded
                : Icons.star_border_rounded,
            size: 20,
            color: isDark ? Colors.white : Colors.black,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(context.l10n.currentPlan, style: AppTextStyles.bodyMedium),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              plan,
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onUpgrade,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isPremium ? context.l10n.manageButton : context.l10n.upgradeButton,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── GDPR / Privacy Section ───────────────────────────────────────────────────

class _GdprSection extends ConsumerWidget {
  const _GdprSection();
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final gdprAsync = ref.watch(gdprProvider);
    final state = gdprAsync.valueOrNull;

    if (state == null) return const SizedBox.shrink();

    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, prefsSnapshot) {
        if (!prefsSnapshot.hasData) return const SizedBox.shrink();
        
        final consentManager = ConsentManager(prefsSnapshot.data!);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                l10n.gdprSectionTitle.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.0),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.border, width: 0.8),
              ),
              child: Column(
                children: [
                  // Location consent
                  FutureBuilder<bool>(
                    future: consentManager.hasLocationConsent,
                    builder: (context, snapshot) {
                      return _GdprToggleTile(
                        icon: Icons.location_on_outlined,
                        label: 'Location Services (Required)',
                        value: snapshot.data ?? true,
                        onChanged: (v) async {
                          await consentManager.setLocationConsent(v);
                          (context as Element).markNeedsBuild();
                        },
                      );
                    },
                  ),
                  Divider(height: 1, indent: 52, color: context.colors.border),
                  // Analytics toggle
                  _GdprToggleTile(
                    icon: Icons.bar_chart_rounded,
                    label: l10n.gdprAnalyticsTitle,
                    value: state.analyticsEnabled,
                    onChanged: (v) =>
                        ref.read(gdprProvider.notifier).updateAnalytics(v),
                  ),
                  Divider(height: 1, indent: 52, color: context.colors.border),
                  // Marketing consent
                  FutureBuilder<bool>(
                    future: consentManager.hasMarketingConsent,
                    builder: (context, snapshot) {
                      return _GdprToggleTile(
                        icon: Icons.campaign_outlined,
                        label: 'Marketing Communications',
                        value: snapshot.data ?? false,
                        onChanged: (v) async {
                          await consentManager.setMarketingConsent(v);
                          (context as Element).markNeedsBuild();
                        },
                      );
                    },
                  ),
                  Divider(height: 1, indent: 52, color: context.colors.border),
                  // Aggregation toggle
                  _GdprToggleTile(
                    icon: Icons.map_outlined,
                    label: l10n.gdprAggregationTitle,
                    value: state.aggregationEnabled,
                    onChanged: (v) =>
                        ref.read(gdprProvider.notifier).updateAggregation(v),
                  ),
                  Divider(height: 1, indent: 52, color: context.colors.border),
                  // Export data
                  _SettingsTile(
                    icon: Icons.download_rounded,
                    label: l10n.exportMyData,
                    onTap: () => _exportUserData(context, ref),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportUserData(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    
    // Show loading dialog
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Use DataExportService for local GDPR-compliant data export
      final exportService = DataExportService();
      await exportService.exportUserData();
      
      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.dataExported)),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportFailed('$e'))),
        );
      }
    }
  }
}

class _GdprToggleTile extends StatelessWidget {
  const _GdprToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}

// ─── Badge ────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
      ),
    );
  }
}

// ─── Provider Section ─────────────────────────────────────────────────────────

class _ProviderSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isProvider = ref.watch(isProviderOwnerProvider);

    return _SettingsSection(
      title: l10n.providerSection,
      tiles: [
        _SettingsTile(
          icon: isProvider
              ? Icons.dashboard_outlined
              : Icons.storefront_outlined,
          label: isProvider
              ? l10n.providerDashboard
              : l10n.becomeProvider,
          onTap: () => context.push(
            isProvider ? AppRoutes.providerDashboard : AppRoutes.provider,
          ),
        ),
      ],
    );
  }
}

// ─── Theme Toggle Tile ───────────────────────────────────────────────────────

class _ThemeTile extends ConsumerWidget {
  const _ThemeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final autoMode = ref.watch(autoThemeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String label;
    IconData icon;
    
    switch (autoMode) {
      case AutoThemeMode.light:
        label = l10n.lightTheme;
        icon = Icons.light_mode_rounded;
        break;
      case AutoThemeMode.dark:
        label = l10n.darkTheme;
        icon = Icons.dark_mode_rounded;
        break;
      case AutoThemeMode.system:
        label = l10n.systemTheme;
        icon = Icons.brightness_auto_rounded;
        break;
      case AutoThemeMode.auto:
        label = l10n.autoTheme;
        icon = Icons.wb_twilight_rounded;
        break;
    }

    return Material(
      color: context.colors.surface,
      child: InkWell(
        onTap: () => _showThemeDialog(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: isDark ? Colors.white : Colors.black, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(label, style: AppTextStyles.bodyMedium),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: context.colors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currentMode = ref.read(autoThemeModeProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.chooseTheme),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeOption(
              title: l10n.lightTheme,
              icon: Icons.light_mode_rounded,
              isSelected: currentMode == AutoThemeMode.light,
              onTap: () {
                ref.read(autoThemeNotifierProvider.notifier).setMode(AutoThemeMode.light);
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              title: l10n.darkTheme,
              icon: Icons.dark_mode_rounded,
              isSelected: currentMode == AutoThemeMode.dark,
              onTap: () {
                ref.read(autoThemeNotifierProvider.notifier).setMode(AutoThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              title: l10n.systemTheme,
              subtitle: l10n.followsDeviceSettings,
              icon: Icons.brightness_auto_rounded,
              isSelected: currentMode == AutoThemeMode.system,
              onTap: () {
                ref.read(autoThemeNotifierProvider.notifier).setMode(AutoThemeMode.system);
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              title: l10n.autoTheme,
              subtitle: l10n.changesAtSunriseSunset,
              icon: Icons.wb_twilight_rounded,
              isSelected: currentMode == AutoThemeMode.auto,
              onTap: () {
                ref.read(autoThemeNotifierProvider.notifier).setMode(AutoThemeMode.auto);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : context.colors.textSecondary,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quick Stat Card Widget ────────────────────────────────────────────────────
class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D3748) : const Color(0xFFF4F5F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF4A5568) : const Color(0xFFE9ECE6),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 22,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4A7C59),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B6B6B),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}