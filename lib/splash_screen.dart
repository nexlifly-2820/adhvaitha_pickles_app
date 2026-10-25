import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import 'main.dart';
import 'onboarding_page.dart';
import 'api_service.dart';
import 'app_config_repository.dart';
import 'app_update_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _loadAdminSplashVideo();
  }

  Future<void> _loadAdminSplashVideo() async {
    String videoUrl = 'assets/images/ambhujakshi-all.mp4';
    try {
      Map<String, dynamic> config = {};
      for (var id in ['splash_video', 'splash', 'splash_screen', 'splashscreen']) {
        config = await ApiService.getAppConfig(id);
        final foundUrl = config['video_url']?.toString() ?? config['url']?.toString() ?? config['video']?.toString() ?? config['link']?.toString() ?? config['media_url']?.toString();
        if (foundUrl != null && foundUrl.isNotEmpty) {
          videoUrl = foundUrl;
          break;
        }
      }
    } catch (e) {
      debugPrint("Error loading splash video config: $e");
    }

    _initVideo(videoUrl);
  }

  void _initVideo(String url) {
    _videoController = url.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(url))
        : VideoPlayerController.asset(url);

    _videoController?.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _isVideoInitialized = true;
      });
      _videoController?.setLooping(false); // Play until finish
      _videoController?.play();
      _videoController?.addListener(_videoListener);
    }).catchError((e) {
      debugPrint("Splash video init error: $e");
      if (url.startsWith('http')) {
        _initVideo('assets/images/ambhujakshi-all.mp4');
      } else {
        _navigateToNext();
      }
    });
  }

  void _videoListener() {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    final position = _videoController!.value.position;
    final duration = _videoController!.value.duration;
    if (position >= duration && duration > Duration.zero) {
      _navigateToNext();
    }
  }

  Future<void> _navigateToNext() async {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _videoController?.removeListener(_videoListener);
    try {
      if (_videoController?.value.isPlaying == true) {
        _videoController?.pause();
      }
    } catch (_) {}

    try {
      final config = await AppConfigRepository().getAppStateStream().first;
      if (config['maintenance_mode'] == true) {
        if (mounted) _showMaintenanceOverlay();
        return;
      }

      const currentVersion = "1.0.0";
      final minVersion = config['min_version'] ?? "1.0.0";

      if (_isVersionLower(currentVersion, minVersion)) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppUpdatePage()),
        );
        return;
      }
    } catch (e) {
      debugPrint("Splash config error: $e");
    }

    Widget nextScreen;
    if (FirebaseAuth.instance.currentUser != null) {
      nextScreen = const MainScreen();
    } else {
      nextScreen = const OnboardingPage();
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, a, secondaryAnimation, c) => FadeTransition(opacity: a, child: c),
        pageBuilder: (_, animation, secondaryAnimation) => nextScreen,
      ),
    );
  }

  bool _isVersionLower(String current, String min) {
    List<int> c = current.split('.').map(int.parse).toList();
    List<int> m = min.split('.').map(int.parse).toList();
    for (int i = 0; i < c.length; i++) {
      if (c[i] < m[i]) return true;
      if (c[i] > m[i]) return false;
    }
    return false;
  }

  void _showMaintenanceOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F5C45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.handyman_rounded, color: Color(0xFFD4AF37), size: 60),
              const SizedBox(height: 20),
              Text('ROYAL KITCHEN\nRESTORATION', textAlign: TextAlign.center, style: GoogleFonts.philosopher(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 15),
              const Text(
                'We are currently updating our flavors. Our boutique will be back online shortly. Thank you for your patience.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 30),
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('CLOSE APP', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF073E2E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Video Player (Fit to screen / box cover)
          if (_isVideoInitialized && _videoController != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width > 0 ? _videoController!.value.size.width : 1600,
                  height: _videoController!.value.size.height > 0 ? _videoController!.value.size.height : 900,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ),
          
          // 2. Subtle Skip Button (Top Right, clean & discreet)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 20,
            child: GestureDetector(
              onTap: _navigateToNext,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 11),
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
