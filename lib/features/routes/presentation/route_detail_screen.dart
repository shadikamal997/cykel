/// CYKEL — Route Detail Screen
/// Detailed view of advanced route with elevation profile and weather

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../domain/advanced_route.dart';
import '../application/advanced_route_providers.dart';

class RouteDetailScreen extends ConsumerStatefulWidget {
  const RouteDetailScreen({
    super.key,
    required this.routeId,
  });

  final String routeId;

  @override
  ConsumerState<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends ConsumerState<RouteDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routeAsync = ref.watch(routeProvider(widget.routeId));

    return Scaffold(
      appBar: AppBar(
        title: routeAsync.when(
          data: (route) => Text(route?.name ?? 'Route Details'),
          loading: () => const Text('Loading...'),
          error: (_, _) => const Text('Error'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Share route
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDelete();
              } else if (value == 'edit') {
                // TODO: Navigate to edit screen
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit Route'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Route'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.info_outline)),
            Tab(text: 'Elevation', icon: Icon(Icons.terrain)),
            Tab(text: 'Weather', icon: Icon(Icons.wb_sunny)),
          ],
        ),
      ),
      body: routeAsync.when(
        data: (route) {
          if (route == null) {
            return const Center(child: Text('Route not found'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(route: route),
              _ElevationTab(route: route),
              _WeatherTab(routeId: widget.routeId, route: route),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Error loading route: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route'),
        content: const Text('Are you sure you want to delete this route?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final service = ref.read(advancedRouteServiceProvider);
      await service.deleteRoute(widget.routeId);
      
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}

// ─── Overview Tab ───────────────────────────────────────────────────────────

class _OverviewTab extends StatefulWidget {
  const _OverviewTab({required this.route});

  final AdvancedRoute route;

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _setupMapData();
  }

  void _setupMapData() {
    // Create markers for waypoints
    for (int i = 0; i < widget.route.waypoints.length; i++) {
      final waypoint = widget.route.waypoints[i];
      _markers.add(
        Marker(
          markerId: MarkerId('waypoint_$i'),
          position: waypoint.location,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            waypoint.type == WaypointType.start
                ? BitmapDescriptor.hueGreen
                : waypoint.type == WaypointType.end
                    ? BitmapDescriptor.hueRed
                    : BitmapDescriptor.hueBlue,
          ),
          infoWindow: InfoWindow(
            title: waypoint.name ?? 'Waypoint ${i + 1}',
            snippet: waypoint.type.displayName,
          ),
        ),
      );
    }

    // Create polyline
    if (widget.route.waypoints.length >= 2) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: widget.route.waypoints.map((w) => w.location).toList(),
          color: Colors.blue,
          width: 4,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map
          SizedBox(
            height: 300,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.route.waypoints.first.location,
                zoom: 12,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                _fitBounds();
              },
              markers: _markers,
              polylines: _polylines,
              zoomControlsEnabled: false,
            ),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Route Statistics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _StatRow(
                  icon: Icons.straighten,
                  label: 'Total Distance',
                  value: '${widget.route.totalDistanceKm.toStringAsFixed(1)} km',
                ),
                _StatRow(
                  icon: Icons.schedule,
                  label: 'Estimated Time',
                  value: '${widget.route.estimatedDurationMinutes ~/ 60}h ${widget.route.estimatedDurationMinutes % 60}m',
                ),
                _StatRow(
                  icon: Icons.av_timer,
                  label: 'Total Journey Time',
                  value: '${widget.route.totalJourneyTimeMinutes ~/ 60}h ${widget.route.totalJourneyTimeMinutes % 60}m',
                ),
                _StatRow(
                  icon: Icons.place,
                  label: 'Waypoints',
                  value: '${widget.route.waypoints.length} (${widget.route.totalStops} stops)',
                ),
                if (widget.route.hasElevationData) ...[
                  _StatRow(
                    icon: Icons.terrain,
                    label: 'Elevation Gain',
                    value: '${widget.route.elevationProfile!.totalElevationGainM.round()} m',
                  ),
                  _StatRow(
                    icon: Icons.trending_down,
                    label: 'Elevation Loss',
                    value: '${widget.route.elevationProfile!.totalElevationLossM.round()} m',
                  ),
                  _StatRow(
                    icon: Icons.fitness_center,
                    label: 'Difficulty',
                    value: widget.route.elevationProfile!.difficultyLabel,
                  ),
                ],
                if (widget.route.isRoundTrip)
                  const _StatRow(
                    icon: Icons.loop,
                    label: 'Type',
                    value: 'Round Trip',
                  ),
                
                const SizedBox(height: 24),

                // Waypoints list
                Text(
                  'Waypoints',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ...widget.route.waypoints.map((waypoint) {
                  return _WaypointItem(waypoint: waypoint);
                }),

                // Tags
                if (widget.route.tags.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Tags',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.route.tags.map((tag) {
                      return Chip(label: Text(tag));
                    }).toList(),
                  ),
                ],

                // Notes
                if (widget.route.notes != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Notes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(widget.route.notes!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _fitBounds() {
    if (_mapController == null || widget.route.waypoints.isEmpty) return;

    final bounds = _calculateBounds(
      widget.route.waypoints.map((w) => w.location).toList(),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    double south = points.first.latitude;
    double north = points.first.latitude;
    double west = points.first.longitude;
    double east = points.first.longitude;

    for (final point in points) {
      if (point.latitude < south) south = point.latitude;
      if (point.latitude > north) north = point.latitude;
      if (point.longitude < west) west = point.longitude;
      if (point.longitude > east) east = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _WaypointItem extends StatelessWidget {
  const _WaypointItem({required this.waypoint});

  final Waypoint waypoint;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(
          waypoint.type.icon,
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(waypoint.name ?? 'Waypoint'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(waypoint.type.displayName),
            if (waypoint.description != null) Text(waypoint.description!),
            if (waypoint.estimatedStopDurationMinutes != null)
              Text('Stop: ${waypoint.estimatedStopDurationMinutes} min'),
          ],
        ),
        dense: true,
      ),
    );
  }
}

// ─── Elevation Tab ──────────────────────────────────────────────────────────

class _ElevationTab extends StatelessWidget {
  const _ElevationTab({required this.route});

  final AdvancedRoute route;

  @override
  Widget build(BuildContext context) {
    if (!route.hasElevationData) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.terrain, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No elevation data available'),
          ],
        ),
      );
    }

    final profile = route.elevationProfile!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elevation chart (simplified representation)
          Text(
            'Elevation Profile',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomPaint(
              painter: _ElevationChartPainter(profile: profile),
              size: const Size(double.infinity, 200),
            ),
          ),

          const SizedBox(height: 24),

          // Elevation stats
          Text(
            'Elevation Statistics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _StatRow(
            icon: Icons.arrow_upward,
            label: 'Total Gain',
            value: '${profile.totalElevationGainM.round()} m',
          ),
          _StatRow(
            icon: Icons.arrow_downward,
            label: 'Total Loss',
            value: '${profile.totalElevationLossM.round()} m',
          ),
          _StatRow(
            icon: Icons.landscape,
            label: 'Max Elevation',
            value: '${profile.maxElevationM.round()} m',
          ),
          _StatRow(
            icon: Icons.vertical_align_bottom,
            label: 'Min Elevation',
            value: '${profile.minElevationM.round()} m',
          ),
          _StatRow(
            icon: Icons.show_chart,
            label: 'Average Grade',
            value: '${profile.averageGradePercent.toStringAsFixed(1)}%',
          ),
          _StatRow(
            icon: Icons.fitness_center,
            label: 'Difficulty',
            value: profile.difficultyLabel,
          ),
        ],
      ),
    );
  }
}

class _ElevationChartPainter extends CustomPainter {
  _ElevationChartPainter({required this.profile});

  final ElevationProfile profile;

  @override
  void paint(Canvas canvas, Size size) {
    if (profile.points.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    // Calculate scale
    final maxDistance = profile.points.last.distanceKm;
    final elevationRange = profile.maxElevationM - profile.minElevationM;
    
    if (elevationRange == 0) return;

    final scaleX = size.width / maxDistance;
    final scaleY = size.height / elevationRange;

    // Build path
    final path = Path();
    final fillPath = Path();
    
    fillPath.moveTo(0, size.height);

    for (int i = 0; i < profile.points.length; i++) {
      final point = profile.points[i];
      final x = point.distanceKm * scaleX;
      final y = size.height - (point.elevationM - profile.minElevationM) * scaleY;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Weather Tab ────────────────────────────────────────────────────────────

class _WeatherTab extends ConsumerWidget {
  const _WeatherTab({
    required this.routeId,
    required this.route,
  });

  final String routeId;
  final AdvancedRoute route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(routeWeatherProvider(routeId));
    final recommendationsAsync = ref.watch(routeWeatherRecommendationsProvider(routeId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current weather (if available)
          if (route.hasWeatherData) ...[
            Text(
              'Current Weather',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _WeatherCard(weather: route.weatherForecast!),
            const SizedBox(height: 24),
          ],

          // Weather along route
          Text(
            'Weather Along Route',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          weatherAsync.when(
            data: (forecasts) {
              if (forecasts.isEmpty) {
                return const Text('No weather data available');
              }

              return Column(
                children: forecasts.map((forecast) {
                  return _WeatherCard(weather: forecast);
                }).toList(),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (_, _) => const Text('Failed to load weather'),
          ),

          const SizedBox(height: 24),

          // Recommendations
          Text(
            'Recommendations',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          recommendationsAsync.when(
            data: (recommendations) {
              if (recommendations.isEmpty) {
                return const Text('No recommendations available');
              }

              return Column(
                children: recommendations.map((rec) {
                  return Card(
                    child: ListTile(
                      title: Text(rec),
                      dense: true,
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (_, _) => const Text('Failed to load recommendations'),
          ),
        ],
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({required this.weather});

  final WeatherForecast weather;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              weather.condition.icon,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weather.condition.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('${weather.temperatureC.round()}°C'),
                  Text('Wind: ${weather.windSpeedKmh.round()} km/h'),
                  Text('Precipitation: ${weather.precipitationChance}%'),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getComfortColor(weather.cyclingComfortScore),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    weather.comfortLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getComfortColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    if (score >= 20) return Colors.deepOrange;
    return Colors.red;
  }
}
