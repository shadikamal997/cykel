/// CYKEL — Language Settings Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currentLocale = ref.watch(localeProvider);

    final languages = [
      (code: 'en', label: l10n.languageEnglish, flag: '🇬🇧'),
      (code: 'da', label: l10n.languageDanish, flag: '🇩🇰'),
    ];

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(l10n.languageTitle),
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colors.border, width: 0.8),
            ),
            child: Column(
              children: List.generate(languages.length, (i) {
                final lang = languages[i];
                final isSelected =
                    currentLocale.languageCode == lang.code;
                return Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        ref
                            .read(localeProvider.notifier)
                            .setLocale(Locale(lang.code));
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        child: Row(children: [
                          Text(lang.flag,
                              style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(lang.label,
                                style: AppTextStyles.bodyMedium),
                          ),
                          if (isSelected)
                            Icon(Icons.check_rounded,
                                color: context.colors.textPrimary, size: 20),
                        ]),
                      ),
                    ),
                    if (i < languages.length - 1)
                      Divider(
                          height: 1, indent: 56, color: context.colors.border),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
