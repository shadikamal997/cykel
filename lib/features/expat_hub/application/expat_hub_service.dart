/// CYKEL — Expat Hub Service
/// Service for managing expat resources and content

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../domain/expat_resource.dart';

class ExpatHubService {
  ExpatHubService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUserId => _auth.currentUser?.uid;

  // Collection references
  CollectionReference get expatGuides => _firestore.collection('expatGuides');
  CollectionReference get quickTips => _firestore.collection('quickTips');
  CollectionReference get bikeShops => _firestore.collection('bikeShops');
  CollectionReference get emergencyContacts => _firestore.collection('emergencyContacts');
  CollectionReference get cyclingRules => _firestore.collection('cyclingRules');
  CollectionReference get expatRoutes => _firestore.collection('expatRoutes');

  // ─── Expat Guides ──────────────────────────────────────────────────────────

  /// Get all guides (optionally filtered by category)
  Stream<List<ExpatGuide>> getGuides({
    ResourceCategory? category,
    String? language,
    bool pinnedFirst = true,
  }) {
    Query query = expatGuides;

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }

    if (language != null) {
      query = query.where('language', isEqualTo: language);
    }

    if (pinnedFirst) {
      query = query.orderBy('isPinned', descending: true);
    }

    query = query.orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ExpatGuide.fromFirestore(doc)).toList();
    });
  }

  /// Get a specific guide
  Future<ExpatGuide?> getGuide(String guideId) async {
    final doc = await expatGuides.doc(guideId).get();
    if (!doc.exists) return null;
    return ExpatGuide.fromFirestore(doc);
  }

  /// Search guides by title or tags
  Stream<List<ExpatGuide>> searchGuides(String query) {
    // Note: For production, use Algolia or similar for full-text search
    // This is a simple implementation
    return expatGuides
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      final guides = snapshot.docs.map((doc) => ExpatGuide.fromFirestore(doc)).toList();
      
      // Client-side filtering
      final lowerQuery = query.toLowerCase();
      return guides.where((guide) {
        return guide.title.toLowerCase().contains(lowerQuery) ||
            guide.summary.toLowerCase().contains(lowerQuery) ||
            guide.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
      }).toList();
    });
  }

  /// Mark guide as helpful
  Future<void> markGuideHelpful(String guideId) async {
    await expatGuides.doc(guideId).update({
      'helpfulCount': FieldValue.increment(1),
    });
  }

  /// Increment view count
  Future<void> incrementGuideViews(String guideId) async {
    await expatGuides.doc(guideId).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  /// Increment view count (singular alias)
  Future<void> incrementGuideView(String guideId) => incrementGuideViews(guideId);

  /// Get guides by category
  Stream<List<ExpatGuide>> getGuidesByCategory(ResourceCategory category) {
    return expatGuides
        .where('category', isEqualTo: category.name)
        .orderBy('isPinned', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ExpatGuide.fromFirestore(doc)).toList();
    });
  }

  /// Get pinned/featured guides
  Stream<List<ExpatGuide>> getFeaturedGuides() {
    return expatGuides
        .where('isPinned', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ExpatGuide.fromFirestore(doc)).toList();
    });
  }

  /// Get the featured "Getting Started" guide (first pinned guide in gettingStarted category)
  Stream<ExpatGuide?> getFeaturedGettingStartedGuide() {
    return expatGuides
        .where('category', isEqualTo: ResourceCategory.gettingStarted.name)
        .where('isPinned', isEqualTo: true)
        .orderBy('createdAt', descending: false) // Oldest pinned first
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return ExpatGuide.fromFirestore(snapshot.docs.first);
    });
  }

  // ─── Quick Tips ────────────────────────────────────────────────────────────

  /// Get quick tips (optionally by category)
  Stream<List<QuickTip>> getQuickTips({ResourceCategory? category}) {
    Query query = quickTips;

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }

    return query
        .orderBy('priority', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => QuickTip.fromFirestore(doc)).toList();
    });
  }

  /// Get top tips (high priority)
  Stream<List<QuickTip>> getTopTips({int limit = 10}) {
    return quickTips
        .orderBy('priority', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => QuickTip.fromFirestore(doc)).toList();
    });
  }

  // ─── Bike Shops ────────────────────────────────────────────────────────────

  /// Get all bike shops
  Stream<List<BikeShop>> getBikeShops() {
    return bikeShops
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BikeShop.fromFirestore(doc)).toList();
    });
  }

  /// Get bike shops by service
  Stream<List<BikeShop>> getShopsByService(ShopService service) {
    return bikeShops
        .where('services', arrayContains: service.name)
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BikeShop.fromFirestore(doc)).toList();
    });
  }

  /// Get expat-friendly shops (English-speaking)
  Stream<List<BikeShop>> getExpatFriendlyShops() {
    return bikeShops
        .where('isExpatFriendly', isEqualTo: true)
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BikeShop.fromFirestore(doc)).toList();
    });
  }

  /// Get nearby bike shops
  Stream<List<BikeShop>> getNearbyShops(LatLng location, double radiusKm) {
    // Note: For production, use GeoFirestore or similar
    // This fetches all and filters client-side
    return bikeShops.snapshots().map((snapshot) {
      final shops = snapshot.docs.map((doc) => BikeShop.fromFirestore(doc)).toList();
      
      return shops.where((shop) {
        final distance = _calculateDistance(
          location.latitude,
          location.longitude,
          shop.location.latitude,
          shop.location.longitude,
        );
        return distance <= radiusKm;
      }).toList()
        ..sort((a, b) {
          final distA = _calculateDistance(
            location.latitude,
            location.longitude,
            a.location.latitude,
            a.location.longitude,
          );
          final distB = _calculateDistance(
            location.latitude,
            location.longitude,
            b.location.latitude,
            b.location.longitude,
          );
          return distA.compareTo(distB);
        });
    });
  }

  // ─── Emergency Contacts ────────────────────────────────────────────────────

  /// Get emergency contacts (optionally by type)
  Stream<List<EmergencyContact>> getEmergencyContacts({EmergencyType? type}) {
    Query query = emergencyContacts;

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    return query
        .orderBy('isAvailable24x7', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EmergencyContact.fromFirestore(doc)).toList();
    });
  }

  /// Get 24/7 emergency contacts
  Stream<List<EmergencyContact>> get247Contacts() {
    return emergencyContacts
        .where('isAvailable24x7', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EmergencyContact.fromFirestore(doc)).toList();
    });
  }

  // ─── Cycling Rules ─────────────────────────────────────────────────────────

  /// Get all cycling rules
  Stream<List<CyclingRule>> getCyclingRules() {
    return cyclingRules
        .orderBy('severity', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CyclingRule.fromFirestore(doc)).toList();
    });
  }

  /// Get critical rules (must-know)
  Stream<List<CyclingRule>> getCriticalRules() {
    return cyclingRules
        .where('severity', isEqualTo: RuleSeverity.critical.name)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CyclingRule.fromFirestore(doc)).toList();
    });
  }

  /// Get rules with fines
  Stream<List<CyclingRule>> getRulesWithFines() {
    return cyclingRules
        .where('fine', isGreaterThan: 0)
        .orderBy('fine', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CyclingRule.fromFirestore(doc)).toList();
    });
  }

  // ─── Expat Routes ──────────────────────────────────────────────────────────

  /// Get all expat-friendly routes
  Stream<List<ExpatRoute>> getExpatRoutes() {
    return expatRoutes
        .orderBy('isTouristFriendly', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ExpatRoute.fromFirestore(doc)).toList();
    });
  }

  /// Get a specific route
  Future<ExpatRoute?> getRoute(String routeId) async {
    final doc = await expatRoutes.doc(routeId).get();
    if (!doc.exists) return null;
    return ExpatRoute.fromFirestore(doc);
  }

  /// Get scenic routes
  Stream<List<ExpatRoute>> getScenicRoutes() {
    return expatRoutes
        .where('isScenic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ExpatRoute.fromFirestore(doc)).toList();
    });
  }

  /// Get tourist-friendly routes
  Stream<List<ExpatRoute>> getTouristRoutes() {
    return expatRoutes
        .where('isTouristFriendly', isEqualTo: true)
        .orderBy('distance')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ExpatRoute.fromFirestore(doc)).toList();
    });
  }

  /// Get commute routes
  Stream<List<ExpatRoute>> getCommuteRoutes() {
    return expatRoutes
        .where('isCommute', isEqualTo: true)
        .orderBy('distance')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ExpatRoute.fromFirestore(doc)).toList();
    });
  }

  /// Get routes by difficulty
  Stream<List<ExpatRoute>> getRoutesByDifficulty(DifficultyLevel difficulty) {
    return expatRoutes
        .where('difficulty', isEqualTo: difficulty.name)
        .orderBy('distance')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ExpatRoute.fromFirestore(doc)).toList();
    });
  }

  // ─── Utilities ─────────────────────────────────────────────────────────────

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (3.14159265359 / 180.0);
}
