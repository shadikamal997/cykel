/// CYKEL Dynamic Links Service
/// Create shareable deep links for routes, events, providers, etc.
/// 
/// ⚠️  IMPORTANT: firebase_dynamic_links is DISCONTINUED by Firebase
/// 
/// This package still works but Firebase recommends migrating to:
/// - App Links (Android): https://developer.android.com/training/app-links
/// - Universal Links (iOS): https://developer.apple.com/ios/universal-links/
/// 
/// For now, this service works but should be migrated in the future.

import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

class DynamicLinksService {
  DynamicLinksService._();
  static final instance = DynamicLinksService._();

  static const String _domainUriPrefix = 'https://cykel.page.link';
  static const String _androidPackageName = 'dk.cykel.cykel';
  static const String _iosBundleId = 'dk.cykel.cykel';
  static const String _appStoreId = ''; // TODO: Add after App Store release

  bool _initialized = false;

  /// Initialize Dynamic Links and handle incoming links
  Future<void> initialize({
    required Function(Uri deepLink) onLinkReceived,
  }) async {
    if (_initialized) return;

    try {
      // Handle link that opened/resumed the app
      final PendingDynamicLinkData? initialLink = 
          await FirebaseDynamicLinks.instance.getInitialLink();
      
      if (initialLink != null) {
        _handleDeepLink(initialLink.link, onLinkReceived);
      }

      // Listen for links while app is running
      FirebaseDynamicLinks.instance.onLink.listen(
        (dynamicLinkData) {
          _handleDeepLink(dynamicLinkData.link, onLinkReceived);
        },
        onError: (error) {
          debugPrint('Dynamic Links error: $error');
        },
      );

      _initialized = true;
      debugPrint('✅ Dynamic Links initialized');
    } catch (e) {
      debugPrint('⚠️ Dynamic Links initialization failed: $e');
    }
  }

  void _handleDeepLink(Uri deepLink, Function(Uri) callback) {
    debugPrint('📲 Deep link received: $deepLink');
    callback(deepLink);
  }

  /// Create a short dynamic link
  Future<Uri?> createShortLink({
    required String path,
    required String title,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final DynamicLinkParameters parameters = DynamicLinkParameters(
        uriPrefix: _domainUriPrefix,
        link: Uri.parse('https://cykel.dk$path'),
      androidParameters: const AndroidParameters(
          packageName: _androidPackageName,
          minimumVersion: 1,
        ),
        iosParameters: IOSParameters(
          bundleId: _iosBundleId,
          minimumVersion: '1.0.0',
          appStoreId: _appStoreId.isNotEmpty ? _appStoreId : null,
        ),
        socialMetaTagParameters: SocialMetaTagParameters(
          title: title,
          description: description,
          imageUrl: imageUrl != null ? Uri.parse(imageUrl) : null,
        ),
      );

      final ShortDynamicLink shortLink = 
          await FirebaseDynamicLinks.instance.buildShortLink(parameters);
      
      return shortLink.shortUrl;
    } catch (e) {
      debugPrint('Failed to create dynamic link: $e');
      return null;
    }
  }

  // ─── Route Sharing ─────────────────────────────────────────────────────────

  Future<void> shareRoute({
    required String routeId,
    required String routeName,
    required double distanceKm,
  }) async {
    final link = await createShortLink(
      path: '/route/$routeId',
      title: 'Check out my route: $routeName',
      description: '${distanceKm.toStringAsFixed(1)} km bike route',
    );

    if (link != null) {
      await Share.share(
        'Check out this bike route: $routeName\n$link',
      );
    }
  }

  // ─── Event Sharing ─────────────────────────────────────────────────────────

  Future<void> shareEvent({
    required String eventId,
    required String eventName,
    required DateTime dateTime,
    String? imageUrl,
  }) async {
    final link = await createShortLink(
      path: '/event/$eventId',
      title: 'Join me: $eventName',
      description: 'Event on ${dateTime.toLocal().toString().split(' ')[0]}',
      imageUrl: imageUrl,
    );

    if (link != null) {
      await Share.share(
        'Join me for this cycling event: $eventName\n$link',
      );
    }
  }

  // ─── Provider Sharing ──────────────────────────────────────────────────────

  Future<void> shareProvider({
    required String providerId,
    required String providerName,
    required String providerType,
    String? imageUrl,
  }) async {
    final link = await createShortLink(
      path: '/provider/$providerId',
      title: providerName,
      description: 'Bike $providerType in Copenhagen',
      imageUrl: imageUrl,
    );

    if (link != null) {
      await Share.share(
        'Check out this bike shop: $providerName\n$link',
      );
    }
  }

  // ─── Marketplace Listing Sharing ───────────────────────────────────────────

  Future<void> shareMarketplaceListing({
    required String listingId,
    required String title,
    required double price,
    String? imageUrl,
  }) async {
    final link = await createShortLink(
      path: '/marketplace/$listingId',
      title: title,
      description: 'DKK ${price.toInt()} - CYKEL Marketplace',
      imageUrl: imageUrl,
    );

    if (link != null) {
      await Share.share(
        'Check out this bike for sale: $title\nDKK ${price.toInt()}\n$link',
      );
    }
  }

  // ─── Bike Share Station ────────────────────────────────────────────────────

  Future<void> shareBikeShareStation({
    required String stationId,
    required String stationName,
    required int availableBikes,
  }) async {
    final link = await createShortLink(
      path: '/station/$stationId',
      title: stationName,
      description: '$availableBikes bikes available',
    );

    if (link != null) {
      await Share.share(
        'Bike share station: $stationName\n$availableBikes bikes available\n$link',
      );
    }
  }

  // ─── Invite Friend ─────────────────────────────────────────────────────────

  Future<void> shareInvite({
    required String userId,
    required String userName,
  }) async {
    final link = await createShortLink(
      path: '/invite/$userId',
      title: '$userName invited you to CYKEL',
      description: 'Join the cycling community in Copenhagen',
    );

    if (link != null) {
      await Share.share(
        'Join me on CYKEL - the Copenhagen cycling app!\n$link',
      );
    }
  }
}
