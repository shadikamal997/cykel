/// CYKEL — Subscription / Plans Screen
/// Full Free vs Premium comparison matching the CYKEL feature specification.
/// Uses `in_app_purchase` for real App Store / Play Store subscriptions.
/// Subscription status is synced to Firestore via the `verifyPurchase`
/// Cloud Function and read back through `subscriptionStatusProvider`.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/subscription_providers.dart';

// ─── Firestore User Data Provider ────────────────────────────────────────────
/// Phase 2: Stream provider for student verification status from Firestore.
final firestoreUserDataProvider = StreamProvider.autoDispose<Map<String, dynamic>?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) => snapshot.data());
});

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
    final tableItems = _buildTable(l10n);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Image.asset(
              'assets/images/subscriptionhero.webp',
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _PriceCard(isPremium: isPremium),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 4),
              child: Row(
                children: [
                  Expanded(child: Text(l10n.featuresHeader, style: AppTextStyles.labelSmall)),
                  _ColLabel(l10n.freeColumn, context.colors.textPrimary.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  _ColLabel(l10n.proColumn, context.colors.textPrimary),
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
          color: (context.colors.textPrimary).withValues(alpha: 0.07),
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
                  color: context.colors.textPrimary,
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
            color: context.colors.surface,
            border: Border(
              bottom: BorderSide(
                  color: context.colors.surfaceVariant.withValues(alpha: 0.5)),
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
                            color: context.colors.textSecondary, fontSize: 11),
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
                  color: context.colors.textPrimary)
              : Icon(Icons.remove_rounded, size: 18, color: context.colors.textHint),
        ),
      );
}

class _PriceCard extends ConsumerStatefulWidget {
  const _PriceCard({required this.isPremium});
  final bool isPremium;

  @override
  ConsumerState<_PriceCard> createState() => _PriceCardState();
}

class _PriceCardState extends ConsumerState<_PriceCard> {
  /// Phase 2: Billing period toggle (monthly = true, yearly = false).
  bool _isMonthly = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final userData = ref.watch(firestoreUserDataProvider).valueOrNull;
    
    // Parse student verification status
    final isStudent = userData?['isStudent'] as bool? ?? false;
    final isStudentVerified = userData?['isStudentVerified'] as bool? ?? false;
    final studentVerifiedUntilStr = userData?['studentVerifiedUntil'] as String?;
    
    DateTime? studentVerifiedUntil;
    if (studentVerifiedUntilStr != null) {
      try {
        studentVerifiedUntil = DateTime.parse(studentVerifiedUntilStr);
      } catch (_) {}
    }
    
    // Check if student verification is valid
    final hasValidStudentStatus = isStudentVerified && 
        studentVerifiedUntil != null && 
        studentVerifiedUntil.isAfter(DateTime.now());
    
    // Show student banner if user is a student but not verified or verification expired
    final showStudentBanner = isStudent && !hasValidStudentStatus && !widget.isPremium;

    // Get prices from providers
    final monthlyPrice = ref.watch(premiumPriceProvider);
    final studentPrice = ref.watch(studentPriceProvider);
    final annualPrice = ref.watch(annualPriceProvider);

    // Determine which price to display
    String? displayPrice;
    if (_isMonthly) {
      displayPrice = hasValidStudentStatus ? (studentPrice ?? 'kr 10') : (monthlyPrice ?? 'kr 20');
    } else {
      displayPrice = annualPrice ?? 'kr 200';
    }

    return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.colors.surface,
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
            if (!widget.isPremium) ...[
              // Student discount banner
              if (showStudentBanner) ...[
                GestureDetector(
                  onTap: () => context.push(AppRoutes.profileStudentVerification),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade50, Colors.purple.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        const Text('🎓', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Student? Get 50% off Premium',
                                style: AppTextStyles.labelMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'kr 10/month instead of kr 20',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue.shade700),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Verified student badge
              if (hasValidStudentStatus) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, color: Colors.green.shade700, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Verified Student - 50% Discount Applied',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Billing period toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _BillingPeriodButton(
                        label: 'Monthly',
                        isSelected: _isMonthly,
                        onTap: () => setState(() => _isMonthly = true),
                      ),
                    ),
                    Expanded(
                      child: _BillingPeriodButton(
                        label: 'Yearly',
                        isSelected: !_isMonthly,
                        onTap: () => setState(() => _isMonthly = false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

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
                Text(displayPrice,
                    style: AppTextStyles.headline1
                        .copyWith(color: context.colors.textPrimary, fontSize: 38)),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(_isMonthly ? l10n.premiumPerMonth : '/year',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: context.colors.textSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            // Savings message for annual plan
            if (!_isMonthly && !widget.isPremium)
              Text(
                'Save kr 40 with annual plan',
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.green.shade700, fontWeight: FontWeight.w600),
              )
            else
              Text(
                l10n.premiumPriceNote,
                style: AppTextStyles.bodySmall
                    .copyWith(color: context.colors.textSecondary),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: widget.isPremium
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
                                      style: TextStyle(color: context.colors.textPrimary))),
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
                              SnackBar(content: Text(l10n.switchedToFree)),
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.colors.textPrimary,
                        side: BorderSide(color: context.colors.textPrimary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(l10n.manageSubscription),
                    )
                  : ElevatedButton(
                      onPressed: () async {
                        final svc = ref.read(purchaseServiceProvider);
                        bool started;
                        
                        // Phase 2: Select appropriate purchase method
                        if (_isMonthly) {
                          if (hasValidStudentStatus) {
                            started = await svc.buyStudentPremium();
                          } else {
                            started = await svc.buyPremium();
                          }
                        } else {
                          started = await svc.buyAnnualPremium();
                        }
                        
                        if (!started && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.purchaseUnavailable),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
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
            if (!widget.isPremium)
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
                        .copyWith(color: context.colors.textSecondary)),
              ),
          ],
        ),
      );
  }
}

/// Phase 2: Billing period toggle button.
class _BillingPeriodButton extends StatelessWidget {
  const _BillingPeriodButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? (context.colors.textPrimary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected
                ? context.colors.surface
                : context.colors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
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
                  .copyWith(fontSize: 10, color: context.colors.textSecondary)),
        ],
      );
}
