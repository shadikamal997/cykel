/// CYKEL — Notifications Settings Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Section(
            title: l10n.notifSectionRiding,
            tiles: [
              _Toggle(
                icon: Icons.directions_bike_outlined,
                label: l10n.notifRideReminders,
                subtitle: l10n.notifRideRemindersDesc,
                value: state.rideReminders,
                onChanged: notifier.setRideReminders,
              ),
              _Toggle(
                icon: Icons.warning_amber_rounded,
                label: l10n.notifHazardAlerts,
                subtitle: l10n.notifHazardAlertsDesc,
                value: state.hazardAlerts,
                onChanged: notifier.setHazardAlerts,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: l10n.notifSectionMarketplace,
            tiles: [
              _Toggle(
                icon: Icons.chat_bubble_outline_rounded,
                label: l10n.notifMarketplace,
                subtitle: l10n.notifMarketplaceDesc,
                value: state.marketplace,
                onChanged: notifier.setMarketplace,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: l10n.notifSectionGeneral,
            tiles: [
              _Toggle(
                icon: Icons.campaign_outlined,
                label: l10n.notifMarketing,
                subtitle: l10n.notifMarketingDesc,
                value: state.marketing,
                onChanged: notifier.setMarketing,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: l10n.notifSectionScheduled,
            tiles: [
              _ScheduleReminderTile(
                current: state.scheduledRideTime,
                onChanged: notifier.setScheduledRideTime,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.tiles});
  final String title;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style:
                AppTextStyles.labelSmall.copyWith(letterSpacing: 1.0),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.border, width: 0.8),
          ),
          child: Column(
            children: List.generate(tiles.length, (i) => Column(
              children: [
                tiles[i],
                if (i < tiles.length - 1)
                  Divider(
                      height: 1, indent: 52, color: context.colors.border),
              ],
            )),
          ),
        ),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodyMedium),
              Text(subtitle,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: context.colors.textSecondary)),
            ],
          ),
        ),
        Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5)),
      ]),
    );
  }
}
class _ScheduleReminderTile extends StatelessWidget {
  const _ScheduleReminderTile({
    required this.current,
    required this.onChanged,
  });
  final TimeOfDay? current;
  final void Function(TimeOfDay?) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.alarm_rounded, size: 20, color: isDark ? Colors.white : Colors.black),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.dailyRideReminder,
                    style: AppTextStyles.bodyMedium),
                Text(
                  current == null
                      ? l10n.tapToSetReminder
                      : l10n.reminderSetFor(_formatTime(current!)),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: context.colors.textSecondary),
                ),
              ],
            ),
          ),
          if (current != null)
            IconButton(
              icon: Icon(Icons.close_rounded,
                  size: 18, color: isDark ? Colors.white : Colors.black),
              tooltip: l10n.removeReminder,
              onPressed: () => onChanged(null),
            ),
          TextButton(
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: current ?? const TimeOfDay(hour: 7, minute: 30),
              );
              if (picked != null) onChanged(picked);
            },
            child: Text(
              current == null ? l10n.setTime : l10n.changeTime,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}