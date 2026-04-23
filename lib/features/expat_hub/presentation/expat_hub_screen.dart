/// CYKEL — Expat Hub Main Screen
/// Landing page for expat resources and guides

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/cached_image.dart';

import '../domain/expat_resource.dart';
import '../application/expat_hub_providers.dart';
import 'guide_detail_screen.dart';
import 'bike_shops_screen.dart';
import 'cycling_rules_screen.dart';
import 'safety_screen.dart';
import 'culture_screen.dart';
import 'emergency_contacts_screen.dart';

class ExpatHubScreen extends ConsumerStatefulWidget {
  const ExpatHubScreen({super.key});

  @override
  ConsumerState<ExpatHubScreen> createState() => _ExpatHubScreenState();
}

class _ExpatHubScreenState extends ConsumerState<ExpatHubScreen> {
  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(hubStatisticsProvider);
    final featuredGuidesAsync = ref.watch(featuredGuidesProvider);
    final topTipsAsync = ref.watch(topTipsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.expatHubTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _ExpatSearchDelegate(),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(hubStatisticsProvider);
          ref.invalidate(featuredGuidesProvider);
          ref.invalidate(topTipsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome Banner
            _buildWelcomeBanner(context),
            const SizedBox(height: 24),

            // Statistics Overview
            statsAsync.when(
              data: (stats) => _buildStatistics(context, stats),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Quick Access Categories
            _buildSectionTitle(context.l10n.expatExploreResources),
            const SizedBox(height: 12),
            _buildCategoryGrid(context),
            const SizedBox(height: 24),

            // Featured Guides
            _buildSectionTitle(context.l10n.expatFeaturedGuides),
            const SizedBox(height: 12),
            featuredGuidesAsync.when(
              data: (guides) => guides.isEmpty
                  ? Center(child: Text(context.l10n.expatNoFeaturedGuides))
                  : _buildFeaturedGuides(context, guides),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(child: Text(context.l10n.expatErrorLoadingGuides)),
            ),
            const SizedBox(height: 24),

            // Top Tips
            _buildSectionTitle(context.l10n.expatQuickTips),
            const SizedBox(height: 12),
            topTipsAsync.when(
              data: (tips) => tips.isEmpty
                  ? Center(child: Text(context.l10n.expatNoTipsAvailable))
                  : _buildTopTips(context, tips),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(child: Text(context.l10n.expatErrorLoadingTips)),
            ),
            const SizedBox(height: 24),

            // Emergency Quick Access
            _buildEmergencyCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text(
            '🇩🇰',
            style: TextStyle(fontSize: 40),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to Copenhagen!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your guide to cycling like a local',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(BuildContext context, HubStatistics stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.menu_book,
            value: stats.totalGuides.toString(),
            label: 'Guides',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.lightbulb,
            value: stats.totalTips.toString(),
            label: 'Tips',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.store,
            value: stats.totalShops.toString(),
            label: 'Shops',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.route,
            value: stats.totalRoutes.toString(),
            label: 'Routes',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    final featuredGuideAsync = ref.watch(featuredGettingStartedGuideProvider);
    
    final categories = [
      _CategoryItem(
        category: ResourceCategory.gettingStarted,
        onTap: () {
          final guide = featuredGuideAsync.value;
          if (guide != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GuideDetailScreen(guideId: guide.id),
              ),
            );
          }
        },
      ),
      _CategoryItem(
        category: ResourceCategory.cyclingLaws,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CyclingRulesScreen(),
          ),
        ),
      ),
      _CategoryItem(
        category: ResourceCategory.safety,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SafetyScreen(),
          ),
        ),
      ),
      _CategoryItem(
        category: ResourceCategory.shopping,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BikeShopsScreen(),
          ),
        ),
      ),
      _CategoryItem(
        category: ResourceCategory.culture,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CultureScreen(),
          ),
        ),
      ),
      _CategoryItem(
        category: ResourceCategory.emergency,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EmergencyContactsScreen(),
          ),
        ),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: categories,
    );
  }

  Widget _buildFeaturedGuides(BuildContext context, List<ExpatGuide> guides) {
    // Filter out the featured getting started guide to avoid showing it twice
    final featuredGuide = ref.watch(featuredGettingStartedGuideProvider).value;
    final filteredGuides = featuredGuide != null
        ? guides.where((g) => g.id != featuredGuide.id).toList()
        : guides;
    
    if (filteredGuides.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filteredGuides.length,
        itemBuilder: (context, index) {
          final guide = filteredGuides[index];
          return _FeaturedGuideCard(guide: guide);
        },
      ),
    );
  }

  Widget _buildTopTips(BuildContext context, List<QuickTip> tips) {
    return Column(
      children: tips.take(5).map((tip) {
        return _QuickTipCard(tip: tip);
      }).toList(),
    );
  }

  Widget _buildEmergencyCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emergency, color: Colors.red[700], size: 28),
              const SizedBox(width: 12),
              const Text(
                'Emergency Contacts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Quick access to important emergency numbers and contacts',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmergencyContactsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.phone),
            label: const Text('View All Contacts'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Item Widget ──────────────────────────────────────────────────

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.category,
    required this.onTap,
  });

  final ResourceCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              category.icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 6),
            Text(
              category.displayName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Featured Guide Card ───────────────────────────────────────────────────

class _FeaturedGuideCard extends StatelessWidget {
  const _FeaturedGuideCard({required this.guide});

  final ExpatGuide guide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GuideDetailScreen(guideId: guide.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image
              if (guide.coverImageUrl != null)
                CachedImage(
                  imageUrl: guide.coverImageUrl!,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              else
                _buildPlaceholder(),

              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          guide.category.icon,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            guide.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${guide.readTimeMinutes} min read',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          guide.difficulty.icon,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          guide.difficulty.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
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

  Widget _buildPlaceholder() {
    return Container(
      height: 100,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.menu_book, size: 40, color: Colors.grey),
      ),
    );
  }
}

// ─── Quick Tip Card ────────────────────────────────────────────────────────

class _QuickTipCard extends StatelessWidget {
  const _QuickTipCard({required this.tip});

  final QuickTip tip;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  tip.icon ?? tip.category.icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tip.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tip.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpatSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults(context);

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Type to search guides, tips, and resources'));
    }
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('expatGuides')
          .where('searchKeywords', arrayContains: query.toLowerCase())
          .limit(20)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(child: Text('No results for "$query"'));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.article_outlined),
              title: Text(data['title'] as String? ?? ''),
              subtitle: Text(data['summary'] as String? ?? '',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => close(context, docs[i].id),
            );
          },
        );
      },
    );
  }
}
