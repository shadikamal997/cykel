/// CYKEL — DAWA Address Service
/// Free Danish Government address autocomplete API.
/// Docs: https://dawadocs.dataforsyningen.dk/

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class DawaService {
  static const _base = 'https://api.dataforsyningen.dk';

  /// Autocomplete Danish addresses.
  /// Returns list of [DawaAddress] suggestions.
  Future<List<DawaAddress>> autocomplete(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse('$_base/adresser/autocomplete').replace(
      queryParameters: {
        'q': query,
        'per_side': '8',
        'fuzzy': '',
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return [];

    final List<dynamic> data = json.decode(response.body) as List;
    return data
        .map((e) => DawaAddress.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Get full address details including coordinates.
  Future<DawaAddress?> getById(String id) async {
    final uri = Uri.parse('$_base/adresser/$id');
    final response = await http.get(uri);
    if (response.statusCode != 200) return null;
    final data = json.decode(response.body) as Map<String, dynamic>;
    return DawaAddress.fromDetailMap(data);
  }
}

class DawaAddress {
  const DawaAddress({
    required this.id,
    required this.text,
    this.lat,
    this.lng,
    this.postalCode,
    this.city,
    this.street,
    this.houseNumber,
  });

  final String id;
  final String text;
  final double? lat;
  final double? lng;
  final String? postalCode;
  final String? city;
  final String? street;
  final String? houseNumber;

  bool get hasCoordinates => lat != null && lng != null;

  factory DawaAddress.fromMap(Map<String, dynamic> map) {
    final adresse = map['adresse'] as Map<String, dynamic>?;
    return DawaAddress(
      id: adresse?['id'] as String? ?? map['tekst'] as String,
      text: map['tekst'] as String,
    );
  }

  factory DawaAddress.fromDetailMap(Map<String, dynamic> map) {
    final adgangsadresse =
        map['adgangsadresse'] as Map<String, dynamic>? ?? {};
    final vejstykke = adgangsadresse['vejstykke'] as Map<String, dynamic>? ?? {};
    final postnummer =
        adgangsadresse['postnummer'] as Map<String, dynamic>? ?? {};
    final koordinater =
        adgangsadresse['koordinater'] as List<dynamic>?;

    return DawaAddress(
      id: map['id'] as String,
      text: map['adressebetegnelse'] as String? ?? '',
      lat: koordinater != null && koordinater.length >= 2
          ? (koordinater[1] as num).toDouble()
          : null,
      lng: koordinater != null && koordinater.isNotEmpty
          ? (koordinater[0] as num).toDouble()
          : null,
      postalCode: postnummer['nr'] as String?,
      city: postnummer['navn'] as String?,
      street: vejstykke['navn'] as String?,
      houseNumber: adgangsadresse['husnr'] as String?,
    );
  }
}

final dawaServiceProvider = Provider<DawaService>((ref) => DawaService());
