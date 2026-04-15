/// CYKEL — Advanced Route Planning Domain Models
/// Multi-waypoint routes, elevation profiles, and weather-adaptive routing

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../bike_share/domain/bike_share_station.dart';

// ─── Waypoint ─────────────────────────────────────────────────────────────────

enum WaypointType {
  start,          // Route start point
  stop,           // Planned stop (café, viewpoint, etc.)
  poi,            // Point of interest
  restArea,       // Rest/water break
  bikeShare,      // Bike share station
  end;            // Route end point

  String get displayName {
    switch (this) {
      case WaypointType.start:
        return 'Start';
      case WaypointType.stop:
        return 'Stop';
      case WaypointType.poi:
        return 'Point of Interest';
      case WaypointType.restArea:
        return 'Rest Area';
      case WaypointType.bikeShare:
        return 'Bike Share';
      case WaypointType.end:
        return 'End';
    }
  }

  String get icon {
    switch (this) {
      case WaypointType.start:
        return '🚩';
      case WaypointType.stop:
        return '⏸️';
      case WaypointType.poi:
        return '📍';
      case WaypointType.restArea:
        return '☕';
      case WaypointType.bikeShare:
        return '🚲';
      case WaypointType.end:
        return '🏁';
    }
  }
}

class Waypoint {
  const Waypoint({
    required this.location,
    required this.type,
    required this.order,
    this.name,
    this.description,
    this.estimatedStopDurationMinutes,
    this.poiId,
    this.bikeShareStation,
    this.arrivalTime,
    this.departureTime,
  });

  final LatLng location;
  final WaypointType type;
  final int order; // 0-based order in the route
  final String? name;
  final String? description;
  final int? estimatedStopDurationMinutes;
  final String? poiId; // Reference to POI if type is poi
  final BikeShareStation? bikeShareStation;
  final DateTime? arrivalTime; // Estimated arrival
  final DateTime? departureTime; // Estimated departure

  factory Waypoint.fromFirestore(Map<String, dynamic> data) {
    final locationData = data['location'] as GeoPoint;
    
    return Waypoint(
      location: LatLng(locationData.latitude, locationData.longitude),
      type: WaypointType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => WaypointType.stop,
      ),
      order: (data['order'] as num).toInt(),
      name: data['name'] as String?,
      description: data['description'] as String?,
      estimatedStopDurationMinutes: (data['estimatedStopDurationMinutes'] as num?)?.toInt(),
      poiId: data['poiId'] as String?,
      arrivalTime: data['arrivalTime'] != null 
          ? (data['arrivalTime'] as Timestamp).toDate() 
          : null,
      departureTime: data['departureTime'] != null 
          ? (data['departureTime'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'location': GeoPoint(location.latitude, location.longitude),
        'type': type.name,
        'order': order,
        'name': name,
        'description': description,
        'estimatedStopDurationMinutes': estimatedStopDurationMinutes,
        'poiId': poiId,
        'arrivalTime': arrivalTime != null ? Timestamp.fromDate(arrivalTime!) : null,
        'departureTime': departureTime != null ? Timestamp.fromDate(departureTime!) : null,
      };

  Waypoint copyWith({
    LatLng? location,
    WaypointType? type,
    int? order,
    String? name,
    String? description,
    int? estimatedStopDurationMinutes,
    String? poiId,
    BikeShareStation? bikeShareStation,
    DateTime? arrivalTime,
    DateTime? departureTime,
  }) {
    return Waypoint(
      location: location ?? this.location,
      type: type ?? this.type,
      order: order ?? this.order,
      name: name ?? this.name,
      description: description ?? this.description,
      estimatedStopDurationMinutes: estimatedStopDurationMinutes ?? this.estimatedStopDurationMinutes,
      poiId: poiId ?? this.poiId,
      bikeShareStation: bikeShareStation ?? this.bikeShareStation,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      departureTime: departureTime ?? this.departureTime,
    );
  }
}

// ─── Elevation Profile ────────────────────────────────────────────────────────

class ElevationPoint {
  const ElevationPoint({
    required this.distanceKm,
    required this.elevationM,
  });

  final double distanceKm; // Distance from start
  final double elevationM; // Elevation in meters

  factory ElevationPoint.fromFirestore(Map<String, dynamic> data) {
    return ElevationPoint(
      distanceKm: (data['distanceKm'] as num).toDouble(),
      elevationM: (data['elevationM'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'distanceKm': distanceKm,
        'elevationM': elevationM,
      };
}

class ElevationProfile {
  const ElevationProfile({
    required this.points,
    required this.totalElevationGainM,
    required this.totalElevationLossM,
    required this.maxElevationM,
    required this.minElevationM,
  });

  final List<ElevationPoint> points;
  final double totalElevationGainM;
  final double totalElevationLossM;
  final double maxElevationM;
  final double minElevationM;

  double get averageGradePercent {
    if (points.isEmpty || points.length < 2) return 0.0;
    final totalDistance = points.last.distanceKm * 1000; // Convert to meters
    if (totalDistance == 0) return 0.0;
    return (totalElevationGainM / totalDistance) * 100;
  }

  /// Calculate difficulty rating (1-5) based on elevation gain and grade
  int get difficultyRating {
    if (totalElevationGainM < 50) return 1; // Flat
    if (totalElevationGainM < 150) return 2; // Easy hills
    if (totalElevationGainM < 300) return 3; // Moderate
    if (totalElevationGainM < 500) return 4; // Challenging
    return 5; // Very challenging
  }

  String get difficultyLabel {
    switch (difficultyRating) {
      case 1:
        return 'Flat';
      case 2:
        return 'Easy Hills';
      case 3:
        return 'Moderate';
      case 4:
        return 'Challenging';
      case 5:
        return 'Very Challenging';
      default:
        return 'Unknown';
    }
  }

  factory ElevationProfile.fromFirestore(Map<String, dynamic> data) {
    return ElevationProfile(
      points: (data['points'] as List<dynamic>?)
              ?.map((p) => ElevationPoint.fromFirestore(p as Map<String, dynamic>))
              .toList() ??
          [],
      totalElevationGainM: (data['totalElevationGainM'] as num).toDouble(),
      totalElevationLossM: (data['totalElevationLossM'] as num).toDouble(),
      maxElevationM: (data['maxElevationM'] as num).toDouble(),
      minElevationM: (data['minElevationM'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'points': points.map((p) => p.toFirestore()).toList(),
        'totalElevationGainM': totalElevationGainM,
        'totalElevationLossM': totalElevationLossM,
        'maxElevationM': maxElevationM,
        'minElevationM': minElevationM,
      };
}

// ─── Weather Conditions ───────────────────────────────────────────────────────

enum WeatherCondition {
  clear,
  partlyCloudy,
  cloudy,
  rain,
  heavyRain,
  snow,
  fog,
  windy;

  String get displayName {
    switch (this) {
      case WeatherCondition.clear:
        return 'Clear';
      case WeatherCondition.partlyCloudy:
        return 'Partly Cloudy';
      case WeatherCondition.cloudy:
        return 'Cloudy';
      case WeatherCondition.rain:
        return 'Rain';
      case WeatherCondition.heavyRain:
        return 'Heavy Rain';
      case WeatherCondition.snow:
        return 'Snow';
      case WeatherCondition.fog:
        return 'Fog';
      case WeatherCondition.windy:
        return 'Windy';
    }
  }

  String get icon {
    switch (this) {
      case WeatherCondition.clear:
        return '☀️';
      case WeatherCondition.partlyCloudy:
        return '⛅';
      case WeatherCondition.cloudy:
        return '☁️';
      case WeatherCondition.rain:
        return '🌧️';
      case WeatherCondition.heavyRain:
        return '⛈️';
      case WeatherCondition.snow:
        return '❄️';
      case WeatherCondition.fog:
        return '🌫️';
      case WeatherCondition.windy:
        return '💨';
    }
  }

  /// Whether this condition is suitable for cycling
  bool get isCyclingSuitable {
    switch (this) {
      case WeatherCondition.clear:
      case WeatherCondition.partlyCloudy:
      case WeatherCondition.cloudy:
        return true;
      case WeatherCondition.rain:
      case WeatherCondition.windy:
        return false;
      case WeatherCondition.heavyRain:
      case WeatherCondition.snow:
      case WeatherCondition.fog:
        return false;
    }
  }
}

class WeatherForecast {
  const WeatherForecast({
    required this.condition,
    required this.temperatureC,
    required this.windSpeedKmh,
    required this.precipitationChance,
    required this.timestamp,
    this.windDirection,
    this.humidity,
    this.uvIndex,
  });

  final WeatherCondition condition;
  final double temperatureC;
  final double windSpeedKmh;
  final int precipitationChance; // 0-100%
  final DateTime timestamp;
  final String? windDirection; // N, NE, E, SE, S, SW, W, NW
  final int? humidity; // 0-100%
  final int? uvIndex; // 0-11+

  /// Calculate cycling comfort score (0-100)
  int get cyclingComfortScore {
    int score = 100;

    // Temperature penalty (optimal 15-25°C)
    if (temperatureC < 10) {
      score -= ((10 - temperatureC) * 3).toInt();
    } else if (temperatureC > 28) {
      score -= ((temperatureC - 28) * 3).toInt();
    }

    // Wind penalty (>20 km/h gets harder)
    if (windSpeedKmh > 20) {
      score -= ((windSpeedKmh - 20) * 2).toInt();
    }

    // Precipitation penalty
    score -= precipitationChance ~/ 2;

    // Condition penalty
    if (!condition.isCyclingSuitable) {
      score -= 30;
    }

    return score.clamp(0, 100);
  }

  String get comfortLabel {
    final score = cyclingComfortScore;
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    if (score >= 20) return 'Poor';
    return 'Not Recommended';
  }

  factory WeatherForecast.fromFirestore(Map<String, dynamic> data) {
    return WeatherForecast(
      condition: WeatherCondition.values.firstWhere(
        (c) => c.name == data['condition'],
        orElse: () => WeatherCondition.clear,
      ),
      temperatureC: (data['temperatureC'] as num).toDouble(),
      windSpeedKmh: (data['windSpeedKmh'] as num).toDouble(),
      precipitationChance: (data['precipitationChance'] as num).toInt(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      windDirection: data['windDirection'] as String?,
      humidity: (data['humidity'] as num?)?.toInt(),
      uvIndex: (data['uvIndex'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'condition': condition.name,
        'temperatureC': temperatureC,
        'windSpeedKmh': windSpeedKmh,
        'precipitationChance': precipitationChance,
        'timestamp': Timestamp.fromDate(timestamp),
        'windDirection': windDirection,
        'humidity': humidity,
        'uvIndex': uvIndex,
      };
}

// ─── Traffic Conditions ───────────────────────────────────────────────────────

enum TrafficLevel {
  clear,      // Free flow
  light,      // Light traffic
  moderate,   // Moderate traffic
  heavy,      // Heavy traffic
  congested;  // Stop and go

  String get displayName {
    switch (this) {
      case TrafficLevel.clear:
        return 'Clear';
      case TrafficLevel.light:
        return 'Light';
      case TrafficLevel.moderate:
        return 'Moderate';
      case TrafficLevel.heavy:
        return 'Heavy';
      case TrafficLevel.congested:
        return 'Congested';
    }
  }

  String get icon {
    switch (this) {
      case TrafficLevel.clear:
        return '🟢';
      case TrafficLevel.light:
        return '🟡';
      case TrafficLevel.moderate:
        return '🟠';
      case TrafficLevel.heavy:
        return '🔴';
      case TrafficLevel.congested:
        return '🔴';
    }
  }

  /// Safety score for cycling (0-100, higher is safer)
  int get cyclingSafetyScore {
    switch (this) {
      case TrafficLevel.clear:
        return 100;
      case TrafficLevel.light:
        return 80;
      case TrafficLevel.moderate:
        return 60;
      case TrafficLevel.heavy:
        return 40;
      case TrafficLevel.congested:
        return 20;
    }
  }
}

class TrafficSegment {
  const TrafficSegment({
    required this.startLocation,
    required this.endLocation,
    required this.level,
    required this.averageSpeedKmh,
    this.delayMinutes = 0,
  });

  final LatLng startLocation;
  final LatLng endLocation;
  final TrafficLevel level;
  final double averageSpeedKmh;
  final int delayMinutes;

  factory TrafficSegment.fromFirestore(Map<String, dynamic> data) {
    final startData = data['startLocation'] as GeoPoint;
    final endData = data['endLocation'] as GeoPoint;

    return TrafficSegment(
      startLocation: LatLng(startData.latitude, startData.longitude),
      endLocation: LatLng(endData.latitude, endData.longitude),
      level: TrafficLevel.values.firstWhere(
        (l) => l.name == data['level'],
        orElse: () => TrafficLevel.moderate,
      ),
      averageSpeedKmh: (data['averageSpeedKmh'] as num).toDouble(),
      delayMinutes: (data['delayMinutes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'startLocation': GeoPoint(startLocation.latitude, startLocation.longitude),
        'endLocation': GeoPoint(endLocation.latitude, endLocation.longitude),
        'level': level.name,
        'averageSpeedKmh': averageSpeedKmh,
        'delayMinutes': delayMinutes,
      };
}

// ─── Advanced Route ───────────────────────────────────────────────────────────

class AdvancedRoute {
  const AdvancedRoute({
    required this.id,
    required this.name,
    required this.waypoints,
    required this.totalDistanceKm,
    required this.estimatedDurationMinutes,
    required this.createdAt,
    this.elevationProfile,
    this.weatherForecast,
    this.trafficSegments = const [],
    this.polyline,
    this.optimizedOrder,
    this.isRoundTrip = false,
    this.createdByUserId,
    this.tags = const [],
    this.notes,
  });

  final String id;
  final String name;
  final List<Waypoint> waypoints;
  final double totalDistanceKm;
  final int estimatedDurationMinutes;
  final ElevationProfile? elevationProfile;
  final WeatherForecast? weatherForecast;
  final List<TrafficSegment> trafficSegments;
  final String? polyline;
  final List<int>? optimizedOrder; // Optimized waypoint order
  final bool isRoundTrip;
  final String? createdByUserId;
  final List<String> tags;
  final String? notes;
  final DateTime createdAt;

  /// Get total stops (excluding start and end)
  int get totalStops => waypoints.where((w) => 
      w.type != WaypointType.start && w.type != WaypointType.end).length;

  /// Get total estimated stop time
  int get totalStopTimeMinutes {
    return waypoints
        .map((w) => w.estimatedStopDurationMinutes ?? 0)
        .fold(0, (total, duration) => total + duration);
  }

  /// Get total journey time including stops
  int get totalJourneyTimeMinutes => estimatedDurationMinutes + totalStopTimeMinutes;

  /// Check if route has elevation data
  bool get hasElevationData => elevationProfile != null;

  /// Check if route has weather data
  bool get hasWeatherData => weatherForecast != null;

  /// Check if route has traffic data
  bool get hasTrafficData => trafficSegments.isNotEmpty;

  /// Calculate overall route difficulty (1-5)
  int get routeDifficulty {
    int difficulty = 1;

    // Factor in elevation
    if (elevationProfile != null) {
      difficulty = (difficulty + elevationProfile!.difficultyRating) ~/ 2;
    }

    // Factor in distance
    if (totalDistanceKm > 50) {
      difficulty = (difficulty + 5) ~/ 2;
    } else if (totalDistanceKm > 30) {
      difficulty = (difficulty + 4) ~/ 2;
    } else if (totalDistanceKm > 15) {
      difficulty = (difficulty + 3) ~/ 2;
    }

    return difficulty.clamp(1, 5);
  }

  /// Get average traffic safety score
  int get averageTrafficSafety {
    if (trafficSegments.isEmpty) return 80; // Assume good if no data
    
    final scores = trafficSegments.map((s) => s.level.cyclingSafetyScore);
    return scores.reduce((a, b) => a + b) ~/ scores.length;
  }

  factory AdvancedRoute.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AdvancedRoute(
      id: doc.id,
      name: data['name'] as String,
      waypoints: (data['waypoints'] as List<dynamic>?)
              ?.map((w) => Waypoint.fromFirestore(w as Map<String, dynamic>))
              .toList() ??
          [],
      totalDistanceKm: (data['totalDistanceKm'] as num).toDouble(),
      estimatedDurationMinutes: (data['estimatedDurationMinutes'] as num).toInt(),
      elevationProfile: data['elevationProfile'] != null
          ? ElevationProfile.fromFirestore(data['elevationProfile'] as Map<String, dynamic>)
          : null,
      weatherForecast: data['weatherForecast'] != null
          ? WeatherForecast.fromFirestore(data['weatherForecast'] as Map<String, dynamic>)
          : null,
      trafficSegments: (data['trafficSegments'] as List<dynamic>?)
              ?.map((t) => TrafficSegment.fromFirestore(t as Map<String, dynamic>))
              .toList() ??
          [],
      polyline: data['polyline'] as String?,
      optimizedOrder: (data['optimizedOrder'] as List<dynamic>?)?.cast<int>(),
      isRoundTrip: data['isRoundTrip'] as bool? ?? false,
      createdByUserId: data['createdByUserId'] as String?,
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'waypoints': waypoints.map((w) => w.toFirestore()).toList(),
        'totalDistanceKm': totalDistanceKm,
        'estimatedDurationMinutes': estimatedDurationMinutes,
        'elevationProfile': elevationProfile?.toFirestore(),
        'weatherForecast': weatherForecast?.toFirestore(),
        'trafficSegments': trafficSegments.map((t) => t.toFirestore()).toList(),
        'polyline': polyline,
        'optimizedOrder': optimizedOrder,
        'isRoundTrip': isRoundTrip,
        'createdByUserId': createdByUserId,
        'tags': tags,
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  AdvancedRoute copyWith({
    String? name,
    List<Waypoint>? waypoints,
    double? totalDistanceKm,
    int? estimatedDurationMinutes,
    ElevationProfile? elevationProfile,
    WeatherForecast? weatherForecast,
    List<TrafficSegment>? trafficSegments,
    String? polyline,
    List<int>? optimizedOrder,
    bool? isRoundTrip,
    List<String>? tags,
    String? notes,
  }) {
    return AdvancedRoute(
      id: id,
      name: name ?? this.name,
      waypoints: waypoints ?? this.waypoints,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      elevationProfile: elevationProfile ?? this.elevationProfile,
      weatherForecast: weatherForecast ?? this.weatherForecast,
      trafficSegments: trafficSegments ?? this.trafficSegments,
      polyline: polyline ?? this.polyline,
      optimizedOrder: optimizedOrder ?? this.optimizedOrder,
      isRoundTrip: isRoundTrip ?? this.isRoundTrip,
      createdByUserId: createdByUserId,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}
