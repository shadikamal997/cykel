/// CYKEL — Elevation Profile Service
/// Fetches and calculates elevation data for routes

import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../domain/advanced_route.dart';

class ElevationService {
  ElevationService({
    required this.apiKey,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String apiKey;
  final http.Client _httpClient;

  /// Base URL for Google Elevation API
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/elevation/json';

  /// Calculate elevation profile from a list of points
  /// 
  /// Uses Google Elevation API to fetch elevation data for each point
  /// Returns null if API call fails
  Future<ElevationProfile?> calculateElevationProfile({
    required List<LatLng> pathPoints,
    int maxSamples = 100,
  }) async {
    if (pathPoints.isEmpty) return null;

    // Sample points if too many (API has limits)
    final sampledPoints = _samplePoints(pathPoints, maxSamples);

    // Fetch elevation data from API
    final elevations = await _fetchElevations(sampledPoints);
    if (elevations == null) return null;

    // Calculate distances between points
    final points = <ElevationPoint>[];
    double cumulativeDistance = 0.0;

    for (int i = 0; i < sampledPoints.length; i++) {
      if (i > 0) {
        cumulativeDistance += _calculateDistance(
          sampledPoints[i - 1],
          sampledPoints[i],
        );
      }

      points.add(ElevationPoint(
        distanceKm: cumulativeDistance,
        elevationM: elevations[i],
      ));
    }

    // Calculate elevation gain and loss
    double totalGain = 0.0;
    double totalLoss = 0.0;
    double maxElevation = elevations.first;
    double minElevation = elevations.first;

    for (int i = 1; i < elevations.length; i++) {
      final diff = elevations[i] - elevations[i - 1];
      
      if (diff > 0) {
        totalGain += diff;
      } else {
        totalLoss += diff.abs();
      }

      if (elevations[i] > maxElevation) maxElevation = elevations[i];
      if (elevations[i] < minElevation) minElevation = elevations[i];
    }

    return ElevationProfile(
      points: points,
      totalElevationGainM: totalGain,
      totalElevationLossM: totalLoss,
      maxElevationM: maxElevation,
      minElevationM: minElevation,
    );
  }

  /// Calculate elevation profile from encoded polyline
  Future<ElevationProfile?> calculateElevationProfileFromPolyline({
    required String polyline,
    int maxSamples = 100,
  }) async {
    final points = _decodePolyline(polyline);
    return calculateElevationProfile(
      pathPoints: points,
      maxSamples: maxSamples,
    );
  }

  /// Fetch elevation data from Google Elevation API
  Future<List<double>?> _fetchElevations(List<LatLng> points) async {
    try {
      // Build locations parameter
      final locations = points
          .map((p) => '${p.latitude},${p.longitude}')
          .join('|');

      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'locations': locations,
        'key': apiKey,
      });

      final response = await _httpClient.get(uri);

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      
      if (data['status'] != 'OK') {
        return null;
      }

      final results = data['results'] as List<dynamic>;
      return results
          .map((r) => (r['elevation'] as num).toDouble())
          .toList();
    } catch (e) {
      // Log error or handle accordingly
      return null;
    }
  }

  /// Sample points evenly from a path
  /// 
  /// Reduces the number of points to stay within API limits
  List<LatLng> _samplePoints(List<LatLng> points, int maxSamples) {
    if (points.length <= maxSamples) return points;

    final sampledPoints = <LatLng>[];
    final step = points.length / maxSamples;

    for (int i = 0; i < maxSamples; i++) {
      final index = (i * step).floor();
      sampledPoints.add(points[index]);
    }

    // Always include the last point
    if (sampledPoints.last != points.last) {
      sampledPoints.add(points.last);
    }

    return sampledPoints;
  }

  /// Calculate distance between two points (Haversine formula)
  /// Returns distance in kilometers
  double _calculateDistance(LatLng point1, LatLng point2) {
    const earthRadiusKm = 6371.0;

    final lat1Rad = point1.latitude * (3.14159265359 / 180);
    final lat2Rad = point2.latitude * (3.14159265359 / 180);
    final deltaLat = (point2.latitude - point1.latitude) * (3.14159265359 / 180);
    final deltaLng = (point2.longitude - point1.longitude) * (3.14159265359 / 180);

    final a = math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) * math.pow(math.sin(deltaLng / 2), 2);
    final c = 2 * math.asin(math.sqrt(a));

    return earthRadiusKm * c;
  }

  /// Decode Google Maps polyline
  /// 
  /// Converts encoded polyline string to list of LatLng points
  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int byte;
      
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      
      final deltaLat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += deltaLat;

      shift = 0;
      result = 0;
      
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      
      final deltaLng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += deltaLng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  /// Estimate calories burned based on elevation gain and distance
  /// 
  /// Returns estimated calories burned
  int estimateCaloriesBurned({
    required double distanceKm,
    required double elevationGainM,
    double weightKg = 70.0, // Average weight
  }) {
    // Base calories from distance (cycling at moderate pace)
    final baseCalories = distanceKm * 40; // ~40 cal/km for cycling

    // Additional calories from elevation gain
    // Climbing burns significantly more calories
    final climbingCalories = elevationGainM * 1.5;

    return (baseCalories + climbingCalories * (weightKg / 70)).round();
  }

  /// Calculate estimated time based on distance and elevation
  /// 
  /// Returns estimated time in minutes
  int estimateTime({
    required double distanceKm,
    required double elevationGainM,
    double averageSpeedKmh = 18.0, // Moderate cycling speed
  }) {
    // Base time from distance
    final baseTimeMinutes = (distanceKm / averageSpeedKmh) * 60;

    // Additional time for climbing (assume 300m/hour vertical speed)
    final climbingTimeMinutes = (elevationGainM / 300) * 60;

    return (baseTimeMinutes + climbingTimeMinutes).round();
  }

  void dispose() {
    _httpClient.close();
  }
}
