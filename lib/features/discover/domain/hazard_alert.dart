/// CYKEL — Hazard Alert domain model

/// Types of cycling hazard that CYKEL can detect from weather API data.
enum HazardType {
  /// Road/path surfaces likely icy (temp ≤ 2 °C + precipitation).
  ice,

  /// Air temperature below freezing — general cold hazard.
  freeze,

  /// Wind speed above danger threshold for cyclists (≥ 45 km/h).
  strongWind,

  /// Heavy rain reducing visibility and grip (≥ 3 mm/h).
  heavyRain,

  /// Light precipitation combined with near-zero temp — wet/slippery.
  wetSurface,

  /// Active snowfall.
  snow,

  /// Fog — visibility below 1 000 m.
  fog,

  /// Very low visibility (< 200 m) — extreme caution required.
  lowVisibility,

  /// Riding after local sunset or before sunrise — use lights.
  darkness,
}

class HazardAlert {
  const HazardAlert({
    required this.type,
    required this.severity, // 0.0 = advisory, 1.0 = severe
  });

  final HazardType type;

  /// Normalised severity 0–1 (0 = advisory, 1 = severe).
  final double severity;

  bool get isWarning => severity >= 0.5;
}
