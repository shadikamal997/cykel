/// CYKEL — Provider Listings Management Screen
/// Shows all marketplace listings created by this provider with
/// stats (views / saves), mark-as-sold toggle, and edit/delete actions.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/cached_image.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../marketplace/data/marketplace_service.dart';
import '../../marketplace/domain/marketplace_listing.dart';
import '../../marketplace/providers/marketplace_providers.dart';

class ProviderListingsScreen extends ConsumerWidget {
  const ProviderListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final listingsAsync = ref.watch(myListingsProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        title: Text(l10n.marketplaceMyListings, style: AppTextStyles.headline3),
      ),
      body: listingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(l10n.changesSaveError(e.toString()),
              style: AppTextStyles.bodySmall),
        ),
        data: (listings) {
          if (listings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sell_outlined,
                        size: 56, color: context.colors.textSecondary),
                    const SizedBox(height: 16),
                    Text(l10n.listingMyListingsEmpty,
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: context.colors.textSecondary),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () =>
                          context.go(AppRoutes.marketplaceCreate),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.marketplaceSell),
                      style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                          elevation: 0),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: listings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) =>
                _ListingCard(listing: listings[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(AppRoutes.marketplaceCreate),
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
        foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
        elevation: 0,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ─── Listing Card ───────────────────────────────────────────────────────────

class _ListingCard extends ConsumerWidget {
  const _ListingCard({required this.listing});
  final MarketplaceListing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final thumb =
        listing.imageUrls.isNotEmpty ? listing.imageUrls.first : null;

    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => context.push(
          '${AppRoutes.marketplace}/listing/${listing.id}',
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: context.colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.colors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: thumb != null
                    ? CachedImage(
                        imageUrl: thumb,
                        fit: BoxFit.cover,
                      )
                    : Icon(Icons.pedal_bike_rounded,
                        color: context.colors.textSecondary),
              ),
              const SizedBox(width: 14),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(listing.title,
                        style: AppTextStyles.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${listing.price.toStringAsFixed(0)} DKK',
                      style: AppTextStyles.labelSmall.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Stat(
                          icon: Icons.visibility_outlined,
                          value: listing.viewCount,
                        ),
                        const SizedBox(width: 12),
                        _Stat(
                          icon: Icons.bookmark_outline_rounded,
                          value: listing.saveCount,
                        ),
                        const Spacer(),
                        _StatusBadge(listing: listing),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions menu
              PopupMenuButton<_Action>(
                icon: Icon(Icons.more_vert_rounded,
                    size: 20, color: context.colors.textSecondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                color: const Color(0xFFF8F9FA),
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.08),
                offset: const Offset(0, 8),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _Action.toggleSold,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          listing.isSold
                              ? Icons.undo_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 22,
                          color: const Color(0xFF4A5568),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          listing.isSold
                              ? l10n.listingMarkAvailable
                              : l10n.listingMarkSold,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF4A5568),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _Action.edit,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 22, color: Color(0xFF4A5568)),
                        const SizedBox(width: 14),
                        Text(
                          l10n.listingEditAction,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF4A5568),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem(
                    value: _Action.delete,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded,
                            size: 22, color: Color(0xFFE53E3E)),
                        const SizedBox(width: 14),
                        Text(
                          l10n.listingDeleteAction,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFE53E3E),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (action) =>
                    _onAction(context, ref, action),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAction(
      BuildContext context, WidgetRef ref, _Action action) async {
    final l10n = context.l10n;
    final svc = ref.read(marketplaceServiceProvider);

    switch (action) {
      case _Action.toggleSold:
        await svc.updateListing(
          listing.copyWith(isSold: !listing.isSold),
        );
      case _Action.edit:
        context.push(
          '${AppRoutes.marketplace}/edit/${listing.id}',
          extra: listing,
        );
      case _Action.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.listingDeleteAction),
            content: Text(l10n.deleteListingConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style:
                    FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                      elevation: 0),
                child: Text(l10n.listingDeleteAction),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await svc.deleteListing(listing.id, listing.imageUrls);
        }
    }
  }
}

enum _Action { toggleSold, edit, delete }

// ─── Small stat widget ──────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value});
  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.colors.textSecondary),
        const SizedBox(width: 3),
        Text('$value',
            style: AppTextStyles.labelSmall
                .copyWith(color: context.colors.textSecondary)),
      ],
    );
  }
}

// ─── Status Badge ───────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.listing});
  final MarketplaceListing listing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;
    final (label, opacity) = listing.isSold
        ? (l10n.listingStatusSold, 0.5)
        : (l10n.listingStatusActive, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: AppTextStyles.labelSmall.copyWith(color: baseColor.withValues(alpha: opacity))),
    );
  }
}
