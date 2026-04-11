/// CYKEL — Frequent Destinations Service
/// Tracks how often the user navigates to each destination.
/// Persists visit counts to SharedPreferences.
/// Surfaces top destinations for the home screen "frequent routes" card.

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kFreqDestKey = 'cykel_freq_dest_v1';
const _kMaxStored   = 20; // keep at most 20 entries

// ─── Domain ──────────────────────────────────────────────────────────────────

class FrequentDestination {
  const FrequentDestination({
    required this.text,
    required this.lat,
    required this.lng,
    required this.count,
    required this.lastVisited,
  });

  final String   text;
  final double   lat;
  final double   lng;
  final int      count;
  final DateTime lastVisited;

  Map<String, dynamic> toJson() => {
        'text':        text,
        'lat':         lat,
        'lng':         lng,
        'count':       count,
        'lastVisited': lastVisited.toIso8601String(),
      };

  factory FrequentDestination.fromJson(Map<String, dynamic> m) =>
      FrequentDestination(
        text:        m['text'] as String,
        lat:         (m['lat'] as num).toDouble(),
        lng:         (m['lng'] as num).toDouble(),
        count:       (m['count'] as num).toInt(),
        lastVisited: DateTime.parse(m['lastVisited'] as String),
      );

  FrequentDestination copyWithIncrement() => FrequentDestination(
        text:        text,
        lat:         lat,
        lng:         lng,
        count:       count + 1,
        lastVisited: DateTime.now(),
      );
}

// ─── Service ─────────────────────────────────────────────────────────────────

class FrequentDestinationsService {
  // Records a navigation to [text/lat/lng].  Increments existing count if the
  // destination already has an entry (within ~100 m), otherwise adds a new one.
  Future<void> recordVisit({
    required String text,
    required double lat,
    required double lng,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_kFreqDestKey);
    var list    = <FrequentDestination>[];
    if (raw != null) {
      try {
        final decoded = json.decode(raw) as List;
        list = decoded
            .map((e) => FrequentDestination.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        list = [];
      }
    }

    // Match by proximity (~100 m bounding box ≈ 0.001 deg) or exact text.
    final idx = list.indexWhere((d) =>
        (d.lat - lat).abs() < 0.001 &&
        (d.lng - lng).abs() < 0.001);

    if (idx >= 0) {
      list[idx] = list[idx].copyWithIncrement();
    } else {
      list.add(FrequentDestination(
        text:        text,
        lat:         lat,
        lng:         lng,
        count:       1,
        lastVisited: DateTime.now(),
      ));
    }

    // Sort by count descending, keep top _kMaxStored.
    list.sort((a, b) => b.count.compareTo(a.count));
    if (list.length > _kMaxStored) list = list.sublist(0, _kMaxStored);

    await prefs.setString(
        _kFreqDestKey, json.encode(list.map((d) => d.toJson()).toList()));
  }

  /// Returns top [limit] destinations sorted by visit count.
  Future<List<FrequentDestination>> getTopDestinations({int limit = 5}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_kFreqDestKey);
    if (raw == null) return [];
    try {
      final decoded = json.decode(raw) as List;
      final list    = decoded
          .map((e) => FrequentDestination.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.count.compareTo(a.count));
      return list.take(limit).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kFreqDestKey);
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final frequentDestinationsServiceProvider =
    Provider<FrequentDestinationsService>((_) => FrequentDestinationsService());

/// Async provider that exposes the top 5 destinations as a list.
final frequentDestinationsProvider =
    FutureProvider.autoDispose<List<FrequentDestination>>((ref) async {
  return ref.read(frequentDestinationsServiceProvider).getTopDestinations();
});
