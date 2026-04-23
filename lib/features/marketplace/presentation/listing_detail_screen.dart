/// CYKEL — Listing Detail Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../core/widgets/app_image.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/chat_service.dart';
import '../data/marketplace_service.dart';
import '../domain/marketplace_listing.dart';
import '../providers/marketplace_providers.dart';
import 'listing_helpers.dart';

// ─── Design Colors ─────────────────────────────────────────────────────────────
const _kSecondaryText = Color(0xFF6B6B6B);

class ListingDetailScreen extends ConsumerStatefulWidget {
  const ListingDetailScreen({
    super.key,
    required this.listingId,
    this.listing,
  });

  final String listingId;
  final MarketplaceListing? listing; // pre-loaded via GoRouter extra

  @override
  ConsumerState<ListingDetailScreen> createState() =>
      _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  int _imageIndex = 0;
  bool _contactLoading = false;

  @override
  void initState() {
    super.initState();
    // Increment view count asynchronously
    Future.microtask(() => ref
        .read(marketplaceServiceProvider)
        .incrementView(widget.listingId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final savedIds =
        ref.watch(savedListingIdsProvider).valueOrNull ?? [];

    // Use pre-loaded listing or fetch by ID
    final asyncListing =
        widget.listing != null ? null : ref.watch(listingByIdProvider(widget.listingId));
    final listing = widget.listing ?? asyncListing?.valueOrNull;

    if (listing == null) {
      if (asyncListing?.isLoading ?? false) {
        return const Scaffold(
            body: Center(child: CircularProgressIndicator()));
      }
      return Scaffold(
        appBar: AppBar(),
        body:
            const Center(child: Icon(Icons.error_outline_rounded, size: 48)),
      );
    }

    final isOwner = user?.uid == listing.sellerId;
    final isSaved = savedIds.contains(listing.id);

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: CustomScrollView(
        slivers: [
          // ── Image app bar ─────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: context.colors.surface,
            leading: IconButton(
              tooltip: l10n.goBack,
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (!isOwner && user != null)
                IconButton(
                  tooltip: isSaved ? l10n.removeFromSaved : l10n.saveListing,
                  icon: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle),
                    child: Icon(
                        isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        color: Colors.white,
                        size: 20),
                  ),
                  onPressed: () {
                    try {
                      if (isSaved) {
                        ref
                            .read(marketplaceServiceProvider)
                            .unsaveListing(user.uid, listing.id);
                      } else {
                        ref
                            .read(marketplaceServiceProvider)
                            .saveListing(user.uid, listing.id);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.genericError(e.toString()))));
                      }
                    }
                  },
                ),
              PopupMenuButton<String>(
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.more_vert_rounded,
                      color: Colors.white, size: 20),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                color: const Color(0xFFF8F9FA),
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.08),
                offset: const Offset(0, 8),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (_) => [
                  if (isOwner) ...[
                    PopupMenuItem(
                      value: 'edit',
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            size: 22,
                            color: Color(0xFF4A5568),
                          ),
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
                    if (!listing.isSold)
                      PopupMenuItem(
                        value: 'sold',
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 22,
                              color: Color(0xFF4A5568),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              l10n.listingMarkSold,
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
                      value: 'delete',
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            size: 22,
                            color: Color(0xFFE53E3E),
                          ),
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
                  ] else
                    PopupMenuItem(
                      value: 'report',
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.flag_outlined,
                            size: 22,
                            color: Color(0xFF4A5568),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            l10n.listingReport,
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
                ],
                onSelected: (v) async {
                  final svc = ref.read(marketplaceServiceProvider);
                  if (v == 'edit') {
                    if (context.mounted) {
                      context.push(
                          '${AppRoutes.marketplace}/edit/${listing.id}',
                          extra: listing);
                    }
                  } else if (v == 'sold') {
                    try {
                      await svc.markSold(listing.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(l10n.listingMarkedSold)));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.genericError(e.toString()))));
                      }
                    }
                  } else if (v == 'delete') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(l10n.listingDeleteAction),
                        content: Text(l10n.deleteListingConfirm),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(false),
                            child: Text(l10n.no),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(true),
                            child: Text(l10n.yes,
                                style: TextStyle(
                                    color: context.colors.textPrimary)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    try {
                      await svc.deleteListing(
                          listing.id, listing.imageUrls);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(l10n.listingDeleted)));
                        context.pop();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.genericError(e.toString()))));
                      }
                    }
                  } else if (v == 'report') {
                    _showReportDialog(context, listing.id);
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: listing.imageUrls.isEmpty
                  ? _CategoryHero(listing.category)
                  : Stack(children: [
                      PageView.builder(
                        itemCount: listing.imageUrls.length,
                        onPageChanged: (i) =>
                            setState(() => _imageIndex = i),
                        itemBuilder: (_, i) => CachedImage(
                            imageUrl: listing.imageUrls[i],
                            fit: BoxFit.cover),
                      ),
                      if (listing.imageUrls.length > 1)
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              listing.imageUrls.length,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 3),
                                width: _imageIndex == i ? 16 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                    color: _imageIndex == i
                                        ? Colors.white
                                        : Colors.white
                                            .withValues(alpha: 0.5),
                                    borderRadius:
                                        BorderRadius.circular(3)),
                              ),
                            ),
                          ),
                        ),
                    ]),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Title + price
                Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Expanded(
                    child: Text(listing.title,
                        style: AppTextStyles.headline3
                            .copyWith(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Text(listing.priceLabel,
                      style: AppTextStyles.headline3.copyWith(
                          color: context.colors.textPrimary, fontSize: 20)),
                ]),
                const SizedBox(height: 10),

                // Badges row
                Wrap(spacing: 8, runSpacing: 6, children: [
                  _Chip(
                      icon: Icons.circle,
                      label: conditionLabel(l10n, listing.condition),
                      color: conditionColor(listing.condition)),
                  _Chip(
                      icon: listing.isShop
                          ? Icons.storefront_rounded
                          : Icons.person_rounded,
                      label: listing.isShop
                          ? l10n.listingShopSeller
                          : l10n.listingPrivateSeller,
                      color: context.colors.textPrimary.withValues(alpha: 0.6)),
                  if (listing.brand != null && listing.brand!.isNotEmpty)
                    _Chip(
                        icon: Icons.sell_outlined,
                        label: listing.brand!,
                        color: _kSecondaryText),
                  if (listing.isElectric)
                    _Chip(
                        icon: Icons.electric_bike_rounded,
                        label: l10n.listingElectricBadge,
                        color: context.colors.textPrimary.withValues(alpha: 0.7)),
                  if (listing.serialVerified)
                    _Chip(
                        icon: Icons.verified_rounded,
                        label: l10n.listingSerialVerified,
                        color: context.colors.textPrimary.withValues(alpha: 0.9))
                  else if (listing.serialDuplicate)
                    _Chip(
                        icon: Icons.warning_rounded,
                        label: l10n.listingSerialDuplicate,
                        color: context.colors.textPrimary.withValues(alpha: 0.5))
                  else if (listing.serialNumber != null)
                    _Chip(
                        icon: Icons.qr_code_rounded,
                        label: l10n.listingSerialUnverified,
                        color: _kSecondaryText),
                  if (listing.city.isNotEmpty)
                    _Chip(
                        icon: Icons.location_on_rounded,
                        label: listing.city,
                        color: AppColors.textSecondary),
                  _Chip(
                      icon: Icons.access_time_rounded,
                      label: _timeAgo(listing.createdAt, l10n),
                      color: AppColors.textSecondary),
                  _Chip(
                      icon: Icons.visibility_rounded,
                      label: l10n.listingViews(listing.viewCount),
                      color: AppColors.textSecondary),
                ]),
                const SizedBox(height: 20),

                // Description
                if (listing.description.isNotEmpty) ...[
                  Text(l10n.descriptionHeader,
                      style: AppTextStyles.headline3
                          .copyWith(fontSize: 15)),
                  const SizedBox(height: 8),
                  Text(listing.description,
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: _kSecondaryText, height: 1.5)),
                  const SizedBox(height: 20),
                ],

                // Seller card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: context.colors.border, width: 1),
                  ),
                  child: Row(children: [
                    AppAvatar(
                      url: listing.sellerPhotoUrl,
                      thumbnailUrl: listing.sellerPhotoThumbnail,
                      size: 44,
                      fallbackText: listing.sellerName.isNotEmpty
                          ? listing.sellerName[0].toUpperCase()
                          : '?',
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                          Text(listing.sellerName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600)),
                          Text(
                              listing.isShop
                                  ? l10n.listingShopSeller
                                  : l10n.listingPrivateSeller,
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: _kSecondaryText)),
                          if (listing.phone != null) ...
                            [
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => launchUrl(
                                    Uri.parse('tel:${listing.phone}')),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.phone_rounded,
                                          size: 13,
                                          color: context.colors.textPrimary),
                                      const SizedBox(width: 4),
                                      Text(listing.phone!,
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                  color: context.colors.textPrimary,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                    ]),
                              ),
                            ],
                        ])),
                    if (isOwner)
                      Icon(Icons.verified_rounded,
                          color: context.colors.textPrimary, size: 18),
                  ]),
                ),
              ]),
            ),
          ),
        ],
      ),

      // ── Bottom action bar ─────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(
              top: BorderSide(
                  color: context.colors.border, width: 1)),
        ),
        child: isOwner
            ? _OwnerStatsBar(listing: listing)
            : listing.isSold
                ? Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14)),
                    child: Center(
                        child: Text(l10n.listingSoldBadge,
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: context.colors.textPrimary,
                                fontWeight: FontWeight.w700))))
                : listing.phone != null
                    ? Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: user == null
                                ? null
                                : () => launchUrl(
                                    Uri.parse('tel:${listing.phone}')),
                            icon: const Icon(Icons.phone_rounded, size: 16),
                            label: Text(l10n.listingCallSeller),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: context.colors.textPrimary,
                                side: BorderSide(
                                    color: context.colors.textPrimary),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                textStyle: AppTextStyles.labelLarge),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: user == null || _contactLoading
                                ? null
                                : () => _contactSeller(listing, user.uid,
                                    user.displayName),
                            icon: _contactLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 16),
                            label: Text(l10n.listingContactSeller),
                            style: FilledButton.styleFrom(
                                backgroundColor: context.colors.textPrimary,
                                foregroundColor: context.colors.surface,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                elevation: 0,
                                textStyle: AppTextStyles.labelLarge),
                          ),
                        ),
                      ])
                    : SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: user == null || _contactLoading
                              ? null
                              : () => _contactSeller(listing, user.uid,
                                  user.displayName),
                          icon: _contactLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 16),
                          label: Text(l10n.listingContactSeller),
                          style: FilledButton.styleFrom(
                              backgroundColor: context.colors.textPrimary,
                              foregroundColor: context.colors.surface,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              textStyle: AppTextStyles.labelLarge),
                        ),
                      ),
      ),
    );
  }

  Future<void> _contactSeller(
      MarketplaceListing listing, String buyerId, String buyerName) async {
    setState(() => _contactLoading = true);
    try {
      final thread = await ref.read(chatServiceProvider).getOrCreateThread(
            listingId: listing.id,
            listingTitle: listing.title,
            listingImageUrl:
                listing.imageUrls.isNotEmpty ? listing.imageUrls.first : null,
            buyerId: buyerId,
            buyerName: buyerName,
            sellerId: listing.sellerId,
            sellerName: listing.sellerName,
          );
      if (mounted) {
        context.push('${AppRoutes.marketplace}/chat/${thread.id}',
            extra: thread);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.couldNotStartChat(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _contactLoading = false);
    }
  }

  void _showReportDialog(BuildContext context, String listingId) {
    final l10n = context.l10n;
    String? reason;
    final reportOptions = [
      ('scam', l10n.reportScam),
      ('stolen', l10n.reportStolen),
      ('inappropriate', l10n.reportInappropriate),
      ('other', l10n.reportOther),
    ];
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.listingReport),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.reportListingReason),
              const SizedBox(height: 12),
              RadioGroup<String>(
                groupValue: reason,
                onChanged: (v) => setDialogState(() => reason = v),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: reportOptions
                      .map((r) => RadioListTile<String>(
                            title: Text(r.$2),
                            value: r.$1,
                            dense: true,
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: reason == null
                  ? null
                  : () async {
                      Navigator.of(ctx).pop();
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await ref.read(marketplaceServiceProvider).reportListing(
                          listingId: listingId,
                          reporterId: ref.read(currentUserProvider)?.uid ?? '',
                          reason: reason!,
                        );
                        messenger.showSnackBar(
                          SnackBar(
                              content: Text(l10n.reportSubmitted)),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(l10n.failedToReport(e.toString()))),
                        );
                      }
                    },
              child: Text(l10n.submitButton,
                  style: const TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Owner Stats Bar ──────────────────────────────────────────────────────────

class _OwnerStatsBar extends ConsumerWidget {
  const _OwnerStatsBar({required this.listing});
  final MarketplaceListing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final inquiries =
        ref.watch(listingInquiriesCountProvider(listing.id)).valueOrNull ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _StatPill(
              icon: Icons.visibility_rounded,
              value: '${listing.viewCount}',
              label: l10n.viewsStat,
              color: _kSecondaryText,
            ),
            const SizedBox(width: 10),
            _StatPill(
              icon: Icons.bookmark_rounded,
              value: '${listing.saveCount}',
              label: l10n.savesStat,
              color: context.colors.textPrimary,
            ),
            const SizedBox(width: 10),
            _StatPill(
              icon: Icons.chat_bubble_rounded,
              value: '$inquiries',
              label: l10n.chatsStat,
              color: context.colors.textPrimary,
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: context.colors.textPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                listing.isSold ? l10n.listingSoldBadge : l10n.activeStatus,
                style: AppTextStyles.labelSmall.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        if (!listing.isSold) ...[
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () async {
              await ref
                  .read(marketplaceServiceProvider)
                  .markSold(listing.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.listingMarkedSold)));
              }
            },
            icon: const Icon(Icons.check_circle_rounded, size: 16),
            label: Text(l10n.listingMarkSold),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 3),
            Text(value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                )),
          ]),
          Text(label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              )),
        ],
      );
}

// ─── Category Hero ────────────────────────────────────────────────────────────

class _CategoryHero extends StatelessWidget {
  const _CategoryHero(this.category);
  final ListingCategory category;

  @override
  Widget build(BuildContext context) {
    final emoji = switch (category) {
      ListingCategory.bike => '🚲',
      ListingCategory.parts => '🔩',
      ListingCategory.accessories => '🎒',
      ListingCategory.clothing => '🪖',
      ListingCategory.tools => '🔧',
    };
    return Container(
      color: context.colors.textPrimary.withValues(alpha: 0.10),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 64))),
    );
  }
}

// ─── Chip ─────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.labelSmall
                  .copyWith(color: color, fontSize: 11)),
        ]),
      );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _timeAgo(DateTime dt, AppLocalizations l10n) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return l10n.agoMinutes(diff.inMinutes);
  if (diff.inHours < 24) return l10n.agoHours(diff.inHours);
  if (diff.inDays < 7) return l10n.agoDays(diff.inDays);
  return DateFormat('d MMM').format(dt);
}
