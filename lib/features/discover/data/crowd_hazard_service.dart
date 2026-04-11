/// CYKEL — Crowd Hazard Service
/// Submit, confirm, dismiss, and stream nearby crowd-reported hazards.
/// Reports older than [kCrowdHazardTtlHours] are ignored client-side.
/// Duplicate detection prevents spam within a 50-metre / 30-minute window.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../auth/providers/auth_providers.dart';
import '../domain/crowd_hazard.dart';

// ── Submit result ─────────────────────────────────────────────────────────────

/// Returned by [CrowdHazardService.submit] to give the caller precise feedback.
sealed class HazardSubmitResult {
  const HazardSubmitResult();
}

/// A new report was created successfully.
class HazardSubmitted extends HazardSubmitResult {
  const HazardSubmitted(this.reportId);
  final String reportId;
}

/// A near-identical report already exists — the existing one was upvoted.
class HazardDuplicate extends HazardSubmitResult {
  const HazardDuplicate(this.existingId);
  final String existingId;
}

/// GPS accuracy was too poor to trust the location (> 50 m).
class HazardAccuracyTooLow extends HazardSubmitResult {
  const HazardAccuracyTooLow(this.accuracyMeters);
  final double accuracyMeters;
}

/// An unexpected error occurred.
class HazardSubmitError extends HazardSubmitResult {
  const HazardSubmitError(this.message);
  final String message;
}

// ─── Service ──────────────────────────────────────────────────────────────────

// Firestore collection name.
const _kCollection = 'hazard_reports';

// Bounding-box radius in degrees (~5 km) used for the nearby query.
const _kQueryBoxDeg = 0.05;

// Duplicate-detection radius (metres).
const _kDuplicateRadiusM = 50.0;

// Duplicate-detection time window.
const _kDuplicateWindow = Duration(minutes: 30);

// GPS accuracy gate — reject submissions with accuracy > this value.
const _kMaxAccuracyM = 50.0;

// Auto-confirm threshold: promote to `confirmed` when confirmCount reaches this.
const _kAutoConfirmThreshold = 2;

// Auto-resolve threshold: resolve when dismissCount exceeds confirms by this.
const _kAutoDismissThreshold = 3;

class CrowdHazardService {
  CrowdHazardService(this._db, this._userId);

  final FirebaseFirestore _db;
  final String            _userId;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(_kCollection);

  // ── Submit ─────────────────────────────────────────────────────────────────

  /// Creates a new hazard report at [position].
  ///
  /// [locationAccuracy] is the GPS accuracy in metres from the device.
  /// Reports with accuracy > 50 m are rejected to prevent noise.
  /// Duplicate detection checks for the same [type] within 50 m in the last
  /// 30 minutes — if found, the existing report is upvoted instead.
  Future<HazardSubmitResult> submit({
    required CrowdHazardType type,
    required LatLng          position,
    HazardSeverity           severity = HazardSeverity.caution,
    double?                  locationAccuracy,
  }) async {
    try {
      // Accuracy gate
      if (locationAccuracy != null && locationAccuracy > _kMaxAccuracyM) {
        return HazardAccuracyTooLow(locationAccuracy);
      }

      // Duplicate detection — query box then distance-filter in Dart
      final cutoff = DateTime.now().subtract(_kDuplicateWindow);
      final minLat = position.latitude  - 0.0005; // ~50 m box
      final maxLat = position.latitude  + 0.0005;

      final recent = await _col
          .where('type', isEqualTo: type.name)
          .where('lat', isGreaterThanOrEqualTo: minLat)
          .where('lat', isLessThanOrEqualTo: maxLat)
          .where('reportedAt', isGreaterThan: Timestamp.fromDate(cutoff))
          .limit(10)
          .get();

      for (final doc in recent.docs) {
        final r = CrowdHazardReport.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>);
        final dist = Geolocator.distanceBetween(
          position.latitude, position.longitude,
          r.lat, r.lng,
        );
        if (dist <= _kDuplicateRadiusM && r.lng >= position.longitude - 0.0005
            && r.lng <= position.longitude + 0.0005) {
          // Near-duplicate — upvote the existing report instead
          await _col.doc(r.id).update({
            'upvotes':   FieldValue.increment(1),
            'upvotedBy': FieldValue.arrayUnion([_userId]),
          });
          return HazardDuplicate(r.id);
        }
      }

      // Create new report
      final now = DateTime.now();
      final doc = await _col.add(CrowdHazardReport(
        id:         '',
        type:       type,
        lat:        position.latitude,
        lng:        position.longitude,
        reportedBy: _userId,
        reportedAt: now,
        severity:   severity,
      ).toFirestore());
      return HazardSubmitted(doc.id);
    } catch (e) {
      debugPrint('CrowdHazardService.submit error: $e');
      return HazardSubmitError(e.toString());
    }
  }

  // ── Nearby stream ──────────────────────────────────────────────────────────

  Stream<List<CrowdHazardReport>> streamNearby(LatLng center) {
    final minLat = center.latitude  - _kQueryBoxDeg;
    final maxLat = center.latitude  + _kQueryBoxDeg;
    final minLng = center.longitude - _kQueryBoxDeg;
    final maxLng = center.longitude + _kQueryBoxDeg;

    return _col
        .where('lat', isGreaterThanOrEqualTo: minLat)
        .where('lat', isLessThanOrEqualTo: maxLat)
        .snapshots()
        .map((snap) {
      final reports = snap.docs
          .map((d) => CrowdHazardReport.fromFirestore(
                d as DocumentSnapshot<Map<String, dynamic>>))
          .where((r) =>
              r.lng >= minLng &&
              r.lng <= maxLng &&
              !r.isExpired &&
              r.status != ReportStatus.resolved)
          .toList();
      reports.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
      return reports;
    });
  }

  // ── Upvote ─────────────────────────────────────────────────────────────────

  Future<void> upvote(String reportId) async {
    try {
      await _col.doc(reportId).update({
        'upvotes':    FieldValue.increment(1),
        'upvotedBy':  FieldValue.arrayUnion([_userId]),
      });
    } catch (e) {
      debugPrint('CrowdHazardService.upvote error: $e');
    }
  }

  // ── Confirm ────────────────────────────────────────────────────────────────

  /// Confirms a hazard as still present.
  /// Automatically promotes status to [ReportStatus.confirmed] when
  /// [_kAutoConfirmThreshold] confirmations are reached.
  Future<void> confirmHazard(String reportId) async {
    try {
      final ref = _col.doc(reportId);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return;
        final data = snap.data()!;
        final newCount = ((data['confirmCount'] as num?)?.toInt() ?? 0) + 1;
        final dismisses = (data['dismissCount'] as num?)?.toInt() ?? 0;
        final currentStatus = ReportStatusX.fromString(data['status'] as String?);

        String? newStatus;
        if (currentStatus == ReportStatus.reported &&
            newCount >= _kAutoConfirmThreshold) {
          newStatus = ReportStatus.confirmed.name;
        }
        // Auto-resolve if dismissed significantly more than confirmed
        if (dismisses - newCount >= _kAutoDismissThreshold) {
          newStatus = ReportStatus.resolved.name;
        }

        tx.update(ref, {
          'confirmCount': newCount,
          'confirmedBy':  FieldValue.arrayUnion([_userId]),
          if (newStatus != null) 'status': newStatus,
        });
      });
    } catch (e) {
      debugPrint('CrowdHazardService.confirmHazard error: $e');
    }
  }

  // ── Dismiss ────────────────────────────────────────────────────────────────

  /// Marks a hazard as no longer present.
  /// Automatically resolves the report when dismissals significantly outweigh
  /// confirmations ([_kAutoDismissThreshold]).
  Future<void> dismissHazard(String reportId) async {
    try {
      final ref = _col.doc(reportId);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return;
        final data = snap.data()!;
        final newDismiss = ((data['dismissCount'] as num?)?.toInt() ?? 0) + 1;
        final confirms = (data['confirmCount'] as num?)?.toInt() ?? 0;

        String? newStatus;
        if (newDismiss - confirms >= _kAutoDismissThreshold) {
          newStatus = ReportStatus.resolved.name;
        }

        tx.update(ref, {
          'dismissCount': newDismiss,
          'dismissedBy':  FieldValue.arrayUnion([_userId]),
          if (newStatus != null) 'status': newStatus,
        });
      });
    } catch (e) {
      debugPrint('CrowdHazardService.dismissHazard error: $e');
    }
  }

  // ── Status update (admin / municipal) ─────────────────────────────────────

  /// Updates the status of a report. Intended for municipal admin use.
  Future<void> updateStatus(String reportId, ReportStatus status) async {
    try {
      await _col.doc(reportId).update({'status': status.name});
    } catch (e) {
      debugPrint('CrowdHazardService.updateStatus error: $e');
    }
  }

  // ── Delete own report ──────────────────────────────────────────────────────

  Future<void> delete(String reportId) async {
    try {
      await _col.doc(reportId).delete();
    } catch (e) {
      debugPrint('CrowdHazardService.delete error: $e');
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final crowdHazardServiceProvider = Provider<CrowdHazardService>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid ?? 'anonymous';
  return CrowdHazardService(FirebaseFirestore.instance, uid);
});
