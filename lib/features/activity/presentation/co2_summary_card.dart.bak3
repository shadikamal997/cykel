/// CYKEL — CO₂ & Climate Impact summary card (Phase 1-CO2)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/l10n/l10n.dart';
import '../data/co2_provider.dart';

class Co2SummaryCard extends ConsumerWidget {
  const Co2SummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final statsAsync = ref.watch(co2StatsProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B7A3F), Color(0xFF27AE60)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF27AE60).withValues(alpha: 0.30),
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
              const Text('🌱', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                l10n.co2ImpactTitle,
                style: AppTextStyles.headline3.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 14),
          statsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            error: (err, stack) => const SizedBox.shrink(),
            data: (stats) => Column(
              children: [
                Row(
                  children: [
                    _ImpactColumn(
                      emoji: '♻️',
                      value: stats.totalCo2SavedKg >= 1
                          ? '${stats.totalCo2SavedKg.toStringAsFixed(2)} kg'
                          : '${(stats.totalCo2SavedKg * 1000).round()} g',
                      label: l10n.co2Saved,
                    ),
                    _Divider(),
                    _ImpactColumn(
                      emoji: '⛽',
                      value: '${stats.totalFuelSavedLiters.toStringAsFixed(1)} L',
                      label: l10n.fuelSaved,
                    ),
                    _Divider(),
                    _ImpactColumn(
                      emoji: '🔥',
                      value: '${stats.totalCaloriesBurned} kcal',
                      label: l10n.caloriesBurned,
                    ),
                  ],
                ),
                if (stats.totalFuelSavedDkk > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('💰', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          l10n.fuelSavingsAmount(stats.fuelSavedDkkLabel),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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

class _ImpactColumn extends StatelessWidget {
  const _ImpactColumn({
    required this.emoji,
    required this.value,
    required this.label,
  });
  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyles.headline3.copyWith(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.80),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 48,
        color: Colors.white.withValues(alpha: 0.25),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );
}
