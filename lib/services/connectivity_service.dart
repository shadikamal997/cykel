/// CYKEL — Connectivity Service
///
/// Provides a lightweight online/offline check using a DNS lookup via dart:io.
/// No extra package required.
///
/// Usage:
///   final online = await connectivityService.isOnline();

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityService {
  /// Returns true if the device can resolve a known hostname.
  /// Uses the OSRM routing API host as the probe target since that is the
  /// primary network dependency for CYKEL.
  Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup('router.project-osrm.org')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } catch (e) {
      debugPrint('ConnectivityService error: $e');
      return false;
    }
  }
}

final connectivityServiceProvider =
    Provider<ConnectivityService>((ref) => ConnectivityService());
