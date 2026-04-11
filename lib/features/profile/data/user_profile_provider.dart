/// CYKEL — User Profile Provider
/// Manages extended user data including home/work locations, battery level, etc.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../domain/user_profile.dart';

const _kUserProfileKey = 'user_profile';

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>(
  (ref) => UserProfileNotifier(),
);

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier() : super(const UserProfile()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kUserProfileKey);
    if (saved != null) {
      try {
        final json = jsonDecode(saved) as Map<String, dynamic>;
        state = UserProfile.fromJson(json);
      } catch (e) {
        // Invalid data, use defaults
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(state.toJson());
    await prefs.setString(_kUserProfileKey, json);
  }

  Future<void> setHomeLocation(LatLng location) async {
    state = state.copyWith(homeLocation: location);
    await _save();
  }

  Future<void> setWorkLocation(LatLng location) async {
    state = state.copyWith(workLocation: location);
    await _save();
  }

  Future<void> setBatteryLevel(int level) async {
    state = state.copyWith(batteryLevel: level.clamp(0, 100));
    await _save();
  }

  Future<void> updateTotalDistance(double additionalKm) async {
    state = state.copyWith(totalDistanceKm: state.totalDistanceKm + additionalKm);
    await _save();
  }

  Future<void> resetMaintenanceCounter() async {
    state = state.copyWith(lastMaintenanceKm: state.totalDistanceKm);
    await _save();
  }

  Future<void> setPlan(CykelPlan plan) async {
    state = state.copyWith(plan: plan);
    await _save();
  }

  Future<void> updateCommuterAddresses({
    String? homeAddress,
    String? workAddress,
  }) async {
    state = state.copyWith(
      homeAddress: homeAddress,
      workAddress: workAddress,
    );
    await _save();
  }
}