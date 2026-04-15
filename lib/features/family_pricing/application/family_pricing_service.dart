import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/family_account.dart';
import '../domain/subscription.dart';

/// Service for managing subscriptions, family accounts, and payments
class FamilyPricingService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FamilyPricingService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  // ==========================================
  // Pricing
  // ==========================================

  /// Get static pricing for all plans
  List<SubscriptionPricing> getAvailablePlans() {
    return [
      const SubscriptionPricing(
        plan: SubscriptionPlan.free,
        monthlyPrice: 0,
        prices: {
          BillingPeriod.monthly: 0,
          BillingPeriod.quarterly: 0,
          BillingPeriod.yearly: 0,
        },
        features: [
          'Basic bike tracking',
          'Route planning (3 per day)',
          'Community forum access',
          'Basic statistics',
        ],
        excludedFeatures: [
          'Advanced statistics',
          'Offline maps',
          'Weather alerts',
          'Family sharing',
          'Premium routes',
        ],
      ),
      const SubscriptionPricing(
        plan: SubscriptionPlan.individual,
        monthlyPrice: 49,
        prices: {
          BillingPeriod.monthly: 49,
          BillingPeriod.quarterly: 132, // ~44/mo
          BillingPeriod.yearly: 441, // ~37/mo
        },
        features: [
          'Unlimited bike tracking',
          'Unlimited route planning',
          'Advanced statistics & analytics',
          'Offline maps',
          'Weather alerts',
          'Priority support',
          'Ad-free experience',
        ],
        excludedFeatures: [
          'Family sharing',
          'Premium routes',
          'Personal coaching',
        ],
        isMostPopular: true,
      ),
      const SubscriptionPricing(
        plan: SubscriptionPlan.family,
        monthlyPrice: 89,
        prices: {
          BillingPeriod.monthly: 89,
          BillingPeriod.quarterly: 240, // ~80/mo
          BillingPeriod.yearly: 801, // ~67/mo
        },
        features: [
          'Everything in Individual',
          'Family sharing (up to 6 members)',
          'Family dashboard',
          'Shared routes & favorites',
          'Family ride planning',
          'Child safety features',
          'Per-member usage stats',
        ],
        excludedFeatures: [
          'Premium routes',
          'Personal coaching',
        ],
        familyMemberLimit: 6,
        perMemberPrice: 15,
        isBestValue: true,
      ),
      const SubscriptionPricing(
        plan: SubscriptionPlan.premium,
        monthlyPrice: 149,
        prices: {
          BillingPeriod.monthly: 149,
          BillingPeriod.quarterly: 402, // ~134/mo
          BillingPeriod.yearly: 1342, // ~112/mo
        },
        features: [
          'Everything in Family',
          'Family sharing (up to 8 members)',
          'Exclusive premium routes',
          'AI personal cycling coach',
          'Unlimited buddy matches',
          '20% bike insurance discount',
          'Early access to new features',
          'VIP customer support',
        ],
        familyMemberLimit: 8,
        perMemberPrice: 10,
      ),
    ];
  }

  // ==========================================
  // Subscriptions
  // ==========================================

  /// Get the current user's active subscription
  Stream<Subscription?> getCurrentSubscription() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value(null);

    return _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['active', 'trialing'])
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return Subscription.fromFirestore(snapshot.docs.first);
    });
  }

  /// Get subscription by ID
  Future<Subscription?> getSubscription(String subscriptionId) async {
    final doc =
        await _firestore.collection('subscriptions').doc(subscriptionId).get();
    if (!doc.exists) return null;
    return Subscription.fromFirestore(doc);
  }

  /// Create a new subscription (after payment confirmation)
  Future<Subscription> createSubscription({
    required SubscriptionPlan plan,
    required BillingPeriod billingPeriod,
    required double amount,
    String? paymentMethodId,
    bool startTrial = false,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Cancel any existing active subscription
    await _cancelExistingSubscriptions(userId);

    final now = DateTime.now();
    final periodEnd = _calculatePeriodEnd(now, billingPeriod);
    final trialEnd = startTrial ? now.add(const Duration(days: 14)) : null;

    final docRef = _firestore.collection('subscriptions').doc();
    final subscription = Subscription(
      id: docRef.id,
      userId: userId,
      plan: plan,
      billingPeriod: billingPeriod,
      status:
          startTrial ? SubscriptionStatus.trialing : SubscriptionStatus.active,
      startDate: now,
      trialEndDate: trialEnd,
      currentPeriodStart: now,
      currentPeriodEnd: startTrial ? trialEnd : periodEnd,
      amount: amount,
      paymentMethodId: paymentMethodId,
      autoRenew: true,
    );

    await docRef.set(subscription.toFirestore());

    // If it's a family plan, create the family account
    if (plan == SubscriptionPlan.family ||
        plan == SubscriptionPlan.premium) {
      await _createInitialFamilyAccount(docRef.id, plan);
    }

    return subscription;
  }

  /// Cancel the current subscription
  Future<void> cancelSubscription(String subscriptionId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final doc =
        await _firestore.collection('subscriptions').doc(subscriptionId).get();
    if (!doc.exists) throw Exception('Subscription not found');

    final subscription = Subscription.fromFirestore(doc);
    if (subscription.userId != userId) {
      throw Exception('Not authorized to cancel this subscription');
    }

    await _firestore.collection('subscriptions').doc(subscriptionId).update({
      'status': SubscriptionStatus.canceled.name,
      'canceledAt': Timestamp.fromDate(DateTime.now()),
      'autoRenew': false,
    });
  }

  /// Resume a canceled subscription (before it expires)
  Future<void> resumeSubscription(String subscriptionId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final doc =
        await _firestore.collection('subscriptions').doc(subscriptionId).get();
    if (!doc.exists) throw Exception('Subscription not found');

    final subscription = Subscription.fromFirestore(doc);
    if (subscription.userId != userId) {
      throw Exception('Not authorized');
    }
    if (subscription.status != SubscriptionStatus.canceled) {
      throw Exception('Subscription is not canceled');
    }

    await _firestore.collection('subscriptions').doc(subscriptionId).update({
      'status': SubscriptionStatus.active.name,
      'canceledAt': null,
      'autoRenew': true,
    });
  }

  /// Change subscription plan (upgrade/downgrade)
  Future<void> changePlan({
    required String subscriptionId,
    required SubscriptionPlan newPlan,
    required BillingPeriod newBillingPeriod,
    required double newAmount,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final doc =
        await _firestore.collection('subscriptions').doc(subscriptionId).get();
    if (!doc.exists) throw Exception('Subscription not found');

    final subscription = Subscription.fromFirestore(doc);
    if (subscription.userId != userId) {
      throw Exception('Not authorized');
    }

    // Update subscription
    await _firestore.collection('subscriptions').doc(subscriptionId).update({
      'plan': newPlan.name,
      'billingPeriod': newBillingPeriod.name,
      'amount': newAmount,
    });

    // Handle family account creation/deletion on plan change
    final wasFamilyPlan = subscription.isFamilyPlan;
    final isFamilyPlan = newPlan == SubscriptionPlan.family ||
        newPlan == SubscriptionPlan.premium;

    if (!wasFamilyPlan && isFamilyPlan) {
      await _createInitialFamilyAccount(subscriptionId, newPlan);
    }
  }

  /// Get subscription payment history
  Stream<List<Payment>> getPaymentHistory() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList());
  }

  // ==========================================
  // Payments
  // ==========================================

  /// Record a payment
  Future<Payment> recordPayment({
    required double amount,
    required PaymentMethod method,
    String? subscriptionId,
    String? description,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final docRef = _firestore.collection('payments').doc();
    final payment = Payment(
      id: docRef.id,
      userId: userId,
      subscriptionId: subscriptionId,
      amount: amount,
      status: PaymentStatus.pending,
      method: method,
      createdAt: DateTime.now(),
      description: description,
    );

    await docRef.set(payment.toFirestore());
    return payment;
  }

  /// Update payment status
  Future<void> updatePaymentStatus(
    String paymentId,
    PaymentStatus status, {
    String? failureReason,
    String? receiptUrl,
  }) async {
    final updates = <String, dynamic>{
      'status': status.name,
    };
    if (status == PaymentStatus.succeeded) {
      updates['processedAt'] = Timestamp.fromDate(DateTime.now());
    }
    if (failureReason != null) updates['failureReason'] = failureReason;
    if (receiptUrl != null) updates['receiptUrl'] = receiptUrl;

    await _firestore.collection('payments').doc(paymentId).update(updates);
  }

  // ==========================================
  // Saved Payment Methods
  // ==========================================

  /// Get saved payment methods
  Stream<List<SavedPaymentMethod>> getSavedPaymentMethods() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('paymentMethods')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SavedPaymentMethod.fromFirestore(doc))
            .toList());
  }

  /// Add a saved payment method
  Future<SavedPaymentMethod> addPaymentMethod({
    required PaymentMethod type,
    String? last4,
    String? brand,
    int? expiryMonth,
    int? expiryYear,
    String? stripePaymentMethodId,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // If this is the first payment method, make it default
    final existing = await _firestore
        .collection('paymentMethods')
        .where('userId', isEqualTo: userId)
        .get();
    final isDefault = existing.docs.isEmpty;

    final docRef = _firestore.collection('paymentMethods').doc();
    final method = SavedPaymentMethod(
      id: docRef.id,
      userId: userId,
      type: type,
      last4: last4,
      brand: brand,
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      isDefault: isDefault,
      stripePaymentMethodId: stripePaymentMethodId,
      createdAt: DateTime.now(),
    );

    await docRef.set(method.toFirestore());
    return method;
  }

  /// Remove a payment method
  Future<void> removePaymentMethod(String paymentMethodId) async {
    await _firestore.collection('paymentMethods').doc(paymentMethodId).delete();
  }

  /// Set default payment method
  Future<void> setDefaultPaymentMethod(String paymentMethodId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final batch = _firestore.batch();

    // Unset current default
    final current = await _firestore
        .collection('paymentMethods')
        .where('userId', isEqualTo: userId)
        .where('isDefault', isEqualTo: true)
        .get();
    for (final doc in current.docs) {
      batch.update(doc.reference, {'isDefault': false});
    }

    // Set new default
    batch.update(
      _firestore.collection('paymentMethods').doc(paymentMethodId),
      {'isDefault': true},
    );

    await batch.commit();
  }

  // ==========================================
  // Family Accounts
  // ==========================================

  /// Get the current user's family account
  Stream<FamilyAccount?> getCurrentFamilyAccount() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value(null);

    return _firestore
        .collection('familyAccounts')
        .where('members', arrayContainsAny: [
          {'userId': userId}
        ])
        .limit(1)
        .snapshots()
        .asyncMap((snapshot) async {
      // Firestore array-contains-any with maps is limited,
      // so we query by ownerId and also check member arrays
      if (snapshot.docs.isEmpty) {
        // Try querying by ownerId
        final ownerSnapshot = await _firestore
            .collection('familyAccounts')
            .where('ownerId', isEqualTo: userId)
            .limit(1)
            .get();
        if (ownerSnapshot.docs.isEmpty) return null;
        return FamilyAccount.fromFirestore(ownerSnapshot.docs.first);
      }
      return FamilyAccount.fromFirestore(snapshot.docs.first);
    });
  }

  /// Get family account by ID
  Future<FamilyAccount?> getFamilyAccount(String accountId) async {
    final doc =
        await _firestore.collection('familyAccounts').doc(accountId).get();
    if (!doc.exists) return null;
    return FamilyAccount.fromFirestore(doc);
  }

  /// Update family account name
  Future<void> updateFamilyName(String accountId, String newName) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final account = await getFamilyAccount(accountId);
    if (account == null) throw Exception('Family account not found');
    if (account.ownerId != userId) {
      throw Exception('Only the owner can rename the family');
    }

    await _firestore.collection('familyAccounts').doc(accountId).update({
      'name': newName,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Invite a member to the family
  Future<FamilyInvitation> inviteFamilyMember({
    required String familyAccountId,
    required String inviteeEmail,
    FamilyRole role = FamilyRole.member,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final account = await getFamilyAccount(familyAccountId);
    if (account == null) throw Exception('Family account not found');

    final member = account.getMember(userId);
    if (member == null || !member.role.canManageMembers) {
      throw Exception('Not authorized to invite members');
    }

    if (account.isFull) {
      throw Exception(
          'Family account is full (${account.maxMembers} members max)');
    }

    // Generate invite code
    final inviteCode = _generateInviteCode();

    final user = _auth.currentUser;
    final docRef = _firestore.collection('familyInvitations').doc();
    final invitation = FamilyInvitation(
      id: docRef.id,
      familyAccountId: familyAccountId,
      familyName: account.name,
      invitedByUserId: userId,
      invitedByName: user?.displayName ?? 'Unknown',
      inviteeEmail: inviteeEmail,
      assignedRole: role,
      status: InvitationStatus.pending,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      inviteCode: inviteCode,
    );

    await docRef.set(invitation.toFirestore());
    return invitation;
  }

  /// Accept a family invitation
  Future<void> acceptInvitation(String invitationId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');
    final user = _auth.currentUser;

    final inviteDoc =
        await _firestore.collection('familyInvitations').doc(invitationId).get();
    if (!inviteDoc.exists) throw Exception('Invitation not found');

    final invitation = FamilyInvitation.fromFirestore(inviteDoc);
    if (invitation.isExpired) throw Exception('Invitation has expired');
    if (invitation.status != InvitationStatus.pending) {
      throw Exception('Invitation is no longer pending');
    }

    // Add member to family account
    final newMember = FamilyMember(
      userId: userId,
      displayName: user?.displayName ?? 'New Member',
      email: user?.email,
      photoUrl: user?.photoURL,
      role: invitation.assignedRole,
      joinedAt: DateTime.now(),
    );

    await _firestore
        .collection('familyAccounts')
        .doc(invitation.familyAccountId)
        .update({
      'members': FieldValue.arrayUnion([newMember.toMap()]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    // Update invitation status
    await _firestore.collection('familyInvitations').doc(invitationId).update({
      'status': InvitationStatus.accepted.name,
      'inviteeUserId': userId,
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Decline a family invitation
  Future<void> declineInvitation(String invitationId) async {
    await _firestore.collection('familyInvitations').doc(invitationId).update({
      'status': InvitationStatus.declined.name,
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Get pending invitations for the current user
  Stream<List<FamilyInvitation>> getPendingInvitations() {
    final user = _auth.currentUser;
    if (user?.email == null) return Stream.value([]);

    return _firestore
        .collection('familyInvitations')
        .where('inviteeEmail', isEqualTo: user!.email)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FamilyInvitation.fromFirestore(doc))
            .where((invite) => !invite.isExpired)
            .toList());
  }

  /// Get sent invitations for a family account
  Stream<List<FamilyInvitation>> getSentInvitations(String familyAccountId) {
    return _firestore
        .collection('familyInvitations')
        .where('familyAccountId', isEqualTo: familyAccountId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FamilyInvitation.fromFirestore(doc))
            .toList());
  }

  /// Remove a member from the family
  Future<void> removeFamilyMember(
      String familyAccountId, String memberUserId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final account = await getFamilyAccount(familyAccountId);
    if (account == null) throw Exception('Family account not found');

    final currentMember = account.getMember(userId);
    if (currentMember == null || !currentMember.role.canManageMembers) {
      throw Exception('Not authorized to remove members');
    }

    final memberToRemove = account.getMember(memberUserId);
    if (memberToRemove == null) throw Exception('Member not found');

    if (memberToRemove.role == FamilyRole.owner) {
      throw Exception('Cannot remove the account owner');
    }

    await _firestore
        .collection('familyAccounts')
        .doc(familyAccountId)
        .update({
      'members': FieldValue.arrayRemove([memberToRemove.toMap()]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Update member role
  Future<void> updateMemberRole(
    String familyAccountId,
    String memberUserId,
    FamilyRole newRole,
  ) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final account = await getFamilyAccount(familyAccountId);
    if (account == null) throw Exception('Family account not found');

    if (account.ownerId != userId) {
      throw Exception('Only the owner can change roles');
    }

    if (newRole == FamilyRole.owner) {
      throw Exception('Cannot assign another owner');
    }

    // Rebuild members with updated role
    final updatedMembers = account.members.map((m) {
      if (m.userId == memberUserId) {
        return FamilyMember(
          userId: m.userId,
          displayName: m.displayName,
          email: m.email,
          photoUrl: m.photoUrl,
          role: newRole,
          joinedAt: m.joinedAt,
          isActive: m.isActive,
          permissions: m.permissions,
        );
      }
      return m;
    }).toList();

    await _firestore
        .collection('familyAccounts')
        .doc(familyAccountId)
        .update({
      'members': updatedMembers.map((m) => m.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Get family usage statistics
  Future<List<FamilyMemberUsage>> getFamilyUsage(
      String familyAccountId) async {
    final account = await getFamilyAccount(familyAccountId);
    if (account == null) return [];

    final usageList = <FamilyMemberUsage>[];
    for (final member in account.members) {
      final usageDoc = await _firestore
          .collection('userStats')
          .doc(member.userId)
          .get();

      if (usageDoc.exists) {
        final data = usageDoc.data() as Map<String, dynamic>;
        usageList.add(FamilyMemberUsage(
          userId: member.userId,
          displayName: member.displayName,
          totalRides: data['totalRides'] as int? ?? 0,
          totalDistanceKm:
              (data['totalDistanceKm'] as num?)?.toDouble() ?? 0,
          totalMinutes: data['totalMinutes'] as int? ?? 0,
          routesShared: data['routesShared'] as int? ?? 0,
          buddyMatches: data['buddyMatches'] as int? ?? 0,
          lastActiveAt: data['lastActiveAt'] != null
              ? (data['lastActiveAt'] as Timestamp).toDate()
              : null,
        ));
      } else {
        usageList.add(FamilyMemberUsage(
          userId: member.userId,
          displayName: member.displayName,
        ));
      }
    }

    return usageList;
  }

  // ==========================================
  // Feature Access
  // ==========================================

  /// Check if the user has access to a specific feature
  Future<bool> hasFeatureAccess(String featureId) async {
    final userId = _currentUserId;
    if (userId == null) return false;

    final subscription = await _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['active', 'trialing'])
        .limit(1)
        .get();

    if (subscription.docs.isEmpty) {
      // Free plan
      final freeFeatures = SubscriptionFeatures.getFeaturesForPlan(
          SubscriptionPlan.free);
      return freeFeatures.any((f) => f.id == featureId);
    }

    final sub = Subscription.fromFirestore(subscription.docs.first);
    final planFeatures = SubscriptionFeatures.getFeaturesForPlan(sub.plan);
    return planFeatures.any((f) => f.id == featureId);
  }

  /// Get the user's current plan (defaults to free)
  Future<SubscriptionPlan> getCurrentPlan() async {
    final userId = _currentUserId;
    if (userId == null) return SubscriptionPlan.free;

    final subscription = await _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['active', 'trialing'])
        .limit(1)
        .get();

    if (subscription.docs.isEmpty) return SubscriptionPlan.free;
    return Subscription.fromFirestore(subscription.docs.first).plan;
  }

  // ==========================================
  // Private Helpers
  // ==========================================

  Future<void> _cancelExistingSubscriptions(String userId) async {
    final existing = await _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['active', 'trialing'])
        .get();

    final batch = _firestore.batch();
    for (final doc in existing.docs) {
      batch.update(doc.reference, {
        'status': SubscriptionStatus.canceled.name,
        'canceledAt': Timestamp.fromDate(DateTime.now()),
        'autoRenew': false,
      });
    }
    await batch.commit();
  }

  DateTime _calculatePeriodEnd(DateTime start, BillingPeriod period) {
    switch (period) {
      case BillingPeriod.monthly:
        return DateTime(start.year, start.month + 1, start.day);
      case BillingPeriod.quarterly:
        return DateTime(start.year, start.month + 3, start.day);
      case BillingPeriod.yearly:
        return DateTime(start.year + 1, start.month, start.day);
    }
  }

  Future<void> _createInitialFamilyAccount(
      String subscriptionId, SubscriptionPlan plan) async {
    final userId = _currentUserId;
    if (userId == null) return;
    final user = _auth.currentUser;

    final docRef = _firestore.collection('familyAccounts').doc();
    final account = FamilyAccount(
      id: docRef.id,
      name: '${user?.displayName ?? "My"} Family',
      ownerId: userId,
      subscriptionId: subscriptionId,
      members: [
        FamilyMember(
          userId: userId,
          displayName: user?.displayName ?? 'Account Owner',
          email: user?.email,
          photoUrl: user?.photoURL,
          role: FamilyRole.owner,
          joinedAt: DateTime.now(),
        ),
      ],
      maxMembers: plan.maxFamilyMembers,
      createdAt: DateTime.now(),
    );

    await docRef.set(account.toFirestore());

    // Link family account to subscription
    await _firestore.collection('subscriptions').doc(subscriptionId).update({
      'familyAccountId': docRef.id,
    });
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
