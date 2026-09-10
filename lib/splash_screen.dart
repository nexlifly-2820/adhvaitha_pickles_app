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

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          pageBuilder: (_, __, ___) => nextScreen,
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
      backgroundColor: const Color(0xFFFFF8E8),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background Image with gentle scale pulse
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_background.png',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Image.asset('assets/images/login_bg.png', fit: BoxFit.cover),
            )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.05, 1.05),
                  duration: 10000.ms,
                ),
          ),

          // Center Animated Content
          Center(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo + Gold Glow Stack
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // GOLD GLOW
                      Container(
                        width: 320,
                        height: 320,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Color(0x55D4AF37),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      )
                          .animate(
                            onPlay: (controller) => controller.repeat(reverse: true),
                          )
                          .scale(
                            begin: const Offset(0.9, 0.9),
                            end: const Offset(1.15, 1.15),
                            duration: 3500.ms,
                          ),

                      // LOGO
                      Image.asset(
                        'assets/images/logo_no_bg.png',
                        width: 240,
                        errorBuilder: (c, e, s) => Image.asset('assets/images/adhvaitha_logo.png', width: 240),
                      )
                          .animate()
                          .fadeIn(
                            duration: 900.ms,
                          )
                          .scale(
                            begin: const Offset(0.65, 0.65),
                            end: const Offset(1, 1),
                            curve: Curves.easeOutBack,
                            duration: 1400.ms,
                          )
                          .then()
                          .moveY(
                            begin: -4,
                            end: 4,
                            duration: 2500.ms,
                            curve: Curves.easeInOut,
                          ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Brand Name
                  Text(
                    "ADHVAITHA FOODS",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cinzel(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: const Color(0xFF0F5C45),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 900.ms)
                      .slideY(
                        begin: 0.3,
                        end: 0,
                        duration: 900.ms,
                      ),

                  const SizedBox(height: 12),

                  // Tagline
                  Text(
                    "AUTHENTIC TASTE • HOMEMADE WITH LOVE",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.5,
                      color: const Color(0xFFD4AF37),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 1500.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
