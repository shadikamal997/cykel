/// CYKEL — Marketplace Riverpod providers

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../../services/subscription_providers.dart';
import '../data/chat_service.dart';
import '../data/marketplace_service.dart';
import '../domain/chat_message.dart';
import '../domain/marketplace_listing.dart';

// ─── Filter state ─────────────────────────────────────────────────────────────

class ListingsFilter {
  const ListingsFilter({
    this.category,
    this.sortBy = 'createdAt',
    this.searchQuery = '',
  });

  final ListingCategory? category;
  final String sortBy; // 'createdAt' | 'price_asc' | 'price_desc'
  final String searchQuery;

  ListingsFilter copyWith({
    ListingCategory? category,
    bool clearCategory = false,
    String? sortBy,
    String? searchQuery,
  }) =>
      ListingsFilter(
        category:
            clearCategory ? null : (category ?? this.category),
        sortBy: sortBy ?? this.sortBy,
        searchQuery: searchQuery ?? this.searchQuery,
      );
}

final listingsFilterProvider =
    StateProvider<ListingsFilter>((ref) => const ListingsFilter());

// ─── Listings stream ──────────────────────────────────────────────────────────

final listingsProvider =
    StreamProvider<List<MarketplaceListing>>((ref) {
  final filter = ref.watch(listingsFilterProvider);
  final service = ref.watch(marketplaceServiceProvider);
  final isPremium = ref.watch(isPremiumProvider);

  return service
      .streamListings(
        category: filter.category,
        sortBy: filter.sortBy,
        prioritizePremium: isPremium,
      )
      .map((list) {
    if (filter.searchQuery.isEmpty) return list;
    final q = filter.searchQuery.toLowerCase();
    return list
        .where((l) =>
            l.title.toLowerCase().contains(q) ||
            l.description.toLowerCase().contains(q) ||
            l.city.toLowerCase().contains(q))
        .toList();
  });
});

// ─── My listings ──────────────────────────────────────────────────────────────

final myListingsProvider =
    StreamProvider<List<MarketplaceListing>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(marketplaceServiceProvider).streamMyListings(user.uid);
});

// ─── Saved listing IDs ────────────────────────────────────────────────────────

final savedListingIdsProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(marketplaceServiceProvider).streamSavedIds(user.uid);
});

// ─── Saved listings (full objects) ───────────────────────────────────────────

final savedListingsProvider =
    StreamProvider<List<MarketplaceListing>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(marketplaceServiceProvider).streamSavedListings(user.uid);
});

// ─── Chat threads ─────────────────────────────────────────────────────────────

final chatThreadsProvider = StreamProvider<List<ChatThread>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(chatServiceProvider).streamThreads(user.uid);
});

// ─── Chat messages ────────────────────────────────────────────────────────────

final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, threadId) {
  return ref.watch(chatServiceProvider).streamMessages(threadId);
});

// ─── Inquiries (chat thread) count for a listing ─────────────────────────────

final listingInquiriesCountProvider =
    StreamProvider.family<int, String>((ref, listingId) {
  return ref.watch(chatServiceProvider).streamInquiriesCount(listingId);
});

// ─── Single listing by ID ─────────────────────────────────────────────────────

final listingByIdProvider =
    FutureProvider.family<MarketplaceListing?, String>((ref, id) {
  return ref.watch(marketplaceServiceProvider).getById(id);
});
