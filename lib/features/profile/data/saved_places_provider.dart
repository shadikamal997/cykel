/// CYKEL — Saved Places Provider
/// Stores home, work, and any number of custom named places in SharedPreferences.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kHomeAddress = 'saved_place_home';
const _kWorkAddress = 'saved_place_work';
const _kCustomPlaces = 'saved_place_custom';

// ─── Custom Place model ───────────────────────────────────────────────────────

class CustomPlace {
  const CustomPlace({required this.name, required this.address});

  final String name;
  final String address;

  Map<String, String> toJson() => {'name': name, 'address': address};

  factory CustomPlace.fromJson(Map<String, dynamic> j) =>
      CustomPlace(name: j['name'] as String, address: j['address'] as String);
}

// ─── State ────────────────────────────────────────────────────────────────────

class SavedPlacesState {
  const SavedPlacesState({
    this.homeAddress,
    this.workAddress,
    this.customPlaces = const [],
  });

  final String? homeAddress;
  final String? workAddress;
  final List<CustomPlace> customPlaces;

  SavedPlacesState copyWith({
    String? homeAddress,
    String? workAddress,
    List<CustomPlace>? customPlaces,
    bool clearHome = false,
    bool clearWork = false,
  }) =>
      SavedPlacesState(
        homeAddress: clearHome ? null : (homeAddress ?? this.homeAddress),
        workAddress: clearWork ? null : (workAddress ?? this.workAddress),
        customPlaces: customPlaces ?? this.customPlaces,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class SavedPlacesNotifier extends StateNotifier<SavedPlacesState> {
  SavedPlacesNotifier() : super(const SavedPlacesState()) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kCustomPlaces);
    final custom = raw != null
        ? (jsonDecode(raw) as List)
            .map((e) => CustomPlace.fromJson(e as Map<String, dynamic>))
            .toList()
        : <CustomPlace>[];
    state = SavedPlacesState(
      homeAddress: p.getString(_kHomeAddress),
      workAddress: p.getString(_kWorkAddress),
      customPlaces: custom,
    );
  }

  // ── Home / Work ───────────────────────────────────────────────────────────

  Future<void> setHome(String address) async {
    state = state.copyWith(homeAddress: address);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kHomeAddress, address);
  }

  Future<void> setWork(String address) async {
    state = state.copyWith(workAddress: address);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kWorkAddress, address);
  }

  Future<void> clearHome() async {
    state = state.copyWith(clearHome: true);
    final p = await SharedPreferences.getInstance();
    await p.remove(_kHomeAddress);
  }

  Future<void> clearWork() async {
    state = state.copyWith(clearWork: true);
    final p = await SharedPreferences.getInstance();
    await p.remove(_kWorkAddress);
  }

  // ── Custom places ─────────────────────────────────────────────────────────

  Future<void> addCustomPlace(String name, String address) async {
    final updated = [...state.customPlaces, CustomPlace(name: name, address: address)];
    state = state.copyWith(customPlaces: updated);
    await _saveCustom(updated);
  }

  Future<void> removeCustomPlace(int index) async {
    final updated = [...state.customPlaces]..removeAt(index);
    state = state.copyWith(customPlaces: updated);
    await _saveCustom(updated);
  }

  Future<void> _saveCustom(List<CustomPlace> places) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _kCustomPlaces, jsonEncode(places.map((e) => e.toJson()).toList()));
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final savedPlacesProvider =
    StateNotifierProvider<SavedPlacesNotifier, SavedPlacesState>(
  (_) => SavedPlacesNotifier(),
);
