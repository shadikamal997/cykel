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

// Phase 1: Critical notifications
const _kRentalUpdates       = 'notif_rental_updates';
const _kEventUpdates        = 'notif_event_updates';
const _kTheftAlerts         = 'notif_theft_alerts';
const _kSecurityAlerts      = 'notif_security_alerts';
const _kSubscriptionAlerts  = 'notif_subscription_alerts';

// Phase 2: Engagement notifications
const _kSocialUpdates       = 'notif_social_updates';
const _kGamification        = 'notif_gamification';

// Phase 3: Polish notifications
const _kCommunityUpdates    = 'notif_community_updates';
const _kSystemUpdates       = 'notif_system_updates';

// Phase 4: Enhanced experience notifications
const _kWeatherAlerts       = 'notif_weather_alerts';
const _kRideStats           = 'notif_ride_stats';
const _kLocalEvents         = 'notif_local_events';
const _kMilestones          = 'notif_milestones';

class NotificationsState {
  const NotificationsState({
    this.rideReminders = true,
    this.hazardAlerts = true,
    this.marketplace = true,
    this.marketing = false,
    this.scheduledRideTime,     // null = no scheduled reminder
    // Phase 1: Critical notifications
    this.rentalUpdates = true,
    this.eventUpdates = true,
    this.theftAlerts = true,
    this.securityAlerts = true,
    this.subscriptionAlerts = true,
    // Phase 2: Engagement notifications
    this.socialUpdates = true,
    this.gamification = true,
    // Phase 3: Polish notifications
    this.communityUpdates = true,
    this.systemUpdates = true,
    // Phase 4: Enhanced experience notifications
    this.weatherAlerts = true,
    this.rideStats = true,
    this.localEvents = true,
    this.milestones = true,
  });

  final bool rideReminders;
  final bool hazardAlerts;
  final bool marketplace;
  final bool marketing;
  
  // Phase 1: Critical notifications
  final bool rentalUpdates;      // Rental requests, reminders
  final bool eventUpdates;       // Event cancellations, reminders
  final bool theftAlerts;        // Community theft alerts
  final bool securityAlerts;     // Login from unknown device
  final bool subscriptionAlerts; // Expiring subscriptions
  
  // Phase 2: Engagement notifications
  final bool socialUpdates;      // Follows, friend requests, shared rides
  final bool gamification;       // Badges, achievements, leaderboard
  
  // Phase 3: Polish notifications
  final bool communityUpdates;   // Group ride invitations, buddy matches
  final bool systemUpdates;      // App updates, maintenance notices
  
  // Phase 4: Enhanced experience notifications
  final bool weatherAlerts;      // Weather conditions for planned rides
  final bool rideStats;          // Weekly/monthly ride summaries
  final bool localEvents;        // Nearby cycling events and meetups
  final bool milestones;         // Achievement milestones and celebrations

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
    bool? rentalUpdates,
    bool? eventUpdates,
    bool? theftAlerts,
    bool? securityAlerts,
    bool? subscriptionAlerts,
    bool? socialUpdates,
    bool? gamification,
    bool? communityUpdates,
    bool? systemUpdates,
    bool? weatherAlerts,
    bool? rideStats,
    bool? localEvents,
    bool? milestones,
    TimeOfDay? scheduledRideTime,
    bool clearSchedule = false,
  }) =>
      NotificationsState(
        rideReminders: rideReminders ?? this.rideReminders,
        hazardAlerts: hazardAlerts ?? this.hazardAlerts,
        marketplace: marketplace ?? this.marketplace,
        marketing: marketing ?? this.marketing,
        rentalUpdates: rentalUpdates ?? this.rentalUpdates,
        eventUpdates: eventUpdates ?? this.eventUpdates,
        theftAlerts: theftAlerts ?? this.theftAlerts,
        securityAlerts: securityAlerts ?? this.securityAlerts,
        subscriptionAlerts: subscriptionAlerts ?? this.subscriptionAlerts,
        socialUpdates: socialUpdates ?? this.socialUpdates,
        gamification: gamification ?? this.gamification,
        communityUpdates: communityUpdates ?? this.communityUpdates,
        systemUpdates: systemUpdates ?? this.systemUpdates,
        weatherAlerts: weatherAlerts ?? this.weatherAlerts,
        rideStats: rideStats ?? this.rideStats,
        localEvents: localEvents ?? this.localEvents,
        milestones: milestones ?? this.milestones,
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
      rentalUpdates: p.getBool(_kRentalUpdates) ?? true,
      eventUpdates: p.getBool(_kEventUpdates) ?? true,
      theftAlerts: p.getBool(_kTheftAlerts) ?? true,
      securityAlerts: p.getBool(_kSecurityAlerts) ?? true,
      subscriptionAlerts: p.getBool(_kSubscriptionAlerts) ?? true,
      socialUpdates: p.getBool(_kSocialUpdates) ?? true,
      gamification: p.getBool(_kGamification) ?? true,
      communityUpdates: p.getBool(_kCommunityUpdates) ?? true,
      systemUpdates: p.getBool(_kSystemUpdates) ?? true,
      weatherAlerts: p.getBool(_kWeatherAlerts) ?? true,
      rideStats: p.getBool(_kRideStats) ?? true,
      localEvents: p.getBool(_kLocalEvents) ?? true,
      milestones: p.getBool(_kMilestones) ?? true,
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
    await p.setBool(_kRentalUpdates, state.rentalUpdates);
    await p.setBool(_kEventUpdates, state.eventUpdates);
    await p.setBool(_kTheftAlerts, state.theftAlerts);
    await p.setBool(_kSecurityAlerts, state.securityAlerts);
    await p.setBool(_kSubscriptionAlerts, state.subscriptionAlerts);
    await p.setBool(_kSocialUpdates, state.socialUpdates);
    await p.setBool(_kGamification, state.gamification);
    await p.setBool(_kCommunityUpdates, state.communityUpdates);
    await p.setBool(_kSystemUpdates, state.systemUpdates);
    await p.setBool(_kWeatherAlerts, state.weatherAlerts);
    await p.setBool(_kRideStats, state.rideStats);
    await p.setBool(_kLocalEvents, state.localEvents);
    await p.setBool(_kMilestones, state.milestones);
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

  // Phase 1: New setters
  Future<void> setRentalUpdates(bool v) async {
    state = state.copyWith(rentalUpdates: v);
    await _save();
  }

  Future<void> setEventUpdates(bool v) async {
    state = state.copyWith(eventUpdates: v);
    await _save();
  }

  Future<void> setTheftAlerts(bool v) async {
    state = state.copyWith(theftAlerts: v);
    await _save();
  }

  Future<void> setSecurityAlerts(bool v) async {
    state = state.copyWith(securityAlerts: v);
    await _save();
  }

  Future<void> setSubscriptionAlerts(bool v) async {
    state = state.copyWith(subscriptionAlerts: v);
    await _save();
  }

  // Phase 2: New setters
  Future<void> setSocialUpdates(bool v) async {
    state = state.copyWith(socialUpdates: v);
    await _save();
  }

  Future<void> setGamification(bool v) async {
    state = state.copyWith(gamification: v);
    await _save();
  }

  // Phase 3: New setters
  Future<void> setCommunityUpdates(bool v) async {
    state = state.copyWith(communityUpdates: v);
    await _save();
  }

  Future<void> setSystemUpdates(bool v) async {
    state = state.copyWith(systemUpdates: v);
    await _save();
  }

  // Phase 4: New setters
  Future<void> setWeatherAlerts(bool v) async {
    state = state.copyWith(weatherAlerts: v);
    await _save();
  }

  Future<void> setRideStats(bool v) async {
    state = state.copyWith(rideStats: v);
    await _save();
  }

  Future<void> setLocalEvents(bool v) async {
    state = state.copyWith(localEvents: v);
    await _save();
  }

  Future<void> setMilestones(bool v) async {
    state = state.copyWith(milestones: v);
    await _save();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>(
  (_) => NotificationsNotifier(),
);
