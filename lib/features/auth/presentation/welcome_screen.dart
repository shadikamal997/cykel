/// Welcome Screen — first screen new/logged-out users see.
/// Design: Apple-inspired Nordic style — hero bike wheel art, curved white card, pill buttons.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../data/auth_repository.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final l10n = context.l10n;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    ref.listen<AsyncValue<void>>(authNotifierProvider, (_, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authErrorMessage(context, error)),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Stack(
        children: [
          // ── Hero image — full screen, behind everything ───────────────────
          Positioned(
            top: -60,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/hero.webp',
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),

          // ── Main column: hero on top, card on bottom ──────────────────────
          Column(
            children: [
              // ── Hero area (transparent — image is behind) ─────────────
              const Expanded(child: SizedBox.expand()),

              // ── White card ────────────────────────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 30,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(28, 0, 28, bottomPad + 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle
                      const SizedBox(height: 14),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Card heading
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.welcomeGetStarted,
                              style: AppTextStyles.headline2.copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: context.colors.textPrimary,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.welcomeJoinCommunity,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Apple button
                      _PillButton(
                        onTap: isLoading
                            ? null
                            : () => ref
                                .read(authNotifierProvider.notifier)
                                .signInWithApple(),
                        backgroundColor: Colors.black,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.apple, size: 22, color: Colors.white),
                            const SizedBox(width: 10),
                            Text(
                              l10n.continueWithApple,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Google button
                      _PillButton(
                        onTap: isLoading
                            ? null
                            : () => ref
                                .read(authNotifierProvider.notifier)
                                .signInWithGoogle(),
                        backgroundColor: Colors.white,
                        border: Border.all(color: AppColors.border, width: 1.5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CustomPaint(painter: _GoogleGPainter()),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              l10n.continueWithGoogle,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F1F1F),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              l10n.or,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: context.colors.textHint,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Email + Create account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _TextLink(
                            label: l10n.signInWithEmail,
                            onTap: isLoading ? null : () => context.push(AppRoutes.login),
                          ),
                          Container(
                            width: 1,
                            height: 14,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            color: context.colors.border,
                          ),
                          _TextLink(
                            label: l10n.createAccount,
                            onTap: isLoading ? null : () => context.push(AppRoutes.signup),
                            primary: true,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Terms
                      Text(
                        l10n.termsNotice,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.colors.textHint,
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Loading overlay ───────────────────────────────────────────────
          if (isLoading)
            Container(
              color: Colors.black38,
              child: Center(
                child: CircularProgressIndicator(
                  color: context.colors.primary,
                  strokeWidth: 2.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Pill Button ──────────────────────────────────────────────────────────────

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.child,
    required this.backgroundColor,
    this.onTap,
    this.border,
  });

  final Widget child;
  final Color backgroundColor;
  final VoidCallback? onTap;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.45 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(100),
            border: border,
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── Text Link ────────────────────────────────────────────────────────────────

class _TextLink extends StatelessWidget {
  const _TextLink({
    required this.label,
    this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: primary ? FontWeight.w700 : FontWeight.w500,
          color: primary ? context.colors.primary : context.colors.textSecondary,
          decoration: primary ? TextDecoration.underline : TextDecoration.none,
          decorationColor: context.colors.primary,
        ),
      ),
    );
  }
}
// ─── Google G Painter ─────────────────────────────────────────────────────────

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Segments of the Google G
    const List<Color> colors = [
      Color(0xFF4285F4), // blue — right (starts at -30°)
      Color(0xFF34A853), // green — bottom
      Color(0xFFFBBC05), // yellow — left
      Color(0xFFEA4335), // red — top
    ];
    const List<double> sweeps = [110.0, 90.0, 80.0, 80.0];
    const List<double> starts = [-30.0, 80.0, 170.0, 250.0];

    for (int i = 0; i < 4; i++) {
      p.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        starts[i] * math.pi / 180,
        sweeps[i] * math.pi / 180,
        true,
        p,
      );
    }

    // White inner circle
    p.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.63, p);

    // Blue horizontal bar (the cut of the G)
    p.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.175, r * 0.98, r * 0.35),
      p,
    );

    // Re-cover inner left half of bar with white
    p.color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(cx - r * 0.005, cy - r * 0.175, r * 0.63, r * 0.35),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
