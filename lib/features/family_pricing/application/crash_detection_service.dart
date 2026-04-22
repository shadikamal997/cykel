import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../services/location_service.dart';
import 'family_location_service.dart';

/// Service for detecting potential bike crashes using accelerometer and speed data
class CrashDetectionService {
  final LocationService _locationService;
  final FamilyLocationService _familyLocationService;

  StreamSubscription<AccelerometerEvent>? _accelerometerSub;
  StreamSubscription<LocationUpdate>? _locationSub;

  String? _familyId;
  bool _isMonitoring = false;
  bool _crashAlertPending = false;
  Timer? _crashConfirmTimer;
  
  // Last known position
  LatLng? _lastPosition;

  // Speed tracking
  double _lastSpeed = 0;
  DateTime? _lastSpeedTime;
  final List<double> _recentSpeeds = [];

  // Accelerometer tracking
  final List<double> _recentAccelMagnitudes = [];
  static const int _accelWindowSize = 10;

  // Crash detection thresholds
  static const double _minSpeedForCrashKmh = 15.0; // Must be going at least 15 km/h
  static const double _suddenStopThreshold = 10.0; // km/h drop per second
  static const double _impactGThreshold = 4.0; // G-force threshold (4G)
  static const double _postCrashSpeedThreshold = 3.0; // Speed after crash < 3 km/h
  static const Duration _crashConfirmDelay = Duration(seconds: 30);

  // Callback for crash detection
  void Function(CrashEvent)? onCrashDetected;

  CrashDetectionService({
    required LocationService locationService,
    required FamilyLocationService familyLocationService,
  })  : _locationService = locationService,
        _familyLocationService = familyLocationService;

  /// Start monitoring for crashes
  void startMonitoring(String familyId) {
    if (_isMonitoring) return;

    _familyId = familyId;
    _isMonitoring = true;
    _recentSpeeds.clear();
    _recentAccelMagnitudes.clear();
    _lastPosition = null;

    // Monitor accelerometer for impact detection
    _accelerometerSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen(_onAccelerometerEvent);

    // Monitor location for speed-based crash detection
    _locationSub = _locationService.locationUpdateStream().listen(_onLocationUpdate);

    debugPrint('[CrashDetection] Started monitoring for family $_familyId');
  }

  /// Stop monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _accelerometerSub?.cancel();
    _accelerometerSub = null;
    _locationSub?.cancel();
    _locationSub = null;
    _crashConfirmTimer?.cancel();
    _crashConfirmTimer = null;
    _crashAlertPending = false;
    _lastPosition = null;

    debugPrint('[CrashDetection] Stopped monitoring');
  }

  /// Handle accelerometer events
  void _onAccelerometerEvent(AccelerometerEvent event) {
    // Calculate magnitude of acceleration (G-force)
    // Normal gravity is ~9.8 m/s², so we divide by 9.8 to get G
    final magnitude = math.sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z,
        ) /
        9.8;

    _recentAccelMagnitudes.add(magnitude);
    if (_recentAccelMagnitudes.length > _accelWindowSize) {
      _recentAccelMagnitudes.removeAt(0);
    }

    // Check for impact (sudden high G-force)
    if (magnitude > _impactGThreshold && _lastSpeed > _minSpeedForCrashKmh) {
      _detectPotentialCrash(
        CrashType.impact,
        magnitude,
        'High impact detected: ${magnitude.toStringAsFixed(1)}G at ${_lastSpeed.toStringAsFixed(0)} km/h',
      );
    }
  }

  /// Handle location updates
  void _onLocationUpdate(LocationUpdate update) {
    final speedKmh = update.speed * 3.6;
    final now = DateTime.now();
    
    // Store last known position
    _lastPosition = update.position;

    // Calculate deceleration if we have previous speed data
    if (_lastSpeedTime != null && _lastSpeed > _minSpeedForCrashKmh) {
      final timeDiff = now.difference(_lastSpeedTime!).inMilliseconds / 1000.0;
      if (timeDiff > 0) {
        final deceleration = (_lastSpeed - speedKmh) / timeDiff;

        // Check for sudden stop (high deceleration + now nearly stopped)
        if (deceleration > _suddenStopThreshold &&
            speedKmh < _postCrashSpeedThreshold) {
          _detectPotentialCrash(
            CrashType.suddenStop,
            deceleration,
            'Sudden stop: ${_lastSpeed.toStringAsFixed(0)} → ${speedKmh.toStringAsFixed(0)} km/h',
          );
        }
      }
    }

    // Update tracking data
    _lastSpeed = speedKmh;
    _lastSpeedTime = now;

    _recentSpeeds.add(speedKmh);
    if (_recentSpeeds.length > 10) {
      _recentSpeeds.removeAt(0);
    }
  }

  /// Detect a potential crash and start confirmation countdown
  void _detectPotentialCrash(CrashType type, double severity, String details) {
    if (_crashAlertPending) return; // Already handling a crash

    _crashAlertPending = true;

    final crashEvent = CrashEvent(
      type: type,
      severity: severity,
      details: details,
      timestamp: DateTime.now(),
      location: _lastPosition,
      speedAtCrash: _lastSpeed,
    );

    debugPrint('[CrashDetection] Potential crash detected: $details');

    // Notify listeners (UI will show countdown dialog)
    onCrashDetected?.call(crashEvent);

    // Start countdown timer - if user doesn't cancel, send alert
    _crashConfirmTimer = Timer(_crashConfirmDelay, () {
      _sendCrashAlert(crashEvent);
    });
  }

  /// User confirmed they are OK - cancel the crash alert
  void cancelCrashAlert() {
    _crashConfirmTimer?.cancel();
    _crashConfirmTimer = null;
    _crashAlertPending = false;
    debugPrint('[CrashDetection] Crash alert cancelled by user');
  }

  /// User confirmed crash or timer expired - send alert to family
  Future<void> confirmCrash() async {
    _crashConfirmTimer?.cancel();
    _crashConfirmTimer = null;

    if (_crashAlertPending) {
      final location = _lastPosition;
      await _sendCrashAlert(CrashEvent(
        type: CrashType.userConfirmed,
        severity: 10.0,
        details: 'User confirmed crash',
        timestamp: DateTime.now(),
        location: location,
        speedAtCrash: _lastSpeed,
      ));
    }
  }

  /// Send crash alert to family
  Future<void> _sendCrashAlert(CrashEvent event) async {
    if (_familyId == null) return;

    _crashAlertPending = false;

    final location = event.location ?? _lastPosition;
    if (location == null) {
      debugPrint('[CrashDetection] Cannot send alert - no location');
      return;
    }

    try {
      // Use the family location service to send the crash alert
      await _familyLocationService.sendCrashAlert(
        _familyId!,
        location,
        event.details,
        event.speedAtCrash,
      );
      debugPrint('[CrashDetection] Crash alert sent to family');
    } catch (e) {
      debugPrint('[CrashDetection] Failed to send crash alert: $e');
    }
  }

  bool get isMonitoring => _isMonitoring;
  bool get hasPendingAlert => _crashAlertPending;
}

/// Types of crash detection
enum CrashType {
  impact, // High G-force impact
  suddenStop, // Rapid deceleration
  userConfirmed, // User pressed "I crashed" button
}

/// Crash event data
class CrashEvent {
  final CrashType type;
  final double severity;
  final String details;
  final DateTime timestamp;
  final LatLng? location;
  final double speedAtCrash;

  const CrashEvent({
    required this.type,
    required this.severity,
    required this.details,
    required this.timestamp,
    this.location,
    this.speedAtCrash = 0,
  });
}

// ==========================================
// Providers
// ==========================================

final crashDetectionServiceProvider = Provider<CrashDetectionService>((ref) {
  return CrashDetectionService(
    locationService: ref.watch(locationServiceProvider),
    familyLocationService: ref.watch(familyLocationServiceProvider),
  );
});

/// State for crash alert UI
class CrashAlertState {
  final bool isActive;
  final CrashEvent? event;
  final int secondsRemaining;

  const CrashAlertState({
    this.isActive = false,
    this.event,
    this.secondsRemaining = 30,
  });

  CrashAlertState copyWith({
    bool? isActive,
    CrashEvent? event,
    int? secondsRemaining,
  }) {
    return CrashAlertState(
      isActive: isActive ?? this.isActive,
      event: event ?? this.event,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
    );
  }
}

final crashAlertStateProvider =
    StateNotifierProvider<CrashAlertNotifier, CrashAlertState>((ref) {
  return CrashAlertNotifier(ref);
});

class CrashAlertNotifier extends StateNotifier<CrashAlertState> {
  final Ref _ref;
  Timer? _countdownTimer;

  CrashAlertNotifier(this._ref) : super(const CrashAlertState()) {
    // Listen for crash events
    _ref.read(crashDetectionServiceProvider).onCrashDetected = _onCrashDetected;
  }

  void _onCrashDetected(CrashEvent event) {
    state = CrashAlertState(
      isActive: true,
      event: event,
      secondsRemaining: 30,
    );

    // Start countdown
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.secondsRemaining > 0) {
        state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
      } else {
        timer.cancel();
      }
    });
  }

  void imOkay() {
    _countdownTimer?.cancel();
    _ref.read(crashDetectionServiceProvider).cancelCrashAlert();
    state = const CrashAlertState();
  }

  void confirmCrash() async {
    _countdownTimer?.cancel();
    await _ref.read(crashDetectionServiceProvider).confirmCrash();
    state = const CrashAlertState();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
