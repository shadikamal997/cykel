/// CYKEL — Route Creator Screen
/// Advanced route planning with multi-waypoint support

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_image.dart';
import '../domain/advanced_route.dart';
import '../application/advanced_route_providers.dart';
import '../application/advanced_route_service.dart';

class RouteCreatorScreen extends ConsumerStatefulWidget {
  const RouteCreatorScreen({super.key});

  @override
  ConsumerState<RouteCreatorScreen> createState() => _RouteCreatorScreenState();
}

class _RouteCreatorScreenState extends ConsumerState<RouteCreatorScreen> {
  GoogleMapController? _mapController;
  final List<Waypoint> _waypoints = [];
  final TextEditingController _routeNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final Set<String> _selectedTags = {};
  bool _isRoundTrip = false;
  bool _calculateElevation = true;
  bool _fetchWeather = true;
  bool _isCreating = false;

  // Map state
  final LatLng _centerLocation = const LatLng(55.6761, 12.5683); // Copenhagen
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void dispose() {
    _routeNameController.dispose();
    _notesController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.routesCreateRoute),
        actions: [
          if (_waypoints.length >= 2)
            TextButton.icon(
              onPressed: _isCreating ? null : _createRoute,
              icon: _isCreating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Create'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _centerLocation,
                    zoom: 12,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onTap: _addWaypointAtLocation,
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                ),
                // Map controls
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    children: [
                      _MapButton(
                        icon: Icons.delete_outline,
                        tooltip: 'Clear All',
                        onPressed: _waypoints.isEmpty ? null : _clearWaypoints,
                      ),
                      const SizedBox(height: 8),
                      _MapButton(
                        icon: Icons.route,
                        tooltip: context.l10n.routesOptimizeRoute,
                        onPressed: _waypoints.length < 3 ? null : _showOptimizationDialog,
                      ),
                    ],
                  ),
                ),
                // Waypoint count badge
                if (_waypoints.isNotEmpty)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_waypoints.length} waypoints',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Route details panel
          Expanded(
            child: _RouteDetailsPanel(
              waypoints: _waypoints,
              routeNameController: _routeNameController,
              notesController: _notesController,
              selectedTags: _selectedTags,
              isRoundTrip: _isRoundTrip,
              calculateElevation: _calculateElevation,
              fetchWeather: _fetchWeather,
              onReorderWaypoints: _reorderWaypoints,
              onRemoveWaypoint: _removeWaypoint,
              onUpdateWaypoint: _updateWaypoint,
              onToggleRoundTrip: (value) => setState(() => _isRoundTrip = value),
              onToggleElevation: (value) => setState(() => _calculateElevation = value),
              onToggleWeather: (value) => setState(() => _fetchWeather = value),
              onAddTag: _addTag,
              onRemoveTag: _removeTag,
            ),
          ),
        ],
      ),
    );
  }

  void _addWaypointAtLocation(LatLng location) {
    setState(() {
      final order = _waypoints.length;
      final type = order == 0
          ? WaypointType.start
          : WaypointType.stop;

      final waypoint = Waypoint(
        location: location,
        type: type,
        order: order,
        name: type == WaypointType.start ? 'Start' : 'Stop $order',
      );

      _waypoints.add(waypoint);
      _updateMapMarkers();
      _updatePolylines();
    });
  }

  void _removeWaypoint(int index) {
    setState(() {
      _waypoints.removeAt(index);
      // Reorder remaining waypoints
      for (int i = 0; i < _waypoints.length; i++) {
        _waypoints[i] = _waypoints[i].copyWith(order: i);
      }
      _updateMapMarkers();
      _updatePolylines();
    });
  }

  void _updateWaypoint(int index, Waypoint waypoint) {
    setState(() {
      _waypoints[index] = waypoint;
      _updateMapMarkers();
    });
  }

  void _reorderWaypoints(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final waypoint = _waypoints.removeAt(oldIndex);
      _waypoints.insert(newIndex, waypoint);
      
      // Update order
      for (int i = 0; i < _waypoints.length; i++) {
        _waypoints[i] = _waypoints[i].copyWith(order: i);
      }
      
      _updateMapMarkers();
      _updatePolylines();
    });
  }

  void _clearWaypoints() {
    setState(() {
      _waypoints.clear();
      _markers.clear();
      _polylines.clear();
    });
  }

  void _updateMapMarkers() {
    _markers.clear();
    
    for (int i = 0; i < _waypoints.length; i++) {
      final waypoint = _waypoints[i];
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
  }

  void _updatePolylines() {
    _polylines.clear();
    
    if (_waypoints.length < 2) return;

    final points = _waypoints.map((w) => w.location).toList();
    
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        color: Theme.of(context).colorScheme.primary,
        width: 4,
      ),
    );
  }

  void _showOptimizationDialog() {
    showDialog<RouteOptimizationStrategy>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.routesOptimizeRoute),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: RouteOptimizationStrategy.values.map((strategy) {
            return ListTile(
              leading: Text(strategy.icon, style: const TextStyle(fontSize: 24)),
              title: Text(strategy.displayName),
              onTap: () => Navigator.pop(context, strategy),
            );
          }).toList(),
        ),
      ),
    ).then((strategy) {
      if (strategy != null) {
        _optimizeRoute(strategy);
      }
    });
  }

  Future<void> _optimizeRoute(RouteOptimizationStrategy strategy) async {
    // This would call the optimization service
    // For now, we'll just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Optimizing for: ${strategy.displayName}')),
    );
  }

  void _addTag(String tag) {
    setState(() {
      _selectedTags.add(tag);
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
  }

  Future<void> _createRoute() async {
    if (_waypoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.routesMinTwoWaypoints)),
      );
      return;
    }

    if (_routeNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.routesEnterName)),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      // Mark last waypoint as end
      final waypoints = List<Waypoint>.from(_waypoints);
      waypoints[waypoints.length - 1] = waypoints.last.copyWith(
        type: WaypointType.end,
        name: 'End',
      );

      final service = ref.read(advancedRouteServiceProvider);
      await service.createRoute(
        name: _routeNameController.text.trim(),
        waypoints: waypoints,
        isRoundTrip: _isRoundTrip,
        tags: _selectedTags.toList(),
        notes: _notesController.text.trim().isNotEmpty 
            ? _notesController.text.trim() 
            : null,
        calculateElevation: _calculateElevation,
        fetchWeather: _fetchWeather,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.routesCreatedSuccess)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.routesErrorCreating(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}

// ─── Map Button ─────────────────────────────────────────────────────────────

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

// ─── Route Details Panel ────────────────────────────────────────────────────

class _RouteDetailsPanel extends StatelessWidget {
  const _RouteDetailsPanel({
    required this.waypoints,
    required this.routeNameController,
    required this.notesController,
    required this.selectedTags,
    required this.isRoundTrip,
    required this.calculateElevation,
    required this.fetchWeather,
    required this.onReorderWaypoints,
    required this.onRemoveWaypoint,
    required this.onUpdateWaypoint,
    required this.onToggleRoundTrip,
    required this.onToggleElevation,
    required this.onToggleWeather,
    required this.onAddTag,
    required this.onRemoveTag,
  });

  final List<Waypoint> waypoints;
  final TextEditingController routeNameController;
  final TextEditingController notesController;
  final Set<String> selectedTags;
  final bool isRoundTrip;
  final bool calculateElevation;
  final bool fetchWeather;
  final void Function(int, int) onReorderWaypoints;
  final void Function(int) onRemoveWaypoint;
  final void Function(int, Waypoint) onUpdateWaypoint;
  final void Function(bool) onToggleRoundTrip;
  final void Function(bool) onToggleElevation;
  final void Function(bool) onToggleWeather;
  final void Function(String) onAddTag;
  final void Function(String) onRemoveTag;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Route name
          TextField(
            controller: routeNameController,
            decoration: const InputDecoration(
              labelText: 'Route Name',
              hintText: 'E.g., Morning Commute',
              prefixIcon: Icon(Icons.route),
            ),
          ),
          const SizedBox(height: 16),

          // Options
          SwitchListTile(
            title: Text(context.l10n.routesRoundTrip),
            subtitle: Text(context.l10n.routesRoundTripDesc),
            value: isRoundTrip,
            onChanged: onToggleRoundTrip,
          ),
          SwitchListTile(
            title: Text(context.l10n.routesCalculateElevation),
            subtitle: Text(context.l10n.routesCalculateElevationDesc),
            value: calculateElevation,
            onChanged: onToggleElevation,
          ),
          SwitchListTile(
            title: Text(context.l10n.routesFetchWeather),
            subtitle: Text(context.l10n.routesFetchWeatherDesc),
            value: fetchWeather,
            onChanged: onToggleWeather,
          ),
          
          const SizedBox(height: 16),

          // Tags
          Text(
            'Tags',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ...selectedTags.map((tag) => Chip(
                    label: Text(tag),
                    onDeleted: () => onRemoveTag(tag),
                  )),
              ActionChip(
                avatar: const Icon(Icons.add),
                label: Text(context.l10n.routesAddTag),
                onPressed: () => _showAddTagDialog(context),
              ),
            ],
          ),
          
          const SizedBox(height: 16),

          // Notes
          TextField(
            controller: notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (Optional)',
              hintText: 'Add any notes about this route',
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 24),

          // Waypoints list
          if (waypoints.isNotEmpty) ...[
            Text(
              'Waypoints',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...waypoints.asMap().entries.map((entry) {
              final index = entry.key;
              final waypoint = entry.value;
              return _WaypointTile(
                waypoint: waypoint,
                index: index,
                onRemove: () => onRemoveWaypoint(index),
                onUpdate: (updated) => onUpdateWaypoint(index, updated),
              );
            }),
          ] else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Tap on the map to add waypoints',
                textAlign: TextAlign.center,
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddTagDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'E.g., scenic, fast, commute',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onAddTag(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ─── Waypoint Tile ──────────────────────────────────────────────────────────

class _WaypointTile extends StatelessWidget {
  const _WaypointTile({
    required this.waypoint,
    required this.index,
    required this.onRemove,
    required this.onUpdate,
  });

  final Waypoint waypoint;
  final int index;
  final VoidCallback onRemove;
  final void Function(Waypoint) onUpdate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: AppAvatar(
          url: null,
          size: 40,
          fallbackText: '${index + 1}',
        ),
        title: Text(waypoint.name ?? 'Waypoint ${index + 1}'),
        subtitle: Text(waypoint.type.displayName),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onRemove,
        ),
        onTap: () => _showEditWaypointDialog(context),
      ),
    );
  }

  void _showEditWaypointDialog(BuildContext context) {
    final nameController = TextEditingController(text: waypoint.name);
    final descController = TextEditingController(text: waypoint.description);
    WaypointType selectedType = waypoint.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Waypoint'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<WaypointType>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: WaypointType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text('${type.icon} ${type.displayName}'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                onUpdate(waypoint.copyWith(
                  name: nameController.text.trim().isNotEmpty 
                      ? nameController.text.trim() 
                      : null,
                  type: selectedType,
                  description: descController.text.trim().isNotEmpty 
                      ? descController.text.trim() 
                      : null,
                ));
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
