/// CYKEL — Badges Screen
/// View all badges and user's collection

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/gamification_provider.dart';
import '../domain/gamification.dart';

class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allBadgesAsync = ref.watch(allBadgesProvider);
    final userBadgesAsync = ref.watch(userBadgesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.l10n.badgesTitle),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: allBadgesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.errorPrefix(e.toString()))),
        data: (allBadges) {
          final earnedBadgeIds = (userBadgesAsync.valueOrNull ?? [])
              .map((ub) => ub.badgeId)
              .toSet();

          // Sort: earned first, then by rarity
          final sortedBadges = allBadges.toList()
            ..sort((Badge a, Badge b) {
              final aEarned = earnedBadgeIds.contains(a.id);
              final bEarned = earnedBadgeIds.contains(b.id);
              if (aEarned != bEarned) return aEarned ? -1 : 1;
              return b.rarity.index.compareTo(a.rarity.index);
            });

          return CustomScrollView(
            slivers: [
              // Stats Header
              SliverToBoxAdapter(
                child: _BadgeStatsHeader(
                  totalBadges: allBadges.length,
                  earnedBadges: earnedBadgeIds.length,
                ),
              ),

              // Badges Grid
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final badge = sortedBadges[index];
                      final isEarned = earnedBadgeIds.contains(badge.id);
                      return _BadgeCard(
                        badge: badge,
                        isEarned: isEarned,
                        onTap: () => _showBadgeDetails(context, badge, isEarned),
                      );
                    },
                    childCount: sortedBadges.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBadgeDetails(BuildContext context, Badge badge, bool isEarned) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BadgeDetailsSheet(badge: badge, isEarned: isEarned),
    );
  }
}

// ─── Badge Stats Header ───────────────────────────────────────────────────────

class _BadgeStatsHeader extends StatelessWidget {
  const _BadgeStatsHeader({
    required this.totalBadges,
    required this.earnedBadges,
  });

  final int totalBadges;
  final int earnedBadges;

  @override
  Widget build(BuildContext context) {
    final progress = totalBadges > 0 ? earnedBadges / totalBadges : 0.0;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.badgesEarnedOf(earnedBadges, totalBadges),
                    style: AppTextStyles.headline2,
                  ),
                  Text(
                    context.l10n.badgesEarned,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.percentComplete((progress * 100).toInt().toString()),
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Badge Card ───────────────────────────────────────────────────────────────

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.badge,
    required this.isEarned,
    required this.onTap,
  });

  final Badge badge;
  final bool isEarned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rarityColor = Color(badge.rarity.colorValue);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isEarned ? AppColors.surface : AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEarned ? rarityColor : AppColors.border,
            width: isEarned ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEarned
                    ? rarityColor.withValues(alpha: 0.2)
                    : AppColors.border.withValues(alpha: 0.3),
              ),
              child: Center(
                child: isEarned
                    ? Text(badge.icon, style: const TextStyle(fontSize: 32))
                    : Icon(
                        Icons.lock_outline_rounded,
                        size: 24,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            // Badge Name
            Text(
              badge.name,
              style: AppTextStyles.labelSmall.copyWith(
                color: isEarned ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isEarned ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Rarity
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: rarityColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getRarityName(context, badge.rarity),
                style: AppTextStyles.caption.copyWith(
                  color: rarityColor,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Badge Details Sheet ──────────────────────────────────────────────────────

class _BadgeDetailsSheet extends StatelessWidget {
  const _BadgeDetailsSheet({
    required this.badge,
    required this.isEarned,
  });

  final Badge badge;
  final bool isEarned;

  @override
  Widget build(BuildContext context) {
    final rarityColor = Color(badge.rarity.colorValue);
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          // Badge Icon (large)
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEarned
                  ? rarityColor.withValues(alpha: 0.2)
                  : AppColors.border.withValues(alpha: 0.3),
              border: Border.all(color: rarityColor, width: 3),
            ),
            child: Center(
              child: isEarned
                  ? Text(badge.icon, style: const TextStyle(fontSize: 48))
                  : const Icon(
                      Icons.lock_outline_rounded,
                      size: 40,
                      color: AppColors.textSecondary,
                    ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Badge Name
          Text(badge.name, style: AppTextStyles.headline2),
          const SizedBox(height: 8),
          
          // Rarity Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: rarityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getRarityName(context, badge.rarity),
              style: AppTextStyles.labelMedium.copyWith(color: rarityColor),
            ),
          ),
          const SizedBox(height: 16),
          
          // Description
          Text(
            badge.description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (badge.requirement != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isEarned ? Icons.check_circle : Icons.info_outline,
                    color: isEarned ? AppColors.success : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    badge.requirement!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isEarned ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Status
          if (isEarned)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 8),
                Text(
                  context.l10n.badgeEarned,
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.success),
                ),
              ],
            )
          else
            Text(
              context.l10n.badgeKeepRiding,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

/// Helper function to get localized rarity name
String _getRarityName(BuildContext context, BadgeRarity rarity) {
  final l10n = context.l10n;
  switch (rarity) {
    case BadgeRarity.common:
      return l10n.rarityCommon;
    case BadgeRarity.uncommon:
      return l10n.rarityUncommon;
    case BadgeRarity.rare:
      return l10n.rarityRare;
    case BadgeRarity.epic:
      return l10n.rarityEpic;
    case BadgeRarity.legendary:
      return l10n.rarityLegendary;
  }
}
