/// CYKEL — Buddy Profile Setup Screen
/// Create or edit buddy matching profile

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/buddy_matching_providers.dart';
import '../domain/buddy_profile.dart';

class BuddyProfileSetupScreen extends ConsumerStatefulWidget {
  const BuddyProfileSetupScreen({
    super.key,
    this.existingProfile,
  });

  final BuddyProfile? existingProfile;

  @override
  ConsumerState<BuddyProfileSetupScreen> createState() => _BuddyProfileSetupScreenState();
}

class _BuddyProfileSetupScreenState extends ConsumerState<BuddyProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _hometownController = TextEditingController();
  
  RidingLevel _selectedLevel = RidingLevel.casual;
  final List<RidingInterest> _selectedInterests = [];
  final List<RideAvailability> _selectedAvailability = [];
  final List<String> _selectedLanguages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Populate with existing data if editing
    if (widget.existingProfile != null) {
      final profile = widget.existingProfile!;
      _bioController.text = profile.bio ?? '';
      _hometownController.text = profile.hometown ?? '';
      _selectedLevel = profile.ridingLevel;
      _selectedInterests.addAll(profile.interests);
      _selectedAvailability.addAll(profile.availability);
      _selectedLanguages.addAll(profile.spokenLanguages);
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _hometownController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one riding interest')),
      );
      return;
    }

    if (_selectedAvailability.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one availability slot')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('Not authenticated');
      }

      final service = ref.read(buddyMatchingServiceProvider);
      
      await service.createOrUpdateProfile(
        userId: currentUser.uid,
        displayName: currentUser.displayName.isEmpty ? 'Cyclist' : currentUser.displayName,
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        hometown: _hometownController.text.trim().isEmpty ? null : _hometownController.text.trim(),
        ridingLevel: _selectedLevel,
        interests: _selectedInterests,
        availability: _selectedAvailability,
        spokenLanguages: _selectedLanguages,
        photoUrl: currentUser.photoUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(widget.existingProfile != null ? 'Edit Profile' : 'Create Profile'),
        backgroundColor: context.colors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Text(
              widget.existingProfile != null
                  ? 'Update your riding profile'
                  : 'Let\'s set up your riding profile',
              style: AppTextStyles.headline2,
            ),
            const SizedBox(height: 8),
            Text(
              'Help us find the perfect riding buddies for you',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Bio
            _buildSectionTitle('About You'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Bio (Optional)',
                hintText: 'Tell us about yourself and your riding style...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 300,
            ),
            const SizedBox(height: 16),

            // Hometown
            TextFormField(
              controller: _hometownController,
              decoration: const InputDecoration(
                labelText: 'Hometown (Optional)',
                hintText: 'Copenhagen',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Riding Level
            _buildSectionTitle('Riding Level'),
            const SizedBox(height: 8),
            Text(
              'Select your current riding ability',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ...RidingLevel.values.map((level) {
              return InkWell(
                onTap: () => setState(() => _selectedLevel = level),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      // ignore: deprecated_member_use
                      Radio<RidingLevel>(
                        value: level,
                        // ignore: deprecated_member_use
                        groupValue: _selectedLevel,
                        // ignore: deprecated_member_use
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedLevel = value);
                          }
                        },
                      ),
                      Text(level.icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(level.displayName, style: AppTextStyles.bodyMedium),
                            Text(
                              level.description,
                              style: AppTextStyles.bodySmall.copyWith(
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
            }),
            const SizedBox(height: 24),

            // Riding Interests
            _buildSectionTitle('Riding Interests'),
            const SizedBox(height: 8),
            Text(
              'Select all that apply (choose at least one)',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RidingInterest.values.map((interest) {
                final isSelected = _selectedInterests.contains(interest);
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(interest.icon),
                      const SizedBox(width: 6),
                      Text(interest.displayName),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedInterests.add(interest);
                      } else {
                        _selectedInterests.remove(interest);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Availability
            _buildSectionTitle('Availability'),
            const SizedBox(height: 8),
            Text(
              'When are you usually available to ride? (choose at least one)',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RideAvailability.values.map((availability) {
                final isSelected = _selectedAvailability.contains(availability);
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(availability.icon),
                      const SizedBox(width: 6),
                      Text(availability.displayName),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedAvailability.add(availability);
                      } else {
                        _selectedAvailability.remove(availability);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Languages
            _buildSectionTitle('Languages'),
            const SizedBox(height: 8),
            Text(
              'What languages do you speak? (Optional)',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonLanguages.map((lang) {
                final isSelected = _selectedLanguages.contains(lang['code']!);
                return FilterChip(
                  label: Text('${lang['flag']} ${lang['name']}'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedLanguages.add(lang['code']!);
                      } else {
                        _selectedLanguages.remove(lang['code']!);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Save Button
            FilledButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.existingProfile != null ? 'Update Profile' : 'Create Profile'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.headline3,
    );
  }
}

// Common languages with flags and codes
const List<Map<String, String>> _commonLanguages = [
  {'code': 'da', 'name': 'Danish', 'flag': '🇩🇰'},
  {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
  {'code': 'de', 'name': 'German', 'flag': '🇩🇪'},
  {'code': 'fr', 'name': 'French', 'flag': '🇫🇷'},
  {'code': 'es', 'name': 'Spanish', 'flag': '🇪🇸'},
  {'code': 'it', 'name': 'Italian', 'flag': '🇮🇹'},
  {'code': 'sv', 'name': 'Swedish', 'flag': '🇸🇪'},
  {'code': 'no', 'name': 'Norwegian', 'flag': '🇳🇴'},
  {'code': 'pl', 'name': 'Polish', 'flag': '🇵🇱'},
  {'code': 'ar', 'name': 'Arabic', 'flag': '🇸🇦'},
  {'code': 'zh', 'name': 'Chinese', 'flag': '🇨🇳'},
  {'code': 'ja', 'name': 'Japanese', 'flag': '🇯🇵'},
];
