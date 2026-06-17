import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class KitchenStoryPage extends StatefulWidget {
  const KitchenStoryPage({super.key});

  @override
  State<KitchenStoryPage> createState() => _KitchenStoryPageState();
}

class _KitchenStoryPageState extends State<KitchenStoryPage> {
  final PageController _pageController = PageController();
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Map<String, String>> chapters = [
    {
      'year': '1982',
      'title': 'THE FIRST\nSPARK',
      'sub': 'A Grandmothers Legacy',
      'desc': 'In a sun-drenched kitchen in coastal Andhra, a revolution began with just 5kg of seasonal mangoes and ancestral love.',
      'image': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
    },
    {
      'year': 'RITUAL',
      'title': 'SUN, SALT &\nPATIENCE',
      'sub': 'Nature’s Slow Alchemy',
      'desc': 'We wait for the peak coastal sun to naturally dehydrate our produce for 48 hours, locking in the soul of the fruit.',
      'image': 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg',
    },
    {
      'year': 'SOUL',
      'title': 'STONE GROUND\nHERITAGE',
      'sub': 'The Sound of Purity',
      'desc': 'Zero machines. Only stone mortars slowly crushing spices to release essential oils that define our 40-year aroma.',
      'image': 'assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg',
    },
    {
      'year': 'TODAY',
      'title': 'ROYAL\nVESSELS',
      'sub': 'Delivered to your Door',
      'desc': 'Now, we bring the same medical-grade glass jars and vacuum-sealed tradition from our kitchen to your table.',
      'image': 'assets/images/gondh_laddu_edible_gum_laddu.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Cinematic Background Layer (Parallax)
          PageView.builder(
            controller: _pageController,
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              double offset = (_currentPage - index);
              return Stack(
                fit: StackFit.expand,
                children: [
                  Transform.translate(
                    offset: Offset(offset * 200, 0),
                    child: Transform.scale(
                      scale: 1.2 + (offset.abs() * 0.2),
                      child: Image.asset(
                        chapters[index]['image']!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.8),
                          Colors.black,
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 2. Animated Content Overlay
          IgnorePointer(
            child: PageView.builder(
              controller: PageController(viewportFraction: 1.0),
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                if (index != _currentPage.floor() && index != _currentPage.ceil()) {
                  return const SizedBox.shrink();
                }
                
                final opacity = (1 - (_currentPage - index).abs()).clamp(0.0, 1.0);
                final slide = (_currentPage - index) * 100;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(0, slide * 0.5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chapters[index]['year']!,
                                style: GoogleFonts.philosopher(
                                  color: const Color(0xFFD4AF37),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 8,
                                ),
                              ).animate().shimmer(duration: 2.seconds),
                              const SizedBox(height: 20),
                              Text(
                                chapters[index]['title']!,
                                style: GoogleFonts.philosopher(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(height: 2, width: 40, color: const Color(0xFFD4AF37)),
                              const SizedBox(height: 25),
                              Text(
                                chapters[index]['sub']!.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                chapters[index]['desc']!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14,
                                  height: 1.8,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
          ),

          // 3. Navigation Controls & Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  Row(
                    children: List.generate(chapters.length, (index) {
                      bool isSelected = _currentPage.round() == index;
                      return AnimatedContainer(
                        duration: 300.ms,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 4,
                        width: isSelected ? 30 : 8,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFD4AF37) : Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          // 4. Scroll Indicator
          Positioned(
            bottom: 40,
            left: 0, right: 0,
            child: Column(
              children: [
                const Text(
                  'SWIPE TO DISCOVER',
                  style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 4),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 40, width: 2,
                  color: Colors.white10,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      height: 15, width: 2,
                      color: const Color(0xFFD4AF37),
                    ).animate(onPlay: (c) => c.repeat())
                     .moveY(begin: 0, end: 25, duration: 1.5.seconds, curve: Curves.easeInOut),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
