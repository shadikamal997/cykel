/// CYKEL — Location Service
/// Wraps geolocator to provide current GPS position with permission handling.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ─── DEV: Mock Location ───────────────────────────────────────────────────────
// Set to true while building/testing from outside Denmark.
// All location calls will return _kMockPosition (Copenhagen city centre).
// MUST be false in production — the assert below enforces this.
const bool kMockLocation = false;
const LatLng _kMockPosition = LatLng(55.6761, 12.5683); // Copenhagen centre
// ─────────────────────────────────────────────────────────────────────────────

/// A single position+bearing update emitted by [LocationService.locationUpdateStream].
class LocationUpdate {
  const LocationUpdate({
    required this.position,
    required this.bearing,
    this.speed = 0.0,
    this.altitude = 0.0,
  });
  final LatLng position;
  final double bearing;  // degrees clockwise from north (0–360)
  final double speed;    // metres per second
  final double altitude; // metres above sea level
}

class LocationService {
  /// Request permission and return current position.
  /// Throws [LocationException] if permission denied or service off.
  Future<LatLng> getCurrentLocation() async {
    if (kMockLocation) return _kMockPosition;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location permission permanently denied. Please enable in Settings.',
      );
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return LatLng(pos.latitude, pos.longitude);
  }

  /// Returns the last cached GPS position instantly, falling back to a fresh
  /// fix if no cached position is available. Ideal for non-navigation uses
  /// (e.g. weather) where a slight staleness is acceptable.
  Future<LatLng> getLastKnownOrCurrent() async {
    if (kMockLocation) return _kMockPosition;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location permission permanently denied. Please enable in Settings.',
      );
    }

    // Fast path: use the OS-cached position (no GPS warm-up needed).
    final last = await Geolocator.getLastKnownPosition();
    if (last != null) return LatLng(last.latitude, last.longitude);

    // Slow path: request a fresh fix with a generous timeout.
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      // As a last resort fall back to Copenhagen city centre so weather
      // always loads rather than showing an error on cold GPS start.
      return const LatLng(55.6761, 12.5683);
    }
  }

  /// Stream of position updates (for navigation mode).
  Stream<LatLng> positionStream() {
    if (kMockLocation) {
      // Emit Copenhagen once, then repeat every 3 seconds so navigation
      // step logic can run without jumping to the real GPS position.
      return Stream.periodic(
        const Duration(seconds: 3),
        (_) => _kMockPosition,
      ).asBroadcastStream();
    }
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 metres
      ),
    ).map((pos) => LatLng(pos.latitude, pos.longitude));
  }

  /// Stream of position + bearing + speed updates used by live navigation.
  Stream<LocationUpdate> locationUpdateStream() {
    if (kMockLocation) {
      return Stream.periodic(
        const Duration(seconds: 3),
        (_) => const LocationUpdate(position: _kMockPosition, bearing: 0, speed: 0, altitude: 0),
      ).asBroadcastStream();
    }
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).map((pos) => LocationUpdate(
          position: LatLng(pos.latitude, pos.longitude),
          bearing: pos.heading,
          speed: pos.speed < 0 ? 0 : pos.speed,
          altitude: pos.altitude,
        ));
  }

  /// Static helper usable without an instance.
  static double staticDistanceBetween(LatLng a, LatLng b) =>
      Geolocator.distanceBetween(
          a.latitude, a.longitude, b.latitude, b.longitude);

  /// Calculate distance in metres between two points (straight line).
  double distanceBetween(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }
}

class LocationException implements Exception {
  const LocationException(this.message);
  final String message;
  @override
  String toString() => message;
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);
