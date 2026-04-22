import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../application/family_pricing_providers.dart';
import '../domain/subscription.dart';
import 'family_management_screen.dart';
import 'subscription_plans_screen.dart';

/// Subscription management screen showing current plan and options
class SubscriptionManagementScreen extends ConsumerWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(subscriptionSummaryProvider);
    final subscription = ref.watch(currentSubscriptionProvider);
    final paymentHistory = ref.watch(paymentHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current plan card
            _CurrentPlanCard(
              summary: summary,
              onUpgrade: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SubscriptionPlansScreen(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Trial banner
            if (summary.isTrialing) ...[
              _TrialBanner(daysRemaining: summary.trialDaysRemaining ?? 0),
              const SizedBox(height: 16),
            ],

            // Family plan section
            if (summary.isFamilyPlan) ...[
              _FamilyQuickAccess(
                memberCount: summary.familyMemberCount,
                maxMembers: summary.familyMaxMembers,
                onManage: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FamilyManagementScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Quick actions
            _QuickActions(
              isActive: summary.isActive,
              isFamilyPlan: summary.isFamilyPlan,
              subscriptionId: subscription.valueOrNull?.id,
              onCancel: subscription.valueOrNull != null
                  ? () => _cancelSubscription(
                      context, ref, subscription.valueOrNull!.id)
                  : null,
              onResume: subscription.valueOrNull?.isCanceled == true
                  ? () => _resumeSubscription(
                      context, ref, subscription.valueOrNull!.id)
                  : null,
            ),
            const SizedBox(height: 24),

            // Payment history
            Text(
              'Payment History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            paymentHistory.when(
              data: (payments) {
                if (payments.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.receipt_long,
                            size: 40, color: AppColors.textHint),
                        SizedBox(height: 8),
                        Text('No payment history yet'),
                      ],
                    ),
                  );
                }
                return Column(
                  children: payments.map((payment) => _PaymentHistoryTile(
                        payment: payment,
                      )).toList(),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  const Text('Could not load payment history'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelSubscription(
      BuildContext context, WidgetRef ref, String subscriptionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Your subscription will remain active until the end of the current billing period. Are you sure you want to cancel?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final service = ref.read(familyPricingServiceProvider);
      await service.cancelSubscription(subscriptionId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription canceled. Access continues until period end.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _resumeSubscription(
      BuildContext context, WidgetRef ref, String subscriptionId) async {
    try {
      final service = ref.read(familyPricingServiceProvider);
      await service.resumeSubscription(subscriptionId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription resumed!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

/// Current plan overview card
class _CurrentPlanCard extends StatelessWidget {
  final SubscriptionSummary summary;
  final VoidCallback onUpgrade;

  const _CurrentPlanCard({
    required this.summary,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: summary.isActive
              ? [AppColors.primary, AppColors.primaryDark]
              : [AppColors.surface, AppColors.surfaceVariant],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getPlanIcon(summary.plan),
                color: summary.isActive ? Colors.white : AppColors.textSecondary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${summary.plan.displayName} Plan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: summary.isActive
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      summary.isActive
                          ? summary.isTrialing
                              ? 'Trial Active'
                              : 'Active'
                          : 'Inactive',
                      style: TextStyle(
                        color: summary.isActive
                            ? Colors.white70
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (summary.plan != SubscriptionPlan.premium)
                OutlinedButton(
                  onPressed: onUpgrade,
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        summary.isActive ? Colors.white : AppColors.primary,
                    side: BorderSide(
                      color: summary.isActive
                          ? Colors.white70
                          : AppColors.primary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                      summary.plan == SubscriptionPlan.free
                          ? 'Upgrade'
                          : 'Change Plan'),
                ),
            ],
          ),
          if (summary.daysUntilRenewal != null && summary.isActive) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text(
                    summary.monthlyAmount != null
                        ? '${summary.monthlyAmount!.toStringAsFixed(0)} DKK · Renews in ${summary.daysUntilRenewal} days'
                        : 'Renews in ${summary.daysUntilRenewal} days',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getPlanIcon(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.free:
        return Icons.pedal_bike;
      case SubscriptionPlan.individual:
        return Icons.person;
      case SubscriptionPlan.family:
        return Icons.family_restroom;
      case SubscriptionPlan.premium:
        return Icons.diamond;
    }
  }
}

/// Trial countdown banner
class _TrialBanner extends StatelessWidget {
  final int daysRemaining;

  const _TrialBanner({required this.daysRemaining});

  @override
  Widget build(BuildContext context) {
    final isUrgent = daysRemaining <= 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUrgent ? AppColors.warningLight : AppColors.infoLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent
              ? AppColors.warning.withValues(alpha: 0.3)
              : AppColors.info.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isUrgent ? Icons.warning_amber : Icons.card_giftcard,
            color: isUrgent ? AppColors.warning : AppColors.info,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrgent ? 'Trial Ending Soon!' : 'Free Trial Active',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isUrgent
                        ? Colors.orange.shade800
                        : AppColors.info,
                  ),
                ),
                Text(
                  '$daysRemaining ${daysRemaining == 1 ? 'day' : 'days'} remaining in your free trial',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Family plan quick access card
class _FamilyQuickAccess extends StatelessWidget {
  final int memberCount;
  final int maxMembers;
  final VoidCallback onManage;

  const _FamilyQuickAccess({
    required this.memberCount,
    required this.maxMembers,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onManage,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.family_restroom, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Family Members',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '$memberCount of $maxMembers members',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

/// Quick action buttons
class _QuickActions extends StatelessWidget {
  final bool isActive;
  final bool isFamilyPlan;
  final String? subscriptionId;
  final VoidCallback? onCancel;
  final VoidCallback? onResume;

  const _QuickActions({
    required this.isActive,
    required this.isFamilyPlan,
    this.subscriptionId,
    this.onCancel,
    this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (onResume != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onResume,
              icon: const Icon(Icons.replay),
              label: const Text('Resume Subscription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (onResume != null) const SizedBox(height: 8),
        if (isActive && onCancel != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Cancel Subscription'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Payment history tile
class _PaymentHistoryTile extends StatelessWidget {
  final Payment payment;

  const _PaymentHistoryTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: payment.isSuccessful
                  ? AppColors.successLight
                  : payment.hasFailed
                      ? AppColors.errorLight
                      : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              payment.isSuccessful
                  ? Icons.check_circle
                  : payment.hasFailed
                      ? Icons.error
                      : Icons.schedule,
              color: payment.isSuccessful
                  ? AppColors.success
                  : payment.hasFailed
                      ? AppColors.error
                      : AppColors.textHint,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.description ?? 'Subscription Payment',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  _formatDate(payment.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${payment.amount.toStringAsFixed(0)} ${payment.currency}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                payment.status.name,
                style: TextStyle(
                  fontSize: 11,
                  color: payment.isSuccessful
                      ? AppColors.success
                      : payment.hasFailed
                          ? AppColors.error
                          : AppColors.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
