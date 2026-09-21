import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app_config_repository.dart';
import 'login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  int _selectedTasteIndex = 1;

  List<Map<String, String>> _steps = [];
  List<Map<String, dynamic>> _tasteOptions = [];
  StreamSubscription? _onboardingSub;
  StreamSubscription? _tasteSub;

  @override
  void initState() {
    super.initState();
    _steps = _defaultSteps;
    _startConfigListeners();
  }

  void _startConfigListeners() {
    _onboardingSub = AppConfigRepository().getOnboardingStream().listen((data) {
      if (mounted) {
        setState(() {
          if (data.isNotEmpty) {
            _steps = data;
          }
        });
      }
    });

    _tasteSub = AppConfigRepository().getTasteOptionsStream().listen((data) {
      if (mounted) {
        setState(() {
          if (data.isNotEmpty) {
            _tasteOptions = data;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _onboardingSub?.cancel();
    _tasteSub?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildDot(bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 12 : 8,
      height: active ? 12 : 8,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE5C76B) : Colors.white54,
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = _defaultSteps;

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemCount: steps.length,
        itemBuilder: (context, i) {
          final step = steps[i];
          final String title = step['title'] ?? 'Taste The Legacy';
          final String subtitle = step['subtitle'] ?? 'Authentic Taste';
          final String desc = step['desc'] ?? 'Experience handcrafted pickles and traditional flavors.';
          final String imgPath = step['img'] ?? 'assets/images/onboarding1.jpg';
          final String overlayText = step['overlay'] ?? '';

          return Stack(
            children: [
              // 1. Background Image
              Positioned.fill(
                child: Image.asset(
                  imgPath,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Image.asset('assets/images/onboarding1.jpg', fit: BoxFit.cover),
                ),
              ),

              // 2. Dark Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.65),
                      ],
                    ),
                  ),
                ),
              ),

              // 2b. Jar Cursive Script Overlay (if provided)
              if (overlayText.isNotEmpty)
                Positioned(
                  right: 40,
                  bottom: 160,
                  child: Text(
                    overlayText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.caveat(
                      color: const Color(0xFFE5C76B),
                      fontSize: 22,
                      height: 1.1,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(blurRadius: 10, color: Colors.black),
                      ],
                    ),
                  ).animate().fadeIn(delay: 800.ms),
                ),

              // 3. Main Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Badge on Left, Header Text on Right
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Left Pill Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF18453B).withOpacity(0.85),
                              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.6)),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.eco_rounded, color: Color(0xFFD4AF37), size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  subtitle.toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFFD4AF37),
                                    letterSpacing: 2,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2, end: 0),

                          // Top Right Header Column
                          Text(
                            "PICKLES\nSPICES\nTRADITION\nALWAYS —",
                            textAlign: TextAlign.right,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFE5C76B),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.5,
                              height: 1.4,
                            ),
                          ).animate().fadeIn(delay: 300.ms),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Main Title
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: title.contains('\n') ? "${title.split('\n').first}\n" : "$title\n",
                              style: GoogleFonts.philosopher(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                            TextSpan(
                              text: title.contains('\n') ? title.split('\n').last : "The Legacy",
                              style: GoogleFonts.philosopher(
                                color: const Color(0xFFE5C76B),
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 12),

                      // Golden Flourish Rule Underline
                      Row(
                        children: [
                          Container(width: 50, height: 2, color: const Color(0xFFE5C76B)),
                          const SizedBox(width: 6),
                          const Icon(Icons.local_florist_rounded, color: Color(0xFFE5C76B), size: 12),
                          const SizedBox(width: 6),
                          Container(width: 30, height: 1, color: const Color(0xFFE5C76B)),
                        ],
                      ).animate().fadeIn(delay: 600.ms),

                      const SizedBox(height: 16),

                      // Sub-description
                      SizedBox(
                        width: 310,
                        child: Text(
                          desc,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ).animate().fadeIn(delay: 700.ms),

                      const Spacer(),

                      // Bottom Action Bar: SKIP | DOTS | NEXT →
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _navigateToLogin,
                            child: const Text(
                              "SKIP",
                              style: TextStyle(
                                color: Colors.white70,
                                letterSpacing: 3,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          Row(
                            children: List.generate(
                              steps.length,
                              (index) => _buildDot(index == _currentIndex),
                            ),
                          ),

                          GestureDetector(
                            onTap: () {
                              if (_currentIndex < steps.length - 1) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                _navigateToLogin();
                              }
                            },
                            child: Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5C76B),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE5C76B).withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  )
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currentIndex == steps.length - 1 ? 'GET STARTED' : 'NEXT',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF1B1B1B),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, color: Color(0xFF1B1B1B), size: 16),
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
            ],
          );
        },
      ),
    );
  }

  static final List<Map<String, String>> _defaultSteps = [
    {
      'title': 'Taste\nThe Legacy',
      'subtitle': 'Authentic Taste',
      'desc': 'Experience handcrafted pickles and traditional flavors made with generations of love and care.',
      'img': 'assets/images/onboarding1.jpg',
      'overlay': '',
    },
    {
      'title': 'Made The\nTraditional Way',
      'subtitle': 'Time-Honored Recipes',
      'desc': 'Prepared using authentic recipes, natural ingredients, and the warmth of home.',
      'img': 'assets/images/onboarding2.jpg',
      'overlay': 'Good Food\nBrings People\nCloser ♡',
    },
    {
      'title': 'Freshness\nIn Every Bite',
      'subtitle': 'Pure Ingredients',
      'desc': 'Carefully selected spices, farm-fresh ingredients, and authentic recipes come together to create unforgettable flavors.',
      'img': 'assets/images/onboarding3.jpg',
      'overlay': '',
    },
  ];

  void _navigateToLogin() {
    HapticFeedback.mediumImpact();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }
}
