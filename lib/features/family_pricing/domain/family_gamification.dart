import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Types of achievements available in the family system
enum AchievementType {
  // Distance achievements
  firstRide,
  distance10km,
  distance50km,
  distance100km,
  distance500km,
  distance1000km,

  // Ride count achievements
  rides5,
  rides25,
  rides100,
  rides500,

  // Streak achievements
  streak3days,
  streak7days,
  streak30days,
  streak100days,

  // Safety achievements
  safetyFirst, // Set up safe zones
  alwaysSafe, // 30 days without leaving safe zones
  speedLimitHero, // Never triggered speed alert

  // Family achievements
  familyRide, // First ride with another family member nearby
  familyChampion, // Top of leaderboard for a week
  helpingHand, // Resolved 10 alerts

  // Time-based achievements
  earlyBird, // Ride before 7am
  nightOwl, // Ride after 9pm
  weekendWarrior, // 10 weekend rides

  // Special achievements
  explorer, // Rode in 5 different cities
  consistent, // Same route 10 times
  speedDemon, // Reached 40 km/h
}

/// Rarity levels for achievements
enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

/// An achievement definition
class Achievement {
  final AchievementType type;
  final String name;
  final String description;
  final IconData icon;
  final AchievementRarity rarity;
  final int points;
  final String? requirement; // Human-readable requirement

  const Achievement({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.points,
    this.requirement,
  });

  Color get color {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.uncommon:
        return Colors.green;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.orange;
    }
  }

  String get rarityName {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.uncommon:
        return 'Uncommon';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }
}

/// An unlocked achievement for a user
class UnlockedAchievement {
  final String id;
  final String memberId;
  final String memberName;
  final AchievementType type;
  final DateTime unlockedAt;
  final Map<String, dynamic>? metadata; // Extra data about how it was earned

  const UnlockedAchievement({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.type,
    required this.unlockedAt,
    this.metadata,
  });

  factory UnlockedAchievement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UnlockedAchievement(
      id: doc.id,
      memberId: data['memberId'] ?? '',
      memberName: data['memberName'] ?? 'Unknown',
      type: AchievementType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => AchievementType.firstRide,
      ),
      unlockedAt: (data['unlockedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'memberId': memberId,
        'memberName': memberName,
        'type': type.name,
        'unlockedAt': Timestamp.fromDate(unlockedAt),
        'metadata': metadata,
      };
}

/// A family challenge
class FamilyChallenge {
  final String id;
  final String familyId;
  final String title;
  final String description;
  final ChallengeType type;
  final double targetValue;
  final double currentValue;
  final DateTime startDate;
  final DateTime endDate;
  final ChallengeStatus status;
  final List<String> participantIds;
  final Map<String, double> memberProgress; // memberId -> progress
  final int rewardPoints;
  final String? createdBy;

  const FamilyChallenge({
    required this.id,
    required this.familyId,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.participantIds,
    required this.memberProgress,
    required this.rewardPoints,
    this.createdBy,
  });

  bool get isActive => status == ChallengeStatus.active;
  bool get isCompleted => status == ChallengeStatus.completed;
  double get progressPercent => (currentValue / targetValue).clamp(0.0, 1.0);
  Duration get timeRemaining => endDate.difference(DateTime.now());
  bool get isExpired => DateTime.now().isAfter(endDate);

  factory FamilyChallenge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyChallenge(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: ChallengeType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => ChallengeType.totalDistance,
      ),
      targetValue: (data['targetValue'] ?? 0).toDouble(),
      currentValue: (data['currentValue'] ?? 0).toDouble(),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: ChallengeStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ChallengeStatus.active,
      ),
      participantIds: List<String>.from(data['participantIds'] ?? []),
      memberProgress: Map<String, double>.from(
        (data['memberProgress'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, v.toDouble()),
            ) ??
            {},
      ),
      rewardPoints: data['rewardPoints'] ?? 0,
      createdBy: data['createdBy'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'familyId': familyId,
        'title': title,
        'description': description,
        'type': type.name,
        'targetValue': targetValue,
        'currentValue': currentValue,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'status': status.name,
        'participantIds': participantIds,
        'memberProgress': memberProgress,
        'rewardPoints': rewardPoints,
        'createdBy': createdBy,
      };

  FamilyChallenge copyWith({
    String? id,
    String? familyId,
    String? title,
    String? description,
    ChallengeType? type,
    double? targetValue,
    double? currentValue,
    DateTime? startDate,
    DateTime? endDate,
    ChallengeStatus? status,
    List<String>? participantIds,
    Map<String, double>? memberProgress,
    int? rewardPoints,
    String? createdBy,
  }) {
    return FamilyChallenge(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      participantIds: participantIds ?? this.participantIds,
      memberProgress: memberProgress ?? this.memberProgress,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

enum ChallengeType {
  totalDistance, // Family total km
  totalRides, // Family total rides
  memberDistance, // Individual km goal
  dailyStreak, // Days with at least one ride
  weeklyDistance, // Distance in a week
}

enum ChallengeStatus {
  upcoming,
  active,
  completed,
  failed,
}

/// Member's gamification stats
class MemberGamificationStats {
  final String memberId;
  final String memberName;
  final int totalPoints;
  final int achievementCount;
  final int currentStreak;
  final int longestStreak;
  final double totalDistanceKm;
  final int totalRides;
  final int challengesCompleted;
  final int level;

  const MemberGamificationStats({
    required this.memberId,
    required this.memberName,
    required this.totalPoints,
    required this.achievementCount,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalDistanceKm,
    required this.totalRides,
    required this.challengesCompleted,
    required this.level,
  });

  factory MemberGamificationStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemberGamificationStats(
      memberId: doc.id,
      memberName: data['memberName'] ?? 'Unknown',
      totalPoints: data['totalPoints'] ?? 0,
      achievementCount: data['achievementCount'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      totalDistanceKm: (data['totalDistanceKm'] ?? 0).toDouble(),
      totalRides: data['totalRides'] ?? 0,
      challengesCompleted: data['challengesCompleted'] ?? 0,
      level: data['level'] ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'memberName': memberName,
        'totalPoints': totalPoints,
        'achievementCount': achievementCount,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'totalDistanceKm': totalDistanceKm,
        'totalRides': totalRides,
        'challengesCompleted': challengesCompleted,
        'level': level,
      };

  int get pointsToNextLevel => (level * 500) - (totalPoints % (level * 500));
  double get levelProgress => (totalPoints % (level * 500)) / (level * 500);

  static int calculateLevel(int points) {
    // Level formula: each level requires more points
    // Level 1: 0-499, Level 2: 500-1499, Level 3: 1500-2999, etc.
    int level = 1;
    int threshold = 500;
    int accumulated = 0;

    while (points >= accumulated + threshold) {
      accumulated += threshold;
      level++;
      threshold = level * 500;
    }

    return level;
  }
}

/// All achievement definitions
class AchievementDefinitions {
  static const List<Achievement> all = [
    // Distance achievements
    Achievement(
      type: AchievementType.firstRide,
      name: 'First Pedal',
      description: 'Complete your first ride',
      icon: Icons.pedal_bike,
      rarity: AchievementRarity.common,
      points: 50,
      requirement: 'Complete 1 ride',
    ),
    Achievement(
      type: AchievementType.distance10km,
      name: 'Getting Started',
      description: 'Ride a total of 10 kilometers',
      icon: Icons.straighten,
      rarity: AchievementRarity.common,
      points: 100,
      requirement: 'Ride 10 km total',
    ),
    Achievement(
      type: AchievementType.distance50km,
      name: 'Half Century',
      description: 'Ride a total of 50 kilometers',
      icon: Icons.trending_up,
      rarity: AchievementRarity.uncommon,
      points: 250,
      requirement: 'Ride 50 km total',
    ),
    Achievement(
      type: AchievementType.distance100km,
      name: 'Century Rider',
      description: 'Ride a total of 100 kilometers',
      icon: Icons.emoji_events,
      rarity: AchievementRarity.rare,
      points: 500,
      requirement: 'Ride 100 km total',
    ),
    Achievement(
      type: AchievementType.distance500km,
      name: 'Road Warrior',
      description: 'Ride a total of 500 kilometers',
      icon: Icons.military_tech,
      rarity: AchievementRarity.epic,
      points: 1500,
      requirement: 'Ride 500 km total',
    ),
    Achievement(
      type: AchievementType.distance1000km,
      name: 'Legendary Cyclist',
      description: 'Ride a total of 1000 kilometers',
      icon: Icons.star,
      rarity: AchievementRarity.legendary,
      points: 5000,
      requirement: 'Ride 1000 km total',
    ),

    // Ride count achievements
    Achievement(
      type: AchievementType.rides5,
      name: 'Regular Rider',
      description: 'Complete 5 rides',
      icon: Icons.repeat,
      rarity: AchievementRarity.common,
      points: 75,
      requirement: 'Complete 5 rides',
    ),
    Achievement(
      type: AchievementType.rides25,
      name: 'Dedicated Cyclist',
      description: 'Complete 25 rides',
      icon: Icons.looks_one,
      rarity: AchievementRarity.uncommon,
      points: 300,
      requirement: 'Complete 25 rides',
    ),
    Achievement(
      type: AchievementType.rides100,
      name: 'Century Club',
      description: 'Complete 100 rides',
      icon: Icons.workspace_premium,
      rarity: AchievementRarity.rare,
      points: 1000,
      requirement: 'Complete 100 rides',
    ),
    Achievement(
      type: AchievementType.rides500,
      name: 'Elite Rider',
      description: 'Complete 500 rides',
      icon: Icons.diamond,
      rarity: AchievementRarity.legendary,
      points: 3000,
      requirement: 'Complete 500 rides',
    ),

    // Streak achievements
    Achievement(
      type: AchievementType.streak3days,
      name: 'Good Start',
      description: 'Ride for 3 days in a row',
      icon: Icons.local_fire_department,
      rarity: AchievementRarity.common,
      points: 100,
      requirement: '3-day streak',
    ),
    Achievement(
      type: AchievementType.streak7days,
      name: 'Week Warrior',
      description: 'Ride for 7 days in a row',
      icon: Icons.whatshot,
      rarity: AchievementRarity.uncommon,
      points: 350,
      requirement: '7-day streak',
    ),
    Achievement(
      type: AchievementType.streak30days,
      name: 'Monthly Master',
      description: 'Ride for 30 days in a row',
      icon: Icons.local_fire_department,
      rarity: AchievementRarity.epic,
      points: 2000,
      requirement: '30-day streak',
    ),
    Achievement(
      type: AchievementType.streak100days,
      name: 'Unstoppable',
      description: 'Ride for 100 days in a row',
      icon: Icons.bolt,
      rarity: AchievementRarity.legendary,
      points: 10000,
      requirement: '100-day streak',
    ),

    // Safety achievements
    Achievement(
      type: AchievementType.safetyFirst,
      name: 'Safety First',
      description: 'Set up your first safe zone',
      icon: Icons.shield,
      rarity: AchievementRarity.common,
      points: 50,
      requirement: 'Create a safe zone',
    ),
    Achievement(
      type: AchievementType.alwaysSafe,
      name: 'Always Safe',
      description: 'Go 30 days without leaving safe zones during curfew',
      icon: Icons.verified_user,
      rarity: AchievementRarity.rare,
      points: 750,
      requirement: '30 days respecting safe zones',
    ),
    Achievement(
      type: AchievementType.speedLimitHero,
      name: 'Speed Limit Hero',
      description: 'Complete 50 rides without triggering a speed alert',
      icon: Icons.speed,
      rarity: AchievementRarity.uncommon,
      points: 400,
      requirement: '50 rides without speed alerts',
    ),

    // Family achievements
    Achievement(
      type: AchievementType.familyRide,
      name: 'Family Ride',
      description: 'Ride with another family member',
      icon: Icons.groups,
      rarity: AchievementRarity.uncommon,
      points: 200,
      requirement: 'Ride together',
    ),
    Achievement(
      type: AchievementType.familyChampion,
      name: 'Family Champion',
      description: 'Top the family leaderboard for a week',
      icon: Icons.leaderboard,
      rarity: AchievementRarity.rare,
      points: 750,
      requirement: '#1 for 7 days',
    ),
    Achievement(
      type: AchievementType.helpingHand,
      name: 'Helping Hand',
      description: 'Resolve 10 family alerts',
      icon: Icons.volunteer_activism,
      rarity: AchievementRarity.uncommon,
      points: 300,
      requirement: 'Resolve 10 alerts',
    ),

    // Time-based achievements
    Achievement(
      type: AchievementType.earlyBird,
      name: 'Early Bird',
      description: 'Complete a ride before 7 AM',
      icon: Icons.wb_sunny,
      rarity: AchievementRarity.uncommon,
      points: 150,
      requirement: 'Ride before 7 AM',
    ),
    Achievement(
      type: AchievementType.nightOwl,
      name: 'Night Owl',
      description: 'Complete a ride after 9 PM',
      icon: Icons.nightlight,
      rarity: AchievementRarity.uncommon,
      points: 150,
      requirement: 'Ride after 9 PM',
    ),
    Achievement(
      type: AchievementType.weekendWarrior,
      name: 'Weekend Warrior',
      description: 'Complete 10 rides on weekends',
      icon: Icons.weekend,
      rarity: AchievementRarity.rare,
      points: 400,
      requirement: '10 weekend rides',
    ),

    // Special achievements
    Achievement(
      type: AchievementType.explorer,
      name: 'Explorer',
      description: 'Ride in 5 different cities',
      icon: Icons.explore,
      rarity: AchievementRarity.epic,
      points: 1000,
      requirement: 'Ride in 5 cities',
    ),
    Achievement(
      type: AchievementType.consistent,
      name: 'Creature of Habit',
      description: 'Complete the same route 10 times',
      icon: Icons.loop,
      rarity: AchievementRarity.rare,
      points: 500,
      requirement: 'Same route 10 times',
    ),
    Achievement(
      type: AchievementType.speedDemon,
      name: 'Speed Demon',
      description: 'Reach 40 km/h during a ride',
      icon: Icons.flash_on,
      rarity: AchievementRarity.rare,
      points: 300,
      requirement: 'Reach 40 km/h',
    ),
  ];

  static Achievement getDefinition(AchievementType type) {
    return all.firstWhere(
      (a) => a.type == type,
      orElse: () => all.first,
    );
  }
}

/// Challenge templates for quick creation
class ChallengeTemplates {
  static List<FamilyChallenge> getTemplates(String familyId) {
    final now = DateTime.now();
    final weekEnd = now.add(const Duration(days: 7));
    final monthEnd = now.add(const Duration(days: 30));

    return [
      FamilyChallenge(
        id: '',
        familyId: familyId,
        title: 'Weekly Family Distance',
        description: 'Ride 50 km together as a family this week',
        type: ChallengeType.totalDistance,
        targetValue: 50,
        currentValue: 0,
        startDate: now,
        endDate: weekEnd,
        status: ChallengeStatus.active,
        participantIds: [],
        memberProgress: {},
        rewardPoints: 500,
      ),
      FamilyChallenge(
        id: '',
        familyId: familyId,
        title: 'Ride Every Day',
        description: 'Have at least one family member ride each day for a week',
        type: ChallengeType.dailyStreak,
        targetValue: 7,
        currentValue: 0,
        startDate: now,
        endDate: weekEnd,
        status: ChallengeStatus.active,
        participantIds: [],
        memberProgress: {},
        rewardPoints: 750,
      ),
      FamilyChallenge(
        id: '',
        familyId: familyId,
        title: 'Monthly Century',
        description: 'Ride 100 km as a family this month',
        type: ChallengeType.totalDistance,
        targetValue: 100,
        currentValue: 0,
        startDate: now,
        endDate: monthEnd,
        status: ChallengeStatus.active,
        participantIds: [],
        memberProgress: {},
        rewardPoints: 1000,
      ),
      FamilyChallenge(
        id: '',
        familyId: familyId,
        title: '20 Rides Challenge',
        description: 'Complete 20 rides as a family this month',
        type: ChallengeType.totalRides,
        targetValue: 20,
        currentValue: 0,
        startDate: now,
        endDate: monthEnd,
        status: ChallengeStatus.active,
        participantIds: [],
        memberProgress: {},
        rewardPoints: 800,
      ),
    ];
  }
}
