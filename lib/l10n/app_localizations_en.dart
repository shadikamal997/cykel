// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'Your Bicycle OS';

  @override
  String get appSubtitle => 'Denmark\'s Bicycle OS';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get or => 'or';

  @override
  String get signInWithEmail => 'Sign in with email';

  @override
  String get createAccount => 'Create account';

  @override
  String get termsNotice =>
      'By continuing you accept our\nTerms and Privacy Policy.';

  @override
  String get signIn => 'Sign in';

  @override
  String get welcomeBack => 'Welcome back to CYKEL';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get required => 'Required';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get getStarted => 'Get started with CYKEL';

  @override
  String get fullName => 'Full name';

  @override
  String get atLeastTwoChars => 'At least 2 characters';

  @override
  String get atLeastEightChars => 'At least 8 characters';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordsMismatch => 'Passwords do not match';

  @override
  String get mustAcceptTerms => 'You must accept the terms to continue.';

  @override
  String get iAgreeTo => 'I agree to the ';

  @override
  String get terms => 'Terms';

  @override
  String get and => ' and ';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get forgotPasswordTitle => 'Forgot password?';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your email and we\'ll send you a link to reset your password.';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get emailSentTitle => 'Email sent!';

  @override
  String resetLinkSentTo(String email) {
    return 'We\'ve sent a reset link to\n$email';
  }

  @override
  String get checkInbox => 'Check your inbox and spam folder.';

  @override
  String get verifyEmailTitle => 'Verify your email';

  @override
  String verifyEmailSentTo(String email) {
    return 'We sent a verification email to\n$email';
  }

  @override
  String get verifyEmailAction =>
      'Click the link in the email to activate your account.';

  @override
  String get waitingForVerification => 'Waiting for verification…';

  @override
  String get verificationEmailResent => 'Verification email resent.';

  @override
  String get emailSentCheck => 'Email sent ✓';

  @override
  String get resendEmail => 'Resend email';

  @override
  String get signOut => 'Sign out';

  @override
  String greeting(String name) {
    return 'Hey, $name 👋';
  }

  @override
  String get rideToday => 'Ready to ride today?';

  @override
  String get dashboardComingSoon => 'Dashboard coming in Phase 2';

  @override
  String get yourAccount => 'Your account';

  @override
  String get role => 'Role';

  @override
  String get emailVerifiedLabel => 'Email verified';

  @override
  String get yes => 'Yes ✓';

  @override
  String get no => 'No';

  @override
  String get defaultRiderName => 'Cyclist';

  @override
  String get tabMap => 'Map';

  @override
  String get tabActivity => 'Activity';

  @override
  String get tabDiscover => 'Discover';

  @override
  String get tabMarketplace => 'Marketplace';

  @override
  String get tabProfile => 'Profile';

  @override
  String get tabProvider => 'Provider';

  @override
  String get tabProviderOnboarding => 'Provider Onboarding';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get home => 'Home';

  @override
  String get sectionRidingConditions => 'Riding Conditions';

  @override
  String get sectionTodayActivity => 'Today\'s Activity';

  @override
  String get sectionQuickRoutes => 'Quick Routes';

  @override
  String get sectionAlerts => 'Alerts';

  @override
  String get sectionNearby => 'Nearby';

  @override
  String get cykelFeatures => 'CYKEL Features';

  @override
  String conditionScore(String score) {
    return '$score/10';
  }

  @override
  String get conditionGood => 'Good conditions';

  @override
  String get conditionFair => 'Fair conditions';

  @override
  String get conditionExcellent => 'Excellent conditions';

  @override
  String get conditionPoor => 'Poor conditions';

  @override
  String get wind => 'Wind';

  @override
  String get rain => 'Rain';

  @override
  String get temperature => 'Temp';

  @override
  String kmToday(String km) {
    return '$km km';
  }

  @override
  String minToday(String min) {
    return '$min min';
  }

  @override
  String dayStreak(int days) {
    return '$days day streak';
  }

  @override
  String get distanceLabel => 'Distance';

  @override
  String get durationLabel => 'Duration';

  @override
  String get streakLabel => 'Streak';

  @override
  String get noAlertsTitle => 'All clear';

  @override
  String get noAlertsSubtitle => 'No alerts in your area';

  @override
  String get noNearbyTitle => 'Nothing nearby yet';

  @override
  String get noNearbySubtitle =>
      'Services will appear here once you set your location';

  @override
  String get addHomeRoute => 'Set home';

  @override
  String get addWorkRoute => 'Set work';

  @override
  String get routeHome => 'Home';

  @override
  String get routeWork => 'Work';

  @override
  String get quickRoutesEmpty =>
      'Save your home and work locations for quick navigation';

  @override
  String get profile => 'Profile';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get savedPlaces => 'Saved places';

  @override
  String get myBikes => 'My Bikes';

  @override
  String get notificationSettings => 'Notifications';

  @override
  String get languageSettings => 'Language';

  @override
  String get account => 'Account';

  @override
  String get subscriptionSection => 'Subscription';

  @override
  String get freePlan => 'Free';

  @override
  String get proPlan => 'Pro';

  @override
  String get privacySettings => 'Privacy';

  @override
  String get helpAndSupport => 'Help & Support';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirm =>
      'Are you sure you want to delete your account? This cannot be undone.';

  @override
  String get noBikesTitle => 'No bikes yet';

  @override
  String get noBikesSubtitle =>
      'Add your bike to track rides and get personalised insights';

  @override
  String get addBike => 'Add bike';

  @override
  String get member => 'Member';

  @override
  String get comingSoonTitle => 'Coming soon';

  @override
  String get comingSoonSubtitle =>
      'We\'re building this feature.\nIt\'ll be worth the wait.';

  @override
  String get searchAddress => 'Search address';

  @override
  String get searchPlaces => 'Search places...';

  @override
  String get mapLayers => 'Map Layers';

  @override
  String get layerCharging => 'Charging Stations';

  @override
  String get layerService => 'Service Points';

  @override
  String get layerShops => 'Bike Shops';

  @override
  String get layerRental => 'Rentals';

  @override
  String get layerRepair => 'Repair Shops';

  @override
  String get allDay => 'Open 24/7';

  @override
  String nearbyCount(int count) {
    return '$count places nearby';
  }

  @override
  String get noPlacesFound => 'No places found';

  @override
  String get tryChangingFilters => 'Try changing filters or search again';

  @override
  String get all => 'All';

  @override
  String get getDirections => 'Get directions';

  @override
  String get startNavigation => 'Start navigation';

  @override
  String get stopNavigation => 'Stop';

  @override
  String get calculating => 'Calculating...';

  @override
  String get calculateRoute => 'Calculate route';

  @override
  String get yourLocation => 'Your location';

  @override
  String get couldNotCalculateRoute => 'Could not calculate route.';

  @override
  String get locationDisabled => 'Location services are disabled.';

  @override
  String get locationDenied => 'Location permission denied.';

  @override
  String get routeDistance => 'Distance';

  @override
  String get routeDuration => 'Duration';

  @override
  String get arrived => 'You have arrived!';

  @override
  String get done => 'Done';

  @override
  String get chargingStation => 'Charging Station';

  @override
  String get servicePoint => 'Service Point';

  @override
  String get bikeShop => 'Bike Shop';

  @override
  String get rental => 'Rental';

  @override
  String get visitWebsite => 'Visit website';

  @override
  String get layerTraffic => 'Traffic';

  @override
  String get layerBikeRoutes => 'Bike Routes';

  @override
  String get layerTransit => 'Public Transit';

  @override
  String get nightMode => 'Night Mode';

  @override
  String get startRide => 'Start Ride';

  @override
  String get stopRide => 'Stop Ride';

  @override
  String get pauseRide => 'Pause Ride';

  @override
  String get resumeRide => 'Resume Ride';

  @override
  String get calories => 'Calories';

  @override
  String get elevation => 'Elevation';

  @override
  String get myRides => 'My Rides';

  @override
  String get rideHistory => 'Ride History';

  @override
  String get noRidesYet => 'No rides yet';

  @override
  String get noRidesSubtitle => 'Tap Start Ride to record your first journey';

  @override
  String get noRidesToday => 'No rides today yet';

  @override
  String get noRidesTodaySubtitle => 'Start your first ride';

  @override
  String get noQuickRoutesYet => 'No quick routes yet';

  @override
  String get noQuickRoutesSubtitle => 'Set your home and work locations';

  @override
  String get startTrackingRides => 'Start tracking your rides';

  @override
  String get startTrackingRidesSubtitle =>
      'Your cycling stats will appear here';

  @override
  String get avgSpeed => 'Avg Speed';

  @override
  String get maxSpeed => 'Max Speed';

  @override
  String get speed => 'Speed';

  @override
  String get rideTime => 'Time';

  @override
  String get offRouteRecalc => 'Off route — recalculating…';

  @override
  String get longPressHint => 'Long press on map to set destination';

  @override
  String stepsRemaining(int count) {
    return '$count steps';
  }

  @override
  String get errInvalidCredential => 'Incorrect email or password.';

  @override
  String get errEmailInUse => 'This email is already registered.';

  @override
  String get errWeakPassword => 'Password is too weak (min. 8 characters).';

  @override
  String get errInvalidEmail => 'Invalid email address.';

  @override
  String get errNoInternet => 'No internet connection.';

  @override
  String get errTooManyRequests => 'Too many attempts. Please try again later.';

  @override
  String get errUserDisabled => 'This account has been disabled.';

  @override
  String get errRequiresRecentLogin => 'Please sign in again to continue.';

  @override
  String get errCancelled => 'Sign-in was cancelled.';

  @override
  String get errGeneric => 'Something went wrong. Please try again.';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get droppedPin => 'Dropped pin';

  @override
  String get clearRoute => 'Clear';

  @override
  String get setHomeAddress => 'Set Home Address';

  @override
  String get setWorkAddress => 'Set Work Address';

  @override
  String get tapToRoute => 'Tap to navigate';

  @override
  String get addressSearch => 'Search for an address…';

  @override
  String get save => 'Save';

  @override
  String arriveAt(String time) {
    return 'Arrive $time';
  }

  @override
  String get noRouteFound => 'No cycling route found between these locations.';

  @override
  String get locationPermissionRequired =>
      'Location permission is required to show your position.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get gpsSignalLost => 'GPS signal lost';

  @override
  String get routeOverview => 'Overview';

  @override
  String get recentSearches => 'Recent';

  @override
  String get myLocation => 'My Location';

  @override
  String get setOnMap => 'Set on map';

  @override
  String get searchingHint => 'Searching…';

  @override
  String inDistance(String dist, String instruction) {
    return 'In $dist, $instruction';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get confirmPin => 'Confirm location';

  @override
  String get placeDetails => 'Place Details';

  @override
  String get setAsDestination => 'Set as destination';

  @override
  String get setAsOrigin => 'Set as starting point';

  @override
  String get mapStyle => 'Map Style';

  @override
  String get satellite => 'Satellite';

  @override
  String get normalMap => 'Map';

  @override
  String get terrain => 'Terrain';

  @override
  String routeOption(int index) {
    return 'Route $index';
  }

  @override
  String get bikeProfile => 'Bike profile';

  @override
  String get bikeProfileCity => 'City';

  @override
  String get bikeProfileEbike => 'E-Bike';

  @override
  String get bikeProfileRoad => 'Road';

  @override
  String get bikeProfileCargo => 'Cargo';

  @override
  String get bikeProfileFamily => 'Family';

  @override
  String get bikeTypeCity => 'City';

  @override
  String get bikeTypeRoad => 'Road';

  @override
  String get bikeTypeEbike => 'E-bike';

  @override
  String get bikeTypeCargo => 'Cargo';

  @override
  String get bikeTypeMountain => 'Mountain';

  @override
  String windHeadwind(String speed) {
    return 'Headwind · $speed km/h — expect longer ETA';
  }

  @override
  String windTailwind(String speed) {
    return 'Tailwind · $speed km/h — great conditions!';
  }

  @override
  String windCrosswind(String speed) {
    return 'Crosswind · $speed km/h';
  }

  @override
  String get saveRoute => 'Save';

  @override
  String get routeSaved => 'Route saved';

  @override
  String get routeUnsaved => 'Route removed';

  @override
  String get savedRoutes => 'Saved routes';

  @override
  String get rerouteComplete => 'Route updated';

  @override
  String get rerouteFailed => 'Cannot recalculate route';

  @override
  String get offlineNavBanner =>
      'Offline — navigation continues. Rerouting paused.';

  @override
  String resumeNavigationPrompt(String dest) {
    return 'Resume navigation to $dest?';
  }

  @override
  String get resumeNavigationAction => 'Resume';

  @override
  String get hazardIce => '⚠ Icy surfaces — ride carefully';

  @override
  String get hazardFreeze => '⚠ Freezing temperatures';

  @override
  String get hazardStrongWind =>
      '⚠ Strong wind — exposed routes may be difficult';

  @override
  String get hazardHeavyRain => 'Heavy rain';

  @override
  String get hazardWetSurface => '⚠ Slippery surfaces — near-zero temperatures';

  @override
  String get hazardSnow => 'Snow';

  @override
  String get hazardTypeRoadDamage => 'Road damage';

  @override
  String get hazardTypeAccident => 'Accident';

  @override
  String get hazardTypeDebris => 'Debris / glass';

  @override
  String get hazardTypeRoadClosed => 'Road closed';

  @override
  String get hazardTypeBadSurface => 'Bad surface';

  @override
  String get hazardTypeFlooding => 'Flooding';

  @override
  String get reportHazardTitle => 'Report hazard';

  @override
  String get reportHazardSubtitle =>
      'Your report helps other riders. Reports expire after 8 hours.';

  @override
  String get reportHazardSubmit => 'Report';

  @override
  String get reportHazardThanks => 'Thanks! Hazard reported.';

  @override
  String get addStop => 'Add stop';

  @override
  String get sectionFrequentRoutes => 'Frequent Routes';

  @override
  String get frequentRoutesEmpty =>
      'Navigate somewhere to see your frequent routes here';

  @override
  String frequentVisitCount(int count) {
    return '$count× visited';
  }

  @override
  String get commuteMorning => 'Morning commute';

  @override
  String get commuteEvening => 'Evening commute';

  @override
  String get startCommute => 'Start';

  @override
  String get navModLeft => 'left';

  @override
  String get navModRight => 'right';

  @override
  String get navModStraight => 'straight';

  @override
  String get navModSlightLeft => 'slight left';

  @override
  String get navModSlightRight => 'slight right';

  @override
  String get navModSharpLeft => 'sharp left';

  @override
  String get navModSharpRight => 'sharp right';

  @override
  String get navModUturn => 'U-turn';

  @override
  String navDepart(String dir, String road) {
    return 'Head $dir on $road';
  }

  @override
  String navDepartBlind(String dir) {
    return 'Head $dir';
  }

  @override
  String get navArrive => 'You have arrived';

  @override
  String navArriveAt(String road) {
    return 'Arrived at $road';
  }

  @override
  String navTurn(String dir, String road) {
    return 'Turn $dir onto $road';
  }

  @override
  String navTurnBlind(String dir) {
    return 'Turn $dir';
  }

  @override
  String navContinue(String road) {
    return 'Continue on $road';
  }

  @override
  String get navContinueBlind => 'Continue';

  @override
  String navMerge(String road) {
    return 'Merge onto $road';
  }

  @override
  String get navMergeBlind => 'Merge';

  @override
  String navFork(String dir, String road) {
    return 'Keep $dir at the fork onto $road';
  }

  @override
  String navForkBlind(String dir) {
    return 'Keep $dir at the fork';
  }

  @override
  String navEndOfRoad(String dir, String road) {
    return 'Turn $dir at end of road onto $road';
  }

  @override
  String navEndOfRoadBlind(String dir) {
    return 'Turn $dir at end of road';
  }

  @override
  String get navRoundabout => 'Enter the roundabout';

  @override
  String navRoundaboutNamed(String road) {
    return 'Enter the roundabout — $road';
  }

  @override
  String get navExitRoundabout => 'Exit the roundabout';

  @override
  String navExitRoundaboutOnto(String road) {
    return 'Exit the roundabout onto $road';
  }

  @override
  String navNewName(String road) {
    return 'Continue onto $road';
  }

  @override
  String navUseLane(String dir, String road) {
    return 'Use the $dir lane onto $road';
  }

  @override
  String navUseLaneBlind(String dir) {
    return 'Use the $dir lane';
  }

  @override
  String navWaypointReached(int n) {
    return 'Stop $n reached — continuing to destination';
  }

  @override
  String get navMaxReroutesReached =>
      'Too many recalculations — continuing on current route';

  @override
  String get discoverActiveHazards => 'Active Hazards';

  @override
  String get discoverNoHazards => 'No active hazards nearby';

  @override
  String get discoverNoSaved => 'No saved routes yet';

  @override
  String get discoverCategories => 'Categories';

  @override
  String get marketplaceBrowse => 'Browse';

  @override
  String get marketplaceSaved => 'Saved';

  @override
  String get marketplaceMyListings => 'My Listings';

  @override
  String get marketplaceMessages => 'Messages';

  @override
  String get marketplaceSell => 'Sell';

  @override
  String get listingCategoryAll => 'All';

  @override
  String get listingCategoryBike => 'Bikes';

  @override
  String get listingCategoryParts => 'Parts';

  @override
  String get listingCategoryAccessories => 'Accessories';

  @override
  String get listingCategoryClothing => 'Clothing & Gear';

  @override
  String get listingCategoryTools => 'Tools';

  @override
  String get listingConditionNew => 'New';

  @override
  String get listingConditionLikeNew => 'Like New';

  @override
  String get listingConditionGood => 'Good';

  @override
  String get listingConditionFair => 'Fair';

  @override
  String get listingContactSeller => 'Contact Seller';

  @override
  String get listingCallSeller => 'Call Seller';

  @override
  String get listingPhoneHint => 'Phone number (optional)';

  @override
  String get listingMarkSold => 'Mark as Sold';

  @override
  String get listingEditAction => 'Edit Listing';

  @override
  String get listingDeleteAction => 'Delete';

  @override
  String get listingSave => 'Save';

  @override
  String get listingUnsave => 'Saved';

  @override
  String get chatMessageHint => 'Type a message...';

  @override
  String get chatSend => 'Send';

  @override
  String get listingPublish => 'Publish Listing';

  @override
  String get listingPrivateSeller => 'Private';

  @override
  String get listingShopSeller => 'Shop';

  @override
  String get listingNoResults => 'No listings found';

  @override
  String get listingMyListingsEmpty => 'You haven\'t listed anything yet';

  @override
  String get listingSavedEmpty => 'No saved listings yet';

  @override
  String get listingNoMessages => 'No messages yet';

  @override
  String get listingReport => 'Report listing';

  @override
  String get listingSortNewest => 'Newest';

  @override
  String get listingSortPriceLow => 'Price: Low to High';

  @override
  String get listingSortPriceHigh => 'Price: High to Low';

  @override
  String get listingCreateTitle => 'New Listing';

  @override
  String get listingEditTitle => 'Edit Listing';

  @override
  String get listingPublished => 'Listing published!';

  @override
  String get listingDeleted => 'Listing deleted';

  @override
  String get listingMarkedSold => 'Marked as sold';

  @override
  String get listingTitleHint => 'e.g. Trek FX3 City Bike';

  @override
  String get listingDescriptionHint => 'Describe condition';

  @override
  String get listingPriceHint => 'Price in DKK';

  @override
  String get listingCityHint => 'City';

  @override
  String get listingAddPhotos => 'Add Photos';

  @override
  String get listingConditionLabel => 'Condition';

  @override
  String get listingCategoryLabel => 'Category';

  @override
  String get listingSortBy => 'Sort by';

  @override
  String listingViews(int count) {
    return '$count views';
  }

  @override
  String listingPostedAgo(String ago) {
    return 'Posted $ago';
  }

  @override
  String get listingSoldBadge => 'SOLD';

  @override
  String get searchHint => 'Search listings...';

  @override
  String get co2ImpactTitle => 'Climate Impact';

  @override
  String get co2Saved => 'CO₂ Saved';

  @override
  String get fuelSaved => 'Fuel Saved';

  @override
  String get caloriesBurned => 'Calories';

  @override
  String get hazardSeverityLabel => 'Severity';

  @override
  String get hazardSeverityInfo => 'Info';

  @override
  String get hazardSeverityCaution => 'Caution';

  @override
  String get hazardSeverityDanger => 'Danger';

  @override
  String get hazardFog => '⚠ Fog — reduced visibility, use lights';

  @override
  String get hazardLowVisibility => '⚠ Very low visibility — extreme caution';

  @override
  String get hazardDarkness =>
      '⚠ Riding in the dark — use front and rear lights';

  @override
  String routeHazardWarning(int count) {
    return '$count hazard(s) on your route';
  }

  @override
  String get infraReportTitle => 'Report Infrastructure Issue';

  @override
  String get infraReportSubtitle =>
      'Help improve cycling infrastructure in your city.';

  @override
  String get infraReportDescHint =>
      'Optional: describe the issue in more detail...';

  @override
  String get infraReportSubmit => 'Submit Report';

  @override
  String get infraReportThanks => 'Thanks! Report submitted.';

  @override
  String get infraMissingLane => 'Missing lane';

  @override
  String get infraBrokenPavement => 'Broken pavement';

  @override
  String get infraPoorLighting => 'Poor lighting';

  @override
  String get infraLackingSignage => 'Lacking signage';

  @override
  String get infraBlockedLane => 'Blocked lane';

  @override
  String get infraMissingRamp => 'Missing ramp';

  @override
  String get infraOther => 'Other';

  @override
  String get gdprTitle => 'Your data, your choice';

  @override
  String get gdprSubtitle =>
      'CYKEL collects only the data needed to make cycling safer and more enjoyable. Review what we use and choose your optional settings below.';

  @override
  String get gdprLocationTitle => 'Location';

  @override
  String get gdprLocationBody =>
      'Used for navigation, route planning, and nearby hazard detection. Never shared without your consent.';

  @override
  String get gdprRidesTitle => 'Ride data';

  @override
  String get gdprRidesBody =>
      'Stored locally on your device. Used to calculate stats and CO₂ impact. Not uploaded to our servers.';

  @override
  String get gdprOptionalTitle => 'Optional features';

  @override
  String get gdprAnalyticsTitle => 'Usage analytics';

  @override
  String get gdprAnalyticsBody =>
      'Anonymous app usage data to help us improve CYKEL. No location or personal data.';

  @override
  String get gdprAggregationTitle => 'Mobility aggregation';

  @override
  String get gdprAggregationBody =>
      'Anonymised, aggregated ride patterns shared with urban planners to improve cycling infrastructure.';

  @override
  String get gdprPrivacyNotice =>
      'You can change these settings at any time in Profile → Privacy. For full details see our Privacy Policy.';

  @override
  String get gdprAccept => 'Accept & Continue';

  @override
  String get gdprSectionTitle => 'Privacy';

  @override
  String get exportMyData => 'Export my data';

  @override
  String get dataExported => 'Data exported successfully';

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get sosButton => 'SOS';

  @override
  String get sosTitle => 'Emergency';

  @override
  String get sosCall112 => 'Call 112 (Emergency Services)';

  @override
  String get sosCall112Subtitle => 'Police, Fire & Ambulance';

  @override
  String get sosShareLocation => 'Copy my location';

  @override
  String get sosReportAccident => 'Report an accident';

  @override
  String get sosReportAccidentSubtitle => 'Submit an incident report to CYKEL';

  @override
  String get sosAccidentDescHint => 'Describe what happened (optional)...';

  @override
  String get sosReportSubmit => 'Submit report';

  @override
  String get sosLocationCopied => 'Location copied to clipboard';

  @override
  String get sosAccidentReported => 'Accident report submitted. Stay safe.';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get displayName => 'Display name';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get savedPlacesTitle => 'Saved Places';

  @override
  String get homePlace => 'Home';

  @override
  String get workPlace => 'Work';

  @override
  String get enterAddress => 'Enter address...';

  @override
  String get addressSaved => 'Saved';

  @override
  String get noAddressSet => 'Not set';

  @override
  String get addBikeTitle => 'Add Bike';

  @override
  String get bikeName => 'Bike name';

  @override
  String get bikeBrand => 'Brand (optional)';

  @override
  String get bikeYear => 'Year (optional)';

  @override
  String get bikeAdded => 'Bike added';

  @override
  String get bikeDeleted => 'Bike removed';

  @override
  String get bikeDeleteConfirm => 'Remove this bike?';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notifRideReminders => 'Ride reminders';

  @override
  String get notifHazardAlerts => 'Hazard alerts';

  @override
  String get notifMarketplace => 'Marketplace messages';

  @override
  String get notifMarketing => 'Product updates & tips';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageDanish => 'Danish';

  @override
  String get helpTitle => 'Help & Support';

  @override
  String get helpEmailAddress => 'support@cykel.app';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get revokeConsent => 'Revoke all consent';

  @override
  String get consentRevoked => 'All consent revoked';

  @override
  String get addPlaceTitle => 'Add Place';

  @override
  String get placeName => 'Place name';

  @override
  String get placeAddress => 'Address';

  @override
  String get placeAdded => 'Place added';

  @override
  String get placeDeleted => 'Place removed';

  @override
  String get customPlaces => 'Other places';

  @override
  String get noCustomPlaces => 'No custom places yet';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get privacyPolicyReadInApp => 'Read in app';

  @override
  String get premiumFeature => 'Premium Feature';

  @override
  String get upgradeToPremium => 'Upgrade to Premium';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get submitButton => 'Submit';

  @override
  String get premiumPlan => 'Premium';

  @override
  String get ridingConditions => 'Riding conditions';

  @override
  String feelsLike(String temp) {
    return 'feels $temp°';
  }

  @override
  String get battery => 'Battery';

  @override
  String get warningCachedData => '⚠️  Cached data';

  @override
  String get warningIceRisk => '⚠️  Ice risk';

  @override
  String get warningStrongWind => '💨  Strong wind';

  @override
  String get warningCold => '🥶  Cold';

  @override
  String get shortcutHomeToWork => 'Home → Work';

  @override
  String get shortcutWorkToHome => 'Work → Home';

  @override
  String get activityStats => 'Activity Stats';

  @override
  String rideCountLabel(int count) {
    return '$count rides';
  }

  @override
  String get streak => 'Streak';

  @override
  String get dayUnit => 'day';

  @override
  String get daysUnit => 'days';

  @override
  String get noWeatherAlerts => 'No Weather Alerts';

  @override
  String get conditionsGoodForCycling => 'Conditions are good for cycling';

  @override
  String get weatherAlerts => 'Weather Alerts';

  @override
  String get lowSeverity => 'Low';

  @override
  String get mediumSeverity => 'Medium';

  @override
  String get highSeverity => 'High';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get noNotificationsDesc =>
      'You\'re all caught up! Notifications will appear here.';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return '$count minutes ago';
  }

  @override
  String hoursAgo(int count) {
    return '$count hours ago';
  }

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get weatherUnavailable => 'Weather Unavailable';

  @override
  String get unableToCheckWeather => 'Unable to check weather conditions';

  @override
  String get maintenanceDue => 'Maintenance Due';

  @override
  String maintenanceBody(String km) {
    return 'Your bike has ridden ${km}km since last service';
  }

  @override
  String get markDone => 'Mark Done';

  @override
  String get couldNotLoadNearby => 'Could not load nearby places';

  @override
  String get checkConnectionRetry => 'Check your connection and try again';

  @override
  String get noBikePlacesNearby => 'No bike places nearby';

  @override
  String get tryCyclingMoreInfra =>
      'Try cycling to an area with more infrastructure';

  @override
  String get bikeRental => 'Bike Rental';

  @override
  String get repairStation => 'Repair Station';

  @override
  String get dayMon => 'Mon';

  @override
  String get dayTue => 'Tue';

  @override
  String get dayWed => 'Wed';

  @override
  String get dayThu => 'Thu';

  @override
  String get dayFri => 'Fri';

  @override
  String get daySat => 'Sat';

  @override
  String get daySun => 'Sun';

  @override
  String get monthJan => 'January';

  @override
  String get monthFeb => 'February';

  @override
  String get monthMar => 'March';

  @override
  String get monthApr => 'April';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'June';

  @override
  String get monthJul => 'July';

  @override
  String get monthAug => 'August';

  @override
  String get monthSep => 'September';

  @override
  String get monthOct => 'October';

  @override
  String get monthNov => 'November';

  @override
  String get monthDec => 'December';

  @override
  String monthlyChallenge(String month) {
    return '$month Challenge';
  }

  @override
  String challengeRideCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'rides',
      one: 'ride',
    );
    return '$count $_temp0';
  }

  @override
  String get premiumBannerSubtitle =>
      'Wind routing · Analytics · Offline · E-Bike — kr 20/mo';

  @override
  String get eBikeRange => 'E-Bike Range';

  @override
  String batteryPercent(int percent) {
    return '$percent% battery';
  }

  @override
  String rangeRemaining(String range) {
    return '≈ $range remaining';
  }

  @override
  String get lowBattery => '⚠ Low battery';

  @override
  String get tabLive => 'Live';

  @override
  String get tabAnalytics => 'Analytics';

  @override
  String rideSavedSnackbar(String distance) {
    return 'Ride saved: $distance';
  }

  @override
  String get replay => 'Replay';

  @override
  String get gpxLabel => 'GPX';

  @override
  String get noGpsPathToExport => 'No GPS path to export.';

  @override
  String get gpxExportTitle => 'GPX Export';

  @override
  String gpxFileSavedTo(String path) {
    return 'File saved to:\n$path';
  }

  @override
  String get copyGpxToClipboard => 'Copy GPX to clipboard';

  @override
  String get gpxCopiedToClipboard => 'GPX copied to clipboard';

  @override
  String get premiumAnalyticsBody =>
      'Detailed ride analytics are available with a Premium subscription.';

  @override
  String get periodSummaries => 'Period Summaries';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get thisYear => 'This Year';

  @override
  String get personalRecords => 'Personal Records';

  @override
  String get completeFirstRide => 'Complete your first ride to see records.';

  @override
  String get timeLabel => 'Time';

  @override
  String get kcalUnit => 'kcal';

  @override
  String get climb => 'Climb';

  @override
  String get savedLabel => 'Saved';

  @override
  String get ridesLabel => 'Rides';

  @override
  String get longestRide => 'Longest Ride';

  @override
  String get fastestAvgSpeed => 'Fastest Avg Speed';

  @override
  String get mostElevation => 'Most Elevation';

  @override
  String get mostCalories => 'Most Calories';

  @override
  String get longestStreak => 'Longest Streak';

  @override
  String get routeReplayTitle => 'Route Replay';

  @override
  String get replayStart => 'Start';

  @override
  String get replayEnd => 'End';

  @override
  String get noGpsPathAvailable => 'No GPS path available';

  @override
  String get elapsed => 'Elapsed';

  @override
  String get total => 'Total';

  @override
  String fuelSavingsAmount(String amount) {
    return 'Fuel savings: $amount';
  }

  @override
  String get cykelPremiumTitle => 'CYKEL Premium';

  @override
  String get premiumTagline => 'Intelligence · Reliability · Optimization';

  @override
  String get onPremiumStatus => '✓  You are on Premium';

  @override
  String get onFreeStatus => 'Currently on Free plan';

  @override
  String get featuresHeader => 'Features';

  @override
  String get freeColumn => 'FREE';

  @override
  String get proColumn => 'PRO';

  @override
  String get premiumPrice => 'kr 20';

  @override
  String get premiumPerMonth => '/month';

  @override
  String get premiumPriceNote => 'Approx. \$2.99 USD · Cancel anytime';

  @override
  String get cancelPremiumTitle => 'Cancel Premium?';

  @override
  String get cancelPremiumBody => 'You will lose access to Premium features.';

  @override
  String get keepPremium => 'Keep Premium';

  @override
  String get switchedToFree => 'Switched to Free plan';

  @override
  String get welcomeToPremium => 'Welcome to Premium!';

  @override
  String get upgradeButtonLabel => 'Upgrade to Premium — kr 20/month';

  @override
  String get manageSubscription => 'Manage Subscription';

  @override
  String get pillWindAI => 'Wind AI';

  @override
  String get pillAnalytics => 'Analytics';

  @override
  String get pillEBike => 'E-Bike';

  @override
  String get pillCloud => 'Cloud';

  @override
  String get studentDiscountBanner => 'Student? Get 50% off Premium';

  @override
  String get studentDiscountPrice => 'kr 10/month instead of kr 20';

  @override
  String get verifiedStudentBadge => 'Verified Student - 50% Discount Applied';

  @override
  String get billingPeriodMonthly => 'Monthly';

  @override
  String get billingPeriodYearly => 'Yearly';

  @override
  String get annualSavingsMessage => 'Save kr 40 with annual plan';

  @override
  String get studentVerificationTitle => 'Verify Student Status';

  @override
  String get studentVerificationSubtitle =>
      'Unlock 50% off Premium with your university email';

  @override
  String get studentEmailLabel => 'University Email';

  @override
  String get studentEmailHint => 'your.name@university.edu';

  @override
  String get invalidStudentEmail => 'Invalid student email domain';

  @override
  String get studentEmailDomainNote =>
      'Accepted: .edu, .ac.dk, .ku.dk, .dtu.dk, .cbs.dk, .ruc.dk, .au.dk, .sdu.dk, .aau.dk';

  @override
  String get verifyStudentButton => 'Verify Student Status';

  @override
  String get studentVerificationSuccess =>
      '✅ Student status verified! You can now get 50% off Premium.';

  @override
  String get studentVerificationPending => 'Verifying...';

  @override
  String get studentVerificationBenefitsTitle => 'Student Benefits:';

  @override
  String get studentBenefit1 => 'Premium for kr 10/month (50% off)';

  @override
  String get studentBenefit2 => 'All Premium features included';

  @override
  String get studentBenefit3 => 'Valid for 1 year - easy renewal';

  @override
  String get studentBenefit4 => 'Support student cycling community';

  @override
  String get subNavAndMap => 'Navigation & Map';

  @override
  String get subSafety => 'Safety & Public Value — Always Free';

  @override
  String get subActivityTracking => 'Activity Tracking';

  @override
  String get subPersonalization => 'Personalization & Utility';

  @override
  String get subMarketplaceBasic => 'Marketplace — Basic Access';

  @override
  String get subSmartRouting => 'Smart Routing & Optimization';

  @override
  String get subOffline => 'Offline & Reliability';

  @override
  String get subEbikeIntel => 'E-Bike Intelligence';

  @override
  String get subAdvAnalytics => 'Advanced Analytics & Performance';

  @override
  String get subAutomation => 'Automation & Smart Assistance';

  @override
  String get subRouteSharing => 'Route Sharing & Social Utility';

  @override
  String get subAdvCustom => 'Advanced Customisation';

  @override
  String get subVoiceNav => 'Voice & Navigation Experience';

  @override
  String get subCloudSync => 'Cloud Sync & Multi-Device';

  @override
  String get subMarketplacePro => 'Marketplace — Premium Enhancements';

  @override
  String get subFeatBasicRouting => 'Basic A → B cycling routing';

  @override
  String get subFeatVoiceNav => 'Turn-by-turn voice navigation';

  @override
  String get subFeatGpsTracking => 'Real-time GPS tracking';

  @override
  String get subFeatFollowUser => 'Follow-user map mode';

  @override
  String get subFeatAltRoutes => 'Alternative route selection';

  @override
  String get subFeatNearbyPoi => 'Nearby POIs (charging, repair, rentals)';

  @override
  String get subFeatMapLayers => 'Map layers: traffic, bike lanes, satellite';

  @override
  String get subFeatRouteSummary => 'Route summary — distance, duration, ETA';

  @override
  String get subFeatWeatherWind => 'Current weather + wind conditions';

  @override
  String get subFeatNightMode => 'Night mode support';

  @override
  String get subFeatLocaleSwitching => 'Language / locale switching';

  @override
  String get subFeatStormWarnings => 'Storm warnings';

  @override
  String get subFeatIceAlerts => 'Ice / slippery road alerts';

  @override
  String get subFeatFogWarnings => 'Fog & visibility warnings';

  @override
  String get subFeatHazardAlerts => 'Hazard alerts on route';

  @override
  String get subFeatCrowdHazards => 'Crowd-reported hazards (view)';

  @override
  String get subFeatEmergencySos => 'Emergency SOS — call & share location';

  @override
  String get subFeatAccidentReport => 'Accident reporting';

  @override
  String get subFeatRideCondition => 'Ride condition indicator';

  @override
  String get subFeatSafetyNotifs => 'Safety push notifications';

  @override
  String get subFeatLiveRecording =>
      'Live ride recording — distance, speed, time';

  @override
  String get subFeatCaloriesBasic => 'Calories (basic)';

  @override
  String get subFeatRideHistory30 => 'Ride history (last 30 days)';

  @override
  String get subFeatRideHistoryNote => 'Premium: unlimited';

  @override
  String get subFeatWeeklyStats => 'Weekly activity stats';

  @override
  String get subFeatMonthlyGoals => 'Monthly challenge goals';

  @override
  String get subFeatCo2Stats => 'Basic CO₂ saved statistics';

  @override
  String get subFeatFuelSavings => 'Fuel savings equivalent (DKK)';

  @override
  String get subFeatDashboardSummary => 'Home dashboard activity summary';

  @override
  String get subFeatMultiBikes => 'Multiple bike profiles';

  @override
  String get subFeatSavedPlaces => 'Saved places / favorites';

  @override
  String get subFeatCommuteSuggestion => 'Commute suggestion card';

  @override
  String get subFeatPushNotifs => 'Push notifications (general)';

  @override
  String get subFeatGdprControls => 'Privacy settings & GDPR controls';

  @override
  String get subFeatAppTheme => 'App theme (light / dark)';

  @override
  String get subFeatBrowseListings => 'Browse listings (bikes & gear)';

  @override
  String get subFeatViewDetails => 'View item details';

  @override
  String get subFeatContactSeller => 'Contact seller';

  @override
  String get subFeatBasicListing => 'Basic listing posting';

  @override
  String get subFeatWindRouting => 'Wind-optimised route auto-selection';

  @override
  String get subFeatElevRouting => 'Elevation-aware routing';

  @override
  String get subFeatRouteModeFastSafe => 'Fastest vs safest route modes';

  @override
  String get subFeatFreqDest => 'Frequent destinations shortcuts';

  @override
  String get subFeatUnlimitedRoutes => 'Quick saved routes (unlimited)';

  @override
  String get subFeatAdvRoutePrefs => 'Advanced route preferences';

  @override
  String get subFeatOfflineRoutes => 'Download routes for offline navigation';

  @override
  String get subFeatCachedTiles => 'Cached map tiles for selected areas';

  @override
  String get subFeatOfflineTbt => 'Offline turn-by-turn guidance';

  @override
  String get subFeatNetworkFallback =>
      'Network failure handling + auto-fallback';

  @override
  String get subFeatGpsMitigation => 'GPS loss mitigation & tunnel mode';

  @override
  String get subFeatRouteRecovery => 'Route recovery after app restart';

  @override
  String get subFeatBatteryRange => 'Battery range estimation';

  @override
  String get subFeatEnergyModel => 'Energy consumption modelling';

  @override
  String get subFeatElevRange => 'Elevation-adjusted range';

  @override
  String get subFeatRangeCard => 'Remaining range dashboard card';

  @override
  String get subFeatUnlimitedHistory => 'Unlimited ride history';

  @override
  String get subFeatElevTracking => 'Elevation gain tracking per ride';

  @override
  String get subFeatElevCalorie => 'Elevation-aware calorie calculation';

  @override
  String get subFeatPeriodStats => 'Weekly / monthly / yearly stats';

  @override
  String get subFeatPersonalRecords =>
      'Personal records — longest, fastest, streaks';

  @override
  String get subFeatGpxExport => 'GPX export of rides';

  @override
  String get subFeatScheduledReminders => 'Scheduled ride reminders';

  @override
  String get subFeatMaintenanceAlerts =>
      'Maintenance alerts — service intervals & wear';

  @override
  String get subFeatSmartNotifs => 'Smart notifications';

  @override
  String get subFeatShareLink => 'Share routes via link';

  @override
  String get subFeatExportGpx => 'Export route to GPX';

  @override
  String get subFeatShareSummary => 'Share ride summaries';

  @override
  String get subFeatSendToFriends => 'Send route to friends';

  @override
  String get subFeatImportRoutes => 'Import shared routes';

  @override
  String get subFeatCustomDashboard => 'Custom dashboard layout';

  @override
  String get subFeatMapStyle => 'Map style personalisation';

  @override
  String get subFeatCustomAlerts => 'Custom alert thresholds';

  @override
  String get subFeatCustomGoals => 'Custom ride goals';

  @override
  String get subFeatUiDensity => 'UI density options';

  @override
  String get subFeatPremiumVoice => 'Premium voice packs';

  @override
  String get subFeatMultiLangVoice => 'Multiple language voice options';

  @override
  String get subFeatVoiceStyle => 'Voice style — Minimal / Detailed / Safety';

  @override
  String get subFeatAnnouncementFreq => 'Adjustable announcement frequency';

  @override
  String get subFeatDataSync => 'Data sync across devices';

  @override
  String get subFeatCloudBackup => 'Cloud backup of rides';

  @override
  String get subFeatRestoreHistory => 'Restore history after reinstall';

  @override
  String get subFeatSyncProfiles => 'Sync bike profiles & settings';

  @override
  String get subFeatUnlimitedListings => 'Unlimited listings';

  @override
  String get subFeatPriorityPlacement => 'Priority placement';

  @override
  String get subFeatHighlighted => 'Highlighted / featured items';

  @override
  String get subFeatAdvSearchFilters => 'Advanced search filters';

  @override
  String get subFeatSellerAnalytics => 'Seller analytics dashboard';

  @override
  String get voiceSettingsTitle => 'Voice Settings';

  @override
  String get voiceStyle => 'Voice Style';

  @override
  String get voiceMinimal => 'Minimal';

  @override
  String get voiceMinimalDesc => 'Street name only — minimal interruptions';

  @override
  String get voiceDetailed => 'Detailed';

  @override
  String get voiceDetailedDesc =>
      'Turn direction + street + distance (default)';

  @override
  String get voiceSafety => 'Safety focus';

  @override
  String get voiceSafetyDesc => 'Detailed + extra hazard & safety callouts';

  @override
  String get speechRate => 'Speech Rate';

  @override
  String get speechRateDesc =>
      'Adjust how quickly the voice speaks instructions.';

  @override
  String get rateVerySlow => 'Very slow';

  @override
  String get rateSlow => 'Slow';

  @override
  String get rateNormal => 'Normal';

  @override
  String get rateFast => 'Fast';

  @override
  String get rateVeryFast => 'Very fast';

  @override
  String get previewVoice => 'Preview voice';

  @override
  String get voicePreviewText => 'In 500 metres, turn right onto Main Street.';

  @override
  String get announcementDistance => 'Announcement Distance';

  @override
  String get announcementDistanceDesc =>
      'How far ahead upcoming turns are announced.';

  @override
  String get freqEarly => 'Early';

  @override
  String get freqNormal => 'Normal (default)';

  @override
  String get freqLate => 'Late';

  @override
  String get premiumVoiceBody =>
      'Voice customisation is available with a Premium subscription.';

  @override
  String get dashboardSettingsTitle => 'Dashboard Settings';

  @override
  String get homeScreenSections => 'Home Screen Sections';

  @override
  String get homeScreenSectionsDesc =>
      'Choose which sections to show on your home dashboard.';

  @override
  String get sectionMonthlyChallenge => 'Monthly Challenge';

  @override
  String get sectionMonthlyChallengeDesc => 'Track your monthly cycling goal';

  @override
  String get sectionEbikeRange => 'E-bike Range';

  @override
  String get sectionEbikeRangeDesc => 'Battery level and estimated range';

  @override
  String get sectionQuickRoutesLabel => 'Quick Routes';

  @override
  String get sectionQuickRoutesDesc => 'Saved routes and frequent destinations';

  @override
  String get sectionRecentActivity => 'Recent Activity';

  @override
  String get sectionRecentActivityDesc => 'Your latest rides and stats';

  @override
  String get sectionMaintenanceReminder => 'Maintenance Reminder';

  @override
  String get sectionMaintenanceReminderDesc => 'Service due notifications';

  @override
  String get changesImmediate => 'Changes take effect immediately.';

  @override
  String get premiumDashboardBody =>
      'Dashboard customisation is available with a Premium subscription.';

  @override
  String get faqSection => 'FAQ';

  @override
  String get contactSection => 'CONTACT';

  @override
  String get emailUs => 'Email us';

  @override
  String get faq1Q => 'How do I record a ride?';

  @override
  String get faq1A =>
      'Open the Map tab and tap the play button at the bottom to start recording. Tap stop when finished.';

  @override
  String get faq2Q => 'How do I report a hazard?';

  @override
  String get faq2A =>
      'While navigating, tap the warning icon and choose the hazard type. Reports are visible to nearby riders for 8 hours.';

  @override
  String get faq3Q => 'How do I list a bike for sale?';

  @override
  String get faq3A =>
      'Go to the Marketplace tab and tap the + button. Fill in the details and add photos to publish your listing.';

  @override
  String get faq4Q => 'How do I save a place?';

  @override
  String get faq4A =>
      'Go to Profile → Saved Places and type in your home or work address.';

  @override
  String get faq5Q => 'How do I delete my account?';

  @override
  String get faq5A =>
      'Go to Profile, scroll to the bottom and tap \"Delete account\". This permanently removes all your data.';

  @override
  String get faq6Q => 'How do I change the language?';

  @override
  String get faq6A => 'Go to Profile → Language and select English or Danish.';

  @override
  String lastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get privacyLastUpdateDate => '23 March 2026';

  @override
  String get privacySection1Title => '1. Who We Are';

  @override
  String get privacySection1Body =>
      'CYKEL ApS (\"CYKEL\", \"we\", \"us\") operates the CYKEL mobile application. We are registered in Denmark and are subject to the EU General Data Protection Regulation (GDPR).\n\nContact: privacy@cykel.app';

  @override
  String get privacySection2Title => '2. Data We Collect';

  @override
  String get privacySection2Body =>
      '• Account data (name, email, profile photo) — provided when you sign up.\n• Location data — collected during rides to draw your route. Never shared with third parties in identifiable form.\n• Ride data — distance, duration, route geometry.\n• Device data — OS version, app version, crash logs.\n• Optional: anonymised, aggregated mobility data if you consent.';

  @override
  String get privacySection3Title => '3. How We Use Your Data';

  @override
  String get privacySection3Body =>
      '• Providing core app functionality (routes, ride history, marketplace).\n• Improving cycling infrastructure planning through aggregated, anonymised data (only with your explicit consent).\n• Sending you service notifications (e.g. ride reminders).\n• Fraud prevention and security.\n\nWe do NOT sell your personal data.';

  @override
  String get privacySection4Title => '4. Legal Basis (GDPR Art. 6)';

  @override
  String get privacySection4Body =>
      '• Performance of a contract — delivering the services you requested.\n• Legitimate interest — security, fraud prevention, app improvement.\n• Consent — analytics and aggregated ride data (you can withdraw at any time in Settings → Privacy).';

  @override
  String get privacySection5Title => '5. Data Sharing';

  @override
  String get privacySection5Body =>
      'We share data only with:\n• Firebase / Google (hosting, authentication, database) — under EU Standard Contractual Clauses.\n• Apple / Google — for sign-in and push notifications.\n• No advertising networks or data brokers.';

  @override
  String get privacySection6Title => '6. Retention';

  @override
  String get privacySection6Body =>
      '• Ride data: retained for 3 years, then automatically deleted.\n• Account data: retained until you delete your account.\n• Crash logs: 90 days.\n• Aggregated anonymised data: retained indefinitely (cannot be linked back to you).';

  @override
  String get privacySection7Title => '7. Your Rights';

  @override
  String get privacySection7Body =>
      'Under GDPR you have the right to:\n• Access — request a copy of all data we hold about you.\n• Rectification — correct inaccurate data.\n• Erasure (\"right to be forgotten\") — delete your account and all associated data.\n• Portability — receive your data in a machine-readable format.\n• Objection — object to processing based on legitimate interest.\n• Withdraw consent — at any time via Settings → Privacy.\n\nTo exercise these rights contact privacy@cykel.app. You also have the right to lodge a complaint with Datatilsynet (datatilsynet.dk).';

  @override
  String get privacySection8Title => '8. Children';

  @override
  String get privacySection8Body =>
      'CYKEL is not directed at children under 13. We do not knowingly collect data from children. If you believe a child has provided us data, contact privacy@cykel.app and we will delete it promptly.';

  @override
  String get privacySection9Title => '9. Policy Changes';

  @override
  String get privacySection9Body =>
      'We may update this policy. Significant changes will be communicated via an in-app notification. Continued use after the effective date constitutes acceptance.';

  @override
  String get privacySection10Title => '10. Contact';

  @override
  String get privacySection10Body =>
      'CYKEL ApS\nprivacy@cykel.app\nFor urgent matters: support@cykel.app';

  @override
  String get notifSectionRiding => 'Riding';

  @override
  String get notifRideRemindersDesc => 'Reminders to log your rides';

  @override
  String get notifHazardAlertsDesc => 'Nearby hazard warnings while cycling';

  @override
  String get notifSectionMarketplace => 'Marketplace';

  @override
  String get notifMarketplaceDesc => 'Chat messages from buyers & sellers';

  @override
  String get notifSectionGeneral => 'General';

  @override
  String get notifMarketingDesc => 'News, tips and feature announcements';

  @override
  String get notifSectionScheduled => 'Scheduled Reminders';

  @override
  String get dailyRideReminder => 'Daily Ride Reminder';

  @override
  String get tapToSetReminder => 'Tap to set a daily reminder time';

  @override
  String reminderSetFor(String time) {
    return 'Reminder set for $time';
  }

  @override
  String get removeReminder => 'Remove reminder';

  @override
  String get setTime => 'Set time';

  @override
  String get changeTime => 'Change';

  @override
  String get preferencesSection => 'Preferences';

  @override
  String get dashboardLabel => 'Dashboard';

  @override
  String get voiceNavLabel => 'Voice & Navigation';

  @override
  String get moreSection => 'More';

  @override
  String get currentPlan => 'Current plan';

  @override
  String get manageButton => 'Manage';

  @override
  String get upgradeButton => 'Upgrade';

  @override
  String signOutFailed(String error) {
    return 'Sign out failed: $error';
  }

  @override
  String deleteAccountFailed(String error) {
    return 'Failed to delete account: $error';
  }

  @override
  String get nameCannotBeEmpty => 'Name cannot be empty';

  @override
  String failedToSave(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get phoneHint => '+45 ...';

  @override
  String get bikeTypeLabel => 'Type';

  @override
  String failedToAddBike(String error) {
    return 'Failed to add bike: $error';
  }

  @override
  String get revokeConsentBody =>
      'This will reset all data consent. You will be shown the consent screen again next time you open the app.';

  @override
  String get requiredBadge => 'Required';

  @override
  String failedToSaveConsent(String error) {
    return 'Failed to save consent: $error';
  }

  @override
  String get deleteListingConfirm =>
      'Are you sure you want to delete this listing? This cannot be undone.';

  @override
  String genericError(String error) {
    return 'Something went wrong. Please try again.';
  }

  @override
  String get discardChangesTitle => 'Discard changes?';

  @override
  String get discardChangesBody =>
      'You have unsaved changes. Are you sure you want to leave?';

  @override
  String get stayButton => 'Stay';

  @override
  String get discardButton => 'Discard';

  @override
  String get addUpToPhotos => 'Add up to 5 photos';

  @override
  String get currencyDKK => 'DKK';

  @override
  String get validPhoneNumber => 'Enter a valid phone number';

  @override
  String get addAtLeastOnePhoto => 'Please add at least one photo';

  @override
  String get descriptionHeader => 'Description';

  @override
  String get chatThreadNotFound => 'Chat thread not found';

  @override
  String couldNotStartChat(String error) {
    return 'Could not start chat: $error';
  }

  @override
  String get reportListingReason => 'Why are you reporting this listing?';

  @override
  String get reportScam => 'Scam / fraud';

  @override
  String get reportStolen => 'Stolen bike';

  @override
  String get reportInappropriate => 'Inappropriate content';

  @override
  String get reportOther => 'Other';

  @override
  String get reportSubmitted => 'Report submitted. Thank you.';

  @override
  String failedToReport(String error) {
    return 'Failed to report: $error';
  }

  @override
  String get viewsStat => 'Views';

  @override
  String get savesStat => 'Saves';

  @override
  String get chatsStat => 'Chats';

  @override
  String get activeStatus => 'Active';

  @override
  String get chatTitle => 'Chat';

  @override
  String failedToSendMessage(String error) {
    return 'Failed to send message';
  }

  @override
  String get welcomeGetStarted => 'Get started';

  @override
  String get welcomeJoinCommunity => 'Join the cycling community';

  @override
  String get filterCharging => 'Charging';

  @override
  String get filterService => 'Service';

  @override
  String get filterShops => 'Shops';

  @override
  String get filterRental => 'Rental';

  @override
  String agoMinutes(int min) {
    return '${min}m ago';
  }

  @override
  String agoHours(int hours) {
    return '${hours}h ago';
  }

  @override
  String agoDays(int days) {
    return '${days}d ago';
  }

  @override
  String get hazardDuplicateUpvoted =>
      'A nearby report already existed — it was upvoted instead.';

  @override
  String hazardGpsAccuracyLow(String meters) {
    return 'GPS accuracy too low ($meters m). Move to an open area and try again.';
  }

  @override
  String get hazardSubmitFailed => 'Failed to submit. Please try again.';

  @override
  String get ttsLanguageUnavailable =>
      'Voice language unavailable — using English';

  @override
  String get noRouteToExport => 'No route to export.';

  @override
  String get shareRouteGpx => 'Share Route GPX';

  @override
  String get shareRoute => 'Share';

  @override
  String get downloadMap => 'Download';

  @override
  String gpxFileLabel(String path) {
    return 'File: $path';
  }

  @override
  String get routeGpxCopied => 'Route GPX copied to clipboard';

  @override
  String get noRouteToCacheTiles => 'No route to cache tiles for.';

  @override
  String get tilesCachedForOffline => 'Map tiles cached for offline use';

  @override
  String tilePrefetchFailed(String error) {
    return 'Tile prefetch failed: $error';
  }

  @override
  String get cachingMapTilesTitle => 'Caching Map Tiles';

  @override
  String get cachingMapTilesBody =>
      'Preparing map tiles for offline use...\nThis may take a minute.';

  @override
  String get routeFastest => 'Fastest';

  @override
  String get routeSafest => 'Safest';

  @override
  String get selectRoute => 'Choose Your Route';

  @override
  String get routingPreference => 'Route Type';

  @override
  String get bikeType => 'Bike Profile';

  @override
  String get destination => 'Destination';

  @override
  String get windOverlay => 'Wind Overlay';

  @override
  String get hazardConfirmedThanks => 'Thanks — hazard confirmed.';

  @override
  String get hazardStillThere => 'Still there';

  @override
  String get hazardClearedThanks => 'Thanks — hazard cleared.';

  @override
  String get hazardCleared => 'Cleared';

  @override
  String get hazardResolved => 'This hazard has been resolved.';

  @override
  String get filterAll => 'All';

  @override
  String get reportListingTitle => 'Report listing';

  @override
  String get todayLabel => 'Today';

  @override
  String get yesterdayLabel => 'Yesterday';

  @override
  String get fieldRequired => 'Required';

  @override
  String get providerTypeRepairShop => 'Repair / Garage Shop';

  @override
  String get providerTypeBikeShop => 'Bike Retail Shop';

  @override
  String get providerTypeChargingLocation => 'E-Bike Charging Location';

  @override
  String get providerTypeServicePoint => 'Service Point';

  @override
  String get providerTypeRental => 'Bike Rental';

  @override
  String get providerTypeRepairShopDesc =>
      'Offer mechanical services, repairs, and maintenance for bicycles.';

  @override
  String get providerTypeBikeShopDesc =>
      'Sell bicycles, e-bikes, accessories, and cycling gear.';

  @override
  String get providerTypeChargingLocationDesc =>
      'Provide charging points for e-bike riders.';

  @override
  String get providerTypeServicePointDesc =>
      'Mobile or fixed service stations for quick repairs and maintenance.';

  @override
  String get providerTypeRentalDesc =>
      'Rent out bicycles and e-bikes to riders.';

  @override
  String get repairFlatTire => 'Flat tire repair';

  @override
  String get repairBrakeService => 'Brake service';

  @override
  String get repairGearAdjustment => 'Gear adjustment';

  @override
  String get repairChainReplacement => 'Chain replacement';

  @override
  String get repairWheelTruing => 'Wheel truing';

  @override
  String get repairSuspensionService => 'Suspension service';

  @override
  String get repairEbikeDiagnostics => 'E-bike diagnostics';

  @override
  String get repairFullTuneUp => 'Full tune-up';

  @override
  String get repairEmergencyRepair => 'Emergency repair';

  @override
  String get repairSafetyInspection => 'Safety inspection';

  @override
  String get repairMobileRepair => 'Mobile repair';

  @override
  String get bikeTypeCityBike => 'City bike';

  @override
  String get bikeTypeRoadBike => 'Road bike';

  @override
  String get bikeTypeMtb => 'MTB';

  @override
  String get bikeTypeCargoBike => 'Cargo bike';

  @override
  String get productCityBikes => 'City bikes';

  @override
  String get productEbikes => 'E-bikes';

  @override
  String get productCargoBikes => 'Cargo bikes';

  @override
  String get productRoadBikes => 'Road bikes';

  @override
  String get productKidsBikes => 'Kids bikes';

  @override
  String get productHelmets => 'Helmets';

  @override
  String get productLocks => 'Locks';

  @override
  String get productLights => 'Lights';

  @override
  String get productTires => 'Tires';

  @override
  String get productSpareParts => 'Spare parts';

  @override
  String get productClothing => 'Clothing';

  @override
  String get chargingStandardOutlet => 'Standard outlet';

  @override
  String get chargingDedicatedCharger => 'Dedicated e-bike charger';

  @override
  String get chargingBatterySwap => 'Battery swap station';

  @override
  String get hostPublicStation => 'Public station';

  @override
  String get hostCafe => 'Café';

  @override
  String get hostShop => 'Shop';

  @override
  String get hostOffice => 'Office';

  @override
  String get hostParkingFacility => 'Parking facility';

  @override
  String get hostOther => 'Other';

  @override
  String get powerFree => 'Free';

  @override
  String get powerPaid => 'Paid';

  @override
  String get powerCustomersOnly => 'Customers only';

  @override
  String get amenitySeating => 'Seating';

  @override
  String get amenityFoodDrinks => 'Food & drinks';

  @override
  String get amenityRestroom => 'Restroom';

  @override
  String get amenityBikeParking => 'Bike parking';

  @override
  String get amenityWifi => 'Wi-Fi';

  @override
  String get accessPublic => 'Public';

  @override
  String get accessCustomersOnly => 'Customers only';

  @override
  String get accessResidentsOnly => 'Residents only';

  @override
  String get priceRangeLow => 'Low';

  @override
  String get priceRangeMedium => 'Medium';

  @override
  String get priceRangeHigh => 'High';

  @override
  String get priceTierBudget => 'Budget';

  @override
  String get priceTierMid => 'Mid-range';

  @override
  String get priceTierPremium => 'Premium';

  @override
  String get verificationPending => 'Pending review';

  @override
  String get verificationApproved => 'Verified';

  @override
  String get verificationRejected => 'Rejected';

  @override
  String get providerActive => 'Active';

  @override
  String get providerInactive => 'Inactive';

  @override
  String get providerTemporarilyClosed => 'Temporarily closed';

  @override
  String get becomeProvider => 'Become a Provider';

  @override
  String get providerDashboard => 'Provider Dashboard';

  @override
  String get providerOnboardingTitle => 'Register your business';

  @override
  String get providerSelectTypeTitle => 'What type of provider are you?';

  @override
  String get providerSelectTypeSubtitle =>
      'Choose the category that best fits your business.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get backLabel => 'Back';

  @override
  String get submitLabel => 'Submit';

  @override
  String stepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get businessInfoTitle => 'Business Information';

  @override
  String get businessNameLabel => 'Business name';

  @override
  String get businessNameHint => 'e.g. Copenhagen Bike Repair';

  @override
  String get legalBusinessNameLabel => 'Legal business name (optional)';

  @override
  String get cvrNumberLabel => 'CVR number';

  @override
  String get cvrNumberHint => '8-digit Danish business ID';

  @override
  String get contactNameLabel => 'Contact person';

  @override
  String get contactNameHint => 'Full name';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'business@example.dk';

  @override
  String get websiteLabel => 'Website (optional)';

  @override
  String get websiteHint => 'https://...';

  @override
  String get locationTitle => 'Location';

  @override
  String get streetAddressLabel => 'Street address';

  @override
  String get streetAddressHint => 'e.g. Nørrebrogade 42';

  @override
  String get cityLabel => 'City';

  @override
  String get cityHint => 'e.g. Copenhagen';

  @override
  String get postalCodeLabel => 'Postal code';

  @override
  String get postalCodeHint => 'e.g. 2200';

  @override
  String get servicesTitle => 'Services & Details';

  @override
  String get servicesOfferedLabel => 'Services offered';

  @override
  String get supportedBikeTypesLabel => 'Supported bike types';

  @override
  String get mobileRepairLabel => 'Offer mobile repair';

  @override
  String get acceptsWalkInsLabel => 'Accept walk-ins';

  @override
  String get appointmentRequiredLabel => 'Appointment required';

  @override
  String get estimatedWaitLabel => 'Estimated wait time (minutes)';

  @override
  String get estimatedWaitHint => 'e.g. 30';

  @override
  String get priceRangeLabel => 'Price range';

  @override
  String get serviceRadiusLabel => 'Mobile service radius (km)';

  @override
  String get serviceRadiusHint => 'e.g. 10';

  @override
  String get productsTitle => 'Products & Details';

  @override
  String get productsAvailableLabel => 'Products available';

  @override
  String get offersTestRidesLabel => 'Offer test rides';

  @override
  String get financingAvailableLabel => 'Financing available';

  @override
  String get acceptsTradeInLabel => 'Accept trade-ins';

  @override
  String get onlineStoreUrlLabel => 'Online store URL (optional)';

  @override
  String get priceTierLabel => 'Price tier';

  @override
  String get hasRepairServiceLabel => 'Also offer repair services';

  @override
  String get chargingTitle => 'Charging Details';

  @override
  String get hostTypeLabel => 'Host type';

  @override
  String get chargingTypeLabel => 'Charging type';

  @override
  String get numberOfPortsLabel => 'Number of charging ports';

  @override
  String get numberOfPortsHint => 'e.g. 4';

  @override
  String get powerAvailabilityLabel => 'Power availability';

  @override
  String get maxChargingDurationLabel => 'Max charging duration (minutes)';

  @override
  String get maxChargingDurationHint => 'Leave empty for unlimited';

  @override
  String get indoorChargingLabel => 'Indoor charging available';

  @override
  String get weatherProtectedLabel => 'Weather-protected';

  @override
  String get amenitiesLabel => 'Amenities';

  @override
  String get accessRestrictionLabel => 'Access restriction';

  @override
  String get openingHoursTitle => 'Opening Hours';

  @override
  String get mondayShort => 'Mon';

  @override
  String get tuesdayShort => 'Tue';

  @override
  String get wednesdayShort => 'Wed';

  @override
  String get thursdayShort => 'Thu';

  @override
  String get fridayShort => 'Fri';

  @override
  String get saturdayShort => 'Sat';

  @override
  String get sundayShort => 'Sun';

  @override
  String get openLabel => 'Open';

  @override
  String get closeLabel => 'Close';

  @override
  String get closedLabel => 'Closed';

  @override
  String get copyToAllDays => 'Copy to all days';

  @override
  String get mediaTitle => 'Photos';

  @override
  String get logoLabel => 'Logo';

  @override
  String get logoHint => 'Upload your business logo';

  @override
  String get coverPhotoLabel => 'Cover photo (optional)';

  @override
  String get galleryLabel => 'Gallery (up to 8 photos)';

  @override
  String get tapToUpload => 'Tap to upload';

  @override
  String get removePhoto => 'Remove';

  @override
  String get descriptionTitle => 'Description';

  @override
  String get shopDescriptionLabel => 'Business description';

  @override
  String get shopDescriptionHint =>
      'Tell cyclists what makes your business special...';

  @override
  String get reviewTitle => 'Review & Submit';

  @override
  String get reviewSubtitle =>
      'Please review your information before submitting.';

  @override
  String get reviewBusinessInfo => 'Business Info';

  @override
  String get reviewLocation => 'Location';

  @override
  String get reviewServices => 'Services';

  @override
  String get reviewHours => 'Opening Hours';

  @override
  String get reviewPhotos => 'Photos';

  @override
  String get reviewDescription => 'Description';

  @override
  String get submittingProvider => 'Submitting...';

  @override
  String get providerSubmitSuccess =>
      'Your provider application has been submitted!';

  @override
  String get providerSubmitSuccessDetail =>
      'We\'ll review your information and get back to you soon.';

  @override
  String providerSubmitError(String error) {
    return 'Failed to submit: $error';
  }

  @override
  String get goToDashboard => 'Go to Dashboard';

  @override
  String get providerSection => 'Provider';

  @override
  String get providerSectionDescription => 'Manage your business on CYKEL';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String dashboardWelcome(String name) {
    return 'Welcome, $name';
  }

  @override
  String get dashboardVerificationBanner =>
      'Your account is pending verification.';

  @override
  String get dashboardRejectedBanner =>
      'Your application was rejected. Please update your details and resubmit.';

  @override
  String get dashboardOverview => 'Overview';

  @override
  String get dashboardProfileViews => 'Profile views';

  @override
  String get dashboardNavRequests => 'Navigation requests';

  @override
  String get dashboardSavedBy => 'Saved by users';

  @override
  String get dashboardQuickActions => 'Quick Actions';

  @override
  String get editBusinessInfo => 'Edit Business Info';

  @override
  String get manageHours => 'Manage Hours';

  @override
  String get managePhotos => 'Manage Photos';

  @override
  String get providerSettings => 'Settings';

  @override
  String get viewAnalytics => 'View Analytics';

  @override
  String get editProviderTitle => 'Edit Business';

  @override
  String get saving => 'Saving...';

  @override
  String get changesSaved => 'Changes saved successfully.';

  @override
  String changesSaveError(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get manageHoursTitle => 'Manage Opening Hours';

  @override
  String get hoursSaved => 'Opening hours updated.';

  @override
  String get managePhotosTitle => 'Manage Photos';

  @override
  String get currentLogo => 'Current logo';

  @override
  String get currentCover => 'Current cover photo';

  @override
  String get currentGallery => 'Current gallery';

  @override
  String get changeLogo => 'Change logo';

  @override
  String get changeCover => 'Change cover';

  @override
  String get addPhotos => 'Add photos';

  @override
  String get photosSaved => 'Photos updated.';

  @override
  String get uploading => 'Uploading...';

  @override
  String get settingsTitle => 'Provider Settings';

  @override
  String get activeStatusLabel => 'Listing active';

  @override
  String get activeStatusDesc =>
      'Your business is visible to cyclists on the map.';

  @override
  String get temporarilyClosedLabel => 'Temporarily closed';

  @override
  String get temporarilyClosedDesc =>
      'Show a closed notice without deactivating your listing.';

  @override
  String get specialNoticeLabel => 'Special notice';

  @override
  String get specialNoticeHint => 'e.g. Closed for renovation until March 30';

  @override
  String get specialNoticeSaved => 'Notice updated.';

  @override
  String get deleteProviderTitle => 'Delete Provider';

  @override
  String get deleteProviderConfirm =>
      'Are you sure you want to delete your provider listing? This action cannot be undone.';

  @override
  String get deleteProviderButton => 'Delete permanently';

  @override
  String get providerDeleted => 'Provider listing deleted.';

  @override
  String get analyticsTitle => 'Analytics';

  @override
  String get analyticsProfileViews => 'Profile Views';

  @override
  String get analyticsNavRequests => 'Navigation Requests';

  @override
  String get analyticsSavedBy => 'Times Saved';

  @override
  String get analyticsNoData => 'No analytics data yet.';

  @override
  String get noProviderFound =>
      'No provider record found. Please complete onboarding first.';

  @override
  String get status => 'Status';

  @override
  String get typeLabel => 'Type';

  @override
  String get layerCykelRepair => 'CYKEL Repair Shops';

  @override
  String get layerCykelShop => 'CYKEL Bike Shops';

  @override
  String get layerCykelCharging => 'CYKEL Charging';

  @override
  String get layerCykelService => 'CYKEL Service Points';

  @override
  String get layerCykelRental => 'CYKEL Rentals';

  @override
  String get cykelVerifiedProviders => 'Find providers on the map';

  @override
  String get cykelVerifiedSection => 'Verified Providers';

  @override
  String get cykelProviderNearby => 'Nearby CYKEL Providers';

  @override
  String get providerDetailGetDirections => 'Get directions';

  @override
  String get providerDetailCall => 'Call';

  @override
  String get providerDetailWebsite => 'Website';

  @override
  String get providerDetailSave => 'Save';

  @override
  String get providerDetailSaved => 'Saved';

  @override
  String get providerDetailOpen => 'Open now';

  @override
  String get providerDetailClosed => 'Closed';

  @override
  String get providerDetailVerified => 'Verified';

  @override
  String get providerDetailOpeningHours => 'Opening hours';

  @override
  String get providerDetailServices => 'Services';

  @override
  String get providerDetailProducts => 'Products';

  @override
  String get providerDetailCharging => 'Charging info';

  @override
  String providerDetailDistanceAway(String distance) {
    return '$distance away';
  }

  @override
  String providerDetailNoPorts(int count) {
    return '$count charging ports';
  }

  @override
  String get noProvidersNearby => 'No CYKEL providers nearby yet.';

  @override
  String get noChargingStationsNearby => 'No charging stations nearby yet.';

  @override
  String get viewAllProviders => 'View all on map';

  @override
  String get filterCykelRepair => 'Repair';

  @override
  String get filterCykelShop => 'Shops';

  @override
  String get filterCykelCharging => 'Charging';

  @override
  String get filterCykelService => 'Service';

  @override
  String get filterCykelRental => 'Rental';

  @override
  String get filterCykelAll => 'All CYKEL';

  @override
  String get listingBrandHint => 'Brand';

  @override
  String get listingIsElectric => 'Electric Bike';

  @override
  String get listingIsElectricHint => 'Toggle if this is an electric bicycle';

  @override
  String get listingSerialHint => 'Serial Number';

  @override
  String get listingSerialHelp =>
      'Adding a serial number helps verify authenticity and prevents stolen bikes from being sold.';

  @override
  String get listingElectricBadge => 'Electric';

  @override
  String get listingSerialVerified => 'Serial Verified';

  @override
  String get listingSerialDuplicate => 'Duplicate Serial';

  @override
  String get listingSerialUnverified => 'Serial Unverified';

  @override
  String get locationsTitle => 'Locations';

  @override
  String get noLocationsYet => 'No locations added yet';

  @override
  String get addLocation => 'Add Location';

  @override
  String get editLocationTitle => 'Edit Location';

  @override
  String get addLocationTitle => 'Add Location';

  @override
  String get locationNameSection => 'Location Name';

  @override
  String get locationNameLabel => 'Name';

  @override
  String get locationTypeLabel => 'Location Type';

  @override
  String get contactInfoSection => 'Contact Info';

  @override
  String get photosSection => 'Photos';

  @override
  String get locationSaved => 'Location saved!';

  @override
  String get deleteLocationTitle => 'Delete Location?';

  @override
  String get deleteLocationConfirm =>
      'Are you sure you want to delete this location? This cannot be undone.';

  @override
  String get pauseLabel => 'Pause';

  @override
  String get activateLabel => 'Activate';

  @override
  String get deleteLabel => 'Delete';

  @override
  String get manageLocations => 'Manage Locations';

  @override
  String get manageListings => 'Manage Listings';

  @override
  String get listingMarkAvailable => 'Mark as Available';

  @override
  String get listingStatusSold => 'Sold';

  @override
  String get listingStatusActive => 'Active';

  @override
  String get purchaseUnavailable => 'Purchase is currently unavailable';

  @override
  String get restorePurchases => 'Restore Purchases';

  @override
  String get restorePurchasesDone => 'Purchases restored';

  @override
  String get premiumFeatureBody =>
      'This feature is available with a Premium subscription.';

  @override
  String get routeEffort => 'Effort';

  @override
  String get darkRidingAlert => 'Dark riding';

  @override
  String get lowVisibility => 'Low visibility';

  @override
  String get chargeSuggestion => 'Consider charging before your ride';

  @override
  String get commuterTax => 'Commuter Tax Deduction';

  @override
  String get commuteDays => 'Commute days';

  @override
  String get commuteKm => 'Commute km';

  @override
  String get deductibleKm => 'Deductible km';

  @override
  String estimatedDeduction(String amount) {
    return 'Est. deduction: $amount DKK';
  }

  @override
  String estimatedTaxSavings(String amount) {
    return 'Est. tax savings: ~$amount DKK';
  }

  @override
  String get taxDeductionInfo => 'Tax Deduction Info';

  @override
  String get yearToDate => 'Year-to-Date';

  @override
  String get howItWorks => 'How It Works';

  @override
  String get rateBreakdown => 'Rate Breakdown';

  @override
  String get exportForTaxFiling => 'Export for Tax Filing';

  @override
  String get learnMore => 'Learn More';

  @override
  String get noCommuteTripsYet => 'No Commute Trips Yet';

  @override
  String get setHomeWorkAddresses =>
      'Set your home and work addresses to start tracking commute tax deductions';

  @override
  String get configure => 'Configure';

  @override
  String get failedToLoad => 'Failed to load';

  @override
  String get hazardThunderstorm => 'Thunderstorm';

  @override
  String get batteryCapacity => 'Battery capacity';

  @override
  String get alertHeavyRainTitle => 'Heavy Rain Warning';

  @override
  String alertHeavyRainMessage(String amount) {
    return 'Heavy rain detected (${amount}mm/h). Consider indoor activities.';
  }

  @override
  String get alertStrongWindTitle => 'Strong Wind Warning';

  @override
  String alertStrongWindMessage(String speed) {
    return 'Winds up to $speed km/h. Ride with caution.';
  }

  @override
  String get alertIceRiskTitle => 'Ice Risk Warning';

  @override
  String get alertIceRiskMessage =>
      'Freezing temperatures with precipitation. Roads may be icy.';

  @override
  String get alertExtremeColdTitle => 'Extreme Cold Warning';

  @override
  String alertExtremeColdMessage(String temp) {
    return 'Temperature is $temp°C. Dress warmly and consider shorter rides.';
  }

  @override
  String get alertHighWindsTitle => 'High Wind Warning';

  @override
  String alertHighWindsMessage(String speed) {
    return 'Very strong winds ($speed km/h). Not recommended for cycling.';
  }

  @override
  String get alertFogTitle => 'Fog Warning';

  @override
  String get alertFogMessage =>
      'Reduced visibility due to fog. Use lights and reflective gear.';

  @override
  String get alertDarknessTitle => 'Dark Riding';

  @override
  String get alertDarknessMessage =>
      'It is currently dark. Use front and rear lights, wear reflective gear.';

  @override
  String get alertSunsetTitle => 'Sunset Approaching';

  @override
  String alertSunsetMessage(String time) {
    return 'Sunset at $time. Bring lights.';
  }

  @override
  String get alertWinterIceTitle => 'Winter Ice Risk';

  @override
  String get alertWinterIceMessage =>
      'Temperature near freezing with moisture. Watch for ice on bridges and shaded paths.';

  @override
  String get severityInfo => 'Info';

  @override
  String get severityCaution => 'Caution';

  @override
  String get severityDanger => 'Danger';

  @override
  String get statusReported => 'Reported';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusUnderReview => 'Under Review';

  @override
  String get statusResolved => 'Resolved';

  @override
  String credibilityLabel(String score, String confirms, String dismisses) {
    return 'Credibility: $score% ($confirms ✓  $dismisses ✗)';
  }

  @override
  String get commuterTaxSettings => 'Commuter Tax';

  @override
  String get commuterTaxTitle => 'Commuter Tax Settings';

  @override
  String get commuterTaxDescription =>
      'Set your home and work addresses to calculate the Danish commuter tax deduction for your rides.';

  @override
  String get homeAddress => 'Home Address';

  @override
  String get workAddress => 'Work Address';

  @override
  String get savedSuccessfully => 'Saved successfully';

  @override
  String get confirmAction => 'Confirm Action';

  @override
  String get confirmMaintenanceReset =>
      'Are you sure you want to mark maintenance as complete? This will reset your service reminder.';

  @override
  String get maintenanceMarkedDone => 'Maintenance marked as complete';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get goHome => 'Go home';

  @override
  String get tryAgain => 'Try again';

  @override
  String get validationEmailRequired => 'Email is required';

  @override
  String get validationEmailInvalid => 'Enter a valid email address';

  @override
  String get validationPasswordRequired => 'Password is required';

  @override
  String get validationPasswordTooShort =>
      'Password must be at least 8 characters';

  @override
  String get validationConfirmPasswordRequired =>
      'Please confirm your password';

  @override
  String get validationPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get validationNameRequired => 'Name is required';

  @override
  String get validationNameTooShort => 'Name is too short';

  @override
  String get validationPhoneInvalid => 'Enter a valid Danish phone number';

  @override
  String get validationPostalCodeRequired => 'Postal code is required';

  @override
  String get validationPostalCodeInvalid => 'Enter a valid 4-digit postal code';

  @override
  String get validationPostalCodeRange =>
      'Postal code must be between 1000 and 9990';

  @override
  String validationFieldRequired(String field) {
    return '$field is required';
  }

  @override
  String get validationPriceRequired => 'Price is required';

  @override
  String get validationPriceInvalid => 'Enter a valid price';

  @override
  String get validationPriceTooHigh => 'Price is too high';

  @override
  String get validationSerialTooShort => 'Serial number is too short';

  @override
  String get validationSerialTooLong => 'Serial number is too long';

  @override
  String get validationUrlInvalid => 'Enter a valid URL (https://...)';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get goBack => 'Go back';

  @override
  String get close => 'Close';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get swapLocations => 'Swap locations';

  @override
  String get openChats => 'Open chats';

  @override
  String get removeFromSaved => 'Remove from saved';

  @override
  String get saveListing => 'Save listing';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get settings => 'Settings';

  @override
  String get share => 'Share';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get search => 'Search';

  @override
  String get joinChallenge => 'Join challenge';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get refresh => 'Refresh';

  @override
  String get sendComment => 'Send comment';

  @override
  String get friendRequests => 'Friend requests';

  @override
  String get searchUsers => 'Search users';

  @override
  String get like => 'Like';

  @override
  String get comment => 'Comment';

  @override
  String get comments => 'Comments';

  @override
  String get download => 'Download';

  @override
  String errorPrefix(String error) {
    return 'Error';
  }

  @override
  String get groupRides => 'Group Rides';

  @override
  String get eventsTabAll => 'All';

  @override
  String get eventsTabMine => 'My Events';

  @override
  String get eventsTabCreated => 'Created';

  @override
  String get createEvent => 'Create Ride';

  @override
  String get discoverGroupRides => 'DISCOVER';

  @override
  String get popularEvents => 'Popular Rides';

  @override
  String get upcomingEvents => 'Upcoming';

  @override
  String get viewAll => 'View all';

  @override
  String get noUpcomingEvents => 'No upcoming rides';

  @override
  String get beFirstToCreate => 'Be the first to create a group ride!';

  @override
  String get noJoinedEvents => 'No joined rides';

  @override
  String get joinEventToSeeHere => 'Join a ride to see them here';

  @override
  String get noCreatedEvents => 'No created rides';

  @override
  String get createYourFirstEvent => 'Create your first group ride!';

  @override
  String get joinedBadge => 'Joined';

  @override
  String get organizerBadge => 'Organizer';

  @override
  String get noDropTooltip => 'No-drop: Group waits for everyone';

  @override
  String get todayBadge => 'Today';

  @override
  String get searchEvents => 'Search for rides...';

  @override
  String get searchEventsHint => 'Search rides by name';

  @override
  String get noEventsFound => 'No rides found';

  @override
  String get eventError => 'Error';

  @override
  String get eventNotFound => 'Not found';

  @override
  String get eventNotFoundMessage => 'The event was not found';

  @override
  String get editEvent => 'Edit';

  @override
  String get cancelEvent => 'Cancel';

  @override
  String get deleteEvent => 'Delete';

  @override
  String get dateAndTime => 'Date and time';

  @override
  String get timePrefix => 'At';

  @override
  String estimatedDuration(String hours) {
    return 'Estimated duration: $hours hours';
  }

  @override
  String get meetingPoint => 'Meeting point';

  @override
  String get navigateToMeetingPoint => 'Navigate';

  @override
  String get eventDescription => 'Description';

  @override
  String get rideDetails => 'Details';

  @override
  String get kmUnit => 'km';

  @override
  String get kmhUnit => 'km/h';

  @override
  String get elevationUnit => 'm elevation';

  @override
  String get lightsRequired => 'Lights required';

  @override
  String get eventOrganizer => 'Organizer';

  @override
  String get organizerLabel => 'Organizer';

  @override
  String get participants => 'Participants';

  @override
  String get peopleJoined => 'people joined';

  @override
  String get noParticipantsYet => 'No participants yet';

  @override
  String get eventFull => 'Full';

  @override
  String get openChat => 'Open chat';

  @override
  String get leaveEvent => 'Leave';

  @override
  String get chat => 'Chat';

  @override
  String get eventIsFull => 'Event is full';

  @override
  String get joinEvent => 'Join';

  @override
  String get discoverEvents => 'Discover';

  @override
  String get youAreJoined => 'You are now joined!';

  @override
  String get youAreLeft => 'You have left the event';

  @override
  String get chatComingSoon => 'Chat coming soon!';

  @override
  String get eventCancelled => 'Event cancelled';

  @override
  String get eventDeleted => 'Event deleted';

  @override
  String get leaveEventQuestion => 'Leave event?';

  @override
  String get leaveEventConfirm => 'Are you sure you want to leave this ride?';

  @override
  String get cancelEventQuestion => 'Cancel event?';

  @override
  String get cancelEventConfirm =>
      'Are you sure you want to cancel this ride? All participants will be notified.';

  @override
  String get deleteEventQuestion => 'Delete event?';

  @override
  String get deleteEventConfirm =>
      'Are you sure you want to delete this ride? This cannot be undone.';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get confirmCancel => 'Cancel Event';

  @override
  String get confirmDelete => 'Delete';

  @override
  String get shareEventText => 'Join in the CYKEL app!';

  @override
  String get repeatsLabel => 'Repeats';

  @override
  String get noDropPolicy => 'No-drop policy';

  @override
  String get noDropDescription => 'Group waits for everyone';

  @override
  String get createGroupRide => 'Create Group Ride';

  @override
  String get basicInfo => 'Basic Info';

  @override
  String get eventTitle => 'Title *';

  @override
  String get eventTitleHint => 'e.g. Sunday Morning Group Ride';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get eventDescriptionLabel => 'Description';

  @override
  String get eventDescriptionHint => 'Describe the ride...';

  @override
  String get eventType => 'Type';

  @override
  String get difficultyLevel => 'Difficulty';

  @override
  String get dateAndTimeSection => 'Date and Time';

  @override
  String get dateLabel => 'Date';

  @override
  String get meetingPointSection => 'Meeting Point';

  @override
  String get placeNameHint => 'e.g. Copenhagen City Hall';

  @override
  String get address => 'Address *';

  @override
  String get addressHint => 'Search for address...';

  @override
  String get addressRequired => 'Address is required';

  @override
  String get searchingAddress => 'Searching...';

  @override
  String get rideDetailsSection => 'Ride Details';

  @override
  String get distanceKm => 'Distance (km)';

  @override
  String get durationMin => 'Duration (min)';

  @override
  String get paceKmh => 'Pace (km/h)';

  @override
  String get elevationGainM => 'Elevation gain (m)';

  @override
  String get maxParticipants => 'Max participants';

  @override
  String get settingsSection => 'Settings';

  @override
  String get lightsRequiredToggle => 'Lights required';

  @override
  String get lightsRequiredDescription => 'For evening/night rides';

  @override
  String get visibility => 'Visibility';

  @override
  String get visibilityPublic => 'Public';

  @override
  String get visibilityPrivate => 'Private';

  @override
  String get createEventButton => 'Create Group Ride';

  @override
  String get couldNotFindCoordinates => 'Could not find coordinates';

  @override
  String get noAddressesFound => 'No addresses found';

  @override
  String get searchForAddressFirst => 'Search for an address first';

  @override
  String get mustBeLoggedIn => 'You must be logged in';

  @override
  String get eventCreated => 'Group ride created!';

  @override
  String get couldNotFindAddress => 'Could not find address';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyModerate => 'Moderate';

  @override
  String get difficultyChallenging => 'Challenging';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get eventTypeSocial => 'Social';

  @override
  String get eventTypeTraining => 'Training';

  @override
  String get eventTypeCommute => 'Commute';

  @override
  String get eventTypeTour => 'Tour';

  @override
  String get eventTypeRace => 'Race';

  @override
  String get eventTypeGravel => 'Gravel';

  @override
  String get eventTypeMtb => 'MTB';

  @override
  String get eventTypeBeginner => 'Beginner';

  @override
  String get eventTypeFamily => 'Family';

  @override
  String get eventTypeNight => 'Night';

  @override
  String get visibilityFriends => 'Friends only';

  @override
  String get visibilityInviteOnly => 'Invite only';

  @override
  String get eventStatusUpcoming => 'Upcoming';

  @override
  String get eventStatusActive => 'Active';

  @override
  String get eventStatusCompleted => 'Completed';

  @override
  String get eventStatusCancelled => 'Cancelled';

  @override
  String get eventDateTimePast => 'Event date/time cannot be in the past';

  @override
  String get challenges => 'Challenges';

  @override
  String get yourActiveChallenges => 'Your active challenges';

  @override
  String get availableChallenges => 'Available challenges';

  @override
  String joinedChallenge(String title) {
    return 'You are now in \"$title\"!';
  }

  @override
  String get level => 'Level';

  @override
  String get points => 'Points';

  @override
  String get badges => 'Badges';

  @override
  String levelProgress(int current, int next) {
    return 'Level $current → Level $next';
  }

  @override
  String pointsToNextLevel(int points) {
    return '$points points to next level';
  }

  @override
  String get challengeTypeDistance => 'Distance';

  @override
  String get challengeTypeRideCount => 'Ride Count';

  @override
  String get challengeTypeElevation => 'Elevation';

  @override
  String get challengeTypeStreak => 'Streak';

  @override
  String get challengeTypeCommunity => 'Community';

  @override
  String get challengeTypeSpeed => 'Speed';

  @override
  String get challengeTypeExplore => 'Explore';

  @override
  String challengePoints(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'points',
      one: 'point',
    );
    return '$points $_temp0';
  }

  @override
  String get difficultyLevelEasy => 'Easy';

  @override
  String get difficultyLevelMedium => 'Medium';

  @override
  String get difficultyLevelHard => 'Hard';

  @override
  String get difficultyLevelExtreme => 'Extreme';

  @override
  String get badgesTitle => 'Badges';

  @override
  String badgesEarnedOf(int earned, int total) {
    return '$earned of $total';
  }

  @override
  String get badgesEarned => 'badges earned';

  @override
  String percentComplete(String percent) {
    return '$percent% complete';
  }

  @override
  String get badgeEarned => 'Earned!';

  @override
  String get badgeKeepRiding => 'Keep riding to earn this badge!';

  @override
  String get rarityCommon => 'Common';

  @override
  String get rarityUncommon => 'Uncommon';

  @override
  String get rarityRare => 'Rare';

  @override
  String get rarityEpic => 'Epic';

  @override
  String get rarityLegendary => 'Legendary';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get leaderboardYou => 'You';

  @override
  String get noDataYet => 'No data yet';

  @override
  String get startRidingToJoin => 'Start riding to join the leaderboard!';

  @override
  String get periodThisWeek => 'This Week';

  @override
  String get periodThisMonth => 'This Month';

  @override
  String get periodAllTime => 'All Time';

  @override
  String get buddyFindRidingBuddies => 'Find Riding Buddies';

  @override
  String get buddyTabForYou => 'For You';

  @override
  String get buddyTabRequests => 'Requests';

  @override
  String get buddyTabMatches => 'Matches';

  @override
  String get buddyFilters => 'Filters';

  @override
  String get buddyRidingLevel => 'Riding Level';

  @override
  String get buddyAllLevels => 'All Levels';

  @override
  String get buddyInterests => 'Interests';

  @override
  String get buddyCreateProfile => 'Create Your Buddy Profile';

  @override
  String get buddyCreateProfileDesc =>
      'Set up your riding profile to find compatible cycling partners';

  @override
  String get buddyCreateProfileButton => 'Create Profile';

  @override
  String get buddyNoMatchesFound => 'No Matches Found';

  @override
  String get buddyNoMatchesFoundDesc =>
      'Try adjusting your preferences or check back later';

  @override
  String get buddyNoPendingRequests => 'No Pending Requests';

  @override
  String get buddyNoPendingRequestsDesc => 'Match requests will appear here';

  @override
  String get buddyNoMatchesYet => 'No Matches Yet';

  @override
  String get buddyConnectInForYou =>
      'Start connecting with riders in the \"For You\" tab';

  @override
  String get buddyAbout => 'About';

  @override
  String get buddyStats => 'Stats';

  @override
  String get buddyAvailability => 'Availability';

  @override
  String get buddyLanguages => 'Languages';

  @override
  String get buddyClose => 'Close';

  @override
  String get buddySendRequest => 'Send Request';

  @override
  String buddyMatchRequestSent(String name) {
    return 'Match request sent to $name!';
  }

  @override
  String get buddyDecline => 'Decline';

  @override
  String get buddyAccept => 'Accept';

  @override
  String get buddyMatchAccepted => 'Match accepted!';

  @override
  String get buddyRequestDeclined => 'Request declined';

  @override
  String get buddyChatComingSoon => 'Chat coming soon';

  @override
  String get rentalSectionBasicInfo => 'Basic Information';

  @override
  String get rentalSectionDetails => 'Details (Optional)';

  @override
  String get rentalSectionPricing => 'Pricing';

  @override
  String get rentalSectionFeatures => 'Features';

  @override
  String get rentalSectionLocation => 'Location';

  @override
  String get rentalSectionAvailability => 'Availability';

  @override
  String get rentalSectionAdditionalInfo => 'Additional Information';

  @override
  String get rentalSectionPhotos => 'Photos';

  @override
  String get rentalAddPhotos => 'Add Photos';

  @override
  String get rentalNoPhotos => 'No photos added yet';

  @override
  String get rentalAvailableFrom => 'Available From';

  @override
  String get rentalAvailableTo => 'Available To';

  @override
  String get rentalNoStartDate => 'No start date (available immediately)';

  @override
  String get rentalNoEndDate => 'No end date (available indefinitely)';

  @override
  String get rentalSelectDates => 'Please select start and end dates/times';

  @override
  String get rentalLocationSet => 'Location set to Copenhagen (picker pending)';

  @override
  String get rentalSelectLocation => 'Please select a pickup location';

  @override
  String rentalErrorSaving(String error) {
    return 'Error saving listing: $error';
  }

  @override
  String get rentalDescription => 'Description';

  @override
  String get rentalDetails => 'Details';

  @override
  String get rentalTerms => 'Rental Terms';

  @override
  String rentalReviews(int count) {
    return 'Reviews ($count)';
  }

  @override
  String get rentalConfirmRequest => 'Confirm Rental Request';

  @override
  String rentalBikeLabel(String title) {
    return 'Bike: $title';
  }

  @override
  String get rentalRequestSent =>
      'Rental request sent! Owner will be notified.';

  @override
  String get rentalListingNotFound => 'Listing not found';

  @override
  String get rentalRequestButton => 'Request Rental';

  @override
  String get rentalRentABike => 'Rent a Bike';

  @override
  String get rentalListYourBike => 'List Your Bike';

  @override
  String get rentalClear => 'Clear';

  @override
  String get rentalApplyFilters => 'Apply Filters';

  @override
  String get rentalFilterBikeType => 'Bike Type';

  @override
  String get rentalFilterSize => 'Size';

  @override
  String get rentalFilterMaxPrice => 'Maximum Price';

  @override
  String get rentalFilterFeatures => 'Features';

  @override
  String get rentalFilterHelmet => 'Helmet included';

  @override
  String get rentalFilterLock => 'Lock included';

  @override
  String get rentalFilterFrom => 'From';

  @override
  String get rentalEndAfterStart => 'End time must be after start time';

  @override
  String get eventsApplyFilter => 'Apply Filter';

  @override
  String get eventsError => 'Error loading events';

  @override
  String get chatDeleteConversation => 'Delete Conversation';

  @override
  String get chatMessages => 'Messages';

  @override
  String get chatErrorLoading => 'Error loading conversations';

  @override
  String chatErrorLoadingMessages(String error) {
    return 'Error loading messages: $error';
  }

  @override
  String get chatSendPhoto => 'Send Photo';

  @override
  String get chatShareLocation => 'Share Location';

  @override
  String get chatDeleteConversationTitle => 'Delete Conversation';

  @override
  String get chatLoading => 'Loading...';

  @override
  String get routesCreateRoute => 'Create Route';

  @override
  String get routesCreate => 'Create';

  @override
  String get routesOptimizeRoute => 'Optimize Route';

  @override
  String get routesMinTwoWaypoints => 'Route must have at least 2 waypoints';

  @override
  String get routesEnterName => 'Please enter a route name';

  @override
  String get routesCreatedSuccess => 'Route created successfully!';

  @override
  String routesErrorCreating(String error) {
    return 'Error creating route: $error';
  }

  @override
  String get routesRoundTrip => 'Round Trip';

  @override
  String get routesRoundTripDesc => 'Route returns to start';

  @override
  String get routesCalculateElevation => 'Calculate Elevation';

  @override
  String get routesCalculateElevationDesc => 'Include elevation profile';

  @override
  String get routesFetchWeather => 'Fetch Weather';

  @override
  String get routesFetchWeatherDesc => 'Get current weather data';

  @override
  String get routesAddTag => 'Add Tag';

  @override
  String get routesEditWaypoint => 'Edit Waypoint';

  @override
  String get routesMyRoutes => 'My Routes';

  @override
  String routesErrorLoadingRoutes(String error) {
    return 'Error loading routes: $error';
  }

  @override
  String get routesRetry => 'Retry';

  @override
  String get routesFilterByTag => 'Filter by Tag';

  @override
  String get routesAllRoutes => 'All Routes';

  @override
  String get routesDeleteRoute => 'Delete Route';

  @override
  String get routesDeleteConfirm =>
      'Are you sure you want to delete this route?';

  @override
  String get routesEditRoute => 'Edit Route';

  @override
  String get routesRouteNotFound => 'Route not found';

  @override
  String get routesNoElevationData => 'No elevation data available';

  @override
  String get routesNoWeatherData => 'No weather data available';

  @override
  String get routesFailedLoadWeather => 'Failed to load weather';

  @override
  String get routesNoRecommendations => 'No recommendations available';

  @override
  String get routesFailedLoadRecommendations =>
      'Failed to load recommendations';

  @override
  String get familyMap => 'Family Map';

  @override
  String get familyNoAccount => 'No family account found';

  @override
  String get familySendSOSAlert => 'Send SOS Alert?';

  @override
  String get familySendSOS => 'Send SOS';

  @override
  String get familySOSSent => 'SOS alert sent to your family!';

  @override
  String familySOSFailed(String error) {
    return 'Failed to send SOS: $error';
  }

  @override
  String get familyCheckout => 'Checkout';

  @override
  String get familyAddPayment => 'Add Payment Method';

  @override
  String get familyPaymentError => 'Could not load payment methods';

  @override
  String get familyGetStarted => 'Get Started';

  @override
  String get familyNoRidesYet => 'No rides yet';

  @override
  String get familyNoRecentAlerts => 'No recent alerts';

  @override
  String get familyAchievements => 'Achievements';

  @override
  String get familyCreateChallenge => 'Create New Challenge';

  @override
  String get familyChallengeCreated => 'Challenge created!';

  @override
  String get expatSafetyEquipment => 'Safety Equipment';

  @override
  String expatNoGuideAvailable(String type) {
    return 'No $type guide available';
  }

  @override
  String expatErrorLoading(String error) {
    return 'Error loading guide: $error';
  }

  @override
  String get expatCyclingLaws => 'Cycling Laws';

  @override
  String get expatCultureEtiquette => 'Culture & Etiquette';

  @override
  String get expatCommute => 'Commute';

  @override
  String get expatNoRoutesAvailable => 'No routes available';

  @override
  String get expatBikeShops => 'Bike Shops';

  @override
  String get expatAllShops => 'All Shops';

  @override
  String get expatExpatFriendly => 'Expat-Friendly Only';

  @override
  String get expatRepairServices => 'Repair Services';

  @override
  String get expatSales => 'Sales';

  @override
  String get expatNoShopsFound => 'No shops found';

  @override
  String get expatCall => 'Call';

  @override
  String get expatWebsite => 'Website';

  @override
  String get expatHubTitle => 'Expat Hub';

  @override
  String get expatExploreResources => 'Explore Resources';

  @override
  String get expatFeaturedGuides => 'Featured Guides';

  @override
  String get expatQuickTips => 'Quick Tips';

  @override
  String get expatNoFeaturedGuides => 'No featured guides yet';

  @override
  String get expatNoTipsAvailable => 'No tips available';

  @override
  String get expatErrorLoadingGuides => 'Error loading guides';

  @override
  String get expatErrorLoadingTips => 'Error loading tips';

  @override
  String get eventsTrendingNow => 'Trending Now';

  @override
  String get familyDashboardTitle => 'Dashboard';

  @override
  String get familyNoPlan => 'No family plan found';

  @override
  String get commonShowAll => 'Show All';

  @override
  String get commonClearAll => 'Clear All';

  @override
  String get commonOpenNowOnly => 'Open now only';

  @override
  String get commonStartHere => 'Start Here';

  @override
  String get commonGoHere => 'Go Here';

  @override
  String get commonHoldSOS => 'Hold the SOS button for 2 seconds';

  @override
  String get bikeMaintenanceTitle => 'Maintenance';

  @override
  String get serviceHistory => 'Service History';

  @override
  String get addService => 'Add Service';

  @override
  String get bikeCondition => 'Bike condition';

  @override
  String get kmRidden => 'km ridden';

  @override
  String get overdueAlert => 'Overdue';

  @override
  String get dueSoonAlert => 'Due soon';

  @override
  String get noServiceHistory => 'No service history yet';

  @override
  String get addFirstService => 'Add your first service to track maintenance';

  @override
  String get serviceType => 'Type';

  @override
  String get serviceDate => 'Date';

  @override
  String get serviceKilometers => 'Kilometers at service';

  @override
  String get servicePriceOptional => 'Price (optional)';

  @override
  String get serviceShopOptional => 'Shop/Workshop (optional)';

  @override
  String get serviceNotesOptional => 'Notes (optional)';

  @override
  String get enterKilometers => 'Enter kilometers';

  @override
  String get invalidValue => 'Invalid value';

  @override
  String get saveButton => 'Save';

  @override
  String get deleteService => 'Delete service?';

  @override
  String get deleteServiceConfirm =>
      'Are you sure you want to delete this service?';

  @override
  String get kilometers => 'Kilometers';

  @override
  String get price => 'Price';

  @override
  String get workshop => 'Workshop';

  @override
  String get notes => 'Notes';

  @override
  String get nextService => 'Next service';

  @override
  String get notLoggedIn => 'Not logged in';

  @override
  String currencyDkk(String amount) {
    return '$amount DKK';
  }

  @override
  String get serviceTypeTireChange => 'Tire Change';

  @override
  String get serviceTypeBrakes => 'Brakes';

  @override
  String get serviceTypeChain => 'Chain';

  @override
  String get serviceTypeGears => 'Gears';

  @override
  String get serviceTypeFullService => 'Full Service';

  @override
  String get serviceTypeLights => 'Lights';

  @override
  String get serviceTypeWheels => 'Wheels';

  @override
  String get serviceTypeOther => 'Other';

  @override
  String get community => 'Community';

  @override
  String get theftAlerts => 'Theft Alerts';

  @override
  String get theftNearby => 'Nearby';

  @override
  String get theftAll => 'All';

  @override
  String get theftMine => 'Mine';

  @override
  String get theftReport => 'Report theft';

  @override
  String theftError(String error) {
    return 'Error: $error';
  }

  @override
  String get theftNoNearby => 'No thefts nearby';

  @override
  String theftNoNearbyDesc(String radius) {
    return 'There are no active theft reports within $radius km';
  }

  @override
  String get theftNoActive => 'No active reports';

  @override
  String get theftNoActiveDesc => 'There are no active theft reports right now';

  @override
  String get theftNoReports => 'No reports';

  @override
  String get theftNoReportsDesc => 'You haven\'t reported any bike thefts';

  @override
  String theftMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String theftHoursAgo(int hours) {
    return '$hours hours ago';
  }

  @override
  String theftDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get theftReportTitle => 'Report bike theft';

  @override
  String get theftNoBikes =>
      'You have no registered bikes. Add your bike first under \"My Bikes\".';

  @override
  String get theftSelectBike => 'Select bike';

  @override
  String get theftSelectBikeError => 'Select a bike';

  @override
  String get theftCouldNotLoadBikes => 'Could not load bikes';

  @override
  String get theftBikeDescription => 'Bike description';

  @override
  String get theftBikeDescriptionHint => 'Color, size, special features...';

  @override
  String get theftDescriptionRequired => 'Enter description';

  @override
  String get theftFrameNumber => 'Frame number (optional)';

  @override
  String get theftArea => 'Area (e.g. Nørrebro)';

  @override
  String get theftAdditionalNotes => 'Additional information (optional)';

  @override
  String get theftAdditionalNotesHint => 'When/where did you last see it...';

  @override
  String get theftContactInfo => 'Contact info (optional)';

  @override
  String get theftContactInfoHint => 'Phone or email';

  @override
  String get theftNotLoggedIn => 'Not logged in';

  @override
  String get theftReportSuccess =>
      'Theft reported! Other cyclists will be alerted.';

  @override
  String get theftAreaLabel => 'Area';

  @override
  String get theftFrameNumberLabel => 'Frame number';

  @override
  String get theftNotesLabel => 'Notes';

  @override
  String get theftContactLabel => 'Contact';

  @override
  String get theftMarkRecovered => 'Mark as recovered';

  @override
  String get theftCloseReport => 'Close report';

  @override
  String get theftSeenThisBike => 'I\'ve seen this bike!';

  @override
  String get theftRecoveredSuccess =>
      'Congratulations! Your bike is marked as recovered.';

  @override
  String get theftSightingThanks => 'Thanks! The owner will be notified.';

  @override
  String get theftAlarmSettings => 'Alarm settings';

  @override
  String get theftEnableAlarms => 'Enable alarms';

  @override
  String get theftRadius => 'Radius';

  @override
  String theftRadiusKm(String radius) {
    return '$radius km';
  }

  @override
  String get theftNewThefts => 'New thefts';

  @override
  String get theftNewTheftsDesc =>
      'Get notified when a bike is reported stolen';

  @override
  String get theftSightings => 'Sightings';

  @override
  String get theftSightingsDesc =>
      'Get notified when someone has seen a stolen bike';

  @override
  String get theftRecoveries => 'Recovered bikes';

  @override
  String get theftRecoveriesDesc => 'Get notified when a bike is recovered';

  @override
  String get theftStatusActive => 'Active';

  @override
  String get theftStatusRecovered => 'Recovered';

  @override
  String get theftStatusClosed => 'Closed';

  @override
  String get aiRouteSuggestions => 'AI Route Suggestions';

  @override
  String get offlineMaps => 'Offline Maps';

  @override
  String get chooseTheme => 'Choose Theme';

  @override
  String get lightTheme => 'Light theme';

  @override
  String get darkTheme => 'Dark theme';

  @override
  String get systemTheme => 'System theme';

  @override
  String get autoTheme => 'Auto (sunrise/sunset)';

  @override
  String get followsDeviceSettings => 'Follows device settings';

  @override
  String get automatic => 'Automatic';

  @override
  String get changesAtSunriseSunset => 'Changes at sunrise/sunset';

  @override
  String get dataExportTitle => 'CYKEL Data Export';

  @override
  String get dataExportSubject => 'Your complete CYKEL data export';

  @override
  String get speedUnit => 'km/h';

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}min';
  }

  @override
  String get socialActivityTab => 'Activity';

  @override
  String get socialFriendsTab => 'Friends';

  @override
  String get socialMyRidesTab => 'My Rides';

  @override
  String socialErrorLoading(String error) {
    return 'Error: $error';
  }

  @override
  String get socialNoActivity => 'No activity yet';

  @override
  String get socialAddFriends => 'Add friends to see their rides';

  @override
  String get socialNoFriends => 'No friends yet';

  @override
  String get socialSearchCyclists =>
      'Search for other cyclists and add them as friends';

  @override
  String get socialNoSharedRides => 'No shared rides';

  @override
  String get socialShareRides => 'Share your bike rides with friends';

  @override
  String socialTotalKm(String km) {
    return '$km km total';
  }

  @override
  String get socialRemoveFriend => 'Remove friend';

  @override
  String get socialRemoveFriendQuestion => 'Remove friend?';

  @override
  String socialConfirmRemoveFriend(String name) {
    return 'Are you sure you want to remove $name as a friend?';
  }

  @override
  String get socialRemove => 'Remove';

  @override
  String get socialFriendRemoved => 'Friend removed';

  @override
  String socialMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String socialHoursAgo(int hours) {
    return '$hours hours ago';
  }

  @override
  String socialDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get socialDeleteRideQuestion => 'Delete shared ride?';

  @override
  String get socialConfirmDeleteRide =>
      'Are you sure you want to delete this shared ride?';

  @override
  String get socialReceived => 'Received';

  @override
  String get socialNoRequests => 'No requests';

  @override
  String get socialSent => 'Sent';

  @override
  String get socialNoSentRequests => 'No sent requests';

  @override
  String get socialFriendAdded => 'Friend added!';

  @override
  String get socialFindCyclists => 'Find Cyclists';

  @override
  String get socialSearchByName => 'Search by name...';

  @override
  String get socialAdd => 'Add';

  @override
  String get socialFriendRequestSent => 'Friend request sent!';

  @override
  String get socialNoComments => 'No comments yet';

  @override
  String get socialWriteComment => 'Write a comment...';

  @override
  String socialMinutesAgoShort(int minutes) {
    return '${minutes}m';
  }

  @override
  String socialHoursAgoShort(int hours) {
    return '${hours}h';
  }

  @override
  String socialDaysAgoShort(int days) {
    return '${days}d';
  }

  @override
  String get routeSuggestions => 'Route Suggestions';

  @override
  String get routeSuggestionsTab => 'Suggestions';

  @override
  String get routeHistoryTab => 'History';

  @override
  String get routeSavedTab => 'Saved';

  @override
  String get routeNoSuggestions => 'No suggestions yet';

  @override
  String get routeNoSuggestionsDesc =>
      'Use the app to cycle some trips, and we\'ll learn your preferences';

  @override
  String get routeAiTitle => 'AI Route Suggestions';

  @override
  String get routeAiDesc => 'Based on your habits, weather and time';

  @override
  String get routeNoHistory => 'No route history';

  @override
  String get routeNoHistoryDesc => 'Your most used routes will appear here';

  @override
  String routeStatsPattern(int duration, String lastUsed) {
    return '~$duration min • Last: $lastUsed';
  }

  @override
  String get routeDefaultName => 'Route';

  @override
  String routeMinutesAgo(int minutes) {
    return '$minutes min';
  }

  @override
  String routeHoursAgo(int hours) {
    return '$hours hours';
  }

  @override
  String routeDaysAgo(int days) {
    return '$days days';
  }

  @override
  String get routeNoSaved => 'No saved routes';

  @override
  String get routeNoSavedDesc => 'Save your favorite routes for quick access';

  @override
  String get routeSettings => 'Route Settings';

  @override
  String get routePreferences => 'Preferences';

  @override
  String get routeAvoidHills => 'Avoid hills';

  @override
  String get routeAvoidHillsDesc => 'Suggest flatter routes';

  @override
  String get routePreferBikeLanes => 'Prefer bike lanes';

  @override
  String get routePreferBikeLanesDesc => 'Prioritize routes with bike lanes';

  @override
  String get routePreferLitRoutes => 'Prefer lit routes';

  @override
  String get routePreferLitRoutesDesc => 'Prioritize well-lit routes at night';

  @override
  String get routeAiSuggestions => 'AI Suggestions';

  @override
  String get routeBasedOnHistory => 'Based on history';

  @override
  String get routeBasedOnHistoryDesc => 'Use your previous trips';

  @override
  String get routeBasedOnWeather => 'Based on weather';

  @override
  String get routeBasedOnWeatherDesc => 'Adapt suggestions to weather';

  @override
  String get routeBasedOnTime => 'Based on time';

  @override
  String get routeBasedOnTimeDesc => 'Adapt suggestions to time of day';

  @override
  String get exportSubject => 'CYKEL Data Export';

  @override
  String get exportMessage => 'Your complete CYKEL data export';

  @override
  String get notLoggedInError => 'Not logged in';

  @override
  String get notSet => 'Not set';

  @override
  String get authenticateBiometric => 'Authenticate to enable biometric lock';

  @override
  String get biometricAuthFailed =>
      'Authentication failed. Biometric lock not enabled.';

  @override
  String get biometricEnabled => 'Biometric lock enabled';

  @override
  String get biometricDisabled => 'Biometric lock disabled';

  @override
  String lockWith(String type) {
    return 'Lock with $type';
  }

  @override
  String get biometricLockDesc => 'Require authentication when opening app';

  @override
  String get offlineMapsTitle => 'Offline Maps';

  @override
  String get downloadedRegions => 'Downloaded Regions';

  @override
  String get availableRegions => 'Available Regions';

  @override
  String get downloadMapsForOfflineNav =>
      'Download maps to use navigation offline';

  @override
  String get downloadCustomRegion => 'Download Custom Region';

  @override
  String get deleteOfflineMaps => 'Delete Offline Maps?';

  @override
  String confirmDeleteRegion(String regionName) {
    return 'Are you sure you want to delete \"$regionName\"?';
  }

  @override
  String startingDownload(String regionName) {
    return 'Starting download of $regionName';
  }

  @override
  String get storage => 'Storage';

  @override
  String get noDownloadedMaps => 'No Downloaded Maps';

  @override
  String get downloadMapsToUseOffline =>
      'Download maps to use the app without internet';

  @override
  String get downloaded => 'Downloaded';

  @override
  String get downloading => 'Downloading...';

  @override
  String percentDownloaded(int percent) {
    return '$percent% downloaded';
  }

  @override
  String get downloadError => 'Error during download';

  @override
  String get pending => 'Pending...';

  @override
  String get selectRegion => 'Select Region';

  @override
  String get selectRegionOnMap => 'Select a region on the map to download';

  @override
  String get regionName => 'Region Name';

  @override
  String get downloadRegion => 'Download Region';

  @override
  String get enterRegionName => 'Enter a name for the region';

  @override
  String get offlineSettings => 'Offline Settings';

  @override
  String get autoDownloadOnWifi => 'Auto-download on WiFi';

  @override
  String get autoDownloadOnWifiDesc =>
      'Automatically download maps when on WiFi';

  @override
  String get downloadRouteBuffer => 'Download Route Buffer';

  @override
  String get downloadRouteBufferDesc => 'Download maps around your routes';

  @override
  String get maxStorage => 'Max Storage';

  @override
  String get deleteAllOfflineMaps => 'Delete All Offline Maps';

  @override
  String get deleteAllOfflineMapsConfirm => 'Delete All Offline Maps?';

  @override
  String get deleteAllOfflineMapsDesc =>
      'This will delete all downloaded maps. You can download them again later.';

  @override
  String get deleteAll => 'Delete All';

  @override
  String get allOfflineMapsDeleted => 'All offline maps deleted';

  @override
  String get eventInstructions => 'Instructions (optional)';

  @override
  String get eventInstructionsHint => 'E.g. Meet at the bike parking';

  @override
  String get searchAddressFirst => 'Search for an address first';

  @override
  String get groupRideCreated => 'Group ride created!';

  @override
  String get updateEvent => 'Update Event';

  @override
  String get eventUpdated => 'Event updated successfully';

  @override
  String get error => 'Error';

  @override
  String get upcomingGroupRides => 'Upcoming Group Rides';

  @override
  String get seeAll => 'See all';

  @override
  String get findGroupRides => 'Find Group Rides';

  @override
  String get discoverLocalRides => 'Discover and join local cycling events';

  @override
  String get noBiometricsAvailable =>
      'This device does not have biometric authentication (fingerprint or face recognition)';

  @override
  String get noBiometricsTitle => 'Biometrics Not Available';

  @override
  String get groupChat => 'Group Chat';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get beFirstToMessage => 'Be the first to send a message!';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get signInToChat => 'Sign in to send messages';

  @override
  String get viewOnMap => 'View on Map';

  @override
  String get myRentals => 'My Rentals';

  @override
  String get renting => 'Renting';

  @override
  String get listings => 'Listings';

  @override
  String get noListingsYet => 'No listings yet';

  @override
  String get listBikeToEarn => 'List your bike to start earning!';

  @override
  String get createListing => 'Create Listing';

  @override
  String get listingNotFound => 'Listing not found';

  @override
  String get errorLoadingListing => 'Error loading listing';

  @override
  String get declineRequest => 'Decline Request';

  @override
  String get declineRequestConfirm =>
      'Are you sure you want to decline this request?';

  @override
  String get approveRequest => 'Approve Request';

  @override
  String get requestApproved => 'Request approved! Renter has been notified.';

  @override
  String get requestDeclined => 'Request declined';

  @override
  String get deleteListing => 'Delete Listing';

  @override
  String get deleteListingQuestion =>
      'Are you sure you want to delete this listing?';

  @override
  String errorOccurred(String error) {
    return 'Error: $error';
  }

  @override
  String get safeZones => 'Safe Zones';

  @override
  String get noFamilyAccount => 'No family account found';

  @override
  String get addZone => 'Add Zone';

  @override
  String get deleteSafeZone => 'Delete Safe Zone?';

  @override
  String get deleteSafeZoneConfirm =>
      'This will permanently remove this safe zone.';

  @override
  String zoneDeleted(String zoneName) {
    return 'Deleted \"$zoneName\"';
  }

  @override
  String get aboutSafeZones => 'About Safe Zones';

  @override
  String get gotIt => 'Got it';

  @override
  String get addFirstZone => 'Add Your First Zone';

  @override
  String get approve => 'Approve';

  @override
  String get createNewListing => 'Create New Listing';

  @override
  String get loading => 'Loading...';

  @override
  String get remove => 'Remove';
}
