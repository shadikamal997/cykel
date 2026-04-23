import '../../../core/widgets/app_image.dart';
import '../../auth/domain/app_user.dart';
/// CYKEL — Leaderboard Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/gamification_provider.dart';
import '../domain/gamification.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LeaderboardCategory _selectedCategory = LeaderboardCategory.distance;
  LeaderboardPeriod _selectedPeriod = LeaderboardPeriod.weekly;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedPeriod = LeaderboardPeriod.values[_tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(
      leaderboardProvider((category: _selectedCategory, period: _selectedPeriod)),
    );

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(context.l10n.leaderboard),
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.colors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: LeaderboardPeriod.values
              .map((p) => Tab(text: _getPeriodName(context, p)))
              .toList(),
        ),
      ),
      body: Column(
        children: [
          // Category chips
          _CategorySelector(
            selected: _selectedCategory,
            onChanged: (category) => setState(() => _selectedCategory = category),
          ),

          // Leaderboard list
          Expanded(
            child: leaderboardAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(context.l10n.errorPrefix(e.toString()))),
              data: (entries) {
                if (entries.isEmpty) {
                  return _EmptyLeaderboard(leaderboardContext: context);
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  itemCount: entries.length,
                  itemBuilder: (context, index) => _LeaderboardTile(
                    entry: entries[index],
                    category: _selectedCategory,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Selector ────────────────────────────────────────────────────────

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({required this.selected, required this.onChanged});

  final LeaderboardCategory selected;
  final ValueChanged<LeaderboardCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: LeaderboardCategory.values.map((category) {
          final isSelected = category == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : context.colors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : context.colors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  _getCategoryName(context, category),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isSelected ? AppColors.primary : context.colors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Leaderboard Tile ─────────────────────────────────────────────────────────

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.entry, required this.category});

  final LeaderboardEntry entry;
  final LeaderboardCategory category;

  @override
  Widget build(BuildContext context) {
    final isTop3 = entry.rank <= 3;
    final isMe = entry.isCurrentUser;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primary.withValues(alpha: 0.07)
            : context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? AppColors.primary.withValues(alpha: 0.5) : context.colors.border,
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 36,
              child: isTop3
                  ? Text(
                      _getRankMedal(entry.rank),
                      style: const TextStyle(fontSize: 24),
                      textAlign: TextAlign.center,
                    )
                  : Text(
                      '${entry.rank}',
                      style: AppTextStyles.headline3.copyWith(
                        color: context.colors.textSecondary,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
            const SizedBox(width: 12),

            // Avatar
            AppAvatar(
              url: entry.photoUrl,
              thumbnailUrl: AppUser.getThumbnailUrl(entry.photoUrl),
              size: 40,
              fallbackText: entry.displayName.isNotEmpty
                  ? entry.displayName[0].toUpperCase()
                  : '?',
            ),
            const SizedBox(width: 12),

            // Name + "You" label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.displayName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  if (isMe)
                    Text(
                      context.l10n.leaderboardYou,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),

            // Value + unit
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatValue(entry.value),
                  style: AppTextStyles.headline3.copyWith(
                    color: isMe ? AppColors.primary : context.colors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                Text(
                  category.unit,
                  style: AppTextStyles.caption.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRankMedal(int rank) {
    return switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '',
    };
  }

  String _formatValue(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyLeaderboard extends StatelessWidget {
  const _EmptyLeaderboard({required this.leaderboardContext});
  final BuildContext leaderboardContext;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            leaderboardContext.l10n.noDataYet,
            style: AppTextStyles.headline3.copyWith(color: context.colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            leaderboardContext.l10n.startRidingToJoin,
            style: AppTextStyles.bodyMedium.copyWith(color: context.colors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _getPeriodName(BuildContext context, LeaderboardPeriod period) {
  final l10n = context.l10n;
  return switch (period) {
    LeaderboardPeriod.weekly  => l10n.periodThisWeek,
    LeaderboardPeriod.monthly => l10n.periodThisMonth,
    LeaderboardPeriod.allTime => l10n.periodAllTime,
  };
}

String _getCategoryName(BuildContext context, LeaderboardCategory category) {
  final l10n = context.l10n;
  return switch (category) {
    LeaderboardCategory.distance  => l10n.challengeTypeDistance,
    LeaderboardCategory.rides     => l10n.challengeTypeRideCount,
    LeaderboardCategory.points    => l10n.points,
    LeaderboardCategory.elevation => l10n.challengeTypeElevation,
    LeaderboardCategory.streak    => l10n.challengeTypeStreak,
  };
}
