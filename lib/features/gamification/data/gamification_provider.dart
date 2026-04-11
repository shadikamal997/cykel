/// CYKEL — Gamification Provider
/// Manages challenges, badges, leaderboards, and user stats

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../domain/gamification.dart';

// ─── Gamification Service ─────────────────────────────────────────────────────

class GamificationService {
  final _firestore = FirebaseFirestore.instance;

  // ─── Challenges ─────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _challengesCol =>
      _firestore.collection('challenges');

  CollectionReference<Map<String, dynamic>> _userChallengesCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('challenges');

  /// Get all active challenges
  Stream<List<Challenge>> watchActiveChallenges() {
    return _challengesCol
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map(Challenge.fromFirestore).toList());
  }

  /// Get featured challenges
  Stream<List<Challenge>> watchFeaturedChallenges() {
    return _challengesCol
        .where('isActive', isEqualTo: true)
        .where('isFeatured', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map(Challenge.fromFirestore).toList());
  }

  /// Get user's active challenge progress
  Stream<List<ChallengeProgress>> watchUserProgress(String uid) {
    return _userChallengesCol(uid)
        .where('completedAt', isNull: true)
        .snapshots()
        .map((s) => s.docs.map(ChallengeProgress.fromFirestore).toList());
  }

  /// Get user's completed challenges
  Stream<List<ChallengeProgress>> watchCompletedChallenges(String uid) {
    return _userChallengesCol(uid)
        .where('completedAt', isNull: false)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ChallengeProgress.fromFirestore).toList());
  }

  /// Start a challenge for user
  Future<void> startChallenge(String uid, String challengeId) async {
    try {
      // Check if already started
      final existing = await _userChallengesCol(uid)
          .where('challengeId', isEqualTo: challengeId)
          .limit(1)
          .get();
      
      if (existing.docs.isNotEmpty) {
        throw Exception('Challenge already started');
      }

      await _userChallengesCol(uid).add({
        'challengeId': challengeId,
        'userId': uid,
        'currentValue': 0,
        'startedAt': FieldValue.serverTimestamp(),
        'completedAt': null,
      });
    } catch (e) {
      debugPrint('[Gamification] Error starting challenge: $e');
      rethrow;
    }
  }

  /// Update progress for a challenge
  Future<void> updateProgress(
    String uid, 
    String progressId, 
    double newValue, {
    bool markComplete = false,
  }) async {
    try {
      final updates = <String, dynamic>{
        'currentValue': newValue,
      };
      if (markComplete) {
        updates['completedAt'] = FieldValue.serverTimestamp();
      }
      await _userChallengesCol(uid).doc(progressId).update(updates);
    } catch (e) {
      debugPrint('[Gamification] Error updating progress: $e');
      rethrow;
    }
  }

  // ─── Badges ─────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _badgesCol =>
      _firestore.collection('badges');

  CollectionReference<Map<String, dynamic>> _userBadgesCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('badges');

  /// Get all badges
  Stream<List<Badge>> watchAllBadges() {
    return _badgesCol.snapshots()
        .map((s) => s.docs.map(Badge.fromFirestore).toList());
  }

  /// Get user's earned badges
  Stream<List<UserBadge>> watchUserBadges(String uid) {
    return _userBadgesCol(uid)
        .orderBy('earnedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(UserBadge.fromFirestore).toList());
  }

  /// Award a badge to user
  Future<void> awardBadge(String uid, String badgeId) async {
    try {
      // Check if already awarded
      final existing = await _userBadgesCol(uid)
          .where('badgeId', isEqualTo: badgeId)
          .limit(1)
          .get();
      
      if (existing.docs.isNotEmpty) {
        return; // Already has badge
      }

      await _userBadgesCol(uid).add({
        'badgeId': badgeId,
        'userId': uid,
        'earnedAt': FieldValue.serverTimestamp(),
      });

      // Update badge count in stats
      await _updateStats(uid, {'badgeCount': FieldValue.increment(1)});
    } catch (e) {
      debugPrint('[Gamification] Error awarding badge: $e');
      rethrow;
    }
  }

  // ─── User Stats ─────────────────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _statsDoc(String uid) =>
      _firestore.collection('users').doc(uid).collection('gamification').doc('stats');

  /// Get user stats
  Stream<UserStats> watchUserStats(String uid) {
    return _statsDoc(uid).snapshots().map((doc) {
      if (!doc.exists) {
        return UserStats(userId: uid);
      }
      return UserStats.fromFirestore(doc);
    });
  }

  /// Update user stats
  Future<void> _updateStats(String uid, Map<String, dynamic> updates) async {
    try {
      await _statsDoc(uid).set(updates, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Gamification] Error updating stats: $e');
      rethrow;
    }
  }

  /// Record a completed ride and update stats
  Future<void> recordRide({
    required String uid,
    required double distanceKm,
    required int durationMinutes,
    required double elevationM,
    required DateTime rideDate,
  }) async {
    try {
      // Get current stats
      final statsDoc = await _statsDoc(uid).get();
      final existingStats = statsDoc.exists 
          ? UserStats.fromFirestore(statsDoc)
          : UserStats(userId: uid);

      // Calculate streak
      final isConsecutiveDay = existingStats.currentStreak > 0;
      // Simple streak logic - in production, check actual last ride date
      final newStreak = isConsecutiveDay 
          ? existingStats.currentStreak + 1 
          : 1;
      final newLongestStreak = newStreak > existingStats.longestStreak 
          ? newStreak 
          : existingStats.longestStreak;

      // Calculate points (10 points per km + 1 point per minute + 0.1 per m elevation)
      final ridePoints = (distanceKm * 10 + durationMinutes + elevationM * 0.1).round();

      // Calculate level from total points
      final newTotalPoints = existingStats.totalPoints + ridePoints;
      final newLevel = (newTotalPoints ~/ 500) + 1;

      await _updateStats(uid, {
        'userId': uid,
        'totalDistanceKm': FieldValue.increment(distanceKm),
        'totalRides': FieldValue.increment(1),
        'totalDurationMinutes': FieldValue.increment(durationMinutes),
        'totalElevationM': FieldValue.increment(elevationM),
        'currentStreak': newStreak,
        'longestStreak': newLongestStreak,
        'totalPoints': FieldValue.increment(ridePoints),
        'level': newLevel,
        'lastRideDate': Timestamp.fromDate(rideDate),
      });

      // Update challenge progress
      await _updateChallengeProgress(
        uid,
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        elevationM: elevationM,
        newStreak: newStreak,
        totalDistance: existingStats.totalDistanceKm + distanceKm,
        totalRides: existingStats.totalRides + 1,
        totalElevation: existingStats.totalElevationM + elevationM,
      );
    } catch (e) {
      debugPrint('[Gamification] Error recording ride: $e');
      rethrow;
    }
  }

  /// Update challenge progress after a ride
  Future<void> _updateChallengeProgress(
    String uid, {
    required double distanceKm,
    required int durationMinutes,
    required double elevationM,
    required int newStreak,
    required double totalDistance,
    required int totalRides,
    required double totalElevation,
  }) async {
    try {
      // Get user's active challenges
      final activeChallenges = await _userChallengesCol(uid)
          .where('completedAt', isNull: true)
          .get();

      // Get all challenge definitions
      final challengeDocs = await _challengesCol.get();
      final challenges = Map.fromEntries(
        challengeDocs.docs.map((d) => MapEntry(d.id, Challenge.fromFirestore(d))),
      );

      for (final progressDoc in activeChallenges.docs) {
        final progress = ChallengeProgress.fromFirestore(progressDoc);
        final challenge = challenges[progress.challengeId];
        if (challenge == null) continue;

        double newValue = progress.currentValue;

        // Update value based on challenge type
        switch (challenge.type) {
          case ChallengeType.distance:
            // Check if single ride or cumulative
            if (challenge.id.contains('total')) {
              newValue = totalDistance;
            } else {
              // Single ride challenge - only update if this ride beats it
              if (distanceKm > newValue) {
                newValue = distanceKm;
              }
            }
            break;
          case ChallengeType.rides:
            newValue = totalRides.toDouble();
            break;
          case ChallengeType.streak:
            newValue = newStreak.toDouble();
            break;
          case ChallengeType.duration:
            newValue += durationMinutes;
            break;
          case ChallengeType.elevation:
            newValue = totalElevation;
            break;
          case ChallengeType.speed:
            // Calculate average speed for this ride
            if (durationMinutes > 0) {
              final avgSpeed = distanceKm / (durationMinutes / 60);
              if (avgSpeed > newValue) {
                newValue = avgSpeed;
              }
            }
            break;
          case ChallengeType.community:
            // Community challenges handled separately
            break;
        }

        // Check if completed
        final isCompleted = newValue >= challenge.targetValue;
        
        await updateProgress(uid, progress.id, newValue, markComplete: isCompleted);

        // Award badge if challenge completed and has badge
        if (isCompleted && challenge.badgeId != null) {
          await awardBadge(uid, challenge.badgeId!);
          await _updateStats(uid, {
            'challengesCompleted': FieldValue.increment(1),
          });
        }
      }
    } catch (e) {
      debugPrint('[Gamification] Error updating challenge progress: $e');
    }
  }

  // ─── Leaderboards ───────────────────────────────────────────────────────────

  /// Get leaderboard entries
  Future<List<LeaderboardEntry>> getLeaderboard({
    required LeaderboardCategory category,
    required LeaderboardPeriod period,
    int limit = 50,
    String? currentUserId,
  }) async {
    try {
      // In production, you'd use Cloud Functions to aggregate this efficiently
      // For now, we query the stats directly
      
      String field;
      switch (category) {
        case LeaderboardCategory.distance:
          field = 'totalDistanceKm';
          break;
        case LeaderboardCategory.rides:
          field = 'totalRides';
          break;
        case LeaderboardCategory.points:
          field = 'totalPoints';
          break;
        case LeaderboardCategory.elevation:
          field = 'totalElevationM';
          break;
        case LeaderboardCategory.streak:
          field = 'longestStreak';
          break;
      }

      // Get all users' stats from the dedicated stats collection
      // Note: We query the user's stats sub-collection directly
      final Query<Map<String, dynamic>> query = _firestore
          .collectionGroup('gamification')
          .orderBy(field, descending: true)
          .limit(limit);

      final snapshot = await query.get();
      
      final entries = <LeaderboardEntry>[];
      var rank = 1;
      for (final doc in snapshot.docs) {
        // Skip documents that aren't stats documents
        if (doc.id != 'stats') continue;
        
        final data = doc.data();
        // Get user info from parent
        final uid = doc.reference.parent.parent?.id ?? '';
        final userDoc = await _firestore.collection('users').doc(uid).get();
        final userData = userDoc.data() ?? {};
        
        entries.add(LeaderboardEntry(
          userId: uid,
          displayName: userData['displayName'] as String? ?? 'Cyklist',
          rank: rank++,
          value: (data[field] as num?)?.toDouble() ?? 0,
          photoUrl: userData['photoUrl'] as String?,
          isCurrentUser: uid == currentUserId,
        ));
      }

      return entries;
    } catch (e) {
      debugPrint('[Gamification] Error getting leaderboard: $e');
      return [];
    }
  }

  /// Initialize default challenges and badges in Firestore
  Future<void> initializeDefaults() async {
    try {
      // Add default challenges if they don't exist
      for (final challenge in defaultChallenges) {
        final doc = await _challengesCol.doc(challenge.id).get();
        if (!doc.exists) {
          await _challengesCol.doc(challenge.id).set(challenge.toJson());
        }
      }

      // Add default badges if they don't exist
      for (final badge in defaultBadges) {
        final doc = await _badgesCol.doc(badge.id).get();
        if (!doc.exists) {
          await _badgesCol.doc(badge.id).set(badge.toJson());
        }
      }
    } catch (e) {
      debugPrint('[Gamification] Error initializing defaults: $e');
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

/// Gamification service provider
final gamificationServiceProvider = Provider<GamificationService>((ref) {
  return GamificationService();
});

/// Active challenges provider
final activeChallengesProvider = StreamProvider<List<Challenge>>((ref) {
  return ref.watch(gamificationServiceProvider).watchActiveChallenges();
});

/// Featured challenges provider
final featuredChallengesProvider = StreamProvider<List<Challenge>>((ref) {
  return ref.watch(gamificationServiceProvider).watchFeaturedChallenges();
});

/// User's challenge progress provider
final userChallengeProgressProvider = StreamProvider<List<ChallengeProgress>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(gamificationServiceProvider).watchUserProgress(user.uid);
});

/// User's completed challenges provider
final completedChallengesProvider = StreamProvider<List<ChallengeProgress>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(gamificationServiceProvider).watchCompletedChallenges(user.uid);
});

/// All badges provider
final allBadgesProvider = StreamProvider<List<Badge>>((ref) {
  return ref.watch(gamificationServiceProvider).watchAllBadges();
});

/// User's badges provider
final userBadgesProvider = StreamProvider<List<UserBadge>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(gamificationServiceProvider).watchUserBadges(user.uid);
});

/// User stats provider
final userStatsProvider = StreamProvider<UserStats>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const UserStats(userId: ''));
  return ref.watch(gamificationServiceProvider).watchUserStats(user.uid);
});

/// Leaderboard provider (async, not a stream)
final leaderboardProvider = FutureProvider.family<List<LeaderboardEntry>, ({LeaderboardCategory category, LeaderboardPeriod period})>((ref, params) {
  final user = ref.watch(currentUserProvider);
  return ref.watch(gamificationServiceProvider).getLeaderboard(
    category: params.category,
    period: params.period,
    currentUserId: user?.uid,
  );
});
