/// CYKEL — Route Replay Screen
/// Animates a saved ride along its GPS path on the map with playback controls.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../activity/domain/ride.dart';

// ─── Design Colors ─────────────────────────────────────────────────────────────
const _kPrimaryColor = Color(0xFF4A7C59);

/// Playback state for map replay.
class _ReplayState {
  const _ReplayState({
    this.currentIndex = 0,
    this.isPlaying = false,
    this.speed = 1,
  });

  final int currentIndex;
  final bool isPlaying;
  final int speed; // 1x, 2x, 4x

  _ReplayState copyWith({int? currentIndex, bool? isPlaying, int? speed}) =>
      _ReplayState(
        currentIndex: currentIndex ?? this.currentIndex,
        isPlaying: isPlaying ?? this.isPlaying,
        speed: speed ?? this.speed,
      );
}

class RouteReplayScreen extends StatefulWidget {
  const RouteReplayScreen({super.key, required this.ride});
  final Ride ride;

  @override
  State<RouteReplayScreen> createState() => _RouteReplayScreenState();
}

class _RouteReplayScreenState extends State<RouteReplayScreen> {
  GoogleMapController? _mapController;
  Timer? _timer;

  _ReplayState _state = const _ReplayState();

  static const _tickMs = 80; // ms between frames at 1x speed

  @override
  void dispose() {
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  List<LatLng> get path => widget.ride.path;
  bool get atEnd => _state.currentIndex >= path.length - 1;

  // ── Playback Controls ─────────────────────────────────────────────────────

  void _play() {
    if (atEnd) _reset();
    _timer?.cancel();
    setState(() => _state = _state.copyWith(isPlaying: true));

    _timer = Timer.periodic(
      Duration(milliseconds: (_tickMs ~/ _state.speed)),
      (_) {
        if (!mounted) return;
        if (_state.currentIndex >= path.length - 1) {
          _pause();
          return;
        }
        setState(() {
          _state = _state.copyWith(currentIndex: _state.currentIndex + 1);
        });
        // Keep the camera centered on the moving marker.
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(path[_state.currentIndex]),
        );
      },
    );
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _state = _state.copyWith(isPlaying: false));
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _state = const _ReplayState();
    });
    if (path.isNotEmpty) {
      _mapController?.animateCamera(CameraUpdate.newLatLng(path.first));
    }
  }

  void _cycleSpeed() {
    final next = switch (_state.speed) {
      1 => 2,
      2 => 4,
      _ => 1,
    };
    final wasPlaying = _state.isPlaying;
    setState(() => _state = _state.copyWith(speed: next));
    if (wasPlaying) {
      _timer?.cancel();
      _play();
    }
  }

  void _seekTo(double fraction) {
    _pause();
    final index = (fraction * (path.length - 1)).round().clamp(0, path.length - 1);
    setState(() => _state = _state.copyWith(currentIndex: index));
    if (path.isNotEmpty) {
      _mapController?.animateCamera(CameraUpdate.newLatLng(path[index]));
    }
  }

  // ── Map Elements ──────────────────────────────────────────────────────────

  Set<Polyline> _buildPolylines() {
    if (path.isEmpty) return {};

    // Full path (faded)
    final fullPath = Polyline(
      polylineId: const PolylineId('full'),
      points: path,
      color: _kPrimaryColor.withValues(alpha: 0.4),
      width: 4,
      patterns: [PatternItem.dot, PatternItem.gap(8)],
    );

    // Traversed segment (bright)
    final traversed = path.sublist(0, _state.currentIndex + 1);
    final traversedPath = Polyline(
      polylineId: const PolylineId('traversed'),
      points: traversed,
      color: _kPrimaryColor,
      width: 5,
    );

    return {fullPath, traversedPath};
  }

  Set<Marker> _buildMarkers() {
    if (path.isEmpty) return {};
    final markers = <Marker>{};

    // Start marker
    markers.add(Marker(
      markerId: const MarkerId('start'),
      position: path.first,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(title: context.l10n.replayStart),
    ));

    // End marker
    markers.add(Marker(
      markerId: const MarkerId('end'),
      position: path.last,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(title: context.l10n.replayEnd),
    ));

    // Current position marker
    if (_state.currentIndex > 0 && _state.currentIndex < path.length - 1) {
      markers.add(Marker(
        markerId: const MarkerId('current'),
        position: path[_state.currentIndex],
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        anchor: const Offset(0.5, 0.5),
        flat: true,
      ));
    }

    return markers;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final ride = widget.ride;
    final progress = path.isEmpty
        ? 0.0
        : _state.currentIndex / (path.length - 1).clamp(1, path.length);

    // Elapsed time at current position
    final elapsed = path.isEmpty
        ? Duration.zero
        : ride.duration * (_state.currentIndex / (path.length - 1).clamp(1, path.length));

    String fmtDuration(Duration d) {
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      if (d.inHours > 0) return '${d.inHours}:$m:$s';
      return '$m:$s';
    }

    final initialBounds = path.isEmpty
        ? const CameraPosition(target: LatLng(55.676, 12.568), zoom: 12)
        : CameraPosition(target: path.first, zoom: 15);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Full-screen map ─────────────────────────────────────────────
          Positioned.fill(
            child: path.isEmpty
                ? Center(
                    child: Text(context.l10n.noGpsPathAvailable,
                        style: const TextStyle(color: Colors.white)))
                : GoogleMap(
                    initialCameraPosition: initialBounds,
                    onMapCreated: (c) {
                      _mapController = c;
                      // Fit all path points.
                      if (path.length >= 2) {
                        final bounds = _computeBounds(path);
                        c.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
                      }
                    },
                    polylines: _buildPolylines(),
                    markers: _buildMarkers(),
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: false,
                    mapToolbarEnabled: false,
                  ),
          ),

          // ── Top bar ─────────────────────────────────────────────────────
          Positioned(
            top: topPad + 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _GlassButton(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.60),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.l10n.routeReplayTitle,
                          style: AppTextStyles.headline3.copyWith(
                              color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${ride.distanceLabel} · ${ride.dateLabel}',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Zoom Controls ────────────────────────────────────────────
          Positioned(
            right: 12,
            top: topPad + 80,
            child: Column(
              children: [
                _ZoomButton(
                  icon: Icons.add_rounded,
                  onTap: () => _mapController
                      ?.animateCamera(CameraUpdate.zoomIn()),
                ),
                const SizedBox(height: 6),
                _ZoomButton(
                  icon: Icons.remove_rounded,
                  onTap: () => _mapController
                      ?.animateCamera(CameraUpdate.zoomOut()),
                ),
              ],
            ),
          ),

          // ── Bottom controls ──────────────────────────────────────────────
          Positioned(
            bottom: bottomPad + 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Stats row ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ReplayStat(
                        label: context.l10n.elapsed,
                        value: fmtDuration(elapsed),
                        icon: Icons.timer_outlined,
                      ),
                      _ReplayStat(
                        label: context.l10n.total,
                        value: ride.durationLabel,
                        icon: Icons.timer_rounded,
                      ),
                      _ReplayStat(
                        label: context.l10n.distanceLabel,
                        value: ride.distanceLabel,
                        icon: Icons.route_rounded,
                      ),
                      _ReplayStat(
                        label: context.l10n.avgSpeed,
                        value: '${ride.avgSpeedKmh.toStringAsFixed(1)} km/h',
                        icon: Icons.speed_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Progress slider ───────────────────────────────────
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 7),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: _kPrimaryColor,
                      inactiveTrackColor:
                          Colors.white.withValues(alpha: 0.20),
                      thumbColor: _kPrimaryColor,
                      overlayColor:
                          _kPrimaryColor.withValues(alpha: 0.20),
                    ),
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: _seekTo,
                    ),
                  ),

                  // ── Control buttons ──────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Reset
                      _GlassButton(
                        onTap: _reset,
                        child: const Icon(Icons.replay_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 16),
                      // Play/Pause
                      GestureDetector(
                        onTap: _state.isPlaying ? _pause : _play,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _kPrimaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _kPrimaryColor.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _state.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Speed toggle
                      _GlassButton(
                        onTap: _cycleSpeed,
                        child: Text(
                          '${_state.speed}x',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static LatLngBounds _computeBounds(List<LatLng> path) {
    double minLat = path.first.latitude;
    double maxLat = path.first.latitude;
    double minLng = path.first.longitude;
    double maxLng = path.first.longitude;

    for (final p in path) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}

// ── Supporting Widgets ─────────────────────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.60),
            shape: BoxShape.circle,
          ),
          child: Center(child: child),
        ),
      );
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 22, color: Colors.black87),
        ),
      );
}

class _ReplayStat extends StatelessWidget {
  const _ReplayStat(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.60)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.60), fontSize: 10)),
        ],
      );
}
