import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../services/location_service.dart';
import '../domain/family_location.dart';
import 'achievement_event_bus.dart';
import 'family_gamification_service.dart';

/// Service for managing family location tracking
class FamilyLocationService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final LocationService _locationService;

  StreamSubscription<LocationUpdate>? _locationSubscription;
  String? _currentRideId;
  List<LatLng> _currentRideRoute = [];
  double _currentRideDistance = 0;
  double _maxSpeed = 0;
  DateTime? _rideStartTime;
  Timer? _onlineStatusTimer;

  // Auto ride detection
  int _consecutiveMovingUpdates = 0;
  int _consecutiveStationaryUpdates = 0;
  static const int _rideStartThreshold = 3; // 3 consecutive moving updates
  static const int _rideEndThreshold = 5; // 5 consecutive stationary updates
  static const double _movingSpeedThreshold = 5.0; // km/h

  FamilyLocationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required LocationService locationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _locationService = locationService;

  String? get _currentUserId => _auth.currentUser?.uid;

  // ==========================================
  // Location Tracking
  // ==========================================

  /// Start tracking location for the current user
  /// This uploads location to Firestore for family members to see
  Future<void> startTracking(String familyId) async {
    if (_locationSubscription != null) return; // Already tracking

    final userId = _currentUserId;
    if (userId == null) return;

    // Set online status
    await _setOnlineStatus(familyId, userId, true);

    // Start periodic online status updates
    _onlineStatusTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _setOnlineStatus(familyId, userId, true),
    );

    // Subscribe to location updates
    _locationSubscription = _locationService.locationUpdateStream().listen(
      (update) async {
        await _handleLocationUpdate(familyId, userId, update);
      },
      onError: (e) {
        // Log error but continue tracking
        debugPrint('Location tracking error: $e');
      },
    );
  }

  /// Stop tracking location
  Future<void> stopTracking(String familyId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    _onlineStatusTimer?.cancel();
    _onlineStatusTimer = null;

    await _locationSubscription?.cancel();
    _locationSubscription = null;

    // Set offline status
    await _setOnlineStatus(familyId, userId, false);

    // End any active ride
    if (_currentRideId != null) {
      await _endRide(familyId, userId);
    }
  }

  /// Handle a location update
  Future<void> _handleLocationUpdate(
    String familyId,
    String userId,
    LocationUpdate update,
  ) async {
    final speedKmh = update.speed * 3.6;
    final isMoving = speedKmh > _movingSpeedThreshold;

    // Auto ride detection logic
    if (isMoving) {
      _consecutiveMovingUpdates++;
      _consecutiveStationaryUpdates = 0;

      // Start ride if moving consistently
      if (_currentRideId == null &&
          _consecutiveMovingUpdates >= _rideStartThreshold) {
        await _startRide(familyId, userId, update);
      }
    } else {
      _consecutiveStationaryUpdates++;
      _consecutiveMovingUpdates = 0;

      // End ride if stationary for too long
      if (_currentRideId != null &&
          _consecutiveStationaryUpdates >= _rideEndThreshold) {
        await _endRide(familyId, userId);
      }
    }

    // Update location in Firestore
    await _updateMemberLocation(familyId, userId, update);

    // If riding, add to route
    if (_currentRideId != null) {
      _currentRideRoute.add(update.position);
      if (_currentRideRoute.length >= 2) {
        final lastIdx = _currentRideRoute.length - 1;
        _currentRideDistance += _locationService.distanceBetween(
          _currentRideRoute[lastIdx - 1],
          _currentRideRoute[lastIdx],
        );
      }
      if (speedKmh > _maxSpeed) {
        _maxSpeed = speedKmh;
      }

      // Update ride in Firestore periodically (every 10 points)
      if (_currentRideRoute.length % 10 == 0) {
        await _updateRide(familyId);
      }
    }
  }

  /// Update member location in Firestore
  Future<void> _updateMemberLocation(
    String familyId,
    String userId,
    LocationUpdate update,
  ) async {
    final user = _auth.currentUser;

    await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('memberLocations')
        .doc(userId)
        .set({
      'memberName': user?.displayName ?? 'Unknown',
      'photoUrl': user?.photoURL,
      'location': GeoPoint(update.position.latitude, update.position.longitude),
      'bearing': update.bearing,
      'speed': update.speed,
      'altitude': update.altitude,
      'timestamp': FieldValue.serverTimestamp(),
      'isRiding': _currentRideId != null,
      'currentRideId': _currentRideId,
      'isOnline': true,
    }, SetOptions(merge: true));

    // Also store in location history (for unlimited retention)
    await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('memberLocations')
        .doc(userId)
        .collection('history')
        .add({
      'location': GeoPoint(update.position.latitude, update.position.longitude),
      'timestamp': FieldValue.serverTimestamp(),
      'speed': update.speed,
      'wasRiding': _currentRideId != null,
    });
  }

  /// Set online/offline status
  Future<void> _setOnlineStatus(
    String familyId,
    String userId,
    bool isOnline,
  ) async {
    await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('memberLocations')
        .doc(userId)
        .set({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ==========================================
  // Ride Management
  // ==========================================

  /// Start a new ride
  Future<void> _startRide(
    String familyId,
    String userId,
    LocationUpdate startLocation,
  ) async {
    final user = _auth.currentUser;
    final rideRef = _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('rides')
        .doc();

    _currentRideId = rideRef.id;
    _currentRideRoute = [startLocation.position];
    _currentRideDistance = 0;
    _maxSpeed = startLocation.speed * 3.6;
    _rideStartTime = DateTime.now();

    await rideRef.set({
      'memberId': userId,
      'memberName': user?.displayName ?? 'Unknown',
      'familyId': familyId,
      'startTime': FieldValue.serverTimestamp(),
      'startLocation': GeoPoint(
        startLocation.position.latitude,
        startLocation.position.longitude,
      ),
      'route': [
        GeoPoint(
          startLocation.position.latitude,
          startLocation.position.longitude,
        )
      ],
      'distanceKm': 0,
      'durationMinutes': 0,
      'avgSpeedKmh': 0,
      'maxSpeedKmh': _maxSpeed,
      'isActive': true,
    });

    // Send alert to family
    await _sendAlert(
      familyId: familyId,
      memberId: userId,
      memberName: user?.displayName ?? 'Unknown',
      type: FamilyAlertType.rideStarted,
      location: startLocation.position,
      message: '${user?.displayName ?? 'A family member'} started a ride',
    );
  }

  /// End the current ride
  Future<void> _endRide(String familyId, String userId) async {
    if (_currentRideId == null) return;

    final endTime = DateTime.now();
    final durationMinutes = _rideStartTime != null
        ? endTime.difference(_rideStartTime!).inMinutes
        : 0;
    final distanceKm = _currentRideDistance / 1000;
    final avgSpeed =
        durationMinutes > 0 ? (distanceKm / (durationMinutes / 60)) : 0.0;

    final user = _auth.currentUser;
    final lastPosition =
        _currentRideRoute.isNotEmpty ? _currentRideRoute.last : null;

    await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('rides')
        .doc(_currentRideId)
        .update({
      'endTime': FieldValue.serverTimestamp(),
      'endLocation': lastPosition != null
          ? GeoPoint(lastPosition.latitude, lastPosition.longitude)
          : null,
      'route': _currentRideRoute
          .map((p) => GeoPoint(p.latitude, p.longitude))
          .toList(),
      'distanceKm': distanceKm,
      'durationMinutes': durationMinutes,
      'avgSpeedKmh': avgSpeed,
      'maxSpeedKmh': _maxSpeed,
      'isActive': false,
    });

    // Send alert to family
    await _sendAlert(
      familyId: familyId,
      memberId: userId,
      memberName: user?.displayName ?? 'Unknown',
      type: FamilyAlertType.rideEnded,
      location: lastPosition,
      message:
          '${user?.displayName ?? 'A family member'} finished their ride (${distanceKm.toStringAsFixed(1)} km)',
    );

    // Check for achievements after ride completion
    final gamificationService = FamilyGamificationService();
    final completedRide = FamilyRide(
      id: _currentRideId!,
      memberId: userId,
      memberName: user?.displayName ?? 'Unknown',
      familyId: familyId,
      startTime: _rideStartTime ?? endTime,
      endTime: endTime,
      route: _currentRideRoute,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      avgSpeedKmh: avgSpeed,
      maxSpeedKmh: _maxSpeed,
      isActive: false,
      endLocation: lastPosition,
    );
    final newAchievements = await gamificationService.checkAchievementsAfterRide(familyId, completedRide);
    
    // Emit achievements for UI notifications
    achievementEventBus.emit(newAchievements);

    // Reset ride state
    _currentRideId = null;
    _currentRideRoute = [];
    _currentRideDistance = 0;
    _maxSpeed = 0;
    _rideStartTime = null;
  }

  /// Update ride data periodically
  Future<void> _updateRide(String familyId) async {
    if (_currentRideId == null) return;

    final durationMinutes = _rideStartTime != null
        ? DateTime.now().difference(_rideStartTime!).inMinutes
        : 0;
    final distanceKm = _currentRideDistance / 1000;
    final avgSpeed =
        durationMinutes > 0 ? (distanceKm / (durationMinutes / 60)) : 0.0;

    await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('rides')
        .doc(_currentRideId)
        .update({
      'route': _currentRideRoute
          .map((p) => GeoPoint(p.latitude, p.longitude))
          .toList(),
      'distanceKm': distanceKm,
      'durationMinutes': durationMinutes,
      'avgSpeedKmh': avgSpeed,
      'maxSpeedKmh': _maxSpeed,
    });
  }

  // ==========================================
  // Streaming Family Locations
  // ==========================================

  /// Stream all family members' locations
  Stream<List<MemberLocation>> watchFamilyLocations(String familyId) {
    return _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('memberLocations')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MemberLocation.fromFirestore(doc))
            .toList());
  }

  /// Stream a specific member's location
  Stream<MemberLocation?> watchMemberLocation(
      String familyId, String memberId) {
    return _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('memberLocations')
        .doc(memberId)
        .snapshots()
        .map((doc) => doc.exists ? MemberLocation.fromFirestore(doc) : null);
  }

  /// Get location history for a member
  Future<List<LocationHistoryEntry>> getMemberLocationHistory(
    String familyId,
    String memberId, {
    DateTime? since,
    int limit = 100,
  }) async {
    var query = _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('memberLocations')
        .doc(memberId)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (since != null) {
      query = query.where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(since));
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) =>
            LocationHistoryEntry.fromMap(doc.data()))
        .toList();
  }

  // ==========================================
  // Active Rides
  // ==========================================

  /// Stream active rides for a family
  Stream<List<FamilyRide>> watchActiveRides(String familyId) {
    return _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('rides')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FamilyRide.fromFirestore(doc)).toList());
  }

  /// Get ride history for a member
  Future<List<FamilyRide>> getMemberRideHistory(
    String familyId,
    String memberId, {
    int limit = 50,
  }) async {
    final snapshot = await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('rides')
        .where('memberId', isEqualTo: memberId)
        .orderBy('startTime', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => FamilyRide.fromFirestore(doc)).toList();
  }

  /// Get family ride history
  Future<List<FamilyRide>> getFamilyRideHistory(
    String familyId, {
    DateTime? since,
    int limit = 100,
  }) async {
    var query = _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('rides')
        .orderBy('startTime', descending: true)
        .limit(limit);

    if (since != null) {
      query = query.where('startTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(since));
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => FamilyRide.fromFirestore(doc)).toList();
  }

  // ==========================================
  // Alerts
  // ==========================================

  /// Send an alert to family members
  Future<void> _sendAlert({
    required String familyId,
    required String memberId,
    required String memberName,
    required FamilyAlertType type,
    LatLng? location,
    String? message,
  }) async {
    await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('alerts')
        .add({
      'familyId': familyId,
      'memberId': memberId,
      'memberName': memberName,
      'type': type.name,
      'location':
          location != null ? GeoPoint(location.latitude, location.longitude) : null,
      'timestamp': FieldValue.serverTimestamp(),
      'message': message,
      'isResolved': false,
    });

    // TODO: Send push notification to family admins
  }

  /// Send SOS alert (can be called directly from UI)
  Future<void> sendSosAlert(String familyId, LatLng location) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final user = _auth.currentUser;

    await _sendAlert(
      familyId: familyId,
      memberId: userId,
      memberName: user?.displayName ?? 'Unknown',
      type: FamilyAlertType.sosPressed,
      location: location,
      message: '🆘 ${user?.displayName ?? 'A family member'} pressed the SOS button!',
    );
  }

  /// Send crash alert (called by crash detection service)
  Future<void> sendCrashAlert(
    String familyId,
    LatLng location,
    String details,
    double speedAtCrash,
  ) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final user = _auth.currentUser;

    await _sendAlert(
      familyId: familyId,
      memberId: userId,
      memberName: user?.displayName ?? 'Unknown',
      type: FamilyAlertType.crashDetected,
      location: location,
      message: '⚠️ CRASH DETECTED: ${user?.displayName ?? 'A family member'} may have crashed at ${speedAtCrash.toStringAsFixed(0)} km/h. $details',
    );
  }

  /// Stream alerts for a family
  Stream<List<FamilyAlert>> watchAlerts(String familyId, {bool unresolvedOnly = true}) {
    var query = _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .limit(50);

    if (unresolvedOnly) {
      query = query.where('isResolved', isEqualTo: false);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => FamilyAlert.fromFirestore(doc)).toList());
  }

  /// Resolve an alert
  Future<void> resolveAlert(String familyId, String alertId) async {
    final userId = _currentUserId;

    await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('alerts')
        .doc(alertId)
        .update({
      'isResolved': true,
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolvedBy': userId,
    });
  }

  /// Get alert history (including resolved alerts)
  Future<List<FamilyAlert>> getAlertHistory(
    String familyId, {
    int limit = 100,
  }) async {
    final snapshot = await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => FamilyAlert.fromFirestore(doc)).toList();
  }

  // ==========================================
  // Safe Zones
  // ==========================================

  /// Add a safe zone
  Future<String> addSafeZone(SafeZone zone) async {
    final docRef = await _firestore
        .collection('familyAccounts')
        .doc(zone.familyId)
        .collection('safeZones')
        .add(zone.toFirestore());
    return docRef.id;
  }

  /// Update a safe zone
  Future<void> updateSafeZone(String familyId, String zoneId, SafeZone zone) async {
    await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('safeZones')
        .doc(zoneId)
        .update(zone.toFirestore());
  }

  /// Delete a safe zone
  Future<void> deleteSafeZone(String familyId, String zoneId) async {
    await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('safeZones')
        .doc(zoneId)
        .delete();
  }

  /// Stream safe zones for a family
  Stream<List<SafeZone>> watchSafeZones(String familyId) {
    return _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('safeZones')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SafeZone.fromFirestore(doc)).toList());
  }

  /// Check safe zone entries/exits and send alerts
  Future<void> checkSafeZones(
    String familyId,
    String memberId,
    String memberName,
    LatLng currentPosition,
    LatLng? previousPosition,
  ) async {
    final zonesSnapshot = await _firestore
        .collection('familyAccounts')
        .doc(familyId)
        .collection('safeZones')
        .where('isActive', isEqualTo: true)
        .get();

    for (final doc in zonesSnapshot.docs) {
      final zone = SafeZone.fromFirestore(doc);

      // Skip if zone doesn't apply to this member
      if (zone.appliesToMembers != null &&
          !zone.appliesToMembers!.contains(memberId)) {
        continue;
      }

      final wasInZone =
          previousPosition != null && zone.containsPosition(previousPosition);
      final isInZone = zone.containsPosition(currentPosition);

      // Entered zone
      if (!wasInZone && isInZone && zone.alertOnEnter) {
        await _sendAlert(
          familyId: familyId,
          memberId: memberId,
          memberName: memberName,
          type: FamilyAlertType.enteredSafeZone,
          location: currentPosition,
          message: '$memberName arrived at ${zone.name}',
        );
      }

      // Left zone
      if (wasInZone && !isInZone && zone.alertOnExit) {
        await _sendAlert(
          familyId: familyId,
          memberId: memberId,
          memberName: memberName,
          type: FamilyAlertType.leftSafeZone,
          location: currentPosition,
          message: '$memberName left ${zone.name}',
        );
      }
    }
  }

  // ==========================================
  // Manual Ride Control
  // ==========================================

  /// Manually start a ride (user-initiated)
  Future<void> startManualRide(String familyId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      final position = await _locationService.getCurrentLocation();
      final update = LocationUpdate(
        position: position,
        bearing: 0,
        speed: 0,
        altitude: 0,
      );
      await _startRide(familyId, userId, update);
    } catch (e) {
      debugPrint('Failed to start manual ride: $e');
    }
  }

  /// Manually end a ride (user-initiated)
  Future<void> endManualRide(String familyId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    await _endRide(familyId, userId);
  }

  /// Check if currently riding
  bool get isRiding => _currentRideId != null;

  /// Get current ride ID
  String? get currentRideId => _currentRideId;
}

// ==========================================
// Providers
// ==========================================

final familyLocationServiceProvider = Provider<FamilyLocationService>((ref) {
  return FamilyLocationService(
    locationService: ref.watch(locationServiceProvider),
  );
});

/// Provider for watching all family members' locations
final familyLocationsProvider = StreamProvider.family<List<MemberLocation>, String>(
  (ref, familyId) {
    final service = ref.watch(familyLocationServiceProvider);
    return service.watchFamilyLocations(familyId);
  },
);

/// Provider for watching a specific member's location
final memberLocationProvider =
    StreamProvider.family<MemberLocation?, ({String familyId, String memberId})>(
  (ref, params) {
    final service = ref.watch(familyLocationServiceProvider);
    return service.watchMemberLocation(params.familyId, params.memberId);
  },
);

/// Provider for watching active rides
final activeRidesProvider = StreamProvider.family<List<FamilyRide>, String>(
  (ref, familyId) {
    final service = ref.watch(familyLocationServiceProvider);
    return service.watchActiveRides(familyId);
  },
);

/// Provider for watching alerts
final familyAlertsProvider = StreamProvider.family<List<FamilyAlert>, String>(
  (ref, familyId) {
    final service = ref.watch(familyLocationServiceProvider);
    return service.watchAlerts(familyId);
  },
);

/// Provider for watching safe zones
final safeZonesProvider = StreamProvider.family<List<SafeZone>, String>(
  (ref, familyId) {
    final service = ref.watch(familyLocationServiceProvider);
    return service.watchSafeZones(familyId);
  },
);
