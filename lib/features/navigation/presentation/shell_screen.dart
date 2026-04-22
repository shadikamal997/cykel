/// CYKEL — Rider Navigation Shell
/// StatefulShellRoute wrapper: preserves each tab's scroll + state.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/providers/back_button_provider.dart';
import '../../../core/theme/app_colors.dart';

// ─── Design Colors ─────────────────────────────────────────────────────────────
const _kPrimaryColor = AppColors.primary;

// ─── Tab Visibility Provider ──────────────────────────────────────────────────
/// Tracks which tab is currently visible in the navigation shell.
/// Used to dispose heavy widgets (like GoogleMap) when their tab is hidden.
/// Tab indices: 0=Home, 1=Map, 2=Activity, 3=Discover, 4=Marketplace
final tabVisibilityProvider = StateProvider<int>((ref) => 0);

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update tab visibility whenever dependencies change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(tabVisibilityProvider.notifier).state = 
            widget.navigationShell.currentIndex;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Update tab visibility on every build
    final currentIndex = widget.navigationShell.currentIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(tabVisibilityProvider.notifier).state = currentIndex;
      }
    });
    return PopScope(
      canPop: false, // Always intercept to check with handler first
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // First, check if any screen has registered a back button handler
        final handler = ref.read(backButtonHandlerProvider);
        if (handler != null) {
          final handled = await handler();
          if (handled) {
            // Handler took care of the back press (e.g., closed route card)
            return;
          }
        }
        
        // No handler or handler didn't consume the event
        if (widget.navigationShell.currentIndex == 0) {
          // On home tab and nothing to close — exit app
          // ignore: use_build_context_synchronously
          Navigator.of(context).maybePop();
        } else {
          // Not on home tab — go to home tab
          widget.navigationShell.goBranch(0, initialLocation: true);
        }
      },
      child: Scaffold(
        extendBody: true,
        body: widget.navigationShell,
        bottomNavigationBar: _CykelBottomNav(
          currentIndex: currentIndex,
          onTap: (index) {
            // Update visibility provider before navigation
            ref.read(tabVisibilityProvider.notifier).state = index;
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == currentIndex,
            );
          },
        ),
      ),
    );
  }
}

// ─── Bottom Nav Bar ───────────────────────────────────────────────────────────

class _CykelBottomNav extends StatelessWidget {
  const _CykelBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: l10n.home),
      _NavItem(icon: Icons.map_outlined, activeIcon: Icons.map_rounded, label: l10n.tabMap),
      _NavItem(icon: Icons.directions_bike_outlined, activeIcon: Icons.directions_bike_rounded, label: l10n.tabActivity),
      _NavItem(icon: Icons.explore_outlined, activeIcon: Icons.explore_rounded, label: l10n.tabDiscover),
      _NavItem(icon: Icons.storefront_outlined, activeIcon: Icons.storefront_rounded, label: l10n.tabMarketplace),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        Colors.black.withValues(alpha: 0.85),
                        Colors.grey.shade900.withValues(alpha: 0.75),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.95),
                        Colors.grey.shade50.withValues(alpha: 0.85),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(items.length, (i) {
                final item = items[i];
                final isActive = i == currentIndex;
                return Expanded(
                  child: Semantics(
                    label: '${item.label} tab${isActive ? ', selected' : ''}',
                    button: true,
                    selected: isActive,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: AnimatedScale(
                        scale: isActive ? 1.0 : 0.95,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.all(10),
                              decoration: isActive
                                  ? BoxDecoration(
                                      color: isDark
                                          ? _kPrimaryColor.withValues(alpha: 0.3)
                                          : _kPrimaryColor.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _kPrimaryColor.withValues(alpha: isDark ? 0.4 : 0.25),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    )
                                  : null,
                              child: Icon(
                                isActive ? item.activeIcon : item.icon,
                                size: 26,
                                color: isActive
                                    ? _kPrimaryColor
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.4)
                                        : Colors.black.withValues(alpha: 0.3)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
