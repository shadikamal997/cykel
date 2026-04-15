/// CYKEL — Buddy Discovery Screen
/// Find and connect with compatible riding partners

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/buddy_matching_providers.dart';
import '../domain/buddy_profile.dart';
import 'buddy_profile_setup_screen.dart';

class BuddyDiscoveryScreen extends ConsumerStatefulWidget {
  const BuddyDiscoveryScreen({super.key});

  @override
  ConsumerState<BuddyDiscoveryScreen> createState() => _BuddyDiscoveryScreenState();
}

class _BuddyDiscoveryScreenState extends ConsumerState<BuddyDiscoveryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  RidingLevel? _filterLevel;
  final List<RidingInterest> _filterInterests = [];
  bool _showFilters = false;

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
    final currentBuddyProfileAsync = ref.watch(currentBuddyProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Find Riding Buddies'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => _navigateToProfile(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
          tabs: const [
            Tab(text: 'For You'),
            Tab(text: 'Requests'),
            Tab(text: 'Matches'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filters section
          if (_showFilters)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filters',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Level filter
                  const Text('Riding Level ', style: AppTextStyles.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All Levels'),
                        selected: _filterLevel == null,
                        onSelected: (selected) {
                          setState(() {
                            _filterLevel = null;
                          });
                        },
                      ),
                      ...RidingLevel.values.map((level) {
                        return FilterChip(
                          label: Text('${level.icon} ${level.displayName}'),
                          selected: _filterLevel == level,
                          onSelected: (selected) {
                            setState(() {
                              _filterLevel = selected ? level : null;
                            });
                          },
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Interest filter
                  const Text('Interests', style: AppTextStyles.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: RidingInterest.values.map((interest) {
                      final isSelected = _filterInterests.contains(interest);
                      return FilterChip(
                        label: Text('${interest.icon} ${interest.displayName}'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _filterInterests.add(interest);
                            } else {
                              _filterInterests.remove(interest);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Tab content
          Expanded(
            child: currentBuddyProfileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (buddyProfile) {
                if (buddyProfile == null) {
                  return _buildCreateProfilePrompt();
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSuggestedTab(),
                    _buildRequestsTab(),
                    _buildMatchesTab(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateProfilePrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👥', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Create Your Buddy Profile',
              style: AppTextStyles.headline3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Set up your riding profile to find compatible cycling partners',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _navigateToProfile(context),
              child: const Text('Create Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedTab() {
    final suggestedBuddiesAsync = ref.watch(suggestedBuddiesProvider(20));

    return suggestedBuddiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('😕', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                'Unable to load suggestions',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      data: (buddies) {
        if (buddies.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔍', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  const Text(
                    'No Matches Found',
                    style: AppTextStyles.headline3,
                    textAlign:TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your preferences or check back later',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(suggestedBuddiesProvider(20));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: buddies.length,
            itemBuilder: (context, index) {
              return _BuddyCard(
                buddy: buddies[index],
                onTap: () => _showBuddyDetail(context, buddies[index]),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    final pendingRequestsAsync = ref.watch(pendingRequestsProvider);

    return pendingRequestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📭', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  const Text(
                    'No Pending Requests',
                    style: AppTextStyles.headline3,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Match requests will appear here',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(pendingRequestsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              return _MatchRequestCard(match: requests[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildMatchesTab() {
    final matchesAsync = ref.watch(acceptedMatchesProvider);

    return matchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (matches) {
        if (matches.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🤝', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  const Text(
                    'No Matches Yet',
                    style: AppTextStyles.headline3,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start connecting with riders in the "For You" tab',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(acceptedMatchesProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              return _MatchCard(match: matches[index]);
            },
          ),
        );
      },
    );
  }

  void _showBuddyDetail(BuildContext context, BuddyProfile buddy) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BuddyDetailSheet(buddy: buddy),
    );
  }

  void _navigateToProfile(BuildContext context) {
    final currentProfile = ref.read(currentBuddyProfileProvider).value;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BuddyProfileSetupScreen(
          existingProfile: currentProfile,
        ),
      ),
    );
  }
}

// ─── Buddy Card ──────────────────────────────────────────────────────────────

class _BuddyCard extends ConsumerWidget {
  const _BuddyCard({
    required this.buddy,
    required this.onTap,
  });

  final BuddyProfile buddy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentProfile = ref.watch(currentBuddyProfileProvider).value;

    final compatibilityScore = currentProfile?.calculateCompatibility(buddy) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: buddy.photoUrl != null
                        ? NetworkImage(buddy.photoUrl!)
                        : null,
                    child: buddy.photoUrl == null
                        ? Text(
                            buddy.displayName[0].toUpperCase(),
                            style: AppTextStyles.headline3,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              buddy.displayName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (buddy.verifiedRider) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, size: 16, color: Colors.blue),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${buddy.ridingLevel.icon} ${buddy.ridingLevel.displayName}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (buddy.hometown != null)
                          Text(
                            '📍 ${buddy.hometown}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Compatibility score
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getScoreColor(compatibilityScore).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getScoreColor(compatibilityScore).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '$compatibilityScore%',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: _getScoreColor(compatibilityScore),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              if (buddy.bio != null) ...[
                const SizedBox(height: 12),
                Text(
                  buddy.bio!,
                  style: AppTextStyles.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Interests
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: buddy.interests.take(4).map((interest) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${interest.icon} ${interest.displayName}',
                      style: AppTextStyles.caption,
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 12),
              
              // Stats
              Row(
                children: [
                  _StatBadge(
                    icon: Icons.route,
                    label: '${buddy.totalRides} rides',
                  ),
                  const SizedBox(width: 12),
                  if (buddy.averagePaceKmh != null)
                    _StatBadge(
                      icon: Icons.speed,
                      label: '${buddy.averagePaceKmh!.toStringAsFixed(1)} km/h',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.grey;
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─── Buddy Detail Sheet ──────────────────────────────────────────────────────

class _BuddyDetailSheet extends ConsumerWidget {
  const _BuddyDetailSheet({required this.buddy});

  final BuddyProfile buddy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentProfile = ref.watch(currentBuddyProfileProvider).value;
    final compatibilityScore = currentProfile?.calculateCompatibility(buddy) ?? 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Profile header
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: buddy.photoUrl != null
                                ? NetworkImage(buddy.photoUrl!)
                                : null,
                            child: buddy.photoUrl == null
                                ? Text(
                                    buddy.displayName[0].toUpperCase(),
                                    style: const TextStyle(fontSize: 32),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                buddy.displayName,
                                style: AppTextStyles.headline2,
                              ),
                              if (buddy.verifiedRider) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.verified, color: Colors.blue),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _getScoreColor(compatibilityScore).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getScoreColor(compatibilityScore).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              '$compatibilityScore% Match',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: _getScoreColor(compatibilityScore),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Bio
                    if (buddy.bio != null) ...[
                      const Text('About', style: AppTextStyles.labelMedium),
                      const SizedBox(height: 8),
                      Text(buddy.bio!, style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 24),
                    ],
                    
                    // Stats
                    const Text('Stats', style: AppTextStyles.labelMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _InfoChip(
                          icon: Icons.trending_up,
                          label: buddy.ridingLevel.displayName,
                        ),
                        _InfoChip(
                          icon: Icons.route,
                          label: '${buddy.totalRides} rides',
                        ),
                        if (buddy.averagePaceKmh != null)
                          _InfoChip(
                            icon: Icons.speed,
                            label: '${buddy.averagePaceKmh!.toStringAsFixed(1)} km/h avg',
                          ),
                        if (buddy.hometown != null)
                          _InfoChip(
                            icon: Icons.location_on,
                            label: buddy.hometown!,
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Interests
                    const Text('Interests', style: AppTextStyles.labelMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: buddy.interests.map((interest) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${interest.icon} ${interest.displayName}',
                            style: AppTextStyles.bodySmall,
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Availability
                    if (buddy.availability.isNotEmpty) ...[
                      const Text('Availability', style: AppTextStyles.labelMedium),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: buddy.availability.map((avail) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${avail.icon} ${avail.displayName}',
                              style: AppTextStyles.bodySmall,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Languages
                    if (buddy.spokenLanguages.isNotEmpty) ...[
                      const Text('Languages', style: AppTextStyles.labelMedium),
                      const SizedBox(height: 8),
                      Text(
                        buddy.spokenLanguages.join(', ').toUpperCase(),
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
              
              // Action buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _sendMatchRequest(context, ref),
                        child: const Text('Send Request'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendMatchRequest(BuildContext context, WidgetRef ref) async {
    final currentUser = ref.read(currentUserProvider);
    final currentProfile = ref.read(currentBuddyProfileProvider).value;
    
    if (currentUser == null || currentProfile == null) return;

    try {
      final service = ref.read(buddyMatchingServiceProvider);
      final compatibilityScore = currentProfile.calculateCompatibility(buddy);
      
      await service.sendMatchRequest(
        fromUserId: currentUser.uid,
        toUserId: buddy.userId,
        compatibilityScore: compatibilityScore,
      );

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Match request sent to ${buddy.displayName}!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.grey;
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ─── Match Request Card ──────────────────────────────────────────────────────

class _MatchRequestCard extends ConsumerWidget {
  const _MatchRequestCard({required this.match});

  final BuddyMatch match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buddyAsync = ref.watch(buddyProfileProvider(match.userId1));

    return buddyAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (buddy) {
        if (buddy == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: buddy.photoUrl != null
                          ? NetworkImage(buddy.photoUrl!)
                          : null,
                      child: buddy.photoUrl == null
                          ? Text(buddy.displayName[0].toUpperCase())
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            buddy.displayName,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${match.compatibilityScore}% match',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _declineRequest(context, ref),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _acceptRequest(context, ref),
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _acceptRequest(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(buddyMatchingServiceProvider);
      await service.acceptMatchRequest(match.id);
      
      ref.invalidate(pendingRequestsProvider);
      ref.invalidate(acceptedMatchesProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match accepted!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _declineRequest(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(buddyMatchingServiceProvider);
      await service.declineMatchRequest(match.id);
      
      ref.invalidate(pendingRequestsProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request declined')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

// ─── Match Card ──────────────────────────────────────────────────────────────

class _MatchCard extends ConsumerWidget {
  const _MatchCard({required this.match});

  final BuddyMatch match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();

    final otherUserId = match.getOtherUserId(currentUser.uid);
    final buddyAsync = ref.watch(buddyProfileProvider(otherUserId));

    return buddyAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (buddy) {
        if (buddy == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: InkWell(
            onTap: () {
              // TODO: Navigate to chat or buddy detail
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat coming soon')),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: buddy.photoUrl != null
                        ? NetworkImage(buddy.photoUrl!)
                        : null,
                    child: buddy.photoUrl == null
                        ? Text(buddy.displayName[0].toUpperCase())
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          buddy.displayName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (match.totalRidesTogether > 0)
                          Text(
                            '${match.totalRidesTogether} rides together',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
