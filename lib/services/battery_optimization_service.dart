// lib/services/battery_optimization_service.dart
//
// Prompts the user to exempt CYKEL from Android battery optimizations.
// Without this, Android Doze mode can suspend GPS and TTS mid-ride.
// No-op on iOS / non-Android.

import 'dart:io' show Platform;
import 'package:flutter/services.dart';

const _channel = MethodChannel('dk.cykel.cykel/system');

/// Ask Android to ignore battery optimizations for this app.
/// Shows the system dialog once; subsequent calls are silent if already exempt.
Future<void> requestIgnoreBatteryOptimizations() async {
  if (!Platform.isAndroid) return;
  try {
    await _channel.invokeMethod<void>('requestIgnoreBatteryOptimizations');
  } on PlatformException catch (_) {
    // Older devices / restricted profiles may not support this intent — safe to ignore.
  }
}

/// Returns true if Android is already ignoring battery optimizations for us.
Future<bool> isIgnoringBatteryOptimizations() async {
  if (!Platform.isAndroid) return true;
  try {
    return await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations') ?? false;
  } on PlatformException catch (_) {
    return false;
  }
}
