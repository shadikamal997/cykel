/// CYKEL — Reusable Premium Feature Gate Widget
/// Wrap any premium-only screen or section with this widget.
/// Shows a branded upgrade prompt when the user is on the free plan.
///
/// Usage:
/// ```dart
/// PremiumGate(
///   title: 'Voice Settings',
///   body: 'Custom voice styles are a Premium feature.',
///   child: const VoiceSettingsContent(),
/// )
/// ```
/// Or as a full-screen gate (with its own Scaffold):
/// ```dart
/// PremiumGate.screen(
///   screenTitle: 'Voice Settings',
///   body: 'Custom voice styles are a Premium feature.',
/// )
/// ```

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/subscription_providers.dart';

/// Inline gate — shows [child] if premium, otherwise shows an upgrade card.
class PremiumGate extends ConsumerWidget {
  const PremiumGate({
    super.key,
    required this.child,
    this.featureDescription,
  });

  /// The premium content to show when the user is subscribed.
  final Widget child;

  /// Optional description shown in the upgrade prompt.
  /// Falls back to the generic `premiumFeatureBody` l10n string.
  final String? featureDescription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    if (isPremium) return child;
    return _UpgradePrompt(description: featureDescription);
  }
}

/// Full-screen gate — a standalone Scaffold with AppBar + upgrade prompt.
class PremiumGateScreen extends ConsumerWidget {
  const PremiumGateScreen({
    super.key,
    required this.screenTitle,
    required this.child,
    this.featureDescription,
  });

  /// Title shown in the AppBar.
  final String screenTitle;

  /// The premium content to show when the user is subscribed.
  final Widget child;

  /// Optional description shown in the upgrade prompt.
  final String? featureDescription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    if (isPremium) return child;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(screenTitle, style: AppTextStyles.headline3),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: _UpgradePrompt(description: featureDescription),
        ),
      ),
    );
  }
}

// ─── Shared upgrade prompt ───────────────────────────────────────────────────

class _UpgradePrompt extends StatelessWidget {
  const _UpgradePrompt({this.description});
  final String? description;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.workspace_premium_rounded,
            size: 64, color: AppColors.primary),
        const SizedBox(height: 16),
        Text(
          l10n.premiumFeature,
          style:
              AppTextStyles.headline3.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          description ?? l10n.premiumFeatureBody,
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => context.push(AppRoutes.profileSubscription),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          ),
          child: Text(l10n.upgradeToPremium,
              style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
