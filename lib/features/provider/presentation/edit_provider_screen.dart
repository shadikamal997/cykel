/// CYKEL — Edit Provider Screen
/// Lets the provider owner update business info, location, description,
/// and type-specific services. Pre-filled from the current [CykelProvider].

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/provider_service.dart';
import '../domain/provider_enums.dart';
import '../domain/provider_model.dart';
import '../providers/provider_providers.dart';

class EditProviderScreen extends ConsumerStatefulWidget {
  const EditProviderScreen({super.key});

  @override
  ConsumerState<EditProviderScreen> createState() => _EditProviderScreenState();
}

class _EditProviderScreenState extends ConsumerState<EditProviderScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // ── Business info controllers ───────────────────────────────────────────
  late final TextEditingController _businessNameCtrl;
  late final TextEditingController _legalNameCtrl;
  late final TextEditingController _cvrCtrl;
  late final TextEditingController _contactNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _websiteCtrl;

  // ── Location controllers ────────────────────────────────────────────────
  late final TextEditingController _streetCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _postalCtrl;

  // ── Description ─────────────────────────────────────────────────────────
  late final TextEditingController _descriptionCtrl;

  // ── Repair-specific state ───────────────────────────────────────────────
  late List<RepairService> _servicesOffered;
  late List<BikeType> _supportedBikeTypes;
  late bool _mobileRepair;
  late bool _acceptsWalkIns;
  late bool _appointmentRequired;
  late final TextEditingController _estimatedWaitCtrl;
  late PriceRange _priceRange;
  late final TextEditingController _serviceRadiusCtrl;

  // ── Shop-specific state ─────────────────────────────────────────────────
  late List<ProductCategory> _productsAvailable;
  late bool _offersTestRides;
  late bool _financingAvailable;
  late bool _acceptsTradeIn;
  late final TextEditingController _onlineStoreCtrl;
  late PriceTier _priceTier;
  late bool _hasRepairService;

  // ── Charging-specific state ─────────────────────────────────────────────
  late HostType _hostType;
  late ChargingType _chargingType;
  late final TextEditingController _numberOfPortsCtrl;
  late PowerAvailability _powerAvailability;
  late final TextEditingController _maxChargingCtrl;
  late bool _indoorCharging;
  late bool _weatherProtected;
  late List<Amenity> _amenities;
  late AccessRestriction _accessRestriction;

  bool _initialised = false;

  void _init(CykelProvider p) {
    if (_initialised) return;
    _initialised = true;

    _businessNameCtrl = TextEditingController(text: p.businessName);
    _legalNameCtrl = TextEditingController(text: p.legalBusinessName ?? '');
    _cvrCtrl = TextEditingController(text: p.cvrNumber ?? '');
    _contactNameCtrl = TextEditingController(text: p.contactName);
    _phoneCtrl = TextEditingController(text: p.phone);
    _emailCtrl = TextEditingController(text: p.email);
    _websiteCtrl = TextEditingController(text: p.website ?? '');

    _streetCtrl = TextEditingController(text: p.streetAddress);
    _cityCtrl = TextEditingController(text: p.city);
    _postalCtrl = TextEditingController(text: p.postalCode);

    _descriptionCtrl = TextEditingController(text: p.shopDescription ?? '');

    // Repair
    _servicesOffered = List.of(p.servicesOffered);
    _supportedBikeTypes = List.of(p.supportedBikeTypes);
    _mobileRepair = p.mobileRepair;
    _acceptsWalkIns = p.acceptsWalkIns;
    _appointmentRequired = p.appointmentRequired;
    _estimatedWaitCtrl = TextEditingController(
        text: p.estimatedWaitMinutes?.toString() ?? '');
    _priceRange = p.priceRange ?? PriceRange.medium;
    _serviceRadiusCtrl =
        TextEditingController(text: p.serviceRadiusKm?.toString() ?? '');

    // Shop
    _productsAvailable = List.of(p.productsAvailable);
    _offersTestRides = p.offersTestRides;
    _financingAvailable = p.financingAvailable;
    _acceptsTradeIn = p.acceptsTradeIn;
    _onlineStoreCtrl = TextEditingController(text: p.onlineStoreUrl ?? '');
    _priceTier = p.priceTier ?? PriceTier.mid;
    _hasRepairService = p.hasRepairService;

    // Charging
    _hostType = p.hostType ?? HostType.publicStation;
    _chargingType = p.chargingType ?? ChargingType.standardOutlet;
    _numberOfPortsCtrl =
        TextEditingController(text: p.numberOfPorts?.toString() ?? '');
    _powerAvailability = p.powerAvailability ?? PowerAvailability.free;
    _maxChargingCtrl = TextEditingController(
        text: p.maxChargingDurationMinutes?.toString() ?? '');
    _indoorCharging = p.indoorCharging;
    _weatherProtected = p.weatherProtected;
    _amenities = List.of(p.amenities);
    _accessRestriction = p.accessRestriction ?? AccessRestriction.public;
  }

  @override
  void dispose() {
    if (_initialised) {
      _businessNameCtrl.dispose();
      _legalNameCtrl.dispose();
      _cvrCtrl.dispose();
      _contactNameCtrl.dispose();
      _phoneCtrl.dispose();
      _emailCtrl.dispose();
      _websiteCtrl.dispose();
      _streetCtrl.dispose();
      _cityCtrl.dispose();
      _postalCtrl.dispose();
      _descriptionCtrl.dispose();
      _estimatedWaitCtrl.dispose();
      _serviceRadiusCtrl.dispose();
      _onlineStoreCtrl.dispose();
      _numberOfPortsCtrl.dispose();
      _maxChargingCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _save(CykelProvider current) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final updated = current.copyWith(
      businessName: _businessNameCtrl.text.trim(),
      legalBusinessName: _legalNameCtrl.text.trim().isEmpty
          ? null
          : _legalNameCtrl.text.trim(),
      cvrNumber:
          _cvrCtrl.text.trim().isEmpty ? null : _cvrCtrl.text.trim(),
      contactName: _contactNameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      website: _websiteCtrl.text.trim().isEmpty
          ? null
          : _websiteCtrl.text.trim(),
      streetAddress: _streetCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      postalCode: _postalCtrl.text.trim(),
      shopDescription: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      updatedAt: DateTime.now(),
      // Repair
      servicesOffered: _servicesOffered,
      supportedBikeTypes: _supportedBikeTypes,
      mobileRepair: _mobileRepair,
      acceptsWalkIns: _acceptsWalkIns,
      appointmentRequired: _appointmentRequired,
      estimatedWaitMinutes: int.tryParse(_estimatedWaitCtrl.text.trim()),
      priceRange: _priceRange,
      serviceRadiusKm: double.tryParse(_serviceRadiusCtrl.text.trim()),
      // Shop
      productsAvailable: _productsAvailable,
      offersTestRides: _offersTestRides,
      financingAvailable: _financingAvailable,
      acceptsTradeIn: _acceptsTradeIn,
      onlineStoreUrl: _onlineStoreCtrl.text.trim().isEmpty
          ? null
          : _onlineStoreCtrl.text.trim(),
      priceTier: _priceTier,
      hasRepairService: _hasRepairService,
      // Charging
      hostType: _hostType,
      chargingType: _chargingType,
      numberOfPorts: int.tryParse(_numberOfPortsCtrl.text.trim()),
      powerAvailability: _powerAvailability,
      maxChargingDurationMinutes:
          int.tryParse(_maxChargingCtrl.text.trim()),
      indoorCharging: _indoorCharging,
      weatherProtected: _weatherProtected,
      amenities: _amenities,
      accessRestriction: _accessRestriction,
    );

    try {
      await ref.read(providerServiceProvider).updateProvider(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.changesSaved),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.changesSaveError(e.toString())),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(myProviderProvider);
    final l10n = context.l10n;

    if (provider == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.editProviderTitle)),
        body: Center(child: Text(l10n.noProviderFound)),
      );
    }

    _init(provider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        title: Text(l10n.editProviderTitle, style: AppTextStyles.headline3),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            // ── Business Information ──────────────────────────────────────
            _SectionHeader(
              icon: Icons.storefront_outlined,
              label: l10n.businessInfoTitle,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _businessNameCtrl,
              label: l10n.businessNameLabel,
              icon: Icons.storefront_outlined,
              required: true,
            ),
            _field(
              controller: _legalNameCtrl,
              label: l10n.legalBusinessNameLabel,
              icon: Icons.business_outlined,
            ),
            _field(
              controller: _cvrCtrl,
              label: l10n.cvrNumberLabel,
              icon: Icons.badge_outlined,
              keyboard: TextInputType.number,
            ),
            _field(
              controller: _contactNameCtrl,
              label: l10n.contactNameLabel,
              icon: Icons.person_outline_rounded,
              required: true,
            ),
            _field(
              controller: _phoneCtrl,
              label: l10n.phoneLabel,
              icon: Icons.phone_outlined,
              keyboard: TextInputType.phone,
              required: true,
            ),
            _field(
              controller: _emailCtrl,
              label: l10n.emailLabel,
              icon: Icons.email_outlined,
              keyboard: TextInputType.emailAddress,
              required: true,
              emailValidation: true,
            ),
            _field(
              controller: _websiteCtrl,
              label: l10n.websiteLabel,
              icon: Icons.language_outlined,
              keyboard: TextInputType.url,
            ),

            const SizedBox(height: 24),

            // ── Location ─────────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.location_on_outlined,
              label: l10n.locationTitle,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _streetCtrl,
              label: l10n.streetAddressLabel,
              icon: Icons.location_on_outlined,
              required: true,
            ),
            _field(
              controller: _cityCtrl,
              label: l10n.cityLabel,
              icon: Icons.location_city_outlined,
              required: true,
            ),
            _field(
              controller: _postalCtrl,
              label: l10n.postalCodeLabel,
              icon: Icons.markunread_mailbox_outlined,
              keyboard: TextInputType.number,
              required: true,
            ),

            const SizedBox(height: 24),

            // ── Description ──────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.description_outlined,
              label: l10n.descriptionTitle,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionCtrl,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: l10n.shopDescriptionLabel,
                hintText: l10n.shopDescriptionHint,
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),

            // ── Type-specific ────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.tune_outlined,
              label: l10n.servicesTitle,
            ),
            const SizedBox(height: 12),
            ...switch (provider.providerType) {
              ProviderType.repairShop => _repairFields(l10n),
              ProviderType.servicePoint => _repairFields(l10n),
              ProviderType.bikeShop => _shopFields(l10n),
              ProviderType.rental => _shopFields(l10n),
              ProviderType.chargingLocation => _chargingFields(l10n),
            },
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: FilledButton(
            onPressed: _saving ? null : () => _save(provider),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _saving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white),
                  )
                : Text(l10n.saveChanges, style: AppTextStyles.button),
          ),
        ),
      ),
    );
  }

  // ── Text field helper ───────────────────────────────────────────────────

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    bool required = false,
    bool emailValidation = false,
  }) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        validator: (v) {
          if (required && (v == null || v.trim().isEmpty)) {
            return l10n.fieldRequired;
          }
          if (emailValidation && v != null && v.trim().isNotEmpty) {
            final re = RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-z]{2,}$');
            if (!re.hasMatch(v.trim())) return l10n.errInvalidEmail;
          }
          return null;
        },
      ),
    );
  }

  // ─── Repair fields ────────────────────────────────────────────────────

  List<Widget> _repairFields(dynamic l10n) {
    return [
      Text(l10n.servicesOfferedLabel, style: AppTextStyles.labelMedium),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: RepairService.values.map((s) {
          final sel = _servicesOffered.contains(s);
          return FilterChip(
            label: Text(_repairLabel(l10n, s)),
            selected: sel,
            selectedColor: AppColors.layerService.withValues(alpha: 0.2),
            checkmarkColor: AppColors.layerService,
            onSelected: (_) => setState(() {
              sel ? _servicesOffered.remove(s) : _servicesOffered.add(s);
            }),
          );
        }).toList(),
      ),
      const SizedBox(height: 16),
      Text(l10n.supportedBikeTypesLabel, style: AppTextStyles.labelMedium),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: BikeType.values.map((b) {
          final sel = _supportedBikeTypes.contains(b);
          return FilterChip(
            label: Text(_bikeLabel(l10n, b)),
            selected: sel,
            selectedColor: AppColors.layerService.withValues(alpha: 0.2),
            checkmarkColor: AppColors.layerService,
            onSelected: (_) => setState(() {
              sel ? _supportedBikeTypes.remove(b) : _supportedBikeTypes.add(b);
            }),
          );
        }).toList(),
      ),
      const SizedBox(height: 16),
      _toggle(l10n.mobileRepairLabel, _mobileRepair,
          (v) => setState(() => _mobileRepair = v)),
      _toggle(l10n.acceptsWalkInsLabel, _acceptsWalkIns,
          (v) => setState(() => _acceptsWalkIns = v)),
      _toggle(l10n.appointmentRequiredLabel, _appointmentRequired,
          (v) => setState(() => _appointmentRequired = v)),
      const SizedBox(height: 12),
      TextFormField(
        controller: _estimatedWaitCtrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: l10n.estimatedWaitLabel,
          hintText: l10n.estimatedWaitHint,
        ),
      ),
      const SizedBox(height: 14),
      Text(l10n.priceRangeLabel, style: AppTextStyles.labelMedium),
      RadioGroup<PriceRange>(
        groupValue: _priceRange,
        onChanged: (v) {
          if (v != null) setState(() => _priceRange = v);
        },
        child: Column(
          children: PriceRange.values
              .map((p) => RadioListTile<PriceRange>(
                    title: Text(_priceRangeLabel(l10n, p)),
                    value: p,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ))
              .toList(),
        ),
      ),
      if (_mobileRepair) ...[
        const SizedBox(height: 8),
        TextFormField(
          controller: _serviceRadiusCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.serviceRadiusLabel,
            hintText: l10n.serviceRadiusHint,
          ),
        ),
      ],
    ];
  }

  // ─── Shop fields ──────────────────────────────────────────────────────

  List<Widget> _shopFields(dynamic l10n) {
    return [
      Text(l10n.productsAvailableLabel, style: AppTextStyles.labelMedium),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: ProductCategory.values.map((p) {
          final sel = _productsAvailable.contains(p);
          return FilterChip(
            label: Text(_productLabel(l10n, p)),
            selected: sel,
            selectedColor: AppColors.layerShop.withValues(alpha: 0.2),
            checkmarkColor: AppColors.layerShop,
            onSelected: (_) => setState(() {
              sel ? _productsAvailable.remove(p) : _productsAvailable.add(p);
            }),
          );
        }).toList(),
      ),
      const SizedBox(height: 16),
      _toggle(l10n.offersTestRidesLabel, _offersTestRides,
          (v) => setState(() => _offersTestRides = v)),
      _toggle(l10n.financingAvailableLabel, _financingAvailable,
          (v) => setState(() => _financingAvailable = v)),
      _toggle(l10n.acceptsTradeInLabel, _acceptsTradeIn,
          (v) => setState(() => _acceptsTradeIn = v)),
      _toggle(l10n.hasRepairServiceLabel, _hasRepairService,
          (v) => setState(() => _hasRepairService = v)),
      const SizedBox(height: 12),
      TextFormField(
        controller: _onlineStoreCtrl,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          labelText: l10n.onlineStoreUrlLabel,
          prefixIcon: const Icon(Icons.shopping_cart_outlined),
        ),
      ),
      const SizedBox(height: 14),
      Text(l10n.priceTierLabel, style: AppTextStyles.labelMedium),
      RadioGroup<PriceTier>(
        groupValue: _priceTier,
        onChanged: (v) {
          if (v != null) setState(() => _priceTier = v);
        },
        child: Column(
          children: PriceTier.values
              .map((t) => RadioListTile<PriceTier>(
                    title: Text(_priceTierLabel(l10n, t)),
                    value: t,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ))
              .toList(),
        ),
      ),
    ];
  }

  // ─── Charging fields ──────────────────────────────────────────────────

  List<Widget> _chargingFields(dynamic l10n) {
    return [
      Text(l10n.hostTypeLabel, style: AppTextStyles.labelMedium),
      const SizedBox(height: 8),
      DropdownButtonFormField<HostType>(
        initialValue: _hostType,
        isExpanded: true,
        decoration: const InputDecoration(),
        items: HostType.values
            .map((h) => DropdownMenuItem(
                  value: h,
                  child: Text(_hostLabel(l10n, h)),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) setState(() => _hostType = v);
        },
      ),
      const SizedBox(height: 16),
      Text(l10n.chargingTypeLabel, style: AppTextStyles.labelMedium),
      const SizedBox(height: 8),
      DropdownButtonFormField<ChargingType>(
        initialValue: _chargingType,
        isExpanded: true,
        decoration: const InputDecoration(),
        items: ChargingType.values
            .map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(_chargingLabel(l10n, c)),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) setState(() => _chargingType = v);
        },
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _numberOfPortsCtrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: l10n.numberOfPortsLabel,
          hintText: l10n.numberOfPortsHint,
        ),
      ),
      const SizedBox(height: 14),
      Text(l10n.powerAvailabilityLabel, style: AppTextStyles.labelMedium),
      RadioGroup<PowerAvailability>(
        groupValue: _powerAvailability,
        onChanged: (v) {
          if (v != null) setState(() => _powerAvailability = v);
        },
        child: Column(
          children: PowerAvailability.values
              .map((p) => RadioListTile<PowerAvailability>(
                    title: Text(_powerLabel(l10n, p)),
                    value: p,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ))
              .toList(),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: _maxChargingCtrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: l10n.maxChargingDurationLabel,
          hintText: l10n.maxChargingDurationHint,
        ),
      ),
      const SizedBox(height: 14),
      _toggle(l10n.indoorChargingLabel, _indoorCharging,
          (v) => setState(() => _indoorCharging = v)),
      _toggle(l10n.weatherProtectedLabel, _weatherProtected,
          (v) => setState(() => _weatherProtected = v)),
      const SizedBox(height: 16),
      Text(l10n.amenitiesLabel, style: AppTextStyles.labelMedium),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: Amenity.values.map((a) {
          final sel = _amenities.contains(a);
          return FilterChip(
            label: Text(_amenityLabel(l10n, a)),
            selected: sel,
            selectedColor: AppColors.layerCharging.withValues(alpha: 0.2),
            checkmarkColor: AppColors.layerCharging,
            onSelected: (_) => setState(() {
              sel ? _amenities.remove(a) : _amenities.add(a);
            }),
          );
        }).toList(),
      ),
      const SizedBox(height: 16),
      Text(l10n.accessRestrictionLabel, style: AppTextStyles.labelMedium),
      RadioGroup<AccessRestriction>(
        groupValue: _accessRestriction,
        onChanged: (v) {
          if (v != null) setState(() => _accessRestriction = v);
        },
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

  // ─── Switch helper ────────────────────────────────────────────────────

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile.adaptive(
      title: Text(label, style: AppTextStyles.bodyMedium),
      value: value,
      contentPadding: EdgeInsets.zero,
      activeTrackColor: (context.colors.textPrimary).withValues(alpha: 0.5),
      dense: true,
      onChanged: onChanged,
    );
  }
}

// ─── Section Header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: context.colors.textPrimary),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.headline3),
      ],
    );
  }
}

// ─── L10n label helpers (mirrors services_step.dart) ─────────────────────────

String _repairLabel(dynamic l10n, RepairService s) => switch (s) {
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

String _bikeLabel(dynamic l10n, BikeType b) => switch (b) {
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

String _chargingLabel(dynamic l10n, ChargingType c) => switch (c) {
      ChargingType.standardOutlet => l10n.chargingStandardOutlet,
      ChargingType.dedicatedCharger => l10n.chargingDedicatedCharger,
      ChargingType.batterySwapStation => l10n.chargingBatterySwap,
    };

String _hostLabel(dynamic l10n, HostType h) => switch (h) {
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
