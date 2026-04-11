/// CYKEL — Certificate Pinning Service
/// Prevents MITM attacks by validating SSL certificate fingerprints
/// 
/// IMPORTANT: Update fingerprints before certificate expiration!
/// Certificates typically expire every 1-2 years.
/// 
/// To get current fingerprints:
/// echo | openssl s_client -connect googleapis.com:443 2>/dev/null | openssl x509 -fingerprint -sha256 -noout

import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

/// Certificate fingerprints for googleapis.com and related services
/// CRITICAL: These must be updated when Google rotates certificates
class CertificateFingerprints {
  CertificateFingerprints._();

  // Google APIs (googleapis.com, maps.googleapis.com, firestore.googleapis.com)
  // Last updated: [UPDATE THIS DATE]
  // Expires: [CHECK CERTIFICATE EXPIRATION]
  static const List<String> googleApis = [
    // Primary certificate (current)
    // 'XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX',
    
    // Backup certificate (rotation)
    // 'YY:YY:YY:YY:YY:YY:YY:YY:YY:YY:YY:YY:YY:YY:YY:YY:YY:YY:YY:YY:YY:YY:YY:YY:YY:YY:YY:YY:YY:YY',
  ];

  // Firebase services (firebase.google.com)
  static const List<String> firebase = [
    // Primary certificate
    // 'XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX',
  ];

  // Weather API (open-meteo.com)
  static const List<String> weather = [
    // Primary certificate
    // 'XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX',
  ];
}

/// Certificate Pinning Configuration
class CertificatePinningConfig {
  CertificatePinningConfig._({
    required this.enabled,
    required this.strictMode,
    required this.allowedFingerprints,
  });

  /// Enable/disable certificate pinning
  /// RECOMMENDED: false in debug, true in release
  final bool enabled;

  /// Strict mode: reject connections on pin mismatch
  /// If false, logs warning but allows connection (for gradual rollout)
  final bool strictMode;

  /// Allowed SHA-256 fingerprints for this host
  final List<String> allowedFingerprints;

  /// Debug configuration (pinning disabled)
  factory CertificatePinningConfig.debug() {
    return CertificatePinningConfig._(
      enabled: false,
      strictMode: false,
      allowedFingerprints: [],
    );
  }

  /// Production configuration (pinning enabled, strict mode)
  factory CertificatePinningConfig.production({
    required List<String> fingerprints,
  }) {
    return CertificatePinningConfig._(
      enabled: true,
      strictMode: true,
      allowedFingerprints: fingerprints,
    );
  }

  /// Gradual rollout (pinning enabled, warnings only)
  factory CertificatePinningConfig.monitored({
    required List<String> fingerprints,
  }) {
    return CertificatePinningConfig._(
      enabled: true,
      strictMode: false,
      allowedFingerprints: fingerprints,
    );
  }
}

/// Certificate Pinning Service
/// 
/// Usage:
/// ```dart
/// final dio = CertificatePinningService.createPinnedDioClient(
///   config: kReleaseMode 
///     ? CertificatePinningConfig.production(
///         fingerprints: CertificateFingerprints.googleApis,
///       )
///     : CertificatePinningConfig.debug(),
/// );
/// ```
class CertificatePinningService {
  CertificatePinningService._();

  /// Create Dio client with certificate pinning
  static Dio createPinnedDioClient({
    required CertificatePinningConfig config,
    BaseOptions? options,
  }) {
    final dio = Dio(options);

    if (!config.enabled) {
      debugPrint('⚠️ Certificate pinning DISABLED (debug mode)');
      return dio;
    }

    if (config.allowedFingerprints.isEmpty) {
      debugPrint('⚠️ Certificate pinning enabled but NO fingerprints configured');
      if (config.strictMode) {
        throw Exception('Certificate pinning: No fingerprints configured in strict mode');
      }
      return dio;
    }

    // Configure certificate validation
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();

      client.badCertificateCallback = (
        X509Certificate cert,
        String host,
        int port,
      ) {
        // Calculate SHA-256 fingerprint from DER-encoded certificate
        final derBytes = cert.der;
        final digest = sha256.convert(derBytes);
        final fingerprint = digest.bytes
            .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
            .join(':')
            .toUpperCase();

        // Check if fingerprint is allowed
        final isAllowed = config.allowedFingerprints.any(
          (fp) => fp.toUpperCase() == fingerprint,
        );

        if (isAllowed) {
          debugPrint('✅ Certificate pinning: Valid certificate for $host');
          return true;
        }

        // Invalid certificate
        debugPrint('❌ Certificate pinning: Invalid certificate for $host');
        debugPrint('   Expected one of: ${config.allowedFingerprints}');
        debugPrint('   Got: $fingerprint');

        if (config.strictMode) {
          // Strict mode: reject connection
          return false;
        } else {
          // Monitor mode: log warning but allow connection
          debugPrint('⚠️ Certificate pinning: Allowing connection (monitor mode)');
          return true;
        }
      };

      return client;
    };

    debugPrint('🔒 Certificate pinning enabled for ${config.allowedFingerprints.length} fingerprints');
    return dio;
  }

  /// Quick validation: Check if a host's certificate is pinned correctly
  /// Useful for health checks or monitoring
  static Future<CertificateValidationResult> validateCertificate({
    required String url,
    required List<String> expectedFingerprints,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final uri = Uri.parse(url);
      final socket = await SecureSocket.connect(
        uri.host,
        uri.port == 0 ? 443 : uri.port,
        timeout: timeout,
      );

      final cert = socket.peerCertificate;
      if (cert == null) {
        return CertificateValidationResult.error('No certificate received');
      }

      // Calculate SHA-256 fingerprint from DER-encoded certificate
      final derBytes = cert.der;
      final digest = sha256.convert(derBytes);
      final fingerprint = digest.bytes
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join(':')
          .toUpperCase();

      final isValid = expectedFingerprints
          .any((fp) => fp.toUpperCase() == fingerprint);

      await socket.close();

      if (isValid) {
        return CertificateValidationResult.success(fingerprint);
      } else {
        return CertificateValidationResult.mismatch(
          expected: expectedFingerprints,
          actual: fingerprint,
        );
      }
    } catch (e) {
      return CertificateValidationResult.error(e.toString());
    }
  }
}

/// Result of certificate validation
class CertificateValidationResult {
  CertificateValidationResult._({
    required this.isValid,
    this.fingerprint,
    this.expectedFingerprints,
    this.errorMessage,
  });

  final bool isValid;
  final String? fingerprint;
  final List<String>? expectedFingerprints;
  final String? errorMessage;

  factory CertificateValidationResult.success(String fingerprint) {
    return CertificateValidationResult._(
      isValid: true,
      fingerprint: fingerprint,
    );
  }

  factory CertificateValidationResult.mismatch({
    required List<String> expected,
    required String actual,
  }) {
    return CertificateValidationResult._(
      isValid: false,
      fingerprint: actual,
      expectedFingerprints: expected,
      errorMessage: 'Certificate fingerprint mismatch',
    );
  }

  factory CertificateValidationResult.error(String message) {
    return CertificateValidationResult._(
      isValid: false,
      errorMessage: message,
    );
  }

  @override
  String toString() {
    if (isValid) {
      return 'Valid certificate: $fingerprint';
    }
    if (expectedFingerprints != null) {
      return 'Certificate mismatch:\n'
          '  Expected: ${expectedFingerprints!.join(" OR ")}\n'
          '  Got: $fingerprint';
    }
    return 'Certificate validation error: $errorMessage';
  }
}
