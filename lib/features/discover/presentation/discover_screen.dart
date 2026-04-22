/// CYKEL — Discover Screen (Phase 3)
/// Search, categories, nearby POIs, saved routes, live hazards.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/providers/pending_route_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/crowd_hazard_service.dart';
import '../data/places_service.dart';
import '../data/saved_route_service.dart';
import '../domain/crowd_hazard.dart';
import '../domain/place.dart';
import '../domain/saved_route.dart';
import '../../provider/domain/provider_enums.dart';
import '../../provider/domain/provider_model.dart';
import '../../provider/providers/provider_providers.dart';
import 'location_detail_screen.dart';
import 'report_hazard_sheet.dart';

// ─── Design Colors ─────────────────────────────────────────────────────────────
const _kPrimaryColor = Color(0xFF4A7C59);
const _kBackground = Color(0xFFFFFFFF);

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();

  List<PlaceResult> _suggestions = [];
  bool _searching = false;
  bool _searchOpen = false;

  LatLng? _userLocation;
  List<PlaceResult>? _nearbyPlaces;
  bool _loadingNearby = true;
  String? _nearbyCategoryFilter;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _loadUserLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Location ───────────────────────────────────────────────────────────────

  Future<void> _loadUserLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _loadingNearby = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (mounted) {
        setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
        await _loadNearby();
      }
    } catch (_) {
      if (mounted) setState(() => _loadingNearby = false);
    }
  }

  Future<void> _loadNearby() async {
    if (_userLocation == null) return;
    // Prevent rapid-fire refreshes - set flag synchronously before async work
    if (_loadingNearby) return;
    _loadingNearby = true;
    setState(() {});
    
    try {
      final places = await ref
          .read(placesServiceProvider)
          .searchNearbyBikePoints(center: _userLocation!);
      if (mounted) {
        setState(() {
          _nearbyPlaces = places;
          _loadingNearby = false;
        });
      }
    } catch (e) {
      debugPrint('_loadNearby error: $e');
      // Keep existing places on error, just stop loading
      if (mounted) {
        setState(() {
          _loadingNearby = false;
          // Only clear if we had no previous data
          _nearbyPlaces ??= [];
        });
      }
    }
  }

  // ── Search ─────────────────────────────────────────────────────────────────

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() { _suggestions = []; _searchOpen = false; });
      return;
    }
    setState(() => _searchOpen = true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _searching = true);
      final results = await ref
          .read(placesServiceProvider)
          .autocomplete(q, center: _userLocation);
      if (mounted) {
        setState(() {
          _suggestions = results.take(6).toList();
          _searching = false;
        });
      }
    });
  }

  void _selectPlace(PlaceResult place) {
    _searchCtrl.clear();
    _focusNode.unfocus();
    setState(() { _suggestions = []; _searchOpen = false; });
    ref.read(pendingRouteProvider.notifier).state = place;
    context.go(AppRoutes.map);
  }

  void _goToMap() => context.go(AppRoutes.map);

  void _goToMapWithLayer(String layer) {
    ref.read(pendingLayerProvider.notifier).state = layer;
    context.go(AppRoutes.map);
  }

  void _goToProviderList(ProviderType type) {
    context.push(AppRoutes.providerList, extra: type);
  }

  // Convert a Overpass PlaceResult → Place domain model for the detail screen.
  Place _placeResultToPlace(PlaceResult r) {
    PlaceType type;
    if (r.placeId.startsWith('shop')) {
      type = PlaceType.shop;
    } else if (r.placeId.startsWith('charging')) {
      type = PlaceType.charging;
    } else if (r.placeId.startsWith('rental')) {
      type = PlaceType.rental;
    } else {
      type = PlaceType.service;
    }
    return Place(
      id: r.placeId,
      type: type,
      name: r.text,
      lat: r.lat,
      lng: r.lng,
      address: r.subtitle.isNotEmpty ? r.subtitle : null,
    );
  }

  /// Opens the full detail sheet for a nearby POI.
  /// If the user presses "Get directions", navigate to the map.
  Future<void> _openNearbyDetail(PlaceResult p) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationDetailScreen(place: _placeResultToPlace(p)),
      ),
    );
    if (result is Map && result['navigate'] != null) {
      _selectPlace(p);
    }
  }

  /// Opens the report-hazard sheet anchored to the user's current position.
  void _reportHazard() {
    final loc = _userLocation;
    if (loc == null) {
      _loadUserLocation();
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _kBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReportHazardSheet(position: loc),
    );
  }

  void _openSavedRoute(SavedRoute r) {
    ref.read(pendingRouteProvider.notifier).state = PlaceResult(
      placeId: 'saved_${r.id}',
      text: r.name,
      subtitle: r.destAddress,
      lat: r.destLat,
      lng: r.destLng,
    );
    context.go(AppRoutes.map);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final topPad = MediaQuery.of(context).padding.top;
    final savedRoutes = ref.watch(savedRoutesProvider);

    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
        if (_searchCtrl.text.isEmpty) setState(() => _searchOpen = false);
      },
      child: Scaffold(
        backgroundColor: _kBackground,
        body: Column(
          children: [
            // ── Header + Search bar ────────────────────────────────────────
            Container(
              color: context.colors.background,
              padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(l10n.tabDiscover,
                          style: AppTextStyles.headline2),
                    ),
                    TextButton.icon(
                      onPressed: _goToMap,
                      icon: Icon(Icons.map_rounded, size: 16, color: _kPrimaryColor),
                      label: Text(l10n.tabMap,
                          style: AppTextStyles.bodySmall
                              .copyWith(fontWeight: FontWeight.w600, color: _kPrimaryColor)),
                      style: TextButton.styleFrom(
                          foregroundColor: _kPrimaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  // Search bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Material(
                      color: context.colors.surfaceVariant,
                      child: TextField(
                        controller: _searchCtrl,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: l10n.searchPlaces,
                          hintStyle: AppTextStyles.bodyMedium
                              .copyWith(color: context.colors.textSecondary),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: context.colors.textSecondary),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  tooltip: 'Clear search',
                                  icon: Icon(Icons.clear_rounded,
                                      size: 18,
                                      color: context.colors.textSecondary),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() {
                                      _suggestions = [];
                                      _searchOpen = false;
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ),
                  // Autocomplete dropdown
                  if (_searchOpen) ...[
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: context.colors.background,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: _searching
                          ? Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                  child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))))
                          : _suggestions.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(l10n.noPlacesFound,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                          color: context.colors.textSecondary)))
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  itemCount: _suggestions.length,
                                  separatorBuilder: (context, index) =>
                                      Divider(height: 1, indent: 48),
                                  itemBuilder: (_, i) {
                                    final p = _suggestions[i];
                                    return ListTile(
                                      dense: true,
                                      leading: Icon(
                                          Icons.location_on_outlined,
                                          size: 18,
                                          color: context.colors.textSecondary),
                                      title: Text(p.text,
                                          style: AppTextStyles.bodyMedium,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      subtitle: p.subtitle.isNotEmpty
                                          ? Text(p.subtitle,
                                              style:
                                                  AppTextStyles.bodySmall
                                                      .copyWith(
                                                          color: AppColors
                                                              .textSecondary),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis)
                                          : null,
                                      trailing: Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 12,
                                          color: context.colors.textSecondary),
                                      onTap: () => _selectPlace(p),
                                    );
                                  }),
                    ),
                  ],
                ],
              ),
            ),

            // ── Scrollable content ─────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                children: [
                  // ── Categories ───────────────────────────────────────────
                  _SectionHeader(title: l10n.discoverCategories),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: _CategoryCard(
                          label: l10n.layerCharging,
                          image: 'assets/images/charging.webp',
                          onTap: () => _goToProviderList(ProviderType.chargingLocation)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CategoryCard(
                          label: l10n.layerRepair,
                          image: 'assets/images/mechanic-repairing-bicycle.webp',
                          onTap: () => _goToProviderList(ProviderType.repairShop)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CategoryCard(
                          label: l10n.layerShops,
                          image: 'assets/images/close-up-young-businessman-bike-shop.webp',
                          onTap: () => _goToProviderList(ProviderType.bikeShop)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: _CategoryCard(
                          label: l10n.layerService,
                          image: 'assets/images/medium-shot-people-travel-agency.webp',
                          onTap: () => _goToProviderList(ProviderType.servicePoint)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CategoryCard(
                          label: l10n.layerRental,
                          image: 'assets/images/paris-france-city-bicycles-bike-rental-bicycle-parking.webp',
                          onTap: () => _goToProviderList(ProviderType.rental)),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(child: SizedBox()),
                  ]),
                  const SizedBox(height: 28),

                  // ── CYKEL Verified Providers ─────────────────────────────
                  _SectionHeader(
                    title: l10n.cykelVerifiedProviders,
                    trailing: GestureDetector(
                      onTap: () => _goToMapWithLayer('cykel_repair'),
                      child: Text(l10n.viewAllProviders,
                          style: AppTextStyles.labelSmall
                              .copyWith(color: _kPrimaryColor)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Category shortcut cards for CYKEL layers
                  Row(children: [
                    Expanded(
                      child: _CategoryCard(
                          label: l10n.filterCykelRepair,
                          image: 'assets/images/mechanic-repairing-bicycle.webp',
                          onTap: () => _goToMapWithLayer('cykel_repair')),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CategoryCard(
                          label: l10n.filterCykelShop,
                          image: 'assets/images/close-up-young-businessman-bike-shop.webp',
                          onTap: () => _goToMapWithLayer('cykel_shop')),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CategoryCard(
                          label: l10n.filterCykelCharging,
                          image: 'assets/images/charging.webp',
                          onTap: () => _goToMapWithLayer('cykel_charging')),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: _CategoryCard(
                          label: l10n.filterCykelService,
                          image: 'assets/images/medium-shot-people-travel-agency.webp',
                          onTap: () => _goToMapWithLayer('cykel_service')),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CategoryCard(
                          label: l10n.filterCykelRental,
                          image: 'assets/images/paris-france-city-bicycles-bike-rental-bicycle-parking.webp',
                          onTap: () => _goToMapWithLayer('cykel_rental')),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(child: SizedBox()),
                  ]),
                  const SizedBox(height: 12),
                  _CykelNearbyProviders(
                    userLocation: _userLocation,
                    onTap: (provider) {
                      ref.read(pendingRouteProvider.notifier).state =
                          PlaceResult(
                        placeId: 'cykel_${provider.id}',
                        text: provider.businessName,
                        subtitle:
                            '${provider.streetAddress}, ${provider.city}',
                        lat: provider.latitude,
                        lng: provider.longitude,
                      );
                      context.go(AppRoutes.map);
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── CYKEL Features ───────────────────────────────────────
                  const _SectionHeader(title: 'CYKEL Features'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: _CategoryCard(
                        label: 'Bike Share',
                        image: 'assets/images/bikeshare.webp',
                        onTap: () => context.push(AppRoutes.bikeShare),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CategoryCard(
                        label: 'Buddy Match',
                        image: 'assets/images/buddymatch.webp',
                        onTap: () => context.push(AppRoutes.buddyMatching),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CategoryCard(
                        label: 'Events',
                        image: 'assets/images/eventhero.webp',
                        onTap: () => context.push(AppRoutes.events),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: _CategoryCard(
                        label: 'Challenges',
                        image: 'assets/images/challenges .webp',
                        onTap: () => context.push(AppRoutes.challenges),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CategoryCard(
                        label: 'Family',
                        image: 'assets/images/man-sitting-grass-his-mountain-bike.webp',
                        onTap: () => context.push(AppRoutes.familyGroups),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CategoryCard(
                        label: 'Social',
                        image: 'assets/images/bikes-rent-street (1).webp',
                        onTap: () => context.push(AppRoutes.social),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: _CategoryCard(
                        label: 'Messages',
                        image: 'assets/images/medium-shot-people-travel-agency.webp',
                        onTap: () => context.push(AppRoutes.messages),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CategoryCard(
                        label: 'Expat Hub',
                        image: 'assets/images/paris-france-city-bicycles-bike-rental-bicycle-parking.webp',
                        onTap: () => context.push(AppRoutes.expatHub),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CategoryCard(
                        label: 'Offline Maps',
                        image: 'assets/images/bike-repair-cable-maintenance-man-workshop-frame-building-professional-engineering-assessment-bicycle-transportation-with-mechanic-technician-startup-restoration.webp',
                        onTap: () => context.push(AppRoutes.offlineMaps),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // ── Nearby ───────────────────────────────────────────────
                  _SectionHeader(
                    title: l10n.sectionNearby,
                    trailing: _userLocation != null
                        ? GestureDetector(
                            onTap: _loadNearby,
                            child: Icon(Icons.refresh_rounded,
                                size: 18, color: _kPrimaryColor),
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                  // ── Category filter chips ────────────────────────────────
                  if (_nearbyPlaces != null && _nearbyPlaces!.isNotEmpty) ...
                    [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          _NearbyFilterChip(
                            label: l10n.filterAll,
                            active: _nearbyCategoryFilter == null,
                            onTap: () => setState(
                                () => _nearbyCategoryFilter = null),
                          ),
                          const SizedBox(width: 6),
                          _NearbyFilterChip(
                            label: l10n.filterCharging,
                            active: _nearbyCategoryFilter == 'charging',
                            onTap: () => setState(
                                () => _nearbyCategoryFilter = 'charging'),
                          ),
                          const SizedBox(width: 6),
                          _NearbyFilterChip(
                            label: l10n.filterService,
                            active: _nearbyCategoryFilter == 'service',
                            onTap: () => setState(
                                () => _nearbyCategoryFilter = 'service'),
                          ),
                          const SizedBox(width: 6),
                          _NearbyFilterChip(
                            label: l10n.filterShops,
                            active: _nearbyCategoryFilter == 'shop',
                            onTap: () => setState(
                                () => _nearbyCategoryFilter = 'shop'),
                          ),
                          const SizedBox(width: 6),
                          _NearbyFilterChip(
                            label: l10n.filterRental,
                            active: _nearbyCategoryFilter == 'rental',
                            onTap: () => setState(
                                () => _nearbyCategoryFilter = 'rental'),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 10),
                    ],
                  _NearbySection(
                    loading: _loadingNearby,
                    places: _nearbyCategoryFilter == null
                        ? _nearbyPlaces
                        : _nearbyPlaces
                            ?.where((p) => p.placeId
                                .startsWith(_nearbyCategoryFilter!))
                            .toList(),
                    userLocation: _userLocation,
                    onTap: _openNearbyDetail,
                    onRequestLocation: _loadUserLocation,
                  ),
                  const SizedBox(height: 24),

                  // ── Saved Routes ─────────────────────────────────────────
                  _SectionHeader(title: l10n.savedRoutes),
                  const SizedBox(height: 10),
                  if (savedRoutes.isEmpty)
                    _EmptyCard(
                        icon: Icons.bookmark_outline_rounded,
                        text: l10n.discoverNoSaved)
                  else
                    ...savedRoutes.take(5).map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _SavedRouteCard(
                            route: r,
                            onTap: () => _openSavedRoute(r),
                            onDelete: () => ref
                                .read(savedRoutesProvider.notifier)
                                .delete(r.id),
                          ),
                        )),
                  const SizedBox(height: 24),

                  // ── Active Hazards ───────────────────────────────────────
                  _SectionHeader(
                    title: l10n.discoverActiveHazards,
                    trailing: GestureDetector(
                      onTap: _reportHazard,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _kPrimaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.add_rounded,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(l10n.reportHazardTitle,
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: Colors.white)),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_userLocation == null)
                    _EmptyCard(
                        icon: Icons.warning_amber_rounded,
                        text: l10n.discoverNoHazards)
                  else
                    _HazardsSection(center: _userLocation!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Text(title,
                style: AppTextStyles.headline3.copyWith(fontSize: 15))),
        if (trailing != null) trailing!,
      ]);
}

// ─── Category Card ────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.label,
    required this.onTap,
    this.image,
  });
  final String label;
  final VoidCallback onTap;
  final String? image;

  @override
  Widget build(BuildContext context) {
    if (image != null) {
      return GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  image!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: _kPrimaryColor.withValues(alpha: 0.15),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                      stops: const [0.45, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 10,
                  right: 10,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE5E7E2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

// ─── Nearby Section ───────────────────────────────────────────────────────────

class _NearbySection extends StatelessWidget {
  const _NearbySection({
    required this.loading,
    required this.places,
    required this.userLocation,
    required this.onTap,
    required this.onRequestLocation,
  });
  final bool loading;
  final List<PlaceResult>? places;
  final LatLng? userLocation;
  final void Function(PlaceResult) onTap;
  final VoidCallback onRequestLocation;

  @override
  Widget build(BuildContext context) {
    if (userLocation == null) {
      return GestureDetector(
        onTap: onRequestLocation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: context.colors.background,
              borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Icon(Icons.location_off_rounded,
                color: context.colors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
                child: Text(context.l10n.noNearbySubtitle,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: context.colors.textSecondary))),
            Icon(Icons.chevron_right_rounded,
                color: context.colors.textSecondary, size: 18),
          ]),
        ),
      );
    }
    if (loading) {
      return SizedBox(
        height: 105,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          itemBuilder: (context, index) => Container(
            width: 105,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
                color: context.colors.background,
                borderRadius: BorderRadius.circular(12)),
            child: Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2))),
          ),
        ),
      );
    }
    if (places == null || places!.isEmpty) {
      return _EmptyCard(
          icon: Icons.explore_off_rounded,
          text: context.l10n.noPlacesFound);
    }
    return SizedBox(
      height: 105,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: places!.length,
        itemBuilder: (_, i) {
          final p = places![i];
          return GestureDetector(
            onTap: () => onTap(p),
            child: Container(
              width: 105,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kPrimaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.location_on_rounded, size: 14, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(p.text,
                          style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 10),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text(context.l10n.getDirections,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white.withValues(alpha: 0.8), fontSize: 9)),
                  ]),
            ),
          );
        },
      ),
    );
  }
}

// ─── Saved Route Card ─────────────────────────────────────────────────────────

class _SavedRouteCard extends StatelessWidget {
  const _SavedRouteCard(
      {required this.route,
      required this.onTap,
      required this.onDelete});
  final SavedRoute route;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Dismissible(
        key: Key('saved_${route.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.delete_rounded,
              color: AppColors.error, size: 20),
        ),
        onDismissed: (_) => onDelete(),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.surfaceVariant),
            ),
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _kPrimaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.bookmark_rounded,
                    color: _kPrimaryColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(route.name,
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600, color: context.colors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (route.destAddress.isNotEmpty)
                      Text(route.destAddress,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: context.colors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ])),
          if (route.distanceMeters > 0) ...[
                Text(route.distanceLabel,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: context.colors.textSecondary)),
                const SizedBox(width: 8),
              ],
              Icon(Icons.chevron_right_rounded,
                  color: context.colors.textSecondary, size: 18),
            ]),
          ),
        ),
      );
}

// ─── Hazards Section ──────────────────────────────────────────────────────────

class _HazardsSection extends ConsumerWidget {
  const _HazardsSection({required this.center});
  final LatLng center;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<CrowdHazardReport>>(
      stream: ref.read(crowdHazardServiceProvider).streamNearby(center),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))));
        }
        final hazards = snap.data ?? [];
        if (hazards.isEmpty) {
          return _EmptyCard(
              icon: Icons.check_circle_outline_rounded,
              text: context.l10n.discoverNoHazards,
              color: Colors.white);
        }
        return Column(
            children: hazards
                .take(5)
                .map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _HazardTile(hazard: h)))
                .toList());
      },
    );
  }
}

class _HazardTile extends StatelessWidget {
  const _HazardTile({required this.hazard});
  final CrowdHazardReport hazard;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (emoji, label) = _meta(hazard.type, l10n);
    final ago = DateTime.now().difference(hazard.reportedAt);
    final agoLabel =
        ago.inMinutes < 60 ? l10n.agoMinutes(ago.inMinutes) : l10n.agoHours(ago.inHours);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.surfaceVariant),
      ),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text(emoji, style: TextStyle(fontSize: 16))),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(label,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
              Text(agoLabel,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: context.colors.textSecondary)),
            ])),
      ]),
    );
  }

  static (String emoji, String label) _meta(
      CrowdHazardType t, AppLocalizations l10n) =>
      switch (t) {
        CrowdHazardType.roadDamage => ('🕳', l10n.hazardTypeRoadDamage),
        CrowdHazardType.accident => ('🚨', l10n.hazardTypeAccident),
        CrowdHazardType.debris => ('🪨', l10n.hazardTypeDebris),
        CrowdHazardType.roadClosed => ('🚧', l10n.hazardTypeRoadClosed),
        CrowdHazardType.badSurface => ('⚠️', l10n.hazardTypeBadSurface),
        CrowdHazardType.flooding => ('🌊', l10n.hazardTypeFlooding),
      };
}

// ─── Empty Card ───────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  const _EmptyCard(
      {required this.icon,
      required this.text,
      this.color = AppColors.textSecondary});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.surfaceVariant),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _kPrimaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _kPrimaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text,
                style: AppTextStyles.bodySmall
                    .copyWith(color: context.colors.textSecondary))),
      ]),
    );
  }
}

// ─── Nearby Filter Chip ───────────────────────────────────────────────────────

class _NearbyFilterChip extends StatelessWidget {
  const _NearbyFilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF6F8F72) : context.colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? const Color(0xFF6F8F72) : const Color(0xFFE5E7E2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: active ? 0.08 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : context.colors.textPrimary,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─── CYKEL Nearby Providers (Firestore) ───────────────────────────────────────

class _CykelNearbyProviders extends ConsumerWidget {
  const _CykelNearbyProviders({
    required this.userLocation,
    required this.onTap,
  });
  final LatLng? userLocation;
  final void Function(CykelProvider) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approved =
        ref.watch(allApprovedProvidersProvider).valueOrNull ?? [];
    // Filter to show only CYKEL-featured providers (repair shops and charging stations)
    final filtered = approved
        .where((p) =>
            p.isFeatured &&
            (p.providerType == ProviderType.repairShop ||
            p.providerType == ProviderType.chargingLocation))
        .toList();
    if (filtered.isEmpty) {
      return _EmptyCard(
        icon: Icons.verified_rounded,
        text: context.l10n.noProvidersNearby,
      );
    }
    // Sort by distance (nearest first) & limit to 6.
    final sorted = List<CykelProvider>.from(filtered);
    if (userLocation != null) {
      sorted.sort((a, b) {
        final da = _sqDist(a, userLocation!);
        final db = _sqDist(b, userLocation!);
        return da.compareTo(db);
      });
    }
    final display = sorted.take(6).toList();
    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: display.length,
        itemBuilder: (_, i) {
          final p = display[i];
          return GestureDetector(
            onTap: () => onTap(p),
            child: Container(
              width: 135,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kPrimaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Icon(_providerIcon(p.providerType),
                          size: 12, color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    if (p.isVerified)
                      Icon(Icons.verified_rounded,
                          size: 10, color: Colors.white),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    p.businessName,
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    p.city,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: Colors.white.withValues(alpha: 0.7), fontSize: 9),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: p.isOpen ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      p.isOpen
                          ? context.l10n.providerDetailOpen
                          : context.l10n.providerDetailClosed,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static double _sqDist(CykelProvider p, LatLng loc) {
    final dx = p.latitude - loc.latitude;
    final dy = p.longitude - loc.longitude;
    return dx * dx + dy * dy;
  }

  static IconData _providerIcon(ProviderType t) {
    switch (t) {
      case ProviderType.repairShop:
        return Icons.build_circle_rounded;
      case ProviderType.bikeShop:
        return Icons.store_rounded;
      case ProviderType.chargingLocation:
        return Icons.ev_station_rounded;
      case ProviderType.servicePoint:
        return Icons.handyman_rounded;
      case ProviderType.rental:
        return Icons.pedal_bike_rounded;
    }
  }
}