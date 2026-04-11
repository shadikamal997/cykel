/// CYKEL — Bikes Riverpod provider
/// Manages the user's bike garage: Firestore users/{uid}/bikes subcollection.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../domain/bike.dart';

// ─── Stream provider ──────────────────────────────────────────────────────────

final bikesProvider = StreamProvider<List<Bike>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('bikes')
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((s) => s.docs.map(Bike.fromFirestore).toList());
});

// ─── Service ──────────────────────────────────────────────────────────────────

class BikesService {
  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('bikes');

  Future<void> addBike(String uid, Bike bike) async {
    try {
      await _col(uid).add(bike.toMap());
    } catch (e) {
      throw Exception('Failed to add bike: $e');
    }
  }

  Future<void> deleteBike(String uid, String bikeId) async {
    try {
      await _col(uid).doc(bikeId).delete();
    } catch (e) {
      throw Exception('Failed to delete bike: $e');
    }
  }

  Future<void> updateBikeKm(String uid, String bikeId, double totalKm) async {
    try {
      await _col(uid).doc(bikeId).update({'totalKm': totalKm});
    } catch (e) {
      throw Exception('Failed to update bike km: $e');
    }
  }
}

final bikesServiceProvider = Provider<BikesService>((_) => BikesService());
