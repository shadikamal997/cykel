/// CYKEL — Notification Service (FCM)
/// Handles push notification setup, token persistence, and routing.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  /// Stream subscriptions to cancel on dispose
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

  /// Emits [RemoteMessage] for every foreground notification.
  /// Listen in your app shell (e.g. app.dart) to show an in-app banner/snackbar.
  final foregroundMessages =
      StreamController<RemoteMessage>.broadcast();

  /// Emits [RemoteMessage] when the user taps a notification while the app is
  /// in the background/terminated.  Listen to drive navigation.
  final navigationEvents =
      StreamController<RemoteMessage>.broadcast();

  // ─── Notification Channels (Phase 1) ─────────────────────────────────────

  static const _rentalChannel = AndroidNotificationChannel(
    'rental_updates',
    'Rental Updates',
    description: 'Rental requests, approvals, and reminders',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  static const _eventChannel = AndroidNotificationChannel(
    'events',
    'Event Updates',
    description: 'Event cancellations and start reminders',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  static const _theftChannel = AndroidNotificationChannel(
    'theft_alerts',
    'Theft Alerts',
    description: 'Community alerts for stolen bikes',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  static const _hazardChannel = AndroidNotificationChannel(
    'hazard_warnings',
    'Hazard Warnings',
    description: 'Road hazards on your saved routes',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  static const _securityChannel = AndroidNotificationChannel(
    'account_security',
    'Security Alerts',
    description: 'Login from new devices and security events',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  static const _subscriptionChannel = AndroidNotificationChannel(
    'subscription_alerts',
    'Subscription Alerts',
    description: 'Expiring subscriptions and renewals',
    importance: Importance.defaultImportance,
    playSound: true,
    enableVibration: false,
  );

  // Phase 2: Engagement channels
  static const _socialChannel = AndroidNotificationChannel(
    'social_updates',
    'Social Updates',
    description: 'Follows, friend requests, and shared rides',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  static const _gamificationChannel = AndroidNotificationChannel(
    'gamification',
    'Achievements & Progress',
    description: 'Badges, achievements, and leaderboard updates',
    importance: Importance.defaultImportance,
    playSound: true,
    enableVibration: false,
  );

  // Phase 3: Polish channels
  static const _communityChannel = AndroidNotificationChannel(
    'community_updates',
    'Community & Groups',
    description: 'Group ride invitations and buddy matches',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  static const _systemChannel = AndroidNotificationChannel(
    'system_updates',
    'System & Maintenance',
    description: 'App updates, maintenance notices, and announcements',
    importance: Importance.defaultImportance,
    playSound: true,
    enableVibration: false,
  );

  // Phase 4: Enhanced experience channels
  static const _weatherChannel = AndroidNotificationChannel(
    'weather_alerts',
    'Weather & Conditions',
    description: 'Weather conditions for planned rides',
    importance: Importance.defaultImportance,
    playSound: true,
    enableVibration: false,
  );

  static const _statsChannel = AndroidNotificationChannel(
    'ride_stats',
    'Statistics & Progress',
    description: 'Weekly and monthly ride summaries',
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
  );

  static const _localEventsChannel = AndroidNotificationChannel(
    'local_events',
    'Local Events',
    description: 'Nearby cycling events and meetups',
    importance: Importance.defaultImportance,
    playSound: true,
    enableVibration: false,
  );

  static const _milestonesChannel = AndroidNotificationChannel(
    'milestones',
    'Celebrations',
    description: 'Distance, carbon savings, and streak celebrations',
    importance: Importance.defaultImportance,
    playSound: true,
    enableVibration: true,
  );

  // ─── Init ─────────────────────────────────────────────────────────────────

  /// Request permission and wire up FCM listeners.
  /// Call once from [main()] after Firebase.initializeApp().
  Future<void> init() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // ── Create notification channels (Android only) ──────────────────────
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(_rentalChannel);
      await androidPlugin?.createNotificationChannel(_eventChannel);
      await androidPlugin?.createNotificationChannel(_theftChannel);
      await androidPlugin?.createNotificationChannel(_hazardChannel);
      await androidPlugin?.createNotificationChannel(_securityChannel);
      await androidPlugin?.createNotificationChannel(_subscriptionChannel);
      await androidPlugin?.createNotificationChannel(_socialChannel);
      await androidPlugin?.createNotificationChannel(_gamificationChannel);
      await androidPlugin?.createNotificationChannel(_communityChannel);
      await androidPlugin?.createNotificationChannel(_systemChannel);
      await androidPlugin?.createNotificationChannel(_weatherChannel);
      await androidPlugin?.createNotificationChannel(_statsChannel);
      await androidPlugin?.createNotificationChannel(_localEventsChannel);
      await androidPlugin?.createNotificationChannel(_milestonesChannel);

      debugPrint('[FCM] Created 14 notification channels');
    }

    // ── Save token to Firestore ───────────────────────────────────────────
    final token = await _messaging.getToken();
    if (token != null) await _saveToken(token);

    // Refresh listener — token may rotate after reinstall / data-clear.
    _tokenRefreshSub = _messaging.onTokenRefresh.listen(_saveToken);

    // ── Foreground messages ───────────────────────────────────────────────
    _onMessageSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // ── Notification tap (app in background) ─────────────────────────────
    _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // ── Notification tap (app was terminated) ────────────────────────────
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _onMessageOpenedApp(initial);
  }

  // ─── Token Persistence ────────────────────────────────────────────────────

  /// Writes the FCM token to `users/{uid}` in Firestore.
  /// Silently skips if no user is signed in yet (token saved on next app open).
  Future<void> _saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FCM] Token saved for $uid');
    } catch (e) {
      debugPrint('[FCM] Token save failed: $e');
    }
  }

  // ─── Message Handlers ─────────────────────────────────────────────────────

  /// Push to [foregroundMessages] stream — app shell can show a banner.
  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground: ${message.notification?.title}');
    foregroundMessages.add(message);
  }

  /// Push to [navigationEvents] stream — app shell drives navigation.
  ///
  /// Consumers should switch on `message.data['type']` to decide where to go:
  ///   'chat_message' → navigate to chats/{chatId}
  ///   'provider_approved' → navigate to provider dashboard
  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] Opened from notification: ${message.data}');
    navigationEvents.add(message);
  }

  // ─── Cleanup ──────────────────────────────────────────────────────────────

  void dispose() {
    // Cancel all stream subscriptions to prevent memory leaks
    _tokenRefreshSub?.cancel();
    _onMessageSub?.cancel();
    _onMessageOpenedSub?.cancel();
    foregroundMessages.close();
    navigationEvents.close();
  }
}

/// Top-level background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised when this runs (firebase-messaging boots it).
  debugPrint('[FCM] Background message: ${message.notification?.title}');
}
