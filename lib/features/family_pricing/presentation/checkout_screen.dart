import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../application/family_pricing_providers.dart';
import '../domain/subscription.dart';

/// Checkout screen for subscription purchase
class CheckoutScreen extends ConsumerStatefulWidget {
  final SubscriptionPricing pricing;
  final BillingPeriod billingPeriod;

  const CheckoutScreen({
    super.key,
    required this.pricing,
    required this.billingPeriod,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _startTrial = true;

  @override
  Widget build(BuildContext context) {
    final isProcessing = ref.watch(isProcessingPaymentProvider);
    final error = ref.watch(paymentErrorProvider);
    final savedMethods = ref.watch(savedPaymentMethodsProvider);
    final defaultMethod = ref.watch(defaultPaymentMethodProvider);
    final price = widget.pricing.getPriceForPeriod(widget.billingPeriod);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order summary
            _OrderSummaryCard(
              pricing: widget.pricing,
              billingPeriod: widget.billingPeriod,
              price: price,
            ),
            const SizedBox(height: 20),

            // Trial toggle
            if (widget.pricing.plan != SubscriptionPlan.free)
              _TrialToggle(
                startTrial: _startTrial,
                onChanged: (value) => setState(() => _startTrial = value),
              ),
            const SizedBox(height: 20),

            // Payment method
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            savedMethods.when(
              data: (methods) {
                if (methods.isEmpty) {
                  return _AddPaymentMethodCard(
                    onTap: () => _showAddPaymentDialog(context),
                  );
                }
                return Column(
                  children: [
                    ...methods.map((method) => _PaymentMethodTile(
                          method: method,
                          isSelected: method.id == defaultMethod?.id,
                          onSelect: () => _selectPaymentMethod(method.id),
                        )),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _showAddPaymentDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Payment Method'),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Text('Could not load payment methods'),
            ),
            const SizedBox(height: 24),

            // Error message
            if (error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(error,
                          style: const TextStyle(color: AppColors.error, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Subscribe button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isProcessing ? null : () => _subscribe(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  foregroundColor: AppColors.buttonText,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _startTrial
                            ? 'Start 14-Day Free Trial'
                            : 'Subscribe for ${price.toStringAsFixed(0)} DKK',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Terms
            Text(
              _startTrial
                  ? 'You won\'t be charged until after your 14-day trial. Cancel anytime.'
                  : 'By subscribing, you agree to our terms. Cancel anytime.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _subscribe(BuildContext context, WidgetRef ref) async {
    ref.read(paymentErrorProvider.notifier).state = null;
    ref.read(isProcessingPaymentProvider.notifier).state = true;

    try {
      final service = ref.read(familyPricingServiceProvider);
      final price = widget.pricing.getPriceForPeriod(widget.billingPeriod);

      await service.createSubscription(
        plan: widget.pricing.plan,
        billingPeriod: widget.billingPeriod,
        amount: price,
        startTrial: _startTrial,
      );

      ref.read(isProcessingPaymentProvider.notifier).state = false;

      if (context.mounted) {
        _showSuccessDialog(context);
      }
    } catch (e) {
      ref.read(isProcessingPaymentProvider.notifier).state = false;
      ref.read(paymentErrorProvider.notifier).state = e.toString();
    }
  }

  void _selectPaymentMethod(String methodId) {
    final service = ref.read(familyPricingServiceProvider);
    service.setDefaultPaymentMethod(methodId);
  }

  void _showAddPaymentDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddPaymentMethodSheet(),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _startTrial ? 'Trial Started!' : 'Subscription Active!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _startTrial
                  ? 'Your 14-day free trial of ${widget.pricing.plan.displayName} has started. Enjoy all the features!'
                  : 'Welcome to ${widget.pricing.plan.displayName}! Your subscription is now active.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to plans
                  Navigator.of(context).pop(); // Go back to settings/home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  foregroundColor: AppColors.buttonText,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Get Started'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Order summary card
class _OrderSummaryCard extends StatelessWidget {
  final SubscriptionPricing pricing;
  final BillingPeriod billingPeriod;
  final double price;

  const _OrderSummaryCard({
    required this.pricing,
    required this.billingPeriod,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${pricing.plan.displayName} Plan',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                '${pricing.monthlyPrice.toStringAsFixed(0)} DKK/mo',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Billing: ${billingPeriod.displayName}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              if (billingPeriod != BillingPeriod.monthly)
                Text(
                  '-${((1 - billingPeriod.discountMultiplier) * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${price.toStringAsFixed(0)} DKK',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Trial toggle
class _TrialToggle extends StatelessWidget {
  final bool startTrial;
  final ValueChanged<bool> onChanged;

  const _TrialToggle({
    required this.startTrial,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: startTrial ? AppColors.successLight : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: startTrial ? AppColors.success.withValues(alpha: 0.3) : AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(
            startTrial ? Icons.card_giftcard : Icons.payment,
            color: startTrial ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  startTrial ? '14-Day Free Trial' : 'Pay Now',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color:
                        startTrial ? AppColors.success : AppColors.textPrimary,
                  ),
                ),
                Text(
                  startTrial
                      ? 'Try all features free for 14 days'
                      : 'Start your subscription immediately',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: startTrial,
            onChanged: onChanged,
            activeTrackColor: AppColors.success,
          ),
        ],
      ),
    );
  }
}

/// Payment method selection tile
class _PaymentMethodTile extends StatelessWidget {
  final SavedPaymentMethod method;
  final bool isSelected;
  final VoidCallback onSelect;

  const _PaymentMethodTile({
    required this.method,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getIconForMethod(method.type),
              color:
                  isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (method.expiryMonth != null && method.expiryYear != null)
                    Text(
                      'Expires ${method.expiryMonth!.toString().padLeft(2, '0')}/${method.expiryYear}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: method.isExpired
                                ? AppColors.error
                                : AppColors.textHint,
                          ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  IconData _getIconForMethod(PaymentMethod type) {
    switch (type) {
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.mobilePay:
        return Icons.phone_android;
      case PaymentMethod.applePay:
        return Icons.apple;
      case PaymentMethod.googlePay:
        return Icons.g_mobiledata;
      case PaymentMethod.paypal:
        return Icons.account_balance_wallet;
    }
  }
}

/// Add payment method card
class _AddPaymentMethodCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPaymentMethodCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            const Icon(Icons.add_circle_outline,
                size: 40, color: AppColors.textHint),
            const SizedBox(height: 8),
            Text(
              'Add Payment Method',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Credit card, MobilePay, Apple Pay',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for adding a payment method
class _AddPaymentMethodSheet extends ConsumerWidget {
  const _AddPaymentMethodSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add Payment Method',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          ...PaymentMethod.values.map((method) => ListTile(
                leading: Icon(_getIconForMethod(method)),
                title: Text(method.displayName),
                trailing: const Icon(Icons.chevron_right),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Integrate with actual payment provider
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${method.displayName} integration coming soon'),
                    ),
                  );
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  IconData _getIconForMethod(PaymentMethod type) {
    switch (type) {
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.mobilePay:
        return Icons.phone_android;
      case PaymentMethod.applePay:
        return Icons.apple;
      case PaymentMethod.googlePay:
        return Icons.g_mobiledata;
      case PaymentMethod.paypal:
        return Icons.account_balance_wallet;
    }
  }
}
