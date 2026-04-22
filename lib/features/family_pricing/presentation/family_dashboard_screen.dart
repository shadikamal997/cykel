import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../../auth/domain/app_user.dart';
import '../application/family_location_service.dart';
import '../application/family_pricing_providers.dart';
import '../domain/family_location.dart';

/// Family Admin Dashboard - Shows statistics, activity, rides, and alerts
class FamilyDashboardScreen extends ConsumerStatefulWidget {
  const FamilyDashboardScreen({super.key});

  @override
  ConsumerState<FamilyDashboardScreen> createState() => _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState extends ConsumerState<FamilyDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        appBar: AppBar(title: const Text('Dashboard')),
        body: Center(child: Text('Error: $error')),
      ),
      data: (account) {
        if (account == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Dashboard')),
            body: const Center(child: Text('No family account found')),
          );
        }

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildAppBar(context, account.name),
              SliverToBoxAdapter(
                child: _buildStatsOverview(account.id),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  tabController: _tabController,
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _MembersTab(familyId: account.id),
                _RidesTab(familyId: account.id),
                _AlertsTab(familyId: account.id),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, String familyName) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.primary,
      actions: [
        IconButton(
          icon: const Icon(Icons.emoji_events),
          tooltip: 'Achievements',
          onPressed: () => context.push(AppRoutes.familyAchievements),
        ),
        IconButton(
          icon: const Icon(Icons.map),
          tooltip: 'Live Map',
          onPressed: () => context.push(AppRoutes.familyMap),
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () => context.push(AppRoutes.familyGroups),
        ),
      ],
    );
  }

  Widget _buildStatsOverview(String familyId) {
    final locationsAsync = ref.watch(familyLocationsProvider(familyId));
    final activeRidesAsync = ref.watch(activeRidesProvider(familyId));
    final alertsAsync = ref.watch(familyAlertsProvider(familyId));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Overview',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.people,
                  label: 'Online',
                  value: locationsAsync.when(
                    data: (locs) => locs.where((l) => l.isOnline).length.toString(),
                    loading: () => '-',
                    error: (e, st) => '0',
                  ),
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: Icons.directions_bike,
                  label: 'Riding',
                  value: activeRidesAsync.when(
                    data: (rides) => rides.length.toString(),
                    loading: () => '-',
                    error: (e, st) => '0',
                  ),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: Icons.notifications_active,
                  label: 'Alerts',
                  value: alertsAsync.when(
                    data: (alerts) => alerts.length.toString(),
                    loading: () => '-',
                    error: (e, st) => '0',
                  ),
                  color: alertsAsync.when(
                    data: (alerts) => alerts.isNotEmpty ? Colors.orange : Colors.grey,
                    loading: () => Colors.grey,
                    error: (e, st) => Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;

  _TabBarDelegate({required this.tabController});

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        controller: tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.primary,
        tabs: const [
          Tab(icon: Icon(Icons.people), text: 'Members'),
          Tab(icon: Icon(Icons.route), text: 'Rides'),
          Tab(icon: Icon(Icons.notifications), text: 'Alerts'),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 72;

  @override
  double get minExtent => 72;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
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

// ==========================================
// Members Tab
// ==========================================

class _MembersTab extends ConsumerWidget {
  final String familyId;

  const _MembersTab({required this.familyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(familyLocationsProvider(familyId));

    return locationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (locations) {
        if (locations.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No one is sharing their location',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Sort: online first, then by name
        final sorted = [...locations]..sort((a, b) {
            if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
            if (a.isRiding != b.isRiding) return a.isRiding ? -1 : 1;
            return a.memberName.compareTo(b.memberName);
          });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sorted.length,
          itemBuilder: (context, index) {
            return _MemberActivityCard(location: sorted[index]);
          },
        );
      },
    );
  }
}

class _MemberActivityCard extends StatelessWidget {
  final MemberLocation location;

  const _MemberActivityCard({required this.location});

  @override
  Widget build(BuildContext context) {
    final speedKmh = (location.speed * 3.6).round();
    final lastSeen = _formatTimestamp(location.timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar with status
            Stack(
              children: [
                AppAvatar(
                  url: location.photoUrl,
                  thumbnailUrl: AppUser.getThumbnailUrl(location.photoUrl),
                  size: 56,
                  fallbackText: location.memberName.isNotEmpty
                      ? location.memberName[0].toUpperCase()
                      : '?',
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: location.isRiding
                          ? Colors.green
                          : location.isOnline
                              ? Colors.blue
                              : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: location.isRiding
                        ? const Icon(Icons.directions_bike, size: 10, color: Colors.white)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.memberName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _StatusChip(
                        icon: location.isRiding
                            ? Icons.directions_bike
                            : location.isOnline
                                ? Icons.wifi
                                : Icons.wifi_off,
                        label: location.isRiding
                            ? 'Riding'
                            : location.isOnline
                                ? 'Online'
                                : 'Offline',
                        color: location.isRiding
                            ? Colors.green
                            : location.isOnline
                                ? Colors.blue
                                : Colors.grey,
                      ),
                      if (location.isRiding) ...[
                        const SizedBox(width: 8),
                        _StatusChip(
                          icon: Icons.speed,
                          label: '$speedKmh km/h',
                          color: Colors.orange,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Last seen
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  lastSeen,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (location.currentRideId != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Active Ride',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(timestamp);
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// Rides Tab
// ==========================================

class _RidesTab extends ConsumerWidget {
  final String familyId;

  const _RidesTab({required this.familyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch active rides
    final activeRidesAsync = ref.watch(activeRidesProvider(familyId));

    return activeRidesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (activeRides) {
        return CustomScrollView(
          slivers: [
            // Active rides section
            if (activeRides.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Active Rides',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _RideCard(ride: activeRides[index], isActive: true),
                  ),
                  childCount: activeRides.length,
                ),
              ),
            ],

            // Recent rides heading
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Rides',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.familyRideHistory),
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),
            ),

            // Recent rides list (fetched separately)
            _RecentRidesList(familyId: familyId),
          ],
        );
      },
    );
  }
}

class _RecentRidesList extends ConsumerWidget {
  final String familyId;

  const _RecentRidesList({required this.familyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use a FutureProvider for ride history
    final rideHistoryAsync = ref.watch(
      FutureProvider<List<FamilyRide>>((ref) async {
        final service = ref.read(familyLocationServiceProvider);
        return service.getFamilyRideHistory(familyId, limit: 20);
      }),
    );

    return rideHistoryAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        )),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Center(child: Text('Error: $e')),
      ),
      data: (rides) {
        final completedRides = rides.where((r) => !r.isActive).toList();

        if (completedRides.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.directions_bike, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No completed rides yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _RideCard(ride: completedRides[index], isActive: false),
            ),
            childCount: completedRides.length,
          ),
        );
      },
    );
  }
}

class _RideCard extends StatelessWidget {
  final FamilyRide ride;
  final bool isActive;

  const _RideCard({required this.ride, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? const BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        dateFormat.format(ride.startTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 8,
                          height: 8,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Stats
            Row(
              children: [
                _RideStat(
                  icon: Icons.straighten,
                  label: 'Distance',
                  value: '${ride.distanceKm.toStringAsFixed(1)} km',
                ),
                const SizedBox(width: 24),
                _RideStat(
                  icon: Icons.timer,
                  label: 'Duration',
                  value: _formatDuration(ride.durationMinutes),
                ),
                const SizedBox(width: 24),
                _RideStat(
                  icon: Icons.speed,
                  label: 'Avg Speed',
                  value: '${ride.avgSpeedKmh.toStringAsFixed(1)} km/h',
                ),
              ],
            ),

            // Route preview placeholder
            if (ride.route.isNotEmpty && !isActive) ...[
              const SizedBox(height: 12),
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, color: Colors.grey[400]),
                      const SizedBox(width: 8),
                      Text(
                        'View Route',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }
}

class _RideStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _RideStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// Alerts Tab
// ==========================================

class _AlertsTab extends ConsumerWidget {
  final String familyId;

  const _AlertsTab({required this.familyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(familyAlertsProvider(familyId));

    return Column(
      children: [
        // Header with See All
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Alerts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.familyAlertHistory),
                child: const Text('See All History'),
              ),
            ],
          ),
        ),
        
        // Alerts list
        Expanded(
          child: alertsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (alerts) {
              if (alerts.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text(
                        'All clear! No active alerts',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  return _AlertCard(
                    alert: alerts[index],
                    familyId: familyId,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AlertCard extends ConsumerWidget {
  final FamilyAlert alert;
  final String familyId;

  const _AlertCard({
    required this.alert,
    required this.familyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _getAlertColor(alert.type);
    final icon = _getAlertIcon(alert.type);
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: _isUrgent(alert.type)
            ? BorderSide(color: color, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.memberName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        dateFormat.format(alert.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!alert.isResolved)
                  TextButton(
                    onPressed: () {
                      ref.read(familyLocationServiceProvider).resolveAlert(
                            familyId,
                            alert.id,
                          );
                    },
                    child: const Text('Resolve'),
                  ),
              ],
            ),

            // Message
            if (alert.message != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  alert.message!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],

            // Location link
            if (alert.location != null) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => context.push(AppRoutes.familyMap),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, size: 16, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'View Location',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Status badge
            if (alert.isResolved) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 14, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Resolved',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
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

  bool _isUrgent(FamilyAlertType type) {
    return type == FamilyAlertType.sosPressed ||
        type == FamilyAlertType.crashDetected;
  }
}
