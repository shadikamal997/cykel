/// Splash Screen — plays the CYKEL intro video fullscreen.
/// Navigation is handled entirely by the router redirect once:
///   (a) the video ends, AND (b) Firebase auth has resolved.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../providers/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _completed = false;
  bool _isInitialized = false;
  bool _isFadingOut = false;
  Timer? _safetyTimer;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    // Lock to portrait for the splash video.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    // Safety net: no matter what, leave the splash screen after 5 seconds.
    _safetyTimer = Timer(const Duration(seconds: 5), _markComplete);
    
    _initVideo();
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset(
      'assets/videos/splash4.mp4',
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
      ),
    );
    
    try {
      await controller.initialize();
      
      if (!mounted) {
        controller.dispose();
        return;
      }
      
      // Mute the video (splash videos should be silent)
      await controller.setVolume(0.0);
      
      // Set looping to false (play once)
      await controller.setLooping(false);
      
      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
      
      // Start fade-in animation
      _fadeController.forward();
      
      // Add listener for video progress
      controller.addListener(_onVideoProgress);
      
      // Play the video
      await controller.play();
    } catch (e) {
      // Video failed to load — skip straight to auth navigation.
      debugPrint('Splash video failed to load: $e');
      controller.dispose();
      if (mounted) _markComplete();
    }
  }

  void _onVideoProgress() {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    
    final pos = ctrl.value.position;
    final dur = ctrl.value.duration;
    
    // Check if video has ended
    if (!ctrl.value.isPlaying && pos.inMilliseconds > 0) {
      _markComplete();
      return;
    }
    
    // Trigger when within 100 ms of the end as backup
    if (dur.inMilliseconds > 0 &&
        pos.inMilliseconds >= dur.inMilliseconds - 100) {
      _markComplete();
    }
  }

  void _markComplete() {
    if (_completed) return; // guard against double-fire
    _completed = true;
    _safetyTimer?.cancel();
    _controller?.removeListener(_onVideoProgress);
    
    if (mounted) {
      setState(() => _isFadingOut = true);
      // Start fade-out animation
      _fadeController.reverse().then((_) {
        if (mounted) {
          // Small delay after fade completes for smoother transition
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted) {
              ref.read(splashVideoCompleteProvider.notifier).state = true;
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _controller?.removeListener(_onVideoProgress);
    _controller?.dispose();
    _fadeController.dispose();
    
    // Restore system UI and orientations synchronously before dispose completes
    // Using scheduleMicrotask to ensure it runs after dispose but before next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    });
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller;

    // Black screen while controller initializes (but not when fading out)
    if (!_isFadingOut && (ctrl == null || !_isInitialized || !ctrl.value.isInitialized)) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: SizedBox.square(
            dimension: 40,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: ctrl?.value.size.width ?? 720,
              height: ctrl?.value.size.height ?? 1280,
              child: ctrl != null ? VideoPlayer(ctrl) : const SizedBox(),
            ),
          ),
        ),
      ),
    );
  }
}

