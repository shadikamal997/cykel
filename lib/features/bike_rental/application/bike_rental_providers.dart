/// CYKEL — Bike Rental Providers
/// Riverpod state management for bike rentals

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../domain/bike_listing.dart';
import '../domain/rental_agreement.dart';
import 'bike_rental_service.dart';

// ─── Service Provider ───────────────────────────────────────────────────────

final bikeRentalServiceProvider = Provider<BikeRentalService>((ref) {
  return BikeRentalService(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    storage: FirebaseStorage.instance,
  );
});

// ─── Bike Listing Providers ─────────────────────────────────────────────────

/// Get a specific bike listing
final bikeListingProvider =
    FutureProvider.autoDispose.family<BikeListing?, String>((ref, listingId) async {
  final service = ref.watch(bikeRentalServiceProvider);
  return await service.getListing(listingId);
});

/// Get all listings owned by current user
final myBikeListingsProvider = StreamProvider.autoDispose<List<BikeListing>>((ref) {
  final service = ref.watch(bikeRentalServiceProvider);
  return service.getMyListings();
});

/// Search parameters provider
final searchParametersProvider = StateProvider<SearchParameters>((ref) {
  return const SearchParameters();
});

class SearchParameters {
  const SearchParameters({
    this.location,
    this.radiusKm,
    this.bikeType,
    this.size,
    this.maxHourlyRate,
    this.maxDailyRate,
    this.hasHelmet,
    this.hasLock,
    this.availableFrom,
    this.availableTo,
  });

  final LatLng? location;
  final double? radiusKm;
  final BikeType? bikeType;
  final BikeSize? size;
  final double? maxHourlyRate;
  final double? maxDailyRate;
  final bool? hasHelmet;
  final bool? hasLock;
  final DateTime? availableFrom;
  final DateTime? availableTo;

  SearchParameters copyWith({
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
    return SearchParameters(
      location: location ?? this.location,
      radiusKm: radiusKm ?? this.radiusKm,
      bikeType: bikeType ?? this.bikeType,
      size: size ?? this.size,
      maxHourlyRate: maxHourlyRate ?? this.maxHourlyRate,
      maxDailyRate: maxDailyRate ?? this.maxDailyRate,
      hasHelmet: hasHelmet ?? this.hasHelmet,
      hasLock: hasLock ?? this.hasLock,
      availableFrom: availableFrom ?? this.availableFrom,
      availableTo: availableTo ?? this.availableTo,
    );
  }
}

/// Search for available bike listings with filters
final searchBikeListingsProvider = Provider<Stream<List<BikeListing>>>((ref) {
  final service = ref.watch(bikeRentalServiceProvider);
  final params = ref.watch(searchParametersProvider);
  
  return service.searchListings(
    location: params.location,
    radiusKm: params.radiusKm,
    bikeType: params.bikeType,
    size: params.size,
    maxHourlyRate: params.maxHourlyRate,
    maxDailyRate: params.maxDailyRate,
    hasHelmet: params.hasHelmet,
    hasLock: params.hasLock,
    availableFrom: params.availableFrom,
    availableTo: params.availableTo,
  );
});

/// Get nearby bike listings
final nearbyBikeListingsProvider = Provider.family<Stream<List<BikeListing>>, NearbyParams>(
  (ref, params) {
    final service = ref.watch(bikeRentalServiceProvider);
    return service.getNearbyListings(
      location: params.location,
      radiusKm: params.radiusKm,
      limit: params.limit,
    );
  },
);

class NearbyParams {
  const NearbyParams({
    required this.location,
    this.radiusKm = 10.0,
    this.limit = 20,
  });

  final LatLng location;
  final double radiusKm;
  final int limit;
}

/// Statistics for user's listings
final myListingStatsProvider = Provider.autoDispose<AsyncValue<BikeListingStats>>((ref) {
  return ref.watch(myBikeListingsProvider).whenData((list) {
    if (list.isEmpty) {
      return const BikeListingStats(
        totalListings: 0,
        activeListings: 0,
        rentedListings: 0,
        totalRevenue: 0,
        averageRating: 0,
        totalRentals: 0,
      );
    }

    final totalListings = list.length;
    final activeListings = list.where((l) => l.status == ListingStatus.active).length;
    final rentedListings = list.where((l) => l.status == ListingStatus.rented).length;
    final totalRentals = list.fold<int>(0, (acc, l) => acc + l.totalRentals);
    
    // Calculate average rating
    final ratingsSum = list.fold<double>(0, (acc, l) {
      if (l.totalReviews > 0) {
        return acc + (l.averageRating * l.totalReviews);
      }
      return acc;
    });
    final totalReviews = list.fold<int>(0, (acc, l) => acc + l.totalReviews);
    final averageRating = totalReviews > 0 ? ratingsSum / totalReviews : 0;

    return BikeListingStats(
      totalListings: totalListings,
      activeListings: activeListings,
      rentedListings: rentedListings,
      totalRevenue: 0, // Would be calculated from completed rentals
      averageRating: averageRating.toDouble(),
      totalRentals: totalRentals,
    );
  });
});

class BikeListingStats {
  const BikeListingStats({
    required this.totalListings,
    required this.activeListings,
    required this.rentedListings,
    required this.totalRevenue,
    required this.averageRating,
    required this.totalRentals,
  });

  final int totalListings;
  final int activeListings;
  final int rentedListings;
  final double totalRevenue;
  final double averageRating;
  final int totalRentals;
}

// ─── Rental Request Providers ───────────────────────────────────────────────

/// Get all rental requests sent by current user
final myRentalRequestsProvider = StreamProvider.autoDispose<List<RentalRequest>>((ref) {
  final service = ref.watch(bikeRentalServiceProvider);
  return service.getMyRentalRequests();
});

/// Get rental requests received by current user (as owner)
final receivedRentalRequestsProvider = StreamProvider.autoDispose<List<RentalRequest>>((ref) {
  final service = ref.watch(bikeRentalServiceProvider);
  return service.getReceivedRequests();
});

/// Get rental requests for a specific listing
final listingRequestsProvider =
    StreamProvider.autoDispose.family<List<RentalRequest>, String>((ref, listingId) {
  final service = ref.watch(bikeRentalServiceProvider);
  return service.getListingRequests(listingId);
});

/// Pending requests count (for badge)
final pendingRequestsCountProvider = Provider.autoDispose<AsyncValue<int>>((ref) {
  return ref.watch(receivedRentalRequestsProvider).whenData((list) =>
      list.where((r) => r.status == RentalRequestStatus.pending).length);
});

// ─── Rental Agreement Providers ─────────────────────────────────────────────

/// Get a specific rental agreement
final rentalAgreementProvider =
    FutureProvider.autoDispose.family<RentalAgreement?, String>((ref, agreementId) async {
  final service = ref.watch(bikeRentalServiceProvider);
  return await service.getAgreement(agreementId);
});

/// Get all rentals where current user is the renter
final myRentalsProvider = StreamProvider.autoDispose<List<RentalAgreement>>((ref) {
  final service = ref.watch(bikeRentalServiceProvider);
  return service.getMyRentals();
});

/// Get all rentals where current user is the owner
final myBikeRentalsProvider = StreamProvider.autoDispose<List<RentalAgreement>>((ref) {
  final service = ref.watch(bikeRentalServiceProvider);
  return service.getMyBikeRentals();
});

/// Get active rentals (as renter)
final activeRentalsProvider = Provider.autoDispose<AsyncValue<List<RentalAgreement>>>((ref) {
  return ref.watch(myRentalsProvider).whenData((list) => list
      .where((r) =>
          r.status == RentalAgreementStatus.active ||
          r.status == RentalAgreementStatus.upcoming)
      .toList());
});

/// Get active bike rentals (as owner)
final activeBikeRentalsProvider = Provider.autoDispose<AsyncValue<List<RentalAgreement>>>((ref) {
  return ref.watch(myBikeRentalsProvider).whenData((list) => list
      .where((r) =>
          r.status == RentalAgreementStatus.active ||
          r.status == RentalAgreementStatus.upcoming)
      .toList());
});

/// Get upcoming rentals (as renter)
final upcomingRentalsProvider = Provider.autoDispose<AsyncValue<List<RentalAgreement>>>((ref) {
  return ref.watch(myRentalsProvider).whenData((list) => list
      .where((r) => r.status == RentalAgreementStatus.upcoming)
      .toList());
});

/// Get rental history (completed rentals as renter)
final rentalHistoryProvider = Provider.autoDispose<AsyncValue<List<RentalAgreement>>>((ref) {
  return ref.watch(myRentalsProvider).whenData((list) => list
      .where((r) => r.status == RentalAgreementStatus.completed)
      .toList());
});

/// Get bike rental history (completed rentals as owner)
final bikeRentalHistoryProvider = Provider.autoDispose<AsyncValue<List<RentalAgreement>>>((ref) {
  return ref.watch(myBikeRentalsProvider).whenData((list) => list
      .where((r) => r.status == RentalAgreementStatus.completed)
      .toList());
});

/// Rental statistics for current user (as renter)
final myRentalStatsProvider = Provider.autoDispose<AsyncValue<RentalStats>>((ref) {
  return ref.watch(myRentalsProvider).whenData((list) {
    if (list.isEmpty) {
      return const RentalStats(
        totalRentals: 0,
        activeRentals: 0,
        completedRentals: 0,
        totalSpent: 0,
        averageRating: 0,
      );
    }

    final totalRentals = list.length;
    final activeRentals = list
        .where((r) =>
            r.status == RentalAgreementStatus.active ||
            r.status == RentalAgreementStatus.upcoming)
        .length;
    final completedRentals =
        list.where((r) => r.status == RentalAgreementStatus.completed).length;
    
    final totalSpent = list
        .where((r) => r.status == RentalAgreementStatus.completed)
        .fold<double>(0, (acc, r) => acc + r.rentalCost);

    return RentalStats(
      totalRentals: totalRentals,
      activeRentals: activeRentals,
      completedRentals: completedRentals,
      totalSpent: totalSpent,
      averageRating: 0, // Would be calculated from reviews
    );
  });
});

/// Rental statistics for current user (as owner)
final myBikeRentalStatsProvider = Provider.autoDispose<AsyncValue<RentalStats>>((ref) {
  return ref.watch(myBikeRentalsProvider).whenData((list) {
    if (list.isEmpty) {
      return const RentalStats(
        totalRentals: 0,
        activeRentals: 0,
        completedRentals: 0,
        totalSpent: 0,
        averageRating: 0,
      );
    }

    final totalRentals = list.length;
    final activeRentals = list
        .where((r) =>
            r.status == RentalAgreementStatus.active ||
            r.status == RentalAgreementStatus.upcoming)
        .length;
    final completedRentals =
        list.where((r) => r.status == RentalAgreementStatus.completed).length;
    
    final totalEarned = list
        .where((r) => r.status == RentalAgreementStatus.completed)
        .fold<double>(0, (acc, r) => acc + r.rentalCost);

    return RentalStats(
      totalRentals: totalRentals,
      activeRentals: activeRentals,
      completedRentals: completedRentals,
      totalSpent: totalEarned, // Reusing field for earnings
      averageRating: 0, // Would be calculated from reviews
    );
  });
});

class RentalStats {
  const RentalStats({
    required this.totalRentals,
    required this.activeRentals,
    required this.completedRentals,
    required this.totalSpent,
    required this.averageRating,
  });

  final int totalRentals;
  final int activeRentals;
  final int completedRentals;
  final double totalSpent; // or totalEarned for owners
  final double averageRating;
}

// ─── Review Providers ───────────────────────────────────────────────────────

/// Get reviews for a bike listing
final listingReviewsProvider =
    StreamProvider.autoDispose.family<List<BikeReview>, String>((ref, listingId) {
  final service = ref.watch(bikeRentalServiceProvider);
  return service.getListingReviews(listingId);
});

/// Get reviews for a user
final userReviewsProvider =
    StreamProvider.autoDispose.family<List<BikeReview>, String>((ref, userId) {
  final service = ref.watch(bikeRentalServiceProvider);
  return service.getUserReviews(userId);
});

/// Calculate average rating for a user
final userAverageRatingProvider =
    Provider.autoDispose.family<AsyncValue<double>, String>((ref, userId) {
  return ref.watch(userReviewsProvider(userId)).whenData((list) {
    if (list.isEmpty) return 0.0;
    
    final totalRating = list.fold<int>(0, (acc, r) => acc + r.rating);
    return totalRating / list.length;
  });
});

/// Calculate average rating for a bike listing
final listingAverageRatingProvider =
    Provider.autoDispose.family<AsyncValue<double>, String>((ref, listingId) {
  return ref.watch(listingReviewsProvider(listingId)).whenData((list) {
    if (list.isEmpty) return 0.0;
    
    final totalRating = list.fold<int>(0, (acc, r) => acc + r.rating);
    return totalRating / list.length;
  });
});
