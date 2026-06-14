import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'kitchen_story_page.dart';
import 'product_detail_page.dart';
import 'product_listing_page.dart';
import 'models.dart';
import 'cart_manager.dart';
import 'main.dart';
import 'search_page.dart';
import 'navigation_util.dart';
import 'product_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final List<Product> allProducts = ProductRepository.allProducts;
  final PageController _pageController = PageController();
  final PageController _adPageController = PageController();
  int _currentPage = 0;
  int _currentAdPage = 0;
  Timer? _carouselTimer;
  Timer? _adCarouselTimer;

  final List<Map<String, String>> banners = [
    {'title': 'LUXURY HANDMADE', 'sub': 'The Purest Flavors of Tradition', 'img': 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg'},
    {'title': 'FESTIVAL OF GOLD', 'sub': 'Flat ₹100 Off on All Sweets', 'img': 'assets/images/gondh_laddu_edible_gum_laddu.jpg'},
    {'title': 'ROYAL COMBOS', 'sub': 'Curated Packs for Your Family', 'img': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg'},
  ];

  final List<Map<String, String>> adBanners = [
    {
      'tag': 'CHEF\'S SPECIAL',
      'title': 'Ancient Garlic Fusion',
      'sub': 'Limited Batch • Aged 120 Days',
      'img': 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg'
    },
    {
      'tag': 'NEW LAUNCH',
      'title': 'Velvet Jaggery Mango',
      'sub': 'Sweetness of tradition refined.',
      'img': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg'
    },
    {
      'tag': 'LIMITED EDITION',
      'title': 'Heritage Spice Blend',
      'sub': 'Hand-pounded stone ground aroma.',
      'img': 'assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg'
    },
    {
      'tag': 'VINTAGE RESERVE',
      'title': 'Sun-Kissed Lemon',
      'sub': 'Citrus Zest from Konaseema Groves.',
      'img': 'assets/images/gondh_laddu_edible_gum_laddu.jpg'
    },
    {
      'tag': 'ROYAL TRIBUTE',
      'title': 'The Red Emperor',
      'sub': 'Fiery Guntur Chilli • Royal Heat.',
      'img': 'assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg'
    },
  ];

  @override
  void initState() {
    super.initState();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_pageController.hasClients) {
        if (_currentPage < banners.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
    
    _adCarouselTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_adPageController.hasClients) {
        if (_currentAdPage < adBanners.length - 1) {
          _currentAdPage++;
        } else {
          _currentAdPage = 0;
        }
        _adPageController.animateToPage(
          _currentAdPage,
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _adCarouselTimer?.cancel();
    _pageController.dispose();
    _adPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildStickyHeader(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAdBanner(),
                _buildStoriesSection(),
                _buildBentoSection(),
                const SizedBox(height: 30),
                _buildCarouselBanners(),
                _buildCategoryScroll(),
                _buildQuickDiscovery(),
                _buildSection('Most Loved Pickles', 'Pickles'),
                _buildActiveCoupons(),
                _buildDealsOfTheDay(),
                _buildSection('Traditional Snacks', 'Snacks'),
                _buildNewArrivalsRow(),
                _buildStaticBanner(
                  title: 'ROYAL COMBOS', 
                  sub: 'Curated Packs for Your Family', 
                  img: 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg'
                ),
                _buildHeritageStory(),
                _buildSection('Fresh Ground Spices', 'Spices'),
                _buildMakingProcessSection(),
                _buildPackagingGallery(),
                _buildTestimonials(),
                _buildStaticBanner(
                  title: 'AUTHENTIC RECIPES', 
                  sub: 'Crafted with Love Since 1982', 
                  img: 'assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg'
                ),
                const SizedBox(height: 40),
                _buildNexliflyFooter(),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNexliflyFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(height: 1, width: 25, color: const Color(0xFFD4AF37).withOpacity(0.3)),
            const SizedBox(width: 12),
            const Text(
              'POWERED BY',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF18453B), letterSpacing: 4),
            ),
            const SizedBox(width: 12),
            Container(height: 1, width: 25, color: const Color(0xFFD4AF37).withOpacity(0.3)),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'NEXLIFLY',
          style: GoogleFonts.philosopher(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF18453B).withOpacity(0.8),
            letterSpacing: 8,
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildWhatsAppFAB() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connecting to Royal Support...')));
        },
        child: Container(
          height: 60, width: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF25D366),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: const Color(0xFF25D366).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
            ],
          ),
          child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 28),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: -10, duration: 2.seconds, curve: Curves.easeInOut);
  }

  Widget _buildStickyHeader() {
    return SliverAppBar(
      expandedHeight: 200,
      toolbarHeight: 70, // Increased to match 70px content and prevent 14px overflow
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFFFFF8E8),
      surfaceTintColor: Colors.transparent,
      title: _buildHeaderTopRow(),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: _buildAnimatedSearchBar(),
      ),
    );
  }

  Widget _buildHeaderTopRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Added safety
              children: [
                Text('HEMANTH SILLA', style: GoogleFonts.philosopher(fontWeight: FontWeight.w900, fontSize: 20, color: const Color(0xFF18453B), letterSpacing: 0.5)),
                const Text('What would you like to order today?', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.2)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeaderIconButton(icon: Icons.notifications_none_rounded, onTap: () => HapticFeedback.lightImpact()),
              const SizedBox(width: 8),
              GlobalCartBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          AppNavigator.push(context, const SearchPage());
        },
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: Color(0xFF18453B), size: 22),
              const SizedBox(width: 12),
              Text('Search royal flavors...', style: TextStyle(fontSize: 14, color: const Color(0xFF2D1B12).withOpacity(0.4), fontWeight: FontWeight.w500)),
              const Spacer(),
              const Icon(Icons.mic_none_rounded, color: Color(0xFFD4AF37), size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdBanner() {
    return Column(
      children: [
        SizedBox(
          height: 320, // Increased for safe clearance
          child: PageView.builder(
            controller: _adPageController,
            onPageChanged: (int page) => setState(() => _currentAdPage = page),
            itemCount: adBanners.length,
            itemBuilder: (context, index) {
              final ad = adBanners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF18453B),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF18453B).withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
                            ),
                            child: Text(
                              ad['tag']!,
                              style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                          ),
                          const Spacer(flex: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              ad['title']!,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Philosopher'),
                            ),
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              ad['sub']!,
                              style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Spacer(flex: 3),
                          ElevatedButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                              foregroundColor: const Color(0xFF18453B),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('SHOP NOW', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 100, width: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Image.asset(
                          ad['img']!,
                          height: 110,
                          width: 110,
                          fit: BoxFit.contain,
                        ).animate(onPlay: (c) => c.repeat(reverse: true))
                         .moveY(begin: -5, end: 5, duration: 2.seconds, curve: Curves.easeInOut),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(adBanners.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              width: _currentAdPage == index ? 16 : 4,
              decoration: BoxDecoration(
                color: _currentAdPage == index ? const Color(0xFFD4AF37) : const Color(0xFFD4AF37).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
      ],
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildStoriesSection() {
    final stories = [
      {'label': 'Packaging', 'icon': Icons.inventory_2_rounded, 'tag': 'PACKAGING'},
      {'label': 'The Origin', 'icon': Icons.auto_stories_rounded, 'tag': 'ORIGIN'},
      {'label': 'Hand-Made', 'icon': Icons.pan_tool_rounded, 'tag': 'HANDMADE'},
      {'label': 'Purity', 'icon': Icons.verified_user_rounded, 'tag': 'PURITY'},
      {'label': 'Gift Boxes', 'icon': Icons.card_giftcard_rounded, 'tag': 'GIFTS'},
    ];
    return Container(
      height: 110,
      margin: const EdgeInsets.only(top: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: stories.length,
        itemBuilder: (context, index) => _StoryItem(
          label: stories[index]['label'] as String,
          icon: stories[index]['icon'] as IconData,
          onTap: () {
            HapticFeedback.mediumImpact();
            _handleStoryTap(stories[index]['tag'] as String);
          },
        ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.5, end: 0),
      ),
    );
  }

  void _handleStoryTap(String tag) {
    switch (tag) {
      case 'ORIGIN':
        _showLuxuryStory(
          title: 'HERITAGE 1982',
          subtitle: 'The Ancestral Roots',
          desc: 'Born in the coastal heart of Andhra, our recipes are silent witnesses to four decades of flavor evolution. We don\'t just make pickles; we preserve time.',
          img: 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg'
        );
        break;
      case 'PACKAGING':
        _showLuxuryStory(
          title: 'ROYAL VESSELS',
          subtitle: 'Lead-Free Purity',
          desc: 'Every batch is housed in medical-grade glass jars. Vacuum-sealed to ensure that the aroma of stone-ground spices reaches you exactly as it left our kitchen.',
          img: 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg'
        );
        break;
      case 'HANDMADE':
        _showLuxuryStory(
          title: 'ARTISAN SOUL',
          subtitle: 'Zero Machines.',
          desc: 'Hand-sorted chillies, sun-dried ingredients, and traditional stone-pounding. Slow preparation ensures zero heat-friction, keeping natural oils intact.',
          img: 'assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg'
        );
        break;
      case 'PURITY':
        _showLuxuryStory(
          title: 'ZERO COMPROMISE',
          subtitle: 'Bio-Preserved',
          desc: 'We use zero chemical preservatives. Our pickles are naturally preserved using cold-pressed oils and sun-dried sea salt, just as nature intended.',
          img: 'assets/images/gondh_laddu_edible_gum_laddu.jpg'
        );
        break;
      case 'GIFTS':
        AppNavigator.push(context, const ProductListingPage(category: 'Sweets'));
        break;
    }
  }

  void _showLuxuryStory({required String title, required String subtitle, required String desc, required String img}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Story',
      transitionDuration: 600.ms,
      pageBuilder: (context, anim1, anim2) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Background Image with Slow Zoom
            Positioned.fill(
              child: Image.asset(img, fit: BoxFit.cover)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.2, 1.2), duration: 10.seconds, curve: Curves.linear),
            ),
            
            // Luxury Cinematic Gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.9),
                    ],
                    stops: const [0.0, 0.3, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modern Progress Bar
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.5), blurRadius: 10)],
                                ),
                              ).animate().scaleX(begin: 0, end: 1, duration: 6.seconds, curve: Curves.linear),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(title, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 10)),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(subtitle, style: GoogleFonts.philosopher(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                        ),
                      ],
                    ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.2, end: 0),

                    const Spacer(),

                    // Glassmorphic Content Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            desc,
                            style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.7, fontWeight: FontWeight.w400, letterSpacing: 0.3),
                          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                              foregroundColor: const Color(0xFF18453B),
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              elevation: 0,
                            ),
                            child: const Text('EXPERIENCE THE TRADITION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12)),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Today\'s Selection', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF18453B))),
          const SizedBox(height: 15),
          SizedBox(
            height: 280, // Increased for cross-device safety
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _BentoCard(
                    title: 'Best Seller',
                    sub: 'Bellam Avakaya',
                    img: 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
                    color: const Color(0xFF18453B),
                    onTap: () => AppNavigator.push(context, ProductDetailPage(product: allProducts[0])),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _BentoCard(
                          title: 'Royal',
                          sub: 'Spices',
                          icon: Icons.auto_awesome,
                          iconSize: 24,
                          color: const Color(0xFFD4AF37),
                          isDarkText: true,
                          onTap: () => AppNavigator.push(context, const ProductListingPage(category: 'Spices')),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _BentoCard(
                          title: 'Crunchy',
                          sub: 'Snacks',
                          icon: Icons.restaurant_menu_rounded,
                          iconSize: 24,
                          color: const Color(0xFF2D1B12),
                          onTap: () => AppNavigator.push(context, const ProductListingPage(category: 'Snacks')),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildCarouselBanners() {
    return Column(
      children: [
        SizedBox(
          height: 240,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) => setState(() => _currentPage = page),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              return _buildStaticBanner(
                title: banners[index]['title']!,
                sub: banners[index]['sub']!,
                img: banners[index]['img']!,
                isHero: true,
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _currentPage == index ? 24 : 6,
              decoration: BoxDecoration(
                color: _currentPage == index ? const Color(0xFF18453B) : const Color(0xFF18453B).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStaticBanner({required String title, required String sub, required String img, bool isHero = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: isHero ? 200 : 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: const Color(0xFF18453B).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Image.asset(img, fit: BoxFit.cover, width: double.infinity, height: double.infinity).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1), duration: 10.seconds),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF18453B).withOpacity(0.9), Colors.transparent], 
                  begin: Alignment.bottomLeft
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 1.5)),
                  Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCoupons() {
    final List<Map<String, String>> coupons = [
      {'code': 'FIRST30', 'title': '30% OFF', 'sub': 'On your first order', 'min': '₹500', 'color': '0xFF18453B'},
      {'code': 'PICKLE100', 'title': '₹100 OFF', 'sub': 'Flat discount on pickles', 'min': '₹999', 'color': '0xFFD4AF37'},
      {'code': 'FESTIVE20', 'title': '20% OFF', 'sub': 'Festive season special', 'min': '₹1500', 'color': '0xFF2D1B12'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 15),
          child: Text('Active Coupons', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF18453B))),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              final c = coupons[index];
              final Color bgColor = Color(int.parse(c['color']!));
              final bool isGold = c['color'] == '0xFFD4AF37';

              return Container(
                width: 300,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(color: bgColor.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            c['title']!, 
                            style: GoogleFonts.philosopher(
                              fontSize: 24, 
                              fontWeight: FontWeight.w900, 
                              color: isGold ? const Color(0xFF18453B) : const Color(0xFFD4AF37)
                            ),
                          ),
                          Text(
                            c['sub']!, 
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isGold ? Colors.black54 : Colors.white60, 
                              fontSize: 11, 
                              fontWeight: FontWeight.bold
                            )
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        Clipboard.setData(ClipboardData(text: c['code']!));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Code ${c['code']} copied to royal clipboard!'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF18453B),
                        ));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isGold ? const Color(0xFF18453B) : const Color(0xFFD4AF37),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              c['code']!, 
                              style: TextStyle(
                                color: isGold ? const Color(0xFFD4AF37) : const Color(0xFF18453B), 
                                fontWeight: FontWeight.w900, 
                                fontSize: 12, 
                                letterSpacing: 1
                              )
                            ),
                            Text('COPY', style: TextStyle(color: isGold ? Colors.white60 : Colors.black45, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.2, end: 0);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryScroll() {
    final categories = [
      {'label': 'Pickles', 'img': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg'},
      {'label': 'Snacks', 'img': 'assets/images/chakinalu_traditional_sankranti_spiral_snacks.jpg'},
      {'label': 'Spices', 'img': 'assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg'},
      {'label': 'Sweets', 'img': 'assets/images/gondh_laddu_edible_gum_laddu.jpg'},
      {'label': 'Combos', 'img': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 40, 20, 20),
          child: Text('Royal Collections', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF18453B))),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return _CategoryItem(
                label: categories[index]['label']!, 
                img: categories[index]['img']!,
                onTap: () {
                  HapticFeedback.selectionClick();
                  AppNavigator.push(context, ProductListingPage(category: categories[index]['label']!));
                },
              ).animate().scale(delay: (index * 50).ms, curve: Curves.easeOutBack);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickDiscovery() {
    final filters = [
      {'label': 'Mildly Spicy', 'color': Colors.green.shade700},
      {'label': 'Extra Hot', 'color': Colors.red.shade900},
      {'label': 'Sweet & Tangy', 'color': Colors.orange.shade800},
      {'label': 'Non-Veg Spec', 'color': Colors.brown.shade800},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 30, 20, 15),
          child: Text('Personalize Search', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF18453B))),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: filters.length,
            itemBuilder: (context, index) => Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: (filters[index]['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: (filters[index]['color'] as Color).withOpacity(0.3)),
              ),
              alignment: Alignment.center,
              child: Text(
                filters[index]['label'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: filters[index]['color'] as Color, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String category) {
    final products = allProducts.where((p) => p.category == category).toList();
    return Column(
      children: [
        _SectionTitle(title: title, onSeeAll: () => AppNavigator.push(context, ProductListingPage(category: category))),
        SizedBox(
          height: 360, // Slightly increased to prevent 1px rounding overflow
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _PremiumProductCard(product: products[index]).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.2, end: 0);
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDealsOfTheDay() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D1B12),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('DEALS OF THE DAY', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12)),
                    ),
                    SizedBox(height: 4),
                    Text('Ending in 04:23:12', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                child: const Text('SHOP ALL', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _DealItem(product: allProducts[2]),
              const SizedBox(width: 15),
              _DealItem(product: allProducts[4]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewArrivalsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 40, 20, 15),
          child: Text('New Arrivals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF18453B))),
        ),
        SizedBox(
          height: 180, // Increased for safety buffer
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: 4,
            itemBuilder: (context, index) {
              final product = allProducts[index + 10];
              return GestureDetector(
                onTap: () => AppNavigator.push(context, ProductDetailPage(product: product)),
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(product.image, width: 70, height: 70, fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(product.name, maxLines: 1, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis)),
                      ),
                      Text(product.defaultPrice, style: const TextStyle(fontSize: 13, color: Color(0xFF18453B), fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeritageStory() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF18453B).withOpacity(0.05)),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 32),
          const SizedBox(height: 20),
          const Text(
            'OUR KITCHEN STORY',
            style: TextStyle(fontFamily: 'Philosopher', fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF18453B), letterSpacing: 1),
          ),
          const SizedBox(height: 15),
          Text(
            'Since 1982, we have been crafting tradition in every jar. No preservatives, only sun-dried ingredients and love from coastal Andhra.',
            textAlign: TextAlign.center,
            style: TextStyle(color: const Color(0xFF2D1B12).withOpacity(0.6), height: 1.6, fontSize: 13),
          ),
          const SizedBox(height: 25),
          GestureDetector(
            onTap: () => AppNavigator.push(context, const KitchenStoryPage()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF18453B)),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text('READ OUR JOURNEY', style: TextStyle(color: Color(0xFF18453B), fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMakingProcessSection() {
    final steps = [
      {'title': 'Sun Drying', 'desc': 'Ingredients dried under peak coastal sun.', 'icon': Icons.wb_sunny_rounded},
      {'title': 'Stone Grinding', 'desc': 'Spices ground in traditional stone mortars.', 'icon': Icons.hardware},
      {'title': 'Secret Ratios', 'desc': 'Ancestral recipes passed down since 1982.', 'icon': Icons.auto_awesome},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 50, 20, 15),
          child: Text('The Art of Pickle Making', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF18453B))),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: steps.length,
            itemBuilder: (context, index) => Container(
              width: 160,
              margin: const EdgeInsets.only(right: 15),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFF18453B).withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(steps[index]['icon'] as IconData, color: const Color(0xFFD4AF37), size: 24),
                  const Spacer(),
                  Text(steps[index]['title'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF18453B))),
                  const SizedBox(height: 5),
                  Text(steps[index]['desc'] as String, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, height: 1.4)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestimonials() {
    return Column(
      children: [
        _SectionTitle(title: 'What Royalty Says', onSeeAll: () {}),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: 3,
            itemBuilder: (context, index) => _ReviewCard(review: ProductRepository.allProducts[0].reviews[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildPackagingGallery() {
    final packagings = [
      {'title': 'Glass Jars', 'desc': 'Premium leak-proof sealing', 'img': 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg'},
      {'title': 'Eco-Friendly', 'desc': 'Sustainable outer boxing', 'img': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg'},
      {'title': 'Gift Ready', 'desc': 'Royal golden finishing', 'img': 'assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 50, 20, 15),
          child: Text('Royal Packaging', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF18453B))),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: packagings.length,
            itemBuilder: (context, index) => Container(
              width: 180,
              margin: const EdgeInsets.only(right: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                      child: Image.asset(packagings[index]['img']!, fit: BoxFit.cover, width: double.infinity),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(packagings[index]['title']!, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF18453B))),
                        const SizedBox(height: 4),
                        Text(packagings[index]['desc']!, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Container(
          height: 36, width: 36, // Fixed height to prevent 14px overflow
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: Icon(icon, color: const Color(0xFF18453B), size: 18),
        ),
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _StoryItem({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 64, width: 64,
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFE5C76B)], begin: Alignment.topLeft),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(icon, color: const Color(0xFF18453B), size: 24),
                  ),
                ),
                Positioned(
                  top: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white, width: 2)),
                    child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold)),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeOut(),
                )
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 70,
              child: Text(label, textAlign: TextAlign.center, maxLines: 1, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2D1B12), overflow: TextOverflow.ellipsis)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DealItem extends StatelessWidget {
  final Product product;
  const _DealItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => AppNavigator.push(context, ProductDetailPage(product: product)),
        child: Container(
          height: 180,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Hero(
                    tag: 'deal_${product.name}',
                    child: Image.asset(product.image, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported_outlined, color: Colors.white24)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(product.name, maxLines: 1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, overflow: TextOverflow.ellipsis)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(product.defaultPrice, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 13)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text('₹${(product.getRawPriceForWeight(product.defaultWeight) * 1.3).toStringAsFixed(0)}', 
                      maxLines: 1,
                      style: const TextStyle(color: Colors.white30, decoration: TextDecoration.lineThrough, fontSize: 9, overflow: TextOverflow.ellipsis)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryItem extends StatefulWidget {
  final String label;
  final String img;
  final VoidCallback onTap;
  const _CategoryItem({required this.label, required this.img, required this.onTap});

  @override
  State<_CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<_CategoryItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              Container(
                height: 74, width: 74,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF18453B).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.asset(widget.img, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_not_supported_outlined))),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(widget.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF18453B))),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  const _SectionTitle({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF18453B))),
            ),
          ),
          const SizedBox(width: 15),
          GestureDetector(
            onTap: onSeeAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.15),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Row(
                children: [
                  Text('View All', style: TextStyle(color: Color(0xFF18453B), fontWeight: FontWeight.w900, fontSize: 11)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF18453B)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumProductCard extends StatefulWidget {
  final Product product;
  const _PremiumProductCard({required this.product});

  @override
  State<_PremiumProductCard> createState() => _PremiumProductCardState();
}

class _PremiumProductCardState extends State<_PremiumProductCard> {
  bool _isPressed = false;
  late String _selectedWeight;

  @override
  void initState() {
    super.initState();
    _selectedWeight = widget.product.defaultWeight;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        AppNavigator.push(context, ProductDetailPage(product: widget.product));
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 180,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.0,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                      child: Container(
                        color: Colors.white,
                        child: Hero(
                          tag: widget.product.name,
                          child: Image.asset(
                            widget.product.image, 
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)),
                          ),
                        ),
                      ),
                    ),
                    if (widget.product.isBestSeller)
                      Positioned(
                        top: 12, left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFE5C76B)]),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)],
                          ),
                          child: const Text('BEST SELLER', style: TextStyle(color: Color(0xFF18453B), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.product.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF2D1B12)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (idx) => Icon(
                        idx < widget.product.rating.floor() ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 12, color: const Color(0xFFD4AF37),
                      )),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedWeight,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 14),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                          items: widget.product.weightPriceMap.keys.map((String v) => DropdownMenuItem<String>(value: v, child: Text(v))).toList(),
                          onChanged: (v) => setState(() => _selectedWeight = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(widget.product.getPriceForWeight(_selectedWeight), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF18453B))),
                          ),
                        ),
                        const SizedBox(width: 4),
                        ListenableBuilder(
                          listenable: CartManager(),
                          builder: (context, _) {
                            int qty = CartManager().getProductQuantity(widget.product.name, _selectedWeight);
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                CartManager().addToCart(widget.product, weight: _selectedWeight);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF18453B), Color(0xFF276357)]),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                                    if (qty > 0) ...[
                                      const SizedBox(width: 4),
                                      Text('$qty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }
                        ),
                      ],
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
}

class _BentoCard extends StatelessWidget {
  final String title, sub;
  final String? img;
  final IconData? icon;
  final double iconSize;
  final Color color;
  final bool isDarkText;
  final VoidCallback onTap;

  const _BentoCard({
    required this.title, 
    required this.sub, 
    this.img, 
    this.icon, 
    this.iconSize = 32,
    required this.color, 
    this.isDarkText = false, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
          image: img != null ? DecorationImage(image: AssetImage(img!), fit: BoxFit.cover, opacity: 0.2) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon!, color: isDarkText ? const Color(0xFF18453B) : Colors.white, size: iconSize),
              const SizedBox(height: 6),
            ],
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title.toUpperCase(), 
                style: TextStyle(
                  color: isDarkText ? const Color(0xFF18453B).withOpacity(0.6) : Colors.white60, 
                  fontWeight: FontWeight.w900, 
                  fontSize: 10, 
                  letterSpacing: 2
                )
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                sub, 
                style: TextStyle(
                  color: isDarkText ? const Color(0xFF18453B) : Colors.white, 
                  fontWeight: FontWeight.w900, 
                  fontSize: 15
                )
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 18, color: i < review.rating ? const Color(0xFFD4AF37) : Colors.grey.shade200)),
          ),
          const SizedBox(height: 15),
          Expanded(child: Text(review.comment, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Color(0xFF2D1B12), height: 1.6, letterSpacing: 0.3), maxLines: 3, overflow: TextOverflow.ellipsis)),
          const SizedBox(height: 15),
          Text('- ${review.userName}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF18453B), letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
