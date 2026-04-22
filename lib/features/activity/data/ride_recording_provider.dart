/// CYKEL — Ride Recording Providers (Phase 4)
/// StateNotifier that manages a live GPS ride recording.

import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../services/location_service.dart';
import '../../../services/elevation_service.dart';
import '../../../services/ride_sync_service.dart';
import '../data/ride_repository.dart';
import '../data/mobility_aggregation_service.dart';
import '../domain/ride.dart';

// ─── State ───────────────────────────────────────────────────────────────────

enum RideStatus { idle, riding, saving }

class RideState {
  const RideState({
    this.status = RideStatus.idle,
    this.startTime,
    this.elapsed = Duration.zero,
    this.distanceMeters = 0,
    this.currentSpeedKmh = 0,
    this.maxSpeedKmh = 0,
    this.path = const [],
    this.error,
    this.isPaused = false,
    this.pausedAt,
    this.totalPausedTime = Duration.zero,
    this.elevationGainM = 0,
    this.altitudes = const [],
    this.userWeightKg = 70,
  });

  final RideStatus status;
  final DateTime? startTime;
  final Duration elapsed;
  final double distanceMeters;
  final double currentSpeedKmh;
  final double maxSpeedKmh;
  final List<LatLng> path;
  final String? error;
  final bool isPaused;
  final DateTime? pausedAt;
  final Duration totalPausedTime;
  final double elevationGainM;
  final List<double> altitudes;
  final double userWeightKg;

  bool get isRiding => status == RideStatus.riding;

  String get distanceLabel {
    if (distanceMeters < 1000) return '${distanceMeters.round()} m';
    return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
  }

  String get elapsedLabel {
    final m = elapsed.inMinutes;
    final s = elapsed.inSeconds % 60;
    if (m < 60) return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    final h = elapsed.inHours;
    return '${h}h ${(m % 60).toString().padLeft(2, '0')}m';
  }

  String get speedLabel => '${currentSpeedKmh.toStringAsFixed(1)} km/h';
  String get maxSpeedLabel => '${maxSpeedKmh.toStringAsFixed(1)} km/h';

  Duration get movingTime => elapsed - totalPausedTime;

  double get avgSpeedKmh {
    final secs = movingTime.inSeconds;
    if (secs <= 0) return 0;
    return (distanceMeters / secs) * 3.6;
  }

  String get elevationLabel {
    if (elevationGainM < 1000) return '${elevationGainM.round()} m';
    return '${(elevationGainM / 1000).toStringAsFixed(2)} km';
  }

  int get caloriesBurned {
    double met;
    if (avgSpeedKmh < 16) {
      met = 4.0; // Light effort
    } else if (avgSpeedKmh < 19) {
      met = 8.0; // Moderate
    } else if (avgSpeedKmh < 22) {
      met = 10.0; // Vigorous
    } else {
      met = 12.0; // Very vigorous
    }
    final hours = movingTime.inSeconds / 3600.0;
    final calories = met * userWeightKg * hours;
    return calories.round();
  }

  RideState copyWith({
    RideStatus? status,
    DateTime? startTime,
    Duration? elapsed,
    double? distanceMeters,
    double? currentSpeedKmh,
    double? maxSpeedKmh,
    List<LatLng>? path,
    String? error,
    bool? isPaused,
    DateTime? pausedAt,
    Duration? totalPausedTime,
    double? elevationGainM,
    List<double>? altitudes,
    double? userWeightKg,
  }) =>
      RideState(
        status: status ?? this.status,
        startTime: startTime ?? this.startTime,
        elapsed: elapsed ?? this.elapsed,
        distanceMeters: distanceMeters ?? this.distanceMeters,
        currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
        maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
        path: path ?? this.path,
        error: error,
        isPaused: isPaused ?? this.isPaused,
        pausedAt: pausedAt,
        totalPausedTime: totalPausedTime ?? this.totalPausedTime,
        elevationGainM: elevationGainM ?? this.elevationGainM,
        altitudes: altitudes ?? this.altitudes,
        userWeightKg: userWeightKg ?? this.userWeightKg,
      );
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class RideNotifier extends StateNotifier<RideState> {
  RideNotifier(
    this._repo,
    this._locService,
    this._elevationService,
    this._syncService, {
    this.onRideSaved,
  }) : super(const RideState());

  final RideRepository _repo;
  final LocationService _locService;
  final ElevationService _elevationService;
  final RideSyncService _syncService;
  /// Optional callback invoked after a ride is saved (Phase 8: aggregation).
  final Future<void> Function(Ride)? onRideSaved;

  StreamSubscription<LocationUpdate>? _locSub;
  Timer? _clockTick;
  LatLng? _lastPos;

  // ─── Dead-reckoning fields ────────────────────────────────────────────────
  Timer? _deadReckoningTimer;
  DateTime? _lastGpsUpdate;
  double _lastBearing = 0.0;
  double _lastSpeedMs = 0.0; // metres per second

  Future<void> startRide() async {
    if (state.isRiding) return;
    state = RideState(status: RideStatus.riding, startTime: DateTime.now());

    // Tick every second to update elapsed time
    _clockTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isRiding) return;
      state = state.copyWith(
        elapsed: DateTime.now().difference(state.startTime!),
      );
    });

    // Listen to GPS
    _locSub = _locService.locationUpdateStream().listen((update) {
      final pos = update.position;
      final speedKmh = update.speed * 3.6;

      // ─── Update dead-reckoning state ──────────────────────────────────────
      _lastGpsUpdate = DateTime.now();
      _lastBearing = update.bearing;
      _lastSpeedMs = update.speed;
      _deadReckoningTimer?.cancel(); // Cancel any existing dead-reckoning
      _deadReckoningTimer = Timer(const Duration(seconds: 3), _startDeadReckoning);

      double addedDist = 0;
      if (_lastPos != null) {
        addedDist = Geolocator.distanceBetween(
          _lastPos!.latitude,
          _lastPos!.longitude,
          pos.latitude,
          pos.longitude,
        );
      }
      _lastPos = pos;

      final newPath = [...state.path, pos];
      final newDist = state.distanceMeters + addedDist;
      final newMax = speedKmh > state.maxSpeedKmh ? speedKmh : state.maxSpeedKmh;

      // Calculate elevation gain
      double newElevation = state.elevationGainM;
      final altitude = update.altitude;
      if (state.altitudes.isNotEmpty) {
        final lastAltitude = state.altitudes.last;
        final altitudeDiff = altitude - lastAltitude;
        // Only count gains (ignore descents), with 1m threshold to filter GPS noise
        if (altitudeDiff > 1.0) {
          newElevation = state.elevationGainM + altitudeDiff;
        }
      }

      state = state.copyWith(
        distanceMeters: newDist,
        currentSpeedKmh: speedKmh,
        maxSpeedKmh: newMax,
        path: newPath,
        elevationGainM: newElevation,
        altitudes: [...state.altitudes, altitude],
      );
    });
  }

  void pauseRide() {
    if (!state.isRiding || state.isPaused) return;
    
    // Stop the clock tick
    _clockTick?.cancel();
    _clockTick = null;
    
    // Stop GPS tracking during pause to save battery
    _locSub?.cancel();
    _locSub = null;
    
    state = state.copyWith(
      isPaused: true,
      pausedAt: DateTime.now(),
    );
  }

  void resumeRide() {
    if (!state.isPaused) return;
    
    // Calculate paused duration and add to total
    final pausedDuration = DateTime.now().difference(state.pausedAt!);
    final newTotalPaused = state.totalPausedTime + pausedDuration;
    
    // Restart the clock tick
    _clockTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isRiding || state.isPaused) return;
      state = state.copyWith(
        elapsed: DateTime.now().difference(state.startTime!),
      );
    });
    
    // Restart GPS tracking
    _locSub = _locService.locationUpdateStream().listen((update) {
      if (state.isPaused) return; // Skip updates while paused
      
      final pos = update.position;
      final speedKmh = update.speed * 3.6;

      _lastGpsUpdate = DateTime.now();
      _lastBearing = update.bearing;
      _lastSpeedMs = update.speed;
      _deadReckoningTimer?.cancel();
      _deadReckoningTimer = Timer(const Duration(seconds: 3), _startDeadReckoning);

      double addedDist = 0;
      if (_lastPos != null) {
        addedDist = Geolocator.distanceBetween(
          _lastPos!.latitude,
          _lastPos!.longitude,
          pos.latitude,
          pos.longitude,
        );
      }
      _lastPos = pos;

      final newPath = [...state.path, pos];
      final newDist = state.distanceMeters + addedDist;
      final newMax = speedKmh > state.maxSpeedKmh ? speedKmh : state.maxSpeedKmh;

      double newElevation = state.elevationGainM;
      final altitude = update.altitude;
      if (state.altitudes.isNotEmpty) {
        final lastAltitude = state.altitudes.last;
        final altitudeDiff = altitude - lastAltitude;
        if (altitudeDiff > 1.0) {
          newElevation = state.elevationGainM + altitudeDiff;
        }
      }

      state = state.copyWith(
        distanceMeters: newDist,
        currentSpeedKmh: speedKmh,
        maxSpeedKmh: newMax,
        path: newPath,
        elevationGainM: newElevation,
        altitudes: [...state.altitudes, altitude],
      );
    });
    
    state = state.copyWith(
      isPaused: false,
      pausedAt: null,
      totalPausedTime: newTotalPaused,
    );
  }

  Future<Ride?> stopRide() async {
    if (!state.isRiding) return null;

    _locSub?.cancel();
    _locSub = null;
    _clockTick?.cancel();
    _clockTick = null;
    _deadReckoningTimer?.cancel();
    _deadReckoningTimer = null;
    _lastPos = null;

    final now = DateTime.now();

    // Fetch elevation gain asynchronously — non-blocking, defaults to 0.
    double elevationGain = 0;
    if (state.path.length >= 2) {
      try {
        final samples = ElevationService.samplesForDistance(state.distanceMeters);
        elevationGain = await _elevationService.getElevationGain(
          state.path,
          maxPoints: samples,
        );
      } catch (_) {
        elevationGain = 0;
      }
    }

    final ride = Ride(
      id: now.millisecondsSinceEpoch.toString(),
      startTime: state.startTime ?? now,
      endTime: now,
      distanceMeters: state.distanceMeters,
      maxSpeedKmh: state.maxSpeedKmh,
      avgSpeedKmh: state.avgSpeedKmh,
      path: state.path,
      elevationGainM: elevationGain,
    );

    state = state.copyWith(status: RideStatus.saving);
    try {
      await _repo.saveRide(ride);
      // Cloud sync — fires in background, silently ignores errors.
      _syncService.uploadRide(ride).catchError((_) {});
      // Phase 8: anonymised mobility aggregation (only if GDPR consent given).
      if (onRideSaved != null) {
        onRideSaved!(ride).catchError((_) {}); // fire-and-forget, non-blocking
      }
    } catch (_) {}

    state = const RideState(); // reset to idle
    return ride;
  }

  // ─── Dead-reckoning implementation ────────────────────────────────────────

  void _startDeadReckoning() {
    if (!state.isRiding || _lastPos == null) return;

    // Start extrapolating position every second
    _deadReckoningTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isRiding) return;

      // Check if GPS has come back (within last 2 seconds)
      if (_lastGpsUpdate != null &&
          DateTime.now().difference(_lastGpsUpdate!) < const Duration(seconds: 2)) {
        _deadReckoningTimer?.cancel();
        _deadReckoningTimer = null;
        return;
      }

      _performDeadReckoningStep();
    });
  }

  void _performDeadReckoningStep() {
    if (_lastPos == null || !state.isRiding) return;

    // Extrapolate position based on last known speed and bearing
    // Speed is in m/s, bearing in degrees
    final distanceMoved = _lastSpeedMs; // 1 second * speed in m/s
    final bearingRad = _lastBearing * (3.14159 / 180.0); // Convert to radians

    // Calculate new position using haversine approximation
    const earthRadius = 6371000.0; // Earth radius in meters
    final latRad = _lastPos!.latitude * (3.14159 / 180.0);
    final lonRad = _lastPos!.longitude * (3.14159 / 180.0);

    final newLatRad = latRad + (distanceMoved / earthRadius) * cos(bearingRad);
    final newLonRad = lonRad + (distanceMoved / earthRadius) * sin(bearingRad) / cos(latRad);

    final newLat = newLatRad * (180.0 / 3.14159);
    final newLon = newLonRad * (180.0 / 3.14159);

    final newPos = LatLng(newLat, newLon);

    // Update state with extrapolated position
    final addedDist = Geolocator.distanceBetween(
      _lastPos!.latitude,
      _lastPos!.longitude,
      newPos.latitude,
      newPos.longitude,
    );

    final newPath = [...state.path, newPos];
    final newDist = state.distanceMeters + addedDist;

    _lastPos = newPos;

    state = state.copyWith(
      distanceMeters: newDist,
      path: newPath,
      // Keep current speed as last known (dead-reckoning doesn't change speed)
    );
  }

  @override
  void dispose() {
    _locSub?.cancel();
    _clockTick?.cancel();
    _deadReckoningTimer?.cancel();
    super.dispose();
  }
}

final rideNotifierProvider =
    StateNotifierProvider<RideNotifier, RideState>((ref) {
  final callback = ref.watch(rideCompletionCallbackProvider);
  return RideNotifier(
    ref.read(rideRepositoryProvider),
    ref.read(locationServiceProvider),
    ref.read(elevationServiceProvider),
    ref.read(rideSyncServiceProvider),
    onRideSaved: callback,
  );
});

/// Async provider that loads ride history from storage.
final rideHistoryProvider = FutureProvider.autoDispose<List<Ride>>((ref) async {
  return ref.watch(rideRepositoryProvider).getRides();
});
