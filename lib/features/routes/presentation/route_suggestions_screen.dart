/// CYKEL — Route Suggestions Screen
/// AI-powered route recommendations

import 'package:flutter/material.dart' hide TimeOfDay, RouteSettings;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/providers/pending_route_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/location_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../../bike_share/domain/bike_share_station.dart';
import '../../discover/data/places_service.dart';
import '../data/route_suggestion_provider.dart';
import '../domain/route_suggestion.dart';

class RouteSuggestionsScreen extends ConsumerStatefulWidget {
  const RouteSuggestionsScreen({super.key});

  @override
  ConsumerState<RouteSuggestionsScreen> createState() => _RouteSuggestionsScreenState();
}

class _RouteSuggestionsScreenState extends ConsumerState<RouteSuggestionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LatLng? _currentLocation;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    try {
      final location = await ref.read(locationServiceProvider).getCurrentLocation();
      setState(() {
        _currentLocation = LatLng(location.latitude, location.longitude);
        _loadingLocation = false;
      });
    } catch (e) {
      setState(() {
        // Default to Copenhagen
        _currentLocation = const LatLng(55.6761, 12.5683);
        _loadingLocation = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.routeSuggestions),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettings(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
          tabs: [
            Tab(text: l10n.routeSuggestionsTab),
            Tab(text: l10n.routeHistoryTab),
            Tab(text: l10n.routeSavedTab),
          ],
        ),
      ),
      body: _loadingLocation
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _SuggestionsTab(currentLocation: _currentLocation!),
                const _HistoryTab(),
                const _SavedRoutesTab(),
              ],
            ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _RouteSettingsSheet(),
    );
  }
}

// ─── Suggestions Tab ──────────────────────────────────────────────────────────

class _SuggestionsTab extends ConsumerWidget {
  const _SuggestionsTab({required this.currentLocation});

  final LatLng currentLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final suggestionsAsync = ref.watch(routeSuggestionsProvider(currentLocation));

    return suggestionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.errorPrefix(e.toString()))),
      data: (suggestions) {
        if (suggestions.isEmpty) {
          return _EmptyState(
            icon: '🧭',
            title: l10n.routeNoSuggestions,
            subtitle: l10n.routeNoSuggestionsDesc,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(routeSuggestionsProvider(currentLocation));
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: suggestions.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _HeaderCard();
              }
              return _SuggestionCard(suggestion: suggestions[index - 1]);
            },
          ),
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Text('🤖', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.routeAiTitle,
                  style: AppTextStyles.headline3.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.routeAiDesc,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatefulWidget {
  const _SuggestionCard({required this.suggestion});

  final RouteSuggestion suggestion;

  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> {
  bool _showBikeShareDetails = false;

  RouteSuggestion get suggestion => widget.suggestion;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Consumer(
        builder: (context, ref, child) => InkWell(
        onTap: () {
          ref.read(pendingRouteProvider.notifier).state = PlaceResult(
            placeId: 'suggestion_${suggestion.id}',
            text: suggestion.name,
            subtitle: suggestion.endAddress ?? '',
            lat: suggestion.endLocation.latitude,
            lng: suggestion.endLocation.longitude,
          );
          context.go(AppRoutes.map);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _scoreColor(context, widget.suggestion.score).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: _scoreColor(context, widget.suggestion.score),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.suggestion.score.toInt()}%',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: _scoreColor(context, widget.suggestion.score),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.suggestion.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Phase 4: Family-friendly badge
                  if (suggestion.isFamilyFriendly)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.family_restroom,
                            size: 12,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Family Safe',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Phase 5: Tourist-friendly badge
                  if (suggestion.isTouristFriendly)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 12,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tourist Friendly',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Phase 5: Tourist indicators (scenic, cultural, POIs, waterfront)
              if (suggestion.scenicScore != null ||
                  suggestion.culturalScore != null ||
                  suggestion.pointsOfInterest.isNotEmpty ||
                  suggestion.waterfrontPercentage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (suggestion.scenicScore != null)
                        _SafetyChip(
                          icon: Icons.landscape_outlined,
                          label: 'Scenic: ${suggestion.scenicScore}/5',
                          color: Colors.green,
                        ),
                      if (suggestion.culturalScore != null)
                        _SafetyChip(
                          icon: Icons.museum_outlined,
                          label: 'Cultural: ${suggestion.culturalScore}/5',
                          color: Colors.purple,
                        ),
                      if (suggestion.pointsOfInterest.isNotEmpty)
                        _SafetyChip(
                          icon: Icons.location_on,
                          label: '${suggestion.pointsOfInterest.length} POIs',
                          color: Colors.orange,
                        ),
                      if (suggestion.waterfrontPercentage != null)
                        _SafetyChip(
                          icon: Icons.water_outlined,
                          label: '${suggestion.waterfrontPercentage!.toInt()}% waterfront',
                          color: Colors.cyan,
                        ),
                    ],
                  ),
                ),

              // Phase 4: Safety indicators (if available)
              if (suggestion.trafficFreePercentage != null ||
                  suggestion.safetyScore != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (suggestion.trafficFreePercentage != null)
                        _SafetyChip(
                          icon: Icons.park_outlined,
                          label: '${suggestion.trafficFreePercentage!.toInt()}% traffic-free',
                          color: Colors.blue,
                        ),
                      if (suggestion.safetyScore != null)
                        _SafetyChip(
                          icon: Icons.shield_outlined,
                          label: 'Safety: ${suggestion.safetyScore}/5',
                          color: _getSafetyColor(suggestion.safetyScore!),
                        ),
                    ],
                  ),
                ),

              // Phase 6: Bike share stations (if available)
              if (suggestion.hasBikeShareStations)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _SafetyChip(
                        icon: Icons.pedal_bike,
                        label: '${suggestion.availableBikeShareCount} stations available',
                        color: Colors.indigo,
                      ),
                      if (suggestion.hasBikeShareAtStart)
                        const _SafetyChip(
                          icon: Icons.location_on,
                          label: 'Station at start',
                          color: Colors.green,
                        ),
                      if (suggestion.hasBikeShareAtEnd)
                        const _SafetyChip(
                          icon: Icons.flag_outlined,
                          label: 'Station at end',
                          color: Colors.green,
                        ),
                      // View details button
                      InkWell(
                        onTap: () {
                          setState(() {
                            _showBikeShareDetails = !_showBikeShareDetails;
                          });
                        },
                        child: _SafetyChip(
                          icon: _showBikeShareDetails 
                              ? Icons.expand_less 
                              : Icons.expand_more,
                          label: _showBikeShareDetails ? 'Hide details' : 'View details',
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                ),

              // Phase 6: Bike share station details (expandable)
              if (suggestion.hasBikeShareStations && _showBikeShareDetails)
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nearby Bike Share Stations',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...suggestion.nearbyStations.take(5).map((station) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Color(int.parse(
                                        station.availabilityColor.substring(1), 
                                        radix: 16
                                      ) + 0xFF000000),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      station.name,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    station.provider.displayName,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (station.availableBikes != null && station.availableBikes! > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Text(
                                        '🚲 ${station.availableBikes}',
                                        style: AppTextStyles.caption,
                                      ),
                                    ),
                                  if (station.availableEBikes != null && station.availableEBikes! > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Text(
                                        '⚡ ${station.availableEBikes}',
                                        style: AppTextStyles.caption,
                                      ),
                                    ),
                                  if (station.availableScooters != null && station.availableScooters! > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Text(
                                        '🛴 ${station.availableScooters}',
                                        style: AppTextStyles.caption,
                                      ),
                                    ),
                                  const Spacer(),
                                  if (station.distance != null)
                                    Text(
                                      '${(station.distance! * 1000).toInt()}m',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                      if (suggestion.nearbyStations.length > 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '+${suggestion.nearbyStations.length - 5} more stations',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              // Stats
              Row(
                children: [
                  _StatChip(
                    icon: Icons.route,
                    value: '${suggestion.estimatedDistanceKm.toStringAsFixed(1)} km',
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    icon: Icons.schedule,
                    value: '${suggestion.estimatedDurationMinutes} min',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Reasons
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: suggestion.reasons.map((reason) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${reason.icon} ${reason.displayName}',
                      style: AppTextStyles.caption.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Color _scoreColor(BuildContext context, double score) {
    final baseColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;
    if (score >= 80) return baseColor.withValues(alpha: 1.0);
    if (score >= 60) return baseColor.withValues(alpha: 0.8);
    if (score >= 40) return baseColor.withValues(alpha: 0.6);
    return AppColors.textSecondary;
  }

  // Phase 4: Safety score color
  Color _getSafetyColor(int score) {
    if (score >= 4) return Colors.green;
    if (score >= 3) return Colors.orange;
    return Colors.red;
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// Phase 4: Safety indicator chip
class _SafetyChip extends StatelessWidget {
  const _SafetyChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── History Tab ──────────────────────────────────────────────────────────────

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final historyAsync = ref.watch(routeHistoryProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.errorPrefix(e.toString()))),
      data: (history) {
        if (history.isEmpty) {
          return _EmptyState(
            icon: '📍',
            title: l10n.routeNoHistory,
            subtitle: l10n.routeNoHistoryDesc,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: history.length,
          itemBuilder: (context, index) => _HistoryCard(history: history[index]),
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.history});

  final RouteHistory history;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${history.usageCount}x',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          _getRouteName(l10n),
          style: AppTextStyles.bodyMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              l10n.routeStatsPattern(history.averageDurationMinutes, _timeAgo(l10n, history.lastUsedAt)),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (history.timeOfDayCounts.isNotEmpty) ...[
              const SizedBox(height: 4),
              _TimeOfDayChips(counts: history.timeOfDayCounts),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ),
    );
  }

  String _getRouteName(AppLocalizations l10n) {
    if (history.startAddress != null && history.endAddress != null) {
      final start = _shortenAddress(history.startAddress!);
      final end = _shortenAddress(history.endAddress!);
      return '$start → $end';
    }
    return l10n.routeDefaultName;
  }

  String _shortenAddress(String address) {
    final parts = address.split(',');
    if (parts.isEmpty) return address;
    return parts.first.trim();
  }

  String _timeAgo(AppLocalizations l10n, DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return l10n.routeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.routeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.routeDaysAgo(diff.inDays);
    return '${date.day}/${date.month}';
  }
}

class _TimeOfDayChips extends StatelessWidget {
  const _TimeOfDayChips({required this.counts});

  final Map<TimeOfDay, int> counts;

  @override
  Widget build(BuildContext context) {
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final top = sorted.take(2);

    return Wrap(
      spacing: 4,
      children: top.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            '${entry.key.displayName} (${entry.value})',
            style: AppTextStyles.caption.copyWith(fontSize: 10),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Saved Routes Tab ─────────────────────────────────────────────────────────

class _SavedRoutesTab extends ConsumerWidget {
  const _SavedRoutesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final savedAsync = ref.watch(savedRoutesProvider);

    return savedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.errorPrefix(e.toString()))),
      data: (routes) {
        if (routes.isEmpty) {
          return _EmptyState(
            icon: '💾',
            title: l10n.routeNoSaved,
            subtitle: l10n.routeNoSavedDesc,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: routes.length,
          itemBuilder: (context, index) => _SavedRouteCard(
            route: routes[index],
            onDelete: () => _deleteRoute(ref, routes[index]),
          ),
        );
      },
    );
  }

  Future<void> _deleteRoute(WidgetRef ref, SavedRoute route) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref.read(routeAIServiceProvider).deleteSavedRoute(user.uid, route.id);
  }
}

class _SavedRouteCard extends StatelessWidget {
  const _SavedRouteCard({required this.route, required this.onDelete});

  final SavedRoute route;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(route.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.1),
        child: Icon(Icons.delete, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(Icons.bookmark, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
            ),
          ),
          title: Text(
            route.name,
            style: AppTextStyles.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              if (route.distanceKm != null || route.estimatedDurationMinutes != null)
                Text(
                  [
                    if (route.distanceKm != null) '${route.distanceKm!.toStringAsFixed(1)} km',
                    if (route.estimatedDurationMinutes != null) '~${route.estimatedDurationMinutes} min',
                  ].join(' • '),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              if (route.tags.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: route.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: AppTextStyles.caption.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

// ─── Settings Sheet ───────────────────────────────────────────────────────────

class _RouteSettingsSheet extends ConsumerWidget {
  const _RouteSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settingsAsync = ref.watch(routeSettingsProvider);
    final settings = settingsAsync.valueOrNull ?? const RouteSettings();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(l10n.routeSettings, style: AppTextStyles.headline3),
              const SizedBox(height: 24),

              Text(
                l10n.routePreferences,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: RoutePreference.values.map((pref) {
                  final isSelected = settings.preferences.contains(pref);
                  return FilterChip(
                    label: Text('${pref.icon} ${pref.displayName}'),
                    selected: isSelected,
                    onSelected: (selected) {
                      final newPrefs = List<RoutePreference>.from(settings.preferences);
                      if (selected) {
                        newPrefs.add(pref);
                      } else {
                        newPrefs.remove(pref);
                      }
                      _updateSettings(ref, settings.copyWith(preferences: newPrefs));
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              SwitchListTile(
                title: Text(l10n.routeAvoidHills),
                subtitle: Text(l10n.routeAvoidHillsDesc),
                value: settings.avoidHills,
                onChanged: (value) => _updateSettings(ref, settings.copyWith(avoidHills: value)),
              ),

              SwitchListTile(
                title: Text(l10n.routePreferBikeLanes),
                subtitle: Text(l10n.routePreferBikeLanesDesc),
                value: settings.preferBikeLanes,
                onChanged: (value) => _updateSettings(ref, settings.copyWith(preferBikeLanes: value)),
              ),

              SwitchListTile(
                title: Text(l10n.routePreferLitRoutes),
                subtitle: Text(l10n.routePreferLitRoutesDesc),
                value: settings.preferLitRoutes,
                onChanged: (value) => _updateSettings(ref, settings.copyWith(preferLitRoutes: value)),
              ),

              const Divider(height: 32),

              Text(
                l10n.routeAiSuggestions,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),

              SwitchListTile(
                title: Text(l10n.routeBasedOnHistory),
                subtitle: Text(l10n.routeBasedOnHistoryDesc),
                value: settings.usageBasedSuggestions,
                onChanged: (value) => _updateSettings(ref, settings.copyWith(usageBasedSuggestions: value)),
              ),

              SwitchListTile(
                title: Text(l10n.routeBasedOnWeather),
                subtitle: Text(l10n.routeBasedOnWeatherDesc),
                value: settings.weatherBasedSuggestions,
                onChanged: (value) => _updateSettings(ref, settings.copyWith(weatherBasedSuggestions: value)),
              ),

              SwitchListTile(
                title: Text(l10n.routeBasedOnTime),
                subtitle: Text(l10n.routeBasedOnTimeDesc),
                value: settings.timeBasedSuggestions,
                onChanged: (value) => _updateSettings(ref, settings.copyWith(timeBasedSuggestions: value)),
              ),

              const Divider(height: 32),

              // Phase 6: Bike share settings
              Text(
                'Bike Share Options',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),

              SwitchListTile(
                title: const Text('🚲 Bike Share Mode'),
                subtitle: const Text('Prioritize routes with bike share stations'),
                value: settings.bikeShareMode,
                onChanged: (value) => _updateSettings(ref, settings.copyWith(bikeShareMode: value)),
              ),

              if (settings.bikeShareMode) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Station at Start'),
                        subtitle: const Text('Only show routes with station near start'),
                        value: settings.requireStationAtStart,
                        onChanged: (value) => _updateSettings(ref, settings.copyWith(requireStationAtStart: value)),
                      ),
                      SwitchListTile(
                        title: const Text('Station at End'),
                        subtitle: const Text('Only show routes with station near end'),
                        value: settings.requireStationAtEnd,
                        onChanged: (value) => _updateSettings(ref, settings.copyWith(requireStationAtEnd: value)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preferred Providers',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: BikeShareProvider.values.map((provider) {
                          final isSelected = settings.preferredProviders.contains(provider);
                          return FilterChip(
                            label: Text('${provider.icon} ${provider.displayName}'),
                            selected: isSelected,
                            onSelected: (selected) {
                              final newProviders = List<BikeShareProvider>.from(settings.preferredProviders);
                              if (selected) {
                                newProviders.add(provider);
                              } else {
                                newProviders.remove(provider);
                              }
                              _updateSettings(ref, settings.copyWith(preferredProviders: newProviders));
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateSettings(WidgetRef ref, RouteSettings settings) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref.read(routeAIServiceProvider).updateRouteSettings(user.uid, settings);
    ref.invalidate(routeSettingsProvider);
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final String icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.headline3),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
