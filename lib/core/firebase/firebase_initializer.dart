/// CYKEL — Firebase Initializer
///
/// ⚠️  IMPORTANT: Before running the app, you MUST:
///
/// 1. Install the FlutterFire CLI:
///    dart pub global activate flutterfire_cli
///
/// 2. Run from the project root:
///    flutterfire configure --project=<your-firebase-project-id>
///
/// This generates lib/firebase_options.dart which is gitignored.
///
/// Until then, this file provides a clear error message.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

// GENERATED FILE — run `flutterfire configure` to create this
// import '../../firebase_options.dart';

class FirebaseInitializer {
  FirebaseInitializer._();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      // Replace this with the generated firebase_options.dart import above
      // and use: options: DefaultFirebaseOptions.currentPlatform
      await Firebase.initializeApp();
      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        print(
          '\n'
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
          '  CYKEL — Firebase Setup Required\n'
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
          '  Run: flutterfire configure\n'
          '  Then uncomment the import in firebase_initializer.dart\n'
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n',
        );
      }
      rethrow;
    }
  }
}
