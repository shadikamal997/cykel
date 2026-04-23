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

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ═══ BACKGROUND: HERO IMAGE (FULL SCREEN) ═══
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/hero.webp'),
                  fit: BoxFit.contain,
                  alignment: Alignment(0, -1.3),
                ),
              ),
            ),
          ),

          // ═══ BOTTOM SHEET (OVERLAPS IMAGE) ═══
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.55,
              ),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 30,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: SingleChildScrollView(
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
                      const SizedBox(height: 24),

                      // ═══ 1. APPLE BUTTON ═══
                      _PillButton(
                        onTap: isLoading
                            ? null
                            : () => ref
                                .read(authNotifierProvider.notifier)
                                .signInWithApple(),
                        backgroundColor: const Color(0xFF000000),
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

                      // ═══ 2. GOOGLE BUTTON ═══
                      _PillButton(
                        onTap: isLoading
                            ? null
                            : () => ref
                                .read(authNotifierProvider.notifier)
                                .signInWithGoogle(),
                        backgroundColor: Colors.white,
                        border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
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
                                color: Color(0xFF111111),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ═══ 3. DIVIDER ═══
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(
                              color: Color(0xFFE0E0E0),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              l10n.or,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF888888),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(
                              color: Color(0xFFE0E0E0),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ═══ 4. AUTH LINKS (INLINE) ═══
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: isLoading ? null : () => context.push(AppRoutes.login),
                            child: Text(
                              l10n.signInWithEmail,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '|',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFFCCCCCC),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: isLoading ? null : () => context.push(AppRoutes.signup),
                            child: Text(
                              l10n.createAccount,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ═══ 5. FOOTER TEXT ═══
                      Text(
                        l10n.termsNotice,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF999999),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
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
          height: 54,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(27),
            border: border,
          ),
          child: child,
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
