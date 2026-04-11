// lib/services/navigation_notification_service.dart
//
// Manages an Android foreground service that keeps navigation running
// when the screen is locked or the app is backgrounded.
// On iOS this is a no-op — background audio via flutter_tts handles it natively.
//
// Usage:
//   navigationNotificationService.setStopCallback(_stopNavigation);
//   await navigationNotificationService.init();
//   await navigationNotificationService.startNavigation('CYKEL', step, dist);
//   await navigationNotificationService.updateStep(step, dist);
//   await navigationNotificationService.stop();

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NavigationNotificationService {
  NavigationNotificationService._();

  static const int _kNotifId = 888;
  static const String _kChannelId = 'cykel_navigation';
  static const String _kChannelName = 'Navigation';
  static const String _kChannelDesc = 'Turn-by-turn guidance while cycling';
  static const String _kStopActionId = 'stop_nav';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Callback invoked when the user taps "Stop navigation" in the notification.
  VoidCallback? _onStop;

  void setStopCallback(VoidCallback cb) => _onStop = cb;
  void clearStopCallback() => _onStop = null;

  // ─── Initialise (call once before first start) ──────────────────────────────
  Future<void> init() async {
    if (_initialized) return;
    if (!Platform.isAndroid) {
      _initialized = true;
      return;
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.actionId == _kStopActionId) {
          _onStop?.call();
        }
      },
    );

    // Create the notification channel (no-op if it already exists).
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _kChannelId,
        _kChannelName,
        description: _kChannelDesc,
        importance: Importance.low, // silent — no sound/vibration
        playSound: false,
        enableVibration: false,
        showBadge: false,
      ),
    );

    _initialized = true;
  }

  // ─── Build notification details with Stop action button ────────────────────
  AndroidNotificationDetails _buildDetails({String stopLabel = 'Stop navigation'}) {
    return AndroidNotificationDetails(
      _kChannelId,
      _kChannelName,
      channelDescription: _kChannelDesc,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      playSound: false,
      enableVibration: false,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.navigation,
      // "Stop navigation" action button shown on the persistent notification.
      actions: [
        AndroidNotificationAction(
          _kStopActionId,
          stopLabel,
          cancelNotification: true,
          showsUserInterface: true,
        ),
      ],
    );
  }

  // ─── Start foreground service ───────────────────────────────────────────────
  Future<void> startNavigation(
    String appName,
    String instruction,
    String distanceLabel,
  ) async {
    if (!Platform.isAndroid) return;
    if (!_initialized) await init();

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.startForegroundService(
      _kNotifId,
      appName,
      '$instruction  ·  $distanceLabel',
      notificationDetails: _buildDetails(),
      startType: AndroidServiceStartType.startSticky,
      foregroundServiceTypes: {
        AndroidServiceForegroundType.foregroundServiceTypeLocation,
      },
    );
  }

  // ─── Update the current step (called on every step advance) ─────────────────
  Future<void> updateStep(String instruction, String distanceLabel) async {
    if (!Platform.isAndroid) return;
    if (!_initialized) return;

    await _plugin.show(
      _kNotifId,
      'CYKEL',
      '$instruction  ·  $distanceLabel',
      NotificationDetails(android: _buildDetails()),
    );
  }

  // ─── Stop foreground service ────────────────────────────────────────────────
  Future<void> stop() async {
    if (!Platform.isAndroid) return;
    if (!_initialized) return;

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.stopForegroundService();
    await _plugin.cancel(_kNotifId);
  }
}

// Global singleton — import and use directly anywhere in the app.
final navigationNotificationService = NavigationNotificationService._();


