/// CYKEL — Expat Hub Providers
/// Riverpod providers for expat resources and content

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../domain/expat_resource.dart';
import 'expat_hub_service.dart';

// ─── Service Provider ──────────────────────────────────────────────────────

final expatHubServiceProvider = Provider<ExpatHubService>((ref) {
  return ExpatHubService();
});

// ─── Guide Providers ───────────────────────────────────────────────────────

/// Get all expat guides
final expatGuidesProvider = StreamProvider.autoDispose<List<ExpatGuide>>((ref) {
  final service = ref.watch(expatHubServiceProvider);
  return service.getGuides();
});

/// Get a specific guide by ID
final expatGuideProvider = 
    FutureProvider.autoDispose.family<ExpatGuide?, String>((ref, guideId) async {
  final service = ref.watch(expatHubServiceProvider);
  return await service.getGuide(guideId);
});

/// Alias for guide detail screen (uses expatGuideProvider)
final guideByIdProvider = expatGuideProvider;

/// Get the featured "Getting Started" guide (first pinned guide in gettingStarted category)
final featuredGettingStartedGuideProvider = StreamProvider.autoDispose<ExpatGuide?>((ref) {
  final service = ref.watch(expatHubServiceProvider);
  return service.getFeaturedGettingStartedGuide();
});

/// Get guides by category
final guidesByCategoryProvider =
    StreamProvider.autoDispose.family<List<ExpatGuide>, ResourceCategory>(
  (ref, category) {
    final service = ref.watch(expatHubServiceProvider);
    return service.getGuidesByCategory(category);
  },
);

/// Get featured/pinned guides
final featuredGuidesProvider = StreamProvider.autoDispose<List<ExpatGuide>>((ref) {
  final service = ref.watch(expatHubServiceProvider);
  return service.getFeaturedGuides();
});

/// Search guides
final guideSearchQueryProvider = StateProvider<String>((ref) => '');

final searchedGuidesProvider = StreamProvider.autoDispose<List<ExpatGuide>>((ref) {
  final service = ref.watch(expatHubServiceProvider);
  final query = ref.watch(guideSearchQueryProvider);
  
  if (query.isEmpty) {
    return service.getGuides();
  }
  
  return service.searchGuides(query);
});

// ─── Quick Tips Providers ──────────────────────────────────────────────────

/// Get all quick tips
final quickTipsProvider = StreamProvider.autoDispose<List<QuickTip>>((ref) {
  final service = ref.watch(expatHubServiceProvider);
  return service.getQuickTips();
});

/// Get tips by category
final tipsByCategoryProvider =
    StreamProvider.autoDispose.family<List<QuickTip>, ResourceCategory>(
  (ref, category) {
    final service = ref.watch(expatHubServiceProvider);
    return service.getQuickTips(category: category);
  },
);

/// Get top priority tips
final topTipsProvider = StreamProvider.autoDispose<List<QuickTip>>((ref) {
  final service = ref.watch(expatHubServiceProvider);
  return service.getTopTips(limit: 10);
});

// ─── Bike Shop Providers ───────────────────────────────────────────────────

/// Get all bike shops
final bikeShopsProvider = StreamProvider.autoDispose<List<BikeShop>>((ref) {
  final service = ref.watch(expatHubServiceProvider);
  return service.getBikeShops();
});

/// Get shops by service type
final shopsByServiceProvider =
    StreamProvider.autoDispose.family<List<BikeShop>, ShopService>(
  (ref, service) {
    final expatService = ref.watch(expatHubServiceProvider);
    return expatService.getShopsByService(service);
  },
);

/// Get expat-friendly shops
final expatFriendlyShopsProvider = StreamProvider.autoDispose<List<BikeShop>>((ref) {
  final service = ref.watch(expatHubServiceProvider);
  return service.getExpatFriendlyShops();
});

/// Get nearby shops
class NearbyShopParams {
  const NearbyShopParams({
    required this.location,
    required this.radiusKm,
  });

  final LatLng location;
  final double radiusKm;
}

final nearbyShopsProvider =
    StreamProvider.autoDispose.family<List<BikeShop>, NearbyShopParams>(
  (ref, params) {
    final service = ref.watch(expatHubServiceProvider);
    return service.getNearbyShops(params.location, params.radiusKm);
  },
);

// ─── Emergency Contact Providers ───────────────────────────────────────────

/// Get all emergency contacts
final emergencyContactsProvider = 
    StreamProvider.autoDispose<List<EmergencyContact>>((ref) {
  final service = ref.watch(expatHubServiceProvider);
  return service.getEmergencyContacts();
});

/// Get contacts by type
final contactsByTypeProvider =
    StreamProvider.autoDispose.family<List<EmergencyContact>, EmergencyType>(
  (ref, type) {
    final service = ref.watch(expatHubServiceProvider);
    return service.getEmergencyContacts(type: type);
  },
);

/// Get 24/7 available contacts
final available247ContactsProvider = 
    StreamProvider.autoDispose<List<EmergencyContact>>((ref) {
  final service = ref.watch(expatHubServiceProvider);
  return service.get247Contacts();
});

// ─── Cycling Rules Providers ───────────────────────────────────────────────

/// Get all cycling rules
final cyclingRulesProvider = StreamProvider.autoDispose<List<CyclingRule>>((ref) {
  final service = ref.watch(expatHubServiceProvider);
  return service.getCyclingRules();
});

/// Get critical rules
final criticalRulesProvider = StreamProvider.autoDispose<List<CyclingRule>>((ref) {
  final service = ref.watch(expatHubServiceProvider);
  return service.getCriticalRules();
});

/// Get rules with fines
final rulesWithFinesProvider = StreamProvider.autoDispose<List<CyclingRule>>((ref) {
  final service = ref.watch(expatHubServiceProvider);
  return service.getRulesWithFines();
});

/// Group rules by severity
final rulesBySeverityProvider = Provider.autoDispose<AsyncValue<Map<RuleSeverity, List<CyclingRule>>>>((ref) {
  return ref.watch(cyclingRulesProvider).whenData((rules) {
    final grouped = <RuleSeverity, List<CyclingRule>>{};
    
    for (final severity in RuleSeverity.values) {
      grouped[severity] = rules.where((r) => r.severity == severity).toList();
    }
    
    return grouped;
  });
});

// ─── Route Providers ───────────────────────────────────────────────────────

/// Get all expat routes
final expatRoutesProvider = StreamProvider.autoDispose<List<ExpatRoute>>((ref) {
  final service = ref.watch(expatHubServiceProvider);
  return service.getExpatRoutes();
});

/// Get a specific route
final expatRouteProvider =
    FutureProvider.autoDispose.family<ExpatRoute?, String>((ref, routeId) async {
  final service = ref.watch(expatHubServiceProvider);
  return await service.getRoute(routeId);
});

/// Get scenic routes
final scenicRoutesProvider = StreamProvider.autoDispose<List<ExpatRoute>>((ref) {
  final service = ref.watch(expatHubServiceProvider);
  return service.getScenicRoutes();
});

/// Get tourist-friendly routes
final touristRoutesProvider = StreamProvider.autoDispose<List<ExpatRoute>>((ref) {
  final service = ref.watch(expatHubServiceProvider);
  return service.getTouristRoutes();
});

/// Get commute routes
final commuteRoutesProvider = StreamProvider.autoDispose<List<ExpatRoute>>((ref) {
  final service = ref.watch(expatHubServiceProvider);
  return service.getCommuteRoutes();
});

/// Get routes by difficulty
final routesByDifficultyProvider =
    StreamProvider.autoDispose.family<List<ExpatRoute>, DifficultyLevel>(
  (ref, difficulty) {
    final service = ref.watch(expatHubServiceProvider);
    return service.getRoutesByDifficulty(difficulty);
  },
);

/// Group routes by difficulty
final routesByDifficultyGroupProvider = 
    Provider.autoDispose<AsyncValue<Map<DifficultyLevel, List<ExpatRoute>>>>((ref) {
  return ref.watch(expatRoutesProvider).whenData((routes) {
    final grouped = <DifficultyLevel, List<ExpatRoute>>{};
    
    for (final difficulty in DifficultyLevel.values) {
      grouped[difficulty] = routes.where((r) => r.difficulty == difficulty).toList();
    }
    
    return grouped;
  });
});

// ─── Statistics Providers ──────────────────────────────────────────────────

/// Get hub statistics
class HubStatistics {
  const HubStatistics({
    required this.totalGuides,
    required this.totalTips,
    required this.totalShops,
    required this.totalRoutes,
    required this.totalRules,
  });

  final int totalGuides;
  final int totalTips;
  final int totalShops;
  final int totalRoutes;
  final int totalRules;
}

final hubStatisticsProvider = FutureProvider.autoDispose<HubStatistics>((ref) async {
  final guides = await ref.watch(expatGuidesProvider.future);
  final tips = await ref.read(quickTipsProvider.future);
  final shops = await ref.read(bikeShopsProvider.future);
  final routes = await ref.read(expatRoutesProvider.future);
  final rules = await ref.read(cyclingRulesProvider.future);
  
  return HubStatistics(
    totalGuides: guides.length,
    totalTips: tips.length,
    totalShops: shops.length,
    totalRoutes: routes.length,
    totalRules: rules.length,
  );
});

// ─── Category Statistics ───────────────────────────────────────────────────

class CategoryStats {
  const CategoryStats({
    required this.category,
    required this.guideCount,
    required this.tipCount,
  });

  final ResourceCategory category;
  final int guideCount;
  final int tipCount;
}

final categoryStatsProvider = 
    FutureProvider.autoDispose<List<CategoryStats>>((ref) async {
  final guides = await ref.watch(expatGuidesProvider.future);
  final tips = await ref.read(quickTipsProvider.future);
  
  return ResourceCategory.values.map((category) {
    return CategoryStats(
      category: category,
      guideCount: guides.where((g) => g.category == category).length,
      tipCount: tips.where((t) => t.category == category).length,
    );
  }).toList();
});
