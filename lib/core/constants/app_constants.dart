/// CYKEL — App-wide Constants

class AppConstants {
  AppConstants._();

  // --- App Info ---
  static const String appName = 'Cykel';
  static const String appVersion = '1.0.0';
  static const String bundleId = 'dk.cykel.app';

  // --- Default Country ---
  static const String defaultCountry = 'DK';
  static const String defaultLocale = 'da_DK';

  // --- Subscription ---
  static const String premiumProductIdIos = 'dk.cykel.premium.monthly';
  static const String premiumProductIdAndroid = 'dk.cykel.premium.monthly';
  static const double premiumPriceUsd = 5.0;

  // --- Firestore Collections ---
  static const String colUsers = 'users';
  static const String colRides = 'rides';
  static const String colListings = 'marketplace_listings';
  static const String colChats = 'marketplace_chats';
  static const String colMessages = 'messages';
  static const String colProviders = 'providers';
  static const String colProviderAnalytics = 'provider_analytics';
  static const String colLocations = 'locations';
  static const String colReports = 'reports';

  // --- Firebase Storage Paths ---
  static const String storageUsers = 'users';
  static const String storageListings = 'listings';
  static const String storageProviders = 'providers';

  // --- User Roles ---
  static const String roleRider = 'rider';
  static const String roleProviderPersonal = 'provider_personal';
  static const String roleProviderBusiness = 'provider_business';
  static const String roleAdmin = 'admin';

  // --- Verification Status ---
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';

  // --- Listing Status ---
  static const String listingActive = 'active';
  static const String listingSold = 'sold';
  static const String listingPaused = 'paused';
  static const String listingRemoved = 'removed';

  // --- Provider Types ---
  static const String providerRepairShop = 'repair_shop';
  static const String providerBikeShop = 'bike_shop';
  static const String providerChargingLocation = 'charging_location';

  // --- Location Types ---
  static const String locationCharging = 'charging';
  static const String locationService = 'service';
  static const String locationShop = 'shop';
  static const String locationRental = 'rental';

  // --- Pagination ---
  static const int pageSize = 20;
  static const int chatPageSize = 30;

  // --- GPS Tracking ---
  static const double gpsMinDistance = 5.0;   // metres between points
  static const int gpsIntervalSeconds = 3;

  // --- Map ---
  static const double defaultMapZoom = 14.0;
  static const double navigationMapZoom = 17.0;

  // --- Weather Cache ---
  static const int weatherCacheMinutes = 30;

  // --- Images ---
  static const int maxListingPhotos = 8;
  static const int maxProviderGalleryPhotos = 8;
  static const int imageQuality = 80;          // 0–100
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5 MB

  // --- Provider Nearby Search ---
  static const double defaultProviderSearchRadiusKm = 10.0;
}
