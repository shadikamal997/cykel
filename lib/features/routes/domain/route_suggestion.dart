/// CYKEL — AI Route Suggestions Domain Models
/// Smart route recommendations based on preferences, weather, and history

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  String get primaryReason => reasons.isNotEmpty
      ? '${reasons.first.icon} ${reasons.first.displayName}'
      : '';
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
  });

  final List<RoutePreference> preferences;
  final bool avoidHills;
  final bool preferBikeLanes;
  final bool preferLitRoutes;
  final int? maxDurationMinutes;
  final bool usageBasedSuggestions;
  final bool weatherBasedSuggestions;
  final bool timeBasedSuggestions;

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
