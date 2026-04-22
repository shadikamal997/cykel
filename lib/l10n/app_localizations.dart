import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_da.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('da'),
    Locale('en'),
  ];

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Your Bicycle OS'**
  String get appTagline;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Denmark\'s Bicycle OS'**
  String get appSubtitle;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @signInWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email'**
  String get signInWithEmail;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @termsNotice.
  ///
  /// In en, this message translates to:
  /// **'By continuing you accept our\nTerms and Privacy Policy.'**
  String get termsNotice;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back to CYKEL'**
  String get welcomeBack;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started with CYKEL'**
  String get getStarted;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @atLeastTwoChars.
  ///
  /// In en, this message translates to:
  /// **'At least 2 characters'**
  String get atLeastTwoChars;

  /// No description provided for @atLeastEightChars.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get atLeastEightChars;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsMismatch;

  /// No description provided for @mustAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'You must accept the terms to continue.'**
  String get mustAcceptTerms;

  /// No description provided for @iAgreeTo.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get iAgreeTo;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get and;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a link to reset your password.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// No description provided for @emailSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Email sent!'**
  String get emailSentTitle;

  /// No description provided for @resetLinkSentTo.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a reset link to\n{email}'**
  String resetLinkSentTo(String email);

  /// No description provided for @checkInbox.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox and spam folder.'**
  String get checkInbox;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification email to\n{email}'**
  String verifyEmailSentTo(String email);

  /// No description provided for @verifyEmailAction.
  ///
  /// In en, this message translates to:
  /// **'Click the link in the email to activate your account.'**
  String get verifyEmailAction;

  /// No description provided for @waitingForVerification.
  ///
  /// In en, this message translates to:
  /// **'Waiting for verification…'**
  String get waitingForVerification;

  /// No description provided for @verificationEmailResent.
  ///
  /// In en, this message translates to:
  /// **'Verification email resent.'**
  String get verificationEmailResent;

  /// No description provided for @emailSentCheck.
  ///
  /// In en, this message translates to:
  /// **'Email sent ✓'**
  String get emailSentCheck;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get resendEmail;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Hey, {name} 👋'**
  String greeting(String name);

  /// No description provided for @rideToday.
  ///
  /// In en, this message translates to:
  /// **'Ready to ride today?'**
  String get rideToday;

  /// No description provided for @dashboardComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Dashboard coming in Phase 2'**
  String get dashboardComingSoon;

  /// No description provided for @yourAccount.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get yourAccount;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @emailVerifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get emailVerifiedLabel;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes ✓'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @defaultRiderName.
  ///
  /// In en, this message translates to:
  /// **'Cyclist'**
  String get defaultRiderName;

  /// No description provided for @tabMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get tabMap;

  /// No description provided for @tabActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get tabActivity;

  /// No description provided for @tabDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get tabDiscover;

  /// No description provided for @tabMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get tabMarketplace;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @tabProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get tabProvider;

  /// No description provided for @tabProviderOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Provider Onboarding'**
  String get tabProviderOnboarding;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @sectionRidingConditions.
  ///
  /// In en, this message translates to:
  /// **'Riding Conditions'**
  String get sectionRidingConditions;

  /// No description provided for @sectionTodayActivity.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Activity'**
  String get sectionTodayActivity;

  /// No description provided for @sectionQuickRoutes.
  ///
  /// In en, this message translates to:
  /// **'Quick Routes'**
  String get sectionQuickRoutes;

  /// No description provided for @sectionAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get sectionAlerts;

  /// No description provided for @sectionNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get sectionNearby;

  /// No description provided for @cykelFeatures.
  ///
  /// In en, this message translates to:
  /// **'CYKEL Features'**
  String get cykelFeatures;

  /// No description provided for @conditionScore.
  ///
  /// In en, this message translates to:
  /// **'{score}/10'**
  String conditionScore(String score);

  /// No description provided for @conditionGood.
  ///
  /// In en, this message translates to:
  /// **'Good conditions'**
  String get conditionGood;

  /// No description provided for @conditionFair.
  ///
  /// In en, this message translates to:
  /// **'Fair conditions'**
  String get conditionFair;

  /// No description provided for @conditionExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent conditions'**
  String get conditionExcellent;

  /// No description provided for @conditionPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor conditions'**
  String get conditionPoor;

  /// No description provided for @wind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get wind;

  /// No description provided for @rain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get rain;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temp'**
  String get temperature;

  /// No description provided for @kmToday.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String kmToday(String km);

  /// No description provided for @minToday.
  ///
  /// In en, this message translates to:
  /// **'{min} min'**
  String minToday(String min);

  /// No description provided for @dayStreak.
  ///
  /// In en, this message translates to:
  /// **'{days} day streak'**
  String dayStreak(int days);

  /// No description provided for @distanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distanceLabel;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// No description provided for @streakLabel.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streakLabel;

  /// No description provided for @noAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get noAlertsTitle;

  /// No description provided for @noAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No alerts in your area'**
  String get noAlertsSubtitle;

  /// No description provided for @noNearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing nearby yet'**
  String get noNearbyTitle;

  /// No description provided for @noNearbySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Services will appear here once you set your location'**
  String get noNearbySubtitle;

  /// No description provided for @addHomeRoute.
  ///
  /// In en, this message translates to:
  /// **'Set home'**
  String get addHomeRoute;

  /// No description provided for @addWorkRoute.
  ///
  /// In en, this message translates to:
  /// **'Set work'**
  String get addWorkRoute;

  /// No description provided for @routeHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get routeHome;

  /// No description provided for @routeWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get routeWork;

  /// No description provided for @quickRoutesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Save your home and work locations for quick navigation'**
  String get quickRoutesEmpty;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @savedPlaces.
  ///
  /// In en, this message translates to:
  /// **'Saved places'**
  String get savedPlaces;

  /// No description provided for @myBikes.
  ///
  /// In en, this message translates to:
  /// **'My Bikes'**
  String get myBikes;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationSettings;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettings;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @subscriptionSection.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionSection;

  /// No description provided for @freePlan.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freePlan;

  /// No description provided for @proPlan.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get proPlan;

  /// No description provided for @privacySettings.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacySettings;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This cannot be undone.'**
  String get deleteAccountConfirm;

  /// No description provided for @noBikesTitle.
  ///
  /// In en, this message translates to:
  /// **'No bikes yet'**
  String get noBikesTitle;

  /// No description provided for @noBikesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your bike to track rides and get personalised insights'**
  String get noBikesSubtitle;

  /// No description provided for @addBike.
  ///
  /// In en, this message translates to:
  /// **'Add bike'**
  String get addBike;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @comingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re building this feature.\nIt\'ll be worth the wait.'**
  String get comingSoonSubtitle;

  /// No description provided for @searchAddress.
  ///
  /// In en, this message translates to:
  /// **'Search address'**
  String get searchAddress;

  /// No description provided for @searchPlaces.
  ///
  /// In en, this message translates to:
  /// **'Search places...'**
  String get searchPlaces;

  /// No description provided for @mapLayers.
  ///
  /// In en, this message translates to:
  /// **'Map Layers'**
  String get mapLayers;

  /// No description provided for @layerCharging.
  ///
  /// In en, this message translates to:
  /// **'Charging Stations'**
  String get layerCharging;

  /// No description provided for @layerService.
  ///
  /// In en, this message translates to:
  /// **'Service Points'**
  String get layerService;

  /// No description provided for @layerShops.
  ///
  /// In en, this message translates to:
  /// **'Bike Shops'**
  String get layerShops;

  /// No description provided for @layerRental.
  ///
  /// In en, this message translates to:
  /// **'Rentals'**
  String get layerRental;

  /// No description provided for @layerRepair.
  ///
  /// In en, this message translates to:
  /// **'Repair Shops'**
  String get layerRepair;

  /// No description provided for @allDay.
  ///
  /// In en, this message translates to:
  /// **'Open 24/7'**
  String get allDay;

  /// No description provided for @nearbyCount.
  ///
  /// In en, this message translates to:
  /// **'{count} places nearby'**
  String nearbyCount(int count);

  /// No description provided for @noPlacesFound.
  ///
  /// In en, this message translates to:
  /// **'No places found'**
  String get noPlacesFound;

  /// No description provided for @tryChangingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try changing filters or search again'**
  String get tryChangingFilters;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @getDirections.
  ///
  /// In en, this message translates to:
  /// **'Get directions'**
  String get getDirections;

  /// No description provided for @startNavigation.
  ///
  /// In en, this message translates to:
  /// **'Start navigation'**
  String get startNavigation;

  /// No description provided for @stopNavigation.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopNavigation;

  /// No description provided for @calculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get calculating;

  /// No description provided for @calculateRoute.
  ///
  /// In en, this message translates to:
  /// **'Calculate route'**
  String get calculateRoute;

  /// No description provided for @yourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your location'**
  String get yourLocation;

  /// No description provided for @couldNotCalculateRoute.
  ///
  /// In en, this message translates to:
  /// **'Could not calculate route.'**
  String get couldNotCalculateRoute;

  /// No description provided for @locationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled.'**
  String get locationDisabled;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied.'**
  String get locationDenied;

  /// No description provided for @routeDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get routeDistance;

  /// No description provided for @routeDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get routeDuration;

  /// No description provided for @arrived.
  ///
  /// In en, this message translates to:
  /// **'You have arrived!'**
  String get arrived;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @chargingStation.
  ///
  /// In en, this message translates to:
  /// **'Charging Station'**
  String get chargingStation;

  /// No description provided for @servicePoint.
  ///
  /// In en, this message translates to:
  /// **'Service Point'**
  String get servicePoint;

  /// No description provided for @bikeShop.
  ///
  /// In en, this message translates to:
  /// **'Bike Shop'**
  String get bikeShop;

  /// No description provided for @rental.
  ///
  /// In en, this message translates to:
  /// **'Rental'**
  String get rental;

  /// No description provided for @visitWebsite.
  ///
  /// In en, this message translates to:
  /// **'Visit website'**
  String get visitWebsite;

  /// No description provided for @layerTraffic.
  ///
  /// In en, this message translates to:
  /// **'Traffic'**
  String get layerTraffic;

  /// No description provided for @layerBikeRoutes.
  ///
  /// In en, this message translates to:
  /// **'Bike Routes'**
  String get layerBikeRoutes;

  /// No description provided for @layerTransit.
  ///
  /// In en, this message translates to:
  /// **'Public Transit'**
  String get layerTransit;

  /// No description provided for @nightMode.
  ///
  /// In en, this message translates to:
  /// **'Night Mode'**
  String get nightMode;

  /// No description provided for @startRide.
  ///
  /// In en, this message translates to:
  /// **'Start Ride'**
  String get startRide;

  /// No description provided for @stopRide.
  ///
  /// In en, this message translates to:
  /// **'Stop Ride'**
  String get stopRide;

  /// No description provided for @pauseRide.
  ///
  /// In en, this message translates to:
  /// **'Pause Ride'**
  String get pauseRide;

  /// No description provided for @resumeRide.
  ///
  /// In en, this message translates to:
  /// **'Resume Ride'**
  String get resumeRide;

  /// No description provided for @calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get calories;

  /// No description provided for @elevation.
  ///
  /// In en, this message translates to:
  /// **'Elevation'**
  String get elevation;

  /// No description provided for @myRides.
  ///
  /// In en, this message translates to:
  /// **'My Rides'**
  String get myRides;

  /// No description provided for @rideHistory.
  ///
  /// In en, this message translates to:
  /// **'Ride History'**
  String get rideHistory;

  /// No description provided for @noRidesYet.
  ///
  /// In en, this message translates to:
  /// **'No rides yet'**
  String get noRidesYet;

  /// No description provided for @noRidesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap Start Ride to record your first journey'**
  String get noRidesSubtitle;

  /// No description provided for @noRidesToday.
  ///
  /// In en, this message translates to:
  /// **'No rides today yet'**
  String get noRidesToday;

  /// No description provided for @noRidesTodaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start your first ride'**
  String get noRidesTodaySubtitle;

  /// No description provided for @noQuickRoutesYet.
  ///
  /// In en, this message translates to:
  /// **'No quick routes yet'**
  String get noQuickRoutesYet;

  /// No description provided for @noQuickRoutesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your home and work locations'**
  String get noQuickRoutesSubtitle;

  /// No description provided for @startTrackingRides.
  ///
  /// In en, this message translates to:
  /// **'Start tracking your rides'**
  String get startTrackingRides;

  /// No description provided for @startTrackingRidesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your cycling stats will appear here'**
  String get startTrackingRidesSubtitle;

  /// No description provided for @avgSpeed.
  ///
  /// In en, this message translates to:
  /// **'Avg Speed'**
  String get avgSpeed;

  /// No description provided for @maxSpeed.
  ///
  /// In en, this message translates to:
  /// **'Max Speed'**
  String get maxSpeed;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @rideTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get rideTime;

  /// No description provided for @offRouteRecalc.
  ///
  /// In en, this message translates to:
  /// **'Off route — recalculating…'**
  String get offRouteRecalc;

  /// No description provided for @longPressHint.
  ///
  /// In en, this message translates to:
  /// **'Long press on map to set destination'**
  String get longPressHint;

  /// No description provided for @stepsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} steps'**
  String stepsRemaining(int count);

  /// No description provided for @errInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get errInvalidCredential;

  /// No description provided for @errEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get errEmailInUse;

  /// No description provided for @errWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak (min. 8 characters).'**
  String get errWeakPassword;

  /// No description provided for @errInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address.'**
  String get errInvalidEmail;

  /// No description provided for @errNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get errNoInternet;

  /// No description provided for @errTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get errTooManyRequests;

  /// No description provided for @errUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get errUserDisabled;

  /// No description provided for @errRequiresRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to continue.'**
  String get errRequiresRecentLogin;

  /// No description provided for @errCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in was cancelled.'**
  String get errCancelled;

  /// No description provided for @errGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errGeneric;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @droppedPin.
  ///
  /// In en, this message translates to:
  /// **'Dropped pin'**
  String get droppedPin;

  /// No description provided for @clearRoute.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearRoute;

  /// No description provided for @setHomeAddress.
  ///
  /// In en, this message translates to:
  /// **'Set Home Address'**
  String get setHomeAddress;

  /// No description provided for @setWorkAddress.
  ///
  /// In en, this message translates to:
  /// **'Set Work Address'**
  String get setWorkAddress;

  /// No description provided for @tapToRoute.
  ///
  /// In en, this message translates to:
  /// **'Tap to navigate'**
  String get tapToRoute;

  /// No description provided for @addressSearch.
  ///
  /// In en, this message translates to:
  /// **'Search for an address…'**
  String get addressSearch;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @arriveAt.
  ///
  /// In en, this message translates to:
  /// **'Arrive {time}'**
  String arriveAt(String time);

  /// No description provided for @noRouteFound.
  ///
  /// In en, this message translates to:
  /// **'No cycling route found between these locations.'**
  String get noRouteFound;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to show your position.'**
  String get locationPermissionRequired;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @gpsSignalLost.
  ///
  /// In en, this message translates to:
  /// **'GPS signal lost'**
  String get gpsSignalLost;

  /// No description provided for @routeOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get routeOverview;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentSearches;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My Location'**
  String get myLocation;

  /// No description provided for @setOnMap.
  ///
  /// In en, this message translates to:
  /// **'Set on map'**
  String get setOnMap;

  /// No description provided for @searchingHint.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get searchingHint;

  /// No description provided for @inDistance.
  ///
  /// In en, this message translates to:
  /// **'In {dist}, {instruction}'**
  String inDistance(String dist, String instruction);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm location'**
  String get confirmPin;

  /// No description provided for @placeDetails.
  ///
  /// In en, this message translates to:
  /// **'Place Details'**
  String get placeDetails;

  /// No description provided for @setAsDestination.
  ///
  /// In en, this message translates to:
  /// **'Set as destination'**
  String get setAsDestination;

  /// No description provided for @setAsOrigin.
  ///
  /// In en, this message translates to:
  /// **'Set as starting point'**
  String get setAsOrigin;

  /// No description provided for @mapStyle.
  ///
  /// In en, this message translates to:
  /// **'Map Style'**
  String get mapStyle;

  /// No description provided for @satellite.
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get satellite;

  /// No description provided for @normalMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get normalMap;

  /// No description provided for @terrain.
  ///
  /// In en, this message translates to:
  /// **'Terrain'**
  String get terrain;

  /// No description provided for @routeOption.
  ///
  /// In en, this message translates to:
  /// **'Route {index}'**
  String routeOption(int index);

  /// No description provided for @bikeProfile.
  ///
  /// In en, this message translates to:
  /// **'Bike profile'**
  String get bikeProfile;

  /// No description provided for @bikeProfileCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get bikeProfileCity;

  /// No description provided for @bikeProfileEbike.
  ///
  /// In en, this message translates to:
  /// **'E-Bike'**
  String get bikeProfileEbike;

  /// No description provided for @bikeProfileRoad.
  ///
  /// In en, this message translates to:
  /// **'Road'**
  String get bikeProfileRoad;

  /// No description provided for @bikeProfileCargo.
  ///
  /// In en, this message translates to:
  /// **'Cargo'**
  String get bikeProfileCargo;

  /// No description provided for @bikeProfileFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get bikeProfileFamily;

  /// No description provided for @bikeTypeCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get bikeTypeCity;

  /// No description provided for @bikeTypeRoad.
  ///
  /// In en, this message translates to:
  /// **'Road'**
  String get bikeTypeRoad;

  /// No description provided for @bikeTypeEbike.
  ///
  /// In en, this message translates to:
  /// **'E-bike'**
  String get bikeTypeEbike;

  /// No description provided for @bikeTypeCargo.
  ///
  /// In en, this message translates to:
  /// **'Cargo'**
  String get bikeTypeCargo;

  /// No description provided for @bikeTypeMountain.
  ///
  /// In en, this message translates to:
  /// **'Mountain'**
  String get bikeTypeMountain;

  /// No description provided for @windHeadwind.
  ///
  /// In en, this message translates to:
  /// **'Headwind · {speed} km/h — expect longer ETA'**
  String windHeadwind(String speed);

  /// No description provided for @windTailwind.
  ///
  /// In en, this message translates to:
  /// **'Tailwind · {speed} km/h — great conditions!'**
  String windTailwind(String speed);

  /// No description provided for @windCrosswind.
  ///
  /// In en, this message translates to:
  /// **'Crosswind · {speed} km/h'**
  String windCrosswind(String speed);

  /// No description provided for @saveRoute.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveRoute;

  /// No description provided for @routeSaved.
  ///
  /// In en, this message translates to:
  /// **'Route saved'**
  String get routeSaved;

  /// No description provided for @routeUnsaved.
  ///
  /// In en, this message translates to:
  /// **'Route removed'**
  String get routeUnsaved;

  /// No description provided for @savedRoutes.
  ///
  /// In en, this message translates to:
  /// **'Saved routes'**
  String get savedRoutes;

  /// No description provided for @rerouteComplete.
  ///
  /// In en, this message translates to:
  /// **'Route updated'**
  String get rerouteComplete;

  /// No description provided for @rerouteFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot recalculate route'**
  String get rerouteFailed;

  /// No description provided for @offlineNavBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline — navigation continues. Rerouting paused.'**
  String get offlineNavBanner;

  /// No description provided for @resumeNavigationPrompt.
  ///
  /// In en, this message translates to:
  /// **'Resume navigation to {dest}?'**
  String resumeNavigationPrompt(String dest);

  /// No description provided for @resumeNavigationAction.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeNavigationAction;

  /// No description provided for @hazardIce.
  ///
  /// In en, this message translates to:
  /// **'⚠ Icy surfaces — ride carefully'**
  String get hazardIce;

  /// No description provided for @hazardFreeze.
  ///
  /// In en, this message translates to:
  /// **'⚠ Freezing temperatures'**
  String get hazardFreeze;

  /// No description provided for @hazardStrongWind.
  ///
  /// In en, this message translates to:
  /// **'⚠ Strong wind — exposed routes may be difficult'**
  String get hazardStrongWind;

  /// No description provided for @hazardHeavyRain.
  ///
  /// In en, this message translates to:
  /// **'Heavy rain'**
  String get hazardHeavyRain;

  /// No description provided for @hazardWetSurface.
  ///
  /// In en, this message translates to:
  /// **'⚠ Slippery surfaces — near-zero temperatures'**
  String get hazardWetSurface;

  /// No description provided for @hazardSnow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get hazardSnow;

  /// No description provided for @hazardTypeRoadDamage.
  ///
  /// In en, this message translates to:
  /// **'Road damage'**
  String get hazardTypeRoadDamage;

  /// No description provided for @hazardTypeAccident.
  ///
  /// In en, this message translates to:
  /// **'Accident'**
  String get hazardTypeAccident;

  /// No description provided for @hazardTypeDebris.
  ///
  /// In en, this message translates to:
  /// **'Debris / glass'**
  String get hazardTypeDebris;

  /// No description provided for @hazardTypeRoadClosed.
  ///
  /// In en, this message translates to:
  /// **'Road closed'**
  String get hazardTypeRoadClosed;

  /// No description provided for @hazardTypeBadSurface.
  ///
  /// In en, this message translates to:
  /// **'Bad surface'**
  String get hazardTypeBadSurface;

  /// No description provided for @hazardTypeFlooding.
  ///
  /// In en, this message translates to:
  /// **'Flooding'**
  String get hazardTypeFlooding;

  /// No description provided for @reportHazardTitle.
  ///
  /// In en, this message translates to:
  /// **'Report hazard'**
  String get reportHazardTitle;

  /// No description provided for @reportHazardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your report helps other riders. Reports expire after 8 hours.'**
  String get reportHazardSubtitle;

  /// No description provided for @reportHazardSubmit.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportHazardSubmit;

  /// No description provided for @reportHazardThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks! Hazard reported.'**
  String get reportHazardThanks;

  /// No description provided for @addStop.
  ///
  /// In en, this message translates to:
  /// **'Add stop'**
  String get addStop;

  /// No description provided for @sectionFrequentRoutes.
  ///
  /// In en, this message translates to:
  /// **'Frequent Routes'**
  String get sectionFrequentRoutes;

  /// No description provided for @frequentRoutesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Navigate somewhere to see your frequent routes here'**
  String get frequentRoutesEmpty;

  /// No description provided for @frequentVisitCount.
  ///
  /// In en, this message translates to:
  /// **'{count}× visited'**
  String frequentVisitCount(int count);

  /// No description provided for @commuteMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning commute'**
  String get commuteMorning;

  /// No description provided for @commuteEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening commute'**
  String get commuteEvening;

  /// No description provided for @startCommute.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startCommute;

  /// No description provided for @navModLeft.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get navModLeft;

  /// No description provided for @navModRight.
  ///
  /// In en, this message translates to:
  /// **'right'**
  String get navModRight;

  /// No description provided for @navModStraight.
  ///
  /// In en, this message translates to:
  /// **'straight'**
  String get navModStraight;

  /// No description provided for @navModSlightLeft.
  ///
  /// In en, this message translates to:
  /// **'slight left'**
  String get navModSlightLeft;

  /// No description provided for @navModSlightRight.
  ///
  /// In en, this message translates to:
  /// **'slight right'**
  String get navModSlightRight;

  /// No description provided for @navModSharpLeft.
  ///
  /// In en, this message translates to:
  /// **'sharp left'**
  String get navModSharpLeft;

  /// No description provided for @navModSharpRight.
  ///
  /// In en, this message translates to:
  /// **'sharp right'**
  String get navModSharpRight;

  /// No description provided for @navModUturn.
  ///
  /// In en, this message translates to:
  /// **'U-turn'**
  String get navModUturn;

  /// No description provided for @navDepart.
  ///
  /// In en, this message translates to:
  /// **'Head {dir} on {road}'**
  String navDepart(String dir, String road);

  /// No description provided for @navDepartBlind.
  ///
  /// In en, this message translates to:
  /// **'Head {dir}'**
  String navDepartBlind(String dir);

  /// No description provided for @navArrive.
  ///
  /// In en, this message translates to:
  /// **'You have arrived'**
  String get navArrive;

  /// No description provided for @navArriveAt.
  ///
  /// In en, this message translates to:
  /// **'Arrived at {road}'**
  String navArriveAt(String road);

  /// No description provided for @navTurn.
  ///
  /// In en, this message translates to:
  /// **'Turn {dir} onto {road}'**
  String navTurn(String dir, String road);

  /// No description provided for @navTurnBlind.
  ///
  /// In en, this message translates to:
  /// **'Turn {dir}'**
  String navTurnBlind(String dir);

  /// No description provided for @navContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue on {road}'**
  String navContinue(String road);

  /// No description provided for @navContinueBlind.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get navContinueBlind;

  /// No description provided for @navMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge onto {road}'**
  String navMerge(String road);

  /// No description provided for @navMergeBlind.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get navMergeBlind;

  /// No description provided for @navFork.
  ///
  /// In en, this message translates to:
  /// **'Keep {dir} at the fork onto {road}'**
  String navFork(String dir, String road);

  /// No description provided for @navForkBlind.
  ///
  /// In en, this message translates to:
  /// **'Keep {dir} at the fork'**
  String navForkBlind(String dir);

  /// No description provided for @navEndOfRoad.
  ///
  /// In en, this message translates to:
  /// **'Turn {dir} at end of road onto {road}'**
  String navEndOfRoad(String dir, String road);

  /// No description provided for @navEndOfRoadBlind.
  ///
  /// In en, this message translates to:
  /// **'Turn {dir} at end of road'**
  String navEndOfRoadBlind(String dir);

  /// No description provided for @navRoundabout.
  ///
  /// In en, this message translates to:
  /// **'Enter the roundabout'**
  String get navRoundabout;

  /// No description provided for @navRoundaboutNamed.
  ///
  /// In en, this message translates to:
  /// **'Enter the roundabout — {road}'**
  String navRoundaboutNamed(String road);

  /// No description provided for @navExitRoundabout.
  ///
  /// In en, this message translates to:
  /// **'Exit the roundabout'**
  String get navExitRoundabout;

  /// No description provided for @navExitRoundaboutOnto.
  ///
  /// In en, this message translates to:
  /// **'Exit the roundabout onto {road}'**
  String navExitRoundaboutOnto(String road);

  /// No description provided for @navNewName.
  ///
  /// In en, this message translates to:
  /// **'Continue onto {road}'**
  String navNewName(String road);

  /// No description provided for @navUseLane.
  ///
  /// In en, this message translates to:
  /// **'Use the {dir} lane onto {road}'**
  String navUseLane(String dir, String road);

  /// No description provided for @navUseLaneBlind.
  ///
  /// In en, this message translates to:
  /// **'Use the {dir} lane'**
  String navUseLaneBlind(String dir);

  /// No description provided for @navWaypointReached.
  ///
  /// In en, this message translates to:
  /// **'Stop {n} reached — continuing to destination'**
  String navWaypointReached(int n);

  /// No description provided for @navMaxReroutesReached.
  ///
  /// In en, this message translates to:
  /// **'Too many recalculations — continuing on current route'**
  String get navMaxReroutesReached;

  /// No description provided for @discoverActiveHazards.
  ///
  /// In en, this message translates to:
  /// **'Active Hazards'**
  String get discoverActiveHazards;

  /// No description provided for @discoverNoHazards.
  ///
  /// In en, this message translates to:
  /// **'No active hazards nearby'**
  String get discoverNoHazards;

  /// No description provided for @discoverNoSaved.
  ///
  /// In en, this message translates to:
  /// **'No saved routes yet'**
  String get discoverNoSaved;

  /// No description provided for @discoverCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get discoverCategories;

  /// No description provided for @marketplaceBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get marketplaceBrowse;

  /// No description provided for @marketplaceSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get marketplaceSaved;

  /// No description provided for @marketplaceMyListings.
  ///
  /// In en, this message translates to:
  /// **'My Listings'**
  String get marketplaceMyListings;

  /// No description provided for @marketplaceMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get marketplaceMessages;

  /// No description provided for @marketplaceSell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get marketplaceSell;

  /// No description provided for @listingCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get listingCategoryAll;

  /// No description provided for @listingCategoryBike.
  ///
  /// In en, this message translates to:
  /// **'Bikes'**
  String get listingCategoryBike;

  /// No description provided for @listingCategoryParts.
  ///
  /// In en, this message translates to:
  /// **'Parts'**
  String get listingCategoryParts;

  /// No description provided for @listingCategoryAccessories.
  ///
  /// In en, this message translates to:
  /// **'Accessories'**
  String get listingCategoryAccessories;

  /// No description provided for @listingCategoryClothing.
  ///
  /// In en, this message translates to:
  /// **'Clothing & Gear'**
  String get listingCategoryClothing;

  /// No description provided for @listingCategoryTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get listingCategoryTools;

  /// No description provided for @listingConditionNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get listingConditionNew;

  /// No description provided for @listingConditionLikeNew.
  ///
  /// In en, this message translates to:
  /// **'Like New'**
  String get listingConditionLikeNew;

  /// No description provided for @listingConditionGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get listingConditionGood;

  /// No description provided for @listingConditionFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get listingConditionFair;

  /// No description provided for @listingContactSeller.
  ///
  /// In en, this message translates to:
  /// **'Contact Seller'**
  String get listingContactSeller;

  /// No description provided for @listingCallSeller.
  ///
  /// In en, this message translates to:
  /// **'Call Seller'**
  String get listingCallSeller;

  /// No description provided for @listingPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Phone number (optional)'**
  String get listingPhoneHint;

  /// No description provided for @listingMarkSold.
  ///
  /// In en, this message translates to:
  /// **'Mark as Sold'**
  String get listingMarkSold;

  /// No description provided for @listingEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit Listing'**
  String get listingEditAction;

  /// No description provided for @listingDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get listingDeleteAction;

  /// No description provided for @listingSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get listingSave;

  /// No description provided for @listingUnsave.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get listingUnsave;

  /// No description provided for @chatMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chatMessageHint;

  /// No description provided for @chatSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// No description provided for @listingPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish Listing'**
  String get listingPublish;

  /// No description provided for @listingPrivateSeller.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get listingPrivateSeller;

  /// No description provided for @listingShopSeller.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get listingShopSeller;

  /// No description provided for @listingNoResults.
  ///
  /// In en, this message translates to:
  /// **'No listings found'**
  String get listingNoResults;

  /// No description provided for @listingMyListingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t listed anything yet'**
  String get listingMyListingsEmpty;

  /// No description provided for @listingSavedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved listings yet'**
  String get listingSavedEmpty;

  /// No description provided for @listingNoMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get listingNoMessages;

  /// No description provided for @listingReport.
  ///
  /// In en, this message translates to:
  /// **'Report listing'**
  String get listingReport;

  /// No description provided for @listingSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get listingSortNewest;

  /// No description provided for @listingSortPriceLow.
  ///
  /// In en, this message translates to:
  /// **'Price: Low to High'**
  String get listingSortPriceLow;

  /// No description provided for @listingSortPriceHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: High to Low'**
  String get listingSortPriceHigh;

  /// No description provided for @listingCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New Listing'**
  String get listingCreateTitle;

  /// No description provided for @listingEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Listing'**
  String get listingEditTitle;

  /// No description provided for @listingPublished.
  ///
  /// In en, this message translates to:
  /// **'Listing published!'**
  String get listingPublished;

  /// No description provided for @listingDeleted.
  ///
  /// In en, this message translates to:
  /// **'Listing deleted'**
  String get listingDeleted;

  /// No description provided for @listingMarkedSold.
  ///
  /// In en, this message translates to:
  /// **'Marked as sold'**
  String get listingMarkedSold;

  /// No description provided for @listingTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Trek FX3 City Bike'**
  String get listingTitleHint;

  /// No description provided for @listingDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe condition'**
  String get listingDescriptionHint;

  /// No description provided for @listingPriceHint.
  ///
  /// In en, this message translates to:
  /// **'Price in DKK'**
  String get listingPriceHint;

  /// No description provided for @listingCityHint.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get listingCityHint;

  /// No description provided for @listingAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get listingAddPhotos;

  /// No description provided for @listingConditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get listingConditionLabel;

  /// No description provided for @listingCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get listingCategoryLabel;

  /// No description provided for @listingSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get listingSortBy;

  /// No description provided for @listingViews.
  ///
  /// In en, this message translates to:
  /// **'{count} views'**
  String listingViews(int count);

  /// No description provided for @listingPostedAgo.
  ///
  /// In en, this message translates to:
  /// **'Posted {ago}'**
  String listingPostedAgo(String ago);

  /// No description provided for @listingSoldBadge.
  ///
  /// In en, this message translates to:
  /// **'SOLD'**
  String get listingSoldBadge;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search listings...'**
  String get searchHint;

  /// No description provided for @co2ImpactTitle.
  ///
  /// In en, this message translates to:
  /// **'Climate Impact'**
  String get co2ImpactTitle;

  /// No description provided for @co2Saved.
  ///
  /// In en, this message translates to:
  /// **'CO₂ Saved'**
  String get co2Saved;

  /// No description provided for @fuelSaved.
  ///
  /// In en, this message translates to:
  /// **'Fuel Saved'**
  String get fuelSaved;

  /// No description provided for @caloriesBurned.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get caloriesBurned;

  /// No description provided for @hazardSeverityLabel.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get hazardSeverityLabel;

  /// No description provided for @hazardSeverityInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get hazardSeverityInfo;

  /// No description provided for @hazardSeverityCaution.
  ///
  /// In en, this message translates to:
  /// **'Caution'**
  String get hazardSeverityCaution;

  /// No description provided for @hazardSeverityDanger.
  ///
  /// In en, this message translates to:
  /// **'Danger'**
  String get hazardSeverityDanger;

  /// No description provided for @hazardFog.
  ///
  /// In en, this message translates to:
  /// **'⚠ Fog — reduced visibility, use lights'**
  String get hazardFog;

  /// No description provided for @hazardLowVisibility.
  ///
  /// In en, this message translates to:
  /// **'⚠ Very low visibility — extreme caution'**
  String get hazardLowVisibility;

  /// No description provided for @hazardDarkness.
  ///
  /// In en, this message translates to:
  /// **'⚠ Riding in the dark — use front and rear lights'**
  String get hazardDarkness;

  /// No description provided for @routeHazardWarning.
  ///
  /// In en, this message translates to:
  /// **'{count} hazard(s) on your route'**
  String routeHazardWarning(int count);

  /// No description provided for @infraReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Infrastructure Issue'**
  String get infraReportTitle;

  /// No description provided for @infraReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help improve cycling infrastructure in your city.'**
  String get infraReportSubtitle;

  /// No description provided for @infraReportDescHint.
  ///
  /// In en, this message translates to:
  /// **'Optional: describe the issue in more detail...'**
  String get infraReportDescHint;

  /// No description provided for @infraReportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get infraReportSubmit;

  /// No description provided for @infraReportThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks! Report submitted.'**
  String get infraReportThanks;

  /// No description provided for @infraMissingLane.
  ///
  /// In en, this message translates to:
  /// **'Missing lane'**
  String get infraMissingLane;

  /// No description provided for @infraBrokenPavement.
  ///
  /// In en, this message translates to:
  /// **'Broken pavement'**
  String get infraBrokenPavement;

  /// No description provided for @infraPoorLighting.
  ///
  /// In en, this message translates to:
  /// **'Poor lighting'**
  String get infraPoorLighting;

  /// No description provided for @infraLackingSignage.
  ///
  /// In en, this message translates to:
  /// **'Lacking signage'**
  String get infraLackingSignage;

  /// No description provided for @infraBlockedLane.
  ///
  /// In en, this message translates to:
  /// **'Blocked lane'**
  String get infraBlockedLane;

  /// No description provided for @infraMissingRamp.
  ///
  /// In en, this message translates to:
  /// **'Missing ramp'**
  String get infraMissingRamp;

  /// No description provided for @infraOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get infraOther;

  /// No description provided for @gdprTitle.
  ///
  /// In en, this message translates to:
  /// **'Your data, your choice'**
  String get gdprTitle;

  /// No description provided for @gdprSubtitle.
  ///
  /// In en, this message translates to:
  /// **'CYKEL collects only the data needed to make cycling safer and more enjoyable. Review what we use and choose your optional settings below.'**
  String get gdprSubtitle;

  /// No description provided for @gdprLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get gdprLocationTitle;

  /// No description provided for @gdprLocationBody.
  ///
  /// In en, this message translates to:
  /// **'Used for navigation, route planning, and nearby hazard detection. Never shared without your consent.'**
  String get gdprLocationBody;

  /// No description provided for @gdprRidesTitle.
  ///
  /// In en, this message translates to:
  /// **'Ride data'**
  String get gdprRidesTitle;

  /// No description provided for @gdprRidesBody.
  ///
  /// In en, this message translates to:
  /// **'Stored locally on your device. Used to calculate stats and CO₂ impact. Not uploaded to our servers.'**
  String get gdprRidesBody;

  /// No description provided for @gdprOptionalTitle.
  ///
  /// In en, this message translates to:
  /// **'Optional features'**
  String get gdprOptionalTitle;

  /// No description provided for @gdprAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Usage analytics'**
  String get gdprAnalyticsTitle;

  /// No description provided for @gdprAnalyticsBody.
  ///
  /// In en, this message translates to:
  /// **'Anonymous app usage data to help us improve CYKEL. No location or personal data.'**
  String get gdprAnalyticsBody;

  /// No description provided for @gdprAggregationTitle.
  ///
  /// In en, this message translates to:
  /// **'Mobility aggregation'**
  String get gdprAggregationTitle;

  /// No description provided for @gdprAggregationBody.
  ///
  /// In en, this message translates to:
  /// **'Anonymised, aggregated ride patterns shared with urban planners to improve cycling infrastructure.'**
  String get gdprAggregationBody;

  /// No description provided for @gdprPrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'You can change these settings at any time in Profile → Privacy. For full details see our Privacy Policy.'**
  String get gdprPrivacyNotice;

  /// No description provided for @gdprAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept & Continue'**
  String get gdprAccept;

  /// No description provided for @gdprSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get gdprSectionTitle;

  /// No description provided for @exportMyData.
  ///
  /// In en, this message translates to:
  /// **'Export my data'**
  String get exportMyData;

  /// No description provided for @dataExported.
  ///
  /// In en, this message translates to:
  /// **'Data exported successfully'**
  String get dataExported;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @sosButton.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sosButton;

  /// No description provided for @sosTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get sosTitle;

  /// No description provided for @sosCall112.
  ///
  /// In en, this message translates to:
  /// **'Call 112 (Emergency Services)'**
  String get sosCall112;

  /// No description provided for @sosCall112Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Police, Fire & Ambulance'**
  String get sosCall112Subtitle;

  /// No description provided for @sosShareLocation.
  ///
  /// In en, this message translates to:
  /// **'Copy my location'**
  String get sosShareLocation;

  /// No description provided for @sosReportAccident.
  ///
  /// In en, this message translates to:
  /// **'Report an accident'**
  String get sosReportAccident;

  /// No description provided for @sosReportAccidentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Submit an incident report to CYKEL'**
  String get sosReportAccidentSubtitle;

  /// No description provided for @sosAccidentDescHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what happened (optional)...'**
  String get sosAccidentDescHint;

  /// No description provided for @sosReportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get sosReportSubmit;

  /// No description provided for @sosLocationCopied.
  ///
  /// In en, this message translates to:
  /// **'Location copied to clipboard'**
  String get sosLocationCopied;

  /// No description provided for @sosAccidentReported.
  ///
  /// In en, this message translates to:
  /// **'Accident report submitted. Stay safe.'**
  String get sosAccidentReported;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @savedPlacesTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Places'**
  String get savedPlacesTitle;

  /// No description provided for @homePlace.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homePlace;

  /// No description provided for @workPlace.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get workPlace;

  /// No description provided for @enterAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter address...'**
  String get enterAddress;

  /// No description provided for @addressSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get addressSaved;

  /// No description provided for @noAddressSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get noAddressSet;

  /// No description provided for @addBikeTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Bike'**
  String get addBikeTitle;

  /// No description provided for @bikeName.
  ///
  /// In en, this message translates to:
  /// **'Bike name'**
  String get bikeName;

  /// No description provided for @bikeBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand (optional)'**
  String get bikeBrand;

  /// No description provided for @bikeYear.
  ///
  /// In en, this message translates to:
  /// **'Year (optional)'**
  String get bikeYear;

  /// No description provided for @bikeAdded.
  ///
  /// In en, this message translates to:
  /// **'Bike added'**
  String get bikeAdded;

  /// No description provided for @bikeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Bike removed'**
  String get bikeDeleted;

  /// No description provided for @bikeDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this bike?'**
  String get bikeDeleteConfirm;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notifRideReminders.
  ///
  /// In en, this message translates to:
  /// **'Ride reminders'**
  String get notifRideReminders;

  /// No description provided for @notifHazardAlerts.
  ///
  /// In en, this message translates to:
  /// **'Hazard alerts'**
  String get notifHazardAlerts;

  /// No description provided for @notifMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace messages'**
  String get notifMarketplace;

  /// No description provided for @notifMarketing.
  ///
  /// In en, this message translates to:
  /// **'Product updates & tips'**
  String get notifMarketing;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageDanish.
  ///
  /// In en, this message translates to:
  /// **'Danish'**
  String get languageDanish;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpTitle;

  /// No description provided for @helpEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'support@cykel.app'**
  String get helpEmailAddress;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyTitle;

  /// No description provided for @revokeConsent.
  ///
  /// In en, this message translates to:
  /// **'Revoke all consent'**
  String get revokeConsent;

  /// No description provided for @consentRevoked.
  ///
  /// In en, this message translates to:
  /// **'All consent revoked'**
  String get consentRevoked;

  /// No description provided for @addPlaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Place'**
  String get addPlaceTitle;

  /// No description provided for @placeName.
  ///
  /// In en, this message translates to:
  /// **'Place name'**
  String get placeName;

  /// No description provided for @placeAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get placeAddress;

  /// No description provided for @placeAdded.
  ///
  /// In en, this message translates to:
  /// **'Place added'**
  String get placeAdded;

  /// No description provided for @placeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Place removed'**
  String get placeDeleted;

  /// No description provided for @customPlaces.
  ///
  /// In en, this message translates to:
  /// **'Other places'**
  String get customPlaces;

  /// No description provided for @noCustomPlaces.
  ///
  /// In en, this message translates to:
  /// **'No custom places yet'**
  String get noCustomPlaces;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// No description provided for @privacyPolicyReadInApp.
  ///
  /// In en, this message translates to:
  /// **'Read in app'**
  String get privacyPolicyReadInApp;

  /// No description provided for @premiumFeature.
  ///
  /// In en, this message translates to:
  /// **'Premium Feature'**
  String get premiumFeature;

  /// No description provided for @upgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradeToPremium;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @submitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitButton;

  /// No description provided for @premiumPlan.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premiumPlan;

  /// No description provided for @ridingConditions.
  ///
  /// In en, this message translates to:
  /// **'Riding conditions'**
  String get ridingConditions;

  /// No description provided for @feelsLike.
  ///
  /// In en, this message translates to:
  /// **'feels {temp}°'**
  String feelsLike(String temp);

  /// No description provided for @battery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get battery;

  /// No description provided for @warningCachedData.
  ///
  /// In en, this message translates to:
  /// **'⚠️  Cached data'**
  String get warningCachedData;

  /// No description provided for @warningIceRisk.
  ///
  /// In en, this message translates to:
  /// **'⚠️  Ice risk'**
  String get warningIceRisk;

  /// No description provided for @warningStrongWind.
  ///
  /// In en, this message translates to:
  /// **'💨  Strong wind'**
  String get warningStrongWind;

  /// No description provided for @warningCold.
  ///
  /// In en, this message translates to:
  /// **'🥶  Cold'**
  String get warningCold;

  /// No description provided for @shortcutHomeToWork.
  ///
  /// In en, this message translates to:
  /// **'Home → Work'**
  String get shortcutHomeToWork;

  /// No description provided for @shortcutWorkToHome.
  ///
  /// In en, this message translates to:
  /// **'Work → Home'**
  String get shortcutWorkToHome;

  /// No description provided for @activityStats.
  ///
  /// In en, this message translates to:
  /// **'Activity Stats'**
  String get activityStats;

  /// No description provided for @rideCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} rides'**
  String rideCountLabel(int count);

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @dayUnit.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get dayUnit;

  /// No description provided for @daysUnit.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysUnit;

  /// No description provided for @noWeatherAlerts.
  ///
  /// In en, this message translates to:
  /// **'No Weather Alerts'**
  String get noWeatherAlerts;

  /// No description provided for @conditionsGoodForCycling.
  ///
  /// In en, this message translates to:
  /// **'Conditions are good for cycling'**
  String get conditionsGoodForCycling;

  /// No description provided for @weatherAlerts.
  ///
  /// In en, this message translates to:
  /// **'Weather Alerts'**
  String get weatherAlerts;

  /// No description provided for @lowSeverity.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get lowSeverity;

  /// No description provided for @mediumSeverity.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get mediumSeverity;

  /// No description provided for @highSeverity.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get highSeverity;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @noNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up! Notifications will appear here.'**
  String get noNotificationsDesc;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @weatherUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Weather Unavailable'**
  String get weatherUnavailable;

  /// No description provided for @unableToCheckWeather.
  ///
  /// In en, this message translates to:
  /// **'Unable to check weather conditions'**
  String get unableToCheckWeather;

  /// No description provided for @maintenanceDue.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Due'**
  String get maintenanceDue;

  /// No description provided for @maintenanceBody.
  ///
  /// In en, this message translates to:
  /// **'Your bike has ridden {km}km since last service'**
  String maintenanceBody(String km);

  /// No description provided for @markDone.
  ///
  /// In en, this message translates to:
  /// **'Mark Done'**
  String get markDone;

  /// No description provided for @couldNotLoadNearby.
  ///
  /// In en, this message translates to:
  /// **'Could not load nearby places'**
  String get couldNotLoadNearby;

  /// No description provided for @checkConnectionRetry.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again'**
  String get checkConnectionRetry;

  /// No description provided for @noBikePlacesNearby.
  ///
  /// In en, this message translates to:
  /// **'No bike places nearby'**
  String get noBikePlacesNearby;

  /// No description provided for @tryCyclingMoreInfra.
  ///
  /// In en, this message translates to:
  /// **'Try cycling to an area with more infrastructure'**
  String get tryCyclingMoreInfra;

  /// No description provided for @bikeRental.
  ///
  /// In en, this message translates to:
  /// **'Bike Rental'**
  String get bikeRental;

  /// No description provided for @repairStation.
  ///
  /// In en, this message translates to:
  /// **'Repair Station'**
  String get repairStation;

  /// No description provided for @dayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get daySun;

  /// No description provided for @monthJan.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get monthDec;

  /// No description provided for @monthlyChallenge.
  ///
  /// In en, this message translates to:
  /// **'{month} Challenge'**
  String monthlyChallenge(String month);

  /// No description provided for @challengeRideCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{ride} other{rides}}'**
  String challengeRideCount(int count);

  /// No description provided for @premiumBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wind routing · Analytics · Offline · E-Bike — kr 20/mo'**
  String get premiumBannerSubtitle;

  /// No description provided for @eBikeRange.
  ///
  /// In en, this message translates to:
  /// **'E-Bike Range'**
  String get eBikeRange;

  /// No description provided for @batteryPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% battery'**
  String batteryPercent(int percent);

  /// No description provided for @rangeRemaining.
  ///
  /// In en, this message translates to:
  /// **'≈ {range} remaining'**
  String rangeRemaining(String range);

  /// No description provided for @lowBattery.
  ///
  /// In en, this message translates to:
  /// **'⚠ Low battery'**
  String get lowBattery;

  /// No description provided for @tabLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get tabLive;

  /// No description provided for @tabAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get tabAnalytics;

  /// No description provided for @rideSavedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Ride saved: {distance}'**
  String rideSavedSnackbar(String distance);

  /// No description provided for @replay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get replay;

  /// No description provided for @gpxLabel.
  ///
  /// In en, this message translates to:
  /// **'GPX'**
  String get gpxLabel;

  /// No description provided for @noGpsPathToExport.
  ///
  /// In en, this message translates to:
  /// **'No GPS path to export.'**
  String get noGpsPathToExport;

  /// No description provided for @gpxExportTitle.
  ///
  /// In en, this message translates to:
  /// **'GPX Export'**
  String get gpxExportTitle;

  /// No description provided for @gpxFileSavedTo.
  ///
  /// In en, this message translates to:
  /// **'File saved to:\n{path}'**
  String gpxFileSavedTo(String path);

  /// No description provided for @copyGpxToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy GPX to clipboard'**
  String get copyGpxToClipboard;

  /// No description provided for @gpxCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'GPX copied to clipboard'**
  String get gpxCopiedToClipboard;

  /// No description provided for @premiumAnalyticsBody.
  ///
  /// In en, this message translates to:
  /// **'Detailed ride analytics are available with a Premium subscription.'**
  String get premiumAnalyticsBody;

  /// No description provided for @periodSummaries.
  ///
  /// In en, this message translates to:
  /// **'Period Summaries'**
  String get periodSummaries;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// No description provided for @personalRecords.
  ///
  /// In en, this message translates to:
  /// **'Personal Records'**
  String get personalRecords;

  /// No description provided for @completeFirstRide.
  ///
  /// In en, this message translates to:
  /// **'Complete your first ride to see records.'**
  String get completeFirstRide;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @kcalUnit.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get kcalUnit;

  /// No description provided for @climb.
  ///
  /// In en, this message translates to:
  /// **'Climb'**
  String get climb;

  /// No description provided for @savedLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedLabel;

  /// No description provided for @ridesLabel.
  ///
  /// In en, this message translates to:
  /// **'Rides'**
  String get ridesLabel;

  /// No description provided for @longestRide.
  ///
  /// In en, this message translates to:
  /// **'Longest Ride'**
  String get longestRide;

  /// No description provided for @fastestAvgSpeed.
  ///
  /// In en, this message translates to:
  /// **'Fastest Avg Speed'**
  String get fastestAvgSpeed;

  /// No description provided for @mostElevation.
  ///
  /// In en, this message translates to:
  /// **'Most Elevation'**
  String get mostElevation;

  /// No description provided for @mostCalories.
  ///
  /// In en, this message translates to:
  /// **'Most Calories'**
  String get mostCalories;

  /// No description provided for @longestStreak.
  ///
  /// In en, this message translates to:
  /// **'Longest Streak'**
  String get longestStreak;

  /// No description provided for @routeReplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Route Replay'**
  String get routeReplayTitle;

  /// No description provided for @replayStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get replayStart;

  /// No description provided for @replayEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get replayEnd;

  /// No description provided for @noGpsPathAvailable.
  ///
  /// In en, this message translates to:
  /// **'No GPS path available'**
  String get noGpsPathAvailable;

  /// No description provided for @elapsed.
  ///
  /// In en, this message translates to:
  /// **'Elapsed'**
  String get elapsed;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @fuelSavingsAmount.
  ///
  /// In en, this message translates to:
  /// **'Fuel savings: {amount}'**
  String fuelSavingsAmount(String amount);

  /// No description provided for @cykelPremiumTitle.
  ///
  /// In en, this message translates to:
  /// **'CYKEL Premium'**
  String get cykelPremiumTitle;

  /// No description provided for @premiumTagline.
  ///
  /// In en, this message translates to:
  /// **'Intelligence · Reliability · Optimization'**
  String get premiumTagline;

  /// No description provided for @onPremiumStatus.
  ///
  /// In en, this message translates to:
  /// **'✓  You are on Premium'**
  String get onPremiumStatus;

  /// No description provided for @onFreeStatus.
  ///
  /// In en, this message translates to:
  /// **'Currently on Free plan'**
  String get onFreeStatus;

  /// No description provided for @featuresHeader.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get featuresHeader;

  /// No description provided for @freeColumn.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get freeColumn;

  /// No description provided for @proColumn.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get proColumn;

  /// No description provided for @premiumPrice.
  ///
  /// In en, this message translates to:
  /// **'kr 20'**
  String get premiumPrice;

  /// No description provided for @premiumPerMonth.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get premiumPerMonth;

  /// No description provided for @premiumPriceNote.
  ///
  /// In en, this message translates to:
  /// **'Approx. \$2.99 USD · Cancel anytime'**
  String get premiumPriceNote;

  /// No description provided for @cancelPremiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Premium?'**
  String get cancelPremiumTitle;

  /// No description provided for @cancelPremiumBody.
  ///
  /// In en, this message translates to:
  /// **'You will lose access to Premium features.'**
  String get cancelPremiumBody;

  /// No description provided for @keepPremium.
  ///
  /// In en, this message translates to:
  /// **'Keep Premium'**
  String get keepPremium;

  /// No description provided for @switchedToFree.
  ///
  /// In en, this message translates to:
  /// **'Switched to Free plan'**
  String get switchedToFree;

  /// No description provided for @welcomeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Premium!'**
  String get welcomeToPremium;

  /// No description provided for @upgradeButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium — kr 20/month'**
  String get upgradeButtonLabel;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscription;

  /// No description provided for @pillWindAI.
  ///
  /// In en, this message translates to:
  /// **'Wind AI'**
  String get pillWindAI;

  /// No description provided for @pillAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get pillAnalytics;

  /// No description provided for @pillEBike.
  ///
  /// In en, this message translates to:
  /// **'E-Bike'**
  String get pillEBike;

  /// No description provided for @pillCloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud'**
  String get pillCloud;

  /// No description provided for @studentDiscountBanner.
  ///
  /// In en, this message translates to:
  /// **'Student? Get 50% off Premium'**
  String get studentDiscountBanner;

  /// No description provided for @studentDiscountPrice.
  ///
  /// In en, this message translates to:
  /// **'kr 10/month instead of kr 20'**
  String get studentDiscountPrice;

  /// No description provided for @verifiedStudentBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified Student - 50% Discount Applied'**
  String get verifiedStudentBadge;

  /// No description provided for @billingPeriodMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get billingPeriodMonthly;

  /// No description provided for @billingPeriodYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get billingPeriodYearly;

  /// No description provided for @annualSavingsMessage.
  ///
  /// In en, this message translates to:
  /// **'Save kr 40 with annual plan'**
  String get annualSavingsMessage;

  /// No description provided for @studentVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Student Status'**
  String get studentVerificationTitle;

  /// No description provided for @studentVerificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock 50% off Premium with your university email'**
  String get studentVerificationSubtitle;

  /// No description provided for @studentEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'University Email'**
  String get studentEmailLabel;

  /// No description provided for @studentEmailHint.
  ///
  /// In en, this message translates to:
  /// **'your.name@university.edu'**
  String get studentEmailHint;

  /// No description provided for @invalidStudentEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid student email domain'**
  String get invalidStudentEmail;

  /// No description provided for @studentEmailDomainNote.
  ///
  /// In en, this message translates to:
  /// **'Accepted: .edu, .ac.dk, .ku.dk, .dtu.dk, .cbs.dk, .ruc.dk, .au.dk, .sdu.dk, .aau.dk'**
  String get studentEmailDomainNote;

  /// No description provided for @verifyStudentButton.
  ///
  /// In en, this message translates to:
  /// **'Verify Student Status'**
  String get verifyStudentButton;

  /// No description provided for @studentVerificationSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Student status verified! You can now get 50% off Premium.'**
  String get studentVerificationSuccess;

  /// No description provided for @studentVerificationPending.
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get studentVerificationPending;

  /// No description provided for @studentVerificationBenefitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Student Benefits:'**
  String get studentVerificationBenefitsTitle;

  /// No description provided for @studentBenefit1.
  ///
  /// In en, this message translates to:
  /// **'Premium for kr 10/month (50% off)'**
  String get studentBenefit1;

  /// No description provided for @studentBenefit2.
  ///
  /// In en, this message translates to:
  /// **'All Premium features included'**
  String get studentBenefit2;

  /// No description provided for @studentBenefit3.
  ///
  /// In en, this message translates to:
  /// **'Valid for 1 year - easy renewal'**
  String get studentBenefit3;

  /// No description provided for @studentBenefit4.
  ///
  /// In en, this message translates to:
  /// **'Support student cycling community'**
  String get studentBenefit4;

  /// No description provided for @subNavAndMap.
  ///
  /// In en, this message translates to:
  /// **'Navigation & Map'**
  String get subNavAndMap;

  /// No description provided for @subSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety & Public Value — Always Free'**
  String get subSafety;

  /// No description provided for @subActivityTracking.
  ///
  /// In en, this message translates to:
  /// **'Activity Tracking'**
  String get subActivityTracking;

  /// No description provided for @subPersonalization.
  ///
  /// In en, this message translates to:
  /// **'Personalization & Utility'**
  String get subPersonalization;

  /// No description provided for @subMarketplaceBasic.
  ///
  /// In en, this message translates to:
  /// **'Marketplace — Basic Access'**
  String get subMarketplaceBasic;

  /// No description provided for @subSmartRouting.
  ///
  /// In en, this message translates to:
  /// **'Smart Routing & Optimization'**
  String get subSmartRouting;

  /// No description provided for @subOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline & Reliability'**
  String get subOffline;

  /// No description provided for @subEbikeIntel.
  ///
  /// In en, this message translates to:
  /// **'E-Bike Intelligence'**
  String get subEbikeIntel;

  /// No description provided for @subAdvAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Advanced Analytics & Performance'**
  String get subAdvAnalytics;

  /// No description provided for @subAutomation.
  ///
  /// In en, this message translates to:
  /// **'Automation & Smart Assistance'**
  String get subAutomation;

  /// No description provided for @subRouteSharing.
  ///
  /// In en, this message translates to:
  /// **'Route Sharing & Social Utility'**
  String get subRouteSharing;

  /// No description provided for @subAdvCustom.
  ///
  /// In en, this message translates to:
  /// **'Advanced Customisation'**
  String get subAdvCustom;

  /// No description provided for @subVoiceNav.
  ///
  /// In en, this message translates to:
  /// **'Voice & Navigation Experience'**
  String get subVoiceNav;

  /// No description provided for @subCloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync & Multi-Device'**
  String get subCloudSync;

  /// No description provided for @subMarketplacePro.
  ///
  /// In en, this message translates to:
  /// **'Marketplace — Premium Enhancements'**
  String get subMarketplacePro;

  /// No description provided for @subFeatBasicRouting.
  ///
  /// In en, this message translates to:
  /// **'Basic A → B cycling routing'**
  String get subFeatBasicRouting;

  /// No description provided for @subFeatVoiceNav.
  ///
  /// In en, this message translates to:
  /// **'Turn-by-turn voice navigation'**
  String get subFeatVoiceNav;

  /// No description provided for @subFeatGpsTracking.
  ///
  /// In en, this message translates to:
  /// **'Real-time GPS tracking'**
  String get subFeatGpsTracking;

  /// No description provided for @subFeatFollowUser.
  ///
  /// In en, this message translates to:
  /// **'Follow-user map mode'**
  String get subFeatFollowUser;

  /// No description provided for @subFeatAltRoutes.
  ///
  /// In en, this message translates to:
  /// **'Alternative route selection'**
  String get subFeatAltRoutes;

  /// No description provided for @subFeatNearbyPoi.
  ///
  /// In en, this message translates to:
  /// **'Nearby POIs (charging, repair, rentals)'**
  String get subFeatNearbyPoi;

  /// No description provided for @subFeatMapLayers.
  ///
  /// In en, this message translates to:
  /// **'Map layers: traffic, bike lanes, satellite'**
  String get subFeatMapLayers;

  /// No description provided for @subFeatRouteSummary.
  ///
  /// In en, this message translates to:
  /// **'Route summary — distance, duration, ETA'**
  String get subFeatRouteSummary;

  /// No description provided for @subFeatWeatherWind.
  ///
  /// In en, this message translates to:
  /// **'Current weather + wind conditions'**
  String get subFeatWeatherWind;

  /// No description provided for @subFeatNightMode.
  ///
  /// In en, this message translates to:
  /// **'Night mode support'**
  String get subFeatNightMode;

  /// No description provided for @subFeatLocaleSwitching.
  ///
  /// In en, this message translates to:
  /// **'Language / locale switching'**
  String get subFeatLocaleSwitching;

  /// No description provided for @subFeatStormWarnings.
  ///
  /// In en, this message translates to:
  /// **'Storm warnings'**
  String get subFeatStormWarnings;

  /// No description provided for @subFeatIceAlerts.
  ///
  /// In en, this message translates to:
  /// **'Ice / slippery road alerts'**
  String get subFeatIceAlerts;

  /// No description provided for @subFeatFogWarnings.
  ///
  /// In en, this message translates to:
  /// **'Fog & visibility warnings'**
  String get subFeatFogWarnings;

  /// No description provided for @subFeatHazardAlerts.
  ///
  /// In en, this message translates to:
  /// **'Hazard alerts on route'**
  String get subFeatHazardAlerts;

  /// No description provided for @subFeatCrowdHazards.
  ///
  /// In en, this message translates to:
  /// **'Crowd-reported hazards (view)'**
  String get subFeatCrowdHazards;

  /// No description provided for @subFeatEmergencySos.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS — call & share location'**
  String get subFeatEmergencySos;

  /// No description provided for @subFeatAccidentReport.
  ///
  /// In en, this message translates to:
  /// **'Accident reporting'**
  String get subFeatAccidentReport;

  /// No description provided for @subFeatRideCondition.
  ///
  /// In en, this message translates to:
  /// **'Ride condition indicator'**
  String get subFeatRideCondition;

  /// No description provided for @subFeatSafetyNotifs.
  ///
  /// In en, this message translates to:
  /// **'Safety push notifications'**
  String get subFeatSafetyNotifs;

  /// No description provided for @subFeatLiveRecording.
  ///
  /// In en, this message translates to:
  /// **'Live ride recording — distance, speed, time'**
  String get subFeatLiveRecording;

  /// No description provided for @subFeatCaloriesBasic.
  ///
  /// In en, this message translates to:
  /// **'Calories (basic)'**
  String get subFeatCaloriesBasic;

  /// No description provided for @subFeatRideHistory30.
  ///
  /// In en, this message translates to:
  /// **'Ride history (last 30 days)'**
  String get subFeatRideHistory30;

  /// No description provided for @subFeatRideHistoryNote.
  ///
  /// In en, this message translates to:
  /// **'Premium: unlimited'**
  String get subFeatRideHistoryNote;

  /// No description provided for @subFeatWeeklyStats.
  ///
  /// In en, this message translates to:
  /// **'Weekly activity stats'**
  String get subFeatWeeklyStats;

  /// No description provided for @subFeatMonthlyGoals.
  ///
  /// In en, this message translates to:
  /// **'Monthly challenge goals'**
  String get subFeatMonthlyGoals;

  /// No description provided for @subFeatCo2Stats.
  ///
  /// In en, this message translates to:
  /// **'Basic CO₂ saved statistics'**
  String get subFeatCo2Stats;

  /// No description provided for @subFeatFuelSavings.
  ///
  /// In en, this message translates to:
  /// **'Fuel savings equivalent (DKK)'**
  String get subFeatFuelSavings;

  /// No description provided for @subFeatDashboardSummary.
  ///
  /// In en, this message translates to:
  /// **'Home dashboard activity summary'**
  String get subFeatDashboardSummary;

  /// No description provided for @subFeatMultiBikes.
  ///
  /// In en, this message translates to:
  /// **'Multiple bike profiles'**
  String get subFeatMultiBikes;

  /// No description provided for @subFeatSavedPlaces.
  ///
  /// In en, this message translates to:
  /// **'Saved places / favorites'**
  String get subFeatSavedPlaces;

  /// No description provided for @subFeatCommuteSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Commute suggestion card'**
  String get subFeatCommuteSuggestion;

  /// No description provided for @subFeatPushNotifs.
  ///
  /// In en, this message translates to:
  /// **'Push notifications (general)'**
  String get subFeatPushNotifs;

  /// No description provided for @subFeatGdprControls.
  ///
  /// In en, this message translates to:
  /// **'Privacy settings & GDPR controls'**
  String get subFeatGdprControls;

  /// No description provided for @subFeatAppTheme.
  ///
  /// In en, this message translates to:
  /// **'App theme (light / dark)'**
  String get subFeatAppTheme;

  /// No description provided for @subFeatBrowseListings.
  ///
  /// In en, this message translates to:
  /// **'Browse listings (bikes & gear)'**
  String get subFeatBrowseListings;

  /// No description provided for @subFeatViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View item details'**
  String get subFeatViewDetails;

  /// No description provided for @subFeatContactSeller.
  ///
  /// In en, this message translates to:
  /// **'Contact seller'**
  String get subFeatContactSeller;

  /// No description provided for @subFeatBasicListing.
  ///
  /// In en, this message translates to:
  /// **'Basic listing posting'**
  String get subFeatBasicListing;

  /// No description provided for @subFeatWindRouting.
  ///
  /// In en, this message translates to:
  /// **'Wind-optimised route auto-selection'**
  String get subFeatWindRouting;

  /// No description provided for @subFeatElevRouting.
  ///
  /// In en, this message translates to:
  /// **'Elevation-aware routing'**
  String get subFeatElevRouting;

  /// No description provided for @subFeatRouteModeFastSafe.
  ///
  /// In en, this message translates to:
  /// **'Fastest vs safest route modes'**
  String get subFeatRouteModeFastSafe;

  /// No description provided for @subFeatFreqDest.
  ///
  /// In en, this message translates to:
  /// **'Frequent destinations shortcuts'**
  String get subFeatFreqDest;

  /// No description provided for @subFeatUnlimitedRoutes.
  ///
  /// In en, this message translates to:
  /// **'Quick saved routes (unlimited)'**
  String get subFeatUnlimitedRoutes;

  /// No description provided for @subFeatAdvRoutePrefs.
  ///
  /// In en, this message translates to:
  /// **'Advanced route preferences'**
  String get subFeatAdvRoutePrefs;

  /// No description provided for @subFeatOfflineRoutes.
  ///
  /// In en, this message translates to:
  /// **'Download routes for offline navigation'**
  String get subFeatOfflineRoutes;

  /// No description provided for @subFeatCachedTiles.
  ///
  /// In en, this message translates to:
  /// **'Cached map tiles for selected areas'**
  String get subFeatCachedTiles;

  /// No description provided for @subFeatOfflineTbt.
  ///
  /// In en, this message translates to:
  /// **'Offline turn-by-turn guidance'**
  String get subFeatOfflineTbt;

  /// No description provided for @subFeatNetworkFallback.
  ///
  /// In en, this message translates to:
  /// **'Network failure handling + auto-fallback'**
  String get subFeatNetworkFallback;

  /// No description provided for @subFeatGpsMitigation.
  ///
  /// In en, this message translates to:
  /// **'GPS loss mitigation & tunnel mode'**
  String get subFeatGpsMitigation;

  /// No description provided for @subFeatRouteRecovery.
  ///
  /// In en, this message translates to:
  /// **'Route recovery after app restart'**
  String get subFeatRouteRecovery;

  /// No description provided for @subFeatBatteryRange.
  ///
  /// In en, this message translates to:
  /// **'Battery range estimation'**
  String get subFeatBatteryRange;

  /// No description provided for @subFeatEnergyModel.
  ///
  /// In en, this message translates to:
  /// **'Energy consumption modelling'**
  String get subFeatEnergyModel;

  /// No description provided for @subFeatElevRange.
  ///
  /// In en, this message translates to:
  /// **'Elevation-adjusted range'**
  String get subFeatElevRange;

  /// No description provided for @subFeatRangeCard.
  ///
  /// In en, this message translates to:
  /// **'Remaining range dashboard card'**
  String get subFeatRangeCard;

  /// No description provided for @subFeatUnlimitedHistory.
  ///
  /// In en, this message translates to:
  /// **'Unlimited ride history'**
  String get subFeatUnlimitedHistory;

  /// No description provided for @subFeatElevTracking.
  ///
  /// In en, this message translates to:
  /// **'Elevation gain tracking per ride'**
  String get subFeatElevTracking;

  /// No description provided for @subFeatElevCalorie.
  ///
  /// In en, this message translates to:
  /// **'Elevation-aware calorie calculation'**
  String get subFeatElevCalorie;

  /// No description provided for @subFeatPeriodStats.
  ///
  /// In en, this message translates to:
  /// **'Weekly / monthly / yearly stats'**
  String get subFeatPeriodStats;

  /// No description provided for @subFeatPersonalRecords.
  ///
  /// In en, this message translates to:
  /// **'Personal records — longest, fastest, streaks'**
  String get subFeatPersonalRecords;

  /// No description provided for @subFeatGpxExport.
  ///
  /// In en, this message translates to:
  /// **'GPX export of rides'**
  String get subFeatGpxExport;

  /// No description provided for @subFeatScheduledReminders.
  ///
  /// In en, this message translates to:
  /// **'Scheduled ride reminders'**
  String get subFeatScheduledReminders;

  /// No description provided for @subFeatMaintenanceAlerts.
  ///
  /// In en, this message translates to:
  /// **'Maintenance alerts — service intervals & wear'**
  String get subFeatMaintenanceAlerts;

  /// No description provided for @subFeatSmartNotifs.
  ///
  /// In en, this message translates to:
  /// **'Smart notifications'**
  String get subFeatSmartNotifs;

  /// No description provided for @subFeatShareLink.
  ///
  /// In en, this message translates to:
  /// **'Share routes via link'**
  String get subFeatShareLink;

  /// No description provided for @subFeatExportGpx.
  ///
  /// In en, this message translates to:
  /// **'Export route to GPX'**
  String get subFeatExportGpx;

  /// No description provided for @subFeatShareSummary.
  ///
  /// In en, this message translates to:
  /// **'Share ride summaries'**
  String get subFeatShareSummary;

  /// No description provided for @subFeatSendToFriends.
  ///
  /// In en, this message translates to:
  /// **'Send route to friends'**
  String get subFeatSendToFriends;

  /// No description provided for @subFeatImportRoutes.
  ///
  /// In en, this message translates to:
  /// **'Import shared routes'**
  String get subFeatImportRoutes;

  /// No description provided for @subFeatCustomDashboard.
  ///
  /// In en, this message translates to:
  /// **'Custom dashboard layout'**
  String get subFeatCustomDashboard;

  /// No description provided for @subFeatMapStyle.
  ///
  /// In en, this message translates to:
  /// **'Map style personalisation'**
  String get subFeatMapStyle;

  /// No description provided for @subFeatCustomAlerts.
  ///
  /// In en, this message translates to:
  /// **'Custom alert thresholds'**
  String get subFeatCustomAlerts;

  /// No description provided for @subFeatCustomGoals.
  ///
  /// In en, this message translates to:
  /// **'Custom ride goals'**
  String get subFeatCustomGoals;

  /// No description provided for @subFeatUiDensity.
  ///
  /// In en, this message translates to:
  /// **'UI density options'**
  String get subFeatUiDensity;

  /// No description provided for @subFeatPremiumVoice.
  ///
  /// In en, this message translates to:
  /// **'Premium voice packs'**
  String get subFeatPremiumVoice;

  /// No description provided for @subFeatMultiLangVoice.
  ///
  /// In en, this message translates to:
  /// **'Multiple language voice options'**
  String get subFeatMultiLangVoice;

  /// No description provided for @subFeatVoiceStyle.
  ///
  /// In en, this message translates to:
  /// **'Voice style — Minimal / Detailed / Safety'**
  String get subFeatVoiceStyle;

  /// No description provided for @subFeatAnnouncementFreq.
  ///
  /// In en, this message translates to:
  /// **'Adjustable announcement frequency'**
  String get subFeatAnnouncementFreq;

  /// No description provided for @subFeatDataSync.
  ///
  /// In en, this message translates to:
  /// **'Data sync across devices'**
  String get subFeatDataSync;

  /// No description provided for @subFeatCloudBackup.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup of rides'**
  String get subFeatCloudBackup;

  /// No description provided for @subFeatRestoreHistory.
  ///
  /// In en, this message translates to:
  /// **'Restore history after reinstall'**
  String get subFeatRestoreHistory;

  /// No description provided for @subFeatSyncProfiles.
  ///
  /// In en, this message translates to:
  /// **'Sync bike profiles & settings'**
  String get subFeatSyncProfiles;

  /// No description provided for @subFeatUnlimitedListings.
  ///
  /// In en, this message translates to:
  /// **'Unlimited listings'**
  String get subFeatUnlimitedListings;

  /// No description provided for @subFeatPriorityPlacement.
  ///
  /// In en, this message translates to:
  /// **'Priority placement'**
  String get subFeatPriorityPlacement;

  /// No description provided for @subFeatHighlighted.
  ///
  /// In en, this message translates to:
  /// **'Highlighted / featured items'**
  String get subFeatHighlighted;

  /// No description provided for @subFeatAdvSearchFilters.
  ///
  /// In en, this message translates to:
  /// **'Advanced search filters'**
  String get subFeatAdvSearchFilters;

  /// No description provided for @subFeatSellerAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Seller analytics dashboard'**
  String get subFeatSellerAnalytics;

  /// No description provided for @voiceSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Settings'**
  String get voiceSettingsTitle;

  /// No description provided for @voiceStyle.
  ///
  /// In en, this message translates to:
  /// **'Voice Style'**
  String get voiceStyle;

  /// No description provided for @voiceMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get voiceMinimal;

  /// No description provided for @voiceMinimalDesc.
  ///
  /// In en, this message translates to:
  /// **'Street name only — minimal interruptions'**
  String get voiceMinimalDesc;

  /// No description provided for @voiceDetailed.
  ///
  /// In en, this message translates to:
  /// **'Detailed'**
  String get voiceDetailed;

  /// No description provided for @voiceDetailedDesc.
  ///
  /// In en, this message translates to:
  /// **'Turn direction + street + distance (default)'**
  String get voiceDetailedDesc;

  /// No description provided for @voiceSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety focus'**
  String get voiceSafety;

  /// No description provided for @voiceSafetyDesc.
  ///
  /// In en, this message translates to:
  /// **'Detailed + extra hazard & safety callouts'**
  String get voiceSafetyDesc;

  /// No description provided for @speechRate.
  ///
  /// In en, this message translates to:
  /// **'Speech Rate'**
  String get speechRate;

  /// No description provided for @speechRateDesc.
  ///
  /// In en, this message translates to:
  /// **'Adjust how quickly the voice speaks instructions.'**
  String get speechRateDesc;

  /// No description provided for @rateVerySlow.
  ///
  /// In en, this message translates to:
  /// **'Very slow'**
  String get rateVerySlow;

  /// No description provided for @rateSlow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get rateSlow;

  /// No description provided for @rateNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get rateNormal;

  /// No description provided for @rateFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get rateFast;

  /// No description provided for @rateVeryFast.
  ///
  /// In en, this message translates to:
  /// **'Very fast'**
  String get rateVeryFast;

  /// No description provided for @previewVoice.
  ///
  /// In en, this message translates to:
  /// **'Preview voice'**
  String get previewVoice;

  /// No description provided for @voicePreviewText.
  ///
  /// In en, this message translates to:
  /// **'In 500 metres, turn right onto Main Street.'**
  String get voicePreviewText;

  /// No description provided for @announcementDistance.
  ///
  /// In en, this message translates to:
  /// **'Announcement Distance'**
  String get announcementDistance;

  /// No description provided for @announcementDistanceDesc.
  ///
  /// In en, this message translates to:
  /// **'How far ahead upcoming turns are announced.'**
  String get announcementDistanceDesc;

  /// No description provided for @freqEarly.
  ///
  /// In en, this message translates to:
  /// **'Early'**
  String get freqEarly;

  /// No description provided for @freqNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal (default)'**
  String get freqNormal;

  /// No description provided for @freqLate.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get freqLate;

  /// No description provided for @premiumVoiceBody.
  ///
  /// In en, this message translates to:
  /// **'Voice customisation is available with a Premium subscription.'**
  String get premiumVoiceBody;

  /// No description provided for @dashboardSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard Settings'**
  String get dashboardSettingsTitle;

  /// No description provided for @homeScreenSections.
  ///
  /// In en, this message translates to:
  /// **'Home Screen Sections'**
  String get homeScreenSections;

  /// No description provided for @homeScreenSectionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose which sections to show on your home dashboard.'**
  String get homeScreenSectionsDesc;

  /// No description provided for @sectionMonthlyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Monthly Challenge'**
  String get sectionMonthlyChallenge;

  /// No description provided for @sectionMonthlyChallengeDesc.
  ///
  /// In en, this message translates to:
  /// **'Track your monthly cycling goal'**
  String get sectionMonthlyChallengeDesc;

  /// No description provided for @sectionEbikeRange.
  ///
  /// In en, this message translates to:
  /// **'E-bike Range'**
  String get sectionEbikeRange;

  /// No description provided for @sectionEbikeRangeDesc.
  ///
  /// In en, this message translates to:
  /// **'Battery level and estimated range'**
  String get sectionEbikeRangeDesc;

  /// No description provided for @sectionQuickRoutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Quick Routes'**
  String get sectionQuickRoutesLabel;

  /// No description provided for @sectionQuickRoutesDesc.
  ///
  /// In en, this message translates to:
  /// **'Saved routes and frequent destinations'**
  String get sectionQuickRoutesDesc;

  /// No description provided for @sectionRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get sectionRecentActivity;

  /// No description provided for @sectionRecentActivityDesc.
  ///
  /// In en, this message translates to:
  /// **'Your latest rides and stats'**
  String get sectionRecentActivityDesc;

  /// No description provided for @sectionMaintenanceReminder.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Reminder'**
  String get sectionMaintenanceReminder;

  /// No description provided for @sectionMaintenanceReminderDesc.
  ///
  /// In en, this message translates to:
  /// **'Service due notifications'**
  String get sectionMaintenanceReminderDesc;

  /// No description provided for @changesImmediate.
  ///
  /// In en, this message translates to:
  /// **'Changes take effect immediately.'**
  String get changesImmediate;

  /// No description provided for @premiumDashboardBody.
  ///
  /// In en, this message translates to:
  /// **'Dashboard customisation is available with a Premium subscription.'**
  String get premiumDashboardBody;

  /// No description provided for @faqSection.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faqSection;

  /// No description provided for @contactSection.
  ///
  /// In en, this message translates to:
  /// **'CONTACT'**
  String get contactSection;

  /// No description provided for @emailUs.
  ///
  /// In en, this message translates to:
  /// **'Email us'**
  String get emailUs;

  /// No description provided for @faq1Q.
  ///
  /// In en, this message translates to:
  /// **'How do I record a ride?'**
  String get faq1Q;

  /// No description provided for @faq1A.
  ///
  /// In en, this message translates to:
  /// **'Open the Map tab and tap the play button at the bottom to start recording. Tap stop when finished.'**
  String get faq1A;

  /// No description provided for @faq2Q.
  ///
  /// In en, this message translates to:
  /// **'How do I report a hazard?'**
  String get faq2Q;

  /// No description provided for @faq2A.
  ///
  /// In en, this message translates to:
  /// **'While navigating, tap the warning icon and choose the hazard type. Reports are visible to nearby riders for 8 hours.'**
  String get faq2A;

  /// No description provided for @faq3Q.
  ///
  /// In en, this message translates to:
  /// **'How do I list a bike for sale?'**
  String get faq3Q;

  /// No description provided for @faq3A.
  ///
  /// In en, this message translates to:
  /// **'Go to the Marketplace tab and tap the + button. Fill in the details and add photos to publish your listing.'**
  String get faq3A;

  /// No description provided for @faq4Q.
  ///
  /// In en, this message translates to:
  /// **'How do I save a place?'**
  String get faq4Q;

  /// No description provided for @faq4A.
  ///
  /// In en, this message translates to:
  /// **'Go to Profile → Saved Places and type in your home or work address.'**
  String get faq4A;

  /// No description provided for @faq5Q.
  ///
  /// In en, this message translates to:
  /// **'How do I delete my account?'**
  String get faq5Q;

  /// No description provided for @faq5A.
  ///
  /// In en, this message translates to:
  /// **'Go to Profile, scroll to the bottom and tap \"Delete account\". This permanently removes all your data.'**
  String get faq5A;

  /// No description provided for @faq6Q.
  ///
  /// In en, this message translates to:
  /// **'How do I change the language?'**
  String get faq6Q;

  /// No description provided for @faq6A.
  ///
  /// In en, this message translates to:
  /// **'Go to Profile → Language and select English or Danish.'**
  String get faq6A;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String lastUpdated(String date);

  /// No description provided for @privacyLastUpdateDate.
  ///
  /// In en, this message translates to:
  /// **'23 March 2026'**
  String get privacyLastUpdateDate;

  /// No description provided for @privacySection1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Who We Are'**
  String get privacySection1Title;

  /// No description provided for @privacySection1Body.
  ///
  /// In en, this message translates to:
  /// **'CYKEL ApS (\"CYKEL\", \"we\", \"us\") operates the CYKEL mobile application. We are registered in Denmark and are subject to the EU General Data Protection Regulation (GDPR).\n\nContact: privacy@cykel.app'**
  String get privacySection1Body;

  /// No description provided for @privacySection2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Data We Collect'**
  String get privacySection2Title;

  /// No description provided for @privacySection2Body.
  ///
  /// In en, this message translates to:
  /// **'• Account data (name, email, profile photo) — provided when you sign up.\n• Location data — collected during rides to draw your route. Never shared with third parties in identifiable form.\n• Ride data — distance, duration, route geometry.\n• Device data — OS version, app version, crash logs.\n• Optional: anonymised, aggregated mobility data if you consent.'**
  String get privacySection2Body;

  /// No description provided for @privacySection3Title.
  ///
  /// In en, this message translates to:
  /// **'3. How We Use Your Data'**
  String get privacySection3Title;

  /// No description provided for @privacySection3Body.
  ///
  /// In en, this message translates to:
  /// **'• Providing core app functionality (routes, ride history, marketplace).\n• Improving cycling infrastructure planning through aggregated, anonymised data (only with your explicit consent).\n• Sending you service notifications (e.g. ride reminders).\n• Fraud prevention and security.\n\nWe do NOT sell your personal data.'**
  String get privacySection3Body;

  /// No description provided for @privacySection4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Legal Basis (GDPR Art. 6)'**
  String get privacySection4Title;

  /// No description provided for @privacySection4Body.
  ///
  /// In en, this message translates to:
  /// **'• Performance of a contract — delivering the services you requested.\n• Legitimate interest — security, fraud prevention, app improvement.\n• Consent — analytics and aggregated ride data (you can withdraw at any time in Settings → Privacy).'**
  String get privacySection4Body;

  /// No description provided for @privacySection5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Data Sharing'**
  String get privacySection5Title;

  /// No description provided for @privacySection5Body.
  ///
  /// In en, this message translates to:
  /// **'We share data only with:\n• Firebase / Google (hosting, authentication, database) — under EU Standard Contractual Clauses.\n• Apple / Google — for sign-in and push notifications.\n• No advertising networks or data brokers.'**
  String get privacySection5Body;

  /// No description provided for @privacySection6Title.
  ///
  /// In en, this message translates to:
  /// **'6. Retention'**
  String get privacySection6Title;

  /// No description provided for @privacySection6Body.
  ///
  /// In en, this message translates to:
  /// **'• Ride data: retained for 3 years, then automatically deleted.\n• Account data: retained until you delete your account.\n• Crash logs: 90 days.\n• Aggregated anonymised data: retained indefinitely (cannot be linked back to you).'**
  String get privacySection6Body;

  /// No description provided for @privacySection7Title.
  ///
  /// In en, this message translates to:
  /// **'7. Your Rights'**
  String get privacySection7Title;

  /// No description provided for @privacySection7Body.
  ///
  /// In en, this message translates to:
  /// **'Under GDPR you have the right to:\n• Access — request a copy of all data we hold about you.\n• Rectification — correct inaccurate data.\n• Erasure (\"right to be forgotten\") — delete your account and all associated data.\n• Portability — receive your data in a machine-readable format.\n• Objection — object to processing based on legitimate interest.\n• Withdraw consent — at any time via Settings → Privacy.\n\nTo exercise these rights contact privacy@cykel.app. You also have the right to lodge a complaint with Datatilsynet (datatilsynet.dk).'**
  String get privacySection7Body;

  /// No description provided for @privacySection8Title.
  ///
  /// In en, this message translates to:
  /// **'8. Children'**
  String get privacySection8Title;

  /// No description provided for @privacySection8Body.
  ///
  /// In en, this message translates to:
  /// **'CYKEL is not directed at children under 13. We do not knowingly collect data from children. If you believe a child has provided us data, contact privacy@cykel.app and we will delete it promptly.'**
  String get privacySection8Body;

  /// No description provided for @privacySection9Title.
  ///
  /// In en, this message translates to:
  /// **'9. Policy Changes'**
  String get privacySection9Title;

  /// No description provided for @privacySection9Body.
  ///
  /// In en, this message translates to:
  /// **'We may update this policy. Significant changes will be communicated via an in-app notification. Continued use after the effective date constitutes acceptance.'**
  String get privacySection9Body;

  /// No description provided for @privacySection10Title.
  ///
  /// In en, this message translates to:
  /// **'10. Contact'**
  String get privacySection10Title;

  /// No description provided for @privacySection10Body.
  ///
  /// In en, this message translates to:
  /// **'CYKEL ApS\nprivacy@cykel.app\nFor urgent matters: support@cykel.app'**
  String get privacySection10Body;

  /// No description provided for @notifSectionRiding.
  ///
  /// In en, this message translates to:
  /// **'Riding'**
  String get notifSectionRiding;

  /// No description provided for @notifRideRemindersDesc.
  ///
  /// In en, this message translates to:
  /// **'Reminders to log your rides'**
  String get notifRideRemindersDesc;

  /// No description provided for @notifHazardAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Nearby hazard warnings while cycling'**
  String get notifHazardAlertsDesc;

  /// No description provided for @notifSectionMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get notifSectionMarketplace;

  /// No description provided for @notifMarketplaceDesc.
  ///
  /// In en, this message translates to:
  /// **'Chat messages from buyers & sellers'**
  String get notifMarketplaceDesc;

  /// No description provided for @notifSectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get notifSectionGeneral;

  /// No description provided for @notifMarketingDesc.
  ///
  /// In en, this message translates to:
  /// **'News, tips and feature announcements'**
  String get notifMarketingDesc;

  /// No description provided for @notifSectionScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Reminders'**
  String get notifSectionScheduled;

  /// No description provided for @dailyRideReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily Ride Reminder'**
  String get dailyRideReminder;

  /// No description provided for @tapToSetReminder.
  ///
  /// In en, this message translates to:
  /// **'Tap to set a daily reminder time'**
  String get tapToSetReminder;

  /// No description provided for @reminderSetFor.
  ///
  /// In en, this message translates to:
  /// **'Reminder set for {time}'**
  String reminderSetFor(String time);

  /// No description provided for @removeReminder.
  ///
  /// In en, this message translates to:
  /// **'Remove reminder'**
  String get removeReminder;

  /// No description provided for @setTime.
  ///
  /// In en, this message translates to:
  /// **'Set time'**
  String get setTime;

  /// No description provided for @changeTime.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeTime;

  /// No description provided for @preferencesSection.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesSection;

  /// No description provided for @dashboardLabel.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardLabel;

  /// No description provided for @voiceNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice & Navigation'**
  String get voiceNavLabel;

  /// No description provided for @moreSection.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreSection;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get currentPlan;

  /// No description provided for @manageButton.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manageButton;

  /// No description provided for @upgradeButton.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgradeButton;

  /// No description provided for @signOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign out failed: {error}'**
  String signOutFailed(String error);

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account: {error}'**
  String deleteAccountFailed(String error);

  /// No description provided for @nameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get nameCannotBeEmpty;

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String failedToSave(String error);

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'+45 ...'**
  String get phoneHint;

  /// No description provided for @bikeTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get bikeTypeLabel;

  /// No description provided for @failedToAddBike.
  ///
  /// In en, this message translates to:
  /// **'Failed to add bike: {error}'**
  String failedToAddBike(String error);

  /// No description provided for @revokeConsentBody.
  ///
  /// In en, this message translates to:
  /// **'This will reset all data consent. You will be shown the consent screen again next time you open the app.'**
  String get revokeConsentBody;

  /// No description provided for @requiredBadge.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredBadge;

  /// No description provided for @failedToSaveConsent.
  ///
  /// In en, this message translates to:
  /// **'Failed to save consent: {error}'**
  String failedToSaveConsent(String error);

  /// No description provided for @deleteListingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this listing? This cannot be undone.'**
  String get deleteListingConfirm;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String genericError(String error);

  /// No description provided for @discardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesBody.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to leave?'**
  String get discardChangesBody;

  /// No description provided for @stayButton.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stayButton;

  /// No description provided for @discardButton.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardButton;

  /// No description provided for @addUpToPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add up to 5 photos'**
  String get addUpToPhotos;

  /// No description provided for @currencyDKK.
  ///
  /// In en, this message translates to:
  /// **'DKK'**
  String get currencyDKK;

  /// No description provided for @validPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get validPhoneNumber;

  /// No description provided for @addAtLeastOnePhoto.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one photo'**
  String get addAtLeastOnePhoto;

  /// No description provided for @descriptionHeader.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionHeader;

  /// No description provided for @chatThreadNotFound.
  ///
  /// In en, this message translates to:
  /// **'Chat thread not found'**
  String get chatThreadNotFound;

  /// No description provided for @couldNotStartChat.
  ///
  /// In en, this message translates to:
  /// **'Could not start chat: {error}'**
  String couldNotStartChat(String error);

  /// No description provided for @reportListingReason.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this listing?'**
  String get reportListingReason;

  /// No description provided for @reportScam.
  ///
  /// In en, this message translates to:
  /// **'Scam / fraud'**
  String get reportScam;

  /// No description provided for @reportStolen.
  ///
  /// In en, this message translates to:
  /// **'Stolen bike'**
  String get reportStolen;

  /// No description provided for @reportInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get reportInappropriate;

  /// No description provided for @reportOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportOther;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thank you.'**
  String get reportSubmitted;

  /// No description provided for @failedToReport.
  ///
  /// In en, this message translates to:
  /// **'Failed to report: {error}'**
  String failedToReport(String error);

  /// No description provided for @viewsStat.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get viewsStat;

  /// No description provided for @savesStat.
  ///
  /// In en, this message translates to:
  /// **'Saves'**
  String get savesStat;

  /// No description provided for @chatsStat.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatsStat;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// No description provided for @failedToSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message'**
  String failedToSendMessage(String error);

  /// No description provided for @welcomeGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get welcomeGetStarted;

  /// No description provided for @welcomeJoinCommunity.
  ///
  /// In en, this message translates to:
  /// **'Join the cycling community'**
  String get welcomeJoinCommunity;

  /// No description provided for @filterCharging.
  ///
  /// In en, this message translates to:
  /// **'Charging'**
  String get filterCharging;

  /// No description provided for @filterService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get filterService;

  /// No description provided for @filterShops.
  ///
  /// In en, this message translates to:
  /// **'Shops'**
  String get filterShops;

  /// No description provided for @filterRental.
  ///
  /// In en, this message translates to:
  /// **'Rental'**
  String get filterRental;

  /// No description provided for @agoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{min}m ago'**
  String agoMinutes(int min);

  /// No description provided for @agoHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String agoHours(int hours);

  /// No description provided for @agoDays.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String agoDays(int days);

  /// No description provided for @hazardDuplicateUpvoted.
  ///
  /// In en, this message translates to:
  /// **'A nearby report already existed — it was upvoted instead.'**
  String get hazardDuplicateUpvoted;

  /// No description provided for @hazardGpsAccuracyLow.
  ///
  /// In en, this message translates to:
  /// **'GPS accuracy too low ({meters} m). Move to an open area and try again.'**
  String hazardGpsAccuracyLow(String meters);

  /// No description provided for @hazardSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit. Please try again.'**
  String get hazardSubmitFailed;

  /// No description provided for @ttsLanguageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice language unavailable — using English'**
  String get ttsLanguageUnavailable;

  /// No description provided for @noRouteToExport.
  ///
  /// In en, this message translates to:
  /// **'No route to export.'**
  String get noRouteToExport;

  /// No description provided for @shareRouteGpx.
  ///
  /// In en, this message translates to:
  /// **'Share Route GPX'**
  String get shareRouteGpx;

  /// No description provided for @shareRoute.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareRoute;

  /// No description provided for @downloadMap.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadMap;

  /// No description provided for @gpxFileLabel.
  ///
  /// In en, this message translates to:
  /// **'File: {path}'**
  String gpxFileLabel(String path);

  /// No description provided for @routeGpxCopied.
  ///
  /// In en, this message translates to:
  /// **'Route GPX copied to clipboard'**
  String get routeGpxCopied;

  /// No description provided for @noRouteToCacheTiles.
  ///
  /// In en, this message translates to:
  /// **'No route to cache tiles for.'**
  String get noRouteToCacheTiles;

  /// No description provided for @tilesCachedForOffline.
  ///
  /// In en, this message translates to:
  /// **'Map tiles cached for offline use'**
  String get tilesCachedForOffline;

  /// No description provided for @tilePrefetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Tile prefetch failed: {error}'**
  String tilePrefetchFailed(String error);

  /// No description provided for @cachingMapTilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Caching Map Tiles'**
  String get cachingMapTilesTitle;

  /// No description provided for @cachingMapTilesBody.
  ///
  /// In en, this message translates to:
  /// **'Preparing map tiles for offline use...\nThis may take a minute.'**
  String get cachingMapTilesBody;

  /// No description provided for @routeFastest.
  ///
  /// In en, this message translates to:
  /// **'Fastest'**
  String get routeFastest;

  /// No description provided for @routeSafest.
  ///
  /// In en, this message translates to:
  /// **'Safest'**
  String get routeSafest;

  /// No description provided for @selectRoute.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Route'**
  String get selectRoute;

  /// No description provided for @routingPreference.
  ///
  /// In en, this message translates to:
  /// **'Route Type'**
  String get routingPreference;

  /// No description provided for @bikeType.
  ///
  /// In en, this message translates to:
  /// **'Bike Profile'**
  String get bikeType;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @windOverlay.
  ///
  /// In en, this message translates to:
  /// **'Wind Overlay'**
  String get windOverlay;

  /// No description provided for @hazardConfirmedThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks — hazard confirmed.'**
  String get hazardConfirmedThanks;

  /// No description provided for @hazardStillThere.
  ///
  /// In en, this message translates to:
  /// **'Still there'**
  String get hazardStillThere;

  /// No description provided for @hazardClearedThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks — hazard cleared.'**
  String get hazardClearedThanks;

  /// No description provided for @hazardCleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get hazardCleared;

  /// No description provided for @hazardResolved.
  ///
  /// In en, this message translates to:
  /// **'This hazard has been resolved.'**
  String get hazardResolved;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @reportListingTitle.
  ///
  /// In en, this message translates to:
  /// **'Report listing'**
  String get reportListingTitle;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @yesterdayLabel.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterdayLabel;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @providerTypeRepairShop.
  ///
  /// In en, this message translates to:
  /// **'Repair / Garage Shop'**
  String get providerTypeRepairShop;

  /// No description provided for @providerTypeBikeShop.
  ///
  /// In en, this message translates to:
  /// **'Bike Retail Shop'**
  String get providerTypeBikeShop;

  /// No description provided for @providerTypeChargingLocation.
  ///
  /// In en, this message translates to:
  /// **'E-Bike Charging Location'**
  String get providerTypeChargingLocation;

  /// No description provided for @providerTypeServicePoint.
  ///
  /// In en, this message translates to:
  /// **'Service Point'**
  String get providerTypeServicePoint;

  /// No description provided for @providerTypeRental.
  ///
  /// In en, this message translates to:
  /// **'Bike Rental'**
  String get providerTypeRental;

  /// No description provided for @providerTypeRepairShopDesc.
  ///
  /// In en, this message translates to:
  /// **'Offer mechanical services, repairs, and maintenance for bicycles.'**
  String get providerTypeRepairShopDesc;

  /// No description provided for @providerTypeBikeShopDesc.
  ///
  /// In en, this message translates to:
  /// **'Sell bicycles, e-bikes, accessories, and cycling gear.'**
  String get providerTypeBikeShopDesc;

  /// No description provided for @providerTypeChargingLocationDesc.
  ///
  /// In en, this message translates to:
  /// **'Provide charging points for e-bike riders.'**
  String get providerTypeChargingLocationDesc;

  /// No description provided for @providerTypeServicePointDesc.
  ///
  /// In en, this message translates to:
  /// **'Mobile or fixed service stations for quick repairs and maintenance.'**
  String get providerTypeServicePointDesc;

  /// No description provided for @providerTypeRentalDesc.
  ///
  /// In en, this message translates to:
  /// **'Rent out bicycles and e-bikes to riders.'**
  String get providerTypeRentalDesc;

  /// No description provided for @repairFlatTire.
  ///
  /// In en, this message translates to:
  /// **'Flat tire repair'**
  String get repairFlatTire;

  /// No description provided for @repairBrakeService.
  ///
  /// In en, this message translates to:
  /// **'Brake service'**
  String get repairBrakeService;

  /// No description provided for @repairGearAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Gear adjustment'**
  String get repairGearAdjustment;

  /// No description provided for @repairChainReplacement.
  ///
  /// In en, this message translates to:
  /// **'Chain replacement'**
  String get repairChainReplacement;

  /// No description provided for @repairWheelTruing.
  ///
  /// In en, this message translates to:
  /// **'Wheel truing'**
  String get repairWheelTruing;

  /// No description provided for @repairSuspensionService.
  ///
  /// In en, this message translates to:
  /// **'Suspension service'**
  String get repairSuspensionService;

  /// No description provided for @repairEbikeDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'E-bike diagnostics'**
  String get repairEbikeDiagnostics;

  /// No description provided for @repairFullTuneUp.
  ///
  /// In en, this message translates to:
  /// **'Full tune-up'**
  String get repairFullTuneUp;

  /// No description provided for @repairEmergencyRepair.
  ///
  /// In en, this message translates to:
  /// **'Emergency repair'**
  String get repairEmergencyRepair;

  /// No description provided for @repairSafetyInspection.
  ///
  /// In en, this message translates to:
  /// **'Safety inspection'**
  String get repairSafetyInspection;

  /// No description provided for @repairMobileRepair.
  ///
  /// In en, this message translates to:
  /// **'Mobile repair'**
  String get repairMobileRepair;

  /// No description provided for @bikeTypeCityBike.
  ///
  /// In en, this message translates to:
  /// **'City bike'**
  String get bikeTypeCityBike;

  /// No description provided for @bikeTypeRoadBike.
  ///
  /// In en, this message translates to:
  /// **'Road bike'**
  String get bikeTypeRoadBike;

  /// No description provided for @bikeTypeMtb.
  ///
  /// In en, this message translates to:
  /// **'MTB'**
  String get bikeTypeMtb;

  /// No description provided for @bikeTypeCargoBike.
  ///
  /// In en, this message translates to:
  /// **'Cargo bike'**
  String get bikeTypeCargoBike;

  /// No description provided for @productCityBikes.
  ///
  /// In en, this message translates to:
  /// **'City bikes'**
  String get productCityBikes;

  /// No description provided for @productEbikes.
  ///
  /// In en, this message translates to:
  /// **'E-bikes'**
  String get productEbikes;

  /// No description provided for @productCargoBikes.
  ///
  /// In en, this message translates to:
  /// **'Cargo bikes'**
  String get productCargoBikes;

  /// No description provided for @productRoadBikes.
  ///
  /// In en, this message translates to:
  /// **'Road bikes'**
  String get productRoadBikes;

  /// No description provided for @productKidsBikes.
  ///
  /// In en, this message translates to:
  /// **'Kids bikes'**
  String get productKidsBikes;

  /// No description provided for @productHelmets.
  ///
  /// In en, this message translates to:
  /// **'Helmets'**
  String get productHelmets;

  /// No description provided for @productLocks.
  ///
  /// In en, this message translates to:
  /// **'Locks'**
  String get productLocks;

  /// No description provided for @productLights.
  ///
  /// In en, this message translates to:
  /// **'Lights'**
  String get productLights;

  /// No description provided for @productTires.
  ///
  /// In en, this message translates to:
  /// **'Tires'**
  String get productTires;

  /// No description provided for @productSpareParts.
  ///
  /// In en, this message translates to:
  /// **'Spare parts'**
  String get productSpareParts;

  /// No description provided for @productClothing.
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get productClothing;

  /// No description provided for @chargingStandardOutlet.
  ///
  /// In en, this message translates to:
  /// **'Standard outlet'**
  String get chargingStandardOutlet;

  /// No description provided for @chargingDedicatedCharger.
  ///
  /// In en, this message translates to:
  /// **'Dedicated e-bike charger'**
  String get chargingDedicatedCharger;

  /// No description provided for @chargingBatterySwap.
  ///
  /// In en, this message translates to:
  /// **'Battery swap station'**
  String get chargingBatterySwap;

  /// No description provided for @hostPublicStation.
  ///
  /// In en, this message translates to:
  /// **'Public station'**
  String get hostPublicStation;

  /// No description provided for @hostCafe.
  ///
  /// In en, this message translates to:
  /// **'Café'**
  String get hostCafe;

  /// No description provided for @hostShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get hostShop;

  /// No description provided for @hostOffice.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get hostOffice;

  /// No description provided for @hostParkingFacility.
  ///
  /// In en, this message translates to:
  /// **'Parking facility'**
  String get hostParkingFacility;

  /// No description provided for @hostOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get hostOther;

  /// No description provided for @powerFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get powerFree;

  /// No description provided for @powerPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get powerPaid;

  /// No description provided for @powerCustomersOnly.
  ///
  /// In en, this message translates to:
  /// **'Customers only'**
  String get powerCustomersOnly;

  /// No description provided for @amenitySeating.
  ///
  /// In en, this message translates to:
  /// **'Seating'**
  String get amenitySeating;

  /// No description provided for @amenityFoodDrinks.
  ///
  /// In en, this message translates to:
  /// **'Food & drinks'**
  String get amenityFoodDrinks;

  /// No description provided for @amenityRestroom.
  ///
  /// In en, this message translates to:
  /// **'Restroom'**
  String get amenityRestroom;

  /// No description provided for @amenityBikeParking.
  ///
  /// In en, this message translates to:
  /// **'Bike parking'**
  String get amenityBikeParking;

  /// No description provided for @amenityWifi.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi'**
  String get amenityWifi;

  /// No description provided for @accessPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get accessPublic;

  /// No description provided for @accessCustomersOnly.
  ///
  /// In en, this message translates to:
  /// **'Customers only'**
  String get accessCustomersOnly;

  /// No description provided for @accessResidentsOnly.
  ///
  /// In en, this message translates to:
  /// **'Residents only'**
  String get accessResidentsOnly;

  /// No description provided for @priceRangeLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priceRangeLow;

  /// No description provided for @priceRangeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priceRangeMedium;

  /// No description provided for @priceRangeHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priceRangeHigh;

  /// No description provided for @priceTierBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get priceTierBudget;

  /// No description provided for @priceTierMid.
  ///
  /// In en, this message translates to:
  /// **'Mid-range'**
  String get priceTierMid;

  /// No description provided for @priceTierPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get priceTierPremium;

  /// No description provided for @verificationPending.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get verificationPending;

  /// No description provided for @verificationApproved.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verificationApproved;

  /// No description provided for @verificationRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get verificationRejected;

  /// No description provided for @providerActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get providerActive;

  /// No description provided for @providerInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get providerInactive;

  /// No description provided for @providerTemporarilyClosed.
  ///
  /// In en, this message translates to:
  /// **'Temporarily closed'**
  String get providerTemporarilyClosed;

  /// No description provided for @becomeProvider.
  ///
  /// In en, this message translates to:
  /// **'Become a Provider'**
  String get becomeProvider;

  /// No description provided for @providerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Provider Dashboard'**
  String get providerDashboard;

  /// No description provided for @providerOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Register your business'**
  String get providerOnboardingTitle;

  /// No description provided for @providerSelectTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'What type of provider are you?'**
  String get providerSelectTypeTitle;

  /// No description provided for @providerSelectTypeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the category that best fits your business.'**
  String get providerSelectTypeSubtitle;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @backLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backLabel;

  /// No description provided for @submitLabel.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitLabel;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOf(int current, int total);

  /// No description provided for @businessInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Information'**
  String get businessInfoTitle;

  /// No description provided for @businessNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get businessNameLabel;

  /// No description provided for @businessNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Copenhagen Bike Repair'**
  String get businessNameHint;

  /// No description provided for @legalBusinessNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Legal business name (optional)'**
  String get legalBusinessNameLabel;

  /// No description provided for @cvrNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'CVR number'**
  String get cvrNumberLabel;

  /// No description provided for @cvrNumberHint.
  ///
  /// In en, this message translates to:
  /// **'8-digit Danish business ID'**
  String get cvrNumberHint;

  /// No description provided for @contactNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact person'**
  String get contactNameLabel;

  /// No description provided for @contactNameHint.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get contactNameHint;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'business@example.dk'**
  String get emailHint;

  /// No description provided for @websiteLabel.
  ///
  /// In en, this message translates to:
  /// **'Website (optional)'**
  String get websiteLabel;

  /// No description provided for @websiteHint.
  ///
  /// In en, this message translates to:
  /// **'https://...'**
  String get websiteHint;

  /// No description provided for @locationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationTitle;

  /// No description provided for @streetAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Street address'**
  String get streetAddressLabel;

  /// No description provided for @streetAddressHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Nørrebrogade 42'**
  String get streetAddressHint;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @cityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Copenhagen'**
  String get cityHint;

  /// No description provided for @postalCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Postal code'**
  String get postalCodeLabel;

  /// No description provided for @postalCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2200'**
  String get postalCodeHint;

  /// No description provided for @servicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Services & Details'**
  String get servicesTitle;

  /// No description provided for @servicesOfferedLabel.
  ///
  /// In en, this message translates to:
  /// **'Services offered'**
  String get servicesOfferedLabel;

  /// No description provided for @supportedBikeTypesLabel.
  ///
  /// In en, this message translates to:
  /// **'Supported bike types'**
  String get supportedBikeTypesLabel;

  /// No description provided for @mobileRepairLabel.
  ///
  /// In en, this message translates to:
  /// **'Offer mobile repair'**
  String get mobileRepairLabel;

  /// No description provided for @acceptsWalkInsLabel.
  ///
  /// In en, this message translates to:
  /// **'Accept walk-ins'**
  String get acceptsWalkInsLabel;

  /// No description provided for @appointmentRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Appointment required'**
  String get appointmentRequiredLabel;

  /// No description provided for @estimatedWaitLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated wait time (minutes)'**
  String get estimatedWaitLabel;

  /// No description provided for @estimatedWaitHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 30'**
  String get estimatedWaitHint;

  /// No description provided for @priceRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Price range'**
  String get priceRangeLabel;

  /// No description provided for @serviceRadiusLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile service radius (km)'**
  String get serviceRadiusLabel;

  /// No description provided for @serviceRadiusHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 10'**
  String get serviceRadiusHint;

  /// No description provided for @productsTitle.
  ///
  /// In en, this message translates to:
  /// **'Products & Details'**
  String get productsTitle;

  /// No description provided for @productsAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Products available'**
  String get productsAvailableLabel;

  /// No description provided for @offersTestRidesLabel.
  ///
  /// In en, this message translates to:
  /// **'Offer test rides'**
  String get offersTestRidesLabel;

  /// No description provided for @financingAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Financing available'**
  String get financingAvailableLabel;

  /// No description provided for @acceptsTradeInLabel.
  ///
  /// In en, this message translates to:
  /// **'Accept trade-ins'**
  String get acceptsTradeInLabel;

  /// No description provided for @onlineStoreUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Online store URL (optional)'**
  String get onlineStoreUrlLabel;

  /// No description provided for @priceTierLabel.
  ///
  /// In en, this message translates to:
  /// **'Price tier'**
  String get priceTierLabel;

  /// No description provided for @hasRepairServiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Also offer repair services'**
  String get hasRepairServiceLabel;

  /// No description provided for @chargingTitle.
  ///
  /// In en, this message translates to:
  /// **'Charging Details'**
  String get chargingTitle;

  /// No description provided for @hostTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Host type'**
  String get hostTypeLabel;

  /// No description provided for @chargingTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Charging type'**
  String get chargingTypeLabel;

  /// No description provided for @numberOfPortsLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of charging ports'**
  String get numberOfPortsLabel;

  /// No description provided for @numberOfPortsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 4'**
  String get numberOfPortsHint;

  /// No description provided for @powerAvailabilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Power availability'**
  String get powerAvailabilityLabel;

  /// No description provided for @maxChargingDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Max charging duration (minutes)'**
  String get maxChargingDurationLabel;

  /// No description provided for @maxChargingDurationHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for unlimited'**
  String get maxChargingDurationHint;

  /// No description provided for @indoorChargingLabel.
  ///
  /// In en, this message translates to:
  /// **'Indoor charging available'**
  String get indoorChargingLabel;

  /// No description provided for @weatherProtectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Weather-protected'**
  String get weatherProtectedLabel;

  /// No description provided for @amenitiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get amenitiesLabel;

  /// No description provided for @accessRestrictionLabel.
  ///
  /// In en, this message translates to:
  /// **'Access restriction'**
  String get accessRestrictionLabel;

  /// No description provided for @openingHoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Opening Hours'**
  String get openingHoursTitle;

  /// No description provided for @mondayShort.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mondayShort;

  /// No description provided for @tuesdayShort.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tuesdayShort;

  /// No description provided for @wednesdayShort.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wednesdayShort;

  /// No description provided for @thursdayShort.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thursdayShort;

  /// No description provided for @fridayShort.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fridayShort;

  /// No description provided for @saturdayShort.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get saturdayShort;

  /// No description provided for @sundayShort.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sundayShort;

  /// No description provided for @openLabel.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openLabel;

  /// No description provided for @closeLabel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeLabel;

  /// No description provided for @closedLabel.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closedLabel;

  /// No description provided for @copyToAllDays.
  ///
  /// In en, this message translates to:
  /// **'Copy to all days'**
  String get copyToAllDays;

  /// No description provided for @mediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get mediaTitle;

  /// No description provided for @logoLabel.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get logoLabel;

  /// No description provided for @logoHint.
  ///
  /// In en, this message translates to:
  /// **'Upload your business logo'**
  String get logoHint;

  /// No description provided for @coverPhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Cover photo (optional)'**
  String get coverPhotoLabel;

  /// No description provided for @galleryLabel.
  ///
  /// In en, this message translates to:
  /// **'Gallery (up to 8 photos)'**
  String get galleryLabel;

  /// No description provided for @tapToUpload.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload'**
  String get tapToUpload;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removePhoto;

  /// No description provided for @descriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionTitle;

  /// No description provided for @shopDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Business description'**
  String get shopDescriptionLabel;

  /// No description provided for @shopDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Tell cyclists what makes your business special...'**
  String get shopDescriptionHint;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review & Submit'**
  String get reviewTitle;

  /// No description provided for @reviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please review your information before submitting.'**
  String get reviewSubtitle;

  /// No description provided for @reviewBusinessInfo.
  ///
  /// In en, this message translates to:
  /// **'Business Info'**
  String get reviewBusinessInfo;

  /// No description provided for @reviewLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get reviewLocation;

  /// No description provided for @reviewServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get reviewServices;

  /// No description provided for @reviewHours.
  ///
  /// In en, this message translates to:
  /// **'Opening Hours'**
  String get reviewHours;

  /// No description provided for @reviewPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get reviewPhotos;

  /// No description provided for @reviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get reviewDescription;

  /// No description provided for @submittingProvider.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submittingProvider;

  /// No description provided for @providerSubmitSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your provider application has been submitted!'**
  String get providerSubmitSuccess;

  /// No description provided for @providerSubmitSuccessDetail.
  ///
  /// In en, this message translates to:
  /// **'We\'ll review your information and get back to you soon.'**
  String get providerSubmitSuccessDetail;

  /// No description provided for @providerSubmitError.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit: {error}'**
  String providerSubmitError(String error);

  /// No description provided for @goToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Go to Dashboard'**
  String get goToDashboard;

  /// No description provided for @providerSection.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get providerSection;

  /// No description provided for @providerSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage your business on CYKEL'**
  String get providerSectionDescription;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String dashboardWelcome(String name);

  /// No description provided for @dashboardVerificationBanner.
  ///
  /// In en, this message translates to:
  /// **'Your account is pending verification.'**
  String get dashboardVerificationBanner;

  /// No description provided for @dashboardRejectedBanner.
  ///
  /// In en, this message translates to:
  /// **'Your application was rejected. Please update your details and resubmit.'**
  String get dashboardRejectedBanner;

  /// No description provided for @dashboardOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get dashboardOverview;

  /// No description provided for @dashboardProfileViews.
  ///
  /// In en, this message translates to:
  /// **'Profile views'**
  String get dashboardProfileViews;

  /// No description provided for @dashboardNavRequests.
  ///
  /// In en, this message translates to:
  /// **'Navigation requests'**
  String get dashboardNavRequests;

  /// No description provided for @dashboardSavedBy.
  ///
  /// In en, this message translates to:
  /// **'Saved by users'**
  String get dashboardSavedBy;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get dashboardQuickActions;

  /// No description provided for @editBusinessInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit Business Info'**
  String get editBusinessInfo;

  /// No description provided for @manageHours.
  ///
  /// In en, this message translates to:
  /// **'Manage Hours'**
  String get manageHours;

  /// No description provided for @managePhotos.
  ///
  /// In en, this message translates to:
  /// **'Manage Photos'**
  String get managePhotos;

  /// No description provided for @providerSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get providerSettings;

  /// No description provided for @viewAnalytics.
  ///
  /// In en, this message translates to:
  /// **'View Analytics'**
  String get viewAnalytics;

  /// No description provided for @editProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Business'**
  String get editProviderTitle;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @changesSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved successfully.'**
  String get changesSaved;

  /// No description provided for @changesSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String changesSaveError(String error);

  /// No description provided for @manageHoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Opening Hours'**
  String get manageHoursTitle;

  /// No description provided for @hoursSaved.
  ///
  /// In en, this message translates to:
  /// **'Opening hours updated.'**
  String get hoursSaved;

  /// No description provided for @managePhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Photos'**
  String get managePhotosTitle;

  /// No description provided for @currentLogo.
  ///
  /// In en, this message translates to:
  /// **'Current logo'**
  String get currentLogo;

  /// No description provided for @currentCover.
  ///
  /// In en, this message translates to:
  /// **'Current cover photo'**
  String get currentCover;

  /// No description provided for @currentGallery.
  ///
  /// In en, this message translates to:
  /// **'Current gallery'**
  String get currentGallery;

  /// No description provided for @changeLogo.
  ///
  /// In en, this message translates to:
  /// **'Change logo'**
  String get changeLogo;

  /// No description provided for @changeCover.
  ///
  /// In en, this message translates to:
  /// **'Change cover'**
  String get changeCover;

  /// No description provided for @addPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get addPhotos;

  /// No description provided for @photosSaved.
  ///
  /// In en, this message translates to:
  /// **'Photos updated.'**
  String get photosSaved;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider Settings'**
  String get settingsTitle;

  /// No description provided for @activeStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Listing active'**
  String get activeStatusLabel;

  /// No description provided for @activeStatusDesc.
  ///
  /// In en, this message translates to:
  /// **'Your business is visible to cyclists on the map.'**
  String get activeStatusDesc;

  /// No description provided for @temporarilyClosedLabel.
  ///
  /// In en, this message translates to:
  /// **'Temporarily closed'**
  String get temporarilyClosedLabel;

  /// No description provided for @temporarilyClosedDesc.
  ///
  /// In en, this message translates to:
  /// **'Show a closed notice without deactivating your listing.'**
  String get temporarilyClosedDesc;

  /// No description provided for @specialNoticeLabel.
  ///
  /// In en, this message translates to:
  /// **'Special notice'**
  String get specialNoticeLabel;

  /// No description provided for @specialNoticeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Closed for renovation until March 30'**
  String get specialNoticeHint;

  /// No description provided for @specialNoticeSaved.
  ///
  /// In en, this message translates to:
  /// **'Notice updated.'**
  String get specialNoticeSaved;

  /// No description provided for @deleteProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Provider'**
  String get deleteProviderTitle;

  /// No description provided for @deleteProviderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your provider listing? This action cannot be undone.'**
  String get deleteProviderConfirm;

  /// No description provided for @deleteProviderButton.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deleteProviderButton;

  /// No description provided for @providerDeleted.
  ///
  /// In en, this message translates to:
  /// **'Provider listing deleted.'**
  String get providerDeleted;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// No description provided for @analyticsProfileViews.
  ///
  /// In en, this message translates to:
  /// **'Profile Views'**
  String get analyticsProfileViews;

  /// No description provided for @analyticsNavRequests.
  ///
  /// In en, this message translates to:
  /// **'Navigation Requests'**
  String get analyticsNavRequests;

  /// No description provided for @analyticsSavedBy.
  ///
  /// In en, this message translates to:
  /// **'Times Saved'**
  String get analyticsSavedBy;

  /// No description provided for @analyticsNoData.
  ///
  /// In en, this message translates to:
  /// **'No analytics data yet.'**
  String get analyticsNoData;

  /// No description provided for @noProviderFound.
  ///
  /// In en, this message translates to:
  /// **'No provider record found. Please complete onboarding first.'**
  String get noProviderFound;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @layerCykelRepair.
  ///
  /// In en, this message translates to:
  /// **'CYKEL Repair Shops'**
  String get layerCykelRepair;

  /// No description provided for @layerCykelShop.
  ///
  /// In en, this message translates to:
  /// **'CYKEL Bike Shops'**
  String get layerCykelShop;

  /// No description provided for @layerCykelCharging.
  ///
  /// In en, this message translates to:
  /// **'CYKEL Charging'**
  String get layerCykelCharging;

  /// No description provided for @layerCykelService.
  ///
  /// In en, this message translates to:
  /// **'CYKEL Service Points'**
  String get layerCykelService;

  /// No description provided for @layerCykelRental.
  ///
  /// In en, this message translates to:
  /// **'CYKEL Rentals'**
  String get layerCykelRental;

  /// No description provided for @cykelVerifiedProviders.
  ///
  /// In en, this message translates to:
  /// **'Find providers on the map'**
  String get cykelVerifiedProviders;

  /// No description provided for @cykelVerifiedSection.
  ///
  /// In en, this message translates to:
  /// **'Verified Providers'**
  String get cykelVerifiedSection;

  /// No description provided for @cykelProviderNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby CYKEL Providers'**
  String get cykelProviderNearby;

  /// No description provided for @providerDetailGetDirections.
  ///
  /// In en, this message translates to:
  /// **'Get directions'**
  String get providerDetailGetDirections;

  /// No description provided for @providerDetailCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get providerDetailCall;

  /// No description provided for @providerDetailWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get providerDetailWebsite;

  /// No description provided for @providerDetailSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get providerDetailSave;

  /// No description provided for @providerDetailSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get providerDetailSaved;

  /// No description provided for @providerDetailOpen.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get providerDetailOpen;

  /// No description provided for @providerDetailClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get providerDetailClosed;

  /// No description provided for @providerDetailVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get providerDetailVerified;

  /// No description provided for @providerDetailOpeningHours.
  ///
  /// In en, this message translates to:
  /// **'Opening hours'**
  String get providerDetailOpeningHours;

  /// No description provided for @providerDetailServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get providerDetailServices;

  /// No description provided for @providerDetailProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get providerDetailProducts;

  /// No description provided for @providerDetailCharging.
  ///
  /// In en, this message translates to:
  /// **'Charging info'**
  String get providerDetailCharging;

  /// No description provided for @providerDetailDistanceAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String providerDetailDistanceAway(String distance);

  /// No description provided for @providerDetailNoPorts.
  ///
  /// In en, this message translates to:
  /// **'{count} charging ports'**
  String providerDetailNoPorts(int count);

  /// No description provided for @noProvidersNearby.
  ///
  /// In en, this message translates to:
  /// **'No CYKEL providers nearby yet.'**
  String get noProvidersNearby;

  /// No description provided for @noChargingStationsNearby.
  ///
  /// In en, this message translates to:
  /// **'No charging stations nearby yet.'**
  String get noChargingStationsNearby;

  /// No description provided for @viewAllProviders.
  ///
  /// In en, this message translates to:
  /// **'View all on map'**
  String get viewAllProviders;

  /// No description provided for @filterCykelRepair.
  ///
  /// In en, this message translates to:
  /// **'Repair'**
  String get filterCykelRepair;

  /// No description provided for @filterCykelShop.
  ///
  /// In en, this message translates to:
  /// **'Shops'**
  String get filterCykelShop;

  /// No description provided for @filterCykelCharging.
  ///
  /// In en, this message translates to:
  /// **'Charging'**
  String get filterCykelCharging;

  /// No description provided for @filterCykelService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get filterCykelService;

  /// No description provided for @filterCykelRental.
  ///
  /// In en, this message translates to:
  /// **'Rental'**
  String get filterCykelRental;

  /// No description provided for @filterCykelAll.
  ///
  /// In en, this message translates to:
  /// **'All CYKEL'**
  String get filterCykelAll;

  /// No description provided for @listingBrandHint.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get listingBrandHint;

  /// No description provided for @listingIsElectric.
  ///
  /// In en, this message translates to:
  /// **'Electric Bike'**
  String get listingIsElectric;

  /// No description provided for @listingIsElectricHint.
  ///
  /// In en, this message translates to:
  /// **'Toggle if this is an electric bicycle'**
  String get listingIsElectricHint;

  /// No description provided for @listingSerialHint.
  ///
  /// In en, this message translates to:
  /// **'Serial Number'**
  String get listingSerialHint;

  /// No description provided for @listingSerialHelp.
  ///
  /// In en, this message translates to:
  /// **'Adding a serial number helps verify authenticity and prevents stolen bikes from being sold.'**
  String get listingSerialHelp;

  /// No description provided for @listingElectricBadge.
  ///
  /// In en, this message translates to:
  /// **'Electric'**
  String get listingElectricBadge;

  /// No description provided for @listingSerialVerified.
  ///
  /// In en, this message translates to:
  /// **'Serial Verified'**
  String get listingSerialVerified;

  /// No description provided for @listingSerialDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Serial'**
  String get listingSerialDuplicate;

  /// No description provided for @listingSerialUnverified.
  ///
  /// In en, this message translates to:
  /// **'Serial Unverified'**
  String get listingSerialUnverified;

  /// No description provided for @locationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get locationsTitle;

  /// No description provided for @noLocationsYet.
  ///
  /// In en, this message translates to:
  /// **'No locations added yet'**
  String get noLocationsYet;

  /// No description provided for @addLocation.
  ///
  /// In en, this message translates to:
  /// **'Add Location'**
  String get addLocation;

  /// No description provided for @editLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Location'**
  String get editLocationTitle;

  /// No description provided for @addLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Location'**
  String get addLocationTitle;

  /// No description provided for @locationNameSection.
  ///
  /// In en, this message translates to:
  /// **'Location Name'**
  String get locationNameSection;

  /// No description provided for @locationNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get locationNameLabel;

  /// No description provided for @locationTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Location Type'**
  String get locationTypeLabel;

  /// No description provided for @contactInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Contact Info'**
  String get contactInfoSection;

  /// No description provided for @photosSection.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photosSection;

  /// No description provided for @locationSaved.
  ///
  /// In en, this message translates to:
  /// **'Location saved!'**
  String get locationSaved;

  /// No description provided for @deleteLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Location?'**
  String get deleteLocationTitle;

  /// No description provided for @deleteLocationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this location? This cannot be undone.'**
  String get deleteLocationConfirm;

  /// No description provided for @pauseLabel.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseLabel;

  /// No description provided for @activateLabel.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activateLabel;

  /// No description provided for @deleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteLabel;

  /// No description provided for @manageLocations.
  ///
  /// In en, this message translates to:
  /// **'Manage Locations'**
  String get manageLocations;

  /// No description provided for @manageListings.
  ///
  /// In en, this message translates to:
  /// **'Manage Listings'**
  String get manageListings;

  /// No description provided for @listingMarkAvailable.
  ///
  /// In en, this message translates to:
  /// **'Mark as Available'**
  String get listingMarkAvailable;

  /// No description provided for @listingStatusSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get listingStatusSold;

  /// No description provided for @listingStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get listingStatusActive;

  /// No description provided for @purchaseUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Purchase is currently unavailable'**
  String get purchaseUnavailable;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restorePurchases;

  /// No description provided for @restorePurchasesDone.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored'**
  String get restorePurchasesDone;

  /// No description provided for @premiumFeatureBody.
  ///
  /// In en, this message translates to:
  /// **'This feature is available with a Premium subscription.'**
  String get premiumFeatureBody;

  /// No description provided for @routeEffort.
  ///
  /// In en, this message translates to:
  /// **'Effort'**
  String get routeEffort;

  /// No description provided for @darkRidingAlert.
  ///
  /// In en, this message translates to:
  /// **'Dark riding'**
  String get darkRidingAlert;

  /// No description provided for @lowVisibility.
  ///
  /// In en, this message translates to:
  /// **'Low visibility'**
  String get lowVisibility;

  /// No description provided for @chargeSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Consider charging before your ride'**
  String get chargeSuggestion;

  /// No description provided for @commuterTax.
  ///
  /// In en, this message translates to:
  /// **'Commuter Tax Deduction'**
  String get commuterTax;

  /// No description provided for @commuteDays.
  ///
  /// In en, this message translates to:
  /// **'Commute days'**
  String get commuteDays;

  /// No description provided for @commuteKm.
  ///
  /// In en, this message translates to:
  /// **'Commute km'**
  String get commuteKm;

  /// No description provided for @deductibleKm.
  ///
  /// In en, this message translates to:
  /// **'Deductible km'**
  String get deductibleKm;

  /// No description provided for @estimatedDeduction.
  ///
  /// In en, this message translates to:
  /// **'Est. deduction: {amount} DKK'**
  String estimatedDeduction(String amount);

  /// No description provided for @estimatedTaxSavings.
  ///
  /// In en, this message translates to:
  /// **'Est. tax savings: ~{amount} DKK'**
  String estimatedTaxSavings(String amount);

  /// No description provided for @taxDeductionInfo.
  ///
  /// In en, this message translates to:
  /// **'Tax Deduction Info'**
  String get taxDeductionInfo;

  /// No description provided for @yearToDate.
  ///
  /// In en, this message translates to:
  /// **'Year-to-Date'**
  String get yearToDate;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get howItWorks;

  /// No description provided for @rateBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Rate Breakdown'**
  String get rateBreakdown;

  /// No description provided for @exportForTaxFiling.
  ///
  /// In en, this message translates to:
  /// **'Export for Tax Filing'**
  String get exportForTaxFiling;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get learnMore;

  /// No description provided for @noCommuteTripsYet.
  ///
  /// In en, this message translates to:
  /// **'No Commute Trips Yet'**
  String get noCommuteTripsYet;

  /// No description provided for @setHomeWorkAddresses.
  ///
  /// In en, this message translates to:
  /// **'Set your home and work addresses to start tracking commute tax deductions'**
  String get setHomeWorkAddresses;

  /// No description provided for @configure.
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get configure;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get failedToLoad;

  /// No description provided for @hazardThunderstorm.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get hazardThunderstorm;

  /// No description provided for @batteryCapacity.
  ///
  /// In en, this message translates to:
  /// **'Battery capacity'**
  String get batteryCapacity;

  /// No description provided for @alertHeavyRainTitle.
  ///
  /// In en, this message translates to:
  /// **'Heavy Rain Warning'**
  String get alertHeavyRainTitle;

  /// No description provided for @alertHeavyRainMessage.
  ///
  /// In en, this message translates to:
  /// **'Heavy rain detected ({amount}mm/h). Consider indoor activities.'**
  String alertHeavyRainMessage(String amount);

  /// No description provided for @alertStrongWindTitle.
  ///
  /// In en, this message translates to:
  /// **'Strong Wind Warning'**
  String get alertStrongWindTitle;

  /// No description provided for @alertStrongWindMessage.
  ///
  /// In en, this message translates to:
  /// **'Winds up to {speed} km/h. Ride with caution.'**
  String alertStrongWindMessage(String speed);

  /// No description provided for @alertIceRiskTitle.
  ///
  /// In en, this message translates to:
  /// **'Ice Risk Warning'**
  String get alertIceRiskTitle;

  /// No description provided for @alertIceRiskMessage.
  ///
  /// In en, this message translates to:
  /// **'Freezing temperatures with precipitation. Roads may be icy.'**
  String get alertIceRiskMessage;

  /// No description provided for @alertExtremeColdTitle.
  ///
  /// In en, this message translates to:
  /// **'Extreme Cold Warning'**
  String get alertExtremeColdTitle;

  /// No description provided for @alertExtremeColdMessage.
  ///
  /// In en, this message translates to:
  /// **'Temperature is {temp}°C. Dress warmly and consider shorter rides.'**
  String alertExtremeColdMessage(String temp);

  /// No description provided for @alertHighWindsTitle.
  ///
  /// In en, this message translates to:
  /// **'High Wind Warning'**
  String get alertHighWindsTitle;

  /// No description provided for @alertHighWindsMessage.
  ///
  /// In en, this message translates to:
  /// **'Very strong winds ({speed} km/h). Not recommended for cycling.'**
  String alertHighWindsMessage(String speed);

  /// No description provided for @alertFogTitle.
  ///
  /// In en, this message translates to:
  /// **'Fog Warning'**
  String get alertFogTitle;

  /// No description provided for @alertFogMessage.
  ///
  /// In en, this message translates to:
  /// **'Reduced visibility due to fog. Use lights and reflective gear.'**
  String get alertFogMessage;

  /// No description provided for @alertDarknessTitle.
  ///
  /// In en, this message translates to:
  /// **'Dark Riding'**
  String get alertDarknessTitle;

  /// No description provided for @alertDarknessMessage.
  ///
  /// In en, this message translates to:
  /// **'It is currently dark. Use front and rear lights, wear reflective gear.'**
  String get alertDarknessMessage;

  /// No description provided for @alertSunsetTitle.
  ///
  /// In en, this message translates to:
  /// **'Sunset Approaching'**
  String get alertSunsetTitle;

  /// No description provided for @alertSunsetMessage.
  ///
  /// In en, this message translates to:
  /// **'Sunset at {time}. Bring lights.'**
  String alertSunsetMessage(String time);

  /// No description provided for @alertWinterIceTitle.
  ///
  /// In en, this message translates to:
  /// **'Winter Ice Risk'**
  String get alertWinterIceTitle;

  /// No description provided for @alertWinterIceMessage.
  ///
  /// In en, this message translates to:
  /// **'Temperature near freezing with moisture. Watch for ice on bridges and shaded paths.'**
  String get alertWinterIceMessage;

  /// No description provided for @severityInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get severityInfo;

  /// No description provided for @severityCaution.
  ///
  /// In en, this message translates to:
  /// **'Caution'**
  String get severityCaution;

  /// No description provided for @severityDanger.
  ///
  /// In en, this message translates to:
  /// **'Danger'**
  String get severityDanger;

  /// No description provided for @statusReported.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get statusReported;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @statusUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get statusUnderReview;

  /// No description provided for @statusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get statusResolved;

  /// No description provided for @credibilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Credibility: {score}% ({confirms} ✓  {dismisses} ✗)'**
  String credibilityLabel(String score, String confirms, String dismisses);

  /// No description provided for @commuterTaxSettings.
  ///
  /// In en, this message translates to:
  /// **'Commuter Tax'**
  String get commuterTaxSettings;

  /// No description provided for @commuterTaxTitle.
  ///
  /// In en, this message translates to:
  /// **'Commuter Tax Settings'**
  String get commuterTaxTitle;

  /// No description provided for @commuterTaxDescription.
  ///
  /// In en, this message translates to:
  /// **'Set your home and work addresses to calculate the Danish commuter tax deduction for your rides.'**
  String get commuterTaxDescription;

  /// No description provided for @homeAddress.
  ///
  /// In en, this message translates to:
  /// **'Home Address'**
  String get homeAddress;

  /// No description provided for @workAddress.
  ///
  /// In en, this message translates to:
  /// **'Work Address'**
  String get workAddress;

  /// No description provided for @savedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get savedSuccessfully;

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Action'**
  String get confirmAction;

  /// No description provided for @confirmMaintenanceReset.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to mark maintenance as complete? This will reset your service reminder.'**
  String get confirmMaintenanceReset;

  /// No description provided for @maintenanceMarkedDone.
  ///
  /// In en, this message translates to:
  /// **'Maintenance marked as complete'**
  String get maintenanceMarkedDone;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go home'**
  String get goHome;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @validationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get validationPasswordTooShort;

  /// No description provided for @validationConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get validationConfirmPasswordRequired;

  /// No description provided for @validationPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validationPasswordsDoNotMatch;

  /// No description provided for @validationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get validationNameRequired;

  /// No description provided for @validationNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name is too short'**
  String get validationNameTooShort;

  /// No description provided for @validationPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Danish phone number'**
  String get validationPhoneInvalid;

  /// No description provided for @validationPostalCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Postal code is required'**
  String get validationPostalCodeRequired;

  /// No description provided for @validationPostalCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 4-digit postal code'**
  String get validationPostalCodeInvalid;

  /// No description provided for @validationPostalCodeRange.
  ///
  /// In en, this message translates to:
  /// **'Postal code must be between 1000 and 9990'**
  String get validationPostalCodeRange;

  /// No description provided for @validationFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{field} is required'**
  String validationFieldRequired(String field);

  /// No description provided for @validationPriceRequired.
  ///
  /// In en, this message translates to:
  /// **'Price is required'**
  String get validationPriceRequired;

  /// No description provided for @validationPriceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price'**
  String get validationPriceInvalid;

  /// No description provided for @validationPriceTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Price is too high'**
  String get validationPriceTooHigh;

  /// No description provided for @validationSerialTooShort.
  ///
  /// In en, this message translates to:
  /// **'Serial number is too short'**
  String get validationSerialTooShort;

  /// No description provided for @validationSerialTooLong.
  ///
  /// In en, this message translates to:
  /// **'Serial number is too long'**
  String get validationSerialTooLong;

  /// No description provided for @validationUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid URL (https://...)'**
  String get validationUrlInvalid;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @swapLocations.
  ///
  /// In en, this message translates to:
  /// **'Swap locations'**
  String get swapLocations;

  /// No description provided for @openChats.
  ///
  /// In en, this message translates to:
  /// **'Open chats'**
  String get openChats;

  /// No description provided for @removeFromSaved.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get removeFromSaved;

  /// No description provided for @saveListing.
  ///
  /// In en, this message translates to:
  /// **'Save listing'**
  String get saveListing;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @joinChallenge.
  ///
  /// In en, this message translates to:
  /// **'Join challenge'**
  String get joinChallenge;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @sendComment.
  ///
  /// In en, this message translates to:
  /// **'Send comment'**
  String get sendComment;

  /// No description provided for @friendRequests.
  ///
  /// In en, this message translates to:
  /// **'Friend requests'**
  String get friendRequests;

  /// No description provided for @searchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search users'**
  String get searchUsers;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String errorPrefix(String error);

  /// No description provided for @groupRides.
  ///
  /// In en, this message translates to:
  /// **'Group Rides'**
  String get groupRides;

  /// No description provided for @eventsTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get eventsTabAll;

  /// No description provided for @eventsTabMine.
  ///
  /// In en, this message translates to:
  /// **'My Events'**
  String get eventsTabMine;

  /// No description provided for @eventsTabCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get eventsTabCreated;

  /// No description provided for @createEvent.
  ///
  /// In en, this message translates to:
  /// **'Create Ride'**
  String get createEvent;

  /// No description provided for @discoverGroupRides.
  ///
  /// In en, this message translates to:
  /// **'DISCOVER'**
  String get discoverGroupRides;

  /// No description provided for @popularEvents.
  ///
  /// In en, this message translates to:
  /// **'Popular Rides'**
  String get popularEvents;

  /// No description provided for @upcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingEvents;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @noUpcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'No upcoming rides'**
  String get noUpcomingEvents;

  /// No description provided for @beFirstToCreate.
  ///
  /// In en, this message translates to:
  /// **'Be the first to create a group ride!'**
  String get beFirstToCreate;

  /// No description provided for @noJoinedEvents.
  ///
  /// In en, this message translates to:
  /// **'No joined rides'**
  String get noJoinedEvents;

  /// No description provided for @joinEventToSeeHere.
  ///
  /// In en, this message translates to:
  /// **'Join a ride to see them here'**
  String get joinEventToSeeHere;

  /// No description provided for @noCreatedEvents.
  ///
  /// In en, this message translates to:
  /// **'No created rides'**
  String get noCreatedEvents;

  /// No description provided for @createYourFirstEvent.
  ///
  /// In en, this message translates to:
  /// **'Create your first group ride!'**
  String get createYourFirstEvent;

  /// No description provided for @joinedBadge.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joinedBadge;

  /// No description provided for @organizerBadge.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get organizerBadge;

  /// No description provided for @noDropTooltip.
  ///
  /// In en, this message translates to:
  /// **'No-drop: Group waits for everyone'**
  String get noDropTooltip;

  /// No description provided for @todayBadge.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayBadge;

  /// No description provided for @searchEvents.
  ///
  /// In en, this message translates to:
  /// **'Search for rides...'**
  String get searchEvents;

  /// No description provided for @searchEventsHint.
  ///
  /// In en, this message translates to:
  /// **'Search rides by name'**
  String get searchEventsHint;

  /// No description provided for @noEventsFound.
  ///
  /// In en, this message translates to:
  /// **'No rides found'**
  String get noEventsFound;

  /// No description provided for @eventError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get eventError;

  /// No description provided for @eventNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get eventNotFound;

  /// No description provided for @eventNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'The event was not found'**
  String get eventNotFoundMessage;

  /// No description provided for @editEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editEvent;

  /// No description provided for @cancelEvent.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelEvent;

  /// No description provided for @deleteEvent.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteEvent;

  /// No description provided for @dateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get dateAndTime;

  /// No description provided for @timePrefix.
  ///
  /// In en, this message translates to:
  /// **'At'**
  String get timePrefix;

  /// No description provided for @estimatedDuration.
  ///
  /// In en, this message translates to:
  /// **'Estimated duration: {hours} hours'**
  String estimatedDuration(String hours);

  /// No description provided for @meetingPoint.
  ///
  /// In en, this message translates to:
  /// **'Meeting point'**
  String get meetingPoint;

  /// No description provided for @navigateToMeetingPoint.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigateToMeetingPoint;

  /// No description provided for @eventDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get eventDescription;

  /// No description provided for @rideDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get rideDetails;

  /// No description provided for @kmUnit.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get kmUnit;

  /// No description provided for @kmhUnit.
  ///
  /// In en, this message translates to:
  /// **'km/h'**
  String get kmhUnit;

  /// No description provided for @elevationUnit.
  ///
  /// In en, this message translates to:
  /// **'m elevation'**
  String get elevationUnit;

  /// No description provided for @lightsRequired.
  ///
  /// In en, this message translates to:
  /// **'Lights required'**
  String get lightsRequired;

  /// No description provided for @eventOrganizer.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get eventOrganizer;

  /// No description provided for @organizerLabel.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get organizerLabel;

  /// No description provided for @participants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participants;

  /// No description provided for @peopleJoined.
  ///
  /// In en, this message translates to:
  /// **'people joined'**
  String get peopleJoined;

  /// No description provided for @noParticipantsYet.
  ///
  /// In en, this message translates to:
  /// **'No participants yet'**
  String get noParticipantsYet;

  /// No description provided for @eventFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get eventFull;

  /// No description provided for @openChat.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get openChat;

  /// No description provided for @leaveEvent.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leaveEvent;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @eventIsFull.
  ///
  /// In en, this message translates to:
  /// **'Event is full'**
  String get eventIsFull;

  /// No description provided for @joinEvent.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinEvent;

  /// No description provided for @discoverEvents.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverEvents;

  /// No description provided for @youAreJoined.
  ///
  /// In en, this message translates to:
  /// **'You are now joined!'**
  String get youAreJoined;

  /// No description provided for @youAreLeft.
  ///
  /// In en, this message translates to:
  /// **'You have left the event'**
  String get youAreLeft;

  /// No description provided for @chatComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Chat coming soon!'**
  String get chatComingSoon;

  /// No description provided for @eventCancelled.
  ///
  /// In en, this message translates to:
  /// **'Event cancelled'**
  String get eventCancelled;

  /// No description provided for @eventDeleted.
  ///
  /// In en, this message translates to:
  /// **'Event deleted'**
  String get eventDeleted;

  /// No description provided for @leaveEventQuestion.
  ///
  /// In en, this message translates to:
  /// **'Leave event?'**
  String get leaveEventQuestion;

  /// No description provided for @leaveEventConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this ride?'**
  String get leaveEventConfirm;

  /// No description provided for @cancelEventQuestion.
  ///
  /// In en, this message translates to:
  /// **'Cancel event?'**
  String get cancelEventQuestion;

  /// No description provided for @cancelEventConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this ride? All participants will be notified.'**
  String get cancelEventConfirm;

  /// No description provided for @deleteEventQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete event?'**
  String get deleteEventQuestion;

  /// No description provided for @deleteEventConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this ride? This cannot be undone.'**
  String get deleteEventConfirm;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @confirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel Event'**
  String get confirmCancel;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get confirmDelete;

  /// No description provided for @shareEventText.
  ///
  /// In en, this message translates to:
  /// **'Join in the CYKEL app!'**
  String get shareEventText;

  /// No description provided for @repeatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get repeatsLabel;

  /// No description provided for @noDropPolicy.
  ///
  /// In en, this message translates to:
  /// **'No-drop policy'**
  String get noDropPolicy;

  /// No description provided for @noDropDescription.
  ///
  /// In en, this message translates to:
  /// **'Group waits for everyone'**
  String get noDropDescription;

  /// No description provided for @createGroupRide.
  ///
  /// In en, this message translates to:
  /// **'Create Group Ride'**
  String get createGroupRide;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get basicInfo;

  /// No description provided for @eventTitle.
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get eventTitle;

  /// No description provided for @eventTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sunday Morning Group Ride'**
  String get eventTitleHint;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @eventDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get eventDescriptionLabel;

  /// No description provided for @eventDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the ride...'**
  String get eventDescriptionHint;

  /// No description provided for @eventType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get eventType;

  /// No description provided for @difficultyLevel.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficultyLevel;

  /// No description provided for @dateAndTimeSection.
  ///
  /// In en, this message translates to:
  /// **'Date and Time'**
  String get dateAndTimeSection;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @meetingPointSection.
  ///
  /// In en, this message translates to:
  /// **'Meeting Point'**
  String get meetingPointSection;

  /// No description provided for @placeNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Copenhagen City Hall'**
  String get placeNameHint;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address *'**
  String get address;

  /// No description provided for @addressHint.
  ///
  /// In en, this message translates to:
  /// **'Search for address...'**
  String get addressHint;

  /// No description provided for @addressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address is required'**
  String get addressRequired;

  /// No description provided for @searchingAddress.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searchingAddress;

  /// No description provided for @rideDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Ride Details'**
  String get rideDetailsSection;

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'Distance (km)'**
  String get distanceKm;

  /// No description provided for @durationMin.
  ///
  /// In en, this message translates to:
  /// **'Duration (min)'**
  String get durationMin;

  /// No description provided for @paceKmh.
  ///
  /// In en, this message translates to:
  /// **'Pace (km/h)'**
  String get paceKmh;

  /// No description provided for @elevationGainM.
  ///
  /// In en, this message translates to:
  /// **'Elevation gain (m)'**
  String get elevationGainM;

  /// No description provided for @maxParticipants.
  ///
  /// In en, this message translates to:
  /// **'Max participants'**
  String get maxParticipants;

  /// No description provided for @settingsSection.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsSection;

  /// No description provided for @lightsRequiredToggle.
  ///
  /// In en, this message translates to:
  /// **'Lights required'**
  String get lightsRequiredToggle;

  /// No description provided for @lightsRequiredDescription.
  ///
  /// In en, this message translates to:
  /// **'For evening/night rides'**
  String get lightsRequiredDescription;

  /// No description provided for @visibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get visibility;

  /// No description provided for @visibilityPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get visibilityPublic;

  /// No description provided for @visibilityPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get visibilityPrivate;

  /// No description provided for @createEventButton.
  ///
  /// In en, this message translates to:
  /// **'Create Group Ride'**
  String get createEventButton;

  /// No description provided for @couldNotFindCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Could not find coordinates'**
  String get couldNotFindCoordinates;

  /// No description provided for @noAddressesFound.
  ///
  /// In en, this message translates to:
  /// **'No addresses found'**
  String get noAddressesFound;

  /// No description provided for @searchForAddressFirst.
  ///
  /// In en, this message translates to:
  /// **'Search for an address first'**
  String get searchForAddressFirst;

  /// No description provided for @mustBeLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in'**
  String get mustBeLoggedIn;

  /// No description provided for @eventCreated.
  ///
  /// In en, this message translates to:
  /// **'Group ride created!'**
  String get eventCreated;

  /// No description provided for @couldNotFindAddress.
  ///
  /// In en, this message translates to:
  /// **'Could not find address'**
  String get couldNotFindAddress;

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get difficultyModerate;

  /// No description provided for @difficultyChallenging.
  ///
  /// In en, this message translates to:
  /// **'Challenging'**
  String get difficultyChallenging;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// No description provided for @eventTypeSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get eventTypeSocial;

  /// No description provided for @eventTypeTraining.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get eventTypeTraining;

  /// No description provided for @eventTypeCommute.
  ///
  /// In en, this message translates to:
  /// **'Commute'**
  String get eventTypeCommute;

  /// No description provided for @eventTypeTour.
  ///
  /// In en, this message translates to:
  /// **'Tour'**
  String get eventTypeTour;

  /// No description provided for @eventTypeRace.
  ///
  /// In en, this message translates to:
  /// **'Race'**
  String get eventTypeRace;

  /// No description provided for @eventTypeGravel.
  ///
  /// In en, this message translates to:
  /// **'Gravel'**
  String get eventTypeGravel;

  /// No description provided for @eventTypeMtb.
  ///
  /// In en, this message translates to:
  /// **'MTB'**
  String get eventTypeMtb;

  /// No description provided for @eventTypeBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get eventTypeBeginner;

  /// No description provided for @eventTypeFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get eventTypeFamily;

  /// No description provided for @eventTypeNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get eventTypeNight;

  /// No description provided for @visibilityFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends only'**
  String get visibilityFriends;

  /// No description provided for @visibilityInviteOnly.
  ///
  /// In en, this message translates to:
  /// **'Invite only'**
  String get visibilityInviteOnly;

  /// No description provided for @eventStatusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get eventStatusUpcoming;

  /// No description provided for @eventStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get eventStatusActive;

  /// No description provided for @eventStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get eventStatusCompleted;

  /// No description provided for @eventStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get eventStatusCancelled;

  /// No description provided for @eventDateTimePast.
  ///
  /// In en, this message translates to:
  /// **'Event date/time cannot be in the past'**
  String get eventDateTimePast;

  /// No description provided for @challenges.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get challenges;

  /// No description provided for @yourActiveChallenges.
  ///
  /// In en, this message translates to:
  /// **'Your active challenges'**
  String get yourActiveChallenges;

  /// No description provided for @availableChallenges.
  ///
  /// In en, this message translates to:
  /// **'Available challenges'**
  String get availableChallenges;

  /// No description provided for @joinedChallenge.
  ///
  /// In en, this message translates to:
  /// **'You are now in \"{title}\"!'**
  String joinedChallenge(String title);

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @badges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badges;

  /// No description provided for @levelProgress.
  ///
  /// In en, this message translates to:
  /// **'Level {current} → Level {next}'**
  String levelProgress(int current, int next);

  /// No description provided for @pointsToNextLevel.
  ///
  /// In en, this message translates to:
  /// **'{points} points to next level'**
  String pointsToNextLevel(int points);

  /// No description provided for @challengeTypeDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get challengeTypeDistance;

  /// No description provided for @challengeTypeRideCount.
  ///
  /// In en, this message translates to:
  /// **'Ride Count'**
  String get challengeTypeRideCount;

  /// No description provided for @challengeTypeElevation.
  ///
  /// In en, this message translates to:
  /// **'Elevation'**
  String get challengeTypeElevation;

  /// No description provided for @challengeTypeStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get challengeTypeStreak;

  /// No description provided for @challengeTypeCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get challengeTypeCommunity;

  /// No description provided for @challengeTypeSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get challengeTypeSpeed;

  /// No description provided for @challengeTypeExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get challengeTypeExplore;

  /// No description provided for @challengePoints.
  ///
  /// In en, this message translates to:
  /// **'{points} {points, plural, =1{point} other{points}}'**
  String challengePoints(int points);

  /// No description provided for @difficultyLevelEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyLevelEasy;

  /// No description provided for @difficultyLevelMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get difficultyLevelMedium;

  /// No description provided for @difficultyLevelHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyLevelHard;

  /// No description provided for @difficultyLevelExtreme.
  ///
  /// In en, this message translates to:
  /// **'Extreme'**
  String get difficultyLevelExtreme;

  /// No description provided for @badgesTitle.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badgesTitle;

  /// No description provided for @badgesEarnedOf.
  ///
  /// In en, this message translates to:
  /// **'{earned} of {total}'**
  String badgesEarnedOf(int earned, int total);

  /// No description provided for @badgesEarned.
  ///
  /// In en, this message translates to:
  /// **'badges earned'**
  String get badgesEarned;

  /// No description provided for @percentComplete.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String percentComplete(String percent);

  /// No description provided for @badgeEarned.
  ///
  /// In en, this message translates to:
  /// **'Earned!'**
  String get badgeEarned;

  /// No description provided for @badgeKeepRiding.
  ///
  /// In en, this message translates to:
  /// **'Keep riding to earn this badge!'**
  String get badgeKeepRiding;

  /// No description provided for @rarityCommon.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get rarityCommon;

  /// No description provided for @rarityUncommon.
  ///
  /// In en, this message translates to:
  /// **'Uncommon'**
  String get rarityUncommon;

  /// No description provided for @rarityRare.
  ///
  /// In en, this message translates to:
  /// **'Rare'**
  String get rarityRare;

  /// No description provided for @rarityEpic.
  ///
  /// In en, this message translates to:
  /// **'Epic'**
  String get rarityEpic;

  /// No description provided for @rarityLegendary.
  ///
  /// In en, this message translates to:
  /// **'Legendary'**
  String get rarityLegendary;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @leaderboardYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get leaderboardYou;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noDataYet;

  /// No description provided for @startRidingToJoin.
  ///
  /// In en, this message translates to:
  /// **'Start riding to join the leaderboard!'**
  String get startRidingToJoin;

  /// No description provided for @periodThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get periodThisWeek;

  /// No description provided for @periodThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get periodThisMonth;

  /// No description provided for @periodAllTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get periodAllTime;

  /// No description provided for @buddyFindRidingBuddies.
  ///
  /// In en, this message translates to:
  /// **'Find Riding Buddies'**
  String get buddyFindRidingBuddies;

  /// No description provided for @buddyTabForYou.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get buddyTabForYou;

  /// No description provided for @buddyTabRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get buddyTabRequests;

  /// No description provided for @buddyTabMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get buddyTabMatches;

  /// No description provided for @buddyFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get buddyFilters;

  /// No description provided for @buddyRidingLevel.
  ///
  /// In en, this message translates to:
  /// **'Riding Level'**
  String get buddyRidingLevel;

  /// No description provided for @buddyAllLevels.
  ///
  /// In en, this message translates to:
  /// **'All Levels'**
  String get buddyAllLevels;

  /// No description provided for @buddyInterests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get buddyInterests;

  /// No description provided for @buddyCreateProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Your Buddy Profile'**
  String get buddyCreateProfile;

  /// No description provided for @buddyCreateProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Set up your riding profile to find compatible cycling partners'**
  String get buddyCreateProfileDesc;

  /// No description provided for @buddyCreateProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Create Profile'**
  String get buddyCreateProfileButton;

  /// No description provided for @buddyNoMatchesFound.
  ///
  /// In en, this message translates to:
  /// **'No Matches Found'**
  String get buddyNoMatchesFound;

  /// No description provided for @buddyNoMatchesFoundDesc.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your preferences or check back later'**
  String get buddyNoMatchesFoundDesc;

  /// No description provided for @buddyNoPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'No Pending Requests'**
  String get buddyNoPendingRequests;

  /// No description provided for @buddyNoPendingRequestsDesc.
  ///
  /// In en, this message translates to:
  /// **'Match requests will appear here'**
  String get buddyNoPendingRequestsDesc;

  /// No description provided for @buddyNoMatchesYet.
  ///
  /// In en, this message translates to:
  /// **'No Matches Yet'**
  String get buddyNoMatchesYet;

  /// No description provided for @buddyConnectInForYou.
  ///
  /// In en, this message translates to:
  /// **'Start connecting with riders in the \"For You\" tab'**
  String get buddyConnectInForYou;

  /// No description provided for @buddyAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get buddyAbout;

  /// No description provided for @buddyStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get buddyStats;

  /// No description provided for @buddyAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get buddyAvailability;

  /// No description provided for @buddyLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get buddyLanguages;

  /// No description provided for @buddyClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get buddyClose;

  /// No description provided for @buddySendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get buddySendRequest;

  /// No description provided for @buddyMatchRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Match request sent to {name}!'**
  String buddyMatchRequestSent(String name);

  /// No description provided for @buddyDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get buddyDecline;

  /// No description provided for @buddyAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get buddyAccept;

  /// No description provided for @buddyMatchAccepted.
  ///
  /// In en, this message translates to:
  /// **'Match accepted!'**
  String get buddyMatchAccepted;

  /// No description provided for @buddyRequestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Request declined'**
  String get buddyRequestDeclined;

  /// No description provided for @buddyChatComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Chat coming soon'**
  String get buddyChatComingSoon;

  /// No description provided for @rentalSectionBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get rentalSectionBasicInfo;

  /// No description provided for @rentalSectionDetails.
  ///
  /// In en, this message translates to:
  /// **'Details (Optional)'**
  String get rentalSectionDetails;

  /// No description provided for @rentalSectionPricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get rentalSectionPricing;

  /// No description provided for @rentalSectionFeatures.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get rentalSectionFeatures;

  /// No description provided for @rentalSectionLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get rentalSectionLocation;

  /// No description provided for @rentalSectionAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get rentalSectionAvailability;

  /// No description provided for @rentalSectionAdditionalInfo.
  ///
  /// In en, this message translates to:
  /// **'Additional Information'**
  String get rentalSectionAdditionalInfo;

  /// No description provided for @rentalSectionPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get rentalSectionPhotos;

  /// No description provided for @rentalAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get rentalAddPhotos;

  /// No description provided for @rentalNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos added yet'**
  String get rentalNoPhotos;

  /// No description provided for @rentalAvailableFrom.
  ///
  /// In en, this message translates to:
  /// **'Available From'**
  String get rentalAvailableFrom;

  /// No description provided for @rentalAvailableTo.
  ///
  /// In en, this message translates to:
  /// **'Available To'**
  String get rentalAvailableTo;

  /// No description provided for @rentalNoStartDate.
  ///
  /// In en, this message translates to:
  /// **'No start date (available immediately)'**
  String get rentalNoStartDate;

  /// No description provided for @rentalNoEndDate.
  ///
  /// In en, this message translates to:
  /// **'No end date (available indefinitely)'**
  String get rentalNoEndDate;

  /// No description provided for @rentalSelectDates.
  ///
  /// In en, this message translates to:
  /// **'Please select start and end dates/times'**
  String get rentalSelectDates;

  /// No description provided for @rentalLocationSet.
  ///
  /// In en, this message translates to:
  /// **'Location set to Copenhagen (picker pending)'**
  String get rentalLocationSet;

  /// No description provided for @rentalSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Please select a pickup location'**
  String get rentalSelectLocation;

  /// No description provided for @rentalErrorSaving.
  ///
  /// In en, this message translates to:
  /// **'Error saving listing: {error}'**
  String rentalErrorSaving(String error);

  /// No description provided for @rentalDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get rentalDescription;

  /// No description provided for @rentalDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get rentalDetails;

  /// No description provided for @rentalTerms.
  ///
  /// In en, this message translates to:
  /// **'Rental Terms'**
  String get rentalTerms;

  /// No description provided for @rentalReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews ({count})'**
  String rentalReviews(int count);

  /// No description provided for @rentalConfirmRequest.
  ///
  /// In en, this message translates to:
  /// **'Confirm Rental Request'**
  String get rentalConfirmRequest;

  /// No description provided for @rentalBikeLabel.
  ///
  /// In en, this message translates to:
  /// **'Bike: {title}'**
  String rentalBikeLabel(String title);

  /// No description provided for @rentalRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Rental request sent! Owner will be notified.'**
  String get rentalRequestSent;

  /// No description provided for @rentalListingNotFound.
  ///
  /// In en, this message translates to:
  /// **'Listing not found'**
  String get rentalListingNotFound;

  /// No description provided for @rentalRequestButton.
  ///
  /// In en, this message translates to:
  /// **'Request Rental'**
  String get rentalRequestButton;

  /// No description provided for @rentalRentABike.
  ///
  /// In en, this message translates to:
  /// **'Rent a Bike'**
  String get rentalRentABike;

  /// No description provided for @rentalListYourBike.
  ///
  /// In en, this message translates to:
  /// **'List Your Bike'**
  String get rentalListYourBike;

  /// No description provided for @rentalClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get rentalClear;

  /// No description provided for @rentalApplyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get rentalApplyFilters;

  /// No description provided for @rentalFilterBikeType.
  ///
  /// In en, this message translates to:
  /// **'Bike Type'**
  String get rentalFilterBikeType;

  /// No description provided for @rentalFilterSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get rentalFilterSize;

  /// No description provided for @rentalFilterMaxPrice.
  ///
  /// In en, this message translates to:
  /// **'Maximum Price'**
  String get rentalFilterMaxPrice;

  /// No description provided for @rentalFilterFeatures.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get rentalFilterFeatures;

  /// No description provided for @rentalFilterHelmet.
  ///
  /// In en, this message translates to:
  /// **'Helmet included'**
  String get rentalFilterHelmet;

  /// No description provided for @rentalFilterLock.
  ///
  /// In en, this message translates to:
  /// **'Lock included'**
  String get rentalFilterLock;

  /// No description provided for @rentalFilterFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get rentalFilterFrom;

  /// No description provided for @rentalEndAfterStart.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get rentalEndAfterStart;

  /// No description provided for @eventsApplyFilter.
  ///
  /// In en, this message translates to:
  /// **'Apply Filter'**
  String get eventsApplyFilter;

  /// No description provided for @eventsError.
  ///
  /// In en, this message translates to:
  /// **'Error loading events'**
  String get eventsError;

  /// No description provided for @chatDeleteConversation.
  ///
  /// In en, this message translates to:
  /// **'Delete Conversation'**
  String get chatDeleteConversation;

  /// No description provided for @chatMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get chatMessages;

  /// No description provided for @chatErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading conversations'**
  String get chatErrorLoading;

  /// No description provided for @chatErrorLoadingMessages.
  ///
  /// In en, this message translates to:
  /// **'Error loading messages: {error}'**
  String chatErrorLoadingMessages(String error);

  /// No description provided for @chatSendPhoto.
  ///
  /// In en, this message translates to:
  /// **'Send Photo'**
  String get chatSendPhoto;

  /// No description provided for @chatShareLocation.
  ///
  /// In en, this message translates to:
  /// **'Share Location'**
  String get chatShareLocation;

  /// No description provided for @chatDeleteConversationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Conversation'**
  String get chatDeleteConversationTitle;

  /// No description provided for @chatLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get chatLoading;

  /// No description provided for @routesCreateRoute.
  ///
  /// In en, this message translates to:
  /// **'Create Route'**
  String get routesCreateRoute;

  /// No description provided for @routesCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get routesCreate;

  /// No description provided for @routesOptimizeRoute.
  ///
  /// In en, this message translates to:
  /// **'Optimize Route'**
  String get routesOptimizeRoute;

  /// No description provided for @routesMinTwoWaypoints.
  ///
  /// In en, this message translates to:
  /// **'Route must have at least 2 waypoints'**
  String get routesMinTwoWaypoints;

  /// No description provided for @routesEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a route name'**
  String get routesEnterName;

  /// No description provided for @routesCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Route created successfully!'**
  String get routesCreatedSuccess;

  /// No description provided for @routesErrorCreating.
  ///
  /// In en, this message translates to:
  /// **'Error creating route: {error}'**
  String routesErrorCreating(String error);

  /// No description provided for @routesRoundTrip.
  ///
  /// In en, this message translates to:
  /// **'Round Trip'**
  String get routesRoundTrip;

  /// No description provided for @routesRoundTripDesc.
  ///
  /// In en, this message translates to:
  /// **'Route returns to start'**
  String get routesRoundTripDesc;

  /// No description provided for @routesCalculateElevation.
  ///
  /// In en, this message translates to:
  /// **'Calculate Elevation'**
  String get routesCalculateElevation;

  /// No description provided for @routesCalculateElevationDesc.
  ///
  /// In en, this message translates to:
  /// **'Include elevation profile'**
  String get routesCalculateElevationDesc;

  /// No description provided for @routesFetchWeather.
  ///
  /// In en, this message translates to:
  /// **'Fetch Weather'**
  String get routesFetchWeather;

  /// No description provided for @routesFetchWeatherDesc.
  ///
  /// In en, this message translates to:
  /// **'Get current weather data'**
  String get routesFetchWeatherDesc;

  /// No description provided for @routesAddTag.
  ///
  /// In en, this message translates to:
  /// **'Add Tag'**
  String get routesAddTag;

  /// No description provided for @routesEditWaypoint.
  ///
  /// In en, this message translates to:
  /// **'Edit Waypoint'**
  String get routesEditWaypoint;

  /// No description provided for @routesMyRoutes.
  ///
  /// In en, this message translates to:
  /// **'My Routes'**
  String get routesMyRoutes;

  /// No description provided for @routesErrorLoadingRoutes.
  ///
  /// In en, this message translates to:
  /// **'Error loading routes: {error}'**
  String routesErrorLoadingRoutes(String error);

  /// No description provided for @routesRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get routesRetry;

  /// No description provided for @routesFilterByTag.
  ///
  /// In en, this message translates to:
  /// **'Filter by Tag'**
  String get routesFilterByTag;

  /// No description provided for @routesAllRoutes.
  ///
  /// In en, this message translates to:
  /// **'All Routes'**
  String get routesAllRoutes;

  /// No description provided for @routesDeleteRoute.
  ///
  /// In en, this message translates to:
  /// **'Delete Route'**
  String get routesDeleteRoute;

  /// No description provided for @routesDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this route?'**
  String get routesDeleteConfirm;

  /// No description provided for @routesEditRoute.
  ///
  /// In en, this message translates to:
  /// **'Edit Route'**
  String get routesEditRoute;

  /// No description provided for @routesRouteNotFound.
  ///
  /// In en, this message translates to:
  /// **'Route not found'**
  String get routesRouteNotFound;

  /// No description provided for @routesNoElevationData.
  ///
  /// In en, this message translates to:
  /// **'No elevation data available'**
  String get routesNoElevationData;

  /// No description provided for @routesNoWeatherData.
  ///
  /// In en, this message translates to:
  /// **'No weather data available'**
  String get routesNoWeatherData;

  /// No description provided for @routesFailedLoadWeather.
  ///
  /// In en, this message translates to:
  /// **'Failed to load weather'**
  String get routesFailedLoadWeather;

  /// No description provided for @routesNoRecommendations.
  ///
  /// In en, this message translates to:
  /// **'No recommendations available'**
  String get routesNoRecommendations;

  /// No description provided for @routesFailedLoadRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Failed to load recommendations'**
  String get routesFailedLoadRecommendations;

  /// No description provided for @familyMap.
  ///
  /// In en, this message translates to:
  /// **'Family Map'**
  String get familyMap;

  /// No description provided for @familyNoAccount.
  ///
  /// In en, this message translates to:
  /// **'No family account found'**
  String get familyNoAccount;

  /// No description provided for @familySendSOSAlert.
  ///
  /// In en, this message translates to:
  /// **'Send SOS Alert?'**
  String get familySendSOSAlert;

  /// No description provided for @familySendSOS.
  ///
  /// In en, this message translates to:
  /// **'Send SOS'**
  String get familySendSOS;

  /// No description provided for @familySOSSent.
  ///
  /// In en, this message translates to:
  /// **'SOS alert sent to your family!'**
  String get familySOSSent;

  /// No description provided for @familySOSFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send SOS: {error}'**
  String familySOSFailed(String error);

  /// No description provided for @familyCheckout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get familyCheckout;

  /// No description provided for @familyAddPayment.
  ///
  /// In en, this message translates to:
  /// **'Add Payment Method'**
  String get familyAddPayment;

  /// No description provided for @familyPaymentError.
  ///
  /// In en, this message translates to:
  /// **'Could not load payment methods'**
  String get familyPaymentError;

  /// No description provided for @familyGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get familyGetStarted;

  /// No description provided for @familyNoRidesYet.
  ///
  /// In en, this message translates to:
  /// **'No rides yet'**
  String get familyNoRidesYet;

  /// No description provided for @familyNoRecentAlerts.
  ///
  /// In en, this message translates to:
  /// **'No recent alerts'**
  String get familyNoRecentAlerts;

  /// No description provided for @familyAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get familyAchievements;

  /// No description provided for @familyCreateChallenge.
  ///
  /// In en, this message translates to:
  /// **'Create New Challenge'**
  String get familyCreateChallenge;

  /// No description provided for @familyChallengeCreated.
  ///
  /// In en, this message translates to:
  /// **'Challenge created!'**
  String get familyChallengeCreated;

  /// No description provided for @expatSafetyEquipment.
  ///
  /// In en, this message translates to:
  /// **'Safety Equipment'**
  String get expatSafetyEquipment;

  /// No description provided for @expatNoGuideAvailable.
  ///
  /// In en, this message translates to:
  /// **'No {type} guide available'**
  String expatNoGuideAvailable(String type);

  /// No description provided for @expatErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading guide: {error}'**
  String expatErrorLoading(String error);

  /// No description provided for @expatCyclingLaws.
  ///
  /// In en, this message translates to:
  /// **'Cycling Laws'**
  String get expatCyclingLaws;

  /// No description provided for @expatCultureEtiquette.
  ///
  /// In en, this message translates to:
  /// **'Culture & Etiquette'**
  String get expatCultureEtiquette;

  /// No description provided for @expatCommute.
  ///
  /// In en, this message translates to:
  /// **'Commute'**
  String get expatCommute;

  /// No description provided for @expatNoRoutesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No routes available'**
  String get expatNoRoutesAvailable;

  /// No description provided for @expatBikeShops.
  ///
  /// In en, this message translates to:
  /// **'Bike Shops'**
  String get expatBikeShops;

  /// No description provided for @expatAllShops.
  ///
  /// In en, this message translates to:
  /// **'All Shops'**
  String get expatAllShops;

  /// No description provided for @expatExpatFriendly.
  ///
  /// In en, this message translates to:
  /// **'Expat-Friendly Only'**
  String get expatExpatFriendly;

  /// No description provided for @expatRepairServices.
  ///
  /// In en, this message translates to:
  /// **'Repair Services'**
  String get expatRepairServices;

  /// No description provided for @expatSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get expatSales;

  /// No description provided for @expatNoShopsFound.
  ///
  /// In en, this message translates to:
  /// **'No shops found'**
  String get expatNoShopsFound;

  /// No description provided for @expatCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get expatCall;

  /// No description provided for @expatWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get expatWebsite;

  /// No description provided for @commonShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get commonShowAll;

  /// No description provided for @commonClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get commonClearAll;

  /// No description provided for @commonOpenNowOnly.
  ///
  /// In en, this message translates to:
  /// **'Open now only'**
  String get commonOpenNowOnly;

  /// No description provided for @commonStartHere.
  ///
  /// In en, this message translates to:
  /// **'Start Here'**
  String get commonStartHere;

  /// No description provided for @commonGoHere.
  ///
  /// In en, this message translates to:
  /// **'Go Here'**
  String get commonGoHere;

  /// No description provided for @commonHoldSOS.
  ///
  /// In en, this message translates to:
  /// **'Hold the SOS button for 2 seconds'**
  String get commonHoldSOS;

  /// No description provided for @bikeMaintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get bikeMaintenanceTitle;

  /// No description provided for @serviceHistory.
  ///
  /// In en, this message translates to:
  /// **'Service History'**
  String get serviceHistory;

  /// No description provided for @addService.
  ///
  /// In en, this message translates to:
  /// **'Add Service'**
  String get addService;

  /// No description provided for @bikeCondition.
  ///
  /// In en, this message translates to:
  /// **'Bike condition'**
  String get bikeCondition;

  /// No description provided for @kmRidden.
  ///
  /// In en, this message translates to:
  /// **'km ridden'**
  String get kmRidden;

  /// No description provided for @overdueAlert.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueAlert;

  /// No description provided for @dueSoonAlert.
  ///
  /// In en, this message translates to:
  /// **'Due soon'**
  String get dueSoonAlert;

  /// No description provided for @noServiceHistory.
  ///
  /// In en, this message translates to:
  /// **'No service history yet'**
  String get noServiceHistory;

  /// No description provided for @addFirstService.
  ///
  /// In en, this message translates to:
  /// **'Add your first service to track maintenance'**
  String get addFirstService;

  /// No description provided for @serviceType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get serviceType;

  /// No description provided for @serviceDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get serviceDate;

  /// No description provided for @serviceKilometers.
  ///
  /// In en, this message translates to:
  /// **'Kilometers at service'**
  String get serviceKilometers;

  /// No description provided for @servicePriceOptional.
  ///
  /// In en, this message translates to:
  /// **'Price (optional)'**
  String get servicePriceOptional;

  /// No description provided for @serviceShopOptional.
  ///
  /// In en, this message translates to:
  /// **'Shop/Workshop (optional)'**
  String get serviceShopOptional;

  /// No description provided for @serviceNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get serviceNotesOptional;

  /// No description provided for @enterKilometers.
  ///
  /// In en, this message translates to:
  /// **'Enter kilometers'**
  String get enterKilometers;

  /// No description provided for @invalidValue.
  ///
  /// In en, this message translates to:
  /// **'Invalid value'**
  String get invalidValue;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @deleteService.
  ///
  /// In en, this message translates to:
  /// **'Delete service?'**
  String get deleteService;

  /// No description provided for @deleteServiceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this service?'**
  String get deleteServiceConfirm;

  /// No description provided for @kilometers.
  ///
  /// In en, this message translates to:
  /// **'Kilometers'**
  String get kilometers;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @workshop.
  ///
  /// In en, this message translates to:
  /// **'Workshop'**
  String get workshop;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @nextService.
  ///
  /// In en, this message translates to:
  /// **'Next service'**
  String get nextService;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get notLoggedIn;

  /// No description provided for @currencyDkk.
  ///
  /// In en, this message translates to:
  /// **'{amount} DKK'**
  String currencyDkk(String amount);

  /// No description provided for @serviceTypeTireChange.
  ///
  /// In en, this message translates to:
  /// **'Tire Change'**
  String get serviceTypeTireChange;

  /// No description provided for @serviceTypeBrakes.
  ///
  /// In en, this message translates to:
  /// **'Brakes'**
  String get serviceTypeBrakes;

  /// No description provided for @serviceTypeChain.
  ///
  /// In en, this message translates to:
  /// **'Chain'**
  String get serviceTypeChain;

  /// No description provided for @serviceTypeGears.
  ///
  /// In en, this message translates to:
  /// **'Gears'**
  String get serviceTypeGears;

  /// No description provided for @serviceTypeFullService.
  ///
  /// In en, this message translates to:
  /// **'Full Service'**
  String get serviceTypeFullService;

  /// No description provided for @serviceTypeLights.
  ///
  /// In en, this message translates to:
  /// **'Lights'**
  String get serviceTypeLights;

  /// No description provided for @serviceTypeWheels.
  ///
  /// In en, this message translates to:
  /// **'Wheels'**
  String get serviceTypeWheels;

  /// No description provided for @serviceTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get serviceTypeOther;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @theftAlerts.
  ///
  /// In en, this message translates to:
  /// **'Theft Alerts'**
  String get theftAlerts;

  /// No description provided for @theftNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get theftNearby;

  /// No description provided for @theftAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get theftAll;

  /// No description provided for @theftMine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get theftMine;

  /// No description provided for @theftReport.
  ///
  /// In en, this message translates to:
  /// **'Report theft'**
  String get theftReport;

  /// No description provided for @theftError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String theftError(String error);

  /// No description provided for @theftNoNearby.
  ///
  /// In en, this message translates to:
  /// **'No thefts nearby'**
  String get theftNoNearby;

  /// No description provided for @theftNoNearbyDesc.
  ///
  /// In en, this message translates to:
  /// **'There are no active theft reports within {radius} km'**
  String theftNoNearbyDesc(String radius);

  /// No description provided for @theftNoActive.
  ///
  /// In en, this message translates to:
  /// **'No active reports'**
  String get theftNoActive;

  /// No description provided for @theftNoActiveDesc.
  ///
  /// In en, this message translates to:
  /// **'There are no active theft reports right now'**
  String get theftNoActiveDesc;

  /// No description provided for @theftNoReports.
  ///
  /// In en, this message translates to:
  /// **'No reports'**
  String get theftNoReports;

  /// No description provided for @theftNoReportsDesc.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t reported any bike thefts'**
  String get theftNoReportsDesc;

  /// No description provided for @theftMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String theftMinutesAgo(int minutes);

  /// No description provided for @theftHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String theftHoursAgo(int hours);

  /// No description provided for @theftDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String theftDaysAgo(int days);

  /// No description provided for @theftReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report bike theft'**
  String get theftReportTitle;

  /// No description provided for @theftNoBikes.
  ///
  /// In en, this message translates to:
  /// **'You have no registered bikes. Add your bike first under \"My Bikes\".'**
  String get theftNoBikes;

  /// No description provided for @theftSelectBike.
  ///
  /// In en, this message translates to:
  /// **'Select bike'**
  String get theftSelectBike;

  /// No description provided for @theftSelectBikeError.
  ///
  /// In en, this message translates to:
  /// **'Select a bike'**
  String get theftSelectBikeError;

  /// No description provided for @theftCouldNotLoadBikes.
  ///
  /// In en, this message translates to:
  /// **'Could not load bikes'**
  String get theftCouldNotLoadBikes;

  /// No description provided for @theftBikeDescription.
  ///
  /// In en, this message translates to:
  /// **'Bike description'**
  String get theftBikeDescription;

  /// No description provided for @theftBikeDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Color, size, special features...'**
  String get theftBikeDescriptionHint;

  /// No description provided for @theftDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter description'**
  String get theftDescriptionRequired;

  /// No description provided for @theftFrameNumber.
  ///
  /// In en, this message translates to:
  /// **'Frame number (optional)'**
  String get theftFrameNumber;

  /// No description provided for @theftArea.
  ///
  /// In en, this message translates to:
  /// **'Area (e.g. Nørrebro)'**
  String get theftArea;

  /// No description provided for @theftAdditionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Additional information (optional)'**
  String get theftAdditionalNotes;

  /// No description provided for @theftAdditionalNotesHint.
  ///
  /// In en, this message translates to:
  /// **'When/where did you last see it...'**
  String get theftAdditionalNotesHint;

  /// No description provided for @theftContactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact info (optional)'**
  String get theftContactInfo;

  /// No description provided for @theftContactInfoHint.
  ///
  /// In en, this message translates to:
  /// **'Phone or email'**
  String get theftContactInfoHint;

  /// No description provided for @theftNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get theftNotLoggedIn;

  /// No description provided for @theftReportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Theft reported! Other cyclists will be alerted.'**
  String get theftReportSuccess;

  /// No description provided for @theftAreaLabel.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get theftAreaLabel;

  /// No description provided for @theftFrameNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Frame number'**
  String get theftFrameNumberLabel;

  /// No description provided for @theftNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get theftNotesLabel;

  /// No description provided for @theftContactLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get theftContactLabel;

  /// No description provided for @theftMarkRecovered.
  ///
  /// In en, this message translates to:
  /// **'Mark as recovered'**
  String get theftMarkRecovered;

  /// No description provided for @theftCloseReport.
  ///
  /// In en, this message translates to:
  /// **'Close report'**
  String get theftCloseReport;

  /// No description provided for @theftSeenThisBike.
  ///
  /// In en, this message translates to:
  /// **'I\'ve seen this bike!'**
  String get theftSeenThisBike;

  /// No description provided for @theftRecoveredSuccess.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! Your bike is marked as recovered.'**
  String get theftRecoveredSuccess;

  /// No description provided for @theftSightingThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks! The owner will be notified.'**
  String get theftSightingThanks;

  /// No description provided for @theftAlarmSettings.
  ///
  /// In en, this message translates to:
  /// **'Alarm settings'**
  String get theftAlarmSettings;

  /// No description provided for @theftEnableAlarms.
  ///
  /// In en, this message translates to:
  /// **'Enable alarms'**
  String get theftEnableAlarms;

  /// No description provided for @theftRadius.
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get theftRadius;

  /// No description provided for @theftRadiusKm.
  ///
  /// In en, this message translates to:
  /// **'{radius} km'**
  String theftRadiusKm(String radius);

  /// No description provided for @theftNewThefts.
  ///
  /// In en, this message translates to:
  /// **'New thefts'**
  String get theftNewThefts;

  /// No description provided for @theftNewTheftsDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified when a bike is reported stolen'**
  String get theftNewTheftsDesc;

  /// No description provided for @theftSightings.
  ///
  /// In en, this message translates to:
  /// **'Sightings'**
  String get theftSightings;

  /// No description provided for @theftSightingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified when someone has seen a stolen bike'**
  String get theftSightingsDesc;

  /// No description provided for @theftRecoveries.
  ///
  /// In en, this message translates to:
  /// **'Recovered bikes'**
  String get theftRecoveries;

  /// No description provided for @theftRecoveriesDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified when a bike is recovered'**
  String get theftRecoveriesDesc;

  /// No description provided for @theftStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get theftStatusActive;

  /// No description provided for @theftStatusRecovered.
  ///
  /// In en, this message translates to:
  /// **'Recovered'**
  String get theftStatusRecovered;

  /// No description provided for @theftStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get theftStatusClosed;

  /// No description provided for @aiRouteSuggestions.
  ///
  /// In en, this message translates to:
  /// **'AI Route Suggestions'**
  String get aiRouteSuggestions;

  /// No description provided for @offlineMaps.
  ///
  /// In en, this message translates to:
  /// **'Offline Maps'**
  String get offlineMaps;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get chooseTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System theme'**
  String get systemTheme;

  /// No description provided for @autoTheme.
  ///
  /// In en, this message translates to:
  /// **'Auto (sunrise/sunset)'**
  String get autoTheme;

  /// No description provided for @followsDeviceSettings.
  ///
  /// In en, this message translates to:
  /// **'Follows device settings'**
  String get followsDeviceSettings;

  /// No description provided for @automatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get automatic;

  /// No description provided for @changesAtSunriseSunset.
  ///
  /// In en, this message translates to:
  /// **'Changes at sunrise/sunset'**
  String get changesAtSunriseSunset;

  /// No description provided for @dataExportTitle.
  ///
  /// In en, this message translates to:
  /// **'CYKEL Data Export'**
  String get dataExportTitle;

  /// No description provided for @dataExportSubject.
  ///
  /// In en, this message translates to:
  /// **'Your complete CYKEL data export'**
  String get dataExportSubject;

  /// No description provided for @speedUnit.
  ///
  /// In en, this message translates to:
  /// **'km/h'**
  String get speedUnit;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}min'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @socialActivityTab.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get socialActivityTab;

  /// No description provided for @socialFriendsTab.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get socialFriendsTab;

  /// No description provided for @socialMyRidesTab.
  ///
  /// In en, this message translates to:
  /// **'My Rides'**
  String get socialMyRidesTab;

  /// No description provided for @socialErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String socialErrorLoading(String error);

  /// No description provided for @socialNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get socialNoActivity;

  /// No description provided for @socialAddFriends.
  ///
  /// In en, this message translates to:
  /// **'Add friends to see their rides'**
  String get socialAddFriends;

  /// No description provided for @socialNoFriends.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get socialNoFriends;

  /// No description provided for @socialSearchCyclists.
  ///
  /// In en, this message translates to:
  /// **'Search for other cyclists and add them as friends'**
  String get socialSearchCyclists;

  /// No description provided for @socialNoSharedRides.
  ///
  /// In en, this message translates to:
  /// **'No shared rides'**
  String get socialNoSharedRides;

  /// No description provided for @socialShareRides.
  ///
  /// In en, this message translates to:
  /// **'Share your bike rides with friends'**
  String get socialShareRides;

  /// No description provided for @socialTotalKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km total'**
  String socialTotalKm(String km);

  /// No description provided for @socialRemoveFriend.
  ///
  /// In en, this message translates to:
  /// **'Remove friend'**
  String get socialRemoveFriend;

  /// No description provided for @socialRemoveFriendQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove friend?'**
  String get socialRemoveFriendQuestion;

  /// No description provided for @socialConfirmRemoveFriend.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {name} as a friend?'**
  String socialConfirmRemoveFriend(String name);

  /// No description provided for @socialRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get socialRemove;

  /// No description provided for @socialFriendRemoved.
  ///
  /// In en, this message translates to:
  /// **'Friend removed'**
  String get socialFriendRemoved;

  /// No description provided for @socialMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String socialMinutesAgo(int minutes);

  /// No description provided for @socialHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String socialHoursAgo(int hours);

  /// No description provided for @socialDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String socialDaysAgo(int days);

  /// No description provided for @socialDeleteRideQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete shared ride?'**
  String get socialDeleteRideQuestion;

  /// No description provided for @socialConfirmDeleteRide.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this shared ride?'**
  String get socialConfirmDeleteRide;

  /// No description provided for @socialReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get socialReceived;

  /// No description provided for @socialNoRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests'**
  String get socialNoRequests;

  /// No description provided for @socialSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get socialSent;

  /// No description provided for @socialNoSentRequests.
  ///
  /// In en, this message translates to:
  /// **'No sent requests'**
  String get socialNoSentRequests;

  /// No description provided for @socialFriendAdded.
  ///
  /// In en, this message translates to:
  /// **'Friend added!'**
  String get socialFriendAdded;

  /// No description provided for @socialFindCyclists.
  ///
  /// In en, this message translates to:
  /// **'Find Cyclists'**
  String get socialFindCyclists;

  /// No description provided for @socialSearchByName.
  ///
  /// In en, this message translates to:
  /// **'Search by name...'**
  String get socialSearchByName;

  /// No description provided for @socialAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get socialAdd;

  /// No description provided for @socialFriendRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent!'**
  String get socialFriendRequestSent;

  /// No description provided for @socialNoComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get socialNoComments;

  /// No description provided for @socialWriteComment.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get socialWriteComment;

  /// No description provided for @socialMinutesAgoShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String socialMinutesAgoShort(int minutes);

  /// No description provided for @socialHoursAgoShort.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String socialHoursAgoShort(int hours);

  /// No description provided for @socialDaysAgoShort.
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String socialDaysAgoShort(int days);

  /// No description provided for @routeSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Route Suggestions'**
  String get routeSuggestions;

  /// No description provided for @routeSuggestionsTab.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get routeSuggestionsTab;

  /// No description provided for @routeHistoryTab.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get routeHistoryTab;

  /// No description provided for @routeSavedTab.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get routeSavedTab;

  /// No description provided for @routeNoSuggestions.
  ///
  /// In en, this message translates to:
  /// **'No suggestions yet'**
  String get routeNoSuggestions;

  /// No description provided for @routeNoSuggestionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Use the app to cycle some trips, and we\'ll learn your preferences'**
  String get routeNoSuggestionsDesc;

  /// No description provided for @routeAiTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Route Suggestions'**
  String get routeAiTitle;

  /// No description provided for @routeAiDesc.
  ///
  /// In en, this message translates to:
  /// **'Based on your habits, weather and time'**
  String get routeAiDesc;

  /// No description provided for @routeNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No route history'**
  String get routeNoHistory;

  /// No description provided for @routeNoHistoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Your most used routes will appear here'**
  String get routeNoHistoryDesc;

  /// No description provided for @routeStatsPattern.
  ///
  /// In en, this message translates to:
  /// **'~{duration} min • Last: {lastUsed}'**
  String routeStatsPattern(int duration, String lastUsed);

  /// No description provided for @routeDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get routeDefaultName;

  /// No description provided for @routeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String routeMinutesAgo(int minutes);

  /// No description provided for @routeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours'**
  String routeHoursAgo(int hours);

  /// No description provided for @routeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String routeDaysAgo(int days);

  /// No description provided for @routeNoSaved.
  ///
  /// In en, this message translates to:
  /// **'No saved routes'**
  String get routeNoSaved;

  /// No description provided for @routeNoSavedDesc.
  ///
  /// In en, this message translates to:
  /// **'Save your favorite routes for quick access'**
  String get routeNoSavedDesc;

  /// No description provided for @routeSettings.
  ///
  /// In en, this message translates to:
  /// **'Route Settings'**
  String get routeSettings;

  /// No description provided for @routePreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get routePreferences;

  /// No description provided for @routeAvoidHills.
  ///
  /// In en, this message translates to:
  /// **'Avoid hills'**
  String get routeAvoidHills;

  /// No description provided for @routeAvoidHillsDesc.
  ///
  /// In en, this message translates to:
  /// **'Suggest flatter routes'**
  String get routeAvoidHillsDesc;

  /// No description provided for @routePreferBikeLanes.
  ///
  /// In en, this message translates to:
  /// **'Prefer bike lanes'**
  String get routePreferBikeLanes;

  /// No description provided for @routePreferBikeLanesDesc.
  ///
  /// In en, this message translates to:
  /// **'Prioritize routes with bike lanes'**
  String get routePreferBikeLanesDesc;

  /// No description provided for @routePreferLitRoutes.
  ///
  /// In en, this message translates to:
  /// **'Prefer lit routes'**
  String get routePreferLitRoutes;

  /// No description provided for @routePreferLitRoutesDesc.
  ///
  /// In en, this message translates to:
  /// **'Prioritize well-lit routes at night'**
  String get routePreferLitRoutesDesc;

  /// No description provided for @routeAiSuggestions.
  ///
  /// In en, this message translates to:
  /// **'AI Suggestions'**
  String get routeAiSuggestions;

  /// No description provided for @routeBasedOnHistory.
  ///
  /// In en, this message translates to:
  /// **'Based on history'**
  String get routeBasedOnHistory;

  /// No description provided for @routeBasedOnHistoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Use your previous trips'**
  String get routeBasedOnHistoryDesc;

  /// No description provided for @routeBasedOnWeather.
  ///
  /// In en, this message translates to:
  /// **'Based on weather'**
  String get routeBasedOnWeather;

  /// No description provided for @routeBasedOnWeatherDesc.
  ///
  /// In en, this message translates to:
  /// **'Adapt suggestions to weather'**
  String get routeBasedOnWeatherDesc;

  /// No description provided for @routeBasedOnTime.
  ///
  /// In en, this message translates to:
  /// **'Based on time'**
  String get routeBasedOnTime;

  /// No description provided for @routeBasedOnTimeDesc.
  ///
  /// In en, this message translates to:
  /// **'Adapt suggestions to time of day'**
  String get routeBasedOnTimeDesc;

  /// No description provided for @exportSubject.
  ///
  /// In en, this message translates to:
  /// **'CYKEL Data Export'**
  String get exportSubject;

  /// No description provided for @exportMessage.
  ///
  /// In en, this message translates to:
  /// **'Your complete CYKEL data export'**
  String get exportMessage;

  /// No description provided for @notLoggedInError.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get notLoggedInError;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @authenticateBiometric.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to enable biometric lock'**
  String get authenticateBiometric;

  /// No description provided for @biometricAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Biometric lock not enabled.'**
  String get biometricAuthFailed;

  /// No description provided for @biometricEnabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric lock enabled'**
  String get biometricEnabled;

  /// No description provided for @biometricDisabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric lock disabled'**
  String get biometricDisabled;

  /// No description provided for @lockWith.
  ///
  /// In en, this message translates to:
  /// **'Lock with {type}'**
  String lockWith(String type);

  /// No description provided for @biometricLockDesc.
  ///
  /// In en, this message translates to:
  /// **'Require authentication when opening app'**
  String get biometricLockDesc;

  /// No description provided for @offlineMapsTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline Maps'**
  String get offlineMapsTitle;

  /// No description provided for @downloadedRegions.
  ///
  /// In en, this message translates to:
  /// **'Downloaded Regions'**
  String get downloadedRegions;

  /// No description provided for @availableRegions.
  ///
  /// In en, this message translates to:
  /// **'Available Regions'**
  String get availableRegions;

  /// No description provided for @downloadMapsForOfflineNav.
  ///
  /// In en, this message translates to:
  /// **'Download maps to use navigation offline'**
  String get downloadMapsForOfflineNav;

  /// No description provided for @downloadCustomRegion.
  ///
  /// In en, this message translates to:
  /// **'Download Custom Region'**
  String get downloadCustomRegion;

  /// No description provided for @deleteOfflineMaps.
  ///
  /// In en, this message translates to:
  /// **'Delete Offline Maps?'**
  String get deleteOfflineMaps;

  /// No description provided for @confirmDeleteRegion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{regionName}\"?'**
  String confirmDeleteRegion(String regionName);

  /// No description provided for @startingDownload.
  ///
  /// In en, this message translates to:
  /// **'Starting download of {regionName}'**
  String startingDownload(String regionName);

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @noDownloadedMaps.
  ///
  /// In en, this message translates to:
  /// **'No Downloaded Maps'**
  String get noDownloadedMaps;

  /// No description provided for @downloadMapsToUseOffline.
  ///
  /// In en, this message translates to:
  /// **'Download maps to use the app without internet'**
  String get downloadMapsToUseOffline;

  /// No description provided for @downloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloaded;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get downloading;

  /// No description provided for @percentDownloaded.
  ///
  /// In en, this message translates to:
  /// **'{percent}% downloaded'**
  String percentDownloaded(int percent);

  /// No description provided for @downloadError.
  ///
  /// In en, this message translates to:
  /// **'Error during download'**
  String get downloadError;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending...'**
  String get pending;

  /// No description provided for @selectRegion.
  ///
  /// In en, this message translates to:
  /// **'Select Region'**
  String get selectRegion;

  /// No description provided for @selectRegionOnMap.
  ///
  /// In en, this message translates to:
  /// **'Select a region on the map to download'**
  String get selectRegionOnMap;

  /// No description provided for @regionName.
  ///
  /// In en, this message translates to:
  /// **'Region Name'**
  String get regionName;

  /// No description provided for @downloadRegion.
  ///
  /// In en, this message translates to:
  /// **'Download Region'**
  String get downloadRegion;

  /// No description provided for @enterRegionName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for the region'**
  String get enterRegionName;

  /// No description provided for @offlineSettings.
  ///
  /// In en, this message translates to:
  /// **'Offline Settings'**
  String get offlineSettings;

  /// No description provided for @autoDownloadOnWifi.
  ///
  /// In en, this message translates to:
  /// **'Auto-download on WiFi'**
  String get autoDownloadOnWifi;

  /// No description provided for @autoDownloadOnWifiDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically download maps when on WiFi'**
  String get autoDownloadOnWifiDesc;

  /// No description provided for @downloadRouteBuffer.
  ///
  /// In en, this message translates to:
  /// **'Download Route Buffer'**
  String get downloadRouteBuffer;

  /// No description provided for @downloadRouteBufferDesc.
  ///
  /// In en, this message translates to:
  /// **'Download maps around your routes'**
  String get downloadRouteBufferDesc;

  /// No description provided for @maxStorage.
  ///
  /// In en, this message translates to:
  /// **'Max Storage'**
  String get maxStorage;

  /// No description provided for @deleteAllOfflineMaps.
  ///
  /// In en, this message translates to:
  /// **'Delete All Offline Maps'**
  String get deleteAllOfflineMaps;

  /// No description provided for @deleteAllOfflineMapsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete All Offline Maps?'**
  String get deleteAllOfflineMapsConfirm;

  /// No description provided for @deleteAllOfflineMapsDesc.
  ///
  /// In en, this message translates to:
  /// **'This will delete all downloaded maps. You can download them again later.'**
  String get deleteAllOfflineMapsDesc;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteAll;

  /// No description provided for @allOfflineMapsDeleted.
  ///
  /// In en, this message translates to:
  /// **'All offline maps deleted'**
  String get allOfflineMapsDeleted;

  /// No description provided for @eventInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions (optional)'**
  String get eventInstructions;

  /// No description provided for @eventInstructionsHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. Meet at the bike parking'**
  String get eventInstructionsHint;

  /// No description provided for @searchAddressFirst.
  ///
  /// In en, this message translates to:
  /// **'Search for an address first'**
  String get searchAddressFirst;

  /// No description provided for @groupRideCreated.
  ///
  /// In en, this message translates to:
  /// **'Group ride created!'**
  String get groupRideCreated;

  /// No description provided for @updateEvent.
  ///
  /// In en, this message translates to:
  /// **'Update Event'**
  String get updateEvent;

  /// No description provided for @eventUpdated.
  ///
  /// In en, this message translates to:
  /// **'Event updated successfully'**
  String get eventUpdated;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @upcomingGroupRides.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Group Rides'**
  String get upcomingGroupRides;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @findGroupRides.
  ///
  /// In en, this message translates to:
  /// **'Find Group Rides'**
  String get findGroupRides;

  /// No description provided for @discoverLocalRides.
  ///
  /// In en, this message translates to:
  /// **'Discover and join local cycling events'**
  String get discoverLocalRides;

  /// No description provided for @noBiometricsAvailable.
  ///
  /// In en, this message translates to:
  /// **'This device does not have biometric authentication (fingerprint or face recognition)'**
  String get noBiometricsAvailable;

  /// No description provided for @noBiometricsTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometrics Not Available'**
  String get noBiometricsTitle;

  /// No description provided for @groupChat.
  ///
  /// In en, this message translates to:
  /// **'Group Chat'**
  String get groupChat;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @beFirstToMessage.
  ///
  /// In en, this message translates to:
  /// **'Be the first to send a message!'**
  String get beFirstToMessage;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @signInToChat.
  ///
  /// In en, this message translates to:
  /// **'Sign in to send messages'**
  String get signInToChat;

  /// No description provided for @viewOnMap.
  ///
  /// In en, this message translates to:
  /// **'View on Map'**
  String get viewOnMap;

  /// No description provided for @myRentals.
  ///
  /// In en, this message translates to:
  /// **'My Rentals'**
  String get myRentals;

  /// No description provided for @renting.
  ///
  /// In en, this message translates to:
  /// **'Renting'**
  String get renting;

  /// No description provided for @listings.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get listings;

  /// No description provided for @noListingsYet.
  ///
  /// In en, this message translates to:
  /// **'No listings yet'**
  String get noListingsYet;

  /// No description provided for @listBikeToEarn.
  ///
  /// In en, this message translates to:
  /// **'List your bike to start earning!'**
  String get listBikeToEarn;

  /// No description provided for @createListing.
  ///
  /// In en, this message translates to:
  /// **'Create Listing'**
  String get createListing;

  /// No description provided for @listingNotFound.
  ///
  /// In en, this message translates to:
  /// **'Listing not found'**
  String get listingNotFound;

  /// No description provided for @errorLoadingListing.
  ///
  /// In en, this message translates to:
  /// **'Error loading listing'**
  String get errorLoadingListing;

  /// No description provided for @declineRequest.
  ///
  /// In en, this message translates to:
  /// **'Decline Request'**
  String get declineRequest;

  /// No description provided for @declineRequestConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to decline this request?'**
  String get declineRequestConfirm;

  /// No description provided for @approveRequest.
  ///
  /// In en, this message translates to:
  /// **'Approve Request'**
  String get approveRequest;

  /// No description provided for @requestApproved.
  ///
  /// In en, this message translates to:
  /// **'Request approved! Renter has been notified.'**
  String get requestApproved;

  /// No description provided for @requestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Request declined'**
  String get requestDeclined;

  /// No description provided for @deleteListing.
  ///
  /// In en, this message translates to:
  /// **'Delete Listing'**
  String get deleteListing;

  /// No description provided for @deleteListingQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this listing?'**
  String get deleteListingQuestion;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorOccurred(String error);

  /// No description provided for @safeZones.
  ///
  /// In en, this message translates to:
  /// **'Safe Zones'**
  String get safeZones;

  /// No description provided for @noFamilyAccount.
  ///
  /// In en, this message translates to:
  /// **'No family account found'**
  String get noFamilyAccount;

  /// No description provided for @addZone.
  ///
  /// In en, this message translates to:
  /// **'Add Zone'**
  String get addZone;

  /// No description provided for @deleteSafeZone.
  ///
  /// In en, this message translates to:
  /// **'Delete Safe Zone?'**
  String get deleteSafeZone;

  /// No description provided for @deleteSafeZoneConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove this safe zone.'**
  String get deleteSafeZoneConfirm;

  /// No description provided for @zoneDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{zoneName}\"'**
  String zoneDeleted(String zoneName);

  /// No description provided for @aboutSafeZones.
  ///
  /// In en, this message translates to:
  /// **'About Safe Zones'**
  String get aboutSafeZones;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @addFirstZone.
  ///
  /// In en, this message translates to:
  /// **'Add Your First Zone'**
  String get addFirstZone;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @createNewListing.
  ///
  /// In en, this message translates to:
  /// **'Create New Listing'**
  String get createNewListing;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['da', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'da':
      return AppLocalizationsDa();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
