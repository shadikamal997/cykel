/// CYKEL — Place domain model
/// Represents a cycling-relevant location (charging, service, shop, rental).

class Place {
  const Place({
    required this.id,
    required this.type,
    required this.name,
    required this.lat,
    required this.lng,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.openingHours,
    this.photoUrls = const [],
    this.distanceMeters,
  });

  final String id;
  final PlaceType type;
  final String name;
  final double lat;
  final double lng;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final String? openingHours;
  final List<String> photoUrls;
  final double? distanceMeters;

  Place copyWith({double? distanceMeters}) => Place(
        id: id,
        type: type,
        name: name,
        lat: lat,
        lng: lng,
        address: address,
        phone: phone,
        email: email,
        website: website,
        openingHours: openingHours,
        photoUrls: photoUrls,
        distanceMeters: distanceMeters ?? this.distanceMeters,
      );

  factory Place.fromMap(String id, Map<String, dynamic> map) => Place(
        id: id,
        type: PlaceType.fromString(map['type'] as String? ?? 'service'),
        name: map['name'] as String? ?? '',
        lat: (map['lat'] as num).toDouble(),
        lng: (map['lng'] as num).toDouble(),
        address: map['address'] as String?,
        phone: map['phone'] as String?,
        email: map['email'] as String?,
        website: map['website'] as String?,
        openingHours: map['openingHours'] as String?,
        photoUrls: List<String>.from(map['photoUrls'] as List? ?? []),
      );

  String get distanceLabel {
    if (distanceMeters == null) return '';
    if (distanceMeters! < 1000) return '${distanceMeters!.round()} m';
    return '${(distanceMeters! / 1000).toStringAsFixed(1)} km';
  }
}

enum PlaceType {
  charging,
  service,
  shop,
  rental;

  static PlaceType fromString(String value) {
    return PlaceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PlaceType.service,
    );
  }
}
