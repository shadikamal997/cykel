import 'package:cached_network_image/cached_network_image.dart';
/// CYKEL — Create / Edit Listing Screen

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/email_verification_banner.dart';
import '../../../services/subscription_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../discover/data/places_service.dart';
import '../../provider/providers/provider_providers.dart';
import '../data/marketplace_service.dart';
import '../domain/marketplace_listing.dart';
import 'listing_helpers.dart';

// ─── Design Colors ─────────────────────────────────────────────────────────────

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key, this.editListing});

  /// When editing, pass the existing listing.
  final MarketplaceListing? editListing;

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  late final _titleCtrl = TextEditingController(
      text: widget.editListing?.title);
  late final _priceCtrl = TextEditingController(
      text: widget.editListing?.price.toStringAsFixed(0));
  late final _descCtrl = TextEditingController(
      text: widget.editListing?.description);
  late final _cityCtrl = TextEditingController(
      text: widget.editListing?.city);
  late final _phoneCtrl = TextEditingController(
      text: widget.editListing?.phone);
  late final _brandCtrl = TextEditingController(
      text: widget.editListing?.brand);
  late final _serialCtrl = TextEditingController(
      text: widget.editListing?.serialNumber);

  // Address autocomplete
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<PlaceResult> _addressSuggestions = [];
  bool _showSuggestions = false;
  Timer? _debounce;

  // Picker state — new local images
  final List<XFile> _newImages = [];

  // Existing image URLs (edit mode)
  List<String> _existingUrls = [];

  late ListingCategory _category;
  late ListingCondition _condition;
  late bool _isElectric;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editListing;
    _category = e?.category ?? ListingCategory.bike;
    _condition = e?.condition ?? ListingCondition.good;
    _isElectric = e?.isElectric ?? false;
    _existingUrls = List.from(e?.imageUrls ?? []);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    _brandCtrl.dispose();
    _serialCtrl.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    final e = widget.editListing;
    if (e == null) {
      return _titleCtrl.text.isNotEmpty ||
          _priceCtrl.text.isNotEmpty ||
          _descCtrl.text.isNotEmpty ||
          _cityCtrl.text.isNotEmpty ||
          _phoneCtrl.text.isNotEmpty ||
          _newImages.isNotEmpty;
    }
    return _titleCtrl.text != (e.title) ||
        _priceCtrl.text != (e.price.toStringAsFixed(0)) ||
        _descCtrl.text != (e.description) ||
        _cityCtrl.text != (e.city) ||
        _phoneCtrl.text != (e.phone ?? '') ||
        _newImages.isNotEmpty ||
        _existingUrls.length != (e.imageUrls.length);
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    final l10n = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.discardChangesTitle),
        content: Text(l10n.discardChangesBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.stayButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.discardButton,
                style: TextStyle(color: context.colors.textPrimary)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEdit = widget.editListing != null;
    final totalImages = _existingUrls.length + _newImages.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(isEdit ? l10n.listingEditTitle : l10n.listingCreateTitle,
            style: AppTextStyles.headline3.copyWith(fontSize: 17)),
        leading: IconButton(
          tooltip: l10n.close,
          icon: const Icon(Icons.close_rounded),
          onPressed: () async {
            final shouldPop = await _onWillPop();
            if (shouldPop && context.mounted) context.pop();
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
            // Photos
            _SectionCard(
              icon: Icons.photo_library_rounded,
              title: l10n.listingAddPhotos,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ..._existingUrls.asMap().entries.map((e) =>
                            _ImageThumb(
                                key: ValueKey('existing_${e.key}'),
                                imageUrl: e.value,
                                onRemove: () => setState(
                                    () => _existingUrls.removeAt(e.key)))),
                        ..._newImages.asMap().entries.map((e) =>
                            _LocalImageThumb(
                                key: ValueKey('new_${e.key}'),
                                file: e.value,
                                onRemove: () => setState(
                                    () => _newImages.removeAt(e.key)))),
                        if (totalImages < 5)
                          GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 92,
                              height: 92,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: (context.colors.textPrimary)
                                      .withValues(alpha: 0.35),
                                  width: 2,
                                ),
                                color: (context.colors.textPrimary)
                                    .withValues(alpha: 0.05),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_rounded,
                                      color: context.colors.textPrimary, size: 28),
                                  const SizedBox(height: 4),
                                  Text('$totalImages/5',
                                      style: AppTextStyles.labelSmall
                                          .copyWith(color: context.colors.textPrimary)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (totalImages == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(l10n.addUpToPhotos,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: context.colors.textSecondary)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Title + Price
            _SectionCard(
              icon: Icons.sell_rounded,
              title: l10n.listingTitleHint,
              child: Column(children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: _inputDecoration(l10n.listingTitleHint),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceCtrl,
                  decoration:
                  _inputDecoration(l10n.listingPriceHint, suffix: l10n.currencyDKK),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: false),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v?.trim().isEmpty ?? true) return l10n.fieldRequired;
                    final price = double.tryParse(v!);
                    if (price == null) return l10n.fieldRequired;
                    if (price > 10000000) return 'Price too high (max 10,000,000 DKK)';
                    if (price < 0) return 'Price cannot be negative';
                    return null;
                  },
                ),
              ]),
            ),
            const SizedBox(height: 12),

            // Category
            _SectionCard(
              icon: Icons.category_rounded,
              title: l10n.listingCategoryAll,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ListingCategory.values
                    .map((c) => _ChoiceChip(
                          label: _categoryLabel(l10n, c),
                          emoji: _categoryEmoji(c),
                          selected: _category == c,
                          onTap: () => setState(() => _category = c),
                          selectedColor: context.colors.textPrimary,
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Condition
            _SectionCard(
              icon: Icons.star_rounded,
              title: l10n.listingConditionNew,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ListingCondition.values
                    .map((c) => _ChoiceChip(
                          label: conditionLabel(l10n, c),
                          selected: _condition == c,
                          onTap: () => setState(() => _condition = c),
                          selectedColor: conditionColor(c),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Brand & Electric toggle
            _SectionCard(
              icon: Icons.two_wheeler_rounded,
              title: l10n.listingBrandHint,
              child: Column(children: [
                TextFormField(
                  controller: _brandCtrl,
                  decoration: _inputDecoration(l10n.listingBrandHint,
                      prefix: Icons.sell_outlined),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.listingIsElectric,
                      style: AppTextStyles.bodyMedium),
                  subtitle: Text(l10n.listingIsElectricHint,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: context.colors.textSecondary)),
                  value: _isElectric,
                  activeTrackColor: context.colors.textPrimary,
                  onChanged: (v) => setState(() => _isElectric = v),
                ),
              ]),
            ),
            const SizedBox(height: 12),

            // Serial number
            _SectionCard(
              icon: Icons.qr_code_rounded,
              title: l10n.listingSerialHint,
              child: Column(children: [
                TextFormField(
                  controller: _serialCtrl,
                  decoration: _inputDecoration(l10n.listingSerialHint,
                      prefix: Icons.fingerprint_rounded),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 6),
                Text(l10n.listingSerialHelp,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: context.colors.textSecondary)),
                if (_serialCtrl.text.trim().isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, 
                            size: 16, 
                            color: AppColors.warning),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Adding serial number enables theft verification',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.warning,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 12),

            // Location + seller type
            _SectionCard(
              icon: Icons.location_on_rounded,
              title: l10n.listingCityHint,
              child: Column(children: [
                CompositedTransformTarget(
                  link: _layerLink,
                  child: TextFormField(
                    controller: _cityCtrl,
                    decoration: _inputDecoration(
                      l10n.listingCityHint,
                      prefix: Icons.location_city_rounded,
                    ).copyWith(
                      suffixIcon: _showSuggestions
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _cityCtrl.clear();
                                _removeOverlay();
                                setState(() {
                                  _addressSuggestions = [];
                                  _showSuggestions = false;
                                });
                              },
                            )
                          : const Icon(Icons.search),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onChanged: _onAddressChanged,
                    onTap: () {
                      if (_addressSuggestions.isNotEmpty) {
                        _showOverlay();
                      }
                    },
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? l10n.fieldRequired : null,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: _inputDecoration(
                    l10n.listingPhoneHint,
                    prefix: Icons.phone_rounded,
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null; // optional
                    final cleaned = v.replaceAll(RegExp(r'[\s\-()]'), '');
                    if (!RegExp(r'^\+?\d{7,15}$').hasMatch(cleaned)) {
                      return l10n.validPhoneNumber;
                    }
                    return null;
                  },
                ),
              ]),
            ),
            const SizedBox(height: 12),

            // Description
            _SectionCard(
              icon: Icons.notes_rounded,
              title: l10n.listingDescriptionHint,
              child: TextFormField(
                controller: _descCtrl,
                decoration: _inputDecoration(l10n.listingDescriptionHint),
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(height: 16),
              ],
            ),
          ),
          ),
          // Pinned publish button
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.textPrimary,
                  foregroundColor: context.colors.surface,
                  minimumSize: const Size.fromHeight(52),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(l10n.listingPublish,
                        style: AppTextStyles.labelLarge
                            .copyWith(color: Colors.white, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  // ─── Address Autocomplete Methods ────────────────────────────────────────────

  void _onAddressChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (value.length < 3) {
      _removeOverlay();
      setState(() {
        _addressSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchAddressSuggestions(value);
    });
  }

  Future<void> _fetchAddressSuggestions(String input) async {
    try {
      final placesService = PlacesService();
      final locale = Localizations.localeOf(context).toString();
      final suggestions = await placesService.autocomplete(
        input,
        language: locale.split('_')[0], // 'en' or 'da'
      );
      
      setState(() {
        _addressSuggestions = suggestions;
        _showSuggestions = suggestions.isNotEmpty;
      });
      
      if (suggestions.isNotEmpty) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    } catch (e) {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _addressSuggestions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final suggestion = _addressSuggestions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on, size: 20),
                    title: Text(
                      suggestion.text,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: suggestion.subtitle.isNotEmpty
                        ? Text(
                            suggestion.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).hintColor,
                            ),
                          )
                        : null,
                    onTap: () => _selectAddress(suggestion),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectAddress(PlaceResult place) {
    _removeOverlay();
    setState(() {
      _cityCtrl.text = place.text;
      _addressSuggestions = [];
      _showSuggestions = false;
    });
  }

  // ─── Image Picker ────────────────────────────────────────────────────────────

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final remaining = 5 - _existingUrls.length - _newImages.length;
    if (remaining <= 0) return;
    final picked = await picker.pickMultiImage(limit: remaining);
    if (picked.isNotEmpty) {
      setState(() => _newImages.addAll(picked));
    }
  }

  Future<void> _submit() async {
    // Check email verification first
    try {
      await checkEmailVerification(context, ref);
    } catch (e) {
      // User's email is not verified, dialog already shown
      return;
    }

    if (!mounted) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_existingUrls.isEmpty && _newImages.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.addAtLeastOnePhoto)),
      );
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _loading = true);
    try {
      final svc = ref.read(marketplaceServiceProvider);
      if (!mounted) return;
      final l10n = context.l10n;

      // Check listing limits for new listings (free users only)
      if (widget.editListing == null) {
        final isProvider = ref.read(isProviderOwnerProvider);
        final isPremium = ref.read(isPremiumProvider);
        
        // Free regular users are limited to 3 listings
        // Providers (bike shops) and premium users have unlimited listings
        if (!isProvider && !isPremium) {
          final count = await svc.getMyListingCount(user.uid);
          if (count >= 3) {
            if (!mounted) return;
            setState(() => _loading = false);
            _showUpgradeDialog();
            return;
          }
        }
      }

      final title = _titleCtrl.text.trim();
      final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
      final description = _descCtrl.text.trim();
      final city = _cityCtrl.text.trim();
      final phone =
          _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim();
      final brand =
          _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim();
      final serial =
          _serialCtrl.text.trim().isEmpty ? null : _serialCtrl.text.trim();

      if (widget.editListing != null) {
        // Edit mode: upload new images in parallel with the Firestore update
        List<String> newUrls = [];
        if (_newImages.isNotEmpty) {
          newUrls = await svc.uploadImages(user.uid, _newImages);
        }
        final allImageUrls = [..._existingUrls, ...newUrls];

        final updated = widget.editListing!.copyWith(
          title: title,
          price: price,
          description: description,
          category: _category,
          condition: _condition,
          city: city,
          isShop: false,
          imageUrls: allImageUrls,
          phone: phone,
          brand: brand,
          isElectric: _isElectric,
          serialNumber: serial,
        );
        await svc.updateListing(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.listingPublished)));
          context.pop();
        }
      } else {
        // Create mode: create the Firestore document immediately (no images yet)
        // so the user sees success instantly, then upload images in the background.
        final listingId = await svc.createListing(
          MarketplaceListing(
            id: '',
            sellerId: user.uid,
            sellerName: user.displayName,
            sellerPhotoUrl: user.photoUrl,
            title: title,
            price: price,
            description: description,
            category: _category,
            condition: _condition,
            city: city,
            isShop: false,
            imageUrls: _existingUrls, // existing URLs only; new ones upload in background
            isSold: false,
            createdAt: DateTime.now(),
            phone: phone,
            brand: brand,
            isElectric: _isElectric,
            serialNumber: serial,
          ),
        );

        // Snapshot the image lists before navigation disposes the widget
        final imagesToUpload = List.of(_newImages);
        final existingImageUrls = List.of(_existingUrls);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.listingPublished)));
          context.pop();
        }

        // Upload new images in the background and attach them to the listing
        if (imagesToUpload.isNotEmpty) {
          unawaited(_uploadAndAttachImages(
              svc, user.uid, listingId, imagesToUpload, existingImageUrls));
        }
      }
    } catch (e, stack) {
      debugPrint('🔴 CREATE LISTING ERROR: $e');
      debugPrint('🔴 Stack: $stack');
      if (mounted) {
        String errorMsg = e.toString();
        // Extract meaningful Firebase error messages
        if (errorMsg.contains('PERMISSION_DENIED')) {
          errorMsg = 'Permission denied. Please check App Check configuration.';
        } else if (errorMsg.contains('app-check-token')) {
          errorMsg = 'App Check token error. Please restart the app.';
        } else if (errorMsg.contains('network')) {
          errorMsg = 'Network error. Please check your connection.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $errorMsg'),
              duration: const Duration(seconds: 5),
              backgroundColor: Colors.red,
            ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Uploads images in the background and attaches their URLs to the listing.
  /// All parameters are passed explicitly so this is safe after widget disposal.
  Future<void> _uploadAndAttachImages(
    MarketplaceService svc,
    String uid,
    String listingId,
    List<XFile> newImages,
    List<String> existingUrls,
  ) async {
    try {
      final newUrls = await svc.uploadImages(uid, newImages);
      if (newUrls.isNotEmpty) {
        await svc.updateListingImages(listingId, [...existingUrls, ...newUrls]);
      }
    } catch (_) {
      // Non-critical: listing already exists; image upload failure is silent
    }
  }

  void _showUpgradeDialog() {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.upgradeToPremium),
        content: Text(
          'Free users can create up to 3 marketplace listings.\n\n'
          'Get unlimited listings by:\n'
          '• Upgrading to Premium (${l10n.premiumPrice}/month)\n'
          '• Registering as a bike shop or service provider',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/subscription');
            },
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.textPrimary,
              foregroundColor: context.colors.surface,
            ),
            child: Text(l10n.upgradeToPremium),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  InputDecoration _inputDecoration(String hint,
          {String? suffix, IconData? prefix}) {
    return InputDecoration(
        hintText: hint,
        hintStyle:
            AppTextStyles.bodyMedium.copyWith(color: context.colors.textSecondary),
        suffixText: suffix,
        prefixIcon: prefix != null ? Icon(prefix, size: 18) : null,
        filled: true,
        fillColor: context.colors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.colors.surfaceVariant)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.colors.surfaceVariant)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.colors.textPrimary, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: (context.colors.textPrimary).withValues(alpha: 0.7))),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: (context.colors.textPrimary).withValues(alpha: 0.7), width: 2)),
    );
  }

  String _categoryLabel(AppLocalizations l10n, ListingCategory c) =>
      switch (c) {
        ListingCategory.bike => l10n.listingCategoryBike,
        ListingCategory.parts => l10n.listingCategoryParts,
        ListingCategory.accessories => l10n.listingCategoryAccessories,
        ListingCategory.clothing => l10n.listingCategoryClothing,
        ListingCategory.tools => l10n.listingCategoryTools,
      };

  String _categoryEmoji(ListingCategory c) => switch (c) {
        ListingCategory.bike => '🚲',
        ListingCategory.parts => '🔩',
        ListingCategory.accessories => '🎒',
        ListingCategory.clothing => '👕',
        ListingCategory.tools => '🔧',
      };
}

// ─── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: context.colors.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: (context.colors.textPrimary).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: context.colors.textPrimary),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: AppTextStyles.labelLarge
                        .copyWith(color: context.colors.textPrimary)),
              ]),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
          ],
        ),
    );
  }
}

// ─── Choice Chip ──────────────────────────────────────────────────────────────

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
    this.emoji,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  final String? emoji;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? selectedColor.withValues(alpha: 0.12)
                : context.colors.background,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: selected ? selectedColor : context.colors.surfaceVariant,
                width: 1.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (emoji != null) ...[  
              Text(emoji!, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
            ],
            Text(label,
                style: AppTextStyles.labelMedium.copyWith(
                    color:
                        selected ? selectedColor : context.colors.textSecondary,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w500)),
          ]),
        ),
      );
}

// ─── Image Thumb (network) ────────────────────────────────────────────────────

class _ImageThumb extends StatelessWidget {
  const _ImageThumb(
      {super.key, required this.imageUrl, required this.onRemove});
  final String imageUrl;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
        Container(
          width: 92,
          height: 92,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            image: DecorationImage(
                image: CachedNetworkImageProvider(imageUrl), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 4,
          right: 14,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                  color: (context.colors.textPrimary).withValues(alpha: 0.7), shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded,
                  size: 13, color: Colors.white),
            ),
          ),
        ),
      ]);
  }
}

// ─── Image Thumb (local XFile) ────────────────────────────────────────────────

class _LocalImageThumb extends StatefulWidget {
  const _LocalImageThumb(
      {super.key, required this.file, required this.onRemove});
  final XFile file;
  final VoidCallback onRemove;

  @override
  State<_LocalImageThumb> createState() => _LocalImageThumbState();
}

class _LocalImageThumbState extends State<_LocalImageThumb> {
  late final Future<Uint8List> _bytesFuture = widget.file.readAsBytes();

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
        FutureBuilder<Uint8List>(
          future: _bytesFuture,
          builder: (_, snap) => Container(
            width: 92,
            height: 92,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: context.colors.surfaceVariant,
              image: snap.hasData
                  ? DecorationImage(
                      image: MemoryImage(snap.data!), fit: BoxFit.cover)
                  : null,
            ),
            child: snap.hasData
                ? null
                : const Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
        Positioned(
          top: 4,
          right: 14,
          child: GestureDetector(
            onTap: widget.onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                  color: (context.colors.textPrimary).withValues(alpha: 0.7), shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded,
                  size: 13, color: Colors.white),
            ),
          ),
        ),
      ]);
  }
}
