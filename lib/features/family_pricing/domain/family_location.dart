import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Real-time location of a family member
class MemberLocation {
  final String memberId;
  final String memberName;
  final String? photoUrl;
  final LatLng position;
  final double bearing; // Direction in degrees
  final double speed; // m/s
  final double altitude;
  final DateTime timestamp;
  final bool isRiding; // Currently on a ride
  final String? currentRideId;
  final bool isOnline; // Recently updated

  const MemberLocation({
    required this.memberId,
    required this.memberName,
    this.photoUrl,
    required this.position,
    this.bearing = 0,
    this.speed = 0,
    this.altitude = 0,
    required this.timestamp,
    this.isRiding = false,
    this.currentRideId,
    this.isOnline = true,
  });

  /// Convert speed from m/s to km/h
  double get speedKmh => speed * 3.6;

  /// Is biking (speed > 5 km/h)
  bool get isBiking => speedKmh > 5;

  /// Was updated in last 2 minutes
  bool get isRecentlyActive =>
      DateTime.now().difference(timestamp).inMinutes < 2;

  factory MemberLocation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final geoPoint = data['location'] as GeoPoint;
    return MemberLocation(
      memberId: doc.id,
      memberName: data['memberName'] as String? ?? 'Unknown',
      photoUrl: data['photoUrl'] as String?,
      position: LatLng(geoPoint.latitude, geoPoint.longitude),
      bearing: (data['bearing'] as num?)?.toDouble() ?? 0,
      speed: (data['speed'] as num?)?.toDouble() ?? 0,
      altitude: (data['altitude'] as num?)?.toDouble() ?? 0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRiding: data['isRiding'] as bool? ?? false,
      currentRideId: data['currentRideId'] as String?,
      isOnline: data['isOnline'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'memberName': memberName,
      'photoUrl': photoUrl,
      'location': GeoPoint(position.latitude, position.longitude),
      'bearing': bearing,
      'speed': speed,
      'altitude': altitude,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRiding': isRiding,
      'currentRideId': currentRideId,
      'isOnline': isOnline,
    };
  }

  MemberLocation copyWith({
    String? memberId,
    String? memberName,
    String? photoUrl,
    LatLng? position,
    double? bearing,
    double? speed,
    double? altitude,
    DateTime? timestamp,
    bool? isRiding,
    String? currentRideId,
    bool? isOnline,
  }) {
    return MemberLocation(
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      photoUrl: photoUrl ?? this.photoUrl,
      position: position ?? this.position,
      bearing: bearing ?? this.bearing,
      speed: speed ?? this.speed,
      altitude: altitude ?? this.altitude,
      timestamp: timestamp ?? this.timestamp,
      isRiding: isRiding ?? this.isRiding,
      currentRideId: currentRideId ?? this.currentRideId,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

/// A tracked family ride with route history
class FamilyRide {
  final String id;
  final String memberId;
  final String memberName;
  final String familyId;
  final DateTime startTime;
  final DateTime? endTime;
  final List<LatLng> route; // Path taken
  final double distanceKm;
  final int durationMinutes;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final bool isActive;
  final LatLng? startLocation;
  final LatLng? endLocation;
  final String? startAddress;
  final String? endAddress;

  const FamilyRide({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.familyId,
    required this.startTime,
    this.endTime,
    this.route = const [],
    this.distanceKm = 0,
    this.durationMinutes = 0,
    this.avgSpeedKmh = 0,
    this.maxSpeedKmh = 0,
    this.isActive = true,
    this.startLocation,
    this.endLocation,
    this.startAddress,
    this.endAddress,
  });

  factory FamilyRide.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final routeData = data['route'] as List<dynamic>? ?? [];

    return FamilyRide(
      id: doc.id,
      memberId: data['memberId'] as String,
      memberName: data['memberName'] as String? ?? 'Unknown',
      familyId: data['familyId'] as String,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      route: routeData.map((point) {
        if (point is GeoPoint) {
          return LatLng(point.latitude, point.longitude);
        }
        final p = point as Map<String, dynamic>;
        return LatLng(p['lat'] as double, p['lng'] as double);
      }).toList(),
      distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0,
      durationMinutes: data['durationMinutes'] as int? ?? 0,
      avgSpeedKmh: (data['avgSpeedKmh'] as num?)?.toDouble() ?? 0,
      maxSpeedKmh: (data['maxSpeedKmh'] as num?)?.toDouble() ?? 0,
      isActive: data['isActive'] as bool? ?? false,
      startLocation: data['startLocation'] != null
          ? LatLng(
              (data['startLocation'] as GeoPoint).latitude,
              (data['startLocation'] as GeoPoint).longitude,
            )
          : null,
      endLocation: data['endLocation'] != null
          ? LatLng(
              (data['endLocation'] as GeoPoint).latitude,
              (data['endLocation'] as GeoPoint).longitude,
            )
          : null,
      startAddress: data['startAddress'] as String?,
      endAddress: data['endAddress'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'familyId': familyId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'route': route.map((p) => GeoPoint(p.latitude, p.longitude)).toList(),
      'distanceKm': distanceKm,
      'durationMinutes': durationMinutes,
      'avgSpeedKmh': avgSpeedKmh,
      'maxSpeedKmh': maxSpeedKmh,
      'isActive': isActive,
      'startLocation': startLocation != null
          ? GeoPoint(startLocation!.latitude, startLocation!.longitude)
          : null,
      'endLocation': endLocation != null
          ? GeoPoint(endLocation!.latitude, endLocation!.longitude)
          : null,
      'startAddress': startAddress,
      'endAddress': endAddress,
    };
  }

  FamilyRide copyWith({
    String? id,
    String? memberId,
    String? memberName,
    String? familyId,
    DateTime? startTime,
    DateTime? endTime,
    List<LatLng>? route,
    double? distanceKm,
    int? durationMinutes,
    double? avgSpeedKmh,
    double? maxSpeedKmh,
    bool? isActive,
    LatLng? startLocation,
    LatLng? endLocation,
    String? startAddress,
    String? endAddress,
  }) {
    return FamilyRide(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      familyId: familyId ?? this.familyId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      route: route ?? this.route,
      distanceKm: distanceKm ?? this.distanceKm,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      isActive: isActive ?? this.isActive,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      startAddress: startAddress ?? this.startAddress,
      endAddress: endAddress ?? this.endAddress,
    );
  }
}

/// Location history entry for a member
class LocationHistoryEntry {
  final LatLng position;
  final DateTime timestamp;
  final double speed;
  final bool wasRiding;

  const LocationHistoryEntry({
    required this.position,
    required this.timestamp,
    this.speed = 0,
    this.wasRiding = false,
  });

  factory LocationHistoryEntry.fromMap(Map<String, dynamic> data) {
    final geoPoint = data['location'] as GeoPoint;
    return LocationHistoryEntry(
      position: LatLng(geoPoint.latitude, geoPoint.longitude),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      speed: (data['speed'] as num?)?.toDouble() ?? 0,
      wasRiding: data['wasRiding'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'location': GeoPoint(position.latitude, position.longitude),
      'timestamp': Timestamp.fromDate(timestamp),
      'speed': speed,
      'wasRiding': wasRiding,
    };
  }
}

/// Alert types for family safety
enum FamilyAlertType {
  rideStarted,
  rideEnded,
  sosPressed,
  crashDetected,
  enteredSafeZone,
  leftSafeZone,
  lowBattery,
  speedAlert,
  curfewViolation,
}

/// A safety alert for a family member
class FamilyAlert {
  final String id;
  final String familyId;
  final String memberId;
  final String memberName;
  final FamilyAlertType type;
  final LatLng? location;
  final DateTime timestamp;
  final String? message;
  final bool isResolved;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  const FamilyAlert({
    required this.id,
    required this.familyId,
    required this.memberId,
    required this.memberName,
    required this.type,
    this.location,
    required this.timestamp,
    this.message,
    this.isResolved = false,
    this.resolvedAt,
    this.resolvedBy,
  });

  String get typeDisplayName {
    switch (type) {
      case FamilyAlertType.rideStarted:
        return 'Started a ride';
      case FamilyAlertType.rideEnded:
        return 'Finished ride';
      case FamilyAlertType.sosPressed:
        return '🆘 SOS Alert';
      case FamilyAlertType.crashDetected:
        return '⚠️ Crash Detected';
      case FamilyAlertType.enteredSafeZone:
        return 'Entered safe zone';
      case FamilyAlertType.leftSafeZone:
        return 'Left safe zone';
      case FamilyAlertType.lowBattery:
        return 'Low battery';
      case FamilyAlertType.speedAlert:
        return 'Speed limit exceeded';
      case FamilyAlertType.curfewViolation:
        return 'Riding after curfew';
    }
  }

  bool get isUrgent =>
      type == FamilyAlertType.sosPressed ||
      type == FamilyAlertType.crashDetected;

  factory FamilyAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final geoPoint = data['location'] as GeoPoint?;

    return FamilyAlert(
      id: doc.id,
      familyId: data['familyId'] as String,
      memberId: data['memberId'] as String,
      memberName: data['memberName'] as String? ?? 'Unknown',
      type: FamilyAlertType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => FamilyAlertType.rideStarted,
      ),
      location: geoPoint != null
          ? LatLng(geoPoint.latitude, geoPoint.longitude)
          : null,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      message: data['message'] as String?,
      isResolved: data['isResolved'] as bool? ?? false,
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
      resolvedBy: data['resolvedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'familyId': familyId,
      'memberId': memberId,
      'memberName': memberName,
      'type': type.name,
      'location': location != null
          ? GeoPoint(location!.latitude, location!.longitude)
          : null,
      'timestamp': Timestamp.fromDate(timestamp),
      'message': message,
      'isResolved': isResolved,
      'resolvedAt':
          resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolvedBy': resolvedBy,
    };
  }
}

/// Safe zone (geofence) for family
class SafeZone {
  final String id;
  final String familyId;
  final String name; // "Home", "School", etc.
  final LatLng center;
  final double radiusMeters;
  final bool alertOnEnter;
  final bool alertOnExit;
  final bool isActive;
  final List<String>? appliesToMembers; // null = all members

  const SafeZone({
    required this.id,
    required this.familyId,
    required this.name,
    required this.center,
    this.radiusMeters = 100.0,
    this.alertOnEnter = true,
    this.alertOnExit = true,
    this.isActive = true,
    this.appliesToMembers,
  });

  factory SafeZone.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final geoPoint = data['center'] as GeoPoint;

    return SafeZone(
      id: doc.id,
      familyId: data['familyId'] as String,
      name: data['name'] as String,
      center: LatLng(geoPoint.latitude, geoPoint.longitude),
      radiusMeters: (data['radiusMeters'] as num?)?.toDouble() ?? 100.0,
      alertOnEnter: data['alertOnEnter'] as bool? ?? true,
      alertOnExit: data['alertOnExit'] as bool? ?? true,
      isActive: data['isActive'] as bool? ?? true,
      appliesToMembers: data['appliesToMembers'] != null
          ? List<String>.from(data['appliesToMembers'] as List)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'familyId': familyId,
      'name': name,
      'center': GeoPoint(center.latitude, center.longitude),
      'radiusMeters': radiusMeters,
      'alertOnEnter': alertOnEnter,
      'alertOnExit': alertOnExit,
      'isActive': isActive,
      'appliesToMembers': appliesToMembers,
    };
  }

  /// Check if a position is inside this zone
  bool containsPosition(LatLng position) {
    // Simple distance check using Haversine formula approximation
    const earthRadius = 6371000.0; // meters
    final dLat = _toRadians(position.latitude - center.latitude);
    final dLng = _toRadians(position.longitude - center.longitude);

    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(center.latitude)) *
            _cos(_toRadians(position.latitude)) *
            _sin(dLng / 2) *
            _sin(dLng / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    final distance = earthRadius * c;

    return distance <= radiusMeters;
  }

  double _toRadians(double degrees) => degrees * 3.141592653589793 / 180;
  double _sin(double x) => x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  double _cos(double x) => 1 - (x * x) / 2 + (x * x * x * x) / 24;
  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 3.141592653589793 / 2;
    if (x == 0 && y < 0) return -3.141592653589793 / 2;
    return 0;
  }

  double _atan(double x) {
    return x - (x * x * x) / 3 + (x * x * x * x * x) / 5;
  }
}
