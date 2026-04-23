/// CYKEL App Router
/// GoRouter configuration with auth redirect guard.

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';

import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/navigation/presentation/shell_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/discover/presentation/map_screen.dart';
import '../../features/activity/presentation/activity_screen.dart';
import '../../features/discover/presentation/discover_screen.dart';
import '../../features/marketplace/presentation/marketplace_screen.dart';
import '../../features/marketplace/presentation/listing_detail_screen.dart';
import '../../features/marketplace/presentation/create_listing_screen.dart';
import '../../features/marketplace/presentation/chat_screen.dart';
import '../../features/marketplace/domain/marketplace_listing.dart';
import '../../features/marketplace/domain/chat_message.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/gdpr_consent_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/my_bikes_screen.dart';
import '../../features/profile/presentation/bike_maintenance_screen.dart';
import '../../features/profile/presentation/saved_places_screen.dart';
import '../../features/profile/presentation/notifications_screen.dart';
import '../../features/profile/presentation/language_screen.dart';
import '../../features/profile/presentation/voice_settings_screen.dart';
import '../../features/profile/presentation/dashboard_settings_screen.dart';
import '../../features/profile/presentation/help_support_screen.dart';
import '../../features/profile/presentation/privacy_screen.dart';
import '../../features/profile/presentation/subscription_screen.dart';
import '../../features/profile/presentation/student_verification_screen.dart';
import '../../features/profile/presentation/commuter_tax_settings_screen.dart';
import '../../features/profile/data/gdpr_provider.dart';
import '../../features/profile/domain/bike.dart';
import '../../features/gamification/presentation/challenges_screen.dart';
import '../../features/gamification/presentation/badges_screen.dart';
import '../../features/gamification/presentation/leaderboard_screen.dart';
import '../../features/theft_alert/presentation/theft_alerts_screen.dart';
import '../../features/social/presentation/social_screen.dart';
import '../../features/routes/presentation/route_suggestions_screen.dart';
import '../../features/offline_maps/presentation/offline_maps_screen.dart';
import '../../features/events/presentation/events_screen.dart';
import '../../features/events/presentation/event_detail_screen.dart';
import '../../features/events/presentation/create_event_screen.dart';
import '../../features/events/presentation/edit_event_screen.dart';
import '../../features/provider/domain/provider_enums.dart';
import '../../features/provider/presentation/provider_type_selection_screen.dart';
import '../../features/provider/presentation/provider_onboarding_screen.dart';
import '../../features/provider/presentation/provider_dashboard_screen.dart';
import '../../features/provider/presentation/edit_provider_screen.dart';
import '../../features/provider/presentation/manage_hours_screen.dart';
import '../../features/provider/presentation/manage_photos_screen.dart';
import '../../features/provider/presentation/provider_settings_screen.dart';
import '../../features/provider/presentation/location_list_screen.dart';
import '../../features/provider/presentation/edit_location_screen.dart';
import '../../features/provider/presentation/provider_listings_screen.dart';
import '../../features/provider/presentation/provider_list_screen.dart';
import '../../features/provider/presentation/provider_detail_screen.dart';
import '../../features/provider/domain/provider_location.dart';
import '../../features/provider/domain/provider_model.dart';

// New feature imports
import '../../features/bike_share/presentation/bike_share_map_screen.dart';
import '../../features/bike_share/presentation/nearby_stations_screen.dart';
import '../../features/chat/presentation/conversations_list_screen.dart';
import '../../features/chat/presentation/chat_screen.dart' as chat;
import '../../features/family_pricing/presentation/family_live_map_screen.dart';
import '../../features/family_pricing/presentation/family_management_screen.dart';
import '../../features/family_pricing/presentation/family_setup_wizard.dart';
import '../../features/family_pricing/presentation/alert_history_screen.dart';
import '../../features/family_pricing/presentation/family_achievements_screen.dart';
import '../../features/family_pricing/presentation/family_dashboard_screen.dart';
import '../../features/family_pricing/presentation/ride_history_screen.dart';
import '../../features/family_pricing/presentation/safe_zones_screen.dart';
import '../../features/family_pricing/presentation/safe_zone_edit_screen.dart';
import '../../features/family_pricing/presentation/guest_riders_screen.dart';
import '../../features/family_pricing/presentation/group_rides_screen.dart';
import '../../features/family_pricing/domain/family_location.dart';
import '../../features/family_pricing/presentation/subscription_plans_screen.dart';
import '../../features/buddy_matching/presentation/buddy_discovery_screen.dart';
import '../../features/expat_hub/presentation/expat_hub_screen.dart';
import '../../features/expat_hub/presentation/guides_screen.dart';
import '../../features/home/presentation/weather_alerts_screen.dart';
import '../../features/notifications/presentation/notifications_list_screen.dart';

// ─── Route Name Constants ────────────────────────────────────────────────────

class AppRoutes {
  AppRoutes._();

  // Auth
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';

  // Rider shell
  static const String home = '/home';
  static const String map = '/map';
  static const String activity = '/activity';
  static const String discover = '/discover';
  static const String marketplace = '/marketplace';

  // Profile
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String profileBikes = '/profile/bikes';
  static const String profileMaintenance = '/profile/maintenance';
  static const String profileSavedPlaces = '/profile/saved-places';
  static const String profileNotifications = '/profile/notifications';
  static const String profileLanguage = '/profile/language';
  static const String profileVoice = '/profile/voice';
  static const String profileCommuterTax = '/profile/commuter-tax';
  static const String profileDashboard = '/profile/dashboard';
  static const String profileHelp = '/profile/help';
  static const String profilePrivacy = '/profile/privacy';
  static const String profileSubscription = '/profile/subscription';
  static const String profileStudentVerification = '/profile/student-verification';

  // Gamification
  static const String challenges = '/challenges';
  static const String badges = '/badges';
  static const String leaderboard = '/leaderboard';

  // Theft Alerts
  static const String theftAlerts = '/theft-alerts';

  // Weather Alerts
  static const String weatherAlerts = '/weather-alerts';

  // Notifications
  static const String notifications = '/notifications';

  // Social
  static const String social = '/social';

  // Route Suggestions
  static const String routeSuggestions = '/route-suggestions';

  // Offline Maps
  static const String offlineMaps = '/offline-maps';

  // Events
  static const String events = '/events';
  static const String createEvent = '/events/create';
  static const String editEvent = '/events/edit';

  // Marketplace sub-routes
  static const String marketplaceCreate = '/marketplace/create';

  // GDPR
  static const String gdprConsent = '/gdpr-consent';

  // Provider portal
  static const String provider = '/provider';
  static const String providerOnboarding = '/provider/onboarding';
  static const String providerList = '/provider/list';
  static const String providerDetail = '/provider/detail';
  static const String providerDashboard = '/provider/dashboard';
  static const String providerEdit = '/provider/edit';
  static const String providerHours = '/provider/hours';
  static const String providerPhotos = '/provider/photos';
  static const String providerSettings = '/provider/settings';
  static const String providerLocations = '/provider/locations';
  static const String providerLocationAdd = '/provider/locations/add';
  static const String providerLocationEdit = '/provider/locations/edit';
  static const String providerListings = '/provider/listings';

  // Bike Share
  static const String bikeShare = '/bike-share';
  static const String bikeShareNearby = '/bike-share/nearby';

  // Chat / Messages
  static const String messages = '/messages';

  // Family Pricing
  static const String familyGroups = '/family';
  static const String familySubscription = '/family/subscription';
  static const String familySetup = '/family/setup';
  static const String familyDashboard = '/family/dashboard';
  static const String familyMap = '/family/map';
  static const String familySafeZones = '/family/safe-zones';
  static const String familySafeZoneEdit = '/family/safe-zones/edit';
  static const String familyRideHistory = '/family/rides';
  static const String familyAlertHistory = '/family/alerts';
  static const String familyAchievements = '/family/achievements';
  static const String familyGuests = '/family/guests';
  static const String familyGroupRides = '/family/group-rides';

  // Buddy Matching
  static const String buddyMatching = '/buddy-matching';

  // Expat Hub
  static const String expatHub = '/expat-hub';
  static const String expatGuides = '/expat-hub/guides';
}

// ─── Router Notifier ─────────────────────────────────────────────────────────
// AsyncNotifier<void> implements Listenable is the correct Riverpod 2.x +
// GoRouter pattern. ref.listen inside AsyncNotifier.build() runs inside the
// reactive graph and is guaranteed to fire on every auth state change.

class _RouterNotifier extends AsyncNotifier<void> implements Listenable {
  VoidCallback? _routerListener;

  @override
  Future<void> build() async {
    ref.listen<AsyncValue<AppUser?>>(authStateProvider, (_, _) {
      _routerListener?.call();
    });
    // Also wake the router when the splash video finishes.
    ref.listen<AsyncValue<GdprState>>(gdprProvider, (_, _) {
      _routerListener?.call();
    });
    ref.listen<bool>(splashVideoCompleteProvider, (_, _) {
      _routerListener?.call();
    });
  }

  @override
  void addListener(VoidCallback listener) => _routerListener = listener;

  @override
  void removeListener(VoidCallback listener) => _routerListener = null;

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = ref.read(authStateProvider);
    final videoComplete = ref.read(splashVideoCompleteProvider);

    if (authState.isLoading) return null;

    final user = authState.valueOrNull;
    final location = state.matchedLocation;

    final isOnSplash = location == AppRoutes.splash;

    // Wait for video to finish before leaving splash.
    if (isOnSplash && !videoComplete) return null;

    // Auth screens that are valid for a signed-out user (splash excluded).
    final isOnAuthScreen = location == AppRoutes.welcome ||
        location == AppRoutes.login ||
        location == AppRoutes.signup ||
        location == AppRoutes.forgotPassword;

    if (user == null) {
      // Signed out: send to welcome unless already on an auth screen.
      if (isOnSplash || !isOnAuthScreen) return AppRoutes.welcome;
      return null;
    }

    if (!user.emailVerified) {
      if (location == AppRoutes.verifyEmail) return null;
      return AppRoutes.verifyEmail;
    }

    // Signed in + verified: check GDPR consent.
    final gdprState = ref.read(gdprProvider);
    final isOnGdpr = location == AppRoutes.gdprConsent;
    
    // If GDPR is still loading, only redirect from splash/auth screens
    // Don't redirect from app screens to avoid disrupting navigation
    if (gdprState.isLoading) {
      // Only redirect away from splash/auth screens when loading
      if (isOnSplash) return AppRoutes.gdprConsent;
      if (isOnAuthScreen) return AppRoutes.gdprConsent;
      // Allow staying on current screen if already in the app
      return null;
    }
    
    final consentGiven = gdprState.valueOrNull?.consentGiven ?? false;

    if (!consentGiven) {
      // User has definitely not consented - only redirect from splash/auth screens
      if (isOnGdpr) return null;
      if (isOnAuthScreen || isOnSplash) return AppRoutes.gdprConsent;
      // Allow app navigation to continue even without consent loaded
      // This prevents disrupting back navigation
      return null;
    }

    if (isOnGdpr) return AppRoutes.home;

    // Signed in + verified + consented: leave auth/splash screens.
    if (isOnAuthScreen || isOnSplash) return AppRoutes.home;

    return null;
  }
}

// ─── Router Provider ──────────────────────────────────────────────────────────

final _routerNotifierProvider =
    AsyncNotifierProvider<_RouterNotifier, void>(_RouterNotifier.new);

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(_routerNotifierProvider.notifier);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    errorBuilder: (context, state) => _ErrorScreen(
      error: state.error?.toString(),
    ),
    routes: [
      // ── Auth routes (no shell) ──────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child; // No transition when entering splash
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        name: 'welcome',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WelcomeScreen(),
          transitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        name: 'verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // ── Profile — pushed on top of the shell ───────────────────────────
      GoRoute(
        path: AppRoutes.gdprConsent,
        name: 'gdpr-consent',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const GdprConsentScreen(),
          transitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileEdit,
        name: 'profile-edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileBikes,
        name: 'profile-bikes',
        builder: (context, state) => const MyBikesScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileMaintenance,
        name: 'profile-maintenance',
        builder: (context, state) {
          final bike = state.extra as Bike;
          return BikeMaintenanceScreen(bike: bike);
        },
      ),
      GoRoute(
        path: AppRoutes.profileSavedPlaces,
        name: 'profile-saved-places',
        builder: (context, state) => const SavedPlacesScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileNotifications,
        name: 'profile-notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileLanguage,
        name: 'profile-language',
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileVoice,
        name: 'profile-voice',
        builder: (context, state) => const VoiceSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileCommuterTax,
        name: 'profile-commuter-tax',
        builder: (context, state) => const CommuterTaxSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileDashboard,
        name: 'profile-dashboard',
        builder: (context, state) => const DashboardSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileHelp,
        name: 'profile-help',
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: AppRoutes.profilePrivacy,
        name: 'profile-privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileSubscription,
        name: 'profile-subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileStudentVerification,
        name: 'profile-student-verification',
        builder: (context, state) => const StudentVerificationScreen(),
      ),

      // ── Gamification ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.challenges,
        name: 'challenges',
        builder: (context, state) => const ChallengesScreen(),
      ),
      GoRoute(
        path: AppRoutes.badges,
        name: 'badges',
        builder: (context, state) => const BadgesScreen(),
      ),
      GoRoute(
        path: AppRoutes.leaderboard,
        name: 'leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),

      // ── Theft Alerts ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.theftAlerts,
        name: 'theft-alerts',
        builder: (context, state) => const TheftAlertsScreen(),
      ),

      // ── Weather Alerts ──────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.weatherAlerts,
        name: 'weather-alerts',
        builder: (context, state) => const WeatherAlertsScreen(),
      ),

      // ── Notifications ───────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsListScreen(),
      ),

      // ── Social ──────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.social,
        name: 'social',
        builder: (context, state) => const SocialScreen(),
      ),

      // ── Route Suggestions ───────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.routeSuggestions,
        name: 'route-suggestions',
        builder: (context, state) => const RouteSuggestionsScreen(),
      ),

      // ── Offline Maps ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.offlineMaps,
        name: 'offline-maps',
        builder: (context, state) => const OfflineMapsScreen(),
      ),

      // ── Events ──────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.events,
        name: 'events',
        builder: (context, state) => const EventsScreen(),
      ),
      // Create event route must be defined before :eventId to avoid matching "create" as an ID
      GoRoute(
        path: AppRoutes.createEvent,
        name: 'create-event',
        builder: (context, state) => const CreateEventScreen(),
      ),
      // Edit event route
      GoRoute(
        path: '${AppRoutes.editEvent}/:eventId',
        name: 'edit-event',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return EditEventScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '${AppRoutes.events}/:eventId',
        name: 'event-detail',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return EventDetailScreen(eventId: eventId);
        },
      ),

      // ── Provider Onboarding ─────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.provider,
        name: 'provider',
        builder: (context, state) => const ProviderTypeSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.providerOnboarding,
        name: 'provider-onboarding',
        builder: (context, state) {
          final type = state.extra as ProviderType? ?? ProviderType.repairShop;
          return ProviderOnboardingScreen(providerType: type);
        },
      ),
      GoRoute(
        path: AppRoutes.providerList,
        name: 'provider-list',
        builder: (context, state) {
          final type = state.extra as ProviderType? ?? ProviderType.repairShop;
          return ProviderListScreen(providerType: type);
        },
      ),
      GoRoute(
        path: AppRoutes.providerDetail,
        name: 'provider-detail',
        builder: (context, state) {
          final provider = state.extra as CykelProvider;
          return ProviderDetailScreen(provider: provider);
        },
      ),

      // ── Provider Dashboard & Management ─────────────────────────────────
      GoRoute(
        path: AppRoutes.providerDashboard,
        name: 'provider-dashboard',
        builder: (context, state) => const ProviderDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.providerEdit,
        name: 'provider-edit',
        builder: (context, state) => const EditProviderScreen(),
      ),
      GoRoute(
        path: AppRoutes.providerHours,
        name: 'provider-hours',
        builder: (context, state) => const ManageHoursScreen(),
      ),
      GoRoute(
        path: AppRoutes.providerPhotos,
        name: 'provider-photos',
        builder: (context, state) => const ManagePhotosScreen(),
      ),
      GoRoute(
        path: AppRoutes.providerSettings,
        name: 'provider-settings',
        builder: (context, state) => const ProviderSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.providerLocations,
        name: 'provider-locations',
        builder: (context, state) => const LocationListScreen(),
      ),
      GoRoute(
        path: AppRoutes.providerLocationAdd,
        name: 'provider-location-add',
        builder: (context, state) => const EditLocationScreen(),
      ),
      GoRoute(
        path: AppRoutes.providerLocationEdit,
        name: 'provider-location-edit',
        builder: (context, state) {
          final location = state.extra as ProviderLocation?;
          return EditLocationScreen(location: location);
        },
      ),
      GoRoute(
        path: AppRoutes.providerListings,
        name: 'provider-listings',
        builder: (context, state) => const ProviderListingsScreen(),
      ),

      // ── Bike Share ──────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.bikeShare,
        name: 'bike-share',
        builder: (context, state) => const BikeShareMapScreen(),
      ),
      GoRoute(
        path: AppRoutes.bikeShareNearby,
        name: 'bike-share-nearby',
        builder: (context, state) => const NearbyStationsScreen(),
      ),

      // ── Chat / Messages ─────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.messages,
        name: 'messages',
        builder: (context, state) => const ConversationsListScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.messages}/:conversationId',
        name: 'chat-detail',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          return chat.ChatScreen(conversationId: conversationId);
        },
      ),

      // ── Family Pricing ──────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.familyGroups,
        name: 'family-groups',
        builder: (context, state) => const FamilyManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.familySubscription,
        name: 'family-subscription',
        builder: (context, state) => const SubscriptionPlansScreen(),
      ),
      GoRoute(
        path: AppRoutes.familySetup,
        name: 'family-setup',
        builder: (context, state) => const FamilySetupWizard(),
      ),
      GoRoute(
        path: AppRoutes.familyMap,
        name: 'family-map',
        builder: (context, state) => const FamilyLiveMapScreen(),
      ),
      GoRoute(
        path: AppRoutes.familySafeZones,
        name: 'family-safe-zones',
        builder: (context, state) => const SafeZonesScreen(),
      ),
      GoRoute(
        path: AppRoutes.familySafeZoneEdit,
        name: 'family-safe-zone-edit',
        builder: (context, state) {
          final zone = state.extra as SafeZone?;
          return SafeZoneEditScreen(existingZone: zone);
        },
      ),
      GoRoute(
        path: AppRoutes.familyDashboard,
        name: 'family-dashboard',
        builder: (context, state) => const FamilyDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.familyRideHistory,
        name: 'family-ride-history',
        builder: (context, state) {
          final memberId = state.extra as String?;
          return RideHistoryScreen(memberId: memberId);
        },
      ),
      GoRoute(
        path: AppRoutes.familyAlertHistory,
        name: 'family-alert-history',
        builder: (context, state) => const AlertHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.familyAchievements,
        name: 'family-achievements',
        builder: (context, state) => const FamilyAchievementsScreen(),
      ),
      GoRoute(
        path: AppRoutes.familyGuests,
        name: 'family-guests',
        builder: (context, state) => const GuestRidersScreen(),
      ),
      GoRoute(
        path: AppRoutes.familyGroupRides,
        name: 'family-group-rides',
        builder: (context, state) => const GroupRidesScreen(),
      ),

      // ── Buddy Matching ──────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.buddyMatching,
        name: 'buddy-matching',
        builder: (context, state) => const BuddyDiscoveryScreen(),
      ),

      // ── Expat Hub ───────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.expatHub,
        name: 'expat-hub',
        builder: (context, state) => const ExpatHubScreen(),
      ),
      GoRoute(
        path: AppRoutes.expatGuides,
        name: 'expat-guides',
        builder: (context, state) => const GuidesScreen(),
      ),

      // ── Rider shell — 5-tab StatefulShellRoute ──────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScreen(navigationShell: navigationShell),
        branches: [
          // Branch 0 — Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const HomeScreen(),
                  transitionDuration: const Duration(milliseconds: 250),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    // Smooth fade when coming from splash
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              ),
            ],
          ),
          // Branch 1 — Map
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.map,
                name: 'map',
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),
          // Branch 2 — Activity
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.activity,
                name: 'activity',
                builder: (context, state) => const ActivityScreen(),
              ),
            ],
          ),
          // Branch 3 — Discover
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.discover,
                name: 'discover',
                builder: (context, state) => const DiscoverScreen(),
              ),
            ],
          ),
          // Branch 4 — Marketplace
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.marketplace,
                name: 'marketplace',
                builder: (context, state) => const MarketplaceScreen(),
                routes: [
                  GoRoute(
                    path: 'listing/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return ListingDetailScreen(
                        listingId: id,
                        listing: state.extra as MarketplaceListing?,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'create',
                    builder: (context, state) => const CreateListingScreen(),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    builder: (context, state) {
                      return CreateListingScreen(
                        editListing: state.extra as MarketplaceListing?,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'chat/:threadId',
                    builder: (context, state) {
                      final threadId = state.pathParameters['threadId'] ?? '';
                      return ChatScreen(
                        threadId: threadId,
                        thread: state.extra as ChatThread?,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

// ─── Error Screen (404) ───────────────────────────────────────────────────────

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({this.error});
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pageNotFound),
        leading: BackButton(onPressed: () => context.go(AppRoutes.home)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🚧', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              l10n.pageNotFound,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(AppRoutes.home),
              child: Text(l10n.goHome),
            ),
          ],
        ),
      ),
    );
  }
}
