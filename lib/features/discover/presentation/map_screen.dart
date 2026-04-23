/// CYKEL — Map Screen (Phase 3)
/// Full map experience: search, routing, navigation, layers.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../services/location_service.dart';
import '../../../services/tts_service.dart';
import '../../../services/navigation_notification_service.dart';
import '../../../services/battery_optimization_service.dart';
import '../../../services/route_cache_service.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/voice_settings_provider.dart';
import '../data/hazard_service.dart';
import '../domain/hazard_alert.dart';
import '../domain/crowd_hazard.dart';
import '../data/crowd_hazard_service.dart';
import './report_hazard_sheet.dart';
import './report_infrastructure_sheet.dart';
import './sos_sheet.dart';
import '../../../services/tile_prefetch_service.dart';
import '../../../services/frequent_destinations_service.dart';
import '../../../services/commute_suggestion_service.dart';
import '../../../core/providers/pending_route_provider.dart';
import '../data/places_service.dart';
import '../data/directions_service.dart';
import '../domain/route_result.dart';
import '../../../core/providers/bike_profile_provider.dart';
import '../data/saved_route_service.dart';
import '../data/wind_service.dart';
import '../data/wind_routing_service.dart';
import '../domain/bike_profile.dart';
import '../domain/saved_route.dart';
import '../data/wind_overlay_provider.dart';
import '../domain/route_hazard_checker.dart';
import '../../offline_maps/data/offline_maps_provider.dart';
import '../../offline_maps/data/local_tile_provider.dart';
import '../../home/data/quick_routes_provider.dart';
import '../../provider/data/provider_service.dart';
import '../../provider/domain/provider_enums.dart';
import '../../provider/domain/provider_model.dart';
import '../../../services/daylight_service.dart';

// ─── Design Colors ─────────────────────────────────────────────────────────────
const _kPrimaryColor = Color(0xFF4A7C59);
const _kPrimaryPressed = Color(0xFF3D6B4A);
const _kBackground = Color(0xFFFFFFFF);

// ─── Local Providers ─────────────────────────────────────────────────────────

final _userLocationProvider = StateProvider<LatLng?>((ref) => null);
final _routeResultProvider = StateProvider<RouteResult?>((ref) => null);
final _isNavigatingProvider = StateProvider<bool>((ref) => false);
final _currentStepProvider = StateProvider<int>((ref) => 0);
final _selectedDestProvider = StateProvider<PlaceResult?>((ref) => null);
final _destLatLngProvider = StateProvider<LatLng?>((ref) => null);
final _originPlaceProvider = StateProvider<PlaceResult?>(
  (ref) => null,
); // null = use GPS
final _bearingProvider = StateProvider<double>((ref) => 0);
final _isArrivedProvider = StateProvider<bool>((ref) => false);
final _showTrafficProvider = StateProvider<bool>((ref) => false);
final _showBicycleLaneProvider = StateProvider<bool>((ref) => true);
final _showTransitProvider = StateProvider<bool>((ref) => false);
final _speedProvider = StateProvider<double>((ref) => 0.0);
/// Manual override for night mode. `null` = auto-detect from daylight.
final _nightOverrideProvider = StateProvider<bool?>((ref) => null);
final _isNightProvider = Provider<bool>((ref) {
  final override = ref.watch(_nightOverrideProvider);
  if (override != null) return override;
  final daylightAsync = ref.watch(daylightInfoProvider);
  return daylightAsync.maybeWhen(
    data: (daylight) => daylight.isDark,
    orElse: () => false, // Default to day mode if loading/error
  );
});
final _distToStepProvider = StateProvider<double>((ref) => 0.0);
final _isReroutingProvider = StateProvider<bool>((ref) => false);
final _showChargingProvider = StateProvider<bool>((ref) => false);
final _showServiceProvider = StateProvider<bool>((ref) => false);
final _showShopsProvider = StateProvider<bool>((ref) => false);
final _showRentalProvider = StateProvider<bool>((ref) => false);
// Map type: Normal / Satellite / Terrain
final _mapTypeProvider = StateProvider<MapType>((ref) => MapType.normal);
// Alternative routes (up to 2) and which one is selected
final _altRoutesProvider = StateProvider<List<RouteResult>>((ref) => []);
final _selectedRouteIndexProvider = StateProvider<int>((ref) => 0);
// Route mode: fastest cycling path vs safest (quieter) roads
final _routeModeProvider = StateProvider<RouteMode>((ref) => RouteMode.fastest);
// POI tapped for the detail bottom sheet
final _selectedPoiProvider = StateProvider<PlaceResult?>((ref) => null);
// Intermediate stops for multi-leg routing (up to 3 waypoints, MVP: 1).
final _waypointsProvider = StateProvider<List<PlaceResult>>((ref) => []);

// POI marker sets — auto-fetch when their toggle and user location are set.
final _chargingMarkersProvider = FutureProvider<Set<Marker>>((ref) async {
  if (!ref.watch(_showChargingProvider)) return {};
  final center = ref.watch(_userLocationProvider);
  if (center == null) return {};
  final results = await ref
      .read(placesServiceProvider)
      .searchNearby(amenity: 'charging_station', center: center);
  return results
      .map(
        (r) => Marker(
          markerId: MarkerId('poi_charging_${r.placeId}'),
          position: r.latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow,
          ),
          onTap: () => ref.read(_selectedPoiProvider.notifier).state = r,
        ),
      )
      .toSet();
});
final _serviceMarkersProvider = FutureProvider<Set<Marker>>((ref) async {
  if (!ref.watch(_showServiceProvider)) return {};
  final center = ref.watch(_userLocationProvider);
  if (center == null) return {};
  final results = await ref
      .read(placesServiceProvider)
      .searchNearby(amenity: 'bicycle_repair_station', center: center);
  return results
      .map(
        (r) => Marker(
          markerId: MarkerId('poi_service_${r.placeId}'),
          position: r.latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          onTap: () => ref.read(_selectedPoiProvider.notifier).state = r,
        ),
      )
      .toSet();
});
final _shopsMarkersProvider = FutureProvider<Set<Marker>>((ref) async {
  if (!ref.watch(_showShopsProvider)) return {};
  final center = ref.watch(_userLocationProvider);
  if (center == null) return {};
  final results = await ref
      .read(placesServiceProvider)
      .searchNearby(shop: 'bicycle', center: center);
  return results
      .map(
        (r) => Marker(
          markerId: MarkerId('poi_shop_${r.placeId}'),
          position: r.latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          onTap: () => ref.read(_selectedPoiProvider.notifier).state = r,
        ),
      )
      .toSet();
});
final _rentalMarkersProvider = FutureProvider<Set<Marker>>((ref) async {
  if (!ref.watch(_showRentalProvider)) return {};
  final center = ref.watch(_userLocationProvider);
  if (center == null) return {};
  final results = await ref
      .read(placesServiceProvider)
      .searchNearby(amenity: 'bicycle_rental', center: center);
  return results
      .map(
        (r) => Marker(
          markerId: MarkerId('poi_rental_${r.placeId}'),
          position: r.latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
          onTap: () => ref.read(_selectedPoiProvider.notifier).state = r,
        ),
      )
      .toSet();
});

// ─── CYKEL Verified Provider Layer Toggles & Markers ─────────────────────────

final _showCykelRepairProvider = StateProvider<bool>((ref) => false);
final _showCykelShopProvider = StateProvider<bool>((ref) => false);
final _showCykelChargingProvider = StateProvider<bool>((ref) => false);
final _showCykelServiceProvider = StateProvider<bool>((ref) => false);
final _showCykelRentalProvider = StateProvider<bool>((ref) => false);

// ─── CYKEL Provider Filters ──────────────────────────────────────────────────

/// Filter: Only show providers currently open based on opening hours
final _filterOpenNowProvider = StateProvider<bool>((ref) => false);

/// Filter: Minimum rating (0.0 = show all)
final _filterMinRatingProvider = StateProvider<double>((ref) => 0.0);

// ─── Search This Area ─────────────────────────────────────────────────────────

/// Whether to show "Search this area" button (true when user pans away from location)
final _showSearchAreaButtonProvider = StateProvider<bool>((ref) => false);

/// Center point for area searches (set when user clicks "Search this area")
final _searchAreaCenterProvider = StateProvider<LatLng?>((ref) => null);

/// Effective center for provider searches (search area if set, otherwise user location)
final _providerSearchCenterProvider = Provider<LatLng?>((ref) {
  final searchCenter = ref.watch(_searchAreaCenterProvider);
  if (searchCenter != null) return searchCenter;
  return ref.watch(_userLocationProvider);
});

/// Currently selected CYKEL provider (shown via _CykelProviderDetailSheet).
final _selectedCykelProviderProvider = StateProvider<CykelProvider?>((ref) => null);

/// Helper: Apply active filters to a provider
bool _applyFilters(CykelProvider p, bool filterOpenNow, double filterMinRating) {
  if (filterOpenNow && !p.isOpenNow) return false;
  if (p.rating < filterMinRating) return false;
  return true;
}

final _cykelRepairMarkersProvider = StreamProvider<Set<Marker>>((ref) {
  if (!ref.watch(_showCykelRepairProvider)) return Stream.value({});
  final center = ref.watch(_providerSearchCenterProvider);
  if (center == null) return Stream.value({});
  final filterOpenNow = ref.watch(_filterOpenNowProvider);
  final filterMinRating = ref.watch(_filterMinRatingProvider);
  final svc = ref.read(providerServiceProvider);
  return svc
      .streamNearby(
        lat: center.latitude,
        lng: center.longitude,
      )
      .map((providers) => providers
          .where((p) => 
            p.isRepairShop && 
            p.latitude != 0 && 
            p.longitude != 0 &&
            _applyFilters(p, filterOpenNow, filterMinRating))
          .map(
            (p) => Marker(
              markerId: MarkerId('cykel_repair_${p.id}'),
              position: LatLng(p.latitude, p.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              onTap: () => ref.read(_selectedCykelProviderProvider.notifier).state = p,
            ),
          )
          .toSet());
});

final _cykelShopMarkersProvider = StreamProvider<Set<Marker>>((ref) {
  if (!ref.watch(_showCykelShopProvider)) return Stream.value({});
  final center = ref.watch(_providerSearchCenterProvider);
  if (center == null) return Stream.value({});
  final filterOpenNow = ref.watch(_filterOpenNowProvider);
  final filterMinRating = ref.watch(_filterMinRatingProvider);
  final svc = ref.read(providerServiceProvider);
  return svc
      .streamNearby(
        lat: center.latitude,
        lng: center.longitude,
      )
      .map((providers) => providers
          .where((p) => 
            p.isBikeShop && 
            p.latitude != 0 && 
            p.longitude != 0 &&
            _applyFilters(p, filterOpenNow, filterMinRating))
          .map(
            (p) => Marker(
              markerId: MarkerId('cykel_shop_${p.id}'),
              position: LatLng(p.latitude, p.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
              onTap: () => ref.read(_selectedCykelProviderProvider.notifier).state = p,
            ),
          )
          .toSet());
});

final _cykelChargingMarkersProvider = StreamProvider<Set<Marker>>((ref) {
  if (!ref.watch(_showCykelChargingProvider)) return Stream.value({});
  final center = ref.watch(_providerSearchCenterProvider);
  if (center == null) return Stream.value({});
  final filterOpenNow = ref.watch(_filterOpenNowProvider);
  final filterMinRating = ref.watch(_filterMinRatingProvider);
  final svc = ref.read(providerServiceProvider);
  return svc
      .streamNearby(
        lat: center.latitude,
        lng: center.longitude,
      )
      .map((providers) => providers
          .where((p) => 
            p.isChargingLocation && 
            p.latitude != 0 && 
            p.longitude != 0 &&
            _applyFilters(p, filterOpenNow, filterMinRating))
          .map(
            (p) => Marker(
              markerId: MarkerId('cykel_charging_${p.id}'),
              position: LatLng(p.latitude, p.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              onTap: () => ref.read(_selectedCykelProviderProvider.notifier).state = p,
            ),
          )
          .toSet());
});

final _cykelServiceMarkersProvider = StreamProvider<Set<Marker>>((ref) {
  if (!ref.watch(_showCykelServiceProvider)) return Stream.value({});
  final center = ref.watch(_providerSearchCenterProvider);
  if (center == null) return Stream.value({});
  final filterOpenNow = ref.watch(_filterOpenNowProvider);
  final filterMinRating = ref.watch(_filterMinRatingProvider);
  final svc = ref.read(providerServiceProvider);
  return svc
      .streamNearby(
        lat: center.latitude,
        lng: center.longitude,
      )
      .map((providers) => providers
          .where((p) => 
            p.isServicePoint && 
            p.latitude != 0 && 
            p.longitude != 0 &&
            _applyFilters(p, filterOpenNow, filterMinRating))
          .map(
            (p) => Marker(
              markerId: MarkerId('cykel_service_${p.id}'),
              position: LatLng(p.latitude, p.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
              onTap: () => ref.read(_selectedCykelProviderProvider.notifier).state = p,
            ),
          )
          .toSet());
});

final _cykelRentalMarkersProvider = StreamProvider<Set<Marker>>((ref) {
  if (!ref.watch(_showCykelRentalProvider)) return Stream.value({});
  final center = ref.watch(_providerSearchCenterProvider);
  if (center == null) return Stream.value({});
  final filterOpenNow = ref.watch(_filterOpenNowProvider);
  final filterMinRating = ref.watch(_filterMinRatingProvider);
  final svc = ref.read(providerServiceProvider);
  return svc
      .streamNearby(
        lat: center.latitude,
        lng: center.longitude,
      )
      .map((providers) => providers
          .where((p) => 
            p.isRental && 
            p.latitude != 0 && 
            p.longitude != 0 &&
            _applyFilters(p, filterOpenNow, filterMinRating))
          .map(
            (p) => Marker(
              markerId: MarkerId('cykel_rental_${p.id}'),
              position: LatLng(p.latitude, p.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
              onTap: () => ref.read(_selectedCykelProviderProvider.notifier).state = p,
            ),
          )
          .toSet());
});

// ─── Provider Counts ─────────────────────────────────────────────────────────

/// Count providers visible in each layer (for UI display like "Repair (5)")
final _cykelRepairCountProvider = Provider<int>((ref) {
  return ref.watch(_cykelRepairMarkersProvider).maybeWhen(
    data: (markers) => markers.length,
    orElse: () => 0,
  );
});

final _cykelShopCountProvider = Provider<int>((ref) {
  return ref.watch(_cykelShopMarkersProvider).maybeWhen(
    data: (markers) => markers.length,
    orElse: () => 0,
  );
});

final _cykelChargingCountProvider = Provider<int>((ref) {
  return ref.watch(_cykelChargingMarkersProvider).maybeWhen(
    data: (markers) => markers.length,
    orElse: () => 0,
  );
});

final _cykelServiceCountProvider = Provider<int>((ref) {
  return ref.watch(_cykelServiceMarkersProvider).maybeWhen(
    data: (markers) => markers.length,
    orElse: () => 0,
  );
});

final _cykelRentalCountProvider = Provider<int>((ref) {
  return ref.watch(_cykelRentalMarkersProvider).maybeWhen(
    data: (markers) => markers.length,
    orElse: () => 0,
  );
});

// Wind data for the current route — fetched at the midpoint from Open-Meteo
// (free, no API key). Auto-invalidates when the selected route changes.
final _routeWindProvider = FutureProvider.autoDispose<WindData?>((ref) async {
  final route = ref.watch(_routeResultProvider);
  if (route == null || route.polylinePoints.length < 2) return null;
  final mid = route.polylinePoints[route.polylinePoints.length ~/ 2];
  return ref.read(windServiceProvider).getWind(mid);
});

// ─── Wind Overlay Toggle ─────────────────────────────────────────────────────
final _showWindOverlayProvider = StateProvider<bool>((ref) => false);

// ─── Set-on-map mode ─────────────────────────────────────────────────────────
/// Which search field is currently being set by tapping the map centre.
enum _SetOnMapTarget { none, from, to }

// ─── Route, wind & profile helpers ───────────────────────────────────────────

/// Compass bearing (degrees clockwise from north) from [from] to [to].
double _bearingBetween(LatLng from, LatLng to) {
  final lat1 = from.latitude * math.pi / 180;
  final lat2 = to.latitude * math.pi / 180;
  final dLng = (to.longitude - from.longitude) * math.pi / 180;
  final y = math.sin(dLng) * math.cos(lat2);
  final x =
      math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

String _profileLabel(BuildContext context, BikeProfile p) => switch (p) {
  BikeProfile.city   => context.l10n.bikeProfileCity,
  BikeProfile.eBike  => context.l10n.bikeProfileEbike,
  BikeProfile.road   => context.l10n.bikeProfileRoad,
  BikeProfile.cargo  => context.l10n.bikeProfileCargo,
  BikeProfile.family => context.l10n.bikeProfileFamily,
};

Color _windColor(WindCondition c) => switch (c) {
  WindCondition.headwind => const Color(0xFFE53935),
  WindCondition.crosswind => const Color(0xFFF57C00),
  WindCondition.tailwind => const Color(0xFF43A047),
  WindCondition.calm => const Color(0xFF757575),
};

IconData _windIcon(WindCondition c) => switch (c) {
  WindCondition.headwind => Icons.arrow_back_rounded,
  WindCondition.crosswind => Icons.swap_horiz_rounded,
  WindCondition.tailwind => Icons.arrow_forward_rounded,
  WindCondition.calm => Icons.air_rounded,
};

String _windLabel(BuildContext context, WindData d, WindCondition c) {
  final speed = d.speedKmh.toStringAsFixed(0);
  return switch (c) {
    WindCondition.headwind => context.l10n.windHeadwind(speed),
    WindCondition.crosswind => context.l10n.windCrosswind(speed),
    WindCondition.tailwind => context.l10n.windTailwind(speed),
    WindCondition.calm => '',
  };
}

/// Saves or removes the active route from the user's saved routes.
void _toggleSaveRoute({
  required WidgetRef ref,
  required BuildContext context,
  required RouteResult route,
  required PlaceResult? dest,
  required LatLng? destLatLng,
  required PlaceResult? origin,
  required LatLng? userLoc,
  required bool isSaved,
  required String savedId,
}) {
  if (dest == null || destLatLng == null) return;
  final notifier = ref.read(savedRoutesProvider.notifier);
  if (isSaved) {
    notifier.delete(savedId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.routeUnsaved),
        duration: const Duration(seconds: 2),
      ),
    );
  } else {
    final originLoc = origin?.latLng ?? userLoc;
    notifier.save(
      SavedRoute(
        id: savedId,
        name: dest.text,
        originAddress: origin?.text ?? '',
        destAddress: dest.text,
        originLat: originLoc?.latitude ?? 0,
        originLng: originLoc?.longitude ?? 0,
        destLat: destLatLng.latitude,
        destLng: destLatLng.longitude,
        savedAt: DateTime.now(),
        distanceMeters: route.distanceMeters,
        durationSeconds: route.durationSeconds,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.routeSaved),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─── Localized navigation instruction helpers (C2) ────────────────────────────

/// Translates an OSRM direction modifier word into the current app locale.
String _localizeModifier(AppLocalizations l10n, String modifier) {
  return switch (modifier) {
    'left' => l10n.navModLeft,
    'right' => l10n.navModRight,
    'straight' => l10n.navModStraight,
    'slight left' => l10n.navModSlightLeft,
    'slight right' => l10n.navModSlightRight,
    'sharp left' => l10n.navModSharpLeft,
    'sharp right' => l10n.navModSharpRight,
    'uturn' => l10n.navModUturn,
    _ => modifier,
  };
}

/// Builds a fully locale-aware OSRM navigation instruction string.
///
/// Used as the [instructionBuilder] callback passed to [DirectionsService].
String _buildLocalizedInstruction(
  AppLocalizations l10n,
  String type,
  String modifier,
  String name,
) {
  final dir = modifier.isNotEmpty ? _localizeModifier(l10n, modifier) : '';
  final hasName = name.isNotEmpty;
  final hasDir = dir.isNotEmpty;
  switch (type) {
    case 'depart':
      return hasName
          ? l10n.navDepart(dir.isEmpty ? l10n.navModStraight : dir, name)
          : l10n.navDepartBlind(dir.isEmpty ? l10n.navModStraight : dir);
    case 'arrive':
      return hasName ? l10n.navArriveAt(name) : l10n.navArrive;
    case 'turn':
      return hasName && hasDir
          ? l10n.navTurn(dir, name)
          : hasDir
          ? l10n.navTurnBlind(dir)
          : l10n.navContinueBlind;
    case 'new name':
      return hasName ? l10n.navNewName(name) : l10n.navContinueBlind;
    case 'merge':
      return hasName ? l10n.navMerge(name) : l10n.navMergeBlind;
    case 'fork':
      return hasName && hasDir
          ? l10n.navFork(dir, name)
          : hasDir
          ? l10n.navForkBlind(dir)
          : l10n.navContinueBlind;
    case 'end of road':
      return hasName && hasDir
          ? l10n.navEndOfRoad(dir, name)
          : hasDir
          ? l10n.navEndOfRoadBlind(dir)
          : l10n.navContinueBlind;
    case 'roundabout':
    case 'rotary':
      return hasName ? l10n.navRoundaboutNamed(name) : l10n.navRoundabout;
    case 'exit roundabout':
    case 'exit rotary':
      return hasName
          ? l10n.navExitRoundaboutOnto(name)
          : l10n.navExitRoundabout;
    case 'use lane':
      return hasName && hasDir
          ? l10n.navUseLane(dir, name)
          : hasDir
          ? l10n.navUseLaneBlind(dir)
          : l10n.navContinueBlind;
    default:
      return hasName ? l10n.navContinue(name) : l10n.navContinueBlind;
  }
}

// ─── MapScreen ────────────────────────────────────────────────────────────────

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  StreamSubscription<LocationUpdate>? _navSubscription;
  bool _isCalculating = false;
  bool _showHint = true;
  final _searchPanelKey = GlobalKey<_RouteSearchPanelState>();
  BitmapDescriptor? _navArrow;
  BitmapDescriptor? _userDotIcon;
  BitmapDescriptor? _destMarkerIcon;
  int _nearestRouteIndex = 0;
  bool _rerouting = false;
  int _lastRerouteAtMs = 0;
  static const _kOffRouteM = 120.0;
  static const _kRerouteBackoffMs = 15000; // 15 s between reroute attempts
  // TTS 3-phase announcement tracking per step (keys: "{stepIdx}_500", etc.)
  final Set<String> _ttsAnnounced = {};
  // GPS lost detection
  int _lastLocationMs = 0;
  bool _gpsLostWarning = false;
  Timer? _gpsLostTimer;
  // Offline navigation state
  bool _isOffline = false;
  Timer? _connectivityTimer;
  // Hazard alerts (fetched at navigation start from weather API)
  List<HazardAlert> _hazardAlerts = [];
  bool _hazardDismissed = false;
  // Crowd-reported hazard stream during navigation
  StreamSubscription<List<CrowdHazardReport>>? _crowdHazardSub;
  List<CrowdHazardReport> _crowdHazards = [];
  // Reroute rate-limiting (H1): after _kMaxReroutesPerWindow in one window,
  // the session is frozen into offline-continuation mode.
  int _rerouteCount = 0;
  int _rerouteWindowStartMs = 0;
  static const _kMaxReroutesPerWindow = 5;
  static const _kRerouteWindowMs = 600000; // 10 minutes
  // Hazard stream center — re-subscribed when rider moves > 3 km (H5).
  LatLng? _lastHazardQueryCenter;
  // Waypoint arrival tracking for multi-stop routes (H4).
  int _nextWaypointIndex = 0;
  // TTS language fallback notification (C3) — shown at most once per session.
  bool _ttsLangFallbackNotified = false;
  // Location permission denied
  bool _permissionDenied = false;
  // POI layers enabled without location permission
  bool _showPoiLocationHint = false;
  // Set-on-map pin picker: which field is being set (none = inactive)
  _SetOnMapTarget _setOnMapTarget = _SetOnMapTarget.none;
  // Current centre of the map viewport (updated via onCameraMove)
  LatLng _mapCenter = _copenhagen;
  // ── Follow-user mode (Google Maps style) ─────────────────────────────────
  // When true the camera tracks the rider. When the user manually pans the map
  // it flips to false so the camera stops fighting gestures. A recenter FAB
  // re-enables tracking.
  bool _followUser = true;
  // Timestamp of the last programmatic animateCamera call (ms since epoch).
  // Used to filter out onCameraMoveStarted events that WE triggered.
  int _lastCameraMs = 0;
  // Minimal dark map style
  static const _kDarkMapStyle =
      '[{"elementType":"geometry","stylers":[{"color":"#1d2c4d"}]},'
      '{"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},'
      '{"elementType":"labels.text.stroke","stylers":[{"color":"#1a3646"}]},'
      '{"featureType":"road","elementType":"geometry","stylers":[{"color":"#304a7d"}]},'
      '{"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},'
      '{"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1626"}]},'
      '{"featureType":"poi","elementType":"geometry","stylers":[{"color":"#283d6a"}]}]';

  static const _copenhagen = LatLng(55.6761, 12.5683);

  @override
  void initState() {
    super.initState();
    // Hide long-press hint after 5 seconds.
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showHint = false);
    });
    // Pre-build marker icons asynchronously.
    _buildUserDot().then((icon) {
      if (mounted && icon != null) setState(() => _userDotIcon = icon);
    });
    _buildDestMarker().then((icon) {
      if (mounted && icon != null) setState(() => _destMarkerIcon = icon);
    });
    // Offer to resume an interrupted navigation session (e.g. app killed mid-ride).
    _checkResumeNavigation();
  }

  @override
  void dispose() {
    _navSubscription?.cancel();
    _gpsLostTimer?.cancel();
    _connectivityTimer?.cancel();
    _crowdHazardSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// Draws a filled chevron/arrow pointing north and bakes it into a BitmapDescriptor.
  Future<BitmapDescriptor?> _buildNavArrow() async {
    try {
      const sz = 72.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final fillPaint = Paint()..color = _kPrimaryColor;
      final strokePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round;
      final path = Path()
        ..moveTo(sz * 0.50, sz * 0.04) // tip (top / north)
        ..lineTo(sz * 0.88, sz * 0.80) // bottom-right
        ..lineTo(sz * 0.50, sz * 0.56) // inner notch
        ..lineTo(sz * 0.12, sz * 0.80) // bottom-left
        ..close();
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);
      final picture = recorder.endRecording();
      final image = await picture.toImage(sz.toInt(), sz.toInt());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return null;
      return BitmapDescriptor.bytes(bytes.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  /// Draws a blue pulsing-style dot (static) for the user's GPS position.
  Future<BitmapDescriptor?> _buildUserDot() async {
    try {
      const sz = 48.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      // Outer halo
      canvas.drawCircle(
        const Offset(sz / 2, sz / 2),
        sz / 2,
        Paint()..color = const Color(0x334A90E2),
      );
      // White ring
      canvas.drawCircle(
        const Offset(sz / 2, sz / 2),
        sz * 0.36,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );
      // Blue fill
      canvas.drawCircle(
        const Offset(sz / 2, sz / 2),
        sz * 0.27,
        Paint()..color = const Color(0xFF4A90E2),
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(sz.toInt(), sz.toInt());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return null;
      return BitmapDescriptor.bytes(bytes.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  /// Draws a red teardrop destination pin via canvas.
  Future<BitmapDescriptor?> _buildDestMarker() async {
    try {
      const w = 40.0;
      const h = 56.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final fillPaint = Paint()..color = const Color(0xFFE53935);
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      // Shadow ellipse at base
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(w / 2, h - 5),
          width: 18,
          height: 8,
        ),
        shadowPaint,
      );
      // Teardrop path
      final path = Path()
        ..moveTo(w / 2, h)
        ..cubicTo(w * 0.1, h * 0.75, 0, h * 0.45, 0, w / 2)
        ..arcTo(const Rect.fromLTWH(0, 0, w, w), math.pi, math.pi, false)
        ..cubicTo(w, h * 0.45, w * 0.9, h * 0.75, w / 2, h)
        ..close();
      canvas.drawPath(path, fillPaint);
      // White inner dot
      canvas.drawCircle(
        const Offset(w / 2, w / 2),
        w * 0.22,
        Paint()..color = Colors.white,
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(w.toInt(), h.toInt());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return null;
      return BitmapDescriptor.bytes(bytes.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  // ── Ramer-Douglas-Peucker polyline simplification ──────────────────────────
  List<LatLng> _simplifyPolyline(List<LatLng> pts, {double epsilon = 0.00003}) {
    if (pts.length < 3) return pts;
    double maxDist = 0;
    int idx = 0;
    final end = pts.length - 1;
    for (int i = 1; i < end; i++) {
      final d = _perpDist(pts[i], pts[0], pts[end]);
      if (d > maxDist) {
        maxDist = d;
        idx = i;
      }
    }
    if (maxDist > epsilon) {
      final left = _simplifyPolyline(pts.sublist(0, idx + 1), epsilon: epsilon);
      final right = _simplifyPolyline(pts.sublist(idx), epsilon: epsilon);
      return [...left.sublist(0, left.length - 1), ...right];
    }
    return [pts.first, pts.last];
  }

  double _perpDist(LatLng p, LatLng a, LatLng b) {
    final dx = b.longitude - a.longitude;
    final dy = b.latitude - a.latitude;
    if (dx == 0 && dy == 0) {
      return math.sqrt(
        math.pow(p.longitude - a.longitude, 2) +
            math.pow(p.latitude - a.latitude, 2),
      );
    }
    final t =
        ((p.longitude - a.longitude) * dx + (p.latitude - a.latitude) * dy) /
        (dx * dx + dy * dy);
    final tc = t.clamp(0.0, 1.0);
    return math.sqrt(
      math.pow(p.longitude - (a.longitude + tc * dx), 2) +
          math.pow(p.latitude - (a.latitude + tc * dy), 2),
    );
  }

  Future<void> _moveToUser() async {
    try {
      final loc = await ref.read(locationServiceProvider).getCurrentLocation();
      if (mounted) setState(() => _permissionDenied = false);
      ref.read(_userLocationProvider.notifier).state = loc;
      // Reset search area to use user location
      ref.read(_searchAreaCenterProvider.notifier).state = null;
      ref.read(_showSearchAreaButtonProvider.notifier).state = false;
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 15));
      // Reverse-geocode to populate FROM field with street address.
      final lang = ref.read(localeProvider).languageCode;
      final place = await ref
          .read(placesServiceProvider)
          .reverseGeocode(loc, language: lang);
      if (place != null) {
        _searchPanelKey.currentState?.setFromAddress(place.text);
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        final isDenied =
            msg.toLowerCase().contains('permission') ||
            msg.toLowerCase().contains('denied');
        setState(() => _permissionDenied = isDenied);
        if (!isDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  /// Calculate distance between two coordinates in kilometers (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) * math.cos(_degToRad(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180);

  Future<void> _calculateRoute(
    PlaceResult dest, {
    bool isReroute = false,
  }) async {
    if (_isCalculating && !isReroute) return;
    if (!isReroute) setState(() => _isCalculating = true);

    try {
      // Resolve origin: custom place or GPS
      final originPlace = ref.read(_originPlaceProvider);
      LatLng? origin;

      if (originPlace != null) {
        origin = originPlace.latLng;
      } else {
        origin = ref.read(_userLocationProvider);
        if (origin == null) {
          await _moveToUser();
          origin = ref.read(_userLocationProvider);
        }
      }

      if (origin == null) {
        if (mounted && !isReroute) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.locationDisabled),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      ref.read(_destLatLngProvider.notifier).state = dest.latLng;

      // Pass any intermediate waypoints to the routing service.
      final waypoints = ref
          .read(_waypointsProvider)
          .map((p) => p.latLng)
          .toList();
      // Build a locale-aware instruction builder so OSRM steps are spoken in
      // the correct language (C2).
      if (!mounted) return;
      final l10n = context.l10n;
      final routeMode = ref.read(_routeModeProvider);
      final results = await ref
          .read(directionsServiceProvider)
          .getRoutes(
            origin: origin,
            destination: dest.latLng,
            viaWaypoints: waypoints.isEmpty ? null : waypoints,
            mode: routeMode,
            instructionBuilder: (type, modifier, name) =>
                _buildLocalizedInstruction(l10n, type, modifier, name),
          );

      if (!mounted) return;

      if (results.isNotEmpty) {
        ref.read(_altRoutesProvider.notifier).state = results;

        // Wind-optimised route selection: use WindRoutingService to score
        // all alternatives and pick the best (lowest effort / most tailwind).
        int bestIdx = 0;
        if (results.length >= 2) {
          try {
            final scores = await ref
                .read(windRoutingServiceProvider)
                .scoreAlternatives(results);
            if (scores.isNotEmpty) {
              bestIdx = scores.first.routeIndex; // highest net score (most tailwind)
            }
          } catch (_) {
            bestIdx = 0; // fallback to first route on any error
          }
        }

        ref.read(_selectedRouteIndexProvider.notifier).state = bestIdx;
        ref.read(_routeResultProvider.notifier).state = results[bestIdx];
        if (!isReroute) {
          final bounds = _boundsFromLatLngs([
            origin,
            ...results[bestIdx].polylinePoints,
          ]);
          _mapController?.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 80),
          );
        }
      } else {
        // Only show the snackbar for manual route searches, not auto-reroutes.
        // Reroute failures are handled by the caller via TTS feedback.
        if (!isReroute && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.l10n.noRouteFound)));
        }
      }
    } finally {
      if (!isReroute && mounted) setState(() => _isCalculating = false);
    }
  }

  LatLngBounds _boundsFromLatLngs(List<LatLng> points) {
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  // Re-lock the camera onto the rider's position after user has panned away.
  void _recenterOnUser() {
    if (!mounted) return;
    setState(() => _followUser = true);
    // Reset search area to use user location
    ref.read(_searchAreaCenterProvider.notifier).state = null;
    ref.read(_showSearchAreaButtonProvider.notifier).state = false;
    final pos = ref.read(_userLocationProvider);
    final bearing = ref.read(_bearingProvider);
    if (pos != null) {
      _lastCameraMs = DateTime.now().millisecondsSinceEpoch;
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: pos, zoom: 17, bearing: bearing, tilt: 45),
        ),
      );
    }
  }

  void _startNavigation() async {
    // Cache l10n strings before entering the async location stream
    // (context is available here since this is called from a button press).
    final arrivedText = context.l10n.arrived;
    final rerouteCompleteText = context.l10n.rerouteComplete;
    final rerouteFailedText = context.l10n.rerouteFailed;

    // Build the directional arrow once and cache it.
    _navArrow ??= await _buildNavArrow();
    if (!mounted) return;

    _nearestRouteIndex = 0;
    _rerouting = false;
    _isOffline = false;
    _hazardAlerts = [];
    _hazardDismissed = false;
    _followUser = true; // always start following on new navigation
    _ttsAnnounced.clear();
    _lastLocationMs = DateTime.now().millisecondsSinceEpoch;
    ref.read(_isReroutingProvider.notifier).state = false;
    // H1: reset reroute rate-limit window for new navigation session.
    _rerouteCount = 0;
    _rerouteWindowStartMs = DateTime.now().millisecondsSinceEpoch;
    // H4: reset waypoint arrival index.
    _nextWaypointIndex = 0;
    // H5: reset hazard query center so the stream is started fresh.
    _lastHazardQueryCenter = null;

    // GPS-lost detection: warn if no location update for 10 seconds.
    _gpsLostTimer?.cancel();
    _gpsLostTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final elapsed = DateTime.now().millisecondsSinceEpoch - _lastLocationMs;
      // 20 s threshold — cyclists stop at traffic lights for > 10 s.
      final lost = elapsed > 20000;
      if (_gpsLostWarning != lost) setState(() => _gpsLostWarning = lost);
    });

    // C3: Set TTS language with Danish → English fallback.
    // Many devices in Denmark ship without the Danish TTS language pack.
    // Try 'da', verify availability, fall back to 'en-GB' if unavailable.
    final ttsService = ref.read(ttsServiceProvider);
    // Apply user voice settings (style, speech rate, frequency).
    final voiceSettings =
        ref.read(voiceSettingsProvider).valueOrNull ?? const VoiceSettings();
    await ttsService.applyVoiceSettings(voiceSettings);
    final langCode = ref.read(localeProvider).languageCode;
    final bool langAvailable = await ttsService.isLanguageAvailable(langCode);
    if (langAvailable) {
      ttsService.setLanguage(langCode);
    } else {
      ttsService.setLanguage('en-GB');
      if (!_ttsLangFallbackNotified && mounted) {
        _ttsLangFallbackNotified = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.ttsLanguageUnavailable),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }

    ref.read(_isNavigatingProvider.notifier).state = true;
    ref.read(_isArrivedProvider.notifier).state = false;
    ref.read(_currentStepProvider.notifier).state = 0;

    // Speak first instruction.
    final tts = ttsService;
    final initRoute = ref.read(_routeResultProvider);
    if (initRoute != null && initRoute.steps.isNotEmpty) {
      // Bug 4 fix: initialise distToStep before the first GPS tick so the
      // banner never shows "0 m" on startup.
      final initUserLoc = ref.read(_userLocationProvider);
      if (initUserLoc != null) {
        ref
            .read(_distToStepProvider.notifier)
            .state = LocationService.staticDistanceBetween(
          initUserLoc,
          initRoute.steps[0].endLocation,
        );
      } else {
        ref.read(_distToStepProvider.notifier).state = initRoute
            .steps[0]
            .distanceMeters
            .toDouble();
      }
      // Bug 3 fix: skip TTS phases whose threshold exceeds the step length.
      _initStepTtsPhases(0, initRoute.steps[0].distanceMeters);
      tts.speak(initRoute.steps[0].instruction);
      // Cache active route — allows resume after app restart + offline continuation.
      final destForCache = ref.read(_selectedDestProvider);
      if (destForCache != null) {
        unawaited(
          ref
              .read(routeCacheServiceProvider)
              .save(
                route: initRoute,
                stepIndex: 0,
                destText: destForCache.text,
                destLat: destForCache.latLng.latitude,
                destLng: destForCache.latLng.longitude,
              ),
        );
        // Record this destination for frequent routes + commute suggestions.
        unawaited(
          ref
              .read(frequentDestinationsServiceProvider)
              .recordVisit(
                text: destForCache.text,
                lat: destForCache.latLng.latitude,
                lng: destForCache.latLng.longitude,
              ),
        );
        unawaited(
          ref
              .read(commuteSuggestionServiceProvider)
              .recordVisit(
                text: destForCache.text,
                lat: destForCache.latLng.latitude,
                lng: destForCache.latLng.longitude,
              ),
        );
      }
      // Fetch hazard alerts at route midpoint (weather API, non-blocking).
      if (initRoute.polylinePoints.length >= 2) {
        final midIdx = initRoute.polylinePoints.length ~/ 2;
        ref
            .read(hazardServiceProvider)
            .getHazards(initRoute.polylinePoints[midIdx])
            .then((alerts) {
              if (mounted && alerts.isNotEmpty) {
                setState(() => _hazardAlerts = alerts);
              }
            });
      }
      // Periodic connectivity check — if network drops, disables rerouting
      // and shows the offline banner so riders know rerouting is paused.
      _connectivityTimer?.cancel();
      _connectivityTimer = Timer.periodic(const Duration(seconds: 20), (
        _,
      ) async {
        if (!mounted) return;
        final online = await ref.read(connectivityServiceProvider).isOnline();
        if (mounted) setState(() => _isOffline = !online);
      });
      // Start crowd-hazard stream — shows user-reported hazards as map pins.
      // C4: errors are caught so an unavailable query never crashes navigation.
      // H5: center is saved so the stream can be re-issued when the rider
      //     moves more than 3 km away.
      final navUserLoc = ref.read(_userLocationProvider);
      if (navUserLoc != null) {
        _startCrowdHazardStream(navUserLoc);
      }
      // Pre-warm map tiles along the route corridor so the map stays detailed
      // if the device goes offline mid-ride. Non-blocking, skipped if already offline.
      if (!_isOffline && _mapController != null) {
        final tileUserLoc = ref.read(_userLocationProvider);
        final tileBearing = ref.read(_bearingProvider);
        final tileRestore = tileUserLoc != null
            ? CameraPosition(
                target: tileUserLoc,
                zoom: 17,
                bearing: tileBearing,
                tilt: 45,
              )
            : const CameraPosition(target: _copenhagen, zoom: 14);
        unawaited(
          ref
              .read(tilePrefetchServiceProvider)
              .prefetchRoute(
                controller: _mapController!,
                polyline: initRoute.polylinePoints,
                restoreTarget: tileRestore,
              ),
        );
      }
      // Start Android foreground service so guidance continues with screen off.
      // Register stop callback BEFORE init so the action button works.
      navigationNotificationService.setStopCallback(_stopNavigation);
      await navigationNotificationService.init();
      // Prompt to disable battery optimizations on Android — prevents Doze
      // mode from suspending GPS and TTS on long rides (shows once per session).
      unawaited(requestIgnoreBatteryOptimizations());
      await navigationNotificationService.startNavigation(
        'CYKEL',
        initRoute.steps[0].instruction,
        initRoute.steps[0].distanceLabel,
      );
    }

    final locService = ref.read(locationServiceProvider);
    int lastStreamMs = 0; // throttle: max 1 UI update per second
    _navSubscription = locService.locationUpdateStream().listen((update) {
      if (!mounted) return;
      // Update GPS-lost clock.
      _lastLocationMs = DateTime.now().millisecondsSinceEpoch;
      // Throttle to 1 update/second to avoid jank.
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (nowMs - lastStreamMs < 900) return;
      lastStreamMs = nowMs;
      final pos = update.position;
      final bearing = update.bearing;

      // Speed (m/s → km/h).
      final speedKmh = (update.speed * 3.6).clamp(0.0, 200.0);
      ref.read(_speedProvider.notifier).state = speedKmh;

      ref.read(_userLocationProvider.notifier).state = pos;
      // H7: only update bearing when moving — prevents arrow spinning at stops.
      if (speedKmh > 2.5) {
        ref.read(_bearingProvider.notifier).state = bearing;
      }

      // Google Maps-style: tilt + rotate toward direction of travel.
      // Only animate when the user hasn't manually panned the map.
      if (_followUser) {
        _lastCameraMs = DateTime.now().millisecondsSinceEpoch;
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: pos,
              zoom: 17,
              bearing: ref.read(_bearingProvider),
              tilt: 45,
            ),
          ),
        );
      }

      // H5: refresh crowd hazard stream if rider has moved > 3 km.
      _maybeRefreshHazardStream(pos);

      final route = ref.read(_routeResultProvider);
      final stepIdx = ref.read(_currentStepProvider);
      if (route == null || stepIdx >= route.steps.length) return;
      final step = route.steps[stepIdx];

      final distToStep = LocationService.staticDistanceBetween(
        pos,
        step.endLocation,
      );
      ref.read(_distToStepProvider.notifier).state = distToStep;

      // Advance nearest polyline index for traveled vs remaining split.
      // Forward scan only: keeps the "traveled" segment growing correctly.
      final pts = route.polylinePoints;
      for (int i = _nearestRouteIndex; i < pts.length; i++) {
        if (LocationService.staticDistanceBetween(pos, pts[i]) < 30) {
          _nearestRouteIndex = i;
        }
      }

      // Off-route detection: measure true distance from the whole polyline.
      // We scan all points (not just a local window) so a wrong turn at any
      // point on the route is caught immediately rather than after 20 points.
      if (!_rerouting) {
        double minDist = double.infinity;
        int nearestIdx = _nearestRouteIndex;
        for (int i = 0; i < pts.length; i++) {
          final d = LocationService.staticDistanceBetween(pos, pts[i]);
          if (d < minDist) {
            minDist = d;
            nearestIdx = i;
          }
        }
        // If a closer point exists ahead, update the polyline cursor.
        if (nearestIdx > _nearestRouteIndex) _nearestRouteIndex = nearestIdx;

        if (minDist > _kOffRouteM) {
          // If offline or H1-frozen, use cached polyline to continue guidance.
          if (_isOffline) {
            if (!_rerouting) tts.speak(rerouteFailedText);
            return;
          }
          // H1 + H3: delegate to _triggerReroute which enforces single-flight
          // and the rolling rate-limit window.
          _triggerReroute(
            pos: pos,
            rerouteCompleteText: rerouteCompleteText,
            rerouteFailedText: rerouteFailedText,
            tts: tts,
          );
        }
      }

      // TTS 3-phase announcements using user's announcement frequency setting.
      // Bug 2 fix: use actual measured distance for every announcement.
      // Bug 3 fix: phases whose threshold exceeds the step length are
      //            pre-marked in _initStepTtsPhases so they never fire.
      if (distToStep > 30) {
        final voiceSettings =
            ref.read(voiceSettingsProvider).valueOrNull ?? const VoiceSettings();
        final thresholds = voiceSettings.thresholds; // [far, medium, near]
        final far    = thresholds[0]; // e.g. 500
        final medium = thresholds[1]; // e.g. 200
        final near   = thresholds[2]; // e.g. 50
        final phaseFar    = '${stepIdx}_${far.round()}';
        final phaseMedium = '${stepIdx}_${medium.round()}';
        final phaseNear   = '${stepIdx}_${near.round()}';
        if (distToStep <= far &&
            distToStep > medium &&
            !_ttsAnnounced.contains(phaseFar)) {
          _ttsAnnounced.add(phaseFar);
          tts.speak(
            context.l10n.inDistance(
              '${distToStep.round()} m',
              step.instruction,
            ),
          );
        } else if (distToStep <= medium &&
            distToStep > near &&
            !_ttsAnnounced.contains(phaseMedium)) {
          _ttsAnnounced.add(phaseMedium);
          tts.speak(
            context.l10n.inDistance(
              '${distToStep.round()} m',
              step.instruction,
            ),
          );
        } else if (distToStep <= near && !_ttsAnnounced.contains(phaseNear)) {
          _ttsAnnounced.add(phaseNear);
          tts.speak(step.instruction);
        }
      }

      if (distToStep < 30) {
        // H4: check for waypoint arrival before step advancement.
        final waypoints = ref.read(_waypointsProvider);
        if (_nextWaypointIndex < waypoints.length) {
          final nextWp = waypoints[_nextWaypointIndex];
          final wpDist = LocationService.staticDistanceBetween(
            step.endLocation,
            LatLng(nextWp.lat, nextWp.lng),
          );
          if (wpDist < 50) {
            // 50m tolerance for waypoint detection
            tts.speak(context.l10n.navWaypointReached(_nextWaypointIndex + 1));
            _nextWaypointIndex++;
          }
        }

        if (stepIdx + 1 < route.steps.length) {
          final nextIdx = stepIdx + 1;
          _ttsAnnounced.removeWhere((k) => k.startsWith('${stepIdx}_'));
          // Bug 6 fix: pre-mark phases that won't fire for the new step.
          _initStepTtsPhases(nextIdx, route.steps[nextIdx].distanceMeters);
          ref.read(_currentStepProvider.notifier).state = nextIdx;
          tts.speak(route.steps[nextIdx].instruction);
          // Keep the notification in sync with the current step.
          navigationNotificationService.updateStep(
            route.steps[nextIdx].instruction,
            route.steps[nextIdx].distanceLabel,
          );
          // Keep the route cache in sync so resume starts at the right step.
          unawaited(ref.read(routeCacheServiceProvider).updateStep(nextIdx));
        } else {
          // Arrived at destination.
          tts.speak(arrivedText);
          _stopNavigation();
          ref.read(_isArrivedProvider.notifier).state = true;
        }
      }
    });
  }

  /// Pre-marks TTS phase keys that will never fire because the step's total
  /// distance is shorter than the corresponding announcement threshold.
  /// This prevents "in 200 m" being spoken on a 88 m step.
  void _initStepTtsPhases(int stepIdx, int stepDistanceM) {
    final voiceSettings =
        ref.read(voiceSettingsProvider).valueOrNull ?? const VoiceSettings();
    final thresholds = voiceSettings.thresholds;
    final far    = thresholds[0];
    final medium = thresholds[1];
    if (stepDistanceM <= far)    _ttsAnnounced.add('${stepIdx}_${far.round()}');
    if (stepDistanceM <= medium) _ttsAnnounced.add('${stepIdx}_${medium.round()}');
    // Legacy keys so existing route-resume code still works:
    if (stepDistanceM <= 500) _ttsAnnounced.add('${stepIdx}_500');
    if (stepDistanceM <= 200) _ttsAnnounced.add('${stepIdx}_200');
  }

  /// Checks for an interrupted navigation session and prompts the rider to resume.
  Future<void> _checkResumeNavigation() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final cached = await ref.read(routeCacheServiceProvider).load();
    if (cached == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.resumeNavigationPrompt(cached.destText)),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: context.l10n.resumeNavigationAction,
          onPressed: () {
            if (!mounted) return;
            ref.read(_routeResultProvider.notifier).state = cached.route;
            ref.read(_currentStepProvider.notifier).state = cached.stepIndex;
            ref.read(_distToStepProvider.notifier).state = cached
                .route
                .steps[cached.stepIndex]
                .distanceMeters
                .toDouble();
            final destPlace = PlaceResult(
              placeId: '',
              text: cached.destText,
              lat: cached.destLat,
              lng: cached.destLng,
            );
            ref.read(_selectedDestProvider.notifier).state = destPlace;
            ref.read(_destLatLngProvider.notifier).state = LatLng(
              cached.destLat,
              cached.destLng,
            );
            _searchPanelKey.currentState?.setDestination(destPlace);
            _startNavigation();
          },
        ),
      ),
    );
  }

  /// Returns a localised label for the highest-severity [HazardAlert].
  String _hazardLabel(BuildContext context, HazardAlert alert) {
    return switch (alert.type) {
      HazardType.ice => context.l10n.hazardIce,
      HazardType.freeze => context.l10n.hazardFreeze,
      HazardType.strongWind => context.l10n.hazardStrongWind,
      HazardType.heavyRain => context.l10n.hazardHeavyRain,
      HazardType.wetSurface => context.l10n.hazardWetSurface,
      HazardType.snow => context.l10n.hazardSnow,
      HazardType.fog => context.l10n.hazardFog,
      HazardType.lowVisibility => context.l10n.hazardLowVisibility,
      HazardType.darkness => context.l10n.hazardDarkness,
    };
  }

  // ── Crowd-hazard stream helpers (C4, H5) ────────────────────────────────────

  /// Starts (or re-starts) the Firestore stream for nearby crowd hazards
  /// centred on [center].
  ///
  /// C4: errors are handled — an unavailable Firestore index or permission
  /// error logs and clears the hazard list rather than crashing the widget.
  ///
  /// H5: saves [center] so [_maybeRefreshHazardStream] can detect when the
  /// rider has moved far enough to warrant a fresh query.
  void _startCrowdHazardStream(LatLng center) {
    _crowdHazardSub?.cancel();
    _lastHazardQueryCenter = center;
    _crowdHazardSub = ref
        .read(crowdHazardServiceProvider)
        .streamNearby(center)
        .listen(
          (reports) {
            if (mounted) setState(() => _crowdHazards = reports);
          },
          onError: (Object e) {
            // C4: log the error but do not rethrow — navigation must continue.
            debugPrint('CrowdHazard stream error (non-fatal): $e');
            if (mounted) setState(() => _crowdHazards = []);
          },
        );
  }

  /// Called on every GPS tick during navigation to check whether the rider
  /// has moved more than 3 km from the last hazard query center (H5).
  void _maybeRefreshHazardStream(LatLng pos) {
    final lastCenter = _lastHazardQueryCenter;
    if (lastCenter == null) {
      _startCrowdHazardStream(pos);
      return;
    }
    final dist = LocationService.staticDistanceBetween(pos, lastCenter);
    if (dist > 3000) {
      _startCrowdHazardStream(pos);
    }
  }

  // ── Off-route reroute handler (H1, H3) ──────────────────────────────────────

  /// Handles off-route detection with a single-flight guard (H3) and a
  /// rate-limit window cap (H1) that switches to offline-continuation mode
  /// when too many reroutes occur in a short window.
  ///
  /// Returns without rerouting if:
  ///   • [_rerouting] is already true (single-flight guard — H3)
  ///   • 15 s backoff has not elapsed since last attempt
  ///   • We have hit [_kMaxReroutesPerWindow] in the current window (H1)
  void _triggerReroute({
    required LatLng pos,
    required String rerouteCompleteText,
    required String rerouteFailedText,
    required TtsService tts,
  }) {
    // H3: single-flight guard — set flag BEFORE the async call so a second
    // GPS tick reaching here within the same 900 ms window is rejected.
    if (_rerouting) return;

    // Backoff: 15 s between reroute attempts.
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastRerouteAtMs < _kRerouteBackoffMs) return;

    // H1: rolling 10-minute reroute window cap.  If exceeded, freeze into
    // offline-continuation mode for the remainder of the ride.
    if (nowMs - _rerouteWindowStartMs > _kRerouteWindowMs) {
      // New window — reset counter.
      _rerouteWindowStartMs = nowMs;
      _rerouteCount = 0;
    }
    if (_rerouteCount >= _kMaxReroutesPerWindow) {
      // Too many reroutes this window — announce and stop trying.
      debugPrint('H1: max reroutes reached, freezing to offline-continuation');
      tts.speak(context.l10n.navMaxReroutesReached);
      setState(() => _isOffline = true); // reuse offline banner
      return;
    }

    _lastRerouteAtMs = nowMs;
    _rerouteCount++;
    _rerouting = true;
    ref.read(_isReroutingProvider.notifier).state = true;

    final dest = ref.read(_selectedDestProvider);
    if (dest == null) {
      _rerouting = false;
      ref.read(_isReroutingProvider.notifier).state = false;
      return;
    }

    _calculateRoute(dest, isReroute: true).then((_) {
      if (!mounted) return;
      final newRoute = ref.read(_routeResultProvider);
      if (newRoute != null && newRoute.steps.isNotEmpty) {
        tts.speak(rerouteCompleteText);
        navigationNotificationService.updateStep(
          newRoute.steps[0].instruction,
          newRoute.steps[0].distanceLabel,
        );
      } else {
        tts.speak(rerouteFailedText);
      }
      _nearestRouteIndex = 0;
      _rerouting = false;
      ref.read(_isReroutingProvider.notifier).state = false;
    });
  }

  void _stopNavigation() {
    navigationNotificationService.clearStopCallback();
    navigationNotificationService
        .stop(); // dismiss foreground service notification
    // Cancel connectivity check and clear the route cache (ride complete).
    _connectivityTimer?.cancel();
    _connectivityTimer = null;
    // Cancel crowd hazard stream.
    _crowdHazardSub?.cancel();
    _crowdHazardSub = null;
    _crowdHazards = [];
    _lastHazardQueryCenter = null;
    // Cancel tile prefetch if still in progress.
    ref.read(tilePrefetchServiceProvider).cancel();
    _isOffline = false;
    _hazardAlerts = [];
    _hazardDismissed = false;
    unawaited(ref.read(routeCacheServiceProvider).clear());
    _navSubscription?.cancel();
    _navSubscription = null;
    _gpsLostTimer?.cancel();
    _gpsLostTimer = null;
    _followUser = true;
    _gpsLostWarning = false;
    _ttsAnnounced.clear();
    // Reset reroute counter and waypoint tracker.
    _rerouteCount = 0;
    _rerouteWindowStartMs = 0;
    _nextWaypointIndex = 0;
    // Clear waypoints (route is done).
    ref.read(_waypointsProvider.notifier).state = [];
    ref.read(_isNavigatingProvider.notifier).state = false;
    ref.read(_currentStepProvider.notifier).state = 0;
    ref.read(_isArrivedProvider.notifier).state = false;
    ref.read(_isReroutingProvider.notifier).state = false;
    // Restore flat top-down camera.
    final userLoc = ref.read(_userLocationProvider);
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: userLoc ?? _copenhagen,
          zoom: 15,
          bearing: 0,
          tilt: 0,
        ),
      ),
    );
  }

  /// Confirms the current map-centre position as FROM or TO location.
  Future<void> _confirmSetOnMap() async {
    final center = _mapCenter;
    final target = _setOnMapTarget;
    if (target == _SetOnMapTarget.none) return;
    setState(() => _setOnMapTarget = _SetOnMapTarget.none);
    final lang = ref.read(localeProvider).languageCode;
    // Placeholder shown immediately.
    final placeholder = PlaceResult(
      placeId: 'pin_${center.latitude}_${center.longitude}',
      text: context.l10n.droppedPin,
      lat: center.latitude,
      lng: center.longitude,
    );
    if (target == _SetOnMapTarget.to) {
      ref.read(_selectedDestProvider.notifier).state = placeholder;
      ref.read(_destLatLngProvider.notifier).state = center;
      _searchPanelKey.currentState?.setDestination(placeholder);
      _calculateRoute(placeholder);
    } else {
      ref.read(_originPlaceProvider.notifier).state = placeholder;
      _searchPanelKey.currentState?.setFromAddress(placeholder.text);
    }
    // Background reverse-geocode for the full street address.
    final resolved = await ref
        .read(placesServiceProvider)
        .reverseGeocode(center, language: lang);
    if (resolved != null && mounted) {
      final better = PlaceResult(
        placeId: placeholder.placeId,
        text: resolved.text,
        subtitle: resolved.subtitle,
        lat: center.latitude,
        lng: center.longitude,
      );
      if (target == _SetOnMapTarget.to) {
        ref.read(_selectedDestProvider.notifier).state = better;
        _searchPanelKey.currentState?.setDestination(better);
      } else {
        ref.read(_originPlaceProvider.notifier).state = better;
        _searchPanelKey.currentState?.setFromAddress(better.text);
        final currentDest = ref.read(_selectedDestProvider);
        if (currentDest != null) {
          ref.read(_routeResultProvider.notifier).state = null;
          _calculateRoute(currentDest);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userLoc = ref.watch(_userLocationProvider);
    final route = ref.watch(_routeResultProvider);
    final isNavigating = ref.watch(_isNavigatingProvider);
    final stepIdx = ref.watch(_currentStepProvider);
    final showTraffic = ref.watch(_showTrafficProvider);
    final dest = ref.watch(_selectedDestProvider);
    final destLatLng = ref.watch(_destLatLngProvider);
    final originPlace = ref.watch(_originPlaceProvider);
    final bearing = ref.watch(_bearingProvider);
    final isArrived = ref.watch(_isArrivedProvider);
    final showBike = ref.watch(_showBicycleLaneProvider);
    final showTransit = ref.watch(_showTransitProvider);
    final speedKmh = ref.watch(_speedProvider);
    final isNight = ref.watch(_isNightProvider);
    final distToStep = ref.watch(_distToStepProvider);
    final isRerouting = ref.watch(_isReroutingProvider);
    final mapType = ref.watch(_mapTypeProvider);
    final altRoutes = ref.watch(_altRoutesProvider);
    final selRouteIdx = ref.watch(_selectedRouteIndexProvider);
    final chargingMarkers = ref
        .watch(_chargingMarkersProvider)
        .maybeWhen(data: (m) => m, orElse: () => <Marker>{});
    final serviceMarkers = ref
        .watch(_serviceMarkersProvider)
        .maybeWhen(data: (m) => m, orElse: () => <Marker>{});
    final shopsMarkers = ref
        .watch(_shopsMarkersProvider)
        .maybeWhen(data: (m) => m, orElse: () => <Marker>{});
    final rentalMarkers = ref
        .watch(_rentalMarkersProvider)
        .maybeWhen(data: (m) => m, orElse: () => <Marker>{});
    final cykelRepairMarkers = ref
        .watch(_cykelRepairMarkersProvider)
        .maybeWhen(data: (m) => m, orElse: () => <Marker>{});
    final cykelShopMarkers = ref
        .watch(_cykelShopMarkersProvider)
        .maybeWhen(data: (m) => m, orElse: () => <Marker>{});
    final cykelChargingMarkers = ref
        .watch(_cykelChargingMarkersProvider)
        .maybeWhen(data: (m) => m, orElse: () => <Marker>{});
    final cykelServiceMarkers = ref
        .watch(_cykelServiceMarkersProvider)
        .maybeWhen(data: (m) => m, orElse: () => <Marker>{});
    final cykelRentalMarkers = ref
        .watch(_cykelRentalMarkersProvider)
        .maybeWhen(data: (m) => m, orElse: () => <Marker>{});
    final showWindOverlay = ref.watch(_showWindOverlayProvider);
    final windOverlayMarkers = showWindOverlay
        ? ref
              .watch(windOverlayProvider)
              .maybeWhen(
                data: (data) => data?.markers ?? <Marker>{},
                orElse: () => <Marker>{},
              )
        : <Marker>{};
    final savedRoutes = ref.watch(quickRoutesProvider);
    final topPad = MediaQuery.of(context).padding.top;

    // Check if any POI layers are enabled without location permission
    final showCharging = ref.watch(_showChargingProvider);
    final showService = ref.watch(_showServiceProvider);
    final showShops = ref.watch(_showShopsProvider);
    final showRental = ref.watch(_showRentalProvider);
    final showCykelRepair = ref.watch(_showCykelRepairProvider);
    final showCykelShop = ref.watch(_showCykelShopProvider);
    final showCykelCharging = ref.watch(_showCykelChargingProvider);
    final showCykelService = ref.watch(_showCykelServiceProvider);
    final showCykelRental = ref.watch(_showCykelRentalProvider);
    final anyPoiLayerEnabled = showCharging || showService || showShops || 
        showRental || showCykelRepair || showCykelShop || showCykelCharging || 
        showCykelService || showCykelRental;
    
    // Update POI location hint visibility
    if (anyPoiLayerEnabled && userLoc == null && !_permissionDenied) {
      if (!_showPoiLocationHint) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _showPoiLocationHint = true);
        });
      }
    } else if (_showPoiLocationHint) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _showPoiLocationHint = false);
      });
    }

    // Sync TTS language with the app locale chosen by the user.
    ref.listen<Locale>(localeProvider, (_, locale) {
      ref.read(ttsServiceProvider).setLanguage(locale.languageCode);
    });

    // Pick up pending destination (e.g. from Quick Routes on home screen).
    ref.listen<PlaceResult?>(pendingRouteProvider, (_, place) {
      if (place == null) return;
      ref.read(pendingRouteProvider.notifier).state = null;
      ref.read(_selectedDestProvider.notifier).state = place;
      _calculateRoute(place);
    });

    // Activate a POI layer when navigating here from Discover categories.
    ref.listen<String?>(pendingLayerProvider, (_, layer) {
      if (layer == null) return;
      ref.read(pendingLayerProvider.notifier).state = null;
      if (layer == 'charging') {
        ref.read(_showChargingProvider.notifier).state = true;
      } else if (layer == 'service') {
        ref.read(_showServiceProvider.notifier).state = true;
      } else if (layer == 'shop') {
        ref.read(_showShopsProvider.notifier).state = true;
      } else if (layer == 'rental') {
        ref.read(_showRentalProvider.notifier).state = true;
      } else if (layer == 'cykel_repair') {
        ref.read(_showCykelRepairProvider.notifier).state = true;
      } else if (layer == 'cykel_shop') {
        ref.read(_showCykelShopProvider.notifier).state = true;
      } else if (layer == 'cykel_charging') {
        ref.read(_showCykelChargingProvider.notifier).state = true;
      } else if (layer == 'cykel_service') {
        ref.read(_showCykelServiceProvider.notifier).state = true;
      } else if (layer == 'cykel_rental') {
        ref.read(_showCykelRentalProvider.notifier).state = true;
      }
    });

    // Show POI detail sheet when a POI marker is tapped.
    ref.listen<PlaceResult?>(_selectedPoiProvider, (_, poi) {
      if (poi == null || !mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _PoiDetailSheet(
          poi: poi,
          onSetAsDestination: () {
            Navigator.of(context).pop();
            ref.read(_selectedPoiProvider.notifier).state = null;
            ref.read(_selectedDestProvider.notifier).state = poi;
            ref.read(_destLatLngProvider.notifier).state = poi.latLng;
            _searchPanelKey.currentState?.setDestination(poi);
            _calculateRoute(poi);
          },
        ),
      ).whenComplete(() {
        ref.read(_selectedPoiProvider.notifier).state = null;
      });
    });

    // Show CYKEL provider detail sheet when a verified provider marker is tapped.
    ref.listen<CykelProvider?>(_selectedCykelProviderProvider, (_, provider) {
      if (provider == null || !mounted) return;
      // Track profile view.
      ref.read(providerServiceProvider).incrementProfileView(provider.id);
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _CykelProviderDetailSheet(
          provider: provider,
          userLocation: ref.read(_userLocationProvider),
          onGetDirections: () {
            Navigator.of(context).pop();
            ref.read(_selectedCykelProviderProvider.notifier).state = null;
            ref.read(providerServiceProvider).incrementNavigationRequest(provider.id);
            final dest = PlaceResult(
              placeId: 'cykel_${provider.id}',
              text: provider.businessName,
              subtitle: '${provider.streetAddress}, ${provider.city}',
              lat: provider.latitude,
              lng: provider.longitude,
            );
            ref.read(_selectedDestProvider.notifier).state = dest;
            ref.read(_destLatLngProvider.notifier).state = dest.latLng;
            _searchPanelKey.currentState?.setDestination(dest);
            _calculateRoute(dest);
          },
        ),
      ).whenComplete(() {
        ref.read(_selectedCykelProviderProvider.notifier).state = null;
      });
    });

    final markers = <Marker>{};
    if (isNavigating && userLoc != null) {
      // Directional arrow — rotates with bearing so it always points forward.
      markers.add(
        Marker(
          markerId: const MarkerId('nav_arrow'),
          position: userLoc,
          rotation: bearing,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          icon:
              _navArrow ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          consumeTapEvents: true,
        ),
      );
    } else {
      // Origin marker — only shown when a custom origin is chosen (not GPS)
      if (originPlace != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('origin'),
            position: originPlace.latLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueCyan,
            ),
            infoWindow: InfoWindow(title: originPlace.text),
          ),
        );
      } else if (userLoc != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('user'),
            position: userLoc,
            icon:
                _userDotIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
            anchor: const Offset(0.5, 0.5),
            infoWindow: InfoWindow(title: context.l10n.yourLocation),
          ),
        );
      }
    }
    if (dest != null && destLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: destLatLng,
          anchor: const Offset(0.5, 1.0),
          icon:
              _destMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: dest.text),
        ),
      );
    }
    // POI layer markers (charging stations, service points, shops, rentals).
    markers
      ..addAll(chargingMarkers)
      ..addAll(serviceMarkers)
      ..addAll(shopsMarkers)
      ..addAll(rentalMarkers)
      ..addAll(windOverlayMarkers)
      // CYKEL verified provider markers.
      ..addAll(cykelRepairMarkers)
      ..addAll(cykelShopMarkers)
      ..addAll(cykelChargingMarkers)
      ..addAll(cykelServiceMarkers)
      ..addAll(cykelRentalMarkers);

    // Saved places — home, work, and custom pins (shown when not navigating).
    if (!isNavigating) {
      void addSavedPin(String id, QuickRoute r, double hue) {
        markers.add(Marker(
          markerId: MarkerId('saved_$id'),
          position: LatLng(r.lat, r.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(title: r.text),
          onTap: () {
            ref.read(_selectedDestProvider.notifier).state = r.toPlaceResult();
          },
        ));
      }

      if (savedRoutes.home != null) {
        addSavedPin('home', savedRoutes.home!, BitmapDescriptor.hueGreen);
      }
      if (savedRoutes.work != null) {
        addSavedPin('work', savedRoutes.work!, BitmapDescriptor.hueBlue);
      }
      for (final named in savedRoutes.custom) {
        addSavedPin('custom_${named.name}', named.route,
            BitmapDescriptor.hueViolet);
      }
    }
    // Crowd-reported hazard markers — shown during navigation.
    for (final hazard in _crowdHazards) {
      final hue = switch (hazard.severity) {
        HazardSeverity.danger  => BitmapDescriptor.hueRed,
        HazardSeverity.caution => BitmapDescriptor.hueOrange,
        HazardSeverity.info    => BitmapDescriptor.hueBlue,
      };
      markers.add(
        Marker(
          markerId: MarkerId('crowd_${hazard.id}'),
          position: hazard.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _HazardDetailSheet(hazard: hazard),
          ),
        ),
      );
    }

    // Tile overlays for bike lanes and transit.
    final tileOverlays = <TileOverlay>{};
    if (showBike) {
      tileOverlays.add(
        TileOverlay(
          tileOverlayId: const TileOverlayId('bike'),
          tileProvider: _NetworkTileProvider(
            'https://tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
          ),
          transparency: 0.2,
        ),
      );
    }
    if (showTransit) {
      tileOverlays.add(
        TileOverlay(
          tileOverlayId: const TileOverlayId('transit'),
          tileProvider: _NetworkTileProvider(
            'https://tile.memomaps.de/tilegen/{z}/{x}/{y}.png',
          ),
          transparency: 0.2,
        ),
      );
    }
    // Offline tile overlay — replaces Google Maps base tiles when device is
    // offline and the user has at least one fully downloaded region.
    final hasOfflineTiles = ref.watch(hasOfflineTilesProvider);
    if (_isOffline && hasOfflineTiles) {
      final offlineService = ref.read(offlineMapsServiceProvider);
      tileOverlays.add(
        TileOverlay(
          tileOverlayId: const TileOverlayId('offline'),
          tileProvider: LocalTileProvider(offlineService),
          transparency: 0.0,
          zIndex: -1,
        ),
      );
    }

    // Dual polylines: gray for traveled portion, primary for remaining.
    // Each segment gets a white outline (drawn first, thicker) + blue line on top.
    // Alternative route polylines — grey/indigo behind the selected route.
    final polylines = <Polyline>{};
    if (altRoutes.length > 1) {
      for (int i = 0; i < altRoutes.length; i++) {
        if (i == selRouteIdx) continue;
        final altPts = _simplifyPolyline(altRoutes[i].polylinePoints);
        polylines.add(
          Polyline(
            polylineId: PolylineId('alt_outline_$i'),
            points: altPts,
            color: Colors.white,
            width: 8,
            zIndex: 0,
          ),
        );
        polylines.add(
          Polyline(
            polylineId: PolylineId('alt_$i'),
            points: altPts,
            color: Colors.blueGrey.shade400,
            width: 4,
            zIndex: 1,
            consumeTapEvents: true,
            onTap: () {
              ref.read(_selectedRouteIndexProvider.notifier).state = i;
              ref.read(_routeResultProvider.notifier).state = altRoutes[i];
            },
          ),
        );
      }
    }
    if (route != null) {
      final pts = _simplifyPolyline(route.polylinePoints);
      if (_nearestRouteIndex > 0 && _nearestRouteIndex < pts.length) {
        // Traveled — gray with white outline
        polylines.add(
          Polyline(
            polylineId: const PolylineId('traveled_outline'),
            points: pts.sublist(0, _nearestRouteIndex + 1),
            color: Colors.white,
            width: 9,
          ),
        );
        polylines.add(
          Polyline(
            polylineId: const PolylineId('traveled'),
            points: pts.sublist(0, _nearestRouteIndex + 1),
            color: Colors.grey.shade400,
            width: 5,
          ),
        );
        // Remaining — blue with white outline
        polylines.add(
          Polyline(
            polylineId: const PolylineId('remaining_outline'),
            points: pts.sublist(_nearestRouteIndex),
            color: Colors.white,
            width: 9,
          ),
        );
        polylines.add(
          Polyline(
            polylineId: const PolylineId('remaining'),
            points: pts.sublist(_nearestRouteIndex),
            color: _kPrimaryColor,
            width: 5,
          ),
        );
      } else {
        // Full route — white outline then blue
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route_outline'),
            points: pts,
            color: Colors.white,
            width: 9,
          ),
        );
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: pts,
            color: _kPrimaryColor,
            width: 5,
          ),
        );
      }
    }

    return PopScope(
      canPop: !isNavigating,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isNavigating) {
          _stopNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: _kBackground,
        body: Stack(
          children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _copenhagen,
              zoom: 12,
            ),
            mapType: mapType,
            myLocationEnabled:
                !isNavigating, // replaced by arrow marker during nav
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false, // Disable built-in zoom controls
            trafficEnabled: showTraffic,
            markers: markers,
            polylines: polylines,
            tileOverlays: tileOverlays,
            style: isNight ? _kDarkMapStyle : null,
            onMapCreated: (ctrl) {
              _mapController = ctrl;
              Future.delayed(const Duration(milliseconds: 500), () async {
                await _moveToUser();
                // Pick up a destination set from Quick Routes on the home screen.
                final pending = ref.read(pendingRouteProvider);
                if (pending != null && mounted) {
                  ref.read(pendingRouteProvider.notifier).state = null;
                  ref.read(_selectedDestProvider.notifier).state = pending;
                  _calculateRoute(pending);
                }
              });
            },
            // Track current map centre for Set-on-map pin picker.
            // Also show "Search this area" button if user pans away from location.
            onCameraMove: (pos) {
              _mapCenter = pos.target;
              
              // Don't show search button during navigation
              if (ref.read(_isNavigatingProvider)) return;
              
              // Check if map has moved significantly from user location
              final userLoc = ref.read(_userLocationProvider);
              if (userLoc != null) {
                final distance = _calculateDistance(
                  userLoc.latitude,
                  userLoc.longitude,
                  pos.target.latitude,
                  pos.target.longitude,
                );
                // Show button if moved more than 500 meters from user location
                final shouldShow = distance > 0.5; // km
                if (shouldShow != ref.read(_showSearchAreaButtonProvider)) {
                  ref.read(_showSearchAreaButtonProvider.notifier).state = shouldShow;
                }
              }
            },
            // Detect user-initiated pan/zoom during navigation and disable
            // camera tracking so the map stops fighting the finger gesture.
            onCameraMoveStarted: () {
              if (!ref.read(_isNavigatingProvider)) return;
              final now = DateTime.now().millisecondsSinceEpoch;
              // Ignore events that we triggered ourselves (within 400 ms).
              if (now - _lastCameraMs < 400) return;
              if (mounted && _followUser) {
                setState(() => _followUser = false);
              }
            },
            onLongPress: (latLng) async {
              // Long-press to drop a pin as destination.
              // Immediately set a placeholder, then reverse-geocode for the full address.
              var pin = PlaceResult(
                placeId: 'pin_${latLng.latitude}_${latLng.longitude}',
                text: context.l10n.droppedPin,
                lat: latLng.latitude,
                lng: latLng.longitude,
              );
              ref.read(_routeResultProvider.notifier).state = null;
              ref.read(_selectedDestProvider.notifier).state = pin;
              ref.read(_destLatLngProvider.notifier).state = latLng;
              _searchPanelKey.currentState?.setDestination(pin);
              _calculateRoute(pin);
              // Reverse-geocode in background and update field with full address.
              final lang = ref.read(localeProvider).languageCode;
              final resolved = await ref
                  .read(placesServiceProvider)
                  .reverseGeocode(latLng, language: lang);
              if (resolved != null && mounted) {
                final better = PlaceResult(
                  placeId: pin.placeId,
                  text: resolved.text,
                  subtitle: resolved.subtitle,
                  lat: latLng.latitude,
                  lng: latLng.longitude,
                );
                ref.read(_selectedDestProvider.notifier).state = better;
                _searchPanelKey.currentState?.setDestination(better);
              }
            },
          ),
          if (isNavigating && route != null && stepIdx < route.steps.length)
            _NavigationBanner(
              step: route.steps[stepIdx],
              distToStep: distToStep,
              onStop: _stopNavigation,
              topPad: topPad,
            ),
          if (isNavigating && route != null)
            _NavigationBottomBar(
              route: route,
              stepIdx: stepIdx,
              distToStep: distToStep,
              speedKmh: speedKmh,
              onStop: _stopNavigation,
            ),
          // Off-route recalculating banner — shown above the navigation bottom bar.
          if (isNavigating && isRerouting)
            Positioned(
              top: topPad + 90,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  context.l10n.offRouteRecalc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          // ── Route hazard warning banner ──────────────────────────────────
          // Shown when crowd-reported hazards exist within 200 m of the route.
          if (route != null) ...[
            Builder(builder: (context) {
              final onRoute = hazardsOnRoute(
                routePoints: route.polylinePoints,
                hazards: _crowdHazards,
              );
              if (onRoute.isEmpty) return const SizedBox.shrink();
              final worst = onRoute.reduce((a, b) =>
                  a.severity.index > b.severity.index ? a : b);
              return Positioned(
                top: isNavigating ? topPad + 90 : topPad + 16,
                left: 20,
                right: 20,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: worst.severity.color.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Text('⚠️', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.l10n.routeHazardWarning(onRoute.length),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
          // "Search this area" button — shown when user pans away from their location
          if (ref.watch(_showSearchAreaButtonProvider))
            Positioned(
              top: topPad + 80,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(24),
                  color: AppColors.surface,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      // Set search center to current map center
                      ref.read(_searchAreaCenterProvider.notifier).state = _mapCenter;
                      // Hide the button
                      ref.read(_showSearchAreaButtonProvider.notifier).state = false;
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.refresh_rounded, color: _kPrimaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Search this area',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: _kPrimaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Recenter FAB — shown during navigation when user has manually panned
          // the map away from their position. Tapping it re-locks the camera.
          if (isNavigating && !_followUser)
            Positioned(
              // Sits just above the navigation bottom bar (~100 px tall).
              bottom: 112 + MediaQuery.of(context).padding.bottom,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'recenter_fab',
                backgroundColor: AppColors.surface,
                foregroundColor: _kPrimaryColor,
                elevation: 4,
                onPressed: _recenterOnUser,
                child: const Icon(Icons.my_location_rounded),
              ),
            ),
          // Report hazard FAB — shown during navigation so riders can flag issues.
          if (isNavigating && userLoc != null)
            Positioned(
              bottom: 112 + MediaQuery.of(context).padding.bottom,
              right: 64,
              child: FloatingActionButton.small(
                heroTag: 'report_hazard_fab',
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                elevation: 4,
                tooltip: context.l10n.reportHazardTitle,
                onPressed: () {
                    final messenger = ScaffoldMessenger.of(context);
                    final thanksText = context.l10n.reportHazardThanks;
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: AppColors.surface,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (_) => ReportHazardSheet(position: userLoc),
                    ).then((submitted) {
                      if (submitted == true && mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(thanksText),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    });
                  },
                child: const Icon(Icons.report_problem_rounded),
              ),
            ),
          // Infrastructure feedback FAB — always visible (except arrived screen).
          if (!isArrived && userLoc != null)
            Positioned(
              bottom: (isNavigating
                      ? 112 + MediaQuery.of(context).padding.bottom
                      : route != null
                          ? 370 + MediaQuery.of(context).padding.bottom
                          : 90 + MediaQuery.of(context).padding.bottom),
              left: 16,
              child: FloatingActionButton.small(
                heroTag: 'infra_report_fab',
                backgroundColor: AppColors.info,
                foregroundColor: Colors.white,
                elevation: 4,
                tooltip: context.l10n.infraReportTitle,
                onPressed: () {
                  final messenger = ScaffoldMessenger.of(context);
                  final thanksText = context.l10n.infraReportThanks;
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: AppColors.surface,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) =>
                        ReportInfrastructureSheet(position: userLoc),
                  ).then((submitted) {
                    if (submitted == true && mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(thanksText),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  });
                },
                child: const Icon(Icons.construction_rounded),
              ),
            ),
          // SOS FAB — always visible.
          if (!isArrived)
            SosFab(
              position: userLoc,
              bottomPad: (isNavigating
                      ? 165 + MediaQuery.of(context).padding.bottom
                      : route != null
                          ? 425 + MediaQuery.of(context).padding.bottom
                          : 148 + MediaQuery.of(context).padding.bottom),
            ),
          // Route overview FAB — shown during navigation to zoom out to full route.
          if (isNavigating && route != null)
            Positioned(
              bottom: 112 + MediaQuery.of(context).padding.bottom,
              left: 16,
              child: FloatingActionButton.small(
                heroTag: 'overview_fab',
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textSecondary,
                elevation: 4,
                onPressed: () {
                  setState(() => _followUser = false);
                  final pts = route.polylinePoints;
                  if (pts.isNotEmpty) {
                    final bounds = _boundsFromLatLngs(pts);
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngBounds(bounds, 80),
                    );
                  }
                },
                child: const Icon(Icons.zoom_out_map_rounded),
              ),
            ),
          // GPS lost warning — shown during navigation when location updates stop.
          if (isNavigating && _gpsLostWarning)
            Positioned(
              top: topPad + 90,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.gps_off_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.gpsSignalLost,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Offline navigation banner — rerouting is paused, route continues.
          if (isNavigating && _isOffline)
            Positioned(
              top: topPad + 90,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6200EE).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        context.l10n.offlineNavBanner,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Hazard alerts banner — dismissible weather condition warning.
          if (isNavigating && _hazardAlerts.isNotEmpty && !_hazardDismissed)
            Positioned(
              top: topPad + 8,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: _hazardAlerts.any((a) => a.isWarning)
                    ? const Color(0xFFE53935)
                    : const Color(0xFFFF8F00),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _hazardLabel(context, _hazardAlerts.first),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _hazardDismissed = true),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Location permission denied — non-dismissible banner.
          if (_permissionDenied)
            Positioned(
              top: topPad + 8,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: AppColors.error,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_off_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.l10n.locationPermissionRequired,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => openAppSettings(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: Text(
                          context.l10n.openSettings,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // POI layers enabled without location — informational banner.
          if (_showPoiLocationHint && !_permissionDenied)
            Positioned(
              top: topPad + 8,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: AppColors.warning,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Enable location to see nearby bike facilities',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (mounted) {
                            setState(() => _showPoiLocationHint = false);
                          }
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (isArrived)
            _NavigationArrivedCard(
              onDone: () {
                ref.read(_isArrivedProvider.notifier).state = false;
                ref.read(_routeResultProvider.notifier).state = null;
                ref.read(_altRoutesProvider.notifier).state = [];
                ref.read(_selectedRouteIndexProvider.notifier).state = 0;
                ref.read(_selectedDestProvider.notifier).state = null;
                ref.read(_destLatLngProvider.notifier).state = null;
                ref.read(_originPlaceProvider.notifier).state = null;
                _searchPanelKey.currentState?.reset();
              },
            ),
          if (!isNavigating && _setOnMapTarget == _SetOnMapTarget.none)
            _RouteSearchPanel(
              key: _searchPanelKey,
              topPad: topPad,
              isCalculating: _isCalculating,
              onSearchFocused: () {
                if (mounted) setState(() => _showHint = false);
              },
              onOriginChanged: (place) {
                ref.read(_originPlaceProvider.notifier).state = place;
                // If dest already chosen, recalculate with new origin
                final currentDest = ref.read(_selectedDestProvider);
                if (currentDest != null) {
                  ref.read(_routeResultProvider.notifier).state = null;
                  _calculateRoute(currentDest);
                }
              },
              onDestinationChanged: (place) {
                ref.read(_routeResultProvider.notifier).state = null;
                ref.read(_selectedDestProvider.notifier).state = place;
                if (place != null) _calculateRoute(place);
              },
              onSetOnMap: (isFrom) {
                setState(
                  () => _setOnMapTarget = isFrom
                      ? _SetOnMapTarget.from
                      : _SetOnMapTarget.to,
                );
              },
              onWaypointAdded: (wp) {
                final list = <PlaceResult>[...ref.read(_waypointsProvider), wp];
                ref.read(_waypointsProvider.notifier).state = list;
                final currentDest = ref.read(_selectedDestProvider);
                if (currentDest != null) {
                  ref.read(_routeResultProvider.notifier).state = null;
                  _calculateRoute(currentDest);
                }
              },
              onWaypointRemoved: (idx) {
                final list = <PlaceResult>[...ref.read(_waypointsProvider)];
                if (idx < list.length) list.removeAt(idx);
                ref.read(_waypointsProvider.notifier).state = list;
                final currentDest = ref.read(_selectedDestProvider);
                if (currentDest != null) {
                  ref.read(_routeResultProvider.notifier).state = null;
                  _calculateRoute(currentDest);
                }
              },
            ),
          if (!isNavigating && route != null)
            _RouteSummaryCard(
              onStart: _startNavigation,
              onRecalculate: () {
                final dest = ref.read(_selectedDestProvider);
                if (dest != null) _calculateRoute(dest);
              },
              mapController: _mapController,
            ),
          // Layer FAB — always visible on right side, stacked above location button.
          Positioned(
            bottom: isNavigating
                ? 112 + MediaQuery.of(context).padding.bottom
                : route != null
                    ? MediaQuery.of(context).padding.bottom + 170
                    : 144,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'layer_fab',
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textSecondary,
              elevation: 4,
              onPressed: () => showModalBottomSheet(
                context: context,
                backgroundColor: AppColors.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                builder: (_) => _LayersSheet(),
              ),
              child: const Icon(Icons.layers_rounded),
            ),
          ),
          if (!isNavigating) ...[
            // Exit route FAB — shown on left when route is set
            if (route != null)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 310,
                left: 16,
                child: FloatingActionButton.small(
                  heroTag: 'exit_route_fab',
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  onPressed: () {
                    ref.read(_routeResultProvider.notifier).state = null;
                    ref.read(_altRoutesProvider.notifier).state = [];
                    ref.read(_selectedRouteIndexProvider.notifier).state = 0;
                    ref.read(_selectedDestProvider.notifier).state = null;
                    ref.read(_destLatLngProvider.notifier).state = null;
                    ref.read(_originPlaceProvider.notifier).state = null;
                    ref.read(_waypointsProvider.notifier).state = [];
                    _searchPanelKey.currentState?.reset();
                  },
                  child: const Icon(Icons.close_rounded),
                ),
              ),
            // Location FAB — always visible, moves above route card when route is set.
            Positioned(
              bottom: route != null
                  ? MediaQuery.of(context).padding.bottom + 200
                  : 96,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'loc_fab',
                backgroundColor: AppColors.surface,
                foregroundColor: _kPrimaryColor,
                onPressed: _moveToUser,
                child: const Icon(Icons.my_location_rounded),
              ),
            ),
            // Zoom in/out buttons
            if (_setOnMapTarget == _SetOnMapTarget.none)
              Positioned(
                top: topPad + 170,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'zoom_in_fab',
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.textSecondary,
                      elevation: 2,
                      onPressed: () =>
                          _mapController?.animateCamera(CameraUpdate.zoomIn()),
                      child: const Icon(Icons.add_rounded),
                    ),
                    const SizedBox(height: 4),
                    FloatingActionButton.small(
                      heroTag: 'zoom_out_fab',
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.textSecondary,
                      elevation: 2,
                      onPressed: () =>
                          _mapController?.animateCamera(CameraUpdate.zoomOut()),
                      child: const Icon(Icons.remove_rounded),
                    ),
                  ],
                ),
              ),
          ],
          // Long-press hint — shown until route is set or 5 s timeout.
          if (_showHint && !isNavigating && route == null)
            Positioned(
              bottom: 210,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    context.l10n.longPressHint,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          // Set-on-map crosshair overlay — shown while picking a pin location.
          if (_setOnMapTarget != _SetOnMapTarget.none) ...[
            const Center(
              child: Icon(
                Icons.add,
                size: 44,
                color: Colors.black87,
                shadows: [Shadow(blurRadius: 4, color: Colors.white)],
              ),
            ),
            Positioned(
              top: topPad + 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _setOnMapTarget == _SetOnMapTarget.from
                        ? context.l10n.setAsOrigin
                        : context.l10n.setAsDestination,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 24,
              right: 24,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(
                        () => _setOnMapTarget = _SetOnMapTarget.none,
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(context.l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _confirmSetOnMap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryColor,
                        foregroundColor: AppColors.textOnPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(context.l10n.confirmPin),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }
}

// ─── Navigation Banner ────────────────────────────────────────────────────────

class _NavigationBanner extends StatelessWidget {
  const _NavigationBanner({
    required this.step,
    required this.distToStep,
    required this.onStop,
    required this.topPad,
  });
  final RouteStep step;
  final double distToStep;
  final VoidCallback onStop;
  final double topPad;

  String _formatDist(double meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
    return '${meters.round()} m';
  }

  IconData _icon(String m) {
    switch (m) {
      case 'turn-left':
      case 'turn-sharp-left':
        return Icons.turn_left_rounded;
      case 'turn-right':
      case 'turn-sharp-right':
        return Icons.turn_right_rounded;
      case 'turn-slight-left':
        return Icons.turn_slight_left_rounded;
      case 'turn-slight-right':
        return Icons.turn_slight_right_rounded;
      case 'uturn-left':
      case 'uturn-right':
        return Icons.u_turn_right_rounded;
      default:
        return Icons.straight_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, topPad + 12, 16, 16),
        color: _kPrimaryPressed,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _icon(step.maneuver),
                color: AppColors.textOnPrimary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.instruction,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDist(distToStep),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textOnPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              color: AppColors.textOnPrimary,
              onPressed: onStop,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Navigation Bottom Bar ────────────────────────────────────────────────────
/// Shows remaining distance, ETA, and a Stop button during live navigation.
class _NavigationBottomBar extends StatelessWidget {
  const _NavigationBottomBar({
    required this.route,
    required this.stepIdx,
    required this.distToStep,
    required this.speedKmh,
    required this.onStop,
  });
  final RouteResult route;
  final int stepIdx;

  /// GPS-measured distance (metres) to the end of the current step.
  /// Used to display a live remaining-distance that reflects actual progress
  /// within the current step, not just cumulative step totals.
  final double distToStep;
  final double speedKmh;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    // Bug 1 fix: remaining = distance to end of *current* step (GPS-measured)
    // plus the full distances of all subsequent steps.
    // This correctly decrements as the user rides through the current step.
    final remainingMeters =
        distToStep + route.remainingDistanceFrom(stepIdx + 1);
    final remainingDist = remainingMeters >= 1000
        ? '${(remainingMeters / 1000).toStringAsFixed(1)} km'
        : '${remainingMeters.round()} m';
    // Remaining time: proportion current step by GPS progress, rest exact.
    final currentStepDist = route.steps[stepIdx].distanceMeters;
    final currentStepSecs = route.steps[stepIdx].durationSeconds;
    final partialSecs = currentStepDist > 0
        ? (distToStep / currentStepDist * currentStepSecs).round()
        : 0;
    final remainingSeconds =
        partialSecs + route.remainingDurationFrom(stepIdx + 1);
    final remainingMins = (remainingSeconds / 60).round();
    final remainingTime = remainingMins < 60
        ? '$remainingMins min'
        : '${remainingMins ~/ 60}h ${remainingMins % 60}min';
    final stepsLeft = route.steps.length - stepIdx;
    final eta = DateTime.now().add(Duration(seconds: remainingSeconds));
    final etaStr = TimeOfDay.fromDateTime(eta).format(context);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Remaining distance chip
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    remainingDist,
                    style: AppTextStyles.headline2.copyWith(
                      color: _kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        remainingTime,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.turn_slight_right_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        context.l10n.stepsRemaining(stepsLeft),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: _kPrimaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        context.l10n.arriveAt(etaStr),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _kPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Speed chip
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _kPrimaryPressed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    speedKmh.toStringAsFixed(0),
                    style: AppTextStyles.headline3.copyWith(
                      color: _kPrimaryColor,
                    ),
                  ),
                  Text(
                    'km/h',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Stop button — minimumSize:zero prevents infinite-width crash when
            // ElevatedButton is a free (non-Expanded) child of a Row and the
            // app theme sets minimumSize: Size(double.infinity, …).
            ElevatedButton.icon(
              icon: const Icon(Icons.stop_rounded, size: 18),
              label: Text(context.l10n.stopNavigation),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onStop,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Navigation Arrived Card ──────────────────────────────────────────────────
class _NavigationArrivedCard extends StatelessWidget {
  const _NavigationArrivedCard({required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  context.l10n.arrived,
                  style: AppTextStyles.headline2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimaryColor,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      context.l10n.done,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Route Search Panel (From → To) ──────────────────────────────────────────

enum _ActiveField { none, from, to }

class _RouteSearchPanel extends ConsumerStatefulWidget {
  const _RouteSearchPanel({
    super.key,
    required this.topPad,
    required this.isCalculating,
    required this.onOriginChanged,
    required this.onDestinationChanged,
    this.onSearchFocused,
    this.onSetOnMap,
    this.onWaypointAdded,
    this.onWaypointRemoved,
  });
  final double topPad;
  final bool isCalculating;
  final void Function(PlaceResult? place) onOriginChanged; // null = use GPS
  final void Function(PlaceResult? place) onDestinationChanged;
  final VoidCallback? onSearchFocused;
  final void Function(bool isFrom)? onSetOnMap;
  final void Function(PlaceResult waypoint)? onWaypointAdded;
  final void Function(int index)? onWaypointRemoved;

  @override
  ConsumerState<_RouteSearchPanel> createState() => _RouteSearchPanelState();
}

class _RouteSearchPanelState extends ConsumerState<_RouteSearchPanel> {
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _fromFocus = FocusNode();
  final _toFocus = FocusNode();

  _ActiveField _active = _ActiveField.none;
  List<PlaceResult> _suggestions = [];
  List<PlaceResult> _recentSearches = [];
  bool _loading = false;
  Timer? _debounce;

  // Holds the actual PlaceResult for each field (null from‑field = GPS)
  PlaceResult? _fromPlace;
  PlaceResult? _toPlace;

  static const _kRecentKey = 'recent_map_searches';

  @override
  void initState() {
    super.initState();
    _fromFocus.addListener(_onFocusChange);
    _toFocus.addListener(_onFocusChange);
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_kRecentKey) ?? [];
      final results = raw
          .map((s) {
            try {
              final m = json.decode(s) as Map<String, dynamic>;
              return PlaceResult(
                placeId: m['id'] as String,
                text: m['text'] as String,
                subtitle: (m['subtitle'] as String?) ?? '',
                lat: m['lat'] as double,
                lng: m['lng'] as double,
              );
            } catch (_) {
              return null;
            }
          })
          .whereType<PlaceResult>()
          .toList();
      if (mounted) setState(() => _recentSearches = results);
    } catch (_) {}
  }

  Future<void> _saveRecentSearch(PlaceResult place) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entry = json.encode({
        'id': place.placeId,
        'text': place.text,
        'subtitle': place.subtitle,
        'lat': place.lat,
        'lng': place.lng,
      });
      final existing = prefs.getStringList(_kRecentKey) ?? [];
      // Remove duplicate by placeId, prepend new, keep max 5.
      final updated = [
        entry,
        ...existing.where((s) {
          try {
            return (json.decode(s) as Map)['id'] != place.placeId;
          } catch (_) {
            return true;
          }
        }),
      ].take(5).toList();
      await prefs.setStringList(_kRecentKey, updated);
      if (mounted) {
        setState(
          () => _recentSearches = [
            place,
            ..._recentSearches.where((r) => r.placeId != place.placeId),
          ].take(5).toList(),
        );
      }
    } catch (_) {}
  }

  void _onFocusChange() {
    if (_fromFocus.hasFocus || _toFocus.hasFocus) {
      widget.onSearchFocused?.call();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel(); // Cancel timer FIRST to prevent post-dispose callbacks
    _fromFocus.removeListener(_onFocusChange);
    _toFocus.removeListener(_onFocusChange);
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  void _onFieldChanged(String value, _ActiveField field) {
    setState(() => _active = field);
    _debounce?.cancel();
    if (value.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 200), () async {
      setState(() => _loading = true);
      final lang = ref.read(localeProvider).languageCode;
      final center = ref.read(_userLocationProvider);
      final results = await ref
          .read(placesServiceProvider)
          .autocomplete(value, language: lang, center: center);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _loading = false;
        });
      }
    });
  }

  void _selectSuggestion(PlaceResult place) {
    _debounce?.cancel();
    FocusScope.of(context).unfocus();
    _saveRecentSearch(place);
    if (_active == _ActiveField.from) {
      _fromPlace = place;
      _fromCtrl.text = place.text;
      widget.onOriginChanged(place);
    } else {
      _toPlace = place;
      _toCtrl.text = place.text;
      widget.onDestinationChanged(place);
    }
    setState(() {
      _suggestions = [];
      _active = _ActiveField.none;
    });
  }

  void _clearFrom() {
    _fromPlace = null;
    _fromCtrl.clear();
    setState(() => _suggestions = []);
    widget.onOriginChanged(null); // back to GPS
  }

  void _clearTo() {
    _toPlace = null;
    _toCtrl.clear();
    setState(() => _suggestions = []);
    widget.onDestinationChanged(null);
  }

  void _swap() {
    final tempPlace = _fromPlace;
    final tempText = _fromCtrl.text;
    _fromPlace = _toPlace;
    _fromCtrl.text = _toCtrl.text;
    _toPlace = tempPlace;
    _toCtrl.text = tempText;
    setState(() => _suggestions = []);
    widget.onOriginChanged(_fromPlace);
    if (_toPlace != null) widget.onDestinationChanged(_toPlace);
  }

  /// Called by parent when the user clears the entire route.
  void reset() {
    _fromPlace = null;
    _toPlace = null;
    _fromCtrl.clear();
    _toCtrl.clear();
    setState(() {
      _suggestions = [];
      _active = _ActiveField.none;
    });
  }

  /// Called by parent when a long-press destination is set on the map.
  void setDestination(PlaceResult place) {
    _toPlace = place;
    _toCtrl.text = place.text;
    setState(() {
      _suggestions = [];
      _active = _ActiveField.none;
    });
    FocusScope.of(context).unfocus();
  }

  /// Called by parent when GPS reverse-geocode resolves the FROM address.
  void setFromAddress(String address) {
    if (_fromPlace == null && _fromCtrl.text.isEmpty) {
      // Only fill if the user hasn't typed anything in the FROM field.
      setState(() {});
      _fromCtrl.text = address;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasFrom = _fromCtrl.text.isNotEmpty;
    final bool hasTo = _toCtrl.text.isNotEmpty;

    return Positioned(
      top: widget.topPad + 8,
      left: 16,
      right: 16,
      child: Column(
        children: [
          // ── Modern Card with Glassmorphic Effect ───────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Modern Dot + line indicator with animation
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // FROM dot
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                    ),
                    // Connecting line
                    Container(
                      width: 2.5,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.success.withValues(alpha: 0.5),
                            _kPrimaryColor.withValues(alpha: 0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // TO dot
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _kPrimaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _kPrimaryColor.withValues(alpha: 0.3),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _kPrimaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                // Fields Container
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // FROM field with modern styling
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: _active == _ActiveField.from
                              ? _kPrimaryColor.withValues(alpha: 0.06)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _fromCtrl,
                          focusNode: _fromFocus,
                          onChanged: (v) =>
                              _onFieldChanged(v, _ActiveField.from),
                          onTap: () =>
                              setState(() => _active = _ActiveField.from),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            hintText: context.l10n.yourLocation,
                            hintStyle: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textHint,
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 12, right: 8),
                              child: Icon(
                                hasFrom
                                    ? Icons.trip_origin_rounded
                                    : Icons.my_location_rounded,
                                size: 18,
                                color: hasFrom
                                    ? AppColors.success
                                    : AppColors.success.withValues(alpha: 0.7),
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 38,
                            ),
                            suffixIcon: hasFrom
                                ? GestureDetector(
                                    onTap: _clearFrom,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  )
                                : null,
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // TO field with modern styling
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: _active == _ActiveField.to
                              ? _kPrimaryColor.withValues(alpha: 0.06)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _toCtrl,
                          focusNode: _toFocus,
                          onChanged: (v) => _onFieldChanged(v, _ActiveField.to),
                          onTap: () =>
                              setState(() => _active = _ActiveField.to),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            hintText: context.l10n.searchAddress,
                            hintStyle: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textHint,
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 12, right: 8),
                              child: Icon(
                                hasTo ? Icons.place_rounded : Icons.search_rounded,
                                size: 18,
                                color: hasTo
                                    ? _kPrimaryColor
                                    : AppColors.textSecondary
                                        .withValues(alpha: 0.5),
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 38,
                            ),
                            suffixIcon: widget.isCalculating && hasTo
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  )
                                : hasTo
                                    ? GestureDetector(
                                        onTap: _clearTo,
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 18,
                                            color: AppColors.textSecondary
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                      )
                                    : null,
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // Modern Swap button
                if (hasFrom || hasTo)
                  Container(
                    decoration: BoxDecoration(
                      color: _kPrimaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.swap_vert_rounded),
                      color: _kPrimaryColor,
                      onPressed: _swap,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      tooltip: 'Swap locations',
                    ),
                  )
                else
                  const SizedBox(width: 4),
              ],
            ),
          ),

          // ── Modern Waypoints (intermediate stops) ───────────────────────────────────
          // Only visible when a destination is set.
          if (hasTo) ...[
            ...ref
                .watch(_waypointsProvider)
                .asMap()
                .entries
                .map(
                  (e) => Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.radio_button_checked_rounded,
                            size: 16,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            e.value.text,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => widget.onWaypointRemoved?.call(e.key),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.error.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (ref.watch(_waypointsProvider).length < 3)
              Container(
                margin: const EdgeInsets.only(top: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: AppColors.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      builder: (_) => _WaypointSearchSheet(
                        onSave: (place) {
                          Navigator.of(context).pop();
                          widget.onWaypointAdded?.call(place);
                        },
                      ),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _kPrimaryColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _kPrimaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add_location_alt_rounded,
                              size: 18,
                              color: _kPrimaryColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            context.l10n.addStop,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: _kPrimaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],

          // ── Modern Suggestions Dropdown ────────────────────────
          if (_suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 360),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _suggestions.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    thickness: 0.5,
                    color: AppColors.surfaceVariant,
                    indent: 56,
                  ),
                  itemBuilder: (_, i) {
                    final s = _suggestions[i];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _selectSuggestion(s),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: (_active == _ActiveField.from
                                          ? AppColors.success
                                          : _kPrimaryColor)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _active == _ActiveField.from
                                      ? Icons.trip_origin_rounded
                                      : Icons.place_rounded,
                                  color: _active == _ActiveField.from
                                      ? AppColors.success
                                      : _kPrimaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      s.text,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                        height: 1.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (s.subtitle.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        s.subtitle,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          height: 1.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.north_west_rounded,
                                size: 16,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            )
          else if (_active != _ActiveField.none &&
              (_active == _ActiveField.to
                  ? _toCtrl.text.isEmpty
                  : _fromCtrl.text.isEmpty))
            // Show recent searches (and quick actions) when focused but empty.
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Saved routes (shown above recents when any exist) ──
                    if (ref.watch(savedRoutesProvider).isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.bookmark_rounded,
                              size: 16,
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.l10n.savedRoutes,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...ref
                          .watch(savedRoutesProvider)
                          .take(3)
                          .map(
                            (r) => Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  _debounce?.cancel();
                                  FocusScope.of(context).unfocus();
                                  final dest = PlaceResult(
                                    placeId: r.id,
                                    text: r.name,
                                    lat: r.destLat,
                                    lng: r.destLng,
                                  );
                                  _toPlace = dest;
                                  _toCtrl.text = dest.text;
                                  widget.onDestinationChanged(dest);
                                  setState(() {
                                    _suggestions = [];
                                    _active = _ActiveField.none;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: _kPrimaryColor
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.bookmark_rounded,
                                          color: _kPrimaryColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              r.name,
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                fontWeight: FontWeight.w600,
                                                height: 1.3,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              r.distanceLabel,
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                color: AppColors.textSecondary,
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 14,
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.4),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      const Divider(
                        height: 1,
                        thickness: 0.5,
                        color: AppColors.surfaceVariant,
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.l10n.recentSearches,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // "My Location" quick action
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final isFromField = _active == _ActiveField.from;
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _active = _ActiveField.none;
                            _suggestions = [];
                          });
                          // Signal parent to use GPS for FROM field.
                          if (isFromField) _clearFrom();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.success
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.my_location_rounded,
                                  color: AppColors.success,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  context.l10n.myLocation,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // "Set on map" quick action
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final isFrom = _active == _ActiveField.from;
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _active = _ActiveField.none;
                            _suggestions = [];
                          });
                          widget.onSetOnMap?.call(isFrom);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _kPrimaryColor
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.location_searching_rounded,
                                  color: _kPrimaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  context.l10n.setOnMap,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w500,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 0.5,
                      color: AppColors.surfaceVariant,
                    ),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _recentSearches.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          color: AppColors.surfaceVariant,
                        ),
                        itemBuilder: (_, i) {
                          final r = _recentSearches[i];
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.history_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            title: Text(
                              r.text,
                              style: AppTextStyles.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: r.subtitle.isNotEmpty
                                ? Text(
                                    r.subtitle,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            onTap: () => _selectSuggestion(r),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_loading)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (!_loading &&
              _active != _ActiveField.none &&
              (_active == _ActiveField.to
                  ? _toCtrl.text.isNotEmpty
                  : _fromCtrl.text.isNotEmpty))
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  context.l10n.noPlacesFound,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Route Summary Card ───────────────────────────────────────────────────────

/// Generates a GPX XML string from a planned [RouteResult]'s polyline.
String _gpxFromRoute(RouteResult route) {
  final sb = StringBuffer();
  sb.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  sb.writeln(
      '<gpx version="1.1" creator="CYKEL" xmlns="http://www.topografix.com/GPX/1/1">');
  sb.writeln('  <rte>');
  for (final pt in route.polylinePoints) {
    sb.writeln('    <rtept lat="${pt.latitude}" lon="${pt.longitude}"></rtept>');
  }
  sb.writeln('  </rte>');
  sb.writeln('</gpx>');
  return sb.toString();
}

/// Saves the route as a GPX temp file and shows a copy/share bottom sheet.
Future<void> _shareRouteGpx(BuildContext context, RouteResult route) async {
  if (route.polylinePoints.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.noRouteToExport)),
    );
    return;
  }
  final gpx = _gpxFromRoute(route);
  try {
    final dir = Directory.systemTemp;
    final file =
        File('${dir.path}/cykel_route_${DateTime.now().millisecondsSinceEpoch}.gpx');
    await file.writeAsString(gpx);
    if (context.mounted) {
      showModalBottomSheet<void>(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => _RouteGpxSheet(gpxPath: file.path, gpxContent: gpx),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.exportFailed(e.toString()))));
    }
  }
}

class _RouteGpxSheet extends StatelessWidget {
  const _RouteGpxSheet({required this.gpxPath, required this.gpxContent});
  final String gpxPath;
  final String gpxContent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.shareRouteGpx,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(context.l10n.gpxFileLabel(gpxPath),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: Text(context.l10n.copyGpxToClipboard),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: gpxContent));
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.routeGpxCopied)),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

Future<void> _prefetchTiles(
  BuildContext context,
  WidgetRef ref,
  RouteResult route,
  GoogleMapController controller,
) async {
  if (route.polylinePoints.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.noRouteToCacheTiles)),
    );
    return;
  }

  // Show progress indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _TilePrefetchDialog(),
  );

  try {
    final service = ref.read(tilePrefetchServiceProvider);
    final currentCamera = await controller.getVisibleRegion();
    final center = LatLng(
      (currentCamera.northeast.latitude + currentCamera.southwest.latitude) / 2,
      (currentCamera.northeast.longitude + currentCamera.southwest.longitude) / 2,
    );

    await service.prefetchRoute(
      controller: controller,
      polyline: route.polylinePoints,
      restoreTarget: CameraPosition(
        target: center,
        zoom: await controller.getZoomLevel(),
      ),
      onProgress: (progress) {
        // Update progress if dialog is still showing
        if (context.mounted) {
          // The dialog handles its own progress via a stream
        }
      },
    );

    if (context.mounted) {
      Navigator.of(context).pop(); // Close progress dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.tilesCachedForOffline),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop(); // Close progress dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tilePrefetchFailed(e.toString()))),
      );
    }
  }
}

class _TilePrefetchDialog extends StatelessWidget {
  const _TilePrefetchDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.cachingMapTilesTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            context.l10n.cachingMapTilesBody,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _RouteSummaryCard extends ConsumerWidget {
  const _RouteSummaryCard({
    required this.onStart,
    required this.onRecalculate,
    required this.mapController,
  });
  final VoidCallback onStart;
  final VoidCallback onRecalculate;
  final GoogleMapController? mapController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(_routeResultProvider)!;
    final altRoutes = ref.watch(_altRoutesProvider);
    final selIdx = ref.watch(_selectedRouteIndexProvider);
    final profile = ref.watch(bikeProfileProvider);
    final savedRoutes = ref.watch(savedRoutesProvider);
    final windAsync = ref.watch(_routeWindProvider);
    final dest = ref.watch(_selectedDestProvider);
    final destLatLng = ref.watch(_destLatLngProvider);
    final origin = ref.watch(_originPlaceProvider);
    final userLoc = ref.watch(_userLocationProvider);
    final routeMode = ref.watch(_routeModeProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    // Adjusted ETA using the selected bike profile speed multiplier.
    final int adjustedMins =
        (route.durationSeconds * profile.durationMultiplier / 60).round();
    final String adjustedLabel = adjustedMins < 60
        ? '$adjustedMins min'
        : '${adjustedMins ~/ 60}h${adjustedMins % 60 > 0 ? ' ${adjustedMins % 60}min' : ''}';

    // Wind badge — populated once the async fetch resolves.
    WindData? windData;
    WindCondition? windCondition;
    if (windAsync.hasValue &&
        windAsync.value != null &&
        route.polylinePoints.length >= 2) {
      windData = windAsync.value!;
      final bearing = _bearingBetween(
        route.polylinePoints.first,
        route.polylinePoints.last,
      );
      windCondition = windData.condition(bearing);
    }

    // Save state — keyed by destination placeId.
    final savedId = dest?.placeId ?? '';
    final isSaved =
        savedId.isNotEmpty && savedRoutes.any((r) => r.id == savedId);

    return Positioned(
      bottom: bottomPad + 12,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Compact Header with Origin & Destination ──────────────────
            Row(
              children: [
                // Origin & Destination stacked
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              origin?.text ?? context.l10n.myLocation,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: AppColors.error),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              dest?.text ?? context.l10n.destination,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Distance & Time badges inline
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kPrimaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.straighten_rounded, size: 12, color: _kPrimaryColor),
                      const SizedBox(width: 3),
                      Text(
                        route.distanceLabel,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimaryColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: AppColors.info),
                      const SizedBox(width: 3),
                      Text(
                        adjustedLabel,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.info),
                      ),
                    ],
                  ),
                ),
                // Bookmark button
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      size: 20,
                    ),
                    color: isSaved ? _kPrimaryColor : AppColors.textSecondary,
                    onPressed: () => _toggleSaveRoute(
                      ref: ref,
                      context: context,
                      route: route,
                      dest: dest,
                      destLatLng: destLatLng,
                      origin: origin,
                      userLoc: userLoc,
                      isSaved: isSaved,
                      savedId: savedId,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // ── Combined Route Mode + Bike Profile Row ────────────────────
            Row(
              children: [
                // Route Mode (compact chips)
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      _CompactModeChip(
                        icon: Icons.bolt_rounded,
                        label: context.l10n.routeFastest,
                        selected: routeMode == RouteMode.fastest,
                        onTap: () {
                          ref.read(_routeModeProvider.notifier).state = RouteMode.fastest;
                          onRecalculate();
                        },
                      ),
                      const SizedBox(width: 4),
                      _CompactModeChip(
                        icon: Icons.shield_rounded,
                        label: context.l10n.routeSafest,
                        selected: routeMode == RouteMode.safest,
                        onTap: () {
                          ref.read(_routeModeProvider.notifier).state = RouteMode.safest;
                          onRecalculate();
                        },
                      ),
                      const SizedBox(width: 4),
                      _CompactModeChip(
                        icon: Icons.air_rounded,
                        label: context.l10n.routeEffort,
                        selected: routeMode == RouteMode.effortOptimized,
                        onTap: () {
                          ref.read(_routeModeProvider.notifier).state = RouteMode.effortOptimized;
                          onRecalculate();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Bike Profile (icon-only chips)
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: BikeProfile.values.map((p) {
                      final sel = p == profile;
                      return GestureDetector(
                        onTap: () => ref.read(bikeProfileProvider.notifier).setProfile(p),
                        child: Container(
                          width: 28,
                          height: 28,
                          margin: EdgeInsets.only(left: p != BikeProfile.values.first ? 3 : 0),
                          decoration: BoxDecoration(
                            color: sel
                                ? _kPrimaryColor.withValues(alpha: 0.15)
                                : AppColors.surfaceVariant.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(6),
                            border: sel ? Border.all(color: _kPrimaryColor, width: 1.5) : null,
                          ),
                          child: Icon(
                            p.icon,
                            size: 14,
                            color: sel ? _kPrimaryColor : AppColors.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            // ── Alt route tabs (compact) ──────────────────────────────────
            if (altRoutes.length > 1) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 52,
                child: Row(
                  children: List.generate(altRoutes.length, (i) {
                    final r = altRoutes[i];
                    final sel = i == selIdx;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          ref.read(_selectedRouteIndexProvider.notifier).state = i;
                          ref.read(_routeResultProvider.notifier).state = r;
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: EdgeInsets.only(right: i < altRoutes.length - 1 ? 6 : 0),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          decoration: BoxDecoration(
                            color: sel ? _kPrimaryColor : AppColors.surfaceVariant.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: sel ? _kPrimaryColor : AppColors.surfaceVariant,
                              width: sel ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (sel)
                                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 12),
                                  if (sel) const SizedBox(width: 3),
                                  Text(
                                    r.distanceLabel,
                                    style: TextStyle(
                                      color: sel ? Colors.white : AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                r.durationLabel,
                                style: TextStyle(
                                  color: sel ? Colors.white.withValues(alpha: 0.85) : AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
            // ── Wind badge (compact) ──────────────────────────────────────
            if (windData != null &&
                windCondition != null &&
                windCondition != WindCondition.calm) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _windColor(windCondition).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(_windIcon(windCondition), size: 12, color: _windColor(windCondition)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _windLabel(context, windData, windCondition),
                        style: TextStyle(fontSize: 11, color: _windColor(windCondition)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            // ── Action buttons (compact) ──────────────────────────────────
            Row(
              children: [
                // Start Navigation (primary)
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: onStart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 1,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.navigation_rounded, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          context.l10n.startNavigation,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Share (icon button)
                SizedBox(
                  width: 42,
                  height: 42,
                  child: OutlinedButton(
                    onPressed: () => _shareRouteGpx(context, route),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: _kPrimaryColor,
                      side: BorderSide(color: _kPrimaryColor.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Icon(Icons.share_rounded, size: 18),
                  ),
                ),
                const SizedBox(width: 6),
                // Download (icon button)
                SizedBox(
                  width: 42,
                  height: 42,
                  child: OutlinedButton(
                    onPressed: mapController != null
                        ? () => _prefetchTiles(context, ref, route, mapController!)
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: AppColors.success,
                      side: BorderSide(color: AppColors.success.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Icon(Icons.download_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact route mode chip for the summary card
class _CompactModeChip extends StatelessWidget {
  const _CompactModeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? _kPrimaryColor.withValues(alpha: 0.15)
                : AppColors.surfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(6),
            border: selected ? Border.all(color: _kPrimaryColor, width: 1.5) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12,
                color: selected ? _kPrimaryColor : AppColors.textSecondary,
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? _kPrimaryColor : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Layers Sheet ─────────────────────────────────────────────────────────────

class _LayersSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showTraffic = ref.watch(_showTrafficProvider);
    final showBike = ref.watch(_showBicycleLaneProvider);
    final showTransit = ref.watch(_showTransitProvider);
    final isNight = ref.watch(_isNightProvider);
    final showCharging = ref.watch(_showChargingProvider);
    final showService = ref.watch(_showServiceProvider);
    final showShops = ref.watch(_showShopsProvider);
    final showRental = ref.watch(_showRentalProvider);
    final showCykelRepair = ref.watch(_showCykelRepairProvider);
    final showCykelShop = ref.watch(_showCykelShopProvider);
    final showCykelCharging = ref.watch(_showCykelChargingProvider);
    final showCykelService = ref.watch(_showCykelServiceProvider);
    final showCykelRental = ref.watch(_showCykelRentalProvider);
    final cykelRepairCount = ref.watch(_cykelRepairCountProvider);
    final cykelShopCount = ref.watch(_cykelShopCountProvider);
    final cykelChargingCount = ref.watch(_cykelChargingCountProvider);
    final cykelServiceCount = ref.watch(_cykelServiceCountProvider);
    final cykelRentalCount = ref.watch(_cykelRentalCountProvider);
    final mapType = ref.watch(_mapTypeProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(context.l10n.mapStyle, style: AppTextStyles.headline3),
            const SizedBox(height: 10),
            SegmentedButton<MapType>(
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: _kPrimaryColor,
                selectedForegroundColor: AppColors.textOnPrimary,
              ),
              segments: [
                ButtonSegment(
                  value: MapType.normal,
                  label: Text(context.l10n.normalMap),
                  icon: const Icon(Icons.map_rounded),
                ),
                ButtonSegment(
                  value: MapType.satellite,
                  label: Text(context.l10n.satellite),
                  icon: const Icon(Icons.satellite_alt_rounded),
                ),
                ButtonSegment(
                  value: MapType.terrain,
                  label: Text(context.l10n.terrain),
                  icon: const Icon(Icons.terrain_rounded),
                ),
              ],
              selected: {mapType},
              onSelectionChanged: (s) =>
                  ref.read(_mapTypeProvider.notifier).state = s.first,
            ),
            const Divider(height: 24),
            Text(context.l10n.mapLayers, style: AppTextStyles.headline3),
            const SizedBox(height: 12),
            _LayerTile(
              icon: Icons.traffic_rounded,
              label: context.l10n.layerTraffic,
              value: showTraffic,
              onChanged: (v) =>
                  ref.read(_showTrafficProvider.notifier).state = v,
            ),
            _LayerTile(
              icon: Icons.directions_bike_rounded,
              label: context.l10n.layerBikeRoutes,
              value: showBike,
              onChanged: (v) =>
                  ref.read(_showBicycleLaneProvider.notifier).state = v,
            ),
            _LayerTile(
              icon: Icons.directions_transit_rounded,
              label: context.l10n.layerTransit,
              value: showTransit,
              onChanged: (v) =>
                  ref.read(_showTransitProvider.notifier).state = v,
            ),
            _LayerTile(
              icon: Icons.nightlight_round,
              label: context.l10n.nightMode,
              value: isNight,
              onChanged: (v) => ref.read(_nightOverrideProvider.notifier).state = v,
            ),
            const Divider(height: 20),
            _LayerTile(
              icon: Icons.ev_station_rounded,
              label: context.l10n.layerCharging,
              value: showCharging,
              onChanged: (v) =>
                  ref.read(_showChargingProvider.notifier).state = v,
            ),
            _LayerTile(
              icon: Icons.build_circle_outlined,
              label: context.l10n.layerService,
              value: showService,
              onChanged: (v) =>
                  ref.read(_showServiceProvider.notifier).state = v,
            ),
            _LayerTile(
              icon: Icons.pedal_bike_rounded,
              label: context.l10n.layerShops,
              value: showShops,
              onChanged: (v) => ref.read(_showShopsProvider.notifier).state = v,
            ),
            _LayerTile(
              icon: Icons.lock_open_rounded,
              label: context.l10n.layerRental,
              value: showRental,
              onChanged: (v) =>
                  ref.read(_showRentalProvider.notifier).state = v,
            ),
            _LayerTile(
              icon: Icons.air_rounded,
              label: context.l10n.windOverlay,
              value: ref.watch(_showWindOverlayProvider),
              onChanged: (v) =>
                  ref.read(_showWindOverlayProvider.notifier).state = v,
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(context.l10n.cykelVerifiedSection, style: AppTextStyles.headline3),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(_showCykelRepairProvider.notifier).state = true;
                    ref.read(_showCykelShopProvider.notifier).state = true;
                    ref.read(_showCykelChargingProvider.notifier).state = true;
                    ref.read(_showCykelServiceProvider.notifier).state = true;
                    ref.read(_showCykelRentalProvider.notifier).state = true;
                  },
                  child: const Text('Show All', style: TextStyle(color: _kPrimaryColor)),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(_showCykelRepairProvider.notifier).state = false;
                    ref.read(_showCykelShopProvider.notifier).state = false;
                    ref.read(_showCykelChargingProvider.notifier).state = false;
                    ref.read(_showCykelServiceProvider.notifier).state = false;
                    ref.read(_showCykelRentalProvider.notifier).state = false;
                  },
                  child: const Text('Clear All', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Filters section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.filter_list_rounded, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Filters',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Open Now filter
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    secondary: const Icon(Icons.access_time_rounded, size: 20, color: AppColors.textSecondary),
                    title: const Text('Open now only', style: AppTextStyles.bodySmall),
                    value: ref.watch(_filterOpenNowProvider),
                    activeTrackColor: _kPrimaryColor,
                    onChanged: (v) => ref.read(_filterOpenNowProvider.notifier).state = v,
                  ),
                  // Minimum rating filter
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 20, color: Colors.amber),
                            const SizedBox(width: 8),
                            Text(
                              'Minimum rating: ${ref.watch(_filterMinRatingProvider).toStringAsFixed(1)}★',
                              style: AppTextStyles.bodySmall,
                            ),
                            if (ref.watch(_filterMinRatingProvider) > 0) ...[
                              const Spacer(),
                              TextButton(
                                onPressed: () => ref.read(_filterMinRatingProvider.notifier).state = 0.0,
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Clear', style: TextStyle(fontSize: 12, color: _kPrimaryColor)),
                              ),
                            ],
                          ],
                        ),
                        Slider(
                          value: ref.watch(_filterMinRatingProvider),
                          min: 0,
                          max: 5,
                          divisions: 10,
                          activeColor: _kPrimaryColor,
                          label: ref.watch(_filterMinRatingProvider).toStringAsFixed(1),
                          onChanged: (v) => ref.read(_filterMinRatingProvider.notifier).state = v,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _LayerTile(
              icon: Icons.build_circle_rounded,
              label: context.l10n.layerCykelRepair,
              value: showCykelRepair,
              count: cykelRepairCount,
              onChanged: (v) =>
                  ref.read(_showCykelRepairProvider.notifier).state = v,
            ),
            _LayerTile(
              icon: Icons.store_rounded,
              label: context.l10n.layerCykelShop,
              value: showCykelShop,
              count: cykelShopCount,
              onChanged: (v) =>
                  ref.read(_showCykelShopProvider.notifier).state = v,
            ),
            _LayerTile(
              icon: Icons.ev_station_rounded,
              label: context.l10n.layerCykelCharging,
              value: showCykelCharging,
              count: cykelChargingCount,
              onChanged: (v) =>
                  ref.read(_showCykelChargingProvider.notifier).state = v,
            ),
            _LayerTile(
              icon: Icons.handyman_rounded,
              label: context.l10n.layerCykelService,
              value: showCykelService,
              count: cykelServiceCount,
              onChanged: (v) =>
                  ref.read(_showCykelServiceProvider.notifier).state = v,
            ),
            _LayerTile(
              icon: Icons.pedal_bike_rounded,
              label: context.l10n.layerCykelRental,
              value: showCykelRental,
              count: cykelRentalCount,
              onChanged: (v) =>
                  ref.read(_showCykelRentalProvider.notifier).state = v,
            ),
          ],
        ),
      ),
    );
  }
}

class _LayerTile extends StatelessWidget {
  const _LayerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.count,
  });
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final displayLabel = count != null && count! > 0
        ? '$label ($count)'
        : label;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: _kPrimaryColor),
      title: Text(displayLabel, style: AppTextStyles.bodyMedium),
      value: value,
      activeTrackColor: _kPrimaryColor,
      onChanged: onChanged,
    );
  }
}

// ─── Network Tile Provider ────────────────────────────────────────────────────
/// Fetches map tiles from a URL template with {z}/{x}/{y} placeholders.
/// Used for CyclOSM bike-lane overlay and transit overlay.
class _NetworkTileProvider extends TileProvider {
  _NetworkTileProvider(this._urlTemplate);
  final String _urlTemplate;
  final _client = http.Client();

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    final url = _urlTemplate
        .replaceAll('{x}', '$x')
        .replaceAll('{y}', '$y')
        .replaceAll('{z}', '${zoom ?? 0}');
    try {
      final resp = await _client.get(
        Uri.parse(url),
        headers: {'User-Agent': 'CYKELApp/1.0'},
      );
      if (resp.statusCode == 200) {
        return Tile(256, 256, resp.bodyBytes);
      }
    } catch (_) {}
    return TileProvider.noTile;
  }
}

// ─── POI Detail Bottom Sheet ──────────────────────────────────────────────────
/// Shown when a POI marker is tapped. Displays name, type, address and
/// a "Set as destination" action button.
class _PoiDetailSheet extends StatelessWidget {
  const _PoiDetailSheet({required this.poi, required this.onSetAsDestination});
  final PlaceResult poi;
  final VoidCallback onSetAsDestination;

  IconData _iconFor(String placeId) {
    if (placeId.contains('charging')) return Icons.ev_station_rounded;
    if (placeId.contains('service')) return Icons.build_circle_outlined;
    if (placeId.contains('shop')) return Icons.pedal_bike_rounded;
    if (placeId.contains('rental')) return Icons.lock_open_rounded;
    return Icons.place_rounded;
  }

  Color _colorFor(String placeId) {
    if (placeId.contains('charging')) return const Color(0xFFF59E0B); // amber
    if (placeId.contains('service')) return const Color(0xFF06B6D4); // cyan
    if (placeId.contains('shop')) return const Color(0xFF10B981); // green
    if (placeId.contains('rental')) return const Color(0xFF8B5CF6); // violet
    return _kPrimaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(poi.placeId);
    final icon = _iconFor(poi.placeId);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poi.text,
                      style: AppTextStyles.headline3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (poi.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        poi.subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.navigation_rounded),
              label: Text(context.l10n.setAsDestination),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryColor,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onSetAsDestination,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CYKEL Provider Detail Bottom Sheet ───────────────────────────────────────
/// Shown when a verified CYKEL provider marker is tapped. Richer than
/// _PoiDetailSheet — shows logo, status, type badge, phone/website, and
/// a prominent "Get Directions" action.
class _CykelProviderDetailSheet extends StatelessWidget {
  const _CykelProviderDetailSheet({
    required this.provider,
    required this.userLocation,
    required this.onGetDirections,
  });
  final CykelProvider provider;
  final LatLng? userLocation;
  final VoidCallback onGetDirections;

  IconData _iconForType() {
    switch (provider.providerType) {
      case ProviderType.repairShop:
        return Icons.build_circle_rounded;
      case ProviderType.bikeShop:
        return Icons.store_rounded;
      case ProviderType.chargingLocation:
        return Icons.ev_station_rounded;
      case ProviderType.servicePoint:
        return Icons.handyman_rounded;
      case ProviderType.rental:
        return Icons.pedal_bike_rounded;
    }
  }

  Color _colorForType() {
    switch (provider.providerType) {
      case ProviderType.repairShop:
        return AppColors.layerService;
      case ProviderType.bikeShop:
        return AppColors.layerShop;
      case ProviderType.chargingLocation:
        return AppColors.layerCharging;
      case ProviderType.servicePoint:
        return AppColors.layerService;
      case ProviderType.rental:
        return AppColors.layerShop;
    }
  }

  /// Calculate distance from user location to provider (in km)
  double? _calculateDistance() {
    if (userLocation == null) return null;
    const earthRadiusKm = 6371.0;
    final lat1 = userLocation!.latitude;
    final lon1 = userLocation!.longitude;
    final lat2 = provider.latitude;
    final lon2 = provider.longitude;
    
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) * math.cos(_degToRad(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180);

  String _formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).round()} m';
    } else {
      return '${km.toStringAsFixed(1)} km';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForType();
    final l10n = context.l10n;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Logo or fallback icon
              if (provider.logoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    provider.logoUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _FallbackIcon(
                      icon: _iconForType(),
                      color: color,
                    ),
                  ),
                )
              else
                _FallbackIcon(icon: _iconForType(), color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.businessName,
                      style: AppTextStyles.headline3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Rating
                        if (provider.rating > 0) ...[
                          const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            provider.rating.toStringAsFixed(1),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (provider.reviewCount > 0) ...[
                            Text(
                              ' (${provider.reviewCount})',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 12,
                            color: AppColors.surfaceVariant,
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Distance
                        if (_calculateDistance() != null) ...[
                          const Icon(Icons.directions_walk_rounded, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 2),
                          Text(
                            _formatDistance(_calculateDistance()!),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Verified badge
                        if (provider.isVerified) ...[
                          Icon(Icons.verified_rounded, size: 14, color: color),
                          const SizedBox(width: 4),
                          Text(
                            l10n.providerDetailVerified,
                            style: AppTextStyles.labelSmall.copyWith(color: color),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Open Now status (using new isOpenNow getter)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: provider.isOpenNow
                                ? AppColors.success.withValues(alpha: 0.12)
                                : AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            provider.isOpenNow
                                ? 'Open now'
                                : l10n.providerDetailClosed,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: provider.isOpenNow
                                  ? AppColors.success
                                  : AppColors.error,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Address
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${provider.streetAddress}, ${provider.postalCode} ${provider.city}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // Phone
          if (provider.phone.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.phone_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  provider.phone,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          // Actions row
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.navigation_rounded),
              label: Text(l10n.providerDetailGetDirections),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onGetDirections,
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

// ─── Waypoint Search Sheet ────────────────────────────────────────────────────
// Simple address-search sheet used when the rider taps "Add stop".

class _WaypointSearchSheet extends ConsumerStatefulWidget {
  const _WaypointSearchSheet({required this.onSave});
  final void Function(PlaceResult place) onSave;

  @override
  ConsumerState<_WaypointSearchSheet> createState() =>
      _WaypointSearchSheetState();
}

class _WaypointSearchSheetState extends ConsumerState<_WaypointSearchSheet> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  List<PlaceResult> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _search(String v) {
    _debounce?.cancel();
    if (v.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _loading = true);
      final lang = ref.read(localeProvider).languageCode;
      final center = ref.read(_userLocationProvider);
      final results = await ref
          .read(placesServiceProvider)
          .autocomplete(v, language: lang, center: center);
      if (mounted) {
        setState(() {
          _results = results;
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(l10n.addStop, style: AppTextStyles.headline3),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              focusNode: _focus,
              autofocus: true,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: l10n.addressSearch,
                prefixIcon: const Icon(Icons.add_location_rounded),
                suffixIcon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
            ),
            if (_results.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: AppColors.surfaceVariant),
                  itemBuilder: (context, i) {
                    final r = _results[i];
                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.place_rounded,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      title: Text(
                        r.text,
                        style: AppTextStyles.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => widget.onSave(r),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Hazard Detail Sheet ───────────────────────────────────────────────────────
//
// Shows when a crowd-reported hazard marker is tapped.
// Displays the report status lifecycle badge, credibility score,
// confirm / dismiss actions, and type/severity metadata.

class _HazardDetailSheet extends ConsumerWidget {
  const _HazardDetailSheet({required this.hazard});
  final CrowdHazardReport hazard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.read(crowdHazardServiceProvider);
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Header row: type label + status badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _crowdHazardLabel(context, hazard.type, l10n),
                      style: AppTextStyles.headline3,
                    ),
                  ),
                  _StatusBadge(status: hazard.status),
                ],
              ),
              const SizedBox(height: 8),
              // Severity chip + age
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: hazard.severity.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: hazard.severity.color),
                    ),
                    child: Text(
                      hazard.severity.label(context),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: hazard.severity.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _relativeTime(hazard.reportedAt, l10n),
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Credibility bar
              _CredibilityBar(score: hazard.credibilityScore),
              const SizedBox(height: 6),
              Text(
                context.l10n.credibilityLabel(
                  hazard.credibilityScore.toString(),
                  hazard.confirmCount.toString(),
                  hazard.dismissCount.toString(),
                ),
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              // Confirm / dismiss actions
              if (hazard.status != ReportStatus.resolved) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          svc.confirmHazard(hazard.id);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.hazardConfirmedThanks),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(l10n.hazardStillThere),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: const BorderSide(color: AppColors.warning),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          svc.dismissHazard(hazard.id);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.hazardClearedThanks),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: Text(l10n.hazardCleared),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else
                Text(
                  l10n.hazardResolved,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _crowdHazardLabel(
      BuildContext context, CrowdHazardType type, AppLocalizations l10n) =>
      switch (type) {
        CrowdHazardType.roadDamage  => l10n.hazardTypeRoadDamage,
        CrowdHazardType.accident    => l10n.hazardTypeAccident,
        CrowdHazardType.debris      => l10n.hazardTypeDebris,
        CrowdHazardType.roadClosed  => l10n.hazardTypeRoadClosed,
        CrowdHazardType.badSurface  => l10n.hazardTypeBadSurface,
        CrowdHazardType.flooding    => l10n.hazardTypeFlooding,
      };

  String _relativeTime(DateTime dt, AppLocalizations l10n) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return l10n.agoMinutes(diff.inMinutes);
    if (diff.inHours < 24)   return l10n.agoHours(diff.inHours);
    return l10n.agoDays(diff.inDays);
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 13, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label(context),
            style: AppTextStyles.bodySmall.copyWith(
              color: status.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Credibility progress bar ──────────────────────────────────────────────────

class _CredibilityBar extends StatelessWidget {
  const _CredibilityBar({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 70
        ? AppColors.success
        : score >= 40
            ? AppColors.warning
            : AppColors.error;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: score / 100,
        minHeight: 6,
        backgroundColor: AppColors.surfaceVariant,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
