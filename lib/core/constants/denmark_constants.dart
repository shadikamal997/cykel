/// CYKEL — Denmark-Specific Constants
/// All local data for DK launch

class DenmarkConstants {
  DenmarkConstants._();

  // --- Geography ---
  static const double centerLatitude = 56.2639;
  static const double centerLongitude = 9.5018;
  static const double defaultZoom = 7.0; // Country-wide view

  // --- Major Cities ---
  static const List<String> majorCities = [
    'København',
    'Aarhus',
    'Odense',
    'Aalborg',
    'Esbjerg',
    'Randers',
    'Kolding',
    'Horsens',
    'Vejle',
    'Roskilde',
    'Helsingør',
    'Næstved',
    'Fredericia',
    'Viborg',
    'Silkeborg',
    'Frederiksberg',
    'Herning',
    'Slagelse',
    'Sønderborg',
    'Hillerød',
    'Holstebro',
    'Taastrup',
    'Svendborg',
    'Ballerup',
    'Gladsaxe',
    'Holbæk',
    'Hjørring',
    'Haderslev',
    'Skive',
    'Ringsted',
    'Køge',
    'Frederikshavn',
    'Greve',
    'Nykøbing Falster',
    'Ikast',
  ];

  // --- Postal Code Format ---
  /// Danish postal codes are exactly 4 digits: 1000–9990
  static const int postalCodeLength = 4;
  static final RegExp postalCodeRegex = RegExp(r'^\d{4}$');
  static const int postalCodeMin = 1000;
  static const int postalCodeMax = 9990;

  // --- Address Format ---
  /// Danish address: [Street] [Number], [PostalCode] [City]
  /// Example: Strøget 1, 1100 København K
  static const String addressFormat = '{street} {number}, {postalCode} {city}';

  // --- DAWA API ---
  static const String dawaBaseUrl = 'https://api.dataforsyningen.dk';
  static const String dawaAutocompleteEndpoint =
      '/adresser/autocomplete';
  static const String dawaAddressEndpoint = '/adresser';
  static const String dawaPostalCodeEndpoint = '/postnumre';

  // --- DMI / Weather ---
  /// Open-Meteo base URL (free, no key, Denmark-accurate)
  static const String openMeteoBaseUrl = 'https://api.open-meteo.com/v1/forecast';

  // --- Wind Thresholds (m/s) ---
  static const double windLightMax = 3.3;     // Calm / light breeze
  static const double windModerateMax = 7.9;  // Moderate — noticeable
  static const double windStrongMax = 8.0;    // Strong — noticeably hard cycling (~29 km/h)
  static const double windVeryStrong = 13.9;  // Dangerous — not recommended

  // --- Temperature Thresholds (°C) ---
  static const double iceRiskTemp = 2.0;       // Ice risk threshold
  static const double coldRidingTemp = 5.0;    // Cold — gear up alert
  static const double idealMinTemp = 10.0;     // Comfortable minimum
  static const double idealMaxTemp = 25.0;     // Comfortable maximum

  // --- Tax Deduction (Denmark 2026) ---
  /// Danish commuter tax deduction (befordringsfradrag) kicks in after 24 km per day (round trip)
  static const double taxDeductionMinKmPerDay = 24.0;
  
  /// Standard deduction rate for 24-120 km per day (DKK/km)
  static const double taxDeductionStandardRate = 1.98;  // DKK per km (2026 rate)
  
  /// Higher distance deduction rate for above 120 km per day (DKK/km)
  static const double taxDeductionHigherRate = 0.99;  // DKK per km (2026 rate)
  
  /// Threshold where lower rate kicks in (km per day)
  static const double taxDeductionHigherThreshold = 120.0;
  
  /// Maximum work days per year for tax calculation
  static const int taxMaxWorkDaysPerYear = 230;
  
  /// Estimated average marginal tax rate in Denmark (for savings calculation)
  /// Used to convert deductions to actual tax savings
  /// Typical range: 37-55%, using 42% as reasonable average
  static const double averageMarginalTaxRate = 0.42;

  // --- Supported Characters ---
  /// Danish special characters
  static const List<String> danishSpecialChars = ['Æ', 'Ø', 'Å', 'æ', 'ø', 'å'];

  // --- E-Bike / Cargo Typical Battery ---
  static const double typicalEbikeCapacityWh = 500.0;    // Wh
  static const double typicalCargoCapacityWh = 700.0;    // Wh
  static const double typicalWhPerKm = 15.0;             // Average Wh/km
  static const double cargoLoadedWhPerKm = 25.0;         // Loaded cargo Wh/km
}
