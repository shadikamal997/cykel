/// CYKEL — Privacy Policy Screen (inline, no external browser needed)

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(l10n.privacyPolicyTitle),
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: _PolicyBody(),
      ),
    );
  }
}

// ─── Policy content ───────────────────────────────────────────────────────────

class _PolicyBody extends StatelessWidget {
  const _PolicyBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _lastUpdated(l10n.lastUpdated(l10n.privacyLastUpdateDate)),
        const SizedBox(height: 20),

        _section(
          context,
          icon: Icons.info_outline_rounded,
          title: l10n.privacySection1Title,
          body: l10n.privacySection1Body,
        ),

        _section(
          context,
          icon: Icons.storage_outlined,
          title: l10n.privacySection2Title,
          body: l10n.privacySection2Body,
        ),

        _section(
          context,
          icon: Icons.tune_rounded,
          title: l10n.privacySection3Title,
          body: l10n.privacySection3Body,
        ),

        _section(
          context,
          icon: Icons.handshake_outlined,
          title: l10n.privacySection4Title,
          body: l10n.privacySection4Body,
        ),

        _section(
          context,
          icon: Icons.share_outlined,
          title: l10n.privacySection5Title,
          body: l10n.privacySection5Body,
        ),

        _section(
          context,
          icon: Icons.lock_clock_outlined,
          title: l10n.privacySection6Title,
          body: l10n.privacySection6Body,
        ),

        _section(
          context,
          icon: Icons.verified_user_outlined,
          title: l10n.privacySection7Title,
          body: l10n.privacySection7Body,
        ),

        _section(
          context,
          icon: Icons.child_care_outlined,
          title: l10n.privacySection8Title,
          body: l10n.privacySection8Body,
        ),

        _section(
          context,
          icon: Icons.update_rounded,
          title: l10n.privacySection9Title,
          body: l10n.privacySection9Body,
        ),

        _section(
          context,
          icon: Icons.alternate_email_rounded,
          title: l10n.privacySection10Title,
          body: l10n.privacySection10Body,
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _lastUpdated(String text) => Builder(
        builder: (context) => Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
        ),
      );

  Widget _section(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.border, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: context.colors.textPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Text(
              body,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.colors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
