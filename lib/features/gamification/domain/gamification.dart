/// CYKEL — Gamification Domain Models
/// Challenges, badges, achievements, and leaderboards

import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Challenge Types ──────────────────────────────────────────────────────────

enum ChallengeType {
  /// Distance-based challenges
  distance,
  /// Number of rides
  rides,
  /// Active days streak
  streak,
  /// Time-based (duration)
  duration,
  /// Elevation gain
  elevation,
  /// Speed achievements
  speed,
  /// Community challenges
  community,
}

extension ChallengeTypeExt on ChallengeType {
  String get displayName {
    switch (this) {
      case ChallengeType.distance:
        return 'Distance';
      case ChallengeType.rides:
        return 'Antal ture';
      case ChallengeType.streak:
        return 'Streak';
      case ChallengeType.duration:
        return 'Tid';
      case ChallengeType.elevation:
        return 'Højdemeter';
      case ChallengeType.speed:
        return 'Hastighed';
      case ChallengeType.community:
        return 'Fællesskab';
    }
  }

  String get icon {
    switch (this) {
      case ChallengeType.distance:
        return '🛣️';
      case ChallengeType.rides:
        return '🚴';
      case ChallengeType.streak:
        return '🔥';
      case ChallengeType.duration:
        return '⏱️';
      case ChallengeType.elevation:
        return '⛰️';
      case ChallengeType.speed:
        return '⚡';
      case ChallengeType.community:
        return '👥';
    }
  }
}

// ─── Challenge Difficulty ─────────────────────────────────────────────────────

enum ChallengeDifficulty {
  easy,
  medium,
  hard,
  extreme,
}

extension ChallengeDifficultyExt on ChallengeDifficulty {
  String get displayName {
    switch (this) {
      case ChallengeDifficulty.easy:
        return 'Let';
      case ChallengeDifficulty.medium:
        return 'Medium';
      case ChallengeDifficulty.hard:
        return 'Svær';
      case ChallengeDifficulty.extreme:
        return 'Ekstrem';
    }
  }

  int get pointsMultiplier {
    switch (this) {
      case ChallengeDifficulty.easy:
        return 1;
      case ChallengeDifficulty.medium:
        return 2;
      case ChallengeDifficulty.hard:
        return 3;
      case ChallengeDifficulty.extreme:
        return 5;
    }
  }
}

// ─── Challenge Model ──────────────────────────────────────────────────────────

class Challenge {
  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.targetValue,
    required this.unit,
    required this.points,
    this.startDate,
    this.endDate,
    this.badgeId,
    this.isActive = true,
    this.isFeatured = false,
  });

  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeDifficulty difficulty;
  final double targetValue;
  final String unit; // 'km', 'rides', 'days', 'hours', 'm', 'km/h'
  final int points;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? badgeId; // Badge awarded on completion
  final bool isActive;
  final bool isFeatured;

  bool get isTimeLimited => startDate != null && endDate != null;
  
  bool get isAvailable {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type.name,
    'difficulty': difficulty.name,
    'targetValue': targetValue,
    'unit': unit,
    'points': points,
    'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
    'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    'badgeId': badgeId,
    'isActive': isActive,
    'isFeatured': isFeatured,
  };

  factory Challenge.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Challenge(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      type: ChallengeType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => ChallengeType.distance,
      ),
      difficulty: ChallengeDifficulty.values.firstWhere(
        (d) => d.name == data['difficulty'],
        orElse: () => ChallengeDifficulty.easy,
      ),
      targetValue: (data['targetValue'] as num).toDouble(),
      unit: data['unit'] as String,
      points: data['points'] as int,
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      badgeId: data['badgeId'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      isFeatured: data['isFeatured'] as bool? ?? false,
    );
  }
}

// ─── User Challenge Progress ──────────────────────────────────────────────────

class ChallengeProgress {
  const ChallengeProgress({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.currentValue,
    required this.startedAt,
    this.completedAt,
  });

  final String id;
  final String challengeId;
  final String userId;
  final double currentValue;
  final DateTime startedAt;
  final DateTime? completedAt;

  bool get isCompleted => completedAt != null;

  double progressPercent(double targetValue) {
    if (targetValue <= 0) return 0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
    'challengeId': challengeId,
    'userId': userId,
    'currentValue': currentValue,
    'startedAt': Timestamp.fromDate(startedAt),
    'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
  };

  factory ChallengeProgress.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ChallengeProgress(
      id: doc.id,
      challengeId: data['challengeId'] as String,
      userId: data['userId'] as String,
      currentValue: (data['currentValue'] as num).toDouble(),
      startedAt: (data['startedAt'] as Timestamp).toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  ChallengeProgress copyWith({
    double? currentValue,
    DateTime? completedAt,
  }) {
    return ChallengeProgress(
      id: id,
      challengeId: challengeId,
      userId: userId,
      currentValue: currentValue ?? this.currentValue,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

// ─── Badge Model ──────────────────────────────────────────────────────────────

enum BadgeRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

extension BadgeRarityExt on BadgeRarity {
  String get displayName {
    switch (this) {
      case BadgeRarity.common:
        return 'Almindelig';
      case BadgeRarity.uncommon:
        return 'Ualmindelig';
      case BadgeRarity.rare:
        return 'Sjælden';
      case BadgeRarity.epic:
        return 'Episk';
      case BadgeRarity.legendary:
        return 'Legendarisk';
    }
  }

  int get colorValue {
    switch (this) {
      case BadgeRarity.common:
        return 0xFF9E9E9E; // Gray
      case BadgeRarity.uncommon:
        return 0xFF4CAF50; // Green
      case BadgeRarity.rare:
        return 0xFF2196F3; // Blue
      case BadgeRarity.epic:
        return 0xFF9C27B0; // Purple
      case BadgeRarity.legendary:
        return 0xFFFF9800; // Gold/Orange
    }
  }
}

class Badge {
  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
    this.requirement,
  });

  final String id;
  final String name;
  final String description;
  final String icon; // Emoji or asset path
  final BadgeRarity rarity;
  final String? requirement; // Human-readable requirement text

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'icon': icon,
    'rarity': rarity.name,
    'requirement': requirement,
  };

  factory Badge.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Badge(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String,
      icon: data['icon'] as String,
      rarity: BadgeRarity.values.firstWhere(
        (r) => r.name == data['rarity'],
        orElse: () => BadgeRarity.common,
      ),
      requirement: data['requirement'] as String?,
    );
  }
}

// ─── User Badge ───────────────────────────────────────────────────────────────

class UserBadge {
  const UserBadge({
    required this.id,
    required this.badgeId,
    required this.userId,
    required this.earnedAt,
  });

  final String id;
  final String badgeId;
  final String userId;
  final DateTime earnedAt;

  Map<String, dynamic> toJson() => {
    'badgeId': badgeId,
    'userId': userId,
    'earnedAt': Timestamp.fromDate(earnedAt),
  };

  factory UserBadge.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserBadge(
      id: doc.id,
      badgeId: data['badgeId'] as String,
      userId: data['userId'] as String,
      earnedAt: (data['earnedAt'] as Timestamp).toDate(),
    );
  }
}

// ─── Leaderboard Entry ────────────────────────────────────────────────────────

enum LeaderboardPeriod {
  weekly,
  monthly,
  allTime,
}

extension LeaderboardPeriodExt on LeaderboardPeriod {
  String get displayName {
    switch (this) {
      case LeaderboardPeriod.weekly:
        return 'Denne uge';
      case LeaderboardPeriod.monthly:
        return 'Denne måned';
      case LeaderboardPeriod.allTime:
        return 'Alle tider';
    }
  }
}

enum LeaderboardCategory {
  distance,
  rides,
  points,
  elevation,
  streak,
}

extension LeaderboardCategoryExt on LeaderboardCategory {
  String get displayName {
    switch (this) {
      case LeaderboardCategory.distance:
        return 'Distance';
      case LeaderboardCategory.rides:
        return 'Ture';
      case LeaderboardCategory.points:
        return 'Point';
      case LeaderboardCategory.elevation:
        return 'Højdemeter';
      case LeaderboardCategory.streak:
        return 'Streak';
    }
  }

  String get unit {
    switch (this) {
      case LeaderboardCategory.distance:
        return 'km';
      case LeaderboardCategory.rides:
        return 'ture';
      case LeaderboardCategory.points:
        return 'pt';
      case LeaderboardCategory.elevation:
        return 'm';
      case LeaderboardCategory.streak:
        return 'dage';
    }
  }
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.rank,
    required this.value,
    this.photoUrl,
    this.isCurrentUser = false,
  });

  final String userId;
  final String displayName;
  final int rank;
  final double value;
  final String? photoUrl;
  final bool isCurrentUser;

  factory LeaderboardEntry.fromFirestore(
    Map<String, dynamic> data, 
    int rank, 
    String? currentUserId,
  ) {
    return LeaderboardEntry(
      userId: data['userId'] as String,
      displayName: data['displayName'] as String? ?? 'Cyklist',
      rank: rank,
      value: (data['value'] as num).toDouble(),
      photoUrl: data['photoUrl'] as String?,
      isCurrentUser: data['userId'] == currentUserId,
    );
  }
}

// ─── User Stats Summary ───────────────────────────────────────────────────────

class UserStats {
  const UserStats({
    required this.userId,
    this.totalDistanceKm = 0,
    this.totalRides = 0,
    this.totalDurationMinutes = 0,
    this.totalElevationM = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalPoints = 0,
    this.level = 1,
    this.badgeCount = 0,
    this.challengesCompleted = 0,
  });

  final String userId;
  final double totalDistanceKm;
  final int totalRides;
  final int totalDurationMinutes;
  final double totalElevationM;
  final int currentStreak;
  final int longestStreak;
  final int totalPoints;
  final int level;
  final int badgeCount;
  final int challengesCompleted;

  /// Points needed for next level (simple exponential curve)
  int get pointsForNextLevel => level * 500;

  /// Progress to next level (0.0 - 1.0)
  double get levelProgress {
    final pointsInCurrentLevel = totalPoints - ((level - 1) * 500);
    return (pointsInCurrentLevel / pointsForNextLevel).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'totalDistanceKm': totalDistanceKm,
    'totalRides': totalRides,
    'totalDurationMinutes': totalDurationMinutes,
    'totalElevationM': totalElevationM,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'totalPoints': totalPoints,
    'level': level,
    'badgeCount': badgeCount,
    'challengesCompleted': challengesCompleted,
  };

  factory UserStats.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserStats(
      userId: doc.id,
      totalDistanceKm: (data['totalDistanceKm'] as num?)?.toDouble() ?? 0,
      totalRides: data['totalRides'] as int? ?? 0,
      totalDurationMinutes: data['totalDurationMinutes'] as int? ?? 0,
      totalElevationM: (data['totalElevationM'] as num?)?.toDouble() ?? 0,
      currentStreak: data['currentStreak'] as int? ?? 0,
      longestStreak: data['longestStreak'] as int? ?? 0,
      totalPoints: data['totalPoints'] as int? ?? 0,
      level: data['level'] as int? ?? 1,
      badgeCount: data['badgeCount'] as int? ?? 0,
      challengesCompleted: data['challengesCompleted'] as int? ?? 0,
    );
  }

  UserStats copyWith({
    double? totalDistanceKm,
    int? totalRides,
    int? totalDurationMinutes,
    double? totalElevationM,
    int? currentStreak,
    int? longestStreak,
    int? totalPoints,
    int? level,
    int? badgeCount,
    int? challengesCompleted,
  }) {
    return UserStats(
      userId: userId,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      totalRides: totalRides ?? this.totalRides,
      totalDurationMinutes: totalDurationMinutes ?? this.totalDurationMinutes,
      totalElevationM: totalElevationM ?? this.totalElevationM,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalPoints: totalPoints ?? this.totalPoints,
      level: level ?? this.level,
      badgeCount: badgeCount ?? this.badgeCount,
      challengesCompleted: challengesCompleted ?? this.challengesCompleted,
    );
  }
}

// ─── Default Challenges ───────────────────────────────────────────────────────

const defaultChallenges = [
  // Distance challenges
  Challenge(
    id: 'first_10km',
    title: 'Første 10 km',
    description: 'Kør din første 10 kilometer',
    type: ChallengeType.distance,
    difficulty: ChallengeDifficulty.easy,
    targetValue: 10,
    unit: 'km',
    points: 50,
    badgeId: 'badge_first_10km',
  ),
  Challenge(
    id: 'century_ride',
    title: 'Century Ride',
    description: 'Kør 100 km på én tur',
    type: ChallengeType.distance,
    difficulty: ChallengeDifficulty.hard,
    targetValue: 100,
    unit: 'km',
    points: 500,
    badgeId: 'badge_century',
  ),
  Challenge(
    id: 'total_500km',
    title: '500 km i alt',
    description: 'Kør 500 km i alt',
    type: ChallengeType.distance,
    difficulty: ChallengeDifficulty.medium,
    targetValue: 500,
    unit: 'km',
    points: 250,
  ),
  Challenge(
    id: 'total_1000km',
    title: '1.000 km i alt',
    description: 'Kør 1.000 km i alt',
    type: ChallengeType.distance,
    difficulty: ChallengeDifficulty.hard,
    targetValue: 1000,
    unit: 'km',
    points: 500,
    badgeId: 'badge_1000km',
  ),
  
  // Ride count challenges
  Challenge(
    id: 'first_ride',
    title: 'Første tur',
    description: 'Gennemfør din første cykeltur',
    type: ChallengeType.rides,
    difficulty: ChallengeDifficulty.easy,
    targetValue: 1,
    unit: 'ture',
    points: 25,
    badgeId: 'badge_first_ride',
  ),
  Challenge(
    id: 'ten_rides',
    title: '10 ture',
    description: 'Gennemfør 10 cykelture',
    type: ChallengeType.rides,
    difficulty: ChallengeDifficulty.easy,
    targetValue: 10,
    unit: 'ture',
    points: 100,
  ),
  Challenge(
    id: 'fifty_rides',
    title: '50 ture',
    description: 'Gennemfør 50 cykelture',
    type: ChallengeType.rides,
    difficulty: ChallengeDifficulty.medium,
    targetValue: 50,
    unit: 'ture',
    points: 300,
  ),
  Challenge(
    id: 'hundred_rides',
    title: '100 ture',
    description: 'Gennemfør 100 cykelture',
    type: ChallengeType.rides,
    difficulty: ChallengeDifficulty.hard,
    targetValue: 100,
    unit: 'ture',
    points: 500,
    badgeId: 'badge_century_rides',
  ),

  // Streak challenges
  Challenge(
    id: 'streak_3',
    title: '3-dages streak',
    description: 'Kør 3 dage i træk',
    type: ChallengeType.streak,
    difficulty: ChallengeDifficulty.easy,
    targetValue: 3,
    unit: 'dage',
    points: 75,
  ),
  Challenge(
    id: 'streak_7',
    title: 'Ugens helt',
    description: 'Kør 7 dage i træk',
    type: ChallengeType.streak,
    difficulty: ChallengeDifficulty.medium,
    targetValue: 7,
    unit: 'dage',
    points: 200,
    badgeId: 'badge_week_streak',
  ),
  Challenge(
    id: 'streak_30',
    title: 'Månedens cyklist',
    description: 'Kør 30 dage i træk',
    type: ChallengeType.streak,
    difficulty: ChallengeDifficulty.extreme,
    targetValue: 30,
    unit: 'dage',
    points: 1000,
    badgeId: 'badge_month_streak',
  ),

  // Elevation challenges
  Challenge(
    id: 'elevation_1000',
    title: 'Bakkekongen',
    description: 'Optjen 1.000 højdemeter',
    type: ChallengeType.elevation,
    difficulty: ChallengeDifficulty.medium,
    targetValue: 1000,
    unit: 'm',
    points: 200,
  ),
  Challenge(
    id: 'elevation_everest',
    title: 'Everest Challenge',
    description: 'Optjen 8.849 højdemeter (Mount Everest)',
    type: ChallengeType.elevation,
    difficulty: ChallengeDifficulty.extreme,
    targetValue: 8849,
    unit: 'm',
    points: 2000,
    badgeId: 'badge_everest',
  ),
];

// ─── Default Badges ───────────────────────────────────────────────────────────

const defaultBadges = [
  Badge(
    id: 'badge_first_ride',
    name: 'Første tur',
    description: 'Gennemførte din første cykeltur',
    icon: '🎉',
    rarity: BadgeRarity.common,
    requirement: 'Gennemfør 1 tur',
  ),
  Badge(
    id: 'badge_first_10km',
    name: 'Ti-tommer',
    description: 'Kørte 10 km for første gang',
    icon: '🔟',
    rarity: BadgeRarity.common,
    requirement: 'Kør 10 km',
  ),
  Badge(
    id: 'badge_century',
    name: 'Century Rider',
    description: 'Kørte 100 km på én tur',
    icon: '💯',
    rarity: BadgeRarity.epic,
    requirement: 'Kør 100 km på én tur',
  ),
  Badge(
    id: 'badge_1000km',
    name: 'Tusindben',
    description: 'Kørte 1.000 km i alt',
    icon: '🏅',
    rarity: BadgeRarity.rare,
    requirement: 'Kør 1.000 km i alt',
  ),
  Badge(
    id: 'badge_century_rides',
    name: 'Tur-titan',
    description: 'Gennemførte 100 cykelture',
    icon: '🏆',
    rarity: BadgeRarity.rare,
    requirement: 'Gennemfør 100 ture',
  ),
  Badge(
    id: 'badge_week_streak',
    name: 'Ugens helt',
    description: 'Cyklede 7 dage i træk',
    icon: '🔥',
    rarity: BadgeRarity.uncommon,
    requirement: '7-dages streak',
  ),
  Badge(
    id: 'badge_month_streak',
    name: 'Måneds-mester',
    description: 'Cyklede 30 dage i træk',
    icon: '🌟',
    rarity: BadgeRarity.legendary,
    requirement: '30-dages streak',
  ),
  Badge(
    id: 'badge_everest',
    name: 'Everest Erobrer',
    description: 'Overvandt Mount Everests højde i elevation',
    icon: '🏔️',
    rarity: BadgeRarity.legendary,
    requirement: 'Optjen 8.849 højdemeter',
  ),
  Badge(
    id: 'badge_early_bird',
    name: 'Morgenfugl',
    description: 'Cyklede før kl. 6:00',
    icon: '🌅',
    rarity: BadgeRarity.uncommon,
    requirement: 'Start en tur før kl. 6:00',
  ),
  Badge(
    id: 'badge_night_owl',
    name: 'Natteravn',
    description: 'Cyklede efter kl. 22:00',
    icon: '🦉',
    rarity: BadgeRarity.uncommon,
    requirement: 'Start en tur efter kl. 22:00',
  ),
  Badge(
    id: 'badge_rain_rider',
    name: 'Regnrytter',
    description: 'Cyklede i regnvejr',
    icon: '🌧️',
    rarity: BadgeRarity.uncommon,
    requirement: 'Cykel i regnvejr',
  ),
];
