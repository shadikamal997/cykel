import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../application/family_gamification_service.dart';
import '../application/family_pricing_providers.dart';
import '../domain/family_gamification.dart';

/// Family achievements and gamification screen
class FamilyAchievementsScreen extends ConsumerStatefulWidget {
  const FamilyAchievementsScreen({super.key});

  @override
  ConsumerState<FamilyAchievementsScreen> createState() =>
      _FamilyAchievementsScreenState();
}

class _FamilyAchievementsScreenState
    extends ConsumerState<FamilyAchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final familyAccountAsync = ref.watch(familyAccountProvider);

    return familyAccountAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.familyAchievements)),
        body: Center(child: Text('Error: $e')),
      ),
      data: (account) {
        if (account == null) {
          return Scaffold(
            appBar: AppBar(title: Text(context.l10n.familyAchievements)),
            body: const Center(child: Text('No family account found')),
          );
        }

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildAppBar(context),
              _buildStatsHeader(account.id),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(tabController: _tabController),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _AchievementsTab(familyId: account.id),
                _LeaderboardTab(familyId: account.id),
                _ChallengesTab(familyId: account.id),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Achievements',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.amber.shade700,
                Colors.orange.shade600,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsHeader(String familyId) {
    final achievementsAsync = ref.watch(familyAchievementsProvider(familyId));
    final statsAsync = ref.watch(familyGamificationStatsProvider(familyId));

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _QuickStat(
                icon: Icons.emoji_events,
                value: achievementsAsync.when(
                  data: (a) => a.length.toString(),
                  loading: () => '-',
                  error: (e, st) => '0',
                ),
                label: 'Unlocked',
                color: Colors.amber,
              ),
            ),
            Expanded(
              child: _QuickStat(
                icon: Icons.star,
                value: statsAsync.when(
                  data: (s) => s.fold(0, (sum, stat) => sum + stat.totalPoints).toString(),
                  loading: () => '-',
                  error: (e, st) => '0',
                ),
                label: 'Family Points',
                color: Colors.purple,
              ),
            ),
            Expanded(
              child: _QuickStat(
                icon: Icons.flash_on,
                value: statsAsync.when(
                  data: (s) =>
                      s.isEmpty ? '0' : s.map((e) => e.currentStreak).reduce((a, b) => a > b ? a : b).toString(),
                  loading: () => '-',
                  error: (e, st) => '0',
                ),
                label: 'Max Streak',
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;

  _TabBarDelegate({required this.tabController});

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        controller: tabController,
        labelColor: Colors.amber.shade700,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.amber.shade700,
        tabs: const [
          Tab(icon: Icon(Icons.emoji_events), text: 'Badges'),
          Tab(icon: Icon(Icons.leaderboard), text: 'Leaderboard'),
          Tab(icon: Icon(Icons.flag), text: 'Challenges'),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 72;

  @override
  double get minExtent => 72;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _QuickStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// Achievements Tab
// ==========================================

class _AchievementsTab extends ConsumerWidget {
  final String familyId;

  const _AchievementsTab({required this.familyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockedAsync = ref.watch(familyAchievementsProvider(familyId));

    return unlockedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (unlocked) {
        final unlockedTypes = unlocked.map((a) => a.type).toSet();

        // Group achievements by rarity
        final grouped = <AchievementRarity, List<Achievement>>{};
        for (final achievement in AchievementDefinitions.all) {
          grouped.putIfAbsent(achievement.rarity, () => []).add(achievement);
        }

        final rarityOrder = [
          AchievementRarity.legendary,
          AchievementRarity.epic,
          AchievementRarity.rare,
          AchievementRarity.uncommon,
          AchievementRarity.common,
        ];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Progress bar
            _AchievementProgress(
              unlocked: unlocked.length,
              total: AchievementDefinitions.all.length,
            ),
            const SizedBox(height: 24),

            // Recently unlocked
            if (unlocked.isNotEmpty) ...[
              const Text(
                'Recently Unlocked',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: unlocked.take(5).length,
                  itemBuilder: (context, index) {
                    final achievement = AchievementDefinitions.getDefinition(
                      unlocked[index].type,
                    );
                    return _RecentAchievementCard(
                      achievement: achievement,
                      unlockedAt: unlocked[index].unlockedAt,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // All achievements by rarity
            for (final rarity in rarityOrder) ...[
              if (grouped[rarity] != null && grouped[rarity]!.isNotEmpty) ...[
                _RarityHeader(
                  rarity: rarity,
                  count: grouped[rarity]!.length,
                  unlockedCount: grouped[rarity]!
                      .where((a) => unlockedTypes.contains(a.type))
                      .length,
                ),
                const SizedBox(height: 12),
                ...grouped[rarity]!.map((achievement) => _AchievementTile(
                      achievement: achievement,
                      isUnlocked: unlockedTypes.contains(achievement.type),
                      unlockedAchievement: unlocked.firstWhere(
                        (u) => u.type == achievement.type,
                        orElse: () => UnlockedAchievement(
                          id: '',
                          memberId: '',
                          memberName: '',
                          type: achievement.type,
                          unlockedAt: DateTime.now(),
                        ),
                      ),
                    )),
                const SizedBox(height: 20),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _AchievementProgress extends StatelessWidget {
  final int unlocked;
  final int total;

  const _AchievementProgress({
    required this.unlocked,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? unlocked / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withValues(alpha: 0.1),
            Colors.orange.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Achievement Progress',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '$unlocked / $total',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(Colors.amber.shade700),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}% Complete',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _RarityHeader extends StatelessWidget {
  final AchievementRarity rarity;
  final int count;
  final int unlockedCount;

  const _RarityHeader({
    required this.rarity,
    required this.count,
    required this.unlockedCount,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getRarityColor(rarity);

    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _getRarityName(rarity),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$unlockedCount / $count',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.uncommon:
        return Colors.green;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.orange;
    }
  }

  String _getRarityName(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.uncommon:
        return 'Uncommon';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }
}

class _RecentAchievementCard extends StatelessWidget {
  final Achievement achievement;
  final DateTime unlockedAt;

  const _RecentAchievementCard({
    required this.achievement,
    required this.unlockedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            achievement.color.withValues(alpha: 0.2),
            achievement.color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: achievement.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: achievement.color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              achievement.icon,
              color: achievement.color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;
  final UnlockedAchievement? unlockedAchievement;

  const _AchievementTile({
    required this.achievement,
    required this.isUnlocked,
    this.unlockedAchievement,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAchievementDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? achievement.color.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  achievement.icon,
                  color: isUnlocked ? achievement.color : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isUnlocked ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      achievement.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (isUnlocked && unlockedAchievement != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Unlocked ${dateFormat.format(unlockedAchievement!.unlockedAt)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: achievement.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Points
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? Colors.amber.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: isUnlocked ? Colors.amber : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${achievement.points}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? Colors.amber.shade700 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isUnlocked) ...[
                    const SizedBox(height: 4),
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAchievementDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AchievementDetailSheet(
        achievement: achievement,
        isUnlocked: isUnlocked,
        unlockedAt: unlockedAchievement?.unlockedAt,
      ),
    );
  }
}

class _AchievementDetailSheet extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const _AchievementDetailSheet({
    required this.achievement,
    required this.isUnlocked,
    this.unlockedAt,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM d, yyyy');

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  achievement.color.withValues(alpha: 0.3),
                  achievement.color.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              achievement.icon,
              size: 48,
              color: isUnlocked ? achievement.color : Colors.grey,
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            achievement.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          // Rarity
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: achievement.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              achievement.rarityName,
              style: TextStyle(
                color: achievement.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            achievement.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Requirement
          if (achievement.requirement != null)
            Text(
              'Requirement: ${achievement.requirement}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: 16),

          // Points
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                '${achievement.points} Points',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status
          if (isUnlocked) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Unlocked ${unlockedAt != null ? dateFormat.format(unlockedAt!) : ""}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Not yet unlocked',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

// ==========================================
// Leaderboard Tab
// ==========================================

class _LeaderboardTab extends ConsumerWidget {
  final String familyId;

  const _LeaderboardTab({required this.familyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(familyGamificationStatsProvider(familyId));

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (stats) {
        if (stats.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.leaderboard, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No stats yet',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Start riding to earn points!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Top 3 podium
            if (stats.isNotEmpty) _Podium(stats: stats.take(3).toList()),
            const SizedBox(height: 24),

            // Full rankings
            const Text(
              'Full Rankings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...stats.asMap().entries.map((entry) => _LeaderboardCard(
                  rank: entry.key + 1,
                  stats: entry.value,
                )),
          ],
        );
      },
    );
  }
}

class _Podium extends StatelessWidget {
  final List<MemberGamificationStats> stats;

  const _Podium({required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.amber, Colors.grey.shade400, Colors.brown.shade400];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd place
        if (stats.length > 1)
          _PodiumPlace(
            rank: 2,
            stats: stats[1],
            height: 80,
            color: colors[1],
          )
        else
          const SizedBox(width: 80),

        const SizedBox(width: 8),

        // 1st place
        if (stats.isNotEmpty)
          _PodiumPlace(
            rank: 1,
            stats: stats[0],
            height: 100,
            color: colors[0],
          )
        else
          const SizedBox(width: 100),

        const SizedBox(width: 8),

        // 3rd place
        if (stats.length > 2)
          _PodiumPlace(
            rank: 3,
            stats: stats[2],
            height: 60,
            color: colors[2],
          )
        else
          const SizedBox(width: 80),
      ],
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  final int rank;
  final MemberGamificationStats stats;
  final double height;
  final Color color;

  const _PodiumPlace({
    required this.rank,
    required this.stats,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar
        AppAvatar(
          url: null,
          size: rank == 1 ? 64 : 48,
          fallbackText: stats.memberName.isNotEmpty ? stats.memberName[0].toUpperCase() : '?',
        ),
        const SizedBox(height: 8),
        Text(
          stats.memberName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${stats.totalPoints} pts',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        // Podium stand
        Container(
          width: rank == 1 ? 100 : 80,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final int rank;
  final MemberGamificationStats stats;

  const _LeaderboardCard({
    required this.rank,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final medalColors = {1: Colors.amber, 2: Colors.grey, 3: Colors.brown};
    final color = medalColors[rank];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Rank
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color?.withValues(alpha: 0.2) ?? Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: color != null
                    ? Icon(Icons.emoji_events, color: color, size: 20)
                    : Text(
                        '$rank',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Avatar
            AppAvatar(
              url: null,
              size: 40,
              fallbackText: stats.memberName.isNotEmpty ? stats.memberName[0].toUpperCase() : '?',
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stats.memberName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      Text(
                        'Level ${stats.level}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '🔥 ${stats.currentStreak} day streak',
                        style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Points
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${stats.totalPoints}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${stats.achievementCount} badges',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// Challenges Tab
// ==========================================

class _ChallengesTab extends ConsumerWidget {
  final String familyId;

  const _ChallengesTab({required this.familyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(allChallengesProvider(familyId));

    return challengesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (challenges) {
        final active = challenges.where((c) => c.isActive).toList();
        final completed = challenges.where((c) => c.isCompleted).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Create challenge button
            OutlinedButton.icon(
              onPressed: () => _showCreateChallengeSheet(context, ref, familyId),
              icon: const Icon(Icons.add),
              label: const Text('Create New Challenge'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            // Active challenges
            const Text(
              'Active Challenges',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (active.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.flag, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No active challenges',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ...active.map((c) => _ChallengeCard(challenge: c, familyId: familyId)),

            const SizedBox(height: 24),

            // Completed challenges
            if (completed.isNotEmpty) ...[
              const Text(
                'Completed Challenges',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...completed.map((c) => _ChallengeCard(challenge: c, familyId: familyId)),
            ],
          ],
        );
      },
    );
  }

  void _showCreateChallengeSheet(BuildContext context, WidgetRef ref, String familyId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CreateChallengeSheet(familyId: familyId),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final FamilyChallenge challenge;
  final String familyId;

  const _ChallengeCard({
    required this.challenge,
    required this.familyId,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = challenge.isActive;
    final dateFormat = DateFormat('MMM d');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? BorderSide(color: AppColors.primary.withValues(alpha: 0.3))
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getChallengeIcon(challenge.type),
                    color: isActive ? AppColors.primary : Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        challenge.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${challenge.rewardPoints}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${challenge.currentValue.toStringAsFixed(1)} / ${challenge.targetValue.toStringAsFixed(0)} ${_getUnit(challenge.type)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${(challenge.progressPercent * 100).toInt()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isActive ? AppColors.primary : Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: challenge.progressPercent,
                    minHeight: 8,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(
                      isActive ? AppColors.primary : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${challenge.participantIds.length} participants',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      isActive ? Icons.timer : Icons.check_circle,
                      size: 16,
                      color: isActive ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isActive
                          ? 'Ends ${dateFormat.format(challenge.endDate)}'
                          : 'Completed',
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getChallengeIcon(ChallengeType type) {
    switch (type) {
      case ChallengeType.totalDistance:
      case ChallengeType.weeklyDistance:
      case ChallengeType.memberDistance:
        return Icons.straighten;
      case ChallengeType.totalRides:
        return Icons.directions_bike;
      case ChallengeType.dailyStreak:
        return Icons.local_fire_department;
    }
  }

  String _getUnit(ChallengeType type) {
    switch (type) {
      case ChallengeType.totalDistance:
      case ChallengeType.weeklyDistance:
      case ChallengeType.memberDistance:
        return 'km';
      case ChallengeType.totalRides:
        return 'rides';
      case ChallengeType.dailyStreak:
        return 'days';
    }
  }
}

class _CreateChallengeSheet extends ConsumerStatefulWidget {
  final String familyId;

  const _CreateChallengeSheet({required this.familyId});

  @override
  ConsumerState<_CreateChallengeSheet> createState() => _CreateChallengeSheetState();
}

class _CreateChallengeSheetState extends ConsumerState<_CreateChallengeSheet> {
  int _selectedTemplateIndex = 0;

  @override
  Widget build(BuildContext context) {
    final templates = ChallengeTemplates.getTemplates(widget.familyId);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Create Challenge',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Template list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  final isSelected = index == _selectedTemplateIndex;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isSelected
                          ? const BorderSide(color: AppColors.primary, width: 2)
                          : BorderSide.none,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _selectedTemplateIndex = index),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Custom selection indicator instead of deprecated Radio
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : Colors.grey,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    template.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    template.description,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, size: 14, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${template.rewardPoints}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade700,
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
                },
              ),
            ),

            // Create button
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: FilledButton(
                onPressed: () async {
                  final template = templates[_selectedTemplateIndex];
                  final service = ref.read(familyGamificationServiceProvider);
                  await service.createChallenge(template);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Challenge created!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Create Challenge'),
              ),
            ),
          ],
        );
      },
    );
  }
}
