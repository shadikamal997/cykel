/// CYKEL — My Bikes Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/bikes_provider.dart';
import '../domain/bike.dart';

class MyBikesScreen extends ConsumerWidget {
  const MyBikesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bikesAsync = ref.watch(bikesProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(l10n.myBikes),
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBikeSheet(context, ref),
        tooltip: l10n.addBikeTitle,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addBikeTitle),
      ),
      body: bikesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (bikes) {
          if (bikes.isEmpty) {
            return _EmptyBikes(
              onAdd: () => _showAddBikeSheet(context, ref),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: bikes.length,
            itemBuilder: (_, i) => _BikeCard(
              bike: bikes[i],
              onDelete: () => _deleteBike(context, ref, bikes[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteBike(
      BuildContext context, WidgetRef ref, Bike bike) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.bikeDeleteConfirm),
        content: Text(bike.name),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.no)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.yes,
                  style: TextStyle(color: context.colors.textPrimary))),
        ],
      ),
    );
    if (confirmed != true) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    
    try {
      await ref.read(bikesServiceProvider).deleteBike(user.uid, bike.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.bikeDeleted)));
      }
    } catch (e) {
      debugPrint('[MyBikes] Delete bike error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errGeneric)));
      }
    }
  }

  void _showAddBikeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _AddBikeSheet(),
    );
  }
}

// ─── Add Bike Sheet ───────────────────────────────────────────────────────────

class _AddBikeSheet extends ConsumerStatefulWidget {
  const _AddBikeSheet();

  @override
  ConsumerState<_AddBikeSheet> createState() => _AddBikeSheetState();
}

class _AddBikeSheetState extends ConsumerState<_AddBikeSheet> {
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _batteryCtrl = TextEditingController();
  BikeType _type = BikeType.city;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _yearCtrl.dispose();
    _batteryCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _saving = true);
    try {
      final bike = Bike(
        id: '',
        name: _nameCtrl.text.trim(),
        type: _type,
        brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
        year: int.tryParse(_yearCtrl.text.trim()),
        batteryCapacityWh: (_type == BikeType.ebike || _type == BikeType.cargo)
            ? double.tryParse(_batteryCtrl.text.trim())
            : null,
        createdAt: DateTime.now(),
      );
      await ref.read(bikesServiceProvider).addBike(user.uid, bike);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.bikeAdded)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.failedToAddBike('$e'))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(l10n.addBikeTitle, style: AppTextStyles.headline3),
          const SizedBox(height: 20),

          // Name
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.bikeName,
              filled: true,
              fillColor: context.colors.background,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: context.colors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: context.colors.border)),
            ),
          ),
          const SizedBox(height: 14),

          // Type chips
          Text(l10n.bikeTypeLabel,
              style: AppTextStyles.labelSmall
                  .copyWith(color: context.colors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: BikeType.values.map((t) {
              final selected = _type == t;
              return ChoiceChip(
                label: Text('${t.emoji} ${t.localizedLabel(context)}'),
                selected: selected,
                selectedColor: context.colors.border.withValues(alpha: 0.2),
                onSelected: (_) => setState(() => _type = t),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          Row(children: [
            Expanded(
              child: TextField(
                controller: _brandCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.bikeBrand,
                  filled: true,
                  fillColor: context.colors.background,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: context.colors.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: context.colors.border)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 110,
              child: TextField(
                controller: _yearCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.bikeYear,
                  filled: true,
                  fillColor: context.colors.background,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: context.colors.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: context.colors.border)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // Battery capacity field (E-Bike & Cargo only)
          if (_type == BikeType.ebike || _type == BikeType.cargo) ...[
            TextField(
              controller: _batteryCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '${l10n.batteryCapacity} (Wh)',
                hintText: 'e.g., 500',
                filled: true,
                fillColor: context.colors.background,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colors.border)),
              ),
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 4),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _add,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(l10n.addBikeTitle,
                      style: AppTextStyles.labelLarge
                          .copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bike Card ────────────────────────────────────────────────────────────────

class _BikeCard extends StatelessWidget {
  const _BikeCard({required this.bike, required this.onDelete});
  final Bike bike;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GestureDetector(
      onTap: () => context.push(AppRoutes.profileMaintenance, extra: bike),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (context.colors.textPrimary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
                child: Text(bike.type.emoji,
                    style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(bike.name,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                [
                  bike.type.label,
                  if (bike.brand != null) bike.brand!,
                  if (bike.year != null) bike.year.toString(),
                  if (bike.totalKm != null) '${bike.totalKm!.toStringAsFixed(0)} km',
                ].join(' · '),
                style: AppTextStyles.bodySmall
                    .copyWith(color: context.colors.textSecondary),
              ),
            ]),
          ),
          // Maintenance indicator
          IconButton(
            icon: Icon(Icons.build_circle_outlined,
                color: context.colors.textPrimary, size: 20),
            tooltip: l10n.maintenance,
            onPressed: () => context.push(AppRoutes.profileMaintenance, extra: bike),
          ),
          IconButton(
            tooltip: l10n.delete,
            icon: Icon(Icons.delete_outline_rounded,
                color: context.colors.textPrimary, size: 20),
            onPressed: onDelete,
          ),
        ]),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyBikes extends StatelessWidget {
  const _EmptyBikes({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🚲', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        Text(l10n.noBikesTitle, style: AppTextStyles.headline3),
        const SizedBox(height: 8),
        Text(
          l10n.noBikesSubtitle,
          style: AppTextStyles.bodyMedium
              .copyWith(color: context.colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.addBikeTitle),
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0),
        ),
      ]),
    );
  }
}
