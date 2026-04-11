/// CYKEL — Voice Alert Service
/// Text-to-speech announcements for navigation and safety alerts
/// Uses flutter_tts package for device-native TTS

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Voice alert categories
enum VoiceAlertType {
  /// Turn-by-turn navigation
  navigation,
  /// Weather warnings
  weather,
  /// Speed/distance updates
  rideStats,
  /// Hazard alerts
  hazard,
  /// General notifications
  general,
}

/// Voice alert settings
class VoiceAlertSettings {
  const VoiceAlertSettings({
    this.enabled = true,
    this.navigationEnabled = true,
    this.weatherEnabled = true,
    this.rideStatsEnabled = true,
    this.hazardEnabled = true,
    this.volume = 1.0,
    this.speechRate = 0.5,
    this.pitch = 1.0,
    this.language = 'da-DK', // Danish by default
  });

  final bool enabled;
  final bool navigationEnabled;
  final bool weatherEnabled;
  final bool rideStatsEnabled;
  final bool hazardEnabled;
  final double volume;
  final double speechRate;
  final double pitch;
  final String language;

  VoiceAlertSettings copyWith({
    bool? enabled,
    bool? navigationEnabled,
    bool? weatherEnabled,
    bool? rideStatsEnabled,
    bool? hazardEnabled,
    double? volume,
    double? speechRate,
    double? pitch,
    String? language,
  }) {
    return VoiceAlertSettings(
      enabled: enabled ?? this.enabled,
      navigationEnabled: navigationEnabled ?? this.navigationEnabled,
      weatherEnabled: weatherEnabled ?? this.weatherEnabled,
      rideStatsEnabled: rideStatsEnabled ?? this.rideStatsEnabled,
      hazardEnabled: hazardEnabled ?? this.hazardEnabled,
      volume: volume ?? this.volume,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'navigationEnabled': navigationEnabled,
    'weatherEnabled': weatherEnabled,
    'rideStatsEnabled': rideStatsEnabled,
    'hazardEnabled': hazardEnabled,
    'volume': volume,
    'speechRate': speechRate,
    'pitch': pitch,
    'language': language,
  };

  factory VoiceAlertSettings.fromJson(Map<String, dynamic> json) {
    return VoiceAlertSettings(
      enabled: json['enabled'] as bool? ?? true,
      navigationEnabled: json['navigationEnabled'] as bool? ?? true,
      weatherEnabled: json['weatherEnabled'] as bool? ?? true,
      rideStatsEnabled: json['rideStatsEnabled'] as bool? ?? true,
      hazardEnabled: json['hazardEnabled'] as bool? ?? true,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      speechRate: (json['speechRate'] as num?)?.toDouble() ?? 0.5,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
      language: json['language'] as String? ?? 'da-DK',
    );
  }
}

/// Voice alert service for TTS announcements
class VoiceAlertService {
  VoiceAlertService() {
    _init();
  }

  final FlutterTts _tts = FlutterTts();
  VoiceAlertSettings _settings = const VoiceAlertSettings();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  final List<_QueuedAlert> _queue = [];

  VoiceAlertSettings get settings => _settings;

  Future<void> _init() async {
    try {
      await _loadSettings();
      await _configureTts();
      _isInitialized = true;
      debugPrint('[VoiceAlert] Initialized');
    } catch (e) {
      debugPrint('[VoiceAlert] Init error: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('voice_alert_settings');
      if (json != null) {
        final map = Map<String, dynamic>.from(
          (await _decodeJson(json)) as Map,
        );
        _settings = VoiceAlertSettings.fromJson(map);
      }
    } catch (e) {
      debugPrint('[VoiceAlert] Load settings error: $e');
    }
  }

  Future<dynamic> _decodeJson(String json) async {
    // Simple JSON decode (avoiding import of dart:convert in main)
    return compute(_parseJson, json);
  }

  static dynamic _parseJson(String json) {
    // Manual parsing for simple settings
    final map = <String, dynamic>{};
    final cleaned = json.replaceAll('{', '').replaceAll('}', '');
    for (final pair in cleaned.split(',')) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        final key = parts[0].trim().replaceAll('"', '');
        var value = parts[1].trim().replaceAll('"', '');
        if (value == 'true') {
          map[key] = true;
        } else if (value == 'false') {
          map[key] = false;
        } else if (double.tryParse(value) != null) {
          map[key] = double.parse(value);
        } else {
          map[key] = value;
        }
      }
    }
    return map;
  }

  Future<void> _configureTts() async {
    await _tts.setVolume(_settings.volume);
    await _tts.setSpeechRate(_settings.speechRate);
    await _tts.setPitch(_settings.pitch);
    
    // Try to set Danish, fallback to English
    final languages = await _tts.getLanguages;
    if (languages != null) {
      final langList = List<String>.from(languages);
      if (langList.contains(_settings.language)) {
        await _tts.setLanguage(_settings.language);
      } else if (langList.contains('en-US')) {
        await _tts.setLanguage('en-US');
      }
    }

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      _processQueue();
    });
  }

  /// Update settings
  Future<void> updateSettings(VoiceAlertSettings settings) async {
    _settings = settings;
    await _configureTts();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = settings.toJson().toString();
      await prefs.setString('voice_alert_settings', json);
    } catch (e) {
      debugPrint('[VoiceAlert] Save settings error: $e');
    }
  }

  /// Speak an alert
  Future<void> speak(String text, {VoiceAlertType type = VoiceAlertType.general, bool priority = false}) async {
    if (!_settings.enabled) return;
    
    // Check if this type is enabled
    switch (type) {
      case VoiceAlertType.navigation:
        if (!_settings.navigationEnabled) return;
        break;
      case VoiceAlertType.weather:
        if (!_settings.weatherEnabled) return;
        break;
      case VoiceAlertType.rideStats:
        if (!_settings.rideStatsEnabled) return;
        break;
      case VoiceAlertType.hazard:
        if (!_settings.hazardEnabled) return;
        break;
      case VoiceAlertType.general:
        break;
    }

    if (!_isInitialized) {
      await _init();
    }

    if (priority) {
      // Stop current speech and speak immediately
      await stop();
      await _speak(text);
    } else {
      // Add to queue
      _queue.add(_QueuedAlert(text: text, type: type));
      _processQueue();
    }
  }

  Future<void> _speak(String text) async {
    if (_isSpeaking) return;
    _isSpeaking = true;
    await _tts.speak(text);
  }

  void _processQueue() {
    if (_isSpeaking || _queue.isEmpty) return;
    final next = _queue.removeAt(0);
    _speak(next.text);
  }

  /// Stop speaking
  Future<void> stop() async {
    _queue.clear();
    _isSpeaking = false;
    await _tts.stop();
  }

  /// Navigation alerts
  Future<void> speakTurn(String instruction) async {
    await speak(instruction, type: VoiceAlertType.navigation);
  }

  Future<void> speakArrival() async {
    await speak('Du er fremme ved din destination', type: VoiceAlertType.navigation, priority: true);
  }

  /// Weather alerts
  Future<void> speakWeatherWarning(String warning) async {
    await speak('Vejradvarsel: $warning', type: VoiceAlertType.weather, priority: true);
  }

  /// Ride stats
  Future<void> speakDistance(double km) async {
    final kmStr = km.toStringAsFixed(1).replaceAll('.', ',');
    await speak('Du har cyklet $kmStr kilometer', type: VoiceAlertType.rideStats);
  }

  Future<void> speakDuration(int minutes) async {
    if (minutes < 60) {
      await speak('$minutes minutter', type: VoiceAlertType.rideStats);
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      await speak('$hours timer og $mins minutter', type: VoiceAlertType.rideStats);
    }
  }

  /// Hazard alerts
  Future<void> speakHazard(String hazard) async {
    await speak('Advarsel: $hazard', type: VoiceAlertType.hazard, priority: true);
  }

  void dispose() {
    _tts.stop();
  }
}

class _QueuedAlert {
  const _QueuedAlert({required this.text, required this.type});
  final String text;
  final VoiceAlertType type;
}

/// Provider for voice alert service
final voiceAlertServiceProvider = Provider<VoiceAlertService>((ref) {
  final service = VoiceAlertService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for voice alert settings
final voiceAlertSettingsProvider = StateProvider<VoiceAlertSettings>((ref) {
  return ref.watch(voiceAlertServiceProvider).settings;
});
