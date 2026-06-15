import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'onboarding_page.dart';

// ----------------------------------------------------------------
// Adhvaitha Foods — Premium Splash Screen
// Sequence: Brand Mark drops & wobbles -> Liquid fill ->
// Wordmark stagger reveal -> Tagline -> Circular wipe transition
// ----------------------------------------------------------------

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Brand Colors
  static const Color luxuryGreen = Color(0xFF18453B);
  static const Color premiumCream = Color(0xFFFFF8E8);
  static const Color brandGold = Color(0xFFD4AF37);
  static const Color darkText = Color(0xFF2D1B12);

  late AnimationController _entranceController; // 0.0 - 1.2s : logo drop + bounce
  late AnimationController _fillController;     // 1.2 - 2.2s : gold fill effect
  late AnimationController _textController;     // 2.2 - 3.2s : wordmark + tagline
  late AnimationController _wipeController;     // 3.5 - 4.2s : circular wipe

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _wipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    // 1. Logo drops and bounces
    await _entranceController.forward();

    // 2. Gold fill animation
    await _fillController.forward();

    // 3. Text reveal
    await _textController.forward();

    // Hold for impact
    await Future.delayed(const Duration(milliseconds: 800));

    // 4. Circular wipe transition
    await _wipeController.forward();

    if (mounted) {
      Widget nextScreen;
      if (FirebaseAuth.instance.currentUser != null) {
        nextScreen = const MainScreen();
      } else {
        nextScreen = const OnboardingPage();
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: Duration.zero,
          pageBuilder: (_, __, ___) => nextScreen,
        ),
      );
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _fillController.dispose();
    _textController.dispose();
    _wipeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: premiumCream,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background Branding (Subtle)
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: Image.asset(
                'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Main Animation Core
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnimatedLogo(),
                const SizedBox(height: 40),
                _buildWordmark(),
                const SizedBox(height: 12),
                _buildTagline(),
              ],
            ),
          ),

          // Circular Wipe Overlay
          AnimatedBuilder(
            animation: _wipeController,
            builder: (context, child) {
              if (_wipeController.value == 0) return const SizedBox.shrink();
              return ClipPath(
                clipper: _CircleRevealClipper(_wipeController.value, size),
                child: Container(
                  color: luxuryGreen,
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 100,
                      height: 100,
                      errorBuilder: (c, e, s) => const Icon(Icons.restaurant, color: brandGold, size: 50),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_entranceController, _fillController]),
      builder: (context, child) {
        final entrance = _entranceController.value;
        final fill = _fillController.value;

        double scale;
        double translateY;
        double rotation;

        // Entrance Logic
        if (entrance < 0.5) {
          final t = entrance / 0.5;
          scale = 0.2 + 0.8 * Curves.easeOutBack.transform(t);
          translateY = -100 * (1 - Curves.bounceOut.transform(t));
          rotation = 0;
        } else {
          final t = (entrance - 0.5) / 0.5;
          final elastic = Curves.elasticOut.transform(t);
          scale = 1.0 + (elastic - 1.0) * 0.05;
          translateY = (1 - elastic) * 10;
          rotation = (1 - elastic) * 0.05;
        }

        return Transform.translate(
          offset: Offset(0, translateY),
          child: Transform.rotate(
            angle: rotation,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: brandGold.withOpacity(0.15 * fill),
                      blurRadius: 30 * fill,
                      spreadRadius: 5 * fill,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Stack(
                  children: [
                    // Liquid Fill Mask
                    ClipOval(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 220 * fill,
                          width: 220,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [brandGold, Color(0xFFFFE5B4)],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Logo Image
                    ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(Icons.restaurant, size: 80, color: luxuryGreen),
                        ),
                      ),
                    ),
                    // Outer Ring
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: brandGold.withOpacity(0.5 + (0.5 * fill)),
                          width: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWordmark() {
    const text = "ADHVAITHA FOODS";
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(text.length, (i) {
                final start = (i * 0.03).clamp(0.0, 1.0);
                final end = (start + 0.4).clamp(0.0, 1.0);
                final t = Interval(start, end, curve: Curves.easeOutQuart)
                    .transform(_textController.value);
    
                return Transform.translate(
                  offset: Offset(0, 12 * (1 - t)),
                  child: Opacity(
                    opacity: t,
                    child: Text(
                      text[i],
                      style: GoogleFonts.philosopher(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: luxuryGreen,
                        letterSpacing: i == text.length - 1 ? 0 : 2,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTagline() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        final t = Interval(0.7, 1.0, curve: Curves.easeIn)
            .transform(_textController.value);
        return Opacity(
          opacity: t,
          child: Text(
            "AUTHENTIC TASTE • HOMEMADE WITH LOVE",
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: brandGold,
              letterSpacing: 2,
            ),
          ),
        );
      },
    );
  }
}

class _CircleRevealClipper extends CustomClipper<Path> {
  final double progress;
  final Size screenSize;

  _CircleRevealClipper(this.progress, this.screenSize);

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = screenSize.longestSide * 1.2;
    final radius = maxRadius * progress;

    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}
