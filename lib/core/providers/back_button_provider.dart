/// Provider to allow screens to register back button handlers.
/// Used by MapScreen to intercept back button when route card is open.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Callback that returns true if the back button was handled, false otherwise.
typedef BackButtonHandler = Future<bool> Function();

/// Provider that holds the current back button handler (if any).
/// Screens can register a handler when they have internal state to close.
final backButtonHandlerProvider = StateProvider<BackButtonHandler?>((ref) => null);
