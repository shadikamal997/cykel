/// CYKEL — User Data Export Service
/// GDPR-compliant data export functionality

import 'dart:convert';
import 'dart:ui' show Rect;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

class DataExportService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DataExportService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Export all user data to JSON and share via system share sheet
  Future<void> exportUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final Map<String, dynamic> exportData = {
      'export_date': DateTime.now().toIso8601String(),
      'user_id': user.uid,
      'format_version': '1.0',
      'data': {},
    };

    try {
      // Export user profile
      final userProfile = await _exportUserProfile(user.uid);
      if (userProfile != null) {
        exportData['data']['profile'] = userProfile;
      }

      // Export created events
      final events = await _exportEvents(user.uid);
      if (events.isNotEmpty) {
        exportData['data']['events'] = events;
      }

      // Export joined events
      final joinedEvents = await _exportJoinedEvents(user.uid);
      if (joinedEvents.isNotEmpty) {
        exportData['data']['joined_events'] = joinedEvents;
      }

      // Export marketplace listings
      final listings = await _exportListings(user.uid);
      if (listings.isNotEmpty) {
        exportData['data']['marketplace_listings'] = listings;
      }

      // Export rides/activities
      final rides = await _exportRides(user.uid);
      if (rides.isNotEmpty) {
        exportData['data']['rides'] = rides;
      }

      // Export provider profile (if exists)
      final providerProfile = await _exportProviderProfile(user.uid);
      if (providerProfile != null) {
        exportData['data']['provider_profile'] = providerProfile;
      }

      // Export favorites
      final favorites = await _exportFavorites(user.uid);
      if (favorites.isNotEmpty) {
        exportData['data']['favorites'] = favorites;
      }

      // Convert to pretty JSON
      const encoder = JsonEncoder.withIndent('  ');
      final prettyJson = encoder.convert(exportData);

      // Create temporary file for sharing
      final xFile = XFile.fromData(
        utf8.encode(prettyJson),
        mimeType: 'application/json',
        name: 'cykel_data_export_${DateTime.now().millisecondsSinceEpoch}.json',
      );

      // Share using SharePlus recommended API
      await Share.shareXFiles(
        [xFile],
        subject: 'CYKEL Data Export',
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 10, 10),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Convert Firestore data to JSON-serializable format
  dynamic _sanitizeData(dynamic data) {
    if (data == null) return null;
    
    if (data is Timestamp) {
      return data.toDate().toIso8601String();
    }
    
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), _sanitizeData(value)));
    }
    
    if (data is List) {
      return data.map(_sanitizeData).toList();
    }
    
    // Handle GeoPoint if present
    if (data.runtimeType.toString() == 'GeoPoint') {
      final geoPoint = data as dynamic;
      return {
        'latitude': geoPoint.latitude,
        'longitude': geoPoint.longitude,
      };
    }
    
    return data;
  }

  Future<Map<String, dynamic>?> _exportUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      // Remove sensitive fields
      data.remove('fcmToken');
      data.remove('deviceTokens');

      return _sanitizeData(data) as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _exportEvents(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('creatorId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => _sanitizeData({'id': doc.id, ...doc.data()}) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _exportJoinedEvents(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('participants', arrayContains: userId)
          .get();

      return snapshot.docs
          .map((doc) => _sanitizeData({'id': doc.id, ...doc.data()}) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _exportListings(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('marketplace')
          .where('sellerId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => _sanitizeData({'id': doc.id, ...doc.data()}) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _exportRides(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('rides')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => _sanitizeData({'id': doc.id, ...doc.data()}) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> _exportProviderProfile(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('providers')
          .where('providerId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return _sanitizeData({'id': doc.id, ...doc.data()}) as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _exportFavorites(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc('events')
          .get();

      if (!doc.exists) return {};

      final data = doc.data();
      return _sanitizeData(data) as Map<String, dynamic>? ?? {};
    } catch (e) {
      return {};
    }
  }
}
