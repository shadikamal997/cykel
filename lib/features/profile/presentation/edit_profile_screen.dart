/// CYKEL — Edit Profile Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/upload_retry_helper.dart';
import '../../../core/widgets/app_image.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/user_profile_provider.dart';
import '../domain/user_profile.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  bool _saving = false;
  // Phase 3: Age preferences
  DateTime? _selectedBirthDate;
  AgeRangePreference _selectedAgePreference = AgeRangePreference.all;
  // Phase 4: Profile type
  ProfileType _selectedProfileType = ProfileType.standard;
  // Phase 4: Bike equipment
  bool _hasChildSeat = false;
  int _childSeatCapacity = 0;
  bool _hasCargoBike = false;
  bool _hasBikeTrailer = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    final profile = ref.read(userProfileProvider);
    _nameCtrl = TextEditingController(text: user?.displayName ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _selectedBirthDate = profile.birthDate;
    _selectedAgePreference = profile.ageRangePreference;
    _selectedProfileType = profile.profileType;
    _hasChildSeat = profile.hasChildSeat;
    _childSeatCapacity = profile.childSeatCapacity;
    _hasCargoBike = profile.hasCargoBike;
    _hasBikeTrailer = profile.hasBikeTrailer;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.nameCannotBeEmpty)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      // Update Firebase Auth profile
      await ref.read(authNotifierProvider.notifier).updateProfile(
            uid: user.uid,
            displayName: name,
            phone: _phoneCtrl.text,
          );
      
      // Phase 3: Update UserProfile with age preferences
      await ref.read(userProfileProvider.notifier).updateAgePreferences(
        birthDate: _selectedBirthDate,
        ageRangePreference: _selectedAgePreference,
      );
      
      // Phase 4: Update profile type
      await ref.read(userProfileProvider.notifier).updateProfileType(
        profileType: _selectedProfileType,
      );
      
      // Phase 4: Update bike equipment
      await ref.read(userProfileProvider.notifier).updateBikeEquipment(
        hasChildSeat: _hasChildSeat,
        childSeatCapacity: _childSeatCapacity,
        hasCargoBike: _hasCargoBike,
        hasBikeTrailer: _hasBikeTrailer,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.profileUpdated)),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.failedToSave('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Phase 3: Birthday picker
  Future<void> _selectBirthDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = _selectedBirthDate ?? DateTime(now.year - 25, now.month, now.day);
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Select your birth date',
    );
    
    if (picked != null) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  String _getAgePreferenceLabel(AgeRangePreference pref) {
    switch (pref) {
      case AgeRangePreference.all:
        return 'All ages';
      case AgeRangePreference.young:
        return 'Young adults (18-25)';
      case AgeRangePreference.adult:
        return 'Adults (26-35)';
      case AgeRangePreference.midlife:
        return 'Middle age (36-45)';
      case AgeRangePreference.senior:
        return 'Seniors (46+)';
    }
  }

  // Phase 4: Profile type helpers
  String _getProfileTypeLabel(ProfileType type) {
    switch (type) {
      case ProfileType.standard:
        return 'Standard - General cycling';
      case ProfileType.family:
        return 'Family - Safe routes for kids';
      case ProfileType.tourist:
        return 'Tourist - Sightseeing routes';
      case ProfileType.student:
        return 'Student - Campus routes';
    }
  }

  IconData _getProfileTypeIcon(ProfileType type) {
    switch (type) {
      case ProfileType.standard:
        return Icons.pedal_bike;
      case ProfileType.family:
        return Icons.family_restroom;
      case ProfileType.tourist:
        return Icons.camera_alt_outlined;
      case ProfileType.student:
        return Icons.school_outlined;
    }
  }

  Future<void> _uploadProfilePhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      final user = ref.read(currentUserProvider);
      if (user == null) return;

      setState(() => _saving = true);

      // Upload to Firebase Storage with retry logic
      final fileName = 'profile_photos/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);
      
      final downloadUrl = await UploadRetryHelper.uploadXFileWithRetry(
        storageRef: storageRef,
        xFile: image,
        metadata: SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'public, max-age=31536000',
        ),
      );

      // Update user profile in Firebase Auth
      await ref.read(authNotifierProvider.notifier).updateProfile(
        uid: user.uid,
        displayName: _nameCtrl.text.trim(),
        photoUrl: downloadUrl,
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.changesSaved),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(l10n.editProfileTitle),
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.saveChanges,
                    style: AppTextStyles.labelLarge
                        .copyWith(color: context.colors.textPrimary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Center(
              child: GestureDetector(
                onTap: _uploadProfilePhoto,
                child: Stack(
                  children: [
                    AppAvatar(
                      url: user?.photoUrl,
                      thumbnailUrl: user?.photoThumbnail,
                      size: 88,
                      fallbackText: (user?.displayName.isNotEmpty == true)
                          ? user!.displayName[0].toUpperCase()
                          : '?',
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? '',
              style: AppTextStyles.bodySmall
                  .copyWith(color: context.colors.textHint),
            ),
            const SizedBox(height: 28),

            // Display name
            _Field(
              controller: _nameCtrl,
              label: l10n.displayName,
              icon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Phone
            _Field(
              controller: _phoneCtrl,
              label: l10n.phoneNumber,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              hint: l10n.phoneHint,
            ),
            const SizedBox(height: 24),

            // Phase 3: Age & Preferences section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Age & Preferences',
                style: AppTextStyles.labelMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Birthday
            GestureDetector(
              onTap: () => _selectBirthDate(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.surfaceVariant),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cake_outlined,
                      size: 20,
                      color: context.colors.textPrimary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Birthday',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedBirthDate != null
                                ? DateFormat('MMMM d, yyyy').format(_selectedBirthDate!)
                                : 'Not set',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: _selectedBirthDate != null
                                  ? context.colors.textPrimary
                                  : context.colors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: context.colors.textHint,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Age Range Preference
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colors.surfaceVariant),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.groups_outlined,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preferred Age Group',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButton<AgeRangePreference>(
                          value: _selectedAgePreference,
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          items: AgeRangePreference.values.map((pref) {
                            return DropdownMenuItem(
                              value: pref,
                              child: Text(
                                _getAgePreferenceLabel(pref),
                                style: AppTextStyles.bodyMedium,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedAgePreference = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Phase 4: Profile Type section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Profile Type',
                style: AppTextStyles.labelMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Profile Type Selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colors.surfaceVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    _getProfileTypeIcon(_selectedProfileType),
                    size: 20,
                    color: context.colors.textPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose your cycling profile',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButton<ProfileType>(
                          value: _selectedProfileType,
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          items: ProfileType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Row(
                                children: [
                                  Icon(
                                    _getProfileTypeIcon(type),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getProfileTypeLabel(type),
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedProfileType = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Phase 4: Bike Equipment (only show in family mode)
            if (_selectedProfileType == ProfileType.family) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Bike Equipment',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Child Seat Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.surfaceVariant),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.child_care,
                      size: 20,
                      color: context.colors.textPrimary,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Has child seat',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    Switch(
                      value: _hasChildSeat,
                      onChanged: (value) {
                        setState(() {
                          _hasChildSeat = value;
                          if (!value) _childSeatCapacity = 0;
                        });
                      },
                    ),
                  ],
                ),
              ),
              if (_hasChildSeat) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.colors.surfaceVariant),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 32),
                      const Expanded(
                        child: Text(
                          'Number of child seats',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                      DropdownButton<int>(
                        value: _childSeatCapacity,
                        underline: const SizedBox.shrink(),
                        items: [0, 1, 2].map((count) {
                          return DropdownMenuItem(
                            value: count,
                            child: Text('$count'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _childSeatCapacity = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),

              // Cargo Bike Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.surfaceVariant),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.delivery_dining,
                      size: 20,
                      color: context.colors.textPrimary,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Has cargo bike',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    Switch(
                      value: _hasCargoBike,
                      onChanged: (value) => setState(() => _hasCargoBike = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Bike Trailer Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.surfaceVariant),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.follow_the_signs,
                      size: 20,
                      color: context.colors.textPrimary,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Has bike trailer for children',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    Switch(
                      value: _hasBikeTrailer,
                      onChanged: (value) => setState(() => _hasBikeTrailer = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white, strokeWidth: 2),
                      )
                    : Text(l10n.saveChanges,
                        style: AppTextStyles.labelLarge
                            .copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: context.colors.textPrimary),
        filled: true,
        fillColor: context.colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: context.colors.textPrimary, width: 1.5),
        ),
      ),
    );
  }
}
