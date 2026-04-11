/// CYKEL — Dashboard Settings Screen
/// Lets users customize which sections appear on the home screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_gate.dart';
import '../../../services/dashboard_settings_provider.dart';
import '../../../core/l10n/l10n.dart';
import '../../../services/subscription_providers.dart';

class DashboardSettingsScreen extends ConsumerWidget {
  const DashboardSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    if (!isPremium) {
      return PremiumGateScreen(
        screenTitle: context.l10n.dashboardSettingsTitle,
        featureDescription: context.l10n.premiumDashboardBody,
        child: const SizedBox.shrink(),
      );
    }
    final asyncSettings = ref.watch(dashboardSettingsProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        title: Text(context.l10n.dashboardSettingsTitle, style: AppTextStyles.headline3),
        leading: BackButton(
          color: context.colors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: asyncSettings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.genericError(e.toString()))),
        data: (settings) => _Body(settings: settings),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.settings});
  final DashboardSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(dashboardSettingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionHeader(title: context.l10n.homeScreenSections),
        const SizedBox(height: 8),
        Text(
          context.l10n.homeScreenSectionsDesc,
          style: AppTextStyles.bodySmall.copyWith(color: context.colors.textSecondary),
        ),
        const SizedBox(height: 16),

        // Monthly Challenge
        SwitchListTile(
          tileColor: isDark ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(context.l10n.sectionMonthlyChallenge, style: AppTextStyles.bodyMedium.copyWith(color: isDark ? Colors.black : Colors.white)),
            subtitle: Text(context.l10n.sectionMonthlyChallengeDesc,
                style: TextStyle(color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7), fontSize: 12)),
            value: settings.showMonthlyChallenge,
            activeTrackColor: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.5),
            onChanged: (v) => notifier.setShowMonthlyChallenge(v),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),

        const SizedBox(height: 8),
        // E-bike Range
        SwitchListTile(
          tileColor: isDark ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(context.l10n.sectionEbikeRange, style: AppTextStyles.bodyMedium.copyWith(color: isDark ? Colors.black : Colors.white)),
            subtitle: Text(context.l10n.sectionEbikeRangeDesc,
                style: TextStyle(color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7), fontSize: 12)),
            value: settings.showEbikeRange,
            activeTrackColor: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.5),
            onChanged: (v) => notifier.setShowEbikeRange(v),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),

        const SizedBox(height: 8),
        // Quick Routes
        SwitchListTile(
          tileColor: isDark ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(context.l10n.sectionQuickRoutesLabel, style: AppTextStyles.bodyMedium.copyWith(color: isDark ? Colors.black : Colors.white)),
            subtitle: Text(context.l10n.sectionQuickRoutesDesc,
                style: TextStyle(color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7), fontSize: 12)),
            value: settings.showQuickRoutes,
            activeTrackColor: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.5),
            onChanged: (v) => notifier.setShowQuickRoutes(v),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),

        const SizedBox(height: 8),
        // Recent Activity
        SwitchListTile(
          tileColor: isDark ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(context.l10n.sectionRecentActivity, style: AppTextStyles.bodyMedium.copyWith(color: isDark ? Colors.black : Colors.white)),
            subtitle: Text(context.l10n.sectionRecentActivityDesc,
                style: TextStyle(color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7), fontSize: 12)),
            value: settings.showRecentActivity,
            activeTrackColor: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.5),
            onChanged: (v) => notifier.setShowRecentActivity(v),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),

        const SizedBox(height: 8),
        // Maintenance Reminder
        SwitchListTile(
          tileColor: isDark ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(context.l10n.sectionMaintenanceReminder, style: AppTextStyles.bodyMedium.copyWith(color: isDark ? Colors.black : Colors.white)),
            subtitle: Text(context.l10n.sectionMaintenanceReminderDesc,
                style: TextStyle(color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7), fontSize: 12)),
            value: settings.showMaintenanceReminder,
            activeTrackColor: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.5),
            onChanged: (v) => notifier.setShowMaintenanceReminder(v),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),

        const SizedBox(height: 40),
        Text(
          context.l10n.changesImmediate,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: AppTextStyles.headline3.copyWith(fontSize: 15));
  }
}
