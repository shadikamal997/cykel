/// CYKEL — Buddy Matching Service
/// Interest-based algorithm for finding compatible riding partners

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../domain/buddy_profile.dart';

class BuddyMatchingService {
  BuddyMatchingService(this._firestore);

  final FirebaseFirestore _firestore;

  /// Find compatible buddies for the given user
  Future<List<BuddyProfile>> findMatches({
    required String currentUserId,
    required BuddyProfile currentUserProfile,
    LatLng? currentLocation,
    int limit = 20,
  }) async {
    try {
      // Get all active buddy profiles except current user
      final querySnapshot = await _firestore
          .collection('buddyProfiles')
          .where('isActive', isEqualTo: true)
          .where(FieldPath.documentId, isNotEqualTo: currentUserId)
          .limit(20) // Reduced for faster initial load
          .get();

      final candidates = querySnapshot.docs
          .map((doc) => BuddyProfile.fromFirestore(doc))
          .toList();

      // Filter by mutual preference matching
      final compatibleCandidates = candidates.where((candidate) {
        return currentUserProfile.matchesPreferences(candidate) &&
               candidate.matchesPreferences(currentUserProfile);
      }).toList();

      // Calculate compatibility scores and sort
      final scoredMatches = compatibleCandidates.map((candidate) {
        final score = currentUserProfile.calculateCompatibility(candidate);
        return _ScoredMatch(profile: candidate, score: score);
      }).toList()
        ..sort((a, b) => b.score.compareTo(a.score));

      // Return top matches
      return scoredMatches
          .take(limit)
          .map((match) => match.profile)
          .toList();
    } catch (e) {
      throw Exception('Failed to find matches: $e');
    }
  }

  /// Find buddies with specific interests
  Future<List<BuddyProfile>> findByInterests({
    required String currentUserId,
    required List<RidingInterest> interests,
    int limit = 20,
  }) async {
    try {
      if (interests.isEmpty) {
        return findAllActiveBuddies(currentUserId: currentUserId, limit: limit);
      }

      final interestNames = interests.map((i) => i.name).toList();

      final querySnapshot = await _firestore
          .collection('buddyProfiles')
          .where('isActive', isEqualTo: true)
          .where('interests', arrayContainsAny: interestNames)
          .where(FieldPath.documentId, isNotEqualTo: currentUserId)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => BuddyProfile.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to find buddies by interests: $e');
    }
  }

  /// Find buddies by riding level
  Future<List<BuddyProfile>> findByLevel({
    required String currentUserId,
    required RidingLevel level,
    int limit = 20,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('buddyProfiles')
          .where('isActive', isEqualTo: true)
          .where('ridingLevel', isEqualTo: level.name)
          .where(FieldPath.documentId, isNotEqualTo: currentUserId)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => BuddyProfile.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to find buddies by level: $e');
    }
  }

  /// Find all active buddies (for browsing)
  Future<List<BuddyProfile>> findAllActiveBuddies({
    required String currentUserId,
    int limit = 20,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('buddyProfiles')
          .where('isActive', isEqualTo: true)
          .where(FieldPath.documentId, isNotEqualTo: currentUserId)
          .orderBy('lastActiveAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => BuddyProfile.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to find active buddies: $e');
    }
  }

  /// Get or create buddy profile for user
  Future<BuddyProfile?> getBuddyProfile(String userId) async {
    try {
      final doc = await _firestore.collection('buddyProfiles').doc(userId).get();
      if (!doc.exists) return null;
      return BuddyProfile.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get buddy profile: $e');
    }
  }

  /// Create or update buddy profile
  Future<void> saveBuddyProfile(BuddyProfile profile) async {
    try {
      await _firestore
          .collection('buddyProfiles')
          .doc(profile.userId)
          .set(profile.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save buddy profile: $e');
    }
  }

  /// Create or update buddy profile with individual parameters
  Future<void> createOrUpdateProfile({
    required String userId,
    required String displayName,
    String? bio,
    String? photoUrl,
    String? hometown,
    required RidingLevel ridingLevel,
    required List<RidingInterest> interests,
    required List<RideAvailability> availability,
    List<String> spokenLanguages = const [],
    double? averagePaceKmh,
  }) async {
    try {
      // Get existing profile to preserve some data if updating
      final existingProfile = await getBuddyProfile(userId);

      final profile = BuddyProfile(
        userId: userId,
        displayName: displayName,
        bio: bio,
        photoUrl: photoUrl,
        hometown: hometown,
        ridingLevel: ridingLevel,
        interests: interests,
        availability: availability,
        spokenLanguages: spokenLanguages,
        averagePaceKmh: averagePaceKmh,
        totalRides: existingProfile?.totalRides ?? 0,
        totalDistanceKm: existingProfile?.totalDistanceKm ?? 0.0,
        preferences: existingProfile?.preferences ?? const BuddyPreferences(),
        verifiedRider: existingProfile?.verifiedRider ?? false,
        createdAt: existingProfile?.createdAt ?? DateTime.now(),
        lastActiveAt: DateTime.now(),
        isActive: true,
      );

      await saveBuddyProfile(profile);
    } catch (e) {
      throw Exception('Failed to create/update buddy profile: $e');
    }
  }

  /// Send buddy match request
  Future<BuddyMatch> sendMatchRequest({
    required String fromUserId,
    required String toUserId,
    required int compatibilityScore,
  }) async {
    try {
      // Check for existing match
      final existingMatch = await _findExistingMatch(fromUserId, toUserId);
      if (existingMatch != null) {
        throw Exception('Match request already exists');
      }

      // Create new match
      final match = BuddyMatch(
        id: '', // Will be set by Firestore
        userId1: fromUserId,
        userId2: toUserId,
        status: BuddyMatchStatus.pending,
        createdAt: DateTime.now(),
        compatibilityScore: compatibilityScore,
      );

      final docRef = await _firestore
          .collection('buddyMatches')
          .add(match.toFirestore());

      // Return match with generated ID
      final doc = await docRef.get();
      return BuddyMatch.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to send match request: $e');
    }
  }

  /// Accept buddy match request
  Future<void> acceptMatchRequest(String matchId) async {
    try {
      await _firestore.collection('buddyMatches').doc(matchId).update({
        'status': BuddyMatchStatus.accepted.name,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to accept match request: $e');
    }
  }

  /// Decline buddy match request
  Future<void> declineMatchRequest(String matchId) async {
    try {
      await _firestore.collection('buddyMatches').doc(matchId).update({
        'status': BuddyMatchStatus.declined.name,
      });
    } catch (e) {
      throw Exception('Failed to decline match request: $e');
    }
  }

  /// Block a user
  Future<void> blockUser(String matchId) async {
    try {
      await _firestore.collection('buddyMatches').doc(matchId).update({
        'status': BuddyMatchStatus.blocked.name,
      });
    } catch (e) {
      throw Exception('Failed to block user: $e');
    }
  }

  /// Get all matches for a user
  Future<List<BuddyMatch>> getMatches(String userId) async {
    try {
      final query1 = await _firestore
          .collection('buddyMatches')
          .where('userId1', isEqualTo: userId)
          .where('status', isEqualTo: BuddyMatchStatus.accepted.name)
          .get();

      final query2 = await _firestore
          .collection('buddyMatches')
          .where('userId2', isEqualTo: userId)
          .where('status', isEqualTo: BuddyMatchStatus.accepted.name)
          .get();

      final allDocs = [...query1.docs, ...query2.docs];
      return allDocs.map((doc) => BuddyMatch.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get matches: $e');
    }
  }

  /// Get pending match requests for a user
  Future<List<BuddyMatch>> getPendingRequests(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('buddyMatches')
          .where('userId2', isEqualTo: userId)
          .where('status', isEqualTo: BuddyMatchStatus.pending.name)
          .orderBy('createdAt', descending: true)
          .limit(100)  // Limit pending match requests
          .get();

      return querySnapshot.docs
          .map((doc) => BuddyMatch.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending requests: $e');
    }
  }

  /// Get sent match requests
  Future<List<BuddyMatch>> getSentRequests(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('buddyMatches')
          .where('userId1', isEqualTo: userId)
          .where('status', isEqualTo: BuddyMatchStatus.pending.name)
          .orderBy('createdAt', descending: true)
          .limit(100)  // Limit sent match requests
          .get();

      return querySnapshot.docs
          .map((doc) => BuddyMatch.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get sent requests: $e');
    }
  }

  /// Update last active timestamp
  Future<void> updateLastActive(String userId) async {
    try {
      await _firestore.collection('buddyProfiles').doc(userId).update({
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update last active: $e');
    }
  }

  /// Increment rides together counter
  Future<void> incrementRidesTogether(String matchId) async {
    try {
      await _firestore.collection('buddyMatches').doc(matchId).update({
        'totalRidesTogether': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to increment rides together: $e');
    }
  }

  /// Helper: Find existing match between two users
  Future<BuddyMatch?> _findExistingMatch(String userId1, String userId2) async {
    // Check both directions
    final query1 = await _firestore
        .collection('buddyMatches')
        .where('userId1', isEqualTo: userId1)
        .where('userId2', isEqualTo: userId2)
        .limit(1)
        .get();

    if (query1.docs.isNotEmpty) {
      return BuddyMatch.fromFirestore(query1.docs.first);
    }

    final query2 = await _firestore
        .collection('buddyMatches')
        .where('userId1', isEqualTo: userId2)
        .where('userId2', isEqualTo: userId1)
        .limit(1)
        .get();

    if (query2.docs.isNotEmpty) {
      return BuddyMatch.fromFirestore(query2.docs.first);
    }

    return null;
  }

  // Future use: Calculate distance between two locations
  // double _calculateDistance(LatLng point1, LatLng point2) {
  //   return Geolocator.distanceBetween(
  //     point1.latitude,
  //     point1.longitude,
  //     point2.latitude,
  //     point2.longitude,
  //   ) / 1000; // Convert to km
  // }
}

/// Helper class for scoring matches
class _ScoredMatch {
  const _ScoredMatch({
    required this.profile,
    required this.score,
  });

  final BuddyProfile profile;
  final int score;
}
