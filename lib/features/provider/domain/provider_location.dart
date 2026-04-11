/// CYKEL — Provider Location Domain Model
/// Represents a physical provider location (shop, repair, charging station)
/// visible on the public map and in the Discover tab.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'provider_enums.dart';
import 'provider_model.dart';

class ProviderLocation {
  const ProviderLocation({
    required this.id,
    required this.providerId,
    required this.providerType,
    required this.name,
    required this.streetAddress,
    required this.city,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.email,
    this.website,
    this.description,
    this.photoUrls = const [],
    this.openingHours = const {},
    this.isActive = true,
    this.temporarilyClosed = false,
    this.specialNotice,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String providerId;
  final ProviderType providerType;
  final String name;
  final String streetAddress;
  final String city;
  final String postalCode;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? email;
  final String? website;
  final String? description;
  final List<String> photoUrls;
  final Map<String, DayHours> openingHours;
  final bool isActive;
  final bool temporarilyClosed;
  final String? specialNotice;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Computed helpers ──────────────────────────────────────────────────────

  bool get isOpen => isActive && !temporarilyClosed;

  String get fullAddress => '$streetAddress, $postalCode $city';

  // ── Firestore serialisation ───────────────────────────────────────────────

  factory ProviderLocation.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return ProviderLocation(
      id: doc.id,
      providerId: m['providerId'] as String? ?? '',
      providerType:
          ProviderType.fromKey(m['providerType'] as String? ?? 'repair_shop'),
      name: m['name'] as String? ?? '',
      streetAddress: m['streetAddress'] as String? ?? '',
      city: m['city'] as String? ?? '',
      postalCode: m['postalCode'] as String? ?? '',
      latitude: (m['latitude'] as num? ?? 0).toDouble(),
      longitude: (m['longitude'] as num? ?? 0).toDouble(),
      phone: m['phone'] as String?,
      email: m['email'] as String?,
      website: m['website'] as String?,
      description: m['description'] as String?,
      photoUrls: List<String>.from(m['photoUrls'] as List? ?? []),
      openingHours: _parseHours(m['openingHours']),
      isActive: m['isActive'] as bool? ?? true,
      temporarilyClosed: m['temporarilyClosed'] as bool? ?? false,
      specialNotice: m['specialNotice'] as String?,
      createdAt: m['createdAt'] is Timestamp
          ? (m['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: m['updatedAt'] is Timestamp
          ? (m['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'providerId': providerId,
        'providerType': providerType.key,
        'name': name,
        'streetAddress': streetAddress,
        'city': city,
        'postalCode': postalCode,
        'latitude': latitude,
        'longitude': longitude,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (website != null) 'website': website,
        if (description != null) 'description': description,
        'photoUrls': photoUrls,
        'openingHours': openingHours.map((k, v) => MapEntry(k, v.toMap())),
        'isActive': isActive,
        'temporarilyClosed': temporarilyClosed,
        if (specialNotice != null) 'specialNotice': specialNotice,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  ProviderLocation copyWith({
    String? id,
    String? providerId,
    ProviderType? providerType,
    String? name,
    String? streetAddress,
    String? city,
    String? postalCode,
    double? latitude,
    double? longitude,
    String? phone,
    String? email,
    String? website,
    String? description,
    List<String>? photoUrls,
    Map<String, DayHours>? openingHours,
    bool? isActive,
    bool? temporarilyClosed,
    String? specialNotice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      ProviderLocation(
        id: id ?? this.id,
        providerId: providerId ?? this.providerId,
        providerType: providerType ?? this.providerType,
        name: name ?? this.name,
        streetAddress: streetAddress ?? this.streetAddress,
        city: city ?? this.city,
        postalCode: postalCode ?? this.postalCode,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        website: website ?? this.website,
        description: description ?? this.description,
        photoUrls: photoUrls ?? this.photoUrls,
        openingHours: openingHours ?? this.openingHours,
        isActive: isActive ?? this.isActive,
        temporarilyClosed: temporarilyClosed ?? this.temporarilyClosed,
        specialNotice: specialNotice ?? this.specialNotice,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  // ── Private helpers ───────────────────────────────────────────────────────

  static Map<String, DayHours> _parseHours(dynamic raw) {
    if (raw is! Map) return {};
    return (raw as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, DayHours.fromMap(v as Map<String, dynamic>)),
    );
  }
}
