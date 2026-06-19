import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'kitchen_story_page.dart';
import 'product_detail_page.dart';
import 'product_listing_page.dart';
import 'models.dart';
import 'cart_manager.dart';
import 'wishlist_manager.dart';
import 'wishlist_page.dart';
import 'main.dart';
import 'search_page.dart';
import 'navigation_util.dart';
import 'product_repository.dart';
import 'app_config_repository.dart';
import 'journey_components.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<Product> allProducts = ProductRepository.allProducts;
  bool _isLoading = true;
  
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  final PageController _adPageController = PageController();
  int _currentPage = 0;
  int _currentAdPage = 0;
  bool _showBackToTop = false;
  String _currentAddress = "Detecting location...";
  
  // Voice Search
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  Timer? _carouselTimer;
  Timer? _adCarouselTimer;
  Timer? _countdownTimer;
  StreamSubscription? _bannersSub;
  StreamSubscription? _couponsSub;
  StreamSubscription? _productsSub;
  StreamSubscription? _storiesSub;
  StreamSubscription? _bentoSub;
  StreamSubscription? _dealsSub;
  StreamSubscription? _packagingSub;
  StreamSubscription? _categoriesSub;
  StreamSubscription? _deliverySub;
  StreamSubscription? _pairingsSub;
  StreamSubscription? _heritageSub;
  StreamSubscription? _trendingSub;
  StreamSubscription? _configSub;

  List<Map<String, String>> banners = [];
  List<Map<String, String>> adBanners = [];
  List<Map<String, dynamic>> activeCoupons = [];
  List<Map<String, dynamic>> stories = [];
  Map<String, dynamic> bentoConfig = {};
  Map<String, dynamic> dealsConfig = {};
  List<Map<String, String>> packagingList = [];
  List<Map<String, dynamic>> categoryList = [];
  List<Map<String, String>> pairingList = [];
  Map<String, String> heritageBanner = {};
  List<String> trendingKeywords = [];
  int inventoryThreshold = 10;

  @override
  void initState() {
    super.initState();
    _startConfigListeners();
    _determinePosition();
    
    _scrollController.addListener(() {
      if (_scrollController.offset > 400 && !_showBackToTop) {
        setState(() => _showBackToTop = true);
      } else if (_scrollController.offset <= 400 && _showBackToTop) {
        setState(() => _showBackToTop = false);
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    });
    
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_pageController.hasClients && banners.isNotEmpty) {
        _currentPage = (_currentPage + 1) % banners.length;
        _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 800), curve: Curves.easeInOutCubic);
      }
    });
    
    _adCarouselTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_adPageController.hasClients && adBanners.isNotEmpty) {
        _currentAdPage = (_currentAdPage + 1) % adBanners.length;
        _adPageController.animateToPage(_currentAdPage, duration: const Duration(milliseconds: 900), curve: Curves.easeInOutCubic);
      }
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _currentAddress = "Location disabled");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _currentAddress = "Permission denied");
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() => _currentAddress = "${place.subLocality}, ${place.locality}");
      }
    } catch (e) {
      setState(() => _currentAddress = "Select Location");
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) {
          if (val.finalResult) {
            setState(() => _isListening = false);
            AppNavigator.push(context, SearchPage(initialQuery: val.recognizedWords));
          }
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _startConfigListeners() {
    _bannersSub = AppConfigRepository().getBannersStream().listen((data) {
      if (mounted) {
        setState(() {
          banners = data['main'] ?? [];
          adBanners = data['ad'] ?? [];
        });
      }
    });

    _couponsSub = AppConfigRepository().getCouponsStream().listen((data) {
      if (mounted) setState(() => activeCoupons = data);
    });

    _storiesSub = AppConfigRepository().getStoriesStream().listen((data) {
      if (mounted) setState(() => stories = data);
    });

    _bentoSub = AppConfigRepository().getBentoConfigStream().listen((data) {
      if (mounted) setState(() => bentoConfig = data);
    });

    _dealsSub = AppConfigRepository().getDealsStream().listen((data) {
      if (mounted) setState(() => dealsConfig = data);
    });

    _packagingSub = AppConfigRepository().getPackagingStream().listen((data) {
      if (mounted) setState(() => packagingList = data);
    });

    _categoriesSub = AppConfigRepository().getCategoriesStream().listen((data) {
      if (mounted) setState(() => categoryList = data);
    });

    _deliverySub = AppConfigRepository().getDeliveryConfigStream().listen((data) {
      CartManager().setDeliveryConfig(
        (data['base_fee'] ?? 40.0).toDouble(),
        (data['free_threshold'] ?? 500.0).toDouble(),
        (data['packing_fee'] ?? 0.0).toDouble(),
        (data['gst_percentage'] ?? 0.0).toDouble(),
      );
    });

    _pairingsSub = AppConfigRepository().getPairingsStream().listen((data) {
      if (mounted) setState(() => pairingList = data);
    });

    _heritageSub = AppConfigRepository().getHeritageBannerStream().listen((data) {
      if (mounted) setState(() => heritageBanner = data);
    });

    _trendingSub = AppConfigRepository().getTrendingSearchesStream().listen((data) {
      if (mounted) setState(() => trendingKeywords = data);
    });

    _configSub = AppConfigRepository().getAppStateStream().listen((data) {
      if (mounted) {
        setState(() {
          inventoryThreshold = (data['inventory_threshold'] ?? 10).toInt();
        });
      }
    });

    _productsSub = ProductRepository().getProductsStream().listen((data) {
      if (mounted) {
        setState(() {
          allProducts = data;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _adCarouselTimer?.cancel();
    _countdownTimer?.cancel();
    _bannersSub?.cancel();
    _couponsSub?.cancel();
    _productsSub?.cancel();
    _storiesSub?.cancel();
    _bentoSub?.cancel();
    _dealsSub?.cancel();
    _packagingSub?.cancel();
    _categoriesSub?.cancel();
    _deliverySub?.cancel();
    _pairingsSub?.cancel();
    _heritageSub?.cancel();
    _trendingSub?.cancel();
    _configSub?.cancel();
    _pageController.dispose();
    _adPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF8E8),
        body: _buildShimmerLoading(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildStickyHeader(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTrendingChips(),
                if (ProductRepository.recentlyViewed.isNotEmpty) _buildRecentlyViewedSection(),
                if (adBanners.isNotEmpty) _buildAdBanner(),
                _buildStoriesSection(),
                _buildBentoSection(),
                const SizedBox(height: 30),
                if (banners.isNotEmpty) _buildCarouselBanners(),
                _buildCategoryScroll(),
                _buildPerfectPairings(),
                _buildSection('Most Loved Pickles', 'Pickles'),
                if (activeCoupons.isNotEmpty) _buildActiveCoupons(),
                _buildDealsOfTheDay(),
                _buildSection('Traditional Snacks', 'Snacks'),
                _buildNewArrivalsRow(),
                _buildHeritageStory(),
                _buildSection('Fresh Ground Spices', 'Spices'),
                _buildMakingProcessSection(),
                _buildPackagingGallery(),
                _buildTestimonials(),
                const SizedBox(height: 40),
                _buildNexliflyFooter(),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _showBackToTop ? FloatingActionButton(
        onPressed: () => _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
        backgroundColor: const Color(0xFF18453B),
        mini: true,
        child: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
      ).animate().scale().fadeIn() : null,
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            backgroundColor: Colors.white,
            flexibleSpace: Container(color: Colors.white),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 180, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (index) => CircleAvatar(radius: 35, backgroundColor: Colors.white)),
                  ),
                  const SizedBox(height: 30),
                  Container(height: 30, width: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5))),
                  const SizedBox(height: 15),
                  Row(
                    children: List.generate(2, (index) => Expanded(child: Container(height: 250, margin: EdgeInsets.only(right: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingChips() {
    if (trendingKeywords.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: trendingKeywords.map((s) => Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ActionChip(
              label: Text(s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF18453B))),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              side: BorderSide(color: const Color(0xFF18453B).withOpacity(0.1)),
              onPressed: () => AppNavigator.push(context, SearchPage(initialQuery: s)),
            ),
          )).toList(),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildRecentlyViewedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 15),
          child: Text('Picked up where you left', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF18453B))),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: ProductRepository.recentlyViewed.length,
            itemBuilder: (context, index) {
              final product = ProductRepository.recentlyViewed[index];
              return GestureDetector(
                onTap: () => AppNavigator.push(context, ProductDetailPage(product: product, allProducts: allProducts)),
                child: Container(
                  width: 250,
                  margin: const EdgeInsets.only(right: 15),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFF18453B).withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(product.image, width: 80, height: 80, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, overflow: TextOverflow.ellipsis)),
                            Text(product.category, style: const TextStyle(fontSize: 10, color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                            Text(product.defaultPrice, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF18453B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn();
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

  Widget _buildStickyHeader() {
    return SliverAppBar(
      expandedHeight: 200,
      toolbarHeight: 70,
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
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? (user?.phoneNumber != null ? 'Member' : 'HEMANTH SILLA');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _determinePosition(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Color(0xFFD4AF37), size: 14),
                      const SizedBox(width: 4),
                      Text(_currentAddress, style: const TextStyle(color: Color(0xFF18453B), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF18453B), size: 14),
                    ],
                  ),
                  Text(displayName.toUpperCase(), style: GoogleFonts.philosopher(fontWeight: FontWeight.w900, fontSize: 18, color: const Color(0xFF18453B), letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeaderIconButton(
                icon: Icons.favorite_border_rounded, 
                onTap: () => AppNavigator.push(context, const WishlistPage())
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                icon: Icons.person_outline_rounded, 
                onTap: () {
                  HapticFeedback.lightImpact();
                  // TODO: Navigate to Profile
                }
              ),
              const SizedBox(width: 8),
              const GlobalCartBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(
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
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              HapticFeedback.heavyImpact();
              _listen();
            },
            child: Container(
              height: 56, width: 56,
              decoration: BoxDecoration(
                color: _isListening ? Colors.red : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Icon(
                _isListening ? Icons.mic_rounded : Icons.mic_none_rounded, 
                color: _isListening ? Colors.white : const Color(0xFFD4AF37), 
                size: 24
              ).animate(target: _isListening ? 1 : 0).scale(begin: const Offset(1,1), end: const Offset(1.2, 1.2)).shimmer(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdBanner() {
    return Column(
      children: [
        SizedBox(
          height: 320,
          child: PageView.builder(
            controller: _adPageController,
            onPageChanged: (int page) => setState(() => _currentAdPage = page),
            itemCount: adBanners.length,
            itemBuilder: (context, index) {
              final ad = adBanners[index];
              return _buildAddBannerItem(
                title: ad['title'] ?? '',
                sub: ad['sub'] ?? '',
                img: ad['img'] ?? '',
                tag: ad['tag'] ?? 'FEATURED',
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

  Widget _buildAddBannerItem({required String title, required String sub, required String img, String? tag}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 300, // Fixed height to prevent Infinity overflow
      decoration: BoxDecoration(
        color: const Color(0xFF18453B),
        borderRadius: BorderRadius.circular(25),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          children: [
            Positioned.fill(child: _buildBannerImage(img)),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFF18453B).withOpacity(0.95),
                      const Color(0xFF18453B).withOpacity(0.6),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 0.8],
                  ),
                ),
              ),
            ),
            // Use a non-positioned child to give the Stack (and thus the Spacer) a size
            Padding(
              padding: const EdgeInsets.all(25),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (tag != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                            ),
                            child: Text(
                              tag.toUpperCase(),
                              style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                            ),
                          ),
                        const Spacer(flex: 2),
                        Text(
                          title,
                          style: GoogleFonts.philosopher(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          sub,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
                            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('SHOP NOW', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselBanners() {
    return Column(
      children: [
        SizedBox(
          height: 320,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) => setState(() => _currentPage = page),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final b = banners[index];
              return _buildAddBannerItem(
                title: b['title'] ?? '',
                sub: b['sub'] ?? '',
                img: b['img'] ?? '',
                tag: b['tag'],
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

  Widget _buildBannerImage(String path) {
    if (path.isEmpty) {
      return Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.image, color: Colors.grey)));
    }
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey)));
    }
    return Image.asset(path, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey)));
  }

  Widget _buildPairingImage(String path) {
    if (path.isEmpty) {
      return Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.image, color: Colors.grey)));
    }
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey)));
    }
    return Image.asset(path, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey)));
  }

  Widget _buildActiveCoupons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ROYAL PRIVILEGES', style: TextStyle(color: const Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 3)),
              const SizedBox(height: 4),
              Text('Unlock Exclusive Tastes', style: GoogleFonts.philosopher(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF18453B))),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: activeCoupons.length,
            itemBuilder: (context, index) {
              final c = activeCoupons[index];
              final String code = c['code']?.toString() ?? '';
              final String title = c['title']?.toString() ?? '';
              final String sub = c['sub']?.toString() ?? '';

              return Container(
                width: 300,
                height: 180,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Stack(
                  children: [
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            const Color(0xFFFFF8E8),
                            Colors.white.withOpacity(0.9),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF18453B).withOpacity(0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2), width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0),
                                      Colors.white.withOpacity(0.4),
                                      Colors.white.withOpacity(0),
                                    ],
                                    stops: const [0.3, 0.5, 0.7],
                                  ),
                                ),
                              ).animate(onPlay: (c) => c.repeat())
                               .shimmer(duration: 3.seconds, color: Colors.white.withOpacity(0.5)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(25),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF18453B).withOpacity(0.05),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 16),
                                      ),
                                      Text(
                                        'OFFER VALID',
                                        style: TextStyle(color: Colors.grey.shade400, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    title,
                                    style: GoogleFonts.philosopher(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF18453B),
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    sub.toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFFD4AF37),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.heavyImpact();
                                      Clipboard.setData(ClipboardData(text: code));
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text('Royal code "$code" revealed and copied!'),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: const Color(0xFF18453B),
                                        margin: const EdgeInsets.all(20),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      ));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF18453B),
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(color: const Color(0xFF184537).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            code,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(width: 1, height: 12, color: Colors.white24),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'REVEAL',
                                            style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: -10, top: 40,
                      child: Opacity(
                        opacity: 0.05,
                        child: Icon(Icons.verified_user_rounded, size: 120, color: const Color(0xFF184537)),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (index * 150).ms).slideX(begin: 0.2, end: 0, curve: Curves.easeOutQuart);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStoriesSection() {
    if (stories.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 110,
      margin: const EdgeInsets.only(top: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          return _StoryItem(
            label: story['label'] ?? '',
            icon: _getIconData(story['icon'] ?? 'help_outline'),
            onTap: () {
              HapticFeedback.mediumImpact();
              _handleStoryTap(story['tag'] ?? '');
            },
          ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.5, end: 0);
        },
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'inventory_2': return Icons.inventory_2_rounded;
      case 'auto_stories': return Icons.auto_stories_rounded;
      case 'pan_tool': return Icons.pan_tool_rounded;
      case 'verified_user': return Icons.verified_user_rounded;
      case 'card_giftcard': return Icons.card_giftcard_rounded;
      case 'auto_awesome': return Icons.auto_awesome;
      case 'restaurant_menu_rounded': return Icons.restaurant_menu_rounded;
      case 'bakery_dining': return Icons.bakery_dining_rounded;
      case 'lunch_dining': return Icons.lunch_dining_rounded;
      case 'set_meal': return Icons.set_meal_rounded;
      case 'breakfast_dining': return Icons.breakfast_dining_rounded;
      default: return Icons.help_outline_rounded;
    }
  }

  void _handleStoryTap(String tag) {
    switch (tag) {
      case 'ORIGIN':
        AppNavigator.push(
          context,
          LuxuryStoryPage(
            appBarTitle: 'HERITAGE 1982',
            title: 'THE ANCESTRAL ROOTS',
            desc: 'Born in the coastal heart of Andhra, our recipes are silent witnesses to four decades of flavor evolution. We don\'t just make pickles; we preserve time.',
            img: 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg',
            tag: 'OUR ORIGIN',
          ),
        );
        break;
      case 'PACKAGING':
        AppNavigator.push(
          context,
          LuxuryStoryPage(
            appBarTitle: 'ROYAL VESSELS',
            title: 'LEAD-FREE PURITY',
            desc: 'Every batch is housed in medical-grade glass jars. Vacuum-sealed to ensure that the aroma of stone-ground spices reaches you exactly as it left our kitchen.',
            img: 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
            tag: 'PREMIUM CARE',
          ),
        );
        break;
      case 'HANDMADE':
        AppNavigator.push(
          context,
          LuxuryStoryPage(
            appBarTitle: 'ARTISAN SOUL',
            title: 'ZERO MACHINES',
            desc: 'Hand-sorted chillies, sun-dried ingredients, and traditional stone-pounding. Slow preparation ensures zero heat-friction, keeping natural oils intact.',
            img: 'assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg',
            tag: 'HANDCRAFTED',
          ),
        );
        break;
      case 'PURITY':
        AppNavigator.push(
          context,
          LuxuryStoryPage(
            appBarTitle: 'ZERO COMPROMISE',
            title: 'BIO-PRESERVED',
            desc: 'We use zero chemical preservatives. Our pickles are naturally preserved using cold-pressed oils and sun-dried sea salt, just as nature intended.',
            img: 'assets/images/gondh_laddu_edible_gum_laddu.jpg',
            tag: '100% NATURAL',
          ),
        );
        break;
      case 'GIFTS':
        AppNavigator.push(context, const ProductListingPage(category: 'Sweets'));
        break;
    }
  }

  Widget _buildBentoSection() {
    final bestSellerName = bentoConfig['best_seller_product'] ?? 'Bellam Avakaya';
    final bestSeller = allProducts.firstWhere((p) => p.name == bestSellerName, orElse: () => allProducts[0]);
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(bentoConfig['section_title'] ?? "Today's Selection", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF18453B))),
          const SizedBox(height: 15),
          SizedBox(
            height: 280,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _BentoCard(
                    title: bentoConfig['card1_label'] ?? 'Best Seller',
                    sub: bestSeller.name,
                    img: bestSeller.image,
                    color: const Color(0xFF18453B),
                    onTap: () => AppNavigator.push(context, ProductDetailPage(product: bestSeller, allProducts: allProducts)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _BentoCard(
                          title: bentoConfig['card2_label'] ?? 'Royal',
                          sub: bentoConfig['card2_sub'] ?? 'Spices',
                          icon: _getIconData(bentoConfig['card2_icon'] ?? 'auto_awesome'),
                          color: const Color(0xFFD4AF37),
                          isDarkText: true,
                          onTap: () => AppNavigator.push(context, const ProductListingPage(category: 'Spices')),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _BentoCard(
                          title: bentoConfig['card3_label'] ?? 'Crunchy',
                          sub: bentoConfig['card3_sub'] ?? 'Snacks',
                          icon: _getIconData(bentoConfig['card3_icon'] ?? 'restaurant_menu_rounded'),
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

  Widget _buildCategoryScroll() {
    if (categoryList.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Royal Collections', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF18453B))),
              Text(
                '${categoryList.length} CATEGORIES',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFD4AF37), letterSpacing: 1),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 150, // Increased height for tagline
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: categoryList.length,
            itemBuilder: (context, index) {
              final cat = categoryList[index];
              final label = cat['label'] ?? '';
              // Count products in this category
              final count = allProducts.where((p) => p.category == label).length;
              
              return _CategoryItem(
                label: label,
                img: cat['img'] ?? '',
                tagline: cat['tagline'] ?? '',
                badge: cat['badge'] ?? '',
                productCount: count,
                onTap: () => AppNavigator.push(context, ProductListingPage(category: label)),
              ).animate().scale(delay: (index * 50).ms, curve: Curves.easeOutBack);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPerfectPairings() {
    List<Map<String, String>> pairings = pairingList;
    
    if (pairings.isEmpty) {
      pairings = [
        {
          'title': 'THE COASTAL CLASSIC',
          'pairing': 'Rice + Ghee + Avakaya',
          'desc': 'Hot steaming rice melts the ghee, perfectly balancing the tangy jaggery mango.',
          'product_name': 'Bellam Avakaya',
          'image_url': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg'
        },
        {
          'title': 'THE BREAKFAST RITUAL',
          'pairing': 'Pesarattu + Allam Pickle',
          'desc': 'Sharp ginger and garlic notes provide the perfect contrast to earthy moong dal.',
          'product_name': 'Allam Velluli Pickle',
          'image_url': 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg'
        },
        {
          'title': 'CRUNCHY TEA TIME',
          'pairing': 'Chakinalu + Usiri Pickle',
          'desc': 'The citrusy amla tartness cuts through the savory sesame crunch of Chakinalu.',
          'product_name': 'Usiri Pickle',
          'image_url': 'assets/images/usiri_pickle_amlagooseberry_pickle.jpg'
        }
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
          child: Row(
            children: [
              Container(width: 4, height: 24, decoration: BoxDecoration(color: const Color(0xFFD4AF37), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CURATED COMBOS', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2)),
                  Text('The Art of Pairing', style: GoogleFonts.philosopher(fontSize: 26, fontWeight: FontWeight.w900, color: const Color(0xFF18453B))),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.9),
            itemCount: pairings.length,
            itemBuilder: (context, index) {
              final p = pairings[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 220,
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 20, 140, 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(35),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF2D1B12).withOpacity(0.06), blurRadius: 30, offset: const Offset(0, 15)),
                          ],
                          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(p['pairing'] ?? '', style: GoogleFonts.philosopher(color: const Color(0xFF18453B), fontSize: 18, fontWeight: FontWeight.w900, height: 1.2)),
                            const SizedBox(height: 8),
                            Text(p['desc'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 10, height: 1.6, fontWeight: FontWeight.w500), maxLines: 3),
                            const SizedBox(height: 15),
                            GestureDetector(
                              onTap: () {
                                final product = allProducts.firstWhere((prod) => prod.name == p['product_name'], orElse: () => allProducts[0]);
                                AppNavigator.push(context, ProductDetailPage(product: product, allProducts: allProducts));
                              },
                              child: Row(
                                children: [
                                  const Text('SEE DETAILS', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_rounded, color: Color(0xFFD4AF37), size: 12),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10, top: 0,
                      child: Container(
                        height: 180, width: 130,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(10, 10)),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: _buildPairingImage(p['image_url'] ?? ''),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -5, end: 5, duration: 3.seconds, curve: Curves.easeInOut),
                    ),
                    Positioned(
                      left: 20, top: 25,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18453B),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(p['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (index * 200).ms).slideX(begin: 0.2, end: 0, curve: Curves.easeOutQuart);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String category) {
    final products = allProducts.where((p) => p.category == category).toList();
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        _SectionTitle(title: title, onSeeAll: () => AppNavigator.push(context, ProductListingPage(category: category))),
        SizedBox(height: 360, child: ListView.builder(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: products.length, itemBuilder: (context, index) => _PremiumProductCard(product: products[index], allProducts: allProducts, threshold: inventoryThreshold).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.2, end: 0))),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDealsOfTheDay() {
    List<Product> dealProducts = [];
    final List<dynamic>? productNames = dealsConfig['product_names'];
    
    if (productNames != null && productNames.isNotEmpty) {
      dealProducts = allProducts.where((p) => productNames.contains(p.name)).toList();
    }
    
    if (dealProducts.length < 3) {
      for (var p in allProducts) {
        if (dealProducts.length >= 3) break;
        if (!dealProducts.contains(p)) {
          dealProducts.add(p);
        }
      }
    }

    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF8E8),
      child: Column(
        children: [
          CustomPaint(
            size: const Size(double.infinity, 25),
            painter: _ScallopPainter(isTop: true),
          ),
          Container(
            color: const Color(0xFFF9E9CF),
            padding: const EdgeInsets.only(top: 15, bottom: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Text(
                                  'DEAL OF THE DAY',
                                  style: GoogleFonts.bangers(
                                    fontSize: 34,
                                    letterSpacing: 2,
                                    foreground: Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 4
                                      ..color = const Color(0xFF8B4513),
                                  ),
                                ),
                                Text(
                                  'DEAL OF THE DAY',
                                  style: GoogleFonts.bangers(
                                    fontSize: 34,
                                    letterSpacing: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Craving-worthy deals, for today only',
                              style: GoogleFonts.philosopher(
                                color: const Color(0xFF18453B),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Image.asset(
                        'assets/images/gondh_laddu_edible_gum_laddu.jpg',
                        height: 80, width: 100, fit: BoxFit.contain,
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -5, end: 5, duration: 2.seconds),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 340,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: dealProducts.length,
                    itemBuilder: (context, index) {
                      return _DealCard(product: dealProducts[index], allProducts: allProducts, threshold: inventoryThreshold);
                    },
                  ),
                ),
              ],
            ),
          ),
          CustomPaint(
            size: const Size(double.infinity, 25),
            painter: _ScallopPainter(isTop: false),
          ),
        ],
      ),
    );
  }

  Widget _buildNewArrivalsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.fromLTRB(20, 40, 20, 15), child: Text('New Arrivals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF18453B)))),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: allProducts.length > 6 ? 6 : allProducts.length,
            itemBuilder: (context, index) {
              final product = allProducts[index];
              return GestureDetector(
                onTap: () => AppNavigator.push(context, ProductDetailPage(product: product, allProducts: allProducts)),
                child: Container(width: 120, margin: const EdgeInsets.only(right: 15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(height: 80, width: 80, child: ClipRRect(borderRadius: BorderRadius.circular(10), child: _buildProductImage(product.image))), const SizedBox(height: 12), Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(product.name, maxLines: 1, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis))), Text(product.defaultPrice, style: const TextStyle(fontSize: 13, color: Color(0xFF18453B), fontWeight: FontWeight.w900))])),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeritageStory() {
    final String title = heritageBanner['title'] ?? 'OUR KITCHEN\nSTORY';
    final String desc = heritageBanner['description'] ?? 'Handmade with love since 1982. Experience the ancestral legacy of Coastal Andhra in every jar.';
    final String img = heritageBanner['image_url'] ?? 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg';
    final String btnText = heritageBanner['button_text'] ?? 'EXPLORE OUR JOURNEY';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      height: 480,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        image: DecorationImage(
          image: _getBannerImageProvider(img),
          fit: BoxFit.cover,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.8),
                    const Color(0xFF18453B),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 40)
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 3.seconds),
                  const SizedBox(height: 25),
                  Text(
                    title, 
                    style: GoogleFonts.philosopher(
                      fontWeight: FontWeight.w900, 
                      fontSize: 42, 
                      color: Colors.white, 
                      height: 1,
                      letterSpacing: 2
                    )
                  ),
                  const SizedBox(height: 15),
                  Container(height: 2, width: 60, color: const Color(0xFFD4AF37)),
                  const SizedBox(height: 20),
                  Text(
                    desc, 
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7), 
                      height: 1.6, 
                      fontSize: 14,
                      fontWeight: FontWeight.w500
                    )
                  ),
                  const SizedBox(height: 35),
                  ElevatedButton(
                    onPressed: () => AppNavigator.push(context, const KitchenStoryPage()), 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: const Color(0xFF18453B),
                      minimumSize: const Size(double.infinity, 64),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: Text(
                      btnText, 
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)
                    )
                  ),
                ],
              ),
            ),
            Positioned(
              top: -100, right: -100,
              child: Container(
                height: 300, width: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1,1), end: const Offset(1.5, 1.5), duration: 4.seconds, curve: Curves.easeInOut),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider _getBannerImageProvider(String path) {
    if (path.startsWith('http')) return NetworkImage(path);
    return AssetImage(path);
  }

  Widget _buildMakingProcessSection() {
    final steps = [{'title': 'Sun Drying', 'desc': 'Ingredients dried under peak coastal sun.', 'icon': Icons.wb_sunny_rounded}, {'title': 'Stone Grinding', 'desc': 'Spices ground in traditional stone mortars.', 'icon': Icons.hardware}, {'title': 'Secret Ratios', 'desc': 'Ancestral recipes passed down since 1982.', 'icon': Icons.auto_awesome}];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.fromLTRB(20, 50, 20, 15), child: Text('The Art of Pickle Making', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF18453B)))),
        SizedBox(height: 160, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 15), itemCount: steps.length, itemBuilder: (context, index) => Container(width: 160, margin: const EdgeInsets.only(right: 15), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), border: Border.all(color: const Color(0xFF18453B).withOpacity(0.05))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(steps[index]['icon'] as IconData, color: const Color(0xFFD4AF37), size: 24), const Spacer(), Text(steps[index]['title'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF18453B))), const SizedBox(height: 5), Text(steps[index]['desc'] as String, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, height: 1.4))])))),
      ],
    );
  }

  Widget _buildTestimonials() {
    List<Review> mixedReviews = [];
    for (var p in allProducts) {
      mixedReviews.addAll(p.reviews);
    }
    mixedReviews.shuffle();

    if (mixedReviews.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TESTIMONIALS', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 3)),
              const SizedBox(height: 4),
              Text('What Royalty Says', style: GoogleFonts.philosopher(fontSize: 26, fontWeight: FontWeight.w900, color: const Color(0xFF18453B))),
            ],
          ),
        ),
        SizedBox(
          height: 320, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal, 
            padding: const EdgeInsets.symmetric(horizontal: 10), 
            itemCount: mixedReviews.length > 10 ? 10 : mixedReviews.length, 
            itemBuilder: (context, index) => RoyalReviewCard(review: mixedReviews[index], index: index)
          )
        ),
      ],
    );
  }

  Widget _buildPackagingGallery() {
    if (packagingList.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.fromLTRB(20, 50, 20, 15), child: Text('Royal Packaging', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF18453B)))),
        SizedBox(
          height: 220, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal, 
            padding: const EdgeInsets.symmetric(horizontal: 15), 
            itemCount: packagingList.length, 
            itemBuilder: (context, index) {
              final item = packagingList[index];
              return Container(
                width: 180, 
                margin: const EdgeInsets.only(right: 15), 
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(25), 
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))]
                ), 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)), 
                        child: _buildBannerImage(item['img'] ?? '')
                      )
                    ), 
                    Padding(
                      padding: const EdgeInsets.all(15), 
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        children: [
                          Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF18453B))), 
                          const SizedBox(height: 4), 
                          Text(item['desc'] ?? '', style: TextStyle(fontSize: 10, color: Colors.grey.shade600))
                        ]
                      )
                    )
                  ]
                )
              );
            }
          )
        ),
      ],
    );
  }

  Widget _buildProductImage(String path) {
    if (path.isEmpty) {
      return Container(color: Colors.grey.shade50, child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)));
    }
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)));
    }
    return Image.asset(path, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)));
  }
}

class LuxuryStoryPage extends StatelessWidget {
  final String appBarTitle;
  final String title;
  final String desc;
  final String img;
  final String tag;

  const LuxuryStoryPage({
    super.key,
    required this.appBarTitle,
    required this.title,
    required this.desc,
    required this.img,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9E9CF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18453B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          appBarTitle,
          style: GoogleFonts.bangers(color: Colors.white, letterSpacing: 2, fontSize: 24),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Center(
              child: PhotoCard(
                imagePath: img,
                angle: -0.05,
                hasPin: true,
                label: tag,
                icons: const [
                  FloatingIcon(icon: Icons.auto_awesome, top: -20, right: -10, color: Color(0xFFD4AF37)),
                  FloatingIcon(icon: Icons.spa_outlined, bottom: 20, left: -30, color: Colors.green),
                ],
              ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),
            ),
            const SizedBox(height: 60),
            Stack(
              alignment: Alignment.center,
              children: [
                const RedBanner(text: ''), // Spacer banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: RedBanner(text: title),
                ).animate().slideX(begin: 1, end: 0, delay: 400.ms),
              ],
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Text(
                desc,
                textAlign: TextAlign.center,
                style: GoogleFonts.philosopher(
                  fontSize: 20,
                  color: const Color(0xFF18453B),
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
            ),
            const SizedBox(height: 60),
            Container(
              height: 2, width: 100,
              color: const Color(0xFFD4AF37).withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.verified_user_rounded, color: Color(0xFF18453B), size: 40),
            const SizedBox(height: 100),
          ],
        ),
      ),
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
          height: 36, width: 36,
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))]),
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
                Container(height: 64, width: 64, padding: const EdgeInsets.all(3), decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFE5C76B)], begin: Alignment.topLeft)), child: Container(decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(icon, color: const Color(0xFF18453B), size: 24))),
                Positioned(top: 0, right: 0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white, width: 2)), child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold))).animate(onPlay: (c) => c.repeat(reverse: true)).fadeOut())
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(width: 70, child: Text(label, textAlign: TextAlign.center, maxLines: 1, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2D1B12), overflow: TextOverflow.ellipsis))),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem extends StatefulWidget {
  final String label;
  final String img;
  final String tagline;
  final String badge;
  final int productCount;
  final VoidCallback onTap;
  const _CategoryItem({
    required this.label, 
    required this.img, 
    this.tagline = '',
    this.badge = '',
    this.productCount = 0,
    required this.onTap
  });

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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 84, width: 84, 
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF18453B).withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
                      ],
                    ), 
                    child: Padding(
                      padding: const EdgeInsets.all(4), 
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40), 
                        child: _buildImage(widget.img),
                      )
                    )
                  ),
                  if (widget.badge.isNotEmpty)
                    Positioned(
                      top: -2, right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.badge == 'HOT' ? Colors.red : const Color(0xFFD4AF37),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                        ),
                        child: Text(
                          widget.badge,
                          style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
                    ),
                  Positioned(
                    bottom: -5,
                    right: 0,
                    left: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18453B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.productCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.label, 
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF18453B)),
              ),
              if (widget.tagline.isNotEmpty)
                Text(
                  widget.tagline,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.isEmpty) {
      return Container(color: Colors.grey.shade50, child: const Center(child: Icon(Icons.category_outlined, color: Colors.grey)));
    }
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.category_outlined, color: Colors.grey));
    }
    return Image.asset(path, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.category_outlined, color: Colors.grey));
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
          Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF18453B))))),
          const SizedBox(width: 15),
          GestureDetector(onTap: onSeeAll, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.15), borderRadius: BorderRadius.circular(15)), child: const Row(children: [Text('View All', style: TextStyle(color: Color(0xFF18453B), fontWeight: FontWeight.w900, fontSize: 11)), SizedBox(width: 4), Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF18453B))]))),
        ],
      ),
    );
  }
}

class _PremiumProductCard extends StatefulWidget {
  final Product product;
  final List<Product> allProducts;
  final int threshold;
  const _PremiumProductCard({required this.product, required this.allProducts, this.threshold = 10});

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
        AppNavigator.push(context, ProductDetailPage(product: widget.product, allProducts: widget.allProducts));
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 180,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))]),
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
                          child: _buildProductImage(widget.product.image),
                        ),
                      ),
                    ),
                    if (widget.product.isBestSeller)
                      Positioned(
                        top: 12, left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFE5C76B)]), borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)]),
                          child: const Text('BEST SELLER', style: TextStyle(color: Color(0xFF18453B), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ),
                      ),
                    if (widget.product.stockCount > 0 && widget.product.stockCount <= widget.threshold)
                      Positioned(
                        bottom: 12, left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                          ),
                          child: Text(
                            'ONLY ${widget.product.stockCount} LEFT!',
                            style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
                    Positioned(
                      top: 12, right: 12,
                      child: ListenableBuilder(
                        listenable: WishlistManager(),
                        builder: (context, _) {
                          final isFav = WishlistManager().isFavorite(widget.product);
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              WishlistManager().toggleFavorite(widget.product);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)]),
                              child: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFav ? Colors.red : Colors.grey, size: 16),
                            ),
                          );
                        }
                      ),
                    ),
                    if (widget.product.isOutOfStock)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('OUT OF STOCK', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                            ),
                          ),
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
                    Row(children: List.generate(5, (idx) => Icon(idx < widget.product.rating.floor() ? Icons.star_rounded : Icons.star_outline_rounded, size: 12, color: const Color(0xFFD4AF37)))),
                    const SizedBox(height: 8),
                    Container(height: 34, padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _selectedWeight, isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down, size: 14), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87), items: widget.product.weightPriceMap.keys.map((String v) => DropdownMenuItem<String>(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => _selectedWeight = v!)))),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(widget.product.getPriceForWeight(_selectedWeight), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF18453B))))),
                        const SizedBox(width: 4),
                        ListenableBuilder(
                          listenable: CartManager(),
                          builder: (context, _) {
                            int qty = CartManager().getProductQuantity(widget.product.name, _selectedWeight);
                            bool isOut = widget.product.isOutOfStock;
                            return GestureDetector(
                              onTap: isOut ? null : () {
                                HapticFeedback.mediumImpact();
                                CartManager().addToCart(widget.product, weight: _selectedWeight);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: isOut 
                                    ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500])
                                    : const LinearGradient(colors: [Color(0xFF18453B), Color(0xFF276357)]),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(isOut ? Icons.block_rounded : Icons.add_rounded, color: Colors.white, size: 16),
                                    if (qty > 0 && !isOut) ...[
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

  const _BentoCard({required this.title, required this.sub, this.img, this.icon, this.iconSize = 32, required this.color, this.isDarkText = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color, 
          borderRadius: BorderRadius.circular(25), 
          image: img != null ? DecorationImage(image: _getBentoImage(img!), fit: BoxFit.cover, opacity: 0.2) : null
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon!, color: isDarkText ? const Color(0xFF18453B) : Colors.white, size: iconSize), const SizedBox(height: 6)],
            FittedBox(fit: BoxFit.scaleDown, child: Text(title.toUpperCase(), style: TextStyle(color: isDarkText ? const Color(0xFF18453B).withOpacity(0.6) : Colors.white60, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2))),
            const SizedBox(height: 2),
            FittedBox(fit: BoxFit.scaleDown, child: Text(sub, style: TextStyle(color: isDarkText ? const Color(0xFF18453B) : Colors.white, fontWeight: FontWeight.w900, fontSize: 15))),
          ],
        ),
      ),
    );
  }

  ImageProvider _getBentoImage(String path) {
    if (path.startsWith('http')) return NetworkImage(path);
    return AssetImage(path);
  }
}

class RoyalReviewCard extends StatelessWidget {
  final Review review;
  final int index;
  const RoyalReviewCard({super.key, required this.review, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(50),
                bottomLeft: Radius.circular(50),
                topLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF18453B).withOpacity(0.06),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                )
              ],
              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(5, (i) => Icon(
                        Icons.star_rounded, 
                        size: 14, 
                        color: i < review.rating ? const Color(0xFFD4AF37) : Colors.grey.shade100
                      )),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18453B).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('VERIFIED', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: const Color(0xFF18453B), letterSpacing: 1)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Text(
                    review.comment, 
                    style: GoogleFonts.poppins(
                      fontSize: 14, 
                      fontStyle: FontStyle.italic, 
                      color: const Color(0xFF2D1B12), 
                      height: 1.7, 
                      fontWeight: FontWeight.w400
                    ), 
                    maxLines: 4, 
                    overflow: TextOverflow.ellipsis
                  )
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Color(0xFF18453B), Color(0xFF276357)]),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        review.userName.isEmpty ? '?' : review.userName[0].toUpperCase(),
                        style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.userName.toUpperCase(), 
                          style: GoogleFonts.philosopher(fontWeight: FontWeight.w900, fontSize: 12, color: const Color(0xFF18453B), letterSpacing: 0.5)
                        ),
                        const Text(
                          'HONORED GUEST',
                          style: TextStyle(fontSize: 7, color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: -8, top: -8,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle),
              child: const Icon(Icons.format_quote_rounded, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 150).ms).scale(begin: const Offset(0.95, 0.95));
  }
}

class _ScallopPainter extends CustomPainter {
  final bool isTop;
  _ScallopPainter({required this.isTop});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFF9E9CF);
    final paintWhite = Paint()..color = const Color(0xFFFFF8E8);
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    double radius = 12.0;
    double diameter = radius * 2;
    double spacing = 4.0;
    double step = diameter + spacing;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawCircle(
        Offset(x + radius, isTop ? 0 : size.height),
        radius,
        paintWhite,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DealCard extends StatelessWidget {
  final Product product;
  final List<Product> allProducts;
  final int threshold;
  const _DealCard({required this.product, required this.allProducts, this.threshold = 10});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 15, bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                child: _buildImage(product.image, 160, width: double.infinity),
              ),
              Positioned(
                bottom: 8,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.green, width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.circle, color: Colors.green, size: 8),
                ),
              ),
              if (product.stockCount > 0 && product.stockCount <= threshold)
                Positioned(
                  top: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                    ),
                    child: Text(
                      'ONLY ${product.stockCount} LEFT!',
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
              Positioned(
                top: 12, right: 12,
                child: ListenableBuilder(
                  listenable: WishlistManager(),
                  builder: (context, _) {
                    final isFav = WishlistManager().isFavorite(product);
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        WishlistManager().toggleFavorite(product);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)]),
                        child: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFav ? Colors.red : Colors.grey, size: 18),
                      ),
                    );
                  }
                ),
              ),
              Positioned(
                bottom: -18,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    CartManager().addToCart(product);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B4513).withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFF8B4513), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ADD',
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF8B4513),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.add, color: Color(0xFF8B4513), size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 24, 15, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.philosopher(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF18453B),
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.description,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Text(
                  product.defaultPrice,
                  style: GoogleFonts.philosopher(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF18453B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String path, double height, {double? width}) {
    if (path.isEmpty) {
      return Container(color: Colors.grey.shade50, child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)));
    }
    if (path.startsWith('http')) {
      return Image.network(path, height: height, width: width, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)));
    }
    return Image.asset(path, height: height, width: width, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)));
  }
}

Widget _buildProductImage(String path) {
  if (path.isEmpty) {
    return Container(color: Colors.grey.shade50, child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)));
  }
  if (path.startsWith('http')) {
    return Image.network(path, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)));
  }
  return Image.asset(path, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)));
}
