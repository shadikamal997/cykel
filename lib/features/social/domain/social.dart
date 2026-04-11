/// CYKEL — Social Feature Domain Models
/// Friends, ride sharing, and social activities

import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Friend Status ────────────────────────────────────────────────────────────

enum FriendRequestStatus {
  pending,
  accepted,
  declined;

  String get displayName {
    switch (this) {
      case FriendRequestStatus.pending:
        return 'Afventer';
      case FriendRequestStatus.accepted:
        return 'Accepteret';
      case FriendRequestStatus.declined:
        return 'Afvist';
    }
  }
}

// ─── Friend Request ───────────────────────────────────────────────────────────

class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.fromUid,
    required this.fromDisplayName,
    required this.toUid,
    required this.toDisplayName,
    required this.status,
    required this.sentAt,
    this.fromPhotoUrl,
    this.toPhotoUrl,
    this.respondedAt,
  });

  final String id;
  final String fromUid;
  final String fromDisplayName;
  final String? fromPhotoUrl;
  final String toUid;
  final String toDisplayName;
  final String? toPhotoUrl;
  final FriendRequestStatus status;
  final DateTime sentAt;
  final DateTime? respondedAt;

  factory FriendRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendRequest(
      id: doc.id,
      fromUid: data['fromUid'] as String,
      fromDisplayName: data['fromDisplayName'] as String,
      fromPhotoUrl: data['fromPhotoUrl'] as String?,
      toUid: data['toUid'] as String,
      toDisplayName: data['toDisplayName'] as String,
      toPhotoUrl: data['toPhotoUrl'] as String?,
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'fromUid': fromUid,
        'fromDisplayName': fromDisplayName,
        'fromPhotoUrl': fromPhotoUrl,
        'toUid': toUid,
        'toDisplayName': toDisplayName,
        'toPhotoUrl': toPhotoUrl,
        'status': status.name,
        'sentAt': Timestamp.fromDate(sentAt),
        'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      };
}

// ─── Friend ───────────────────────────────────────────────────────────────────

class Friend {
  const Friend({
    required this.uid,
    required this.displayName,
    required this.friendsSince,
    this.photoUrl,
    this.totalKm = 0,
    this.totalRides = 0,
    this.lastRideAt,
  });

  final String uid;
  final String displayName;
  final String? photoUrl;
  final DateTime friendsSince;
  final double totalKm;
  final int totalRides;
  final DateTime? lastRideAt;

  factory Friend.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Friend(
      uid: doc.id,
      displayName: data['displayName'] as String,
      photoUrl: data['photoUrl'] as String?,
      friendsSince: (data['friendsSince'] as Timestamp).toDate(),
      totalKm: (data['totalKm'] as num?)?.toDouble() ?? 0,
      totalRides: (data['totalRides'] as num?)?.toInt() ?? 0,
      lastRideAt: data['lastRideAt'] != null
          ? (data['lastRideAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'displayName': displayName,
        'photoUrl': photoUrl,
        'friendsSince': Timestamp.fromDate(friendsSince),
        'totalKm': totalKm,
        'totalRides': totalRides,
        'lastRideAt': lastRideAt != null ? Timestamp.fromDate(lastRideAt!) : null,
      };
}

// ─── Shared Ride ──────────────────────────────────────────────────────────────

class SharedRide {
  const SharedRide({
    required this.id,
    required this.rideId,
    required this.ownerUid,
    required this.ownerDisplayName,
    required this.sharedAt,
    required this.distanceKm,
    required this.durationMinutes,
    this.ownerPhotoUrl,
    this.caption,
    this.routePolyline,
    this.startAddress,
    this.endAddress,
    this.likes = const [],
    this.commentsCount = 0,
  });

  final String id;
  final String rideId;
  final String ownerUid;
  final String ownerDisplayName;
  final String? ownerPhotoUrl;
  final DateTime sharedAt;
  final double distanceKm;
  final int durationMinutes;
  final String? caption;
  final String? routePolyline;
  final String? startAddress;
  final String? endAddress;
  final List<String> likes; // List of user IDs who liked
  final int commentsCount;

  bool get isLikedBy => likes.isNotEmpty;

  factory SharedRide.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SharedRide(
      id: doc.id,
      rideId: data['rideId'] as String,
      ownerUid: data['ownerUid'] as String,
      ownerDisplayName: data['ownerDisplayName'] as String,
      ownerPhotoUrl: data['ownerPhotoUrl'] as String?,
      sharedAt: (data['sharedAt'] as Timestamp).toDate(),
      distanceKm: (data['distanceKm'] as num).toDouble(),
      durationMinutes: (data['durationMinutes'] as num).toInt(),
      caption: data['caption'] as String?,
      routePolyline: data['routePolyline'] as String?,
      startAddress: data['startAddress'] as String?,
      endAddress: data['endAddress'] as String?,
      likes: List<String>.from(data['likes'] ?? []),
      commentsCount: (data['commentsCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'rideId': rideId,
        'ownerUid': ownerUid,
        'ownerDisplayName': ownerDisplayName,
        'ownerPhotoUrl': ownerPhotoUrl,
        'sharedAt': Timestamp.fromDate(sharedAt),
        'distanceKm': distanceKm,
        'durationMinutes': durationMinutes,
        'caption': caption,
        'routePolyline': routePolyline,
        'startAddress': startAddress,
        'endAddress': endAddress,
        'likes': likes,
        'commentsCount': commentsCount,
      };
}

// ─── Ride Comment ─────────────────────────────────────────────────────────────

class RideComment {
  const RideComment({
    required this.id,
    required this.authorUid,
    required this.authorDisplayName,
    required this.text,
    required this.createdAt,
    this.authorPhotoUrl,
  });

  final String id;
  final String authorUid;
  final String authorDisplayName;
  final String? authorPhotoUrl;
  final String text;
  final DateTime createdAt;

  factory RideComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RideComment(
      id: doc.id,
      authorUid: data['authorUid'] as String,
      authorDisplayName: data['authorDisplayName'] as String,
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      text: data['text'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'authorUid': authorUid,
        'authorDisplayName': authorDisplayName,
        'authorPhotoUrl': authorPhotoUrl,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

// ─── Social Activity ──────────────────────────────────────────────────────────

enum SocialActivityType {
  friendAdded,
  rideShared,
  rideLiked,
  rideCommented,
  challengeCompleted,
  badgeEarned,
  milestonReached;

  String get displayName {
    switch (this) {
      case SocialActivityType.friendAdded:
        return 'Ny ven tilføjet';
      case SocialActivityType.rideShared:
        return 'Delte en tur';
      case SocialActivityType.rideLiked:
        return 'Syntes godt om en tur';
      case SocialActivityType.rideCommented:
        return 'Kommenterede på en tur';
      case SocialActivityType.challengeCompleted:
        return 'Fuldførte en udfordring';
      case SocialActivityType.badgeEarned:
        return 'Optjente et badge';
      case SocialActivityType.milestonReached:
        return 'Nåede en milepæl';
    }
  }

  String get icon {
    switch (this) {
      case SocialActivityType.friendAdded:
        return '👋';
      case SocialActivityType.rideShared:
        return '🚴';
      case SocialActivityType.rideLiked:
        return '❤️';
      case SocialActivityType.rideCommented:
        return '💬';
      case SocialActivityType.challengeCompleted:
        return '🏆';
      case SocialActivityType.badgeEarned:
        return '🎖️';
      case SocialActivityType.milestonReached:
        return '🎉';
    }
  }
}

class SocialActivity {
  const SocialActivity({
    required this.id,
    required this.type,
    required this.actorUid,
    required this.actorDisplayName,
    required this.timestamp,
    this.actorPhotoUrl,
    this.targetUid,
    this.targetDisplayName,
    this.referenceId,
    this.metadata,
  });

  final String id;
  final SocialActivityType type;
  final String actorUid;
  final String actorDisplayName;
  final String? actorPhotoUrl;
  final DateTime timestamp;
  final String? targetUid;
  final String? targetDisplayName;
  final String? referenceId; // ID of related entity (ride, challenge, badge)
  final Map<String, dynamic>? metadata;

  factory SocialActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SocialActivity(
      id: doc.id,
      type: SocialActivityType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => SocialActivityType.rideShared,
      ),
      actorUid: data['actorUid'] as String,
      actorDisplayName: data['actorDisplayName'] as String,
      actorPhotoUrl: data['actorPhotoUrl'] as String?,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      targetUid: data['targetUid'] as String?,
      targetDisplayName: data['targetDisplayName'] as String?,
      referenceId: data['referenceId'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'type': type.name,
        'actorUid': actorUid,
        'actorDisplayName': actorDisplayName,
        'actorPhotoUrl': actorPhotoUrl,
        'timestamp': Timestamp.fromDate(timestamp),
        'targetUid': targetUid,
        'targetDisplayName': targetDisplayName,
        'referenceId': referenceId,
        'metadata': metadata,
      };
}

// ─── User Search Result ───────────────────────────────────────────────────────

class UserSearchResult {
  const UserSearchResult({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.totalKm = 0,
    this.isFriend = false,
    this.hasPendingRequest = false,
  });

  final String uid;
  final String displayName;
  final String? photoUrl;
  final double totalKm;
  final bool isFriend;
  final bool hasPendingRequest;
}
