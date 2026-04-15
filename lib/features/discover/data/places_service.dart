/// CYKEL — Search Service via OpenStreetMap Nominatim
/// Free, no API key required. Supports both English and Danish input.
/// e.g. "Copenhagen" and "København" both return correct results.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class PlaceResult {
  const PlaceResult({
    required this.placeId,
    required this.text,
    required this.lat,
    required this.lng,
    this.subtitle = '',
  });

  /// For Nominatim, placeId is the osm_id (as string).
  final String placeId;
  /// Short primary label (place name + city).
  final String text;
  /// Full formatted address shown as secondary line in suggestions.
  final String subtitle;
  final double lat;
  final double lng;

  LatLng get latLng => LatLng(lat, lng);
}

class PlacesService {
  static const _baseUrl    = 'https://nominatim.openstreetmap.org/search';
  static const _reverseUrl = 'https://nominatim.openstreetmap.org/reverse';

  /// Search — accepts English OR Danish input.
  /// [language] is sent as Accept-Language so results display in that language.
  /// [center] is the user's current GPS location; used to build a viewbox so
  /// nearby results (streets, shops, buildings in the area) rank first.
  Future<List<PlaceResult>> autocomplete(
    String query, {
    String language = 'en',
    LatLng? center,
  }) async {
    if (query.trim().isEmpty) return [];
    try {
      // Build a ~15 km viewbox around [center] (or all of Denmark if unknown)
      final String viewbox;
      if (center != null) {
        const delta = 0.14; // ~15 km in degrees
        final minLon = center.longitude - delta;
        final maxLon = center.longitude + delta;
        final minLat = center.latitude  - delta;
        final maxLat = center.latitude  + delta;
        viewbox = '$minLon,$maxLat,$maxLon,$minLat';
      } else {
        viewbox = '8.0,57.8,15.3,54.5'; // all of Denmark
      }

      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': '50',         // Nominatim hard max
          'addressdetails': '1',
          'extratags': '1',
          'namedetails': '1',
          'viewbox': viewbox,
          'bounded': center != null ? '1' : '0',
        },
      );
      
      debugPrint('[PlacesService] Searching for: "$query" (lang=$language, center=${center != null ? '${center.latitude},${center.longitude}' : 'null'})');
      debugPrint('[PlacesService] Request URL: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Accept-Language': language,
          'User-Agent': 'CYKELApp/1.0',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('[PlacesService] ❌ Request timeout after 10 seconds');
          throw TimeoutException('Search request timed out');
        },
      );
      
      debugPrint('[PlacesService] Response status: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        debugPrint('[PlacesService] ❌ HTTP ${response.statusCode}: ${response.body}');
        return [];
      }
      
      debugPrint('[PlacesService] Response body length: ${response.body.length} bytes');
      
      final data = json.decode(response.body) as List;
      debugPrint('[PlacesService] ✅ Found ${data.length} results');
      
      if (data.isEmpty) {
        debugPrint('[PlacesService] ⚠️  No results returned from Nominatim for query "$query"');
        return [];
      }
      
      return data.map((item) {
        final m = item as Map<String, dynamic>;
        // Build a short, readable label: prefer name + road + city
        final addr = m['address'] as Map<String, dynamic>? ?? {};
        final name = (m['name'] as String?)?.trim() ?? '';
        final road = (addr['road'] as String?) ??
            (addr['pedestrian'] as String?) ??
            (addr['path'] as String?) ?? '';
        final houseNumber = (addr['house_number'] as String?) ?? '';
        final city = (addr['city'] as String?) ??
            (addr['town'] as String?) ??
            (addr['village'] as String?) ??
            (addr['municipality'] as String?) ?? '';
        final postcode = (addr['postcode'] as String?) ?? '';

        String label;
        if (name.isNotEmpty && road.isNotEmpty) {
          final streetPart = houseNumber.isNotEmpty ? '$road $houseNumber' : road;
          label = '$name, $streetPart';
        } else if (name.isNotEmpty) {
          label = name;
        } else if (road.isNotEmpty) {
          label = houseNumber.isNotEmpty ? '$road $houseNumber' : road;
        } else {
          label = m['display_name'] as String;
        }
        if (city.isNotEmpty) label += ', $city';
        if (postcode.isNotEmpty) label += ' $postcode';

        // Build subtitle = full readable address
        final parts = <String>[];
        if (road.isNotEmpty) parts.add(houseNumber.isNotEmpty ? '$road $houseNumber' : road);
        if (city.isNotEmpty) parts.add(city);
        if (postcode.isNotEmpty) parts.add(postcode);
        final subtitle = parts.isNotEmpty ? parts.join(', ') : (m['display_name'] as String? ?? '');

        return PlaceResult(
          placeId: m['osm_id'].toString(),
          text: label,
          subtitle: subtitle,
          lat: double.parse(m['lat'] as String),
          lng: double.parse(m['lon'] as String),
        );
      }).toList();
    } on TimeoutException catch (e) {
      debugPrint('[PlacesService] ❌ Timeout error: $e');
      return [];
    } on FormatException catch (e, st) {
      debugPrint('[PlacesService] ❌ JSON parsing error: $e\n$st');
      return [];
    } catch (e, st) {
      debugPrint('[PlacesService] ❌ Unexpected error: $e\n$st');
      return [];
    }
  }

  /// Reverse-geocodes [position] into a human-readable address.
  Future<PlaceResult?> reverseGeocode(
    LatLng position, {
    String language = 'en',
  }) async {
    try {
      final uri = Uri.parse(_reverseUrl).replace(queryParameters: {
        'lat': '${position.latitude}',
        'lon': '${position.longitude}',
        'format': 'json',
        'addressdetails': '1',
      });
      final response = await http.get(uri, headers: {
        'Accept-Language': language,
        'User-Agent': 'CYKELApp/1.0',
      });
      if (response.statusCode != 200) return null;
      final m = json.decode(response.body) as Map<String, dynamic>;
      if (m.containsKey('error')) return null;
      final addr        = m['address'] as Map<String, dynamic>? ?? {};
      final name        = (m['name'] as String?)?.trim() ?? '';
      final road        = (addr['road'] as String?) ?? (addr['pedestrian'] as String?) ?? '';
      final houseNumber = (addr['house_number'] as String?) ?? '';
      final city        = (addr['city'] as String?) ?? (addr['town'] as String?) ??
                          (addr['village'] as String?) ?? '';
      final postcode    = (addr['postcode'] as String?) ?? '';

      String label;
      if (name.isNotEmpty && road.isNotEmpty) {
        final street = houseNumber.isNotEmpty ? '$road $houseNumber' : road;
        label = '$name, $street';
      } else if (road.isNotEmpty) {
        label = houseNumber.isNotEmpty ? '$road $houseNumber' : road;
      } else if (name.isNotEmpty) {
        label = name;
      } else {
        label = m['display_name'] as String? ?? '${position.latitude}, ${position.longitude}';
      }
      if (city.isNotEmpty) label += ', $city';
      if (postcode.isNotEmpty) label += ' $postcode';

      final fullAddr = m['display_name'] as String? ?? '';
      return PlaceResult(
        placeId: m['osm_id']?.toString() ??
            'rev_${position.latitude}_${position.longitude}',
        text: label,
        subtitle: fullAddr,
        lat: position.latitude,
        lng: position.longitude,
      );
    } catch (e) {
      debugPrint('PlacesService.reverseGeocode error: $e');
      return null;
    }
  }

  /// Search POI by OSM amenity or shop tag near [center].
  /// Uses the Overpass API (the correct API for tag-based OSM queries).
  /// Nominatim /search does NOT support amenity/shop filtering — only Overpass does.
  Future<List<PlaceResult>> searchNearby({
    String? amenity,
    String? shop,
    required LatLng center,
    int limit = 50,
    double radiusMeters = 5000,
  }) async {
    try {
      const overpassUrl = 'https://overpass-api.de/api/interpreter';
      final lat = center.latitude;
      final lng = center.longitude;

      // Build Overpass QL filter tag
      final tag = amenity != null ? '"amenity"="$amenity"' : '"shop"="$shop"';

      final query = '''
[out:json][timeout:15];
(
  node[$tag](around:$radiusMeters,$lat,$lng);
  way[$tag](around:$radiusMeters,$lat,$lng);
  relation[$tag](around:$radiusMeters,$lat,$lng);
);
out center $limit;
''';

      final response = await http.post(
        Uri.parse(overpassUrl),
        body: 'data=${Uri.encodeComponent(query)}',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'CYKELApp/1.0',
        },
      );

      if (response.statusCode != 200) {
        debugPrint('Overpass HTTP ${response.statusCode}');
        return [];
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final elements = data['elements'] as List? ?? [];

      return elements.map((item) {
        final m = item as Map<String, dynamic>;
        final tags = m['tags'] as Map<String, dynamic>? ?? {};

        // Ways/relations have a `center` object; nodes have lat/lon directly.
        final double lat;
        final double lng;
        if (m['type'] == 'node') {
          lat = (m['lat'] as num).toDouble();
          lng = (m['lon'] as num).toDouble();
        } else {
          final c = m['center'] as Map<String, dynamic>;
          lat = (c['lat'] as num).toDouble();
          lng = (c['lon'] as num).toDouble();
        }

        final name = (tags['name'] as String?)?.trim() ??
            (tags['operator'] as String?)?.trim() ??
            (tags['brand'] as String?)?.trim() ??
            '';
        final osmType = amenity ?? shop ?? '';
        final label = name.isNotEmpty
            ? name
            : osmType
                .replaceAll('_', ' ')
                .split(' ')
                .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
                .join(' ');

        return PlaceResult(
          placeId: '${m['type']}_${m['id']}',
          text: label,
          lat: lat,
          lng: lng,
        );
      }).toList();
    } catch (e, st) {
      debugPrint('PlacesService.searchNearby error: $e\n$st');
      return [];
    }
  }

  /// Fetch all bike-related POIs near [center] in a single Overpass query.
  /// placeId prefixes: 'shop_*' | 'charging_*' | 'rental_*' | 'service_*'
  Future<List<PlaceResult>> searchNearbyBikePoints({
    required LatLng center,
    double radiusMeters = 3000,
  }) async {
    try {
      const overpassUrl = 'https://overpass-api.de/api/interpreter';
      final lat = center.latitude;
      final lng = center.longitude;
      final query =
          '[out:json][timeout:25];'
          '('
          'node["shop"="bicycle"](around:$radiusMeters,$lat,$lng);'
          'way["shop"="bicycle"](around:$radiusMeters,$lat,$lng);'
          'node["amenity"="charging_station"](around:$radiusMeters,$lat,$lng);'
          'node["amenity"="bicycle_rental"](around:$radiusMeters,$lat,$lng);'
          'node["amenity"="bicycle_repair_station"](around:$radiusMeters,$lat,$lng);'
          ');out center 20;';

      final response = await http.post(
        Uri.parse(overpassUrl),
        body: 'data=${Uri.encodeComponent(query)}',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'CYKELApp/1.0',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('PlacesService.searchNearbyBikePoints: Request timed out');
          throw TimeoutException('Overpass API request timed out');
        },
      );
      if (response.statusCode != 200) {
        debugPrint('PlacesService.searchNearbyBikePoints: HTTP ${response.statusCode}');
        return [];
      }
      final data = json.decode(response.body) as Map<String, dynamic>;
      final elements = data['elements'] as List? ?? [];
      return elements.map((item) {
        final m = item as Map<String, dynamic>;
        final tags = m['tags'] as Map<String, dynamic>? ?? {};
        final double itemLat;
        final double itemLng;
        if (m['type'] == 'node') {
          itemLat = (m['lat'] as num).toDouble();
          itemLng = (m['lon'] as num).toDouble();
        } else {
          final c = m['center'] as Map<String, dynamic>;
          itemLat = (c['lat'] as num).toDouble();
          itemLng = (c['lon'] as num).toDouble();
        }
        final amenity = tags['amenity'] as String? ?? '';
        final shop = tags['shop'] as String? ?? '';
        final String prefix;
        if (shop == 'bicycle') {
          prefix = 'shop';
        } else if (amenity == 'charging_station') {
          prefix = 'charging';
        } else if (amenity == 'bicycle_rental') {
          prefix = 'rental';
        } else {
          prefix = 'service';
        }
        final name = (tags['name'] as String?)?.trim() ??
            (tags['operator'] as String?)?.trim() ?? '';
        final label = name.isNotEmpty ? name : _categoryLabel(prefix);
        return PlaceResult(
          placeId: '${prefix}_${m['id']}',
          text: label,
          lat: itemLat,
          lng: itemLng,
        );
      }).toList();
    } catch (e, st) {
      debugPrint('PlacesService.searchNearbyBikePoints error: $e\n$st');
      return [];
    }
  }

  static String _categoryLabel(String prefix) => switch (prefix) {
    'shop' => 'Bike Shop',
    'charging' => 'Charging Station',
    'rental' => 'Bike Rental',
    _ => 'Service Point',
  };

  /// Kept for API compatibility. With Nominatim, coordinates are already on
  /// [PlaceResult.latLng] so this is not needed in normal usage.
  // getCoordinates removed — was always null (legacy stub)
}

final placesServiceProvider =
    Provider<PlacesService>((ref) => PlacesService());
