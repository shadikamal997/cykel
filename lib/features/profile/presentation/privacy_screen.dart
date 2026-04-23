/// CYKEL — Privacy Settings Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/gdpr_provider.dart';
import 'privacy_policy_screen.dart';
import '../../../services/biometric_service.dart';

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final gdprAsync = ref.watch(gdprProvider);
    final state = gdprAsync.valueOrNull;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(l10n.privacyTitle),
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Data toggles
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              l10n.gdprSectionTitle.toUpperCase(),
              style:
                  AppTextStyles.labelSmall.copyWith(letterSpacing: 1.0),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colors.border, width: 0.8),
            ),
            child: state == null
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child:
                        Center(child: CircularProgressIndicator()))
                : Column(children: [
                    _ConsentTile(
                      icon: Icons.bar_chart_rounded,
                      label: l10n.gdprAnalyticsTitle,
                      subtitle: l10n.gdprAnalyticsBody,
                      value: state.analyticsEnabled,
                      onChanged: (v) =>
                          ref.read(gdprProvider.notifier).updateAnalytics(v),
                    ),
                    Divider(
                        height: 1, indent: 52, color: context.colors.border),
                    _ConsentTile(
                      icon: Icons.map_outlined,
                      label: l10n.gdprAggregationTitle,
                      subtitle: l10n.gdprAggregationBody,
                      value: state.aggregationEnabled,
                      onChanged: (v) =>
                          ref.read(gdprProvider.notifier).updateAggregation(v),
                    ),
                  ]),
          ),
          const SizedBox(height: 16),

          // Biometric lock toggle
          _BiometricLockSection(),
          const SizedBox(height: 16),

          // Privacy policy — opens inline
          Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colors.border, width: 0.8),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                child: Row(children: [
                  const Icon(Icons.policy_outlined,
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Text(l10n.privacyPolicy,
                          style: AppTextStyles.bodyMedium)),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: context.colors.textHint),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Revoke all consent
          TextButton(
            onPressed: () => _revokeConsent(context, ref),
            child: Text(
              l10n.revokeConsent,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _revokeConsent(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.revokeConsent),
        content: Text(l10n.revokeConsentBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.no)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.yes,
                  style: const TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(gdprProvider.notifier).revokeConsent();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.consentRevoked)));
    }
  }
}

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodyMedium),
              Text(subtitle,
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
            inactiveTrackColor: context.colors.border),
      ]),
    );
  }
}

// ─── Biometric Lock Section ──────────────────────────────────────────────────

class _BiometricLockSection extends StatefulWidget {
  @override
  State<_BiometricLockSection> createState() => _BiometricLockSectionState();
}

class _BiometricLockSectionState extends State<_BiometricLockSection> {
  bool _isAvailable = false;
  bool _isEnabled = false;
  String _biometricType = 'Biometric';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    final biometric = BiometricService.instance;
    
    final available = await biometric.canCheckBiometrics();
    final enabled = await biometric.isBiometricEnabled();
    final type = await biometric.getBiometricTypeDescription();
    
    if (mounted) {
      setState(() {
        _isAvailable = available;
        _isEnabled = enabled;
        _biometricType = type;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Enable: require authentication first to verify it works
      final authenticated = await BiometricService.instance.authenticate(
        localizedReason: context.l10n.authenticateBiometric,
      );
      
      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.biometricAuthFailed),
            ),
          );
        }
        return;
      }
    }
    
    await BiometricService.instance.setBiometricEnabled(value);
    
    if (mounted) {
      setState(() {
        _isEnabled = value;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value 
              ? context.l10n.biometricEnabled 
              : context.l10n.biometricDisabled,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.border, width: 0.8),
        ),
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (!_isAvailable) {
      // Show message that biometrics are not available
      return Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.border, width: 0.8),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.fingerprint_rounded,
              size: 20,
              color: context.colors.textSecondary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.noBiometricsTitle,
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.noBiometricsAvailable,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border, width: 0.8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            _biometricType.contains('Face')
              ? Icons.face_rounded
              : Icons.fingerprint_rounded,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.lockWith(_biometricType),
                  style: AppTextStyles.bodyMedium,
                ),
                Text(
                  context.l10n.biometricLockDesc,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isEnabled,
            onChanged: _toggleBiometric,
            activeTrackColor: AppColors.primary,
            activeThumbColor: Colors.white,
            inactiveTrackColor: context.colors.border,
          ),
        ],
      ),
    );
  }
}
