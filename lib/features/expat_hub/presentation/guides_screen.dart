/// CYKEL — Guides Screen
/// Browse expat guides by category

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/expat_resource.dart';
import '../application/expat_hub_providers.dart';
import 'guide_detail_screen.dart';

class GuidesScreen extends ConsumerWidget {
  const GuidesScreen({
    super.key,
    this.category,
  });

  final ResourceCategory? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guidesAsync = category != null
        ? ref.watch(guidesByCategoryProvider(category!))
        : ref.watch(expatGuidesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(category?.displayName ?? 'All Guides'),
      ),
      body: guidesAsync.when(
        data: (guides) {
          if (guides.isEmpty) {
            return const Center(
              child: Text('No guides available'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: guides.length,
            itemBuilder: (context, index) {
              final guide = guides[index];
              return RepaintBoundary(
                child: _GuideCard(guide: guide),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading guides: $error'),
        ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.guide});

  final ExpatGuide guide;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GuideDetailScreen(
                guideId: guide.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    guide.category.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guide.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          guide.category.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (guide.isPinned)
                    const Icon(Icons.push_pin, size: 16, color: Colors.orange),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                guide.summary,
                style: TextStyle(color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildChip(
                    context,
                    icon: Icons.access_time,
                    label: '${guide.readTimeMinutes} min',
                  ),
                  const SizedBox(width: 8),
                  _buildChip(
                    context,
                    label: '${guide.difficulty.icon} ${guide.difficulty.displayName}',
                  ),
                  const Spacer(),
                  Icon(Icons.thumb_up, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${guide.helpfulCount}',
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
      ),
    );
  }

  Widget _buildChip(BuildContext context, {IconData? icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: Theme.of(context).primaryColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
