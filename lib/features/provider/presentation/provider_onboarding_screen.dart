/// CYKEL — Provider Onboarding Screen
/// Multi-step form host using PageView. Steps:
/// 1. Business Info  2. Location  3. Services (type-specific)
/// 4. Opening Hours  5. Media  6. Description  7. Review & Submit

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/email_verification_banner.dart';
import '../../auth/providers/auth_providers.dart';
import '../../discover/data/places_service.dart';
import '../data/provider_service.dart';
import '../domain/provider_enums.dart';
import '../domain/provider_model.dart';
import 'steps/business_info_step.dart';
import 'steps/location_step.dart';
import 'steps/services_step.dart';
import 'steps/hours_step.dart';
import 'steps/media_step.dart';
import 'steps/review_step.dart';

class ProviderOnboardingScreen extends ConsumerStatefulWidget {
  const ProviderOnboardingScreen({super.key, required this.providerType});

  final ProviderType providerType;

  @override
  ConsumerState<ProviderOnboardingScreen> createState() =>
      _ProviderOnboardingScreenState();
}

class _ProviderOnboardingScreenState
    extends ConsumerState<ProviderOnboardingScreen> {
  late final PageController _pageCtrl;
  int _currentPage = 0;
  bool _submitting = false;

  // ── Shared form data ────
  // Business info
  final _businessNameCtrl = TextEditingController();
  final _legalNameCtrl = TextEditingController();
  final _cvrCtrl = TextEditingController();
  final _contactNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();

  // Location
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  
  // Provider location coordinates (extracted from Google Places)
  double? _latitude;
  double? _longitude;

  // Repair shop fields
  List<RepairService> _servicesOffered = [];
  List<BikeType> _supportedBikeTypes = [];
  bool _mobileRepair = false;
  bool _acceptsWalkIns = true;
  bool _appointmentRequired = false;
  final _estimatedWaitCtrl = TextEditingController();
  PriceRange _priceRange = PriceRange.medium;
  final _serviceRadiusCtrl = TextEditingController();

  // Bike shop fields
  List<ProductCategory> _productsAvailable = [];
  bool _offersTestRides = false;
  bool _financingAvailable = false;
  bool _acceptsTradeIn = false;
  final _onlineStoreCtrl = TextEditingController();
  PriceTier _priceTier = PriceTier.mid;
  bool _hasRepairService = false;

  // Charging fields
  HostType _hostType = HostType.publicStation;
  ChargingType _chargingType = ChargingType.standardOutlet;
  final _numberOfPortsCtrl = TextEditingController();
  PowerAvailability _powerAvailability = PowerAvailability.free;
  final _maxChargingCtrl = TextEditingController();
  bool _indoorCharging = false;
  bool _weatherProtected = false;
  List<Amenity> _amenities = [];
  AccessRestriction _accessRestriction = AccessRestriction.public;

  // Opening hours
  Map<String, DayHours> _openingHours = {
    'mon': const DayHours(open: '09:00', close: '17:00'),
    'tue': const DayHours(open: '09:00', close: '17:00'),
    'wed': const DayHours(open: '09:00', close: '17:00'),
    'thu': const DayHours(open: '09:00', close: '17:00'),
    'fri': const DayHours(open: '09:00', close: '17:00'),
    'sat': const DayHours(open: '10:00', close: '14:00'),
    'sun': const DayHours(open: '10:00', close: '14:00', closed: true),
  };

  // Media
  XFile? _logoFile;
  XFile? _coverFile;
  List<XFile> _galleryFiles = [];

  // Description
  final _descriptionCtrl = TextEditingController();

  // Form keys per step
  final _businessFormKey = GlobalKey<FormState>();
  final _locationFormKey = GlobalKey<FormState>();
  final _servicesFormKey = GlobalKey<FormState>();

  static const _totalSteps = 6; // Business, Location, Services, Hours, Media, Review

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    // Pre-fill email from user account
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _emailCtrl.text = user.email;
      _contactNameCtrl.text = user.displayName;
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
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
    _estimatedWaitCtrl.dispose();
    _serviceRadiusCtrl.dispose();
    _onlineStoreCtrl.dispose();
    _numberOfPortsCtrl.dispose();
    _maxChargingCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  // ── Navigation ──────────────────────────────────────────────────────────────

  void _nextPage() {
    // Validate current step
    if (!_validateCurrentStep()) return;

    if (_currentPage < _totalSteps - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentPage) {
      case 0:
        return _businessFormKey.currentState?.validate() ?? false;
      case 1:
        return _locationFormKey.currentState?.validate() ?? false;
      case 2:
        return _servicesFormKey.currentState?.validate() ?? false;
      default:
        return true;
    }
  }

  // ── Submit ──────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    // Check email verification first
    try {
      await checkEmailVerification(context, ref);
    } catch (e) {
      // User's email is not verified, dialog already shown
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _submitting = true);

    try {
      final service = ref.read(providerServiceProvider);

      // Upload images
      String? logoUrl;
      String? coverUrl;
      List<String> galleryUrls = [];

      if (_logoFile != null) {
        logoUrl = await service.uploadSingleImage(user.uid, _logoFile!);
      }
      if (_coverFile != null) {
        coverUrl = await service.uploadSingleImage(user.uid, _coverFile!);
      }
      if (_galleryFiles.isNotEmpty) {
        galleryUrls = await service.uploadImages(user.uid, _galleryFiles);
      }

      // Geocode address if coordinates are missing
      double lat = _latitude ?? 0;
      double lng = _longitude ?? 0;
      if (lat == 0 && lng == 0) {
        final fullAddress =
            '${_streetCtrl.text.trim()}, ${_cityCtrl.text.trim()} ${_postalCtrl.text.trim()}, Denmark';
        final placesService = ref.read(placesServiceProvider);
        final results = await placesService.autocomplete(fullAddress);
        if (results.isNotEmpty) {
          lat = results.first.lat;
          lng = results.first.lng;
        }
      }

      final now = DateTime.now();
      final provider = CykelProvider(
        id: '',
        userId: user.uid,
        providerType: widget.providerType,
        businessName: _businessNameCtrl.text.trim(),
        legalBusinessName: _legalNameCtrl.text.trim().isNotEmpty
            ? _legalNameCtrl.text.trim()
            : null,
        cvrNumber:
            _cvrCtrl.text.trim().isNotEmpty ? _cvrCtrl.text.trim() : null,
        contactName: _contactNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        website: _websiteCtrl.text.trim().isNotEmpty
            ? _websiteCtrl.text.trim()
            : null,
        streetAddress: _streetCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        postalCode: _postalCtrl.text.trim(),
        latitude: lat,
        longitude: lng,
        shopDescription: _descriptionCtrl.text.trim().isNotEmpty
            ? _descriptionCtrl.text.trim()
            : null,
        logoUrl: logoUrl,
        coverPhotoUrl: coverUrl,
        galleryUrls: galleryUrls,
        openingHours: _openingHours,
        verificationStatus: VerificationStatus.approved,
        createdAt: now,
        updatedAt: now,
        // Repair fields
        servicesOffered: _servicesOffered,
        mobileRepair: _mobileRepair,
        acceptsWalkIns: _acceptsWalkIns,
        appointmentRequired: _appointmentRequired,
        estimatedWaitMinutes:
            int.tryParse(_estimatedWaitCtrl.text.trim()),
        priceRange: _priceRange,
        supportedBikeTypes: _supportedBikeTypes,
        serviceRadiusKm:
            double.tryParse(_serviceRadiusCtrl.text.trim()),
        // Shop fields
        productsAvailable: _productsAvailable,
        offersTestRides: _offersTestRides,
        financingAvailable: _financingAvailable,
        acceptsTradeIn: _acceptsTradeIn,
        onlineStoreUrl: _onlineStoreCtrl.text.trim().isNotEmpty
            ? _onlineStoreCtrl.text.trim()
            : null,
        priceTier: _priceTier,
        hasRepairService: _hasRepairService,
        // Charging fields
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

      await service.createProvider(provider);

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.providerSubmitError('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSuccessDialog() {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.providerSubmitSuccess)),
          ],
        ),
        content: Text(l10n.providerSubmitSuccessDetail),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              context.go(AppRoutes.profile);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
              elevation: 0,
            ),
            child: Text(l10n.goToDashboard),
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(l10n.providerOnboardingTitle,
            style: AppTextStyles.headline3),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _StepIndicator(
            current: _currentPage,
            total: _totalSteps,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                // Step 1: Business Info
                BusinessInfoStep(
                  formKey: _businessFormKey,
                  businessNameCtrl: _businessNameCtrl,
                  legalNameCtrl: _legalNameCtrl,
                  cvrCtrl: _cvrCtrl,
                  contactNameCtrl: _contactNameCtrl,
                  phoneCtrl: _phoneCtrl,
                  emailCtrl: _emailCtrl,
                  websiteCtrl: _websiteCtrl,
                ),
                // Step 2: Location
                LocationStep(
                  formKey: _locationFormKey,
                  streetCtrl: _streetCtrl,
                  cityCtrl: _cityCtrl,
                  postalCtrl: _postalCtrl,
                  onCoordinatesSelected: (lat, lng) {
                    setState(() {
                      _latitude = lat;
                      _longitude = lng;
                    });
                  },
                ),
                // Step 3: Services (type-specific)
                ServicesStep(
                  formKey: _servicesFormKey,
                  providerType: widget.providerType,
                  // Repair
                  servicesOffered: _servicesOffered,
                  onServicesChanged: (v) =>
                      setState(() => _servicesOffered = v),
                  supportedBikeTypes: _supportedBikeTypes,
                  onBikeTypesChanged: (v) =>
                      setState(() => _supportedBikeTypes = v),
                  mobileRepair: _mobileRepair,
                  onMobileRepairChanged: (v) =>
                      setState(() => _mobileRepair = v),
                  acceptsWalkIns: _acceptsWalkIns,
                  onWalkInsChanged: (v) =>
                      setState(() => _acceptsWalkIns = v),
                  appointmentRequired: _appointmentRequired,
                  onAppointmentChanged: (v) =>
                      setState(() => _appointmentRequired = v),
                  estimatedWaitCtrl: _estimatedWaitCtrl,
                  priceRange: _priceRange,
                  onPriceRangeChanged: (v) =>
                      setState(() => _priceRange = v),
                  serviceRadiusCtrl: _serviceRadiusCtrl,
                  // Shop
                  productsAvailable: _productsAvailable,
                  onProductsChanged: (v) =>
                      setState(() => _productsAvailable = v),
                  offersTestRides: _offersTestRides,
                  onTestRidesChanged: (v) =>
                      setState(() => _offersTestRides = v),
                  financingAvailable: _financingAvailable,
                  onFinancingChanged: (v) =>
                      setState(() => _financingAvailable = v),
                  acceptsTradeIn: _acceptsTradeIn,
                  onTradeInChanged: (v) =>
                      setState(() => _acceptsTradeIn = v),
                  onlineStoreCtrl: _onlineStoreCtrl,
                  priceTier: _priceTier,
                  onPriceTierChanged: (v) =>
                      setState(() => _priceTier = v),
                  hasRepairService: _hasRepairService,
                  onRepairServiceChanged: (v) =>
                      setState(() => _hasRepairService = v),
                  // Charging
                  hostType: _hostType,
                  onHostTypeChanged: (v) =>
                      setState(() => _hostType = v),
                  chargingType: _chargingType,
                  onChargingTypeChanged: (v) =>
                      setState(() => _chargingType = v),
                  numberOfPortsCtrl: _numberOfPortsCtrl,
                  powerAvailability: _powerAvailability,
                  onPowerChanged: (v) =>
                      setState(() => _powerAvailability = v),
                  maxChargingCtrl: _maxChargingCtrl,
                  indoorCharging: _indoorCharging,
                  onIndoorChanged: (v) =>
                      setState(() => _indoorCharging = v),
                  weatherProtected: _weatherProtected,
                  onWeatherChanged: (v) =>
                      setState(() => _weatherProtected = v),
                  amenities: _amenities,
                  onAmenitiesChanged: (v) =>
                      setState(() => _amenities = v),
                  accessRestriction: _accessRestriction,
                  onAccessChanged: (v) =>
                      setState(() => _accessRestriction = v),
                  descriptionCtrl: _descriptionCtrl,
                ),
                // Step 4: Opening Hours
                HoursStep(
                  hours: _openingHours,
                  onChanged: (h) => setState(() => _openingHours = h),
                ),
                // Step 5: Media
                MediaStep(
                  logoFile: _logoFile,
                  onLogoChanged: (f) => setState(() => _logoFile = f),
                  coverFile: _coverFile,
                  onCoverChanged: (f) => setState(() => _coverFile = f),
                  galleryFiles: _galleryFiles,
                  onGalleryChanged: (f) =>
                      setState(() => _galleryFiles = f),
                ),
                // Step 6: Review & Submit
                ReviewStep(
                  providerType: widget.providerType,
                  businessName: _businessNameCtrl.text,
                  contactName: _contactNameCtrl.text,
                  phone: _phoneCtrl.text,
                  email: _emailCtrl.text,
                  streetAddress: _streetCtrl.text,
                  city: _cityCtrl.text,
                  postalCode: _postalCtrl.text,
                  openingHours: _openingHours,
                  hasLogo: _logoFile != null,
                  galleryCount: _galleryFiles.length,
                  description: _descriptionCtrl.text,
                ),
              ],
            ),
          ),
          // Bottom nav buttons
          SafeArea(
            child: Padding(
              padding:
                  EdgeInsets.fromLTRB(20, 12, 20, bottomPad > 0 ? 0 : 16),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting ? null : _prevPage,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(l10n.backLabel,
                            style: AppTextStyles.button
                                .copyWith(color: AppColors.textPrimary)),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: _currentPage > 0 ? 2 : 1,
                    child: FilledButton(
                      onPressed: _submitting
                          ? null
                          : (_currentPage == _totalSteps - 1
                              ? _submit
                              : _nextPage),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                        elevation: 0,
                        disabledBackgroundColor: AppColors.border,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _submitting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                              ),
                            )
                          : Text(
                              _currentPage == _totalSteps - 1
                                  ? l10n.submitLabel
                                  : l10n.continueLabel,
                              style: AppTextStyles.button
                                  .copyWith(color: AppColors.textOnPrimary)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step Indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        children: [
          Text(
            context.l10n.stepOf(current + 1, total),
            style: AppTextStyles.labelSmall,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (current + 1) / total,
              backgroundColor: AppColors.border,
              valueColor:
                  AlwaysStoppedAnimation<Color>(Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
