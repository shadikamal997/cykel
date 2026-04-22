/// CYKEL App — Brand Colors
/// 
/// "Emerald Green Design System" — Modern, vibrant design with comprehensive light/dark mode support.
/// Based on CSS design tokens with bright emerald green primary color.

import 'package:flutter/material.dart';

/// Theme-aware color extension for BuildContext
/// Use context.colors.background instead of AppColors.background
extension ThemeAwareColors on BuildContext {
  ThemeColors get colors => ThemeColors(this);
}

/// Theme-aware color resolver
class ThemeColors {
  ThemeColors(this._context);
  final BuildContext _context;

  bool get _isDark => Theme.of(_context).brightness == Brightness.dark;

  Color get background => _isDark ? AppColors.backgroundDark : AppColors.background;
  Color get surface => _isDark ? AppColors.surfaceDark : AppColors.surface;
  Color get surfaceVariant => _isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
  Color get textPrimary => _isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
  Color get textSecondary => _isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
  Color get textHint => _isDark ? AppColors.textHintDark : AppColors.textHint;
  Color get border => _isDark ? AppColors.borderDark : AppColors.border;
  Color get divider => _isDark ? AppColors.dividerDark : AppColors.divider;
  Color get primary => _isDark ? AppColors.primaryDark : AppColors.primary;
  Color get primaryForeground => _isDark ? AppColors.primaryForegroundDark : AppColors.primaryForeground;
  Color get cardBackground => _isDark ? AppColors.cardDark : AppColors.cardBackground;
  Color get cardBorder => _isDark ? AppColors.borderDark : AppColors.cardBorder;
  Color get ring => _isDark ? AppColors.ringDark : AppColors.ring;
  Color get destructive => _isDark ? AppColors.destructiveDark : AppColors.destructive;
  Color get muted => _isDark ? AppColors.mutedDark : AppColors.muted;
  Color get mutedForeground => _isDark ? AppColors.mutedForegroundDark : AppColors.mutedForeground;
  Color get accent => _isDark ? AppColors.accentDark : AppColors.accent;
}

class AppColors {
  AppColors._();

  // ─── Primary Colors (Emerald Green) ─────────────────────────────────────
  static const Color primary              = Color(0xFF72E3AD); // Bright emerald green (light mode)
  static const Color primaryForeground    = Color(0xFF001F10); // Text on primary (light)
  static const Color primaryDark          = Color(0xFF006239); // Primary color in dark mode
  static const Color primaryForegroundDark = Color(0xFFA9F6CC); // Text on primary (dark)
  static const Color primaryLight         = Color(0xFF72E3AD); // Alias for compatibility

  // ─── Background ─────────────────────────────────────────────────────────
  static const Color background     = Color(0xFFFCFCFC); // Almost white (light)
  static const Color foreground     = Color(0xFF171717); // Main text color (light)
  static const Color backgroundDark = Color(0xFF121212); // True dark background (dark)
  static const Color foregroundDark = Color(0xFFE2E8F0); // Main text color (dark)

  // ─── Card / Surface ─────────────────────────────────────────────────────
  static const Color cardBackground = Color(0xFFFCFCFC); // Card background (light)
  static const Color cardForeground = Color(0xFF171717); // Card text (light)
  static const Color surface        = Color(0xFFFCFCFC); // Surface (light)
  static const Color cardDark       = Color(0xFF171717); // Card background (dark)
  static const Color cardForegroundDark = Color(0xFFE2E8F0); // Card text (dark)
  static const Color surfaceDark    = Color(0xFF171717); // Surface (dark)
  static const Color cardBorder     = Color(0xFFDFDFDF); // Card border (light)
  static const Color cardAccent     = Color(0xFFFCFCFC); // Card accent (light)

  // ─── Popover ─────────────────────────────────────────────────────────────
  static const Color popover            = Color(0xFFFCFCFC); // Popover background (light)
  static const Color popoverForeground  = Color(0xFF171717); // Popover text (light)
  static const Color popoverDark        = Color(0xFF171717); // Popover background (dark)
  static const Color popoverForegroundDark = Color(0xFFE2E8F0); // Popover text (dark)

  // ─── Secondary ──────────────────────────────────────────────────────────
  static const Color secondary            = Color(0xFFEDEDED); // Secondary (light)
  static const Color secondaryForeground  = Color(0xFF171717); // Text on secondary (light)
  static const Color secondaryDark        = Color(0xFF1F1F1F); // Secondary (dark)
  static const Color secondaryForegroundDark = Color(0xFFE2E8F0); // Text on secondary (dark)

  // ─── Muted ──────────────────────────────────────────────────────────────
  static const Color muted            = Color(0xFFEDEDED); // Muted background (light)
  static const Color mutedForeground  = Color(0xFF545454); // Muted text (light)
  static const Color mutedDark        = Color(0xFF1F1F1F); // Muted background (dark)
  static const Color mutedForegroundDark = Color(0xFF9A9A9A); // Muted text (dark)
  static const Color surfaceVariant   = Color(0xFFEDEDED); // Alias for muted
  static const Color surfaceVariantDark = Color(0xFF1F1F1F); // Alias for mutedDark

  // ─── Accent ─────────────────────────────────────────────────────────────
  static const Color accent            = Color(0xFFEDEDED); // Accent (light)
  static const Color accentForeground  = Color(0xFF171717); // Text on accent (light)
  static const Color accentDark        = Color(0xFF313131); // Accent (dark)
  static const Color accentForegroundDark = Color(0xFFE2E8F0); // Text on accent (dark)
  static const Color accentLight       = Color(0xFFEDEDED); // Alias for compatibility

  // ─── Destructive / Error ────────────────────────────────────────────────
  static const Color destructive            = Color(0xFFCA3214); // Destructive (light)
  static const Color destructiveForeground  = Color(0xFFFEE9E6); // Text on destructive (light)
  static const Color destructiveDark        = Color(0xFF541C15); // Destructive (dark)
  static const Color error                  = Color(0xFFCA3214); // Error alias
  static const Color errorLight             = Color(0xFFFEE9E6); // Light error background

  // ─── Border / Input ─────────────────────────────────────────────────────
  static const Color border      = Color(0xFFDFDFDF); // Border (light)
  static const Color input       = Color(0xFFDFDFDF); // Input border (light)
  static const Color borderDark  = Color(0xFF292929); // Border (dark)
  static const Color inputDark   = Color(0xFF292929); // Input border (dark)
  static const Color divider     = Color(0xFFDFDFDF); // Divider (light)
  static const Color dividerDark = Color(0xFF292929); // Divider (dark)

  // ─── Ring (Focus) ───────────────────────────────────────────────────────
  static const Color ring     = Color(0xFF72E3AD); // Focus ring (light)
  static const Color ringDark = Color(0xFF4ADE80); // Focus ring (dark)

  // ─── Semantic Colors ────────────────────────────────────────────────────
  static const Color success      = Color(0xFF72E3AD); // Success (use primary emerald)
  static const Color successLight = Color(0xFFE8F5EC); // Light success background
  static const Color warning      = Color(0xFFF59E0B); // Warning (amber)
  static const Color warningLight = Color(0xFFFDF6E3); // Light warning background
  static const Color info         = Color(0xFF3B82F6); // Info (blue)
  static const Color infoLight    = Color(0xFFEDF4F9); // Light info background

  // ─── Text Colors (Legacy Compatibility) ────────────────────────────────
  static const Color textPrimary      = foreground;       // #171717 (light)
  static const Color textSecondary    = mutedForeground;  // #545454 (light)
  static const Color textHint         = mutedForeground;  // #545454 (light)
  static const Color textOnPrimary    = primaryForeground; // #001F10 (light)
  static const Color textOnAccent     = accentForeground; // #171717 (light)
  
  static const Color textPrimaryDark   = foregroundDark;       // #E2E8F0 (dark)
  static const Color textSecondaryDark = mutedForegroundDark;  // #9A9A9A (dark)
  static const Color textHintDark      = mutedForegroundDark;  // #9A9A9A (dark)

  // ─── Button Colors ──────────────────────────────────────────────────────
  static const Color buttonPrimary   = primary;    // Emerald green
  static const Color buttonSecondary = secondary;  // Light gray
  static const Color buttonText      = primaryForeground; // Dark text on emerald

  // ─── Ride Condition Colors ──────────────────────────────────────────────
  static const Color conditionExcellent = Color(0xFF72E3AD); // Score 9–10 (emerald)
  static const Color conditionGood      = Color(0xFF4ADE80); // Score 7–8 (green)
  static const Color conditionFair      = Color(0xFFF59E0B); // Score 5–6 (amber)
  static const Color conditionPoor      = Color(0xFFCA3214); // Score 1–4 (red)

  // ─── Map Layer Colors ───────────────────────────────────────────────────
  static const Color layerCharging = Color(0xFF72E3AD); // Emerald
  static const Color layerService  = Color(0xFF3B82F6); // Blue
  static const Color layerShop     = Color(0xFF9B7DB8); // Purple
  static const Color layerRental   = Color(0xFF4ADE80); // Green

  // ─── Other ──────────────────────────────────────────────────────────────
  static const Color shadow = Color(0xFFE8E8E8); // Shadow color
}
