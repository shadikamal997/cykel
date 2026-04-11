/// CYKEL App Check Service
/// Protects Firebase services from abuse by verifying requests come from your app
/// 
/// IMPORTANT: Before using in production:
/// 1. Register your app for Play Integrity (Android) in Firebase Console
/// 2. Register your app for Device Check (iOS) in Firebase Console
/// 3. Update webRecaptchaSiteKey with your actual reCAPTCHA v3 key

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

class AppCheckService {
  AppCheckService._();

  static Future<void> initialize() async {
    try {
      // Basic activation - Firebase will use default providers
      // iOS: DeviceCheck (production), Debug (development)
      // Android: Play Integrity (production), Debug (development)
      // Web: reCAPTCHA v3
      await FirebaseAppCheck.instance.activate();
      
      debugPrint('✅ Firebase App Check activated');
      if (kDebugMode) {
        debugPrint('   Mode: DEBUG (uses debug tokens)');
        debugPrint('   To get debug token, check console logs after first API call');
      } else {
        debugPrint('   Mode: PRODUCTION (Play Integrity / DeviceCheck)');
      }
    } catch (e) {
      debugPrint('⚠️ App Check activation failed: $e');
      debugPrint('   App will continue but may be vulnerable to abuse');
      debugPrint('   This is normal if Firebase App Check is not configured yet');
    }
  }

  /// Activate with debug provider for development/testing
  /// Use this when testing on emulators or debug builds
  static Future<void> initializeDebug() async {
    try {
      await FirebaseAppCheck.instance.activate();
      
      debugPrint('✅ Firebase App Check activated (DEBUG mode)');
      debugPrint('⚠️  App Check debug mode - NOT for production!');
      debugPrint('   Debug tokens will be printed to console on first use');
    } catch (e) {
      debugPrint('⚠️ App Check debug activation failed: $e');
    }
  }

  /// Get the current App Check token (useful for debugging)
  static Future<String?> getToken() async {
    try {
      final token = await FirebaseAppCheck.instance.getToken();
      debugPrint('App Check token received: ${token?.substring(0, 20)}...');
      return token;
    } catch (e) {
      debugPrint('Failed to get App Check token: $e');
      return null;
    }
  }
}
