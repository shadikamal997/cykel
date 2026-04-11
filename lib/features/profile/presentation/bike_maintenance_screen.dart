/// CYKEL — Bike Maintenance Screen
/// Track and manage bike maintenance records

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/bikes_provider.dart';
import '../data/maintenance_provider.dart';
import '../domain/bike.dart';
import '../domain/maintenance.dart';

class BikeMaintenanceScreen extends ConsumerWidget {
  const BikeMaintenanceScreen({super.key, required this.bike});

  final Bike bike;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(bikeMaintenanceProvider(bike.id));
    final totalKm = bike.totalKm ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('${bike.name} - ${context.l10n.bikeMaintenanceTitle}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRecordSheet(context, ref),
          ),
        ],
      ),
      body: recordsAsync.when(
        data: (records) {
          final status = MaintenanceStatus(
            bikeId: bike.id,
            totalKm: totalKm,
            records: records,
          );

          return CustomScrollView(
            slivers: [
              // Health Score Card
              SliverToBoxAdapter(
                child: _HealthScoreCard(status: status),
              ),

              // Alerts Section
              if (status.overdueItems.isNotEmpty || status.dueSoonItems.isNotEmpty)
                SliverToBoxAdapter(
                  child: _AlertsSection(status: status, totalKm: totalKm),
                ),

              // Records List Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    context.l10n.serviceHistory,
                    style: AppTextStyles.headline3,
                  ),
                ),
              ),

              // Records List
              if (records.isEmpty)
                SliverToBoxAdapter(
                  child: _EmptyState(onAdd: () => _showAddRecordSheet(context, ref)),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _RecordTile(
                      record: records[index],
                      totalKm: totalKm,
                      onTap: () => _showRecordDetails(context, ref, records[index]),
                    ),
                    childCount: records.length,
                  ),
                ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.errorPrefix(e.toString()))),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRecordSheet(context, ref),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.addService),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black,
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        elevation: 0,
      ),
    );
  }

  void _showAddRecordSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddMaintenanceSheet(bike: bike),
    );
  }

  void _showRecordDetails(BuildContext context, WidgetRef ref, MaintenanceRecord record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RecordDetailsSheet(record: record, bike: bike),
    );
  }
}

// ─── Health Score Card ────────────────────────────────────────────────────────

class _HealthScoreCard extends StatelessWidget {
  const _HealthScoreCard({required this.status});

  final MaintenanceStatus status;

  @override
  Widget build(BuildContext context) {
    final score = status.healthScore;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;
    final color = score >= 80
        ? baseColor.withValues(alpha: 1.0)
        : score >= 60
            ? baseColor.withValues(alpha: 0.7)
            : baseColor.withValues(alpha: 0.5);

    return Card(
      margin: const EdgeInsets.all(16),
      color: context.colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Score Circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 4),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: AppTextStyles.headline2.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '%',
                      style: AppTextStyles.bodySmall.copyWith(color: color),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            // Status Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.bikeCondition,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status.healthLabel,
                    style: AppTextStyles.headline3.copyWith(color: color),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${status.totalKm.toStringAsFixed(0)} ${context.l10n.kmRidden}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Alerts Section ───────────────────────────────────────────────────────────

class _AlertsSection extends StatelessWidget {
  const _AlertsSection({required this.status, required this.totalKm});

  final MaintenanceStatus status;
  final double totalKm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status.overdueItems.isNotEmpty) ...[
            _AlertCard(
              icon: Icons.warning_amber_rounded,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.9),
              title: context.l10n.overdueAlert,
              items: status.overdueItems.map((r) => 
                '${r.type.displayName}: ${(-r.kmUntilService(totalKm)).toStringAsFixed(0)} km over'
              ).toList(),
            ),
            const SizedBox(height: 8),
          ],
          if (status.dueSoonItems.isNotEmpty)
            _AlertCard(
              icon: Icons.schedule,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7),
              title: context.l10n.dueSoonAlert,
              items: status.dueSoonItems.map((r) => 
                '${r.type.displayName}: om ${r.kmUntilService(totalKm).toStringAsFixed(0)} km'
              ).toList(),
            ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final Color color;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(color: color),
                  ),
                  const SizedBox(height: 4),
                  ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(item, style: AppTextStyles.bodySmall),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Record Tile ──────────────────────────────────────────────────────────────

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.record,
    required this.totalKm,
    required this.onTap,
  });

  final MaintenanceRecord record;
  final double totalKm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;
    final isOverdue = record.isOverdue(totalKm);
    final isDueSoon = record.isDueSoon(totalKm);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: isOverdue
            ? baseColor.withValues(alpha: 0.1)
            : isDueSoon
                ? baseColor.withValues(alpha: 0.1)
                : context.colors.surface,
        child: Icon(
          Icons.build_circle_outlined,
          color: isOverdue
              ? baseColor.withValues(alpha: 0.9)
              : isDueSoon
                  ? baseColor.withValues(alpha: 0.7)
                  : baseColor.withValues(alpha: 0.5),
        ),
      ),
      title: Text(record.type.displayName),
      subtitle: Text(
        '${_formatDate(record.date)} • ${record.kmAtService.toStringAsFixed(0)} km',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      trailing: record.cost != null
          ? Text(
              context.l10n.currencyDkk(record.cost!.toStringAsFixed(0)),
              style: AppTextStyles.labelMedium,
            )
          : null,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.build_circle_outlined,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.noServiceHistory,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.addFirstService,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(context.l10n.addService),
          ),
        ],
      ),
    );
  }
}

// ─── Add Maintenance Sheet ────────────────────────────────────────────────────

class _AddMaintenanceSheet extends ConsumerStatefulWidget {
  const _AddMaintenanceSheet({required this.bike});

  final Bike bike;

  @override
  ConsumerState<_AddMaintenanceSheet> createState() => _AddMaintenanceSheetState();
}

class _AddMaintenanceSheetState extends ConsumerState<_AddMaintenanceSheet> {
  final _formKey = GlobalKey<FormState>();
  MaintenanceType _type = MaintenanceType.chain;
  DateTime _date = DateTime.now();
  final _kmController = TextEditingController();
  final _notesController = TextEditingController();
  final _costController = TextEditingController();
  final _shopController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill km with bike's total
    if (widget.bike.totalKm != null) {
      _kmController.text = widget.bike.totalKm!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _kmController.dispose();
    _notesController.dispose();
    _costController.dispose();
    _shopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(context.l10n.addService, style: AppTextStyles.headline3),
              const SizedBox(height: 24),

              // Type Dropdown
              DropdownButtonFormField<MaintenanceType>(
                initialValue: _type,
                decoration: InputDecoration(
                  labelText: context.l10n.serviceType,
                  border: const OutlineInputBorder(),
                ),
                items: MaintenanceType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _type = value!),
              ),
              const SizedBox(height: 16),

              // Date Picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.serviceDate),
                subtitle: Text(_formatDate(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _date = picked);
                  }
                },
              ),
              const Divider(),

              // Km Field
              TextFormField(
                controller: _kmController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.l10n.serviceKilometers,
                  border: const OutlineInputBorder(),
                  suffixText: 'km',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.l10n.enterKilometers;
                  }
                  if (double.tryParse(value) == null) {
                    return context.l10n.invalidValue;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Cost Field (Optional)
              TextFormField(
                controller: _costController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.l10n.servicePriceOptional,
                  border: const OutlineInputBorder(),
                  suffixText: 'DKK',
                ),
              ),
              const SizedBox(height: 16),

              // Shop Field (Optional)
              TextFormField(
                controller: _shopController,
                decoration: InputDecoration(
                  labelText: context.l10n.serviceShopOptional,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Notes Field (Optional)
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: context.l10n.serviceNotesOptional,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.l10n.saveButton),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception(context.l10n.notLoggedInError);

      final record = MaintenanceRecord(
        id: '', // Will be set by Firestore
        bikeId: widget.bike.id,
        type: _type,
        date: _date,
        kmAtService: double.parse(_kmController.text),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        cost: _costController.text.isEmpty ? null : double.tryParse(_costController.text),
        shopName: _shopController.text.isEmpty ? null : _shopController.text,
      );

      await ref.read(maintenanceServiceProvider).addRecord(
        user.uid,
        widget.bike.id,
        record,
      );

      // Update bike's totalKm if the service km is higher
      final serviceKm = double.parse(_kmController.text);
      if (serviceKm > (widget.bike.totalKm ?? 0)) {
        await ref.read(bikesServiceProvider).updateBikeKm(
          user.uid,
          widget.bike.id,
          serviceKm,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorPrefix(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Record Details Sheet ─────────────────────────────────────────────────────

class _RecordDetailsSheet extends ConsumerWidget {
  const _RecordDetailsSheet({required this.record, required this.bike});

  final MaintenanceRecord record;
  final Bike bike;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(record.type.displayName, style: AppTextStyles.headline3),
          const SizedBox(height: 16),

          _DetailRow(label: context.l10n.serviceDate, value: _formatDate(record.date)),
          _DetailRow(label: context.l10n.kilometers, value: '${record.kmAtService.toStringAsFixed(0)} km'),
          if (record.cost != null)
            _DetailRow(label: context.l10n.price, value: context.l10n.currencyDkk(record.cost!.toStringAsFixed(0))),
          if (record.shopName != null)
            _DetailRow(label: context.l10n.workshop, value: record.shopName!),
          if (record.notes != null)
            _DetailRow(label: context.l10n.notes, value: record.notes!),

          const SizedBox(height: 16),

          // Next Service Info
          Card(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.update, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.nextService,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${(record.nextServiceKm ?? (record.kmAtService + record.type.recommendedIntervalKm)).toStringAsFixed(0)} km',
                          style: AppTextStyles.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Delete Button
          TextButton.icon(
            onPressed: () => _delete(context, ref),
            icon: Icon(Icons.delete_outline, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
            label: Text(
              context.l10n.confirmDelete,
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteService),
        content: Text(l10n.deleteServiceConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.confirmDelete, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      await ref.read(maintenanceServiceProvider).deleteRecord(
        user.uid,
        bike.id,
        record.id,
      );

      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorPrefix(e.toString()))),
        );
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}
