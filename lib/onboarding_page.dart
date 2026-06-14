import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'main.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  int _selectedTasteIndex = 1;

  final List<Map<String, String>> _steps = [
    {
      'title': 'ANCIENT\nHERITAGE',
      'subtitle': 'SINCE 1982',
      'desc': 'Crafting tradition in every jar. Our recipes are silent witnesses to four decades of flavor evolution.',
      'img': 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg'
    },
    {
      'title': 'STONE\nGROUND',
      'subtitle': 'THE ARTISAN WAY',
      'desc': 'No machines. Only love. We use ancestral techniques to preserve the essential oils of every spice.',
      'img': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg'
    },
    {
      'title': 'PURE\nNATURE',
      'subtitle': 'ZERO CHEMICALS',
      'desc': 'Naturally preserved using cold-pressed oils and sun-dried sea salt. Pure as the coastal Andhra sun.',
      'img': 'assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg'
    },
  ];

  @override
  Widget build(BuildContext context) {
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
          child: Image.asset(_steps[i]['img']!, fit: BoxFit.cover)
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
                    _steps[i]['subtitle']!, 
                    style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 10),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2, end: 0),
                const SizedBox(height: 25),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _steps[i]['title']!, 
                    style: GoogleFonts.philosopher(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w900, height: 1.0, letterSpacing: 2),
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 30),
                SizedBox(
                  width: 250,
                  child: Text(
                    _steps[i]['desc']!, 
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

  void _showTastePersonalizer() {
    HapticFeedback.heavyImpact();
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
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _tasteOption(0, 'MILD & GENTLE', 'Focus on flavor, low heat profile.', Icons.eco_rounded, const Color(0xFF4CAF50), _selectedTasteIndex == 0, () {
                            setSheetState(() => _selectedTasteIndex = 0);
                            setState(() => _selectedTasteIndex = 0);
                          }),
                          const SizedBox(height: 16),
                          _tasteOption(1, 'THE CLASSIC BALANCE', 'The perfect traditional Andhra spice.', Icons.balance_rounded, const Color(0xFFFFA000), _selectedTasteIndex == 1, () {
                            setSheetState(() => _selectedTasteIndex = 1);
                            setState(() => _selectedTasteIndex = 1);
                          }),
                          const SizedBox(height: 16),
                          _tasteOption(2, 'EXTRA FIERY', 'For the true spice connoisseurs.', Icons.whatshot_rounded, const Color(0xFFD32F2F), _selectedTasteIndex == 2, () {
                            setSheetState(() => _selectedTasteIndex = 2);
                            setState(() => _selectedTasteIndex = 2);
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
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
