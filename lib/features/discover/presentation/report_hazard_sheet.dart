/// CYKEL — Report Hazard Bottom Sheet
///
/// Shown when the user taps "Report hazard" during active navigation.
/// Lets them pick a hazard type and submits it to Firestore.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/l10n/l10n.dart';
import '../domain/crowd_hazard.dart';
import '../data/crowd_hazard_service.dart';

class ReportHazardSheet extends ConsumerStatefulWidget {
  const ReportHazardSheet({super.key, required this.position});
  final LatLng position;

  @override
  ConsumerState<ReportHazardSheet> createState() => _ReportHazardSheetState();
}

class _ReportHazardSheetState extends ConsumerState<ReportHazardSheet> {
  CrowdHazardType? _selected;
  HazardSeverity   _severity = HazardSeverity.caution;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.reportHazardTitle, style: AppTextStyles.headline3),
            const SizedBox(height: 4),
            Text(
              l10n.reportHazardSubtitle,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            // Hazard type grid
            Wrap(
              spacing:    10,
              runSpacing: 10,
              children: CrowdHazardType.values
                  .map((t) => _HazardTypeChip(
                        type:       t,
                        l10n:       l10n,
                        isSelected: _selected == t,
                        onTap:      () => setState(() => _selected = t),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            // Severity selector
            Text(l10n.hazardSeverityLabel,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: HazardSeverity.values.map((s) {
                final selected = _severity == s;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _severity = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? s.color.withValues(alpha: 0.15)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? s.color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        s.label(context),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: selected ? s.color : AppColors.textSecondary,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Submit button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (_selected == null || _submitting)
                    ? null
                    : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(l10n.reportHazardSubmit),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: AppTextStyles.labelLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selected == null) return;
    setState(() => _submitting = true);
    final result = await ref.read(crowdHazardServiceProvider).submit(
          type:     _selected!,
          position: widget.position,
          severity: _severity,
        );
    if (!mounted) return;
    switch (result) {
      case HazardSubmitted():
        Navigator.of(context).pop(true);
      case HazardDuplicate():
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.hazardDuplicateUpvoted),
            duration: const Duration(seconds: 3),
          ),
        );
      case HazardAccuracyTooLow(accuracyMeters: final acc):
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.hazardGpsAccuracyLow(acc.toStringAsFixed(0))),
            backgroundColor: Colors.red,
          ),
        );
      case HazardSubmitError():
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.hazardSubmitFailed)),
        );
    }
  }
}

// ─── Chip ─────────────────────────────────────────────────────────────────────

class _HazardTypeChip extends StatelessWidget {
  const _HazardTypeChip({
    required this.type,
    required this.l10n,
    required this.isSelected,
    required this.onTap,
  });

  final CrowdHazardType type;
  final AppLocalizations l10n;
  final bool            isSelected;
  final VoidCallback    onTap;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = _meta(type, l10n);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.warning.withValues(alpha: 0.15)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.warning : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.warning
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static (String label, String icon) _meta(
      CrowdHazardType type, AppLocalizations l10n) =>
      switch (type) {
        CrowdHazardType.roadDamage  => (l10n.hazardTypeRoadDamage,  '🕳'),
        CrowdHazardType.accident    => (l10n.hazardTypeAccident,     '🚨'),
        CrowdHazardType.debris      => (l10n.hazardTypeDebris,       '🪨'),
        CrowdHazardType.roadClosed  => (l10n.hazardTypeRoadClosed,   '🚧'),
        CrowdHazardType.badSurface  => (l10n.hazardTypeBadSurface,   '⚠️'),
        CrowdHazardType.flooding    => (l10n.hazardTypeFlooding,     '🌊'),
      };
}
