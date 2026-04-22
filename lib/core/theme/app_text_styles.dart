/// CYKEL App Text Styles
/// Uses system-default sans-serif; swap for a custom font later

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // --- Display ---
  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    // color removed - will use theme default
    letterSpacing: -0.5,
    height: 1.2,
  );

  // --- Headline ---
  static const TextStyle headline1 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    // color removed - will use theme default
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    // color removed - will use theme default
    height: 1.3,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    // color removed - will use theme default
    height: 1.4,
  );

  // --- Body ---
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    // color removed - will use theme default
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    // color removed - will use theme default
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    // color removed - will use theme default (or specify via copyWith)
    height: 1.4,
  );

  // --- Label ---
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    // color removed - will use theme default
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    // color removed - will use theme default
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    // color removed - will use theme default
    letterSpacing: 0.5,
  );

  // --- Button ---
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  // --- Caption ---
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    height: 1.4,
  );

  // --- Tab Bar ---
  static const TextStyle tabLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );
}
