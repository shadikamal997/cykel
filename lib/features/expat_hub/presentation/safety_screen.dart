/// CYKEL — Safety Screen
/// View cycling safety guide and equipment recommendations

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/l10n/l10n.dart';
import '../domain/expat_resource.dart';
import '../application/expat_hub_providers.dart';

class SafetyScreen extends ConsumerWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the featured safety guide
    final guidesAsync = ref.watch(guidesByCategoryProvider(ResourceCategory.safety));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.expatSafetyEquipment),
      ),
      body: guidesAsync.when(
        data: (guides) {
          if (guides.isEmpty) {
            return const Center(
              child: Text('No safety guide available'),
            );
          }
          // Get the first (pinned) guide
          final guide = guides.first;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Display guide content as markdown
              MarkdownBody(
                data: guide.content,
                styleSheet: MarkdownStyleSheet(
                  h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  p: const TextStyle(fontSize: 16, height: 1.5),
                  listBullet: const TextStyle(fontSize: 16),
                  tableHead: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  tableBody: const TextStyle(fontSize: 15),
                ),
              ),
            ],
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
