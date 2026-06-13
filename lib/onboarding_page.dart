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
  int _selectedTasteIndex = 1; // Default to 'Classic Balance'

  final List<Map<String, String>> _steps = [
    {
      'title': 'ANCIENT\nHERITAGE',
      'subtitle': 'Since 1982',
      'desc': 'Crafting tradition in every jar. Our recipes are silent witnesses to four decades of flavor evolution.',
      'img': 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg'
    },
    {
      'title': 'STONE\nGROUND',
      'subtitle': 'The Artisan Way',
      'desc': 'No machines. Only love. We use ancestral techniques to preserve the essential oils of every spice.',
      'img': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg'
    },
    {
      'title': 'PURE\nNATURE',
      'subtitle': 'Zero Chemicals',
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
          
          // Bottom Controls
          Positioned(
            bottom: 60, left: 30, right: 30,
            child: Column(
              children: [
                // Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_steps.length, (index) => AnimatedContainer(
                    duration: 300.ms,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 4,
                    width: _currentIndex == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index ? const Color(0xFFD4AF37) : Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  )),
                ),
                const SizedBox(height: 40),
                
                // Action Button
                GestureDetector(
                  onTap: () {
                    if (_currentIndex < _steps.length - 1) {
                      _pageController.nextPage(duration: 600.ms, curve: Curves.easeOutCubic);
                    } else {
                      _showTastePersonalizer();
                    }
                  },
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _currentIndex == _steps.length - 1 ? 'BEGIN YOUR JOURNEY' : 'CONTINUE',
                      style: const TextStyle(color: Color(0xFF18453B), fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Skip Button
          Positioned(
            top: 60, right: 20,
            child: TextButton(
              onPressed: _showTastePersonalizer,
              child: const Text('SKIP', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 11)),
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
            .animate(key: ValueKey(i)).scale(begin: const Offset(1.1, 1.1), end: const Offset(1.0, 1.0), duration: 5.seconds),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.6), Colors.transparent, Colors.black.withOpacity(0.9)],
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 100),
                Text(_steps[i]['subtitle']!, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 12))
                  .animate().fadeIn(delay: 300.ms).slideX(begin: -0.2, end: 0),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(_steps[i]['title']!, style: GoogleFonts.philosopher(color: Colors.white, fontSize: 50, fontWeight: FontWeight.w900, height: 1.1)),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 30),
                Text(_steps[i]['desc']!, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15, height: 1.6))
                  .animate().fadeIn(delay: 800.ms),
                const SizedBox(height: 200), // Space for bottom controls
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
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF8E8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
          ),
          padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
          child: Column(
            children: [
              Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 30),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('PERSONALIZE YOUR PALATE', style: GoogleFonts.philosopher(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFF18453B))),
              ),
              const SizedBox(height: 10),
              const Text('How spicy do you like your traditional jars?', style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 30),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _tasteOption(0, 'MILD & GENTLE', 'Focus on flavor, low heat.', Icons.eco_rounded, const Color(0xFF4CAF50), _selectedTasteIndex == 0, () {
                        setSheetState(() => _selectedTasteIndex = 0);
                        setState(() => _selectedTasteIndex = 0);
                      }),
                      const SizedBox(height: 15),
                      _tasteOption(1, 'THE CLASSIC BALANCE', 'Perfect traditional spice level.', Icons.balance_rounded, const Color(0xFFFFA000), _selectedTasteIndex == 1, () {
                        setSheetState(() => _selectedTasteIndex = 1);
                        setState(() => _selectedTasteIndex = 1);
                      }),
                      const SizedBox(height: 15),
                      _tasteOption(2, 'EXTRA FIERY', 'For the true spice connoisseurs.', Icons.whatshot_rounded, const Color(0xFFD32F2F), _selectedTasteIndex == 2, () {
                        setSheetState(() => _selectedTasteIndex = 2);
                        setState(() => _selectedTasteIndex = 2);
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF18453B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('ENTER THE BOUTIQUE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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
        duration: 300.ms,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF18453B) : Colors.grey.shade100,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF18453B).withOpacity(0.05), blurRadius: 10)] : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF18453B))),
                  Text(sub, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined, 
              color: isSelected ? const Color(0xFF18453B) : Colors.grey, 
              size: 20
            ),
          ],
        ),
      ),
    );
  }
}
