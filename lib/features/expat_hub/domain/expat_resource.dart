/// CYKEL — Expat Hub Domain Models
/// Resources and guides for expats and newcomers to Copenhagen

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ─── Resource Categories ───────────────────────────────────────────────────

enum ResourceCategory {
  gettingStarted,
  cyclingLaws,
  safety,
  culture,
  maintenance,
  shopping,
  weather,
  emergency;

  String get displayName {
    switch (this) {
      case ResourceCategory.gettingStarted:
        return 'Getting Started';
      case ResourceCategory.cyclingLaws:
        return 'Cycling Laws';
      case ResourceCategory.safety:
        return 'Safety';
      case ResourceCategory.culture:
        return 'Culture & Etiquette';
      case ResourceCategory.maintenance:
        return 'Bike Maintenance';
      case ResourceCategory.shopping:
        return 'Shopping & Services';
      case ResourceCategory.weather:
        return 'Weather & Seasons';
      case ResourceCategory.emergency:
        return 'Emergency';
    }
  }

  String get icon {
    switch (this) {
      case ResourceCategory.gettingStarted:
        return '🚴';
      case ResourceCategory.cyclingLaws:
        return '📜';
      case ResourceCategory.safety:
        return '🦺';
      case ResourceCategory.culture:
        return '🇩🇰';
      case ResourceCategory.maintenance:
        return '🔧';
      case ResourceCategory.shopping:
        return '🏪';
      case ResourceCategory.weather:
        return '🌦️';
      case ResourceCategory.emergency:
        return '🚨';
    }
  }

  String get description {
    switch (this) {
      case ResourceCategory.gettingStarted:
        return 'Essential information for your first days cycling in Copenhagen';
      case ResourceCategory.cyclingLaws:
        return 'Danish traffic rules and regulations for cyclists';
      case ResourceCategory.safety:
        return 'Stay safe on Copenhagen roads';
      case ResourceCategory.culture:
        return 'Learn Danish cycling culture and etiquette';
      case ResourceCategory.maintenance:
        return 'Keep your bike in top condition';
      case ResourceCategory.shopping:
        return 'Where to buy and service your bike';
      case ResourceCategory.weather:
        return 'Cycling through all seasons';
      case ResourceCategory.emergency:
        return 'Important contacts and what to do in emergencies';
    }
  }
}

enum DifficultyLevel {
  beginner,
  intermediate,
  advanced;

  String get displayName {
    switch (this) {
      case DifficultyLevel.beginner:
        return 'Beginner';
      case DifficultyLevel.intermediate:
        return 'Intermediate';
      case DifficultyLevel.advanced:
        return 'Advanced';
    }
  }

  String get icon {
    switch (this) {
      case DifficultyLevel.beginner:
        return '🟢';
      case DifficultyLevel.intermediate:
        return '🟡';
      case DifficultyLevel.advanced:
        return '🔴';
    }
  }
}

// ─── Expat Guide ───────────────────────────────────────────────────────────

class ExpatGuide {
  const ExpatGuide({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    required this.summary,
    required this.difficulty,
    required this.readTimeMinutes,
    required this.language,
    this.translatedVersions = const {},
    this.tags = const [],
    this.relatedGuides = const [],
    this.coverImageUrl,
    this.author,
    this.lastUpdated,
    required this.createdAt,
    this.viewCount = 0,
    this.helpfulCount = 0,
    this.isPinned = false,
  });

  final String id;
  final String title;
  final ResourceCategory category;
  final String content; // Markdown formatted
  final String summary;
  final DifficultyLevel difficulty;
  final int readTimeMinutes;
  final String language; // 'en', 'da', 'de', etc.
  final Map<String, String> translatedVersions; // language code -> guide ID
  final List<String> tags;
  final List<String> relatedGuides; // Guide IDs
  final String? coverImageUrl;
  final String? author; // User ID or 'CYKEL Team'
  final DateTime? lastUpdated;
  final DateTime createdAt;
  final int viewCount;
  final int helpfulCount;
  final bool isPinned;

  bool get isOfficial => author == null || author == 'CYKEL Team';
  bool get hasTranslations => translatedVersions.isNotEmpty;
  bool get isRecent => createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30)));

  factory ExpatGuide.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpatGuide(
      id: doc.id,
      title: data['title'] ?? '',
      category: ResourceCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => ResourceCategory.gettingStarted,
      ),
      content: data['content'] ?? '',
      summary: data['summary'] ?? '',
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => DifficultyLevel.beginner,
      ),
      readTimeMinutes: data['readTimeMinutes'] ?? 5,
      language: data['language'] ?? 'en',
      translatedVersions: Map<String, String>.from(data['translatedVersions'] ?? {}),
      tags: List<String>.from(data['tags'] ?? []),
      relatedGuides: List<String>.from(data['relatedGuides'] ?? []),
      coverImageUrl: data['coverImageUrl'],
      author: data['author'],
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      viewCount: data['viewCount'] ?? 0,
      helpfulCount: data['helpfulCount'] ?? 0,
      isPinned: data['isPinned'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'category': category.name,
      'content': content,
      'summary': summary,
      'difficulty': difficulty.name,
      'readTimeMinutes': readTimeMinutes,
      'language': language,
      'translatedVersions': translatedVersions,
      'tags': tags,
      'relatedGuides': relatedGuides,
      'coverImageUrl': coverImageUrl,
      'author': author,
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'viewCount': viewCount,
      'helpfulCount': helpfulCount,
      'isPinned': isPinned,
    };
  }

  ExpatGuide copyWith({
    String? title,
    ResourceCategory? category,
    String? content,
    String? summary,
    DifficultyLevel? difficulty,
    int? readTimeMinutes,
    String? language,
    Map<String, String>? translatedVersions,
    List<String>? tags,
    List<String>? relatedGuides,
    String? coverImageUrl,
    String? author,
    DateTime? lastUpdated,
    int? viewCount,
    int? helpfulCount,
    bool? isPinned,
  }) {
    return ExpatGuide(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      difficulty: difficulty ?? this.difficulty,
      readTimeMinutes: readTimeMinutes ?? this.readTimeMinutes,
      language: language ?? this.language,
      translatedVersions: translatedVersions ?? this.translatedVersions,
      tags: tags ?? this.tags,
      relatedGuides: relatedGuides ?? this.relatedGuides,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      author: author ?? this.author,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt,
      viewCount: viewCount ?? this.viewCount,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}

// ─── Quick Tips ────────────────────────────────────────────────────────────

class QuickTip {
  const QuickTip({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.icon,
    this.priority = 0,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final ResourceCategory category;
  final String? icon;
  final int priority; // Higher = more important
  final DateTime createdAt;

  factory QuickTip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuickTip(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: ResourceCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => ResourceCategory.gettingStarted,
      ),
      icon: data['icon'],
      priority: data['priority'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category.name,
      'icon': icon,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

// ─── Bike Shops & Services ─────────────────────────────────────────────────

enum ShopService {
  sales,
  repair,
  rental,
  accessories,
  customization,
  electricBikes,
  cargoBikes;

  String get displayName {
    switch (this) {
      case ShopService.sales:
        return 'Bike Sales';
      case ShopService.repair:
        return 'Repairs';
      case ShopService.rental:
        return 'Rentals';
      case ShopService.accessories:
        return 'Accessories';
      case ShopService.customization:
        return 'Customization';
      case ShopService.electricBikes:
        return 'E-Bikes';
      case ShopService.cargoBikes:
        return 'Cargo Bikes';
    }
  }
}

class BikeShop {
  const BikeShop({
    required this.id,
    required this.name,
    required this.location,
    required this.address,
    required this.services,
    this.description,
    this.phone,
    this.email,
    this.website,
    this.openingHours,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isExpatFriendly = false,
    this.languagesSpoken = const ['da'],
    this.photoUrls = const [],
    required this.createdAt,
  });

  final String id;
  final String name;
  final LatLng location;
  final String address;
  final List<ShopService> services;
  final String? description;
  final String? phone;
  final String? email;
  final String? website;
  final Map<String, String>? openingHours; // day -> hours
  final double rating;
  final int reviewCount;
  final bool isExpatFriendly; // English-speaking staff
  final List<String> languagesSpoken; // ISO codes
  final List<String> photoUrls;
  final DateTime createdAt;

  bool get hasPhotos => photoUrls.isNotEmpty;
  bool get hasRatings => reviewCount > 0;
  bool get speaksEnglish => languagesSpoken.contains('en');

  String get servicesDisplay => services.map((s) => s.displayName).join(', ');

  factory BikeShop.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final geopoint = data['location'] as GeoPoint;
    
    return BikeShop(
      id: doc.id,
      name: data['name'] ?? '',
      location: LatLng(geopoint.latitude, geopoint.longitude),
      address: data['address'] ?? '',
      services: (data['services'] as List<dynamic>?)
          ?.map((s) => ShopService.values.firstWhere(
                (e) => e.name == s,
                orElse: () => ShopService.sales,
              ))
          .toList() ??
          [],
      description: data['description'],
      phone: data['phone'],
      email: data['email'],
      website: data['website'],
      openingHours: data['openingHours'] != null
          ? Map<String, String>.from(data['openingHours'])
          : null,
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      isExpatFriendly: data['isExpatFriendly'] ?? false,
      languagesSpoken: List<String>.from(data['languagesSpoken'] ?? ['da']),
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'location': GeoPoint(location.latitude, location.longitude),
      'address': address,
      'services': services.map((s) => s.name).toList(),
      'description': description,
      'phone': phone,
      'email': email,
      'website': website,
      'openingHours': openingHours,
      'rating': rating,
      'reviewCount': reviewCount,
      'isExpatFriendly': isExpatFriendly,
      'languagesSpoken': languagesSpoken,
      'photoUrls': photoUrls,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

// ─── Emergency Contacts ────────────────────────────────────────────────────

enum EmergencyType {
  police,
  medical,
  roadAssistance,
  bikeTheft,
  embassy,
  other;

  String get displayName {
    switch (this) {
      case EmergencyType.police:
        return 'Police';
      case EmergencyType.medical:
        return 'Medical';
      case EmergencyType.roadAssistance:
        return 'Road Assistance';
      case EmergencyType.bikeTheft:
        return 'Bike Theft';
      case EmergencyType.embassy:
        return 'Embassy';
      case EmergencyType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case EmergencyType.police:
        return '👮';
      case EmergencyType.medical:
        return '🏥';
      case EmergencyType.roadAssistance:
        return '🚗';
      case EmergencyType.bikeTheft:
        return '🚲';
      case EmergencyType.embassy:
        return '🏛️';
      case EmergencyType.other:
        return '📞';
    }
  }
}

class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.type,
    required this.phoneNumber,
    this.description,
    this.website,
    this.address,
    this.isAvailable24x7 = false,
    this.languages = const ['da'],
    required this.createdAt,
  });

  final String id;
  final String name;
  final EmergencyType type;
  final String phoneNumber;
  final String? description;
  final String? website;
  final String? address;
  final bool isAvailable24x7;
  final List<String> languages;
  final DateTime createdAt;

  bool get speaksEnglish => languages.contains('en');

  factory EmergencyContact.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EmergencyContact(
      id: doc.id,
      name: data['name'] ?? '',
      type: EmergencyType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => EmergencyType.other,
      ),
      phoneNumber: data['phoneNumber'] ?? '',
      description: data['description'],
      website: data['website'],
      address: data['address'],
      isAvailable24x7: data['isAvailable24x7'] ?? false,
      languages: List<String>.from(data['languages'] ?? ['da']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type.name,
      'phoneNumber': phoneNumber,
      'description': description,
      'website': website,
      'address': address,
      'isAvailable24x7': isAvailable24x7,
      'languages': languages,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

// ─── Cycling Rules ─────────────────────────────────────────────────────────

enum RuleSeverity {
  info,
  warning,
  critical;

  String get displayName {
    switch (this) {
      case RuleSeverity.info:
        return 'Info';
      case RuleSeverity.warning:
        return 'Important';
      case RuleSeverity.critical:
        return 'Critical';
    }
  }

  String get icon {
    switch (this) {
      case RuleSeverity.info:
        return 'ℹ️';
      case RuleSeverity.warning:
        return '⚠️';
      case RuleSeverity.critical:
        return '🚫';
    }
  }
}

class CyclingRule {
  const CyclingRule({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    this.fine, // DKK
    this.examples = const [],
    this.imageUrl,
    this.videoUrl,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final RuleSeverity severity;
  final int? fine;
  final List<String> examples;
  final String? imageUrl;
  final String? videoUrl;
  final DateTime createdAt;

  bool get hasFine => fine != null && fine! > 0;
  String get fineDisplay => hasFine ? '$fine DKK' : 'No fine';

  factory CyclingRule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CyclingRule(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      severity: RuleSeverity.values.firstWhere(
        (e) => e.name == data['severity'],
        orElse: () => RuleSeverity.info,
      ),
      fine: data['fine'],
      examples: List<String>.from(data['examples'] ?? []),
      imageUrl: data['imageUrl'],
      videoUrl: data['videoUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'severity': severity.name,
      'fine': fine,
      'examples': examples,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

// ─── Expat Routes ──────────────────────────────────────────────────────────

class ExpatRoute {
  const ExpatRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.startPoint,
    required this.endPoint,
    required this.distance,
    required this.difficulty,
    required this.points, // Route polyline points
    this.highlights = const [],
    this.tips = const [],
    this.photoUrls = const [],
    this.isScenic = false,
    this.isTouristFriendly = false,
    this.isCommute = false,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final LatLng startPoint;
  final LatLng endPoint;
  final double distance; // km
  final DifficultyLevel difficulty;
  final List<LatLng> points;
  final List<String> highlights; // Points of interest
  final List<String> tips;
  final List<String> photoUrls;
  final bool isScenic;
  final bool isTouristFriendly;
  final bool isCommute;
  final DateTime createdAt;

  String get distanceDisplay => '${distance.toStringAsFixed(1)} km';
  
  int get estimatedMinutes => (distance * 5).round(); // ~12 km/h average
  String get estimatedTimeDisplay {
    final hours = estimatedMinutes ~/ 60;
    final mins = estimatedMinutes % 60;
    if (hours > 0) {
      return '$hours hr $mins min';
    }
    return '$mins min';
  }

  factory ExpatRoute.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    GeoPoint startGeo = data['startPoint'];
    GeoPoint endGeo = data['endPoint'];
    List<dynamic> pointsData = data['points'] ?? [];
    
    return ExpatRoute(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      startPoint: LatLng(startGeo.latitude, startGeo.longitude),
      endPoint: LatLng(endGeo.latitude, endGeo.longitude),
      distance: (data['distance'] ?? 0.0).toDouble(),
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => DifficultyLevel.beginner,
      ),
      points: pointsData.map((p) {
        final gp = p as GeoPoint;
        return LatLng(gp.latitude, gp.longitude);
      }).toList(),
      highlights: List<String>.from(data['highlights'] ?? []),
      tips: List<String>.from(data['tips'] ?? []),
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      isScenic: data['isScenic'] ?? false,
      isTouristFriendly: data['isTouristFriendly'] ?? false,
      isCommute: data['isCommute'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'startPoint': GeoPoint(startPoint.latitude, startPoint.longitude),
      'endPoint': GeoPoint(endPoint.latitude, endPoint.longitude),
      'distance': distance,
      'difficulty': difficulty.name,
      'points': points.map((p) => GeoPoint(p.latitude, p.longitude)).toList(),
      'highlights': highlights,
      'tips': tips,
      'photoUrls': photoUrls,
      'isScenic': isScenic,
      'isTouristFriendly': isTouristFriendly,
      'isCommute': isCommute,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
