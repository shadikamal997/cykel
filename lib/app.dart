/// CYKEL — Root App Widget

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'services/auto_theme_service.dart';
import 'services/notification_service.dart';
import 'services/subscription_providers.dart';
import 'services/biometric_service.dart';

class CykelApp extends ConsumerStatefulWidget {
  const CykelApp({super.key});

  @override
  ConsumerState<CykelApp> createState() => _CykelAppState();
}

class _CykelAppState extends ConsumerState<CykelApp> with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  late final StreamSubscription<RemoteMessage> _foregroundSub;
  late final StreamSubscription<RemoteMessage> _navigationSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final svc = NotificationService.instance;
    _foregroundSub = svc.foregroundMessages.stream.listen(_showBanner);
    _navigationSub = svc.navigationEvents.stream.listen(_handleNavigation);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _foregroundSub.cancel();
    _navigationSub.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Require biometric authentication when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _checkBiometricAuth();
    }
  }

  Future<void> _checkBiometricAuth() async {
    final shouldAuth = await BiometricService.instance.shouldAuthenticate();
    if (!shouldAuth) return;

    final authenticated = await BiometricService.instance.authenticate(
      localizedReason: 'Authenticate to unlock CYKEL',
    );

    if (!authenticated && mounted) {
      // Authentication failed - could show error or exit app
      // For now, show a snackbar
      _scaffoldKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Authentication required to access CYKEL'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Show an in-app snackbar banner for foreground notifications.
  void _showBanner(RemoteMessage message) {
    final title = message.notification?.title ?? 'CYKEL';
    final body = message.notification?.body ?? '';
    _scaffoldKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_outlined,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                body.isNotEmpty ? '$title\n$body' : title,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryDark,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  /// Navigate to the relevant screen when a notification is tapped.
  void _handleNavigation(RemoteMessage message) {
    final router = ref.read(routerProvider);
    final type = message.data['type'] as String?;
    
    switch (type) {
      case 'chat_message':
        router.go(AppRoutes.marketplace);
        break;
      case 'provider_approved':
      case 'badge_earned':
        router.go(AppRoutes.profile);
        break;
      case 'event_upcoming':
      case 'event_reminder':
        router.go(AppRoutes.discover);
        break;
      case 'ride_shared':
      case 'activity_goal':
        router.go(AppRoutes.activity);
        break;
      case 'marketplace_sale':
      case 'listing_sold':
        router.go(AppRoutes.marketplace);
        break;
      default:
        // Unknown type or no type — don't navigate
        debugPrint('[Navigation] Unknown notification type: $type');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(effectiveThemeModeProvider);

    // Kick off IAP store initialisation (fire-and-forget).
    ref.watch(purchaseInitProvider);

    return MaterialApp.router(
      scaffoldMessengerKey: _scaffoldKey,
      title: 'Cykel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
