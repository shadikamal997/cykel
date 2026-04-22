/// CYKEL — Help & Support Screen

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final faqs = [
      (q: l10n.faq1Q, a: l10n.faq1A),
      (q: l10n.faq2Q, a: l10n.faq2A),
      (q: l10n.faq3Q, a: l10n.faq3A),
      (q: l10n.faq4Q, a: l10n.faq4A),
      (q: l10n.faq5Q, a: l10n.faq5A),
      (q: l10n.faq6Q, a: l10n.faq6A),
    ];

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(l10n.helpTitle),
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // FAQ section
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              l10n.faqSection,
              style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.0),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colors.border, width: 0.8),
            ),
            child: Column(
              children: faqs
                  .map((faq) => _FaqTile(question: faq.q, answer: faq.a))
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Contact section
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              l10n.contactSection,
              style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.0),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colors.border, width: 0.8),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => launchUrl(
                  Uri.parse('mailto:${l10n.helpEmailAddress}')),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                child: Row(children: [
                  Icon(Icons.email_outlined,
                      size: 20, color: context.colors.textPrimary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.emailUs,
                            style: AppTextStyles.bodyMedium),
                        Text(l10n.helpEmailAddress,
                            style: AppTextStyles.bodySmall.copyWith(
                                color: context.colors.textPrimary)),
                      ],
                    ),
                  ),
                  Icon(Icons.open_in_new_rounded,
                      size: 16, color: context.colors.textHint),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            child: Row(children: [
              Expanded(
                child: Text(widget.question,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w500)),
              ),
              Icon(
                _expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 20,
                color: context.colors.textSecondary,
              ),
            ]),
          ),
        ),
        if (_expanded)
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              widget.answer,
              style: AppTextStyles.bodySmall
                  .copyWith(color: context.colors.textSecondary, height: 1.5),
            ),
          ),
        Divider(height: 1, color: context.colors.border),
      ],
    );
  }
}
