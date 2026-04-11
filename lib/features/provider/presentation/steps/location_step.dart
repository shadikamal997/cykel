/// CYKEL — Provider Onboarding: Step 2 – Location

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/address_autocomplete_field.dart';

class LocationStep extends StatefulWidget {
  const LocationStep({
    super.key,
    required this.formKey,
    required this.streetCtrl,
    required this.cityCtrl,
    required this.postalCtrl,
    this.onCoordinatesSelected,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController streetCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController postalCtrl;
  final Function(double latitude, double longitude)? onCoordinatesSelected;

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Form(
      key: widget.formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Text(l10n.locationTitle, style: AppTextStyles.headline3),
          const SizedBox(height: 20),

          // Street address with autocomplete
          AddressAutocompleteField(
            streetController: widget.streetCtrl,
            cityController: widget.cityCtrl,
            postalController: widget.postalCtrl,
            labelText: l10n.streetAddressLabel,
            hintText: l10n.streetAddressHint,
            onAddressSelected: ({
              required String street,
              required String city,
              required String postalCode,
              required double latitude,
              required double longitude,
            }) {
              widget.onCoordinatesSelected?.call(latitude, longitude);
            },
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
          ),
          const SizedBox(height: 16),

          // City *
          TextFormField(
            controller: widget.cityCtrl,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.cityLabel,
              hintText: l10n.cityHint,
              prefixIcon: const Icon(Icons.location_city_outlined),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
          ),
          const SizedBox(height: 16),

          // Postal code *
          TextFormField(
            controller: widget.postalCtrl,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.postalCodeLabel,
              hintText: l10n.postalCodeHint,
              prefixIcon: const Icon(Icons.markunread_mailbox_outlined),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
          ),
          const SizedBox(height: 24),

          // Note about location
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 20, color: Color(0xFF6B7280)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Start typing your address to see suggestions. '
                    'Your location will be shown on the map for customers to find you.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: const Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
