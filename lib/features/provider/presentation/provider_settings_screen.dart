/// CYKEL — Provider Settings Screen
/// Active/closed toggles, special notice, and delete provider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/provider_service.dart';
import '../domain/provider_model.dart';
import '../providers/provider_providers.dart';

class ProviderSettingsScreen extends ConsumerStatefulWidget {
  const ProviderSettingsScreen({super.key});

  @override
  ConsumerState<ProviderSettingsScreen> createState() =>
      _ProviderSettingsScreenState();
}

class _ProviderSettingsScreenState
    extends ConsumerState<ProviderSettingsScreen> {
  late final TextEditingController _noticeCtrl;
  bool _initialised = false;
  bool _busy = false;

  void _init(CykelProvider p) {
    if (_initialised) return;
    _initialised = true;
    _noticeCtrl = TextEditingController(text: p.specialNotice ?? '');
  }

  @override
  void dispose() {
    if (_initialised) _noticeCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleActive(CykelProvider provider) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(providerServiceProvider)
          .setActive(provider.id, active: !provider.isActive);
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleClosed(CykelProvider provider) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(providerServiceProvider)
          .setTemporarilyClosed(provider.id, closed: !provider.temporarilyClosed);
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveNotice(CykelProvider provider) async {
    setState(() => _busy = true);
    try {
      final text = _noticeCtrl.text.trim().isEmpty
          ? null
          : _noticeCtrl.text.trim();
      await ref
          .read(providerServiceProvider)
          .setSpecialNotice(provider.id, text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.specialNoticeSaved),
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteProvider(CykelProvider provider) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteProviderTitle),
        content: Text(l10n.deleteProviderConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
              elevation: 0,
            ),
            child: Text(l10n.deleteProviderButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await ref.read(providerServiceProvider).deleteProvider(provider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.providerDeleted),
          ),
        );
        context.go(AppRoutes.profile);
      }
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.changesSaveError(e.toString())),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(myProviderProvider);
    final l10n = context.l10n;

    if (provider == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settingsTitle)),
        body: Center(child: Text(l10n.noProviderFound)),
      );
    }

    _init(provider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(l10n.settingsTitle, style: AppTextStyles.headline3),
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // ── Active toggle ──────────────────────────────────────
                _SettingsCard(
                  children: [
                    SwitchListTile.adaptive(
                      title: Text(l10n.activeStatusLabel,
                          style: AppTextStyles.bodyMedium),
                      subtitle: Text(l10n.activeStatusDesc,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                      value: provider.isActive,
                      activeTrackColor: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (_) => _toggleActive(provider),
                    ),
                    const Divider(color: AppColors.border),
                    SwitchListTile.adaptive(
                      title: Text(l10n.temporarilyClosedLabel,
                          style: AppTextStyles.bodyMedium),
                      subtitle: Text(l10n.temporarilyClosedDesc,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                      value: provider.temporarilyClosed,
                      activeTrackColor: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (_) => _toggleClosed(provider),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Special notice ─────────────────────────────────────
                _SettingsCard(
                  children: [
                    Text(l10n.specialNoticeLabel,
                        style: AppTextStyles.labelMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _noticeCtrl,
                      maxLines: 3,
                      maxLength: 200,
                      decoration: InputDecoration(
                        hintText: l10n.specialNoticeHint,
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: () => _saveNotice(provider),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                          elevation: 0,
                        ),
                        child: Text(l10n.saveChanges),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Danger zone ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.deleteProviderTitle,
                          style: AppTextStyles.headline3
                              .copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)),
                      const SizedBox(height: 8),
                      Text(l10n.deleteProviderConfirm,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.7))),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _deleteProvider(provider),
                        icon: const Icon(Icons.delete_forever_rounded),
                        label: Text(l10n.deleteProviderButton),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Settings Card ──────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
