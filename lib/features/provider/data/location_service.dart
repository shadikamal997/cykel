/// CYKEL — Location Service
/// CRUD operations for the `locations` collection plus image upload.

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/provider_enums.dart';
import '../domain/provider_location.dart';

class LocationService {
  LocationService(this._db, this._storage);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.colLocations);

  // ── Create ──────────────────────────────────────────────────────────────────

  Future<String> createLocation(ProviderLocation location) async {
    try {
      final doc = await _col.add(location.toMap());
      return doc.id;
    } catch (e) {
      throw Exception('Failed to create location: $e');
    }
  }

  // ── Read ────────────────────────────────────────────────────────────────────

  Future<ProviderLocation?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return ProviderLocation.fromFirestore(doc);
  }

  Stream<ProviderLocation?> streamLocation(String id) =>
      _col.doc(id).snapshots().map(
            (doc) =>
                doc.exists ? ProviderLocation.fromFirestore(doc) : null,
          );

  /// Stream all locations belonging to a specific provider.
  Stream<List<ProviderLocation>> streamProviderLocations(
          String providerId) =>
      _col
          .where('providerId', isEqualTo: providerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map(ProviderLocation.fromFirestore).toList());

  /// Stream all active locations (for public map).
  Stream<List<ProviderLocation>> streamAllActive() => _col
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ProviderLocation.fromFirestore).toList());

  /// Stream active locations filtered by provider type.
  Stream<List<ProviderLocation>> streamByType(ProviderType type) => _col
      .where('providerType', isEqualTo: type.key)
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ProviderLocation.fromFirestore).toList());

  // ── Update ──────────────────────────────────────────────────────────────────

  Future<void> updateLocation(ProviderLocation location) async {
    try {
      await _col.doc(location.id).update(location.toMap());
    } catch (e) {
      throw Exception('Failed to update location: $e');
    }
  }

  Future<void> setActive(String id, {required bool active}) async {
    await _col.doc(id).update({'isActive': active});
  }

  Future<void> setTemporarilyClosed(String id,
      {required bool closed}) async {
    await _col.doc(id).update({'temporarilyClosed': closed});
  }

  // ── Delete ──────────────────────────────────────────────────────────────────

  Future<void> deleteLocation(ProviderLocation location) async {
    try {
      // Delete stored images
      for (final url in location.photoUrls) {
        try {
          await _storage.refFromURL(url).delete();
        } catch (_) {}
      }
      await _col.doc(location.id).delete();
    } catch (e) {
      throw Exception('Failed to delete location: $e');
    }
  }

  // ── Image Upload ────────────────────────────────────────────────────────────

  Future<String> uploadLocationImage(
      String providerId, XFile file) async {
    final ref = _storage
        .ref()
        .child('locations/$providerId/'
            '${DateTime.now().millisecondsSinceEpoch}_${file.name}');
    await ref.putFile(
      File(file.path),
      SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
      ),
    );
    return ref.getDownloadURL();
  }

  Future<List<String>> uploadLocationImages(
      String providerId, List<XFile> files) async {
    final futures = files.map((f) => uploadLocationImage(providerId, f));
    return Future.wait(futures);
  }
}

// ─── Riverpod Provider ────────────────────────────────────────────────────────

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
  );
});
