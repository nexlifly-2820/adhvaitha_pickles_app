import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _masterController;
  late Animation<double> _energyPulse;
  late Animation<double> _particleConvergence;
  late Animation<double> _logoReveal;
  late Animation<double> _textBlur;
  late Animation<double> _finalZoom;

  @override
  void initState() {
    super.initState();

    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // 1. Energy "Core" Pulse
    _energyPulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _masterController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );

    // 2. Particles converge into the logo
    _particleConvergence = Tween<double>(begin: 1.5, end: 0.0).animate(
      CurvedAnimation(parent: _masterController, curve: const Interval(0.2, 0.6, curve: Curves.elasticOut)),
    );

    // 3. Logo pops and glows
    _logoReveal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _masterController, curve: const Interval(0.4, 0.7, curve: Curves.bounceOut)),
    );

    // 4. Text focus reveal
    _textBlur = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _masterController, curve: const Interval(0.6, 0.9, curve: Curves.easeOut)),
    );

    // 5. Final zoom out into the app
    _finalZoom = Tween<double>(begin: 1.0, end: 5.0).animate(
      CurvedAnimation(parent: _masterController, curve: const Interval(0.9, 1.0, curve: Curves.fastOutSlowIn)),
    );

    _masterController.forward();

    Timer(const Duration(milliseconds: 4800), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  void dispose() {
    _masterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E12), // Deep black-blue for maximum contrast
        body: AnimatedBuilder(
          animation: _masterController,
          builder: (context, child) {
            return Stack(
              children: [
                // LAYER 1: CINEMATIC DYNAMIC GRID
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TechGridPainter(progress: _energyPulse.value),
                  ),
                ),

                // LAYER 2: THE SPICE CONVERGENCE (PARTICLES)
                Center(
                  child: CustomPaint(
                    size: const Size(400, 400),
                    painter: _ConvergencePainter(
                      convergence: _particleConvergence.value,
                      opacity: 1.0 - _logoReveal.value,
                    ),
                  ),
                ),

                // LAYER 3: LOGO REVEAL WITH GLASS MORPHISM
                Center(
                  child: Transform.scale(
                    scale: _logoReveal.value,
                    child: Container(
                      height: 140,
                      width: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD35400).withOpacity(0.6 * _logoReveal.value),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            color: Colors.white.withOpacity(0.9),
                            child: const Icon(
                              Icons.local_fire_department_rounded,
                              size: 70,
                              color: Color(0xFFD35400),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // LAYER 4: BRAND NAME (BLUR TO FOCUS)
                Align(
                  alignment: const Alignment(0, 0.6),
                  child: Opacity(
                    opacity: _masterController.value > 0.6 ? 1.0 : 0.0,
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: _textBlur.value, sigmaY: _textBlur.value),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ADHVAITHA',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 20 * (1 - _masterController.value * 0.1),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'M O D E R N   T R A D I T I O N',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.orange.shade400,
                              letterSpacing: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // LAYER 5: FINAL CINEMATIC BLAST
                if (_finalZoom.value > 1.0)
                  Positioned.fill(
                    child: Opacity(
                      opacity: (_finalZoom.value - 1.0) / 4.0,
                      child: Container(color: Colors.white),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ConvergencePainter extends CustomPainter {
  final double convergence;
  final double opacity;

  _ConvergencePainter({required this.convergence, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final random = math.Random(555);

    for (int i = 0; i < 150; i++) {
      double angle = random.nextDouble() * 2 * math.pi;
      double dist = (100 + random.nextDouble() * 200) * convergence;
      
      Offset pos = Offset(
        center.dx + math.cos(angle) * dist,
        center.dy + math.sin(angle) * dist,
      );

      paint.color = [
        const Color(0xFFD35400),
        const Color(0xFFFFAB40),
        const Color(0xFFF1C40F),
      ][random.nextInt(3)].withOpacity(opacity);

      canvas.drawCircle(pos, 2 + random.nextDouble() * 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _TechGridPainter extends CustomPainter {
  final double progress;
  _TechGridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange.withOpacity(0.05 * progress)
      ..strokeWidth = 0.5;

    double step = 40;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
