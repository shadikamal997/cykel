/// CYKEL — Advanced Routes List Screen
/// View and manage saved routes with elevation and weather data

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../domain/advanced_route.dart';
import '../application/advanced_route_providers.dart';
import 'route_creator_screen.dart';
import 'route_detail_screen.dart';

class AdvancedRoutesScreen extends ConsumerStatefulWidget {
  const AdvancedRoutesScreen({super.key});

  @override
  ConsumerState<AdvancedRoutesScreen> createState() => _AdvancedRoutesScreenState();
}

class _AdvancedRoutesScreenState extends ConsumerState<AdvancedRoutesScreen> {
  String? _selectedTag;

  @override
  Widget build(BuildContext context) {
    final routesAsync = _selectedTag != null
        ? ref.watch(routesByTagProvider(_selectedTag!))
        : ref.watch(userRoutesProvider);
    
    final stats = ref.watch(routeStatisticsProvider);
    final tags = ref.watch(routeTagsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.routesMyRoutes),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(tags),
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics card
          _StatisticsCard(stats: stats),
          
          // Tag filter chips
          if (tags.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedTag == null,
                    onSelected: (_) => setState(() => _selectedTag = null),
                  ),
                  const SizedBox(width: 8),
                  ...tags.map((tag) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(tag),
                          selected: _selectedTag == tag,
                          onSelected: (_) => setState(() => _selectedTag = tag),
                        ),
                      )),
                ],
              ),
            ),
          
          // Routes list
          Expanded(
            child: routesAsync.when(
              data: (routes) {
                if (routes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.route,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedTag != null
                              ? 'No routes with tag "$_selectedTag"'
                              : 'No routes yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedTag != null
                              ? 'Try selecting a different tag'
                              : 'Create your first multi-waypoint route',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(userRoutesProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: routes.length,
                    itemBuilder: (context, index) {
                      return RepaintBoundary(
                        child: _RouteCard(route: routes[index]),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    Text(context.l10n.routesErrorLoadingRoutes(error.toString())),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(userRoutesProvider),
                      child: Text(context.l10n.routesRetry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RouteCreatorScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(context.l10n.routesCreate),
      ),
    );
  }

  void _showFilterDialog(List<String> tags) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Tag'),
        content: RadioGroup<String?>(
          groupValue: _selectedTag,
          onChanged: (value) {
            setState(() => _selectedTag = value);
            Navigator.pop(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('All Routes'),
                leading: Radio<String?>(
                  value: null,
                ),
              ),
              ...tags.map((tag) => ListTile(
                    title: Text(tag),
                    leading: Radio<String?>(
                      value: tag,
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Statistics Card ────────────────────────────────────────────────────────

class _StatisticsCard extends StatelessWidget {
  const _StatisticsCard({required this.stats});

  final RouteStatistics stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.route,
            label: 'Routes',
            value: stats.totalRoutes.toString(),
          ),
          _StatItem(
            icon: Icons.straighten,
            label: 'Distance',
            value: stats.formattedTotalDistance,
          ),
          _StatItem(
            icon: Icons.terrain,
            label: 'Elevation',
            value: stats.formattedTotalElevationGain,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

// ─── Route Card ─────────────────────────────────────────────────────────────

class _RouteCard extends ConsumerWidget {
  const _RouteCard({required this.route});

  final AdvancedRoute route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RouteDetailScreen(routeId: route.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      route.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (route.hasWeatherData)
                    Text(
                      route.weatherForecast!.condition.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Stats
              Row(
                children: [
                  _RouteStatChip(
                    icon: Icons.straighten,
                    label: '${route.totalDistanceKm.toStringAsFixed(1)} km',
                  ),
                  const SizedBox(width: 8),
                  _RouteStatChip(
                    icon: Icons.schedule,
                    label: '${route.totalJourneyTimeMinutes ~/ 60}h ${route.totalJourneyTimeMinutes % 60}m',
                  ),
                  const SizedBox(width: 8),
                  if (route.totalStops > 0)
                    _RouteStatChip(
                      icon: Icons.place,
                      label: '${route.totalStops} stops',
                    ),
                ],
              ),

              // Elevation
              if (route.hasElevationData) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.terrain,
                      size: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${route.elevationProfile!.totalElevationGainM.round()}m gain',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(route.routeDifficulty),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        route.elevationProfile!.difficultyLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Tags
              if (route.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: route.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],

              // Notes preview
              if (route.notes != null) ...[
                const SizedBox(height: 8),
                Text(
                  route.notes!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _RouteStatChip extends StatelessWidget {
  const _RouteStatChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
