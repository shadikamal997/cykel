/// CYKEL — Student Verification Screen
/// Phase 2: Email domain verification for student discount (50% off premium)
/// Supported domains: .edu, .ac.dk, .ku.dk, .dtu.dk, .cbs.dk, .ruc.dk, .au.dk

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/user_profile_provider.dart';

/// Whitelisted student email domains.
const List<String> _studentEmailDomains = [
  '.edu',       // International universities
  '.ac.dk',     // Danish academic institutions
  '.ku.dk',     // University of Copenhagen
  '.dtu.dk',    // Technical University of Denmark
  '.cbs.dk',    // Copenhagen Business School
  '.ruc.dk',    // Roskilde University
  '.au.dk',     // Aarhus University
  '.sdu.dk',    // University of Southern Denmark
  '.aau.dk',    // Aalborg University
];

class StudentVerificationScreen extends ConsumerStatefulWidget {
  const StudentVerificationScreen({super.key});

  @override
  ConsumerState<StudentVerificationScreen> createState() =>
      _StudentVerificationScreenState();
}

class _StudentVerificationScreenState
    extends ConsumerState<StudentVerificationScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;
  bool _verificationEmailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Validate if email domain is in whitelist.
  bool _isValidStudentEmail(String email) {
    final lowercaseEmail = email.toLowerCase();
    return _studentEmailDomains.any((domain) => lowercaseEmail.endsWith(domain));
  }

  /// Send verification email and update Firestore.
  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();

    if (!_isValidStudentEmail(email)) {
      setState(() {
        _errorMessage = 'Invalid student email domain. Please use your university email (.edu, .ac.dk, etc.)';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Not authenticated');
      }

      // Update user profile with student status
      // Verification expires in 1 year
      final verifiedUntil = DateTime.now().add(const Duration(days: 365));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'isStudent': true,
        'isStudentVerified': true,
        'studentEmail': email,
        'studentVerifiedUntil': verifiedUntil.toIso8601String(),
        'studentVerifiedAt': DateTime.now().toIso8601String(),
      });

      // TODO: Send verification email via Cloud Function
      // For now, we trust the domain validation
      // In production, you'd send verification link to student email

      setState(() {
        _verificationEmailSent = true;
        _isLoading = false;
      });

      // Refresh user profile provider
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Student status verified! You can now get 50% off Premium.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate back after 2 seconds
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop(true); // Return success
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Verification failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.studentVerificationTitle),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.blue.shade800
                          : Colors.blue.shade700,
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.blue.shade900
                          : Colors.blue.shade900,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.school, size: 64, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      '🎓 Get 50% OFF Premium',
                      style: AppTextStyles.headline2.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'kr 10/month instead of kr 20',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Benefits
              const Text(
                'Student Benefits',
                style: AppTextStyles.headline3,
              ),
              const SizedBox(height: 16),
              const _BenefitTile(
                icon: Icons.discount,
                title: '50% Discount',
                subtitle: 'Save kr 120/year on Premium',
              ),
              const _BenefitTile(
                icon: Icons.verified,
                title: 'Quick Verification',
                subtitle: 'Just enter your university email',
              ),
              const _BenefitTile(
                icon: Icons.calendar_today,
                title: 'Valid for 1 Year',
                subtitle: 'Re-verify annually',
              ),
              const SizedBox(height: 32),

              // Email input
              const Text(
                'University Email',
                style: AppTextStyles.labelMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enabled: !_isLoading && !_verificationEmailSent,
                decoration: InputDecoration(
                  hintText: 'student@ku.dk',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your university email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Accepted domains
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.surfaceVariant,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Accepted Domains',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _studentEmailDomains
                          .map(
                            (domain) => Chip(
                              label: Text(
                                domain,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor:
                                  AppColors.surface,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading || _verificationEmailSent
                      ? null
                      : _submitVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    foregroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _verificationEmailSent
                              ? '✅ Verified'
                              : 'Verify Student Status',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Footer note
              Center(
                child: Text(
                  'Verification is valid for 1 year.\nYou\'ll need to re-verify annually.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.blue.shade900.withValues(alpha: 0.3)
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.blue.shade300
                  : Colors.blue.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
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
