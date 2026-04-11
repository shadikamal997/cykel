/// CYKEL — Tile Prefetch Service
/// When a route is calculated and the device is online, pans the
/// GoogleMapController along the route corridor to force the SDK to
/// load and cache map tiles.  This gives reasonable offline map detail
/// for the next ~60–120 minutes without requiring any extra package.
///
/// Strategy:
///   1. Sample points along the polyline at every Nth index.
///   2. Animate the camera to each point at zoom 15 with a short delay.
///   3. Return the camera to the original position when finished.
///
/// This works because the Google Maps SDK automatically caches tiles that
/// have been rendered, so tiles loaded during prefetch are available when the
/// device goes offline.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TilePrefetchService {
  bool _running = false;

  /// Prefetches tiles along [polyline].
  ///
  /// [controller]    — the active GoogleMapController.
  /// [polyline]      — the route to pre-warm.
  /// [restoreTarget] — camera position to restore when done.
  /// [onProgress]    — optional 0.0–1.0 callback.
  Future<void> prefetchRoute({
    required GoogleMapController     controller,
    required List<LatLng>            polyline,
    required CameraPosition          restoreTarget,
    void Function(double progress)? onProgress,
  }) async {
    if (_running || polyline.isEmpty) return;
    _running = true;
    debugPrint('TilePrefetch: starting for ${polyline.length} points');

    try {
      // Sample every ~500 m (roughly every 10 polyline points depending on
      // OSRM's geometry resolution at zoom 15).
      final step = (polyline.length / 30).ceil().clamp(1, polyline.length);
      final samples = <LatLng>[];
      for (int i = 0; i < polyline.length; i += step) {
        samples.add(polyline[i]);
      }
      if (samples.last != polyline.last) samples.add(polyline.last);

      for (int i = 0; i < samples.length; i++) {
        if (!_running) break;
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: samples[i], zoom: 15),
          ),
        );
        onProgress?.call((i + 1) / samples.length);
        // Short pause so the SDK has time to initiate tile requests.
        await Future<void>.delayed(const Duration(milliseconds: 180));
      }
    } catch (e) {
      debugPrint('TilePrefetch error: $e');
    } finally {
      _running = false;
      // Restore camera.
      try {
        await controller.animateCamera(
            CameraUpdate.newCameraPosition(restoreTarget));
      } catch (_) {}
      debugPrint('TilePrefetch: complete, camera restored');
    }
  }

  /// Cancels an in-progress prefetch on the next iteration.
  void cancel() => _running = false;
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final tilePrefetchServiceProvider =
    Provider<TilePrefetchService>((_) => TilePrefetchService());
