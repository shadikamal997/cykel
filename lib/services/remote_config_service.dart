/// CYKEL Remote Config Service
/// Dynamically configure app features without releasing updates
/// 
/// Use this to:
/// - Toggle features on/off
/// - Configure map settings
/// - A/B test features
/// - Emergency feature flags

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  RemoteConfigService._();
  static final instance = RemoteConfigService._();

  late final FirebaseRemoteConfig _remoteConfig;
  bool _initialized = false;

  /// Initialize Remote Config with defaults
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Set config settings
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 5) // Short interval for testing
              : const Duration(hours: 1), // Production interval
        ),
      );

      // Set default values
      await _remoteConfig.setDefaults(_defaultValues);

      // Fetch and activate
      await _remoteConfig.fetchAndActivate();

      _initialized = true;
      debugPrint('✅ Remote Config initialized');
    } catch (e) {
      debugPrint('⚠️ Remote Config initialization failed: $e');
      // Continue with defaults
    }
  }

  /// Default configuration values
  static const Map<String, dynamic> _defaultValues = {
    // Map Features
    'enable_traffic_layer': true,
    'enable_bike_lanes': true,
    'enable_wind_overlay': true,
    'enable_hazard_layer': true,
    'default_map_style': 'auto', // 'auto', 'light', 'dark', 'satellite'
    
    // Feature Flags
    'enable_bike_share': true,
    'enable_social_features': true,
    'enable_buddy_matching': true,
    'enable_expat_hub': true,
    'enable_marketplace': true,
    'enable_events': true,
    
    // Routing Settings
    'max_routing_distance_km': 100,
    'prefer_bike_lanes': true,
    'avoid_hills': false,
    'wind_routing_enabled': true,
    
    // Performance
    'enable_tile_prefetch': true,
    'max_nearby_hazards': 50,
    'max_nearby_providers': 30,
    'hazard_radius_km': 5.0,
    'provider_radius_km': 10.0,
    
    // Maintenance
    'maintenance_mode': false,
    'maintenance_message': '',
    'force_update': false,
    'min_app_version': '1.0.0',
    
    // Emergency Alerts
    'show_weather_alert': false,
    'weather_alert_message': '',
    'show_traffic_alert': false,
    'traffic_alert_message': '',
  };

  // ─── Map Features ──────────────────────────────────────────────────────────

  bool get enableTrafficLayer => _getBool('enable_traffic_layer');
  bool get enableBikeLanes => _getBool('enable_bike_lanes');
  bool get enableWindOverlay => _getBool('enable_wind_overlay');
  bool get enableHazardLayer => _getBool('enable_hazard_layer');
  String get defaultMapStyle => _getString('default_map_style');

  // ─── Feature Flags ─────────────────────────────────────────────────────────

  bool get enableBikeShare => _getBool('enable_bike_share');
  bool get enableSocialFeatures => _getBool('enable_social_features');
  bool get enableBuddyMatching => _getBool('enable_buddy_matching');
  bool get enableExpatHub => _getBool('enable_expat_hub');
  bool get enableMarketplace => _getBool('enable_marketplace');
  bool get enableEvents => _getBool('enable_events');

  // ─── Routing Settings ──────────────────────────────────────────────────────

  int get maxRoutingDistanceKm => _getInt('max_routing_distance_km');
  bool get preferBikeLanes => _getBool('prefer_bike_lanes');
  bool get avoidHills => _getBool('avoid_hills');
  bool get windRoutingEnabled => _getBool('wind_routing_enabled');

  // ─── Performance ───────────────────────────────────────────────────────────

  bool get enableTilePrefetch => _getBool('enable_tile_prefetch');
  int get maxNearbyHazards => _getInt('max_nearby_hazards');
  int get maxNearbyProviders => _getInt('max_nearby_providers');
  double get hazardRadiusKm => _getDouble('hazard_radius_km');
  double get providerRadiusKm => _getDouble('provider_radius_km');

  // ─── Maintenance ───────────────────────────────────────────────────────────

  bool get maintenanceMode => _getBool('maintenance_mode');
  String get maintenanceMessage => _getString('maintenance_message');
  bool get forceUpdate => _getBool('force_update');
  String get minAppVersion => _getString('min_app_version');

  // ─── Emergency Alerts ──────────────────────────────────────────────────────

  bool get showWeatherAlert => _getBool('show_weather_alert');
  String get weatherAlertMessage => _getString('weather_alert_message');
  bool get showTrafficAlert => _getBool('show_traffic_alert');
  String get trafficAlertMessage => _getString('traffic_alert_message');

  // ─── Helper Methods ────────────────────────────────────────────────────────

  bool _getBool(String key) {
    if (!_initialized) return _defaultValues[key] as bool? ?? false;
    return _remoteConfig.getBool(key);
  }

  String _getString(String key) {
    if (!_initialized) return _defaultValues[key] as String? ?? '';
    return _remoteConfig.getString(key);
  }

  int _getInt(String key) {
    if (!_initialized) return _defaultValues[key] as int? ?? 0;
    return _remoteConfig.getInt(key);
  }

  double _getDouble(String key) {
    if (!_initialized) {
      final value = _defaultValues[key];
      if (value is int) return value.toDouble();
      return value as double? ?? 0.0;
    }
    return _remoteConfig.getDouble(key);
  }

  /// Force fetch latest config from server
  Future<bool> fetchAndActivate() async {
    if (!_initialized) return false;
    try {
      return await _remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint('Failed to fetch Remote Config: $e');
      return false;
    }
  }

  /// Get all config values (for debugging)
  Map<String, dynamic> getAllValues() {
    if (!_initialized) return _defaultValues;
    
    return {
      for (final key in _defaultValues.keys)
        key: _remoteConfig.getValue(key).asString(),
    };
  }
}
