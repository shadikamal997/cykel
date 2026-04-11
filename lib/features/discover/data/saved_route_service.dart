/// CYKEL — Saved Routes Service
/// CRUD for user-saved routes, persisted via SharedPreferences.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/saved_route.dart';

const _kSavedRoutesKey = 'saved_routes_v1';

class SavedRoutesNotifier extends StateNotifier<List<SavedRoute>> {
  SavedRoutesNotifier() : super(const []) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSavedRoutesKey);
    if (raw != null) {
      try {
        state = SavedRoute.decodeList(raw);
      } catch (_) {
        // Corrupt data — start fresh.
        state = const [];
      }
    }
  }

  /// Save [route]. Replaces any existing entry with the same destination.
  Future<void> save(SavedRoute route) async {
    final updated = [
      route,
      ...state.where((r) => r.id != route.id),
    ]..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    state = updated;
    await _persist();
  }

  Future<void> delete(String id) async {
    state = state.where((r) => r.id != id).toList();
    await _persist();
  }

  bool isSaved(String id) => state.any((r) => r.id == id);

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSavedRoutesKey, SavedRoute.encodeList(state));
  }
}

final savedRoutesProvider =
    StateNotifierProvider<SavedRoutesNotifier, List<SavedRoute>>(
  (ref) => SavedRoutesNotifier(),
);
