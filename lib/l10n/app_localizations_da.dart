// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get appTagline => 'Din cykel OS';

  @override
  String get appSubtitle => 'Danmarks cykel OS';

  @override
  String get continueWithGoogle => 'Fortsæt med Google';

  @override
  String get continueWithApple => 'Fortsæt med Apple';

  @override
  String get or => 'eller';

  @override
  String get signInWithEmail => 'Log ind med e-mail';

  @override
  String get createAccount => 'Opret konto';

  @override
  String get termsNotice =>
      'Ved at fortsætte accepterer du vores\nVilkår og Privatlivspolitik.';

  @override
  String get signIn => 'Log ind';

  @override
  String get welcomeBack => 'Velkommen tilbage til CYKEL';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Adgangskode';

  @override
  String get required => 'Påkrævet';

  @override
  String get forgotPassword => 'Glemt adgangskode?';

  @override
  String get dontHaveAccount => 'Har du ikke en konto?';

  @override
  String get getStarted => 'Kom i gang med CYKEL';

  @override
  String get fullName => 'Fulde navn';

  @override
  String get atLeastTwoChars => 'Mindst 2 tegn';

  @override
  String get atLeastEightChars => 'Mindst 8 tegn';

  @override
  String get confirmPassword => 'Bekræft adgangskode';

  @override
  String get passwordsMismatch => 'Adgangskoderne stemmer ikke overens';

  @override
  String get mustAcceptTerms => 'Du skal acceptere vilkårene for at fortsætte.';

  @override
  String get iAgreeTo => 'Jeg accepterer ';

  @override
  String get terms => 'Vilkår';

  @override
  String get and => ' og ';

  @override
  String get privacyPolicy => 'Privatlivspolitik';

  @override
  String get alreadyHaveAccount => 'Har du allerede en konto?';

  @override
  String get forgotPasswordTitle => 'Glemt adgangskode?';

  @override
  String get forgotPasswordSubtitle =>
      'Indtast din e-mail og vi sender dig et link til at nulstille din adgangskode.';

  @override
  String get sendResetLink => 'Send nulstillingslink';

  @override
  String get backToSignIn => 'Tilbage til log ind';

  @override
  String get emailSentTitle => 'Mail sendt!';

  @override
  String resetLinkSentTo(String email) {
    return 'Vi har sendt et nulstillingslink til\n$email';
  }

  @override
  String get checkInbox => 'Tjek din indbakke og evt. spam-mappe.';

  @override
  String get verifyEmailTitle => 'Bekræft din e-mail';

  @override
  String verifyEmailSentTo(String email) {
    return 'Vi har sendt en bekræftelsesmail til\n$email';
  }

  @override
  String get verifyEmailAction =>
      'Klik på linket i mailen for at aktivere din konto.';

  @override
  String get waitingForVerification => 'Venter på bekræftelse…';

  @override
  String get verificationEmailResent => 'Verifikationsmail sendt igen.';

  @override
  String get emailSentCheck => 'Mail sendt ✓';

  @override
  String get resendEmail => 'Send mail igen';

  @override
  String get signOut => 'Log ud';

  @override
  String greeting(String name) {
    return 'Hej, $name 👋';
  }

  @override
  String get rideToday => 'Klar til at cykle i dag?';

  @override
  String get dashboardComingSoon => 'Dashboard kommer i Phase 2';

  @override
  String get yourAccount => 'Din konto';

  @override
  String get role => 'Rolle';

  @override
  String get emailVerifiedLabel => 'E-mail bekræftet';

  @override
  String get yes => 'Ja ✓';

  @override
  String get no => 'Nej';

  @override
  String get defaultRiderName => 'Cyklist';

  @override
  String get tabMap => 'Kort';

  @override
  String get tabActivity => 'Aktivitet';

  @override
  String get tabDiscover => 'Opdag';

  @override
  String get tabMarketplace => 'Marked';

  @override
  String get tabProfile => 'Profil';

  @override
  String get tabProvider => 'Udbyder';

  @override
  String get tabProviderOnboarding => 'Udbyder Onboarding';

  @override
  String get comingSoon => 'Kommer snart';

  @override
  String get home => 'Hjem';

  @override
  String get sectionRidingConditions => 'Cykelforhold';

  @override
  String get sectionTodayActivity => 'Dagens aktivitet';

  @override
  String get sectionQuickRoutes => 'Hurtige ruter';

  @override
  String get sectionAlerts => 'Advarsler';

  @override
  String get sectionNearby => 'I nærheden';

  @override
  String conditionScore(String score) {
    return '$score/10';
  }

  @override
  String get conditionGood => 'Gode forhold';

  @override
  String get conditionFair => 'Rimelige forhold';

  @override
  String get conditionExcellent => 'Fremragende forhold';

  @override
  String get conditionPoor => 'Dårlige forhold';

  @override
  String get wind => 'Vind';

  @override
  String get rain => 'Regn';

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
    return '$days dages streak';
  }

  @override
  String get distanceLabel => 'Distance';

  @override
  String get durationLabel => 'Varighed';

  @override
  String get streakLabel => 'Streak';

  @override
  String get noAlertsTitle => 'Alt klart';

  @override
  String get noAlertsSubtitle => 'Ingen advarsler i dit område';

  @override
  String get noNearbyTitle => 'Intet i nærheden endnu';

  @override
  String get noNearbySubtitle =>
      'Tjenester vises her, når du angiver din placering';

  @override
  String get addHomeRoute => 'Sæt hjem';

  @override
  String get addWorkRoute => 'Sæt arbejde';

  @override
  String get routeHome => 'Hjem';

  @override
  String get routeWork => 'Arbejde';

  @override
  String get quickRoutesEmpty =>
      'Gem dine hjem- og arbejdslokationer for hurtig navigation';

  @override
  String get profile => 'Profil';

  @override
  String get editProfile => 'Rediger profil';

  @override
  String get savedPlaces => 'Gemte steder';

  @override
  String get myBikes => 'Mine cykler';

  @override
  String get notificationSettings => 'Notifikationer';

  @override
  String get languageSettings => 'Sprog';

  @override
  String get account => 'Konto';

  @override
  String get subscriptionSection => 'Abonnement';

  @override
  String get freePlan => 'Gratis';

  @override
  String get proPlan => 'Pro';

  @override
  String get privacySettings => 'Privatliv';

  @override
  String get helpAndSupport => 'Hjælp & Support';

  @override
  String get deleteAccount => 'Slet konto';

  @override
  String get deleteAccountConfirm =>
      'Er du sikker på, at du vil slette din konto? Det kan ikke fortrydes.';

  @override
  String get noBikesTitle => 'Ingen cykler endnu';

  @override
  String get noBikesSubtitle =>
      'Tilføj din cykel for at spore ture og få personlige indsigter';

  @override
  String get addBike => 'Tilføj cykel';

  @override
  String get member => 'Medlem';

  @override
  String get comingSoonTitle => 'Kommer snart';

  @override
  String get comingSoonSubtitle =>
      'Vi bygger denne funktion.\nDet er ventetiden værd.';

  @override
  String get searchAddress => 'Søg adresse';

  @override
  String get searchPlaces => 'Søg steder...';

  @override
  String get mapLayers => 'Kortlag';

  @override
  String get layerCharging => 'Ladestationer';

  @override
  String get layerService => 'Servicepunkter';

  @override
  String get layerShops => 'Cykelbutikker';

  @override
  String get layerRental => 'Udlejning';

  @override
  String get layerRepair => 'Repair Shops';

  @override
  String get allDay => 'Åbent 24/7';

  @override
  String nearbyCount(int count) {
    return '$count steder i nærheden';
  }

  @override
  String get noPlacesFound => 'Ingen steder fundet';

  @override
  String get tryChangingFilters => 'Prøv at ændre filtre eller søg igen';

  @override
  String get all => 'Alle';

  @override
  String get getDirections => 'Få vejledning';

  @override
  String get startNavigation => 'Start navigation';

  @override
  String get stopNavigation => 'Stop';

  @override
  String get calculating => 'Beregner...';

  @override
  String get calculateRoute => 'Beregn rute';

  @override
  String get yourLocation => 'Din placering';

  @override
  String get couldNotCalculateRoute => 'Kunne ikke beregne rute.';

  @override
  String get locationDisabled => 'Placeringstjenester er deaktiveret.';

  @override
  String get locationDenied => 'Plakeringstilladelse nægtet.';

  @override
  String get routeDistance => 'Distance';

  @override
  String get routeDuration => 'Varighed';

  @override
  String get arrived => 'Du er fremme!';

  @override
  String get done => 'Færdig';

  @override
  String get chargingStation => 'Ladestation';

  @override
  String get servicePoint => 'Servicepunkt';

  @override
  String get bikeShop => 'Cykelbutik';

  @override
  String get rental => 'Udlejning';

  @override
  String get visitWebsite => 'Besøg hjemmeside';

  @override
  String get layerTraffic => 'Trafik';

  @override
  String get layerBikeRoutes => 'Cykelruter';

  @override
  String get layerTransit => 'Offentlig transport';

  @override
  String get nightMode => 'Nattilstand';

  @override
  String get startRide => 'Start tur';

  @override
  String get stopRide => 'Stop tur';

  @override
  String get pauseRide => 'Pausetur';

  @override
  String get resumeRide => 'Genoptag tur';

  @override
  String get calories => 'Kalorier';

  @override
  String get elevation => 'Højde';

  @override
  String get myRides => 'Mine ture';

  @override
  String get rideHistory => 'Turhistorik';

  @override
  String get noRidesYet => 'Ingen ture endnu';

  @override
  String get noRidesSubtitle => 'Tryk Start tur for at optage din første tur';

  @override
  String get avgSpeed => 'Gns. hastighed';

  @override
  String get maxSpeed => 'Maks. hastighed';

  @override
  String get speed => 'Hastighed';

  @override
  String get rideTime => 'Tid';

  @override
  String get offRouteRecalc => 'Afviger fra ruten — genberegner…';

  @override
  String get longPressHint => 'Hold nede på kortet for at sætte destination';

  @override
  String stepsRemaining(int count) {
    return '$count trin';
  }

  @override
  String get errInvalidCredential => 'Forkert e-mail eller adgangskode.';

  @override
  String get errEmailInUse => 'Denne e-mail er allerede i brug.';

  @override
  String get errWeakPassword => 'Adgangskoden er for svag (min. 8 tegn).';

  @override
  String get errInvalidEmail => 'Ugyldig e-mailadresse.';

  @override
  String get errNoInternet => 'Ingen internet forbindelse.';

  @override
  String get errTooManyRequests => 'For mange forsøg. Prøv igen senere.';

  @override
  String get errUserDisabled => 'Denne konto er deaktiveret.';

  @override
  String get errRequiresRecentLogin =>
      'Log venligst ind igen for at fortsætte.';

  @override
  String get errCancelled => 'Login annulleret.';

  @override
  String get errGeneric => 'Der opstod en fejl. Prøv venligst igen.';

  @override
  String get goodMorning => 'God morgen';

  @override
  String get goodAfternoon => 'God eftermiddag';

  @override
  String get goodEvening => 'God aften';

  @override
  String get droppedPin => 'Tabt pin';

  @override
  String get clearRoute => 'Ryd';

  @override
  String get setHomeAddress => 'Indstil hjemmeadresse';

  @override
  String get setWorkAddress => 'Indstil arbejdsadresse';

  @override
  String get tapToRoute => 'Tryk for at navigere';

  @override
  String get addressSearch => 'Søg efter en adresse…';

  @override
  String get save => 'Gem';

  @override
  String arriveAt(String time) {
    return 'Ankomst $time';
  }

  @override
  String get noRouteFound => 'Ingen cykelrute fundet mellem disse steder.';

  @override
  String get locationPermissionRequired =>
      'Placeringstilladelse er påkrævet for at vise din position.';

  @override
  String get openSettings => 'Åbn indstillinger';

  @override
  String get gpsSignalLost => 'GPS-signal mistet';

  @override
  String get routeOverview => 'Oversigt';

  @override
  String get recentSearches => 'Seneste';

  @override
  String get myLocation => 'Min Placering';

  @override
  String get setOnMap => 'Sæt på kortet';

  @override
  String get searchingHint => 'Søger…';

  @override
  String inDistance(String dist, String instruction) {
    return 'Om $dist, $instruction';
  }

  @override
  String get cancel => 'Annuller';

  @override
  String get confirmPin => 'Bekræft placering';

  @override
  String get placeDetails => 'Stedsdetaljer';

  @override
  String get setAsDestination => 'Sæt som destination';

  @override
  String get setAsOrigin => 'Sæt som startpunkt';

  @override
  String get mapStyle => 'Kortstil';

  @override
  String get satellite => 'Satellitbillede';

  @override
  String get normalMap => 'Kort';

  @override
  String get terrain => 'Terræn';

  @override
  String routeOption(int index) {
    return 'Rute $index';
  }

  @override
  String get bikeProfile => 'Cykelprofil';

  @override
  String get bikeProfileCity => 'Bycykel';

  @override
  String get bikeProfileEbike => 'Elcykel';

  @override
  String get bikeProfileRoad => 'Racercykel';

  @override
  String get bikeProfileCargo => 'Ladcykel';

  @override
  String get bikeProfileFamily => 'Familiecykel';

  @override
  String get bikeTypeCity => 'City';

  @override
  String get bikeTypeRoad => 'Road';

  @override
  String get bikeTypeEbike => 'El-cykel';

  @override
  String get bikeTypeCargo => 'Cargo';

  @override
  String get bikeTypeMountain => 'Mountain';

  @override
  String windHeadwind(String speed) {
    return 'Modvind · $speed km/t — forventet længere rejsetid';
  }

  @override
  String windTailwind(String speed) {
    return 'Medvind · $speed km/t — gode forhold!';
  }

  @override
  String windCrosswind(String speed) {
    return 'Sidevind · $speed km/t';
  }

  @override
  String get saveRoute => 'Gem';

  @override
  String get routeSaved => 'Rute gemt';

  @override
  String get routeUnsaved => 'Rute fjernet';

  @override
  String get savedRoutes => 'Gemte ruter';

  @override
  String get rerouteComplete => 'Rute opdateret';

  @override
  String get rerouteFailed => 'Kan ikke genberegne ruten';

  @override
  String get offlineNavBanner =>
      'Offline — navigation fortsætter. Omberegning sat på pause.';

  @override
  String resumeNavigationPrompt(String dest) {
    return 'Genoptag navigation til $dest?';
  }

  @override
  String get resumeNavigationAction => 'Genoptag';

  @override
  String get hazardIce => '⚠ Glatte overflader — kør forsigtigt';

  @override
  String get hazardFreeze => '⚠ Frostvejr';

  @override
  String get hazardStrongWind =>
      '⚠ Kraftig vind — eksponerede ruter kan være vanskelige';

  @override
  String get hazardHeavyRain => 'Kraftig regn';

  @override
  String get hazardWetSurface => '⚠ Glatte overflader — tæt på frysepunktet';

  @override
  String get hazardSnow => 'Sne';

  @override
  String get hazardTypeRoadDamage => 'Vejskader';

  @override
  String get hazardTypeAccident => 'Ulykke';

  @override
  String get hazardTypeDebris => 'Grus / glas';

  @override
  String get hazardTypeRoadClosed => 'Vej spærret';

  @override
  String get hazardTypeBadSurface => 'Dårlig vejbelægning';

  @override
  String get hazardTypeFlooding => 'Oversvømmelse';

  @override
  String get reportHazardTitle => 'Rapportér fare';

  @override
  String get reportHazardSubtitle =>
      'Din rapport hjælper andre cyklister. Rapporter udløber efter 8 timer.';

  @override
  String get reportHazardSubmit => 'Rapportér';

  @override
  String get reportHazardThanks => 'Tak! Fare rapporteret.';

  @override
  String get addStop => 'Tilføj stop';

  @override
  String get sectionFrequentRoutes => 'Hyppige ruter';

  @override
  String get frequentRoutesEmpty =>
      'Naviger et sted hen for at se dine hyppige ruter her';

  @override
  String frequentVisitCount(int count) {
    return '$count× besøgt';
  }

  @override
  String get commuteMorning => 'Morgentur';

  @override
  String get commuteEvening => 'Aftentur';

  @override
  String get startCommute => 'Start';

  @override
  String get navModLeft => 'til venstre';

  @override
  String get navModRight => 'til højre';

  @override
  String get navModStraight => 'ligeud';

  @override
  String get navModSlightLeft => 'let til venstre';

  @override
  String get navModSlightRight => 'let til højre';

  @override
  String get navModSharpLeft => 'skarpt til venstre';

  @override
  String get navModSharpRight => 'skarpt til højre';

  @override
  String get navModUturn => 'U-vending';

  @override
  String navDepart(String dir, String road) {
    return 'Kør $dir ad $road';
  }

  @override
  String navDepartBlind(String dir) {
    return 'Kør $dir';
  }

  @override
  String get navArrive => 'Du er fremme';

  @override
  String navArriveAt(String road) {
    return 'Fremme ved $road';
  }

  @override
  String navTurn(String dir, String road) {
    return 'Drej $dir ad $road';
  }

  @override
  String navTurnBlind(String dir) {
    return 'Drej $dir';
  }

  @override
  String navContinue(String road) {
    return 'Fortsæt ad $road';
  }

  @override
  String get navContinueBlind => 'Fortsæt';

  @override
  String navMerge(String road) {
    return 'Flet ind på $road';
  }

  @override
  String get navMergeBlind => 'Flet ind';

  @override
  String navFork(String dir, String road) {
    return 'Hold $dir i vejforgreningen ad $road';
  }

  @override
  String navForkBlind(String dir) {
    return 'Hold $dir i vejforgreningen';
  }

  @override
  String navEndOfRoad(String dir, String road) {
    return 'Drej $dir ved vejenden ad $road';
  }

  @override
  String navEndOfRoadBlind(String dir) {
    return 'Drej $dir ved vejenden';
  }

  @override
  String get navRoundabout => 'Kør ind i rundkørslen';

  @override
  String navRoundaboutNamed(String road) {
    return 'Kør ind i rundkørslen — $road';
  }

  @override
  String get navExitRoundabout => 'Forlad rundkørslen';

  @override
  String navExitRoundaboutOnto(String road) {
    return 'Forlad rundkørslen ad $road';
  }

  @override
  String navNewName(String road) {
    return 'Fortsæt ad $road';
  }

  @override
  String navUseLane(String dir, String road) {
    return 'Brug $dir vognbane ad $road';
  }

  @override
  String navUseLaneBlind(String dir) {
    return 'Brug $dir vognbane';
  }

  @override
  String navWaypointReached(int n) {
    return 'Stop $n nået — fortsætter til destination';
  }

  @override
  String get navMaxReroutesReached =>
      'For mange omberegninger — fortsætter på nuværende rute';

  @override
  String get discoverActiveHazards => 'Aktive farer';

  @override
  String get discoverNoHazards => 'Ingen aktive farer i nærheden';

  @override
  String get discoverNoSaved => 'Ingen gemte ruter endnu';

  @override
  String get discoverCategories => 'Kategorier';

  @override
  String get marketplaceBrowse => 'Gennemse';

  @override
  String get marketplaceSaved => 'Gemt';

  @override
  String get marketplaceMyListings => 'Mine annoncer';

  @override
  String get marketplaceMessages => 'Beskeder';

  @override
  String get marketplaceSell => 'Sælg';

  @override
  String get listingCategoryAll => 'Alle';

  @override
  String get listingCategoryBike => 'Cykler';

  @override
  String get listingCategoryParts => 'Dele';

  @override
  String get listingCategoryAccessories => 'Tilbehør';

  @override
  String get listingCategoryClothing => 'Tøj & Udstyr';

  @override
  String get listingCategoryTools => 'Værktøj';

  @override
  String get listingConditionNew => 'Ny';

  @override
  String get listingConditionLikeNew => 'Som ny';

  @override
  String get listingConditionGood => 'God stand';

  @override
  String get listingConditionFair => 'Brugt';

  @override
  String get listingContactSeller => 'Kontakt sælger';

  @override
  String get listingCallSeller => 'Ring sælger';

  @override
  String get listingPhoneHint => 'Telefonnummer (valgfrit)';

  @override
  String get listingMarkSold => 'Marker som solgt';

  @override
  String get listingEditAction => 'Rediger annonce';

  @override
  String get listingDeleteAction => 'Slet';

  @override
  String get listingSave => 'Gem';

  @override
  String get listingUnsave => 'Gemt';

  @override
  String get chatMessageHint => 'Skriv en besked...';

  @override
  String get chatSend => 'Send';

  @override
  String get listingPublish => 'Publicer annonce';

  @override
  String get listingPrivateSeller => 'Privat';

  @override
  String get listingShopSeller => 'Butik';

  @override
  String get listingNoResults => 'Ingen annoncer fundet';

  @override
  String get listingMyListingsEmpty =>
      'Du har ikke oprettet nogen annoncer endnu';

  @override
  String get listingSavedEmpty => 'Ingen gemte annoncer endnu';

  @override
  String get listingNoMessages => 'Ingen beskeder endnu';

  @override
  String get listingReport => 'Rapporter annonce';

  @override
  String get listingSortNewest => 'Nyeste';

  @override
  String get listingSortPriceLow => 'Pris: Lav til høj';

  @override
  String get listingSortPriceHigh => 'Pris: Høj til lav';

  @override
  String get listingCreateTitle => 'Ny annonce';

  @override
  String get listingEditTitle => 'Rediger annonce';

  @override
  String get listingPublished => 'Annonce publiceret!';

  @override
  String get listingDeleted => 'Annonce slettet';

  @override
  String get listingMarkedSold => 'Markeret som solgt';

  @override
  String get listingTitleHint => 'f.eks. Trek FX3 bycykel';

  @override
  String get listingDescriptionHint => 'Beskriv stand';

  @override
  String get listingPriceHint => 'Pris i DKK';

  @override
  String get listingCityHint => 'By';

  @override
  String get listingAddPhotos => 'Tilføj billeder';

  @override
  String get listingConditionLabel => 'Stand';

  @override
  String get listingCategoryLabel => 'Kategori';

  @override
  String get listingSortBy => 'Sorter efter';

  @override
  String listingViews(int count) {
    return '$count visninger';
  }

  @override
  String listingPostedAgo(String ago) {
    return 'Oprettet $ago';
  }

  @override
  String get listingSoldBadge => 'SOLGT';

  @override
  String get searchHint => 'Søg i annoncer...';

  @override
  String get co2ImpactTitle => 'Klimavenlig kørsel';

  @override
  String get co2Saved => 'CO₂ sparet';

  @override
  String get fuelSaved => 'Brændstof sparet';

  @override
  String get caloriesBurned => 'Kalorier';

  @override
  String get hazardSeverityLabel => 'Alvorlighed';

  @override
  String get hazardSeverityInfo => 'Info';

  @override
  String get hazardSeverityCaution => 'Forsigtig';

  @override
  String get hazardSeverityDanger => 'Farlig';

  @override
  String get hazardFog => '⚠ Tåge — nedsat sigtbarhed, brug lygter';

  @override
  String get hazardLowVisibility =>
      '⚠ Meget lav sigtbarhed — vær ekstremt forsigtig';

  @override
  String get hazardDarkness => '⚠ Kørsel i mørke — brug for- og baglygter';

  @override
  String routeHazardWarning(int count) {
    return '$count fare(r) på din rute';
  }

  @override
  String get infraReportTitle => 'Rapportér infrastrukturproblem';

  @override
  String get infraReportSubtitle =>
      'Hjælp med at forbedre cykelinfrastrukturen i din by.';

  @override
  String get infraReportDescHint => 'Valgfrit: beskriv problemet nærmere...';

  @override
  String get infraReportSubmit => 'Send rapport';

  @override
  String get infraReportThanks => 'Tak! Rapporten er sendt.';

  @override
  String get infraMissingLane => 'Manglende cykelsti';

  @override
  String get infraBrokenPavement => 'Beskadiget belægning';

  @override
  String get infraPoorLighting => 'Dårlig belysning';

  @override
  String get infraLackingSignage => 'Manglende skiltning';

  @override
  String get infraBlockedLane => 'Blokeret cykelsti';

  @override
  String get infraMissingRamp => 'Manglende rampe';

  @override
  String get infraOther => 'Andet';

  @override
  String get gdprTitle => 'Dine data, dit valg';

  @override
  String get gdprSubtitle =>
      'CYKEL indsamler kun de data, der er nødvendige for at gøre cykling mere sikkert. Gennemgå hvad vi bruger herunder.';

  @override
  String get gdprLocationTitle => 'Placering';

  @override
  String get gdprLocationBody =>
      'Bruges til navigation og nærliggende advarsler. Deles aldrig uden dit samtykke.';

  @override
  String get gdprRidesTitle => 'Turdata';

  @override
  String get gdprRidesBody =>
      'Gemt lokalt på din enhed. Bruges til statistik og CO₂-beregning.';

  @override
  String get gdprOptionalTitle => 'Valgfrie funktioner';

  @override
  String get gdprAnalyticsTitle => 'Brug af app';

  @override
  String get gdprAnalyticsBody =>
      'Anonyme brugsdata til at forbedre CYKEL. Ingen placering eller personoplysninger.';

  @override
  String get gdprAggregationTitle => 'Mobilitetsaggregering';

  @override
  String get gdprAggregationBody =>
      'Anonymiserede turdata deles med byplanlæggere for at forbedre cykelinfrastrukturen.';

  @override
  String get gdprPrivacyNotice =>
      'Du kan ændre disse indstillinger til enhver tid under Profil → Privatliv.';

  @override
  String get gdprAccept => 'Accepter og fortsæt';

  @override
  String get gdprSectionTitle => 'Privatliv';

  @override
  String get exportMyData => 'Eksportér mine data';

  @override
  String get dataExported => 'Data eksporteret med succes';

  @override
  String exportFailed(String error) {
    return 'Eksport mislykkedes: $error';
  }

  @override
  String get sosButton => 'SOS';

  @override
  String get sosTitle => 'Nødsituation';

  @override
  String get sosCall112 => 'Ring 112 (nødtjenester)';

  @override
  String get sosCall112Subtitle => 'Politi, Brandvæsen og Ambulance';

  @override
  String get sosShareLocation => 'Kopiér min placering';

  @override
  String get sosReportAccident => 'Rapportér en ulykke';

  @override
  String get sosReportAccidentSubtitle => 'Send en hændelsesrapport til CYKEL';

  @override
  String get sosAccidentDescHint => 'Beskriv hvad der skete (valgfrit)...';

  @override
  String get sosReportSubmit => 'Send rapport';

  @override
  String get sosLocationCopied => 'Placering kopieret til udklipsholder';

  @override
  String get sosAccidentReported => 'Ulykke anmeldt. Pas på dig selv.';

  @override
  String get editProfileTitle => 'Rediger profil';

  @override
  String get displayName => 'Visningsnavn';

  @override
  String get saveChanges => 'Gem ændringer';

  @override
  String get profileUpdated => 'Profil opdateret';

  @override
  String get savedPlacesTitle => 'Gemte steder';

  @override
  String get homePlace => 'Hjem';

  @override
  String get workPlace => 'Arbejde';

  @override
  String get enterAddress => 'Indtast adresse...';

  @override
  String get addressSaved => 'Gemt';

  @override
  String get noAddressSet => 'Ikke angivet';

  @override
  String get addBikeTitle => 'Tilføj cykel';

  @override
  String get bikeName => 'Cykelnavn';

  @override
  String get bikeBrand => 'Mærke (valgfrit)';

  @override
  String get bikeYear => 'Årstal (valgfrit)';

  @override
  String get bikeAdded => 'Cykel tilføjet';

  @override
  String get bikeDeleted => 'Cykel fjernet';

  @override
  String get bikeDeleteConfirm => 'Fjern denne cykel?';

  @override
  String get notificationsTitle => 'Beskeder';

  @override
  String get notifRideReminders => 'Turpåmindelser';

  @override
  String get notifHazardAlerts => 'Fareadvarsler';

  @override
  String get notifMarketplace => 'Markedspladsmeddelelser';

  @override
  String get notifMarketing => 'Produktopdateringer og tips';

  @override
  String get languageTitle => 'Sprog';

  @override
  String get languageEnglish => 'Engelsk';

  @override
  String get languageDanish => 'Dansk';

  @override
  String get helpTitle => 'Hjælp og support';

  @override
  String get helpEmailAddress => 'support@cykel.app';

  @override
  String get privacyTitle => 'Privatliv';

  @override
  String get revokeConsent => 'Tilbagekald alt samtykke';

  @override
  String get consentRevoked => 'Alt samtykke tilbagekaldt';

  @override
  String get addPlaceTitle => 'Tilføj sted';

  @override
  String get placeName => 'Stednavn';

  @override
  String get placeAddress => 'Adresse';

  @override
  String get placeAdded => 'Sted tilføjet';

  @override
  String get placeDeleted => 'Sted fjernet';

  @override
  String get customPlaces => 'Andre steder';

  @override
  String get noCustomPlaces => 'Ingen tilpassede steder endnu';

  @override
  String get privacyPolicyTitle => 'Privatlivspolitik';

  @override
  String get privacyPolicyReadInApp => 'Læs i app';

  @override
  String get premiumFeature => 'Premium-funktion';

  @override
  String get upgradeToPremium => 'Opgrader til Premium';

  @override
  String get today => 'I dag';

  @override
  String get yesterday => 'I går';

  @override
  String get submitButton => 'Indsend';

  @override
  String get premiumPlan => 'Premium';

  @override
  String get ridingConditions => 'Cykelforhold';

  @override
  String feelsLike(String temp) {
    return 'føles som $temp°';
  }

  @override
  String get battery => 'Batteri';

  @override
  String get warningCachedData => '⚠️  Cachelagrede data';

  @override
  String get warningIceRisk => '⚠️  Isrisiko';

  @override
  String get warningStrongWind => '💨  Kraftig vind';

  @override
  String get warningCold => '🥶  Koldt';

  @override
  String get shortcutHomeToWork => 'Hjem → Arbejde';

  @override
  String get shortcutWorkToHome => 'Arbejde → Hjem';

  @override
  String get activityStats => 'Aktivitetsstatistik';

  @override
  String rideCountLabel(int count) {
    return '$count ture';
  }

  @override
  String get streak => 'Stribe';

  @override
  String get dayUnit => 'dag';

  @override
  String get daysUnit => 'dage';

  @override
  String get noWeatherAlerts => 'Ingen vejrvarsler';

  @override
  String get conditionsGoodForCycling => 'Forholdene er gode for cykling';

  @override
  String get weatherAlerts => 'Vejrvarsler';

  @override
  String get weatherUnavailable => 'Vejr ikke tilgængeligt';

  @override
  String get unableToCheckWeather => 'Kan ikke tjekke vejrforholdene';

  @override
  String get maintenanceDue => 'Service påkrævet';

  @override
  String maintenanceBody(String km) {
    return 'Din cykel har kørt $km km siden sidste service';
  }

  @override
  String get markDone => 'Markér udført';

  @override
  String get couldNotLoadNearby => 'Kunne ikke indlæse steder i nærheden';

  @override
  String get checkConnectionRetry => 'Tjek din forbindelse og prøv igen';

  @override
  String get noBikePlacesNearby => 'Ingen cykelsteder i nærheden';

  @override
  String get tryCyclingMoreInfra =>
      'Prøv at cykle til et område med mere infrastruktur';

  @override
  String get bikeRental => 'Cykeludlejning';

  @override
  String get repairStation => 'Reparationsstation';

  @override
  String get dayMon => 'Man';

  @override
  String get dayTue => 'Tir';

  @override
  String get dayWed => 'Ons';

  @override
  String get dayThu => 'Tor';

  @override
  String get dayFri => 'Fre';

  @override
  String get daySat => 'Lør';

  @override
  String get daySun => 'Søn';

  @override
  String get monthJan => 'Januar';

  @override
  String get monthFeb => 'Februar';

  @override
  String get monthMar => 'Marts';

  @override
  String get monthApr => 'April';

  @override
  String get monthMay => 'Maj';

  @override
  String get monthJun => 'Juni';

  @override
  String get monthJul => 'Juli';

  @override
  String get monthAug => 'August';

  @override
  String get monthSep => 'September';

  @override
  String get monthOct => 'Oktober';

  @override
  String get monthNov => 'November';

  @override
  String get monthDec => 'December';

  @override
  String monthlyChallenge(String month) {
    return '$month-udfordring';
  }

  @override
  String challengeRideCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ture',
      one: 'tur',
    );
    return '$count $_temp0';
  }

  @override
  String get premiumBannerSubtitle =>
      'Vindnavigation · Analyse · Offline · E-Bike — kr 20/md';

  @override
  String get eBikeRange => 'E-cykel rækkevidde';

  @override
  String batteryPercent(int percent) {
    return '$percent% batteri';
  }

  @override
  String rangeRemaining(String range) {
    return '≈ $range tilbage';
  }

  @override
  String get lowBattery => '⚠ Lavt batteri';

  @override
  String get tabLive => 'Live';

  @override
  String get tabAnalytics => 'Analyse';

  @override
  String rideSavedSnackbar(String distance) {
    return 'Tur gemt: $distance';
  }

  @override
  String get replay => 'Afspil igen';

  @override
  String get gpxLabel => 'GPX';

  @override
  String get noGpsPathToExport => 'Ingen GPS-rute at eksportere.';

  @override
  String get gpxExportTitle => 'GPX-eksport';

  @override
  String gpxFileSavedTo(String path) {
    return 'Fil gemt i:\n$path';
  }

  @override
  String get copyGpxToClipboard => 'Kopiér GPX til udklipsholder';

  @override
  String get gpxCopiedToClipboard => 'GPX kopieret til udklipsholder';

  @override
  String get premiumAnalyticsBody =>
      'Detaljeret turstatistik er tilgængelig med et Premium-abonnement.';

  @override
  String get periodSummaries => 'Periodeoversigter';

  @override
  String get thisWeek => 'Denne uge';

  @override
  String get thisMonth => 'Denne måned';

  @override
  String get thisYear => 'I år';

  @override
  String get personalRecords => 'Personlige rekorder';

  @override
  String get completeFirstRide =>
      'Gennemfør din første tur for at se rekorder.';

  @override
  String get timeLabel => 'Tidspunkt';

  @override
  String get kcalUnit => 'kcal';

  @override
  String get climb => 'Stigning';

  @override
  String get savedLabel => 'Gemt';

  @override
  String get ridesLabel => 'Ture';

  @override
  String get longestRide => 'Længste tur';

  @override
  String get fastestAvgSpeed => 'Hurtigste gns. hastighed';

  @override
  String get mostElevation => 'Mest stigning';

  @override
  String get mostCalories => 'Flest kalorier';

  @override
  String get longestStreak => 'Længste stribe';

  @override
  String get routeReplayTitle => 'Rutegenafspilning';

  @override
  String get replayStart => 'Start';

  @override
  String get replayEnd => 'Slut';

  @override
  String get noGpsPathAvailable => 'Ingen GPS-rute tilgængelig';

  @override
  String get elapsed => 'Forløbet';

  @override
  String get total => 'Total';

  @override
  String fuelSavingsAmount(String amount) {
    return 'Brændstofbesparelse: $amount';
  }

  @override
  String get cykelPremiumTitle => 'CYKEL Premium';

  @override
  String get premiumTagline => 'Intelligens · Pålidelighed · Optimering';

  @override
  String get onPremiumStatus => '✓  Du har Premium';

  @override
  String get onFreeStatus => 'Du er på gratisplanen';

  @override
  String get featuresHeader => 'Funktioner';

  @override
  String get freeColumn => 'GRATIS';

  @override
  String get proColumn => 'PRO';

  @override
  String get premiumPrice => 'kr 20';

  @override
  String get premiumPerMonth => '/måned';

  @override
  String get premiumPriceNote => 'Ca. \$2.99 USD · Opsig når som helst';

  @override
  String get cancelPremiumTitle => 'Opsig Premium?';

  @override
  String get cancelPremiumBody => 'Du mister adgang til Premium-funktioner.';

  @override
  String get keepPremium => 'Behold Premium';

  @override
  String get switchedToFree => 'Skiftet til gratisplan';

  @override
  String get welcomeToPremium => 'Velkommen til Premium!';

  @override
  String get upgradeButtonLabel => 'Opgrader til Premium — kr 20/måned';

  @override
  String get manageSubscription => 'Administrer abonnement';

  @override
  String get pillWindAI => 'Vind-AI';

  @override
  String get pillAnalytics => 'Analyse';

  @override
  String get pillEBike => 'E-Cykel';

  @override
  String get pillCloud => 'Cloud';

  @override
  String get subNavAndMap => 'Navigation & kort';

  @override
  String get subSafety => 'Sikkerhed & offentlig værdi — altid gratis';

  @override
  String get subActivityTracking => 'Aktivitetsopfølgning';

  @override
  String get subPersonalization => 'Personalisering & nytte';

  @override
  String get subMarketplaceBasic => 'Markedsplads — basisadgang';

  @override
  String get subSmartRouting => 'Smart ruteplanlægning & optimering';

  @override
  String get subOffline => 'Offline & pålidelighed';

  @override
  String get subEbikeIntel => 'E-cykel intelligens';

  @override
  String get subAdvAnalytics => 'Avanceret analyse & ydeevne';

  @override
  String get subAutomation => 'Automatisering & smart assistance';

  @override
  String get subRouteSharing => 'Rutedeling & social nytte';

  @override
  String get subAdvCustom => 'Avanceret tilpasning';

  @override
  String get subVoiceNav => 'Stemme- & navigationsoplevelse';

  @override
  String get subCloudSync => 'Cloud-synkronisering & multienhed';

  @override
  String get subMarketplacePro => 'Markedsplads — Premium-forbedringer';

  @override
  String get subFeatBasicRouting => 'Grundlæggende A → B cykelnavigation';

  @override
  String get subFeatVoiceNav => 'Sving-for-sving stemmenavigation';

  @override
  String get subFeatGpsTracking => 'GPS-sporing i realtid';

  @override
  String get subFeatFollowUser => 'Følg-bruger korttilstand';

  @override
  String get subFeatAltRoutes => 'Alternativt rutevalg';

  @override
  String get subFeatNearbyPoi =>
      'POI\'er i nærheden (opladning, reparation, udlejning)';

  @override
  String get subFeatMapLayers => 'Kortlag: trafik, cykelstier, satellit';

  @override
  String get subFeatRouteSummary => 'Ruteoversigt — afstand, varighed, ETA';

  @override
  String get subFeatWeatherWind => 'Aktuelle vejr- og vindforhold';

  @override
  String get subFeatNightMode => 'Nattilstand';

  @override
  String get subFeatLocaleSwitching => 'Sprog- / områdeskift';

  @override
  String get subFeatStormWarnings => 'Stormvarsler';

  @override
  String get subFeatIceAlerts => 'Is- / glatte vej-advarsler';

  @override
  String get subFeatFogWarnings => 'Tåge- & sigtbarhedsadvarsler';

  @override
  String get subFeatHazardAlerts => 'Fareadvarsler på ruten';

  @override
  String get subFeatCrowdHazards => 'Brugerrapporterede farer (visning)';

  @override
  String get subFeatEmergencySos => 'Nød-SOS — ring & del placering';

  @override
  String get subFeatAccidentReport => 'Ulykkesrapportering';

  @override
  String get subFeatRideCondition => 'Cykelforholdindikator';

  @override
  String get subFeatSafetyNotifs => 'Sikkerheds-pushnotifikationer';

  @override
  String get subFeatLiveRecording =>
      'Live turoptagelse — afstand, hastighed, tid';

  @override
  String get subFeatCaloriesBasic => 'Kalorier (basis)';

  @override
  String get subFeatRideHistory30 => 'Turhistorik (seneste 30 dage)';

  @override
  String get subFeatRideHistoryNote => 'Premium: ubegrænset';

  @override
  String get subFeatWeeklyStats => 'Ugentlige aktivitetsstatistikker';

  @override
  String get subFeatMonthlyGoals => 'Månedlige udfordringsmål';

  @override
  String get subFeatCo2Stats => 'Grundlæggende CO₂-besparelsesstatistik';

  @override
  String get subFeatFuelSavings => 'Brændstofbesparelse (DKK)';

  @override
  String get subFeatDashboardSummary =>
      'Oversigt over hjemme-dashboard aktivitet';

  @override
  String get subFeatMultiBikes => 'Flere cykelprofiler';

  @override
  String get subFeatSavedPlaces => 'Gemte steder / favoritter';

  @override
  String get subFeatCommuteSuggestion => 'Pendlerforslag';

  @override
  String get subFeatPushNotifs => 'Push-notifikationer (generelle)';

  @override
  String get subFeatGdprControls => 'Privatlivsindstillinger & GDPR-kontrol';

  @override
  String get subFeatAppTheme => 'Apptema (lys / mørk)';

  @override
  String get subFeatBrowseListings => 'Gennemse annoncer (cykler & udstyr)';

  @override
  String get subFeatViewDetails => 'Se detaljer';

  @override
  String get subFeatContactSeller => 'Kontakt sælger';

  @override
  String get subFeatBasicListing => 'Grundlæggende annonceoprettelse';

  @override
  String get subFeatWindRouting => 'Vindoptimeret automatisk rutevalg';

  @override
  String get subFeatElevRouting => 'Højdebevidst ruteplanlægning';

  @override
  String get subFeatRouteModeFastSafe => 'Hurtigste vs. sikreste rutetilstande';

  @override
  String get subFeatFreqDest => 'Hyppige destinationsgenveje';

  @override
  String get subFeatUnlimitedRoutes => 'Hurtige gemte ruter (ubegrænset)';

  @override
  String get subFeatAdvRoutePrefs => 'Avancerede rutepræferencer';

  @override
  String get subFeatOfflineRoutes => 'Download ruter til offlinenavigation';

  @override
  String get subFeatCachedTiles =>
      'Cachelagrede kortfliser for udvalgte områder';

  @override
  String get subFeatOfflineTbt => 'Offline sving-for-sving vejledning';

  @override
  String get subFeatNetworkFallback => 'Netværksfejlhåndtering + auto-fallback';

  @override
  String get subFeatGpsMitigation => 'GPS-tabsafhjælpning & tunneltilstand';

  @override
  String get subFeatRouteRecovery => 'Rutegendannelse efter genstart af app';

  @override
  String get subFeatBatteryRange => 'Batterirækkeviddeestimering';

  @override
  String get subFeatEnergyModel => 'Energiforbrugsmodellering';

  @override
  String get subFeatElevRange => 'Højdejusteret rækkevidde';

  @override
  String get subFeatRangeCard => 'Dashboard-kort for resterende rækkevidde';

  @override
  String get subFeatUnlimitedHistory => 'Ubegrænset turhistorik';

  @override
  String get subFeatElevTracking => 'Højdemeteroptælling pr. tur';

  @override
  String get subFeatElevCalorie => 'Højdebevidst kalorieberegning';

  @override
  String get subFeatPeriodStats =>
      'Ugentlige / månedlige / årlige statistikker';

  @override
  String get subFeatPersonalRecords =>
      'Personlige rekorder — længste, hurtigste, striber';

  @override
  String get subFeatGpxExport => 'GPX-eksport af ture';

  @override
  String get subFeatScheduledReminders => 'Planlagte turpåmindelser';

  @override
  String get subFeatMaintenanceAlerts =>
      'Vedligeholdelsesadvarsler — serviceintervaller & slid';

  @override
  String get subFeatSmartNotifs => 'Smarte notifikationer';

  @override
  String get subFeatShareLink => 'Del ruter via link';

  @override
  String get subFeatExportGpx => 'Eksportér rute til GPX';

  @override
  String get subFeatShareSummary => 'Del turopsummeringer';

  @override
  String get subFeatSendToFriends => 'Send rute til venner';

  @override
  String get subFeatImportRoutes => 'Importér delte ruter';

  @override
  String get subFeatCustomDashboard => 'Tilpasset dashboard-layout';

  @override
  String get subFeatMapStyle => 'Kortstilstilpasning';

  @override
  String get subFeatCustomAlerts => 'Tilpassede advarselsgrænser';

  @override
  String get subFeatCustomGoals => 'Tilpassede turmål';

  @override
  String get subFeatUiDensity => 'UI-tæthedsindstillinger';

  @override
  String get subFeatPremiumVoice => 'Premium stemmepakker';

  @override
  String get subFeatMultiLangVoice => 'Flersprogede stemmeindstillinger';

  @override
  String get subFeatVoiceStyle =>
      'Stemmestil — Minimal / Detaljeret / Sikkerhed';

  @override
  String get subFeatAnnouncementFreq => 'Justerbar annonceringsfrekvens';

  @override
  String get subFeatDataSync => 'Datasynkronisering på tværs af enheder';

  @override
  String get subFeatCloudBackup => 'Cloud-backup af ture';

  @override
  String get subFeatRestoreHistory => 'Gendan historik efter geninstallering';

  @override
  String get subFeatSyncProfiles => 'Synkronisér cykelprofiler & indstillinger';

  @override
  String get subFeatUnlimitedListings => 'Ubegrænsede annoncer';

  @override
  String get subFeatPriorityPlacement => 'Prioriteret placering';

  @override
  String get subFeatHighlighted => 'Fremhævede / udvalgte produkter';

  @override
  String get subFeatAdvSearchFilters => 'Avancerede søgefiltre';

  @override
  String get subFeatSellerAnalytics => 'Sælger-analysedashboard';

  @override
  String get voiceSettingsTitle => 'Stemmeindstillinger';

  @override
  String get voiceStyle => 'Stemmestil';

  @override
  String get voiceMinimal => 'Minimal';

  @override
  String get voiceMinimalDesc => 'Kun gadenavn — minimale afbrydelser';

  @override
  String get voiceDetailed => 'Detaljeret';

  @override
  String get voiceDetailedDesc =>
      'Drejningsretning + gade + afstand (standard)';

  @override
  String get voiceSafety => 'Sikkerhedsfokus';

  @override
  String get voiceSafetyDesc =>
      'Detaljeret + ekstra fare- & sikkerhedsadvarsler';

  @override
  String get speechRate => 'Talehastighed';

  @override
  String get speechRateDesc =>
      'Justér hvor hurtigt stemmen giver instruktioner.';

  @override
  String get rateVerySlow => 'Meget langsom';

  @override
  String get rateSlow => 'Langsom';

  @override
  String get rateNormal => 'Normal';

  @override
  String get rateFast => 'Hurtig';

  @override
  String get rateVeryFast => 'Meget hurtig';

  @override
  String get previewVoice => 'Forhåndsvisning af stemme';

  @override
  String get voicePreviewText => 'Om 500 meter, drej til højre ad Hovedgaden.';

  @override
  String get announcementDistance => 'Annonceringsafstand';

  @override
  String get announcementDistanceDesc =>
      'Hvor langt før kommende sving annonceres.';

  @override
  String get freqEarly => 'Tidlig';

  @override
  String get freqNormal => 'Normal (standard)';

  @override
  String get freqLate => 'Sen';

  @override
  String get premiumVoiceBody =>
      'Stemmetilpasning er tilgængelig med et Premium-abonnement.';

  @override
  String get dashboardSettingsTitle => 'Dashboard-indstillinger';

  @override
  String get homeScreenSections => 'Hjemmeskærmssektioner';

  @override
  String get homeScreenSectionsDesc =>
      'Vælg hvilke sektioner der skal vises på dit hjemme-dashboard.';

  @override
  String get sectionMonthlyChallenge => 'Månedlig udfordring';

  @override
  String get sectionMonthlyChallengeDesc => 'Følg dit månedlige cykelmål';

  @override
  String get sectionEbikeRange => 'E-cykel rækkevidde';

  @override
  String get sectionEbikeRangeDesc => 'Batteriniveau og estimeret rækkevidde';

  @override
  String get sectionQuickRoutesLabel => 'Hurtige ruter';

  @override
  String get sectionQuickRoutesDesc => 'Gemte ruter og hyppige destinationer';

  @override
  String get sectionRecentActivity => 'Seneste aktivitet';

  @override
  String get sectionRecentActivityDesc => 'Dine seneste ture og statistikker';

  @override
  String get sectionMaintenanceReminder => 'Servicepåmindelse';

  @override
  String get sectionMaintenanceReminderDesc =>
      'Notifikationer om serviceeftersyn';

  @override
  String get changesImmediate => 'Ændringer træder i kraft med det samme.';

  @override
  String get premiumDashboardBody =>
      'Dashboard-tilpasning er tilgængelig med et Premium-abonnement.';

  @override
  String get faqSection => 'FAQ';

  @override
  String get contactSection => 'KONTAKT';

  @override
  String get emailUs => 'Send os en e-mail';

  @override
  String get faq1Q => 'Hvordan optager jeg en tur?';

  @override
  String get faq1A =>
      'Åbn Kort-fanen og tryk på play-knappen nederst for at starte optagelsen. Tryk stop når du er færdig.';

  @override
  String get faq2Q => 'Hvordan rapporterer jeg en fare?';

  @override
  String get faq2A =>
      'Under navigation, tryk på advarselsikonet og vælg faretype. Rapporter er synlige for nærliggende cyklister i 8 timer.';

  @override
  String get faq3Q => 'Hvordan sætter jeg en cykel til salg?';

  @override
  String get faq3A =>
      'Gå til Markedsplads-fanen og tryk på +-knappen. Udfyld detaljerne og tilføj billeder for at publicere din annonce.';

  @override
  String get faq4Q => 'Hvordan gemmer jeg et sted?';

  @override
  String get faq4A =>
      'Gå til Profil → Gemte steder og indtast din hjemme- eller arbejdsadresse.';

  @override
  String get faq5Q => 'Hvordan sletter jeg min konto?';

  @override
  String get faq5A =>
      'Gå til Profil, scroll til bunden og tryk \"Slet konto\". Dette fjerner permanent alle dine data.';

  @override
  String get faq6Q => 'Hvordan ændrer jeg sproget?';

  @override
  String get faq6A => 'Gå til Profil → Sprog og vælg Engelsk eller Dansk.';

  @override
  String lastUpdated(String date) {
    return 'Sidst opdateret: $date';
  }

  @override
  String get privacyLastUpdateDate => '23. marts 2026';

  @override
  String get privacySection1Title => '1. Hvem vi er';

  @override
  String get privacySection1Body =>
      'CYKEL ApS (\"CYKEL\", \"vi\", \"os\") driver CYKEL-mobilapplikationen. Vi er registreret i Danmark og er underlagt EU\'s generelle databeskyttelsesforordning (GDPR).\n\nKontakt: privacy@cykel.app';

  @override
  String get privacySection2Title => '2. Data vi indsamler';

  @override
  String get privacySection2Body =>
      '• Kontodata (navn, e-mail, profilbillede) — angivet ved tilmelding.\n• Placeringsdata — indsamlet under ture for at tegne din rute. Deles aldrig med tredjeparter i identificerbar form.\n• Turdata — afstand, varighed, rutegeometri.\n• Enhedsdata — OS-version, app-version, crashlogs.\n• Valgfrit: anonymiserede, aggregerede mobilitetsdata med dit samtykke.';

  @override
  String get privacySection3Title => '3. Sådan bruger vi dine data';

  @override
  String get privacySection3Body =>
      '• Levering af kernefunktionalitet (ruter, turhistorik, markedsplads).\n• Forbedring af cykelinfrastrukturplanlægning via aggregerede, anonymiserede data (kun med dit udtrykkelige samtykke).\n• Afsendelse af servicenotifikationer (f.eks. turpåmindelser).\n• Forebyggelse af svindel og sikkerhed.\n\nVi sælger IKKE dine personlige data.';

  @override
  String get privacySection4Title => '4. Retsgrundlag (GDPR art. 6)';

  @override
  String get privacySection4Body =>
      '• Opfyldelse af kontrakt — levering af de tjenester, du har anmodet om.\n• Legitim interesse — sikkerhed, forebyggelse af svindel, app-forbedring.\n• Samtykke — analyse og aggregerede turdata (du kan trække dit samtykke tilbage når som helst under Indstillinger → Privatliv).';

  @override
  String get privacySection5Title => '5. Datadeling';

  @override
  String get privacySection5Body =>
      'Vi deler kun data med:\n• Firebase / Google (hosting, godkendelse, database) — under EU\'s standardkontraktbestemmelser.\n• Apple / Google — til login og push-notifikationer.\n• Ingen reklamenetværk eller datamæglere.';

  @override
  String get privacySection6Title => '6. Opbevaring';

  @override
  String get privacySection6Body =>
      '• Turdata: opbevares i 3 år, derefter automatisk slettet.\n• Kontodata: opbevares indtil du sletter din konto.\n• Crashlogs: 90 dage.\n• Aggregerede anonymiserede data: opbevares på ubestemt tid (kan ikke knyttes tilbage til dig).';

  @override
  String get privacySection7Title => '7. Dine rettigheder';

  @override
  String get privacySection7Body =>
      'Under GDPR har du ret til:\n• Indsigt — anmod om en kopi af alle data, vi har om dig.\n• Berigtigelse — ret forkerte data.\n• Sletning (\"retten til at blive glemt\") — slet din konto og alle tilknyttede data.\n• Dataportabilitet — modtag dine data i et maskinlæsbart format.\n• Indsigelse — gør indsigelse mod behandling baseret på legitim interesse.\n• Tilbagekaldelse af samtykke — når som helst via Indstillinger → Privatliv.\n\nFor at udøve disse rettigheder kontakt privacy@cykel.app. Du har også ret til at indgive en klage til Datatilsynet (datatilsynet.dk).';

  @override
  String get privacySection8Title => '8. Børn';

  @override
  String get privacySection8Body =>
      'CYKEL er ikke rettet mod børn under 13. Vi indsamler ikke bevidst data fra børn. Hvis du mener, et barn har givet os data, kontakt privacy@cykel.app, og vi vil slette det omgående.';

  @override
  String get privacySection9Title => '9. Ændringer af politik';

  @override
  String get privacySection9Body =>
      'Vi kan opdatere denne politik. Væsentlige ændringer vil blive kommunikeret via en meddelelse i appen. Fortsat brug efter ikrafttrædelsesdatoen udgør accept.';

  @override
  String get privacySection10Title => '10. Kontakt';

  @override
  String get privacySection10Body =>
      'CYKEL ApS\nprivacy@cykel.app\nFor akutte henvendelser: support@cykel.app';

  @override
  String get notifSectionRiding => 'Cykling';

  @override
  String get notifRideRemindersDesc => 'Påmindelser om at logge dine ture';

  @override
  String get notifHazardAlertsDesc =>
      'Advarsler om farer i nærheden under cykling';

  @override
  String get notifSectionMarketplace => 'Markedsplads';

  @override
  String get notifMarketplaceDesc => 'Chatbeskeder fra købere & sælgere';

  @override
  String get notifSectionGeneral => 'Generelt';

  @override
  String get notifMarketingDesc => 'Nyheder, tips og funktionsmeddelelser';

  @override
  String get notifSectionScheduled => 'Planlagte påmindelser';

  @override
  String get dailyRideReminder => 'Daglig cykelpåmindelse';

  @override
  String get tapToSetReminder => 'Tryk for at indstille daglig påmindelsestid';

  @override
  String reminderSetFor(String time) {
    return 'Påmindelse sat til $time';
  }

  @override
  String get removeReminder => 'Fjern påmindelse';

  @override
  String get setTime => 'Indstil tid';

  @override
  String get changeTime => 'Ændr';

  @override
  String get preferencesSection => 'Præferencer';

  @override
  String get dashboardLabel => 'Dashboard';

  @override
  String get voiceNavLabel => 'Stemme & Navigation';

  @override
  String get moreSection => 'Mere';

  @override
  String get currentPlan => 'Nuværende plan';

  @override
  String get manageButton => 'Administrer';

  @override
  String get upgradeButton => 'Opgrader';

  @override
  String signOutFailed(String error) {
    return 'Logud mislykkedes: $error';
  }

  @override
  String deleteAccountFailed(String error) {
    return 'Kontosletning mislykkedes: $error';
  }

  @override
  String get nameCannotBeEmpty => 'Navn må ikke være tomt';

  @override
  String failedToSave(String error) {
    return 'Kunne ikke gemme: $error';
  }

  @override
  String get phoneNumber => 'Telefonnummer';

  @override
  String get phoneHint => '+45 ...';

  @override
  String get bikeTypeLabel => 'Type';

  @override
  String failedToAddBike(String error) {
    return 'Kunne ikke tilføje cykel: $error';
  }

  @override
  String get revokeConsentBody =>
      'Dette nulstiller alt datasamtykke. Du vil blive vist samtykkeskærmen igen næste gang du åbner appen.';

  @override
  String get requiredBadge => 'Påkrævet';

  @override
  String failedToSaveConsent(String error) {
    return 'Kunne ikke gemme samtykke: $error';
  }

  @override
  String get deleteListingConfirm =>
      'Er du sikker på, at du vil slette denne annonce? Dette kan ikke fortrydes.';

  @override
  String genericError(String error) {
    return 'Noget gik galt. Prøv venligst igen.';
  }

  @override
  String get discardChangesTitle => 'Kassér ændringer?';

  @override
  String get discardChangesBody =>
      'Du har ikke-gemte ændringer. Er du sikker på, at du vil forlade?';

  @override
  String get stayButton => 'Bliv';

  @override
  String get discardButton => 'Kassér';

  @override
  String get addUpToPhotos => 'Tilføj op til 5 billeder';

  @override
  String get currencyDKK => 'DKK';

  @override
  String get validPhoneNumber => 'Indtast et gyldigt telefonnummer';

  @override
  String get addAtLeastOnePhoto => 'Tilføj mindst ét billede';

  @override
  String get descriptionHeader => 'Beskrivelse';

  @override
  String get chatThreadNotFound => 'Chattråd ikke fundet';

  @override
  String couldNotStartChat(String error) {
    return 'Kunne ikke starte chat: $error';
  }

  @override
  String get reportListingReason => 'Hvorfor rapporterer du denne annonce?';

  @override
  String get reportScam => 'Svindel / bedrageri';

  @override
  String get reportStolen => 'Stjålet cykel';

  @override
  String get reportInappropriate => 'Upassende indhold';

  @override
  String get reportOther => 'Andet';

  @override
  String get reportSubmitted => 'Rapportering indsendt. Tak.';

  @override
  String failedToReport(String error) {
    return 'Kunne ikke rapportere: $error';
  }

  @override
  String get viewsStat => 'Visninger';

  @override
  String get savesStat => 'Gemte';

  @override
  String get chatsStat => 'Chats';

  @override
  String get activeStatus => 'Aktiv';

  @override
  String get chatTitle => 'Chat';

  @override
  String failedToSendMessage(String error) {
    return 'Kunne ikke sende besked';
  }

  @override
  String get welcomeGetStarted => 'Kom i gang';

  @override
  String get welcomeJoinCommunity => 'Bliv en del af cykelfællesskabet';

  @override
  String get filterCharging => 'Opladning';

  @override
  String get filterService => 'Service';

  @override
  String get filterShops => 'Butikker';

  @override
  String get filterRental => 'Udlejning';

  @override
  String agoMinutes(int min) {
    return '${min}m siden';
  }

  @override
  String agoHours(int hours) {
    return '${hours}t siden';
  }

  @override
  String agoDays(int days) {
    return '${days}d siden';
  }

  @override
  String get hazardDuplicateUpvoted =>
      'En nærliggende rapportering fandtes allerede — den blev opjusteret i stedet.';

  @override
  String hazardGpsAccuracyLow(String meters) {
    return 'GPS-nøjagtigheden er for lav ($meters m). Flyt til et åbent område og prøv igen.';
  }

  @override
  String get hazardSubmitFailed => 'Kunne ikke indsende. Prøv igen.';

  @override
  String get ttsLanguageUnavailable =>
      'Stemme ikke tilgængelig på det valgte sprog — bruger engelsk';

  @override
  String get noRouteToExport => 'Ingen rute at eksportere.';

  @override
  String get shareRouteGpx => 'Del rute-GPX';

  @override
  String get shareRoute => 'Del';

  @override
  String get downloadMap => 'Download';

  @override
  String gpxFileLabel(String path) {
    return 'Fil: $path';
  }

  @override
  String get routeGpxCopied => 'Rute-GPX kopieret til udklipsholder';

  @override
  String get noRouteToCacheTiles => 'Ingen rute at cache tiles for.';

  @override
  String get tilesCachedForOffline => 'Kortfliser cachet til offlinebrug';

  @override
  String tilePrefetchFailed(String error) {
    return 'Caching af kortfliser mislykkedes: $error';
  }

  @override
  String get cachingMapTilesTitle => 'Cacher kortfliser';

  @override
  String get cachingMapTilesBody =>
      'Forbereder kortfliser til offlinebrug...\nDet kan tage et minut.';

  @override
  String get routeFastest => 'Hurtigst';

  @override
  String get routeSafest => 'Sikreste';

  @override
  String get selectRoute => 'Vælg Din Rute';

  @override
  String get routingPreference => 'Rutetype';

  @override
  String get bikeType => 'Cykelprofil';

  @override
  String get destination => 'Destination';

  @override
  String get windOverlay => 'Vindoverlay';

  @override
  String get hazardConfirmedThanks => 'Tak — fare bekræftet.';

  @override
  String get hazardStillThere => 'Stadig der';

  @override
  String get hazardClearedThanks => 'Tak — fare ryddet.';

  @override
  String get hazardCleared => 'Ryddet';

  @override
  String get hazardResolved => 'Denne fare er blevet løst.';

  @override
  String get filterAll => 'Alle';

  @override
  String get reportListingTitle => 'Anmeld opslag';

  @override
  String get todayLabel => 'I dag';

  @override
  String get yesterdayLabel => 'I går';

  @override
  String get fieldRequired => 'Påkrævet';

  @override
  String get providerTypeRepairShop => 'Reparation / Cykelværksted';

  @override
  String get providerTypeBikeShop => 'Cykelforretning';

  @override
  String get providerTypeChargingLocation => 'E-cykel opladning';

  @override
  String get providerTypeServicePoint => 'Service Point';

  @override
  String get providerTypeRental => 'Bike Rental';

  @override
  String get providerTypeRepairShopDesc =>
      'Tilbyd mekaniske ydelser, reparationer og vedligeholdelse af cykler.';

  @override
  String get providerTypeBikeShopDesc =>
      'Sælg cykler, el-cykler, tilbehør og cykeludstyr.';

  @override
  String get providerTypeChargingLocationDesc =>
      'Tilbyd opladningspunkter for el-cykelryttere.';

  @override
  String get providerTypeServicePointDesc =>
      'Mobile or fixed service stations for quick repairs and maintenance.';

  @override
  String get providerTypeRentalDesc =>
      'Rent out bicycles and e-bikes to riders.';

  @override
  String get repairFlatTire => 'Punktering';

  @override
  String get repairBrakeService => 'Bremsejustering';

  @override
  String get repairGearAdjustment => 'Gearjustering';

  @override
  String get repairChainReplacement => 'Kædeskift';

  @override
  String get repairWheelTruing => 'Hjulretning';

  @override
  String get repairSuspensionService => 'Affjedring service';

  @override
  String get repairEbikeDiagnostics => 'El-cykel diagnostik';

  @override
  String get repairFullTuneUp => 'Komplet eftersyn';

  @override
  String get repairEmergencyRepair => 'Nødreparation';

  @override
  String get repairSafetyInspection => 'Sikkerhedsinspektion';

  @override
  String get repairMobileRepair => 'Mobil reparation';

  @override
  String get bikeTypeCityBike => 'Bycykel';

  @override
  String get bikeTypeRoadBike => 'Racercykel';

  @override
  String get bikeTypeMtb => 'MTB';

  @override
  String get bikeTypeCargoBike => 'Ladcykel';

  @override
  String get productCityBikes => 'Bycykler';

  @override
  String get productEbikes => 'El-cykler';

  @override
  String get productCargoBikes => 'Ladcykler';

  @override
  String get productRoadBikes => 'Racercykler';

  @override
  String get productKidsBikes => 'Børnecykler';

  @override
  String get productHelmets => 'Hjelme';

  @override
  String get productLocks => 'Låse';

  @override
  String get productLights => 'Lygter';

  @override
  String get productTires => 'Dæk';

  @override
  String get productSpareParts => 'Reservedele';

  @override
  String get productClothing => 'Beklædning';

  @override
  String get chargingStandardOutlet => 'Standard stikkontakt';

  @override
  String get chargingDedicatedCharger => 'Dedikeret el-cykel oplader';

  @override
  String get chargingBatterySwap => 'Batteriskiftestation';

  @override
  String get hostPublicStation => 'Offentlig station';

  @override
  String get hostCafe => 'Café';

  @override
  String get hostShop => 'Butik';

  @override
  String get hostOffice => 'Kontor';

  @override
  String get hostParkingFacility => 'Parkeringsanlæg';

  @override
  String get hostOther => 'Andet';

  @override
  String get powerFree => 'Gratis';

  @override
  String get powerPaid => 'Betalt';

  @override
  String get powerCustomersOnly => 'Kun for kunder';

  @override
  String get amenitySeating => 'Siddepladser';

  @override
  String get amenityFoodDrinks => 'Mad og drikke';

  @override
  String get amenityRestroom => 'Toilet';

  @override
  String get amenityBikeParking => 'Cykelparkering';

  @override
  String get amenityWifi => 'Wi-Fi';

  @override
  String get accessPublic => 'Offentlig';

  @override
  String get accessCustomersOnly => 'Kun for kunder';

  @override
  String get accessResidentsOnly => 'Kun for beboere';

  @override
  String get priceRangeLow => 'Lav';

  @override
  String get priceRangeMedium => 'Mellem';

  @override
  String get priceRangeHigh => 'Høj';

  @override
  String get priceTierBudget => 'Budget';

  @override
  String get priceTierMid => 'Mellemklasse';

  @override
  String get priceTierPremium => 'Premium';

  @override
  String get verificationPending => 'Afventer godkendelse';

  @override
  String get verificationApproved => 'Verificeret';

  @override
  String get verificationRejected => 'Afvist';

  @override
  String get providerActive => 'Aktiv';

  @override
  String get providerInactive => 'Inaktiv';

  @override
  String get providerTemporarilyClosed => 'Midlertidigt lukket';

  @override
  String get becomeProvider => 'Bliv udbyder';

  @override
  String get providerDashboard => 'Udbyder Dashboard';

  @override
  String get providerOnboardingTitle => 'Registrer din virksomhed';

  @override
  String get providerSelectTypeTitle => 'Hvilken type udbyder er du?';

  @override
  String get providerSelectTypeSubtitle =>
      'Vælg den kategori, der bedst passer til din virksomhed.';

  @override
  String get continueLabel => 'Fortsæt';

  @override
  String get backLabel => 'Tilbage';

  @override
  String get submitLabel => 'Indsend';

  @override
  String stepOf(int current, int total) {
    return 'Trin $current af $total';
  }

  @override
  String get businessInfoTitle => 'Virksomhedsoplysninger';

  @override
  String get businessNameLabel => 'Virksomhedsnavn';

  @override
  String get businessNameHint => 'f.eks. København Cykelværksted';

  @override
  String get legalBusinessNameLabel => 'Officielt firmanavn (valgfrit)';

  @override
  String get cvrNumberLabel => 'CVR-nummer';

  @override
  String get cvrNumberHint => '8-cifret dansk virksomheds-ID';

  @override
  String get contactNameLabel => 'Kontaktperson';

  @override
  String get contactNameHint => 'Fulde navn';

  @override
  String get phoneLabel => 'Telefon';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get emailHint => 'firma@eksempel.dk';

  @override
  String get websiteLabel => 'Hjemmeside (valgfrit)';

  @override
  String get websiteHint => 'https://...';

  @override
  String get locationTitle => 'Placering';

  @override
  String get streetAddressLabel => 'Gadeadresse';

  @override
  String get streetAddressHint => 'f.eks. Nørrebrogade 42';

  @override
  String get cityLabel => 'By';

  @override
  String get cityHint => 'f.eks. København';

  @override
  String get postalCodeLabel => 'Postnummer';

  @override
  String get postalCodeHint => 'f.eks. 2200';

  @override
  String get servicesTitle => 'Ydelser og detaljer';

  @override
  String get servicesOfferedLabel => 'Tilbudte ydelser';

  @override
  String get supportedBikeTypesLabel => 'Understøttede cykeltyper';

  @override
  String get mobileRepairLabel => 'Tilbyd mobil reparation';

  @override
  String get acceptsWalkInsLabel => 'Accepter walk-ins';

  @override
  String get appointmentRequiredLabel => 'Tidsbestilling påkrævet';

  @override
  String get estimatedWaitLabel => 'Anslået ventetid (minutter)';

  @override
  String get estimatedWaitHint => 'f.eks. 30';

  @override
  String get priceRangeLabel => 'Prisniveau';

  @override
  String get serviceRadiusLabel => 'Mobil serviceradius (km)';

  @override
  String get serviceRadiusHint => 'f.eks. 10';

  @override
  String get productsTitle => 'Produkter og detaljer';

  @override
  String get productsAvailableLabel => 'Tilgængelige produkter';

  @override
  String get offersTestRidesLabel => 'Tilbyd prøvetur';

  @override
  String get financingAvailableLabel => 'Finansiering tilgængelig';

  @override
  String get acceptsTradeInLabel => 'Accepter bytteprodukter';

  @override
  String get onlineStoreUrlLabel => 'Webshop URL (valgfrit)';

  @override
  String get priceTierLabel => 'Prisniveau';

  @override
  String get hasRepairServiceLabel => 'Tilbyd også reparation';

  @override
  String get chargingTitle => 'Opladningsdetaljer';

  @override
  String get hostTypeLabel => 'Værtstype';

  @override
  String get chargingTypeLabel => 'Opladningstype';

  @override
  String get numberOfPortsLabel => 'Antal opladningsporte';

  @override
  String get numberOfPortsHint => 'f.eks. 4';

  @override
  String get powerAvailabilityLabel => 'Strømtilgængelighed';

  @override
  String get maxChargingDurationLabel => 'Maks opladningstid (minutter)';

  @override
  String get maxChargingDurationHint => 'Lad stå tomt for ubegrænset';

  @override
  String get indoorChargingLabel => 'Indendørs opladning';

  @override
  String get weatherProtectedLabel => 'Vejrbeskyttet';

  @override
  String get amenitiesLabel => 'Faciliteter';

  @override
  String get accessRestrictionLabel => 'Adgangsbegrænsning';

  @override
  String get openingHoursTitle => 'Åbningstider';

  @override
  String get mondayShort => 'Man';

  @override
  String get tuesdayShort => 'Tir';

  @override
  String get wednesdayShort => 'Ons';

  @override
  String get thursdayShort => 'Tor';

  @override
  String get fridayShort => 'Fre';

  @override
  String get saturdayShort => 'Lør';

  @override
  String get sundayShort => 'Søn';

  @override
  String get openLabel => 'Åbner';

  @override
  String get closeLabel => 'Lukker';

  @override
  String get closedLabel => 'Lukket';

  @override
  String get copyToAllDays => 'Kopiér til alle dage';

  @override
  String get mediaTitle => 'Billeder';

  @override
  String get logoLabel => 'Logo';

  @override
  String get logoHint => 'Upload dit virksomhedslogo';

  @override
  String get coverPhotoLabel => 'Coverbillede (valgfrit)';

  @override
  String get galleryLabel => 'Galleri (op til 8 billeder)';

  @override
  String get tapToUpload => 'Tryk for at uploade';

  @override
  String get removePhoto => 'Fjern';

  @override
  String get descriptionTitle => 'Beskrivelse';

  @override
  String get shopDescriptionLabel => 'Virksomhedsbeskrivelse';

  @override
  String get shopDescriptionHint =>
      'Fortæl cyklister hvad der gør din virksomhed speciel...';

  @override
  String get reviewTitle => 'Gennemse og indsend';

  @override
  String get reviewSubtitle =>
      'Gennemgå venligst dine oplysninger inden indsendelse.';

  @override
  String get reviewBusinessInfo => 'Virksomhedsinfo';

  @override
  String get reviewLocation => 'Placering';

  @override
  String get reviewServices => 'Ydelser';

  @override
  String get reviewHours => 'Åbningstider';

  @override
  String get reviewPhotos => 'Billeder';

  @override
  String get reviewDescription => 'Beskrivelse';

  @override
  String get submittingProvider => 'Indsender...';

  @override
  String get providerSubmitSuccess => 'Din udbyderansøgning er indsendt!';

  @override
  String get providerSubmitSuccessDetail =>
      'Vi gennemgår dine oplysninger og vender snart tilbage.';

  @override
  String providerSubmitError(String error) {
    return 'Kunne ikke indsende: $error';
  }

  @override
  String get goToDashboard => 'Gå til Dashboard';

  @override
  String get providerSection => 'Udbyder';

  @override
  String get providerSectionDescription =>
      'Administrer din virksomhed på CYKEL';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String dashboardWelcome(String name) {
    return 'Velkommen, $name';
  }

  @override
  String get dashboardVerificationBanner => 'Din konto afventer verifikation.';

  @override
  String get dashboardRejectedBanner =>
      'Din ansøgning blev afvist. Opdater dine oplysninger og indsend igen.';

  @override
  String get dashboardOverview => 'Oversigt';

  @override
  String get dashboardProfileViews => 'Profilvisninger';

  @override
  String get dashboardNavRequests => 'Navigationsanmodninger';

  @override
  String get dashboardSavedBy => 'Gemt af brugere';

  @override
  String get dashboardQuickActions => 'Hurtige handlinger';

  @override
  String get editBusinessInfo => 'Rediger virksomhedsinfo';

  @override
  String get manageHours => 'Administrer åbningstider';

  @override
  String get managePhotos => 'Administrer billeder';

  @override
  String get providerSettings => 'Indstillinger';

  @override
  String get viewAnalytics => 'Se analyser';

  @override
  String get editProviderTitle => 'Rediger virksomhed';

  @override
  String get saving => 'Gemmer...';

  @override
  String get changesSaved => 'Ændringer gemt.';

  @override
  String changesSaveError(String error) {
    return 'Kunne ikke gemme: $error';
  }

  @override
  String get manageHoursTitle => 'Administrer åbningstider';

  @override
  String get hoursSaved => 'Åbningstider opdateret.';

  @override
  String get managePhotosTitle => 'Administrer billeder';

  @override
  String get currentLogo => 'Nuværende logo';

  @override
  String get currentCover => 'Nuværende coverbillede';

  @override
  String get currentGallery => 'Nuværende galleri';

  @override
  String get changeLogo => 'Skift logo';

  @override
  String get changeCover => 'Skift cover';

  @override
  String get addPhotos => 'Tilføj billeder';

  @override
  String get photosSaved => 'Billeder opdateret.';

  @override
  String get uploading => 'Uploader...';

  @override
  String get settingsTitle => 'Udbyderindstillinger';

  @override
  String get activeStatusLabel => 'Opslag aktivt';

  @override
  String get activeStatusDesc =>
      'Din virksomhed er synlig for cyklister på kortet.';

  @override
  String get temporarilyClosedLabel => 'Midlertidigt lukket';

  @override
  String get temporarilyClosedDesc =>
      'Vis en lukket-meddelelse uden at deaktivere dit opslag.';

  @override
  String get specialNoticeLabel => 'Særlig meddelelse';

  @override
  String get specialNoticeHint => 'f.eks. Lukket for renovering til 30. marts';

  @override
  String get specialNoticeSaved => 'Meddelelse opdateret.';

  @override
  String get deleteProviderTitle => 'Slet udbyder';

  @override
  String get deleteProviderConfirm =>
      'Er du sikker på, at du vil slette dit udbyderopslag? Denne handling kan ikke fortrydes.';

  @override
  String get deleteProviderButton => 'Slet permanent';

  @override
  String get providerDeleted => 'Udbyderopslag slettet.';

  @override
  String get analyticsTitle => 'Analyser';

  @override
  String get analyticsProfileViews => 'Profilvisninger';

  @override
  String get analyticsNavRequests => 'Navigationsanmodninger';

  @override
  String get analyticsSavedBy => 'Gange gemt';

  @override
  String get analyticsNoData => 'Ingen analysedata endnu.';

  @override
  String get noProviderFound =>
      'Ingen udbyderregistrering fundet. Gennemfør venligst onboarding først.';

  @override
  String get status => 'Status';

  @override
  String get typeLabel => 'Type';

  @override
  String get layerCykelRepair => 'CYKEL Cykelværksteder';

  @override
  String get layerCykelShop => 'CYKEL Cykelforretninger';

  @override
  String get layerCykelCharging => 'CYKEL Opladning';

  @override
  String get layerCykelService => 'CYKEL Servicepunkter';

  @override
  String get layerCykelRental => 'CYKEL Udlejning';

  @override
  String get cykelVerifiedProviders => 'Find udbydere på kortet';

  @override
  String get cykelVerifiedSection => 'Verificerede Udbydere';

  @override
  String get cykelProviderNearby => 'CYKEL Udbydere i nærheden';

  @override
  String get providerDetailGetDirections => 'Få rutevejledning';

  @override
  String get providerDetailCall => 'Ring';

  @override
  String get providerDetailWebsite => 'Webside';

  @override
  String get providerDetailSave => 'Gem';

  @override
  String get providerDetailSaved => 'Gemt';

  @override
  String get providerDetailOpen => 'Åben nu';

  @override
  String get providerDetailClosed => 'Lukket';

  @override
  String get providerDetailVerified => 'Verificeret';

  @override
  String get providerDetailOpeningHours => 'Åbningstider';

  @override
  String get providerDetailServices => 'Ydelser';

  @override
  String get providerDetailProducts => 'Produkter';

  @override
  String get providerDetailCharging => 'Opladningsinfo';

  @override
  String providerDetailDistanceAway(String distance) {
    return '$distance væk';
  }

  @override
  String providerDetailNoPorts(int count) {
    return '$count opladningsporte';
  }

  @override
  String get noProvidersNearby => 'Ingen CYKEL-udbydere i nærheden endnu.';

  @override
  String get noChargingStationsNearby => 'No charging stations nearby yet.';

  @override
  String get viewAllProviders => 'I nærheden';

  @override
  String get filterCykelRepair => 'Reparation';

  @override
  String get filterCykelShop => 'Forretninger';

  @override
  String get filterCykelCharging => 'Opladning';

  @override
  String get filterCykelService => 'Service';

  @override
  String get filterCykelRental => 'Udlejning';

  @override
  String get filterCykelAll => 'Alle CYKEL';

  @override
  String get listingBrandHint => 'Mærke';

  @override
  String get listingIsElectric => 'Elcykel';

  @override
  String get listingIsElectricHint => 'Slå til hvis dette er en elcykel';

  @override
  String get listingSerialHint => 'Serienummer';

  @override
  String get listingSerialHelp =>
      'At tilføje et serienummer hjælper med at verificere ægthed og forhindrer salg af stjålne cykler.';

  @override
  String get listingElectricBadge => 'Elektrisk';

  @override
  String get listingSerialVerified => 'Serienummer verificeret';

  @override
  String get listingSerialDuplicate => 'Duplikat serienummer';

  @override
  String get listingSerialUnverified => 'Serienummer uverificeret';

  @override
  String get locationsTitle => 'Lokationer';

  @override
  String get noLocationsYet => 'Ingen lokationer tilføjet endnu';

  @override
  String get addLocation => 'Tilføj lokation';

  @override
  String get editLocationTitle => 'Rediger lokation';

  @override
  String get addLocationTitle => 'Tilføj lokation';

  @override
  String get locationNameSection => 'Lokationsnavn';

  @override
  String get locationNameLabel => 'Navn';

  @override
  String get locationTypeLabel => 'Lokationstype';

  @override
  String get contactInfoSection => 'Kontaktoplysninger';

  @override
  String get photosSection => 'Fotos';

  @override
  String get locationSaved => 'Lokation gemt!';

  @override
  String get deleteLocationTitle => 'Slet lokation?';

  @override
  String get deleteLocationConfirm =>
      'Er du sikker på, at du vil slette denne lokation? Dette kan ikke fortrydes.';

  @override
  String get pauseLabel => 'Pause';

  @override
  String get activateLabel => 'Aktivér';

  @override
  String get deleteLabel => 'Slet';

  @override
  String get manageLocations => 'Administrér lokationer';

  @override
  String get manageListings => 'Administrér opslag';

  @override
  String get listingMarkAvailable => 'Markér som tilgængelig';

  @override
  String get listingStatusSold => 'Solgt';

  @override
  String get listingStatusActive => 'Aktiv';

  @override
  String get purchaseUnavailable => 'Køb er ikke tilgængeligt i øjeblikket';

  @override
  String get restorePurchases => 'Gendan køb';

  @override
  String get restorePurchasesDone => 'Køb gendannet';

  @override
  String get premiumFeatureBody =>
      'Denne funktion er tilgængelig med et Premium-abonnement.';

  @override
  String get routeEffort => 'Indsats';

  @override
  String get darkRidingAlert => 'Mørk kørsel';

  @override
  String get lowVisibility => 'Dårlig sigtbarhed';

  @override
  String get chargeSuggestion => 'Overvej at oplade før din tur';

  @override
  String get commuterTax => 'Kørselsfradrag';

  @override
  String get commuteDays => 'Pendlerdage';

  @override
  String get commuteKm => 'Pendler km';

  @override
  String get deductibleKm => 'Fradragsberettiget km';

  @override
  String estimatedDeduction(String amount) {
    return 'Anslået fradrag: $amount DKK';
  }

  @override
  String get hazardThunderstorm => 'Tordenvejr';

  @override
  String get batteryCapacity => 'Batterikapacitet';

  @override
  String get alertHeavyRainTitle => 'Kraftig regnvarsel';

  @override
  String alertHeavyRainMessage(String amount) {
    return 'Kraftig regn registreret (${amount}mm/t). Overvej indendørs aktiviteter.';
  }

  @override
  String get alertStrongWindTitle => 'Kraftig vindvarsel';

  @override
  String alertStrongWindMessage(String speed) {
    return 'Vinde op til $speed km/t. Kør forsigtigt.';
  }

  @override
  String get alertIceRiskTitle => 'Isrisiko';

  @override
  String get alertIceRiskMessage =>
      'Frosttemperaturer med nedbør. Vejene kan være glatte.';

  @override
  String get alertExtremeColdTitle => 'Ekstrem kuldevarsel';

  @override
  String alertExtremeColdMessage(String temp) {
    return 'Temperaturen er $temp°C. Klæd dig varmt på og overvej kortere ture.';
  }

  @override
  String get alertHighWindsTitle => 'Stormvarsel';

  @override
  String alertHighWindsMessage(String speed) {
    return 'Meget kraftige vinde ($speed km/t). Frarådes at cykle.';
  }

  @override
  String get alertFogTitle => 'Tågevarsel';

  @override
  String get alertFogMessage =>
      'Nedsat sigtbarhed på grund af tåge. Brug lys og reflekser.';

  @override
  String get alertDarknessTitle => 'Mørk kørsel';

  @override
  String get alertDarknessMessage =>
      'Det er mørkt. Brug for- og baglygter, bær reflekstøj.';

  @override
  String get alertSunsetTitle => 'Solnedgang nærmer sig';

  @override
  String alertSunsetMessage(String time) {
    return 'Solnedgang kl. $time. Medbring lygter.';
  }

  @override
  String get alertWinterIceTitle => 'Vinteris risiko';

  @override
  String get alertWinterIceMessage =>
      'Temperatur nær frysepunktet med fugt. Pas på is på broer og skyggefulde stier.';

  @override
  String get severityInfo => 'Info';

  @override
  String get severityCaution => 'Forsigtig';

  @override
  String get severityDanger => 'Fare';

  @override
  String get statusReported => 'Rapporteret';

  @override
  String get statusConfirmed => 'Bekræftet';

  @override
  String get statusUnderReview => 'Under behandling';

  @override
  String get statusResolved => 'Løst';

  @override
  String credibilityLabel(String score, String confirms, String dismisses) {
    return 'Troværdighed: $score% ($confirms ✓  $dismisses ✗)';
  }

  @override
  String get commuterTaxSettings => 'Befordringsfradrag';

  @override
  String get commuterTaxTitle => 'Befordringsfradrag';

  @override
  String get commuterTaxDescription =>
      'Indstil din hjemme- og arbejdsadresse for at beregne det danske befordringsfradrag for dine ture.';

  @override
  String get homeAddress => 'Hjemmeadresse';

  @override
  String get workAddress => 'Arbejdsadresse';

  @override
  String get savedSuccessfully => 'Gemt succesfuldt';

  @override
  String get confirmAction => 'Bekræft handling';

  @override
  String get confirmMaintenanceReset =>
      'Er du sikker på, at du vil markere vedligeholdelse som udført? Dette nulstiller din servicepåmindelse.';

  @override
  String get maintenanceMarkedDone => 'Vedligeholdelse markeret som udført';

  @override
  String get pageNotFound => 'Siden blev ikke fundet';

  @override
  String get goHome => 'Gå hjem';

  @override
  String get tryAgain => 'Prøv igen';

  @override
  String get validationEmailRequired => 'E-mail er påkrævet';

  @override
  String get validationEmailInvalid => 'Indtast en gyldig e-mailadresse';

  @override
  String get validationPasswordRequired => 'Adgangskode er påkrævet';

  @override
  String get validationPasswordTooShort =>
      'Adgangskoden skal være mindst 8 tegn';

  @override
  String get validationConfirmPasswordRequired =>
      'Bekræft venligst din adgangskode';

  @override
  String get validationPasswordsDoNotMatch => 'Adgangskoderne matcher ikke';

  @override
  String get validationNameRequired => 'Navn er påkrævet';

  @override
  String get validationNameTooShort => 'Navnet er for kort';

  @override
  String get validationPhoneInvalid => 'Indtast et gyldigt dansk telefonnummer';

  @override
  String get validationPostalCodeRequired => 'Postnummer er påkrævet';

  @override
  String get validationPostalCodeInvalid =>
      'Indtast et gyldigt 4-cifret postnummer';

  @override
  String get validationPostalCodeRange =>
      'Postnummer skal være mellem 1000 og 9990';

  @override
  String validationFieldRequired(String field) {
    return '$field er påkrævet';
  }

  @override
  String get validationPriceRequired => 'Pris er påkrævet';

  @override
  String get validationPriceInvalid => 'Indtast en gyldig pris';

  @override
  String get validationPriceTooHigh => 'Prisen er for høj';

  @override
  String get validationSerialTooShort => 'Serienummeret er for kort';

  @override
  String get validationSerialTooLong => 'Serienummeret er for langt';

  @override
  String get validationUrlInvalid => 'Indtast en gyldig URL (https://...)';

  @override
  String get showPassword => 'Vis adgangskode';

  @override
  String get hidePassword => 'Skjul adgangskode';

  @override
  String get goBack => 'Gå tilbage';

  @override
  String get close => 'Luk';

  @override
  String get clearSearch => 'Ryd søgning';

  @override
  String get swapLocations => 'Byt lokationer';

  @override
  String get openChats => 'Åbn beskeder';

  @override
  String get removeFromSaved => 'Fjern fra gemte';

  @override
  String get saveListing => 'Gem annonce';

  @override
  String get maintenance => 'Vedligeholdelse';

  @override
  String get settings => 'Indstillinger';

  @override
  String get share => 'Del';

  @override
  String get delete => 'Slet';

  @override
  String get edit => 'Rediger';

  @override
  String get search => 'Søg';

  @override
  String get joinChallenge => 'Deltag i udfordring';

  @override
  String get accept => 'Accepter';

  @override
  String get decline => 'Afvis';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Genoptag';

  @override
  String get refresh => 'Opdater';

  @override
  String get sendComment => 'Send kommentar';

  @override
  String get friendRequests => 'Venneanmodninger';

  @override
  String get searchUsers => 'Søg brugere';

  @override
  String get like => 'Synes godt om';

  @override
  String get comment => 'Kommentar';

  @override
  String get comments => 'Kommentarer';

  @override
  String get download => 'Download';

  @override
  String errorPrefix(String error) {
    return 'Fejl';
  }

  @override
  String get groupRides => 'Gruppeture';

  @override
  String get eventsTabAll => 'Alle';

  @override
  String get eventsTabMine => 'Mine ture';

  @override
  String get eventsTabCreated => 'Oprettet';

  @override
  String get createEvent => 'Opret tur';

  @override
  String get discoverGroupRides => 'OPDAG';

  @override
  String get popularEvents => 'Populære ture';

  @override
  String get upcomingEvents => 'Kommende';

  @override
  String get viewAll => 'Se alle';

  @override
  String get noUpcomingEvents => 'Ingen kommende ture';

  @override
  String get beFirstToCreate => 'Vær den første til at oprette en fællestur!';

  @override
  String get noJoinedEvents => 'Ingen tilmeldte ture';

  @override
  String get joinEventToSeeHere => 'Tilmeld dig en tur for at se dem her';

  @override
  String get noCreatedEvents => 'Ingen oprettede ture';

  @override
  String get createYourFirstEvent => 'Opret din første fællestur!';

  @override
  String get joinedBadge => 'Tilmeldt';

  @override
  String get organizerBadge => 'Arrangør';

  @override
  String get noDropTooltip => 'No-drop: Gruppen venter på alle';

  @override
  String get todayBadge => 'I dag';

  @override
  String get searchEvents => 'Søg efter ture...';

  @override
  String get searchEventsHint => 'Søg ture efter navn';

  @override
  String get noEventsFound => 'Ingen ture fundet';

  @override
  String get eventError => 'Fejl';

  @override
  String get eventNotFound => 'Ikke fundet';

  @override
  String get eventNotFoundMessage => 'Begivenheden blev ikke fundet';

  @override
  String get editEvent => 'Rediger';

  @override
  String get cancelEvent => 'Aflys';

  @override
  String get deleteEvent => 'Slet';

  @override
  String get dateAndTime => 'Dato og tid';

  @override
  String get timePrefix => 'Kl.';

  @override
  String estimatedDuration(String hours) {
    return 'Estimeret varighed: $hours timer';
  }

  @override
  String get meetingPoint => 'Mødested';

  @override
  String get navigateToMeetingPoint => 'Naviger';

  @override
  String get eventDescription => 'Beskrivelse';

  @override
  String get rideDetails => 'Detaljer';

  @override
  String get kmUnit => 'km';

  @override
  String get kmhUnit => 'km/t';

  @override
  String get elevationUnit => 'm stigning';

  @override
  String get lightsRequired => 'Lys påkrævet';

  @override
  String get eventOrganizer => 'Arrangør';

  @override
  String get organizerLabel => 'Arrangør';

  @override
  String get participants => 'Deltagere';

  @override
  String get peopleJoined => 'personer tilmeldt';

  @override
  String get noParticipantsYet => 'Ingen deltagere endnu';

  @override
  String get eventFull => 'Fuld';

  @override
  String get openChat => 'Åbn chat';

  @override
  String get leaveEvent => 'Forlad';

  @override
  String get chat => 'Chat';

  @override
  String get eventIsFull => 'Begivenheden er fuld';

  @override
  String get joinEvent => 'Tilmeld';

  @override
  String get discoverEvents => 'Udforsk';

  @override
  String get youAreJoined => 'Du er nu tilmeldt!';

  @override
  String get youAreLeft => 'Du har forladt begivenheden';

  @override
  String get chatComingSoon => 'Chat kommer snart!';

  @override
  String get eventCancelled => 'Begivenhed aflyst';

  @override
  String get eventDeleted => 'Begivenhed slettet';

  @override
  String get leaveEventQuestion => 'Forlad begivenhed?';

  @override
  String get leaveEventConfirm =>
      'Er du sikker på, at du vil forlade denne tur?';

  @override
  String get cancelEventQuestion => 'Aflys begivenhed?';

  @override
  String get cancelEventConfirm =>
      'Er du sikker på, at du vil aflyse denne tur? Alle deltagere vil blive underrettet.';

  @override
  String get deleteEventQuestion => 'Slet begivenhed?';

  @override
  String get deleteEventConfirm =>
      'Er du sikker på, at du vil slette denne tur? Dette kan ikke fortrydes.';

  @override
  String get cancelButton => 'Annuller';

  @override
  String get confirmCancel => 'Aflys begivenhed';

  @override
  String get confirmDelete => 'Slet';

  @override
  String get shareEventText => 'Deltag i CYKEL appen!';

  @override
  String get repeatsLabel => 'Gentages';

  @override
  String get noDropPolicy => 'No-drop politik';

  @override
  String get noDropDescription => 'Gruppen venter på alle';

  @override
  String get createGroupRide => 'Opret fællestur';

  @override
  String get basicInfo => 'Grundlæggende info';

  @override
  String get eventTitle => 'Titel *';

  @override
  String get eventTitleHint => 'f.eks. Søndag morgen fællestur';

  @override
  String get titleRequired => 'Titel er påkrævet';

  @override
  String get eventDescriptionLabel => 'Beskrivelse';

  @override
  String get eventDescriptionHint => 'Beskriv turen...';

  @override
  String get eventType => 'Type';

  @override
  String get difficultyLevel => 'Sværhedsgrad';

  @override
  String get dateAndTimeSection => 'Dato og tid';

  @override
  String get dateLabel => 'Dato';

  @override
  String get meetingPointSection => 'Mødested';

  @override
  String get placeNameHint => 'f.eks. Københavns Rådhus';

  @override
  String get address => 'Adresse *';

  @override
  String get addressHint => 'Søg efter adresse...';

  @override
  String get addressRequired => 'Adresse er påkrævet';

  @override
  String get searchingAddress => 'Søger...';

  @override
  String get rideDetailsSection => 'Turdetaljer';

  @override
  String get distanceKm => 'Distance (km)';

  @override
  String get durationMin => 'Varighed (min)';

  @override
  String get paceKmh => 'Tempo (km/t)';

  @override
  String get elevationGainM => 'Stigning (m)';

  @override
  String get maxParticipants => 'Maks deltagere';

  @override
  String get settingsSection => 'Indstillinger';

  @override
  String get lightsRequiredToggle => 'Lys påkrævet';

  @override
  String get lightsRequiredDescription => 'Til aften-/natture';

  @override
  String get visibility => 'Synlighed';

  @override
  String get visibilityPublic => 'Offentlig';

  @override
  String get visibilityPrivate => 'Privat';

  @override
  String get createEventButton => 'Opret fællestur';

  @override
  String get couldNotFindCoordinates => 'Kunne ikke finde koordinater';

  @override
  String get noAddressesFound => 'Ingen adresser fundet';

  @override
  String get searchForAddressFirst => 'Søg efter en adresse først';

  @override
  String get mustBeLoggedIn => 'Du skal være logget ind';

  @override
  String get eventCreated => 'Fællestur oprettet!';

  @override
  String get couldNotFindAddress => 'Kunne ikke finde adresse';

  @override
  String get difficultyEasy => 'Let';

  @override
  String get difficultyModerate => 'Moderat';

  @override
  String get difficultyChallenging => 'Udfordrende';

  @override
  String get difficultyHard => 'Hård';

  @override
  String get eventTypeSocial => 'Social';

  @override
  String get eventTypeTraining => 'Træning';

  @override
  String get eventTypeCommute => 'Pendling';

  @override
  String get eventTypeTour => 'Tur';

  @override
  String get eventTypeRace => 'Løb';

  @override
  String get eventTypeGravel => 'Gravel';

  @override
  String get eventTypeMtb => 'MTB';

  @override
  String get eventTypeBeginner => 'Begyndervenlig';

  @override
  String get eventTypeFamily => 'Familiecykling';

  @override
  String get eventTypeNight => 'Nattur';

  @override
  String get visibilityFriends => 'Kun venner';

  @override
  String get visibilityInviteOnly => 'Kun inviterede';

  @override
  String get eventStatusUpcoming => 'Kommende';

  @override
  String get eventStatusActive => 'I gang';

  @override
  String get eventStatusCompleted => 'Afsluttet';

  @override
  String get eventStatusCancelled => 'Aflyst';

  @override
  String get eventDateTimePast =>
      'Begivenhedens dato/tid kan ikke være i fortiden';

  @override
  String get challenges => 'Udfordringer';

  @override
  String get yourActiveChallenges => 'Dine aktive udfordringer';

  @override
  String get availableChallenges => 'Tilgængelige udfordringer';

  @override
  String joinedChallenge(String title) {
    return 'Du er nu med i \"$title\"!';
  }

  @override
  String get level => 'Niveau';

  @override
  String get points => 'Point';

  @override
  String get badges => 'Badges';

  @override
  String levelProgress(int current, int next) {
    return 'Niveau $current → Niveau $next';
  }

  @override
  String pointsToNextLevel(int points) {
    return '$points point til næste niveau';
  }

  @override
  String get challengeTypeDistance => 'Distance';

  @override
  String get challengeTypeRideCount => 'Antal ture';

  @override
  String get challengeTypeElevation => 'Stigning';

  @override
  String get challengeTypeStreak => 'Streak';

  @override
  String get challengeTypeCommunity => 'Fællesskab';

  @override
  String get challengeTypeSpeed => 'Hastighed';

  @override
  String get challengeTypeExplore => 'Udforsk';

  @override
  String challengePoints(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'point',
      one: 'point',
    );
    return '$points $_temp0';
  }

  @override
  String get difficultyLevelEasy => 'Let';

  @override
  String get difficultyLevelMedium => 'Mellem';

  @override
  String get difficultyLevelHard => 'Svær';

  @override
  String get difficultyLevelExtreme => 'Ekstrem';

  @override
  String get badgesTitle => 'Badges';

  @override
  String badgesEarnedOf(int earned, int total) {
    return '$earned af $total';
  }

  @override
  String get badgesEarned => 'badges optjent';

  @override
  String percentComplete(String percent) {
    return '$percent% færdig';
  }

  @override
  String get badgeEarned => 'Optjent!';

  @override
  String get badgeKeepRiding =>
      'Bliv ved med at cykle for at optjene dette badge!';

  @override
  String get rarityCommon => 'Almindelig';

  @override
  String get rarityUncommon => 'Ualmindelig';

  @override
  String get rarityRare => 'Sjælden';

  @override
  String get rarityEpic => 'Episk';

  @override
  String get rarityLegendary => 'Legendarisk';

  @override
  String get leaderboard => 'Rangliste';

  @override
  String get leaderboardYou => 'Dig';

  @override
  String get noDataYet => 'Ingen data endnu';

  @override
  String get startRidingToJoin => 'Begynd at cykle for at komme på ranglisten!';

  @override
  String get periodThisWeek => 'Denne uge';

  @override
  String get periodThisMonth => 'Denne måned';

  @override
  String get periodAllTime => 'Al tid';

  @override
  String get bikeMaintenanceTitle => 'Vedligeholdelse';

  @override
  String get serviceHistory => 'Servicehistorik';

  @override
  String get addService => 'Tilføj service';

  @override
  String get bikeCondition => 'Cykelens tilstand';

  @override
  String get kmRidden => 'km kørt';

  @override
  String get overdueAlert => 'Overskredet';

  @override
  String get dueSoonAlert => 'Snart';

  @override
  String get noServiceHistory => 'Ingen servicehistorik endnu';

  @override
  String get addFirstService =>
      'Tilføj din første service for at spore vedligeholdelse';

  @override
  String get serviceType => 'Type';

  @override
  String get serviceDate => 'Dato';

  @override
  String get serviceKilometers => 'Kilometer ved service';

  @override
  String get servicePriceOptional => 'Pris (valgfrit)';

  @override
  String get serviceShopOptional => 'Værksted (valgfrit)';

  @override
  String get serviceNotesOptional => 'Noter (valgfrit)';

  @override
  String get enterKilometers => 'Indtast kilometer';

  @override
  String get invalidValue => 'Ugyldig værdi';

  @override
  String get saveButton => 'Gem';

  @override
  String get deleteService => 'Slet service?';

  @override
  String get deleteServiceConfirm =>
      'Er du sikker på, at du vil slette denne service?';

  @override
  String get kilometers => 'Kilometer';

  @override
  String get price => 'Pris';

  @override
  String get workshop => 'Værksted';

  @override
  String get notes => 'Noter';

  @override
  String get nextService => 'Næste service';

  @override
  String get notLoggedIn => 'Ikke logget ind';

  @override
  String currencyDkk(String amount) {
    return '$amount DKK';
  }

  @override
  String get serviceTypeTireChange => 'Dækskift';

  @override
  String get serviceTypeBrakes => 'Bremser';

  @override
  String get serviceTypeChain => 'Kæde';

  @override
  String get serviceTypeGears => 'Gear';

  @override
  String get serviceTypeFullService => 'Fuld service';

  @override
  String get serviceTypeLights => 'Lys';

  @override
  String get serviceTypeWheels => 'Hjul';

  @override
  String get serviceTypeOther => 'Andet';

  @override
  String get community => 'Fællesskab';

  @override
  String get theftAlerts => 'Tyverialarm';

  @override
  String get theftNearby => 'I nærheden';

  @override
  String get theftAll => 'Alle';

  @override
  String get theftMine => 'Mine';

  @override
  String get theftReport => 'Anmeld tyveri';

  @override
  String theftError(String error) {
    return 'Fejl: $error';
  }

  @override
  String get theftNoNearby => 'Ingen tyverier i nærheden';

  @override
  String theftNoNearbyDesc(String radius) {
    return 'Der er ingen aktive tyveri-anmeldelser inden for $radius km';
  }

  @override
  String get theftNoActive => 'Ingen aktive anmeldelser';

  @override
  String get theftNoActiveDesc =>
      'Der er ingen aktive tyveri-anmeldelser lige nu';

  @override
  String get theftNoReports => 'Ingen anmeldelser';

  @override
  String get theftNoReportsDesc => 'Du har ikke anmeldt nogen cykeltyverier';

  @override
  String theftMinutesAgo(int minutes) {
    return '$minutes min siden';
  }

  @override
  String theftHoursAgo(int hours) {
    return '$hours timer siden';
  }

  @override
  String theftDaysAgo(int days) {
    return '$days dage siden';
  }

  @override
  String get theftReportTitle => 'Anmeld cykeltyveri';

  @override
  String get theftNoBikes =>
      'Du har ingen cykler registreret. Tilføj din cykel først under \"Mine cykler\".';

  @override
  String get theftSelectBike => 'Vælg cykel';

  @override
  String get theftSelectBikeError => 'Vælg en cykel';

  @override
  String get theftCouldNotLoadBikes => 'Kunne ikke hente cykler';

  @override
  String get theftBikeDescription => 'Beskrivelse af cyklen';

  @override
  String get theftBikeDescriptionHint =>
      'Farve, størrelse, særlige kendetegn...';

  @override
  String get theftDescriptionRequired => 'Angiv beskrivelse';

  @override
  String get theftFrameNumber => 'Stelnummer (valgfrit)';

  @override
  String get theftArea => 'Område (f.eks. Nørrebro)';

  @override
  String get theftAdditionalNotes => 'Yderligere oplysninger (valgfrit)';

  @override
  String get theftAdditionalNotesHint => 'Hvornår/hvor så du den sidst...';

  @override
  String get theftContactInfo => 'Kontaktinfo (valgfrit)';

  @override
  String get theftContactInfoHint => 'Telefon eller email';

  @override
  String get theftNotLoggedIn => 'Ikke logget ind';

  @override
  String get theftReportSuccess =>
      'Tyveri anmeldt! Andre cyklister vil blive advaret.';

  @override
  String get theftAreaLabel => 'Område';

  @override
  String get theftFrameNumberLabel => 'Stelnummer';

  @override
  String get theftNotesLabel => 'Bemærkninger';

  @override
  String get theftContactLabel => 'Kontakt';

  @override
  String get theftMarkRecovered => 'Marker som fundet';

  @override
  String get theftCloseReport => 'Luk anmeldelse';

  @override
  String get theftSeenThisBike => 'Jeg har set denne cykel!';

  @override
  String get theftRecoveredSuccess =>
      'Tillykke! Din cykel er markeret som fundet.';

  @override
  String get theftSightingThanks => 'Tak! Ejeren vil blive underrettet.';

  @override
  String get theftAlarmSettings => 'Alarm-indstillinger';

  @override
  String get theftEnableAlarms => 'Aktiver alarmer';

  @override
  String get theftRadius => 'Radius';

  @override
  String theftRadiusKm(String radius) {
    return '$radius km';
  }

  @override
  String get theftNewThefts => 'Nye tyverier';

  @override
  String get theftNewTheftsDesc => 'Få besked når en cykel anmeldes stjålet';

  @override
  String get theftSightings => 'Observationer';

  @override
  String get theftSightingsDesc =>
      'Få besked når nogen har set en stjålet cykel';

  @override
  String get theftRecoveries => 'Fundne cykler';

  @override
  String get theftRecoveriesDesc => 'Få besked når en cykel bliver fundet';

  @override
  String get theftStatusActive => 'Aktiv';

  @override
  String get theftStatusRecovered => 'Fundet';

  @override
  String get theftStatusClosed => 'Lukket';

  @override
  String get aiRouteSuggestions => 'AI ruteforslag';

  @override
  String get offlineMaps => 'Offline kort';

  @override
  String get chooseTheme => 'Vælg tema';

  @override
  String get lightTheme => 'Lyst tema';

  @override
  String get darkTheme => 'Mørkt tema';

  @override
  String get systemTheme => 'Systemtema';

  @override
  String get autoTheme => 'Auto (solopgang/solnedgang)';

  @override
  String get followsDeviceSettings => 'Følger enhedsindstillinger';

  @override
  String get automatic => 'Automatisk';

  @override
  String get changesAtSunriseSunset => 'Skifter ved solopgang/solnedgang';

  @override
  String get dataExportTitle => 'CYKEL data eksport';

  @override
  String get dataExportSubject => 'Din komplette CYKEL data eksport';

  @override
  String get speedUnit => 'km/t';

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}t ${minutes}min';
  }

  @override
  String get socialActivityTab => 'Aktivitet';

  @override
  String get socialFriendsTab => 'Venner';

  @override
  String get socialMyRidesTab => 'Mine ture';

  @override
  String socialErrorLoading(String error) {
    return 'Fejl: $error';
  }

  @override
  String get socialNoActivity => 'Ingen aktivitet endnu';

  @override
  String get socialAddFriends => 'Tilføj venner for at se deres ture';

  @override
  String get socialNoFriends => 'Ingen venner endnu';

  @override
  String get socialSearchCyclists =>
      'Søg efter andre cyklister og tilføj dem som venner';

  @override
  String get socialNoSharedRides => 'Ingen delte ture';

  @override
  String get socialShareRides => 'Del dine cykelture med dine venner';

  @override
  String socialTotalKm(String km) {
    return '$km km total';
  }

  @override
  String get socialRemoveFriend => 'Fjern ven';

  @override
  String get socialRemoveFriendQuestion => 'Fjern ven?';

  @override
  String socialConfirmRemoveFriend(String name) {
    return 'Er du sikker på, at du vil fjerne $name som ven?';
  }

  @override
  String get socialRemove => 'Fjern';

  @override
  String get socialFriendRemoved => 'Ven fjernet';

  @override
  String socialMinutesAgo(int minutes) {
    return '$minutes min siden';
  }

  @override
  String socialHoursAgo(int hours) {
    return '$hours timer siden';
  }

  @override
  String socialDaysAgo(int days) {
    return '$days dage siden';
  }

  @override
  String get socialDeleteRideQuestion => 'Slet delt tur?';

  @override
  String get socialConfirmDeleteRide =>
      'Er du sikker på, at du vil slette denne delte tur?';

  @override
  String get socialReceived => 'Modtagne';

  @override
  String get socialNoRequests => 'Ingen anmodninger';

  @override
  String get socialSent => 'Afsendte';

  @override
  String get socialNoSentRequests => 'Ingen afsendte anmodninger';

  @override
  String get socialFriendAdded => 'Ven tilføjet!';

  @override
  String get socialFindCyclists => 'Find cyklister';

  @override
  String get socialSearchByName => 'Søg efter navn...';

  @override
  String get socialAdd => 'Tilføj';

  @override
  String get socialFriendRequestSent => 'Venneanmodning sendt!';

  @override
  String get socialNoComments => 'Ingen kommentarer endnu';

  @override
  String get socialWriteComment => 'Skriv en kommentar...';

  @override
  String socialMinutesAgoShort(int minutes) {
    return '${minutes}m';
  }

  @override
  String socialHoursAgoShort(int hours) {
    return '${hours}t';
  }

  @override
  String socialDaysAgoShort(int days) {
    return '${days}d';
  }

  @override
  String get routeSuggestions => 'Ruteforslag';

  @override
  String get routeSuggestionsTab => 'Forslag';

  @override
  String get routeHistoryTab => 'Historik';

  @override
  String get routeSavedTab => 'Gemte';

  @override
  String get routeNoSuggestions => 'Ingen forslag endnu';

  @override
  String get routeNoSuggestionsDesc =>
      'Brug appen til at cykle nogle ture, så lærer vi dine præferencer';

  @override
  String get routeAiTitle => 'AI Ruteforslag';

  @override
  String get routeAiDesc => 'Baseret på dine vaner, vejret og tidspunktet';

  @override
  String get routeNoHistory => 'Ingen rutehistorik';

  @override
  String get routeNoHistoryDesc => 'Dine hyppigst brugte ruter vises her';

  @override
  String routeStatsPattern(int duration, String lastUsed) {
    return '~$duration min • Sidst: $lastUsed';
  }

  @override
  String get routeDefaultName => 'Rute';

  @override
  String routeMinutesAgo(int minutes) {
    return '$minutes min';
  }

  @override
  String routeHoursAgo(int hours) {
    return '$hours timer';
  }

  @override
  String routeDaysAgo(int days) {
    return '$days dage';
  }

  @override
  String get routeNoSaved => 'Ingen gemte ruter';

  @override
  String get routeNoSavedDesc => 'Gem dine yndlingsruter for hurtig adgang';

  @override
  String get routeSettings => 'Rute indstillinger';

  @override
  String get routePreferences => 'Præferencer';

  @override
  String get routeAvoidHills => 'Undgå bakker';

  @override
  String get routeAvoidHillsDesc => 'Foreslå fladere ruter';

  @override
  String get routePreferBikeLanes => 'Foretruk cykelstier';

  @override
  String get routePreferBikeLanesDesc => 'Prioritér ruter med cykelstier';

  @override
  String get routePreferLitRoutes => 'Foretruk oplyste ruter';

  @override
  String get routePreferLitRoutesDesc =>
      'Prioritér godt oplyste ruter om natten';

  @override
  String get routeAiSuggestions => 'AI Forslag';

  @override
  String get routeBasedOnHistory => 'Baseret på historik';

  @override
  String get routeBasedOnHistoryDesc => 'Brug dine tidligere ture';

  @override
  String get routeBasedOnWeather => 'Baseret på vejret';

  @override
  String get routeBasedOnWeatherDesc => 'Tilpas forslag efter vejret';

  @override
  String get routeBasedOnTime => 'Baseret på tidspunkt';

  @override
  String get routeBasedOnTimeDesc => 'Tilpas forslag efter klokkeslæt';

  @override
  String get exportSubject => 'CYKEL Dataeksport';

  @override
  String get exportMessage => 'Din komplette CYKEL dataeksport';

  @override
  String get notLoggedInError => 'Ikke logget ind';

  @override
  String get notSet => 'Ikke angivet';

  @override
  String get authenticateBiometric => 'Godkend for at aktivere biometrisk lås';

  @override
  String get biometricAuthFailed =>
      'Godkendelse mislykkedes. Biometrisk lås ikke aktiveret.';

  @override
  String get biometricEnabled => 'Biometrisk lås aktiveret';

  @override
  String get biometricDisabled => 'Biometrisk lås deaktiveret';

  @override
  String lockWith(String type) {
    return 'Lås med $type';
  }

  @override
  String get biometricLockDesc => 'Kræv godkendelse ved åbning af app';

  @override
  String get offlineMapsTitle => 'Offline kort';

  @override
  String get downloadedRegions => 'Downloadede områder';

  @override
  String get availableRegions => 'Tilgængelige områder';

  @override
  String get downloadMapsForOfflineNav =>
      'Download kort for at bruge navigation offline';

  @override
  String get downloadCustomRegion => 'Download brugerdefineret område';

  @override
  String get deleteOfflineMaps => 'Slet offline kort?';

  @override
  String confirmDeleteRegion(String regionName) {
    return 'Er du sikker på, at du vil slette \"$regionName\"?';
  }

  @override
  String startingDownload(String regionName) {
    return 'Begynder download af $regionName';
  }

  @override
  String get storage => 'Lagring';

  @override
  String get noDownloadedMaps => 'Ingen downloadede kort';

  @override
  String get downloadMapsToUseOffline =>
      'Download kort for at bruge appen uden internet';

  @override
  String get downloaded => 'Downloadet';

  @override
  String get downloading => 'Downloader...';

  @override
  String percentDownloaded(int percent) {
    return '$percent% downloadet';
  }

  @override
  String get downloadError => 'Fejl under download';

  @override
  String get pending => 'Afventer...';

  @override
  String get selectRegion => 'Vælg område';

  @override
  String get selectRegionOnMap => 'Vælg et område på kortet for at downloade';

  @override
  String get regionName => 'Navn på område';

  @override
  String get downloadRegion => 'Download område';

  @override
  String get enterRegionName => 'Angiv et navn for området';

  @override
  String get offlineSettings => 'Offline indstillinger';

  @override
  String get autoDownloadOnWifi => 'Auto-download på WiFi';

  @override
  String get autoDownloadOnWifiDesc => 'Download automatisk kort når på WiFi';

  @override
  String get downloadRouteBuffer => 'Download rute-buffer';

  @override
  String get downloadRouteBufferDesc => 'Download kort omkring dine ruter';

  @override
  String get maxStorage => 'Maks lagring';

  @override
  String get deleteAllOfflineMaps => 'Slet alle offline kort';

  @override
  String get deleteAllOfflineMapsConfirm => 'Slet alle offline kort?';

  @override
  String get deleteAllOfflineMapsDesc =>
      'Dette vil slette alle downloadede kort. Du kan downloade dem igen senere.';

  @override
  String get deleteAll => 'Slet alle';

  @override
  String get allOfflineMapsDeleted => 'Alle offline kort slettet';

  @override
  String get eventInstructions => 'Instruktioner (valgfrit)';

  @override
  String get eventInstructionsHint => 'F.eks. Vi mødes ved cykelparkering';

  @override
  String get searchAddressFirst => 'Søg efter en adresse først';

  @override
  String get groupRideCreated => 'Gruppetur oprettet!';

  @override
  String get updateEvent => 'Opdater Begivenhed';

  @override
  String get eventUpdated => 'Begivenhed opdateret';

  @override
  String get error => 'Fejl';

  @override
  String get upcomingGroupRides => 'Kommende gruppeture';

  @override
  String get seeAll => 'Se alle';

  @override
  String get findGroupRides => 'Find gruppeture';

  @override
  String get discoverLocalRides => 'Opdag og deltag i lokale cykelture';

  @override
  String get noBiometricsAvailable =>
      'Denne enhed har ikke biometrisk godkendelse (fingeraftryk eller ansigtsgenkendelse)';

  @override
  String get noBiometricsTitle => 'Biometri ikke tilgængelig';

  @override
  String get groupChat => 'Gruppechat';

  @override
  String get noMessagesYet => 'Ingen beskeder endnu';

  @override
  String get beFirstToMessage => 'Vær den første til at sende en besked!';

  @override
  String get typeMessage => 'Skriv en besked...';

  @override
  String get signInToChat => 'Log ind for at sende beskeder';

  @override
  String get viewOnMap => 'Se på kort';
}
