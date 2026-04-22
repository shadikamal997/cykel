/// CYKEL — Manage Opening Hours Screen
/// Lets the provider edit their 7-day opening hours schedule.
/// Reuses the same day-row pattern from onboarding [HoursStep].

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/provider_service.dart';
import '../domain/provider_model.dart';
import '../providers/provider_providers.dart';

class ManageHoursScreen extends ConsumerStatefulWidget {
  const ManageHoursScreen({super.key});

  @override
  ConsumerState<ManageHoursScreen> createState() => _ManageHoursScreenState();
}

class _ManageHoursScreenState extends ConsumerState<ManageHoursScreen> {
  static const _dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  late Map<String, DayHours> _hours;
  bool _saving = false;
  bool _initialised = false;

  void _init(CykelProvider p) {
    if (_initialised) return;
    _initialised = true;
    _hours = Map<String, DayHours>.from(p.openingHours);
    // Ensure all 7 days exist
    for (final k in _dayKeys) {
      _hours.putIfAbsent(k, () => const DayHours(open: '09:00', close: '17:00'));
    }
  }

  void _updateDay(String key, DayHours dh) {
    setState(() {
      _hours = Map<String, DayHours>.from(_hours)..[key] = dh;
    });
  }

  void _copyToAll() {
    final first = _hours[_dayKeys.first] ??
        const DayHours(open: '09:00', close: '17:00');
    setState(() {
      _hours = {for (final k in _dayKeys) k: first};
    });
  }

  Future<void> _save(CykelProvider current) async {
    setState(() => _saving = true);
    try {
      final updated = current.copyWith(
        openingHours: _hours,
        updatedAt: DateTime.now(),
      );
      await ref.read(providerServiceProvider).updateProvider(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.hoursSaved),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.changesSaveError(e.toString())),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(myProviderProvider);
    final l10n = context.l10n;

    if (provider == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.manageHoursTitle)),
        body: Center(child: Text(l10n.noProviderFound)),
      );
    }

    _init(provider);

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
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        title: Text(l10n.manageHoursTitle, style: AppTextStyles.headline3),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          TextButton.icon(
            onPressed: _copyToAll,
            icon: const Icon(Icons.copy_all_rounded, size: 18),
            label: Text(l10n.copyToAllDays),
            style: TextButton.styleFrom(
              foregroundColor: context.colors.textPrimary,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_dayKeys.length, (i) {
            final key = _dayKeys[i];
            final dh =
                _hours[key] ?? const DayHours(open: '09:00', close: '17:00');
            return _DayRow(
              label: dayLabels[key] ?? key,
              dayHours: dh,
              onChanged: (v) => _updateDay(key, v),
            );
          }),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: FilledButton(
            onPressed: _saving ? null : () => _save(provider),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
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
                : Text(l10n.saveChanges),
          ),
        ),
      ),
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
            SizedBox(
              width: 42,
              child: Text(label,
                  style: AppTextStyles.labelMedium
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
            SizedBox(
              width: 80,
              child: Row(
                children: [
                  Checkbox(
                    value: dayHours.closed,
                    activeColor: context.colors.textPrimary,
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
