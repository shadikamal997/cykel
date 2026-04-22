/// CYKEL — Subscription Riverpod Providers
/// Manages PurchaseService lifecycle and exposes reactive subscription state.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/purchase_service.dart';
import '../features/auth/providers/auth_providers.dart';

// ─── PurchaseService singleton ───────────────────────────────────────────────

final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final svc = PurchaseService();
  ref.onDispose(svc.dispose);
  return svc;
});

// ─── Initialise (call once) ──────────────────────────────────────────────────

/// FutureProvider that initialises the IAP connection.
/// Watch this early (e.g. in App widget) so the store is ready.
final purchaseInitProvider = FutureProvider<bool>((ref) async {
  final svc = ref.read(purchaseServiceProvider);
  return svc.initialise();
});

// ─── Subscription status stream ──────────────────────────────────────────────

/// Stream of the current user's subscription status from Firestore.
/// Automatically re-subscribes when the user changes.
final subscriptionStatusProvider =
    StreamProvider<SubscriptionStatus>((ref) {
  // Watch currentUserProvider to re-subscribe on user change
  final user = ref.watch(currentUserProvider);
  final svc = ref.read(purchaseServiceProvider);
  
  if (user == null) {
    return Stream.value(const SubscriptionStatus());
  }
  
  return svc.subscriptionStatusStream();
});

// ─── Convenience: isPremium ──────────────────────────────────────────────────

/// Simple boolean derived provider – true when user has active premium access (paid or trial).
final isPremiumProvider = Provider<bool>((ref) {
  final status = ref.watch(subscriptionStatusProvider).valueOrNull;
  return status?.hasPremiumAccess ?? false;
});

/// Check if user is on a trial subscription
final isTrialProvider = Provider<bool>((ref) {
  final status = ref.watch(subscriptionStatusProvider).valueOrNull;
  return status?.isTrialActive ?? false;
});

/// Get remaining trial days (null if not on trial)
final trialDaysRemainingProvider = Provider<int?>((ref) {
  final status = ref.watch(subscriptionStatusProvider).valueOrNull;
  return status?.trialDaysRemaining;
});

// ─── Product details ─────────────────────────────────────────────────────────

/// The formatted price string from the store (e.g. "kr 20,00").
/// Returns null until the store connection is ready.
final premiumPriceProvider = Provider<String?>((ref) {
  // Ensure initialisation has completed
  ref.watch(purchaseInitProvider);
  return ref.read(purchaseServiceProvider).formattedPrice;
});

/// Phase 2: Student discount subscription price (kr 10/month).
final studentPriceProvider = Provider<String?>((ref) {
  ref.watch(purchaseInitProvider);
  return ref.read(purchaseServiceProvider).formattedStudentPrice;
});

/// Phase 2: Annual subscription price (kr 200/year).
final annualPriceProvider = Provider<String?>((ref) {
  ref.watch(purchaseInitProvider);
  return ref.read(purchaseServiceProvider).formattedAnnualPrice;
});
