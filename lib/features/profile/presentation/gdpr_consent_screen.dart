/// CYKEL — GDPR Consent Screen (Phase 5)
///
/// Shown on first launch after sign-in. Users must acknowledge data usage
/// before proceeding to the app. Analytics and mobility aggregation are
/// optional opt-ins; core functionality always works without them.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../data/gdpr_provider.dart';

class GdprConsentScreen extends ConsumerStatefulWidget {
  const GdprConsentScreen({super.key});

  @override
  ConsumerState<GdprConsentScreen> createState() => _GdprConsentScreenState();
}

class _GdprConsentScreenState extends ConsumerState<GdprConsentScreen> {
  bool _analyticsEnabled   = false;
  bool _aggregationEnabled = false;
  bool _submitting         = false;

  @override
  Widget build(BuildContext context) {
    final l10n   = context.l10n;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, topPad + 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text('🔒', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(l10n.gdprTitle,
                  style: AppTextStyles.headline1.copyWith(fontSize: 26)),
              const SizedBox(height: 8),
              Text(
                l10n.gdprSubtitle,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: context.colors.textSecondary),
              ),
              const SizedBox(height: 28),

              // Core data notice
              _DataCard(
                icon: '📍',
                title: l10n.gdprLocationTitle,
                body: l10n.gdprLocationBody,
                mandatory: true,
              ),
              const SizedBox(height: 12),
              _DataCard(
                icon: '🚲',
                title: l10n.gdprRidesTitle,
                body: l10n.gdprRidesBody,
                mandatory: true,
              ),
              const SizedBox(height: 20),

              // Optional opt-ins
              Text(
                l10n.gdprOptionalTitle.toUpperCase(),
                style: AppTextStyles.labelSmall
                    .copyWith(letterSpacing: 1.0, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),

              // Analytics
              _ConsentToggle(
                icon: '📊',
                title: l10n.gdprAnalyticsTitle,
                body: l10n.gdprAnalyticsBody,
                value: _analyticsEnabled,
                onChanged: (v) => setState(() => _analyticsEnabled = v),
              ),
              const SizedBox(height: 10),

              // Mobility aggregation
              _ConsentToggle(
                icon: '🗺️',
                title: l10n.gdprAggregationTitle,
                body: l10n.gdprAggregationBody,
                value: _aggregationEnabled,
                onChanged: (v) => setState(() => _aggregationEnabled = v),
              ),
              const SizedBox(height: 28),

              // Privacy notice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.gdprPrivacyNotice,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: context.colors.textSecondary),
                ),
              ),
              const SizedBox(height: 24),

              // Accept button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _accept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: AppTextStyles.labelLarge,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(l10n.gdprAccept),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _accept() async {
    setState(() => _submitting = true);
    try {
      await ref.read(gdprProvider.notifier).acceptConsent(
            analytics:   _analyticsEnabled,
            aggregation: _aggregationEnabled,
          );
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.failedToSaveConsent(e.toString()))));
      }
    }
  }
}

// ─── Data Card (mandatory) ────────────────────────────────────────────────────

class _DataCard extends StatelessWidget {
  const _DataCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.mandatory,
  });
  final String icon;
  final String title;
  final String body;
  final bool mandatory;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(title,
                            style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700))),
                    if (mandatory)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (context.colors.textPrimary).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          context.l10n.requiredBadge,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: context.colors.textPrimary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(body,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: context.colors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Consent Toggle ──────────────────────────────────────────────────────────

class _ConsentToggle extends StatelessWidget {
  const _ConsentToggle({
    required this.icon,
    required this.title,
    required this.body,
    required this.value,
    required this.onChanged,
  });
  final String icon;
  final String title;
  final String body;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: value
            ? AppColors.primary.withValues(alpha: 0.07)
            : context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? AppColors.primary.withValues(alpha: 0.5) : context.colors.border,
          width: value ? 1.5 : 0.8,
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(body,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: context.colors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
            activeThumbColor: Colors.white,
            inactiveTrackColor: context.colors.border,
          ),
        ],
      ),
    );
  }
}
