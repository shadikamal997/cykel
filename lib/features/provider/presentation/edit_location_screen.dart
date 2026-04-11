/// CYKEL — Add / Edit Location Screen
/// Form for creating or editing a provider location.
/// Includes name, type, address, opening hours, contact, photos.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/location_service.dart';
import '../domain/provider_enums.dart';
import '../domain/provider_location.dart';
import '../domain/provider_model.dart';
import '../providers/provider_providers.dart';
import 'widgets/address_autocomplete_field.dart';

class EditLocationScreen extends ConsumerStatefulWidget {
  const EditLocationScreen({super.key, this.location});

  /// If non-null we are editing; otherwise creating.
  final ProviderLocation? location;

  @override
  ConsumerState<EditLocationScreen> createState() =>
      _EditLocationScreenState();
}

class _EditLocationScreenState extends ConsumerState<EditLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _postalCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _descriptionCtrl;

  late ProviderType _locationType;
  late Map<String, DayHours> _hours;
  List<String> _existingPhotos = [];
  final List<XFile> _newPhotos = [];

  // Location coordinates
  double _latitude = 0;
  double _longitude = 0;

  static const _dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  bool get _isEditing => widget.location != null;

  @override
  void initState() {
    super.initState();
    final loc = widget.location;
    _nameCtrl = TextEditingController(text: loc?.name ?? '');
    _streetCtrl = TextEditingController(text: loc?.streetAddress ?? '');
    _cityCtrl = TextEditingController(text: loc?.city ?? '');
    _postalCtrl = TextEditingController(text: loc?.postalCode ?? '');
    _phoneCtrl = TextEditingController(text: loc?.phone ?? '');
    _emailCtrl = TextEditingController(text: loc?.email ?? '');
    _websiteCtrl = TextEditingController(text: loc?.website ?? '');
    _descriptionCtrl = TextEditingController(text: loc?.description ?? '');
    _locationType = loc?.providerType ??
        ref.read(myProviderProvider)?.providerType ??
        ProviderType.repairShop;
    _existingPhotos = List<String>.from(loc?.photoUrls ?? []);
    _latitude = loc?.latitude ?? 0;
    _longitude = loc?.longitude ?? 0;

    _hours = {};
    for (final k in _dayKeys) {
      _hours[k] = loc?.openingHours[k] ??
          const DayHours(open: '09:00', close: '17:00');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _postalCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked.isNotEmpty) {
      setState(() => _newPhotos.addAll(picked));
    }
  }

  void _removeExisting(int index) {
    setState(() => _existingPhotos.removeAt(index));
  }

  void _removeNew(int index) {
    setState(() => _newPhotos.removeAt(index));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = ref.read(myProviderProvider);
    if (provider == null) return;

    setState(() => _saving = true);
    final l10n = context.l10n;

    try {
      final locSvc = ref.read(locationServiceProvider);

      // Upload new photos
      List<String> newUrls = [];
      if (_newPhotos.isNotEmpty) {
        newUrls = await locSvc.uploadLocationImages(
            provider.id, _newPhotos);
      }

      final allPhotos = [..._existingPhotos, ...newUrls];
      final now = DateTime.now();

      if (_isEditing) {
        final updated = widget.location!.copyWith(
          name: _nameCtrl.text.trim(),
          providerType: _locationType,
          streetAddress: _streetCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
          postalCode: _postalCtrl.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          phone: _phoneCtrl.text.trim().isEmpty
              ? null
              : _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty
              ? null
              : _emailCtrl.text.trim(),
          website: _websiteCtrl.text.trim().isEmpty
              ? null
              : _websiteCtrl.text.trim(),
          description: _descriptionCtrl.text.trim().isEmpty
              ? null
              : _descriptionCtrl.text.trim(),
          photoUrls: allPhotos,
          openingHours: _hours,
          updatedAt: now,
        );
        await locSvc.updateLocation(updated);
      } else {
        final location = ProviderLocation(
          id: '',
          providerId: provider.id,
          providerType: _locationType,
          name: _nameCtrl.text.trim(),
          streetAddress: _streetCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
          postalCode: _postalCtrl.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          phone: _phoneCtrl.text.trim().isEmpty
              ? null
              : _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty
              ? null
              : _emailCtrl.text.trim(),
          website: _websiteCtrl.text.trim().isEmpty
              ? null
              : _websiteCtrl.text.trim(),
          description: _descriptionCtrl.text.trim().isEmpty
              ? null
              : _descriptionCtrl.text.trim(),
          photoUrls: allPhotos,
          openingHours: _hours,
          createdAt: now,
          updatedAt: now,
        );
        await locSvc.createLocation(location);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.locationSaved),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.changesSaveError(e.toString())),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final dayLabels = {
      'mon': l10n.mondayShort,
      'tue': l10n.tuesdayShort,
      'wed': l10n.wednesdayShort,
      'thu': l10n.thursdayShort,
      'fri': l10n.fridayShort,
      'sat': l10n.saturdayShort,
      'sun': l10n.sundayShort,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          _isEditing ? l10n.editLocationTitle : l10n.addLocationTitle,
          style: AppTextStyles.headline3,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            // ── Name & Type ────────────────────────────────────────────
            _Section(icon: Icons.storefront_outlined, label: l10n.locationNameSection),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.locationNameLabel,
                prefixIcon: const Icon(Icons.storefront_outlined),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.fieldRequired
                  : null,
            ),
            const SizedBox(height: 14),
            Text(l10n.locationTypeLabel, style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<ProviderType>(
              initialValue: _locationType,
              isExpanded: true,
              decoration: const InputDecoration(),
              items: ProviderType.values
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(_typeLabel(l10n, t)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _locationType = v);
              },
            ),

            const SizedBox(height: 24),

            // ── Address ────────────────────────────────────────────────
            _Section(icon: Icons.location_on_outlined, label: l10n.locationTitle),
            const SizedBox(height: 12),
            AddressAutocompleteField(
              streetController: _streetCtrl,
              cityController: _cityCtrl,
              postalController: _postalCtrl,
              labelText: l10n.streetAddressLabel,
              hintText: 'Start typing to search...',
              onAddressSelected: ({
                required String street,
                required String city,
                required String postalCode,
                required double latitude,
                required double longitude,
              }) {
                setState(() {
                  _latitude = latitude;
                  _longitude = longitude;
                });
              },
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.fieldRequired
                  : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _cityCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.cityLabel,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.fieldRequired
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _postalCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.postalCodeLabel,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.fieldRequired
                        : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Contact ────────────────────────────────────────────────
            _Section(icon: Icons.call_outlined, label: l10n.contactInfoSection),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.phoneLabel,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n.emailLabel,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _websiteCtrl,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: l10n.websiteLabel,
                prefixIcon: const Icon(Icons.language_outlined),
              ),
            ),

            const SizedBox(height: 24),

            // ── Description ────────────────────────────────────────────
            _Section(
                icon: Icons.description_outlined,
                label: l10n.descriptionTitle),
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

            // ── Opening Hours ──────────────────────────────────────────
            _Section(
                icon: Icons.schedule_outlined, label: l10n.openingHoursTitle),
            const SizedBox(height: 12),
            ...List.generate(_dayKeys.length, (i) {
              final key = _dayKeys[i];
              final dh = _hours[key] ??
                  const DayHours(open: '09:00', close: '17:00');
              return _DayRow(
                label: dayLabels[key] ?? key,
                dayHours: dh,
                onChanged: (v) => setState(() {
                  _hours = Map<String, DayHours>.from(_hours)..[key] = v;
                }),
              );
            }),

            const SizedBox(height: 24),

            // ── Photos ─────────────────────────────────────────────────
            _Section(
                icon: Icons.photo_library_outlined,
                label: l10n.photosSection),
            const SizedBox(height: 12),
            if (_existingPhotos.isNotEmpty || _newPhotos.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._existingPhotos.asMap().entries.map((e) =>
                      _PhotoTile(
                        child: Image.network(e.value,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.textSecondary)),
                        onRemove: () => _removeExisting(e.key),
                      )),
                  ..._newPhotos.asMap().entries.map((e) => _PhotoTile(
                        child: Image.asset(e.value.path,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                                Icons.image_outlined,
                                color: AppColors.textSecondary)),
                        onRemove: () => _removeNew(e.key),
                      )),
                ],
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickPhotos,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(l10n.addPhotos),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
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
                : Text(
                    _isEditing ? l10n.saveChanges : l10n.addLocation,
                    style: AppTextStyles.button),
          ),
        ),
      ),
    );
  }

  String _typeLabel(dynamic l10n, ProviderType t) => switch (t) {
        ProviderType.repairShop => l10n.providerTypeRepairShop,
        ProviderType.bikeShop => l10n.providerTypeBikeShop,
        ProviderType.chargingLocation => l10n.providerTypeChargingLocation,
        ProviderType.servicePoint => l10n.providerTypeServicePoint,
        ProviderType.rental => l10n.providerTypeRental,
      };
}

// ─── Section Header ─────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.headline3),
      ],
    );
  }
}

// ─── Day Row (simplified) ───────────────────────────────────────────────────

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.label,
    required this.dayHours,
    required this.onChanged,
  });
  final String label;
  final DayHours dayHours;
  final ValueChanged<DayHours> onChanged;

  Future<void> _pickTime(
    BuildContext context, {
    required String initial,
    required void Function(String) onPicked,
  }) async {
    final parts = initial.split(':');
    final hour = int.tryParse(parts.first) ?? 9;
    final minute = int.tryParse(parts.last) ?? 0;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      final str =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onPicked(str);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(label,
                  style: AppTextStyles.labelSmall
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
            SizedBox(
              width: 80,
              child: Row(
                children: [
                  Checkbox(
                    value: dayHours.closed,
                    activeColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    visualDensity: VisualDensity.compact,
                    onChanged: (v) => onChanged(DayHours(
                      open: dayHours.open,
                      close: dayHours.close,
                      closed: v ?? false,
                    )),
                  ),
                  Text(l10n.closedLabel, style: AppTextStyles.labelSmall),
                ],
              ),
            ),
            const Spacer(),
            if (!dayHours.closed)
              _TimeChip(
                label: dayHours.open,
                onTap: () => _pickTime(
                  context,
                  initial: dayHours.open,
                  onPicked: (t) => onChanged(DayHours(
                    open: t,
                    close: dayHours.close,
                    closed: false,
                  )),
                ),
              ),
            if (!dayHours.closed)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('–', style: AppTextStyles.bodySmall),
              ),
            if (!dayHours.closed)
              _TimeChip(
                label: dayHours.close,
                onTap: () => _pickTime(
                  context,
                  initial: dayHours.close,
                  onPicked: (t) => onChanged(DayHours(
                    open: dayHours.open,
                    close: t,
                    closed: false,
                  )),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(label, style: AppTextStyles.bodySmall),
      ),
    );
  }
}

// ─── Photo Tile ─────────────────────────────────────────────────────────────

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.child, required this.onRemove});
  final Widget child;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        children: [
          Container(
            width: 80,
            height: 80,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: child,
          ),
          Positioned(
            top: 2,
            right: 2,
            child: IconButton.filled(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 12),
              style: IconButton.styleFrom(
                backgroundColor: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.9),
                foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                minimumSize: const Size(20, 20),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
