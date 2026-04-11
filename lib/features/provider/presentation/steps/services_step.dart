/// CYKEL — Provider Onboarding: Step 3 – Services & Details
/// Shows different fields depending on the ProviderType.

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/provider_enums.dart';

class ServicesStep extends StatelessWidget {
  const ServicesStep({
    super.key,
    required this.formKey,
    required this.providerType,
    // Description (shared)
    required this.descriptionCtrl,
    // Repair
    required this.servicesOffered,
    required this.onServicesChanged,
    required this.supportedBikeTypes,
    required this.onBikeTypesChanged,
    required this.mobileRepair,
    required this.onMobileRepairChanged,
    required this.acceptsWalkIns,
    required this.onWalkInsChanged,
    required this.appointmentRequired,
    required this.onAppointmentChanged,
    required this.estimatedWaitCtrl,
    required this.priceRange,
    required this.onPriceRangeChanged,
    required this.serviceRadiusCtrl,
    // Shop
    required this.productsAvailable,
    required this.onProductsChanged,
    required this.offersTestRides,
    required this.onTestRidesChanged,
    required this.financingAvailable,
    required this.onFinancingChanged,
    required this.acceptsTradeIn,
    required this.onTradeInChanged,
    required this.onlineStoreCtrl,
    required this.priceTier,
    required this.onPriceTierChanged,
    required this.hasRepairService,
    required this.onRepairServiceChanged,
    // Charging
    required this.hostType,
    required this.onHostTypeChanged,
    required this.chargingType,
    required this.onChargingTypeChanged,
    required this.numberOfPortsCtrl,
    required this.powerAvailability,
    required this.onPowerChanged,
    required this.maxChargingCtrl,
    required this.indoorCharging,
    required this.onIndoorChanged,
    required this.weatherProtected,
    required this.onWeatherChanged,
    required this.amenities,
    required this.onAmenitiesChanged,
    required this.accessRestriction,
    required this.onAccessChanged,
  });

  final GlobalKey<FormState> formKey;
  final ProviderType providerType;
  final TextEditingController descriptionCtrl;

  // Repair
  final List<RepairService> servicesOffered;
  final ValueChanged<List<RepairService>> onServicesChanged;
  final List<BikeType> supportedBikeTypes;
  final ValueChanged<List<BikeType>> onBikeTypesChanged;
  final bool mobileRepair;
  final ValueChanged<bool> onMobileRepairChanged;
  final bool acceptsWalkIns;
  final ValueChanged<bool> onWalkInsChanged;
  final bool appointmentRequired;
  final ValueChanged<bool> onAppointmentChanged;
  final TextEditingController estimatedWaitCtrl;
  final PriceRange priceRange;
  final ValueChanged<PriceRange> onPriceRangeChanged;
  final TextEditingController serviceRadiusCtrl;

  // Shop
  final List<ProductCategory> productsAvailable;
  final ValueChanged<List<ProductCategory>> onProductsChanged;
  final bool offersTestRides;
  final ValueChanged<bool> onTestRidesChanged;
  final bool financingAvailable;
  final ValueChanged<bool> onFinancingChanged;
  final bool acceptsTradeIn;
  final ValueChanged<bool> onTradeInChanged;
  final TextEditingController onlineStoreCtrl;
  final PriceTier priceTier;
  final ValueChanged<PriceTier> onPriceTierChanged;
  final bool hasRepairService;
  final ValueChanged<bool> onRepairServiceChanged;

  // Charging
  final HostType hostType;
  final ValueChanged<HostType> onHostTypeChanged;
  final ChargingType chargingType;
  final ValueChanged<ChargingType> onChargingTypeChanged;
  final TextEditingController numberOfPortsCtrl;
  final PowerAvailability powerAvailability;
  final ValueChanged<PowerAvailability> onPowerChanged;
  final TextEditingController maxChargingCtrl;
  final bool indoorCharging;
  final ValueChanged<bool> onIndoorChanged;
  final bool weatherProtected;
  final ValueChanged<bool> onWeatherChanged;
  final List<Amenity> amenities;
  final ValueChanged<List<Amenity>> onAmenitiesChanged;
  final AccessRestriction accessRestriction;
  final ValueChanged<AccessRestriction> onAccessChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Text(
            context.l10n.servicesTitle,
            style: AppTextStyles.headline3,
          ),
          const SizedBox(height: 20),
          ...switch (providerType) {
            ProviderType.repairShop => _repairFields(context),
            ProviderType.servicePoint => _repairFields(context),
            ProviderType.bikeShop => _shopFields(context),
            ProviderType.rental => _shopFields(context),
            ProviderType.chargingLocation => _chargingFields(context),
          },
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          // Description (shared)
          Text(context.l10n.descriptionTitle, style: AppTextStyles.headline3),
          const SizedBox(height: 12),
          TextFormField(
            controller: descriptionCtrl,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: context.l10n.shopDescriptionLabel,
              hintText: context.l10n.shopDescriptionHint,
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Repair Shop Fields ─────────────────────────────────────────────────────

  List<Widget> _repairFields(BuildContext context) {
    final l10n = context.l10n;
    return [
      // Services chips
      Text(l10n.servicesOfferedLabel, style: AppTextStyles.labelMedium),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: RepairService.values.map((s) {
          final selected = servicesOffered.contains(s);
          return FilterChip(
            label: Text(_repairServiceLabel(l10n, s)),
            selected: selected,
            selectedColor: AppColors.layerService.withValues(alpha: 0.2),
            checkmarkColor: AppColors.layerService,
            onSelected: (_) {
              final copy = List<RepairService>.from(servicesOffered);
              selected ? copy.remove(s) : copy.add(s);
              onServicesChanged(copy);
            },
          );
        }).toList(),
      ),
      const SizedBox(height: 20),

      // Bike types chips
      Text(l10n.supportedBikeTypesLabel, style: AppTextStyles.labelMedium),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: BikeType.values.map((b) {
          final selected = supportedBikeTypes.contains(b);
          return FilterChip(
            label: Text(_bikeTypeLabel(l10n, b)),
            selected: selected,
            selectedColor: AppColors.layerService.withValues(alpha: 0.2),
            checkmarkColor: AppColors.layerService,
            onSelected: (_) {
              final copy = List<BikeType>.from(supportedBikeTypes);
              selected ? copy.remove(b) : copy.add(b);
              onBikeTypesChanged(copy);
            },
          );
        }).toList(),
      ),
      const SizedBox(height: 20),

      // Toggles
      _ToggleTile(
        label: l10n.mobileRepairLabel,
        value: mobileRepair,
        onChanged: onMobileRepairChanged,
      ),
      _ToggleTile(
        label: l10n.acceptsWalkInsLabel,
        value: acceptsWalkIns,
        onChanged: onWalkInsChanged,
      ),
      _ToggleTile(
        label: l10n.appointmentRequiredLabel,
        value: appointmentRequired,
        onChanged: onAppointmentChanged,
      ),
      const SizedBox(height: 16),

      // Estimated wait
      TextFormField(
        controller: estimatedWaitCtrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: l10n.estimatedWaitLabel,
          hintText: l10n.estimatedWaitHint,
        ),
      ),
      const SizedBox(height: 16),

      // Price range radio
      Text(l10n.priceRangeLabel, style: AppTextStyles.labelMedium),
      RadioGroup<PriceRange>(
        groupValue: priceRange,
        onChanged: (v) { if (v != null) onPriceRangeChanged(v); },
        child: Column(
          children: PriceRange.values.map((p) => RadioListTile<PriceRange>(
                title: Text(_priceRangeLabel(l10n, p)),
                value: p,
                dense: true,
                contentPadding: EdgeInsets.zero,
              )).toList(),
        ),
      ),

      // Service radius (shown when mobile repair)
      if (mobileRepair) ...[
        const SizedBox(height: 12),
        TextFormField(
          controller: serviceRadiusCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.serviceRadiusLabel,
            hintText: l10n.serviceRadiusHint,
          ),
        ),
      ],
    ];
  }

  // ─── Bike Shop Fields ───────────────────────────────────────────────────────

  List<Widget> _shopFields(BuildContext context) {
    final l10n = context.l10n;
    return [
      // Products chips
      Text(l10n.productsAvailableLabel, style: AppTextStyles.labelMedium),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: ProductCategory.values.map((p) {
          final selected = productsAvailable.contains(p);
          return FilterChip(
            label: Text(_productLabel(l10n, p)),
            selected: selected,
            selectedColor: AppColors.layerShop.withValues(alpha: 0.2),
            checkmarkColor: AppColors.layerShop,
            onSelected: (_) {
              final copy = List<ProductCategory>.from(productsAvailable);
              selected ? copy.remove(p) : copy.add(p);
              onProductsChanged(copy);
            },
          );
        }).toList(),
      ),
      const SizedBox(height: 20),

      _ToggleTile(
        label: l10n.offersTestRidesLabel,
        value: offersTestRides,
        onChanged: onTestRidesChanged,
      ),
      _ToggleTile(
        label: l10n.financingAvailableLabel,
        value: financingAvailable,
        onChanged: onFinancingChanged,
      ),
      _ToggleTile(
        label: l10n.acceptsTradeInLabel,
        value: acceptsTradeIn,
        onChanged: onTradeInChanged,
      ),
      _ToggleTile(
        label: l10n.hasRepairServiceLabel,
        value: hasRepairService,
        onChanged: onRepairServiceChanged,
      ),
      const SizedBox(height: 16),

      // Online store URL
      TextFormField(
        controller: onlineStoreCtrl,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          labelText: l10n.onlineStoreUrlLabel,
          prefixIcon: const Icon(Icons.shopping_cart_outlined),
        ),
      ),
      const SizedBox(height: 16),

      // Price tier radio
      Text(l10n.priceTierLabel, style: AppTextStyles.labelMedium),
      RadioGroup<PriceTier>(
        groupValue: priceTier,
        onChanged: (v) { if (v != null) onPriceTierChanged(v); },
        child: Column(
          children: PriceTier.values.map((t) => RadioListTile<PriceTier>(
                title: Text(_priceTierLabel(l10n, t)),
                value: t,
                dense: true,
                contentPadding: EdgeInsets.zero,
              )).toList(),
        ),
      ),
    ];
  }

  // ─── Charging Location Fields ───────────────────────────────────────────────

  List<Widget> _chargingFields(BuildContext context) {
    final l10n = context.l10n;
    return [
      // Host type dropdown
      Text(l10n.hostTypeLabel, style: AppTextStyles.labelMedium),
      const SizedBox(height: 8),
      DropdownButtonFormField<HostType>(
        initialValue: hostType,
        isExpanded: true,
        decoration: const InputDecoration(),
        items: HostType.values
            .map((h) => DropdownMenuItem(
                  value: h,
                  child: Text(_hostTypeLabel(l10n, h)),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) onHostTypeChanged(v);
        },
      ),
      const SizedBox(height: 20),

      // Charging type dropdown
      Text(l10n.chargingTypeLabel, style: AppTextStyles.labelMedium),
      const SizedBox(height: 8),
      DropdownButtonFormField<ChargingType>(
        initialValue: chargingType,
        isExpanded: true,
        decoration: const InputDecoration(),
        items: ChargingType.values
            .map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(_chargingTypeLabel(l10n, c)),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) onChargingTypeChanged(v);
        },
      ),
      const SizedBox(height: 16),

      // Number of ports
      TextFormField(
        controller: numberOfPortsCtrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: l10n.numberOfPortsLabel,
          hintText: l10n.numberOfPortsHint,
        ),
      ),
      const SizedBox(height: 16),

      // Power availability radio
      Text(l10n.powerAvailabilityLabel, style: AppTextStyles.labelMedium),
      RadioGroup<PowerAvailability>(
        groupValue: powerAvailability,
        onChanged: (v) { if (v != null) onPowerChanged(v); },
        child: Column(
          children: PowerAvailability.values.map((p) => RadioListTile<PowerAvailability>(
                title: Text(_powerLabel(l10n, p)),
                value: p,
                dense: true,
                contentPadding: EdgeInsets.zero,
              )).toList(),
        ),
      ),
      const SizedBox(height: 8),

      // Max charging duration
      TextFormField(
        controller: maxChargingCtrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: l10n.maxChargingDurationLabel,
          hintText: l10n.maxChargingDurationHint,
        ),
      ),
      const SizedBox(height: 16),

      // Indoor / weather
      _ToggleTile(
        label: l10n.indoorChargingLabel,
        value: indoorCharging,
        onChanged: onIndoorChanged,
      ),
      _ToggleTile(
        label: l10n.weatherProtectedLabel,
        value: weatherProtected,
        onChanged: onWeatherChanged,
      ),
      const SizedBox(height: 20),

      // Amenities chips
      Text(l10n.amenitiesLabel, style: AppTextStyles.labelMedium),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: Amenity.values.map((a) {
          final selected = amenities.contains(a);
          return FilterChip(
            label: Text(_amenityLabel(l10n, a)),
            selected: selected,
            selectedColor: AppColors.layerCharging.withValues(alpha: 0.2),
            checkmarkColor: AppColors.layerCharging,
            onSelected: (_) {
              final copy = List<Amenity>.from(amenities);
              selected ? copy.remove(a) : copy.add(a);
              onAmenitiesChanged(copy);
            },
          );
        }).toList(),
      ),
      const SizedBox(height: 20),

      // Access restriction
      Text(l10n.accessRestrictionLabel, style: AppTextStyles.labelMedium),
      RadioGroup<AccessRestriction>(
        groupValue: accessRestriction,
        onChanged: (v) { if (v != null) onAccessChanged(v); },
        child: Column(
          children: AccessRestriction.values
              .map((r) => RadioListTile<AccessRestriction>(
                    title: Text(_accessLabel(l10n, r)),
                    value: r,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ))
              .toList(),
        ),
      ),
    ];
  }
}

// ─── Toggle Tile ──────────────────────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: Text(label, style: AppTextStyles.bodyMedium),
      value: value,
      contentPadding: EdgeInsets.zero,
      activeTrackColor: AppColors.primary,
      dense: true,
      onChanged: onChanged,
    );
  }
}

// ─── L10n label helpers ───────────────────────────────────────────────────────

String _repairServiceLabel(dynamic l10n, RepairService s) => switch (s) {
      RepairService.flatTireRepair => l10n.repairFlatTire,
      RepairService.brakeService => l10n.repairBrakeService,
      RepairService.gearAdjustment => l10n.repairGearAdjustment,
      RepairService.chainReplacement => l10n.repairChainReplacement,
      RepairService.wheelTruing => l10n.repairWheelTruing,
      RepairService.suspensionService => l10n.repairSuspensionService,
      RepairService.ebikeDiagnostics => l10n.repairEbikeDiagnostics,
      RepairService.fullTuneUp => l10n.repairFullTuneUp,
      RepairService.emergencyRepair => l10n.repairEmergencyRepair,
      RepairService.safetyInspection => l10n.repairSafetyInspection,
      RepairService.mobileRepair => l10n.repairMobileRepair,
    };

String _bikeTypeLabel(dynamic l10n, BikeType b) => switch (b) {
      BikeType.cityBike => l10n.bikeTypeCityBike,
      BikeType.roadBike => l10n.bikeTypeRoadBike,
      BikeType.mtb => l10n.bikeTypeMtb,
      BikeType.cargoBike => l10n.bikeTypeCargoBike,
      BikeType.ebike => l10n.bikeTypeEbike,
    };

String _productLabel(dynamic l10n, ProductCategory p) => switch (p) {
      ProductCategory.cityBikes => l10n.productCityBikes,
      ProductCategory.ebikes => l10n.productEbikes,
      ProductCategory.cargoBikes => l10n.productCargoBikes,
      ProductCategory.roadBikes => l10n.productRoadBikes,
      ProductCategory.kidsBikes => l10n.productKidsBikes,
      ProductCategory.helmets => l10n.productHelmets,
      ProductCategory.locks => l10n.productLocks,
      ProductCategory.lights => l10n.productLights,
      ProductCategory.tires => l10n.productTires,
      ProductCategory.spareParts => l10n.productSpareParts,
      ProductCategory.clothing => l10n.productClothing,
    };

String _chargingTypeLabel(dynamic l10n, ChargingType c) => switch (c) {
      ChargingType.standardOutlet => l10n.chargingStandardOutlet,
      ChargingType.dedicatedCharger => l10n.chargingDedicatedCharger,
      ChargingType.batterySwapStation => l10n.chargingBatterySwap,
    };

String _hostTypeLabel(dynamic l10n, HostType h) => switch (h) {
      HostType.publicStation => l10n.hostPublicStation,
      HostType.cafe => l10n.hostCafe,
      HostType.shop => l10n.hostShop,
      HostType.office => l10n.hostOffice,
      HostType.parkingFacility => l10n.hostParkingFacility,
      HostType.other => l10n.hostOther,
    };

String _powerLabel(dynamic l10n, PowerAvailability p) => switch (p) {
      PowerAvailability.free => l10n.powerFree,
      PowerAvailability.paid => l10n.powerPaid,
      PowerAvailability.customersOnly => l10n.powerCustomersOnly,
    };

String _amenityLabel(dynamic l10n, Amenity a) => switch (a) {
      Amenity.seating => l10n.amenitySeating,
      Amenity.foodAndDrinks => l10n.amenityFoodDrinks,
      Amenity.restroom => l10n.amenityRestroom,
      Amenity.bikeParking => l10n.amenityBikeParking,
      Amenity.wifi => l10n.amenityWifi,
    };

String _accessLabel(dynamic l10n, AccessRestriction r) => switch (r) {
      AccessRestriction.public => l10n.accessPublic,
      AccessRestriction.customersOnly => l10n.accessCustomersOnly,
      AccessRestriction.residentsOnly => l10n.accessResidentsOnly,
    };

String _priceRangeLabel(dynamic l10n, PriceRange p) => switch (p) {
      PriceRange.low => l10n.priceRangeLow,
      PriceRange.medium => l10n.priceRangeMedium,
      PriceRange.high => l10n.priceRangeHigh,
    };

String _priceTierLabel(dynamic l10n, PriceTier t) => switch (t) {
      PriceTier.budget => l10n.priceTierBudget,
      PriceTier.mid => l10n.priceTierMid,
      PriceTier.premium => l10n.priceTierPremium,
    };
