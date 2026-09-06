import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app_config_repository.dart';
import 'main.dart';
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

  @override
  Widget build(BuildContext context) {
    final steps = _steps.isNotEmpty ? _steps : _defaultSteps;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemCount: steps.length,
            itemBuilder: (context, i) => _buildPage(steps[i], i),
          ),
          
          // Top Vignette
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
            ),
          ),

          // Bottom Panel
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(30, 60, 30, 50),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent, 
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.9),
                    Colors.black
                  ],
                  stops: const [0.0, 0.2, 0.6, 1.0],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(steps.length, (index) => AnimatedContainer(
                      duration: 300.ms,
                      margin: const EdgeInsets.only(right: 8),
                      height: 6,
                      width: _currentIndex == index ? 32 : 12,
                      decoration: BoxDecoration(
                        color: _currentIndex == index ? const Color(0xFFD4AF37) : Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    )),
                  ),
                  const SizedBox(height: 40),
                  
                  // Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _showTastePersonalizer,
                        child: const Text('SKIP STORY', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 11)),
                      ),
                      
                      GestureDetector(
                        onTap: () {
                          if (_currentIndex < steps.length - 1) {
                            _pageController.nextPage(duration: 800.ms, curve: Curves.easeInOutQuart);
                          } else {
                            _showTastePersonalizer();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFE5C76B)]),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentIndex == steps.length - 1 ? 'GET STARTED' : 'CONTINUE',
                                style: const TextStyle(color: Color(0xFF18453B), fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF18453B)),
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
      ),
    );
  }

  Widget _buildPage(Map<String, String> step, int i) {
    return Stack(
      children: [
        Positioned.fill(
          child: _buildBannerImage(step['img'] ?? '')
            .animate(key: ValueKey(i)).scale(begin: const Offset(1.2, 1.2), end: const Offset(1.0, 1.0), duration: 8.seconds),
        ),
        // Darker overlay for better text contrast
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.3),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 100),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18453B).withOpacity(0.8),
                    border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (step['subtitle'] ?? '').toUpperCase(), 
                    style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 10),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2, end: 0),
                const SizedBox(height: 30),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    step['title'] ?? '', 
                    style: GoogleFonts.philosopher(
                      color: Colors.white, 
                      fontSize: 60, 
                      fontWeight: FontWeight.w900, 
                      height: 1.0, 
                      letterSpacing: 2,
                      shadows: [
                        Shadow(color: Colors.black.withOpacity(0.8), offset: const Offset(2, 4), blurRadius: 10),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Text(
                        step['desc'] ?? '', 
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 16, 
                          height: 1.6, 
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(color: Colors.black, offset: const Offset(1, 1), blurRadius: 5),
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 900.ms),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static final List<Map<String, String>> _defaultSteps = [
    {
      'title': 'Legacy of\nFlavors',
      'subtitle': 'Established 1982',
      'desc': 'Experience four decades of ancestral recipes, hand-crafted in the heart of coastal Andhra.',
      'img': 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg',
    },
    {
      'title': 'Purely\nHandmade',
      'subtitle': 'Artesian Craft',
      'desc': 'Zero machines. Stone-ground spices and sun-dried ingredients preserved in medical-grade glass jars.',
      'img': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
    },
    {
      'title': 'Royal\nExperience',
      'subtitle': 'Awaiting You',
      'desc': 'Unlock the secret taste of tradition with our premium collection of pickles and snacks.',
      'img': 'assets/images/gondh_laddu_edible_gum_laddu.jpg',
    },
  ];

  Widget _buildBannerImage(String path) {
    if (path.isEmpty) {
      return Container(color: const Color(0xFF18453B), child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.white24, size: 50)));
    }
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (c, e, s) => _buildBannerImage(''));
    }
    String assetPath = path;
    if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/images/$path';
    }
    return Image.asset(assetPath, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (c, e, s) => _buildBannerImage(''));
  }

  void _showTastePersonalizer() {
    HapticFeedback.heavyImpact();
    
    // Default options if Firestore is empty
    final options = _tasteOptions.isNotEmpty ? _tasteOptions : [
      {'title': 'MILD & GENTLE', 'sub': 'Focus on flavor, low heat profile.', 'icon': 'eco', 'color': '0xFF4CAF50'},
      {'title': 'THE CLASSIC BALANCE', 'sub': 'The perfect traditional Andhra spice.', 'icon': 'balance', 'color': '0xFFFFA000'},
      {'title': 'EXTRA FIERY', 'sub': 'For the true spice connoisseurs.', 'icon': 'whatshot', 'color': '0xFFD32F2F'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF8E8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 20, left: 0, right: 0,
                child: Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 60, 30, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PERSONALIZE\nYOUR PALATE', style: GoogleFonts.philosopher(fontSize: 36, fontWeight: FontWeight.w900, color: const Color(0xFF18453B), height: 1.1)),
                    const SizedBox(height: 12),
                    const Text('Select your preferred spice level for a curated experience.', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 40),
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final opt = options[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _tasteOption(
                              index, 
                              opt['title'] ?? '', 
                              opt['sub'] ?? '', 
                              _getIconData(opt['icon'] ?? ''), 
                              Color(int.parse(opt['color']?.toString() ?? '0xFF18453B')), 
                              _selectedTasteIndex == index, 
                              () {
                                setSheetState(() => _selectedTasteIndex = index);
                                setState(() => _selectedTasteIndex = index);
                              }
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                      },
                      child: Container(
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF18453B),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: const Color(0xFF18453B).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        alignment: Alignment.center,
                        child: const Text('ENTER THE ROYAL BOUTIQUE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'eco': return Icons.eco_rounded;
      case 'balance': return Icons.balance_rounded;
      case 'whatshot': return Icons.whatshot_rounded;
      default: return Icons.restaurant_menu_rounded;
    }
  }

  Widget _tasteOption(int index, String title, String sub, IconData icon, Color color, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: 400.ms,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.grey.shade100,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected 
            ? [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))] 
            : [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF18453B), letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(sub, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            AnimatedScale(
              scale: isSelected ? 1.0 : 0.8,
              duration: 300.ms,
              child: Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined, 
                color: isSelected ? const Color(0xFF18453B) : Colors.grey.shade300, 
                size: 24
              ),
            ),
          ],
        ),
      ),
    );
  }
}
