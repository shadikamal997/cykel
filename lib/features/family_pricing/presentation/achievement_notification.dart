import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/family_gamification.dart';
import '../application/achievement_event_bus.dart';

/// A widget that listens for achievement unlocks and shows notifications
class AchievementNotificationListener extends ConsumerStatefulWidget {
  final Widget child;

  const AchievementNotificationListener({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AchievementNotificationListener> createState() =>
      _AchievementNotificationListenerState();
}

class _AchievementNotificationListenerState
    extends ConsumerState<AchievementNotificationListener> {
  StreamSubscription<List<UnlockedAchievement>>? _subscription;
  OverlayEntry? _currentOverlay;
  final _pendingAchievements = <UnlockedAchievement>[];
  bool _isShowingNotification = false;

  @override
  void initState() {
    super.initState();
    _subscription = achievementEventBus.stream.listen(_onAchievementsUnlocked);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _currentOverlay?.remove();
    super.dispose();
  }

  void _onAchievementsUnlocked(List<UnlockedAchievement> achievements) {
    _pendingAchievements.addAll(achievements);
    _showNextAchievement();
  }

  void _showNextAchievement() {
    if (_isShowingNotification || _pendingAchievements.isEmpty) return;

    _isShowingNotification = true;
    final unlocked = _pendingAchievements.removeAt(0);
    
    // Remove current overlay if exists
    _currentOverlay?.remove();

    // Get achievement definition
    final achievement = AchievementDefinitions.getDefinition(unlocked.type);

    // Create new overlay
    _currentOverlay = OverlayEntry(
      builder: (context) => _AchievementToast(
        achievement: achievement,
        unlockedBy: unlocked.memberName,
        onDismiss: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
          _isShowingNotification = false;
          // Show next achievement after a short delay
          Future.delayed(const Duration(milliseconds: 300), _showNextAchievement);
        },
      ),
    );

    // Show overlay
    if (mounted) {
      Overlay.of(context).insert(_currentOverlay!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// A toast notification widget for achievement unlocks
class _AchievementToast extends StatefulWidget {
  final Achievement achievement;
  final String unlockedBy;
  final VoidCallback onDismiss;

  const _AchievementToast({
    required this.achievement,
    required this.unlockedBy,
    required this.onDismiss,
  });

  @override
  State<_AchievementToast> createState() => _AchievementToastState();
}

class _AchievementToastState extends State<_AchievementToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: -100, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Start animation
    _controller.forward();

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Positioned(
      top: mediaQuery.padding.top + 16,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: _dismiss,
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                _dismiss();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.achievement.color.withValues(alpha: 0.95),
                    widget.achievement.color.withValues(alpha: 0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.achievement.color.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Trophy icon with animation
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.achievement.icon,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '🎉 Achievement Unlocked!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.achievement.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.unlockedBy.isNotEmpty
                              ? 'Unlocked by ${widget.unlockedBy}'
                              : widget.achievement.description,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Points badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '+${widget.achievement.points}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A simple snackbar-style achievement notification
void showAchievementSnackbar(BuildContext context, UnlockedAchievement unlocked) {
  final achievement = AchievementDefinitions.getDefinition(unlocked.type);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: achievement.color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              achievement.icon,
              color: achievement.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🎉 Achievement Unlocked!',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                Text(
                  achievement.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text(
                  '+${achievement.points}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Theme.of(context).colorScheme.surface,
    ),
  );
}
