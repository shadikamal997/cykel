/// CYKEL — Notifications List Screen
/// Shows actual app notifications (events, marketplace, social, etc.)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/app_notifications_provider.dart';

class NotificationsListScreen extends ConsumerWidget {
  const NotificationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notificationsAsync = ref.watch(appNotificationsProvider);

    return notificationsAsync.when(
      data: (notifications) => _buildContent(context, l10n, notifications),
      loading: () => Scaffold(
        backgroundColor: context.colors.background,
        appBar: AppBar(
          title: Text(l10n.notifications),
          backgroundColor: context.colors.surface,
          foregroundColor: context.colors.textPrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: context.colors.background,
        appBar: AppBar(
          title: Text(l10n.notifications),
          backgroundColor: context.colors.surface,
          foregroundColor: context.colors.textPrimary,
        ),
        body: Center(
          child: Text('Error loading notifications: $error'),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n, List<AppNotification> notifications) {

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(l10n.notifications),
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
        actions: [
          if (notifications.isNotEmpty && notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;
                final batch = FirebaseFirestore.instance.batch();
                for (final n in notifications.where((n) => !n.isRead)) {
                  batch.update(
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('notifications')
                        .doc(n.id),
                    {'isRead': true},
                  );
                }
                try {
                  await batch.commit();
                } catch (_) {}
              },
              child: Text(
                l10n.markAllRead,
                style: TextStyle(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState(context, l10n)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationCard(notification: notification);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.colors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 64,
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noNotifications,
              style: AppTextStyles.headline3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noNotificationsDesc,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: notification.isRead
            ? context.colors.surface
            : context.colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? context.colors.border
              : context.colors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('notifications')
                  .doc(notification.id)
                  .update({'isRead': true});
            }
          }
          if (notification.actionRoute != null) {
            Navigator.of(context).pop();
            context.go(notification.actionRoute!);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getTypeColor(notification.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getTypeIcon(notification.type),
                  size: 24,
                  color: _getTypeColor(notification.type),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.colors.textPrimary,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: context.colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTimestamp(context, notification.timestamp),
                      style: AppTextStyles.caption.copyWith(
                        color: context.colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(NotificationType type) {
    return switch (type) {
      NotificationType.marketplace => Icons.shopping_bag_outlined,
      NotificationType.event => Icons.event_outlined,
      NotificationType.social => Icons.people_outline,
      NotificationType.ride => Icons.directions_bike_outlined,
      NotificationType.achievement => Icons.emoji_events_outlined,
      NotificationType.system => Icons.info_outline,
    };
  }

  Color _getTypeColor(NotificationType type) {
    return switch (type) {
      NotificationType.marketplace => AppColors.info,
      NotificationType.event => AppColors.success,
      NotificationType.social => AppColors.warning,
      NotificationType.ride => AppColors.primaryLight,
      NotificationType.achievement => AppColors.warning,
      NotificationType.system => AppColors.textSecondary,
    };
  }

  String _formatTimestamp(BuildContext context, DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return context.l10n.justNow;
    } else if (difference.inMinutes < 60) {
      return context.l10n.minutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return context.l10n.hoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return context.l10n.daysAgo(difference.inDays);
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────

enum NotificationType {
  marketplace,
  event,
  social,
  ride,
  achievement,
  system,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.actionRoute,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? actionRoute;

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      type: NotificationType.values.firstWhere(
        (e) => e.name == (data['type'] as String? ?? 'system'),
        orElse: () => NotificationType.system,
      ),
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
      actionRoute: data['actionRoute'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'type': type.name,
        'title': title,
        'message': message,
        'timestamp': Timestamp.fromDate(timestamp),
        'isRead': isRead,
        if (actionRoute != null) 'actionRoute': actionRoute,
      };
}
