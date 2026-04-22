import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../application/family_pricing_providers.dart';
import '../domain/subscription.dart';
import 'checkout_screen.dart';

/// Subscription plans comparison and selection screen
class SubscriptionPlansScreen extends ConsumerWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(availablePlansProvider);
    final billingPeriod = ref.watch(selectedBillingPeriodProvider);
    final currentSub = ref.watch(currentSubscriptionProvider);
    final currentPlan = currentSub.valueOrNull?.plan ?? SubscriptionPlan.free;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Image with Overlay
            Stack(
              children: [
                // Hero Image
                SizedBox(
                  height: 320,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/images/subscriptionhero.webp',
                    fit: BoxFit.cover,
                  ),
                ),
                // Gradient Overlay
                Container(
                  height: 320,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
                // Hero Content
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        size: 56,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Upgrade Your Cycling Experience',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose the plan that fits your riding style',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Content Padding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

            // Billing toggle
            _BillingPeriodSelector(
              selected: billingPeriod,
              onChanged: (period) {
                ref.read(selectedBillingPeriodProvider.notifier).state = period;
              },
            ),
            const SizedBox(height: 32),

            // Section Title
            Text(
              'Choose Your Plan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Plan cards
            ...plans.map((pricing) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _PlanCard(
                    pricing: pricing,
                    billingPeriod: billingPeriod,
                    isCurrentPlan: currentPlan == pricing.plan,
                    onSelect: currentPlan == pricing.plan
                        ? null
                        : () => _selectPlan(context, ref, pricing, billingPeriod),
                  ),
                )),

            const SizedBox(height: 24),

            // Trial info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All paid plans include a 14-day free trial. Cancel anytime.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.info,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Feature comparison
            _FeatureComparisonTable(plans: plans),

            const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectPlan(BuildContext context, WidgetRef ref,
      SubscriptionPricing pricing, BillingPeriod period) {
    ref.read(selectedPlanProvider.notifier).state = pricing.plan;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CheckoutScreen(
        pricing: pricing,
        billingPeriod: period,
      ),
    ));
  }
}

/// Toggle between monthly/quarterly/yearly billing
class _BillingPeriodSelector extends StatelessWidget {
  final BillingPeriod selected;
  final ValueChanged<BillingPeriod> onChanged;

  const _BillingPeriodSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: BillingPeriod.values.map((period) {
          final isSelected = period == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(period),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      period.displayName,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: isSelected ? 14 : 13,
                      ),
                    ),
                    if (period == BillingPeriod.yearly)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.2)
                              : AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Save 25%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppColors.success,
                          ),
                        ),
                      ),
                    if (period == BillingPeriod.quarterly)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.2)
                              : AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Save 10%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Individual plan card
class _PlanCard extends StatelessWidget {
  final SubscriptionPricing pricing;
  final BillingPeriod billingPeriod;
  final bool isCurrentPlan;
  final VoidCallback? onSelect;

  const _PlanCard({
    required this.pricing,
    required this.billingPeriod,
    required this.isCurrentPlan,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final price = pricing.getPriceForPeriod(billingPeriod);
    final isHighlighted = pricing.isMostPopular || pricing.isBestValue;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlan
              ? AppColors.success
              : isHighlighted
                  ? AppColors.primary
                  : AppColors.cardBorder,
          width: isHighlighted || isCurrentPlan ? 2 : 1,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Badge
          if (pricing.isMostPopular || pricing.isBestValue || isCurrentPlan)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isCurrentPlan
                    ? AppColors.success
                    : pricing.isBestValue
                        ? AppColors.warning
                        : AppColors.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Text(
                isCurrentPlan
                    ? 'Current Plan'
                    : pricing.isBestValue
                        ? '🏆 Best Value'
                        : '⭐ Most Popular',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan name & description
                Text(
                  pricing.plan.displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  pricing.plan.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                ),
                const SizedBox(height: 16),

                // Price
                if (pricing.monthlyPrice == 0)
                  Text(
                    'Free',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${price.toStringAsFixed(0)} DKK',
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '/${billingPeriod == BillingPeriod.monthly ? 'mo' : billingPeriod == BillingPeriod.quarterly ? 'qtr' : 'yr'}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: context.colors.textSecondary,
                                  ),
                        ),
                      ),
                    ],
                  ),

                if (billingPeriod == BillingPeriod.yearly &&
                    pricing.monthlyPrice > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Save ${pricing.yearlySavings.toStringAsFixed(0)} DKK/year (${pricing.yearlySavingsPercentage.toStringAsFixed(0)}%)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Features
                ...pricing.features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              size: 18, color: AppColors.success),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    )),

                // Excluded features
                ...pricing.excludedFeatures.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.cancel,
                              size: 18,
                              color: AppColors.textHint.withValues(alpha: 0.5)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style:
                                  Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textHint,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                            ),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 16),

                // CTA button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentPlan
                          ? AppColors.surface
                          : pricing.plan == SubscriptionPlan.free
                              ? AppColors.surface
                              : AppColors.buttonPrimary,
                      foregroundColor: isCurrentPlan
                          ? AppColors.textSecondary
                          : pricing.plan == SubscriptionPlan.free
                              ? AppColors.textPrimary
                              : AppColors.buttonText,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isCurrentPlan
                          ? 'Current Plan'
                          : pricing.plan == SubscriptionPlan.free
                              ? 'Downgrade to Free'
                              : 'Start Free Trial',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
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

/// Full feature comparison table
class _FeatureComparisonTable extends StatelessWidget {
  final List<SubscriptionPricing> plans;

  const _FeatureComparisonTable({required this.plans});

  @override
  Widget build(BuildContext context) {
    final allFeatures = SubscriptionFeatures.getAllFeatures();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feature Comparison',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              // Header row
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 3,
                      child: Text('Feature',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    ...SubscriptionPlan.values.map((plan) => Expanded(
                          child: Text(
                            plan.displayName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        )),
                  ],
                ),
              ),
              // Feature rows
              ...allFeatures.map((feature) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.cardBorder, width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Text(feature.icon, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  feature.name,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...SubscriptionPlan.values.map((plan) => Expanded(
                              child: Icon(
                                feature.isAvailableIn(plan)
                                    ? Icons.check_circle
                                    : Icons.remove_circle_outline,
                                size: 18,
                                color: feature.isAvailableIn(plan)
                                    ? AppColors.success
                                    : AppColors.textHint.withValues(alpha: 0.3),
                              ),
                            )),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}
