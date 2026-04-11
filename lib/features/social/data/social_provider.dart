/// CYKEL — Social Feature Provider
/// Friends, ride sharing, and social activities

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../domain/social.dart';

// ─── Social Service ───────────────────────────────────────────────────────────

class SocialService {
  SocialService(this._firestore);

  final FirebaseFirestore _firestore;

  // ─── Friends ────────────────────────────────────────────────────────────────

  /// Get user's friends list
  Stream<List<Friend>> watchFriends(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('friends')
        .orderBy('friendsSince', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Friend.fromFirestore).toList());
  }

  /// Send friend request
  Future<void> sendFriendRequest({
    required String fromUid,
    required String fromDisplayName,
    required String? fromPhotoUrl,
    required String toUid,
    required String toDisplayName,
    required String? toPhotoUrl,
  }) async {
    // Check if already friends
    final existing = await _firestore
        .collection('users')
        .doc(fromUid)
        .collection('friends')
        .doc(toUid)
        .get();

    if (existing.exists) {
      throw Exception('Allerede venner');
    }

    // Check if request already exists
    final pendingQuery = await _firestore
        .collection('friendRequests')
        .where('fromUid', isEqualTo: fromUid)
        .where('toUid', isEqualTo: toUid)
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .get();

    if (pendingQuery.docs.isNotEmpty) {
      throw Exception('Anmodning allerede sendt');
    }

    // Create request
    final request = FriendRequest(
      id: '',
      fromUid: fromUid,
      fromDisplayName: fromDisplayName,
      fromPhotoUrl: fromPhotoUrl,
      toUid: toUid,
      toDisplayName: toDisplayName,
      toPhotoUrl: toPhotoUrl,
      status: FriendRequestStatus.pending,
      sentAt: DateTime.now(),
    );

    await _firestore.collection('friendRequests').add(request.toFirestore());
  }

  /// Get incoming friend requests
  Stream<List<FriendRequest>> watchIncomingRequests(String uid) {
    return _firestore
        .collection('friendRequests')
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(FriendRequest.fromFirestore).toList());
  }

  /// Get outgoing friend requests
  Stream<List<FriendRequest>> watchOutgoingRequests(String uid) {
    return _firestore
        .collection('friendRequests')
        .where('fromUid', isEqualTo: uid)
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(FriendRequest.fromFirestore).toList());
  }

  /// Accept friend request
  Future<void> acceptFriendRequest(String requestId) async {
    final doc = await _firestore.collection('friendRequests').doc(requestId).get();
    if (!doc.exists) throw Exception('Anmodning ikke fundet');

    final request = FriendRequest.fromFirestore(doc);

    final batch = _firestore.batch();

    // Update request status
    batch.update(doc.reference, {
      'status': FriendRequestStatus.accepted.name,
      'respondedAt': FieldValue.serverTimestamp(),
    });

    // Add friend to requester's list
    final fromFriendRef = _firestore
        .collection('users')
        .doc(request.fromUid)
        .collection('friends')
        .doc(request.toUid);
    batch.set(fromFriendRef, Friend(
      uid: request.toUid,
      displayName: request.toDisplayName,
      photoUrl: request.toPhotoUrl,
      friendsSince: DateTime.now(),
    ).toFirestore());

    // Add friend to receiver's list
    final toFriendRef = _firestore
        .collection('users')
        .doc(request.toUid)
        .collection('friends')
        .doc(request.fromUid);
    batch.set(toFriendRef, Friend(
      uid: request.fromUid,
      displayName: request.fromDisplayName,
      photoUrl: request.fromPhotoUrl,
      friendsSince: DateTime.now(),
    ).toFirestore());

    // Create activity
    final activityRef = _firestore.collection('socialActivity').doc();
    batch.set(activityRef, SocialActivity(
      id: activityRef.id,
      type: SocialActivityType.friendAdded,
      actorUid: request.toUid,
      actorDisplayName: request.toDisplayName,
      actorPhotoUrl: request.toPhotoUrl,
      timestamp: DateTime.now(),
      targetUid: request.fromUid,
      targetDisplayName: request.fromDisplayName,
    ).toFirestore());

    await batch.commit();
  }

  /// Decline friend request
  Future<void> declineFriendRequest(String requestId) async {
    await _firestore.collection('friendRequests').doc(requestId).update({
      'status': FriendRequestStatus.declined.name,
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove friend
  Future<void> removeFriend(String uid, String friendUid) async {
    final batch = _firestore.batch();

    batch.delete(_firestore
        .collection('users')
        .doc(uid)
        .collection('friends')
        .doc(friendUid));

    batch.delete(_firestore
        .collection('users')
        .doc(friendUid)
        .collection('friends')
        .doc(uid));

    await batch.commit();
  }

  // ─── Shared Rides ───────────────────────────────────────────────────────────

  /// Share a ride
  Future<void> shareRide({
    required String rideId,
    required String ownerUid,
    required String ownerDisplayName,
    required String? ownerPhotoUrl,
    required double distanceKm,
    required int durationMinutes,
    String? caption,
    String? routePolyline,
    String? startAddress,
    String? endAddress,
  }) async {
    final sharedRide = SharedRide(
      id: '',
      rideId: rideId,
      ownerUid: ownerUid,
      ownerDisplayName: ownerDisplayName,
      ownerPhotoUrl: ownerPhotoUrl,
      sharedAt: DateTime.now(),
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      caption: caption,
      routePolyline: routePolyline,
      startAddress: startAddress,
      endAddress: endAddress,
    );

    final docRef = await _firestore.collection('sharedRides').add(sharedRide.toFirestore());

    // Create activity
    await _firestore.collection('socialActivity').add(SocialActivity(
      id: '',
      type: SocialActivityType.rideShared,
      actorUid: ownerUid,
      actorDisplayName: ownerDisplayName,
      actorPhotoUrl: ownerPhotoUrl,
      timestamp: DateTime.now(),
      referenceId: docRef.id,
      metadata: {
        'distanceKm': distanceKm,
        'durationMinutes': durationMinutes,
      },
    ).toFirestore());
  }

  /// Get feed of shared rides from friends
  Stream<List<SharedRide>> watchFriendsFeed(String uid) {
    // Get friends' UIDs
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('friends')
        .snapshots()
        .asyncMap((friendsSnapshot) async {
      if (friendsSnapshot.docs.isEmpty) return <SharedRide>[];

      final friendUids = friendsSnapshot.docs.map((d) => d.id).toList();
      
      // Firestore 'in' queries limited to 30 items
      final batches = <List<String>>[];
      for (var i = 0; i < friendUids.length; i += 30) {
        batches.add(friendUids.sublist(i, i + 30 > friendUids.length ? friendUids.length : i + 30));
      }

      final rides = <SharedRide>[];
      for (final batch in batches) {
        final snapshot = await _firestore
            .collection('sharedRides')
            .where('ownerUid', whereIn: batch)
            .orderBy('sharedAt', descending: true)
            .limit(50)
            .get();
        rides.addAll(snapshot.docs.map(SharedRide.fromFirestore));
      }

      rides.sort((a, b) => b.sharedAt.compareTo(a.sharedAt));
      return rides.take(50).toList();
    });
  }

  /// Get user's shared rides
  Stream<List<SharedRide>> watchUserSharedRides(String uid) {
    return _firestore
        .collection('sharedRides')
        .where('ownerUid', isEqualTo: uid)
        .orderBy('sharedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(SharedRide.fromFirestore).toList());
  }

  /// Like/unlike a shared ride
  Future<void> toggleLike(String sharedRideId, String uid) async {
    final doc = await _firestore.collection('sharedRides').doc(sharedRideId).get();
    if (!doc.exists) return;

    final ride = SharedRide.fromFirestore(doc);
    final likes = List<String>.from(ride.likes);

    if (likes.contains(uid)) {
      likes.remove(uid);
    } else {
      likes.add(uid);
    }

    await doc.reference.update({'likes': likes});
  }

  /// Add comment to shared ride
  Future<void> addComment({
    required String sharedRideId,
    required String authorUid,
    required String authorDisplayName,
    required String? authorPhotoUrl,
    required String text,
  }) async {
    final comment = RideComment(
      id: '',
      authorUid: authorUid,
      authorDisplayName: authorDisplayName,
      authorPhotoUrl: authorPhotoUrl,
      text: text,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('sharedRides')
        .doc(sharedRideId)
        .collection('comments')
        .add(comment.toFirestore());

    // Update comment count
    await _firestore.collection('sharedRides').doc(sharedRideId).update({
      'commentsCount': FieldValue.increment(1),
    });
  }

  /// Get comments for a shared ride
  Stream<List<RideComment>> watchComments(String sharedRideId) {
    return _firestore
        .collection('sharedRides')
        .doc(sharedRideId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(RideComment.fromFirestore).toList());
  }

  /// Delete shared ride
  Future<void> deleteSharedRide(String sharedRideId) async {
    await _firestore.collection('sharedRides').doc(sharedRideId).delete();
  }

  // ─── Activity Feed ──────────────────────────────────────────────────────────

  /// Get activity feed for user's friends
  Stream<List<SocialActivity>> watchActivityFeed(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('friends')
        .snapshots()
        .asyncMap((friendsSnapshot) async {
      if (friendsSnapshot.docs.isEmpty) return <SocialActivity>[];

      final friendUids = friendsSnapshot.docs.map((d) => d.id).toList();
      friendUids.add(uid); // Include own activities

      final batches = <List<String>>[];
      for (var i = 0; i < friendUids.length; i += 30) {
        batches.add(friendUids.sublist(i, i + 30 > friendUids.length ? friendUids.length : i + 30));
      }

      final activities = <SocialActivity>[];
      for (final batch in batches) {
        final snapshot = await _firestore
            .collection('socialActivity')
            .where('actorUid', whereIn: batch)
            .orderBy('timestamp', descending: true)
            .limit(50)
            .get();
        activities.addAll(snapshot.docs.map(SocialActivity.fromFirestore));
      }

      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return activities.take(50).toList();
    });
  }

  // ─── User Search ────────────────────────────────────────────────────────────

  /// Search users by display name
  Future<List<UserSearchResult>> searchUsers({
    required String query,
    required String currentUid,
  }) async {
    if (query.isEmpty || query.length < 2) return [];

    // Get current user's friends
    final friendsSnapshot = await _firestore
        .collection('users')
        .doc(currentUid)
        .collection('friends')
        .get();
    final friendUids = friendsSnapshot.docs.map((d) => d.id).toSet();

    // Get pending requests
    final pendingSnapshot = await _firestore
        .collection('friendRequests')
        .where('fromUid', isEqualTo: currentUid)
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .get();
    final pendingUids = pendingSnapshot.docs.map((d) => d['toUid'] as String).toSet();

    // Search users - using case-insensitive search with prefix
    final searchLower = query.toLowerCase();
    final usersSnapshot = await _firestore
        .collection('users')
        .where('displayNameLower', isGreaterThanOrEqualTo: searchLower)
        .where('displayNameLower', isLessThan: '${searchLower}z')
        .limit(20)
        .get();

    return usersSnapshot.docs
        .where((doc) => doc.id != currentUid)
        .map((doc) {
      final data = doc.data();
      return UserSearchResult(
        uid: doc.id,
        displayName: data['displayName'] as String? ?? 'Ukendt',
        photoUrl: data['photoUrl'] as String?,
        totalKm: (data['totalKm'] as num?)?.toDouble() ?? 0,
        isFriend: friendUids.contains(doc.id),
        hasPendingRequest: pendingUids.contains(doc.id),
      );
    }).toList();
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final socialServiceProvider = Provider<SocialService>((ref) {
  return SocialService(FirebaseFirestore.instance);
});

/// Current user's friends
final friendsProvider = StreamProvider<List<Friend>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(socialServiceProvider).watchFriends(user.uid);
});

/// Incoming friend requests
final incomingFriendRequestsProvider = StreamProvider<List<FriendRequest>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(socialServiceProvider).watchIncomingRequests(user.uid);
});

/// Outgoing friend requests
final outgoingFriendRequestsProvider = StreamProvider<List<FriendRequest>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(socialServiceProvider).watchOutgoingRequests(user.uid);
});

/// Friends' shared rides feed
final friendsFeedProvider = StreamProvider<List<SharedRide>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(socialServiceProvider).watchFriendsFeed(user.uid);
});

/// User's own shared rides
final userSharedRidesProvider = StreamProvider<List<SharedRide>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(socialServiceProvider).watchUserSharedRides(user.uid);
});

/// Social activity feed
final socialActivityFeedProvider = StreamProvider<List<SocialActivity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(socialServiceProvider).watchActivityFeed(user.uid);
});

/// Comments for a shared ride
final rideCommentsProvider = StreamProvider.family<List<RideComment>, String>((ref, sharedRideId) {
  return ref.watch(socialServiceProvider).watchComments(sharedRideId);
});
