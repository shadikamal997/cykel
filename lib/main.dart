/// CYKEL — App Entry Point
///
/// ⚠️  Firebase Setup Required Before Running:
///
///   1. Create a Firebase project at https://console.firebase.google.com
///   2. Install CLI:  dart pub global activate flutterfire_cli
///   3. Configure:    flutterfire configure
///   4. Uncomment the firebase_options import + DefaultFirebaseOptions below
///
/// After setup the app boots normally.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'firebase_options.dart';

import 'services/notification_service.dart';
import 'services/remote_config_service.dart';
import 'core/security/app_check_service.dart';
import 'app.dart';
import 'core/theme/app_colors.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable debug logging in release mode for better performance
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize Firebase Performance Monitoring
    final FirebasePerformance performance = FirebasePerformance.instance;
    unawaited(performance.setPerformanceCollectionEnabled(true));
    if (kDebugMode) {
      debugPrint('✅ Firebase Performance Monitoring enabled');
    }

    // Initialize Firebase Analytics
    final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    await analytics.setAnalyticsCollectionEnabled(true);
    if (kDebugMode) {
      debugPrint('✅ Firebase Analytics enabled');
    }

    // Initialize Firebase Crashlytics
    final FirebaseCrashlytics crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(true);

    // Pass all uncaught Flutter errors to Crashlytics
    FlutterError.onError = crashlytics.recordFlutterError;

    // Pass all uncaught async errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };

    if (kDebugMode) {
      debugPrint('✅ Firebase Crashlytics enabled');
    }

    // Initialize App Check for security
    if (kDebugMode) {
      await AppCheckService.initializeDebug();
    } else {
      await AppCheckService.initialize();
    }

    // Initialize Remote Config for feature flags
    await RemoteConfigService.instance.initialize();

    // Notification init is non-critical for startup — run after app is visible
    unawaited(NotificationService.instance.init());
    firebaseReady = true;
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
    firebaseReady = false;
  }

  // Validate environment configuration (API keys, etc.)
  if (firebaseReady && !AppConfig.isValid) {
    debugPrint('⚠️  Warning: Google Maps API key not configured.');
    debugPrint('   Provide via: flutter run --dart-define=GOOGLE_MAPS_API_KEY=your_key');
  }

  runApp(
    ProviderScope(
      child: firebaseReady ? const CykelApp() : const _FirebaseSetupScreen(),
    ),
  );
}

// ─── Setup guide shown until Firebase is configured ──────────────────────────

class _FirebaseSetupScreen extends StatelessWidget {
  const _FirebaseSetupScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🚲', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 24),
                const Text(
                  'CYKEL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The Digital OS for Urban Cycling',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                _step('1', 'Create Firebase project',
                    'console.firebase.google.com'),
                const SizedBox(height: 12),
                _step('2', 'Install FlutterFire CLI',
                    'dart pub global activate flutterfire_cli'),
                const SizedBox(height: 12),
                _step('3', 'Configure', 'flutterfire configure'),
                const SizedBox(height: 12),
                _step('4', 'Uncomment options in main.dart',
                    'DefaultFirebaseOptions.currentPlatform'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _step(String n, String title, String cmd) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primaryDark,
              shape: BoxShape.circle,
            ),
            child: Text(n,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(80),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(cmd,
                      style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontFamily: 'monospace')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
