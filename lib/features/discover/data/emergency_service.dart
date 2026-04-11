/// CYKEL — Emergency / Safety Service (Phase 6)
///
/// Handles accident reports stored in Firestore and emergency actions.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../auth/providers/auth_providers.dart';

const _kEmergencyCollection = 'emergency_reports';

class EmergencyService {
  EmergencyService(this._db, this._userId);

  final FirebaseFirestore _db;
  final String _userId;

  /// Submit an accident / incident report.
  Future<String?> reportAccident({
    required LatLng position,
    required String description,
  }) async {
    try {
      final doc = await _db.collection(_kEmergencyCollection).add({
        'reportedBy':  _userId,
        'reportedAt':  Timestamp.fromDate(DateTime.now()),
        'lat':         position.latitude,
        'lng':         position.longitude,
        'description': description,
        'type':        'accident',
      });
      return doc.id;
    } catch (e) {
      debugPrint('EmergencyService.reportAccident error: $e');
      return null;
    }
  }
}

final emergencyServiceProvider = Provider<EmergencyService>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid ?? 'anonymous';
  return EmergencyService(FirebaseFirestore.instance, uid);
});
