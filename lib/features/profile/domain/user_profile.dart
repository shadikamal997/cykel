/// CYKEL — User Profile Domain Model
/// Extended user data including bike battery, home/work locations, plan, etc.

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Subscription plan tier.
enum CykelPlan { free, premium }

/// User profile type for segmented experiences.
enum ProfileType {
  standard,  // Default profile
  family,    // Family-friendly routes and events
  tourist,   // Sightseeing and tourist content
  student,   // Student-focused features
}

/// Age range preferences for event matching.
enum AgeRangePreference {
  all,       // All ages welcome
  young,     // 18-25
  adult,     // 26-35
  midlife,   // 36-45
  senior,    // 46+
}

class UserProfile {
  const UserProfile({
    this.homeLocation,
    this.workLocation,
    this.homeAddress,
    this.workAddress,
    this.batteryLevel, // 0-100, null if not set
    this.lastMaintenanceKm, // km reading at last service
    this.totalDistanceKm = 0, // total km ridden
    this.plan = CykelPlan.free,
    this.monthlyGoalKm = 100, // default 100km/month
    // Phase 1: Segmentation fields
    this.birthDate,
    this.isStudent = false,
    this.isStudentVerified = false,
    this.studentVerifiedUntil,
    this.profileType = ProfileType.standard,
    this.preferredLanguage,
    this.ageRangePreference = AgeRangePreference.all,
    // Phase 4: Bike equipment for family mode
    this.hasChildSeat = false,
    this.childSeatCapacity = 0,
    this.hasCargoBike = false,
    this.hasBikeTrailer = false,
  });

  final LatLng? homeLocation;
  final LatLng? workLocation;
  final String? homeAddress;
  final String? workAddress;
  final int? batteryLevel;
  final double? lastMaintenanceKm;
  final double totalDistanceKm;

  /// Current subscription plan.
  final CykelPlan plan;

  /// Monthly cycling goal in km (for challenge card).
  final int monthlyGoalKm;

  // ── Phase 1: User Segmentation Fields ──────────────────────────────────


  // ── Phase 1: Segmentation Getters ──────────────────────────────────────

  /// Calculate user's age from birth date.
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  /// Whether user has a valid birth date set.
  bool get hasBirthDate => birthDate != null;

  /// Whether student verification is currently valid.
  bool get hasValidStudentStatus {
    if (!isStudentVerified || studentVerifiedUntil == null) return false;
    return DateTime.now().isBefore(studentVerifiedUntil!);
  }

  /// Whether user is in family mode.
  bool get isFamilyMode => profileType == ProfileType.family;

  /// Whether user is in tourist mode.
  bool get isTouristMode => profileType == ProfileType.tourist;

  /// Whether user is in student mode.
  bool get isStudentMode => profileType == ProfileType.student;
  /// User's date of birth (for age calculation and filtering).
  final DateTime? birthDate;

  /// Whether user has identified as a student.
  final bool isStudent;

  /// Whether student status has been verified via email domain.
  final bool isStudentVerified;

  /// When student verification expires (annual re-verification).
  final DateTime? studentVerifiedUntil;

  /// Profile type for content personalization.
  final ProfileType profileType;

  /// Preferred language for events and content (ISO 639-1: 'en', 'da', etc.).
  final String? preferredLanguage;

  /// Preferred age range for event discovery.
  final AgeRangePreference ageRangePreference;

  // ── Phase 4: Bike Equipment ────────────────────────────────────────────

  /// Whether user has a child seat on their bike.
  final bool hasChildSeat;

  /// Number of children that can be seated (1-2 typically).
  final int childSeatCapacity;

  /// Whether user has a cargo bike.
  final bool hasCargoBike;

  /// Whether user has a bike trailer for children.
  final bool hasBikeTrailer;

  bool get hasHomeLocation => homeLocation != null;
  bool get hasWorkLocation => workLocation != null;
  bool get hasBatteryLevel => batteryLevel != null;
  bool get isPremium => plan == CykelPlan.premium;

  /// Whether user has any family-friendly bike equipment.
  bool get hasFamilyEquipment => hasChildSeat || hasCargoBike || hasBikeTrailer;

  // Maintenance reminder logic
  bool get needsMaintenance {
    if (lastMaintenanceKm == null) return false;
    return totalDistanceKm - lastMaintenanceKm! >= 1500; // 1500km service interval
  }

  UserProfile copyWith({
    LatLng? homeLocation,
    LatLng? workLocation,
    String? homeAddress,
    String? workAddress,
    int? batteryLevel,
    double? lastMaintenanceKm,
    double? totalDistanceKm,
    CykelPlan? plan,
    int? monthlyGoalKm,
    DateTime? birthDate,
    bool? isStudent,
    bool? isStudentVerified,
    DateTime? studentVerifiedUntil,
    ProfileType? profileType,
    String? preferredLanguage,
    AgeRangePreference? ageRangePreference,
    // Phase 4
    bool? hasChildSeat,
    int? childSeatCapacity,
    bool? hasCargoBike,
    bool? hasBikeTrailer,
  }) {
    return UserProfile(
      homeLocation: homeLocation ?? this.homeLocation,
      workLocation: workLocation ?? this.workLocation,
      homeAddress: homeAddress ?? this.homeAddress,
      workAddress: workAddress ?? this.workAddress,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      lastMaintenanceKm: lastMaintenanceKm ?? this.lastMaintenanceKm,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      plan: plan ?? this.plan,
      monthlyGoalKm: monthlyGoalKm ?? this.monthlyGoalKm,
      birthDate: birthDate ?? this.birthDate,
      isStudent: isStudent ?? this.isStudent,
      isStudentVerified: isStudentVerified ?? this.isStudentVerified,
      studentVerifiedUntil: studentVerifiedUntil ?? this.studentVerifiedUntil,
      profileType: profileType ?? this.profileType,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      ageRangePreference: ageRangePreference ?? this.ageRangePreference,
      hasChildSeat: hasChildSeat ?? this.hasChildSeat,
      childSeatCapacity: childSeatCapacity ?? this.childSeatCapacity,
      hasCargoBike: hasCargoBike ?? this.hasCargoBike,
      hasBikeTrailer: hasBikeTrailer ?? this.hasBikeTrailer,
    );
  }

  Map<String, dynamic> toJson() => {
        if (homeLocation != null) 'homeLat': homeLocation!.latitude,
        if (homeLocation != null) 'homeLng': homeLocation!.longitude,
        if (workLocation != null) 'workLat': workLocation!.latitude,
        if (workLocation != null) 'workLng': workLocation!.longitude,
        if (homeAddress != null) 'homeAddress': homeAddress,
        if (workAddress != null) 'workAddress': workAddress,
        if (batteryLevel != null) 'batteryLevel': batteryLevel,
        if (lastMaintenanceKm != null) 'lastMaintenanceKm': lastMaintenanceKm,
        'totalDistanceKm': totalDistanceKm,
        'plan': plan.name,
        'monthlyGoalKm': monthlyGoalKm,
        // Phase 1 fields
        if (birthDate != null) 'birthDate': birthDate!.toIso8601String(),
        'isStudent': isStudent,
        'isStudentVerified': isStudentVerified,
        if (studentVerifiedUntil != null)
          'studentVerifiedUntil': studentVerifiedUntil!.toIso8601String(),
        'profileType': profileType.name,
        if (preferredLanguage != null) 'preferredLanguage': preferredLanguage,
        'ageRangePreference': ageRangePreference.name,
        // Phase 4 fields
        'hasChildSeat': hasChildSeat,
        'childSeatCapacity': childSeatCapacity,
        'hasCargoBike': hasCargoBike,
        'hasBikeTrailer': hasBikeTrailer,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        homeLocation: json['homeLat'] != null && json['homeLng'] != null
            ? LatLng((json['homeLat'] as num).toDouble(), (json['homeLng'] as num).toDouble())
            : null,
        workLocation: json['workLat'] != null && json['workLng'] != null
            ? LatLng((json['workLat'] as num).toDouble(), (json['workLng'] as num).toDouble())
            : null,
        homeAddress: json['homeAddress'] as String?,
        // Phase 1 fields
        birthDate: json['birthDate'] != null
            ? DateTime.parse(json['birthDate'] as String)
            : null,
        isStudent: (json['isStudent'] as bool?) ?? false,
        isStudentVerified: (json['isStudentVerified'] as bool?) ?? false,
        studentVerifiedUntil: json['studentVerifiedUntil'] != null
            ? DateTime.parse(json['studentVerifiedUntil'] as String)
            : null,
        profileType: ProfileType.values.firstWhere(
          (p) => p.name == (json['profileType'] as String?),
          orElse: () => ProfileType.standard,
        ),
        preferredLanguage: json['preferredLanguage'] as String?,
        ageRangePreference: AgeRangePreference.values.firstWhere(
          (a) => a.name == (json['ageRangePreference'] as String?),
          orElse: () => AgeRangePreference.all,
        ),
        // Phase 4 fields
        hasChildSeat: (json['hasChildSeat'] as bool?) ?? false,
        childSeatCapacity: (json['childSeatCapacity'] as int?) ?? 0,
        hasCargoBike: (json['hasCargoBike'] as bool?) ?? false,
        hasBikeTrailer: (json['hasBikeTrailer'] as bool?) ?? false,
        workAddress: json['workAddress'] as String?,
        batteryLevel: json['batteryLevel'] as int?,
        lastMaintenanceKm: json['lastMaintenanceKm'] as double?,
        totalDistanceKm: (json['totalDistanceKm'] as num?)?.toDouble() ?? 0,
        plan: CykelPlan.values.firstWhere(
          (p) => p.name == (json['plan'] as String?),
          orElse: () => CykelPlan.free,
        ),
        monthlyGoalKm: (json['monthlyGoalKm'] as int?) ?? 100,
      );
}