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

/// Phase 1: Extended subscription tiers.
enum SubscriptionPlan {
  free,           // Free tier
  premium,        // Standard premium (kr 20/month)
  student,        // Student discount premium (kr 10/month) - Phase 1
  annual,         // Annual premium (kr 200/year) - Phase 1
  family,         // Family plan (kr 50/month, up to 5 accounts) - Future phase
}

class SubscriptionStatus {
  const SubscriptionStatus({
    this.plan = SubscriptionPlan.free,
    this.isActive = false,
    this.expiresAt,
    this.productId,
    this.isTrial = false,
    this.trialStartedAt,
    this.trialEndsAt,
    this.hasUsedTrial = false,
  });

  final SubscriptionPlan plan;
  final bool isActive;
  final DateTime? expiresAt;
  final String? productId;
  
  /// Whether the current subscription is in trial period
  final bool isTrial;
  
  /// When the trial period started
  final DateTime? trialStartedAt;
  
  /// When the trial period ends
  final DateTime? trialEndsAt;
  
  /// Whether the user has ever used a trial (prevents re-trials)
  final bool hasUsedTrial;

  /// Whether user has any paid premium tier (including student, annual, family).
  bool get isPremium =>
      (plan == SubscriptionPlan.premium ||
          plan == SubscriptionPlan.student ||
          plan == SubscriptionPlan.annual ||
          plan == SubscriptionPlan.family) &&
      isActive;
  
  /// Whether the trial is currently active and not expired
  bool get isTrialActive {
    if (!isTrial || trialEndsAt == null) return false;
    return DateTime.now().isBefore(trialEndsAt!);
  }
  
  /// Whether the user has access to premium features (paid or trial)
  bool get hasPremiumAccess => isPremium || isTrialActive;
  
  /// Remaining days in trial period
  int? get trialDaysRemaining {
    if (!isTrial || trialEndsAt == null) return null;
    final remaining = trialEndsAt!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  /// Legacy check for standard premium tier only.
  bool get isStandardPremium => plan == SubscriptionPlan.premium && isActive;

  /// Whether user has student tier (Phase 1).
  bool get isStudent => plan == SubscriptionPlan.student && isActive;

  /// Whether user has annual tier (Phase 1).
  bool get isAnnual => plan == SubscriptionPlan.annual && isActive;

  /// Whether user has family tier (Future).
  bool get isFamily => plan == SubscriptionPlan.family && isActive;

  factory SubscriptionStatus.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return const SubscriptionStatus();

    // Parse plan string to enum
    SubscriptionPlan parsedPlan = SubscriptionPlan.free;
    final planStr = data['plan'] as String?;
    if (planStr != null) {
      parsedPlan = SubscriptionPlan.values.firstWhere(
        (p) => p.name == planStr,
        orElse: () => SubscriptionPlan.free,
      );
    }

    return SubscriptionStatus(
      plan: parsedPlan,
      isActive: data['active'] as bool? ?? false,
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      productId: data['productId'] as String?,
      isTrial: data['isTrial'] as bool? ?? false,
      trialStartedAt: (data['trialStartedAt'] as Timestamp?)?.toDate(),
      trialEndsAt: (data['trialEndsAt'] as Timestamp?)?.toDate(),
      hasUsedTrial: data['hasUsedTrial'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'plan': plan.name,
        'active': isActive,
        'expiresAt':
            expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
        'productId': productId,
        'isTrial': isTrial,
        'trialStartedAt':
            trialStartedAt != null ? Timestamp.fromDate(trialStartedAt!) : null,
        'trialEndsAt':
            trialEndsAt != null ? Timestamp.fromDate(trialEndsAt!) : null,
        'hasUsedTrial': hasUsedTrial,
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
  /// Phase 2: Includes student and annual subscriptions.
  static final Set<String> _productIds = {
    // Standard premium monthly
    AppConstants.premiumProductIdIos,
    if (AppConstants.premiumProductIdAndroid != AppConstants.premiumProductIdIos)
      AppConstants.premiumProductIdAndroid,
    // Student discount monthly
    AppConstants.studentProductIdIos,
    if (AppConstants.studentProductIdAndroid != AppConstants.studentProductIdIos)
      AppConstants.studentProductIdAndroid,
    // Annual premium
    AppConstants.annualProductIdIos,
    if (AppConstants.annualProductIdAndroid != AppConstants.annualProductIdIos)
      AppConstants.annualProductIdAndroid,
  };

  /// Resolved product IDs for the current platform.
  static String get platformProductId => Platform.isIOS
      ? AppConstants.premiumProductIdIos
      : AppConstants.premiumProductIdAndroid;

  static String get studentProductId => Platform.isIOS
      ? AppConstants.studentProductIdIos
      : AppConstants.studentProductIdAndroid;

  static String get annualProductId => Platform.isIOS
      ? AppConstants.annualProductIdIos
      : AppConstants.annualProductIdAndroid;

  // ── Loaded product details ─────────────────────────────────────────────

  ProductDetails? _premiumProduct;
  ProductDetails? _studentProduct;
  ProductDetails? _annualProduct;

  ProductDetails? get premiumProduct => _premiumProduct;
  ProductDetails? get studentProduct => _studentProduct;
  ProductDetails? get annualProduct => _annualProduct;

  /// Formatted price string from the store (e.g. "kr 20,00" or "$2.99").
  String? get formattedPrice => _premiumProduct?.price;
  String? get formattedStudentPrice => _studentProduct?.price;
  String? get formattedAnnualPrice => _annualProduct?.price;

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
      // Map products by ID
      for (final product in response.productDetails) {
        if (product.id == platformProductId) {
          _premiumProduct = product;
        } else if (product.id == studentProductId) {
          _studentProduct = product;
        } else if (product.id == annualProductId) {
          _annualProduct = product;
        }
      }
      debugPrint('[PurchaseService] Loaded ${response.productDetails.length} products');
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

  /// Initiate the purchase flow for Premium (standard monthly).
  /// Returns `false` if the product was not loaded or the store is unavailable.
  Future<bool> buyPremium() async {
    if (_premiumProduct == null) return false;

    final purchaseParam = PurchaseParam(productDetails: _premiumProduct!);
    // Subscription purchase — not consumable.
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Initiate the purchase flow for Student Premium (kr 10/month).
  /// Phase 2: Student discount tier.
  Future<bool> buyStudentPremium() async {
    if (_studentProduct == null) return false;

    final purchaseParam = PurchaseParam(productDetails: _studentProduct!);
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Initiate the purchase flow for Annual Premium (kr 200/year).
  /// Phase 2: Annual subscription.
  Future<bool> buyAnnualPremium() async {
    if (_annualProduct == null) return false;

    final purchaseParam = PurchaseParam(productDetails: _annualProduct!);
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  // ── Restore ────────────────────────────────────────────────────────────

  /// Restore previous purchases (e.g. after reinstall or device transfer).
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  // ── Trial Period Management ────────────────────────────────────────────

  /// Start a 7-day free trial for the current user
  /// Returns true if trial started successfully, false if already used
  Future<bool> startTrial() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final userDoc = _firestore.collection(AppConstants.colUsers).doc(uid);
    final snapshot = await userDoc.get();
    
    // Check if user has already used their trial
    if (snapshot.exists) {
      final data = snapshot.data();
      final subscription = data?['subscription'] as Map<String, dynamic>?;
      if (subscription?['hasUsedTrial'] == true) {
        debugPrint('[PurchaseService] User has already used their trial');
        return false;
      }
    }

    // Start 7-day trial
    final now = DateTime.now();
    final trialEnd = now.add(const Duration(days: 7));
    
    try {
      await userDoc.set({
        'subscription': {
          'plan': SubscriptionPlan.premium.name,
          'active': true,
          'isTrial': true,
          'trialStartedAt': Timestamp.fromDate(now),
          'trialEndsAt': Timestamp.fromDate(trialEnd),
          'hasUsedTrial': true,
          'expiresAt': Timestamp.fromDate(trialEnd),
          'productId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
      
      debugPrint('[PurchaseService] ✅ Started 7-day trial until $trialEnd');
      return true;
    } catch (e) {
      debugPrint('[PurchaseService] ❌ Failed to start trial: $e');
      return false;
    }
  }

  /// Check if trial has expired and update subscription status
  Future<void> checkTrialExpiry() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userDoc = _firestore.collection(AppConstants.colUsers).doc(uid);
    final snapshot = await userDoc.get();
    
    if (!snapshot.exists) return;
    
    final data = snapshot.data();
    final subscription = data?['subscription'] as Map<String, dynamic>?;
    if (subscription == null) return;
    
    final isTrial = subscription['isTrial'] as bool? ?? false;
    final trialEndsAt = (subscription['trialEndsAt'] as Timestamp?)?.toDate();
    
    if (isTrial && trialEndsAt != null && DateTime.now().isAfter(trialEndsAt)) {
      // Trial has expired, revert to free tier
      try {
        await userDoc.update({
          'subscription.plan': SubscriptionPlan.free.name,
          'subscription.active': false,
          'subscription.isTrial': false,
          'subscription.expiresAt': null,
          'subscription.updatedAt': FieldValue.serverTimestamp(),
        });
        
        debugPrint('[PurchaseService] ⏰ Trial expired, reverted to free tier');
      } catch (e) {
        debugPrint('[PurchaseService] ❌ Failed to update expired trial: $e');
      }
    }
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
