import '../../../core/widgets/app_image.dart';
import '../../auth/domain/app_user.dart';
/// CYKEL — Leaderboard Screen
/// View rankings across different categories and time periods

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.l10n.leaderboard),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
          tabs: LeaderboardPeriod.values.map((p) => Tab(text: _getPeriodName(context, p))).toList(),
        ),
      ),
      body: Column(
        children: [
          // Category Selector
          _CategorySelector(
            selected: _selectedCategory,
            onChanged: (category) => setState(() => _selectedCategory = category),
          ),
          
          // Leaderboard
          Expanded(
            child: leaderboardAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(context.l10n.errorPrefix(e.toString()))),
              data: (entries) {
                if (entries.isEmpty) {
                  return _EmptyLeaderboard(context: context);
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
  const _CategorySelector({
    required this.selected,
    required this.onChanged,
  });

  final LeaderboardCategory selected;
  final ValueChanged<LeaderboardCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: LeaderboardCategory.values.map((category) {
          final isSelected = category == selected;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(_getCategoryName(context, category)),
              selected: isSelected,
              onSelected: (_) => onChanged(category),
              selectedColor: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.1),
              labelStyle: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black) : AppColors.textSecondary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black) : AppColors.border,
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
  const _LeaderboardTile({
    required this.entry,
    required this.category,
  });

  final LeaderboardEntry entry;
  final LeaderboardCategory category;

  @override
  Widget build(BuildContext context) {
    final isTop3 = entry.rank <= 3;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: entry.isCurrentUser 
            ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
            : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.isCurrentUser ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black) : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3)),
          width: entry.isCurrentUser ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rank
            SizedBox(
              width: 32,
              child: isTop3
                  ? Text(
                      _getRankMedal(entry.rank),
                      style: const TextStyle(fontSize: 24),
                    )
                  : Text(
                      '${entry.rank}',
                      style: AppTextStyles.headline3.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.white,
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
              fallbackText: entry.displayName.isNotEmpty ? entry.displayName[0].toUpperCase() : '?',
            ),
          ],
        ),
        title: Text(
          entry.displayName,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: entry.isCurrentUser ? FontWeight.w600 : FontWeight.normal,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.white,
          ),
        ),
        subtitle: entry.isCurrentUser
            ? Text(
                context.l10n.leaderboardYou,
                style: AppTextStyles.caption.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.7)),
              )
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatValue(entry.value),
              style: AppTextStyles.headline3.copyWith(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.white,
              ),
            ),
            Text(
              category.unit,
              style: AppTextStyles.caption.copyWith(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRankMedal(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  String _formatValue(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyLeaderboard extends StatelessWidget {
  const _EmptyLeaderboard({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            context.l10n.noDataYet,
            style: AppTextStyles.headline3.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.startRidingToJoin,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Helper function to get localized period name
String _getPeriodName(BuildContext context, LeaderboardPeriod period) {
  final l10n = context.l10n;
  switch (period) {
    case LeaderboardPeriod.weekly:
      return l10n.periodThisWeek;
    case LeaderboardPeriod.monthly:
      return l10n.periodThisMonth;
    case LeaderboardPeriod.allTime:
      return l10n.periodAllTime;
  }
}

/// Helper function to get localized category name
String _getCategoryName(BuildContext context, LeaderboardCategory category) {
  final l10n = context.l10n;
  switch (category) {
    case LeaderboardCategory.distance:
      return l10n.challengeTypeDistance;
    case LeaderboardCategory.rides:
      return l10n.challengeTypeRideCount;
    case LeaderboardCategory.points:
      return l10n.points;
    case LeaderboardCategory.elevation:
      return l10n.challengeTypeElevation;
    case LeaderboardCategory.streak:
      return l10n.challengeTypeStreak;
  }
}
