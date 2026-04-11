/// CYKEL — Infrastructure Feedback Service (Phase 4)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../auth/providers/auth_providers.dart';
import '../domain/infrastructure_report.dart';

const _kCollection = 'infrastructure_reports';

class InfrastructureService {
  InfrastructureService(this._db, this._userId);

  final FirebaseFirestore _db;
  final String _userId;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(_kCollection);

  /// Submit a new infrastructure feedback report.
  Future<String?> submit({
    required InfrastructureIssueType type,
    required LatLng position,
    String description = '',
  }) async {
    try {
      final doc = await _col.add(
        InfrastructureReport(
          id:          '',
          type:        type,
          lat:         position.latitude,
          lng:         position.longitude,
          reportedBy:  _userId,
          reportedAt:  DateTime.now(),
          description: description,
        ).toFirestore(),
      );
      return doc.id;
    } catch (e) {
      debugPrint('InfrastructureService.submit error: $e');
      return null;
    }
  }

  /// Fetches the most recent infrastructure reports near [center] (~5 km).
  Future<List<InfrastructureReport>> fetchNearby(LatLng center) async {
    const boxDeg = 0.05;
    try {
      final snap = await _col
          .where('lat', isGreaterThanOrEqualTo: center.latitude - boxDeg)
          .where('lat', isLessThanOrEqualTo: center.latitude + boxDeg)
          .orderBy('lat')
          .orderBy('reportedAt', descending: true)
          .limit(50)
          .get();
      return snap.docs
          .map((d) => InfrastructureReport.fromFirestore(
                d as DocumentSnapshot<Map<String, dynamic>>))
          .where((r) =>
              r.lng >= center.longitude - boxDeg &&
              r.lng <= center.longitude + boxDeg)
          .toList();
    } catch (e) {
      debugPrint('InfrastructureService.fetchNearby error: $e');
      return [];
    }
  }
}

final infrastructureServiceProvider = Provider<InfrastructureService>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid ?? 'anonymous';
  return InfrastructureService(FirebaseFirestore.instance, uid);
});
