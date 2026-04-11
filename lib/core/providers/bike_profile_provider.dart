/// CYKEL — Bike Profile Provider
/// Persists the selected bike profile across app restarts.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/discover/domain/bike_profile.dart';

const _kBikeProfileKey = 'bike_profile';

final bikeProfileProvider =
    StateNotifierProvider<BikeProfileNotifier, BikeProfile>(
  (ref) => BikeProfileNotifier(),
);

class BikeProfileNotifier extends StateNotifier<BikeProfile> {
  BikeProfileNotifier() : super(BikeProfile.city) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kBikeProfileKey);
    if (saved != null) {
      state = BikeProfile.values.firstWhere(
        (p) => p.persistKey == saved,
        orElse: () => BikeProfile.city,
      );
    }
  }

  Future<void> setProfile(BikeProfile profile) async {
    state = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBikeProfileKey, profile.persistKey);
  }
}
