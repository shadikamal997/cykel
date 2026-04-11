/// CYKEL — In-App Purchase Service
/// Manages the full purchase lifecycle for CYKEL Premium:
///   • Store connection & product loading
///   • Purchase initiation
///   • Purchase stream handling (delivered / pending / error)
///   • Receipt verification via Cloud Function
///   • Restore purchases
///
/// Product ID: `dk.cykel.premium.monthly` (auto-renewing subscription)

import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/constants/app_constants.dart';

// ─── Subscription Status Model ───────────────────────────────────────────────

enum SubscriptionPlan { free, premium }

class SubscriptionStatus {
  const SubscriptionStatus({
    this.plan = SubscriptionPlan.free,
    this.isActive = false,
    this.expiresAt,
    this.productId,
  });

  final SubscriptionPlan plan;
  final bool isActive;
  final DateTime? expiresAt;
  final String? productId;

  bool get isPremium => plan == SubscriptionPlan.premium && isActive;

  factory SubscriptionStatus.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return const SubscriptionStatus();
    return SubscriptionStatus(
      plan: data['plan'] == 'premium'
          ? SubscriptionPlan.premium
          : SubscriptionPlan.free,
      isActive: data['active'] as bool? ?? false,
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      productId: data['productId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'plan': plan == SubscriptionPlan.premium ? 'premium' : 'free',
        'active': isActive,
        'expiresAt':
            expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
        'productId': productId,
      };
}

// ─── Purchase Service ────────────────────────────────────────────────────────

class PurchaseService {
  PurchaseService({
    InAppPurchase? iap,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  })  : _iap = iap ?? InAppPurchase.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final InAppPurchase _iap;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  /// The set of product IDs used across platforms.
  static final Set<String> _productIds = {
    AppConstants.premiumProductIdIos,
    if (AppConstants.premiumProductIdAndroid != AppConstants.premiumProductIdIos)
      AppConstants.premiumProductIdAndroid,
  };

  /// Resolved product ID for the current platform.
  static String get platformProductId => Platform.isIOS
      ? AppConstants.premiumProductIdIos
      : AppConstants.premiumProductIdAndroid;

  // ── Loaded product details ─────────────────────────────────────────────

  ProductDetails? _premiumProduct;
  ProductDetails? get premiumProduct => _premiumProduct;

  /// Formatted price string from the store (e.g. "kr 20,00" or "$2.99").
  String? get formattedPrice => _premiumProduct?.price;

  // ── Initialise ─────────────────────────────────────────────────────────

  /// Call once at app start (e.g. in `main()` or a top-level provider).
  Future<bool> initialise() async {
    final available = await _iap.isAvailable();
    if (!available) {
      debugPrint('[PurchaseService] Store not available');
      return false;
    }

    // Load product details
    final response = await _iap.queryProductDetails(_productIds);
    if (response.productDetails.isNotEmpty) {
      _premiumProduct = response.productDetails.first;
    } else {
      debugPrint(
          '[PurchaseService] No products found. Errors: ${response.error}');
    }

    // Listen to the purchase stream
    _purchaseSub = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _purchaseSub?.cancel(),
      onError: (Object error) {
        debugPrint('[PurchaseService] Purchase stream error: $error');
      },
    );

    return true;
  }

  // ── Purchase ───────────────────────────────────────────────────────────

  /// Initiate the purchase flow for Premium.
  /// Returns `false` if the product was not loaded or the store is unavailable.
  Future<bool> buyPremium() async {
    if (_premiumProduct == null) return false;

    final purchaseParam = PurchaseParam(productDetails: _premiumProduct!);
    // Subscription purchase — not consumable.
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  // ── Restore ────────────────────────────────────────────────────────────

  /// Restore previous purchases (e.g. after reinstall or device transfer).
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  // ── Handle purchase updates ────────────────────────────────────────────

  Future<void> _handlePurchaseUpdates(
      List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndDeliver(purchase);
        case PurchaseStatus.pending:
          debugPrint('[PurchaseService] Purchase pending…');
        case PurchaseStatus.error:
          debugPrint(
              '[PurchaseService] Purchase error: ${purchase.error?.message}');
          // Complete the purchase to dismiss any platform UI.
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
        case PurchaseStatus.canceled:
          debugPrint('[PurchaseService] Purchase cancelled');
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
      }
    }
  }

  // ── Verify receipt via Cloud Function ──────────────────────────────────

  Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      // Call Cloud Function to verify the receipt server-side.
      final callable = _functions.httpsCallable('verifyPurchase');
      final result = await callable.call<Map<String, dynamic>>({
        'source': Platform.isIOS ? 'apple' : 'google',
        'verificationData':
            purchase.verificationData.serverVerificationData,
        'productId': purchase.productID,
      });

      final success = result.data['success'] as bool? ?? false;

      if (success) {
        debugPrint('[PurchaseService] Purchase verified for $uid');
      } else {
        final error = result.data['error'] as String? ?? 'Unknown error';
        debugPrint('[PurchaseService] Verification failed: $error');
        // Don't set local premium if server explicitly rejected the receipt
        // This prevents fraudulent purchases from being honored
      }
    } catch (e) {
      debugPrint('[PurchaseService] Verification call error: $e');
      // SECURITY: Do NOT grant premium locally when verification fails.
      // This prevents exploitation by blocking network requests.
      // The purchase will be re-verified on next app start or restore.
      debugPrint('[PurchaseService] Purchase pending verification - will retry later');
    } finally {
      // Always complete the purchase to avoid re-delivery loops.
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  } 
  /// 
  /// NOTE: This method is no longer used as we removed the optimistic grant.
  /// Kept for reference and potential future use with proper safeguards.
  /// A scheduled Cloud Function handles verification reconciliation.
  @Deprecated('Removed for security - see verifyPurchase Cloud Function')
  // ignore: unused_element - kept for reference
  Future<void> _setLocalPremium() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    debugPrint('WARNING: _setLocalPremium is deprecated and should not be called');
    // This method intentionally does nothing now
  }

  // ── Stream Firestore subscription status ───────────────────────────────

  /// Real-time stream of the user's subscription status from Firestore.
  Stream<SubscriptionStatus> subscriptionStatusStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(const SubscriptionStatus());
    }
    return _firestore
        .collection(AppConstants.colUsers)
        .doc(uid)
        .snapshots()
        .map((snap) {
      final data = snap.data();
      final sub = data?['subscription'] as Map<String, dynamic>?;
      return SubscriptionStatus.fromFirestore(sub);
    });
  }

  // ── Dispose ────────────────────────────────────────────────────────────

  void dispose() {
    _purchaseSub?.cancel();
  }
}
