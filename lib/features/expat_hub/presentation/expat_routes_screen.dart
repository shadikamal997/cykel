/// CYKEL — Expat Routes Screen
/// Browse expat-friendly cycling routes

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../domain/expat_resource.dart';
import '../application/expat_hub_providers.dart';

class ExpatRoutesScreen extends ConsumerStatefulWidget {
  const ExpatRoutesScreen({super.key});

  @override
  ConsumerState<ExpatRoutesScreen> createState() => _ExpatRoutesScreenState();
}

class _ExpatRoutesScreenState extends ConsumerState<ExpatRoutesScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(expatRoutesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expat Routes'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Routes')),
              const PopupMenuItem(value: 'scenic', child: Text('Scenic')),
              const PopupMenuItem(value: 'tourist', child: Text('Tourist-Friendly')),
              const PopupMenuItem(value: 'commute', child: Text('Commute')),
            ],
          ),
        ],
      ),
      body: routesAsync.when(
        data: (routes) {
          final filtered = _filter == 'all' ? routes : routes.where((r) {
            if (_filter == 'scenic') return r.isScenic;
            if (_filter == 'tourist') return r.isTouristFriendly;
            if (_filter == 'commute') return r.isCommute;
            return true;
          }).toList();

          if (filtered.isEmpty) {
            return Center(child: Text(context.l10n.expatNoRoutesAvailable));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return RepaintBoundary(child: _RouteCard(route: filtered[index]));
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(context.l10n.expatErrorLoading(error.toString())),
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route});

  final ExpatRoute route;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => _RouteDetailSheet(route: route),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.route, size: 28, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${route.distanceDisplay} • ${route.estimatedTimeDisplay}',
                          style: TextStyle(
                            fontSize: 12,
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
                      color: _getDifficultyColor(route.difficulty),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${route.difficulty.icon} ${route.difficulty.displayName}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                route.description,
                style: TextStyle(color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: [
                  if (route.isScenic) _buildBadge('🌄 Scenic'),
                  if (route.isTouristFriendly) _buildBadge('👥 Tourist-Friendly'),
                  if (route.isCommute) _buildBadge('💼 Commute'),
                ],
              ),
              if (route.highlights.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Highlights:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: route.highlights.take(3).map((highlight) {
                    return Chip(
                      label: Text(
                        highlight,
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  Color _getDifficultyColor(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return Colors.green;
      case DifficultyLevel.intermediate:
        return Colors.orange;
      case DifficultyLevel.advanced:
        return Colors.red;
    }
  }
}

class _RouteDetailSheet extends StatelessWidget {
  const _RouteDetailSheet({required this.route});
  final ExpatRoute route;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(route.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${route.distanceDisplay} • ${route.estimatedTimeDisplay}',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          Text(route.description, style: const TextStyle(fontSize: 15)),
          if (route.highlights.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Highlights', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            ...route.highlights.map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(child: Text(h)),
              ]),
            )),
          ],
          if (route.tips.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Tips', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            ...route.tips.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                const Icon(Icons.lightbulb_outline, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(child: Text(t)),
              ]),
            )),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
