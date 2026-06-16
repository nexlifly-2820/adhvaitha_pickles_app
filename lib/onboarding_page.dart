import 'dart:async';
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
  bool _isLoading = true;

  List<Map<String, String>> _steps = [];
  List<Map<String, dynamic>> _tasteOptions = [];
  StreamSubscription? _onboardingSub;
  StreamSubscription? _tasteSub;

  @override
  void initState() {
    super.initState();
    _startConfigListeners();
  }

  void _startConfigListeners() {
    _onboardingSub = AppConfigRepository().getOnboardingStream().listen((data) {
      if (mounted) {
        setState(() {
          if (data.isNotEmpty) {
            _steps = data;
            _isLoading = false;
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
    if (_isLoading || _steps.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemCount: _steps.length,
            itemBuilder: (context, i) => _buildPage(i),
          ),
          
          // Bottom Panel
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(30, 40, 30, 50),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8), Colors.black],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(_steps.length, (index) => AnimatedContainer(
                      duration: 300.ms,
                      margin: const EdgeInsets.only(right: 8),
                      height: 4,
                      width: _currentIndex == index ? 32 : 12,
                      decoration: BoxDecoration(
                        color: _currentIndex == index ? const Color(0xFFD4AF37) : Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    )),
                  ),
                  const SizedBox(height: 30),
                  
                  // Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentIndex < _steps.length - 1)
                        TextButton(
                          onPressed: _showTastePersonalizer,
                          child: const Text('SKIP STORY', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 11)),
                        )
                      else
                        const SizedBox.shrink(),
                      
                      GestureDetector(
                        onTap: () {
                          if (_currentIndex < _steps.length - 1) {
                            _pageController.nextPage(duration: 800.ms, curve: Curves.easeInOutQuart);
                          } else {
                            _showTastePersonalizer();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentIndex == _steps.length - 1 ? 'GET STARTED' : 'NEXT CHAPTER',
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

  Widget _buildPage(int i) {
    return Stack(
      children: [
        Positioned.fill(
          child: _buildBannerImage(_steps[i]['img'] ?? '')
            .animate(key: ValueKey(i)).scale(begin: const Offset(1.2, 1.2), end: const Offset(1.0, 1.0), duration: 10.seconds),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.4), Colors.transparent, Colors.black.withOpacity(0.6)],
                stops: const [0.0, 0.4, 0.8],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _steps[i]['subtitle'] ?? '', 
                    style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 10),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2, end: 0),
                const SizedBox(height: 25),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _steps[i]['title'] ?? '', 
                    style: GoogleFonts.philosopher(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w900, height: 1.0, letterSpacing: 2),
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 30),
                SizedBox(
                  width: 250,
                  child: Text(
                    _steps[i]['desc'] ?? '', 
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, height: 1.8, fontWeight: FontWeight.w500),
                  ),
                ).animate().fadeIn(delay: 900.ms),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }
    return Image.asset(path, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
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
