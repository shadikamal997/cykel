/// CYKEL — Provider Onboarding: Step 6 – Review & Submit

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/provider_enums.dart';
import '../../domain/provider_model.dart';

class ReviewStep extends StatelessWidget {
  const ReviewStep({
    super.key,
    required this.providerType,
    required this.businessName,
    required this.contactName,
    required this.phone,
    required this.email,
    required this.streetAddress,
    required this.city,
    required this.postalCode,
    required this.openingHours,
    required this.hasLogo,
    required this.galleryCount,
    required this.description,
  });

  final ProviderType providerType;
  final String businessName;
  final String contactName;
  final String phone;
  final String email;
  final String streetAddress;
  final String city;
  final String postalCode;
  final Map<String, DayHours> openingHours;
  final bool hasLogo;
  final int galleryCount;
  final String description;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Text(l10n.reviewTitle, style: AppTextStyles.headline3),
        const SizedBox(height: 4),
        Text(
          l10n.reviewSubtitle,
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),

        // Business info section
        _Section(
          title: l10n.reviewBusinessInfo,
          icon: Icons.storefront_outlined,
          children: [
            _Row(label: l10n.businessNameLabel, value: businessName),
            _Row(label: l10n.contactNameLabel, value: contactName),
            _Row(label: l10n.phoneLabel, value: phone),
            _Row(label: l10n.emailLabel, value: email),
          ],
        ),
        const SizedBox(height: 16),

        // Location section
        _Section(
          title: l10n.reviewLocation,
          icon: Icons.location_on_outlined,
          children: [
            _Row(label: l10n.streetAddressLabel, value: streetAddress),
            _Row(
              label: l10n.cityLabel,
              value: '$postalCode $city',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Hours section
        _Section(
          title: l10n.reviewHours,
          icon: Icons.schedule_outlined,
          children: [
            ...openingHours.entries.map((e) {
              final day = _dayLabel(l10n, e.key);
              final hours = e.value.closed
                  ? l10n.closedLabel
                  : '${e.value.open} – ${e.value.close}';
              return _Row(label: day, value: hours);
            }),
          ],
        ),
        const SizedBox(height: 16),

        // Photos section
        _Section(
          title: l10n.reviewPhotos,
          icon: Icons.photo_library_outlined,
          children: [
            _Row(
              label: l10n.logoLabel,
              value: hasLogo ? '✓' : '–',
            ),
            _Row(
              label: l10n.galleryLabel,
              value: '$galleryCount',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Description section
        if (description.isNotEmpty) ...[
          _Section(
            title: l10n.reviewDescription,
            icon: Icons.description_outlined,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  description,
                  style: AppTextStyles.bodySmall,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Info notice
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.providerSubmitSuccessDetail,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _dayLabel(dynamic l10n, String key) => switch (key) {
        'mon' => l10n.mondayShort,
        'tue' => l10n.tuesdayShort,
        'wed' => l10n.wednesdayShort,
        'thu' => l10n.thursdayShort,
        'fri' => l10n.fridayShort,
        'sat' => l10n.saturdayShort,
        'sun' => l10n.sundayShort,
        _ => key,
      };
}

// ─── Section Card ─────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.labelMedium),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

// ─── Row ──────────────────────────────────────────────────────────────────────

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '–' : value,
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
