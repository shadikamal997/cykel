/// CYKEL — Provider Domain Model
/// Unified model for all three provider types:
/// Repair/Garage Shops, Bike Retail Shops, E-Bike Charging Locations.
///
/// Common fields are always present; type-specific fields are nullable
/// and only populated for the relevant provider type.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'provider_enums.dart';

// ─── Opening Hours ────────────────────────────────────────────────────────────

class DayHours {
  const DayHours({
    required this.open,
    required this.close,
    this.closed = false,
  });

  /// e.g. "08:00"
  final String open;

  /// e.g. "18:00"
  final String close;

  /// If true, the business is closed on this day.
  final bool closed;

  factory DayHours.fromMap(Map<String, dynamic> m) => DayHours(
        open: m['open'] as String? ?? '09:00',
        close: m['close'] as String? ?? '17:00',
        closed: m['closed'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'open': open,
        'close': close,
        'closed': closed,
      };

  DayHours copyWith({String? open, String? close, bool? closed}) => DayHours(
        open: open ?? this.open,
        close: close ?? this.close,
        closed: closed ?? this.closed,
      );
}

// ─── Provider Model ───────────────────────────────────────────────────────────

class CykelProvider {
  const CykelProvider({
    required this.id,
    required this.userId,
    required this.providerType,
    required this.businessName,
    this.legalBusinessName,
    this.cvrNumber,
    required this.contactName,
    required this.phone,
    required this.email,
    this.website,
    required this.streetAddress,
    required this.city,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
    this.shopDescription,
    this.logoUrl,
    this.coverPhotoUrl,
    this.galleryUrls = const [],
    this.openingHours = const {},
    this.rating = 0.0,
    this.reviewCount = 0,
    this.verificationStatus = VerificationStatus.pending,
    this.isActive = true,
    this.temporarilyClosed = false,
    this.isFeatured = false,
    this.holidaySchedule,
    this.specialNotice,
    this.documentUrls = const [],
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    // ── Repair shop fields ──
    this.servicesOffered = const [],
    this.mobileRepair = false,
    this.acceptsWalkIns = true,
    this.appointmentRequired = false,
    this.estimatedWaitMinutes,
    this.priceRange,
    this.supportedBikeTypes = const [],
    this.serviceRadiusKm,
    // ── Bike shop fields ──
    this.productsAvailable = const [],
    this.offersTestRides = false,
    this.financingAvailable = false,
    this.acceptsTradeIn = false,
    this.onlineStoreUrl,
    this.priceTier,
    this.hasRepairService = false,
    // ── Charging location fields ──
    this.hostType,
    this.chargingType,
    this.numberOfPorts,
    this.powerAvailability,
    this.maxChargingDurationMinutes,
    this.indoorCharging = false,
    this.weatherProtected = false,
    this.amenities = const [],
    this.accessRestriction,
  });

  // ── Common fields ─────────────────────────────────────────────────────────
  final String id;
  final String userId;
  final ProviderType providerType;
  final String businessName;
  final String? legalBusinessName;
  final String? cvrNumber;
  final String contactName;
  final String phone;
  final String email;
  final String? website;
  final String streetAddress;
  final String city;
  final String postalCode;
  final double latitude;
  final double longitude;
  final String? shopDescription;
  final String? logoUrl;
  final String? coverPhotoUrl;
  final List<String> galleryUrls;
  final Map<String, DayHours> openingHours; // keys: mon, tue, wed, thu, fri, sat, sun
  final double rating;
  final int reviewCount;
  final VerificationStatus verificationStatus;
  final bool isActive;
  final bool temporarilyClosed;
  final bool isFeatured; // CYKEL-curated providers shown in "Find providers on the map"
  final String? holidaySchedule;
  final String? specialNotice;
  final List<String> documentUrls;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Repair shop fields ────────────────────────────────────────────────────
  final List<RepairService> servicesOffered;
  final bool mobileRepair;
  final bool acceptsWalkIns;
  final bool appointmentRequired;
  final int? estimatedWaitMinutes;
  final PriceRange? priceRange;
  final List<BikeType> supportedBikeTypes;
  final double? serviceRadiusKm;

  // ── Bike shop fields ──────────────────────────────────────────────────────
  final List<ProductCategory> productsAvailable;
  final bool offersTestRides;
  final bool financingAvailable;
  final bool acceptsTradeIn;
  final String? onlineStoreUrl;
  final PriceTier? priceTier;
  final bool hasRepairService;

  // ── Charging location fields ──────────────────────────────────────────────
  final HostType? hostType;
  final ChargingType? chargingType;
  final int? numberOfPorts;
  final PowerAvailability? powerAvailability;
  final int? maxChargingDurationMinutes;
  final bool indoorCharging;
  final bool weatherProtected;
  final List<Amenity> amenities;
  final AccessRestriction? accessRestriction;

  // ── Computed helpers ──────────────────────────────────────────────────────

  bool get isVerified => verificationStatus == VerificationStatus.approved;
  bool get isPending => verificationStatus == VerificationStatus.pending;
  bool get isRejected => verificationStatus == VerificationStatus.rejected;
  bool get isRepairShop => providerType == ProviderType.repairShop;
  bool get isBikeShop => providerType == ProviderType.bikeShop;
  bool get isChargingLocation => providerType == ProviderType.chargingLocation;
  bool get isServicePoint => providerType == ProviderType.servicePoint;
  bool get isRental => providerType == ProviderType.rental;

  /// Whether this provider is currently open for business (not closed/paused).
  bool get isOpen => isActive && !temporarilyClosed && isVerified;

  // ── Firestore serialisation ───────────────────────────────────────────────

  factory CykelProvider.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return CykelProvider(
      id: doc.id,
      userId: m['userId'] as String? ?? '',
      providerType:
          ProviderType.fromKey(m['providerType'] as String? ?? 'repair_shop'),
      businessName: m['businessName'] as String? ?? '',
      legalBusinessName: m['legalBusinessName'] as String?,
      cvrNumber: m['cvrNumber'] as String?,
      contactName: m['contactName'] as String? ?? '',
      phone: m['phone'] as String? ?? '',
      email: m['email'] as String? ?? '',
      website: m['website'] as String?,
      streetAddress: m['streetAddress'] as String? ?? '',
      city: m['city'] as String? ?? '',
      postalCode: m['postalCode'] as String? ?? '',
      latitude: (m['latitude'] as num? ?? 0).toDouble(),
      longitude: (m['longitude'] as num? ?? 0).toDouble(),
      shopDescription: m['shopDescription'] as String?,
      logoUrl: m['logoUrl'] as String?,
      coverPhotoUrl: m['coverPhotoUrl'] as String?,
      galleryUrls: List<String>.from(m['galleryUrls'] as List? ?? []),
      openingHours: _parseOpeningHours(m['openingHours']),
      rating: (m['rating'] as num? ?? 0).toDouble(),
      reviewCount: m['reviewCount'] as int? ?? 0,
      verificationStatus: VerificationStatus.fromKey(
          m['verificationStatus'] as String? ?? 'pending'),
      isActive: m['isActive'] as bool? ?? true,
      temporarilyClosed: m['temporarilyClosed'] as bool? ?? false,
      isFeatured: m['isFeatured'] as bool? ?? false,
      holidaySchedule: m['holidaySchedule'] as String?,
      specialNotice: m['specialNotice'] as String?,
      documentUrls: List<String>.from(m['documentUrls'] as List? ?? []),
      rejectionReason: m['rejectionReason'] as String?,
      createdAt: m['createdAt'] is Timestamp
          ? (m['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: m['updatedAt'] is Timestamp
          ? (m['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      // Repair fields
      servicesOffered: (m['servicesOffered'] as List?)
              ?.map((e) => RepairService.fromKey(e as String))
              .toList() ??
          [],
      mobileRepair: m['mobileRepair'] as bool? ?? false,
      acceptsWalkIns: m['acceptsWalkIns'] as bool? ?? true,
      appointmentRequired: m['appointmentRequired'] as bool? ?? false,
      estimatedWaitMinutes: m['estimatedWaitMinutes'] as int?,
      priceRange: m['priceRange'] != null
          ? PriceRange.fromKey(m['priceRange'] as String)
          : null,
      supportedBikeTypes: (m['supportedBikeTypes'] as List?)
              ?.map((e) => BikeType.fromKey(e as String))
              .toList() ??
          [],
      serviceRadiusKm: (m['serviceRadiusKm'] as num?)?.toDouble(),
      // Shop fields
      productsAvailable: (m['productsAvailable'] as List?)
              ?.map((e) => ProductCategory.fromKey(e as String))
              .toList() ??
          [],
      offersTestRides: m['offersTestRides'] as bool? ?? false,
      financingAvailable: m['financingAvailable'] as bool? ?? false,
      acceptsTradeIn: m['acceptsTradeIn'] as bool? ?? false,
      onlineStoreUrl: m['onlineStoreUrl'] as String?,
      priceTier: m['priceTier'] != null
          ? PriceTier.fromKey(m['priceTier'] as String)
          : null,
      hasRepairService: m['hasRepairService'] as bool? ?? false,
      // Charging fields
      hostType: m['hostType'] != null
          ? HostType.fromKey(m['hostType'] as String)
          : null,
      chargingType: m['chargingType'] != null
          ? ChargingType.fromKey(m['chargingType'] as String)
          : null,
      numberOfPorts: m['numberOfPorts'] as int?,
      powerAvailability: m['powerAvailability'] != null
          ? PowerAvailability.fromKey(m['powerAvailability'] as String)
          : null,
      maxChargingDurationMinutes: m['maxChargingDurationMinutes'] as int?,
      indoorCharging: m['indoorCharging'] as bool? ?? false,
      weatherProtected: m['weatherProtected'] as bool? ?? false,
      amenities: (m['amenities'] as List?)
              ?.map((e) => Amenity.fromKey(e as String))
              .toList() ??
          [],
      accessRestriction: m['accessRestriction'] != null
          ? AccessRestriction.fromKey(m['accessRestriction'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'userId': userId,
      'providerType': providerType.key,
      'businessName': businessName,
      if (legalBusinessName != null) 'legalBusinessName': legalBusinessName,
      if (cvrNumber != null) 'cvrNumber': cvrNumber,
      'contactName': contactName,
      'phone': phone,
      'email': email,
      if (website != null) 'website': website,
      'streetAddress': streetAddress,
      'city': city,
      'postalCode': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      if (shopDescription != null) 'shopDescription': shopDescription,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (coverPhotoUrl != null) 'coverPhotoUrl': coverPhotoUrl,
      'galleryUrls': galleryUrls,
      'openingHours':
          openingHours.map((k, v) => MapEntry(k, v.toMap())),
      'rating': rating,
      'reviewCount': reviewCount,
      'verificationStatus': verificationStatus.key,
      'isActive': isActive,
      'temporarilyClosed': temporarilyClosed,
      'isFeatured': isFeatured,
      if (holidaySchedule != null) 'holidaySchedule': holidaySchedule,
      if (specialNotice != null) 'specialNotice': specialNotice,
      'documentUrls': documentUrls,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };

    // Type-specific fields
    switch (providerType) {
      case ProviderType.repairShop:
      case ProviderType.servicePoint:
        map['servicesOffered'] = servicesOffered.map((e) => e.key).toList();
        map['mobileRepair'] = mobileRepair;
        map['acceptsWalkIns'] = acceptsWalkIns;
        map['appointmentRequired'] = appointmentRequired;
        if (estimatedWaitMinutes != null) {
          map['estimatedWaitMinutes'] = estimatedWaitMinutes;
        }
        if (priceRange != null) map['priceRange'] = priceRange!.key;
        map['supportedBikeTypes'] =
            supportedBikeTypes.map((e) => e.key).toList();
        if (serviceRadiusKm != null) map['serviceRadiusKm'] = serviceRadiusKm;
      case ProviderType.bikeShop:
      case ProviderType.rental:
        map['productsAvailable'] =
            productsAvailable.map((e) => e.key).toList();
        map['offersTestRides'] = offersTestRides;
        map['financingAvailable'] = financingAvailable;
        map['acceptsTradeIn'] = acceptsTradeIn;
        if (onlineStoreUrl != null) map['onlineStoreUrl'] = onlineStoreUrl;
        if (priceTier != null) map['priceTier'] = priceTier!.key;
        map['hasRepairService'] = hasRepairService;
      case ProviderType.chargingLocation:
        if (hostType != null) map['hostType'] = hostType!.key;
        if (chargingType != null) map['chargingType'] = chargingType!.key;
        if (numberOfPorts != null) map['numberOfPorts'] = numberOfPorts;
        if (powerAvailability != null) {
          map['powerAvailability'] = powerAvailability!.key;
        }
        if (maxChargingDurationMinutes != null) {
          map['maxChargingDurationMinutes'] = maxChargingDurationMinutes;
        }
        map['indoorCharging'] = indoorCharging;
        map['weatherProtected'] = weatherProtected;
        map['amenities'] = amenities.map((e) => e.key).toList();
        if (accessRestriction != null) {
          map['accessRestriction'] = accessRestriction!.key;
        }
    }

    return map;
  }

  // ── copyWith ──────────────────────────────────────────────────────────────

  CykelProvider copyWith({
    String? id,
    String? userId,
    ProviderType? providerType,
    String? businessName,
    String? legalBusinessName,
    String? cvrNumber,
    String? contactName,
    String? phone,
    String? email,
    String? website,
    String? streetAddress,
    String? city,
    String? postalCode,
    double? latitude,
    double? longitude,
    String? shopDescription,
    String? logoUrl,
    String? coverPhotoUrl,
    List<String>? galleryUrls,
    Map<String, DayHours>? openingHours,
    double? rating,
    int? reviewCount,
    VerificationStatus? verificationStatus,
    bool? isActive,
    bool? temporarilyClosed,
    bool? isFeatured,
    String? holidaySchedule,
    String? specialNotice,
    List<String>? documentUrls,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<RepairService>? servicesOffered,
    bool? mobileRepair,
    bool? acceptsWalkIns,
    bool? appointmentRequired,
    int? estimatedWaitMinutes,
    PriceRange? priceRange,
    List<BikeType>? supportedBikeTypes,
    double? serviceRadiusKm,
    List<ProductCategory>? productsAvailable,
    bool? offersTestRides,
    bool? financingAvailable,
    bool? acceptsTradeIn,
    String? onlineStoreUrl,
    PriceTier? priceTier,
    bool? hasRepairService,
    HostType? hostType,
    ChargingType? chargingType,
    int? numberOfPorts,
    PowerAvailability? powerAvailability,
    int? maxChargingDurationMinutes,
    bool? indoorCharging,
    bool? weatherProtected,
    List<Amenity>? amenities,
    AccessRestriction? accessRestriction,
  }) =>
      CykelProvider(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        providerType: providerType ?? this.providerType,
        businessName: businessName ?? this.businessName,
        legalBusinessName: legalBusinessName ?? this.legalBusinessName,
        cvrNumber: cvrNumber ?? this.cvrNumber,
        contactName: contactName ?? this.contactName,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        website: website ?? this.website,
        streetAddress: streetAddress ?? this.streetAddress,
        city: city ?? this.city,
        postalCode: postalCode ?? this.postalCode,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        shopDescription: shopDescription ?? this.shopDescription,
        logoUrl: logoUrl ?? this.logoUrl,
        coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
        galleryUrls: galleryUrls ?? this.galleryUrls,
        openingHours: openingHours ?? this.openingHours,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        verificationStatus: verificationStatus ?? this.verificationStatus,
        isActive: isActive ?? this.isActive,
        temporarilyClosed: temporarilyClosed ?? this.temporarilyClosed,
        isFeatured: isFeatured ?? this.isFeatured,
        holidaySchedule: holidaySchedule ?? this.holidaySchedule,
        specialNotice: specialNotice ?? this.specialNotice,
        documentUrls: documentUrls ?? this.documentUrls,
        rejectionReason: rejectionReason ?? this.rejectionReason,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        servicesOffered: servicesOffered ?? this.servicesOffered,
        mobileRepair: mobileRepair ?? this.mobileRepair,
        acceptsWalkIns: acceptsWalkIns ?? this.acceptsWalkIns,
        appointmentRequired: appointmentRequired ?? this.appointmentRequired,
        estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
        priceRange: priceRange ?? this.priceRange,
        supportedBikeTypes: supportedBikeTypes ?? this.supportedBikeTypes,
        serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
        productsAvailable: productsAvailable ?? this.productsAvailable,
        offersTestRides: offersTestRides ?? this.offersTestRides,
        financingAvailable: financingAvailable ?? this.financingAvailable,
        acceptsTradeIn: acceptsTradeIn ?? this.acceptsTradeIn,
        onlineStoreUrl: onlineStoreUrl ?? this.onlineStoreUrl,
        priceTier: priceTier ?? this.priceTier,
        hasRepairService: hasRepairService ?? this.hasRepairService,
        hostType: hostType ?? this.hostType,
        chargingType: chargingType ?? this.chargingType,
        numberOfPorts: numberOfPorts ?? this.numberOfPorts,
        powerAvailability: powerAvailability ?? this.powerAvailability,
        maxChargingDurationMinutes:
            maxChargingDurationMinutes ?? this.maxChargingDurationMinutes,
        indoorCharging: indoorCharging ?? this.indoorCharging,
        weatherProtected: weatherProtected ?? this.weatherProtected,
        amenities: amenities ?? this.amenities,
        accessRestriction: accessRestriction ?? this.accessRestriction,
      );

  // ── Private helpers ───────────────────────────────────────────────────────

  static Map<String, DayHours> _parseOpeningHours(dynamic raw) {
    if (raw is! Map) return {};
    return (raw as Map<String, dynamic>).map(
      (k, v) => MapEntry(
        k,
        DayHours.fromMap(v as Map<String, dynamic>),
      ),
    );
  }
}
