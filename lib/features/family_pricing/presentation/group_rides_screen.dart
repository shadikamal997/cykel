import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/providers/auth_providers.dart';
import '../application/family_extras_service.dart';
import '../application/family_pricing_providers.dart';
import '../domain/family_extras.dart';

/// Screen showing group rides for the family
class GroupRidesScreen extends ConsumerWidget {
  const GroupRidesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAccountAsync = ref.watch(familyAccountProvider);

    return familyAccountAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Group Rides')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (account) {
        if (account == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Group Rides')),
            body: const Center(child: Text('No family account found')),
          );
        }

        return _GroupRidesContent(familyId: account.id);
      },
    );
  }
}

class _GroupRidesContent extends ConsumerStatefulWidget {
  final String familyId;

  const _GroupRidesContent({required this.familyId});

  @override
  ConsumerState<_GroupRidesContent> createState() => _GroupRidesContentState();
}

class _GroupRidesContentState extends ConsumerState<_GroupRidesContent>
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Rides'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Active'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UpcomingTab(familyId: widget.familyId),
          _ActiveTab(familyId: widget.familyId),
          _PastTab(familyId: widget.familyId),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateRideSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Plan Ride'),
      ),
    );
  }

  void _showCreateRideSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CreateGroupRideSheet(familyId: widget.familyId),
    );
  }
}

// ==========================================
// Upcoming Tab
// ==========================================

class _UpcomingTab extends ConsumerWidget {
  final String familyId;

  const _UpcomingTab({required this.familyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridesAsync = ref.watch(upcomingRidesProvider(familyId));

    return ridesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (rides) {
        if (rides.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No upcoming rides',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Plan a group ride for your family!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            return _GroupRideCard(ride: rides[index], familyId: familyId);
          },
        );
      },
    );
  }
}

// ==========================================
// Active Tab
// ==========================================

class _ActiveTab extends ConsumerWidget {
  final String familyId;

  const _ActiveTab({required this.familyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridesAsync = ref.watch(activeGroupRidesProvider(familyId));

    return ridesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (rides) {
        if (rides.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_bike, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No active rides',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            return _GroupRideCard(
              ride: rides[index],
              familyId: familyId,
              isActive: true,
            );
          },
        );
      },
    );
  }
}

// ==========================================
// Past Tab
// ==========================================

class _PastTab extends ConsumerWidget {
  final String familyId;

  const _PastTab({required this.familyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridesAsync = ref.watch(completedGroupRidesProvider(familyId));

    return ridesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (rides) {
        if (rides.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No past rides',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            return _GroupRideCard(
              ride: rides[index],
              familyId: familyId,
              isPast: true,
            );
          },
        );
      },
    );
  }
}

// ==========================================
// Group Ride Card
// ==========================================

class _GroupRideCard extends ConsumerWidget {
  final GroupRide ride;
  final String familyId;
  final bool isActive;
  final bool isPast;

  const _GroupRideCard({
    required this.ride,
    required this.familyId,
    this.isActive = false,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('EEE, MMM d');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isActive
            ? const BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showRideDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Type icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ride.typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      ride.typeIcon,
                      color: ride.typeColor,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and organizer
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'by ${ride.organizerName}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ride.typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ride.typeName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ride.typeColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date, time, distance
              Row(
                children: [
                  _InfoItem(
                    icon: Icons.calendar_today,
                    label: dateFormat.format(ride.scheduledStart),
                  ),
                  const SizedBox(width: 16),
                  _InfoItem(
                    icon: Icons.access_time,
                    label: timeFormat.format(ride.scheduledStart),
                  ),
                  const SizedBox(width: 16),
                  _InfoItem(
                    icon: Icons.straighten,
                    label: '${ride.plannedDistanceKm.toStringAsFixed(1)} km',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Location
              if (ride.startAddress != null) ...[
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ride.startAddress!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Participants
              _ParticipantsRow(participants: ride.participants),

              if (!isPast) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                // Actions
                _RideActions(ride: ride, familyId: familyId, isActive: isActive),
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
      builder: (context) => _GroupRideDetailSheet(ride: ride, familyId: familyId),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _ParticipantsRow extends StatelessWidget {
  final List<GroupRideParticipant> participants;

  const _ParticipantsRow({required this.participants});

  @override
  Widget build(BuildContext context) {
    final confirmed = participants
        .where((p) =>
            p.status == ParticipantStatus.confirmed ||
            p.status == ParticipantStatus.joined ||
            p.status == ParticipantStatus.finished)
        .toList();

    return Row(
      children: [
        // Avatars stack
        SizedBox(
          width: 60,
          height: 32,
          child: Stack(
            children: [
              for (var i = 0; i < confirmed.take(3).length; i++)
                Positioned(
                  left: i * 20.0,
                  child: AppAvatar(
                    url: confirmed[i].photoUrl,
                    thumbnailUrl: AppUser.getThumbnailUrl(confirmed[i].photoUrl),
                    size: 32,
                    fallbackText: confirmed[i].memberName.isNotEmpty
                        ? confirmed[i].memberName[0].toUpperCase()
                        : '?',
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${confirmed.length} confirmed',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        if (participants.any((p) => p.needsAssistance)) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning, size: 14, color: Colors.red),
                SizedBox(width: 4),
                Text(
                  'Needs help',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _RideActions extends ConsumerWidget {
  final GroupRide ride;
  final String familyId;
  final bool isActive;

  const _RideActions({
    required this.ride,
    required this.familyId,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserProvider)?.uid;
    final isOrganizer = ride.organizerId == currentUserId;
    final hasJoined = ride.participants.any((p) => p.memberId == currentUserId);

    if (isActive) {
      return Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => context.push(AppRoutes.familyMap),
              icon: const Icon(Icons.map),
              label: const Text('View on Map'),
            ),
          ),
          if (isOrganizer) ...[
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => _endRide(context, ref),
              icon: const Icon(Icons.flag),
              label: const Text('End'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        if (!hasJoined && ride.canJoin) ...[
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _joinRide(context, ref),
              icon: const Icon(Icons.group_add),
              label: const Text('Join'),
            ),
          ),
        ],
        if (hasJoined && !isOrganizer) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _leaveRide(context, ref),
              icon: const Icon(Icons.logout),
              label: const Text('Leave'),
            ),
          ),
        ],
        if (isOrganizer) ...[
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _startRide(context, ref),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Ride'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _cancelRide(context, ref),
            icon: const Icon(Icons.close, color: Colors.red),
            tooltip: 'Cancel',
          ),
        ],
      ],
    );
  }

  Future<void> _joinRide(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(familyExtrasServiceProvider);
      await service.joinGroupRide(familyId, ride.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You\'ve joined the ride!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _leaveRide(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(familyExtrasServiceProvider);
      await service.leaveGroupRide(familyId, ride.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You\'ve left the ride')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _startRide(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(familyExtrasServiceProvider);
      await service.startGroupRide(familyId, ride.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride started! 🚴')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _endRide(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Ride'),
        content: const Text('Are you sure you want to end this ride for everyone?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End Ride'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final service = ref.read(familyExtrasServiceProvider);
      await service.endGroupRide(familyId, ride.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride completed! 🎉')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _cancelRide(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Ride'),
        content: const Text('Are you sure you want to cancel this ride? All participants will be notified.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Ride'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final service = ref.read(familyExtrasServiceProvider);
      await service.cancelGroupRide(familyId, ride.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride cancelled')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

// ==========================================
// Group Ride Detail Sheet
// ==========================================

class _GroupRideDetailSheet extends StatelessWidget {
  final GroupRide ride;
  final String familyId;

  const _GroupRideDetailSheet({
    required this.ride,
    required this.familyId,
  });

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

            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ride.typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(ride.typeIcon, color: ride.typeColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${ride.typeName} ride by ${ride.organizerName}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  if (ride.description != null) ...[
                    Text(
                      ride.description!,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Details card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: Icons.calendar_today,
                            label: 'Date',
                            value: dateFormat.format(ride.scheduledStart),
                          ),
                          const Divider(),
                          _DetailRow(
                            icon: Icons.access_time,
                            label: 'Time',
                            value: timeFormat.format(ride.scheduledStart),
                          ),
                          const Divider(),
                          _DetailRow(
                            icon: Icons.straighten,
                            label: 'Distance',
                            value: '${ride.plannedDistanceKm.toStringAsFixed(1)} km',
                          ),
                          const Divider(),
                          _DetailRow(
                            icon: Icons.timer,
                            label: 'Est. Duration',
                            value: '${ride.estimatedDurationMinutes} min',
                          ),
                          if (ride.startAddress != null) ...[
                            const Divider(),
                            _DetailRow(
                              icon: Icons.location_on,
                              label: 'Start',
                              value: ride.startAddress!,
                            ),
                          ],
                          if (ride.endAddress != null) ...[
                            const Divider(),
                            _DetailRow(
                              icon: Icons.flag,
                              label: 'End',
                              value: ride.endAddress!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Participants
                  const Text(
                    'Participants',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...ride.participants.map((p) => _ParticipantTile(participant: p)),

                  if (ride.notes != null) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ride.notes!,
                      style: TextStyle(color: Colors.grey[700]),
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
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final GroupRideParticipant participant;

  const _ParticipantTile({required this.participant});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AppAvatar(
        url: participant.photoUrl,
        thumbnailUrl: AppUser.getThumbnailUrl(participant.photoUrl),
        size: 40,
        fallbackText: participant.memberName.isNotEmpty
            ? participant.memberName[0].toUpperCase()
            : '?',
      ),
      title: Row(
        children: [
          Text(participant.memberName),
          if (participant.isOrganizer) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Organizer',
                style: TextStyle(fontSize: 10, color: Colors.amber),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(_getStatusText(participant.status)),
      trailing: participant.needsAssistance
          ? const Icon(Icons.warning, color: Colors.red)
          : null,
    );
  }

  String _getStatusText(ParticipantStatus status) {
    switch (status) {
      case ParticipantStatus.invited:
        return 'Invited';
      case ParticipantStatus.confirmed:
        return 'Confirmed';
      case ParticipantStatus.declined:
        return 'Declined';
      case ParticipantStatus.joined:
        return 'Riding';
      case ParticipantStatus.finished:
        return 'Finished';
      case ParticipantStatus.leftEarly:
        return 'Left early';
    }
  }
}

// ==========================================
// Create Group Ride Sheet
// ==========================================

class _CreateGroupRideSheet extends ConsumerStatefulWidget {
  final String familyId;

  const _CreateGroupRideSheet({required this.familyId});

  @override
  ConsumerState<_CreateGroupRideSheet> createState() => _CreateGroupRideSheetState();
}

class _CreateGroupRideSheetState extends ConsumerState<_CreateGroupRideSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  GroupRideType _type = GroupRideType.casual;
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _scheduledTime = const TimeOfDay(hour: 10, minute: 0);
  double _plannedDistance = 5.0;
  int _estimatedDuration = 30;
  bool _allowGuests = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
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
              const Text(
                'Plan Group Ride',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Form
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Title field
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Ride Title',
                          hintText: 'e.g. Weekend Family Ride',
                          prefixIcon: Icon(Icons.title),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Ride type
                      const Text(
                        'Ride Type',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: GroupRideType.values.map((type) {
                          final isSelected = _type == type;
                          return ChoiceChip(
                            label: Text(_getTypeName(type)),
                            selected: isSelected,
                            avatar: Icon(
                              _getTypeIcon(type),
                              size: 18,
                              color: isSelected ? Colors.white : Colors.grey,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _type = type);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Date and time
                      Row(
                        children: [
                          Expanded(
                            child: _DateField(
                              date: _scheduledDate,
                              onChanged: (date) => setState(() => _scheduledDate = date),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _TimeField(
                              time: _scheduledTime,
                              onChanged: (time) => setState(() => _scheduledTime = time),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Start location
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Meeting Point',
                          hintText: 'Enter address or location name',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Distance and duration
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Distance: ${_plannedDistance.toStringAsFixed(1)} km'),
                                Slider(
                                  value: _plannedDistance,
                                  min: 1,
                                  max: 50,
                                  divisions: 49,
                                  onChanged: (v) => setState(() => _plannedDistance = v),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Duration: $_estimatedDuration min'),
                                Slider(
                                  value: _estimatedDuration.toDouble(),
                                  min: 15,
                                  max: 180,
                                  divisions: 33,
                                  onChanged: (v) =>
                                      setState(() => _estimatedDuration = v.toInt()),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'Describe the route or add details',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Allow guests
                      SwitchListTile(
                        title: const Text('Allow Guest Riders'),
                        subtitle: const Text('Let guests join this ride'),
                        value: _allowGuests,
                        onChanged: (v) => setState(() => _allowGuests = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),

              // Create button
              SafeArea(
                child: FilledButton(
                  onPressed: _isLoading ? null : _createRide,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Ride'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getTypeName(GroupRideType type) {
    switch (type) {
      case GroupRideType.casual:
        return 'Casual';
      case GroupRideType.fitness:
        return 'Fitness';
      case GroupRideType.commute:
        return 'Commute';
      case GroupRideType.adventure:
        return 'Adventure';
      case GroupRideType.training:
        return 'Training';
    }
  }

  IconData _getTypeIcon(GroupRideType type) {
    switch (type) {
      case GroupRideType.casual:
        return Icons.family_restroom;
      case GroupRideType.fitness:
        return Icons.fitness_center;
      case GroupRideType.commute:
        return Icons.work;
      case GroupRideType.adventure:
        return Icons.explore;
      case GroupRideType.training:
        return Icons.school;
    }
  }

  Future<void> _createRide() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final scheduledStart = DateTime(
        _scheduledDate.year,
        _scheduledDate.month,
        _scheduledDate.day,
        _scheduledTime.hour,
        _scheduledTime.minute,
      );

      final service = ref.read(familyExtrasServiceProvider);
      await service.createGroupRide(
        familyId: widget.familyId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        type: _type,
        scheduledStart: scheduledStart,
        // Using default Amsterdam coordinates for now
        startLocation: const LatLng(52.3676, 4.9041),
        startAddress: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        plannedDistanceKm: _plannedDistance,
        estimatedDurationMinutes: _estimatedDuration,
        allowGuests: _allowGuests,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group ride created!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _DateField extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _DateField({
    required this.date,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          prefixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(),
        ),
        child: Text(DateFormat('MMM d, yyyy').format(date)),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;

  const _TimeField({
    required this.time,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Time',
          prefixIcon: Icon(Icons.access_time),
          border: OutlineInputBorder(),
        ),
        child: Text(time.format(context)),
      ),
    );
  }
}
