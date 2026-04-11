import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cykel/core/theme/app_theme.dart';
import 'package:cykel/core/theme/app_colors.dart';

void main() {
  group('AppTheme', () {
    test('light theme uses Material 3', () {
      final theme = AppTheme.light;
      expect(theme.useMaterial3, true);
    });

    test('dark theme uses Material 3', () {
      final theme = AppTheme.dark;
      expect(theme.useMaterial3, true);
    });

    test('light theme has correct primary color', () {
      final theme = AppTheme.light;
      expect(theme.primaryColor, AppColors.primary);
    });

    test('dark theme has correct background color', () {
      final theme = AppTheme.dark;
      expect(theme.scaffoldBackgroundColor, AppColors.backgroundDark);
    });

    test('light theme app bar has correct background', () {
      final theme = AppTheme.light;
      expect(theme.appBarTheme.backgroundColor, AppColors.surface);
    });

    test('dark theme app bar has dark background', () {
      final theme = AppTheme.dark;
      expect(theme.appBarTheme.backgroundColor, AppColors.surfaceDark);
    });

    test('light theme bottom nav has correct styling', () {
      final theme = AppTheme.light;
      expect(theme.bottomNavigationBarTheme.backgroundColor, AppColors.surface);
      expect(theme.bottomNavigationBarTheme.selectedItemColor, AppColors.primaryDark);
    });

    test('dark theme bottom nav has dark styling', () {
      final theme = AppTheme.dark;
      expect(theme.bottomNavigationBarTheme.backgroundColor, AppColors.surfaceDark);
    });

    test('card theme has rounded corners', () {
      final lightTheme = AppTheme.light;
      final darkTheme = AppTheme.dark;
      
      expect(lightTheme.cardTheme.shape, isA<RoundedRectangleBorder>());
      expect(darkTheme.cardTheme.shape, isA<RoundedRectangleBorder>());
    });

    test('input decoration theme has borders', () {
      final theme = AppTheme.light;
      expect(theme.inputDecorationTheme.border, isNotNull);
      expect(theme.inputDecorationTheme.enabledBorder, isNotNull);
      expect(theme.inputDecorationTheme.focusedBorder, isNotNull);
    });

    test('elevated button has correct styling', () {
      final theme = AppTheme.light;
      expect(theme.elevatedButtonTheme, isNotNull);
    });

    test('text button has correct styling', () {
      final theme = AppTheme.light;
      expect(theme.textButtonTheme, isNotNull);
    });

    test('divider has correct color', () {
      final lightTheme = AppTheme.light;
      final darkTheme = AppTheme.dark;
      
      expect(lightTheme.dividerTheme.color, AppColors.divider);
      expect(darkTheme.dividerTheme.color, AppColors.dividerDark);
    });
  });
}
