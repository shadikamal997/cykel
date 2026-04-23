/// CYKEL — Home Dashboard
/// Phase 2: Rider home screen with condition card, activity strip, quick routes.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/widgets/cached_image.dart';

import '../../auth/providers/auth_providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../activity/data/ride_recording_provider.dart';
import '../../activity/data/activity_stats_provider.dart';
import '../data/quick_routes_provider.dart';
import '../data/weather_provider.dart';
import '../data/weather_alerts_provider.dart';
import '../../../core/providers/pending_route_provider.dart';
import '../../discover/data/places_service.dart';
import '../../../services/location_service.dart';
import '../../../services/frequent_destinations_service.dart';
import '../../../services/commute_suggestion_service.dart';
import '../../../core/providers/bike_profile_provider.dart';
import '../../profile/data/user_profile_provider.dart';
import '../data/estimated_range_provider.dart';
import '../data/monthly_challenge_provider.dart';
import '../../../services/dashboard_settings_provider.dart';
import '../domain/ride_condition.dart';
import '../../../services/daylight_service.dart';
import '../../../services/commuter_tax_service.dart';
import 'commuter_tax_detail_screen.dart';
import '../../events/data/events_provider.dart';
import '../../events/domain/event.dart';
import '../../../services/subscription_providers.dart';

// ─── Design Colors (kept for compatibility with white-on-color elements) ─────
const _kPrimaryColor = AppColors.primary;
const _kPrimaryPressed = AppColors.primaryDark;
const _kPrimaryText = AppColors.textPrimary;
const _kSecondaryText = AppColors.textSecondary;
const _kBackground = AppColors.background;
const _kCardBackground = AppColors.surface;
const _kSoftElements = AppColors.surfaceVariant;
// NOTE: For dark mode support, widgets should use context.colors.textPrimary instead of _kPrimaryText

// ─── Nearby POI provider ──────────────────────────────────────────────────────
final _homeNearbyProvider = FutureProvider<List<PlaceResult>>((ref) async {
  LatLng loc;
  try {
    loc = await ref.read(locationServiceProvider).getLastKnownOrCurrent();
  } catch (_) {
    loc = const LatLng(55.6761, 12.5683); // Copenhagen fallback
  }
  return ref.read(placesServiceProvider).searchNearbyBikePoints(center: loc);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final l10n = context.l10n;
    final rawName = user?.displayName.split(' ').first ?? '';
    final firstName = rawName.isEmpty ? l10n.defaultRiderName : rawName;
    final dashboardSettings = ref.watch(dashboardSettingsProvider).valueOrNull ?? const DashboardSettings();
    final isPremium = ref.watch(isPremiumProvider);
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: RefreshIndicator(
        color: _kPrimaryColor,
        onRefresh: () async {
          ref.invalidate(rideHistoryProvider);
          ref.invalidate(homeWeatherProvider);
          await Future.delayed(const Duration(milliseconds: 400));
        },
        child: CustomScrollView(
          slivers: [
            // ── Premium App Bar (White Scandinavian) ──────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: context.colors.border.withValues(alpha: 0.06),
                      width: 1,
                    ),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 16),
                child: Row(
                  children: [
                    // Profile avatar (moved to left)
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.profile),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_kPrimaryColor, _kPrimaryPressed],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: _kPrimaryColor.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            (user?.displayName.isNotEmpty == true)
                                ? user!.displayName[0].toUpperCase()
                                : '?',
                            style: AppTextStyles.headline3.copyWith(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name and greeting
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_greeting(context)}, $firstName!',
                            style: AppTextStyles.headline3.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              height: 1.2,
                              color: context.colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _todayDate(context),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: context.colors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Language toggle
                    InkWell(
                      onTap: () => _showLanguageSelector(context, ref),
                      borderRadius: BorderRadius.circular(22),
                      child: _LanguageToggle(),
                    ),
                    const SizedBox(width: 6),
                    // App notifications bell
                    InkWell(
                      onTap: () => context.push(AppRoutes.notifications),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _kCardBackground,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.notifications_none_rounded,
                            size: 22,
                            color: _kPrimaryText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Weather alerts bell with badge
                    const _WeatherAlertsBell(),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Ride Condition Card (PERFORMANCE: RepaintBoundary) ─────────────────────────────────
                  _SectionLabel(l10n.sectionRidingConditions),
                  const SizedBox(height: 10),
                  const RepaintBoundary(
                    child: _RideConditionCard(),
                  ),
                  const SizedBox(height: 24),

                  // ── Upcoming Events (PERFORMANCE: RepaintBoundary) ────────────────────────────────────
                  const RepaintBoundary(
                    child: _UpcomingEventsCard(),
                  ),
                  const SizedBox(height: 12),

                  // ── Commute Suggestion ───────────────────────────
                  const _CommuteSuggestionCard(),                  const SizedBox(height: 24),

                  // ── Today's Activity ────────────────────────────────────
                  if (dashboardSettings.showRecentActivity) ...[
                    _SectionLabel(l10n.sectionTodayActivity),
                    const SizedBox(height: 10),
                    const _TodayActivityStrip(),
                    const SizedBox(height: 12),
                    const RepaintBoundary(
                      child: _ActivityStatsCard(),
                    ),
                    const SizedBox(height: 12),
                    if (dashboardSettings.showMonthlyChallenge) ...[
                      const _MonthlyChallengeCard(),
                      const SizedBox(height: 12),
                    ],
                    if (isPremium && dashboardSettings.showEbikeRange) ...[
                      const _EbikeRangeCard(),
                      const SizedBox(height: 12),
                    ],
                    const _CommuterTaxCard(),
                    const SizedBox(height: 24),
                  ],

                  // ── Quick Routes ────────────────────────────────────────
                  if (dashboardSettings.showQuickRoutes) ...[
                    _SectionLabel(l10n.sectionQuickRoutes),
                    const SizedBox(height: 10),
                    const _QuickRoutesCard(),
                    const SizedBox(height: 24),
                  ],
                  // ── Frequent Destinations ─────────────────────────
                  if (dashboardSettings.showRecentActivity) ...[
                    _SectionLabel(l10n.sectionFrequentRoutes),
                    const SizedBox(height: 10),
                    const _FrequentDestinationsCard(),
                    const SizedBox(height: 24),
                  ],

                  // ── Maintenance Reminder ───────────────────────────
                  if (isPremium && dashboardSettings.showMaintenanceReminder) ...[
                    const _MaintenanceAlertsCard(),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 120), // Extra padding for navbar clearance
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _greeting(BuildContext context) {
    final hour = DateTime.now().hour;
    final l10n = context.l10n;
    // Morning: Midnight (12 AM) through 11:59 AM (hours 0-11)
    if (hour < 12) return l10n.goodMorning;
    // Afternoon: Noon through 5:59 PM (hours 12-17)
    if (hour < 18) return l10n.goodAfternoon;
    // Evening: 6 PM through 11:59 PM (hours 18-23)
    return l10n.goodEvening;
  }

  static String _todayDate(BuildContext context) {
    final now = DateTime.now();
    final l10n = context.l10n;
    final weekdays = [l10n.dayMon, l10n.dayTue, l10n.dayWed, l10n.dayThu, l10n.dayFri, l10n.daySat, l10n.daySun];
    final months = [
      l10n.monthJan, l10n.monthFeb, l10n.monthMar, l10n.monthApr, l10n.monthMay, l10n.monthJun,
      l10n.monthJul, l10n.monthAug, l10n.monthSep, l10n.monthOct, l10n.monthNov, l10n.monthDec
    ];
    final wd = weekdays[now.weekday - 1];
    final mo = months[now.month - 1];
    return '$wd, $mo ${now.day}';
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: _kPrimaryText,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: -0.3,
        ),
      );
}

// ─── Ride Condition Card ──────────────────────────────────────────────────────

class _RideConditionCard extends ConsumerWidget {
  const _RideConditionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final weatherAsync = ref.watch(homeWeatherProvider);

    return weatherAsync.when(
      loading: () => Container(
        height: 120,
        decoration: BoxDecoration(
          color: _kBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Container(
        height: 120,
        decoration: BoxDecoration(
          color: _kBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(l10n.errGeneric,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: _kSecondaryText)),
        ),
      ),
      data: (weather) {
        final daylightAsync = ref.watch(daylightInfoProvider);
        final isDark = daylightAsync.maybeWhen(
          data: (daylight) => daylight.isDark,
          orElse: () => false,
        );
        final condition = RideCondition.fromWeather(
          weather,
          isDark: isDark,
        );
        final score = condition.score;

        final conditionLabel = switch (condition.tier) {
          ConditionTier.excellent => l10n.conditionExcellent,
          ConditionTier.good      => l10n.conditionGood,
          ConditionTier.fair      => l10n.conditionFair,
          ConditionTier.poor      => l10n.conditionPoor,
        };

        final windKmh = (weather.windSpeedMs * 3.6).round();
        final windDir = _compassDir(weather.windDirectionDeg);
        final windText = '$windKmh km/h $windDir';
        final rainText = weather.precipitationMm > 0
            ? '${weather.precipitationMm.toStringAsFixed(1)} mm'
            : '0 mm';
        final hasBattery = ref.watch(userProfileProvider).hasBatteryLevel;
        final batteryLevel = ref.watch(userProfileProvider).batteryLevel ?? 0;
        final batteryRange = ref.watch(allBikesRangeProvider);
        final batteryLabel = batteryRange != null
            ? '$batteryLevel% · ${batteryRange.label}'
            : '$batteryLevel%';

        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.successLight, // Soft green light
                AppColors.successLight, // Soft green medium
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // ── Top row: score | label | temperature ─────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Score circle (white, premium style)
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _kPrimaryColor.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$score',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _kPrimaryColor,
                            height: 1.0,
                          ),
                        ),
                        const Text(
                          '/10',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _kSecondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Condition label
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conditionLabel,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: _kPrimaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.ridingConditions,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _kSecondaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Temperature (white pill)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.border,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${weather.temperatureC.round()}°',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: _kPrimaryText,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.feelsLike(weather.feelsLikeC.round().toString()),
                          style: const TextStyle(
                            fontSize: 10,
                            color: _kSecondaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                height: 1,
                color: context.colors.border.withValues(alpha: 0.08),
              ),
              const SizedBox(height: 12),
              // ── Metric row ────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _MetricRow(
                      icon: Icons.air_rounded,
                      label: l10n.wind,
                      value: windText,
                    ),
                  ),
                  Expanded(
                    child: _MetricRow(
                      icon: Icons.water_drop_outlined,
                      label: l10n.rain,
                      value: rainText,
                    ),
                  ),
                  if (hasBattery)
                    Expanded(
                      child: _MetricRow(
                        icon: Icons.battery_charging_full_rounded,
                        label: l10n.battery,
                        value: batteryLabel,
                      ),
                    ),
                ],
              ),
              // ── Warning pills ─────────────────────────────────────────────
              if (condition.warnings.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (condition.warnings.contains(ConditionWarning.cachedData))
                      _WarningPill(label: l10n.warningCachedData),
                    if (condition.warnings.contains(ConditionWarning.iceRisk))
                      _WarningPill(label: l10n.warningIceRisk),
                    if (condition.warnings.contains(ConditionWarning.strongWind))
                      _WarningPill(label: l10n.warningStrongWind),
                    if (condition.warnings.contains(ConditionWarning.cold))
                      _WarningPill(label: l10n.warningCold),
                    if (condition.warnings.contains(ConditionWarning.fog))
                      _WarningPill(label: l10n.hazardFog),
                    if (condition.warnings.contains(ConditionWarning.darkRiding))
                      _WarningPill(label: l10n.darkRidingAlert),
                    if (condition.warnings.contains(ConditionWarning.lowVisibility))
                      _WarningPill(label: l10n.lowVisibility),
                    if (condition.warnings.contains(ConditionWarning.rain))
                      _WarningPill(label: l10n.rain),
                    if (condition.warnings.contains(ConditionWarning.heavyRain))
                      _WarningPill(label: l10n.hazardHeavyRain),
                    if (condition.warnings.contains(ConditionWarning.snow))
                      _WarningPill(label: l10n.hazardSnow),
                    if (condition.warnings.contains(ConditionWarning.thunderstorm))
                      _WarningPill(label: l10n.hazardThunderstorm),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static String _compassDir(int deg) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return dirs[((deg + 22) ~/ 45) % 8];
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: _kSecondaryText),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _kSecondaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kPrimaryText,
          ),
        ),
      ],
    );
  }
}

class _WarningPill extends StatelessWidget {
  const _WarningPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.warning.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

// ─── Today's Activity Strip ───────────────────────────────────────────────────

class _TodayActivityStrip extends ConsumerWidget {
  const _TodayActivityStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ridesAsync = ref.watch(rideHistoryProvider);

    return ridesAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, _) => _EmptyStateCard(
        icon: Icons.directions_bike_rounded,
        title: context.l10n.noRidesToday,
        subtitle: context.l10n.noRidesTodaySubtitle,
      ),
      data: (rides) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final todayRides = rides.where((r) =>
            r.startTime.year == now.year &&
            r.startTime.month == now.month &&
            r.startTime.day == now.day).toList();

        final totalDistM =
            todayRides.fold<double>(0, (s, r) => s + r.distanceMeters);
        final totalMins =
            todayRides.fold<int>(0, (s, r) => s + r.duration.inMinutes);

        // Count consecutive riding days ending today (streak).
        int streak = 0;
        var checkDay = today;
        while (true) {
          final hasRide = rides.any((r) =>
              r.startTime.year == checkDay.year &&
              r.startTime.month == checkDay.month &&
              r.startTime.day == checkDay.day);
          if (!hasRide) break;
          streak++;
          checkDay = checkDay.subtract(const Duration(days: 1));
        }

        // Show empty state if no activity today
        if (totalDistM == 0 && totalMins == 0 && streak == 0) {
          return _EmptyStateCard(
            icon: Icons.directions_bike_rounded,
            title: context.l10n.noRidesToday,
            subtitle: context.l10n.noRidesTodaySubtitle,
          );
        }

        final distText = totalDistM < 1000
            ? '${totalDistM.round()} m'
            : l10n.kmToday((totalDistM / 1000).toStringAsFixed(1));
        final durText = l10n.minToday('$totalMins');

        return _buildRow(l10n, distText, durText, '$streak');
      },
    );
  }

  Widget _buildRow(AppLocalizations l10n, String dist, String dur, String streak) {
    return Row(
      children: [
        Expanded(
          child: _ActivityTile(
            icon: Icons.route_rounded,
            value: dist,
            label: l10n.distanceLabel,
            color: _kPrimaryColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActivityTile(
            icon: Icons.timer_outlined,
            value: dur,
            label: l10n.durationLabel,
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActivityTile(
            icon: Icons.local_fire_department_outlined,
            value: streak,
            label: l10n.streakLabel,
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: _kCardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kPrimaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _kSecondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Quick Routes Card ────────────────────────────────────────────────────────

// ─── Quick Routes Card ────────────────────────────────────────────────────────

class _QuickRoutesCard extends ConsumerWidget {
  const _QuickRoutesCard();

  void _showAddressSearch(
    BuildContext context,
    WidgetRef ref,
    String title,
    void Function(QuickRoute) onSave,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddressSearchSheet(title: title, onSave: onSave),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final routes = ref.watch(quickRoutesProvider);
    final home = routes.home;
    final work = routes.work;
    final custom = routes.custom;
    final neitherSet = home == null && work == null && custom.isEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // ── Home route button ─────────────────────────────────────────
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (home != null) {
                      // Navigate to map with pre-filled destination.
                      ref.read(pendingRouteProvider.notifier).state =
                          home.toPlaceResult();
                      context.go(AppRoutes.map);
                    } else {
                      _showAddressSearch(
                        context,
                        ref,
                        l10n.setHomeAddress,
                        (r) => ref
                            .read(quickRoutesProvider.notifier)
                            .setHome(r),
                      );
                    }
                  },
                  onLongPress: home != null
                      ? () => ref
                          .read(quickRoutesProvider.notifier)
                          .clearHome()
                      : null,
                  child: _RouteButton(
                    icon: Icons.home_rounded,
                    label: l10n.routeHome,
                    sublabel: home?.text,
                    isSet: home != null,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // ── Work route button ─────────────────────────────────────────
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (work != null) {
                      ref.read(pendingRouteProvider.notifier).state =
                          work.toPlaceResult();
                      context.go(AppRoutes.map);
                    } else {
                      _showAddressSearch(
                        context,
                        ref,
                        l10n.setWorkAddress,
                        (r) => ref
                            .read(quickRoutesProvider.notifier)
                            .setWork(r),
                      );
                    }
                  },
                  onLongPress: work != null
                      ? () => ref
                          .read(quickRoutesProvider.notifier)
                          .clearWork()
                      : null,
                  child: _RouteButton(
                    icon: Icons.work_rounded,
                    label: l10n.routeWork,
                    sublabel: work?.text,
                    isSet: work != null,
                  ),
                ),
              ),
            ],
          ),
          if (neitherSet) ...[
            const SizedBox(height: 16),
            _EmptyStateCard(
              icon: Icons.near_me_rounded,
              title: context.l10n.noQuickRoutesYet,
              subtitle: context.l10n.noQuickRoutesSubtitle,
            ),
          ] else if (home != null && work != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                // ── Home to Work shortcut ───────────────────────────────────
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Start navigation from home to work
                      ref.read(pendingRouteProvider.notifier).state = work.toPlaceResult();
                      // Set origin to home location
                      // This will need to be handled in the map screen
                      context.go(AppRoutes.map);
                    },
                    child: _ShortcutButton(
                      icon: Icons.arrow_forward_rounded,
                      label: l10n.shortcutHomeToWork,
                      color: _kPrimaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // ── Work to Home shortcut ───────────────────────────────────
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Start navigation from work to home
                      ref.read(pendingRouteProvider.notifier).state = home.toPlaceResult();
                      context.go(AppRoutes.map);
                    },
                    child: _ShortcutButton(
                      icon: Icons.arrow_back_rounded,
                      label: l10n.shortcutWorkToHome,
                      color: _kPrimaryPressed,
                    ),
                  ),
                ),
              ],
            ),
          ],
          // ── Custom saved places ─────────────────────────────────────────
          if (custom.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _kSoftElements.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: custom.length,
                separatorBuilder: (_, index) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final named = custom[i];
                  return GestureDetector(
                    onTap: () {
                      ref.read(pendingRouteProvider.notifier).state =
                          named.route.toPlaceResult();
                      context.go(AppRoutes.map);
                    },
                    onLongPress: () => ref
                        .read(quickRoutesProvider.notifier)
                        .removeCustom(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _kPrimaryColor.withValues(alpha: 0.08),
                            _kPrimaryColor.withValues(alpha: 0.04),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                            color: _kPrimaryColor.withValues(alpha: 0.25),
                            width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.place_rounded,
                              size: 16, color: _kPrimaryColor),
                          const SizedBox(width: 7),
                          Text(named.name,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: _kPrimaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteButton extends StatelessWidget {
  const _RouteButton({
    required this.icon,
    required this.label,
    this.sublabel,
    this.isSet = false,
  });
  final IconData icon;
  final String label;
  final String? sublabel;
  final bool isSet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: _kCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSet
              ? _kPrimaryColor.withValues(alpha: 0.4)
              : context.colors.border.withValues(alpha: 0.08),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSet
                  ? _kPrimaryColor.withValues(alpha: 0.12)
                  : context.colors.border.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                size: 24,
                color: isSet ? _kPrimaryColor : _kSecondaryText),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: _kPrimaryText,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (sublabel != null) ...[
            const SizedBox(height: 6),
            Text(
              sublabel!,
              style: const TextStyle(
                color: _kSecondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _ShortcutButton extends StatelessWidget {
  const _ShortcutButton({
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: _kPrimaryColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _kPrimaryColor.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Address Search Sheet (used by Quick Routes) ──────────────────────────────

class _AddressSearchSheet extends ConsumerStatefulWidget {
  const _AddressSearchSheet({required this.title, required this.onSave});
  final String title;
  final void Function(QuickRoute) onSave;

  @override
  ConsumerState<_AddressSearchSheet> createState() =>
      _AddressSearchSheetState();
}

class _AddressSearchSheetState extends ConsumerState<_AddressSearchSheet> {
  final _ctrl = TextEditingController();
  List<PlaceResult> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _search(String v) {
    _debounce?.cancel();
    if (v.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      setState(() => _loading = true);
      final lang = ref.read(localeProvider).languageCode;
      final results = await ref
          .read(placesServiceProvider)
          .autocomplete(v, language: lang);
      if (mounted) setState(() { _results = results; _loading = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _kSoftElements,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(widget.title, style: AppTextStyles.headline3),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: l10n.addressSearch,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
            if (_results.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: _kSoftElements),
                  itemBuilder: (_, i) {
                    final r = _results[i];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.place_rounded,
                          color: _kPrimaryColor, size: 20),
                      title: Text(r.text,
                          style: AppTextStyles.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSave(
                            QuickRoute(text: r.text, lat: r.lat, lng: r.lng));
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State Card ─────────────────────────────────────────────────────────

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: _kCardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kSoftElements, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kSoftElements, width: 1),
            ),
            child: Icon(icon, size: 28, color: _kSecondaryText),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: _kPrimaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: _kSecondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Language Toggle Button ──────────────────────────────────────────────────

void _showLanguageSelector(BuildContext context, WidgetRef ref) {
  final l10n = context.l10n;
  final currentLocale = ref.read(localeProvider);

  final languages = [
    (code: 'en', label: l10n.languageEnglish, flag: '🇬🇧'),
    (code: 'da', label: l10n.languageDanish, flag: '🇩🇰'),
  ];

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (context) => SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              l10n.languageTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
            ),
          ),
          // Language options
          ...languages.map((lang) {
            final isSelected = currentLocale.languageCode == lang.code;
            return InkWell(
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(Locale(lang.code));
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _kPrimaryColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? _kPrimaryColor
                        : context.colors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      lang.flag,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        lang.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: context.colors.textPrimary,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: _kPrimaryColor,
                        size: 24,
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
        ),
      ),
    ),
  );
}

class _LanguageToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isEn = locale.languageCode == 'en';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kCardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kSoftElements, width: 1),
      ),
      child: Center(
        child: Text(
          isEn ? '🇬🇧' : '🇩🇰',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

// ─── Weather Alerts Bell ──────────────────────────────────────────────────────

class _WeatherAlertsBell extends ConsumerWidget {
  const _WeatherAlertsBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(weatherAlertsProvider);

    return alertsAsync.when(
      loading: () => _buildBell(context, 0),
      error: (_, _) => _buildBell(context, 0),
      data: (alerts) => _buildBell(context, alerts.length),
    );
  }

  Widget _buildBell(BuildContext context, int alertCount) {
    return InkWell(
      onTap: () => context.push(AppRoutes.weatherAlerts),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _kCardBackground,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.warning_amber_rounded,
                size: 22,
                color: alertCount > 0 ? AppColors.warning : _kPrimaryText,
              ),
            ),
            if (alertCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: _kCardBackground, width: 1.5),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      alertCount > 9 ? '9+' : '$alertCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Commute Suggestion Card ──────────────────────────────────────────────────
// Shown at the top of the home screen when a time-appropriate commute
// destination is detected from the user's navigation history.

class _CommuteSuggestionCard extends ConsumerWidget {
  const _CommuteSuggestionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n       = context.l10n;
    final suggestion = ref.watch(commuteSuggestionProvider);

    return suggestion.when(
      loading: () => const SizedBox.shrink(),
      error:   (_, _) => const SizedBox.shrink(),
      data: (s) {
        if (s == null) return const SizedBox.shrink();
        final slotLabel = s.slot == SuggestionSlot.morning
            ? l10n.commuteMorning
            : s.slot == SuggestionSlot.evening
                ? l10n.commuteEvening
                : '';
        if (slotLabel.isEmpty && s.visitCount < 3) return const SizedBox.shrink();
        return Container(
          decoration: BoxDecoration(
            color: _kCardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kPrimaryColor.withValues(alpha: 0.2), width: 1),
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  s.slot == SuggestionSlot.morning
                      ? Icons.wb_sunny_outlined
                      : s.slot == SuggestionSlot.evening
                          ? Icons.nights_stay_outlined
                          : Icons.directions_bike_rounded,
                  color: _kPrimaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (slotLabel.isNotEmpty)
                      Text(
                        slotLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kSecondaryText,
                          letterSpacing: 0.2,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      s.text,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _kPrimaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: _kPrimaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      ref.read(pendingRouteProvider.notifier).state = PlaceResult(
                        placeId: 'commute_${s.lat}_${s.lng}',
                        text: s.text,
                        lat: s.lat,
                        lng: s.lng,
                      );
                      context.go(AppRoutes.map);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(
                        l10n.startCommute,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Frequent Destinations Card ───────────────────────────────────────────────
// Shows the user's top-visited cycling destinations so they can re-navigate
// to frequent places in one tap.

class _FrequentDestinationsCard extends ConsumerWidget {
  const _FrequentDestinationsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(frequentDestinationsProvider);

    return async.when(
      loading: () => const SizedBox.shrink(),
      error:   (_, _) => const SizedBox.shrink(),
      data: (destinations) {
        if (destinations.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: _kCardBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _kSoftElements, width: 1),
            ),
            child: Center(
              child: Text(
                l10n.frequentRoutesEmpty,
                style: AppTextStyles.bodySmall
                    .copyWith(color: _kSecondaryText),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _kCardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kSoftElements, width: 1),
          ),
          child: Column(
            children: destinations.map((d) {
              final isLast = d == destinations.last;
              return Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      ref.read(pendingRouteProvider.notifier).state = PlaceResult(
                        placeId: 'freq_${d.lat}_${d.lng}',
                        text: d.text,
                        lat: d.lat,
                        lng: d.lng,
                      );
                      context.go(AppRoutes.map);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _kPrimaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.place_rounded,
                                color: _kPrimaryColor, size: 18),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              d.text,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: _kPrimaryText,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.colors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _kSoftElements, width: 1),
                            ),
                            child: Text(
                              l10n.frequentVisitCount(d.count),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: _kSecondaryText,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right_rounded,
                              size: 18, color: _kSecondaryText),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                        height: 1, color: _kSoftElements),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// ─── Activity Stats Card ──────────────────────────────────────────────────────

class _ActivityStatsCard extends ConsumerStatefulWidget {
  const _ActivityStatsCard();

  @override
  ConsumerState<_ActivityStatsCard> createState() => _ActivityStatsCardState();
}

class _ActivityStatsCardState extends ConsumerState<_ActivityStatsCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Cache this widget after first build

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final todayStatsAsync = ref.watch(todayStatsProvider);
    final streakAsync = ref.watch(ridingStreakProvider);

    // Check if both values are loaded and empty
    final hasData = todayStatsAsync.hasValue && streakAsync.hasValue;
    final isEmpty = hasData && 
                    todayStatsAsync.value!.rideCount == 0 && 
                    streakAsync.value! == 0;

    if (isEmpty) {
      return _EmptyStateCard(
        icon: Icons.analytics_rounded,
        title: context.l10n.startTrackingRides,
        subtitle: context.l10n.startTrackingRidesSubtitle,
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kPrimaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.analytics_rounded, size: 18, color: _kPrimaryColor),
                ),
                const SizedBox(width: 12),
                Text(
                  context.l10n.activityStats,
                  style: const TextStyle(
                    color: _kPrimaryText,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 18),
          Row(
              children: [
                Expanded(
                  child: todayStatsAsync.when(
                    data: (stats) => _StatItem(
                      icon: Icons.directions_bike_rounded,
                      label: context.l10n.today,
                      value: stats.distanceLabel,
                      subtitle: '${stats.rideCount} rides',
                    ),
                    loading: () => const _StatItemSkeleton(),
                    error: (_, _) => _StatItem(
                      icon: Icons.error_outline,
                      label: context.l10n.today,
                      value: '--',
                      subtitle: '',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: streakAsync.when(
                    data: (streak) => _StatItem(
                      icon: Icons.local_fire_department_rounded,
                      label: context.l10n.streak,
                      value: '$streak',
                      subtitle: streak == 1 ? context.l10n.dayUnit : context.l10n.daysUnit,
                    ),
                    loading: () => const _StatItemSkeleton(),
                    error: (_, _) => _StatItem(
                      icon: Icons.error_outline,
                      label: context.l10n.streak,
                      value: '--',
                      subtitle: '',
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Weather Alerts Card ──────────────────────────────────────────────────────

class _WeatherAlertsCard extends ConsumerStatefulWidget {
  const _WeatherAlertsCard();

  @override
  ConsumerState<_WeatherAlertsCard> createState() => _WeatherAlertsCardState();
}

class _WeatherAlertsCardState extends ConsumerState<_WeatherAlertsCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Cache this widget after first build

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final alertsAsync = ref.watch(weatherAlertsProvider);

    return alertsAsync.when(
      data: (alerts) {
        if (alerts.isEmpty) {
          return _EmptyStateCard(
            icon: Icons.wb_sunny_rounded,
            title: context.l10n.noWeatherAlerts,
            subtitle: context.l10n.conditionsGoodForCycling,
          );
        }

        // PERFORMANCE: Use RepaintBoundary for each alert to reduce paint area
        return Container(
          decoration: BoxDecoration(
            color: _kCardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kSoftElements, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.error),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.l10n.weatherAlerts,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: _kPrimaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...alerts.map((alert) {
                  final localized = alert.localized(context);
                  // PERFORMANCE: RepaintBoundary per alert
                  return RepaintBoundary(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _getSeverityColor(alert.severity).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getAlertIcon(alert.type),
                            size: 14,
                            color: _getSeverityColor(alert.severity),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localized.title,
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: _kPrimaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                localized.message,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: _kSecondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ));
                }),
              ],
            ),
          ),
        );
      },
      loading: () => Container(
        decoration: BoxDecoration(
          color: _kCardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kSoftElements, width: 1),
        ),
        child: const Padding(
          padding: EdgeInsets.all(18),
          child: SizedBox(
            height: 60,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
      error: (_, _) => _EmptyStateCard(
        icon: Icons.wb_cloudy_rounded,
        title: context.l10n.weatherUnavailable,
        subtitle: context.l10n.unableToCheckWeather,
      ),
    );
  }

  IconData _getAlertIcon(WeatherAlertType type) {
    return switch (type) {
      WeatherAlertType.heavyRain        => Icons.grain_rounded,
      WeatherAlertType.strongWind       => Icons.air_rounded,
      WeatherAlertType.iceRisk          => Icons.ac_unit_rounded,
      WeatherAlertType.extremeCold      => Icons.thermostat_rounded,
      WeatherAlertType.highWinds        => Icons.storm_rounded,
      WeatherAlertType.fog              => Icons.cloud_rounded,
      WeatherAlertType.darkness         => Icons.nightlight_rounded,
      WeatherAlertType.sunsetApproaching => Icons.wb_twilight_rounded,
      WeatherAlertType.winterIce        => Icons.severe_cold_rounded,
    };
  }

  Color _getSeverityColor(AlertSeverity severity) {
    return switch (severity) {
      AlertSeverity.low => AppColors.textSecondary,
      AlertSeverity.medium => AppColors.warning,
      AlertSeverity.high => AppColors.error,
    };
  }
}

// ─── Maintenance Alerts Card ──────────────────────────────────────────────────

class _MaintenanceAlertsCard extends ConsumerWidget {
  const _MaintenanceAlertsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    ref.watch(bikeProfileProvider); // for rebuild on bike profile change

    if (!profile.needsMaintenance) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      color: AppColors.warning.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.warning, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.build_rounded,
              size: 20,
              color: AppColors.warning,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.maintenanceDue,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.maintenanceBody((profile.totalDistanceKm - (profile.lastMaintenanceKm ?? 0)).round().toString()),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _kSecondaryText,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(context.l10n.confirmAction),
                    content: Text(context.l10n.confirmMaintenanceReset),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(context.l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(context.l10n.markDone),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  ref.read(userProfileProvider.notifier).resetMaintenanceCounter();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.maintenanceMarkedDone)),
                  );
                }
              },
              child: Text(
                context.l10n.markDone,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Item Widget ─────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: _kPrimaryColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: _kSecondaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.headline3.copyWith(
            color: _kPrimaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: _kSecondaryText,
            ),
          ),
      ],
    );
  }
}

// ─── Stat Item Skeleton ───────────────────────────────────────────────────────

class _StatItemSkeleton extends StatelessWidget {
  const _StatItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          height: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _kSoftElements,
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          ),
        ),
        SizedBox(height: 4),
        SizedBox(
          width: 40,
          height: 20,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _kSoftElements,
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          ),
        ),
        SizedBox(
          width: 50,
          height: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _kSoftElements,
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          ),
        ),
      ],
    );
  }
}
// ─── Nearby Card ──────────────────────────────────────────────────────────────

class _NearbyCard extends ConsumerStatefulWidget {
  const _NearbyCard();

  // Static helper methods remain in parent class for access from child widgets
  static Color _poiColor(String placeId) {
    if (placeId.startsWith('shop_')) return _kPrimaryColor;
    if (placeId.startsWith('charging_')) return AppColors.warning;
    if (placeId.startsWith('rental_')) return Colors.deepPurpleAccent;
    return AppColors.info; // service_
  }

  static IconData _poiIcon(String placeId) {
    if (placeId.startsWith('shop_')) return Icons.storefront_rounded;
    if (placeId.startsWith('charging_')) return Icons.ev_station_rounded;
    if (placeId.startsWith('rental_')) return Icons.directions_bike_rounded;
    return Icons.build_circle_rounded; // service_
  }

  @override
  ConsumerState<_NearbyCard> createState() => _NearbyCardState();
}

class _NearbyCardState extends ConsumerState<_NearbyCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Cache this widget after first build

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final nearbyAsync = ref.watch(_homeNearbyProvider);

    return nearbyAsync.when(
      loading: () => Container(
        height: 80,
        decoration: BoxDecoration(
          color: _kCardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kSoftElements, width: 1),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => _EmptyStateCard(
        icon: Icons.location_off_outlined,
        title: context.l10n.couldNotLoadNearby,
        subtitle: context.l10n.checkConnectionRetry,
      ),
      data: (places) {
        if (places.isEmpty) {
          return _EmptyStateCard(
            icon: Icons.location_on_outlined,
            title: context.l10n.noBikePlacesNearby,
            subtitle: context.l10n.tryCyclingMoreInfra,
          );
        }
        final shown = places.take(5).toList();
        return Container(
          decoration: BoxDecoration(
            color: _kCardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kSoftElements, width: 1),
          ),
          child: Column(
            children: [
              for (int i = 0; i < shown.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, indent: 60, endIndent: 18, color: _kSoftElements),
                _NearbyTile(place: shown[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _NearbyTile extends ConsumerWidget {
  const _NearbyTile({required this.place});
  final PlaceResult place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _NearbyCard._poiColor(place.placeId);
    final icon = _NearbyCard._poiIcon(place.placeId);
    final l10n = context.l10n;
    final category = place.placeId.startsWith('shop_')
        ? l10n.bikeShop
        : place.placeId.startsWith('charging_')
            ? l10n.chargingStation
            : place.placeId.startsWith('rental_')
                ? l10n.bikeRental
                : l10n.repairStation;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        ref.read(pendingRouteProvider.notifier).state = place;
        context.go(AppRoutes.map);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.text,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _kSecondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _kSecondaryText,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Monthly Challenge Card ───────────────────────────────────────────────────

class _MonthlyChallengeCard extends ConsumerWidget {
  const _MonthlyChallengeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(monthlyChallengeProvider);

    return challengeAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, e) => const SizedBox.shrink(),
      data: (challenge) {
        final now = DateTime.now();
        final l10n = context.l10n;
        final monthNames = [
          l10n.monthJan, l10n.monthFeb, l10n.monthMar, l10n.monthApr, l10n.monthMay, l10n.monthJun,
          l10n.monthJul, l10n.monthAug, l10n.monthSep, l10n.monthOct, l10n.monthNov, l10n.monthDec
        ];
        final monthName = monthNames[now.month - 1];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: challenge.isComplete
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.successLight, AppColors.successLight],
                  )
                : null,
            color: challenge.isComplete ? null : context.colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: challenge.isComplete
                    ? _kPrimaryColor.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    challenge.isComplete
                        ? Icons.emoji_events_rounded
                        : Icons.flag_rounded,
                    color: _kPrimaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.monthlyChallenge(monthName),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _kPrimaryText,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l10n.challengeRideCount(challenge.rideCount),
                    style: const TextStyle(
                      color: _kSecondaryText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: challenge.progress,
                  minHeight: 8,
                  backgroundColor: _kPrimaryColor.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(_kPrimaryColor),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    challenge.progressLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _kPrimaryText,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    challenge.statusLabel,
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── E-Bike Range Card ────────────────────────────────────────────────────────

class _EbikeRangeCard extends ConsumerWidget {
  const _EbikeRangeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(allBikesRangeProvider);
    if (range == null) return const SizedBox.shrink();

    final Color barColor = range.isLow
        ? AppColors.error
        : range.isMedium
            ? AppColors.warning
            : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: barColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.electric_bolt_rounded,
              color: barColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.eBikeRange,
                      style: const TextStyle(
                        color: _kPrimaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      context.l10n.batteryPercent(range.batteryPercent),
                      style: const TextStyle(
                        color: _kSecondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: range.batteryPercent / 100,
                    minHeight: 6,
                    backgroundColor: barColor.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      context.l10n.rangeRemaining(range.label),
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _kPrimaryText,
                      ),
                    ),
                    if (range.weatherAdjusted) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.thermostat_rounded,
                          size: 14, color: _kSecondaryText),
                    ],
                    if (range.isLow) ...[
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.lowBattery,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                if (range.needsChargingSoon) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.ev_station_rounded,
                          size: 14, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        context.l10n.chargeSuggestion,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Commuter Tax Deduction Card (Phase 8.6) ─────────────────────────────────

class _CommuterTaxCard extends ConsumerWidget {
  const _CommuterTaxCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final deductionAsync = ref.watch(taxDeductionProvider);

    return deductionAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (summary) {
        // Only show if there are commute trips recorded.
        if (summary.totalCommuteDays == 0) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CommuterTaxDetailScreen(),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _kPrimaryColor.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long_rounded,
                      color: _kPrimaryColor, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.commuterTax,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _kPrimaryText,
                      ),
                    ),
                  ),
                  Text(
                    '${summary.year}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: _kSecondaryText),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TaxMetric(
                      label: l10n.commuteDays,
                      value: '${summary.totalCommuteDays}',
                    ),
                  ),
                  Expanded(
                    child: _TaxMetric(
                      label: l10n.commuteKm,
                      value: '${summary.totalCommuteKm.toStringAsFixed(0)} km',
                    ),
                  ),
                  Expanded(
                    child: _TaxMetric(
                      label: l10n.deductibleKm,
                      value: '${summary.deductibleKm.toStringAsFixed(0)} km',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: _kPrimaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.estimatedDeduction(
                          summary.estimatedDeductionDkk.toStringAsFixed(0)),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _kPrimaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.estimatedTaxSavings(
                          summary.estimatedTaxSavingsDkk.toStringAsFixed(0)),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _kPrimaryColor,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showTaxDeductionInfo(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: _kPrimaryColor.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.taxDeductionInfo,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _kPrimaryColor.withValues(alpha: 0.7),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ), // GestureDetector child
        );
      },
    );
  }

  void _showTaxDeductionInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.receipt_long_rounded, color: _kPrimaryColor),
            const SizedBox(width: 8),
            Text(context.l10n.taxDeductionInfo),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            CommuterTaxService.getDeductionInfo(),
            style: AppTextStyles.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _TaxMetric extends StatelessWidget {
  const _TaxMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: _kSecondaryText,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: _kPrimaryText,
          ),
        ),
      ],
    );
  }
}

// ─── Upcoming Events Card ─────────────────────────────────────────────────────

class _UpcomingEventsCard extends ConsumerWidget {
  const _UpcomingEventsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(upcomingEventsProvider);

    return eventsAsync.when(
      loading: () => const SizedBox(
        height: 174,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, stack) {
        debugPrint('🔴 EVENTS ERROR: $e');
        debugPrint('🔴 Stack: $stack');
        return const SizedBox.shrink();
      },
      data: (events) {
        debugPrint('🟢 EVENTS: Loaded ${events.length} upcoming events');
        if (events.isEmpty) {
          debugPrint('🟡 EVENTS: No events found - showing discover card');
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  context.l10n.groupRides,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _kPrimaryText,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 174,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  cacheExtent: 0,
                  physics: const ClampingScrollPhysics(),
                  itemCount: 1,
                  itemBuilder: (context, index) => _buildDiscoverCard(context),
                ),
              ),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.upcomingGroupRides,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _kPrimaryText,
                        fontSize: 20,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.events),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      context.l10n.seeAll,
                      style: const TextStyle(
                        color: _kPrimaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                cacheExtent: 0,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: false,
                itemCount: events.length,
                itemBuilder: (context, index) => _buildEventItem(context, events[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDiscoverCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.events),
      child: Container(
        height: 174,
        margin: const EdgeInsets.only(right: 12),
        width: MediaQuery.of(context).size.width * 0.75,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _kPrimaryColor,
              _kPrimaryPressed,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Pattern overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Opacity(
                  opacity: 0.15,
                  child: CustomPaint(
                    painter: _BikePatterPainter(),
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.groups_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.findGroupRides,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.discoverLocalRides,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      context.l10n.discoverEvents,
                      style: const TextStyle(
                        color: _kPrimaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(BuildContext context, RideEvent event) {
    final cardWidth = MediaQuery.of(context).size.width * 0.85;
    
    return GestureDetector(
      onTap: () => context.push('${AppRoutes.events}/${event.id}'),
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image only - NO gradient, NO stack, NO shadow
            SizedBox(
              height: 135,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                    ? Image.network(
                        event.imageUrl!,
                        height: 135,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        cacheWidth: 400,
                        cacheHeight: 270,
                        filterQuality: FilterQuality.low,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: _kPrimaryColor,
                          child: const Icon(Icons.event, color: Colors.white, size: 40),
                        ),
                      )
                    : Container(
                        color: _kPrimaryColor,
                        child: const Icon(Icons.event, color: Colors.white, size: 40),
                      ),
              ),
            ),
            // Text BELOW image - simple, no overlays
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        event.eventType.icon,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (event.currentParticipants > 0) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.people, size: 13, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(
                          '${event.currentParticipants}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${event.formattedDate} • ${event.formattedTime}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Optimized event card without image loading to prevent GPU buffer issues
  Widget _buildEventItemOptimized(BuildContext context, RideEvent event) {
    final cardWidth = MediaQuery.of(context).size.width * 0.75;
    const cardHeight = 174.0;
    
    // Generate stable gradient colors based on event type
    final gradientColors = _getEventTypeGradient(event.eventType);
    
    return GestureDetector(
      onTap: () => context.push('${AppRoutes.events}/${event.id}'),
      child: Container(
        height: cardHeight,
        width: cardWidth,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Dark gradient overlay for text readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),
            // Event type tag (top-left)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event.eventType.icon,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.eventType.localizedLabel(context),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Participant count (top-right)
            if (event.currentParticipants > 0)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.people,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.currentParticipants}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Content (bottom)
            Positioned(
              bottom: 12,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${event.formattedDate} • ${event.formattedTime}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (event.meetingPoint.name != null && event.meetingPoint.name!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            event.meetingPoint.name!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getEventTypeGradient(EventType type) {
    switch (type) {
      case EventType.social:
        return [const Color(0xFF4CAF50), const Color(0xFF2E7D32)];
      case EventType.training:
        return [const Color(0xFFFF6F00), const Color(0xFFE65100)];
      case EventType.race:
        return [const Color(0xFFD32F2F), const Color(0xFFB71C1C)];
      case EventType.tour:
        return [const Color(0xFF0288D1), const Color(0xFF01579B)];
      case EventType.commute:
        return [const Color(0xFF7B1FA2), const Color(0xFF4A148C)];
      case EventType.gravel:
        return [const Color(0xFF5D4037), const Color(0xFF3E2723)];
      case EventType.family:
        return [const Color(0xFFEC407A), const Color(0xFFC2185B)];
      case EventType.night:
        return [const Color(0xFF1A237E), const Color(0xFF0D47A1)];
      case EventType.beginner:
        return [const Color(0xFF66BB6A), const Color(0xFF43A047)];
      case EventType.expat:
        return [const Color(0xFF26A69A), const Color(0xFF00897B)];
      case EventType.languageExchange:
        return [const Color(0xFFAB47BC), const Color(0xFF8E24AA)];
      default:
        return [_kPrimaryColor, _kPrimaryPressed];
    }
  }
}

// ─── Bike Pattern Painter ─────────────────────────────────────────────────────
class _BikePatterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw simple bike-like patterns
    for (var i = 0; i < 3; i++) {
      final offsetY = size.height * (0.2 + i * 0.3);
      final offsetX = size.width * (0.2 + i * 0.2);
      
      // Draw circles (wheels)
      canvas.drawCircle(Offset(offsetX, offsetY), 12, paint);
      canvas.drawCircle(Offset(offsetX + 40, offsetY), 12, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
