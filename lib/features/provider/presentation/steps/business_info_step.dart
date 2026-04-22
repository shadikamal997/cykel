/// CYKEL — Provider Onboarding: Step 1 – Business Information

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class BusinessInfoStep extends StatelessWidget {
  const BusinessInfoStep({
    super.key,
    required this.formKey,
    required this.businessNameCtrl,
    required this.legalNameCtrl,
    required this.cvrCtrl,
    required this.contactNameCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.websiteCtrl,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController businessNameCtrl;
  final TextEditingController legalNameCtrl;
  final TextEditingController cvrCtrl;
  final TextEditingController contactNameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController websiteCtrl;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Text(l10n.businessInfoTitle, style: AppTextStyles.headline3),
          const SizedBox(height: 20),

          // Business name *
          TextFormField(
            controller: businessNameCtrl,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.businessNameLabel,
              hintText: l10n.businessNameHint,
              prefixIcon: const Icon(Icons.storefront_outlined),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
          ),
          const SizedBox(height: 16),

          // Legal business name (optional)
          TextFormField(
            controller: legalNameCtrl,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.legalBusinessNameLabel,
              prefixIcon: const Icon(Icons.business_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // CVR number
          TextFormField(
            controller: cvrCtrl,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.cvrNumberLabel,
              hintText: l10n.cvrNumberHint,
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null; // Optional field
              final trimmed = v.trim();
              if (trimmed.length != 8) return 'CVR must be exactly 8 digits';
              if (!RegExp(r'^\d{8}$').hasMatch(trimmed)) return 'CVR must contain only digits';
              return null;
            },
          ),
          const SizedBox(height: 24),

          Divider(color: context.colors.border),
          const SizedBox(height: 16),

          // Contact person *
          TextFormField(
            controller: contactNameCtrl,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.contactNameLabel,
              hintText: l10n.contactNameHint,
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
          ),
          const SizedBox(height: 16),

          // Phone *
          TextFormField(
            controller: phoneCtrl,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.phoneLabel,
              hintText: l10n.phoneHint,
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
          ),
          const SizedBox(height: 16),

          // Email *
          TextFormField(
            controller: emailCtrl,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.emailLabel,
              hintText: l10n.emailHint,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return l10n.fieldRequired;
              final emailRegex =
                  RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-z]{2,}$');
              if (!emailRegex.hasMatch(v.trim())) {
                return l10n.errInvalidEmail;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Website (optional)
          TextFormField(
            controller: websiteCtrl,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: l10n.websiteLabel,
              hintText: l10n.websiteHint,
              prefixIcon: const Icon(Icons.language_outlined),
            ),
          ),
        ],
      ),
    );
  }
}
