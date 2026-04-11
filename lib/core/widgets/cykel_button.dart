/// CYKEL — Shared Button Widget

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum CykelButtonVariant { primary, secondary, outline, ghost, danger }

class CykelButton extends StatelessWidget {
  const CykelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = CykelButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.size = CykelButtonSize.medium,
  });

  final String label;
  final VoidCallback? onPressed;
  final CykelButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final CykelButtonSize size;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, Color? border) = _colors;
    final (height, textStyle, iconSize) = _sizing;

    Widget child = isLoading
        ? SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fg,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: iconSize, color: fg),
                const SizedBox(width: 8),
              ],
              Text(label, style: textStyle.copyWith(color: fg)),
            ],
          );

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: border != null
              ? BorderSide(color: border, width: 1.5)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(child: child),
        ),
      ),
    );
  }

  (Color bg, Color fg, Color? border) get _colors => switch (variant) {
    CykelButtonVariant.primary => (
        AppColors.primary,
        AppColors.textOnPrimary,
        null,
      ),
    CykelButtonVariant.secondary => (
        AppColors.accent,
        AppColors.textOnAccent,
        null,
      ),
    CykelButtonVariant.outline => (
        Colors.transparent,
        AppColors.primary,
        AppColors.primary,
      ),
    CykelButtonVariant.ghost => (
        AppColors.surfaceVariant,
        AppColors.textPrimary,
        null,
      ),
    CykelButtonVariant.danger => (
        AppColors.error,
        Colors.white,
        null,
      ),
  };

  (double height, TextStyle textStyle, double iconSize) get _sizing =>
      switch (size) {
        CykelButtonSize.small => (40.0, AppTextStyles.buttonSmall, 16.0),
        CykelButtonSize.medium => (52.0, AppTextStyles.button, 20.0),
        CykelButtonSize.large => (60.0, AppTextStyles.button, 22.0),
      };
}

enum CykelButtonSize { small, medium, large }
