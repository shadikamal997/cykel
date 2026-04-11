/// CYKEL — Secure Storage Service
/// Encrypted storage for sensitive data (auth tokens, credentials, PII)
/// Uses platform-specific secure storage: Keychain (iOS), KeyStore (Android)

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  SecureStorageService() : _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true, // Auto-reset on decryption errors
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final FlutterSecureStorage _storage;

  // ─── Storage Keys (Centralized) ─────────────────────────────────────────────
  static const _keyAuthToken = 'auth_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserId = 'user_id';
  static const _keyUserEmail = 'user_email';
  static const _keyBiometricEnabled = 'biometric_enabled';
  static const _keyEncryptionKey = 'encryption_key';
  static const _keyLastSyncTime = 'last_sync_time';

  // ─── Authentication Tokens ──────────────────────────────────────────────────

  /// Store Firebase auth token securely
  Future<void> setAuthToken(String token) async {
    await _storage.write(key: _keyAuthToken, value: token);
  }

  /// Retrieve Firebase auth token
  Future<String?> getAuthToken() async {
    return await _storage.read(key: _keyAuthToken);
  }

  /// Store refresh token
  Future<void> setRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  /// Retrieve refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  /// Delete all auth tokens (logout)
  Future<void> clearAuthTokens() async {
    await Future.wait([
      _storage.delete(key: _keyAuthToken),
      _storage.delete(key: _keyRefreshToken),
    ]);
  }

  // ─── User Credentials ───────────────────────────────────────────────────────

  /// Store user ID
  Future<void> setUserId(String userId) async {
    await _storage.write(key: _keyUserId, value: userId);
  }

  /// Retrieve user ID
  Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  /// Store user email
  Future<void> setUserEmail(String email) async {
    await _storage.write(key: _keyUserEmail, value: email);
  }

  /// Retrieve user email
  Future<String?> getUserEmail() async {
    return await _storage.read(key: _keyUserEmail);
  }

  // ─── Security Settings ──────────────────────────────────────────────────────

  /// Enable/disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: _keyBiometricEnabled,
      value: enabled.toString(),
    );
  }

  /// Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  /// Store encryption key for local data
  Future<void> setEncryptionKey(String key) async {
    await _storage.write(key: _keyEncryptionKey, value: key);
  }

  /// Retrieve encryption key
  Future<String?> getEncryptionKey() async {
    return await _storage.read(key: _keyEncryptionKey);
  }

  // ─── Sync & Cache Management ────────────────────────────────────────────────

  /// Store last sync timestamp
  Future<void> setLastSyncTime(DateTime time) async {
    await _storage.write(
      key: _keyLastSyncTime,
      value: time.toIso8601String(),
    );
  }

  /// Retrieve last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    final value = await _storage.read(key: _keyLastSyncTime);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  // ─── Generic Key-Value Storage ──────────────────────────────────────────────

  /// Write any secure value
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Read any secure value
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// Delete a specific key
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Check if a key exists
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  // ─── Complete Data Wipe ─────────────────────────────────────────────────────

  /// Delete ALL secure storage data (account deletion, logout, reset)
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Get all stored keys (debugging only - DO NOT use in production logging)
  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }
}
