/// CYKEL — GDPR & Privacy Consent provider (Phase 5)
///
/// Manages user consent for analytics and anonymous mobility aggregation.
/// Consent is stored in SharedPreferences under well-known keys.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── SharedPreferences keys ──────────────────────────────────────────────────

const _kConsentGiven      = 'gdpr_consent_given';
const _kAnalyticsConsent  = 'gdpr_analytics_consent';
const _kAggregationConsent = 'gdpr_aggregation_consent';

// ── State ───────────────────────────────────────────────────────────────────

class GdprState {
  const GdprState({
    required this.consentGiven,
    required this.analyticsEnabled,
    required this.aggregationEnabled,
  });

  final bool consentGiven;
  final bool analyticsEnabled;
  final bool aggregationEnabled;

  GdprState copyWith({
    bool? consentGiven,
    bool? analyticsEnabled,
    bool? aggregationEnabled,
  }) =>
      GdprState(
        consentGiven:       consentGiven       ?? this.consentGiven,
        analyticsEnabled:   analyticsEnabled   ?? this.analyticsEnabled,
        aggregationEnabled: aggregationEnabled ?? this.aggregationEnabled,
      );
}

// ── Notifier ────────────────────────────────────────────────────────────────

class GdprNotifier extends AsyncNotifier<GdprState> {
  @override
  Future<GdprState> build() async {
    final prefs = await SharedPreferences.getInstance();
    return GdprState(
      consentGiven:       prefs.getBool(_kConsentGiven)       ?? false,
      analyticsEnabled:   prefs.getBool(_kAnalyticsConsent)   ?? false,
      aggregationEnabled: prefs.getBool(_kAggregationConsent) ?? false,
    );
  }

  /// Called when the user completes the GDPR consent screen.
  Future<void> acceptConsent({
    required bool analytics,
    required bool aggregation,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kConsentGiven, true);
    await prefs.setBool(_kAnalyticsConsent, analytics);
    await prefs.setBool(_kAggregationConsent, aggregation);
    final current = state.valueOrNull ?? const GdprState(
      consentGiven: false, analyticsEnabled: false, aggregationEnabled: false);
    state = AsyncData(current.copyWith(
      consentGiven:       true,
      analyticsEnabled:   analytics,
      aggregationEnabled: aggregation,
    ));
  }

  /// Update individual consent toggles from Settings.
  Future<void> updateAnalytics(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAnalyticsConsent, value);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(analyticsEnabled: value));
    }
  }

  Future<void> updateAggregation(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAggregationConsent, value);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(aggregationEnabled: value));
    }
  }

  /// Revoke all consent (from settings).
  Future<void> revokeConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kConsentGiven);
    await prefs.remove(_kAnalyticsConsent);
    await prefs.remove(_kAggregationConsent);
    state = const AsyncData(GdprState(
      consentGiven: false,
      analyticsEnabled: false,
      aggregationEnabled: false,
    ));
  }
}

final gdprProvider =
    AsyncNotifierProvider<GdprNotifier, GdprState>(GdprNotifier.new);

/// Simple bool convenience provider — true if consent has been given.
final gdprConsentGivenProvider = Provider<bool>((ref) {
  return ref.watch(gdprProvider).valueOrNull?.consentGiven ?? false;
});

/// True if user opted-in to anonymous mobility aggregation.
final gdprAggregationEnabledProvider = Provider<bool>((ref) {
  return ref.watch(gdprProvider).valueOrNull?.aggregationEnabled ?? false;
});
