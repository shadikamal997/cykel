import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../application/family_location_service.dart';
import '../application/family_pricing_providers.dart';
import '../domain/family_location.dart';

/// Screen for managing family safe zones (geofences)
class SafeZonesScreen extends ConsumerWidget {
  const SafeZonesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAccountAsync = ref.watch(familyAccountProvider);

    return familyAccountAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.safeZones)),
        body: Center(child: Text(context.l10n.errorOccurred(error.toString()))),
      ),
      data: (account) {
        if (account == null) {
          return Scaffold(
            appBar: AppBar(title: Text(context.l10n.safeZones)),
            body: Center(child: Text(context.l10n.noFamilyAccount)),
          );
        }

        return _SafeZonesContent(familyId: account.id);
      },
    );
  }
}

class _SafeZonesContent extends ConsumerWidget {
  final String familyId;

  const _SafeZonesContent({required this.familyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeZonesAsync = ref.watch(safeZonesProvider(familyId));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.safeZones),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: safeZonesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.errorOccurred(e.toString()))),
        data: (zones) {
          if (zones.isEmpty) {
            return _EmptyState(
              onAddZone: () => _navigateToAddZone(context),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: zones.length + 1, // +1 for header card
            itemBuilder: (context, index) {
              if (index == 0) {
                return _InfoCard(zoneCount: zones.length);
              }
              return _SafeZoneTile(
                zone: zones[index - 1],
                onTap: () => _navigateToEditZone(context, zones[index - 1]),
                onDelete: () => _deleteZone(context, ref, zones[index - 1]),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddZone(context),
        icon: const Icon(Icons.add_location_alt),
        label: Text(context.l10n.addZone),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _navigateToAddZone(BuildContext context) {
    context.push(AppRoutes.familySafeZoneEdit);
  }

  void _navigateToEditZone(BuildContext context, SafeZone zone) {
    context.push(AppRoutes.familySafeZoneEdit, extra: zone);
  }

  Future<void> _deleteZone(
    BuildContext context,
    WidgetRef ref,
    SafeZone zone,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteSafeZone),
        content: Text(
          context.l10n.deleteSafeZoneConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(familyLocationServiceProvider).deleteSafeZone(
            familyId,
            zone.id,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.zoneDeleted(zone.name))),
        );
      }
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.help, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(context.l10n.aboutSafeZones),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Safe zones are virtual boundaries that help you keep track of family members.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              _HelpItem(
                icon: Icons.location_on,
                title: 'Set locations',
                description: 'Mark important places like home, school, or work.',
              ),
              _HelpItem(
                icon: Icons.notifications_active,
                title: 'Get alerts',
                description: 'Receive notifications when family members enter or leave zones.',
              ),
              _HelpItem(
                icon: Icons.people,
                title: 'Per-member settings',
                description: 'Choose which family members each zone applies to.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.gotIt),
          ),
        ],
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _HelpItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddZone;

  const _EmptyState({required this.onAddZone});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Safe Zones Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add safe zones to get notified when family members arrive at or leave important places.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddZone,
              icon: const Icon(Icons.add_location_alt),
              label: Text(context.l10n.addFirstZone),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final int zoneCount;

  const _InfoCard({required this.zoneCount});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$zoneCount Safe Zone${zoneCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap a zone to edit or view details',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
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

class _SafeZoneTile extends StatelessWidget {
  final SafeZone zone;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SafeZoneTile({
    required this.zone,
    required this.onTap,
    required this.onDelete,
  });

  IconData get _zoneIcon {
    final name = zone.name.toLowerCase();
    if (name.contains('home')) return Icons.home;
    if (name.contains('school')) return Icons.school;
    if (name.contains('work') || name.contains('office')) return Icons.work;
    if (name.contains('gym') || name.contains('sport')) return Icons.fitness_center;
    if (name.contains('park')) return Icons.park;
    if (name.contains('shop') || name.contains('mall')) return Icons.shopping_bag;
    return Icons.location_on;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: zone.isActive
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _zoneIcon,
                  color: zone.isActive ? AppColors.primary : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            zone.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (!zone.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Inactive',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.radar,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${zone.radiusMeters.toInt()}m radius',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (zone.alertOnEnter)
                          const _AlertBadge(
                            icon: Icons.login,
                            label: 'Enter',
                          ),
                        if (zone.alertOnEnter && zone.alertOnExit)
                          const SizedBox(width: 6),
                        if (zone.alertOnExit)
                          const _AlertBadge(
                            icon: Icons.logout,
                            label: 'Exit',
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Delete button
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AlertBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.green),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
