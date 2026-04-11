/// CYKEL — Ride Condition Score (Phase 8)
/// Extracted domain model so the score algorithm is testable and reusable.
///
/// Inputs: weather data, optional sunrise/sunset, optional daylight info.
/// Outputs: score 1-10, label, color tier, list of active warnings.

import '../../../services/weather_service.dart';

// ─── Condition Tier ──────────────────────────────────────────────────────────

enum ConditionTier { excellent, good, fair, poor }

// ─── Warning Tag ─────────────────────────────────────────────────────────────

enum ConditionWarning {
  rain,
  heavyRain,
  strongWind,
  cold,
  iceRisk,
  fog,
  snow,
  thunderstorm,
  darkRiding,
  lowVisibility,
  cachedData,
}

// ─── Ride Condition Score ────────────────────────────────────────────────────

class RideCondition {
  const RideCondition({
    required this.score,
    required this.tier,
    required this.warnings,
  });

  /// Score from 1 (worst) to 10 (best).
  final int score;

  /// Human-readable tier derived from score.
  final ConditionTier tier;

  /// Active warnings for the user.
  final List<ConditionWarning> warnings;

  /// Compute the ride condition from current weather.
  ///
  /// [isDark] — true if the ride would happen after sunset / before sunrise.
  factory RideCondition.fromWeather(
    WeatherData weather, {
    bool isDark = false,
  }) {
    int s = 10;
    final w = <ConditionWarning>[];

    // ── Precipitation ────────────────────────────────────────────────────
    if (weather.precipitationMm > 0) {
      s -= 2;
      w.add(ConditionWarning.rain);
    }
    if (weather.precipitationMm > 2) {
      s -= 1;
      w.add(ConditionWarning.heavyRain);
    }

    // ── Wind ─────────────────────────────────────────────────────────────
    if (weather.isWindy) {
      s -= 2;
      w.add(ConditionWarning.strongWind);
    }

    // ── Cold ─────────────────────────────────────────────────────────────
    if (weather.isCold) {
      s -= 1;
      w.add(ConditionWarning.cold);
    }

    // ── Ice Risk ─────────────────────────────────────────────────────────
    if (weather.isIceRisk) {
      s -= 2;
      w.add(ConditionWarning.iceRisk);
    }

    // ── WMO code penalties ───────────────────────────────────────────────
    final code = weather.weatherCode;
    if (code == 45 || code == 48) {
      // Fog / rime fog
      s -= 1;
      w.add(ConditionWarning.fog);
    }
    if ((code >= 71 && code <= 77) || code == 85 || code == 86) {
      // Snow / snow showers
      s -= 2;
      w.add(ConditionWarning.snow);
    }
    if (code == 95 || code == 96 || code == 99) {
      // Thunderstorm
      s -= 3;
      w.add(ConditionWarning.thunderstorm);
    }

    // ── Dark / visibility ────────────────────────────────────────────────
    if (isDark) {
      s -= 1;
      w.add(ConditionWarning.darkRiding);
    }
    if (weather.isLowVisibility) {
      s -= 1;
      w.add(ConditionWarning.lowVisibility);
    }

    // ── Fallback data marker ─────────────────────────────────────────────
    if (weather.isFallback) {
      w.add(ConditionWarning.cachedData);
    }

    s = s.clamp(1, 10);
    final tier = s >= 9
        ? ConditionTier.excellent
        : s >= 7
            ? ConditionTier.good
            : s >= 5
                ? ConditionTier.fair
                : ConditionTier.poor;

    return RideCondition(score: s, tier: tier, warnings: w);
  }
}
