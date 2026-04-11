import 'package:flutter_test/flutter_test.dart';
import 'package:cykel/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('googleMapsApiKey returns empty string when not provided', () {
      expect(AppConfig.googleMapsApiKey, isEmpty);
    });

    test('isValid returns false when API key is empty', () {
      expect(AppConfig.isValid, false);
    });

    test('validate throws exception when API key is empty', () {
      expect(
        () => AppConfig.validate(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
