/// CYKEL — Group Ride Events Domain Models
/// Events for organizing group cycling rides

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/l10n/l10n.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

/// Event difficulty levels
enum EventDifficulty {
  easy,      // Let - begyndervenlig
  moderate,  // Moderat - nogen erfaring
  challenging, // Udfordrende - erfarne
  hard;      // Hård - meget erfarne

  String get label {
    switch (this) {
      case EventDifficulty.easy: return 'Let';
      case EventDifficulty.moderate: return 'Moderat';
      case EventDifficulty.challenging: return 'Udfordrende';
      case EventDifficulty.hard: return 'Hård';
    }
  }

  String localizedLabel(BuildContext context) {
    final l10n = context.l10n;
    switch (this) {
      case EventDifficulty.easy: return l10n.difficultyEasy;
      case EventDifficulty.moderate: return l10n.difficultyModerate;
      case EventDifficulty.challenging: return l10n.difficultyChallenging;
      case EventDifficulty.hard: return l10n.difficultyHard;
    }
  }

  String get icon {
    switch (this) {
      case EventDifficulty.easy: return '🌱';
      case EventDifficulty.moderate: return '💪';
      case EventDifficulty.challenging: return '🔥';
      case EventDifficulty.hard: return '⚡';
    }
  }
}

/// Event types
enum EventType {
  social,        // Social ride
  training,      // Training group
  commute,       // Commute buddy
  race,          // Competitive race
  tour,          // Long distance tour
  beginner,      // Beginner friendly
  family,        // Family ride
  night,         // Night ride
  gravel;        // Gravel/MTB

  String get label {
    switch (this) {
      case EventType.social: return 'Social tur';
      case EventType.training: return 'Træningsgruppe';
      case EventType.commute: return 'Pendlermakker';
      case EventType.race: return 'Løb';
      case EventType.tour: return 'Langtur';
      case EventType.beginner: return 'Begyndervenlig';
      case EventType.family: return 'Familiecykling';
      case EventType.night: return 'Nattur';
      case EventType.gravel: return 'Gravel/MTB';
    }
  }

  String localizedLabel(BuildContext context) {
    final l10n = context.l10n;
    switch (this) {
      case EventType.social: return l10n.eventTypeSocial;
      case EventType.training: return l10n.eventTypeTraining;
      case EventType.commute: return l10n.eventTypeCommute;
      case EventType.race: return l10n.eventTypeRace;
      case EventType.tour: return l10n.eventTypeTour;
      case EventType.beginner: return l10n.eventTypeBeginner;
      case EventType.family: return l10n.eventTypeFamily;
      case EventType.night: return l10n.eventTypeNight;
      case EventType.gravel: return l10n.eventTypeGravel;
    }
  }

  String get icon {
    switch (this) {
      case EventType.social: return '🚴';
      case EventType.training: return '💪';
      case EventType.commute: return '🏢';
      case EventType.race: return '🏁';
      case EventType.tour: return '🗺️';
      case EventType.beginner: return '🌱';
      case EventType.family: return '👨‍👩‍👧';
      case EventType.night: return '🌙';
      case EventType.gravel: return '🏔️';
    }
  }
}

/// Event visibility
enum EventVisibility {
  public,      // Anyone can see and join
  friends,     // Only friends can see
  inviteOnly;  // Only invited users

  String get label {
    switch (this) {
      case EventVisibility.public: return 'Offentlig';
      case EventVisibility.friends: return 'Kun venner';
      case EventVisibility.inviteOnly: return 'Kun inviterede';
    }
  }

  String localizedLabel(BuildContext context) {
    final l10n = context.l10n;
    switch (this) {
      case EventVisibility.public: return l10n.visibilityPublic;
      case EventVisibility.friends: return l10n.visibilityFriends;
      case EventVisibility.inviteOnly: return l10n.visibilityInviteOnly;
    }
  }
}

/// Event status
enum EventStatus {
  upcoming,   // Not started yet
  active,     // Currently in progress
  completed,  // Finished
  cancelled;  // Cancelled by organizer

  String get label {
    switch (this) {
      case EventStatus.upcoming: return 'Kommende';
      case EventStatus.active: return 'I gang';
      case EventStatus.completed: return 'Afsluttet';
      case EventStatus.cancelled: return 'Aflyst';
    }
  }

  String localizedLabel(BuildContext context) {
    final l10n = context.l10n;
    switch (this) {
      case EventStatus.upcoming: return l10n.eventStatusUpcoming;
      case EventStatus.active: return l10n.eventStatusActive;
      case EventStatus.completed: return l10n.eventStatusCompleted;
      case EventStatus.cancelled: return l10n.eventStatusCancelled;
    }
  }
}

/// Participant RSVP status
enum ParticipantStatus {
  confirmed,  // Will attend
  waitlist,   // On waitlist
  maybe,      // Interested but uncertain
  declined,   // Can't attend
  noShow;     // Didn't show up

  String get label {
    switch (this) {
      case ParticipantStatus.confirmed: return 'Deltager';
      case ParticipantStatus.waitlist: return 'Venteliste';
      case ParticipantStatus.maybe: return 'Måske';
      case ParticipantStatus.declined: return 'Afmeldt';
      case ParticipantStatus.noShow: return 'Udeblev';
    }
  }

  String get icon {
    switch (this) {
      case ParticipantStatus.confirmed: return '✅';
      case ParticipantStatus.waitlist: return '⏳';
      case ParticipantStatus.maybe: return '❓';
      case ParticipantStatus.declined: return '❌';
      case ParticipantStatus.noShow: return '👻';
    }
  }
}

/// Chat message type
enum ChatMessageType {
  text,
  image,
  location,
  poll,
  system;
}

// ─── Meeting Point ────────────────────────────────────────────────────────────

class MeetingPoint {
  const MeetingPoint({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.name,
    this.instructions,
  });

  final double latitude;
  final double longitude;
  final String address;
  final String? name;
  final String? instructions;

  LatLng get latLng => LatLng(latitude, longitude);

  factory MeetingPoint.fromMap(Map<String, dynamic> map) {
    return MeetingPoint(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      address: map['address'] as String? ?? '',
      name: map['name'] as String?,
      instructions: map['instructions'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    if (name != null) 'name': name,
    if (instructions != null) 'instructions': instructions,
  };
}

// ─── Event Route ──────────────────────────────────────────────────────────────

class EventRoute {
  const EventRoute({
    required this.polyline,
    required this.distanceKm,
    this.elevationGain,
    this.estimatedDurationMinutes,
  });

  final String polyline; // Encoded polyline
  final double distanceKm;
  final double? elevationGain;
  final int? estimatedDurationMinutes;

  factory EventRoute.fromMap(Map<String, dynamic> map) {
    return EventRoute(
      polyline: map['polyline'] as String? ?? '',
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0,
      elevationGain: (map['elevationGain'] as num?)?.toDouble(),
      estimatedDurationMinutes: map['estimatedDurationMinutes'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
    'polyline': polyline,
    'distanceKm': distanceKm,
    if (elevationGain != null) 'elevationGain': elevationGain,
    if (estimatedDurationMinutes != null) 'estimatedDurationMinutes': estimatedDurationMinutes,
  };
}

// ─── Recurring Schedule ───────────────────────────────────────────────────────

class RecurringSchedule {
  const RecurringSchedule({
    required this.frequency,
    this.dayOfWeek,
    this.endDate,
  });

  final String frequency; // 'weekly', 'biWeekly', 'monthly'
  final int? dayOfWeek; // 1=Monday, 7=Sunday
  final DateTime? endDate;

  factory RecurringSchedule.fromMap(Map<String, dynamic> map) {
    return RecurringSchedule(
      frequency: map['frequency'] as String? ?? 'weekly',
      dayOfWeek: map['dayOfWeek'] as int?,
      endDate: map['endDate'] != null 
          ? (map['endDate'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'frequency': frequency,
    if (dayOfWeek != null) 'dayOfWeek': dayOfWeek,
    if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
  };
}

// ─── Main Event Model ─────────────────────────────────────────────────────────

class RideEvent {
  const RideEvent({
    required this.id,
    required this.title,
    required this.organizerId,
    required this.organizerName,
    required this.dateTime,
    required this.meetingPoint,
    required this.eventType,
    required this.difficulty,
    required this.visibility,
    required this.status,
    required this.createdAt,
    this.description,
    this.organizerPhotoUrl,
    this.route,
    this.distanceKm,
    this.durationMinutes,
    this.paceKmh,
    this.maxParticipants,
    this.currentParticipants = 0,
    this.recurring,
    this.imageUrl,
    this.tags = const [],
    this.isNoDrop = false,
    this.requiresLights = false,
  });

  final String id;
  final String title;
  final String? description;
  final String organizerId;
  final String organizerName;
  final String? organizerPhotoUrl;
  final DateTime dateTime;
  final MeetingPoint meetingPoint;
  final EventRoute? route;
  final double? distanceKm;
  final int? durationMinutes;
  final double? paceKmh;
  final EventType eventType;
  final EventDifficulty difficulty;
  final EventVisibility visibility;
  final EventStatus status;
  final int? maxParticipants;
  final int currentParticipants;
  final RecurringSchedule? recurring;
  final String? imageUrl;
  final List<String> tags;
  final bool isNoDrop; // No-drop policy - group waits for everyone
  final bool requiresLights;
  final DateTime createdAt;

  bool get isFull => maxParticipants != null && currentParticipants >= maxParticipants!;
  bool get isUpcoming => status == EventStatus.upcoming && dateTime.isAfter(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year && 
           dateTime.month == now.month && 
           dateTime.day == now.day;
  }

  String get formattedDate {
    final months = ['jan', 'feb', 'mar', 'apr', 'maj', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec'];
    final days = ['man', 'tir', 'ons', 'tor', 'fre', 'lør', 'søn'];
    return '${days[dateTime.weekday - 1]} ${dateTime.day}. ${months[dateTime.month - 1]}';
  }

  String get formattedTime {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String get participantText {
    if (maxParticipants != null) {
      return '$currentParticipants/$maxParticipants';
    }
    return '$currentParticipants';
  }

  factory RideEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RideEvent(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      organizerId: data['organizerId'] as String? ?? '',
      organizerName: data['organizerName'] as String? ?? 'Ukendt',
      organizerPhotoUrl: data['organizerPhotoUrl'] as String?,
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      meetingPoint: MeetingPoint.fromMap(data['meetingPoint'] as Map<String, dynamic>),
      route: data['route'] != null 
          ? EventRoute.fromMap(data['route'] as Map<String, dynamic>) 
          : null,
      distanceKm: (data['distanceKm'] as num?)?.toDouble(),
      durationMinutes: data['durationMinutes'] as int?,
      paceKmh: (data['paceKmh'] as num?)?.toDouble(),
      eventType: EventType.values.firstWhere(
        (e) => e.name == data['eventType'],
        orElse: () => EventType.social,
      ),
      difficulty: EventDifficulty.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => EventDifficulty.moderate,
      ),
      visibility: EventVisibility.values.firstWhere(
        (e) => e.name == data['visibility'],
        orElse: () => EventVisibility.public,
      ),
      status: EventStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => EventStatus.upcoming,
      ),
      maxParticipants: data['maxParticipants'] as int?,
      currentParticipants: data['currentParticipants'] as int? ?? 0,
      recurring: data['recurring'] != null 
          ? RecurringSchedule.fromMap(data['recurring'] as Map<String, dynamic>)
          : null,
      imageUrl: data['imageUrl'] as String?,
      tags: List<String>.from(data['tags'] ?? []),
      isNoDrop: data['isNoDrop'] as bool? ?? false,
      requiresLights: data['requiresLights'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'description': description,
    'organizerId': organizerId,
    'organizerName': organizerName,
    'organizerPhotoUrl': organizerPhotoUrl,
    'dateTime': Timestamp.fromDate(dateTime),
    'meetingPoint': meetingPoint.toMap(),
    'route': route?.toMap(),
    'distanceKm': distanceKm,
    'durationMinutes': durationMinutes,
    'paceKmh': paceKmh,
    'eventType': eventType.name,
    'difficulty': difficulty.name,
    'visibility': visibility.name,
    'status': status.name,
    'maxParticipants': maxParticipants,
    'currentParticipants': currentParticipants,
    'recurring': recurring?.toMap(),
    'imageUrl': imageUrl,
    'tags': tags,
    'isNoDrop': isNoDrop,
    'requiresLights': requiresLights,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  RideEvent copyWith({
    String? id,
    String? title,
    String? description,
    String? organizerId,
    String? organizerName,
    String? organizerPhotoUrl,
    DateTime? dateTime,
    MeetingPoint? meetingPoint,
    EventRoute? route,
    double? distanceKm,
    int? durationMinutes,
    double? paceKmh,
    EventType? eventType,
    EventDifficulty? difficulty,
    EventVisibility? visibility,
    EventStatus? status,
    int? maxParticipants,
    int? currentParticipants,
    RecurringSchedule? recurring,
    String? imageUrl,
    List<String>? tags,
    bool? isNoDrop,
    bool? requiresLights,
    DateTime? createdAt,
  }) {
    return RideEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      organizerPhotoUrl: organizerPhotoUrl ?? this.organizerPhotoUrl,
      dateTime: dateTime ?? this.dateTime,
      meetingPoint: meetingPoint ?? this.meetingPoint,
      route: route ?? this.route,
      distanceKm: distanceKm ?? this.distanceKm,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      paceKmh: paceKmh ?? this.paceKmh,
      eventType: eventType ?? this.eventType,
      difficulty: difficulty ?? this.difficulty,
      visibility: visibility ?? this.visibility,
      status: status ?? this.status,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      recurring: recurring ?? this.recurring,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      isNoDrop: isNoDrop ?? this.isNoDrop,
      requiresLights: requiresLights ?? this.requiresLights,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ─── Event Participant ────────────────────────────────────────────────────────

class EventParticipant {
  const EventParticipant({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.status,
    required this.joinedAt,
    this.userPhotoUrl,
    this.isOrganizer = false,
    this.isCoOrganizer = false,
    this.role,
    this.liveLocation,
    this.lastLocationUpdate,
  });

  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final ParticipantStatus status;
  final DateTime joinedAt;
  final bool isOrganizer;
  final bool isCoOrganizer;
  final String? role; // 'leader', 'sweeper', etc.
  final LatLng? liveLocation;
  final DateTime? lastLocationUpdate;

  factory EventParticipant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventParticipant(
      id: doc.id,
      eventId: data['eventId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Ukendt',
      userPhotoUrl: data['userPhotoUrl'] as String?,
      status: ParticipantStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ParticipantStatus.confirmed,
      ),
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOrganizer: data['isOrganizer'] as bool? ?? false,
      isCoOrganizer: data['isCoOrganizer'] as bool? ?? false,
      role: data['role'] as String?,
      liveLocation: data['liveLocation'] != null
          ? LatLng(
              (data['liveLocation']['latitude'] as num).toDouble(),
              (data['liveLocation']['longitude'] as num).toDouble(),
            )
          : null,
      lastLocationUpdate: data['lastLocationUpdate'] != null
          ? (data['lastLocationUpdate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'eventId': eventId,
    'userId': userId,
    'userName': userName,
    'userPhotoUrl': userPhotoUrl,
    'status': status.name,
    'joinedAt': Timestamp.fromDate(joinedAt),
    'isOrganizer': isOrganizer,
    'isCoOrganizer': isCoOrganizer,
    'role': role,
    if (liveLocation != null) 'liveLocation': {
      'latitude': liveLocation!.latitude,
      'longitude': liveLocation!.longitude,
    },
    if (lastLocationUpdate != null) 
      'lastLocationUpdate': Timestamp.fromDate(lastLocationUpdate!),
  };
}

// ─── Event Chat Message ───────────────────────────────────────────────────────

class EventChatMessage {
  const EventChatMessage({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.type,
    required this.timestamp,
    this.userPhotoUrl,
    this.text,
    this.imageUrl,
    this.location,
    this.pollOptions,
    this.pollVotes,
  });

  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final ChatMessageType type;
  final String? text;
  final String? imageUrl;
  final LatLng? location;
  final List<String>? pollOptions;
  final Map<String, List<String>>? pollVotes; // option -> userIds
  final DateTime timestamp;

  factory EventChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventChatMessage(
      id: doc.id,
      eventId: data['eventId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Ukendt',
      userPhotoUrl: data['userPhotoUrl'] as String?,
      type: ChatMessageType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => ChatMessageType.text,
      ),
      text: data['text'] as String?,
      imageUrl: data['imageUrl'] as String?,
      location: data['location'] != null
          ? LatLng(
              (data['location']['latitude'] as num).toDouble(),
              (data['location']['longitude'] as num).toDouble(),
            )
          : null,
      pollOptions: data['pollOptions'] != null
          ? List<String>.from(data['pollOptions'])
          : null,
      pollVotes: data['pollVotes'] != null
          ? (data['pollVotes'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, List<String>.from(v)),
            )
          : null,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'eventId': eventId,
    'userId': userId,
    'userName': userName,
    'userPhotoUrl': userPhotoUrl,
    'type': type.name,
    'text': text,
    'imageUrl': imageUrl,
    if (location != null) 'location': {
      'latitude': location!.latitude,
      'longitude': location!.longitude,
    },
    'pollOptions': pollOptions,
    'pollVotes': pollVotes,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}

// ─── Event Review ─────────────────────────────────────────────────────────────

class EventReview {
  const EventReview({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.createdAt,
    this.userPhotoUrl,
    this.comment,
  });

  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final int rating; // 1-5
  final String? comment;
  final DateTime createdAt;

  factory EventReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventReview(
      id: doc.id,
      eventId: data['eventId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Ukendt',
      userPhotoUrl: data['userPhotoUrl'] as String?,
      rating: data['rating'] as int? ?? 5,
      comment: data['comment'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'eventId': eventId,
    'userId': userId,
    'userName': userName,
    'userPhotoUrl': userPhotoUrl,
    'rating': rating,
    'comment': comment,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
