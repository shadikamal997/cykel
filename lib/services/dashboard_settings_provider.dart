/// CYKEL — Dashboard Settings Provider
/// Controls which sections are visible on the home screen.
/// Persists to SharedPreferences.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardSettings {
  const DashboardSettings({
    this.showMonthlyChallenge = true,
    this.showEbikeRange = true,
    this.showQuickRoutes = true,
    this.showRecentActivity = true,
    this.showMaintenanceReminder = true,
  });

  final bool showMonthlyChallenge;
  final bool showEbikeRange;
  final bool showQuickRoutes;
  final bool showRecentActivity;
  final bool showMaintenanceReminder;

  DashboardSettings copyWith({
    bool? showMonthlyChallenge,
    bool? showEbikeRange,
    bool? showQuickRoutes,
    bool? showRecentActivity,
    bool? showMaintenanceReminder,
  }) =>
      DashboardSettings(
        showMonthlyChallenge: showMonthlyChallenge ?? this.showMonthlyChallenge,
        showEbikeRange: showEbikeRange ?? this.showEbikeRange,
        showQuickRoutes: showQuickRoutes ?? this.showQuickRoutes,
        showRecentActivity: showRecentActivity ?? this.showRecentActivity,
        showMaintenanceReminder: showMaintenanceReminder ?? this.showMaintenanceReminder,
      );

  // ─── Persistence keys ──────────────────────────────────────────────────────
  static const _kMonthlyChallenge = 'dashboard_show_monthly_challenge';
  static const _kEbikeRange = 'dashboard_show_ebike_range';
  static const _kQuickRoutes = 'dashboard_show_quick_routes';
  static const _kRecentActivity = 'dashboard_show_recent_activity';
  static const _kMaintenanceReminder = 'dashboard_show_maintenance_reminder';

  Map<String, bool> toPrefsMap() => {
        _kMonthlyChallenge: showMonthlyChallenge,
        _kEbikeRange: showEbikeRange,
        _kQuickRoutes: showQuickRoutes,
        _kRecentActivity: showRecentActivity,
        _kMaintenanceReminder: showMaintenanceReminder,
      };

  factory DashboardSettings.fromPrefs(SharedPreferences prefs) => DashboardSettings(
        showMonthlyChallenge: prefs.getBool(_kMonthlyChallenge) ?? true,
        showEbikeRange: prefs.getBool(_kEbikeRange) ?? true,
        showQuickRoutes: prefs.getBool(_kQuickRoutes) ?? true,
        showRecentActivity: prefs.getBool(_kRecentActivity) ?? true,
        showMaintenanceReminder: prefs.getBool(_kMaintenanceReminder) ?? true,
      );
}

class DashboardSettingsNotifier extends AsyncNotifier<DashboardSettings> {
  @override
  Future<DashboardSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return DashboardSettings.fromPrefs(prefs);
  }

  Future<void> _save(DashboardSettings s) async {
    state = AsyncData(s);
    final prefs = await SharedPreferences.getInstance();
    for (final entry in s.toPrefsMap().entries) {
      await prefs.setBool(entry.key, entry.value);
    }
  }

  Future<void> setShowMonthlyChallenge(bool show) async {
    final current = state.valueOrNull ?? const DashboardSettings();
    await _save(current.copyWith(showMonthlyChallenge: show));
  }

  Future<void> setShowEbikeRange(bool show) async {
    final current = state.valueOrNull ?? const DashboardSettings();
    await _save(current.copyWith(showEbikeRange: show));
  }

  Future<void> setShowQuickRoutes(bool show) async {
    final current = state.valueOrNull ?? const DashboardSettings();
    await _save(current.copyWith(showQuickRoutes: show));
  }

  Future<void> setShowRecentActivity(bool show) async {
    final current = state.valueOrNull ?? const DashboardSettings();
    await _save(current.copyWith(showRecentActivity: show));
  }

  Future<void> setShowMaintenanceReminder(bool show) async {
    final current = state.valueOrNull ?? const DashboardSettings();
    await _save(current.copyWith(showMaintenanceReminder: show));
  }
}

final dashboardSettingsProvider =
    AsyncNotifierProvider<DashboardSettingsNotifier, DashboardSettings>(
        DashboardSettingsNotifier.new);
