/// CYKEL — Bike Share Service
/// Integration with GBFS (General Bikeshare Feed Specification) APIs

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../domain/bike_share_station.dart';

class BikeShareService {
  BikeShareService();

  // GBFS feed URLs for Copenhagen providers
  static const _bycyklenStationInfoUrl =
      'https://gbfs.urbansharing.com/oslobysykkel.no/station_information.json';
  static const _bycyklenStationStatusUrl =
      'https://gbfs.urbansharing.com/oslobysykkel.no/station_status.json';

  final _stationsController = StreamController<List<BikeShareStation>>.broadcast();
  List<BikeShareStation> _cachedStations = [];
  DateTime? _lastFetch;
  Timer? _refreshTimer;

  /// Stream of all bike share stations
  Stream<List<BikeShareStation>> get stationsStream => _stationsController.stream;

  /// Get all active bike share stations
  Future<List<BikeShareStation>> getAllStations() async {
    // Return cached data if fresh (less than 1 minute old)
    if (_cachedStations.isNotEmpty &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!).inSeconds < 60) {
      return _cachedStations;
    }

    final stations = <BikeShareStation>[];

    // Fetch Bycyklen stations (Copenhagen City Bikes)
    try {
      final bycyklenStations = await _fetchBycyklenStations();
      stations.addAll(bycyklenStations);
    } catch (e) {
      developer.log('Error fetching Bycyklen stations: $e', name: 'BikeShareService');
    }

    // Add mock data for other providers (would be real API calls in production)
    stations.addAll(_getMockDonkeyStations());
    stations.addAll(_getMockLimeStations());

    _cachedStations = stations;
    _lastFetch = DateTime.now();
    _stationsController.add(stations);

    return stations;
  }

  /// Fetch Bycyklen stations from GBFS feed
  Future<List<BikeShareStation>> _fetchBycyklenStations() async {
    try {
      // Fetch station information (static data)
      final infoResponse = await http.get(Uri.parse(_bycyklenStationInfoUrl));
      if (infoResponse.statusCode != 200) {
        throw Exception('Failed to load station info: ${infoResponse.statusCode}');
      }

      final infoData = json.decode(infoResponse.body);
      final stationsInfo = infoData['data']['stations'] as List;

      // Fetch station status (real-time data)
      final statusResponse = await http.get(Uri.parse(_bycyklenStationStatusUrl));
      if (statusResponse.statusCode != 200) {
        throw Exception('Failed to load station status: ${statusResponse.statusCode}');
      }

      final statusData = json.decode(statusResponse.body);
      final stationsStatus = statusData['data']['stations'] as List;

      // Create map of station statuses for quick lookup
      final statusMap = <String, dynamic>{};
      for (final status in stationsStatus) {
        statusMap[status['station_id']] = status;
      }

      // Combine info and status data
      final stations = <BikeShareStation>[];
      for (final info in stationsInfo) {
        final status = statusMap[info['station_id']];
        if (status == null) continue;

        stations.add(BikeShareStation(
          id: info['station_id'].toString(),
          name: info['name'] ?? 'Unknown Station',
          provider: BikeShareProvider.bycyklen,
          location: LatLng(info['lat'] as double, info['lon'] as double),
          address: info['address'] ?? '',
          totalCapacity: info['capacity'] as int?,
          availableBikes: 0, // Bycyklen only has e-bikes
          availableEBikes: status['num_bikes_available'] as int?,
          availableScooters: 0,
          availableDocks: status['num_docks_available'] as int?,
          isActive: status['is_renting'] == 1 && status['is_returning'] == 1,
          lastUpdated: DateTime.fromMillisecondsSinceEpoch(
            status['last_reported'] * 1000,
          ),
        ));
      }

      return stations;
    } catch (e) {
      // Return empty list on error
      developer.log('Error in _fetchBycyklenStations: $e', name: 'BikeShareService');
      return [];
    }
  }

  /// Get stations filtered by provider
  Future<List<BikeShareStation>> getStationsByProvider(
    BikeShareProvider provider,
  ) async {
    final allStations = await getAllStations();
    return allStations.where((s) => s.provider == provider).toList();
  }

  /// Get nearby stations within radius (in kilometers)
  Future<List<BikeShareStation>> getNearbyStations({
    required LatLng userLocation,
    double radiusKm = 1.0,
    int? limit,
  }) async {
    final allStations = await getAllStations();

    // Calculate distances and filter by radius
    final nearbyStations = allStations.map((station) {
      final distance = station.distanceFromPoint(userLocation);
      return station.copyWith(distance: distance);
    }).where((station) {
      return station.distance! <= radiusKm;
    }).toList();

    // Sort by distance
    nearbyStations.sort((a, b) => a.distance!.compareTo(b.distance!));

    // Apply limit if specified
    if (limit != null && nearbyStations.length > limit) {
      return nearbyStations.sublist(0, limit);
    }

    return nearbyStations;
  }

  /// Get station by ID
  Future<BikeShareStation?> getStationById(String stationId) async {
    final allStations = await getAllStations();
    try {
      return allStations.firstWhere((s) => s.id == stationId);
    } catch (e) {
      return null;
    }
  }

  /// Start auto-refresh timer (updates every 30 seconds)
  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      getAllStations();
    });
  }

  /// Stop auto-refresh timer
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
  }

  /// Mock Donkey Republic stations (would be replaced with real API)
  List<BikeShareStation> _getMockDonkeyStations() {
    return [
      const BikeShareStation(
        id: 'donkey_1',
        name: 'Nørreport Station',
        provider: BikeShareProvider.donkey,
        location: LatLng(55.6833, 12.5719),
        address: 'Nørreport, Copenhagen',
        totalCapacity: 20,
        availableBikes: 8,
        availableEBikes: 4,
        availableDocks: 8,
        isActive: true,
      ),
      const BikeShareStation(
        id: 'donkey_2',
        name: 'Kongens Have',
        provider: BikeShareProvider.donkey,
        location: LatLng(55.6851, 12.5778),
        address: 'Øster Voldgade, Copenhagen',
        totalCapacity: 15,
        availableBikes: 6,
        availableEBikes: 2,
        availableDocks: 7,
        isActive: true,
      ),
      const BikeShareStation(
        id: 'donkey_3',
        name: 'City Hall Square',
        provider: BikeShareProvider.donkey,
        location: LatLng(55.6759, 12.5697),
        address: 'Rådhuspladsen, Copenhagen',
        totalCapacity: 25,
        availableBikes: 10,
        availableEBikes: 5,
        availableDocks: 10,
        isActive: true,
      ),
    ];
  }

  /// Mock Lime stations (dockless - show popular drop zones)
  List<BikeShareStation> _getMockLimeStations() {
    return [
      const BikeShareStation(
        id: 'lime_zone_1',
        name: 'Nyhavn Area',
        provider: BikeShareProvider.lime,
        location: LatLng(55.6795, 12.5910),
        address: 'Nyhavn, Copenhagen',
        availableBikes: 3,
        availableEBikes: 5,
        availableScooters: 7,
        isActive: true,
      ),
      const BikeShareStation(
        id: 'lime_zone_2',
        name: 'Tivoli Gardens',
        provider: BikeShareProvider.lime,
        location: LatLng(55.6736, 12.5681),
        address: 'Vesterbrogade, Copenhagen',
        availableBikes: 2,
        availableEBikes: 8,
        availableScooters: 12,
        isActive: true,
      ),
      const BikeShareStation(
        id: 'lime_zone_3',
        name: 'Christiania',
        provider: BikeShareProvider.lime,
        location: LatLng(55.6738, 12.5992),
        address: 'Christianshavn, Copenhagen',
        availableBikes: 4,
        availableEBikes: 6,
        availableScooters: 9,
        isActive: true,
      ),
    ];
  }

  void dispose() {
    _refreshTimer?.cancel();
    _stationsController.close();
  }
}
