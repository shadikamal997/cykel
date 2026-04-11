/// CYKEL — Auto Theme Service
/// Automatically switches between light/dark mode based on sunrise/sunset
/// Uses the existing daylight_service.dart for calculations

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'daylight_service.dart';

/// Auto theme mode preference
enum AutoThemeMode {
  /// Follow system setting
  system,
  /// Always light
  light,
  /// Always dark
  dark,
  /// Auto switch at sunrise/sunset
  auto,
}

/// Auto theme notifier that manages theme and periodic checks
class AutoThemeNotifier extends StateNotifier<ThemeMode> {
  AutoThemeNotifier(this._ref) : super(ThemeMode.system) {
    _init();
  }

  final Ref _ref;
  Timer? _checkTimer;
  static const _prefKey = 'auto_theme_mode';
  
  AutoThemeMode _mode = AutoThemeMode.system;
  AutoThemeMode get mode => _mode;

  void _init() {
    _loadPreference();
    // Check every minute if we need to switch themes
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (_) => _checkAndUpdate());
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null) {
        _mode = AutoThemeMode.values.firstWhere(
          (m) => m.name == saved,
          orElse: () => AutoThemeMode.system,
        );
        state = _getEffectiveThemeMode();
      }
    } catch (e) {
      debugPrint('[AutoTheme] Error loading preference: $e');
    }
  }

  /// Set the auto theme mode
  Future<void> setMode(AutoThemeMode mode) async {
    _mode = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, mode.name);
    } catch (e) {
      debugPrint('[AutoTheme] Error saving preference: $e');
    }
    state = _getEffectiveThemeMode();
  }

  /// Get the current effective ThemeMode based on settings and time
  ThemeMode _getEffectiveThemeMode() {
    switch (_mode) {
      case AutoThemeMode.system:
        return ThemeMode.system;
      case AutoThemeMode.light:
        return ThemeMode.light;
      case AutoThemeMode.dark:
        return ThemeMode.dark;
      case AutoThemeMode.auto:
        return _calculateAutoTheme();
    }
  }

  /// Calculate whether to use light or dark based on sunrise/sunset
  ThemeMode _calculateAutoTheme() {
    try {
      // Default to Copenhagen coordinates - user's actual location not critical for theme
      const lat = 55.6761; // Copenhagen
      const lng = 12.5683;
      
      final daylightService = _ref.read(daylightServiceProvider);
      final daylight = daylightService.calculate(latitude: lat, longitude: lng);
      
      // If dark, use dark mode
      return daylight.isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (e) {
      debugPrint('[AutoTheme] Error calculating theme: $e');
      return ThemeMode.system;
    }
  }

  /// Check if theme needs to change and notify
  void _checkAndUpdate() {
    if (_mode == AutoThemeMode.auto) {
      // Update state if it changed
      final newTheme = _getEffectiveThemeMode();
      if (state != newTheme) {
        state = newTheme;
      }
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }
}

/// Provider for auto theme notifier
final autoThemeNotifierProvider = StateNotifierProvider<AutoThemeNotifier, ThemeMode>((ref) {
  return AutoThemeNotifier(ref);
});

/// Provider for the current auto theme mode
final autoThemeModeProvider = Provider<AutoThemeMode>((ref) {
  return ref.watch(autoThemeNotifierProvider.notifier).mode;
});

/// Provider for the effective theme mode (what should actually be used)
final effectiveThemeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(autoThemeNotifierProvider);
});

/// Provider for next theme change time (for UI display)
final nextThemeChangeProvider = Provider<DateTime?>((ref) {
  final mode = ref.watch(autoThemeModeProvider);
  if (mode != AutoThemeMode.auto) return null;
  
  try {
    // Default to Copenhagen coordinates
    const lat = 55.6761;
    const lng = 12.5683;
    
    final daylightService = ref.read(daylightServiceProvider);
    final daylight = daylightService.calculate(latitude: lat, longitude: lng);
    
    // Return next sunrise or sunset
    final now = DateTime.now();
    if (now.isBefore(daylight.sunrise)) {
      return daylight.sunrise; // Next change is sunrise (dark -> light)
    } else if (now.isBefore(daylight.sunset)) {
      return daylight.sunset; // Next change is sunset (light -> dark)
    } else {
      // After sunset, next change is tomorrow's sunrise
      final tomorrow = daylightService.calculate(
        latitude: lat, 
        longitude: lng,
        date: now.add(const Duration(days: 1)),
      );
      return tomorrow.sunrise;
    }
  } catch (e) {
    return null;
  }
});
