/// CYKEL — Events Provider
/// Firebase CRUD operations for group ride events

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../auth/providers/auth_providers.dart';
import '../domain/event.dart';
import '../../../core/utils/input_validator.dart';

// ─── Events Service ───────────────────────────────────────────────────────────

class EventsService {
  EventsService(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _eventsCol => 
      _db.collection('events');

  CollectionReference<Map<String, dynamic>> _participantsCol(String eventId) => 
      _eventsCol.doc(eventId).collection('participants');

  CollectionReference<Map<String, dynamic>> _chatCol(String eventId) => 
      _eventsCol.doc(eventId).collection('chat');

  CollectionReference<Map<String, dynamic>> _reviewsCol(String eventId) => 
      _eventsCol.doc(eventId).collection('reviews');

  // ─── Event CRUD ───────────────────────────────────────────────────────────

  /// Create a new event
  Future<String> createEvent(RideEvent event) async {
    // Validate inputs
    final titleValidation = InputValidator.validateEventTitle(event.title);
    if (!titleValidation.isValid) {
      throw ValidationException(titleValidation.errorMessage!);
    }
    
    final descValidation = InputValidator.validateEventDescription(event.description ?? '');
    if (!descValidation.isValid) {
      throw ValidationException(descValidation.errorMessage!);
    }
    
    // Create event with sanitized data
    final sanitizedEvent = event.copyWith(
      title: titleValidation.getOrThrow(),
      description: descValidation.getOrThrow(),
    );
    
    final doc = await _eventsCol.add(sanitizedEvent.toFirestore());
    
    // Add organizer as first participant
    await _participantsCol(doc.id).add(EventParticipant(
      id: '',
      eventId: doc.id,
      userId: event.organizerId,
      userName: event.organizerName,
      userPhotoUrl: event.organizerPhotoUrl,
      status: ParticipantStatus.confirmed,
      joinedAt: DateTime.now(),
      isOrganizer: true,
    ).toFirestore());

    return doc.id;
  }

  /// Update an event
  Future<void> updateEvent(RideEvent event) async {
    // Validate inputs
    final titleValidation = InputValidator.validateEventTitle(event.title);
    if (!titleValidation.isValid) {
      throw ValidationException(titleValidation.errorMessage!);
    }
    
    final descValidation = InputValidator.validateEventDescription(event.description ?? '');
    if (!descValidation.isValid) {
      throw ValidationException(descValidation.errorMessage!);
    }
    
    // Update with sanitized data
    final sanitizedEvent = event.copyWith(
      title: titleValidation.getOrThrow(),
      description: descValidation.getOrThrow(),
    );
    
    await _eventsCol.doc(event.id).update(sanitizedEvent.toFirestore());
  }

  /// Cancel an event
  Future<void> cancelEvent(String eventId) async {
    await _eventsCol.doc(eventId).update({
      'status': EventStatus.cancelled.name,
    });
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    // Delete sub-collections first
    final participants = await _participantsCol(eventId).get();
    for (final doc in participants.docs) {
      await doc.reference.delete();
    }
    
    final chat = await _chatCol(eventId).get();
    for (final doc in chat.docs) {
      await doc.reference.delete();
    }

    final reviews = await _reviewsCol(eventId).get();
    for (final doc in reviews.docs) {
      await doc.reference.delete();
    }

    await _eventsCol.doc(eventId).delete();
  }

  /// Get a single event
  Future<RideEvent?> getEvent(String eventId) async {
    final doc = await _eventsCol.doc(eventId).get();
    if (!doc.exists) return null;
    return RideEvent.fromFirestore(doc);
  }

  /// Stream a single event
  Stream<RideEvent?> streamEvent(String eventId) {
    return _eventsCol.doc(eventId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return RideEvent.fromFirestore(doc);
    });
  }

  // ─── Event Queries ────────────────────────────────────────────────────────

  /// Get upcoming public events
  Stream<List<RideEvent>> streamUpcomingEvents({int limit = 20}) {
    return _eventsCol
        .where('status', isEqualTo: EventStatus.upcoming.name)
        .where('visibility', isEqualTo: EventVisibility.public.name)
        .where('dateTime', isGreaterThan: Timestamp.now())
        .orderBy('dateTime')
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(RideEvent.fromFirestore).toList());
  }

  /// Get events by organizer
  Stream<List<RideEvent>> streamEventsByOrganizer(String userId) {
    return _eventsCol
        .where('organizerId', isEqualTo: userId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(RideEvent.fromFirestore).toList());
  }

  /// Get nearby events (simplified - for accurate results use geohash)
  Future<List<RideEvent>> getNearbyEvents(LatLng location, {double radiusKm = 50}) async {
    // Simple bounding box approximation
    // ~0.009 degrees = 1km at equator
    final latDelta = radiusKm * 0.009;
    final lngDelta = radiusKm * 0.009;

    final snapshot = await _eventsCol
        .where('status', isEqualTo: EventStatus.upcoming.name)
        .where('visibility', isEqualTo: EventVisibility.public.name)
        .where('dateTime', isGreaterThan: Timestamp.now())
        .get();

    return snapshot.docs
        .map(RideEvent.fromFirestore)
        .where((event) {
          final lat = event.meetingPoint.latitude;
          final lng = event.meetingPoint.longitude;
          return lat >= location.latitude - latDelta &&
                 lat <= location.latitude + latDelta &&
                 lng >= location.longitude - lngDelta &&
                 lng <= location.longitude + lngDelta;
        })
        .toList();
  }

  /// Search events by title
  Future<List<RideEvent>> searchEvents(String query) async {
    final snapshot = await _eventsCol
        .where('status', isEqualTo: EventStatus.upcoming.name)
        .where('visibility', isEqualTo: EventVisibility.public.name)
        .where('dateTime', isGreaterThan: Timestamp.now())
        .get();

    final lowerQuery = query.toLowerCase();
    return snapshot.docs
        .map(RideEvent.fromFirestore)
        .where((event) => 
            event.title.toLowerCase().contains(lowerQuery) ||
            (event.description?.toLowerCase().contains(lowerQuery) ?? false))
        .toList();
  }

  // ─── Participant Management ───────────────────────────────────────────────

  /// Join an event
  Future<void> joinEvent({
    required String eventId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
  }) async {
    // Check if already a participant
    final existing = await _participantsCol(eventId)
        .where('userId', isEqualTo: userId)
        .get();
    
    if (existing.docs.isNotEmpty) {
      // Update status if was declined
      await existing.docs.first.reference.update({
        'status': ParticipantStatus.confirmed.name,
      });
    } else {
      // Add new participant
      await _participantsCol(eventId).add(EventParticipant(
        id: '',
        eventId: eventId,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        status: ParticipantStatus.confirmed,
        joinedAt: DateTime.now(),
      ).toFirestore());

      // Increment participant count
      await _eventsCol.doc(eventId).update({
        'currentParticipants': FieldValue.increment(1),
      });
    }
  }

  /// Leave an event
  Future<void> leaveEvent(String eventId, String userId) async {
    final participants = await _participantsCol(eventId)
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in participants.docs) {
      final participant = EventParticipant.fromFirestore(doc);
      if (!participant.isOrganizer) {
        await doc.reference.delete();
        
        // Decrement participant count
        await _eventsCol.doc(eventId).update({
          'currentParticipants': FieldValue.increment(-1),
        });
      }
    }
  }

  /// Get event participants
  Stream<List<EventParticipant>> streamParticipants(String eventId) {
    return _participantsCol(eventId)
        .orderBy('joinedAt')
        .snapshots()
        .map((snap) => snap.docs.map(EventParticipant.fromFirestore).toList());
  }

  /// Check if user is participant
  Future<bool> isParticipant(String eventId, String userId) async {
    final existing = await _participantsCol(eventId)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: ParticipantStatus.confirmed.name)
        .get();
    return existing.docs.isNotEmpty;
  }

  /// Get user's participation status
  Future<ParticipantStatus?> getParticipationStatus(String eventId, String userId) async {
    final existing = await _participantsCol(eventId)
        .where('userId', isEqualTo: userId)
        .get();
    
    if (existing.docs.isEmpty) return null;
    return EventParticipant.fromFirestore(existing.docs.first).status;
  }

  /// Update live location during ride
  Future<void> updateLiveLocation(String eventId, String participantId, LatLng location) async {
    await _participantsCol(eventId).doc(participantId).update({
      'liveLocation': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'lastLocationUpdate': Timestamp.now(),
    });
  }

  // ─── User Events ──────────────────────────────────────────────────────────

  /// Get events the user has joined
  Future<List<RideEvent>> getUserJoinedEvents(String userId) async {
    // First get all event IDs where user is a confirmed participant
    final allEvents = await _eventsCol.get();
    final joinedEventIds = <String>[];

    for (final eventDoc in allEvents.docs) {
      final participants = await _participantsCol(eventDoc.id)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: ParticipantStatus.confirmed.name)
          .get();
      
      if (participants.docs.isNotEmpty) {
        joinedEventIds.add(eventDoc.id);
      }
    }

    if (joinedEventIds.isEmpty) return [];

    // Get the actual events
    final events = <RideEvent>[];
    for (final eventId in joinedEventIds) {
      final doc = await _eventsCol.doc(eventId).get();
      if (doc.exists) {
        events.add(RideEvent.fromFirestore(doc));
      }
    }

    // Sort by date and filter upcoming
    events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return events.where((e) => e.dateTime.isAfter(DateTime.now())).toList();
  }

  /// Stream user's upcoming joined events
  Stream<List<RideEvent>> streamUserUpcomingEvents(String userId) {
    // This is a simplified version - for production, consider denormalization
    return Stream.periodic(const Duration(seconds: 30))
        .asyncMap((_) => getUserJoinedEvents(userId));
  }

  // ─── Chat ─────────────────────────────────────────────────────────────────

  /// Send a chat message
  Future<void> sendMessage(EventChatMessage message) async {
    await _chatCol(message.eventId).add(message.toFirestore());
  }

  /// Stream chat messages
  Stream<List<EventChatMessage>> streamChat(String eventId, {int limit = 100}) {
    return _chatCol(eventId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(EventChatMessage.fromFirestore).toList());
  }

  // ─── Reviews ──────────────────────────────────────────────────────────────

  /// Add a review
  Future<void> addReview(EventReview review) async {
    // Check if user already reviewed
    final existing = await _reviewsCol(review.eventId)
        .where('userId', isEqualTo: review.userId)
        .get();

    if (existing.docs.isNotEmpty) {
      // Update existing
      await existing.docs.first.reference.update(review.toFirestore());
    } else {
      await _reviewsCol(review.eventId).add(review.toFirestore());
    }
  }

  /// Get reviews for an event
  Stream<List<EventReview>> streamReviews(String eventId) {
    return _reviewsCol(eventId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(EventReview.fromFirestore).toList());
  }

  /// Get average rating
  Future<double> getAverageRating(String eventId) async {
    final reviews = await _reviewsCol(eventId).get();
    if (reviews.docs.isEmpty) return 0;

    final total = reviews.docs
        .map((doc) => doc.data()['rating'] as int? ?? 5)
        .reduce((a, b) => a + b);
    
    return total / reviews.docs.length;
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final eventsServiceProvider = Provider<EventsService>((ref) {
  return EventsService(FirebaseFirestore.instance);
});

/// Stream of all upcoming public events
final upcomingEventsProvider = StreamProvider<List<RideEvent>>((ref) {
  return ref.watch(eventsServiceProvider).streamUpcomingEvents();
});

/// Stream of user's joined upcoming events
final userUpcomingEventsProvider = FutureProvider<List<RideEvent>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(eventsServiceProvider).getUserJoinedEvents(user.uid);
});

/// Stream events created by current user
final myCreatedEventsProvider = StreamProvider<List<RideEvent>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(eventsServiceProvider).streamEventsByOrganizer(user.uid);
});

/// Single event provider
final eventProvider = StreamProvider.family<RideEvent?, String>((ref, eventId) {
  return ref.watch(eventsServiceProvider).streamEvent(eventId);
});

/// Event participants provider
final eventParticipantsProvider = StreamProvider.family<List<EventParticipant>, String>((ref, eventId) {
  return ref.watch(eventsServiceProvider).streamParticipants(eventId);
});

/// Event chat provider
final eventChatProvider = StreamProvider.family<List<EventChatMessage>, String>((ref, eventId) {
  return ref.watch(eventsServiceProvider).streamChat(eventId);
});

/// Event reviews provider
final eventReviewsProvider = StreamProvider.family<List<EventReview>, String>((ref, eventId) {
  return ref.watch(eventsServiceProvider).streamReviews(eventId);
});

/// Check if current user is participant
final isParticipantProvider = FutureProvider.family<bool, String>((ref, eventId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return ref.watch(eventsServiceProvider).isParticipant(eventId, user.uid);
});

/// User's participation status for an event
final participationStatusProvider = FutureProvider.family<ParticipantStatus?, String>((ref, eventId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(eventsServiceProvider).getParticipationStatus(eventId, user.uid);
});

// ─── Favorites ────────────────────────────────────────────────────────────────

/// Provider that streams the user's favorite event IDs
final favoriteEventIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value({});
  
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('favoriteEvents')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
});

/// Check if a specific event is favorited
final isEventFavoritedProvider = Provider.family<bool, String>((ref, eventId) {
  final favorites = ref.watch(favoriteEventIdsProvider).valueOrNull ?? {};
  return favorites.contains(eventId);
});

/// Notifier for managing favorites
class FavoriteEventsNotifier extends StateNotifier<Set<String>> {
  FavoriteEventsNotifier(this._ref) : super({}) {
    _init();
  }

  final Ref _ref;

  void _init() {
    _ref.listen(favoriteEventIdsProvider, (_, next) {
      next.whenData((ids) => state = ids);
    });
  }

  Future<void> toggleFavorite(String eventId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favoriteEvents')
        .doc(eventId);

    final doc = await favRef.get();
    if (doc.exists) {
      await favRef.delete();
      state = {...state}..remove(eventId);
    } else {
      await favRef.set({
        'eventId': eventId,
        'addedAt': FieldValue.serverTimestamp(),
      });
      state = {...state, eventId};
    }
  }

  bool isFavorited(String eventId) => state.contains(eventId);
}

final favoriteEventsNotifierProvider =
    StateNotifierProvider<FavoriteEventsNotifier, Set<String>>((ref) {
  return FavoriteEventsNotifier(ref);
});

