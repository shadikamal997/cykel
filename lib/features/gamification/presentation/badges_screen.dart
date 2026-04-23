/// CYKEL — Badges Screen

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/gamification_provider.dart';
import '../domain/gamification.dart';

class BadgesScreen extends ConsumerStatefulWidget {
  const BadgesScreen({super.key});

  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen> {
  BadgeRarity? _filterRarity;

  @override
  Widget build(BuildContext context) {
    final allBadgesAsync = ref.watch(allBadgesProvider);
    final userBadgesAsync = ref.watch(userBadgesProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(context.l10n.badgesTitle),
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
      ),
      body: allBadgesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(context.l10n.errorPrefix(err.toString()))),
        data: (allBadges) {
          final earnedBadgeIds = (userBadgesAsync.valueOrNull ?? [])
              .map((ub) => ub.badgeId)
              .toSet();

          // Apply rarity filter
          final filtered = _filterRarity == null
              ? allBadges
              : allBadges.where((b) => b.rarity == _filterRarity).toList();

          // Sort: earned first, then by rarity
          final sortedBadges = filtered.toList()
            ..sort((Badge a, Badge b) {
              final aEarned = earnedBadgeIds.contains(a.id);
              final bEarned = earnedBadgeIds.contains(b.id);
              if (aEarned != bEarned) return aEarned ? -1 : 1;
              return b.rarity.index.compareTo(a.rarity.index);
            });

          final earnedCount = allBadges.where((b) => earnedBadgeIds.contains(b.id)).length;

          return CustomScrollView(
            slivers: [
              // Stats header
              SliverToBoxAdapter(
                child: _BadgeStatsHeader(
                  totalBadges: allBadges.length,
                  earnedBadges: earnedCount,
                ),
              ),

              // Rarity filter chips
              SliverToBoxAdapter(
                child: _RarityFilter(
                  selected: _filterRarity,
                  onChanged: (r) => setState(() => _filterRarity = r),
                ),
              ),

              // Earned section label
              if (_filterRarity == null && earnedCount > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                        const SizedBox(width: 6),
                        Text(
                          '$earnedCount earned',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.success,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${allBadges.length - earnedCount} locked',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: context.colors.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.lock_outline, size: 14, color: context.colors.textSecondary),
                      ],
                    ),
                  ),
                ),

              // Badges grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
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
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BadgeDetailsSheet(badge: badge, isEarned: isEarned),
    );
  }
}

// ─── Rarity Filter ────────────────────────────────────────────────────────────

class _RarityFilter extends StatelessWidget {
  const _RarityFilter({required this.selected, required this.onChanged});
  final BadgeRarity? selected;
  final void Function(BadgeRarity?) onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            color: context.colors.textPrimary,
            isSelected: selected == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 8),
          ...BadgeRarity.values.map((r) {
            final color = Color(r.colorValue);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: _rarityLabel(r),
                color: color,
                isSelected: selected == r,
                onTap: () => onChanged(selected == r ? null : r),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _rarityLabel(BadgeRarity r) => switch (r) {
    BadgeRarity.common    => 'Common',
    BadgeRarity.uncommon  => 'Uncommon',
    BadgeRarity.rare      => 'Rare',
    BadgeRarity.epic      => 'Epic',
    BadgeRarity.legendary => 'Legendary',
  };
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : context.colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : context.colors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isSelected ? color : context.colors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─── Badge Stats Header ───────────────────────────────────────────────────────

class _BadgeStatsHeader extends StatelessWidget {
  const _BadgeStatsHeader({required this.totalBadges, required this.earnedBadges});
  final int totalBadges;
  final int earnedBadges;

  @override
  Widget build(BuildContext context) {
    final progress = totalBadges > 0 ? earnedBadges / totalBadges : 0.0;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🏆', style: TextStyle(fontSize: 30)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.badgesEarnedOf(earnedBadges, totalBadges),
                      style: AppTextStyles.headline2.copyWith(color: Colors.white),
                    ),
                    Text(
                      context.l10n.badgesEarned,
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              // Circular progress
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                      strokeWidth: 5,
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Badge Card ───────────────────────────────────────────────────────────────

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge, required this.isEarned, required this.onTap});
  final Badge badge;
  final bool isEarned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rarityColor = Color(badge.rarity.colorValue);
    final isLegendary = badge.rarity == BadgeRarity.legendary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isEarned ? rarityColor.withValues(alpha: 0.6) : context.colors.border,
            width: isEarned ? 1.5 : 1,
          ),
          boxShadow: isEarned && isLegendary
              ? [
                  BoxShadow(
                    color: rarityColor.withValues(alpha: 0.25),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEarned
                    ? rarityColor.withValues(alpha: 0.15)
                    : context.colors.border.withValues(alpha: 0.3),
              ),
              child: Center(
                child: isEarned
                    ? Text(badge.icon, style: const TextStyle(fontSize: 30))
                    : Icon(
                        Icons.lock_outline_rounded,
                        size: 24,
                        color: context.colors.textSecondary.withValues(alpha: 0.5),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                badge.name,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isEarned ? context.colors.textPrimary : context.colors.textSecondary,
                  fontWeight: isEarned ? FontWeight.w700 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isEarned
                    ? rarityColor.withValues(alpha: 0.12)
                    : context.colors.border.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getRarityName(context, badge.rarity),
                style: AppTextStyles.caption.copyWith(
                  color: isEarned ? rarityColor : context.colors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
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
  const _BadgeDetailsSheet({required this.badge, required this.isEarned});
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
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: context.colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Badge Icon (large)
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEarned
                  ? rarityColor.withValues(alpha: 0.15)
                  : context.colors.border.withValues(alpha: 0.3),
              border: Border.all(color: rarityColor, width: 2.5),
            ),
            child: Center(
              child: isEarned
                  ? Text(badge.icon, style: const TextStyle(fontSize: 48))
                  : Icon(Icons.lock_outline_rounded, size: 40, color: context.colors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),

          Text(badge.name, style: AppTextStyles.headline2),
          const SizedBox(height: 8),

          // Rarity chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: rarityColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: rarityColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              _getRarityName(context, badge.rarity),
              style: AppTextStyles.labelMedium.copyWith(color: rarityColor, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            badge.description,
            style: AppTextStyles.bodyMedium.copyWith(color: context.colors.textSecondary),
            textAlign: TextAlign.center,
          ),

          if (badge.requirement != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEarned
                    ? AppColors.success.withValues(alpha: 0.08)
                    : context.colors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isEarned
                      ? AppColors.success.withValues(alpha: 0.3)
                      : context.colors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEarned ? Icons.check_circle : Icons.info_outline,
                    color: isEarned ? AppColors.success : context.colors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      badge.requirement!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isEarned ? AppColors.success : context.colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

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
              style: AppTextStyles.bodySmall.copyWith(color: context.colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _getRarityName(BuildContext context, BadgeRarity rarity) {
  final l10n = context.l10n;
  return switch (rarity) {
    BadgeRarity.common    => l10n.rarityCommon,
    BadgeRarity.uncommon  => l10n.rarityUncommon,
    BadgeRarity.rare      => l10n.rarityRare,
    BadgeRarity.epic      => l10n.rarityEpic,
    BadgeRarity.legendary => l10n.rarityLegendary,
  };
}
