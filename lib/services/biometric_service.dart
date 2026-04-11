/// Biometric Authentication Service
///
/// Handles Face ID, Touch ID, and Android biometric authentication.
/// Stores user preference for biometric lock and authenticates on app resume.

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  BiometricService._();
  static final instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();
  static const String _biometricEnabledKey = 'biometric_lock_enabled';

  /// Check if device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Check if biometrics are enrolled (fingerprint/face registered)
  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  /// Get available biometric types (face, fingerprint, iris, etc.)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Check if biometric lock is enabled by user
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  /// Enable or disable biometric lock
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  /// Authenticate user with biometrics
  ///
  /// Returns `true` if authentication succeeded, `false` otherwise.
  /// Throws [PlatformException] if biometric hardware is not available.
  Future<bool> authenticate({
    String localizedReason = 'Please authenticate to access CYKEL',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final canAuth = await canCheckBiometrics();
      if (!canAuth) {
        return false;
      }

      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      // Handle specific error codes
      if (e.code == 'NotAvailable') {
        return false; // Biometrics not available
      } else if (e.code == 'LockedOut') {
        return false; // Too many failed attempts
      } else if (e.code == 'PermanentlyLockedOut') {
        return false; // Biometrics disabled
      }
      rethrow;
    }
  }

  /// Check if authentication should be required
  ///
  /// Returns `true` if biometric lock is enabled AND available on device.
  Future<bool> shouldAuthenticate() async {
    final enabled = await isBiometricEnabled();
    if (!enabled) return false;

    final canAuth = await canCheckBiometrics();
    return canAuth;
  }

  /// Get a user-friendly description of available biometric types
  Future<String> getBiometricTypeDescription() async {
    final types = await getAvailableBiometrics();
    
    if (types.isEmpty) {
      return 'No biometrics available';
    }
    
    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (types.contains(BiometricType.iris)) {
      return 'Iris scan';
    } else {
      return 'Biometric authentication';
    }
  }

  /// Stop biometric authentication and cancel pending prompts
  Future<void> stopAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } on PlatformException {
      // Ignore errors when stopping auth
    }
  }
}
