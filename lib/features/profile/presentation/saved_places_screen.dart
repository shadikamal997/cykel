/// CYKEL — Saved Places Screen

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../discover/data/places_service.dart';
import '../../home/data/quick_routes_provider.dart';
import '../data/saved_places_provider.dart';

class SavedPlacesScreen extends ConsumerStatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  ConsumerState<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends ConsumerState<SavedPlacesScreen> {
  late final TextEditingController _homeCtrl;
  late final TextEditingController _workCtrl;

  @override
  void initState() {
    super.initState();
    final places = ref.read(savedPlacesProvider);
    _homeCtrl = TextEditingController(text: places.homeAddress ?? '');
    _workCtrl = TextEditingController(text: places.workAddress ?? '');
  }

  @override
  void dispose() {
    _homeCtrl.dispose();
    _workCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final customRoutes = ref.watch(quickRoutesProvider).custom;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(l10n.savedPlacesTitle),
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        tooltip: l10n.addPlaceTitle,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black,
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: Text(l10n.addPlaceTitle, style: AppTextStyles.labelLarge.copyWith(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          // ── Home ──────────────────────────────────────────────────────
          _PlaceCard(
            icon: Icons.home_outlined,
            label: l10n.homePlace,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            controller: _homeCtrl,
            hint: l10n.enterAddress,
            onSave: () async {
              await ref.read(savedPlacesProvider.notifier).setHome(_homeCtrl.text.trim());
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l10n.addressSaved)));
              }
            },
            onClear: () async {
              _homeCtrl.clear();
              await ref.read(savedPlacesProvider.notifier).clearHome();
            },
          ),
          const SizedBox(height: 16),

          // ── Work ──────────────────────────────────────────────────────
          _PlaceCard(
            icon: Icons.work_outline_rounded,
            label: l10n.workPlace,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            controller: _workCtrl,
            hint: l10n.enterAddress,
            onSave: () async {
              await ref.read(savedPlacesProvider.notifier).setWork(_workCtrl.text.trim());
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l10n.addressSaved)));
              }
            },
            onClear: () async {
              _workCtrl.clear();
              await ref.read(savedPlacesProvider.notifier).clearWork();
            },
          ),

          // ── Custom places (from quickRoutesProvider) ──────────────────
          if (customRoutes.isNotEmpty) ...[
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                l10n.customPlaces.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.0),
              ),
            ),
            ...customRoutes.asMap().entries.map((entry) {
              final idx = entry.key;
              final named = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CustomPlaceCard(
                  name: named.name,
                  address: named.route.text,
                  onDelete: () async {
                    await ref
                        .read(quickRoutesProvider.notifier)
                        .removeCustom(idx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.placeDeleted)));
                    }
                  },
                ),
              );
            }),
          ] else ...[
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Icon(Icons.add_location_outlined,
                      size: 36, color: context.colors.textHint),
                  const SizedBox(height: 8),
                  Text(l10n.noCustomPlaces,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: context.colors.textHint)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPlaceSheet(
        onAdd: (name, route) async {
          await ref.read(quickRoutesProvider.notifier).addCustom(
              NamedQuickRoute(name: name, route: route));
          messenger.showSnackBar(SnackBar(content: Text(l10n.placeAdded)));
        },
      ),
    );
  }
}

// ─── Place Card (home / work) ─────────────────────────────────────────────────

class _PlaceCard extends StatefulWidget {
  const _PlaceCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.controller,
    required this.hint,
    required this.onSave,
    required this.onClear,
  });

  final IconData icon;
  final String label;
  final Color color;
  final TextEditingController controller;
  final String hint;
  final VoidCallback onSave;
  final VoidCallback onClear;

  @override
  State<_PlaceCard> createState() => _PlaceCardState();
}

class _PlaceCardState extends State<_PlaceCard> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, size: 18, color: widget.color),
            ),
            const SizedBox(width: 12),
            Text(widget.label,
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 14),
          TextField(
            controller: widget.controller,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle:
                  AppTextStyles.bodyMedium.copyWith(color: context.colors.textHint),
              filled: true,
              fillColor: context.colors.background,
              isDense: true,
              suffixIcon: widget.controller.text.isNotEmpty
                  ? IconButton(
                      tooltip: context.l10n.clearSearch,
                      icon: Icon(Icons.clear_rounded,
                          size: 16, color: context.colors.textHint),
                      onPressed: widget.onClear,
                    )
                  : null,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.colors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.colors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: widget.color, width: 1.5)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.onSave,
              style: OutlinedButton.styleFrom(
                  foregroundColor: widget.color,
                  backgroundColor: widget.color,
                  side: BorderSide(color: widget.color),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              child: Text(context.l10n.saveChanges,
                  style: AppTextStyles.labelLarge.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Custom Place Card ────────────────────────────────────────────────────────

class _CustomPlaceCard extends StatelessWidget {
  const _CustomPlaceCard(
      {required this.name, required this.address, required this.onDelete});

  final String name;
  final String address;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.place_outlined,
              size: 18, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
              if (address.isNotEmpty)
                Text(address,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: context.colors.textSecondary)),
            ],
          ),
        ),
        IconButton(
          tooltip: l10n.delete,
          icon: Icon(Icons.delete_outline_rounded,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, size: 20),
          onPressed: onDelete,
        ),
      ]),
    );
  }
}

// ─── Add Place bottom sheet (with address autocomplete) ──────────────────────

class _AddPlaceSheet extends ConsumerStatefulWidget {
  const _AddPlaceSheet({required this.onAdd});
  final Future<void> Function(String name, QuickRoute route) onAdd;

  @override
  ConsumerState<_AddPlaceSheet> createState() => _AddPlaceSheetState();
}

class _AddPlaceSheetState extends ConsumerState<_AddPlaceSheet> {
  final _nameCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  List<PlaceResult> _results = [];
  PlaceResult? _selected;
  bool _searching = false;
  bool _saving = false;
  Timer? _debounce;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    setState(() { _selected = null; });
    if (v.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      setState(() => _searching = true);
      try {
        final lang = ref.read(localeProvider).languageCode;
        final results = await ref
            .read(placesServiceProvider)
            .autocomplete(v, language: lang);
        if (mounted) setState(() { _results = results; _searching = false; });
      } catch (_) {
        if (mounted) setState(() { _results = []; _searching = false; });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text(l10n.addPlaceTitle,
              style: AppTextStyles.headline3.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),

          // ── Place name ────────────────────────────────────────────────
          _Field(
            controller: _nameCtrl,
            label: l10n.placeName,
            icon: Icons.label_outline_rounded,
          ),
          const SizedBox(height: 14),

          // ── Address search ────────────────────────────────────────────
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              labelText: l10n.placeAddress,
              labelStyle: AppTextStyles.bodyMedium
                  .copyWith(color: context.colors.textSecondary),
              prefixIcon: _selected != null
                  ? Icon(Icons.check_circle_rounded,
                      size: 18, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                  : Icon(Icons.search_rounded,
                      size: 18, color: context.colors.textHint),
              suffixIcon: _searching
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2)))
                  : null,
              filled: true,
              fillColor: context.colors.background,
              isDense: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.colors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.colors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, width: 1.5)),
            ),
          ),

          // ── Autocomplete results ──────────────────────────────────────
          if (_results.isNotEmpty && _selected == null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.border),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _results.length,
                  separatorBuilder: (_, index) =>
                      Divider(height: 1, color: context.colors.border),
                  itemBuilder: (_, i) {
                    final r = _results[i];
                    return ListTile(
                      dense: true,
                      leading: Icon(Icons.place_rounded,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, size: 18),
                      title: Text(r.text,
                          style: AppTextStyles.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      onTap: () {
                        setState(() {
                          _selected = r;
                          _searchCtrl.text = r.text;
                          _results = [];
                        });
                      },
                    );
                  },
                ),
              ),
            ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_saving || _selected == null ||
                      _nameCtrl.text.trim().isEmpty)
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      final route = QuickRoute(
                        text: _selected!.text,
                        lat: _selected!.lat,
                        lng: _selected!.lng,
                      );
                      await widget.onAdd(_nameCtrl.text.trim(), route);
                      if (!mounted) return;
                      // ignore: use_build_context_synchronously
                      Navigator.pop(context);
                    },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                disabledBackgroundColor:
                    (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: _saving
                  ? SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white, strokeWidth: 2))
                  : Text(l10n.addPlaceTitle,
                      style: AppTextStyles.labelLarge),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(
      {required this.controller, required this.label, required this.icon});

  final TextEditingController controller;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: context.colors.textSecondary),
        prefixIcon: Icon(icon, size: 18, color: context.colors.textHint),
        filled: true,
        fillColor: context.colors.background,
        isDense: true,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.colors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.colors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, width: 1.5)),
      ),
    );
  }
}

