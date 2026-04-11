/// Persists Home, Work, and custom quick-route addresses via SharedPreferences.

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../discover/data/places_service.dart';

class QuickRoute {
  const QuickRoute({required this.text, required this.lat, required this.lng});
  final String text;
  final double lat;
  final double lng;

  PlaceResult toPlaceResult() =>
      PlaceResult(placeId: 'qr_${lat}_$lng', text: text, lat: lat, lng: lng);

  Map<String, dynamic> toJson() => {'text': text, 'lat': lat, 'lng': lng};

  static QuickRoute fromJson(Map<String, dynamic> m) => QuickRoute(
        text: m['text'] as String,
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
      );
}

// ─── Named custom route ───────────────────────────────────────────────────────

class NamedQuickRoute {
  const NamedQuickRoute({required this.name, required this.route});
  final String name;
  final QuickRoute route;

  Map<String, dynamic> toJson() =>
      {'name': name, 'route': route.toJson()};

  static NamedQuickRoute fromJson(Map<String, dynamic> m) => NamedQuickRoute(
        name: m['name'] as String,
        route: QuickRoute.fromJson(m['route'] as Map<String, dynamic>),
      );
}

// ─── State ────────────────────────────────────────────────────────────────────

class QuickRoutesState {
  const QuickRoutesState({
    this.home,
    this.work,
    this.custom = const [],
  });

  final QuickRoute? home;
  final QuickRoute? work;
  final List<NamedQuickRoute> custom;

  QuickRoutesState copyWith({
    QuickRoute? home,
    QuickRoute? work,
    List<NamedQuickRoute>? custom,
    bool clearHome = false,
    bool clearWork = false,
  }) =>
      QuickRoutesState(
        home: clearHome ? null : (home ?? this.home),
        work: clearWork ? null : (work ?? this.work),
        custom: custom ?? this.custom,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class QuickRoutesNotifier extends StateNotifier<QuickRoutesState> {
  QuickRoutesNotifier() : super(const QuickRoutesState()) {
    _load();
  }

  static const _homeKey = 'cykel_qr_home_v1';
  static const _workKey = 'cykel_qr_work_v1';
  static const _customKey = 'cykel_qr_custom_v1';

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final h = p.getString(_homeKey);
    final w = p.getString(_workKey);
    final c = p.getString(_customKey);
    state = QuickRoutesState(
      home: h != null
          ? QuickRoute.fromJson(json.decode(h) as Map<String, dynamic>)
          : null,
      work: w != null
          ? QuickRoute.fromJson(json.decode(w) as Map<String, dynamic>)
          : null,
      custom: c != null
          ? (json.decode(c) as List)
              .map((e) => NamedQuickRoute.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Future<void> setHome(QuickRoute r) async {
    state = state.copyWith(home: r);
    final p = await SharedPreferences.getInstance();
    await p.setString(_homeKey, json.encode(r.toJson()));
  }

  Future<void> setWork(QuickRoute r) async {
    state = state.copyWith(work: r);
    final p = await SharedPreferences.getInstance();
    await p.setString(_workKey, json.encode(r.toJson()));
  }

  Future<void> clearHome() async {
    state = state.copyWith(clearHome: true);
    final p = await SharedPreferences.getInstance();
    await p.remove(_homeKey);
  }

  Future<void> clearWork() async {
    state = state.copyWith(clearWork: true);
    final p = await SharedPreferences.getInstance();
    await p.remove(_workKey);
  }

  Future<void> addCustom(NamedQuickRoute named) async {
    final updated = [...state.custom, named];
    state = state.copyWith(custom: updated);
    await _saveCustom(updated);
  }

  Future<void> removeCustom(int index) async {
    final updated = [...state.custom]..removeAt(index);
    state = state.copyWith(custom: updated);
    await _saveCustom(updated);
  }

  Future<void> _saveCustom(List<NamedQuickRoute> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_customKey,
        json.encode(list.map((e) => e.toJson()).toList()));
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final quickRoutesProvider =
    StateNotifierProvider<QuickRoutesNotifier, QuickRoutesState>(
  (ref) => QuickRoutesNotifier(),
);
