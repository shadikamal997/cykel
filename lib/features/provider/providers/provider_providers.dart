/// CYKEL — Provider System Riverpod Providers
/// Exposes reactive data for the provider feature:
/// current user's provider, nearby providers, type filters, analytics.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/location_service.dart';
import '../data/provider_service.dart';
import '../domain/provider_analytics.dart';
import '../domain/provider_enums.dart';
import '../domain/provider_location.dart';
import '../domain/provider_model.dart';

// ─── Current User's Provider ──────────────────────────────────────────────────

/// Streams the list of providers owned by the currently signed-in user.
/// Most users will have 0 or 1 providers.
final myProvidersProvider = StreamProvider<List<CykelProvider>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(providerServiceProvider).streamMyProviders(user.uid);
});

/// Convenience — the first provider owned by this user, or null.
final myProviderProvider = Provider<CykelProvider?>((ref) {
  final list = ref.watch(myProvidersProvider).valueOrNull ?? [];
  return list.isNotEmpty ? list.first : null;
});

/// Whether the current user has registered as a provider.
final isProviderOwnerProvider = Provider<bool>((ref) {
  return ref.watch(myProviderProvider) != null;
});

// ─── Single Provider by ID ────────────────────────────────────────────────────

/// Family provider to stream a single provider by its document ID.
final providerByIdProvider =
    StreamProvider.family<CykelProvider?, String>((ref, id) {
  return ref.watch(providerServiceProvider).streamProvider(id);
});

// ─── Providers by Type ────────────────────────────────────────────────────────

/// Streams approved + active providers of a specific type.
final providersByTypeProvider =
    StreamProvider.family<List<CykelProvider>, ProviderType>((ref, type) {
  return ref.watch(providerServiceProvider).streamProvidersByType(type);
});

/// All approved & active providers (all types).
final allApprovedProvidersProvider = StreamProvider<List<CykelProvider>>((ref) {
  return ref.watch(providerServiceProvider).streamAllApproved();
});

// ─── Analytics ────────────────────────────────────────────────────────────────

/// Stream analytics for the current user's provider.
final myProviderAnalyticsProvider = StreamProvider<ProviderAnalytics>((ref) {
  final provider = ref.watch(myProviderProvider);
  if (provider == null) {
    return Stream.value(const ProviderAnalytics(providerId: '', userId: ''));
  }
  return ref.watch(providerServiceProvider).streamAnalytics(provider.id);
});

/// Analytics for any provider by ID (used on detail screens).
final providerAnalyticsByIdProvider =
    StreamProvider.family<ProviderAnalytics, String>((ref, id) {
  return ref.watch(providerServiceProvider).streamAnalytics(id);
});

// ─── Saved Providers ──────────────────────────────────────────────────────────

/// Stream of provider IDs saved by the current user.
final savedProviderIdsProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(providerServiceProvider).streamSavedProviderIds(user.uid);
});

// ─── Locations ────────────────────────────────────────────────────────────────

/// Stream locations owned by the current user's provider.
final myLocationsProvider = StreamProvider<List<ProviderLocation>>((ref) {
  final provider = ref.watch(myProviderProvider);
  if (provider == null) return Stream.value([]);
  return ref.watch(locationServiceProvider).streamProviderLocations(provider.id);
});

/// Stream all active locations (public map).
final allActiveLocationsProvider = StreamProvider<List<ProviderLocation>>((ref) {
  return ref.watch(locationServiceProvider).streamAllActive();
});

/// Stream active locations filtered by type.
final locationsByTypeProvider =
    StreamProvider.family<List<ProviderLocation>, ProviderType>((ref, type) {
  return ref.watch(locationServiceProvider).streamByType(type);
});

/// Single location by ID.
final locationByIdProvider =
    StreamProvider.family<ProviderLocation?, String>((ref, id) {
  return ref.watch(locationServiceProvider).streamLocation(id);
});
