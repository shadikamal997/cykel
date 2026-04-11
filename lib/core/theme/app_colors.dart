/// CYKEL App — Brand Colors
/// 
/// "Premium Nordic Minimal" — Clean, bright Scandinavian design.
/// Pure white background, soft grey cards, muted sage green accent.

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
  Color get primary => _isDark ? AppColors.primaryLight : AppColors.primary;
  Color get cardBackground => _isDark ? AppColors.surfaceDark : AppColors.cardBackground;
  Color get cardBorder => _isDark ? AppColors.borderDark : AppColors.cardBorder;
}

class AppColors {
  AppColors._();

  // ─── Brand ──────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF7F9077); // Muted Sage Green
  static const Color primaryDark  = Color(0xFF5E6F59); // Dark Sage Green (pressed / icons)
  static const Color primaryLight = Color(0xFFA8B5A2); // Light Sage Green (chips / highlights)

  // Secondary / Accent — used for secondary filled buttons & map accents
  static const Color accent       = Color(0xFF5E6F59); // Same as primaryDark
  static const Color accentLight  = Color(0xFF7F9077); // Same as primary
  static const Color accentDark   = Color(0xFF3D4D39); // Even darker sage

  // ─── Background (Premium White) ─────────────────────────────────────────
  static const Color background    = Color(0xFFFFFFFF); // Pure White
  static const Color surface       = Color(0xFFF5F5F5); // Light Grey Card
  static const Color surfaceVariant = Color(0xFFEEEEEE); // Subtle border grey

  // ─── Premium Card Styling ───────────────────────────────────────────────
  static const Color cardBackground = Color(0xFFF5F5F5); // Light grey cards
  static const Color cardBorder     = Color(0xFFE8E8E8); // Subtle border
  static const Color cardAccent     = Color(0xFFF8F8F8); // Even lighter accent

  // ─── Text ──────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1A1A1A); // Near black for high contrast
  static const Color textSecondary = Color(0xFF6B6B6B); // Mid gray
  static const Color textHint      = Color(0xFF9E9E9E); // Placeholder gray
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White on sage green
  static const Color textOnAccent  = Color(0xFFFFFFFF); // White on dark green

  // ─── Button Colors (Premium Dark) ───────────────────────────────────────
  static const Color buttonPrimary   = Color(0xFF1A1A1A); // Near black
  static const Color buttonSecondary = Color(0xFF2D2D2D); // Dark grey
  static const Color buttonText      = Color(0xFFFFFFFF); // White text on buttons

  // ─── Semantic ──────────────────────────────────────────────────────────
  static const Color success      = Color(0xFF4FA36A);
  static const Color successLight = Color(0xFFE8F5EC);
  static const Color warning      = Color(0xFFE3B341);
  static const Color warningLight = Color(0xFFFDF6E3);
  static const Color error        = Color(0xFFD65C5C);
  static const Color errorLight   = Color(0xFFFDF0F0);
  static const Color info         = Color(0xFF5B8DB8);
  static const Color infoLight    = Color(0xFFEDF4F9);

  // ─── Ride Condition Colors ──────────────────────────────────────────────────
  static const Color conditionExcellent = Color(0xFF4FA36A); // Score 9–10
  static const Color conditionGood      = Color(0xFF7F9077); // Score 7–8
  static const Color conditionFair      = Color(0xFFE3B341); // Score 5–6
  static const Color conditionPoor      = Color(0xFFD65C5C); // Score 1–4

  // ─── Map Layer Colors ───────────────────────────────────────────────────────
  static const Color layerCharging = Color(0xFF4FA36A);
  static const Color layerService  = Color(0xFF5B8DB8);
  static const Color layerShop     = Color(0xFF9B7DB8);
  static const Color layerRental   = Color(0xFF7F9077);

  // ─── Border / Divider ───────────────────────────────────────────────────────
  static const Color border  = Color(0xFFE8E8E8);
  static const Color divider = Color(0xFFF0F0F0);

  // ─── Dark Mode Colors ──────────────────────────────────────────────────────
  static const Color backgroundDark       = Color(0xFF1A1E18); // Dark sage background
  static const Color surfaceDark          = Color(0xFF252B22); // Elevated surface
  static const Color surfaceVariantDark   = Color(0xFF2F362A); // Slightly lighter

  static const Color textPrimaryDark      = Color(0xFFE8EBE6); // Off-white
  static const Color textSecondaryDark    = Color(0xFFA8B5A2); // Sage-tinted gray
  static const Color textHintDark         = Color(0xFF6B7766); // Darker gray

  static const Color borderDark           = Color(0xFF3D4D39); // Sage-tinted border
  static const Color dividerDark          = Color(0xFF3D4D39);
}
