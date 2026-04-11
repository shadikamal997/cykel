/// CYKEL — Infrastructure Feedback Bottom Sheet (Phase 4)
///
/// Lets the rider report a cycling infrastructure issue at their current location.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/l10n/l10n.dart';
import '../data/infrastructure_service.dart';
import '../domain/infrastructure_report.dart';

class ReportInfrastructureSheet extends ConsumerStatefulWidget {
  const ReportInfrastructureSheet({super.key, required this.position});
  final LatLng position;

  @override
  ConsumerState<ReportInfrastructureSheet> createState() =>
      _ReportInfrastructureSheetState();
}

class _ReportInfrastructureSheetState
    extends ConsumerState<ReportInfrastructureSheet> {
  InfrastructureIssueType? _selected;
  final _descController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
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
            Row(
              children: [
                const Text('🔧', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(l10n.infraReportTitle,
                    style: AppTextStyles.headline3),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.infraReportSubtitle,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            // Issue type grid
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: InfrastructureIssueType.values
                  .map((t) => _IssueChip(
                        type: t,
                        l10n: l10n,
                        isSelected: _selected == t,
                        onTap: () => setState(() => _selected = t),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 14),
            // Optional description
            TextField(
              controller: _descController,
              maxLines: 2,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: l10n.infraReportDescHint,
                hintStyle: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                counterStyle: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textHint),
              ),
            ),
            const SizedBox(height: 12),
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
                label: Text(l10n.infraReportSubmit),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
    try {
      final result = await ref.read(infrastructureServiceProvider).submit(
            type: _selected!,
            position: widget.position,
            description: _descController.text.trim(),
          );
      if (mounted) {
        if (result != null) {
          Navigator.of(context).pop(true);
        } else {
          // Show error to user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.errGeneric),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _submitting = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.errGeneric),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _submitting = false);
      }
    }
  }
}

// ─── Issue Chip ───────────────────────────────────────────────────────────────

class _IssueChip extends StatelessWidget {
  const _IssueChip({
    required this.type,
    required this.l10n,
    required this.isSelected,
    required this.onTap,
  });
  final InfrastructureIssueType type;
  final AppLocalizations l10n;
  final bool isSelected;
  final VoidCallback onTap;

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
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static (String label, String icon) _meta(
          InfrastructureIssueType type, AppLocalizations l10n) =>
      switch (type) {
        InfrastructureIssueType.missingLane    => (l10n.infraMissingLane,    '🚲'),
        InfrastructureIssueType.brokenPavement => (l10n.infraBrokenPavement, '🕳'),
        InfrastructureIssueType.poorLighting   => (l10n.infraPoorLighting,   '💡'),
        InfrastructureIssueType.lackingSignage => (l10n.infraLackingSignage,  '🚦'),
        InfrastructureIssueType.blockedLane    => (l10n.infraBlockedLane,    '🚗'),
        InfrastructureIssueType.missingRamp    => (l10n.infraMissingRamp,    '♿'),
        InfrastructureIssueType.other          => (l10n.infraOther,          '📍'),
      };
}
