/// CYKEL — Marketplace domain models

import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum ListingCategory { bike, parts, accessories, clothing, tools }

enum ListingCondition { newItem, likeNew, good, fair }

extension ListingCategoryX on ListingCategory {
  String get key => switch (this) {
        ListingCategory.bike => 'bike',
        ListingCategory.parts => 'parts',
        ListingCategory.accessories => 'accessories',
        ListingCategory.clothing => 'clothing',
        ListingCategory.tools => 'tools',
      };

  static ListingCategory fromKey(String s) => switch (s) {
        'parts' => ListingCategory.parts,
        'accessories' => ListingCategory.accessories,
        'clothing' => ListingCategory.clothing,
        'tools' => ListingCategory.tools,
        _ => ListingCategory.bike,
      };
}

extension ListingConditionX on ListingCondition {
  String get key => switch (this) {
        ListingCondition.newItem => 'new',
        ListingCondition.likeNew => 'likeNew',
        ListingCondition.good => 'good',
        ListingCondition.fair => 'fair',
      };

  static ListingCondition fromKey(String s) => switch (s) {
        'new' => ListingCondition.newItem,
        'likeNew' => ListingCondition.likeNew,
        'fair' => ListingCondition.fair,
        _ => ListingCondition.good,
      };
}

// ─── MarketplaceListing ───────────────────────────────────────────────────────

class MarketplaceListing {
  const MarketplaceListing({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    this.sellerPhotoUrl,
    this.sellerPhotoThumbnailUrl,
    required this.isShop,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.imageUrls,
    this.thumbnailUrls = const [],
    required this.city,
    this.lat,
    this.lng,
    required this.isSold,
    required this.createdAt,
    this.viewCount = 0,
    this.saveCount = 0,
    this.phone,
    this.isPriority = false,
    this.brand,
    this.isElectric = false,
    this.serialNumber,
    this.serialVerified = false,
    this.serialDuplicate = false,
  });

  final String id;
  final String sellerId;
  final String sellerName;
  final String? sellerPhotoUrl;
  final String? sellerPhotoThumbnailUrl;
  final bool isShop;
  final String title;
  final String description;
  final double price;
  final ListingCategory category;
  final ListingCondition condition;
  final List<String> imageUrls;
  final List<String> thumbnailUrls;
  final String city;
  final double? lat;
  final double? lng;
  final bool isSold;
  final DateTime createdAt;
  final int viewCount;
  final int saveCount;
  final String? phone;
  final bool isPriority;
  final String? brand;
  final bool isElectric;
  final String? serialNumber;
  final bool serialVerified;
  final bool serialDuplicate;

  String get priceLabel => '${price.toStringAsFixed(0)} DKK';

  /// Calculate thumbnail URL from image URL
  /// Cloud Function creates thumbnails in: thumbnails/{original_path}
  static String? getThumbnailUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    
    // Firebase Storage URL pattern: .../o/path%2Fto%2Fimage.jpg?alt=...
    // Extract path and prepend "thumbnails/"
    final uri = Uri.parse(imageUrl);
    final encodedPath = uri.pathSegments.lastWhere(
      (segment) => segment.contains('%2F'),
      orElse: () => '',
    );
    
    if (encodedPath.isEmpty) return imageUrl;
    
    final decodedPath = Uri.decodeComponent(encodedPath);
    final thumbnailPath = 'thumbnails/$decodedPath';
    final encodedThumbnailPath = Uri.encodeComponent(thumbnailPath);
    
    return imageUrl.replaceFirst(encodedPath, encodedThumbnailPath);
  }

  /// Get thumbnail URL for seller photo
  String? get sellerPhotoThumbnail => getThumbnailUrl(sellerPhotoUrl);

  /// Get thumbnail URLs for all listing images  
  List<String> get imageThumbnails => 
      imageUrls.map((url) => getThumbnailUrl(url) ?? url).toList();

  factory MarketplaceListing.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return MarketplaceListing(
      id: doc.id,
      sellerId: m['sellerId'] as String? ?? '',
      sellerName: m['sellerName'] as String? ?? 'Unknown',
      sellerPhotoUrl: m['sellerPhotoUrl'] as String?,
      sellerPhotoThumbnailUrl: m['sellerPhotoThumbnailUrl'] as String?,
      isShop: m['isShop'] as bool? ?? false,
      title: m['title'] as String? ?? '',
      description: m['description'] as String? ?? '',
      price: (m['price'] as num? ?? 0).toDouble(),
      category:
          ListingCategoryX.fromKey(m['category'] as String? ?? 'bike'),
      condition:
          ListingConditionX.fromKey(m['condition'] as String? ?? 'good'),
      imageUrls: List<String>.from(m['imageUrls'] as List? ?? []),
      thumbnailUrls: List<String>.from(m['thumbnailUrls'] as List? ?? []),
      city: m['city'] as String? ?? '',
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      isSold: m['isSold'] as bool? ?? false,
      createdAt: m['createdAt'] is Timestamp
          ? (m['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      viewCount: m['viewCount'] as int? ?? 0,
      saveCount: m['saveCount'] as int? ?? 0,
      phone: m['phone'] as String?,
      isPriority: m['isPriority'] as bool? ?? false,
      brand: m['brand'] as String?,
      isElectric: m['isElectric'] as bool? ?? false,
      serialNumber: m['serialNumber'] as String?,
      serialVerified: m['serialVerified'] as bool? ?? false,
      serialDuplicate: m['serialDuplicate'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'sellerId': sellerId,
        'sellerName': sellerName,
        if (sellerPhotoUrl != null) 'sellerPhotoUrl': sellerPhotoUrl,
        if (sellerPhotoThumbnailUrl != null) 'sellerPhotoThumbnailUrl': sellerPhotoThumbnailUrl,
        'isShop': isShop,
        'title': title,
        'description': description,
        'price': price,
        'category': category.key,
        'condition': condition.key,
        'imageUrls': imageUrls,
        'thumbnailUrls': thumbnailUrls,
        'city': city,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'isSold': isSold,
        'createdAt': Timestamp.fromDate(createdAt),
        'viewCount': viewCount,
        'saveCount': saveCount,
        if (phone != null) 'phone': phone,
        'isPriority': isPriority,
        if (brand != null) 'brand': brand,
        'isElectric': isElectric,
        if (serialNumber != null) 'serialNumber': serialNumber,
        'serialVerified': serialVerified,
        'serialDuplicate': serialDuplicate,
      };

  MarketplaceListing copyWith({
    String? id,
    String? sellerId,
    String? sellerName,
    String? sellerPhotoUrl,
    String? sellerPhotoThumbnailUrl,
    bool? isShop,
    String? title,
    String? description,
    double? price,
    ListingCategory? category,
    ListingCondition? condition,
    List<String>? imageUrls,
    List<String>? thumbnailUrls,
    String? city,
    double? lat,
    double? lng,
    bool? isSold,
    DateTime? createdAt,
    int? viewCount,
    int? saveCount,
    String? phone,
    bool? isPriority,
    String? brand,
    bool? isElectric,
    String? serialNumber,
    bool? serialVerified,
    bool? serialDuplicate,
  }) =>
      MarketplaceListing(
        id: id ?? this.id,
        sellerId: sellerId ?? this.sellerId,
        sellerName: sellerName ?? this.sellerName,
        sellerPhotoUrl: sellerPhotoUrl ?? this.sellerPhotoUrl,
        sellerPhotoThumbnailUrl: sellerPhotoThumbnailUrl ?? this.sellerPhotoThumbnailUrl,
        isShop: isShop ?? this.isShop,
        title: title ?? this.title,
        description: description ?? this.description,
        price: price ?? this.price,
        category: category ?? this.category,
        condition: condition ?? this.condition,
        imageUrls: imageUrls ?? this.imageUrls,
        thumbnailUrls: thumbnailUrls ?? this.thumbnailUrls,
        city: city ?? this.city,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        isSold: isSold ?? this.isSold,
        createdAt: createdAt ?? this.createdAt,
        viewCount: viewCount ?? this.viewCount,
        saveCount: saveCount ?? this.saveCount,
        phone: phone ?? this.phone,
        isPriority: isPriority ?? this.isPriority,
        brand: brand ?? this.brand,
        isElectric: isElectric ?? this.isElectric,
        serialNumber: serialNumber ?? this.serialNumber,
        serialVerified: serialVerified ?? this.serialVerified,
        serialDuplicate: serialDuplicate ?? this.serialDuplicate,
      );
}
