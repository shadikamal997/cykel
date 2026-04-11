/// Email Verification Screen.
/// Polls Firebase every few seconds; auto-advances to /home once verified.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cykel_button.dart';
import '../../../core/router/app_router.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  Timer? _pollTimer;
  bool _resentEmail = false;

  @override
  void initState() {
    super.initState();
    // Poll every 4 seconds to check if email is verified
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _checkVerified());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerified() async {
    await ref.read(authRepositoryProvider).reloadUser();
    // authStateProvider will re-emit; router redirect handles navigation
    final user = ref.read(currentUserProvider);
    if (user?.emailVerified == true && mounted) {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _resend() async {
    await ref.read(authNotifierProvider.notifier).resendVerificationEmail();
    if (mounted) {
      setState(() => _resentEmail = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.verificationEmailResent),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Icon
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: context.colors.primary.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mark_email_unread_outlined,
                    size: 44,
                    color: context.colors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Text(
                l10n.verifyEmailTitle,
                style: AppTextStyles.headline1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                l10n.verifyEmailSentTo(user?.email ?? ''),
                style: AppTextStyles.bodyMedium
                    .copyWith(color: context.colors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.verifyEmailAction,
                style: AppTextStyles.bodySmall
                    .copyWith(color: context.colors.textSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Checking indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.colors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.waitingForVerification,
                    style: TextStyle(color: context.colors.textSecondary),
                  ),
                ],
              ),

              const Spacer(),

              // Resend button
              CykelButton(
                label: _resentEmail ? l10n.emailSentCheck : l10n.resendEmail,
                variant: CykelButtonVariant.outline,
                isLoading: isLoading,
                onPressed: (isLoading || _resentEmail) ? null : _resend,
              ),
              const SizedBox(height: 12),

              // Sign out
              CykelButton(
                label: l10n.signOut,
                variant: CykelButtonVariant.ghost,
                onPressed: () =>
                    ref.read(authNotifierProvider.notifier).signOut(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
