import 'package:cloud_firestore/cloud_firestore.dart';

/// Subscription plan types
enum SubscriptionPlan {
  free,
  individual,
  family,
  premium;

  String get displayName {
    switch (this) {
      case SubscriptionPlan.free:
        return 'Free';
      case SubscriptionPlan.individual:
        return 'Individual';
      case SubscriptionPlan.family:
        return 'Family';
      case SubscriptionPlan.premium:
        return 'Premium';
    }
  }

  String get description {
    switch (this) {
      case SubscriptionPlan.free:
        return 'Basic features for casual cyclists';
      case SubscriptionPlan.individual:
        return 'Full features for solo riders';
      case SubscriptionPlan.family:
        return 'Shared benefits for up to 6 members';
      case SubscriptionPlan.premium:
        return 'All features + exclusive perks';
    }
  }

  int get maxFamilyMembers {
    switch (this) {
      case SubscriptionPlan.family:
        return 6;
      case SubscriptionPlan.premium:
        return 8;
      default:
        return 1;
    }
  }
}

/// Subscription billing period
enum BillingPeriod {
  monthly,
  quarterly,
  yearly;

  String get displayName {
    switch (this) {
      case BillingPeriod.monthly:
        return 'Monthly';
      case BillingPeriod.quarterly:
        return 'Quarterly';
      case BillingPeriod.yearly:
        return 'Yearly';
    }
  }

  int get months {
    switch (this) {
      case BillingPeriod.monthly:
        return 1;
      case BillingPeriod.quarterly:
        return 3;
      case BillingPeriod.yearly:
        return 12;
    }
  }

  double get discountMultiplier {
    switch (this) {
      case BillingPeriod.monthly:
        return 1.0;
      case BillingPeriod.quarterly:
        return 0.90; // 10% discount
      case BillingPeriod.yearly:
        return 0.75; // 25% discount
    }
  }
}

/// Subscription status
enum SubscriptionStatus {
  active,
  trialing,
  pastDue,
  canceled,
  expired;

  bool get isActive => this == SubscriptionStatus.active || this == SubscriptionStatus.trialing;
}

/// Payment status
enum PaymentStatus {
  pending,
  processing,
  succeeded,
  failed,
  refunded;

  bool get isSuccessful => this == PaymentStatus.succeeded;
}

/// Payment method type
enum PaymentMethod {
  card,
  mobilePay,
  applePay,
  googlePay,
  paypal;

  String get displayName {
    switch (this) {
      case PaymentMethod.card:
        return 'Credit/Debit Card';
      case PaymentMethod.mobilePay:
        return 'MobilePay';
      case PaymentMethod.applePay:
        return 'Apple Pay';
      case PaymentMethod.googlePay:
        return 'Google Pay';
      case PaymentMethod.paypal:
        return 'PayPal';
    }
  }
}

/// Pricing model for subscription plans
class SubscriptionPricing {
  final SubscriptionPlan plan;
  final double monthlyPrice; // DKK
  final Map<BillingPeriod, double> prices; // DKK per period
  final List<String> features;
  final List<String> excludedFeatures;
  final bool isMostPopular;
  final bool isBestValue;
  final int? familyMemberLimit;
  final double? perMemberPrice; // Extra cost per additional member

  const SubscriptionPricing({
    required this.plan,
    required this.monthlyPrice,
    required this.prices,
    required this.features,
    this.excludedFeatures = const [],
    this.isMostPopular = false,
    this.isBestValue = false,
    this.familyMemberLimit,
    this.perMemberPrice,
  });

  double getPriceForPeriod(BillingPeriod period) {
    return prices[period] ?? (monthlyPrice * period.months * period.discountMultiplier);
  }

  double get yearlyPrice => getPriceForPeriod(BillingPeriod.yearly);
  double get yearlySavings => (monthlyPrice * 12) - yearlyPrice;
  double get yearlySavingsPercentage => (yearlySavings / (monthlyPrice * 12)) * 100;
}

/// User's active subscription
class Subscription {
  final String id;
  final String userId;
  final SubscriptionPlan plan;
  final BillingPeriod billingPeriod;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? trialEndDate;
  final DateTime? canceledAt;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final double amount; // DKK
  final String? paymentMethodId;
  final String? stripeSubscriptionId;
  final String? familyAccountId;
  final bool autoRenew;
  final Map<String, dynamic>? metadata;

  const Subscription({
    required this.id,
    required this.userId,
    required this.plan,
    required this.billingPeriod,
    required this.status,
    required this.startDate,
    this.endDate,
    this.trialEndDate,
    this.canceledAt,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    required this.amount,
    this.paymentMethodId,
    this.stripeSubscriptionId,
    this.familyAccountId,
    this.autoRenew = true,
    this.metadata,
  });

  bool get isActive => status.isActive;
  bool get isTrialing => status == SubscriptionStatus.trialing;
  bool get isCanceled => status == SubscriptionStatus.canceled;
  bool get isExpired => status == SubscriptionStatus.expired;
  bool get isFamilyPlan => plan == SubscriptionPlan.family || plan == SubscriptionPlan.premium;

  int? get daysUntilRenewal {
    if (currentPeriodEnd == null) return null;
    final now = DateTime.now();
    if (currentPeriodEnd!.isBefore(now)) return 0;
    return currentPeriodEnd!.difference(now).inDays;
  }

  int? get daysUntilTrialEnd {
    if (trialEndDate == null || !isTrialing) return null;
    final now = DateTime.now();
    if (trialEndDate!.isBefore(now)) return 0;
    return trialEndDate!.difference(now).inDays;
  }

  factory Subscription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Subscription(
      id: doc.id,
      userId: data['userId'] as String,
      plan: SubscriptionPlan.values.firstWhere(
        (e) => e.name == data['plan'],
        orElse: () => SubscriptionPlan.free,
      ),
      billingPeriod: BillingPeriod.values.firstWhere(
        (e) => e.name == data['billingPeriod'],
        orElse: () => BillingPeriod.monthly,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => SubscriptionStatus.expired,
      ),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
      trialEndDate: data['trialEndDate'] != null ? (data['trialEndDate'] as Timestamp).toDate() : null,
      canceledAt: data['canceledAt'] != null ? (data['canceledAt'] as Timestamp).toDate() : null,
      currentPeriodStart: data['currentPeriodStart'] != null ? (data['currentPeriodStart'] as Timestamp).toDate() : null,
      currentPeriodEnd: data['currentPeriodEnd'] != null ? (data['currentPeriodEnd'] as Timestamp).toDate() : null,
      amount: (data['amount'] as num).toDouble(),
      paymentMethodId: data['paymentMethodId'] as String?,
      stripeSubscriptionId: data['stripeSubscriptionId'] as String?,
      familyAccountId: data['familyAccountId'] as String?,
      autoRenew: data['autoRenew'] as bool? ?? true,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'plan': plan.name,
      'billingPeriod': billingPeriod.name,
      'status': status.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'trialEndDate': trialEndDate != null ? Timestamp.fromDate(trialEndDate!) : null,
      'canceledAt': canceledAt != null ? Timestamp.fromDate(canceledAt!) : null,
      'currentPeriodStart': currentPeriodStart != null ? Timestamp.fromDate(currentPeriodStart!) : null,
      'currentPeriodEnd': currentPeriodEnd != null ? Timestamp.fromDate(currentPeriodEnd!) : null,
      'amount': amount,
      'paymentMethodId': paymentMethodId,
      'stripeSubscriptionId': stripeSubscriptionId,
      'familyAccountId': familyAccountId,
      'autoRenew': autoRenew,
      'metadata': metadata,
    };
  }
}

/// Payment transaction record
class Payment {
  final String id;
  final String userId;
  final String? subscriptionId;
  final double amount; // DKK
  final String currency;
  final PaymentStatus status;
  final PaymentMethod method;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? stripePaymentIntentId;
  final String? receiptUrl;
  final String? failureReason;
  final String? description;
  final Map<String, dynamic>? metadata;

  const Payment({
    required this.id,
    required this.userId,
    this.subscriptionId,
    required this.amount,
    this.currency = 'DKK',
    required this.status,
    required this.method,
    required this.createdAt,
    this.processedAt,
    this.stripePaymentIntentId,
    this.receiptUrl,
    this.failureReason,
    this.description,
    this.metadata,
  });

  bool get isSuccessful => status.isSuccessful;
  bool get isPending => status == PaymentStatus.pending || status == PaymentStatus.processing;
  bool get hasFailed => status == PaymentStatus.failed;

  factory Payment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Payment(
      id: doc.id,
      userId: data['userId'] as String,
      subscriptionId: data['subscriptionId'] as String?,
      amount: (data['amount'] as num).toDouble(),
      currency: data['currency'] as String? ?? 'DKK',
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => PaymentStatus.pending,
      ),
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == data['method'],
        orElse: () => PaymentMethod.card,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      processedAt: data['processedAt'] != null ? (data['processedAt'] as Timestamp).toDate() : null,
      stripePaymentIntentId: data['stripePaymentIntentId'] as String?,
      receiptUrl: data['receiptUrl'] as String?,
      failureReason: data['failureReason'] as String?,
      description: data['description'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'subscriptionId': subscriptionId,
      'amount': amount,
      'currency': currency,
      'status': status.name,
      'method': method.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'stripePaymentIntentId': stripePaymentIntentId,
      'receiptUrl': receiptUrl,
      'failureReason': failureReason,
      'description': description,
      'metadata': metadata,
    };
  }
}

/// Saved payment method
class SavedPaymentMethod {
  final String id;
  final String userId;
  final PaymentMethod type;
  final String? last4; // Last 4 digits for card
  final String? brand; // Visa, Mastercard, etc.
  final int? expiryMonth;
  final int? expiryYear;
  final bool isDefault;
  final String? stripePaymentMethodId;
  final DateTime createdAt;

  const SavedPaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    this.last4,
    this.brand,
    this.expiryMonth,
    this.expiryYear,
    this.isDefault = false,
    this.stripePaymentMethodId,
    required this.createdAt,
  });

  bool get isExpired {
    if (expiryMonth == null || expiryYear == null) return false;
    final now = DateTime.now();
    final expiryDate = DateTime(expiryYear!, expiryMonth!);
    return expiryDate.isBefore(now);
  }

  String get displayName {
    if (type == PaymentMethod.card && brand != null && last4 != null) {
      return '$brand •••• $last4';
    }
    return type.displayName;
  }

  factory SavedPaymentMethod.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavedPaymentMethod(
      id: doc.id,
      userId: data['userId'] as String,
      type: PaymentMethod.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => PaymentMethod.card,
      ),
      last4: data['last4'] as String?,
      brand: data['brand'] as String?,
      expiryMonth: data['expiryMonth'] as int?,
      expiryYear: data['expiryYear'] as int?,
      isDefault: data['isDefault'] as bool? ?? false,
      stripePaymentMethodId: data['stripePaymentMethodId'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'last4': last4,
      'brand': brand,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'isDefault': isDefault,
      'stripePaymentMethodId': stripePaymentMethodId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Features included in subscription plans
class SubscriptionFeature {
  final String id;
  final String name;
  final String description;
  final String icon;
  final List<SubscriptionPlan> availableIn;
  final bool isPremiumOnly;

  const SubscriptionFeature({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.availableIn,
    this.isPremiumOnly = false,
  });

  bool isAvailableIn(SubscriptionPlan plan) => availableIn.contains(plan);
}

/// Static feature definitions
class SubscriptionFeatures {
  static const basicFeatures = [
    SubscriptionFeature(
      id: 'bike_tracking',
      name: 'Basic Bike Tracking',
      description: 'Track your bike rides',
      icon: '🚴',
      availableIn: [
        SubscriptionPlan.free,
        SubscriptionPlan.individual,
        SubscriptionPlan.family,
        SubscriptionPlan.premium,
      ],
    ),
    SubscriptionFeature(
      id: 'route_planning',
      name: 'Route Planning',
      description: 'Plan cycling routes',
      icon: '🗺️',
      availableIn: [
        SubscriptionPlan.free,
        SubscriptionPlan.individual,
        SubscriptionPlan.family,
        SubscriptionPlan.premium,
      ],
    ),
  ];

  static const individualFeatures = [
    SubscriptionFeature(
      id: 'advanced_stats',
      name: 'Advanced Statistics',
      description: 'Detailed ride analytics',
      icon: '📊',
      availableIn: [
        SubscriptionPlan.individual,
        SubscriptionPlan.family,
        SubscriptionPlan.premium,
      ],
    ),
    SubscriptionFeature(
      id: 'offline_maps',
      name: 'Offline Maps',
      description: 'Download maps for offline use',
      icon: '🗾',
      availableIn: [
        SubscriptionPlan.individual,
        SubscriptionPlan.family,
        SubscriptionPlan.premium,
      ],
    ),
    SubscriptionFeature(
      id: 'weather_alerts',
      name: 'Weather Alerts',
      description: 'Real-time weather notifications',
      icon: '⛈️',
      availableIn: [
        SubscriptionPlan.individual,
        SubscriptionPlan.family,
        SubscriptionPlan.premium,
      ],
    ),
    SubscriptionFeature(
      id: 'priority_support',
      name: 'Priority Support',
      description: '24/7 customer support',
      icon: '💬',
      availableIn: [
        SubscriptionPlan.individual,
        SubscriptionPlan.family,
        SubscriptionPlan.premium,
      ],
    ),
  ];

  static const familyFeatures = [
    SubscriptionFeature(
      id: 'family_sharing',
      name: 'Family Sharing',
      description: 'Share subscription with up to 6 members',
      icon: '👨‍👩‍👧‍👦',
      availableIn: [
        SubscriptionPlan.family,
        SubscriptionPlan.premium,
      ],
    ),
    SubscriptionFeature(
      id: 'family_dashboard',
      name: 'Family Dashboard',
      description: 'View family member activities',
      icon: '📱',
      availableIn: [
        SubscriptionPlan.family,
        SubscriptionPlan.premium,
      ],
    ),
    SubscriptionFeature(
      id: 'shared_routes',
      name: 'Shared Routes',
      description: 'Share favorite routes with family',
      icon: '🔗',
      availableIn: [
        SubscriptionPlan.family,
        SubscriptionPlan.premium,
      ],
    ),
  ];

  static const premiumFeatures = [
    SubscriptionFeature(
      id: 'premium_routes',
      name: 'Premium Routes',
      description: 'Exclusive curated routes',
      icon: '⭐',
      availableIn: [SubscriptionPlan.premium],
      isPremiumOnly: true,
    ),
    SubscriptionFeature(
      id: 'coaching',
      name: 'Personal Coaching',
      description: 'AI-powered cycling coach',
      icon: '🎯',
      availableIn: [SubscriptionPlan.premium],
      isPremiumOnly: true,
    ),
    SubscriptionFeature(
      id: 'unlimited_buddies',
      name: 'Unlimited Buddy Matches',
      description: 'Connect with unlimited cycling buddies',
      icon: '🤝',
      availableIn: [SubscriptionPlan.premium],
      isPremiumOnly: true,
    ),
    SubscriptionFeature(
      id: 'bike_insurance',
      name: 'Bike Insurance Discount',
      description: '20% off bike insurance',
      icon: '🛡️',
      availableIn: [SubscriptionPlan.premium],
      isPremiumOnly: true,
    ),
  ];

  static List<SubscriptionFeature> getAllFeatures() {
    return [
      ...basicFeatures,
      ...individualFeatures,
      ...familyFeatures,
      ...premiumFeatures,
    ];
  }

  static List<SubscriptionFeature> getFeaturesForPlan(SubscriptionPlan plan) {
    return getAllFeatures().where((feature) => feature.isAvailableIn(plan)).toList();
  }
}
