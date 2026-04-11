/// CYKEL — Weather Alerts Provider
/// Monitors weather conditions and generates alerts for severe conditions.
/// Phase 8.5: added darkness and seasonal alerts.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/weather_service.dart';
import '../../../services/daylight_service.dart';
import '../../../core/l10n/l10n.dart';
import '../../home/data/weather_provider.dart';

/// Weather alerts for severe conditions - returns raw alert data
/// Use WeatherAlert.localized() or weatherAlertsProvider.localize() in UI
final weatherAlertsProvider = FutureProvider<List<WeatherAlert>>((ref) async {
  final weatherAsync = await ref.watch(homeWeatherProvider.future);
  final daylightAsync = ref.watch(daylightInfoProvider);
  final daylight = await daylightAsync.when(
    data: (d) => Future.value(d),
    loading: () => Future.value(ref.read(daylightServiceProvider).calculate(
      latitude: 55.6761,
      longitude: 12.5683,
    )),
    error: (_, _) => Future.value(ref.read(daylightServiceProvider).calculate(
      latitude: 55.6761,
      longitude: 12.5683,
    )),
  );
  return _generateAlerts(weatherAsync, daylight);
});

/// Weather alert with raw data - call localized() to get title/message
class WeatherAlert {
  const WeatherAlert({
    required this.type,
    required this.severity,
    this.value,
    this.extraValue,
  });

  final WeatherAlertType type;
  final AlertSeverity severity;
  /// Optional value (temperature, wind speed, etc.)
  final String? value;
  /// Optional extra value (e.g., sunset time)
  final String? extraValue;

  /// Get localized title and message for display
  LocalizedAlert localized(BuildContext context) {
    final l10n = context.l10n;
    return switch (type) {
      WeatherAlertType.heavyRain => LocalizedAlert(
          title: l10n.alertHeavyRainTitle,
          message: l10n.alertHeavyRainMessage(value ?? ''),
        ),
      WeatherAlertType.strongWind => LocalizedAlert(
          title: l10n.alertStrongWindTitle,
          message: l10n.alertStrongWindMessage(value ?? ''),
        ),
      WeatherAlertType.iceRisk => LocalizedAlert(
          title: l10n.alertIceRiskTitle,
          message: l10n.alertIceRiskMessage,
        ),
      WeatherAlertType.extremeCold => LocalizedAlert(
          title: l10n.alertExtremeColdTitle,
          message: l10n.alertExtremeColdMessage(value ?? ''),
        ),
      WeatherAlertType.highWinds => LocalizedAlert(
          title: l10n.alertHighWindsTitle,
          message: l10n.alertHighWindsMessage(value ?? ''),
        ),
      WeatherAlertType.fog => LocalizedAlert(
          title: l10n.alertFogTitle,
          message: l10n.alertFogMessage,
        ),
      WeatherAlertType.darkness => LocalizedAlert(
          title: l10n.alertDarknessTitle,
          message: l10n.alertDarknessMessage,
        ),
      WeatherAlertType.sunsetApproaching => LocalizedAlert(
          title: l10n.alertSunsetTitle,
          message: l10n.alertSunsetMessage(extraValue ?? ''),
        ),
      WeatherAlertType.winterIce => LocalizedAlert(
          title: l10n.alertWinterIceTitle,
          message: l10n.alertWinterIceMessage,
        ),
    };
  }
}

/// Localized alert ready for display
class LocalizedAlert {
  const LocalizedAlert({required this.title, required this.message});
  final String title;
  final String message;
}

enum WeatherAlertType {
  heavyRain,
  strongWind,
  iceRisk,
  extremeCold,
  highWinds,
  fog,
  darkness,
  sunsetApproaching,
  winterIce,
}

enum AlertSeverity { low, medium, high }

List<WeatherAlert> _generateAlerts(WeatherData weather, DaylightInfo daylight) {
  final alerts = <WeatherAlert>[];

  // Heavy rain alert (>5mm/h)
  if (weather.precipitationMm > 5) {
    alerts.add(WeatherAlert(
      type: WeatherAlertType.heavyRain,
      value: weather.precipitationMm.toStringAsFixed(1),
      severity: AlertSeverity.medium,
    ));
  }

  // Strong wind alert (>20 km/h sustained)
  if (weather.windSpeedMs > 5.5) {
    alerts.add(WeatherAlert(
      type: WeatherAlertType.strongWind,
      value: (weather.windSpeedMs * 3.6).round().toString(),
      severity: AlertSeverity.medium,
    ));
  }

  // Ice risk alert (< -2°C)
  if (weather.temperatureC < -2 && weather.precipitationMm > 0) {
    alerts.add(const WeatherAlert(
      type: WeatherAlertType.iceRisk,
      severity: AlertSeverity.high,
    ));
  }

  // Extreme cold alert (< -5°C)
  if (weather.temperatureC < -5) {
    alerts.add(WeatherAlert(
      type: WeatherAlertType.extremeCold,
      value: weather.temperatureC.round().toString(),
      severity: AlertSeverity.high,
    ));
  }

  // Very high winds (>30 km/h)
  if (weather.windSpeedMs > 8.3) {
    alerts.add(WeatherAlert(
      type: WeatherAlertType.highWinds,
      value: (weather.windSpeedMs * 3.6).round().toString(),
      severity: AlertSeverity.high,
    ));
  }

  // Fog: WMO codes 45 = fog, 48 = rime fog
  if (weather.weatherCode == 45 || weather.weatherCode == 48) {
    alerts.add(const WeatherAlert(
      type: WeatherAlertType.fog,
      severity: AlertSeverity.medium,
    ));
  }

  // ── Seasonal / daylight alerts (Phase 8.5) ──────────────────────────────
  if (daylight.isDark) {
    alerts.add(const WeatherAlert(
      type: WeatherAlertType.darkness,
      severity: AlertSeverity.medium,
    ));
  } else if (daylight.isDarkSoon) {
    final time = '${daylight.sunset.hour.toString().padLeft(2, '0')}:${daylight.sunset.minute.toString().padLeft(2, '0')}';
    alerts.add(WeatherAlert(
      type: WeatherAlertType.sunsetApproaching,
      extraValue: time,
      severity: AlertSeverity.low,
    ));
  }

  // Winter mode: ice risk on bridges and exposed areas when near 0°C
  if (weather.temperatureC >= -1 && weather.temperatureC <= 3 && weather.precipitationMm > 0) {
    alerts.add(const WeatherAlert(
      type: WeatherAlertType.winterIce,
      severity: AlertSeverity.high,
    ));
  }

  return alerts;
}