import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cykel/core/theme/app_colors.dart';

void main() {
  group('AppColors', () {
    test('primary color is correct', () {
      expect(AppColors.primary, equals(const Color(0xFF6B9080)));
    });

    test('primaryLight color is correct', () {
      expect(AppColors.primaryLight, equals(const Color(0xFF8FAF9E)));
    });

    test('primaryDark color is correct', () {
      expect(AppColors.primaryDark, equals(const Color(0xFF4A7C6B)));
    });

    test('background color is not null', () {
      expect(AppColors.background, isNotNull);
    });

    test('surface color is not null', () {
      expect(AppColors.surface, isNotNull);
    });

    test('textPrimary has high contrast', () {
      // TextPrimary should be dark enough for good contrast
      expect(AppColors.textPrimary.computeLuminance(), lessThan(0.3));
    });

    test('error color is red-ish', () {
      // Error should be in the red range
      expect((AppColors.error.r * 255.0).round().clamp(0, 255), greaterThan(200));
    });

    test('success color is green-ish', () {
      // Success should be in the green range
      expect((AppColors.success.g * 255.0).round().clamp(0, 255), greaterThan(150));
    });

    test('dark theme colors exist', () {
      expect(AppColors.backgroundDark, isNotNull);
      expect(AppColors.surfaceDark, isNotNull);
      expect(AppColors.textPrimaryDark, isNotNull);
    });

    test('dark theme has good contrast', () {
      // Light text on dark background
      expect(AppColors.textPrimaryDark.computeLuminance(), greaterThan(0.7));
      expect(AppColors.backgroundDark.computeLuminance(), lessThan(0.1));
    });
  });
}
