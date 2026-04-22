/// CYKEL — Provider Onboarding: Step 4 – Opening Hours

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/provider_model.dart';

class HoursStep extends StatelessWidget {
  const HoursStep({
    super.key,
    required this.hours,
    required this.onChanged,
  });

  final Map<String, DayHours> hours;
  final ValueChanged<Map<String, DayHours>> onChanged;

  static const _dayKeys = [
    'mon',
    'tue',
    'wed',
    'thu',
    'fri',
    'sat',
    'sun',
  ];

  void _updateDay(String key, DayHours dh) {
    final copy = Map<String, DayHours>.from(hours);
    copy[key] = dh;
    onChanged(copy);
  }

  void _copyToAll() {
    final first = hours[_dayKeys.first] ??
        const DayHours(open: '09:00', close: '17:00');
    final copy = {for (final k in _dayKeys) k: first};
    onChanged(copy);
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Text(l10n.openingHoursTitle, style: AppTextStyles.headline3),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _copyToAll,
          icon: const Icon(Icons.copy_all_rounded, size: 18),
          label: Text(l10n.copyToAllDays),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_dayKeys.length, (i) {
          final key = _dayKeys[i];
          final dh =
              hours[key] ?? const DayHours(open: '09:00', close: '17:00');
          return _DayRow(
            label: dayLabels[key] ?? key,
            dayHours: dh,
            onChanged: (v) => _updateDay(key, v),
          );
        }),
      ],
    );
  }
}

// ─── Day Row ──────────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Day label
            SizedBox(
              width: 42,
              child: Text(label,
                  style: AppTextStyles.labelMedium
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
            // Closed toggle
            SizedBox(
              width: 80,
              child: Row(
                children: [
                  Checkbox(
                    value: dayHours.closed,
                    activeColor: AppColors.primary,
                    visualDensity: VisualDensity.compact,
                    onChanged: (v) => onChanged(DayHours(
                      open: dayHours.open,
                      close: dayHours.close,
                      closed: v ?? false,
                    )),
                  ),
                  Text(l10n.closedLabel,
                      style: AppTextStyles.labelSmall),
                ],
              ),
            ),
            const Spacer(),
            // Open time
            if (!dayHours.closed)
              _TimeButton(
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
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('–', style: AppTextStyles.bodyMedium),
              ),
            if (!dayHours.closed)
              _TimeButton(
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

// ─── Time Button ──────────────────────────────────────────────────────────────

class _TimeButton extends StatelessWidget {
  const _TimeButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.colors.border),
        ),
        child: Text(label, style: AppTextStyles.bodyMedium),
      ),
    );
  }
}
