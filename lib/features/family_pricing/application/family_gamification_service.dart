import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/family_gamification.dart';
import '../domain/family_location.dart';

/// Service for managing achievements and challenges
class FamilyGamificationService {
  final FirebaseFirestore _firestore;

  FamilyGamificationService({
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance;

  // ==========================================
  // Achievement Management
  // ==========================================

  /// Check and unlock achievements after a ride
  Future<List<UnlockedAchievement>> checkAchievementsAfterRide(
    String familyId,
    FamilyRide ride,
  ) async {
    final userId = ride.memberId;
    final stats = await getMemberStats(familyId, userId);
    final unlockedTypes = await _getUnlockedAchievementTypes(familyId, userId);

    final newlyUnlocked = <UnlockedAchievement>[];

    // Check distance achievements
    if (!unlockedTypes.contains(AchievementType.firstRide)) {
      final achievement = await _unlockAchievement(
        familyId,
        userId,
        ride.memberName,
        AchievementType.firstRide,
      );
      if (achievement != null) newlyUnlocked.add(achievement);
    }

    final totalDistance = stats.totalDistanceKm + ride.distanceKm;

    if (totalDistance >= 10 && !unlockedTypes.contains(AchievementType.distance10km)) {
      final achievement = await _unlockAchievement(
        familyId,
        userId,
        ride.memberName,
        AchievementType.distance10km,
        metadata: {'totalDistance': totalDistance},
      );
      if (achievement != null) newlyUnlocked.add(achievement);
    }

    if (totalDistance >= 50 && !unlockedTypes.contains(AchievementType.distance50km)) {
      final achievement = await _unlockAchievement(
        familyId,
        userId,
        ride.memberName,
        AchievementType.distance50km,
        metadata: {'totalDistance': totalDistance},
      );
      if (achievement != null) newlyUnlocked.add(achievement);
    }

    if (totalDistance >= 100 && !unlockedTypes.contains(AchievementType.distance100km)) {
      final achievement = await _unlockAchievement(
        familyId,
        userId,
        ride.memberName,
        AchievementType.distance100km,
        metadata: {'totalDistance': totalDistance},
      );
      if (achievement != null) newlyUnlocked.add(achievement);
    }

    if (totalDistance >= 500 && !unlockedTypes.contains(AchievementType.distance500km)) {
      final achievement = await _unlockAchievement(
        familyId,
        userId,
        ride.memberName,
        AchievementType.distance500km,
        metadata: {'totalDistance': totalDistance},
      );
      if (achievement != null) newlyUnlocked.add(achievement);
    }

    if (totalDistance >= 1000 && !unlockedTypes.contains(AchievementType.distance1000km)) {
      final achievement = await _unlockAchievement(
        familyId,
        userId,
        ride.memberName,
        AchievementType.distance1000km,
        metadata: {'totalDistance': totalDistance},
      );
      if (achievement != null) newlyUnlocked.add(achievement);
    }

    // Check ride count achievements
    final totalRides = stats.totalRides + 1;

    if (totalRides >= 5 && !unlockedTypes.contains(AchievementType.rides5)) {
      final achievement = await _unlockAchievement(
        familyId,
        userId,
        ride.memberName,
        AchievementType.rides5,
        metadata: {'totalRides': totalRides},
      );
      if (achievement != null) newlyUnlocked.add(achievement);
    }

    if (totalRides >= 25 && !unlockedTypes.contains(AchievementType.rides25)) {
      final achievement = await _unlockAchievement(
        familyId,
        userId,
        ride.memberName,
        AchievementType.rides25,
        metadata: {'totalRides': totalRides},
      );
      if (achievement != null) newlyUnlocked.add(achievement);
    }

    if (totalRides >= 100 && !unlockedTypes.contains(AchievementType.rides100)) {
      final achievement = await _unlockAchievement(
        familyId,
        userId,
        ride.memberName,
        AchievementType.rides100,
        metadata: {'totalRides': totalRides},
      );
      if (achievement != null) newlyUnlocked.add(achievement);
    }

    if (totalRides >= 500 && !unlockedTypes.contains(AchievementType.rides500)) {
      final achievement = await _unlockAchievement(
        familyId,
        userId,
        ride.memberName,
        AchievementType.rides500,
        metadata: {'totalRides': totalRides},
      );
      if (achievement != null) newlyUnlocked.add(achievement);
    }

    // Check speed achievement
    if (ride.maxSpeedKmh >= 40 && !unlockedTypes.contains(AchievementType.speedDemon)) {
      final achievement = await _unlockAchievement(
        familyId,
        userId,
        ride.memberName,
        AchievementType.speedDemon,
        metadata: {'maxSpeed': ride.maxSpeedKmh},
      );
      if (achievement != null) newlyUnlocked.add(achievement);
    }

    // Check time-based achievements
    final rideHour = ride.startTime.hour;
    if (rideHour < 7 && !unlockedTypes.contains(AchievementType.earlyBird)) {
      final achievement = await _unlockAchievement(
        familyId,
        userId,
        ride.memberName,
        AchievementType.earlyBird,
        metadata: {'startHour': rideHour},
      );
      if (achievement != null) newlyUnlocked.add(achievement);
    }

    if (rideHour >= 21 && !unlockedTypes.contains(AchievementType.nightOwl)) {
      final achievement = await _unlockAchievement(
        familyId,
        userId,
        ride.memberName,
        AchievementType.nightOwl,
        metadata: {'startHour': rideHour},
      );
      if (achievement != null) newlyUnlocked.add(achievement);
    }

    // Update member stats
    await _updateMemberStats(
      familyId,
      userId,
      ride.memberName,
      addDistance: ride.distanceKm,
      addRides: 1,
      addPoints: newlyUnlocked.fold(
        0,
        (total, a) => total + AchievementDefinitions.getDefinition(a.type).points,
      ),
      achievementCount: newlyUnlocked.length,
    );

    // Update challenges
    await _updateChallengesAfterRide(familyId, userId, ride);

    return newlyUnlocked;
  }

  /// Unlock an achievement
  Future<UnlockedAchievement?> _unlockAchievement(
    String familyId,
    String memberId,
    String memberName,
    AchievementType type, {
    Map<String, dynamic>? metadata,
  }) async {
    // Check if already unlocked
    final existing = await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('achievements')
        .where('memberId', isEqualTo: memberId)
        .where('type', isEqualTo: type.name)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return null;

    final now = DateTime.now();
    final achievement = UnlockedAchievement(
      id: '',
      memberId: memberId,
      memberName: memberName,
      type: type,
      unlockedAt: now,
      metadata: metadata,
    );

    final docRef = await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('achievements')
        .add(achievement.toFirestore());

    return UnlockedAchievement(
      id: docRef.id,
      memberId: memberId,
      memberName: memberName,
      type: type,
      unlockedAt: now,
      metadata: metadata,
    );
  }

  /// Get unlocked achievement types for a member
  Future<Set<AchievementType>> _getUnlockedAchievementTypes(
    String familyId,
    String memberId,
  ) async {
    final snapshot = await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('achievements')
        .where('memberId', isEqualTo: memberId)
        .get();

    return snapshot.docs
        .map((doc) {
          final typeStr = doc['type'] as String?;
          return AchievementType.values.firstWhere(
            (t) => t.name == typeStr,
            orElse: () => AchievementType.firstRide,
          );
        })
        .toSet();
  }

  /// Stream all achievements for a family
  Stream<List<UnlockedAchievement>> watchFamilyAchievements(String familyId) {
    return _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('achievements')
        .orderBy('unlockedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UnlockedAchievement.fromFirestore(doc))
            .toList());
  }

  /// Stream achievements for a specific member
  Stream<List<UnlockedAchievement>> watchMemberAchievements(
    String familyId,
    String memberId,
  ) {
    return _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('achievements')
        .where('memberId', isEqualTo: memberId)
        .orderBy('unlockedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UnlockedAchievement.fromFirestore(doc))
            .toList());
  }

  /// Get member achievements count
  Future<int> getMemberAchievementCount(String familyId, String memberId) async {
    final snapshot = await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('achievements')
        .where('memberId', isEqualTo: memberId)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  // ==========================================
  // Member Stats
  // ==========================================

  /// Get member gamification stats
  Future<MemberGamificationStats> getMemberStats(
    String familyId,
    String memberId,
  ) async {
    final doc = await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('memberStats')
        .doc(memberId)
        .get();

    if (!doc.exists) {
      return MemberGamificationStats(
        memberId: memberId,
        memberName: 'Unknown',
        totalPoints: 0,
        achievementCount: 0,
        currentStreak: 0,
        longestStreak: 0,
        totalDistanceKm: 0,
        totalRides: 0,
        challengesCompleted: 0,
        level: 1,
      );
    }

    return MemberGamificationStats.fromFirestore(doc);
  }

  /// Update member stats
  Future<void> _updateMemberStats(
    String familyId,
    String memberId,
    String memberName, {
    double addDistance = 0,
    int addRides = 0,
    int addPoints = 0,
    int achievementCount = 0,
    int challengesCompleted = 0,
  }) async {
    final docRef = _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('memberStats')
        .doc(memberId);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);

      if (!doc.exists) {
        final newStats = MemberGamificationStats(
          memberId: memberId,
          memberName: memberName,
          totalPoints: addPoints,
          achievementCount: achievementCount,
          currentStreak: addRides > 0 ? 1 : 0,
          longestStreak: addRides > 0 ? 1 : 0,
          totalDistanceKm: addDistance,
          totalRides: addRides,
          challengesCompleted: challengesCompleted,
          level: MemberGamificationStats.calculateLevel(addPoints),
        );
        transaction.set(docRef, newStats.toFirestore());
        return;
      }

      final current = MemberGamificationStats.fromFirestore(doc);
      final newPoints = current.totalPoints + addPoints;

      transaction.update(docRef, {
        'memberName': memberName,
        'totalPoints': FieldValue.increment(addPoints),
        'achievementCount': FieldValue.increment(achievementCount),
        'totalDistanceKm': FieldValue.increment(addDistance),
        'totalRides': FieldValue.increment(addRides),
        'challengesCompleted': FieldValue.increment(challengesCompleted),
        'level': MemberGamificationStats.calculateLevel(newPoints),
      });
    });
  }

  /// Stream member stats
  Stream<MemberGamificationStats?> watchMemberStats(
    String familyId,
    String memberId,
  ) {
    return _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('memberStats')
        .doc(memberId)
        .snapshots()
        .map((doc) => doc.exists ? MemberGamificationStats.fromFirestore(doc) : null);
  }

  /// Stream all members' stats
  Stream<List<MemberGamificationStats>> watchFamilyStats(String familyId) {
    return _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('memberStats')
        .orderBy('totalPoints', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MemberGamificationStats.fromFirestore(doc))
            .toList());
  }

  // ==========================================
  // Streak Management
  // ==========================================

  /// Update riding streak
  Future<void> updateStreak(String familyId, String memberId) async {
    final docRef = _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('memberStats')
        .doc(memberId);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);

      if (!doc.exists) return;

      final data = doc.data()!;
      final lastRideDate = (data['lastRideDate'] as Timestamp?)?.toDate();

      int currentStreak = data['currentStreak'] ?? 0;
      int longestStreak = data['longestStreak'] ?? 0;

      if (lastRideDate != null) {
        final lastRideDay = DateTime(
          lastRideDate.year,
          lastRideDate.month,
          lastRideDate.day,
        );
        final daysDiff = today.difference(lastRideDay).inDays;

        if (daysDiff == 1) {
          // Consecutive day - increase streak
          currentStreak++;
        } else if (daysDiff > 1) {
          // Streak broken - reset
          currentStreak = 1;
        }
        // daysDiff == 0 means same day, no change to streak

        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
      } else {
        currentStreak = 1;
        longestStreak = 1;
      }

      transaction.update(docRef, {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastRideDate': Timestamp.fromDate(today),
      });

      // Check streak achievements
      final userId = memberId;
      final memberName = data['memberName'] ?? 'Unknown';
      final unlockedTypes = await _getUnlockedAchievementTypes(familyId, userId);

      if (currentStreak >= 3 && !unlockedTypes.contains(AchievementType.streak3days)) {
        await _unlockAchievement(familyId, userId, memberName, AchievementType.streak3days);
      }
      if (currentStreak >= 7 && !unlockedTypes.contains(AchievementType.streak7days)) {
        await _unlockAchievement(familyId, userId, memberName, AchievementType.streak7days);
      }
      if (currentStreak >= 30 && !unlockedTypes.contains(AchievementType.streak30days)) {
        await _unlockAchievement(familyId, userId, memberName, AchievementType.streak30days);
      }
      if (currentStreak >= 100 && !unlockedTypes.contains(AchievementType.streak100days)) {
        await _unlockAchievement(familyId, userId, memberName, AchievementType.streak100days);
      }
    });
  }

  // ==========================================
  // Challenge Management
  // ==========================================

  /// Create a new family challenge
  Future<String> createChallenge(FamilyChallenge challenge) async {
    final docRef = await _firestore
        .collection('familyAccounts')
        .doc(challenge.familyId)
        .collection('challenges')
        .add(challenge.toFirestore());

    return docRef.id;
  }

  /// Update challenge progress after a ride
  Future<void> _updateChallengesAfterRide(
    String familyId,
    String memberId,
    FamilyRide ride,
  ) async {
    final snapshot = await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('challenges')
        .where('status', isEqualTo: ChallengeStatus.active.name)
        .get();

    for (final doc in snapshot.docs) {
      final challenge = FamilyChallenge.fromFirestore(doc);

      if (challenge.isExpired) {
        // Mark as failed if expired
        await doc.reference.update({'status': ChallengeStatus.failed.name});
        continue;
      }

      double addValue = 0;
      switch (challenge.type) {
        case ChallengeType.totalDistance:
        case ChallengeType.weeklyDistance:
        case ChallengeType.memberDistance:
          addValue = ride.distanceKm;
          break;
        case ChallengeType.totalRides:
          addValue = 1;
          break;
        case ChallengeType.dailyStreak:
          // Handle separately in streak logic
          continue;
      }

      if (addValue > 0) {
        final newProgress = Map<String, double>.from(challenge.memberProgress);
        newProgress[memberId] = (newProgress[memberId] ?? 0) + addValue;

        final newCurrentValue = challenge.currentValue + addValue;
        final isCompleted = newCurrentValue >= challenge.targetValue;

        await doc.reference.update({
          'currentValue': newCurrentValue,
          'memberProgress': newProgress,
          if (!challenge.participantIds.contains(memberId))
            'participantIds': FieldValue.arrayUnion([memberId]),
          if (isCompleted) 'status': ChallengeStatus.completed.name,
        });

        // Award points for completing challenge
        if (isCompleted) {
          for (final participantId in challenge.participantIds) {
            await _updateMemberStats(
              familyId,
              participantId,
              '',
              addPoints: challenge.rewardPoints,
              challengesCompleted: 1,
            );
          }
        }
      }
    }
  }

  /// Stream active challenges
  Stream<List<FamilyChallenge>> watchActiveChallenges(String familyId) {
    return _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('challenges')
        .where('status', isEqualTo: ChallengeStatus.active.name)
        .orderBy('endDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FamilyChallenge.fromFirestore(doc))
            .toList());
  }

  /// Stream all challenges
  Stream<List<FamilyChallenge>> watchAllChallenges(String familyId) {
    return _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('challenges')
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FamilyChallenge.fromFirestore(doc))
            .toList());
  }

  /// Delete a challenge
  Future<void> deleteChallenge(String familyId, String challengeId) async {
    await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('challenges')
        .doc(challengeId)
        .delete();
  }

  /// Check safety achievement
  Future<void> checkSafetyAchievement(String familyId, String memberId, String memberName) async {
    final unlockedTypes = await _getUnlockedAchievementTypes(familyId, memberId);

    // Check if safe zones exist (for safetyFirst achievement)
    if (!unlockedTypes.contains(AchievementType.safetyFirst)) {
      final zones = await _firestore
          .collection('familyAccounts')
          .doc(familyId)
          .collection('safeZones')
          .limit(1)
          .get();

      if (zones.docs.isNotEmpty) {
        await _unlockAchievement(familyId, memberId, memberName, AchievementType.safetyFirst);
      }
    }
  }

  /// Check alert resolution achievement
  Future<void> checkAlertResolutionAchievement(
    String familyId,
    String memberId,
    String memberName,
  ) async {
    final unlockedTypes = await _getUnlockedAchievementTypes(familyId, memberId);

    if (!unlockedTypes.contains(AchievementType.helpingHand)) {
      final resolvedAlerts = await _firestore
          .collection('familyAccounts')
          .doc(familyId)
          .collection('alerts')
          .where('resolvedBy', isEqualTo: memberId)
          .count()
          .get();

      if ((resolvedAlerts.count ?? 0) >= 10) {
        await _unlockAchievement(familyId, memberId, memberName, AchievementType.helpingHand);
      }
    }
  }
}

// ==========================================
// Providers
// ==========================================

final familyGamificationServiceProvider = Provider<FamilyGamificationService>((ref) {
  return FamilyGamificationService();
});

/// Watch family achievements
final familyAchievementsProvider =
    StreamProvider.family<List<UnlockedAchievement>, String>((ref, familyId) {
  final service = ref.watch(familyGamificationServiceProvider);
  return service.watchFamilyAchievements(familyId);
});

/// Watch member achievements
final memberAchievementsProvider = StreamProvider.family<
    List<UnlockedAchievement>,
    ({String familyId, String memberId})>((ref, params) {
  final service = ref.watch(familyGamificationServiceProvider);
  return service.watchMemberAchievements(params.familyId, params.memberId);
});

/// Watch member stats
final memberGamificationStatsProvider =
    StreamProvider.family<MemberGamificationStats?, ({String familyId, String memberId})>(
        (ref, params) {
  final service = ref.watch(familyGamificationServiceProvider);
  return service.watchMemberStats(params.familyId, params.memberId);
});

/// Watch family stats leaderboard
final familyGamificationStatsProvider =
    StreamProvider.family<List<MemberGamificationStats>, String>((ref, familyId) {
  final service = ref.watch(familyGamificationServiceProvider);
  return service.watchFamilyStats(familyId);
});

/// Watch active challenges
final activeChallengesProvider =
    StreamProvider.family<List<FamilyChallenge>, String>((ref, familyId) {
  final service = ref.watch(familyGamificationServiceProvider);
  return service.watchActiveChallenges(familyId);
});

/// Watch all challenges
final allChallengesProvider =
    StreamProvider.family<List<FamilyChallenge>, String>((ref, familyId) {
  final service = ref.watch(familyGamificationServiceProvider);
  return service.watchAllChallenges(familyId);
});
