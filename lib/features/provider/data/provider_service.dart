/// CYKEL — Provider Firestore + Storage Service
/// CRUD operations for the `providers` collection plus analytics
/// and image upload utilities.

import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/input_validator.dart';
import '../domain/provider_analytics.dart';
import '../domain/provider_enums.dart';
import '../domain/provider_model.dart';

class ProviderService {
  ProviderService(this._db, this._storage);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.colProviders);

  CollectionReference<Map<String, dynamic>> get _analyticCol =>
      _db.collection('provider_analytics');

  // ── Create ──────────────────────────────────────────────────────────────────

  /// Creates a new provider document and returns the generated ID.
  /// Analytics document is created server-side by Cloud Function.
  Future<String> createProvider(CykelProvider provider) async {
    try {
      // Validate all text inputs
      InputValidator.validateBusinessName(provider.businessName).getOrThrow();
      InputValidator.validateDisplayName(provider.contactName).getOrThrow();
      InputValidator.validatePhoneNumber(provider.phone).getOrThrow();
      InputValidator.validateEmail(provider.email).getOrThrow();
      
      if (provider.website != null && provider.website!.isNotEmpty) {
        InputValidator.validateUrl(provider.website!).getOrThrow();
      }
      
      // Sanitize description to prevent XSS
      final sanitizedProvider = provider.copyWith(
        shopDescription: provider.shopDescription != null
            ? InputValidator.sanitize(provider.shopDescription!)
            : null,
      );
      
      final doc = await _col.add(sanitizedProvider.toMap());
      // Analytics document created by Cloud Function (onProviderSubmit)
      // This avoids race conditions with security rules
      return doc.id;
    } catch (e) {
      throw Exception('Failed to create provider: $e');
    }
  }

  // ── Read ────────────────────────────────────────────────────────────────────

  /// Fetches a single provider by document ID.
  Future<CykelProvider?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return CykelProvider.fromFirestore(doc);
  }

  /// Real-time stream for a single provider.
  Stream<CykelProvider?> streamProvider(String id) =>
      _col.doc(id).snapshots().map(
        (doc) => doc.exists ? CykelProvider.fromFirestore(doc) : null,
      );

  /// Stream all providers owned by a specific user.
  Stream<List<CykelProvider>> streamMyProviders(String uid) => _col
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(CykelProvider.fromFirestore).toList());

  /// Stream approved providers filtered by type.
  Stream<List<CykelProvider>> streamProvidersByType(ProviderType type) => _col
      .where('providerType', isEqualTo: type.key)
      .where('verificationStatus', isEqualTo: VerificationStatus.approved.key)
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(CykelProvider.fromFirestore).toList());

  /// Stream all approved & active providers.
  Stream<List<CykelProvider>> streamAllApproved() => _col
      .where('verificationStatus', isEqualTo: VerificationStatus.approved.key)
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(CykelProvider.fromFirestore).toList());

  /// Fetch approved providers near [lat],[lng] within [radiusKm].
  ///
  /// Uses a bounding-box approximation followed by a Haversine client-side
  /// filter. This avoids needing GeoHash libraries while providing good
  /// accuracy for urban distances (< 50 km).
  Future<List<CykelProvider>> getNearby({
    required double lat,
    required double lng,
    double radiusKm = 10,
  }) async {
    // Approximate bounding box (~111 km per degree latitude).
    final latDelta = radiusKm / 111.0;
    final lngDelta = radiusKm / (111.0 * cos(lat * pi / 180));

    final snap = await _col
        .where('verificationStatus',
            isEqualTo: VerificationStatus.approved.key)
        .where('isActive', isEqualTo: true)
        .where('latitude', isGreaterThanOrEqualTo: lat - latDelta)
        .where('latitude', isLessThanOrEqualTo: lat + latDelta)
        .get();

    final candidates = snap.docs.map(CykelProvider.fromFirestore).toList();

    // Client-side Haversine filter on longitude + exact radius.
    return candidates.where((p) {
      if (p.longitude < lng - lngDelta || p.longitude > lng + lngDelta) {
        return false;
      }
      return _haversineKm(lat, lng, p.latitude, p.longitude) <= radiusKm;
    }).toList();
  }

  /// Stream approved providers near [lat],[lng] within [radiusKm].
  ///
  /// Real-time stream that updates when providers are added, modified, or removed.
  /// Uses the same bounding-box + Haversine filtering as [getNearby].
  Stream<List<CykelProvider>> streamNearby({
    required double lat,
    required double lng,
    double radiusKm = 10,
  }) {
    // Approximate bounding box (~111 km per degree latitude).
    final latDelta = radiusKm / 111.0;
    final lngDelta = radiusKm / (111.0 * cos(lat * pi / 180));

    return _col
        .where('verificationStatus',
            isEqualTo: VerificationStatus.approved.key)
        .where('isActive', isEqualTo: true)
        .where('latitude', isGreaterThanOrEqualTo: lat - latDelta)
        .where('latitude', isLessThanOrEqualTo: lat + latDelta)
        .snapshots()
        .map((snap) {
      final candidates = snap.docs.map(CykelProvider.fromFirestore).toList();

      // Client-side Haversine filter on longitude + exact radius.
      return candidates.where((p) {
        if (p.longitude < lng - lngDelta || p.longitude > lng + lngDelta) {
          return false;
        }
        return _haversineKm(lat, lng, p.latitude, p.longitude) <= radiusKm;
      }).toList();
    });
  }

  // ── Update ──────────────────────────────────────────────────────────────────

  Future<void> updateProvider(CykelProvider provider) async {
    try {
      await _col.doc(provider.id).update(provider.toMap());
    } catch (e) {
      throw Exception('Failed to update provider: $e');
    }
  }

  /// Toggle the `isActive` flag on a provider.
  Future<void> setActive(String id, {required bool active}) async {
    await _col.doc(id).update({'isActive': active});
  }

  /// Toggle the `temporarilyClosed` flag.
  Future<void> setTemporarilyClosed(String id, {required bool closed}) async {
    await _col.doc(id).update({'temporarilyClosed': closed});
  }

  /// Update the special notice text.
  Future<void> setSpecialNotice(String id, String? notice) async {
    await _col.doc(id).update({'specialNotice': notice});
  }

  // ── Delete ──────────────────────────────────────────────────────────────────

  /// Deletes the provider document, its analytics, and all stored images.
  Future<void> deleteProvider(CykelProvider provider) async {
    try {
      // Delete stored images.
      final urls = [
        if (provider.logoUrl != null) provider.logoUrl!,
        if (provider.coverPhotoUrl != null) provider.coverPhotoUrl!,
        ...provider.galleryUrls,
      ];
      for (final url in urls) {
        try {
          await _storage.refFromURL(url).delete();
        } catch (_) {}
      }
      await _analyticCol.doc(provider.id).delete();
      await _col.doc(provider.id).delete();
    } catch (e) {
      throw Exception('Failed to delete provider: $e');
    }
  }

  // ── Analytics ───────────────────────────────────────────────────────────────

  /// Fetches analytics for a provider.
  Future<ProviderAnalytics> getAnalytics(String providerId) async {
    final doc = await _analyticCol.doc(providerId).get();
    if (!doc.exists) return ProviderAnalytics(providerId: providerId, userId: '');
    return ProviderAnalytics.fromFirestore(doc);
  }

  /// Stream analytics for a provider.
  Stream<ProviderAnalytics> streamAnalytics(String providerId) =>
      _analyticCol.doc(providerId).snapshots().map(
            (doc) => doc.exists
                ? ProviderAnalytics.fromFirestore(doc)
                : ProviderAnalytics(providerId: providerId, userId: ''),
          );

  /// Increment a single analytics counter.
  Future<void> incrementProfileView(String providerId) async {
    try {
      await _analyticCol.doc(providerId).update({
        'profileViews': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Non-critical — silently ignore.
    }
  }

  Future<void> incrementNavigationRequest(String providerId) async {
    try {
      await _analyticCol.doc(providerId).update({
        'navigationRequests': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> incrementSavedByUsers(String providerId) async {
    try {
      await _analyticCol.doc(providerId).update({
        'savedByUsersCount': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> decrementSavedByUsers(String providerId) async {
    try {
      await _analyticCol.doc(providerId).update({
        'savedByUsersCount': FieldValue.increment(-1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ── Image Upload ────────────────────────────────────────────────────────────

  /// Uploads provider images in parallel and returns download URLs.
  Future<List<String>> uploadImages(String userId, List<XFile> files) async {
    final futures = files.map((file) async {
      final ref = _storage
          .ref()
          .child('${AppConstants.storageProviders}/$userId/photos/'
              '${DateTime.now().millisecondsSinceEpoch}_${file.name}');
      await ref.putFile(
        File(file.path),
        SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'public, max-age=31536000',
        ),
      );
      return ref.getDownloadURL();
    });
    return Future.wait(futures);
  }

  /// Upload a single image (e.g. logo) and return the download URL.
  Future<String> uploadSingleImage(String userId, XFile file) async {
    final ref = _storage
        .ref()
        .child('${AppConstants.storageProviders}/$userId/photos/'
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

  /// Upload a verification document (image or PDF) and return the download URL.
  Future<String> uploadDocument(String userId, XFile file) async {
    final ext = file.name.split('.').last.toLowerCase();
    final contentType = ext == 'pdf' ? 'application/pdf' : 'image/jpeg';
    final ref = _storage
        .ref()
        .child('${AppConstants.storageProviders}/$userId/documents/'
            '${DateTime.now().millisecondsSinceEpoch}_${file.name}');
    await ref.putFile(
      File(file.path),
      SettableMetadata(
        contentType: contentType,
        cacheControl: 'public, max-age=31536000',
      ),
    );
    return ref.getDownloadURL();
  }

  // ── Saved Providers ─────────────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _db.collection(AppConstants.colUsers).doc(uid);

  /// Stream the list of provider IDs saved by a user.
  Stream<List<String>> streamSavedProviderIds(String uid) => _userRef(uid)
      .snapshots()
      .map((doc) =>
          List<String>.from(doc.data()?['savedProviders'] as List? ?? []));

  /// Save a provider as favourite.
  Future<void> saveProvider(String uid, String providerId) async {
    await Future.wait([
      _userRef(uid).update({
        'savedProviders': FieldValue.arrayUnion([providerId]),
      }),
      incrementSavedByUsers(providerId),
    ]);
  }

  /// Remove a provider from favourites.
  Future<void> unsaveProvider(String uid, String providerId) async {
    await Future.wait([
      _userRef(uid).update({
        'savedProviders': FieldValue.arrayRemove([providerId]),
      }),
      decrementSavedByUsers(providerId),
    ]);
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  /// Haversine formula — returns distance in kilometres.
  static double _haversineKm(
      double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (pi / 180);
}

// ─── Riverpod Provider ────────────────────────────────────────────────────────

final providerServiceProvider = Provider<ProviderService>((ref) {
  return ProviderService(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
  );
});
