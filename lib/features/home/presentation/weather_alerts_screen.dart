/// CYKEL — Weather Alerts Screen
/// Full-screen view of all weather and riding condition alerts

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/weather_alerts_provider.dart';

class WeatherAlertsScreen extends ConsumerWidget {
  const WeatherAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final alertsAsync = ref.watch(weatherAlertsProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(l10n.weatherAlerts),
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
      ),
      body: alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 64, color: context.colors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  l10n.genericError(e.toString()),
                  style: AppTextStyles.bodyMedium.copyWith(color: context.colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (alerts) {
          if (alerts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.wb_sunny_rounded,
                        size: 64,
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.noWeatherAlerts,
                      style: AppTextStyles.headline3,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.conditionsGoodForCycling,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.colors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              final localized = alert.localized(context);
              return _AlertCard(
                alert: alert,
                title: localized.title,
                message: localized.message,
              );
            },
          );
        },
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.title,
    required this.message,
  });

  final WeatherAlert alert;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.border,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getSeverityColor(alert.severity).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getAlertIcon(alert.type),
                size: 24,
                color: _getSeverityColor(alert.severity),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(alert.severity).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getSeverityLabel(context, alert.severity),
                      style: AppTextStyles.caption.copyWith(
                        color: _getSeverityColor(alert.severity),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
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

  IconData _getAlertIcon(WeatherAlertType type) {
    return switch (type) {
      WeatherAlertType.heavyRain => Icons.water_drop_rounded,
      WeatherAlertType.strongWind => Icons.air_rounded,
      WeatherAlertType.iceRisk => Icons.ac_unit_rounded,
      WeatherAlertType.extremeCold => Icons.severe_cold_rounded,
      WeatherAlertType.highWinds => Icons.wind_power_rounded,
      WeatherAlertType.fog => Icons.cloud_rounded,
      WeatherAlertType.darkness => Icons.nightlight_rounded,
      WeatherAlertType.sunsetApproaching => Icons.wb_twilight_rounded,
      WeatherAlertType.winterIce => Icons.severe_cold_rounded,
    };
  }

  Color _getSeverityColor(AlertSeverity severity) {
    return switch (severity) {
      AlertSeverity.low => AppColors.info,
      AlertSeverity.medium => AppColors.warning,
      AlertSeverity.high => AppColors.error,
    };
  }

  String _getSeverityLabel(BuildContext context, AlertSeverity severity) {
    return switch (severity) {
      AlertSeverity.low => context.l10n.lowSeverity,
      AlertSeverity.medium => context.l10n.mediumSeverity,
      AlertSeverity.high => context.l10n.highSeverity,
    };
  }
}
