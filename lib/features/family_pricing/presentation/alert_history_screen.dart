import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../application/family_location_service.dart';
import '../application/family_pricing_providers.dart';
import '../domain/family_location.dart';

/// Provider for alert history (includes resolved alerts)
final alertHistoryProvider = FutureProvider.family<List<FamilyAlert>, String>(
  (ref, familyId) async {
    final service = ref.read(familyLocationServiceProvider);
    // Get all alerts including resolved ones
    return service.getAlertHistory(familyId, limit: 100);
  },
);

/// Full alert history screen with filtering and resolution
class AlertHistoryScreen extends ConsumerStatefulWidget {
  const AlertHistoryScreen({super.key});

  @override
  ConsumerState<AlertHistoryScreen> createState() => _AlertHistoryScreenState();
}

class _AlertHistoryScreenState extends ConsumerState<AlertHistoryScreen> {
  FamilyAlertType? _typeFilter;
  bool _showResolvedOnly = false;
  bool _showUnresolvedOnly = false;

  @override
  Widget build(BuildContext context) {
    final familyAccountAsync = ref.watch(familyAccountProvider);

    return familyAccountAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Alert History')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (account) {
        if (account == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Alert History')),
            body: const Center(child: Text('No family account found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Alert History'),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterSheet(context),
              ),
            ],
          ),
          body: Column(
            children: [
              // Active filters indicator
              if (_typeFilter != null || _showResolvedOnly || _showUnresolvedOnly)
                _FilterIndicator(
                  typeFilter: _typeFilter,
                  showResolvedOnly: _showResolvedOnly,
                  showUnresolvedOnly: _showUnresolvedOnly,
                  onClear: () {
                    setState(() {
                      _typeFilter = null;
                      _showResolvedOnly = false;
                      _showUnresolvedOnly = false;
                    });
                  },
                ),

              // Alerts list
              Expanded(
                child: _AlertsList(
                  familyId: account.id,
                  typeFilter: _typeFilter,
                  showResolvedOnly: _showResolvedOnly,
                  showUnresolvedOnly: _showUnresolvedOnly,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AlertFilterSheet(
        typeFilter: _typeFilter,
        showResolvedOnly: _showResolvedOnly,
        showUnresolvedOnly: _showUnresolvedOnly,
        onTypeSelected: (type) {
          setState(() => _typeFilter = type);
          Navigator.pop(context);
        },
        onStatusSelected: (resolved, unresolved) {
          setState(() {
            _showResolvedOnly = resolved;
            _showUnresolvedOnly = unresolved;
          });
          Navigator.pop(context);
        },
        onClear: () {
          setState(() {
            _typeFilter = null;
            _showResolvedOnly = false;
            _showUnresolvedOnly = false;
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _FilterIndicator extends StatelessWidget {
  final FamilyAlertType? typeFilter;
  final bool showResolvedOnly;
  final bool showUnresolvedOnly;
  final VoidCallback onClear;

  const _FilterIndicator({
    this.typeFilter,
    required this.showResolvedOnly,
    required this.showUnresolvedOnly,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.primary.withValues(alpha: 0.05),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                if (typeFilter != null)
                  Chip(
                    label: Text(_getTypeName(typeFilter!)),
                    visualDensity: VisualDensity.compact,
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: onClear,
                  ),
                if (showResolvedOnly)
                  const Chip(
                    label: Text('Resolved'),
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(Icons.check_circle, size: 16, color: Colors.green),
                  ),
                if (showUnresolvedOnly)
                  const Chip(
                    label: Text('Unresolved'),
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(Icons.warning, size: 16, color: Colors.orange),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  String _getTypeName(FamilyAlertType type) {
    switch (type) {
      case FamilyAlertType.rideStarted:
        return 'Ride Started';
      case FamilyAlertType.rideEnded:
        return 'Ride Ended';
      case FamilyAlertType.sosPressed:
        return 'SOS';
      case FamilyAlertType.crashDetected:
        return 'Crash';
      case FamilyAlertType.enteredSafeZone:
        return 'Entered Zone';
      case FamilyAlertType.leftSafeZone:
        return 'Left Zone';
      case FamilyAlertType.lowBattery:
        return 'Low Battery';
      case FamilyAlertType.speedAlert:
        return 'Speed Alert';
      case FamilyAlertType.curfewViolation:
        return 'Curfew';
    }
  }
}

class _AlertFilterSheet extends StatelessWidget {
  final FamilyAlertType? typeFilter;
  final bool showResolvedOnly;
  final bool showUnresolvedOnly;
  final ValueChanged<FamilyAlertType?> onTypeSelected;
  final void Function(bool resolved, bool unresolved) onStatusSelected;
  final VoidCallback onClear;

  const _AlertFilterSheet({
    this.typeFilter,
    required this.showResolvedOnly,
    required this.showUnresolvedOnly,
    required this.onTypeSelected,
    required this.onStatusSelected,
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
                'Filter Alerts',
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

          // Alert type filter
          const Text(
            'Alert Type',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: typeFilter == null,
                onSelected: (_) => onTypeSelected(null),
              ),
              _TypeChip(
                type: FamilyAlertType.sosPressed,
                selected: typeFilter == FamilyAlertType.sosPressed,
                onSelected: (selected) =>
                    onTypeSelected(selected ? FamilyAlertType.sosPressed : null),
              ),
              _TypeChip(
                type: FamilyAlertType.crashDetected,
                selected: typeFilter == FamilyAlertType.crashDetected,
                onSelected: (selected) =>
                    onTypeSelected(selected ? FamilyAlertType.crashDetected : null),
              ),
              _TypeChip(
                type: FamilyAlertType.leftSafeZone,
                selected: typeFilter == FamilyAlertType.leftSafeZone,
                onSelected: (selected) =>
                    onTypeSelected(selected ? FamilyAlertType.leftSafeZone : null),
              ),
              _TypeChip(
                type: FamilyAlertType.rideStarted,
                selected: typeFilter == FamilyAlertType.rideStarted,
                onSelected: (selected) =>
                    onTypeSelected(selected ? FamilyAlertType.rideStarted : null),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Status filter
          const Text(
            'Status',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: !showResolvedOnly && !showUnresolvedOnly,
                onSelected: (_) => onStatusSelected(false, false),
              ),
              ChoiceChip(
                avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                label: const Text('Resolved'),
                selected: showResolvedOnly,
                onSelected: (selected) => onStatusSelected(selected, false),
              ),
              ChoiceChip(
                avatar: const Icon(Icons.warning, size: 16, color: Colors.orange),
                label: const Text('Unresolved'),
                selected: showUnresolvedOnly,
                onSelected: (selected) => onStatusSelected(false, selected),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final FamilyAlertType type;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _TypeChip({
    required this.type,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      avatar: Icon(_getIcon(type), size: 16, color: _getColor(type)),
      label: Text(_getName(type)),
      selected: selected,
      onSelected: onSelected,
    );
  }

  IconData _getIcon(FamilyAlertType type) {
    switch (type) {
      case FamilyAlertType.sosPressed:
        return Icons.emergency;
      case FamilyAlertType.crashDetected:
        return Icons.warning;
      case FamilyAlertType.leftSafeZone:
        return Icons.exit_to_app;
      case FamilyAlertType.rideStarted:
        return Icons.directions_bike;
      case FamilyAlertType.rideEnded:
        return Icons.flag;
      case FamilyAlertType.enteredSafeZone:
        return Icons.home;
      case FamilyAlertType.lowBattery:
        return Icons.battery_alert;
      case FamilyAlertType.speedAlert:
        return Icons.speed;
      case FamilyAlertType.curfewViolation:
        return Icons.nightlight;
    }
  }

  Color _getColor(FamilyAlertType type) {
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

  String _getName(FamilyAlertType type) {
    switch (type) {
      case FamilyAlertType.sosPressed:
        return 'SOS';
      case FamilyAlertType.crashDetected:
        return 'Crash';
      case FamilyAlertType.leftSafeZone:
        return 'Left Zone';
      case FamilyAlertType.rideStarted:
        return 'Ride Started';
      case FamilyAlertType.rideEnded:
        return 'Ride Ended';
      case FamilyAlertType.enteredSafeZone:
        return 'Entered Zone';
      case FamilyAlertType.lowBattery:
        return 'Low Battery';
      case FamilyAlertType.speedAlert:
        return 'Speed Alert';
      case FamilyAlertType.curfewViolation:
        return 'Curfew';
    }
  }
}

class _AlertsList extends ConsumerWidget {
  final String familyId;
  final FamilyAlertType? typeFilter;
  final bool showResolvedOnly;
  final bool showUnresolvedOnly;

  const _AlertsList({
    required this.familyId,
    this.typeFilter,
    required this.showResolvedOnly,
    required this.showUnresolvedOnly,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertHistoryProvider(familyId));

    return alertsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (alerts) {
        // Apply filters
        var filteredAlerts = alerts;

        if (typeFilter != null) {
          filteredAlerts = filteredAlerts.where((a) => a.type == typeFilter).toList();
        }

        if (showResolvedOnly) {
          filteredAlerts = filteredAlerts.where((a) => a.isResolved).toList();
        } else if (showUnresolvedOnly) {
          filteredAlerts = filteredAlerts.where((a) => !a.isResolved).toList();
        }

        if (filteredAlerts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text(
                  'No alerts found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                if (typeFilter != null || showResolvedOnly || showUnresolvedOnly) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your filters',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          );
        }

        // Group by date
        final grouped = <String, List<FamilyAlert>>{};
        final dateFormat = DateFormat('MMMM d, yyyy');

        for (final alert in filteredAlerts) {
          final key = dateFormat.format(alert.timestamp);
          grouped.putIfAbsent(key, () => []).add(alert);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: grouped.length,
          itemBuilder: (context, index) {
            final entry = grouped.entries.elementAt(index);
            return _DateSection(
              date: entry.key,
              alerts: entry.value,
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
  final List<FamilyAlert> alerts;
  final String familyId;

  const _DateSection({
    required this.date,
    required this.alerts,
    required this.familyId,
  });

  @override
  Widget build(BuildContext context) {
    final urgentCount = alerts.where((a) =>
        a.type == FamilyAlertType.sosPressed ||
        a.type == FamilyAlertType.crashDetected).length;

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
              Row(
                children: [
                  if (urgentCount > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning, size: 12, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            '$urgentCount urgent',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${alerts.length} alerts',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Alerts
        ...alerts.map((alert) => _AlertDetailCard(
              alert: alert,
              familyId: familyId,
            )),

        const SizedBox(height: 8),
      ],
    );
  }
}

class _AlertDetailCard extends ConsumerWidget {
  final FamilyAlert alert;
  final String familyId;

  const _AlertDetailCard({
    required this.alert,
    required this.familyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFormat = DateFormat('h:mm a');
    final color = _getAlertColor(alert.type);
    final isUrgent = alert.type == FamilyAlertType.sosPressed ||
        alert.type == FamilyAlertType.crashDetected;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUrgent && !alert.isResolved
            ? BorderSide(color: color, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAlertDetails(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getAlertIcon(alert.type),
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info
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
                          _getAlertTitle(alert.type),
                          style: TextStyle(
                            fontSize: 13,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Time and status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeFormat.format(alert.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: alert.isResolved
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              alert.isResolved ? Icons.check_circle : Icons.schedule,
                              size: 12,
                              color: alert.isResolved ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              alert.isResolved ? 'Resolved' : 'Open',
                              style: TextStyle(
                                fontSize: 11,
                                color: alert.isResolved ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

              // Actions
              if (!alert.isResolved) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (alert.location != null)
                      TextButton.icon(
                        icon: const Icon(Icons.map, size: 16),
                        label: const Text('View Location'),
                        onPressed: () => context.push(AppRoutes.familyMap),
                      ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Resolve'),
                      onPressed: () {
                        ref.read(familyLocationServiceProvider).resolveAlert(
                              familyId,
                              alert.id,
                            );
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAlertDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AlertDetailSheet(
        alert: alert,
        familyId: familyId,
        onResolve: () {
          ref.read(familyLocationServiceProvider).resolveAlert(
                familyId,
                alert.id,
              );
          Navigator.pop(context);
        },
        onViewLocation: () {
          Navigator.pop(context);
          context.push(AppRoutes.familyMap);
        },
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

  String _getAlertTitle(FamilyAlertType type) {
    switch (type) {
      case FamilyAlertType.rideStarted:
        return 'Started a ride';
      case FamilyAlertType.rideEnded:
        return 'Finished riding';
      case FamilyAlertType.sosPressed:
        return '🆘 SOS Alert';
      case FamilyAlertType.crashDetected:
        return '⚠️ Crash Detected';
      case FamilyAlertType.enteredSafeZone:
        return 'Arrived at safe zone';
      case FamilyAlertType.leftSafeZone:
        return 'Left safe zone';
      case FamilyAlertType.lowBattery:
        return 'Low battery';
      case FamilyAlertType.speedAlert:
        return 'Speed warning';
      case FamilyAlertType.curfewViolation:
        return 'Curfew violation';
    }
  }
}

class _AlertDetailSheet extends StatelessWidget {
  final FamilyAlert alert;
  final String familyId;
  final VoidCallback onResolve;
  final VoidCallback onViewLocation;

  const _AlertDetailSheet({
    required this.alert,
    required this.familyId,
    required this.onResolve,
    required this.onViewLocation,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm:ss a');
    final color = _getAlertColor(alert.type);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getAlertIcon(alert.type),
              size: 40,
              color: color,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            _getAlertTitle(alert.type),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),

          // Member name
          Text(
            alert.memberName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),

          // Timestamp
          Text(
            '${dateFormat.format(alert.timestamp)} at ${timeFormat.format(alert.timestamp)}',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),

          // Message
          if (alert.message != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                alert.message!,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: alert.isResolved
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: alert.isResolved
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  alert.isResolved ? Icons.check_circle : Icons.schedule,
                  color: alert.isResolved ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  alert.isResolved ? 'This alert has been resolved' : 'This alert is still open',
                  style: TextStyle(
                    color: alert.isResolved ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              if (alert.location != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text('View on Map'),
                    onPressed: onViewLocation,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (!alert.isResolved)
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Resolve Alert'),
                    onPressed: onResolve,
                  ),
                ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
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

  String _getAlertTitle(FamilyAlertType type) {
    switch (type) {
      case FamilyAlertType.rideStarted:
        return 'Ride Started';
      case FamilyAlertType.rideEnded:
        return 'Ride Ended';
      case FamilyAlertType.sosPressed:
        return 'SOS Emergency';
      case FamilyAlertType.crashDetected:
        return 'Crash Detected';
      case FamilyAlertType.enteredSafeZone:
        return 'Entered Safe Zone';
      case FamilyAlertType.leftSafeZone:
        return 'Left Safe Zone';
      case FamilyAlertType.lowBattery:
        return 'Low Battery';
      case FamilyAlertType.speedAlert:
        return 'Speed Alert';
      case FamilyAlertType.curfewViolation:
        return 'Curfew Violation';
    }
  }
}
