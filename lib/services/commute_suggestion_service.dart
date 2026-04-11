/// CYKEL — Commute Suggestion Service
///
/// Analyses the user's navigation history (stored by FrequentDestinationsService)
/// together with the time of day to suggest the most likely destination.
///
/// Rules:
///   Morning  06:00–10:00  →  suggest the most-visited destination between 06–10 h
///   Evening  16:00–21:00  →  suggest the most-visited destination between 16–21 h
///   Other times           →  suggest the all-time most-visited destination, if any
///
/// To support time-of-day segmentation, this service writes an extended
/// visit log (`cykel_visit_log_v1`) that includes the hour of each visit.

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kVisitLogKey     = 'cykel_visit_log_v1';
const _kMaxLogEntries   = 200;

// ─── Domain ──────────────────────────────────────────────────────────────────

enum SuggestionSlot { morning, evening, anytime }

class CommuteSuggestion {
  const CommuteSuggestion({
    required this.text,
    required this.lat,
    required this.lng,
    required this.slot,
    required this.visitCount,
  });

  final String         text;
  final double         lat;
  final double         lng;
  final SuggestionSlot slot;
  final int            visitCount;
}

class _VisitEntry {
  const _VisitEntry({
    required this.text,
    required this.lat,
    required this.lng,
    required this.hour,
    required this.visitedAt,
  });

  final String   text;
  final double   lat;
  final double   lng;
  final int      hour;         // 0–23
  final DateTime visitedAt;

  Map<String, dynamic> toJson() => {
        'text':      text,
        'lat':       lat,
        'lng':       lng,
        'hour':      hour,
        'visitedAt': visitedAt.toIso8601String(),
      };

  factory _VisitEntry.fromJson(Map<String, dynamic> m) => _VisitEntry(
        text:      m['text'] as String,
        lat:       (m['lat'] as num).toDouble(),
        lng:       (m['lng'] as num).toDouble(),
        hour:      (m['hour'] as num).toInt(),
        visitedAt: DateTime.parse(m['visitedAt'] as String),
      );
}

// ─── Service ─────────────────────────────────────────────────────────────────

class CommuteSuggestionService {
  // Record a timestamped visit.  Call this alongside FrequentDestinationsService.recordVisit.
  Future<void> recordVisit({
    required String text,
    required double lat,
    required double lng,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_kVisitLogKey);
    var log     = <_VisitEntry>[];
    if (raw != null) {
      try {
        final decoded = json.decode(raw) as List;
        log = decoded.map((e) => _VisitEntry.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        log = [];
      }
    }

    log.add(_VisitEntry(
      text:      text,
      lat:       lat,
      lng:       lng,
      hour:      DateTime.now().hour,
      visitedAt: DateTime.now(),
    ));

    // Trim to max entries.
    if (log.length > _kMaxLogEntries) {
      log = log.sublist(log.length - _kMaxLogEntries);
    }

    await prefs.setString(
        _kVisitLogKey, json.encode(log.map((e) => e.toJson()).toList()));
  }

  /// Returns the best suggestion for the current time of day.
  /// Returns null if there is insufficient history (< 2 visits for any dest).
  Future<CommuteSuggestion?> getSuggestion() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_kVisitLogKey);
    if (raw == null) return null;
    List<_VisitEntry> log;
    try {
      final decoded = json.decode(raw) as List;
      log = decoded.map((e) => _VisitEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
    if (log.isEmpty) return null;

    final hour = DateTime.now().hour;
    SuggestionSlot slot;
    List<_VisitEntry> relevant;

    if (hour >= 6 && hour < 10) {
      slot     = SuggestionSlot.morning;
      relevant = log.where((e) => e.hour >= 6 && e.hour < 10).toList();
    } else if (hour >= 16 && hour < 21) {
      slot     = SuggestionSlot.evening;
      relevant = log.where((e) => e.hour >= 16 && e.hour < 21).toList();
    } else {
      slot     = SuggestionSlot.anytime;
      relevant = log;
    }

    if (relevant.isEmpty) relevant = log;

    // Aggregate by proximity bucket (0.001° ≈ 100 m).
    final Map<String, ({int count, String text, double lat, double lng})> buckets = {};
    for (final e in relevant) {
      // Round to 3 decimal places to cluster nearby coords.
      final key = '${(e.lat * 1000).round()}_${(e.lng * 1000).round()}';
      final prev = buckets[key];
      if (prev == null) {
        buckets[key] = (count: 1, text: e.text, lat: e.lat, lng: e.lng);
      } else {
        buckets[key] = (
          count: prev.count + 1,
          text: e.text,
          lat: prev.lat,
          lng: prev.lng,
        );
      }
    }

    if (buckets.isEmpty) return null;

    final top = buckets.values.reduce((a, b) => a.count >= b.count ? a : b);
    // Only suggest if visited at least twice.
    if (top.count < 2) return null;

    return CommuteSuggestion(
      text:       top.text,
      lat:        top.lat,
      lng:        top.lng,
      slot:       slot,
      visitCount: top.count,
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kVisitLogKey);
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final commuteSuggestionServiceProvider =
    Provider<CommuteSuggestionService>((_) => CommuteSuggestionService());

/// Async provider — auto-refreshes whenever the widget tree is rebuilt.
final commuteSuggestionProvider =
    FutureProvider.autoDispose<CommuteSuggestion?>((ref) async {
  return ref.read(commuteSuggestionServiceProvider).getSuggestion();
});
