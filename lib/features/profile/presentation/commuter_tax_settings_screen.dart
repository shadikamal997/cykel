/// CYKEL — Commuter Tax Settings Screen
/// Allows users to set home and work addresses for Danish commuter tax
/// deduction calculations (befordringsfradrag).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_gate.dart';
import '../../../services/subscription_providers.dart';
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
    // Show a simple text input dialog for address entry
    // In a production app, this would use DAWA API autocomplete
    final controller = TextEditingController(
      text: isHome ? _homeAddress : _workAddress,
    );
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isHome ? context.l10n.setHomeAddress : context.l10n.setWorkAddress),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: context.l10n.searchAddress,
            border: const OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        if (isHome) {
          _homeAddress = result;
        } else {
          _workAddress = result;
        }
      });
      await _saveAddresses();
    }
  }

  Future<void> _saveAddresses() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(userProfileProvider.notifier).updateCommuterAddresses(
            homeAddress: _homeAddress,
            workAddress: _workAddress,
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
        color: isDark ? Colors.white : Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white : Colors.black),
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
