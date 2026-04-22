/// CYKEL — Bike Shops Screen
/// Browse and search bike shops

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/l10n.dart';
import '../domain/expat_resource.dart';
import '../application/expat_hub_providers.dart';

class BikeShopsScreen extends ConsumerStatefulWidget {
  const BikeShopsScreen({super.key});

  @override
  ConsumerState<BikeShopsScreen> createState() => _BikeShopsScreenState();
}

class _BikeShopsScreenState extends ConsumerState<BikeShopsScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final shopsAsync = ref.watch(bikeShopsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.expatBikeShops),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filter = value),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'all', child: Text(context.l10n.expatAllShops)),
              PopupMenuItem(value: 'expat', child: Text(context.l10n.expatExpatFriendly)),
              PopupMenuItem(value: 'repair', child: Text(context.l10n.expatRepairServices)),
              PopupMenuItem(value: 'sales', child: Text(context.l10n.expatSales)),
            ],
          ),
        ],
      ),
      body: shopsAsync.when(
        data: (shops) {
          final filtered = _filter == 'all' ? shops : shops.where((s) {
            if (_filter == 'expat') return s.isExpatFriendly;
            if (_filter == 'repair') return s.services.contains(ShopService.repair);
            if (_filter == 'sales') return s.services.contains(ShopService.sales);
            return true;
          }).toList();

          if (filtered.isEmpty) {
            return Center(child: Text(context.l10n.expatNoShopsFound));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) => RepaintBoundary(
              child: _ShopCard(shop: filtered[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading shops: $error'),
        ),
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.shop});

  final BikeShop shop;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.store, size: 32, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (shop.hasRatings)
                        Row(
                          children: [
                            ...List.generate(5, (i) {
                              return Icon(
                                i < shop.rating.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 16,
                                color: Colors.amber,
                              );
                            }),
                            const SizedBox(width: 4),
                            Text(
                              '${shop.rating.toStringAsFixed(1)} (${shop.reviewCount})',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (shop.isExpatFriendly)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '🇬🇧 English',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    shop.address,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            if (shop.description != null) ...[
              const SizedBox(height: 8),
              Text(
                shop.description!,
                style: TextStyle(color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: shop.services.map((service) {
                return Chip(
                  label: Text(
                    service.displayName,
                    style: const TextStyle(fontSize: 11),
                  ),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (shop.phone != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _launchPhone(shop.phone!),
                      icon: const Icon(Icons.phone, size: 16),
                      label: Text(context.l10n.expatCall),
                    ),
                  ),
                if (shop.phone != null && shop.website != null)
                  const SizedBox(width: 8),
                if (shop.website != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _launchUrl(shop.website!),
                      icon: const Icon(Icons.language, size: 16),
                      label: Text(context.l10n.expatWebsite),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
