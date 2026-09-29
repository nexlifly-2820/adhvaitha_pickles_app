import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'onboarding_page.dart';
import 'app_config_repository.dart';
import 'app_update_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startSequence();
  }

  Future<void> _startSequence() async {
    // Hold 3.5s for cinematic sequence
    await Future.delayed(const Duration(milliseconds: 3500));

    if (mounted) {
      // Fetch App Status (Maintenance / Update)
      try {
        final config = await AppConfigRepository().getAppStateStream().first;
        if (config['maintenance_mode'] == true) {
          _showMaintenanceOverlay();
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

      // Navigate
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF073E2E),
      body: Center(
        child: Container(
          width: 210,
          height: 210,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(52),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              'assets/images/AMBHUJAKSHI  logo.png',
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => Image.asset('assets/images/logo_no_bg.png', fit: BoxFit.contain),
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 800.ms)
            .scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1.0, 1.0),
              curve: Curves.easeOutBack,
              duration: 1000.ms,
            ),
      ),
    );
  }
}
