/// CYKEL — Marketplace Firestore + Storage service

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../domain/marketplace_listing.dart';
import '../../../core/utils/input_validator.dart';

class MarketplaceService {
  MarketplaceService(this._db, this._storage);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('marketplace_listings');

  // ── Read ───────────────────────────────────────────────────────────────────

  Stream<List<MarketplaceListing>> streamListings({
    ListingCategory? category,
    String sortBy = 'createdAt', // 'createdAt' | 'price_asc' | 'price_desc'
    bool prioritizePremium = false,
  }) {
    // Filter isSold in Firestore so we never read sold listings over the wire.
    // Requires a composite index on (isSold, createdAt) — create it in the
    // Firebase console or via firebase.indexes.json if not already present.
    var query = _col
        .where('isSold', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(20);  // Reduced to 20 for faster initial load

    return query.snapshots().map((snap) {
      var list =
          snap.docs.map(MarketplaceListing.fromFirestore).toList();
      if (category != null) {
        list = list.where((l) => l.category == category).toList();
      }
      if (sortBy == 'price_asc') {
        list.sort((a, b) => a.price.compareTo(b.price));
      } else if (sortBy == 'price_desc') {
        list.sort((a, b) => b.price.compareTo(a.price));
      }

      // Prioritize premium listings for premium users
      if (prioritizePremium) {
        list.sort((a, b) {
          // Priority listings first
          if (a.isPriority && !b.isPriority) return -1;
          if (!a.isPriority && b.isPriority) return 1;
          // Then apply normal sorting
          if (sortBy == 'price_asc') return a.price.compareTo(b.price);
          if (sortBy == 'price_desc') return b.price.compareTo(a.price);
          // Default: newer first
          return b.createdAt.compareTo(a.createdAt);
        });
      }

      return list;
    });
  }

  Stream<List<MarketplaceListing>> streamMyListings(String uid) => _col
      .where('sellerId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(50)  // Limit to 50 most recent listings for performance
      .snapshots()
      .map((s) => s.docs.map(MarketplaceListing.fromFirestore).toList());

  /// Get count of active listings for a user (excludes sold listings).
  Future<int> getMyListingCount(String uid) async {
    final snap = await _col
        .where('sellerId', isEqualTo: uid)
        .where('isSold', isEqualTo: false)
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<MarketplaceListing?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return MarketplaceListing.fromFirestore(doc);
  }

  // ── Write ──────────────────────────────────────────────────────────────────

  Future<String> createListing(MarketplaceListing listing) async {
    try {
      // Validate inputs
      final titleValidation = InputValidator.validateListingTitle(listing.title);
      if (!titleValidation.isValid) {
        throw ValidationException(titleValidation.errorMessage!);
      }
      
      final descValidation = InputValidator.validateListingDescription(listing.description);
      if (!descValidation.isValid) {
        throw ValidationException(descValidation.errorMessage!);
      }
      
      final priceValidation = InputValidator.validatePrice(listing.price);
      if (!priceValidation.isValid) {
        throw ValidationException(priceValidation.errorMessage!);
      }
      
      // Create with sanitized data
      final sanitizedListing = listing.copyWith(
        title: titleValidation.getOrThrow(),
        description: descValidation.getOrThrow(),
        price: priceValidation.getOrThrow(),
      );
      
      final doc = await _col.add(sanitizedListing.toMap());
      return doc.id;
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw Exception('Failed to create listing: $e');
    }
  }

  Future<void> updateListing(MarketplaceListing listing) async {
    try {
      // Validate inputs
      final titleValidation = InputValidator.validateListingTitle(listing.title);
      if (!titleValidation.isValid) {
        throw ValidationException(titleValidation.errorMessage!);
      }
      
      final descValidation = InputValidator.validateListingDescription(listing.description);
      if (!descValidation.isValid) {
        throw ValidationException(descValidation.errorMessage!);
      }
      
      final priceValidation = InputValidator.validatePrice(listing.price);
      if (!priceValidation.isValid) {
        throw ValidationException(priceValidation.errorMessage!);
      }
      
      // Update with sanitized data
      final sanitizedListing = listing.copyWith(
        title: titleValidation.getOrThrow(),
        description: descValidation.getOrThrow(),
        price: priceValidation.getOrThrow(),
      );
      
      await _col.doc(listing.id).update(sanitizedListing.toMap());
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw Exception('Failed to update listing: $e');
    }
  }

  Future<void> deleteListing(String id, List<String> imageUrls) async {
    try {
      // Delete document first - this is the critical operation
      // If image deletion fails after, the listing is still properly removed
      await _col.doc(id).delete();
      
      // Then clean up storage (best-effort, silent failures)
      for (final url in imageUrls) {
        try {
          await _storage.refFromURL(url).delete();
        } catch (_) {
          // Storage cleanup is non-critical
        }
      }
    } catch (e) {
      throw Exception('Failed to delete listing: $e');
    }
  }

  Future<void> markSold(String id) async {
    try {
      await _col.doc(id).update({'isSold': true});
    } catch (e) {
      throw Exception('Failed to mark as sold: $e');
    }
  }

  Future<void> incrementView(String id) async {
    try {
      await _col.doc(id).update({'viewCount': FieldValue.increment(1)});
    } catch (_) {
      // Silently fail — non-critical
    }
  }

  /// Report a listing for violating community guidelines
  Future<void> reportListing({
    required String listingId,
    required String reporterId,
    required String reason,
  }) async {
    try {
      await _db.collection('reports').add({
        'type': 'listing',
        'targetId': listingId,
        'reason': reason,
        'reportedBy': reporterId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }

  // ── Image upload ───────────────────────────────────────────────────────────

  /// Uploads [files] to Firebase Storage concurrently (all in parallel).
  ///
  /// Sequential uploads were the primary cause of slow publish times.
  /// With parallel uploads, total time ≈ slowest single image instead of sum.
  /// Images are compressed before upload to reduce storage costs and upload time.
  ///
  /// Cloud Function automatically generates thumbnails in thumbnails/ folder.
  Future<List<String>> uploadImages(String uid, List<XFile> files) async {
    // Fire all uploads simultaneously.
    final futures = files.map((file) async {
      // Compress image before upload (max 1920px width, 85% quality)
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        file.path,
        minWidth: 1920,
        minHeight: 1920,
        quality: 85,
      );
      
      if (compressedBytes == null) {
        throw Exception('Image compression failed for ${file.name}');
      }
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final ref = _storage
          .ref()
          .child('marketplace/$uid/$fileName');
      await ref.putData(
        compressedBytes,
        SettableMetadata(
          // Hint the CDN that these are images so it serves them efficiently.
          contentType: 'image/jpeg',
          cacheControl: 'public, max-age=31536000',
        ),
      );
      return ref.getDownloadURL();
    });
    return Future.wait(futures);
  }

  // ── Saved listings ─────────────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _db.collection('users').doc(uid);

  Stream<List<String>> streamSavedIds(String uid) => _userRef(uid)
      .snapshots()
      .map((doc) =>
          List<String>.from(doc.data()?['savedListings'] as List? ?? []));

  Future<void> saveListing(String uid, String listingId) async {
    try {
      await Future.wait([
        _userRef(uid).update({
          'savedListings': FieldValue.arrayUnion([listingId])
        }),
        _col.doc(listingId).update({'saveCount': FieldValue.increment(1)}),
      ]);
    } catch (e) {
      throw Exception('Failed to save listing: $e');
    }
  }

  Future<void> unsaveListing(String uid, String listingId) async {
    try {
      await Future.wait([
        _userRef(uid).update({
          'savedListings': FieldValue.arrayRemove([listingId])
        }),
        _col.doc(listingId).update({'saveCount': FieldValue.increment(-1)}),
      ]);
    } catch (e) {
      throw Exception('Failed to unsave listing: $e');
    }
  }

  Stream<List<MarketplaceListing>> streamSavedListings(String uid) {
    return streamSavedIds(uid).asyncMap((ids) {
      if (ids.isEmpty) return Future.value(<MarketplaceListing>[]);
      return _fetchByIds(ids);
    });
  }

  Future<List<MarketplaceListing>> _fetchByIds(List<String> ids) async {
    // Split into chunks of 10 (Firestore whereIn limit) and fetch in parallel.
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      chunks.add(ids.sublist(i, (i + 10) < ids.length ? i + 10 : ids.length));
    }
    final snapshots = await Future.wait(
      chunks.map((chunk) =>
          _col.where(FieldPath.documentId, whereIn: chunk).get()),
    );
    return snapshots
        .expand((snap) => snap.docs.map(MarketplaceListing.fromFirestore))
        .toList();
  }

  /// Update only the image URLs on a listing (used for background image uploads).
  Future<void> updateListingImages(String listingId, List<String> imageUrls) async {
    await _col.doc(listingId).update({'imageUrls': imageUrls});
  }
}

final marketplaceServiceProvider = Provider<MarketplaceService>(
    (ref) => MarketplaceService(
        FirebaseFirestore.instance, FirebaseStorage.instance));
