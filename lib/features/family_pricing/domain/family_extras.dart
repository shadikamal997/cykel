import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ==========================================
// Guest Riders
// ==========================================

/// Status of a guest invitation
enum GuestInviteStatus {
  pending,   // Invitation sent, waiting for response
  accepted,  // Guest accepted and joined
  declined,  // Guest declined the invitation
  expired,   // Invitation expired
  revoked,   // Owner revoked the invitation
}

/// A guest rider invitation
class GuestInvite {
  final String id;
  final String familyId;
  final String invitedByUserId;
  final String invitedByName;
  final String guestEmail;
  final String? guestName;
  final String? guestUserId; // Set when guest accepts
  final GuestInviteStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? respondedAt;
  final int maxDays; // How many days the guest can stay
  final int daysRemaining;
  final bool canTrack; // Whether family can track guest location
  final String? personalMessage;

  const GuestInvite({
    required this.id,
    required this.familyId,
    required this.invitedByUserId,
    required this.invitedByName,
    required this.guestEmail,
    this.guestName,
    this.guestUserId,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.respondedAt,
    this.maxDays = 7,
    this.daysRemaining = 7,
    this.canTrack = false,
    this.personalMessage,
  });

  bool get isActive => 
      status == GuestInviteStatus.accepted && 
      daysRemaining > 0 &&
      DateTime.now().isBefore(expiresAt);

  bool get isPending => status == GuestInviteStatus.pending;

  bool get isExpired => 
      status == GuestInviteStatus.expired || 
      DateTime.now().isAfter(expiresAt);

  factory GuestInvite.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GuestInvite(
      id: doc.id,
      familyId: data['familyId'] as String,
      invitedByUserId: data['invitedByUserId'] as String,
      invitedByName: data['invitedByName'] as String? ?? 'Unknown',
      guestEmail: data['guestEmail'] as String,
      guestName: data['guestName'] as String?,
      guestUserId: data['guestUserId'] as String?,
      status: GuestInviteStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => GuestInviteStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      maxDays: data['maxDays'] as int? ?? 7,
      daysRemaining: data['daysRemaining'] as int? ?? 7,
      canTrack: data['canTrack'] as bool? ?? false,
      personalMessage: data['personalMessage'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'familyId': familyId,
      'invitedByUserId': invitedByUserId,
      'invitedByName': invitedByName,
      'guestEmail': guestEmail,
      'guestName': guestName,
      'guestUserId': guestUserId,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'maxDays': maxDays,
      'daysRemaining': daysRemaining,
      'canTrack': canTrack,
      'personalMessage': personalMessage,
    };
  }

  GuestInvite copyWith({
    String? id,
    String? guestName,
    String? guestUserId,
    GuestInviteStatus? status,
    DateTime? respondedAt,
    int? daysRemaining,
  }) {
    return GuestInvite(
      id: id ?? this.id,
      familyId: familyId,
      invitedByUserId: invitedByUserId,
      invitedByName: invitedByName,
      guestEmail: guestEmail,
      guestName: guestName ?? this.guestName,
      guestUserId: guestUserId ?? this.guestUserId,
      status: status ?? this.status,
      createdAt: createdAt,
      expiresAt: expiresAt,
      respondedAt: respondedAt ?? this.respondedAt,
      maxDays: maxDays,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      canTrack: canTrack,
      personalMessage: personalMessage,
    );
  }
}

/// An active guest member (subset of FamilyMember)
class GuestMember {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime joinedAt;
  final DateTime expiresAt;
  final int daysRemaining;
  final bool isTracking;
  final LatLng? lastKnownLocation;
  final DateTime? lastLocationUpdate;

  const GuestMember({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.joinedAt,
    required this.expiresAt,
    required this.daysRemaining,
    this.isTracking = false,
    this.lastKnownLocation,
    this.lastLocationUpdate,
  });

  bool get isOnline => 
      lastLocationUpdate != null &&
      DateTime.now().difference(lastLocationUpdate!).inMinutes < 5;

  factory GuestMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final locationData = data['lastKnownLocation'] as GeoPoint?;
    
    return GuestMember(
      id: doc.id,
      name: data['name'] as String? ?? 'Guest',
      email: data['email'] as String,
      photoUrl: data['photoUrl'] as String?,
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      daysRemaining: data['daysRemaining'] as int? ?? 0,
      isTracking: data['isTracking'] as bool? ?? false,
      lastKnownLocation: locationData != null
          ? LatLng(locationData.latitude, locationData.longitude)
          : null,
      lastLocationUpdate: data['lastLocationUpdate'] != null
          ? (data['lastLocationUpdate'] as Timestamp).toDate()
          : null,
    );
  }
}

// ==========================================
// Group Rides
// ==========================================

/// Status of a group ride
enum GroupRideStatus {
  planned,    // Scheduled for the future
  gathering,  // Participants are gathering at start point
  inProgress, // Ride is active
  completed,  // Ride finished
  cancelled,  // Ride was cancelled
}

/// Type of group ride
enum GroupRideType {
  casual,     // Leisurely pace, family-friendly
  fitness,    // More intense, for exercise
  commute,    // Getting from A to B
  adventure,  // Exploring new areas
  training,   // Teaching kids to ride
}

/// A participant in a group ride
class GroupRideParticipant {
  final String memberId;
  final String memberName;
  final String? photoUrl;
  final bool isOrganizer;
  final ParticipantStatus status;
  final DateTime? joinedAt;
  final LatLng? currentLocation;
  final double distanceCovered;
  final bool needsAssistance;

  const GroupRideParticipant({
    required this.memberId,
    required this.memberName,
    this.photoUrl,
    this.isOrganizer = false,
    this.status = ParticipantStatus.invited,
    this.joinedAt,
    this.currentLocation,
    this.distanceCovered = 0,
    this.needsAssistance = false,
  });

  factory GroupRideParticipant.fromMap(Map<String, dynamic> data) {
    final locationData = data['currentLocation'] as GeoPoint?;
    return GroupRideParticipant(
      memberId: data['memberId'] as String,
      memberName: data['memberName'] as String? ?? 'Unknown',
      photoUrl: data['photoUrl'] as String?,
      isOrganizer: data['isOrganizer'] as bool? ?? false,
      status: ParticipantStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ParticipantStatus.invited,
      ),
      joinedAt: data['joinedAt'] != null
          ? (data['joinedAt'] as Timestamp).toDate()
          : null,
      currentLocation: locationData != null
          ? LatLng(locationData.latitude, locationData.longitude)
          : null,
      distanceCovered: (data['distanceCovered'] as num?)?.toDouble() ?? 0,
      needsAssistance: data['needsAssistance'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'photoUrl': photoUrl,
      'isOrganizer': isOrganizer,
      'status': status.name,
      'joinedAt': joinedAt != null ? Timestamp.fromDate(joinedAt!) : null,
      'currentLocation': currentLocation != null
          ? GeoPoint(currentLocation!.latitude, currentLocation!.longitude)
          : null,
      'distanceCovered': distanceCovered,
      'needsAssistance': needsAssistance,
    };
  }
}

/// Status of a participant
enum ParticipantStatus {
  invited,    // Invited but hasn't responded
  confirmed,  // Confirmed attendance
  declined,   // Won't attend
  joined,     // Currently participating
  finished,   // Completed the ride
  leftEarly,  // Left before ride ended
}

/// A group ride event
class GroupRide {
  final String id;
  final String familyId;
  final String organizerId;
  final String organizerName;
  final String title;
  final String? description;
  final GroupRideType type;
  final GroupRideStatus status;
  final DateTime scheduledStart;
  final DateTime? actualStart;
  final DateTime? endTime;
  final LatLng startLocation;
  final String? startAddress;
  final LatLng? endLocation;
  final String? endAddress;
  final List<LatLng> plannedRoute;
  final double plannedDistanceKm;
  final int estimatedDurationMinutes;
  final List<GroupRideParticipant> participants;
  final double? actualDistanceKm;
  final int? actualDurationMinutes;
  final bool allowGuests;
  final int maxParticipants;
  final String? notes;
  final String? eventId; // Link to public event in events collection
  final DateTime createdAt;

  const GroupRide({
    required this.id,
    required this.familyId,
    required this.organizerId,
    required this.organizerName,
    required this.title,
    this.description,
    required this.type,
    required this.status,
    required this.scheduledStart,
    this.actualStart,
    this.endTime,
    required this.startLocation,
    this.startAddress,
    this.endLocation,
    this.endAddress,
    this.plannedRoute = const [],
    this.plannedDistanceKm = 0,
    this.estimatedDurationMinutes = 60,
    this.participants = const [],
    this.actualDistanceKm,
    this.actualDurationMinutes,
    this.allowGuests = true,
    this.maxParticipants = 10,
    this.notes,
    this.eventId,
    required this.createdAt,
  });

  int get confirmedCount => 
      participants.where((p) => p.status == ParticipantStatus.confirmed || 
                                p.status == ParticipantStatus.joined).length;

  int get activeCount =>
      participants.where((p) => p.status == ParticipantStatus.joined).length;

  bool get isUpcoming => status == GroupRideStatus.planned;
  bool get isActive => status == GroupRideStatus.inProgress || 
                       status == GroupRideStatus.gathering;
  bool get isCompleted => status == GroupRideStatus.completed;
  bool get isCancelled => status == GroupRideStatus.cancelled;

  bool get canJoin => 
      (status == GroupRideStatus.planned || status == GroupRideStatus.gathering) &&
      confirmedCount < maxParticipants;

  IconData get typeIcon {
    switch (type) {
      case GroupRideType.casual:
        return Icons.family_restroom;
      case GroupRideType.fitness:
        return Icons.fitness_center;
      case GroupRideType.commute:
        return Icons.work;
      case GroupRideType.adventure:
        return Icons.explore;
      case GroupRideType.training:
        return Icons.school;
    }
  }

  Color get typeColor {
    switch (type) {
      case GroupRideType.casual:
        return Colors.green;
      case GroupRideType.fitness:
        return Colors.orange;
      case GroupRideType.commute:
        return Colors.blue;
      case GroupRideType.adventure:
        return Colors.purple;
      case GroupRideType.training:
        return Colors.teal;
    }
  }

  String get typeName {
    switch (type) {
      case GroupRideType.casual:
        return 'Casual';
      case GroupRideType.fitness:
        return 'Fitness';
      case GroupRideType.commute:
        return 'Commute';
      case GroupRideType.adventure:
        return 'Adventure';
      case GroupRideType.training:
        return 'Training';
    }
  }

  factory GroupRide.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final startGeo = data['startLocation'] as GeoPoint;
    final endGeo = data['endLocation'] as GeoPoint?;
    final routeData = data['plannedRoute'] as List<dynamic>? ?? [];
    final participantsData = data['participants'] as List<dynamic>? ?? [];

    return GroupRide(
      id: doc.id,
      familyId: data['familyId'] as String,
      organizerId: data['organizerId'] as String,
      organizerName: data['organizerName'] as String? ?? 'Unknown',
      title: data['title'] as String,
      description: data['description'] as String?,
      type: GroupRideType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => GroupRideType.casual,
      ),
      status: GroupRideStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => GroupRideStatus.planned,
      ),
      scheduledStart: (data['scheduledStart'] as Timestamp).toDate(),
      actualStart: data['actualStart'] != null
          ? (data['actualStart'] as Timestamp).toDate()
          : null,
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      startLocation: LatLng(startGeo.latitude, startGeo.longitude),
      startAddress: data['startAddress'] as String?,
      endLocation: endGeo != null
          ? LatLng(endGeo.latitude, endGeo.longitude)
          : null,
      endAddress: data['endAddress'] as String?,
      plannedRoute: routeData.map((point) {
        if (point is GeoPoint) {
          return LatLng(point.latitude, point.longitude);
        }
        final p = point as Map<String, dynamic>;
        return LatLng(p['lat'] as double, p['lng'] as double);
      }).toList(),
      plannedDistanceKm: (data['plannedDistanceKm'] as num?)?.toDouble() ?? 0,
      estimatedDurationMinutes: data['estimatedDurationMinutes'] as int? ?? 60,
      participants: participantsData
          .map((p) => GroupRideParticipant.fromMap(p as Map<String, dynamic>))
          .toList(),
      actualDistanceKm: (data['actualDistanceKm'] as num?)?.toDouble(),
      actualDurationMinutes: data['actualDurationMinutes'] as int?,
      allowGuests: data['allowGuests'] as bool? ?? true,
      maxParticipants: data['maxParticipants'] as int? ?? 10,
      notes: data['notes'] as String?,
      eventId: data['eventId'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'familyId': familyId,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'title': title,
      'description': description,
      'type': type.name,
      'status': status.name,
      'scheduledStart': Timestamp.fromDate(scheduledStart),
      'actualStart': actualStart != null ? Timestamp.fromDate(actualStart!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'startLocation': GeoPoint(startLocation.latitude, startLocation.longitude),
      'startAddress': startAddress,
      'endLocation': endLocation != null
          ? GeoPoint(endLocation!.latitude, endLocation!.longitude)
          : null,
      'endAddress': endAddress,
      'plannedRoute': plannedRoute
          .map((p) => GeoPoint(p.latitude, p.longitude))
          .toList(),
      'plannedDistanceKm': plannedDistanceKm,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'participants': participants.map((p) => p.toMap()).toList(),
      'actualDistanceKm': actualDistanceKm,
      'actualDurationMinutes': actualDurationMinutes,
      'allowGuests': allowGuests,
      'maxParticipants': maxParticipants,
      'notes': notes,
      'eventId': eventId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  GroupRide copyWith({
    String? id,
    GroupRideStatus? status,
    DateTime? actualStart,
    DateTime? endTime,
    List<GroupRideParticipant>? participants,
    double? actualDistanceKm,
    int? actualDurationMinutes,
    String? eventId,
  }) {
    return GroupRide(
      id: id ?? this.id,
      familyId: familyId,
      organizerId: organizerId,
      organizerName: organizerName,
      title: title,
      description: description,
      type: type,
      status: status ?? this.status,
      scheduledStart: scheduledStart,
      actualStart: actualStart ?? this.actualStart,
      endTime: endTime ?? this.endTime,
      startLocation: startLocation,
      startAddress: startAddress,
      endLocation: endLocation,
      endAddress: endAddress,
      plannedRoute: plannedRoute,
      plannedDistanceKm: plannedDistanceKm,
      estimatedDurationMinutes: estimatedDurationMinutes,
      participants: participants ?? this.participants,
      actualDistanceKm: actualDistanceKm ?? this.actualDistanceKm,
      actualDurationMinutes: actualDurationMinutes ?? this.actualDurationMinutes,
      allowGuests: allowGuests,
      maxParticipants: maxParticipants,
      notes: notes,
      eventId: eventId ?? this.eventId,
      createdAt: createdAt,
    );
  }
}

/// A waypoint or checkpoint for a group ride
class RideWaypoint {
  final String id;
  final String name;
  final LatLng location;
  final String? description;
  final int orderIndex;
  final bool isRestStop;
  final int? estimatedArrivalMinutes;

  const RideWaypoint({
    required this.id,
    required this.name,
    required this.location,
    this.description,
    required this.orderIndex,
    this.isRestStop = false,
    this.estimatedArrivalMinutes,
  });

  factory RideWaypoint.fromMap(Map<String, dynamic> data) {
    final locationData = data['location'] as GeoPoint;
    return RideWaypoint(
      id: data['id'] as String,
      name: data['name'] as String,
      location: LatLng(locationData.latitude, locationData.longitude),
      description: data['description'] as String?,
      orderIndex: data['orderIndex'] as int,
      isRestStop: data['isRestStop'] as bool? ?? false,
      estimatedArrivalMinutes: data['estimatedArrivalMinutes'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': GeoPoint(location.latitude, location.longitude),
      'description': description,
      'orderIndex': orderIndex,
      'isRestStop': isRestStop,
      'estimatedArrivalMinutes': estimatedArrivalMinutes,
    };
  }
}
