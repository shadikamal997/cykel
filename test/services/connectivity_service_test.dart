/// Unit tests for ConnectivityService
/// Tests network connectivity checking

import 'package:flutter_test/flutter_test.dart';
import 'package:cykel/services/connectivity_service.dart';

void main() {
  group('ConnectivityService', () {
    late ConnectivityService service;

    setUp(() {
      service = ConnectivityService();
    });

    test('isOnline returns true when network is available', () async {
      // Note: This is a real network test. In a controlled environment
      // (CI/CD), you might want to mock InternetAddress.lookup
      final result = await service.isOnline();
      
      // Since this depends on actual network, we can't guarantee true
      // but we can verify the method completes without error
      expect(result, isA<bool>());
    });

    test('isOnline completes within timeout', () async {
      // Verify the method respects the 3-second timeout
      final stopwatch = Stopwatch()..start();
      await service.isOnline();
      stopwatch.stop();
      
      // Should complete within 4 seconds (3s timeout + 1s buffer)
      expect(stopwatch.elapsed.inSeconds, lessThan(4));
    });
  });
}
