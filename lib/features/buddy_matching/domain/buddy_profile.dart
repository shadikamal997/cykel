/// CYKEL — Buddy Matching Domain Models
/// Connect cyclists with compatible riding partners

import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Riding Interests ────────────────────────────────────────────────────────

enum RidingInterest {
  commuting,        // Daily commute rides
  leisure,          // Casual, relaxed rides
  fitness,          // Exercise and training
  touring,          // Long-distance tours
  racing,           // Competitive/fast rides
  mountain,         // Mountain biking, trails
  social,           // Group social rides
  sightseeing,      // Tourist/exploration rides
  family,           // Family-friendly rides
  photography,      // Photo stops and scenic routes
  foodie,           // Café and food stops
  nightRiding;      // Evening/night rides

  String get displayName {
    switch (this) {
      case RidingInterest.commuting:
        return 'Commuting';
      case RidingInterest.leisure:
        return 'Leisure';
      case RidingInterest.fitness:
        return 'Fitness';
      case RidingInterest.touring:
        return 'Touring';
      case RidingInterest.racing:
        return 'Racing';
      case RidingInterest.mountain:
        return 'Mountain Biking';
      case RidingInterest.social:
        return 'Social Rides';
      case RidingInterest.sightseeing:
        return 'Sightseeing';
      case RidingInterest.family:
        return 'Family Rides';
      case RidingInterest.photography:
        return 'Photography';
      case RidingInterest.foodie:
        return 'Food & Cafés';
      case RidingInterest.nightRiding:
        return 'Night Riding';
    }
  }

  String get icon {
    switch (this) {
      case RidingInterest.commuting:
        return '💼';
      case RidingInterest.leisure:
        return '🚴';
      case RidingInterest.fitness:
        return '💪';
      case RidingInterest.touring:
        return '🗺️';
      case RidingInterest.racing:
        return '🏁';
      case RidingInterest.mountain:
        return '⛰️';
      case RidingInterest.social:
        return '👥';
      case RidingInterest.sightseeing:
        return '📸';
      case RidingInterest.family:
        return '👨‍👩‍👧‍👦';
      case RidingInterest.photography:
        return '📷';
      case RidingInterest.foodie:
        return '☕';
      case RidingInterest.nightRiding:
        return '🌙';
    }
  }
}

// ─── Riding Level ────────────────────────────────────────────────────────────

enum RidingLevel {
  beginner,      // New to cycling, <10km comfortable
  casual,        // Regular rider, 10-20km comfortable
  intermediate,  // Experienced, 20-40km comfortable
  advanced,      // Very experienced, 40-80km comfortable
  expert;        // Competitive level, 80km+ comfortable

  String get displayName {
    switch (this) {
      case RidingLevel.beginner:
        return 'Beginner';
      case RidingLevel.casual:
        return 'Casual';
      case RidingLevel.intermediate:
        return 'Intermediate';
      case RidingLevel.advanced:
        return 'Advanced';
      case RidingLevel.expert:
        return 'Expert';
    }
  }

  String get description {
    switch (this) {
      case RidingLevel.beginner:
        return 'New to cycling, <10km';
      case RidingLevel.casual:
        return 'Regular rider, 10-20km';
      case RidingLevel.intermediate:
        return 'Experienced, 20-40km';
      case RidingLevel.advanced:
        return 'Very experienced, 40-80km';
      case RidingLevel.expert:
        return 'Competitive, 80km+';
    }
  }

  String get icon {
    switch (this) {
      case RidingLevel.beginner:
        return '🌱';
      case RidingLevel.casual:
        return '🚲';
      case RidingLevel.intermediate:
        return '🚴‍♂️';
      case RidingLevel.advanced:
        return '🏃';
      case RidingLevel.expert:
        return '🏆';
    }
  }
}

// ─── Availability ────────────────────────────────────────────────────────────

enum RideAvailability {
  weekdayMornings,   // Mon-Fri, 6am-12pm
  weekdayAfternoons, // Mon-Fri, 12pm-6pm
  weekdayEvenings,   // Mon-Fri, 6pm-10pm
  weekendMornings,   // Sat-Sun, 6am-12pm
  weekendAfternoons, // Sat-Sun, 12pm-6pm
  weekendEvenings,   // Sat-Sun, 6pm-10pm
  flexible;          // Anytime

  String get displayName {
    switch (this) {
      case RideAvailability.weekdayMornings:
        return 'Weekday Mornings';
      case RideAvailability.weekdayAfternoons:
        return 'Weekday Afternoons';
      case RideAvailability.weekdayEvenings:
        return 'Weekday Evenings';
      case RideAvailability.weekendMornings:
        return 'Weekend Mornings';
      case RideAvailability.weekendAfternoons:
        return 'Weekend Afternoons';
      case RideAvailability.weekendEvenings:
        return 'Weekend Evenings';
      case RideAvailability.flexible:
        return 'Flexible';
    }
  }

  String get icon {
    switch (this) {
      case RideAvailability.weekdayMornings:
        return '🌅';
      case RideAvailability.weekdayAfternoons:
        return '☀️';
      case RideAvailability.weekdayEvenings:
        return '🌆';
      case RideAvailability.weekendMornings:
        return '🏖️';
      case RideAvailability.weekendAfternoons:
        return '🎉';
      case RideAvailability.weekendEvenings:
        return '🌃';
      case RideAvailability.flexible:
        return '⏰';
    }
  }
}

// ─── Buddy Preferences ───────────────────────────────────────────────────────

class BuddyPreferences {
  const BuddyPreferences({
    this.preferredLevels = const [],
    this.ageRangeMin,
    this.ageRangeMax,
    this.preferredGenders = const [],
    this.maxDistance = 10.0, // km from user's location
    this.languagePreferences = const [],
    this.verifiedOnly = false,
    this.samePaceImportant = true,
  });

  final List<RidingLevel> preferredLevels;
  final int? ageRangeMin;
  final int? ageRangeMax;
  final List<String> preferredGenders; // 'male', 'female', 'other', 'any'
  final double maxDistance;
  final List<String> languagePreferences; // ISO 639-1 codes
  final bool verifiedOnly; // Only match with verified users
  final bool samePaceImportant; // Match similar riding speeds

  factory BuddyPreferences.fromFirestore(Map<String, dynamic> data) {
    return BuddyPreferences(
      preferredLevels: (data['preferredLevels'] as List<dynamic>?)
              ?.map((e) => RidingLevel.values.firstWhere(
                    (level) => level.name == e,
                    orElse: () => RidingLevel.casual,
                  ))
              .toList() ??
          [],
      ageRangeMin: data['ageRangeMin'] as int?,
      ageRangeMax: data['ageRangeMax'] as int?,
      preferredGenders: (data['preferredGenders'] as List<dynamic>?)?.cast<String>() ?? [],
      maxDistance: (data['maxDistance'] as num?)?.toDouble() ?? 10.0,
      languagePreferences: (data['languagePreferences'] as List<dynamic>?)?.cast<String>() ?? [],
      verifiedOnly: data['verifiedOnly'] as bool? ?? false,
      samePaceImportant: data['samePaceImportant'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'preferredLevels': preferredLevels.map((l) => l.name).toList(),
        'ageRangeMin': ageRangeMin,
        'ageRangeMax': ageRangeMax,
        'preferredGenders': preferredGenders,
        'maxDistance': maxDistance,
        'languagePreferences': languagePreferences,
        'verifiedOnly': verifiedOnly,
        'samePaceImportant': samePaceImportant,
      };

  BuddyPreferences copyWith({
    List<RidingLevel>? preferredLevels,
    int? ageRangeMin,
    int? ageRangeMax,
    List<String>? preferredGenders,
    double? maxDistance,
    List<String>? languagePreferences,
    bool? verifiedOnly,
    bool? samePaceImportant,
  }) {
    return BuddyPreferences(
      preferredLevels: preferredLevels ?? this.preferredLevels,
      ageRangeMin: ageRangeMin ?? this.ageRangeMin,
      ageRangeMax: ageRangeMax ?? this.ageRangeMax,
      preferredGenders: preferredGenders ?? this.preferredGenders,
      maxDistance: maxDistance ?? this.maxDistance,
      languagePreferences: languagePreferences ?? this.languagePreferences,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      samePaceImportant: samePaceImportant ?? this.samePaceImportant,
    );
  }
}

// ─── Buddy Profile ───────────────────────────────────────────────────────────

class BuddyProfile {
  const BuddyProfile({
    required this.userId,
    required this.displayName,
    required this.ridingLevel,
    required this.interests,
    required this.availability,
    required this.createdAt,
    this.bio,
    this.photoUrl,
    this.photoThumbnailUrl,
    this.hometown,
    this.spokenLanguages = const [],
    this.averagePaceKmh,
    this.totalRides = 0,
    this.totalDistanceKm = 0.0,
    this.preferences = const BuddyPreferences(),
    this.verifiedRider = false,
    this.lastActiveAt,
    this.isActive = true,
  });

  final String userId;
  final String displayName;
  final String? bio;
  final String? photoUrl;
  final String? photoThumbnailUrl;
  final String? hometown;
  final RidingLevel ridingLevel;
  final List<RidingInterest> interests;
  final List<RideAvailability> availability;
  final List<String> spokenLanguages;
  final double? averagePaceKmh;
  final int totalRides;
  final double totalDistanceKm;
  final BuddyPreferences preferences;
  final bool verifiedRider;
  final DateTime createdAt;
  final DateTime? lastActiveAt;
  final bool isActive;

  /// Calculate thumbnail URL from photo URL based on Cloud Function pattern
  static String? getThumbnailUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    
    final uri = Uri.parse(imageUrl);
    final encodedPath = uri.pathSegments.lastWhere(
      (segment) => segment.contains('%2F'),
      orElse: () => '',
    );
    
    if (encodedPath.isEmpty) return imageUrl;
    
    final decodedPath = Uri.decodeComponent(encodedPath);
    final thumbnailPath = 'thumbnails/$decodedPath';
    final encodedThumbnailPath = Uri.encodeComponent(thumbnailPath);
    
    return imageUrl.replaceFirst(encodedPath, encodedThumbnailPath);
  }

  /// Get calculated thumbnail for buddy photo
  String? get photoThumbnail => getThumbnailUrl(photoUrl);

  /// Calculate match compatibility score (0-100)
  int calculateCompatibility(BuddyProfile other) {
    int score = 0;

    // Riding level compatibility (30 points max)
    final levelDiff = (ridingLevel.index - other.ridingLevel.index).abs();
    if (levelDiff == 0) {
      score += 30;
    } else if (levelDiff == 1) {
      score += 20;
    } else if (levelDiff == 2) {
      score += 10;
    }

    // Shared interests (40 points max)
    final sharedInterests = interests.where((i) => other.interests.contains(i)).length;
    score += (sharedInterests * 5).clamp(0, 40);

    // Availability overlap (20 points max)
    final sharedAvailability = availability.where((a) => other.availability.contains(a)).length;
    score += (sharedAvailability * 4).clamp(0, 20);

    // Language compatibility (10 points max)
    final sharedLanguages = spokenLanguages.where((l) => other.spokenLanguages.contains(l)).length;
    if (sharedLanguages > 0) {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  /// Check if this profile matches the other's preferences
  bool matchesPreferences(BuddyProfile other) {
    final prefs = other.preferences;

    // Check riding level preference
    if (prefs.preferredLevels.isNotEmpty && !prefs.preferredLevels.contains(ridingLevel)) {
      return false;
    }

    // Check verified rider requirement
    if (prefs.verifiedOnly && !verifiedRider) {
      return false;
    }

    // Check language preferences
    if (prefs.languagePreferences.isNotEmpty) {
      final hasCommonLanguage = spokenLanguages.any((lang) => prefs.languagePreferences.contains(lang));
      if (!hasCommonLanguage) {
        return false;
      }
    }

    // Check pace compatibility
    if (prefs.samePaceImportant && averagePaceKmh != null && other.averagePaceKmh != null) {
      final paceDiff = (averagePaceKmh! - other.averagePaceKmh!).abs();
      if (paceDiff > 5.0) { // More than 5 km/h difference
        return false;
      }
    }

    return true;
  }

  factory BuddyProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return BuddyProfile(
      userId: doc.id,
      displayName: data['displayName'] as String,
      bio: data['bio'] as String?,
      photoUrl: data['photoUrl'] as String?,      photoThumbnailUrl: data['photoThumbnailUrl'] as String?,      hometown: data['hometown'] as String?,
      ridingLevel: RidingLevel.values.firstWhere(
        (level) => level.name == data['ridingLevel'],
        orElse: () => RidingLevel.casual,
      ),
      interests: (data['interests'] as List<dynamic>?)
              ?.map((e) => RidingInterest.values.firstWhere(
                    (interest) => interest.name == e,
                    orElse: () => RidingInterest.leisure,
                  ))
              .toList() ??
          [],
      availability: (data['availability'] as List<dynamic>?)
              ?.map((e) => RideAvailability.values.firstWhere(
                    (avail) => avail.name == e,
                    orElse: () => RideAvailability.flexible,
                  ))
              .toList() ??
          [],
      spokenLanguages: (data['spokenLanguages'] as List<dynamic>?)?.cast<String>() ?? [],
      averagePaceKmh: (data['averagePaceKmh'] as num?)?.toDouble(),
      totalRides: (data['totalRides'] as num?)?.toInt() ?? 0,
      totalDistanceKm: (data['totalDistanceKm'] as num?)?.toDouble() ?? 0.0,
      preferences: data['preferences'] != null
          ? BuddyPreferences.fromFirestore(data['preferences'] as Map<String, dynamic>)
          : const BuddyPreferences(),
      verifiedRider: data['verifiedRider'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActiveAt: data['lastActiveAt'] != null ? (data['lastActiveAt'] as Timestamp).toDate() : null,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'displayName': displayName,
        'bio': bio,
        'photoUrl': photoUrl,
        'photoThumbnailUrl': photoThumbnailUrl,
        'hometown': hometown,
        'ridingLevel': ridingLevel.name,
        'interests': interests.map((i) => i.name).toList(),
        'availability': availability.map((a) => a.name).toList(),
        'spokenLanguages': spokenLanguages,
        'averagePaceKmh': averagePaceKmh,
        'totalRides': totalRides,
        'totalDistanceKm': totalDistanceKm,
        'preferences': preferences.toFirestore(),
        'verifiedRider': verifiedRider,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastActiveAt': lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
        'isActive': isActive,
      };

  BuddyProfile copyWith({
    String? displayName,
    String? bio,
    String? photoUrl,
    String? photoThumbnailUrl,
    String? hometown,
    RidingLevel? ridingLevel,
    List<RidingInterest>? interests,
    List<RideAvailability>? availability,
    List<String>? spokenLanguages,
    double? averagePaceKmh,
    int? totalRides,
    double? totalDistanceKm,
    BuddyPreferences? preferences,
    bool? verifiedRider,
    DateTime? lastActiveAt,
    bool? isActive,
  }) {
    return BuddyProfile(
      userId: userId,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      photoThumbnailUrl: photoThumbnailUrl ?? this.photoThumbnailUrl,
      hometown: hometown ?? this.hometown,
      ridingLevel: ridingLevel ?? this.ridingLevel,
      interests: interests ?? this.interests,
      availability: availability ?? this.availability,
      spokenLanguages: spokenLanguages ?? this.spokenLanguages,
      averagePaceKmh: averagePaceKmh ?? this.averagePaceKmh,
      totalRides: totalRides ?? this.totalRides,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      preferences: preferences ?? this.preferences,
      verifiedRider: verifiedRider ?? this.verifiedRider,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

// ─── Buddy Match Status ──────────────────────────────────────────────────────

enum BuddyMatchStatus {
  pending,    // Request sent, awaiting response
  accepted,   // Both users accepted, active match
  declined,   // Request declined
  blocked;    // User blocked

  String get displayName {
    switch (this) {
      case BuddyMatchStatus.pending:
        return 'Pending';
      case BuddyMatchStatus.accepted:
        return 'Matched';
      case BuddyMatchStatus.declined:
        return 'Declined';
      case BuddyMatchStatus.blocked:
        return 'Blocked';
    }
  }
}

// ─── Buddy Match ─────────────────────────────────────────────────────────────

class BuddyMatch {
  const BuddyMatch({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.status,
    required this.createdAt,
    required this.compatibilityScore,
    this.acceptedAt,
    this.lastMessageAt,
    this.totalRidesTogether = 0,
  });

  final String id;
  final String userId1; // User who initiated the match
  final String userId2; // User who received the match
  final BuddyMatchStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? lastMessageAt;
  final int compatibilityScore; // 0-100
  final int totalRidesTogether;

  /// Check if this match involves the given user
  bool involvesUser(String userId) => userId1 == userId || userId2 == userId;

  /// Get the other user's ID in this match
  String getOtherUserId(String currentUserId) {
    if (userId1 == currentUserId) return userId2;
    if (userId2 == currentUserId) return userId1;
    throw ArgumentError('User $currentUserId is not part of this match');
  }

  factory BuddyMatch.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return BuddyMatch(
      id: doc.id,
      userId1: data['userId1'] as String,
      userId2: data['userId2'] as String,
      status: BuddyMatchStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => BuddyMatchStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      acceptedAt: data['acceptedAt'] != null ? (data['acceptedAt'] as Timestamp).toDate() : null,
      lastMessageAt: data['lastMessageAt'] != null ? (data['lastMessageAt'] as Timestamp).toDate() : null,
      compatibilityScore: (data['compatibilityScore'] as num?)?.toInt() ?? 0,
      totalRidesTogether: (data['totalRidesTogether'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId1': userId1,
        'userId2': userId2,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
        'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
        'compatibilityScore': compatibilityScore,
        'totalRidesTogether': totalRidesTogether,
      };

  BuddyMatch copyWith({
    BuddyMatchStatus? status,
    DateTime? acceptedAt,
    DateTime? lastMessageAt,
    int? totalRidesTogether,
  }) {
    return BuddyMatch(
      id: id,
      userId1: userId1,
      userId2: userId2,
      status: status ?? this.status,
      createdAt: createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      compatibilityScore: compatibilityScore,
      totalRidesTogether: totalRidesTogether ?? this.totalRidesTogether,
    );
  }
}
