/// CYKEL — Notification Service (FCM)
/// Handles push notification setup, token persistence, and routing.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;

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

  // ─── Init ─────────────────────────────────────────────────────────────────

  /// Request permission and wire up FCM listeners.
  /// Call once from [main()] after Firebase.initializeApp().
  Future<void> init() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

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
