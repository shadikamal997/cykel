/// CYKEL — Subscription / Plans Screen
/// Full Free vs Premium comparison matching the CYKEL feature specification.
/// Uses `in_app_purchase` for real App Store / Play Store subscriptions.
/// Subscription status is synced to Firestore via the `verifyPurchase`
/// Cloud Function and read back through `subscriptionStatusProvider`.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/subscription_providers.dart';

// ─── Data helpers ─────────────────────────────────────────────────────────────

class _Row {
  const _Row(this.label, {this.free = true, this.premium = true, this.note});
  final String  label;
  final bool    free;
  final bool    premium;
  final String? note;
}

class _Section {
  const _Section(this.emoji, this.title);
  final String emoji;
  final String title;
}

// Each list entry is either a _Section or a _Row
List<Object> _buildTable(AppLocalizations l10n) => [
  // ── FREE: Navigation & Map ────────────────────────────────────────────────
  _Section('🗺️', l10n.subNavAndMap),
  _Row(l10n.subFeatBasicRouting),
  _Row(l10n.subFeatVoiceNav),
  _Row(l10n.subFeatGpsTracking),
  _Row(l10n.subFeatFollowUser),
  _Row(l10n.subFeatAltRoutes),
  _Row(l10n.subFeatNearbyPoi),
  _Row(l10n.subFeatMapLayers),
  _Row(l10n.subFeatRouteSummary),
  _Row(l10n.subFeatWeatherWind),
  _Row(l10n.subFeatNightMode),
  _Row(l10n.subFeatLocaleSwitching),

  // ── FREE: Safety — Always Free ────────────────────────────────────────────
  _Section('🛡️', l10n.subSafety),
  _Row(l10n.subFeatStormWarnings),
  _Row(l10n.subFeatIceAlerts),
  _Row(l10n.subFeatFogWarnings),
  _Row(l10n.subFeatHazardAlerts),
  _Row(l10n.subFeatCrowdHazards),
  _Row(l10n.subFeatEmergencySos),
  _Row(l10n.subFeatAccidentReport),
  _Row(l10n.subFeatRideCondition),
  _Row(l10n.subFeatSafetyNotifs),

  // ── FREE: Activity Tracking ───────────────────────────────────────────────
  _Section('🚲', l10n.subActivityTracking),
  _Row(l10n.subFeatLiveRecording),
  _Row(l10n.subFeatCaloriesBasic),
  _Row(l10n.subFeatRideHistory30, premium: false, note: l10n.subFeatRideHistoryNote),
  _Row(l10n.subFeatWeeklyStats),
  _Row(l10n.subFeatMonthlyGoals),
  _Row(l10n.subFeatCo2Stats),
  _Row(l10n.subFeatFuelSavings),
  _Row(l10n.subFeatDashboardSummary),

  // ── FREE: Personalization ─────────────────────────────────────────────────
  _Section('⚙️', l10n.subPersonalization),
  _Row(l10n.subFeatMultiBikes),
  _Row(l10n.subFeatSavedPlaces),
  _Row(l10n.subFeatCommuteSuggestion),
  _Row(l10n.subFeatPushNotifs),
  _Row(l10n.subFeatGdprControls),
  _Row(l10n.subFeatAppTheme),

  // ── FREE: Marketplace ─────────────────────────────────────────────────────
  _Section('🛒', l10n.subMarketplaceBasic),
  _Row(l10n.subFeatBrowseListings),
  _Row(l10n.subFeatViewDetails),
  _Row(l10n.subFeatContactSeller),
  _Row(l10n.subFeatBasicListing),

  // ── PREMIUM: Smart Routing ────────────────────────────────────────────────
  _Section('🌬️', l10n.subSmartRouting),
  _Row(l10n.subFeatWindRouting, free: false),
  _Row(l10n.subFeatElevRouting, free: false),
  _Row(l10n.subFeatRouteModeFastSafe, free: false),
  _Row(l10n.subFeatFreqDest, free: false),
  _Row(l10n.subFeatUnlimitedRoutes, free: false),
  _Row(l10n.subFeatAdvRoutePrefs, free: false),

  // ── PREMIUM: Offline & Reliability ───────────────────────────────────────
  _Section('📡', l10n.subOffline),
  _Row(l10n.subFeatOfflineRoutes, free: false),
  _Row(l10n.subFeatCachedTiles, free: false),
  _Row(l10n.subFeatOfflineTbt, free: false),
  _Row(l10n.subFeatNetworkFallback, free: false),
  _Row(l10n.subFeatGpsMitigation, free: false),
  _Row(l10n.subFeatRouteRecovery, free: false),

  // ── PREMIUM: E-Bike Intelligence ──────────────────────────────────────────
  _Section('⚡', l10n.subEbikeIntel),
  _Row(l10n.subFeatBatteryRange, free: false),
  _Row(l10n.subFeatEnergyModel, free: false),
  _Row(l10n.subFeatElevRange, free: false),
  _Row(l10n.subFeatRangeCard, free: false),

  // ── PREMIUM: Advanced Analytics ───────────────────────────────────────────
  _Section('📊', l10n.subAdvAnalytics),
  _Row(l10n.subFeatUnlimitedHistory, free: false),
  _Row(l10n.subFeatElevTracking, free: false),
  _Row(l10n.subFeatElevCalorie, free: false),
  _Row(l10n.subFeatPeriodStats, free: false),
  _Row(l10n.subFeatPersonalRecords, free: false),
  _Row(l10n.subFeatGpxExport, free: false),

  // ── PREMIUM: Automation ───────────────────────────────────────────────────
  _Section('🔔', l10n.subAutomation),
  _Row(l10n.subFeatScheduledReminders, free: false),
  _Row(l10n.subFeatMaintenanceAlerts, free: false),
  _Row(l10n.subFeatSmartNotifs, free: false),

  // ── PREMIUM: Route Sharing ────────────────────────────────────────────────
  _Section('🔗', l10n.subRouteSharing),
  _Row(l10n.subFeatShareLink, free: false),
  _Row(l10n.subFeatExportGpx, free: false),
  _Row(l10n.subFeatShareSummary, free: false),
  _Row(l10n.subFeatSendToFriends, free: false),
  _Row(l10n.subFeatImportRoutes, free: false),

  // ── PREMIUM: Advanced Customisation ──────────────────────────────────────
  _Section('🎨', l10n.subAdvCustom),
  _Row(l10n.subFeatCustomDashboard, free: false),
  _Row(l10n.subFeatMapStyle, free: false),
  _Row(l10n.subFeatCustomAlerts, free: false),
  _Row(l10n.subFeatCustomGoals, free: false),
  _Row(l10n.subFeatUiDensity, free: false),

  // ── PREMIUM: Voice Experience ─────────────────────────────────────────────
  _Section('🔊', l10n.subVoiceNav),
  _Row(l10n.subFeatPremiumVoice, free: false),
  _Row(l10n.subFeatMultiLangVoice, free: false),
  _Row(l10n.subFeatVoiceStyle, free: false),
  _Row(l10n.subFeatAnnouncementFreq, free: false),

  // ── PREMIUM: Cloud Sync ───────────────────────────────────────────────────
  _Section('☁️', l10n.subCloudSync),
  _Row(l10n.subFeatDataSync, free: false),
  _Row(l10n.subFeatCloudBackup, free: false),
  _Row(l10n.subFeatRestoreHistory, free: false),
  _Row(l10n.subFeatSyncProfiles, free: false),

  // ── PREMIUM: Marketplace Plus ─────────────────────────────────────────────
  _Section('⭐', l10n.subMarketplacePro),
  _Row(l10n.subFeatUnlimitedListings, free: false),
  _Row(l10n.subFeatPriorityPlacement, free: false),
  _Row(l10n.subFeatHighlighted, free: false),
  _Row(l10n.subFeatAdvSearchFilters, free: false),
  _Row(l10n.subFeatSellerAnalytics, free: false),
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n       = context.l10n;
    final isPremium  = ref.watch(isPremiumProvider);
    final topPad     = MediaQuery.of(context).padding.top;
    final tableItems = _buildTable(l10n);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [Colors.white.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.1)]
                      : [Colors.black.withValues(alpha: 0.9), Colors.black.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.fromLTRB(24, topPad + 16, 24, 32),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.workspace_premium_rounded,
                      size: 64, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    l10n.cykelPremiumTitle,
                    style: AppTextStyles.headline1
                        .copyWith(color: Colors.white, fontSize: 28),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.premiumTagline,
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      isPremium
                          ? l10n.onPremiumStatus
                          : l10n.onFreeStatus,
                      style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _PriceCard(isPremium: isPremium, widgetRef: ref),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 4),
              child: Row(
                children: [
                  Expanded(child: Text(l10n.featuresHeader, style: AppTextStyles.labelSmall)),
                  _ColLabel(l10n.freeColumn, Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  _ColLabel(l10n.proColumn, Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                ],
              ),
            ),
          ),

          SliverList.list(
            children: tableItems.map((item) {
              if (item is _Section) return _SectionTile(item);
              if (item is _Row)     return _FeatureTile(item);
              return const SizedBox.shrink();
            }).toList(),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }
}

class _ColLabel extends StatelessWidget {
  const _ColLabel(this.text, this.color);
  final String text;
  final Color  color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 44,
        child: Center(
          child: Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      );
}

class _SectionTile extends StatelessWidget {
  const _SectionTile(this.section);
  final _Section section;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.07),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        child: Row(
          children: [
            Text(section.emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                section.title,
                style: AppTextStyles.labelMedium.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile(this.data);
  final _Row data;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.label,
                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 13)),
                    if (data.note != null)
                      Text(
                        data.note!,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                  ],
                ),
              ),
              _Tick(data.free),
              const SizedBox(width: 8),
              _Tick(data.premium, isPremium: true),
            ],
          ),
        ),
      );
}

class _Tick extends StatelessWidget {
  const _Tick(this.included, {this.isPremium = false});
  final bool included;
  final bool isPremium;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 44,
        child: Center(
          child: included
              ? Icon(Icons.check_circle_rounded,
                  size: 18,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
              : Icon(Icons.remove_rounded, size: 18, color: context.colors.textHint),
        ),
      );
}

class _PriceCard extends ConsumerWidget {
  const _PriceCard({required this.isPremium, required this.widgetRef});
  final bool      isPremium;
  final WidgetRef widgetRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final storePrice = ref.watch(premiumPriceProvider);
    return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            if (!isPremium) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ValuePill('🌬️', l10n.pillWindAI),
                  _ValuePill('📊', l10n.pillAnalytics),
                  _ValuePill('⚡', l10n.pillEBike),
                  _ValuePill('☁️', l10n.pillCloud),
                ],
              ),
              const SizedBox(height: 20),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(storePrice ?? l10n.premiumPrice,
                    style: AppTextStyles.headline1
                        .copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 38)),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(l10n.premiumPerMonth,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.premiumPriceNote,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: isPremium
                  ? OutlinedButton(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(l10n.cancelPremiumTitle),
                            content: Text(l10n.cancelPremiumBody),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(l10n.keepPremium)),
                              TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(l10n.cancel,
                                      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black))),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .update({
                            'subscription.plan': 'free',
                            'subscription.active': false,
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.switchedToFree)));
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(l10n.manageSubscription),
                    )
                  : ElevatedButton(
                      onPressed: () async {
                        final svc = ref.read(purchaseServiceProvider);
                        final started = await svc.buyPremium();
                        if (!started && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.purchaseUnavailable),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        l10n.upgradeButtonLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            if (!isPremium)
              TextButton(
                onPressed: () async {
                  final svc = ref.read(purchaseServiceProvider);
                  await svc.restorePurchases();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.restorePurchasesDone)),
                    );
                  }
                },
                child: Text(l10n.restorePurchases,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ),
          ],
        ),
      );
  }
}

class _ValuePill extends StatelessWidget {
  const _ValuePill(this.emoji, this.label);
  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(fontSize: 10, color: AppColors.textSecondary)),
        ],
      );
}
