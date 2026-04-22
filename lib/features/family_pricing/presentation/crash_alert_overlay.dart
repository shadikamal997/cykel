import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../services/location_service.dart';
import '../application/crash_detection_service.dart';
import '../application/family_location_service.dart';

/// Full-screen crash alert overlay with countdown
class CrashAlertOverlay extends ConsumerWidget {
  const CrashAlertOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertState = ref.watch(crashAlertStateProvider);

    if (!alertState.isActive) {
      return const SizedBox.shrink();
    }

    // Trigger haptic feedback
    HapticFeedback.heavyImpact();

    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Warning icon with pulse animation
              _PulsingIcon(),
              const SizedBox(height: 32),

              // Title
              const Text(
                'ARE YOU OK?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                alertState.event?.details ?? 'A potential crash was detected',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Countdown
              _CountdownCircle(seconds: alertState.secondsRemaining),
              const SizedBox(height: 16),

              Text(
                'Emergency alert will be sent in ${alertState.secondsRemaining} seconds',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Buttons
              Row(
                children: [
                  // I'm OK button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(crashAlertStateProvider.notifier).imOkay();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 24),
                          SizedBox(width: 8),
                          Text(
                            "I'M OK",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // I need help button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(crashAlertStateProvider.notifier).confirmCrash();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emergency, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'SEND SOS',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.white,
                size: 64,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CountdownCircle extends StatelessWidget {
  final int seconds;

  const _CountdownCircle({required this.seconds});

  @override
  Widget build(BuildContext context) {
    final progress = seconds / 30.0;

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background circle
          const CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 8,
            color: Colors.white24,
          ),
          // Progress circle
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 8,
            color: seconds <= 10 ? Colors.red : Colors.orange,
            strokeCap: StrokeCap.round,
          ),
          // Countdown text
          Center(
            child: Text(
              '$seconds',
              style: TextStyle(
                color: seconds <= 10 ? Colors.red : Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// SOS button with long-press confirmation
class SosButton extends ConsumerStatefulWidget {
  final String familyId;
  final double size;

  const SosButton({
    super.key,
    required this.familyId,
    this.size = 56,
  });

  @override
  ConsumerState<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends ConsumerState<SosButton>
    with SingleTickerProviderStateMixin {
  bool _isHolding = false;
  double _holdProgress = 0;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _progressController.addListener(() {
      setState(() => _holdProgress = _progressController.value);
    });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _triggerSos();
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _startHold() {
    setState(() => _isHolding = true);
    HapticFeedback.mediumImpact();
    _progressController.forward(from: 0);
  }

  void _cancelHold() {
    setState(() => _isHolding = false);
    _progressController.reset();
  }

  Future<void> _triggerSos() async {
    HapticFeedback.heavyImpact();
    setState(() => _isHolding = false);

    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emergency, color: Colors.red),
            ),
            const SizedBox(width: 12),
            Text('${context.l10n.familySendSOS}?'),
          ],
        ),
        content: const Text(
          'This will send an emergency alert with your location to all family admins.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.l10n.familySendSOS),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final locationService = ref.read(
          familyLocationServiceProvider,
        );
        final position = await ref
            .read(locationServiceProvider)
            .getCurrentLocation();
        await locationService.sendSosAlert(widget.familyId, position);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check, color: Colors.white),
                  SizedBox(width: 8),
                  Text('SOS alert sent to your family'),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.familySOSFailed(e.toString()))),
          );
        }
      }
    }

    _progressController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startHold(),
      onLongPressEnd: (_) => _cancelHold(),
      onLongPressCancel: _cancelHold,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Progress ring
            if (_isHolding)
              CircularProgressIndicator(
                value: _holdProgress,
                strokeWidth: 4,
                color: Colors.red,
              ),
            // Button
            Padding(
              padding: const EdgeInsets.all(4),
              child: Material(
                color: _isHolding ? Colors.red.shade700 : Colors.red,
                shape: const CircleBorder(),
                elevation: _isHolding ? 8 : 4,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    // Show hint on tap
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.commonHoldSOS),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Center(
                    child: _isHolding
                        ? const Icon(
                            Icons.emergency,
                            color: Colors.white,
                            size: 28,
                          )
                        : const Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
