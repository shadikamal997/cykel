/// CYKEL — Challenges Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/gamification_provider.dart';
import '../domain/gamification.dart';

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(activeChallengesProvider);
    final progressAsync = ref.watch(userChallengeProgressProvider);
    final statsAsync = ref.watch(userStatsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.colors.background,
        appBar: AppBar(
          title: Text(context.l10n.challenges),
          backgroundColor: context.colors.surface,
          foregroundColor: context.colors.textPrimary,
          elevation: 0,
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: context.colors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              const Tab(text: 'Active'),
              const Tab(text: 'Browse'),
            ],
          ),
        ),
        body: challengesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text(context.l10n.errorPrefix(err.toString()))),
          data: (challenges) {
            final activeChallenges = challenges.where((c) => c.isAvailable).toList();
            final progressList = progressAsync.valueOrNull ?? [];
            final activeProgressIds = progressList.map((p) => p.challengeId).toSet();

            final grouped = <ChallengeType, List<Challenge>>{};
            for (final challenge in activeChallenges) {
              grouped.putIfAbsent(challenge.type, () => []).add(challenge);
            }

            return Column(
              children: [
                // Stats header (shown above tabs)
                statsAsync.when(
                  data: (stats) => _StatsHeader(stats: stats),
                  loading: () => const SizedBox(height: 8),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // ─── Tab 1: Active / My Challenges ───────────────────
                      _ActiveTab(
                        progressList: progressList,
                        activeChallenges: activeChallenges,
                        onJoin: (c) => _joinChallenge(context, ref, c),
                      ),

                      // ─── Tab 2: Browse all challenges ─────────────────────
                      _BrowseTab(
                        grouped: grouped,
                        activeProgressIds: activeProgressIds,
                        onJoin: (c) => _joinChallenge(context, ref, c),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _joinChallenge(
    BuildContext context,
    WidgetRef ref,
    Challenge challenge,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    try {
      await ref.read(gamificationServiceProvider).startChallenge(user.uid, challenge.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.joinedChallenge(challenge.title)),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.errorPrefix(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ─── Active Tab ───────────────────────────────────────────────────────────────

class _ActiveTab extends StatelessWidget {
  const _ActiveTab({
    required this.progressList,
    required this.activeChallenges,
    required this.onJoin,
  });

  final List<ChallengeProgress> progressList;
  final List<Challenge> activeChallenges;
  final void Function(Challenge) onJoin;

  @override
  Widget build(BuildContext context) {
    if (progressList.isEmpty) {
      return const _EmptyActive(onBrowse: null);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: progressList.length,
      itemBuilder: (context, index) {
        final progress = progressList[index];
        final challenge = activeChallenges.firstWhere(
          (c) => c.id == progress.challengeId,
          orElse: () => defaultChallenges.first,
        );
        return _ChallengeProgressCard(challenge: challenge, progress: progress);
      },
    );
  }
}

// ─── Browse Tab ───────────────────────────────────────────────────────────────

class _BrowseTab extends StatelessWidget {
  const _BrowseTab({
    required this.grouped,
    required this.activeProgressIds,
    required this.onJoin,
  });

  final Map<ChallengeType, List<Challenge>> grouped;
  final Set<String> activeProgressIds;
  final void Function(Challenge) onJoin;

  @override
  Widget build(BuildContext context) {
    if (grouped.isEmpty) {
      return Center(
        child: Text(
          'No challenges available',
          style: AppTextStyles.bodyMedium.copyWith(color: context.colors.textSecondary),
        ),
      );
    }
    return CustomScrollView(
      slivers: [
        ...grouped.entries.expand((entry) => [
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: '${entry.key.icon} ${_getChallengeTypeName(context, entry.key)}',
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final challenge = entry.value[index];
                final isActive = activeProgressIds.contains(challenge.id);
                return _ChallengeCard(
                  challenge: challenge,
                  isActive: isActive,
                  onJoin: isActive ? null : () => onJoin(challenge),
                );
              },
              childCount: entry.value.length,
            ),
          ),
        ]),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }
}

// ─── Empty Active State ───────────────────────────────────────────────────────

class _EmptyActive extends StatelessWidget {
  const _EmptyActive({required this.onBrowse});
  final VoidCallback? onBrowse;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_outlined, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'No active challenges',
              style: AppTextStyles.headline3.copyWith(color: context.colors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse challenges and join one to start tracking your progress.',
              style: AppTextStyles.bodyMedium.copyWith(color: context.colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats Header ─────────────────────────────────────────────────────────────

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.stats});
  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: context.l10n.level, value: '${stats.level}', icon: Icons.star_rounded),
              _StatItem(label: context.l10n.points, value: '${stats.totalPoints}', icon: Icons.emoji_events_rounded),
              _StatItem(label: context.l10n.badges, value: '${stats.badgeCount}', icon: Icons.military_tech_rounded),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${context.l10n.level} ${stats.level}',
                      style: AppTextStyles.labelSmall.copyWith(color: Colors.white70)),
                  Text('${context.l10n.level} ${stats.level + 1}',
                      style: AppTextStyles.labelSmall.copyWith(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: stats.levelProgress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.pointsToNextLevel(
                    stats.pointsForNextLevel - (stats.totalPoints % 500)),
                style: AppTextStyles.caption.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 26),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.headline3.copyWith(color: Colors.white)),
        Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
      ],
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title, style: AppTextStyles.headline3),
    );
  }
}

// ─── Challenge Card (Browse) ──────────────────────────────────────────────────

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.challenge,
    required this.isActive,
    this.onJoin,
  });

  final Challenge challenge;
  final bool isActive;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final diffColor = _difficultyColor(challenge.difficulty);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? AppColors.primary : context.colors.border,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Difficulty color strip
          Container(
            width: 6,
            height: 90,
            decoration: BoxDecoration(
              color: diffColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                bottomLeft: Radius.circular(13),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: diffColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(challenge.type.icon, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.title,
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          challenge.description,
                          style: AppTextStyles.bodySmall.copyWith(color: context.colors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _DifficultyBadge(difficulty: challenge.difficulty),
                            const SizedBox(width: 8),
                            const Icon(Icons.stars_rounded, size: 13, color: AppColors.warning),
                            const SizedBox(width: 3),
                            Text(
                              context.l10n.challengePoints(challenge.points),
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  isActive
                      ? const Icon(Icons.check_circle, color: AppColors.success, size: 28)
                      : IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 28),
                          onPressed: onJoin,
                          tooltip: 'Join',
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _difficultyColor(ChallengeDifficulty difficulty) {
    return switch (difficulty) {
      ChallengeDifficulty.easy    => AppColors.success,
      ChallengeDifficulty.medium  => AppColors.warning,
      ChallengeDifficulty.hard    => Colors.orange,
      ChallengeDifficulty.extreme => AppColors.error,
    };
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});
  final ChallengeDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final color = switch (difficulty) {
      ChallengeDifficulty.easy    => AppColors.success,
      ChallengeDifficulty.medium  => AppColors.warning,
      ChallengeDifficulty.hard    => Colors.orange,
      ChallengeDifficulty.extreme => AppColors.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _getDifficultyName(context, difficulty),
        style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Challenge Progress Card (Active) ────────────────────────────────────────

class _ChallengeProgressCard extends StatelessWidget {
  const _ChallengeProgressCard({
    required this.challenge,
    required this.progress,
  });

  final Challenge challenge;
  final ChallengeProgress progress;

  @override
  Widget build(BuildContext context) {
    final progressPercent = progress.progressPercent(challenge.targetValue);
    final pct = (progressPercent * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Center(
                    child: Text(challenge.type.icon, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        challenge.description,
                        style: AppTextStyles.bodySmall.copyWith(color: context.colors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Circular progress indicator
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progressPercent,
                        backgroundColor: context.colors.border,
                        color: AppColors.primary,
                        strokeWidth: 4,
                      ),
                      Text(
                        '$pct%',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progressPercent,
                backgroundColor: context.colors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progress.currentValue.toStringAsFixed(1)} / ${challenge.targetValue.toStringAsFixed(0)} ${challenge.unit}',
                  style: AppTextStyles.caption.copyWith(color: context.colors.textSecondary),
                ),
                Row(
                  children: [
                    const Icon(Icons.stars_rounded, size: 12, color: AppColors.warning),
                    const SizedBox(width: 3),
                    Text(
                      context.l10n.challengePoints(challenge.points),
                      style: AppTextStyles.caption.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600),
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
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _getChallengeTypeName(BuildContext context, ChallengeType type) {
  final l10n = context.l10n;
  return switch (type) {
    ChallengeType.distance  => l10n.challengeTypeDistance,
    ChallengeType.rides     => l10n.challengeTypeRideCount,
    ChallengeType.streak    => l10n.challengeTypeStreak,
    ChallengeType.duration  => l10n.challengeTypeDistance,
    ChallengeType.elevation => l10n.challengeTypeElevation,
    ChallengeType.speed     => l10n.challengeTypeSpeed,
    ChallengeType.community => l10n.challengeTypeCommunity,
  };
}

String _getDifficultyName(BuildContext context, ChallengeDifficulty difficulty) {
  final l10n = context.l10n;
  return switch (difficulty) {
    ChallengeDifficulty.easy    => l10n.difficultyLevelEasy,
    ChallengeDifficulty.medium  => l10n.difficultyLevelMedium,
    ChallengeDifficulty.hard    => l10n.difficultyLevelHard,
    ChallengeDifficulty.extreme => l10n.difficultyLevelExtreme,
  };
}
