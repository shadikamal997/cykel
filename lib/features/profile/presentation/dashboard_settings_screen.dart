/// CYKEL — Dashboard Settings Screen
/// Lets users customize which sections appear on the home screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_gate.dart';
import '../../../services/dashboard_settings_provider.dart';
import '../../../services/subscription_providers.dart';
import '../../../core/l10n/l10n.dart';

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

        _ToggleCard(
          icon: Icons.emoji_events_outlined,
          title: context.l10n.sectionMonthlyChallenge,
          subtitle: context.l10n.sectionMonthlyChallengeDesc,
          value: settings.showMonthlyChallenge,
          onChanged: notifier.setShowMonthlyChallenge,
        ),
        const SizedBox(height: 10),
        _ToggleCard(
          icon: Icons.battery_charging_full_outlined,
          title: context.l10n.sectionEbikeRange,
          subtitle: context.l10n.sectionEbikeRangeDesc,
          value: settings.showEbikeRange,
          onChanged: notifier.setShowEbikeRange,
        ),
        const SizedBox(height: 10),
        _ToggleCard(
          icon: Icons.map_outlined,
          title: context.l10n.sectionQuickRoutesLabel,
          subtitle: context.l10n.sectionQuickRoutesDesc,
          value: settings.showQuickRoutes,
          onChanged: notifier.setShowQuickRoutes,
        ),
        const SizedBox(height: 10),
        _ToggleCard(
          icon: Icons.directions_bike_outlined,
          title: context.l10n.sectionRecentActivity,
          subtitle: context.l10n.sectionRecentActivityDesc,
          value: settings.showRecentActivity,
          onChanged: notifier.setShowRecentActivity,
        ),
        const SizedBox(height: 10),
        _ToggleCard(
          icon: Icons.build_outlined,
          title: context.l10n.sectionMaintenanceReminder,
          subtitle: context.l10n.sectionMaintenanceReminderDesc,
          value: settings.showMaintenanceReminder,
          onChanged: notifier.setShowMaintenanceReminder,
        ),

        const SizedBox(height: 40),
        Text(
          context.l10n.changesImmediate,
          style: AppTextStyles.bodySmall.copyWith(color: context.colors.textSecondary),
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

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.colors.textSecondary.withValues(alpha: 0.12),
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        secondary: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(color: context.colors.textSecondary),
        ),
        value: value,
        activeThumbColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }
}
