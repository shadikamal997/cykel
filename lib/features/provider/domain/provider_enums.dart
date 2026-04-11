/// CYKEL — Provider System Enums
/// All enumerations for the five provider types:
/// Repair/Garage Shops, Bike Retail Shops, E-Bike Charging Locations,
/// Service Points, and Rental Services.

// ─── Provider Type ────────────────────────────────────────────────────────────

enum ProviderType {
  repairShop,
  bikeShop,
  chargingLocation,
  servicePoint,
  rental;

  String get key => switch (this) {
        ProviderType.repairShop => 'repair_shop',
        ProviderType.bikeShop => 'bike_shop',
        ProviderType.chargingLocation => 'charging_location',
        ProviderType.servicePoint => 'service_point',
        ProviderType.rental => 'rental',
      };

  static ProviderType fromKey(String s) => switch (s) {
        'bike_shop' => ProviderType.bikeShop,
        'charging_location' => ProviderType.chargingLocation,
        'service_point' => ProviderType.servicePoint,
        'rental' => ProviderType.rental,
        _ => ProviderType.repairShop,
      };
}

// ─── Verification Status ──────────────────────────────────────────────────────

enum VerificationStatus {
  pending,
  approved,
  rejected;

  String get key => name;

  static VerificationStatus fromKey(String s) => switch (s) {
        'approved' => VerificationStatus.approved,
        'rejected' => VerificationStatus.rejected,
        _ => VerificationStatus.pending,
      };
}

// ─── Repair Services ──────────────────────────────────────────────────────────

enum RepairService {
  flatTireRepair,
  brakeService,
  gearAdjustment,
  chainReplacement,
  wheelTruing,
  suspensionService,
  ebikeDiagnostics,
  fullTuneUp,
  emergencyRepair,
  safetyInspection,
  mobileRepair;

  String get key => switch (this) {
        RepairService.flatTireRepair => 'flat_tire_repair',
        RepairService.brakeService => 'brake_service',
        RepairService.gearAdjustment => 'gear_adjustment',
        RepairService.chainReplacement => 'chain_replacement',
        RepairService.wheelTruing => 'wheel_truing',
        RepairService.suspensionService => 'suspension_service',
        RepairService.ebikeDiagnostics => 'ebike_diagnostics',
        RepairService.fullTuneUp => 'full_tuneup',
        RepairService.emergencyRepair => 'emergency_repair',
        RepairService.safetyInspection => 'safety_inspection',
        RepairService.mobileRepair => 'mobile_repair',
      };

  static RepairService fromKey(String s) => RepairService.values.firstWhere(
        (e) => e.key == s,
        orElse: () => RepairService.flatTireRepair,
      );
}

// ─── Supported Bike Types ─────────────────────────────────────────────────────

enum BikeType {
  cityBike,
  roadBike,
  mtb,
  cargoBike,
  ebike;

  String get key => switch (this) {
        BikeType.cityBike => 'city_bike',
        BikeType.roadBike => 'road_bike',
        BikeType.mtb => 'mtb',
        BikeType.cargoBike => 'cargo_bike',
        BikeType.ebike => 'ebike',
      };

  static BikeType fromKey(String s) => BikeType.values.firstWhere(
        (e) => e.key == s,
        orElse: () => BikeType.cityBike,
      );
}

// ─── Product Categories (Bike Shops) ──────────────────────────────────────────

enum ProductCategory {
  cityBikes,
  ebikes,
  cargoBikes,
  roadBikes,
  kidsBikes,
  helmets,
  locks,
  lights,
  tires,
  spareParts,
  clothing;

  String get key => switch (this) {
        ProductCategory.cityBikes => 'city_bikes',
        ProductCategory.ebikes => 'ebikes',
        ProductCategory.cargoBikes => 'cargo_bikes',
        ProductCategory.roadBikes => 'road_bikes',
        ProductCategory.kidsBikes => 'kids_bikes',
        ProductCategory.helmets => 'helmets',
        ProductCategory.locks => 'locks',
        ProductCategory.lights => 'lights',
        ProductCategory.tires => 'tires',
        ProductCategory.spareParts => 'spare_parts',
        ProductCategory.clothing => 'clothing',
      };

  static ProductCategory fromKey(String s) =>
      ProductCategory.values.firstWhere(
        (e) => e.key == s,
        orElse: () => ProductCategory.cityBikes,
      );
}

// ─── Charging Types ───────────────────────────────────────────────────────────

enum ChargingType {
  standardOutlet,
  dedicatedCharger,
  batterySwapStation;

  String get key => switch (this) {
        ChargingType.standardOutlet => 'standard_outlet',
        ChargingType.dedicatedCharger => 'dedicated_charger',
        ChargingType.batterySwapStation => 'battery_swap_station',
      };

  static ChargingType fromKey(String s) => ChargingType.values.firstWhere(
        (e) => e.key == s,
        orElse: () => ChargingType.standardOutlet,
      );
}

// ─── Host Type (Charging Locations) ───────────────────────────────────────────

enum HostType {
  publicStation,
  cafe,
  shop,
  office,
  parkingFacility,
  other;

  String get key => switch (this) {
        HostType.publicStation => 'public_station',
        HostType.cafe => 'cafe',
        HostType.shop => 'shop',
        HostType.office => 'office',
        HostType.parkingFacility => 'parking_facility',
        HostType.other => 'other',
      };

  static HostType fromKey(String s) => HostType.values.firstWhere(
        (e) => e.key == s,
        orElse: () => HostType.other,
      );
}

// ─── Power Availability ───────────────────────────────────────────────────────

enum PowerAvailability {
  free,
  paid,
  customersOnly;

  String get key => switch (this) {
        PowerAvailability.free => 'free',
        PowerAvailability.paid => 'paid',
        PowerAvailability.customersOnly => 'customers_only',
      };

  static PowerAvailability fromKey(String s) =>
      PowerAvailability.values.firstWhere(
        (e) => e.key == s,
        orElse: () => PowerAvailability.free,
      );
}

// ─── Amenities (Charging Locations) ───────────────────────────────────────────

enum Amenity {
  seating,
  foodAndDrinks,
  restroom,
  bikeParking,
  wifi;

  String get key => switch (this) {
        Amenity.seating => 'seating',
        Amenity.foodAndDrinks => 'food_drinks',
        Amenity.restroom => 'restroom',
        Amenity.bikeParking => 'bike_parking',
        Amenity.wifi => 'wifi',
      };

  static Amenity fromKey(String s) => Amenity.values.firstWhere(
        (e) => e.key == s,
        orElse: () => Amenity.seating,
      );
}

// ─── Access Restriction ───────────────────────────────────────────────────────

enum AccessRestriction {
  public,
  customersOnly,
  residentsOnly;

  String get key => switch (this) {
        AccessRestriction.public => 'public',
        AccessRestriction.customersOnly => 'customers',
        AccessRestriction.residentsOnly => 'residents',
      };

  static AccessRestriction fromKey(String s) =>
      AccessRestriction.values.firstWhere(
        (e) => e.key == s,
        orElse: () => AccessRestriction.public,
      );
}

// ─── Price Range (Repair Shops) ───────────────────────────────────────────────

enum PriceRange {
  low,
  medium,
  high;

  String get key => name;

  static PriceRange fromKey(String s) => PriceRange.values.firstWhere(
        (e) => e.key == s,
        orElse: () => PriceRange.medium,
      );
}

// ─── Price Tier (Bike Shops) ──────────────────────────────────────────────────

enum PriceTier {
  budget,
  mid,
  premium;

  String get key => name;

  static PriceTier fromKey(String s) => PriceTier.values.firstWhere(
        (e) => e.key == s,
        orElse: () => PriceTier.mid,
      );
}
