/// CYKEL — P2P Bike Rental Domain Models
/// Bike listings, rental requests, and agreements

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ─── Bike Types & Specs ──────────────────────────────────────────────────────

enum BikeType {
  city,           // City/cruiser bikes
  road,           // Road bikes
  mountain,       // Mountain bikes
  hybrid,         // Hybrid bikes
  electric,       // E-bikes
  cargo,          // Cargo bikes
  folding,        // Folding bikes
  touring,        // Touring bikes
  bmx,            // BMX bikes
  kids;           // Kids bikes

  String get displayName {
    switch (this) {
      case BikeType.city:
        return 'City Bike';
      case BikeType.road:
        return 'Road Bike';
      case BikeType.mountain:
        return 'Mountain Bike';
      case BikeType.hybrid:
        return 'Hybrid';
      case BikeType.electric:
        return 'Electric Bike';
      case BikeType.cargo:
        return 'Cargo Bike';
      case BikeType.folding:
        return 'Folding Bike';
      case BikeType.touring:
        return 'Touring Bike';
      case BikeType.bmx:
        return 'BMX';
      case BikeType.kids:
        return 'Kids Bike';
    }
  }

  String get icon {
    switch (this) {
      case BikeType.city:
        return '🚲';
      case BikeType.road:
        return '🚴';
      case BikeType.mountain:
        return '🚵';
      case BikeType.hybrid:
        return '🚴‍♀️';
      case BikeType.electric:
        return '⚡';
      case BikeType.cargo:
        return '📦';
      case BikeType.folding:
        return '🔄';
      case BikeType.touring:
        return '🗺️';
      case BikeType.bmx:
        return '🛹';
      case BikeType.kids:
        return '👶';
    }
  }
}

enum BikeCondition {
  excellent,    // Like new
  good,         // Well maintained
  fair,         // Some wear
  poor;         // Needs work

  String get displayName {
    switch (this) {
      case BikeCondition.excellent:
        return 'Excellent';
      case BikeCondition.good:
        return 'Good';
      case BikeCondition.fair:
        return 'Fair';
      case BikeCondition.poor:
        return 'Poor';
    }
  }

  String get description {
    switch (this) {
      case BikeCondition.excellent:
        return 'Like new, minimal wear';
      case BikeCondition.good:
        return 'Well maintained, normal wear';
      case BikeCondition.fair:
        return 'Some wear, fully functional';
      case BikeCondition.poor:
        return 'Significant wear, may need maintenance';
    }
  }
}

enum BikeSize {
  xs,     // Extra Small (under 150cm)
  s,      // Small (150-165cm)
  m,      // Medium (165-178cm)
  l,      // Large (178-185cm)
  xl,     // Extra Large (185-195cm)
  xxl;    // XXL (over 195cm)

  String get displayName {
    switch (this) {
      case BikeSize.xs:
        return 'XS';
      case BikeSize.s:
        return 'S';
      case BikeSize.m:
        return 'M';
      case BikeSize.l:
        return 'L';
      case BikeSize.xl:
        return 'XL';
      case BikeSize.xxl:
        return 'XXL';
    }
  }

  String get heightRange {
    switch (this) {
      case BikeSize.xs:
        return 'Under 150cm';
      case BikeSize.s:
        return '150-165cm';
      case BikeSize.m:
        return '165-178cm';
      case BikeSize.l:
        return '178-185cm';
      case BikeSize.xl:
        return '185-195cm';
      case BikeSize.xxl:
        return 'Over 195cm';
    }
  }
}

// ─── Bike Listing ────────────────────────────────────────────────────────────

class BikeFeatures {
  const BikeFeatures({
    this.hasLights = false,
    this.hasLock = false,
    this.hasBasket = false,
    this.hasRack = false,
    this.hasHelmet = false,
    this.hasBell = false,
    this.hasGears = false,
    this.gearCount,
    this.hasChildSeat = false,
    this.hasKickstand = false,
  });

  final bool hasLights;
  final bool hasLock;
  final bool hasBasket;
  final bool hasRack;
  final bool hasHelmet;
  final bool hasBell;
  final bool hasGears;
  final int? gearCount;
  final bool hasChildSeat;
  final bool hasKickstand;

  factory BikeFeatures.fromFirestore(Map<String, dynamic> data) {
    return BikeFeatures(
      hasLights: data['hasLights'] as bool? ?? false,
      hasLock: data['hasLock'] as bool? ?? false,
      hasBasket: data['hasBasket'] as bool? ?? false,
      hasRack: data['hasRack'] as bool? ?? false,
      hasHelmet: data['hasHelmet'] as bool? ?? false,
      hasBell: data['hasBell'] as bool? ?? false,
      hasGears: data['hasGears'] as bool? ?? false,
      gearCount: (data['gearCount'] as num?)?.toInt(),
      hasChildSeat: data['hasChildSeat'] as bool? ?? false,
      hasKickstand: data['hasKickstand'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'hasLights': hasLights,
        'hasLock': hasLock,
        'hasBasket': hasBasket,
        'hasRack': hasRack,
        'hasHelmet': hasHelmet,
        'hasBell': hasBell,
        'hasGears': hasGears,
        'gearCount': gearCount,
        'hasChildSeat': hasChildSeat,
        'hasKickstand': hasKickstand,
      };

  List<String> get featuresList {
    final features = <String>[];
    if (hasLights) features.add('Lights');
    if (hasLock) features.add('Lock');
    if (hasBasket) features.add('Basket');
    if (hasRack) features.add('Rack');
    if (hasHelmet) features.add('Helmet included');
    if (hasBell) features.add('Bell');
    if (hasGears && gearCount != null) features.add('$gearCount gears');
    if (hasChildSeat) features.add('Child seat');
    if (hasKickstand) features.add('Kickstand');
    return features;
  }

  BikeFeatures copyWith({
    bool? hasLights,
    bool? hasLock,
    bool? hasBasket,
    bool? hasRack,
    bool? hasHelmet,
    bool? hasBell,
    bool? hasGears,
    int? gearCount,
    bool? hasChildSeat,
    bool? hasKickstand,
  }) {
    return BikeFeatures(
      hasLights: hasLights ?? this.hasLights,
      hasLock: hasLock ?? this.hasLock,
      hasBasket: hasBasket ?? this.hasBasket,
      hasRack: hasRack ?? this.hasRack,
      hasHelmet: hasHelmet ?? this.hasHelmet,
      hasBell: hasBell ?? this.hasBell,
      hasGears: hasGears ?? this.hasGears,
      gearCount: gearCount ?? this.gearCount,
      hasChildSeat: hasChildSeat ?? this.hasChildSeat,
      hasKickstand: hasKickstand ?? this.hasKickstand,
    );
  }
}

class BikePricing {
  const BikePricing({
    required this.hourlyRate,
    required this.dailyRate,
    this.weeklyRate,
    required this.depositAmount,
    this.currency = 'DKK',
  });

  final double hourlyRate;
  final double dailyRate;
  final double? weeklyRate;
  final double depositAmount;
  final String currency;

  factory BikePricing.fromFirestore(Map<String, dynamic> data) {
    return BikePricing(
      hourlyRate: (data['hourlyRate'] as num).toDouble(),
      dailyRate: (data['dailyRate'] as num).toDouble(),
      weeklyRate: (data['weeklyRate'] as num?)?.toDouble(),
      depositAmount: (data['depositAmount'] as num).toDouble(),
      currency: data['currency'] as String? ?? 'DKK',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'hourlyRate': hourlyRate,
        'dailyRate': dailyRate,
        'weeklyRate': weeklyRate,
        'depositAmount': depositAmount,
        'currency': currency,
      };

  String formatPrice(double price) {
    return '$price $currency';
  }

  String get formattedHourlyRate => formatPrice(hourlyRate);
  String get formattedDailyRate => formatPrice(dailyRate);
  String? get formattedWeeklyRate => weeklyRate != null ? formatPrice(weeklyRate!) : null;
  String get formattedDeposit => formatPrice(depositAmount);

  /// Calculate total rental cost
  double calculateCost({
    required DateTime startTime,
    required DateTime endTime,
  }) {
    final duration = endTime.difference(startTime);
    final hours = duration.inHours;
    final days = duration.inDays;

    // If rental is 7+ days and weekly rate exists, use weekly rate
    if (days >= 7 && weeklyRate != null) {
      final weeks = days ~/ 7;
      final remainingDays = days % 7;
      return (weeks * weeklyRate!) + (remainingDays * dailyRate);
    }

    // If rental is 24+ hours, use daily rate
    if (hours >= 24) {
      return days * dailyRate + ((hours % 24) > 0 ? dailyRate : 0);
    }

    // For short rentals, use hourly rate
    return hours * hourlyRate + (duration.inMinutes % 60 > 0 ? hourlyRate : 0);
  }

  BikePricing copyWith({
    double? hourlyRate,
    double? dailyRate,
    double? weeklyRate,
    double? depositAmount,
    String? currency,
  }) {
    return BikePricing(
      hourlyRate: hourlyRate ?? this.hourlyRate,
      dailyRate: dailyRate ?? this.dailyRate,
      weeklyRate: weeklyRate ?? this.weeklyRate,
      depositAmount: depositAmount ?? this.depositAmount,
      currency: currency ?? this.currency,
    );
  }
}

enum ListingStatus {
  active,       // Available for rent
  rented,       // Currently rented out
  unavailable,  // Temporarily unavailable
  archived;     // No longer available

  String get displayName {
    switch (this) {
      case ListingStatus.active:
        return 'Available';
      case ListingStatus.rented:
        return 'Rented';
      case ListingStatus.unavailable:
        return 'Unavailable';
      case ListingStatus.archived:
        return 'Archived';
    }
  }
}

class BikeListing {
  const BikeListing({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.bikeType,
    required this.size,
    required this.condition,
    required this.pricing,
    required this.features,
    required this.location,
    required this.locationName,
    required this.photoUrls,
    required this.status,
    required this.createdAt,
    this.brand,
    this.model,
    this.year,
    this.color,
    this.availableFrom,
    this.availableTo,
    this.unavailableDates = const [],
    this.minimumRentalHours = 1,
    this.maximumRentalDays,
    this.pickupInstructions,
    this.rules,
    this.averageRating = 0.0,
    this.totalRentals = 0,
    this.totalReviews = 0,
    this.lastRentedAt,
    this.isVerified = false,
  });

  final String id;
  final String ownerId;
  final String title;
  final String description;
  final BikeType bikeType;
  final BikeSize size;
  final BikeCondition condition;
  final BikePricing pricing;
  final BikeFeatures features;
  final LatLng location;
  final String locationName;
  final List<String> photoUrls;
  final ListingStatus status;
  final DateTime createdAt;

  // Optional bike details
  final String? brand;
  final String? model;
  final int? year;
  final String? color;

  // Availability
  final DateTime? availableFrom;
  final DateTime? availableTo;
  final List<DateTime> unavailableDates;
  final int minimumRentalHours;
  final int? maximumRentalDays;

  // Rental information
  final String? pickupInstructions;
  final String? rules;

  // Statistics
  final double averageRating;
  final int totalRentals;
  final int totalReviews;
  final DateTime? lastRentedAt;
  final bool isVerified;

  bool get isAvailable => status == ListingStatus.active;
  bool get isCurrentlyRented => status == ListingStatus.rented;
  bool get hasPhotos => photoUrls.isNotEmpty;
  bool get hasReviews => totalReviews > 0;

  /// Check if bike is available on a specific date
  bool isAvailableOnDate(DateTime date) {
    if (status != ListingStatus.active) return false;

    final dateOnly = DateTime(date.year, date.month, date.day);

    // Check if date is within available range
    if (availableFrom != null && dateOnly.isBefore(availableFrom!)) {
      return false;
    }
    if (availableTo != null && dateOnly.isAfter(availableTo!)) {
      return false;
    }

    // Check if date is in unavailable dates
    return !unavailableDates.any((unavailable) {
      final unavailableOnly = DateTime(
        unavailable.year,
        unavailable.month,
        unavailable.day,
      );
      return unavailableOnly.isAtSameMomentAs(dateOnly);
    });
  }

  /// Check if bike is available for a date range
  bool isAvailableForPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final duration = endDate.difference(startDate);
    
    // Check minimum rental hours
    if (duration.inHours < minimumRentalHours) {
      return false;
    }

    // Check maximum rental days
    if (maximumRentalDays != null && duration.inDays > maximumRentalDays!) {
      return false;
    }

    // Check each day in the period
    var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final lastDate = DateTime(endDate.year, endDate.month, endDate.day);

    while (currentDate.isBefore(lastDate) || currentDate.isAtSameMomentAs(lastDate)) {
      if (!isAvailableOnDate(currentDate)) {
        return false;
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return true;
  }

  factory BikeListing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final locationData = data['location'] as GeoPoint;

    return BikeListing(
      id: doc.id,
      ownerId: data['ownerId'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      bikeType: BikeType.values.firstWhere(
        (t) => t.name == data['bikeType'],
        orElse: () => BikeType.city,
      ),
      size: BikeSize.values.firstWhere(
        (s) => s.name == data['size'],
        orElse: () => BikeSize.m,
      ),
      condition: BikeCondition.values.firstWhere(
        (c) => c.name == data['condition'],
        orElse: () => BikeCondition.good,
      ),
      pricing: BikePricing.fromFirestore(data['pricing'] as Map<String, dynamic>),
      features: BikeFeatures.fromFirestore(data['features'] as Map<String, dynamic>),
      location: LatLng(locationData.latitude, locationData.longitude),
      locationName: data['locationName'] as String,
      photoUrls: (data['photoUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      status: ListingStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ListingStatus.active,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      brand: data['brand'] as String?,
      model: data['model'] as String?,
      year: (data['year'] as num?)?.toInt(),
      color: data['color'] as String?,
      availableFrom: data['availableFrom'] != null
          ? (data['availableFrom'] as Timestamp).toDate()
          : null,
      availableTo: data['availableTo'] != null
          ? (data['availableTo'] as Timestamp).toDate()
          : null,
      unavailableDates: (data['unavailableDates'] as List<dynamic>?)
              ?.map((d) => (d as Timestamp).toDate())
              .toList() ??
          [],
      minimumRentalHours: (data['minimumRentalHours'] as num?)?.toInt() ?? 1,
      maximumRentalDays: (data['maximumRentalDays'] as num?)?.toInt(),
      pickupInstructions: data['pickupInstructions'] as String?,
      rules: data['rules'] as String?,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalRentals: (data['totalRentals'] as num?)?.toInt() ?? 0,
      totalReviews: (data['totalReviews'] as num?)?.toInt() ?? 0,
      lastRentedAt: data['lastRentedAt'] != null
          ? (data['lastRentedAt'] as Timestamp).toDate()
          : null,
      isVerified: data['isVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'ownerId': ownerId,
        'title': title,
        'description': description,
        'bikeType': bikeType.name,
        'size': size.name,
        'condition': condition.name,
        'pricing': pricing.toFirestore(),
        'features': features.toFirestore(),
        'location': GeoPoint(location.latitude, location.longitude),
        'locationName': locationName,
        'photoUrls': photoUrls,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'brand': brand,
        'model': model,
        'year': year,
        'color': color,
        'availableFrom': availableFrom != null ? Timestamp.fromDate(availableFrom!) : null,
        'availableTo': availableTo != null ? Timestamp.fromDate(availableTo!) : null,
        'unavailableDates': unavailableDates.map((d) => Timestamp.fromDate(d)).toList(),
        'minimumRentalHours': minimumRentalHours,
        'maximumRentalDays': maximumRentalDays,
        'pickupInstructions': pickupInstructions,
        'rules': rules,
        'averageRating': averageRating,
        'totalRentals': totalRentals,
        'totalReviews': totalReviews,
        'lastRentedAt': lastRentedAt != null ? Timestamp.fromDate(lastRentedAt!) : null,
        'isVerified': isVerified,
      };

  BikeListing copyWith({
    String? title,
    String? description,
    BikeType? bikeType,
    BikeSize? size,
    BikeCondition? condition,
    BikePricing? pricing,
    BikeFeatures? features,
    LatLng? location,
    String? locationName,
    List<String>? photoUrls,
    ListingStatus? status,
    String? brand,
    String? model,
    int? year,
    String? color,
    DateTime? availableFrom,
    DateTime? availableTo,
    List<DateTime>? unavailableDates,
    int? minimumRentalHours,
    int? maximumRentalDays,
    String? pickupInstructions,
    String? rules,
    double? averageRating,
    int? totalRentals,
    int? totalReviews,
    DateTime? lastRentedAt,
    bool? isVerified,
  }) {
    return BikeListing(
      id: id,
      ownerId: ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      bikeType: bikeType ?? this.bikeType,
      size: size ?? this.size,
      condition: condition ?? this.condition,
      pricing: pricing ?? this.pricing,
      features: features ?? this.features,
      location: location ?? this.location,
      locationName: locationName ?? this.locationName,
      photoUrls: photoUrls ?? this.photoUrls,
      status: status ?? this.status,
      createdAt: createdAt,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      availableFrom: availableFrom ?? this.availableFrom,
      availableTo: availableTo ?? this.availableTo,
      unavailableDates: unavailableDates ?? this.unavailableDates,
      minimumRentalHours: minimumRentalHours ?? this.minimumRentalHours,
      maximumRentalDays: maximumRentalDays ?? this.maximumRentalDays,
      pickupInstructions: pickupInstructions ?? this.pickupInstructions,
      rules: rules ?? this.rules,
      averageRating: averageRating ?? this.averageRating,
      totalRentals: totalRentals ?? this.totalRentals,
      totalReviews: totalReviews ?? this.totalReviews,
      lastRentedAt: lastRentedAt ?? this.lastRentedAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
