import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/family_account.dart';
import '../domain/subscription.dart';
import 'family_pricing_service.dart';

// ==========================================
// Service Provider
// ==========================================

final familyPricingServiceProvider = Provider<FamilyPricingService>((ref) {
  return FamilyPricingService();
});

// ==========================================
// Pricing Providers
// ==========================================

final availablePlansProvider = Provider<List<SubscriptionPricing>>((ref) {
  final service = ref.watch(familyPricingServiceProvider);
  return service.getAvailablePlans();
});

final selectedBillingPeriodProvider =
    StateProvider<BillingPeriod>((ref) => BillingPeriod.monthly);

final planForTypeProvider =
    Provider.family<SubscriptionPricing?, SubscriptionPlan>((ref, plan) {
  final plans = ref.watch(availablePlansProvider);
  return plans.where((p) => p.plan == plan).firstOrNull;
});

// ==========================================
// Subscription Providers
// ==========================================

final currentSubscriptionProvider = StreamProvider<Subscription?>((ref) {
  final service = ref.watch(familyPricingServiceProvider);
  return service.getCurrentSubscription();
});

final currentPlanProvider = FutureProvider<SubscriptionPlan>((ref) {
  final service = ref.watch(familyPricingServiceProvider);
  return service.getCurrentPlan();
});

final isSubscribedProvider = Provider<bool>((ref) {
  final subscription = ref.watch(currentSubscriptionProvider);
  return subscription.valueOrNull?.isActive ?? false;
});

final subscriptionPlanProvider = Provider<SubscriptionPlan>((ref) {
  final subscription = ref.watch(currentSubscriptionProvider);
  return subscription.valueOrNull?.plan ?? SubscriptionPlan.free;
});

final isFamilyPlanProvider = Provider<bool>((ref) {
  final plan = ref.watch(subscriptionPlanProvider);
  return plan == SubscriptionPlan.family || plan == SubscriptionPlan.premium;
});

final daysUntilRenewalProvider = Provider<int?>((ref) {
  final subscription = ref.watch(currentSubscriptionProvider);
  return subscription.valueOrNull?.daysUntilRenewal;
});

final isTrialingProvider = Provider<bool>((ref) {
  final subscription = ref.watch(currentSubscriptionProvider);
  return subscription.valueOrNull?.isTrialing ?? false;
});

final trialDaysRemainingProvider = Provider<int?>((ref) {
  final subscription = ref.watch(currentSubscriptionProvider);
  return subscription.valueOrNull?.daysUntilTrialEnd;
});

// ==========================================
// Payment Providers
// ==========================================

final paymentHistoryProvider = StreamProvider<List<Payment>>((ref) {
  final service = ref.watch(familyPricingServiceProvider);
  return service.getPaymentHistory();
});

final savedPaymentMethodsProvider =
    StreamProvider<List<SavedPaymentMethod>>((ref) {
  final service = ref.watch(familyPricingServiceProvider);
  return service.getSavedPaymentMethods();
});

final defaultPaymentMethodProvider = Provider<SavedPaymentMethod?>((ref) {
  final methods = ref.watch(savedPaymentMethodsProvider);
  final list = methods.valueOrNull ?? [];
  return list.where((m) => m.isDefault).firstOrNull ?? list.firstOrNull;
});

// ==========================================
// Family Account Providers
// ==========================================

final familyAccountProvider = StreamProvider<FamilyAccount?>((ref) {
  final service = ref.watch(familyPricingServiceProvider);
  return service.getCurrentFamilyAccount();
});

final familyMembersProvider = Provider<List<FamilyMember>>((ref) {
  final account = ref.watch(familyAccountProvider);
  return account.valueOrNull?.members ?? [];
});

final familyMemberCountProvider = Provider<int>((ref) {
  return ref.watch(familyMembersProvider).length;
});

final familyAvailableSlotsProvider = Provider<int>((ref) {
  final account = ref.watch(familyAccountProvider);
  return account.valueOrNull?.availableSlots ?? 0;
});

final isFamilyFullProvider = Provider<bool>((ref) {
  final account = ref.watch(familyAccountProvider);
  return account.valueOrNull?.isFull ?? false;
});

final familyOwnerProvider = Provider<FamilyMember?>((ref) {
  final account = ref.watch(familyAccountProvider);
  return account.valueOrNull?.owner;
});

// ==========================================
// Invitation Providers
// ==========================================

final pendingInvitationsProvider =
    StreamProvider<List<FamilyInvitation>>((ref) {
  final service = ref.watch(familyPricingServiceProvider);
  return service.getPendingInvitations();
});

final sentInvitationsProvider =
    StreamProvider.family<List<FamilyInvitation>, String>(
        (ref, familyAccountId) {
  final service = ref.watch(familyPricingServiceProvider);
  return service.getSentInvitations(familyAccountId);
});

final pendingInvitationCountProvider = Provider<int>((ref) {
  final invitations = ref.watch(pendingInvitationsProvider);
  return invitations.valueOrNull?.length ?? 0;
});

// ==========================================
// Family Usage Providers
// ==========================================

final familyUsageProvider =
    FutureProvider.family<List<FamilyMemberUsage>, String>(
        (ref, familyAccountId) {
  final service = ref.watch(familyPricingServiceProvider);
  return service.getFamilyUsage(familyAccountId);
});

// ==========================================
// Feature Access Providers
// ==========================================

final featureAccessProvider =
    FutureProvider.family<bool, String>((ref, featureId) {
  final service = ref.watch(familyPricingServiceProvider);
  return service.hasFeatureAccess(featureId);
});

final planFeaturesProvider =
    Provider.family<List<SubscriptionFeature>, SubscriptionPlan>((ref, plan) {
  return SubscriptionFeatures.getFeaturesForPlan(plan);
});

// ==========================================
// UI State Providers
// ==========================================

final selectedPlanProvider =
    StateProvider<SubscriptionPlan?>((ref) => null);

final isProcessingPaymentProvider = StateProvider<bool>((ref) => false);

final paymentErrorProvider = StateProvider<String?>((ref) => null);

/// Combined subscription summary for quick UI access
class SubscriptionSummary {
  final SubscriptionPlan plan;
  final bool isActive;
  final bool isTrialing;
  final int? daysUntilRenewal;
  final int? trialDaysRemaining;
  final double? monthlyAmount;
  final bool isFamilyPlan;
  final int familyMemberCount;
  final int familyMaxMembers;

  const SubscriptionSummary({
    required this.plan,
    required this.isActive,
    required this.isTrialing,
    this.daysUntilRenewal,
    this.trialDaysRemaining,
    this.monthlyAmount,
    required this.isFamilyPlan,
    required this.familyMemberCount,
    required this.familyMaxMembers,
  });
}

final subscriptionSummaryProvider = Provider<SubscriptionSummary>((ref) {
  final subscription = ref.watch(currentSubscriptionProvider).valueOrNull;
  final familyAccount = ref.watch(familyAccountProvider).valueOrNull;

  return SubscriptionSummary(
    plan: subscription?.plan ?? SubscriptionPlan.free,
    isActive: subscription?.isActive ?? false,
    isTrialing: subscription?.isTrialing ?? false,
    daysUntilRenewal: subscription?.daysUntilRenewal,
    trialDaysRemaining: subscription?.daysUntilTrialEnd,
    monthlyAmount: subscription?.amount,
    isFamilyPlan: subscription?.isFamilyPlan ?? false,
    familyMemberCount: familyAccount?.memberCount ?? 0,
    familyMaxMembers: familyAccount?.maxMembers ?? 1,
  );
});
