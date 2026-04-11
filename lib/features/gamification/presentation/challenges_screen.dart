/// CYKEL — Challenges Screen
/// View and join challenges

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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.l10n.challenges),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: challengesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.errorPrefix(e.toString()))),
        data: (challenges) {
          final activeChallenges = challenges.where((c) => c.isAvailable).toList();
          
          // Get user's active progress
          final progressList = progressAsync.valueOrNull ?? [];
          final activeProgressIds = progressList.map((p) => p.challengeId).toSet();

          // Group by type
          final grouped = <ChallengeType, List<Challenge>>{};
          for (final challenge in activeChallenges) {
            grouped.putIfAbsent(challenge.type, () => []).add(challenge);
          }

          return CustomScrollView(
            slivers: [
              // Stats Header
              SliverToBoxAdapter(
                child: statsAsync.when(
                  data: (stats) => _StatsHeader(stats: stats),
                  loading: () => const SizedBox(height: 120),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),

              // Active Challenges Section
              if (progressList.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(title: context.l10n.yourActiveChallenges),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final progress = progressList[index];
                      final challenge = activeChallenges.firstWhere(
                        (c) => c.id == progress.challengeId,
                        orElse: () => defaultChallenges.first,
                      );
                      return _ChallengeProgressCard(
                        challenge: challenge,
                        progress: progress,
                      );
                    },
                    childCount: progressList.length,
                  ),
                ),
              ],

              // Available Challenges by Type
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
                        onJoin: isActive
                            ? null
                            : () => _joinChallenge(context, ref, challenge),
                      );
                    },
                    childCount: entry.value.length,
                  ),
                ),
              ]),

              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
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
      await ref.read(gamificationServiceProvider).startChallenge(
        user.uid,
        challenge.id,
      );
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

// ─── Stats Header ─────────────────────────────────────────────────────────────

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
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
              _StatItem(
                label: context.l10n.level,
                value: '${stats.level}',
                icon: Icons.star_rounded,
              ),
              _StatItem(
                label: context.l10n.points,
                value: '${stats.totalPoints}',
                icon: Icons.emoji_events_rounded,
              ),
              _StatItem(
                label: context.l10n.badges,
                value: '${stats.badgeCount}',
                icon: Icons.military_tech_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Level progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${context.l10n.level} ${stats.level}',
                    style: AppTextStyles.labelSmall.copyWith(color: Colors.white70),
                  ),
                  Text(
                    '${context.l10n.level} ${stats.level + 1}',
                    style: AppTextStyles.labelSmall.copyWith(color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: stats.levelProgress,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.pointsToNextLevel(stats.pointsForNextLevel - (stats.totalPoints % 500)),
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
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.headline3.copyWith(color: Colors.white),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: Colors.white70),
        ),
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

// ─── Challenge Card ───────────────────────────────────────────────────────────

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.border,
          width: isActive ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _difficultyColor(challenge.difficulty).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              challenge.type.icon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Text(
          challenge.title,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              challenge.description,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _DifficultyBadge(difficulty: challenge.difficulty),
                const SizedBox(width: 8),
                const Icon(Icons.stars_rounded, size: 14, color: AppColors.warning),
                const SizedBox(width: 4),
                Text(
                  context.l10n.challengePoints(challenge.points),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
        ),
        trailing: isActive
            ? const Icon(Icons.check_circle, color: AppColors.success)
            : IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                onPressed: onJoin,
              ),
      ),
    );
  }

  Color _difficultyColor(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return AppColors.success;
      case ChallengeDifficulty.medium:
        return AppColors.warning;
      case ChallengeDifficulty.hard:
        return Colors.orange;
      case ChallengeDifficulty.extreme:
        return AppColors.error;
    }
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});

  final ChallengeDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        color = AppColors.success;
        break;
      case ChallengeDifficulty.medium:
        color = AppColors.warning;
        break;
      case ChallengeDifficulty.hard:
        color = Colors.orange;
        break;
      case ChallengeDifficulty.extreme:
        color = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _getDifficultyName(context, difficulty),
        style: AppTextStyles.caption.copyWith(color: color),
      ),
    );
  }
}

/// Helper function to get localized challenge type name
String _getChallengeTypeName(BuildContext context, ChallengeType type) {
  final l10n = context.l10n;
  switch (type) {
    case ChallengeType.distance:
      return l10n.challengeTypeDistance;
    case ChallengeType.rides:
      return l10n.challengeTypeRideCount;
    case ChallengeType.streak:
      return l10n.challengeTypeStreak;
    case ChallengeType.duration:
      return l10n.challengeTypeDistance; // Fallback, could add specific key
    case ChallengeType.elevation:
      return l10n.challengeTypeElevation;
    case ChallengeType.speed:
      return l10n.challengeTypeSpeed;
    case ChallengeType.community:
      return l10n.challengeTypeCommunity;
  }
}

/// Helper function to get localized difficulty name
String _getDifficultyName(BuildContext context, ChallengeDifficulty difficulty) {
  final l10n = context.l10n;
  switch (difficulty) {
    case ChallengeDifficulty.easy:
      return l10n.difficultyLevelEasy;
    case ChallengeDifficulty.medium:
      return l10n.difficultyLevelMedium;
    case ChallengeDifficulty.hard:
      return l10n.difficultyLevelHard;
    case ChallengeDifficulty.extreme:
      return l10n.difficultyLevelExtreme;
  }
}

// ─── Challenge Progress Card ──────────────────────────────────────────────────

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
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(challenge.type.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        challenge.description,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(progressPercent * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.headline3.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressPercent,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${progress.currentValue.toStringAsFixed(1)} / ${challenge.targetValue.toStringAsFixed(0)} ${challenge.unit}',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
