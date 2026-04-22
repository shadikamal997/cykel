import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../application/family_location_service.dart';
import '../domain/family_location.dart';

/// Provider for family statistics calculation
final familyStatisticsProvider = FutureProvider.family<FamilyStatistics, String>(
  (ref, familyId) async {
    final service = ref.read(familyLocationServiceProvider);

    // Get ride history for different time periods
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    final allRides = await service.getFamilyRideHistory(familyId, limit: 500);

    // Calculate statistics
    final todayRides = allRides.where((r) => r.startTime.isAfter(todayStart)).toList();
    final weekRides = allRides.where((r) => r.startTime.isAfter(weekStart)).toList();
    final monthRides = allRides.where((r) => r.startTime.isAfter(monthStart)).toList();

    return FamilyStatistics(
      todayRides: todayRides.length,
      todayDistance: todayRides.fold(0.0, (sum, r) => sum + r.distanceKm),
      todayDuration: todayRides.fold(0, (sum, r) => sum + r.durationMinutes),
      weekRides: weekRides.length,
      weekDistance: weekRides.fold(0.0, (sum, r) => sum + r.distanceKm),
      weekDuration: weekRides.fold(0, (sum, r) => sum + r.durationMinutes),
      monthRides: monthRides.length,
      monthDistance: monthRides.fold(0.0, (sum, r) => sum + r.distanceKm),
      monthDuration: monthRides.fold(0, (sum, r) => sum + r.durationMinutes),
      totalRides: allRides.length,
      totalDistance: allRides.fold(0.0, (sum, r) => sum + r.distanceKm),
      totalDuration: allRides.fold(0, (sum, r) => sum + r.durationMinutes),
      memberStats: _calculateMemberStats(allRides),
    );
  },
);

Map<String, MemberStatistics> _calculateMemberStats(List<FamilyRide> rides) {
  final stats = <String, MemberStatistics>{};

  for (final ride in rides) {
    final existing = stats[ride.memberId];
    if (existing != null) {
      stats[ride.memberId] = MemberStatistics(
        memberId: ride.memberId,
        memberName: ride.memberName,
        rideCount: existing.rideCount + 1,
        totalDistance: existing.totalDistance + ride.distanceKm,
        totalDuration: existing.totalDuration + ride.durationMinutes,
        maxSpeed: ride.maxSpeedKmh > existing.maxSpeed ? ride.maxSpeedKmh : existing.maxSpeed,
      );
    } else {
      stats[ride.memberId] = MemberStatistics(
        memberId: ride.memberId,
        memberName: ride.memberName,
        rideCount: 1,
        totalDistance: ride.distanceKm,
        totalDuration: ride.durationMinutes,
        maxSpeed: ride.maxSpeedKmh,
      );
    }
  }

  return stats;
}

class FamilyStatistics {
  final int todayRides;
  final double todayDistance;
  final int todayDuration;
  final int weekRides;
  final double weekDistance;
  final int weekDuration;
  final int monthRides;
  final double monthDistance;
  final int monthDuration;
  final int totalRides;
  final double totalDistance;
  final int totalDuration;
  final Map<String, MemberStatistics> memberStats;

  const FamilyStatistics({
    required this.todayRides,
    required this.todayDistance,
    required this.todayDuration,
    required this.weekRides,
    required this.weekDistance,
    required this.weekDuration,
    required this.monthRides,
    required this.monthDistance,
    required this.monthDuration,
    required this.totalRides,
    required this.totalDistance,
    required this.totalDuration,
    required this.memberStats,
  });

  double get averageRideDistance =>
      totalRides > 0 ? totalDistance / totalRides : 0;

  int get averageRideDuration =>
      totalRides > 0 ? totalDuration ~/ totalRides : 0;
}

class MemberStatistics {
  final String memberId;
  final String memberName;
  final int rideCount;
  final double totalDistance;
  final int totalDuration;
  final double maxSpeed;

  const MemberStatistics({
    required this.memberId,
    required this.memberName,
    required this.rideCount,
    required this.totalDistance,
    required this.totalDuration,
    required this.maxSpeed,
  });
}

// ==========================================
// Widgets
// ==========================================

/// Detailed statistics card with time period breakdown
class FamilyStatisticsCard extends ConsumerWidget {
  final String familyId;

  const FamilyStatisticsCard({super.key, required this.familyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(familyStatisticsProvider(familyId));

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: statsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $e'),
        ),
        data: (stats) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bar_chart, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Family Statistics',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Time period stats
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _TimePeriodRow(
                    period: 'Today',
                    rides: stats.todayRides,
                    distance: stats.todayDistance,
                    duration: stats.todayDuration,
                    color: Colors.blue,
                  ),
                  const Divider(height: 24),
                  _TimePeriodRow(
                    period: 'This Week',
                    rides: stats.weekRides,
                    distance: stats.weekDistance,
                    duration: stats.weekDuration,
                    color: Colors.green,
                  ),
                  const Divider(height: 24),
                  _TimePeriodRow(
                    period: 'This Month',
                    rides: stats.monthRides,
                    distance: stats.monthDistance,
                    duration: stats.monthDuration,
                    color: Colors.orange,
                  ),
                  const Divider(height: 24),
                  _TimePeriodRow(
                    period: 'All Time',
                    rides: stats.totalRides,
                    distance: stats.totalDistance,
                    duration: stats.totalDuration,
                    color: AppColors.primary,
                    isHighlighted: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePeriodRow extends StatelessWidget {
  final String period;
  final int rides;
  final double distance;
  final int duration;
  final Color color;
  final bool isHighlighted;

  const _TimePeriodRow({
    required this.period,
    required this.rides,
    required this.distance,
    required this.duration,
    required this.color,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: isHighlighted ? const EdgeInsets.all(12) : null,
      decoration: isHighlighted
          ? BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            )
          : null,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              period,
              style: TextStyle(
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                fontSize: isHighlighted ? 16 : 14,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '$rides',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: isHighlighted ? 18 : 16,
                  ),
                ),
                Text(
                  'rides',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  distance.toStringAsFixed(1),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: isHighlighted ? 18 : 16,
                  ),
                ),
                Text(
                  'km',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _formatDuration(duration),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: isHighlighted ? 18 : 16,
                  ),
                ),
                Text(
                  'time',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    if (hours < 24) {
      if (remainingMins == 0) return '${hours}h';
      return '${hours}h ${remainingMins}m';
    }
    final days = hours ~/ 24;
    return '${days}d';
  }
}

/// Leaderboard widget showing top riders
class FamilyLeaderboard extends ConsumerWidget {
  final String familyId;

  const FamilyLeaderboard({super.key, required this.familyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(familyStatisticsProvider(familyId));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: statsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $e'),
        ),
        data: (stats) {
          final sortedMembers = stats.memberStats.values.toList()
            ..sort((a, b) => b.totalDistance.compareTo(a.totalDistance));

          if (sortedMembers.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.emoji_events, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(context.l10n.familyNoRidesYet, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber),
                    SizedBox(width: 12),
                    Text(
                      'Leaderboard',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ...sortedMembers.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final member = entry.value;
                return _LeaderboardItem(
                  rank: rank,
                  memberName: member.memberName,
                  distance: member.totalDistance,
                  rideCount: member.rideCount,
                );
              }),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

class _LeaderboardItem extends StatelessWidget {
  final int rank;
  final String memberName;
  final double distance;
  final int rideCount;

  const _LeaderboardItem({
    required this.rank,
    required this.memberName,
    required this.distance,
    required this.rideCount,
  });

  @override
  Widget build(BuildContext context) {
    final medalColors = {
      1: Colors.amber,
      2: Colors.grey,
      3: Colors.brown,
    };
    final medalColor = medalColors[rank];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rank == 1
            ? Colors.amber.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: rank == 1
            ? Border.all(color: Colors.amber.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: medalColor ?? AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: medalColor != null
                  ? Icon(Icons.emoji_events, size: 18, color: medalColor)
                  : Text(
                      '$rank',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memberName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '$rideCount rides',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Distance
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${distance.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'total',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Weekly activity chart widget
class WeeklyActivityChart extends ConsumerWidget {
  final String familyId;

  const WeeklyActivityChart({super.key, required this.familyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_weeklyActivityProvider(familyId));

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.primary),
                SizedBox(width: 12),
                Text(
                  'Weekly Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (dailyData) {
                final maxValue = dailyData.values.fold(0.0, (max, val) => val > max ? val : max);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: dailyData.entries.map((entry) {
                    final height = maxValue > 0 ? (entry.value / maxValue) * 80 : 0.0;
                    return _DayColumn(
                      day: entry.key,
                      distance: entry.value,
                      height: height,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

final _weeklyActivityProvider = FutureProvider.family<Map<String, double>, String>(
  (ref, familyId) async {
    final service = ref.read(familyLocationServiceProvider);
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    final rides = await service.getFamilyRideHistory(
      familyId,
      since: weekStart,
      limit: 200,
    );

    // Group by day of week
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final result = <String, double>{};

    for (final name in dayNames) {
      result[name] = 0.0;
    }

    for (final ride in rides) {
      final dayIndex = ride.startTime.weekday - 1; // 0-6
      if (dayIndex >= 0 && dayIndex < 7) {
        result[dayNames[dayIndex]] = (result[dayNames[dayIndex]] ?? 0) + ride.distanceKm;
      }
    }

    return result;
  },
);

class _DayColumn extends StatelessWidget {
  final String day;
  final double distance;
  final double height;

  const _DayColumn({
    required this.day,
    required this.distance,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(day);

    return Column(
      children: [
        if (distance > 0)
          Text(
            distance.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isToday ? AppColors.primary : Colors.grey[600],
            ),
          )
        else
          const SizedBox(height: 14),
        const SizedBox(height: 4),
        Container(
          width: 32,
          height: height.clamp(4.0, 80.0),
          decoration: BoxDecoration(
            color: isToday ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            color: isToday ? AppColors.primary : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  bool _isToday(String dayName) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayIndex = DateTime.now().weekday - 1;
    final dayIndex = dayNames.indexOf(dayName);
    return todayIndex == dayIndex;
  }
}

/// Alert history widget
class AlertHistoryList extends ConsumerWidget {
  final String familyId;
  final int limit;

  const AlertHistoryList({
    super.key,
    required this.familyId,
    this.limit = 10,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(familyAlertsProvider(familyId));

    return alertsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (alerts) {
        if (alerts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(Icons.check_circle, size: 48, color: Colors.green),
                const SizedBox(height: 12),
                Text(context.l10n.familyNoRecentAlerts, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final displayAlerts = alerts.take(limit).toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayAlerts.length,
          itemBuilder: (context, index) {
            final alert = displayAlerts[index];
            return _CompactAlertItem(alert: alert);
          },
        );
      },
    );
  }
}

class _CompactAlertItem extends StatelessWidget {
  final FamilyAlert alert;

  const _CompactAlertItem({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = _getAlertColor(alert.type);
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getAlertIcon(alert.type), size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.memberName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  _getAlertTitle(alert.type),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dateFormat.format(alert.timestamp),
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              if (alert.isResolved)
                const Icon(Icons.check_circle, size: 14, color: Colors.green),
            ],
          ),
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
