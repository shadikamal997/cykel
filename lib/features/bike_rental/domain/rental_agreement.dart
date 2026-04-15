/// CYKEL — Rental Request and Agreement Models
/// Rental booking flow and management

import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Rental Request ──────────────────────────────────────────────────────────

enum RentalRequestStatus {
  pending,      // Awaiting owner approval
  approved,     // Owner approved
  declined,     // Owner declined
  cancelled,    // Renter cancelled
  expired;      // Request expired

  String get displayName {
    switch (this) {
      case RentalRequestStatus.pending:
        return 'Pending';
      case RentalRequestStatus.approved:
        return 'Approved';
      case RentalRequestStatus.declined:
        return 'Declined';
      case RentalRequestStatus.cancelled:
        return 'Cancelled';
      case RentalRequestStatus.expired:
        return 'Expired';
    }
  }

  String get icon {
    switch (this) {
      case RentalRequestStatus.pending:
        return '⏳';
      case RentalRequestStatus.approved:
        return '✅';
      case RentalRequestStatus.declined:
        return '❌';
      case RentalRequestStatus.cancelled:
        return '🚫';
      case RentalRequestStatus.expired:
        return '⌛';
    }
  }
}

class RentalRequest {
  const RentalRequest({
    required this.id,
    required this.listingId,
    required this.renterId,
    required this.ownerId,
    required this.startTime,
    required this.endTime,
    required this.totalCost,
    required this.depositAmount,
    required this.status,
    required this.createdAt,
    this.message,
    this.declineReason,
    this.respondedAt,
    this.expiresAt,
  });

  final String id;
  final String listingId;
  final String renterId;
  final String ownerId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalCost;
  final double depositAmount;
  final RentalRequestStatus status;
  final DateTime createdAt;

  final String? message; // Message from renter
  final String? declineReason; // Reason if declined
  final DateTime? respondedAt;
  final DateTime? expiresAt; // Auto-expire after 24h

  bool get isPending => status == RentalRequestStatus.pending;
  bool get isApproved => status == RentalRequestStatus.approved;
  bool get isDeclined => status == RentalRequestStatus.declined;
  bool get isCancelled => status == RentalRequestStatus.cancelled;
  bool get isExpired => status == RentalRequestStatus.expired;

  Duration get rentalDuration => endTime.difference(startTime);
  int get rentalDays => rentalDuration.inDays;
  int get rentalHours => rentalDuration.inHours;

  bool get isExpiredByTime {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  factory RentalRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return RentalRequest(
      id: doc.id,
      listingId: data['listingId'] as String,
      renterId: data['renterId'] as String,
      ownerId: data['ownerId'] as String,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      totalCost: (data['totalCost'] as num).toDouble(),
      depositAmount: (data['depositAmount'] as num).toDouble(),
      status: RentalRequestStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => RentalRequestStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      message: data['message'] as String?,
      declineReason: data['declineReason'] as String?,
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'listingId': listingId,
        'renterId': renterId,
        'ownerId': ownerId,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'totalCost': totalCost,
        'depositAmount': depositAmount,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'message': message,
        'declineReason': declineReason,
        'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      };

  RentalRequest copyWith({
    RentalRequestStatus? status,
    String? declineReason,
    DateTime? respondedAt,
  }) {
    return RentalRequest(
      id: id,
      listingId: listingId,
      renterId: renterId,
      ownerId: ownerId,
      startTime: startTime,
      endTime: endTime,
      totalCost: totalCost,
      depositAmount: depositAmount,
      status: status ?? this.status,
      createdAt: createdAt,
      message: message,
      declineReason: declineReason ?? this.declineReason,
      respondedAt: respondedAt ?? this.respondedAt,
      expiresAt: expiresAt,
    );
  }
}

// ─── Rental Agreement ────────────────────────────────────────────────────────

enum RentalAgreementStatus {
  upcoming,     // Confirmed, waiting for start time
  active,       // Currently renting
  completed,    // Rental finished
  cancelled,    // Cancelled before start
  disputed;     // Under dispute

  String get displayName {
    switch (this) {
      case RentalAgreementStatus.upcoming:
        return 'Upcoming';
      case RentalAgreementStatus.active:
        return 'Active';
      case RentalAgreementStatus.completed:
        return 'Completed';
      case RentalAgreementStatus.cancelled:
        return 'Cancelled';
      case RentalAgreementStatus.disputed:
        return 'Disputed';
    }
  }

  String get icon {
    switch (this) {
      case RentalAgreementStatus.upcoming:
        return '📅';
      case RentalAgreementStatus.active:
        return '🚲';
      case RentalAgreementStatus.completed:
        return '✅';
      case RentalAgreementStatus.cancelled:
        return '❌';
      case RentalAgreementStatus.disputed:
        return '⚠️';
    }
  }
}

enum PaymentStatus {
  pending,          // Payment not yet processed
  authorized,       // Payment authorized (card hold)
  captured,         // Payment captured
  refunded,         // Payment refunded (partial or full)
  failed;           // Payment failed

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.authorized:
        return 'Authorized';
      case PaymentStatus.captured:
        return 'Captured';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.failed:
        return 'Failed';
    }
  }
}

class RentalAgreement {
  const RentalAgreement({
    required this.id,
    required this.requestId,
    required this.listingId,
    required this.renterId,
    required this.ownerId,
    required this.startTime,
    required this.endTime,
    required this.rentalCost,
    required this.depositAmount,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
    this.pickupTime,
    this.returnTime,
    this.pickupPhotos = const [],
    this.returnPhotos = const [],
    this.pickupNotes,
    this.returnNotes,
    this.damageReported = false,
    this.damageDescription,
    this.damagePhotos = const [],
    this.depositReturned = false,
    this.depositReturnedAt,
    this.depositReturnAmount,
    this.cancellationReason,
    this.cancelledAt,
    this.cancelledBy,
    this.paymentIntentId,
    this.refundAmount,
  });

  final String id;
  final String requestId;
  final String listingId;
  final String renterId;
  final String ownerId;
  final DateTime startTime;
  final DateTime endTime;
  final double rentalCost;
  final double depositAmount;
  final double totalAmount;
  final RentalAgreementStatus status;
  final PaymentStatus paymentStatus;
  final DateTime createdAt;

  // Pickup/Return tracking
  final DateTime? pickupTime;
  final DateTime? returnTime;
  final List<String> pickupPhotos;
  final List<String> returnPhotos;
  final String? pickupNotes;
  final String? returnNotes;

  // Damage tracking
  final bool damageReported;
  final String? damageDescription;
  final List<String> damagePhotos;

  // Deposit management
  final bool depositReturned;
  final DateTime? depositReturnedAt;
  final double? depositReturnAmount;

  // Cancellation
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final String? cancelledBy; // userId who cancelled

  // Payment
  final String? paymentIntentId; // Stripe payment intent
  final double? refundAmount;

  bool get isUpcoming => status == RentalAgreementStatus.upcoming;
  bool get isActive => status == RentalAgreementStatus.active;
  bool get isCompleted => status == RentalAgreementStatus.completed;
  bool get isCancelled => status == RentalAgreementStatus.cancelled;
  bool get isDisputed => status == RentalAgreementStatus.disputed;

  bool get isPickedUp => pickupTime != null;
  bool get isReturned => returnTime != null;
  bool get hasStarted => DateTime.now().isAfter(startTime);
  bool get hasEnded => DateTime.now().isAfter(endTime);

  Duration get rentalDuration => endTime.difference(startTime);
  Duration? get actualDuration {
    if (pickupTime == null) return null;
    final end = returnTime ?? DateTime.now();
    return end.difference(pickupTime!);
  }

  bool get isOverdue {
    if (returnTime != null) return false;
    return DateTime.now().isAfter(endTime);
  }

  Duration? get overdueBy {
    if (!isOverdue) return null;
    return DateTime.now().difference(endTime);
  }

  factory RentalAgreement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return RentalAgreement(
      id: doc.id,
      requestId: data['requestId'] as String,
      listingId: data['listingId'] as String,
      renterId: data['renterId'] as String,
      ownerId: data['ownerId'] as String,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      rentalCost: (data['rentalCost'] as num).toDouble(),
      depositAmount: (data['depositAmount'] as num).toDouble(),
      totalAmount: (data['totalAmount'] as num).toDouble(),
      status: RentalAgreementStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => RentalAgreementStatus.upcoming,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (s) => s.name == data['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      pickupTime: data['pickupTime'] != null
          ? (data['pickupTime'] as Timestamp).toDate()
          : null,
      returnTime: data['returnTime'] != null
          ? (data['returnTime'] as Timestamp).toDate()
          : null,
      pickupPhotos: (data['pickupPhotos'] as List<dynamic>?)?.cast<String>() ?? [],
      returnPhotos: (data['returnPhotos'] as List<dynamic>?)?.cast<String>() ?? [],
      pickupNotes: data['pickupNotes'] as String?,
      returnNotes: data['returnNotes'] as String?,
      damageReported: data['damageReported'] as bool? ?? false,
      damageDescription: data['damageDescription'] as String?,
      damagePhotos: (data['damagePhotos'] as List<dynamic>?)?.cast<String>() ?? [],
      depositReturned: data['depositReturned'] as bool? ?? false,
      depositReturnedAt: data['depositReturnedAt'] != null
          ? (data['depositReturnedAt'] as Timestamp).toDate()
          : null,
      depositReturnAmount: (data['depositReturnAmount'] as num?)?.toDouble(),
      cancellationReason: data['cancellationReason'] as String?,
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
      cancelledBy: data['cancelledBy'] as String?,
      paymentIntentId: data['paymentIntentId'] as String?,
      refundAmount: (data['refundAmount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'requestId': requestId,
        'listingId': listingId,
        'renterId': renterId,
        'ownerId': ownerId,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'rentalCost': rentalCost,
        'depositAmount': depositAmount,
        'totalAmount': totalAmount,
        'status': status.name,
        'paymentStatus': paymentStatus.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'pickupTime': pickupTime != null ? Timestamp.fromDate(pickupTime!) : null,
        'returnTime': returnTime != null ? Timestamp.fromDate(returnTime!) : null,
        'pickupPhotos': pickupPhotos,
        'returnPhotos': returnPhotos,
        'pickupNotes': pickupNotes,
        'returnNotes': returnNotes,
        'damageReported': damageReported,
        'damageDescription': damageDescription,
        'damagePhotos': damagePhotos,
        'depositReturned': depositReturned,
        'depositReturnedAt':
            depositReturnedAt != null ? Timestamp.fromDate(depositReturnedAt!) : null,
        'depositReturnAmount': depositReturnAmount,
        'cancellationReason': cancellationReason,
        'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
        'cancelledBy': cancelledBy,
        'paymentIntentId': paymentIntentId,
        'refundAmount': refundAmount,
      };

  RentalAgreement copyWith({
    RentalAgreementStatus? status,
    PaymentStatus? paymentStatus,
    DateTime? pickupTime,
    DateTime? returnTime,
    List<String>? pickupPhotos,
    List<String>? returnPhotos,
    String? pickupNotes,
    String? returnNotes,
    bool? damageReported,
    String? damageDescription,
    List<String>? damagePhotos,
    bool? depositReturned,
    DateTime? depositReturnedAt,
    double? depositReturnAmount,
    String? cancellationReason,
    DateTime? cancelledAt,
    String? cancelledBy,
    String? paymentIntentId,
    double? refundAmount,
  }) {
    return RentalAgreement(
      id: id,
      requestId: requestId,
      listingId: listingId,
      renterId: renterId,
      ownerId: ownerId,
      startTime: startTime,
      endTime: endTime,
      rentalCost: rentalCost,
      depositAmount: depositAmount,
      totalAmount: totalAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt,
      pickupTime: pickupTime ?? this.pickupTime,
      returnTime: returnTime ?? this.returnTime,
      pickupPhotos: pickupPhotos ?? this.pickupPhotos,
      returnPhotos: returnPhotos ?? this.returnPhotos,
      pickupNotes: pickupNotes ?? this.pickupNotes,
      returnNotes: returnNotes ?? this.returnNotes,
      damageReported: damageReported ?? this.damageReported,
      damageDescription: damageDescription ?? this.damageDescription,
      damagePhotos: damagePhotos ?? this.damagePhotos,
      depositReturned: depositReturned ?? this.depositReturned,
      depositReturnedAt: depositReturnedAt ?? this.depositReturnedAt,
      depositReturnAmount: depositReturnAmount ?? this.depositReturnAmount,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      refundAmount: refundAmount ?? this.refundAmount,
    );
  }
}

// ─── Review and Rating ───────────────────────────────────────────────────────

enum ReviewType {
  renter,  // Review of the renter (by owner)
  owner,   // Review of the owner (by renter)
  bike;    // Review of the bike (by renter)

  String get displayName {
    switch (this) {
      case ReviewType.renter:
        return 'Renter Review';
      case ReviewType.owner:
        return 'Owner Review';
      case ReviewType.bike:
        return 'Bike Review';
    }
  }
}

class BikeReview {
  const BikeReview({
    required this.id,
    required this.agreementId,
    required this.listingId,
    required this.reviewerId,
    required this.revieweeId,
    required this.type,
    required this.rating,
    required this.createdAt,
    this.comment,
    this.cleanliness,      // For bike reviews
    this.condition,        // For bike reviews
    this.communication,    // For owner/renter reviews
    this.reliability,      // For owner/renter reviews
    this.respectfulness,   // For renter reviews
  });

  final String id;
  final String agreementId;
  final String listingId;
  final String reviewerId; // User who wrote the review
  final String revieweeId; // User or bike being reviewed
  final ReviewType type;
  final int rating; // 1-5 stars
  final DateTime createdAt;

  final String? comment;

  // Bike-specific ratings (1-5)
  final int? cleanliness;
  final int? condition;

  // Owner/Renter-specific ratings (1-5)
  final int? communication;
  final int? reliability;
  final int? respectfulness;

  bool get isPositive => rating >= 4;
  bool get isNegative => rating <= 2;
  bool get hasComment => comment != null && comment!.isNotEmpty;

  factory BikeReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return BikeReview(
      id: doc.id,
      agreementId: data['agreementId'] as String,
      listingId: data['listingId'] as String,
      reviewerId: data['reviewerId'] as String,
      revieweeId: data['revieweeId'] as String,
      type: ReviewType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => ReviewType.bike,
      ),
      rating: (data['rating'] as num).toInt(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      comment: data['comment'] as String?,
      cleanliness: (data['cleanliness'] as num?)?.toInt(),
      condition: (data['condition'] as num?)?.toInt(),
      communication: (data['communication'] as num?)?.toInt(),
      reliability: (data['reliability'] as num?)?.toInt(),
      respectfulness: (data['respectfulness'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'agreementId': agreementId,
        'listingId': listingId,
        'reviewerId': reviewerId,
        'revieweeId': revieweeId,
        'type': type.name,
        'rating': rating,
        'createdAt': Timestamp.fromDate(createdAt),
        'comment': comment,
        'cleanliness': cleanliness,
        'condition': condition,
        'communication': communication,
        'reliability': reliability,
        'respectfulness': respectfulness,
      };
}
