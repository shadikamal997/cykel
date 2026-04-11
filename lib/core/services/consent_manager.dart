/// CYKEL — GDPR Consent Manager
/// Manages user consent for data collection and processing

import 'package:shared_preferences/shared_preferences.dart';

class ConsentManager {
  static const String _keyLocationConsent = 'consent_location';
  static const String _keyAnalyticsConsent = 'consent_analytics';
  static const String _keyMarketingConsent = 'consent_marketing';
  static const String _keyConsentTimestamp = 'consent_timestamp';
  static const String _keyConsentShown = 'consent_shown';

  final SharedPreferences _prefs;

  ConsentManager(this._prefs);

  // Check if consent dialog has been shown
  bool get hasShownConsent => _prefs.getBool(_keyConsentShown) ?? false;

  // Location tracking consent
  Future<bool> get hasLocationConsent async => _prefs.getBool(_keyLocationConsent) ?? false;

  // Analytics consent
  Future<bool> get hasAnalyticsConsent async => _prefs.getBool(_keyAnalyticsConsent) ?? false;

  // Marketing consent
  Future<bool> get hasMarketingConsent async => _prefs.getBool(_keyMarketingConsent) ?? false;

  // Get consent timestamp
  DateTime? get consentTimestamp {
    final timestamp = _prefs.getInt(_keyConsentTimestamp);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  // Set all consents
  Future<void> setConsents({
    required bool location,
    required bool analytics,
    required bool marketing,
  }) async {
    await _prefs.setBool(_keyLocationConsent, location);
    await _prefs.setBool(_keyAnalyticsConsent, analytics);
    await _prefs.setBool(_keyMarketingConsent, marketing);
    await _prefs.setInt(_keyConsentTimestamp, DateTime.now().millisecondsSinceEpoch);
    await _prefs.setBool(_keyConsentShown, true);
  }

  // Update individual consents
  Future<void> setLocationConsent(bool value) async {
    await _prefs.setBool(_keyLocationConsent, value);
  }

  Future<void> setAnalyticsConsent(bool value) async {
    await _prefs.setBool(_keyAnalyticsConsent, value);
  }

  Future<void> setMarketingConsent(bool value) async {
    await _prefs.setBool(_keyMarketingConsent, value);
  }

  // Clear all consents
  Future<void> clearConsents() async {
    await _prefs.remove(_keyLocationConsent);
    await _prefs.remove(_keyAnalyticsConsent);
    await _prefs.remove(_keyMarketingConsent);
    await _prefs.remove(_keyConsentTimestamp);
    await _prefs.remove(_keyConsentShown);
  }
}
