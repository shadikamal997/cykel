import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../application/family_location_service.dart';
import '../application/family_pricing_providers.dart';
import '../domain/family_location.dart';

/// Full ride history screen with filtering and details
class RideHistoryScreen extends ConsumerStatefulWidget {
  final String? memberId; // If null, shows all family members

  const RideHistoryScreen({super.key, this.memberId});

  @override
  ConsumerState<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends ConsumerState<RideHistoryScreen> {
  String? _selectedMemberId;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _selectedMemberId = widget.memberId;
  }

  @override
  Widget build(BuildContext context) {
    final familyAccountAsync = ref.watch(familyAccountProvider);

    return familyAccountAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Ride History')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (account) {
        if (account == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ride History')),
            body: const Center(child: Text('No family account found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Ride History'),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterSheet(context, account.members),
              ),
            ],
          ),
          body: Column(
            children: [
              // Active filters
              if (_selectedMemberId != null || _dateRange != null)
                _FilterChips(
                  memberName: _selectedMemberId != null
                      ? account.members
                          .firstWhere(
                            (m) => m.userId == _selectedMemberId,
                            orElse: () => account.members.first,
                          )
                          .displayName
                      : null,
                  dateRange: _dateRange,
                  onClearMember: () => setState(() => _selectedMemberId = null),
                  onClearDateRange: () => setState(() => _dateRange = null),
                ),

              // Rides list
              Expanded(
                child: _RidesList(
                  familyId: account.id,
                  memberId: _selectedMemberId,
                  dateRange: _dateRange,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context, List<dynamic> members) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterSheet(
        members: members,
        selectedMemberId: _selectedMemberId,
        dateRange: _dateRange,
        onMemberSelected: (id) {
          setState(() => _selectedMemberId = id);
          Navigator.pop(context);
        },
        onDateRangeSelected: (range) {
          setState(() => _dateRange = range);
          Navigator.pop(context);
        },
        onClear: () {
          setState(() {
            _selectedMemberId = null;
            _dateRange = null;
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final String? memberName;
  final DateTimeRange? dateRange;
  final VoidCallback onClearMember;
  final VoidCallback onClearDateRange;

  const _FilterChips({
    this.memberName,
    this.dateRange,
    required this.onClearMember,
    required this.onClearDateRange,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          if (memberName != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(memberName!),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: onClearMember,
                visualDensity: VisualDensity.compact,
              ),
            ),
          if (dateRange != null)
            Chip(
              label: Text(
                '${dateFormat.format(dateRange!.start)} - ${dateFormat.format(dateRange!.end)}',
              ),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: onClearDateRange,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  final List<dynamic> members;
  final String? selectedMemberId;
  final DateTimeRange? dateRange;
  final ValueChanged<String?> onMemberSelected;
  final ValueChanged<DateTimeRange> onDateRangeSelected;
  final VoidCallback onClear;

  const _FilterSheet({
    required this.members,
    this.selectedMemberId,
    this.dateRange,
    required this.onMemberSelected,
    required this.onDateRangeSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Rides',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onClear,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Member filter
          const Text(
            'Member',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: selectedMemberId == null,
                onSelected: (_) => onMemberSelected(null),
              ),
              ...members.map((member) => ChoiceChip(
                    label: Text(member.displayName ?? 'Unknown'),
                    selected: selectedMemberId == member.userId,
                    onSelected: (_) => onMemberSelected(member.userId),
                  )),
            ],
          ),
          const SizedBox(height: 20),

          // Date filter
          const Text(
            'Date Range',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.today, size: 16),
                label: const Text('Today'),
                onPressed: () {
                  final now = DateTime.now();
                  onDateRangeSelected(DateTimeRange(
                    start: DateTime(now.year, now.month, now.day),
                    end: now,
                  ));
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.date_range, size: 16),
                label: const Text('This Week'),
                onPressed: () {
                  final now = DateTime.now();
                  final weekStart = now.subtract(Duration(days: now.weekday - 1));
                  onDateRangeSelected(DateTimeRange(
                    start: DateTime(weekStart.year, weekStart.month, weekStart.day),
                    end: now,
                  ));
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.calendar_month, size: 16),
                label: const Text('This Month'),
                onPressed: () {
                  final now = DateTime.now();
                  onDateRangeSelected(DateTimeRange(
                    start: DateTime(now.year, now.month, 1),
                    end: now,
                  ));
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.edit_calendar, size: 16),
                label: const Text('Custom...'),
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: dateRange,
                  );
                  if (range != null) {
                    onDateRangeSelected(range);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _RidesList extends ConsumerWidget {
  final String familyId;
  final String? memberId;
  final DateTimeRange? dateRange;

  const _RidesList({
    required this.familyId,
    this.memberId,
    this.dateRange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridesAsync = ref.watch(
      FutureProvider<List<FamilyRide>>((ref) async {
        final service = ref.read(familyLocationServiceProvider);

        if (memberId != null) {
          return service.getMemberRideHistory(familyId, memberId!, limit: 100);
        } else {
          return service.getFamilyRideHistory(
            familyId,
            since: dateRange?.start,
            limit: 100,
          );
        }
      }),
    );

    return ridesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (rides) {
        // Apply date filter
        var filteredRides = rides;
        if (dateRange != null) {
          filteredRides = rides.where((r) {
            return r.startTime.isAfter(dateRange!.start) &&
                r.startTime.isBefore(dateRange!.end.add(const Duration(days: 1)));
          }).toList();
        }

        if (filteredRides.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_bike, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text(
                  'No rides found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your filters',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Group by date
        final grouped = <String, List<FamilyRide>>{};
        final dateFormat = DateFormat('MMMM d, yyyy');

        for (final ride in filteredRides) {
          final key = dateFormat.format(ride.startTime);
          grouped.putIfAbsent(key, () => []).add(ride);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: grouped.length,
          itemBuilder: (context, index) {
            final entry = grouped.entries.elementAt(index);
            return _DateSection(
              date: entry.key,
              rides: entry.value,
              familyId: familyId,
            );
          },
        );
      },
    );
  }
}

class _DateSection extends StatelessWidget {
  final String date;
  final List<FamilyRide> rides;
  final String familyId;

  const _DateSection({
    required this.date,
    required this.rides,
    required this.familyId,
  });

  @override
  Widget build(BuildContext context) {
    final totalDistance = rides.fold(0.0, (sum, r) => sum + r.distanceKm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${rides.length} rides • ${totalDistance.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Rides
        ...rides.map((ride) => _RideDetailCard(
              ride: ride,
              familyId: familyId,
            )),

        const SizedBox(height: 8),
      ],
    );
  }
}

class _RideDetailCard extends StatelessWidget {
  final FamilyRide ride;
  final String familyId;

  const _RideDetailCard({
    required this.ride,
    required this.familyId,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showRideDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const AppAvatar(
                    url: null,
                    size: 36,
                    fallbackIcon: Icons.directions_bike,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.memberName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          timeFormat.format(ride.startTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),

              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  _StatItem(
                    icon: Icons.straighten,
                    value: '${ride.distanceKm.toStringAsFixed(1)} km',
                    label: 'Distance',
                  ),
                  _StatItem(
                    icon: Icons.timer,
                    value: _formatDuration(ride.durationMinutes),
                    label: 'Duration',
                  ),
                  _StatItem(
                    icon: Icons.speed,
                    value: '${ride.avgSpeedKmh.toStringAsFixed(0)} km/h',
                    label: 'Avg Speed',
                  ),
                  _StatItem(
                    icon: Icons.bolt,
                    value: '${ride.maxSpeedKmh.toStringAsFixed(0)} km/h',
                    label: 'Max Speed',
                  ),
                ],
              ),

              // Mini map preview
              if (ride.route.length > 1) ...[
                const SizedBox(height: 12),
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _MiniRoutePreview(route: ride.route),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showRideDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RideDetailSheet(ride: ride),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniRoutePreview extends StatelessWidget {
  final List<LatLng> route;

  const _MiniRoutePreview({required this.route});

  @override
  Widget build(BuildContext context) {
    // For a simple preview, just show markers for start/end
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
      ),
      child: Stack(
        children: [
          // Simplified route line representation
          CustomPaint(
            size: const Size(double.infinity, 100),
            painter: _RouteLinePainter(route),
          ),
          // View route label
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map, size: 14, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    'View Route',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteLinePainter extends CustomPainter {
  final List<LatLng> route;

  _RouteLinePainter(this.route);

  @override
  void paint(Canvas canvas, Size size) {
    if (route.length < 2) return;

    // Calculate bounds
    double minLat = route[0].latitude;
    double maxLat = route[0].latitude;
    double minLng = route[0].longitude;
    double maxLng = route[0].longitude;

    for (final point in route) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;

    if (latRange == 0 || lngRange == 0) return;

    // Map route to canvas
    const padding = 16.0;
    final drawWidth = size.width - padding * 2;
    final drawHeight = size.height - padding * 2;

    final points = route.map((p) {
      final x = padding + ((p.longitude - minLng) / lngRange) * drawWidth;
      final y = padding + drawHeight - ((p.latitude - minLat) / latRange) * drawHeight;
      return Offset(x, y);
    }).toList();

    // Draw route line
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);

    // Draw start/end markers
    final startPaint = Paint()..color = Colors.green;
    final endPaint = Paint()..color = Colors.red;

    canvas.drawCircle(points.first, 6, startPaint);
    canvas.drawCircle(points.last, 6, endPaint);
  }

  @override
  bool shouldRepaint(covariant _RouteLinePainter oldDelegate) {
    return oldDelegate.route != route;
  }
}

class _RideDetailSheet extends StatelessWidget {
  final FamilyRide ride;

  const _RideDetailSheet({required this.ride});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const AppAvatar(
                    url: null,
                    size: 48,
                    fallbackIcon: Icons.directions_bike,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.memberName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          dateFormat.format(ride.startTime),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Time info
                  _DetailRow(
                    icon: Icons.schedule,
                    label: 'Start Time',
                    value: timeFormat.format(ride.startTime),
                  ),
                  if (ride.endTime != null)
                    _DetailRow(
                      icon: Icons.flag,
                      label: 'End Time',
                      value: timeFormat.format(ride.endTime!),
                    ),
                  const SizedBox(height: 16),

                  // Stats grid
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _LargeStat(
                              label: 'Distance',
                              value: ride.distanceKm.toStringAsFixed(2),
                              unit: 'km',
                              icon: Icons.straighten,
                            ),
                            _LargeStat(
                              label: 'Duration',
                              value: ride.durationMinutes.toString(),
                              unit: 'min',
                              icon: Icons.timer,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _LargeStat(
                              label: 'Avg Speed',
                              value: ride.avgSpeedKmh.toStringAsFixed(1),
                              unit: 'km/h',
                              icon: Icons.speed,
                            ),
                            _LargeStat(
                              label: 'Max Speed',
                              value: ride.maxSpeedKmh.toStringAsFixed(1),
                              unit: 'km/h',
                              icon: Icons.bolt,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Route map
                  if (ride.route.length > 1) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Route',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _RouteMapView(ride: ride),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _LargeStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  const _LargeStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteMapView extends StatefulWidget {
  final FamilyRide ride;

  const _RouteMapView({required this.ride});

  @override
  State<_RouteMapView> createState() => _RouteMapViewState();
}

class _RouteMapViewState extends State<_RouteMapView> {
  GoogleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    final route = widget.ride.route;
    if (route.isEmpty) {
      return const Center(child: Text('No route data'));
    }

    // Calculate bounds
    double minLat = route[0].latitude;
    double maxLat = route[0].latitude;
    double minLng = route[0].longitude;
    double maxLng = route[0].longitude;

    for (final point in route) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final center = LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: center,
        zoom: 14,
      ),
      onMapCreated: (controller) {
        _controller = controller;
        // Fit bounds
        _controller?.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(minLat, minLng),
              northeast: LatLng(maxLat, maxLng),
            ),
            50,
          ),
        );
      },
      polylines: {
        Polyline(
          polylineId: const PolylineId('route'),
          points: route,
          color: AppColors.primary,
          width: 4,
        ),
      },
      markers: {
        Marker(
          markerId: const MarkerId('start'),
          position: route.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Start'),
        ),
        if (route.length > 1)
          Marker(
            markerId: const MarkerId('end'),
            position: route.last,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: 'End'),
          ),
      },
      myLocationEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }
}
