/// CYKEL — Ride Sync Service
/// Syncs rides to Cloud Firestore under users/{uid}/rides/{rideId}.
/// Upload: called after a ride is saved locally.
/// Download: called to restore rides on a new device (if local list is empty).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/activity/domain/ride.dart';
import '../features/activity/data/ride_repository.dart';

class RideSyncService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final RideRepository _local;

  RideSyncService({
    required FirebaseFirestore db,
    required FirebaseAuth auth,
    required RideRepository local,
  })  : _db = db,
        _auth = auth,
        _local = local;

  /// Returns the Firestore sub-collection reference for the current user.
  CollectionReference<Map<String, dynamic>>? get _ridesCol {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('rides');
  }

  /// Uploads a single [ride] to Firestore (upsert by ride ID).
  /// Silently swallows errors so a failed sync never blocks the user.
  Future<void> uploadRide(Ride ride) async {
    final col = _ridesCol;
    if (col == null) return;
    try {
      await col.doc(ride.id).set(ride.toJson());
    } catch (e) {
      debugPrint('RideSyncService.uploadRide error: $e');
    }
  }

  /// Downloads all rides from Firestore and merges them into local storage.
  /// Existing local rides are preserved; cloud-only rides are added.
  Future<int> downloadRides() async {
    final col = _ridesCol;
    if (col == null) return 0;
    try {
      final snapshot = await col
          .orderBy('startTime', descending: true)
          .limit(200)
          .get();
      int added = 0;
      final localRides = await _local.getRides();
      final localIds = localRides.map((r) => r.id).toSet();
      for (final doc in snapshot.docs) {
        final ride = Ride.fromJson(doc.data());
        if (!localIds.contains(ride.id)) {
          await _local.saveRide(ride);
          added++;
        }
      }
      return added;
    } catch (e) {
      debugPrint('RideSyncService.downloadRides error: $e');
      return 0;
    }
  }

  /// Deletes a ride from Firestore (should be called when deleted locally).
  Future<void> deleteRide(String rideId) async {
    final col = _ridesCol;
    if (col == null) return;
    try {
      await col.doc(rideId).delete();
    } catch (e) {
      debugPrint('RideSyncService.deleteRide error: $e');
    }
  }
}

final rideSyncServiceProvider = Provider<RideSyncService>((ref) {
  return RideSyncService(
    db: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    local: ref.read(rideRepositoryProvider),
  );
});
