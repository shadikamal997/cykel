/// CYKEL — TTS Service
/// Voice turn-by-turn instructions via flutter_tts.
/// Guards against repeating the same instruction twice in a row.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'voice_settings_provider.dart';

class TtsService {
  final _tts = FlutterTts();
  String _lastSpoken = '';

  TtsService() {
    _tts
      ..setLanguage('en-US')
      ..setSpeechRate(0.48)
      ..setVolume(1.0)
      ..setPitch(1.05);
    // Use the navigation audio stream so guidance plays through car / Bluetooth
    // headsets and is not silenced when the screen turns off on Android.
    _tts.setAudioAttributesForNavigation();
  }

  Future<void> speak(String text) async {
    if (text.isEmpty || text == _lastSpoken) return;
    _lastSpoken = text;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  Future<void> stop() async {
    _lastSpoken = '';
    try {
      await _tts.stop();
    } catch (_) {}
  }

  void setLanguage(String lang) {
    // 'da' → Danish (full BCP-47); 'en-GB' → British English as fallback;
    // bare 'en' → US English.
    final bcp47 = switch (lang) {
      'da'    => 'da-DK',
      'en-GB' => 'en-GB',
      _       => 'en-US',
    };
    _tts.setLanguage(bcp47);
  }

  /// Applies [settings] to TTS engine: speech rate and pitch based on style.
  Future<void> applyVoiceSettings(VoiceSettings settings) async {
    await _tts.setSpeechRate(settings.speechRate);
    // Safety style: slightly slower and lower pitch for clarity.
    final pitch = switch (settings.style) {
      VoiceStyle.minimal  => 1.1,
      VoiceStyle.detailed => 1.05,
      VoiceStyle.safety   => 0.95,
    };
    await _tts.setPitch(pitch);
  }

  /// Returns true if the TTS engine supports [lang] (bare ISO-639-1 code or
  /// BCP-47 tag). Falls back to true on platforms that don't support the check
  /// so navigation is not blocked on unsupported platforms.
  Future<bool> isLanguageAvailable(String lang) async {
    final bcp47 = switch (lang) {
      'da'    => 'da-DK',
      'en-GB' => 'en-GB',
      _       => 'en-US',
    };
    try {
      final result = await _tts.isLanguageAvailable(bcp47);
      // flutter_tts returns 1 (int) or true (bool) on Android / iOS.
      if (result is bool) return result;
      if (result is int)  return result == 1;
      return true;
    } catch (_) {
      return true; // assume available if check fails
    }
  }
}

final ttsServiceProvider = Provider<TtsService>((ref) {
  final svc = TtsService();
  ref.onDispose(svc.stop);
  return svc;
});
