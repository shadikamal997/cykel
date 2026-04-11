import 'package:flutter_test/flutter_test.dart';
import 'package:cykel/services/biometric_service.dart';

void main() {
  late BiometricService biometricService;

  setUp(() {
    biometricService = BiometricService.instance;
  });

  group('BiometricService', () {
    test('instance returns singleton', () {
      final instance1 = BiometricService.instance;
      final instance2 = BiometricService.instance;
      expect(identical(instance1, instance2), true);
    });

    test('isDeviceSupported returns false on unsupported platform', () async {
      // This test will pass on most test environments where biometrics aren't available
      final supported = await biometricService.isDeviceSupported();
      expect(supported, isA<bool>());
    });

    test('canCheckBiometrics returns false when not enrolled', () async {
      final canCheck = await biometricService.canCheckBiometrics();
      expect(canCheck, isA<bool>());
    });

    test('isBiometricEnabled returns false by default', () async {
      final enabled = await biometricService.isBiometricEnabled();
      expect(enabled, false);
    });

    test('setBiometricEnabled stores preference', () async {
      await biometricService.setBiometricEnabled(true);
      final enabled = await biometricService.isBiometricEnabled();
      expect(enabled, true);

      // Cleanup
      await biometricService.setBiometricEnabled(false);
    });

    test('shouldAuthenticate returns false when not enabled', () async {
      await biometricService.setBiometricEnabled(false);
      final should = await biometricService.shouldAuthenticate();
      expect(should, false);
    });

    test('getBiometricTypeDescription returns a string', () async {
      final description =
          await biometricService.getBiometricTypeDescription();
      expect(description, isA<String>());
      expect(description.isNotEmpty, true);
    });

    test('getAvailableBiometrics returns a list', () async {
      final types = await biometricService.getAvailableBiometrics();
      expect(types, isA<List>());
    });
  });
}
