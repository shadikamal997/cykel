import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../../../services/location_service.dart';
import '../../auth/domain/app_user.dart';
import '../application/family_location_service.dart';
import '../application/family_pricing_providers.dart';
import '../domain/family_location.dart';

/// Family Live Map - Shows all family members' real-time locations
class FamilyLiveMapScreen extends ConsumerStatefulWidget {
  const FamilyLiveMapScreen({super.key});

  @override
  ConsumerState<FamilyLiveMapScreen> createState() => _FamilyLiveMapScreenState();
}

class _FamilyLiveMapScreenState extends ConsumerState<FamilyLiveMapScreen> {
  GoogleMapController? _mapController;
  bool _isTracking = false;
  String? _selectedMemberId;
  bool _showAlerts = false;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final familyAccountAsync = ref.watch(familyAccountProvider);

    return familyAccountAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Family Map')),
        body: Center(child: Text('Error: $error')),
      ),
      data: (account) {
        if (account == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Family Map')),
            body: Center(
              child: Text(context.l10n.familyNoAccount),
            ),
          );
        }

        final familyId = account.id;

        return Scaffold(
          body: Stack(
            children: [
              // Map with family members
              _buildMap(familyId),

              // Top bar with title and controls
              _buildTopBar(familyId),

              // Member list drawer at bottom
              _buildMemberDrawer(familyId),

              // Alerts panel (if shown)
              if (_showAlerts) _buildAlertsPanel(familyId),

              // SOS Button
              _buildSosButton(familyId),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMap(String familyId) {
    final locationsAsync = ref.watch(familyLocationsProvider(familyId));
    final safeZonesAsync = ref.watch(safeZonesProvider(familyId));

    return locationsAsync.when(
      loading: () => Container(
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        color: Colors.grey[200],
        child: Center(child: Text('Map error: $e')),
      ),
      data: (locations) {
        final markers = _buildMarkers(locations);
        final circles = safeZonesAsync.when(
          data: (zones) => _buildSafeZoneCircles(zones),
          loading: () => <Circle>{},
          error: (e, st) => <Circle>{},
        );

        // Default to a central position if no locations
        final initialPosition = locations.isNotEmpty
            ? LatLng(
                locations.first.position.latitude,
                locations.first.position.longitude,
              )
            : const LatLng(31.9522, 35.2332); // Amman

        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: 14,
          ),
          markers: markers,
          circles: circles,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          onMapCreated: (controller) {
            _mapController = controller;
            // Fit all markers in view
            if (locations.length > 1) {
              _fitAllMarkers(locations);
            }
          },
        );
      },
    );
  }

  Set<Marker> _buildMarkers(List<MemberLocation> locations) {
    return locations.map((loc) {
      final isRiding = loc.isRiding;

      return Marker(
        markerId: MarkerId(loc.memberId),
        position: loc.position,
        infoWindow: InfoWindow(
          title: loc.memberName,
          snippet: isRiding ? '🚴 Riding' : loc.isOnline ? 'Online' : 'Offline',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isRiding
              ? BitmapDescriptor.hueGreen
              : loc.isOnline
                  ? BitmapDescriptor.hueAzure
                  : BitmapDescriptor.hueRed,
        ),
        onTap: () {
          setState(() => _selectedMemberId = loc.memberId);
          _animateToMember(loc);
        },
      );
    }).toSet();
  }

  Set<Circle> _buildSafeZoneCircles(List<SafeZone> zones) {
    return zones.map((zone) {
      return Circle(
        circleId: CircleId(zone.id),
        center: zone.center,
        radius: zone.radiusMeters,
        fillColor: AppColors.primary.withValues(alpha: 0.15),
        strokeColor: AppColors.primary,
        strokeWidth: 2,
      );
    }).toSet();
  }

  void _fitAllMarkers(List<MemberLocation> locations) {
    if (locations.isEmpty || _mapController == null) return;

    double minLat = locations.first.position.latitude;
    double maxLat = locations.first.position.latitude;
    double minLng = locations.first.position.longitude;
    double maxLng = locations.first.position.longitude;

    for (final loc in locations) {
      if (loc.position.latitude < minLat) minLat = loc.position.latitude;
      if (loc.position.latitude > maxLat) maxLat = loc.position.latitude;
      if (loc.position.longitude < minLng) minLng = loc.position.longitude;
      if (loc.position.longitude > maxLng) maxLng = loc.position.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80, // padding
      ),
    );
  }

  void _animateToMember(MemberLocation loc) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(loc.position, 16),
    );
  }

  Widget _buildTopBar(String familyId) {
    final alertsAsync = ref.watch(familyAlertsProvider(familyId));
    final unresolvedCount = alertsAsync.when(
      data: (alerts) => alerts.length,
      loading: () => 0,
      error: (e, st) => 0,
    );

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.white.withValues(alpha: 0),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Back button
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back, size: 20),
                  ),
                ),

                const Spacer(),

                // Title
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isTracking ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Family Map',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Alerts button
                IconButton(
                  onPressed: () => setState(() => _showAlerts = !_showAlerts),
                  icon: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.notifications_outlined, size: 20),
                      ),
                      if (unresolvedCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unresolvedCount > 9 ? '9+' : '$unresolvedCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberDrawer(String familyId) {
    final locationsAsync = ref.watch(familyLocationsProvider(familyId));

    return DraggableScrollableSheet(
      initialChildSize: 0.15,
      minChildSize: 0.1,
      maxChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Tracking toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      'Family Members',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        _toggleTracking(familyId);
                      },
                      icon: Icon(
                        _isTracking ? Icons.location_off : Icons.location_on,
                        size: 18,
                      ),
                      label: Text(_isTracking ? 'Stop Sharing' : 'Share Location'),
                    ),
                  ],
                ),
              ),

              // Member list
              Expanded(
                child: locationsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => Center(
                    child: Text('Error: $e'),
                  ),
                  data: (locations) {
                    if (locations.isEmpty) {
                      return const Center(
                        child: Text(
                          'No one is sharing their location',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: locations.length,
                      itemBuilder: (context, index) {
                        return _buildMemberTile(locations[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMemberTile(MemberLocation location) {
    final isSelected = location.memberId == _selectedMemberId;
    final speedKmh = (location.speed * 3.6).round();

    return Card(
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          setState(() => _selectedMemberId = location.memberId);
          _animateToMember(location);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  AppAvatar(
                    url: location.photoUrl,
                    thumbnailUrl: AppUser.getThumbnailUrl(location.photoUrl),
                    size: 48,
                    fallbackText: location.memberName.isNotEmpty
                        ? location.memberName[0].toUpperCase()
                        : '?',
                  ),
                  // Online indicator
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: location.isOnline
                            ? (location.isRiding ? Colors.green : Colors.blue)
                            : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.memberName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        // Status
                        Icon(
                          location.isRiding
                              ? Icons.directions_bike
                              : location.isOnline
                                  ? Icons.circle
                                  : Icons.circle_outlined,
                          size: 12,
                          color: location.isRiding
                              ? Colors.green
                              : location.isOnline
                                  ? Colors.blue
                                  : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          location.isRiding
                              ? 'Riding • $speedKmh km/h'
                              : location.isOnline
                                  ? 'Online'
                                  : 'Last seen ${_formatLastSeen(location.timestamp)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Navigate button
              IconButton(
                onPressed: () => _animateToMember(location),
                icon: const Icon(
                  Icons.near_me,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertsPanel(String familyId) {
    final alertsAsync = ref.watch(familyAlertsProvider(familyId));

    return Positioned(
      top: 100,
      right: 16,
      child: Container(
        width: 280,
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.notifications, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Alerts',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(() => _showAlerts = false),
                    icon: const Icon(Icons.close, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Alerts list
            alertsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $e'),
              ),
              data: (alerts) {
                if (alerts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No alerts',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      return _buildAlertTile(familyId, alert);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTile(String familyId, FamilyAlert alert) {
    final icon = _getAlertIcon(alert.type);
    final color = _getAlertColor(alert.type);

    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        alert.memberName,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      subtitle: Text(
        alert.message ?? alert.type.name,
        style: const TextStyle(fontSize: 11),
      ),
      trailing: IconButton(
        onPressed: () {
          ref.read(familyLocationServiceProvider).resolveAlert(familyId, alert.id);
        },
        icon: const Icon(Icons.check, size: 18),
      ),
    );
  }

  Widget _buildSosButton(String familyId) {
    return Positioned(
      left: 16,
      bottom: 180,
      child: FloatingActionButton(
        heroTag: 'sos',
        backgroundColor: Colors.red,
        onPressed: () => _showSosDialog(familyId),
        child: const Text(
          'SOS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _showSosDialog(String familyId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emergency, color: Colors.red),
            ),
            const SizedBox(width: 12),
            Text(context.l10n.familySendSOSAlert),
          ],
        ),
        content: const Text(
          'This will send an emergency alert to all family members with your current location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _sendSos(familyId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(context.l10n.familySendSOS),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSos(String familyId) async {
    try {
      final locationService = ref.read(familyLocationServiceProvider);
      final position = await ref.read(locationServiceProvider).getCurrentLocation();
      await locationService.sendSosAlert(familyId, position);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.familySOSSent),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.familySOSFailed(e.toString()))),
        );
      }
    }
  }

  void _toggleTracking(String familyId) async {
    final service = ref.read(familyLocationServiceProvider);

    if (_isTracking) {
      await service.stopTracking(familyId);
    } else {
      await service.startTracking(familyId);
    }

    setState(() => _isTracking = !_isTracking);
  }

  String _formatLastSeen(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  IconData _getAlertIcon(FamilyAlertType type) {
    switch (type) {
      case FamilyAlertType.rideStarted:
        return Icons.directions_bike;
      case FamilyAlertType.rideEnded:
        return Icons.flag;
      case FamilyAlertType.sosPressed:
        return Icons.emergency;
      case FamilyAlertType.crashDetected:
        return Icons.warning;
      case FamilyAlertType.enteredSafeZone:
        return Icons.home;
      case FamilyAlertType.leftSafeZone:
        return Icons.exit_to_app;
      case FamilyAlertType.lowBattery:
        return Icons.battery_alert;
      case FamilyAlertType.speedAlert:
        return Icons.speed;
      case FamilyAlertType.curfewViolation:
        return Icons.nightlight;
    }
  }

  Color _getAlertColor(FamilyAlertType type) {
    switch (type) {
      case FamilyAlertType.sosPressed:
      case FamilyAlertType.crashDetected:
        return Colors.red;
      case FamilyAlertType.leftSafeZone:
      case FamilyAlertType.curfewViolation:
        return Colors.orange;
      case FamilyAlertType.rideStarted:
      case FamilyAlertType.rideEnded:
        return Colors.green;
      case FamilyAlertType.enteredSafeZone:
        return Colors.blue;
      case FamilyAlertType.lowBattery:
      case FamilyAlertType.speedAlert:
        return Colors.amber;
    }
  }
}
