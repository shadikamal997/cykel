/// CYKEL — Voice Settings Provider
/// Persists user preferences for TTS voice style, speech rate, and
/// announcement frequency to SharedPreferences.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Enums ───────────────────────────────────────────────────────────────────

/// Controls how many details are included in voice announcements.
enum VoiceStyle {
  minimal,   // Street name only
  detailed,  // Default: Turn + street + distance
  safety,    // Detailed + extra hazard/safety callouts
}

/// Controls at what distance upcoming turns are announced.
enum AnnouncementFrequency {
  early,    // 800 m / 400 m / 100 m
  normal,   // 500 m / 200 m / 50 m  (default)
  late,     // 200 m / 100 m / 30 m
}

// ─── Model ───────────────────────────────────────────────────────────────────

class VoiceSettings {
  const VoiceSettings({
    this.style = VoiceStyle.detailed,
    this.speechRate = 0.48,
    this.frequency = AnnouncementFrequency.normal,
  });

  final VoiceStyle style;
  final double speechRate;
  final AnnouncementFrequency frequency;

  /// Announcement distances (metres) for 3 phases: far / medium / near.
  List<double> get thresholds => switch (frequency) {
        AnnouncementFrequency.early  => [800, 400, 100],
        AnnouncementFrequency.normal => [500, 200, 50],
        AnnouncementFrequency.late   => [200, 100, 30],
      };

  VoiceSettings copyWith({
    VoiceStyle? style,
    double? speechRate,
    AnnouncementFrequency? frequency,
  }) =>
      VoiceSettings(
        style: style ?? this.style,
        speechRate: speechRate ?? this.speechRate,
        frequency: frequency ?? this.frequency,
      );

  // ─── Persistence keys ──────────────────────────────────────────────────────
  static const _kStyle     = 'voice_style';
  static const _kRate      = 'voice_speech_rate';
  static const _kFrequency = 'voice_frequency';

  Map<String, Object> toPrefsMap() => {
        _kStyle: style.index,
        _kRate: speechRate,
        _kFrequency: frequency.index,
      };

  factory VoiceSettings.fromPrefs(SharedPreferences prefs) => VoiceSettings(
        style: VoiceStyle.values[prefs.getInt(_kStyle) ?? VoiceStyle.detailed.index],
        speechRate: prefs.getDouble(_kRate) ?? 0.48,
        frequency: AnnouncementFrequency.values[
            prefs.getInt(_kFrequency) ?? AnnouncementFrequency.normal.index],
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class VoiceSettingsNotifier extends AsyncNotifier<VoiceSettings> {
  @override
  Future<VoiceSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return VoiceSettings.fromPrefs(prefs);
  }

  Future<void> _save(VoiceSettings s) async {
    state = AsyncData(s);
    final prefs = await SharedPreferences.getInstance();
    for (final entry in s.toPrefsMap().entries) {
      if (entry.value is int) await prefs.setInt(entry.key, entry.value as int);
      if (entry.value is double) {
        await prefs.setDouble(entry.key, entry.value as double);
      }
    }
  }

  Future<void> setStyle(VoiceStyle style) async {
    final current = state.valueOrNull ?? const VoiceSettings();
    await _save(current.copyWith(style: style));
  }

  Future<void> setSpeechRate(double rate) async {
    final current = state.valueOrNull ?? const VoiceSettings();
    await _save(current.copyWith(speechRate: rate.clamp(0.2, 0.9)));
  }

  Future<void> setFrequency(AnnouncementFrequency freq) async {
    final current = state.valueOrNull ?? const VoiceSettings();
    await _save(current.copyWith(frequency: freq));
  }
}

final voiceSettingsProvider =
    AsyncNotifierProvider<VoiceSettingsNotifier, VoiceSettings>(
        VoiceSettingsNotifier.new);
