/// CYKEL — Notifications Preferences Provider
/// Persists per-category notification toggles + scheduled ride reminder time.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kRideReminders       = 'notif_ride_reminders';
const _kHazardAlerts        = 'notif_hazard_alerts';
const _kMarketplace         = 'notif_marketplace';
const _kMarketing           = 'notif_marketing';
const _kScheduledTimeHour   = 'notif_scheduled_hour';
const _kScheduledTimeMinute = 'notif_scheduled_minute';

class NotificationsState {
  const NotificationsState({
    this.rideReminders = true,
    this.hazardAlerts = true,
    this.marketplace = true,
    this.marketing = false,
    this.scheduledRideTime,     // null = no scheduled reminder
  });

  final bool rideReminders;
  final bool hazardAlerts;
  final bool marketplace;
  final bool marketing;

  /// Daily ride reminder time, e.g. 07:30. Null means disabled.
  final TimeOfDay? scheduledRideTime;

  String get scheduledRideTimeLabel {
    if (scheduledRideTime == null) return 'Off';
    final h = scheduledRideTime!.hour.toString().padLeft(2, '0');
    final m = scheduledRideTime!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  NotificationsState copyWith({
    bool? rideReminders,
    bool? hazardAlerts,
    bool? marketplace,
    bool? marketing,
    TimeOfDay? scheduledRideTime,
    bool clearSchedule = false,
  }) =>
      NotificationsState(
        rideReminders: rideReminders ?? this.rideReminders,
        hazardAlerts: hazardAlerts ?? this.hazardAlerts,
        marketplace: marketplace ?? this.marketplace,
        marketing: marketing ?? this.marketing,
        scheduledRideTime:
            clearSchedule ? null : (scheduledRideTime ?? this.scheduledRideTime),
      );
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier() : super(const NotificationsState()) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final hour   = p.getInt(_kScheduledTimeHour);
    final minute = p.getInt(_kScheduledTimeMinute);
    state = NotificationsState(
      rideReminders: p.getBool(_kRideReminders) ?? true,
      hazardAlerts:  p.getBool(_kHazardAlerts)  ?? true,
      marketplace:   p.getBool(_kMarketplace)   ?? true,
      marketing:     p.getBool(_kMarketing)      ?? false,
      scheduledRideTime: hour != null && minute != null
          ? TimeOfDay(hour: hour, minute: minute)
          : null,
    );
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kRideReminders, state.rideReminders);
    await p.setBool(_kHazardAlerts,  state.hazardAlerts);
    await p.setBool(_kMarketplace,   state.marketplace);
    await p.setBool(_kMarketing,     state.marketing);
    if (state.scheduledRideTime != null) {
      await p.setInt(_kScheduledTimeHour,   state.scheduledRideTime!.hour);
      await p.setInt(_kScheduledTimeMinute, state.scheduledRideTime!.minute);
    } else {
      await p.remove(_kScheduledTimeHour);
      await p.remove(_kScheduledTimeMinute);
    }
  }

  Future<void> setRideReminders(bool v) async {
    state = state.copyWith(rideReminders: v);
    await _save();
  }

  Future<void> setHazardAlerts(bool v) async {
    state = state.copyWith(hazardAlerts: v);
    await _save();
  }

  Future<void> setMarketplace(bool v) async {
    state = state.copyWith(marketplace: v);
    await _save();
  }

  Future<void> setMarketing(bool v) async {
    state = state.copyWith(marketing: v);
    await _save();
  }

  Future<void> setScheduledRideTime(TimeOfDay? time) async {
    if (time == null) {
      state = state.copyWith(clearSchedule: true);
    } else {
      state = state.copyWith(scheduledRideTime: time);
    }
    await _save();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>(
  (_) => NotificationsNotifier(),
);
