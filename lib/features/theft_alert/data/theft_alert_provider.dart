/// CYKEL — Theft Alert Provider
/// Manages theft reports, sightings, and alert notifications

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../auth/providers/auth_providers.dart';
import '../domain/theft_alert.dart';

// ─── Theft Alert Service ──────────────────────────────────────────────────────

class TheftAlertService {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reportsCol =>
      _firestore.collection('theft_reports');

  CollectionReference<Map<String, dynamic>> _sightingsCol(String reportId) =>
      _reportsCol.doc(reportId).collection('sightings');

  DocumentReference<Map<String, dynamic>> _settingsDoc(String uid) =>
      _firestore.collection('users').doc(uid).collection('settings').doc('theft_alerts');

  // ─── Reports ────────────────────────────────────────────────────────────────

  /// Get all active theft reports
  Stream<List<TheftReport>> watchActiveReports() {
    return _reportsCol
        .where('status', isEqualTo: TheftReportStatus.active.name)
        .orderBy('reportedAt', descending: true)
        .limit(20)  // Reduced for faster initial load
        .snapshots()
        .map((s) => s.docs.map(TheftReport.fromFirestore).toList());
  }

  /// Get theft reports near a location
  Stream<List<TheftReport>> watchNearbyReports(LatLng center, double radiusKm) {
    // Firestore doesn't support geospatial queries natively
    // We fetch active reports and filter client-side
    // For production, consider using Firebase GeoFire or a GeoHash approach
    return _reportsCol
        .where('status', isEqualTo: TheftReportStatus.active.name)
        .orderBy('reportedAt', descending: true)
        .limit(20) // Reduced for faster initial load
        .snapshots()
        .map((snapshot) {
      final reports = snapshot.docs.map(TheftReport.fromFirestore).toList();
      return reports.where((report) {
        final distance = _calculateDistance(
          center.latitude,
          center.longitude,
          report.location.latitude,
          report.location.longitude,
        );
        return distance <= radiusKm;
      }).toList();
    });
  }

  /// Get user's own theft reports
  Stream<List<TheftReport>> watchUserReports(String uid) {
    return _reportsCol
        .where('userId', isEqualTo: uid)
        .orderBy('reportedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(TheftReport.fromFirestore).toList());
  }

  /// Report a stolen bike
  Future<String> reportTheft({
    required String uid,
    required String bikeId,
    required String bikeName,
    required String bikeDescription,
    required LatLng location,
    String? bikePhotoUrl,
    String? additionalNotes,
    String? contactInfo,
    DateTime? lastSeenAt,
    String? frameNumber,
    String? cityArea,
  }) async {
    try {
      final docRef = await _reportsCol.add({
        'userId': uid,
        'bikeId': bikeId,
        'bikeName': bikeName,
        'bikeDescription': bikeDescription,
        'location': GeoPoint(location.latitude, location.longitude),
        'reportedAt': FieldValue.serverTimestamp(),
        'status': TheftReportStatus.active.name,
        'bikePhotoUrl': bikePhotoUrl,
        'additionalNotes': additionalNotes,
        'contactInfo': contactInfo,
        'lastSeenAt': lastSeenAt != null ? Timestamp.fromDate(lastSeenAt) : null,
        'frameNumber': frameNumber,
        'cityArea': cityArea,
      });
      return docRef.id;
    } catch (e) {
      debugPrint('[TheftAlert] Error reporting theft: $e');
      rethrow;
    }
  }

  /// Update report status
  Future<void> updateReportStatus(String reportId, TheftReportStatus status) async {
    try {
      final updates = <String, dynamic>{'status': status.name};
      if (status == TheftReportStatus.recovered) {
        updates['recoveredAt'] = FieldValue.serverTimestamp();
      }
      await _reportsCol.doc(reportId).update(updates);
    } catch (e) {
      debugPrint('[TheftAlert] Error updating status: $e');
      rethrow;
    }
  }

  // ─── Sightings ──────────────────────────────────────────────────────────────

  /// Get sightings for a report
  Stream<List<TheftSighting>> watchSightings(String reportId) {
    return _sightingsCol(reportId)
        .orderBy('reportedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(TheftSighting.fromFirestore).toList());
  }

  /// Report a sighting
  Future<void> reportSighting({
    required String reportId,
    required String reporterId,
    required LatLng location,
    String? notes,
    String? photoUrl,
  }) async {
    try {
      await _sightingsCol(reportId).add({
        'reportId': reportId,
        'reporterId': reporterId,
        'location': GeoPoint(location.latitude, location.longitude),
        'reportedAt': FieldValue.serverTimestamp(),
        'notes': notes,
        'photoUrl': photoUrl,
      });

      // Update report with sighting count
      await _reportsCol.doc(reportId).update({
        'sightingCount': FieldValue.increment(1),
        'lastSightingAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[TheftAlert] Error reporting sighting: $e');
      rethrow;
    }
  }

  // ─── Settings ───────────────────────────────────────────────────────────────

  /// Get user's alert settings
  Stream<TheftAlertSettings> watchSettings(String uid) {
    return _settingsDoc(uid).snapshots().map((doc) {
      return TheftAlertSettings.fromJson(doc.data());
    });
  }

  /// Update alert settings
  Future<void> updateSettings(String uid, TheftAlertSettings settings) async {
    try {
      await _settingsDoc(uid).set(settings.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[TheftAlert] Error updating settings: $e');
      rethrow;
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  /// Calculate distance between two points in km (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;
}

// ─── Providers ────────────────────────────────────────────────────────────────

/// Theft alert service provider
final theftAlertServiceProvider = Provider<TheftAlertService>((ref) {
  return TheftAlertService();
});

/// All active theft reports
final activeTheftReportsProvider = StreamProvider<List<TheftReport>>((ref) {
  return ref.watch(theftAlertServiceProvider).watchActiveReports();
});

/// Nearby theft reports (requires location)
final nearbyTheftReportsProvider = StreamProvider.family<List<TheftReport>, ({LatLng center, double radiusKm})>((ref, params) {
  return ref.watch(theftAlertServiceProvider).watchNearbyReports(
    params.center, 
    params.radiusKm,
  );
});

/// User's own theft reports
final userTheftReportsProvider = StreamProvider<List<TheftReport>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(theftAlertServiceProvider).watchUserReports(user.uid);
});

/// Sightings for a specific report
final theftSightingsProvider = StreamProvider.family<List<TheftSighting>, String>((ref, reportId) {
  return ref.watch(theftAlertServiceProvider).watchSightings(reportId);
});

/// User's theft alert settings
final theftAlertSettingsProvider = StreamProvider<TheftAlertSettings>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const TheftAlertSettings());
  return ref.watch(theftAlertServiceProvider).watchSettings(user.uid);
});
