/// CYKEL — Voice Settings Screen
/// Lets Premium riders customise TTS style, speech rate, and
/// announcement frequency.

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
        title: Text(context.l10n.voiceSettingsTitle, style: AppTextStyles.headline3),
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
        _SectionHeader(title: context.l10n.voiceStyle),
        const SizedBox(height: 8),
        RadioGroup<VoiceStyle>(
          groupValue: settings.style,
          onChanged: (v) {
            if (v != null) notifier.setStyle(v);
          },
          child: Column(
            children: VoiceStyle.values.map((s) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final desc = switch (s) {
                VoiceStyle.minimal  => context.l10n.voiceMinimalDesc,
                VoiceStyle.detailed => context.l10n.voiceDetailedDesc,
                VoiceStyle.safety   => context.l10n.voiceSafetyDesc,
              };
              final label = switch (s) {
                VoiceStyle.minimal  => context.l10n.voiceMinimal,
                VoiceStyle.detailed => context.l10n.voiceDetailed,
                VoiceStyle.safety   => context.l10n.voiceSafety,
              };
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RadioListTile<VoiceStyle>(
                  tileColor: isDark ? Colors.white : Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: isDark ? Colors.black : Colors.white)),
                  subtitle: Text(desc,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7))),
                  value: s,
                  activeColor: isDark ? Colors.black : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 20),

        // ── Speech Rate ──────────────────────────────────────────────────────
        _SectionHeader(title: context.l10n.speechRate),
        const SizedBox(height: 4),
        Text(
          context.l10n.speechRateDesc,
          style: AppTextStyles.bodySmall.copyWith(color: context.colors.textSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.slow_motion_video_rounded,
                color: context.colors.textSecondary, size: 18),
            Expanded(
              child: Slider(
                value: _speechRate,
                min: 0.2,
                max: 0.9,
                divisions: 7,
                activeColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                label: _rateLabel(_speechRate),
                onChanged: (v) => setState(() => _speechRate = v),
                onChangeEnd: (v) => notifier.setSpeechRate(v),
              ),
            ),
            Icon(Icons.fast_forward_rounded,
                color: context.colors.textSecondary, size: 18),
          ],
        ),
        Center(
          child: Text(
            _rateLabel(_speechRate),
            style: AppTextStyles.bodySmall
                .copyWith(color: context.colors.textSecondary),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
            label: Text(context.l10n.previewVoice),
            style: OutlinedButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final previewText = context.l10n.voicePreviewText;
              final tts = ref.read(ttsServiceProvider);
              final current = ref.read(voiceSettingsProvider).valueOrNull ??
                  const VoiceSettings();
              await tts.applyVoiceSettings(current);
              tts.speak(previewText);
            },
          ),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 20),

        // ── Announcement Frequency ───────────────────────────────────────────
        _SectionHeader(title: context.l10n.announcementDistance),
        const SizedBox(height: 8),
        Text(
          context.l10n.announcementDistanceDesc,
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        RadioGroup<AnnouncementFrequency>(
          groupValue: settings.frequency,
          onChanged: (v) {
            if (v != null) notifier.setFrequency(v);
          },
          child: Column(
            children: AnnouncementFrequency.values.map((f) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final thresholds = VoiceSettings(frequency: f).thresholds;
              final desc =
                  '${thresholds[0].round()} m / ${thresholds[1].round()} m / ${thresholds[2].round()} m';
              final label = switch (f) {
                AnnouncementFrequency.early  => context.l10n.freqEarly,
                AnnouncementFrequency.normal => context.l10n.freqNormal,
                AnnouncementFrequency.late   => context.l10n.freqLate,
              };
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RadioListTile<AnnouncementFrequency>(
                  tileColor: isDark ? Colors.white : Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: isDark ? Colors.black : Colors.white)),
                  subtitle: Text(desc,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7))),
                  value: f,
                  activeColor: isDark ? Colors.black : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              );
            }).toList(),
          ),
        ),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: AppTextStyles.headline3.copyWith(fontSize: 15));
  }
}
