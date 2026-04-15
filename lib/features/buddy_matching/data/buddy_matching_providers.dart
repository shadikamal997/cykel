/// CYKEL — Buddy Matching Providers
/// Riverpod providers for buddy matching features

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/buddy_matching_service.dart';
import '../domain/buddy_profile.dart';

// ─── Service Provider ────────────────────────────────────────────────────────

final buddyMatchingServiceProvider = Provider<BuddyMatchingService>((ref) {
  return BuddyMatchingService(FirebaseFirestore.instance);
});

// ─── Current User's Buddy Profile ────────────────────────────────────────────

final currentBuddyProfileProvider = StreamProvider<BuddyProfile?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('buddyProfiles')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    return BuddyProfile.fromFirestore(doc);
  });
});

// ─── Buddy Matches (Suggested) ───────────────────────────────────────────────

final suggestedBuddiesProvider = FutureProvider.family<List<BuddyProfile>, int>((ref, limit) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final buddyProfile = await ref.watch(currentBuddyProfileProvider.future);
  if (buddyProfile == null) return [];

  final service = ref.watch(buddyMatchingServiceProvider);
  return service.findMatches(
    currentUserId: user.uid,
    currentUserProfile: buddyProfile,
    limit: limit,
  );
});

// ─── Buddy Matches (Accepted) ────────────────────────────────────────────────

final acceptedMatchesProvider = StreamProvider<List<BuddyMatch>>((ref) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield [];
    return;
  }

  final service = ref.watch(buddyMatchingServiceProvider);
  
  // This would ideally be a real-time stream
  // For now, we'll poll periodically
  while (true) {
    try {
      final matches = await service.getMatches(user.uid);
      yield matches;
    } catch (e) {
      yield [];
    }
    await Future.delayed(const Duration(seconds: 30));
  }
});

// ─── Pending Match Requests ──────────────────────────────────────────────────

final pendingRequestsProvider = StreamProvider<List<BuddyMatch>>((ref) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield [];
    return;
  }

  final service = ref.watch(buddyMatchingServiceProvider);
  
  while (true) {
    try {
      final requests = await service.getPendingRequests(user.uid);
      yield requests;
    } catch (e) {
      yield [];
    }
    await Future.delayed(const Duration(seconds: 15));
  }
});

// ─── Sent Match Requests ─────────────────────────────────────────────────────

final sentRequestsProvider = FutureProvider<List<BuddyMatch>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final service = ref.watch(buddyMatchingServiceProvider);
  return service.getSentRequests(user.uid);
});

// ─── Buddy Profile by ID ─────────────────────────────────────────────────────

final buddyProfileProvider = FutureProvider.family<BuddyProfile?, String>((ref, userId) async {
  final service = ref.watch(buddyMatchingServiceProvider);
  return service.getBuddyProfile(userId);
});

// ─── Find Buddies by Interest ────────────────────────────────────────────────

final buddiesByInterestProvider = FutureProvider.family<List<BuddyProfile>, List<RidingInterest>>((ref, interests) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final service = ref.watch(buddyMatchingServiceProvider);
  return service.findByInterests(
    currentUserId: user.uid,
    interests: interests,
  );
});

// ─── Find Buddies by Level ───────────────────────────────────────────────────

final buddiesByLevelProvider = FutureProvider.family<List<BuddyProfile>, RidingLevel>((ref, level) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final service = ref.watch(buddyMatchingServiceProvider);
  return service.findByLevel(
    currentUserId: user.uid,
    level: level,
  );
});
