/// CYKEL — Voice Settings Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_gate.dart';
import '../../../services/voice_settings_provider.dart';
import '../../../services/tts_service.dart';
import '../../../core/l10n/l10n.dart';
import '../../../services/subscription_providers.dart';

class VoiceSettingsScreen extends ConsumerWidget {
  const VoiceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    if (!isPremium) {
      return PremiumGateScreen(
        screenTitle: context.l10n.voiceSettingsTitle,
        featureDescription: context.l10n.premiumVoiceBody,
        child: const SizedBox.shrink(),
      );
    }
    final asyncSettings = ref.watch(voiceSettingsProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        title: Text(context.l10n.voiceSettingsTitle),
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
      ),
      body: asyncSettings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.genericError(e.toString()))),
        data: (settings) => _Body(settings: settings),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.settings});
  final VoiceSettings settings;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late double _speechRate;

  @override
  void initState() {
    super.initState();
    _speechRate = widget.settings.speechRate;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(voiceSettingsProvider).valueOrNull ?? widget.settings;
    final notifier = ref.read(voiceSettingsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Voice Style ──────────────────────────────────────────────────────
        _SectionLabel(label: context.l10n.voiceStyle),
        const SizedBox(height: 10),
        ...VoiceStyle.values.map((s) {
          final isSelected = settings.style == s;
          final icon = switch (s) {
            VoiceStyle.minimal  => Icons.volume_down_rounded,
            VoiceStyle.detailed => Icons.volume_up_rounded,
            VoiceStyle.safety   => Icons.health_and_safety_rounded,
          };
          final label = switch (s) {
            VoiceStyle.minimal  => context.l10n.voiceMinimal,
            VoiceStyle.detailed => context.l10n.voiceDetailed,
            VoiceStyle.safety   => context.l10n.voiceSafety,
          };
          final desc = switch (s) {
            VoiceStyle.minimal  => context.l10n.voiceMinimalDesc,
            VoiceStyle.detailed => context.l10n.voiceDetailedDesc,
            VoiceStyle.safety   => context.l10n.voiceSafetyDesc,
          };
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectionCard(
              icon: icon,
              label: label,
              description: desc,
              isSelected: isSelected,
              onTap: () => notifier.setStyle(s),
            ),
          );
        }),

        const SizedBox(height: 8),
        _Divider(),
        const SizedBox(height: 8),

        // ── Speech Rate ──────────────────────────────────────────────────────
        _SectionLabel(label: context.l10n.speechRate),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.speechRateDesc,
                style: AppTextStyles.bodySmall.copyWith(color: context.colors.textSecondary),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.slow_motion_video_rounded, color: context.colors.textSecondary, size: 18),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: context.colors.border,
                        thumbColor: AppColors.primary,
                        overlayColor: AppColors.primary.withValues(alpha: 0.12),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _speechRate,
                        min: 0.2,
                        max: 0.9,
                        divisions: 7,
                        label: _rateLabel(_speechRate),
                        onChanged: (v) => setState(() => _speechRate = v),
                        onChangeEnd: (v) => notifier.setSpeechRate(v),
                      ),
                    ),
                  ),
                  Icon(Icons.fast_forward_rounded, color: context.colors.textSecondary, size: 18),
                ],
              ),
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _rateLabel(_speechRate),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Preview button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
            label: Text(context.l10n.previewVoice),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () async {
              final previewText = context.l10n.voicePreviewText;
              final tts = ref.read(ttsServiceProvider);
              final current = ref.read(voiceSettingsProvider).valueOrNull ?? const VoiceSettings();
              await tts.applyVoiceSettings(current);
              tts.speak(previewText);
            },
          ),
        ),

        const SizedBox(height: 8),
        _Divider(),
        const SizedBox(height: 8),

        // ── Announcement Frequency ───────────────────────────────────────────
        _SectionLabel(label: context.l10n.announcementDistance),
        const SizedBox(height: 4),
        Text(
          context.l10n.announcementDistanceDesc,
          style: AppTextStyles.bodySmall.copyWith(color: context.colors.textSecondary),
        ),
        const SizedBox(height: 12),
        ...AnnouncementFrequency.values.map((f) {
          final isSelected = settings.frequency == f;
          final thresholds = VoiceSettings(frequency: f).thresholds;
          final desc =
              '${thresholds[0].round()} m · ${thresholds[1].round()} m · ${thresholds[2].round()} m';
          final icon = switch (f) {
            AnnouncementFrequency.early  => Icons.notifications_active_rounded,
            AnnouncementFrequency.normal => Icons.notifications_rounded,
            AnnouncementFrequency.late   => Icons.notification_important_rounded,
          };
          final label = switch (f) {
            AnnouncementFrequency.early  => context.l10n.freqEarly,
            AnnouncementFrequency.normal => context.l10n.freqNormal,
            AnnouncementFrequency.late   => context.l10n.freqLate,
          };
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectionCard(
              icon: icon,
              label: label,
              description: desc,
              isSelected: isSelected,
              onTap: () => notifier.setFrequency(f),
            ),
          );
        }),

        const SizedBox(height: 40),
      ],
    );
  }

  String _rateLabel(double rate) {
    if (rate <= 0.3) return context.l10n.rateVerySlow;
    if (rate <= 0.45) return context.l10n.rateSlow;
    if (rate <= 0.55) return context.l10n.rateNormal;
    if (rate <= 0.7) return context.l10n.rateFast;
    return context.l10n.rateVeryFast;
  }
}

// ─── Modern Selection Card ────────────────────────────────────────────────────

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.07)
              : context.colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.6) : context.colors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : context.colors.background,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? AppColors.primary : context.colors.textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Selection indicator — green dot with check when selected
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : context.colors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTextStyles.labelSmall.copyWith(
        color: context.colors.textSecondary,
        letterSpacing: 1.0,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(color: context.colors.border, height: 1),
    );
  }
}
