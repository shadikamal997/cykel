/// CYKEL Geohash Service
/// Provides geospatial indexing for efficient proximity queries
/// 
/// This service wraps geoflutterfire_plus to enable fast location-based
/// searches for hazards, providers, events, etc.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeohashService {
  GeohashService._();
  static final instance = GeohashService._();

  /// Convert LatLng to GeoFirePoint for storage
  GeoFirePoint point({required double latitude, required double longitude}) {
    return GeoFirePoint(GeoPoint(latitude, longitude));
  }

  /// Convert LatLng to GeoFirePoint
  GeoFirePoint fromLatLng(LatLng latLng) {
    return point(latitude: latLng.latitude, longitude: latLng.longitude);
  }

  /// Get geohash string from coordinates (for manual indexing)
  String getGeohash({required double latitude, required double longitude}) {
    final geoPoint = point(latitude: latitude, longitude: longitude);
    return geoPoint.geohash;
  }

  /// Create a geo-collection reference for querying
  GeoCollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return GeoCollectionReference(
      FirebaseFirestore.instance.collection(collectionPath),
    );
  }

  /// Query documents within radius (in kilometers)
  /// 
  /// Example:
  /// ```dart
  /// final hazards = await GeohashService.instance.queryWithinRadius(
  ///   collection: 'hazard_reports',
  ///   center: LatLng(55.6761, 12.5683),
  ///   radiusKm: 5.0,
  ///   field: 'geo', // Field name storing GeoFirePoint
  /// );
  /// ```
  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> queryWithinRadius({
    required String collectionPath,
    required LatLng center,
    required double radiusKm,
    String field = 'geo',
    Query<Map<String, dynamic>>? Function(Query<Map<String, dynamic>>)? queryBuilder,
  }) {
    final geoPoint = fromLatLng(center);
    
    final geoRef = GeoCollectionReference<Map<String, dynamic>>(
      FirebaseFirestore.instance.collection(collectionPath),
    );

    return geoRef
        .subscribeWithin(
          center: geoPoint,
          radiusInKm: radiusKm,
          field: field,
          geopointFrom: (data) {
            if (data[field] is Map) {
              final geoData = data[field] as Map<String, dynamic>;
              final geopoint = geoData['geopoint'];
              if (geopoint is GeoPoint) return geopoint;
            } else if (data[field] is GeoPoint) {
              return data[field] as GeoPoint;
            }
            // Fallback: try to construct from lat/lng fields
            final lat = data['latitude'];
            final lng = data['longitude'];
            if (lat is double && lng is double) {
              return GeoPoint(lat, lng);
            }
            // Return a default GeoPoint as fallback (required by API)
            return const GeoPoint(0, 0);
          },
          queryBuilder: queryBuilder,
        )
        .map((snapshots) => snapshots.where((doc) {
          // Filter out documents with invalid coordinates
          final data = doc.data();
          if (data == null) return false;
          if (data[field] is Map) {
            final geoData = data[field] as Map<String, dynamic>;
            final geopoint = geoData['geopoint'];
            if (geopoint is GeoPoint) {
              return geopoint.latitude != 0 || geopoint.longitude != 0;
            }
          }
          return true;
        }).toList());
  }

  /// Add geohash data to a document
  /// 
  /// Example:
  /// ```dart
  /// final data = {
  ///   'name': 'Pothole on Main St',
  ///   'description': 'Large pothole',
  ///   ...GeohashService.instance.geoData(
  ///     latitude: 55.6761,
  ///     longitude: 12.5683,
  ///   ),
  /// };
  /// ```
  Map<String, dynamic> geoData({
    required double latitude,
    required double longitude,
    String field = 'geo',
  }) {
    final geoPoint = point(latitude: latitude, longitude: longitude);
    return {
      field: {
        'geopoint': geoPoint.geopoint,
        'geohash': geoPoint.geohash,
      },
      // Also store separate lat/lng for compatibility
      'latitude': latitude,
      'longitude': longitude,
      'geohash': geoPoint.geohash,
    };
  }

  /// Extract LatLng from geo field in document
  LatLng? latLngFromGeoData(Map<String, dynamic> data, {String field = 'geo'}) {
    try {
      if (data[field] is Map) {
        final geoData = data[field] as Map<String, dynamic>;
        final geopoint = geoData['geopoint'] as GeoPoint;
        return LatLng(geopoint.latitude, geopoint.longitude);
      }
      // Fallback to separate lat/lng fields
      final lat = data['latitude'] as double?;
      final lng = data['longitude'] as double?;
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update existing document with geohash data
  /// Useful for migrating existing documents
  Future<void> addGeohashToDocument({
    required String collectionPath,
    required String documentId,
    required double latitude,
    required double longitude,
    String field = 'geo',
  }) async {
    final data = geoData(
      latitude: latitude,
      longitude: longitude,
      field: field,
    );

    await FirebaseFirestore.instance
        .collection(collectionPath)
        .doc(documentId)
        .update(data);
  }

  /// Batch update documents with geohash
  /// Useful for migrating existing data
  Future<void> batchAddGeohash({
    required String collectionPath,
    String latField = 'lat',
    String lngField = 'lng',
    String geoField = 'geo',
  }) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(collectionPath)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    int count = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final lat = data[latField] as double?;
      final lng = data[lngField] as double?;

      if (lat != null && lng != null) {
        final geoData = this.geoData(
          latitude: lat,
          longitude: lng,
          field: geoField,
        );

        batch.update(doc.reference, geoData);
        count++;

        // Firestore batch limit is 500
        if (count >= 500) {
          await batch.commit();
          count = 0;
        }
      }
    }

    if (count > 0) {
      await batch.commit();
    }
  }
}
