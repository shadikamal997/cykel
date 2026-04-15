/// CYKEL — Bike Rental Service
/// Manages bike listings, rental requests, and agreements

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;

import '../domain/bike_listing.dart';
import '../domain/rental_agreement.dart';

class BikeRentalService {
  BikeRentalService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get _currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _listingsCollection =>
      _firestore.collection('bikeListings');
  
  CollectionReference<Map<String, dynamic>> get _requestsCollection =>
      _firestore.collection('rentalRequests');
  
  CollectionReference<Map<String, dynamic>> get _agreementsCollection =>
      _firestore.collection('rentalAgreements');
  
  CollectionReference<Map<String, dynamic>> get _reviewsCollection =>
      _firestore.collection('bikeReviews');

  // ─── Bike Listings ──────────────────────────────────────────────────────────

  /// Create a new bike listing
  Future<BikeListing> createListing({
    required String title,
    required String description,
    required BikeType bikeType,
    required BikeSize size,
    required BikeCondition condition,
    required BikePricing pricing,
    required BikeFeatures features,
    required LatLng location,
    required String locationName,
    List<String> photoUrls = const [],
    String? brand,
    String? model,
    int? year,
    String? color,
    DateTime? availableFrom,
    DateTime? availableTo,
    int minimumRentalHours = 1,
    int? maximumRentalDays,
    String? pickupInstructions,
    String? rules,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User must be logged in to create a listing');
    }

    final listing = BikeListing(
      id: '', // Will be set by Firestore
      ownerId: _currentUserId!,
      title: title,
      description: description,
      bikeType: bikeType,
      size: size,
      condition: condition,
      pricing: pricing,
      features: features,
      location: location,
      locationName: locationName,
      photoUrls: photoUrls,
      status: ListingStatus.active,
      createdAt: DateTime.now(),
      brand: brand,
      model: model,
      year: year,
      color: color,
      availableFrom: availableFrom,
      availableTo: availableTo,
      minimumRentalHours: minimumRentalHours,
      maximumRentalDays: maximumRentalDays,
      pickupInstructions: pickupInstructions,
      rules: rules,
    );

    final docRef = await _listingsCollection.add(listing.toFirestore());
    return BikeListing.fromFirestore(await docRef.get());
  }

  /// Update a bike listing
  Future<void> updateListing(BikeListing listing) async {
    await _listingsCollection.doc(listing.id).update(listing.toFirestore());
  }

  /// Update listing status
  Future<void> updateListingStatus(String listingId, ListingStatus status) async {
    await _listingsCollection.doc(listingId).update({'status': status.name});
  }

  /// Delete a bike listing
  Future<void> deleteListing(String listingId) async {
    await _listingsCollection.doc(listingId).delete();
  }

  /// Get a bike listing by ID
  Future<BikeListing?> getListing(String listingId) async {
    final doc = await _listingsCollection.doc(listingId).get();
    if (!doc.exists) return null;
    return BikeListing.fromFirestore(doc);
  }

  /// Get all listings for current user
  Stream<List<BikeListing>> getMyListings() {
    if (_currentUserId == null) return Stream.value([]);

    return _listingsCollection
        .where('ownerId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BikeListing.fromFirestore(doc)).toList());
  }

  /// Search for available bike listings
  Stream<List<BikeListing>> searchListings({
    LatLng? location,
    double? radiusKm,
    BikeType? bikeType,
    BikeSize? size,
    double? maxHourlyRate,
    double? maxDailyRate,
    bool? hasHelmet,
    bool? hasLock,
    DateTime? availableFrom,
    DateTime? availableTo,
  }) {
    Query<Map<String, dynamic>> query = _listingsCollection
        .where('status', isEqualTo: ListingStatus.active.name);

    // Filter by bike type
    if (bikeType != null) {
      query = query.where('bikeType', isEqualTo: bikeType.name);
    }

    // Filter by size
    if (size != null) {
      query = query.where('size', isEqualTo: size.name);
    }

    // Note: Location-based filtering requires custom implementation
    // Firestore doesn't support geoqueries natively
    // For production, use GeoFlutterFire or similar

    return query
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      var listings = snapshot.docs
          .map((doc) => BikeListing.fromFirestore(doc))
          .toList();

      // Client-side filtering for complex queries
      if (location != null && radiusKm != null) {
        listings = listings.where((listing) {
          final distance = _calculateDistance(location, listing.location);
          return distance <= radiusKm;
        }).toList();
      }

      if (maxHourlyRate != null) {
        listings = listings
            .where((l) => l.pricing.hourlyRate <= maxHourlyRate)
            .toList();
      }

      if (maxDailyRate != null) {
        listings = listings
            .where((l) => l.pricing.dailyRate <= maxDailyRate)
            .toList();
      }

      if (hasHelmet != null && hasHelmet) {
        listings = listings.where((l) => l.features.hasHelmet).toList();
      }

      if (hasLock != null && hasLock) {
        listings = listings.where((l) => l.features.hasLock).toList();
      }

      if (availableFrom != null && availableTo != null) {
        listings = listings.where((l) {
          return l.isAvailableForPeriod(
            startDate: availableFrom,
            endDate: availableTo,
          );
        }).toList();
      }

      // Sort by distance if location provided
      if (location != null) {
        listings.sort((a, b) {
          final distA = _calculateDistance(location, a.location);
          final distB = _calculateDistance(location, b.location);
          return distA.compareTo(distB);
        });
      }

      return listings;
    });
  }

  /// Get nearby bike listings
  Stream<List<BikeListing>> getNearbyListings({
    required LatLng location,
    double radiusKm = 10.0,
    int limit = 20,
  }) {
    return searchListings(location: location, radiusKm: radiusKm);
  }

  // ─── Rental Requests ────────────────────────────────────────────────────────

  /// Create a rental request
  Future<RentalRequest> createRentalRequest({
    required String listingId,
    required DateTime startTime,
    required DateTime endTime,
    String? message,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User must be logged in to create a rental request');
    }

    // Get the listing
    final listing = await getListing(listingId);
    if (listing == null) {
      throw Exception('Listing not found');
    }

    // Check availability
    if (!listing.isAvailableForPeriod(startDate: startTime, endDate: endTime)) {
      throw Exception('Bike is not available for the selected dates');
    }

    // Calculate cost
    final totalCost = listing.pricing.calculateCost(
      startTime: startTime,
      endTime: endTime,
    );

    final request = RentalRequest(
      id: '', // Will be set by Firestore
      listingId: listingId,
      renterId: _currentUserId!,
      ownerId: listing.ownerId,
      startTime: startTime,
      endTime: endTime,
      totalCost: totalCost,
      depositAmount: listing.pricing.depositAmount,
      status: RentalRequestStatus.pending,
      createdAt: DateTime.now(),
      message: message,
      expiresAt: DateTime.now().add(const Duration(hours: 24)), // 24h to respond
    );

    final docRef = await _requestsCollection.add(request.toFirestore());
    return RentalRequest.fromFirestore(await docRef.get());
  }

  /// Approve a rental request (owner only)
  Future<RentalAgreement> approveRentalRequest(String requestId) async {
    if (_currentUserId == null) {
      throw Exception('User must be logged in');
    }

    final requestDoc = await _requestsCollection.doc(requestId).get();
    if (!requestDoc.exists) {
      throw Exception('Request not found');
    }

    final request = RentalRequest.fromFirestore(requestDoc);

    // Verify current user is the owner
    if (request.ownerId != _currentUserId) {
      throw Exception('Only the owner can approve requests');
    }

    // Update request status
    await _requestsCollection.doc(requestId).update({
      'status': RentalRequestStatus.approved.name,
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });

    // Create rental agreement
    final agreement = RentalAgreement(
      id: '', // Will be set by Firestore
      requestId: requestId,
      listingId: request.listingId,
      renterId: request.renterId,
      ownerId: request.ownerId,
      startTime: request.startTime,
      endTime: request.endTime,
      rentalCost: request.totalCost,
      depositAmount: request.depositAmount,
      totalAmount: request.totalCost + request.depositAmount,
      status: RentalAgreementStatus.upcoming,
      paymentStatus: PaymentStatus.pending,
      createdAt: DateTime.now(),
    );

    final docRef = await _agreementsCollection.add(agreement.toFirestore());
    
    // Update listing status to rented
    await updateListingStatus(request.listingId, ListingStatus.rented);

    return RentalAgreement.fromFirestore(await docRef.get());
  }

  /// Decline a rental request (owner only)
  Future<void> declineRentalRequest(String requestId, String reason) async {
    if (_currentUserId == null) {
      throw Exception('User must be logged in');
    }

    final requestDoc = await _requestsCollection.doc(requestId).get();
    if (!requestDoc.exists) {
      throw Exception('Request not found');
    }

    final request = RentalRequest.fromFirestore(requestDoc);

    // Verify current user is the owner
    if (request.ownerId != _currentUserId) {
      throw Exception('Only the owner can decline requests');
    }

    await _requestsCollection.doc(requestId).update({
      'status': RentalRequestStatus.declined.name,
      'declineReason': reason,
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Cancel a rental request (renter only)
  Future<void> cancelRentalRequest(String requestId) async {
    if (_currentUserId == null) {
      throw Exception('User must be logged in');
    }

    final requestDoc = await _requestsCollection.doc(requestId).get();
    if (!requestDoc.exists) {
      throw Exception('Request not found');
    }

    final request = RentalRequest.fromFirestore(requestDoc);

    // Verify current user is the renter
    if (request.renterId != _currentUserId) {
      throw Exception('Only the renter can cancel requests');
    }

    await _requestsCollection.doc(requestId).update({
      'status': RentalRequestStatus.cancelled.name,
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Get all rental requests for a listing (owner view)
  Stream<List<RentalRequest>> getListingRequests(String listingId) {
    return _requestsCollection
        .where('listingId', isEqualTo: listingId)
        .where('status', isEqualTo: RentalRequestStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RentalRequest.fromFirestore(doc)).toList());
  }

  /// Get rental requests sent by current user
  Stream<List<RentalRequest>> getMyRentalRequests() {
    if (_currentUserId == null) return Stream.value([]);

    return _requestsCollection
        .where('renterId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RentalRequest.fromFirestore(doc)).toList());
  }

  /// Get rental requests received by current user (as owner)
  Stream<List<RentalRequest>> getReceivedRequests() {
    if (_currentUserId == null) return Stream.value([]);

    return _requestsCollection
        .where('ownerId', isEqualTo: _currentUserId)
        .where('status', isEqualTo: RentalRequestStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RentalRequest.fromFirestore(doc)).toList());
  }

  // ─── Rental Agreements ──────────────────────────────────────────────────────

  /// Get a rental agreement by ID
  Future<RentalAgreement?> getAgreement(String agreementId) async {
    final doc = await _agreementsCollection.doc(agreementId).get();
    if (!doc.exists) return null;
    return RentalAgreement.fromFirestore(doc);
  }

  /// Get all rental agreements for current user (as renter)
  Stream<List<RentalAgreement>> getMyRentals() {
    if (_currentUserId == null) return Stream.value([]);

    return _agreementsCollection
        .where('renterId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RentalAgreement.fromFirestore(doc)).toList());
  }

  /// Get all rental agreements for current user (as owner)
  Stream<List<RentalAgreement>> getMyBikeRentals() {
    if (_currentUserId == null) return Stream.value([]);

    return _agreementsCollection
        .where('ownerId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RentalAgreement.fromFirestore(doc)).toList());
  }

  /// Mark bike as picked up
  Future<void> markPickedUp({
    required String agreementId,
    List<String> photoUrls = const [],
    String? notes,
  }) async {
    await _agreementsCollection.doc(agreementId).update({
      'pickupTime': Timestamp.fromDate(DateTime.now()),
      'pickupPhotos': photoUrls,
      'pickupNotes': notes,
      'status': RentalAgreementStatus.active.name,
    });
  }

  /// Mark bike as returned
  Future<void> markReturned({
    required String agreementId,
    List<String> photoUrls = const [],
    String? notes,
    bool damageReported = false,
    String? damageDescription,
    List<String> damagePhotos = const [],
  }) async {
    final updates = {
      'returnTime': Timestamp.fromDate(DateTime.now()),
      'returnPhotos': photoUrls,
      'returnNotes': notes,
      'status': RentalAgreementStatus.completed.name,
      'damageReported': damageReported,
    };

    if (damageReported) {
      updates['damageDescription'] = damageDescription;
      updates['damagePhotos'] = damagePhotos;
    }

    await _agreementsCollection.doc(agreementId).update(updates);

    // Update listing status back to active
    final agreement = await getAgreement(agreementId);
    if (agreement != null) {
      await updateListingStatus(agreement.listingId, ListingStatus.active);
    }
  }

  /// Release deposit
  Future<void> releaseDeposit({
    required String agreementId,
    required double amount,
  }) async {
    await _agreementsCollection.doc(agreementId).update({
      'depositReturned': true,
      'depositReturnedAt': Timestamp.fromDate(DateTime.now()),
      'depositReturnAmount': amount,
    });
  }

  // ─── Reviews ────────────────────────────────────────────────────────────────

  /// Create a review
  Future<BikeReview> createReview({
    required String agreementId,
    required String listingId,
    required String revieweeId,
    required ReviewType type,
    required int rating,
    String? comment,
    int? cleanliness,
    int? condition,
    int? communication,
    int? reliability,
    int? respectfulness,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User must be logged in to create a review');
    }

    final review = BikeReview(
      id: '', // Will be set by Firestore
      agreementId: agreementId,
      listingId: listingId,
      reviewerId: _currentUserId!,
      revieweeId: revieweeId,
      type: type,
      rating: rating,
      createdAt: DateTime.now(),
      comment: comment,
      cleanliness: cleanliness,
      condition: condition,
      communication: communication,
      reliability: reliability,
      respectfulness: respectfulness,
    );

    final docRef = await _reviewsCollection.add(review.toFirestore());
    
    // Update listing average rating if reviewing the bike
    if (type == ReviewType.bike) {
      await _updateListingRating(listingId);
    }

    return BikeReview.fromFirestore(await docRef.get());
  }

  /// Update listing average rating
  Future<void> _updateListingRating(String listingId) async {
    final reviews = await _reviewsCollection
        .where('listingId', isEqualTo: listingId)
        .where('type', isEqualTo: ReviewType.bike.name)
        .get();

    if (reviews.docs.isEmpty) return;

    final ratings = reviews.docs.map((doc) {
      final data = doc.data();
      return (data['rating'] as num).toDouble();
    }).toList();

    final averageRating = ratings.reduce((a, b) => a + b) / ratings.length;

    await _listingsCollection.doc(listingId).update({
      'averageRating': averageRating,
      'totalReviews': reviews.docs.length,
    });
  }

  /// Get reviews for a listing
  Stream<List<BikeReview>> getListingReviews(String listingId) {
    return _reviewsCollection
        .where('listingId', isEqualTo: listingId)
        .where('type', isEqualTo: ReviewType.bike.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BikeReview.fromFirestore(doc)).toList());
  }

  /// Get reviews for a user
  Stream<List<BikeReview>> getUserReviews(String userId) {
    return _reviewsCollection
        .where('revieweeId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BikeReview.fromFirestore(doc)).toList());
  }

  // ─── Utilities ──────────────────────────────────────────────────────────────

  /// Calculate distance between two points (Haversine formula)
  double _calculateDistance(LatLng point1, LatLng point2) {
    const earthRadiusKm = 6371.0;

    final lat1Rad = point1.latitude * (math.pi / 180);
    final lat2Rad = point2.latitude * (math.pi / 180);
    final deltaLat = (point2.latitude - point1.latitude) * (math.pi / 180);
    final deltaLng = (point2.longitude - point1.longitude) * (math.pi / 180);

    final a = math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.pow(math.sin(deltaLng / 2), 2);
    final c = 2 * math.asin(math.sqrt(a));

    return earthRadiusKm * c;
  }
}
