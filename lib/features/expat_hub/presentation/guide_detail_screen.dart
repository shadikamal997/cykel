/// CYKEL — Guide Detail Screen
/// Full view of an expat guide with markdown content

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/expat_resource.dart';
import '../application/expat_hub_providers.dart';

class GuideDetailScreen extends ConsumerStatefulWidget {
  const GuideDetailScreen({
    super.key,
    required this.guideId,
  });

  final String guideId;

  @override
  ConsumerState<GuideDetailScreen> createState() => _GuideDetailScreenState();
}

class _GuideDetailScreenState extends ConsumerState<GuideDetailScreen> {
  bool _wasHelpful = false;

  @override
  void initState() {
    super.initState();
    // Increment view count when guide is opened
    Future.microtask(() {
      ref.read(expatHubServiceProvider).incrementGuideView(widget.guideId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final guideAsync = ref.watch(guideByIdProvider(widget.guideId));

    return guideAsync.when(
      data: (guide) {
        if (guide == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Guide Not Found')),
            body: const Center(child: Text('This guide could not be found.')),
          );
        }
        return _buildGuideContent(context, guide);
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error loading guide: $error')),
      ),
    );
  }

  Widget _buildGuideContent(BuildContext context, ExpatGuide guide) {
    return Scaffold(
      appBar: AppBar(
        title: Text(guide.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              SharePlus.instance.share(
                ShareParams(
                  text: 'Check out this guide: ${guide.title}\n\n${guide.summary}',
                  subject: guide.title,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Guide metadata
                _buildMetadata(context, guide),
                const SizedBox(height: 24),

                // Main content (Markdown)
                MarkdownBody(
                  data: guide.content,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                    h1: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    h2: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    h3: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    p: const TextStyle(fontSize: 16, height: 1.6),
                    listBullet: const TextStyle(fontSize: 16),
                  ),
                ),

                const SizedBox(height: 32),

                // Related guides
                if (guide.relatedGuides.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildRelatedGuides(context, guide),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          ),

          // Bottom action bar
          _buildBottomBar(context, guide),
        ],
      ),
    );
  }

  Widget _buildMetadata(BuildContext context, ExpatGuide guide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(guide.category.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                guide.category.displayName,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Title
        Text(
          guide.title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Summary
        Text(
          guide.summary,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),

        // Stats row
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildStatItem(
              icon: Icons.access_time,
              text: '${guide.readTimeMinutes} min read',
            ),
            _buildStatItem(
              icon: Icons.signal_cellular_alt,
              text: guide.difficulty.displayName,
            ),
            _buildStatItem(
              icon: Icons.visibility,
              text: '${guide.viewCount} views',
            ),
            _buildStatItem(
              icon: Icons.thumb_up,
              text: '${guide.helpfulCount} helpful',
            ),
          ],
        ),

        if (guide.tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: guide.tags.map((tag) {
              return Chip(
                label: Text(tag),
                backgroundColor: Colors.grey[200],
                labelStyle: const TextStyle(fontSize: 12),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildStatItem({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildRelatedGuides(BuildContext context, ExpatGuide guide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Related Guides',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...guide.relatedGuides.map((relatedId) {
          final relatedAsync = ref.watch(guideByIdProvider(relatedId));
          return relatedAsync.when(
            data: (relatedGuide) {
              if (relatedGuide == null) return const SizedBox.shrink();
              
              return Card(
                child: ListTile(
                  leading: Text(
                    relatedGuide.category.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(relatedGuide.title),
                  subtitle: Text('${relatedGuide.readTimeMinutes} min read'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GuideDetailScreen(
                          guideId: relatedGuide.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
          );
        }),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, ExpatGuide guide) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Was this helpful?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: _wasHelpful
                  ? null
                  : () {
                      setState(() => _wasHelpful = true);
                      ref
                          .read(expatHubServiceProvider)
                          .markGuideHelpful(widget.guideId);
                    },
              icon: Icon(_wasHelpful ? Icons.check : Icons.thumb_up),
              label: Text(_wasHelpful ? 'Thanks!' : 'Helpful'),
              style: FilledButton.styleFrom(
                backgroundColor: _wasHelpful
                    ? Colors.green
                    : Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
