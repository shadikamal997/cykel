/// CYKEL — AI Route Suggestions Domain Models
/// Smart route recommendations based on preferences, weather, and history

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../bike_share/domain/bike_share_station.dart';

// ─── Route Preference ─────────────────────────────────────────────────────────

enum RoutePreference {
  fastest,
  safest,
  scenic,
  bikeLanes,
  lessHills,
  lessTraffic;

  String get displayName {
    switch (this) {
      case RoutePreference.fastest:
        return 'Hurtigst';
      case RoutePreference.safest:
        return 'Sikrest';
      case RoutePreference.scenic:
        return 'Naturskøn';
      case RoutePreference.bikeLanes:
        return 'Cykelstier';
      case RoutePreference.lessHills:
        return 'Færre bakker';
      case RoutePreference.lessTraffic:
        return 'Mindre trafik';
    }
  }

  String get icon {
    switch (this) {
      case RoutePreference.fastest:
        return '⚡';
      case RoutePreference.safest:
        return '🛡️';
      case RoutePreference.scenic:
        return '🌳';
      case RoutePreference.bikeLanes:
        return '🚲';
      case RoutePreference.lessHills:
        return '⬇️';
      case RoutePreference.lessTraffic:
        return '🚗';
    }
  }
}

// ─── Weather Condition ────────────────────────────────────────────────────────

enum WeatherCondition {
  sunny,
  cloudy,
  rainy,
  windy,
  snowy,
  foggy;

  String get displayName {
    switch (this) {
      case WeatherCondition.sunny:
        return 'Sol';
      case WeatherCondition.cloudy:
        return 'Overskyet';
      case WeatherCondition.rainy:
        return 'Regn';
      case WeatherCondition.windy:
        return 'Vind';
      case WeatherCondition.snowy:
        return 'Sne';
      case WeatherCondition.foggy:
        return 'Tåge';
    }
  }

  String get icon {
    switch (this) {
      case WeatherCondition.sunny:
        return '☀️';
      case WeatherCondition.cloudy:
        return '☁️';
      case WeatherCondition.rainy:
        return '🌧️';
      case WeatherCondition.windy:
        return '💨';
      case WeatherCondition.snowy:
        return '❄️';
      case WeatherCondition.foggy:
        return '🌫️';
    }
  }
}

// ─── Time of Day ──────────────────────────────────────────────────────────────

enum TimeOfDay {
  earlyMorning, // 5-7
  morning,      // 7-10
  midday,       // 10-14
  afternoon,    // 14-17
  evening,      // 17-20
  night;        // 20-5

  String get displayName {
    switch (this) {
      case TimeOfDay.earlyMorning:
        return 'Tidlig morgen';
      case TimeOfDay.morning:
        return 'Morgen';
      case TimeOfDay.midday:
        return 'Middag';
      case TimeOfDay.afternoon:
        return 'Eftermiddag';
      case TimeOfDay.evening:
        return 'Aften';
      case TimeOfDay.night:
        return 'Nat';
    }
  }

  static TimeOfDay fromHour(int hour) {
    if (hour >= 5 && hour < 7) return TimeOfDay.earlyMorning;
    if (hour >= 7 && hour < 10) return TimeOfDay.morning;
    if (hour >= 10 && hour < 14) return TimeOfDay.midday;
    if (hour >= 14 && hour < 17) return TimeOfDay.afternoon;
    if (hour >= 17 && hour < 20) return TimeOfDay.evening;
    return TimeOfDay.night;
  }
}

// ─── Point of Interest (POI) for Tourist Mode ────────────────────────────────

enum POIType {
  landmark,      // Historical landmarks, monuments
  museum,        // Museums, galleries
  viewpoint,     // Scenic viewpoints, photo spots
  restaurant,    // Restaurants, cafes
  park,          // Parks, gardens
  culture,       // Cultural centers, theaters
  shopping,      // Shopping areas, markets
  waterfront;    // Harbor, beach, waterside areas

  String get icon {
    switch (this) {
      case POIType.landmark: return '🏛️';
      case POIType.museum: return '🏛️';
      case POIType.viewpoint: return '📸';
      case POIType.restaurant: return '🍽️';
      case POIType.park: return '🌳';
      case POIType.culture: return '🎭';
      case POIType.shopping: return '🛍️';
      case POIType.waterfront: return '⛵';
    }
  }

  String get displayName {
    switch (this) {
      case POIType.landmark: return 'Landmark';
      case POIType.museum: return 'Museum';
      case POIType.viewpoint: return 'Viewpoint';
      case POIType.restaurant: return 'Restaurant';
      case POIType.park: return 'Park';
      case POIType.culture: return 'Cultural';
      case POIType.shopping: return 'Shopping';
      case POIType.waterfront: return 'Waterfront';
    }
  }
}

class PointOfInterest {
  const PointOfInterest({
    required this.name,
    required this.type,
    required this.location,
    this.description,
    this.rating,
    this.distanceFromRouteM,
  });

  final String name;
  final POIType type;
  final LatLng location;
  final String? description;
  final double? rating; // 1-5 rating
  final double? distanceFromRouteM; // Distance from route in meters
}

// ─── Route Suggestion Reason ──────────────────────────────────────────────────

enum SuggestionReason {
  frequentlyUsed,
  optimalForWeather,
  lessTrafficNow,
  wellLit,
  moreBikeLanes,
  lessElevation,
  scenic,
  quickest,
  safestOption,
  basedOnHistory,
  popularRoute,
  commuteTime;

  String get displayName {
    switch (this) {
      case SuggestionReason.frequentlyUsed:
        return 'Din hyppigste rute';
      case SuggestionReason.optimalForWeather:
        return 'Optimal til vejret';
      case SuggestionReason.lessTrafficNow:
        return 'Mindre trafik nu';
      case SuggestionReason.wellLit:
        return 'Godt oplyst';
      case SuggestionReason.moreBikeLanes:
        return 'Flere cykelstier';
      case SuggestionReason.lessElevation:
        return 'Færre stigninger';
      case SuggestionReason.scenic:
        return 'Naturskøn';
      case SuggestionReason.quickest:
        return 'Hurtigste';
      case SuggestionReason.safestOption:
        return 'Sikrest valg';
      case SuggestionReason.basedOnHistory:
        return 'Baseret på din historik';
      case SuggestionReason.popularRoute:
        return 'Populær blandt cyklister';
      case SuggestionReason.commuteTime:
        return 'Perfekt til pendlertid';
    }
  }

  String get icon {
    switch (this) {
      case SuggestionReason.frequentlyUsed:
        return '⭐';
      case SuggestionReason.optimalForWeather:
        return '🌤️';
      case SuggestionReason.lessTrafficNow:
        return '🚗';
      case SuggestionReason.wellLit:
        return '💡';
      case SuggestionReason.moreBikeLanes:
        return '🚲';
      case SuggestionReason.lessElevation:
        return '⬇️';
      case SuggestionReason.scenic:
        return '🌳';
      case SuggestionReason.quickest:
        return '⚡';
      case SuggestionReason.safestOption:
        return '🛡️';
      case SuggestionReason.basedOnHistory:
        return '📊';
      case SuggestionReason.popularRoute:
        return '👥';
      case SuggestionReason.commuteTime:
        return '💼';
    }
  }
}

// ─── Route Suggestion ─────────────────────────────────────────────────────────

class RouteSuggestion {
  const RouteSuggestion({
    required this.id,
    required this.name,
    required this.startLocation,
    required this.endLocation,
    required this.estimatedDurationMinutes,
    required this.estimatedDistanceKm,
    required this.reasons,
    required this.score,
    this.startAddress,
    this.endAddress,
    this.polyline,
    this.elevationGainM,
    this.bikeLanePercentage,
    this.trafficLevel,
    this.lightingLevel,
    // Phase 4: Family-friendly attributes
    this.trafficFreePercentage,
    this.safetyScore,
    this.maxSpeed,
    this.hasPlaygrounds,
    // Phase 5: Tourist mode attributes
    this.pointsOfInterest = const [],
    this.scenicScore,
    this.culturalScore,
    this.waterfrontPercentage,
    // Phase 6: Bike share integration
    this.nearbyStations = const [],
  });

  final String id;
  final String name;
  final LatLng startLocation;
  final LatLng endLocation;
  final String? startAddress;
  final String? endAddress;
  final int estimatedDurationMinutes;
  final double estimatedDistanceKm;
  final List<SuggestionReason> reasons;
  final double score; // 0-100, higher is better match
  final String? polyline;
  final double? elevationGainM;
  final double? bikeLanePercentage;
  final int? trafficLevel; // 1-5
  final int? lightingLevel; // 1-5

  // Phase 4: Family-friendly attributes
  final double? trafficFreePercentage; // % of route on traffic-free paths (parks, dedicated paths)
  final int? safetyScore; // 1-5, combines traffic, lighting, surface quality
  final int? maxSpeed; // Maximum speed limit along route (km/h)
  final bool? hasPlaygrounds; // Route passes by playgrounds/parks

  // Phase 5: Tourist mode attributes
  final List<PointOfInterest> pointsOfInterest; // POIs along or near the route
  final int? scenicScore; // 1-5, how scenic/picturesque the route is
  final int? culturalScore; // 1-5, cultural/historical significance
  final double? waterfrontPercentage; // % of route along waterfront/harbor

  // Phase 6: Bike share integration
  final List<BikeShareStation> nearbyStations; // Bike share stations near start/end points

  String get primaryReason => reasons.isNotEmpty
      ? '${reasons.first.icon} ${reasons.first.displayName}'
      : '';

  // Phase 4: Family-friendly indicator
  bool get isFamilyFriendly {
    // Route is family-friendly if:
    // - Traffic-free percentage > 60% OR
    // - Safety score >= 4 AND bike lane percentage > 70%
    if (trafficFreePercentage != null && trafficFreePercentage! > 60) {
      return true;
    }
    if (safetyScore != null && safetyScore! >= 4 &&
        bikeLanePercentage != null && bikeLanePercentage! > 70) {
      return true;
    }
    return false;
  }

  // Phase 5: Tourist-friendly indicator
  bool get isTouristFriendly {
    // Route is tourist-friendly if:
    // - Scenic score >= 4 OR
    // - Cultural score >= 4 OR
    // - Has 3+ POIs OR
    // - Waterfront percentage > 40%
    if (scenicScore != null && scenicScore! >= 4) return true;
    if (culturalScore != null && culturalScore! >= 4) return true;
    if (pointsOfInterest.length >= 3) return true;
    if (waterfrontPercentage != null && waterfrontPercentage! > 40) return true;
    return false;
  }

  // Phase 5: Get POI count by type
  int getPoiCountByType(POIType type) {
    return pointsOfInterest.where((poi) => poi.type == type).length;
  }

  // Phase 6: Bike share helpers
  bool get hasBikeShareStations => nearbyStations.isNotEmpty;
  
  int get availableBikeShareCount {
    return nearbyStations.where((s) => s.hasAvailableVehicles).length;
  }
  
  List<BikeShareStation> getStationsByProvider(BikeShareProvider provider) {
    return nearbyStations.where((s) => s.provider == provider).toList();
  }
  
  bool get hasBikeShareAtStart {
    // Check if any station is within 500m of start location
    return nearbyStations.any((station) => 
      station.distanceFromPoint(startLocation) < 0.5);
  }
  
  bool get hasBikeShareAtEnd {
    // Check if any station is within 500m of end location
    return nearbyStations.any((station) => 
      station.distanceFromPoint(endLocation) < 0.5);
  }
}

// ─── User Route History ───────────────────────────────────────────────────────

class RouteHistory {
  const RouteHistory({
    required this.id,
    required this.startLocation,
    required this.endLocation,
    required this.usageCount,
    required this.lastUsedAt,
    required this.averageDurationMinutes,
    this.startAddress,
    this.endAddress,
    this.polyline,
    this.timeOfDayCounts = const {},
  });

  final String id;
  final LatLng startLocation;
  final LatLng endLocation;
  final String? startAddress;
  final String? endAddress;
  final int usageCount;
  final DateTime lastUsedAt;
  final int averageDurationMinutes;
  final String? polyline;
  final Map<TimeOfDay, int> timeOfDayCounts;

  factory RouteHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final startLoc = data['startLocation'] as GeoPoint;
    final endLoc = data['endLocation'] as GeoPoint;
    
    final todCounts = <TimeOfDay, int>{};
    if (data['timeOfDayCounts'] != null) {
      final counts = data['timeOfDayCounts'] as Map<String, dynamic>;
      for (final entry in counts.entries) {
        final tod = TimeOfDay.values.firstWhere(
          (e) => e.name == entry.key,
          orElse: () => TimeOfDay.midday,
        );
        todCounts[tod] = (entry.value as num).toInt();
      }
    }

    return RouteHistory(
      id: doc.id,
      startLocation: LatLng(startLoc.latitude, startLoc.longitude),
      endLocation: LatLng(endLoc.latitude, endLoc.longitude),
      startAddress: data['startAddress'] as String?,
      endAddress: data['endAddress'] as String?,
      usageCount: (data['usageCount'] as num).toInt(),
      lastUsedAt: (data['lastUsedAt'] as Timestamp).toDate(),
      averageDurationMinutes: (data['averageDurationMinutes'] as num).toInt(),
      polyline: data['polyline'] as String?,
      timeOfDayCounts: todCounts,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'startLocation': GeoPoint(startLocation.latitude, startLocation.longitude),
        'endLocation': GeoPoint(endLocation.latitude, endLocation.longitude),
        'startAddress': startAddress,
        'endAddress': endAddress,
        'usageCount': usageCount,
        'lastUsedAt': Timestamp.fromDate(lastUsedAt),
        'averageDurationMinutes': averageDurationMinutes,
        'polyline': polyline,
        'timeOfDayCounts': timeOfDayCounts.map((k, v) => MapEntry(k.name, v)),
      };
}

// ─── Route Preferences Settings ───────────────────────────────────────────────

class RouteSettings {
  const RouteSettings({
    this.preferences = const [RoutePreference.fastest],
    this.avoidHills = false,
    this.preferBikeLanes = true,
    this.preferLitRoutes = false,
    this.maxDurationMinutes,
    this.usageBasedSuggestions = true,
    this.weatherBasedSuggestions = true,
    this.timeBasedSuggestions = true,
    // Phase 4: Family mode preferences
    this.familyFriendlyMode = false,
    this.preferTrafficFree = false,
    this.maxSpeedLimit,
    // Phase 5: Tourist mode preferences
    this.touristMode = false,
    this.preferScenic = false,
    this.preferCultural = false,
    this.preferWaterfront = false,
    // Phase 6: Bike share preferences
    this.bikeShareMode = false,
    this.requireStationAtStart = false,
    this.requireStationAtEnd = false,
    this.preferredProviders = const [],
  });

  final List<RoutePreference> preferences;
  final bool avoidHills;
  final bool preferBikeLanes;
  final bool preferLitRoutes;
  final int? maxDurationMinutes;
  final bool usageBasedSuggestions;
  final bool weatherBasedSuggestions;
  final bool timeBasedSuggestions;
  
  // Phase 4: Family mode preferences
  final bool familyFriendlyMode; // Prioritize safe, low-traffic routes
  final bool preferTrafficFree; // Prefer parks and dedicated paths
  final int? maxSpeedLimit; // Filter routes by max speed limit (km/h)

  // Phase 5: Tourist mode preferences
  final bool touristMode; // Prioritize scenic, cultural routes with POIs
  final bool preferScenic; // Prefer scenic/picturesque routes
  final bool preferCultural; // Prefer routes with cultural/historical significance
  final bool preferWaterfront; // Prefer routes along water (harbor, lakes, coast)

  // Phase 6: Bike share preferences
  final bool bikeShareMode; // Filter routes with bike share stations
  final bool requireStationAtStart; // Only show routes with station at start
  final bool requireStationAtEnd; // Only show routes with station at end
  final List<BikeShareProvider> preferredProviders; // Filter by specific providers

  factory RouteSettings.fromFirestore(Map<String, dynamic> data) {
    return RouteSettings(
      preferences: (data['preferences'] as List<dynamic>?)
              ?.map((e) => RoutePreference.values.firstWhere(
                    (p) => p.name == e,
                    orElse: () => RoutePreference.fastest,
                  ))
              .toList() ??
          [RoutePreference.fastest],
      avoidHills: data['avoidHills'] as bool? ?? false,
      preferBikeLanes: data['preferBikeLanes'] as bool? ?? true,
      preferLitRoutes: data['preferLitRoutes'] as bool? ?? false,
      maxDurationMinutes: data['maxDurationMinutes'] as int?,
      usageBasedSuggestions: data['usageBasedSuggestions'] as bool? ?? true,
      weatherBasedSuggestions: data['weatherBasedSuggestions'] as bool? ?? true,
      timeBasedSuggestions: data['timeBasedSuggestions'] as bool? ?? true,
      // Phase 4
      familyFriendlyMode: data['familyFriendlyMode'] as bool? ?? false,
      preferTrafficFree: data['preferTrafficFree'] as bool? ?? false,
      maxSpeedLimit: data['maxSpeedLimit'] as int?,
      // Phase 5
      touristMode: data['touristMode'] as bool? ?? false,
      preferScenic: data['preferScenic'] as bool? ?? false,
      preferCultural: data['preferCultural'] as bool? ?? false,
      preferWaterfront: data['preferWaterfront'] as bool? ?? false,
      // Phase 6
      bikeShareMode: data['bikeShareMode'] as bool? ?? false,
      requireStationAtStart: data['requireStationAtStart'] as bool? ?? false,
      requireStationAtEnd: data['requireStationAtEnd'] as bool? ?? false,
      preferredProviders: (data['preferredProviders'] as List<dynamic>?)
              ?.map((e) => BikeShareProvider.values.firstWhere(
                    (p) => p.name == e,
                    orElse: () => BikeShareProvider.bycyklen,
                  ))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'preferences': preferences.map((p) => p.name).toList(),
        'avoidHills': avoidHills,
        'preferBikeLanes': preferBikeLanes,
        'preferLitRoutes': preferLitRoutes,
        'maxDurationMinutes': maxDurationMinutes,
        'usageBasedSuggestions': usageBasedSuggestions,
        'weatherBasedSuggestions': weatherBasedSuggestions,
        'timeBasedSuggestions': timeBasedSuggestions,
        // Phase 4
        'familyFriendlyMode': familyFriendlyMode,
        'preferTrafficFree': preferTrafficFree,
        'maxSpeedLimit': maxSpeedLimit,
        // Phase 5
        'touristMode': touristMode,
        'preferScenic': preferScenic,
        'preferCultural': preferCultural,
        'preferWaterfront': preferWaterfront,
        // Phase 6
        'bikeShareMode': bikeShareMode,
        'requireStationAtStart': requireStationAtStart,
        'requireStationAtEnd': requireStationAtEnd,
        'preferredProviders': preferredProviders.map((p) => p.name).toList(),
      };

  RouteSettings copyWith({
    List<RoutePreference>? preferences,
    bool? avoidHills,
    bool? preferBikeLanes,
    bool? preferLitRoutes,
    int? maxDurationMinutes,
    bool? usageBasedSuggestions,
    bool? weatherBasedSuggestions,
    bool? timeBasedSuggestions,
    bool? familyFriendlyMode,
    bool? preferTrafficFree,
    int? maxSpeedLimit,
    bool? touristMode,
    bool? preferScenic,
    bool? preferCultural,
    bool? preferWaterfront,
    bool? bikeShareMode,
    bool? requireStationAtStart,
    bool? requireStationAtEnd,
    List<BikeShareProvider>? preferredProviders,
  }) {
    return RouteSettings(
      preferences: preferences ?? this.preferences,
      avoidHills: avoidHills ?? this.avoidHills,
      preferBikeLanes: preferBikeLanes ?? this.preferBikeLanes,
      preferLitRoutes: preferLitRoutes ?? this.preferLitRoutes,
      maxDurationMinutes: maxDurationMinutes ?? this.maxDurationMinutes,
      usageBasedSuggestions: usageBasedSuggestions ?? this.usageBasedSuggestions,
      weatherBasedSuggestions: weatherBasedSuggestions ?? this.weatherBasedSuggestions,
      timeBasedSuggestions: timeBasedSuggestions ?? this.timeBasedSuggestions,
      familyFriendlyMode: familyFriendlyMode ?? this.familyFriendlyMode,
      preferTrafficFree: preferTrafficFree ?? this.preferTrafficFree,
      maxSpeedLimit: maxSpeedLimit ?? this.maxSpeedLimit,
      touristMode: touristMode ?? this.touristMode,
      preferScenic: preferScenic ?? this.preferScenic,
      preferCultural: preferCultural ?? this.preferCultural,
      preferWaterfront: preferWaterfront ?? this.preferWaterfront,
      bikeShareMode: bikeShareMode ?? this.bikeShareMode,
      requireStationAtStart: requireStationAtStart ?? this.requireStationAtStart,
      requireStationAtEnd: requireStationAtEnd ?? this.requireStationAtEnd,
      preferredProviders: preferredProviders ?? this.preferredProviders,
    );
  }
}

// ─── Saved Route ──────────────────────────────────────────────────────────────

class SavedRoute {
  const SavedRoute({
    required this.id,
    required this.name,
    required this.startLocation,
    required this.endLocation,
    required this.createdAt,
    this.startAddress,
    this.endAddress,
    this.polyline,
    this.distanceKm,
    this.estimatedDurationMinutes,
    this.notes,
    this.tags = const [],
  });

  final String id;
  final String name;
  final LatLng startLocation;
  final LatLng endLocation;
  final String? startAddress;
  final String? endAddress;
  final String? polyline;
  final double? distanceKm;
  final int? estimatedDurationMinutes;
  final DateTime createdAt;
  final String? notes;
  final List<String> tags;

  factory SavedRoute.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final startLoc = data['startLocation'] as GeoPoint;
    final endLoc = data['endLocation'] as GeoPoint;

    return SavedRoute(
      id: doc.id,
      name: data['name'] as String,
      startLocation: LatLng(startLoc.latitude, startLoc.longitude),
      endLocation: LatLng(endLoc.latitude, endLoc.longitude),
      startAddress: data['startAddress'] as String?,
      endAddress: data['endAddress'] as String?,
      polyline: data['polyline'] as String?,
      distanceKm: (data['distanceKm'] as num?)?.toDouble(),
      estimatedDurationMinutes: (data['estimatedDurationMinutes'] as num?)?.toInt(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      notes: data['notes'] as String?,
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'startLocation': GeoPoint(startLocation.latitude, startLocation.longitude),
        'endLocation': GeoPoint(endLocation.latitude, endLocation.longitude),
        'startAddress': startAddress,
        'endAddress': endAddress,
        'polyline': polyline,
        'distanceKm': distanceKm,
        'estimatedDurationMinutes': estimatedDurationMinutes,
        'createdAt': Timestamp.fromDate(createdAt),
        'notes': notes,
        'tags': tags,
      };
}
