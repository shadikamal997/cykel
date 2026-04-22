/// CYKEL — Commuter Tax Settings Screen
/// Allows users to set home and work addresses for Danish commuter tax
/// deduction calculations (befordringsfradrag).

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_gate.dart';
import '../../../services/subscription_providers.dart';
import '../../discover/data/dawa_service.dart';
import '../data/user_profile_provider.dart';

class CommuterTaxSettingsScreen extends ConsumerStatefulWidget {
  const CommuterTaxSettingsScreen({super.key});

  @override
  ConsumerState<CommuterTaxSettingsScreen> createState() =>
      _CommuterTaxSettingsScreenState();
}

class _CommuterTaxSettingsScreenState
    extends ConsumerState<CommuterTaxSettingsScreen> {
  String? _homeAddress;
  String? _workAddress;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load saved addresses from user profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(userProfileProvider);
      setState(() {
        _homeAddress = profile.homeAddress;
        _workAddress = profile.workAddress;
      });
    });
  }

  Future<void> _selectAddress({required bool isHome}) async {
    // Show DAWA autocomplete sheet for Danish address search
    final result = await showModalBottomSheet<DawaAddress>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _DawaAddressSearchSheet(
        title: isHome ? context.l10n.setHomeAddress : context.l10n.setWorkAddress,
      ),
    );

    if (result != null && result.text.isNotEmpty) {
      setState(() {
        if (isHome) {
          _homeAddress = result.text;
        } else {
          _workAddress = result.text;
        }
      });
      
      // Save both address text and coordinates
      final location = result.hasCoordinates
          ? LatLng(result.lat!, result.lng!)
          : null;
      
      await _saveAddressWithLocation(
        isHome: isHome,
        address: result.text,
        location: location,
      );
    }
  }

  Future<void> _saveAddressWithLocation({
    required bool isHome,
    required String address,
    LatLng? location,
  }) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(userProfileProvider.notifier).updateCommuterAddresses(
            homeAddress: isHome ? address : _homeAddress,
            workAddress: isHome ? _workAddress : address,
            homeLocation: isHome ? location : null,
            workLocation: isHome ? null : location,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.savedSuccessfully)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.failedToSave}: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isPremium = ref.watch(isPremiumProvider);

    if (!isPremium) {
      return PremiumGateScreen(
        screenTitle: l10n.commuterTaxTitle,
        featureDescription: l10n.commuterTaxDescription,
        child: const SizedBox.shrink(),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        title: Text(l10n.commuterTaxTitle, style: AppTextStyles.headline3),
        leading: BackButton(
          color: context.colors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Description
          Text(
            l10n.commuterTaxDescription,
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Home Address
          _AddressCard(
            title: l10n.homeAddress,
            address: _homeAddress,
            icon: Icons.home_rounded,
            onTap: () => _selectAddress(isHome: true),
          ),
          const SizedBox(height: 16),

          // Work Address
          _AddressCard(
            title: l10n.workAddress,
            address: _workAddress,
            icon: Icons.business_rounded,
            onTap: () => _selectAddress(isHome: false),
          ),
          const SizedBox(height: 24),

          // Loading indicator
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.title,
    required this.address,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String? address;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.black : Colors.white;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.textPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.textPrimary),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.labelLarge.copyWith(color: isDark ? Colors.black : Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                      address ?? context.l10n.notSet,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit_rounded, size: 20, color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── DAWA Address Search Sheet ───────────────────────────────────────────────

class _DawaAddressSearchSheet extends ConsumerStatefulWidget {
  const _DawaAddressSearchSheet({required this.title});
  
  final String title;

  @override
  ConsumerState<_DawaAddressSearchSheet> createState() =>
      _DawaAddressSearchSheetState();
}

class _DawaAddressSearchSheetState
    extends ConsumerState<_DawaAddressSearchSheet> {
  final _ctrl = TextEditingController();
  List<DawaAddress> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _search(String v) {
    _debounce?.cancel();
    if (v.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      setState(() => _loading = true);
      final results = await ref.read(dawaServiceProvider).autocomplete(v);
      if (mounted) {
        setState(() {
          _results = results;
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            
            // Title
            Text(widget.title, style: AppTextStyles.headline3),
            const SizedBox(height: 12),
            
            // Search field
            TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: l10n.searchAddress,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
            
            // Results list
            if (_results.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: context.colors.textSecondary.withValues(alpha: 0.2),
                  ),
                  itemBuilder: (_, i) {
                    final addr = _results[i];
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.place_rounded,
                        color: context.colors.primary,
                        size: 20,
                      ),
                      title: Text(
                        addr.text,
                        style: AppTextStyles.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: addr.hasCoordinates
                          ? Text(
                              '${addr.postalCode ?? ''} ${addr.city ?? ''}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            )
                          : null,
                      onTap: () => Navigator.pop(context, addr),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
