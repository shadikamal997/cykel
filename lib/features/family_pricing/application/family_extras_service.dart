import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../domain/family_extras.dart';
import '../../events/domain/event.dart' as events;

/// Service for managing guest riders and group rides
class FamilyExtrasService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FamilyExtrasService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // ==========================================
  // Guest Invitations
  // ==========================================

  /// Send a guest invitation
  Future<GuestInvite> sendGuestInvite({
    required String familyId,
    required String guestEmail,
    String? personalMessage,
    int maxDays = 7,
    bool canTrack = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Check if guest is already invited or a member
    final existingInvite = await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('guestInvites')
        .where('guestEmail', isEqualTo: guestEmail)
        .where('status', isEqualTo: GuestInviteStatus.pending.name)
        .get();

    if (existingInvite.docs.isNotEmpty) {
      throw Exception('This guest already has a pending invitation');
    }

    final now = DateTime.now();
    final invite = GuestInvite(
      id: '', // Will be set by Firestore
      familyId: familyId,
      invitedByUserId: user.uid,
      invitedByName: user.displayName ?? 'Family Member',
      guestEmail: guestEmail,
      status: GuestInviteStatus.pending,
      createdAt: now,
      expiresAt: now.add(Duration(days: maxDays + 7)), // Extra 7 days to accept
      maxDays: maxDays,
      daysRemaining: maxDays,
      canTrack: canTrack,
      personalMessage: personalMessage,
    );

    final docRef = await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('guestInvites')
        .add(invite.toFirestore());

    // TODO: Send email notification to guest
    
    return invite.copyWith(id: docRef.id);
  }

  /// Accept a guest invitation
  Future<void> acceptGuestInvite(String familyId, String inviteId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final inviteDoc = await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('guestInvites')
        .doc(inviteId)
        .get();

    if (!inviteDoc.exists) throw Exception('Invitation not found');

    final invite = GuestInvite.fromFirestore(inviteDoc);
    
    if (invite.guestEmail.toLowerCase() != user.email?.toLowerCase()) {
      throw Exception('This invitation is not for you');
    }

    if (invite.isExpired) {
      throw Exception('This invitation has expired');
    }

    // Update invite status
    await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('guestInvites')
        .doc(inviteId)
        .update({
      'status': GuestInviteStatus.accepted.name,
      'guestUserId': user.uid,
      'guestName': user.displayName ?? 'Guest',
      'respondedAt': FieldValue.serverTimestamp(),
    });

    // Create guest member record
    final now = DateTime.now();
    await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('guests')
        .doc(user.uid)
        .set({
      'name': user.displayName ?? 'Guest',
      'email': user.email,
      'photoUrl': user.photoURL,
      'joinedAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(now.add(Duration(days: invite.maxDays))),
      'daysRemaining': invite.maxDays,
      'isTracking': invite.canTrack,
      'inviteId': inviteId,
    });

    // Add guest to family members list (with guest role)
    await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .update({
      'guestIds': FieldValue.arrayUnion([user.uid]),
    });
  }

  /// Decline a guest invitation
  Future<void> declineGuestInvite(String familyId, String inviteId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('guestInvites')
        .doc(inviteId)
        .update({
      'status': GuestInviteStatus.declined.name,
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Revoke a guest invitation (by family owner)
  Future<void> revokeGuestInvite(String familyId, String inviteId) async {
    await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('guestInvites')
        .doc(inviteId)
        .update({
      'status': GuestInviteStatus.revoked.name,
    });
  }

  /// Remove a guest from the family
  Future<void> removeGuest(String familyId, String guestId) async {
    // Remove from guests collection
    await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('guests')
        .doc(guestId)
        .delete();

    // Remove from family guest IDs
    await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .update({
      'guestIds': FieldValue.arrayRemove([guestId]),
    });
  }

  /// Watch all guest invites for a family
  Stream<List<GuestInvite>> watchGuestInvites(String familyId) {
    return _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('guestInvites')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => GuestInvite.fromFirestore(doc)).toList());
  }

  /// Watch pending invites for the current user
  Stream<List<GuestInvite>> watchMyPendingInvites() {
    final user = _auth.currentUser;
    if (user?.email == null) return Stream.value([]);

    return _firestore
        .collectionGroup('guestInvites')
        .where('guestEmail', isEqualTo: user!.email!.toLowerCase())
        .where('status', isEqualTo: GuestInviteStatus.pending.name)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => GuestInvite.fromFirestore(doc)).toList());
  }

  /// Watch active guests for a family
  Stream<List<GuestMember>> watchActiveGuests(String familyId) {
    return _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('guests')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => GuestMember.fromFirestore(doc)).toList());
  }

  // ==========================================
  // Group Rides
  // ==========================================

  /// Create a new group ride
  Future<GroupRide> createGroupRide({
    required String familyId,
    required String title,
    String? description,
    required GroupRideType type,
    required DateTime scheduledStart,
    required LatLng startLocation,
    String? startAddress,
    LatLng? endLocation,
    String? endAddress,
    List<LatLng> plannedRoute = const [],
    double plannedDistanceKm = 0,
    int estimatedDurationMinutes = 60,
    bool allowGuests = true,
    int maxParticipants = 10,
    String? notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final organizer = GroupRideParticipant(
      memberId: user.uid,
      memberName: user.displayName ?? 'Unknown',
      photoUrl: user.photoURL,
      isOrganizer: true,
      status: ParticipantStatus.confirmed,
    );

    //  === 1. CREATE PUBLIC RIDE EVENT ===
    // This makes the group ride discoverable in the Events tab
    final publicEvent = events.RideEvent(
      id: '', // Will be set by Firestore
      title: title,
      description: description ?? 'Join us for this group ride!',
      organizerId: user.uid,
      organizerName: user.displayName ?? 'Unknown',
      organizerPhotoUrl: user.photoURL,
      dateTime: scheduledStart,
      meetingPoint: events.MeetingPoint(
        latitude: startLocation.latitude,
        longitude: startLocation.longitude,
        address: startAddress ?? 'Meeting Point',
        instructions: notes,
      ),
      eventType: _mapGroupRideTypeToEventType(type),
      difficulty: events.EventDifficulty.moderate, // Default
      visibility: events.EventVisibility.public,
      status: events.EventStatus.upcoming,
      route: plannedRoute.isNotEmpty
          ? events.EventRoute(
              polyline: '', // Empty for now, would need encoding
              distanceKm: plannedDistanceKm,
              elevationGain: 0,
              estimatedDurationMinutes: estimatedDurationMinutes,
            )
          : null,
      distanceKm: plannedDistanceKm,
      durationMinutes: estimatedDurationMinutes,
      maxParticipants: maxParticipants,
      currentParticipants: 1, // Organizer
      tags: ['family', 'group-ride', type.name],
      createdAt: DateTime.now(),
    );

    // Create the public event in events collection
    final eventDocRef = await _firestore
        .collection('events')
        .add(publicEvent.toFirestore());

    // Add organizer as participant in the event
    await _firestore
        .collection('events')
        .doc(eventDocRef.id)
        .collection('participants')
        .add({
      'eventId': eventDocRef.id,
      'userId': user.uid,
      'userName': user.displayName ?? 'Unknown',
      'userPhotoUrl': user.photoURL,
      'status': 'confirmed',
      'joinedAt': FieldValue.serverTimestamp(),
      'isOrganizer': true,
    });

    // === 2. CREATE GROUP RIDE (FAMILY-SPECIFIC) ===
    final ride = GroupRide(
      id: '', // Will be set by Firestore
      familyId: familyId,
      organizerId: user.uid,
      organizerName: user.displayName ?? 'Unknown',
      title: title,
      description: description,
      type: type,
      status: GroupRideStatus.planned,
      scheduledStart: scheduledStart,
      startLocation: startLocation,
      startAddress: startAddress,
      endLocation: endLocation,
      endAddress: endAddress,
      plannedRoute: plannedRoute,
      plannedDistanceKm: plannedDistanceKm,
      estimatedDurationMinutes: estimatedDurationMinutes,
      participants: [organizer],
      allowGuests: allowGuests,
      maxParticipants: maxParticipants,
      notes: notes,
      createdAt: DateTime.now(),
      eventId: eventDocRef.id, // Link to public event
    );

    final rideDocRef = await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('groupRides')
        .add(ride.toFirestore());

    return ride.copyWith(id: rideDocRef.id);
  }

  /// Map GroupRideType to EventType
  events.EventType _mapGroupRideTypeToEventType(GroupRideType type) {
    switch (type) {
      case GroupRideType.casual:
        return events.EventType.social;
      case GroupRideType.fitness:
        return events.EventType.training;
      case GroupRideType.commute:
        return events.EventType.commute;
      case GroupRideType.adventure:
        return events.EventType.tour;
      case GroupRideType.training:
        return events.EventType.training;
    }
  }

  /// Join a group ride
  Future<void> joinGroupRide(String familyId, String rideId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final rideDoc = await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('groupRides')
        .doc(rideId)
        .get();

    if (!rideDoc.exists) throw Exception('Ride not found');

    final ride = GroupRide.fromFirestore(rideDoc);
    
    if (!ride.canJoin) {
      throw Exception('This ride is full or has already started');
    }

    // Check if already participating
    if (ride.participants.any((p) => p.memberId == user.uid)) {
      throw Exception('You have already joined this ride');
    }

    final participant = GroupRideParticipant(
      memberId: user.uid,
      memberName: user.displayName ?? 'Unknown',
      photoUrl: user.photoURL,
      status: ParticipantStatus.confirmed,
    );

    await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('groupRides')
        .doc(rideId)
        .update({
      'participants': FieldValue.arrayUnion([participant.toMap()]),
    });
  }

  /// Leave a group ride
  Future<void> leaveGroupRide(String familyId, String rideId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final rideDoc = await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('groupRides')
        .doc(rideId)
        .get();

    if (!rideDoc.exists) throw Exception('Ride not found');

    final ride = GroupRide.fromFirestore(rideDoc);
    
    // Can't leave if you're the organizer
    if (ride.organizerId == user.uid) {
      throw Exception('Organizer cannot leave. Cancel the ride instead.');
    }

    final updatedParticipants = ride.participants
        .where((p) => p.memberId != user.uid)
        .map((p) => p.toMap())
        .toList();

    await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('groupRides')
        .doc(rideId)
        .update({
      'participants': updatedParticipants,
    });
  }

  /// Start a group ride (organizer only)
  Future<void> startGroupRide(String familyId, String rideId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final rideDoc = await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('groupRides')
        .doc(rideId)
        .get();

    if (!rideDoc.exists) throw Exception('Ride not found');

    final ride = GroupRide.fromFirestore(rideDoc);
    
    if (ride.organizerId != user.uid) {
      throw Exception('Only the organizer can start the ride');
    }

    // Update all confirmed participants to joined status
    final updatedParticipants = ride.participants.map((p) {
      if (p.status == ParticipantStatus.confirmed) {
        return GroupRideParticipant(
          memberId: p.memberId,
          memberName: p.memberName,
          photoUrl: p.photoUrl,
          isOrganizer: p.isOrganizer,
          status: ParticipantStatus.joined,
          joinedAt: DateTime.now(),
        );
      }
      return p;
    }).map((p) => p.toMap()).toList();

    await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('groupRides')
        .doc(rideId)
        .update({
      'status': GroupRideStatus.inProgress.name,
      'actualStart': FieldValue.serverTimestamp(),
      'participants': updatedParticipants,
    });
  }

  /// End a group ride (organizer only)
  Future<void> endGroupRide(
    String familyId,
    String rideId, {
    double? actualDistanceKm,
    int? actualDurationMinutes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final rideDoc = await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('groupRides')
        .doc(rideId)
        .get();

    if (!rideDoc.exists) throw Exception('Ride not found');

    final ride = GroupRide.fromFirestore(rideDoc);
    
    if (ride.organizerId != user.uid) {
      throw Exception('Only the organizer can end the ride');
    }

    // Update joined participants to finished status
    final updatedParticipants = ride.participants.map((p) {
      if (p.status == ParticipantStatus.joined) {
        return GroupRideParticipant(
          memberId: p.memberId,
          memberName: p.memberName,
          photoUrl: p.photoUrl,
          isOrganizer: p.isOrganizer,
          status: ParticipantStatus.finished,
          joinedAt: p.joinedAt,
          distanceCovered: p.distanceCovered,
        );
      }
      return p;
    }).map((p) => p.toMap()).toList();

    await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('groupRides')
        .doc(rideId)
        .update({
      'status': GroupRideStatus.completed.name,
      'endTime': FieldValue.serverTimestamp(),
      'actualDistanceKm': actualDistanceKm,
      'actualDurationMinutes': actualDurationMinutes,
      'participants': updatedParticipants,
    });
  }

  /// Cancel a group ride (organizer only)
  Future<void> cancelGroupRide(String familyId, String rideId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final rideDoc = await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('groupRides')
        .doc(rideId)
        .get();

    if (!rideDoc.exists) throw Exception('Ride not found');

    final ride = GroupRide.fromFirestore(rideDoc);
    
    if (ride.organizerId != user.uid) {
      throw Exception('Only the organizer can cancel the ride');
    }

    await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('groupRides')
        .doc(rideId)
        .update({
      'status': GroupRideStatus.cancelled.name,
    });
  }

  /// Update participant location during active ride
  Future<void> updateRideParticipantLocation(
    String familyId,
    String rideId,
    LatLng location,
    double distanceCovered,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final rideDoc = await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('groupRides')
        .doc(rideId)
        .get();

    if (!rideDoc.exists) return;

    final ride = GroupRide.fromFirestore(rideDoc);
    
    final updatedParticipants = ride.participants.map((p) {
      if (p.memberId == user.uid) {
        return GroupRideParticipant(
          memberId: p.memberId,
          memberName: p.memberName,
          photoUrl: p.photoUrl,
          isOrganizer: p.isOrganizer,
          status: p.status,
          joinedAt: p.joinedAt,
          currentLocation: location,
          distanceCovered: distanceCovered,
        );
      }
      return p;
    }).map((p) => p.toMap()).toList();

    await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('groupRides')
        .doc(rideId)
        .update({
      'participants': updatedParticipants,
    });
  }

  /// Signal that a participant needs assistance
  Future<void> signalNeedsAssistance(
    String familyId,
    String rideId,
    bool needsHelp,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final rideDoc = await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('groupRides')
        .doc(rideId)
        .get();

    if (!rideDoc.exists) return;

    final ride = GroupRide.fromFirestore(rideDoc);
    
    final updatedParticipants = ride.participants.map((p) {
      if (p.memberId == user.uid) {
        return GroupRideParticipant(
          memberId: p.memberId,
          memberName: p.memberName,
          photoUrl: p.photoUrl,
          isOrganizer: p.isOrganizer,
          status: p.status,
          joinedAt: p.joinedAt,
          currentLocation: p.currentLocation,
          distanceCovered: p.distanceCovered,
          needsAssistance: needsHelp,
        );
      }
      return p;
    }).map((p) => p.toMap()).toList();

    await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('groupRides')
        .doc(rideId)
        .update({
      'participants': updatedParticipants,
    });

    // TODO: Send push notification to organizer
  }

  /// Watch upcoming group rides
  Stream<List<GroupRide>> watchUpcomingRides(String familyId) {
    return _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('groupRides')
        .where('status', isEqualTo: GroupRideStatus.planned.name)
        .where('scheduledStart', isGreaterThan: Timestamp.now())
        .orderBy('scheduledStart')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => GroupRide.fromFirestore(doc)).toList());
  }

  /// Watch active group rides
  Stream<List<GroupRide>> watchActiveRides(String familyId) {
    return _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('groupRides')
        .where('status', whereIn: [
          GroupRideStatus.gathering.name,
          GroupRideStatus.inProgress.name,
        ])
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => GroupRide.fromFirestore(doc)).toList());
  }

  /// Watch completed group rides
  Stream<List<GroupRide>> watchCompletedRides(String familyId) {
    return _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('groupRides')
        .where('status', isEqualTo: GroupRideStatus.completed.name)
        .orderBy('endTime', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => GroupRide.fromFirestore(doc)).toList());
  }

  /// Get a single group ride
  Stream<GroupRide?> watchGroupRide(String familyId, String rideId) {
    return _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('groupRides')
        .doc(rideId)
        .snapshots()
        .map((doc) => doc.exists ? GroupRide.fromFirestore(doc) : null);
  }
}

// ==========================================
// Providers
// ==========================================

final familyExtrasServiceProvider = Provider<FamilyExtrasService>((ref) {
  return FamilyExtrasService();
});

final guestInvitesProvider = StreamProvider.family<List<GuestInvite>, String>((ref, familyId) {
  final service = ref.watch(familyExtrasServiceProvider);
  return service.watchGuestInvites(familyId);
});

final myPendingInvitesProvider = StreamProvider<List<GuestInvite>>((ref) {
  final service = ref.watch(familyExtrasServiceProvider);
  return service.watchMyPendingInvites();
});

final activeGuestsProvider = StreamProvider.family<List<GuestMember>, String>((ref, familyId) {
  final service = ref.watch(familyExtrasServiceProvider);
  return service.watchActiveGuests(familyId);
});

final upcomingRidesProvider = StreamProvider.family<List<GroupRide>, String>((ref, familyId) {
  final service = ref.watch(familyExtrasServiceProvider);
  return service.watchUpcomingRides(familyId);
});

final activeGroupRidesProvider = StreamProvider.family<List<GroupRide>, String>((ref, familyId) {
  final service = ref.watch(familyExtrasServiceProvider);
  return service.watchActiveRides(familyId);
});

final completedGroupRidesProvider = StreamProvider.family<List<GroupRide>, String>((ref, familyId) {
  final service = ref.watch(familyExtrasServiceProvider);
  return service.watchCompletedRides(familyId);
});

final groupRideProvider = StreamProvider.family<GroupRide?, ({String familyId, String rideId})>((ref, params) {
  final service = ref.watch(familyExtrasServiceProvider);
  return service.watchGroupRide(params.familyId, params.rideId);
});
