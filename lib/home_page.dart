import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'product_manager.dart';
import 'product_repository.dart';
import 'app_config_repository.dart';
import 'journey_components.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool _isLoading = true;
  
  List<Product> get allProducts => ProductManager().products;

  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  final PageController _adPageController = PageController();
  int _currentPage = 0;
  int _currentAdPage = 0;
  int _selectedCategoryIndex = 0;
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
    ProductManager().addListener(_onProductUpdate);
    
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

  void _onProductUpdate() {
    if (mounted) setState(() {});
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
    ProductManager().removeListener(_onProductUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = ProductManager().products;
    final isGlobalLoading = ProductManager().isLoading;

    if (_isLoading && isGlobalLoading && allProducts.length <= 5) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF8E8),
        body: _buildShimmerLoading(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EC),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildStickyHeader(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildValuePropsRow(),
                _buildHeroBanner(),
                _buildPerfectPairings(),
                _buildSection('Most Loved Pickles', 'Pickles'),
                _buildTrustReassuranceBanner(),
                _buildActiveCoupons(),
                _buildRoyalCollectionsSection(),
                _buildBestSellersSection(),
                _buildPopularCategoriesSection(),
                _buildContinueShoppingSection(),
                _buildTodaysSpecialsGrid(),
                _buildNewArrivalsRow(),
                _buildSnacksSection(),
                _buildSection('Fresh Ground Spices', 'Spices'),
                _buildSweetsSection(),
                _buildSweetsQuoteBanner(),
                _buildHeritageStory(),
                _buildMakingProcessSection(),
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
                        child: _buildProductImage(product.image),
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
      expandedHeight: 145,
      toolbarHeight: 72,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFFF8F5EC),
      surfaceTintColor: Colors.transparent,
      title: _buildHeaderTopRow(),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(62),
        child: _buildAnimatedSearchBar(),
      ),
    );
  }

  Widget _buildHeaderTopRow() {
    final user = FirebaseAuth.instance.currentUser;

    String formattedName = "Hemanth";
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      final parts = user.displayName!.trim().split(' ');
      formattedName = parts.first[0].toUpperCase() + parts.first.substring(1).toLowerCase();
    } else if (user?.email != null && user!.email!.isNotEmpty) {
      final prefix = user.email!.split('@').first;
      formattedName = prefix[0].toUpperCase() + prefix.substring(1).toLowerCase();
    }

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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded, color: Color(0xFFD4AF37), size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _currentAddress.isNotEmpty ? _currentAddress : "HSR Layout, Bengaluru",
                          style: const TextStyle(
                            color: Color(0xFF1B1B1B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1B1B1B), size: 16),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'Good Afternoon 👋',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF6B7280),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    formattedName,
                    style: GoogleFonts.philosopher(
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                      color: const Color(0xFF0F4D3C),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Good food brings good mood!',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HeaderIconButton(
                    icon: Icons.favorite_border_rounded,
                    onTap: () => AppNavigator.push(context, const WishlistPage()),
                  ),
                  const SizedBox(width: 8),
                  _HeaderIconButton(
                    icon: Icons.person_outline_rounded,
                    onTap: () => MainScreen.of(context)?.setIndex(4),
                  ),
                  const SizedBox(width: 8),
                  const GlobalCartBadge(),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Taste Tradition Every Day',
                style: GoogleFonts.caveat(
                  color: const Color(0xFFD4AF37),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
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
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: Color(0xFF0F4D3C), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search royal flavors...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(height: 20, width: 1, color: Colors.grey.shade300),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  _listen();
                },
                child: Icon(
                  _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: _isListening ? Colors.red : const Color(0xFF0F4D3C),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = [
      {'label': 'Mango', 'emoji': '🥭'},
      {'label': 'Chicken', 'emoji': '🍗'},
      {'label': 'Spicy', 'emoji': '🌶️'},
      {'label': 'Snacks', 'emoji': '🍟'},
      {'label': 'Dry Fruits', 'emoji': '🥜'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = _selectedCategoryIndex == index;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedCategoryIndex = index);
                AppNavigator.push(context, ProductListingPage(category: cat['label']!));
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0F4D3C) : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: isSelected ? null : Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    if (!isSelected)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cat['emoji']!, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Text(
                      cat['label']!,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF1B1B1B),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0C3D2E), Color(0xFF135341)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0C3D2E).withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 16,
              right: 18,
              child: Text(
                'Pure\nTraditional\nHomemade',
                textAlign: TextAlign.right,
                style: GoogleFonts.caveat(
                  color: const Color(0xFFE5C76B),
                  fontSize: 14,
                  height: 1.1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'AUTHENTIC ANDHRA',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFD4AF37),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Handmade\nPickles',
                    style: GoogleFonts.philosopher(
                      color: const Color(0xFFFFF8E8),
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Traditional Taste Since 1982',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      AppNavigator.push(context, const ProductListingPage(category: 'Pickles'));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5C76B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Shop Now',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF0F4D3C),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, color: Color(0xFF0F4D3C), size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              width: 145,
              height: 135,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildProductImage('assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg'),
              ),
            ),
            Positioned(
              left: 22,
              bottom: 14,
              child: Row(
                children: List.generate(4, (i) => Container(
                  margin: const EdgeInsets.only(right: 5),
                  width: i == 0 ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == 0 ? const Color(0xFFE5C76B) : Colors.white30,
                    borderRadius: BorderRadius.circular(10),
                  ),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoyalCollectionsSection() {
    final collections = [
      {'title': 'Pickles', 'sub': '12+ varieties', 'img': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg', 'cat': 'Pickles'},
      {'title': 'Snacks', 'sub': '9+ varieties', 'img': 'assets/images/chakinalu_traditional_sankranti_spiral_snacks.jpg', 'cat': 'Snacks'},
      {'title': 'Spices', 'sub': '8+ varieties', 'img': 'assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg', 'cat': 'Spices'},
      {'title': 'Combos', 'sub': 'Special Packs', 'img': 'assets/images/gondh_laddu_edible_gum_laddu.jpg', 'cat': 'Sweets'},
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Royal Collections',
                style: GoogleFonts.philosopher(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1B1B1B),
                ),
              ),
              GestureDetector(
                onTap: () => MainScreen.of(context)?.setIndex(1),
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF0F4D3C),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF0F4D3C)),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 175,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: collections.length,
            itemBuilder: (context, index) {
              final item = collections[index];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  AppNavigator.push(context, ProductListingPage(category: item['cat']!));
                },
                child: Container(
                  width: 130,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: SizedBox(
                              height: 110,
                              width: double.infinity,
                              child: _buildProductImage(item['img']!),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF0F4D3C),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title']!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B1B1B)),
                            ),
                            Text(
                              item['sub']!,
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                            ),
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
    );
  }

  Widget _buildBestSellersSection() {
    final bestSellers = [
      {'name': 'Mango Pickle', 'weight': '500 g', 'price': '₹199', 'badge': 'Bestseller', 'badgeColor': const Color(0xFFE5C76B), 'img': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg'},
      {'name': 'Gongura Pickle', 'weight': '500 g', 'price': '₹219', 'badge': 'Spicy', 'badgeColor': Colors.red.shade600, 'img': 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg'},
      {'name': 'Garlic Pickle', 'weight': '500 g', 'price': '₹199', 'badge': 'Popular', 'badgeColor': const Color(0xFF0F4D3C), 'img': 'assets/images/usiri_pickle_amlagooseberry_pickle.jpg'},
      {'name': 'Mixed Pickle', 'weight': '500 g', 'price': '₹249', 'badge': 'New', 'badgeColor': const Color(0xFFD4AF37), 'img': 'assets/images/uppava_traditional_salted_pickle.jpg'},
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Best Sellers',
                style: GoogleFonts.philosopher(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1B1B1B),
                ),
              ),
              GestureDetector(
                onTap: () => MainScreen.of(context)?.setIndex(1),
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF0F4D3C),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF0F4D3C)),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 205,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: bestSellers.length,
            itemBuilder: (context, index) {
              final item = bestSellers[index];
              final String nameStr = item['name'] as String;
              final String imgStr = item['img'] as String;
              final matchingProduct = allProducts.firstWhere(
                (p) => p.name.contains(nameStr.split(' ').first),
                orElse: () => allProducts[index % allProducts.length],
              );

              return GestureDetector(
                onTap: () => AppNavigator.push(context, ProductDetailPage(product: matchingProduct, allProducts: allProducts)),
                child: Container(
                  width: 145,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: SizedBox(
                              height: 110,
                              width: double.infinity,
                              child: _buildProductImage(imgStr),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nameStr,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1B1B1B)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['weight'] as String,
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item['price'] as String,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1B1B1B)),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        CartManager().addToCart(matchingProduct);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F4D3C),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: item['badgeColor'] as Color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item['badge'] as String,
                            style: TextStyle(
                              color: (item['badge'] == 'Bestseller' || item['badge'] == 'New') ? const Color(0xFF2D1B12) : Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            WishlistManager().toggleFavorite(matchingProduct);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.favorite_border_rounded, size: 14, color: Colors.black54),
                          ),
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
    );
  }

  Widget _buildContinueShoppingSection() {
    final continueProducts = allProducts.take(2).toList();
    if (continueProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Continue Shopping',
                style: GoogleFonts.philosopher(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1B1B1B),
                ),
              ),
              GestureDetector(
                onTap: () => MainScreen.of(context)?.setIndex(1),
                child: Row(
                  children: [
                    Text(
                      'See All',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF0F4D3C),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF0F4D3C)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: continueProducts.map<Widget>((product) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: _buildProductImage(product.image),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1B1B1B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '500 g',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                product.defaultPrice,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F4D3C)),
                              ),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  CartManager().addToCart(product);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F4D3C),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Add',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPopularNearYouSection() {
    final popularProducts = allProducts.skip(2).take(5).toList();
    if (popularProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Popular Near You',
                style: GoogleFonts.philosopher(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1B1B1B),
                ),
              ),
              GestureDetector(
                onTap: () => MainScreen.of(context)?.setIndex(1),
                child: Row(
                  children: [
                    Text(
                      'See All',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF0F4D3C),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF0F4D3C)),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 190,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: popularProducts.length,
            itemBuilder: (context, index) {
              final product = popularProducts[index];
              return GestureDetector(
                onTap: () => AppNavigator.push(context, ProductDetailPage(product: product, allProducts: allProducts)),
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                            child: SizedBox(
                              height: 105,
                              width: double.infinity,
                              child: _buildProductImage(product.image),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1B1B1B)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '200 g',
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.defaultPrice,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F4D3C)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 8, right: 8,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            WishlistManager().toggleFavorite(product);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.favorite_border_rounded, size: 14, color: Colors.black54),
                          ),
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
    );
  }

  Widget _buildTodaysSpecialsGrid() {
    final specialProduct = allProducts.firstWhere(
      (p) => p.name.contains('Allam') || p.name.contains('Podi') || p.isBestSeller,
      orElse: () => allProducts[0],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "TODAY'S SPECIAL",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFD4AF37),
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 30, height: 1, color: const Color(0xFFD4AF37)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'A Taste Worth Grabbing Today',
                    style: GoogleFonts.philosopher(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1B1B1B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Handpicked just for today, because good food shouldn't wait.",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                'Same\nTradition\nMore Love ♡',
                textAlign: TextAlign.right,
                style: GoogleFonts.caveat(
                  color: const Color(0xFFD4AF37),
                  fontSize: 13,
                  height: 1.1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Main Deal Card Container
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              children: [
                // Top Dark Section
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: Color(0xFF231610),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      // Top Row: Badge + Heart Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.flash_on_rounded, color: Color(0xFFE5C76B), size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  "TODAY'S SPECIAL",
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFE5C76B),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ListenableBuilder(
                            listenable: WishlistManager(),
                            builder: (context, _) {
                              final isFav = WishlistManager().isFavorite(specialProduct);
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  WishlistManager().toggleFavorite(specialProduct);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    color: isFav ? Colors.red : Colors.grey,
                                    size: 16,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Content Row: Text Details on Left, Product Image on Right
                      Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  specialProduct.name,
                                  style: GoogleFonts.philosopher(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'A bold blend of ginger, garlic and traditional Andhra spices.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.white70,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Feature Circles Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildFeatureCircle(Icons.eco_outlined, '100%\nNatural'),
                                    _buildFeatureCircle(Icons.soup_kitchen_outlined, 'Homemade\nTaste'),
                                    _buildFeatureCircle(Icons.verified_outlined, 'No\nPreservatives'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 5,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                height: 140,
                                child: _buildProductImage(specialProduct.image),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Bottom Parchment Section (#FFF8E8)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF8E8),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      // Price Row
                      Row(
                        children: [
                          Text(
                            '₹350',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F4D3C),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₹400',
                            style: TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3D6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '12% OFF',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8B5E3C),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Lower Row: Countdown Timer & Add to Cart Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Countdown Timer Box
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF6B7280)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Offer ends in',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: const Color(0xFF6B7280),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _buildTimerBox('08', 'HRS'),
                                  const SizedBox(width: 6),
                                  _buildTimerBox('46', 'MINS'),
                                  const SizedBox(width: 6),
                                  _buildTimerBox('22', 'SECS'),
                                ],
                              ),
                            ],
                          ),

                          // Add to Cart Button
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              CartManager().addToCart(specialProduct);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F4D3C),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Add to Cart',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

        const SizedBox(height: 12),

        // Bottom Page Indicators (— • •)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFF0F4D3C),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCircle(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white30),
          ),
          child: Icon(icon, color: const Color(0xFFE5C76B), size: 14),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 8,
            height: 1.1,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerBox(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3D6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2D1B12),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 7, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
        ),
      ],
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
    String assetPath = path;
    if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/images/$path';
    }
    return Image.asset(assetPath, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey)));
  }

  Widget _buildPairingImage(String path) {
    if (path.isEmpty) {
      return Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.image, color: Colors.grey)));
    }
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey)));
    }
    String assetPath = path;
    if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/images/$path';
    }
    return Image.asset(assetPath, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey)));
  }

  Widget _buildActiveCoupons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'ROYAL PRIVILEGES',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFD4AF37),
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 30, height: 1, color: const Color(0xFFD4AF37)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Exclusive Offers for You',
                    style: GoogleFonts.philosopher(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1B1B1B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Special savings. Authentic flavors. Always.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Clipboard.setData(const ClipboardData(text: 'ROYAL10'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coupon ROYAL10 copied!')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0F4D3C),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF0F4D3C)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Main Hero Ticket Coupon Banner
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 195,
            decoration: BoxDecoration(
              color: const Color(0xFF0C3D2E),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0C3D2E).withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Row(
              children: [
                // Left Green Section
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WELCOME OFFER',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFD4AF37),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '10% OFF',
                              style: GoogleFonts.philosopher(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFE5C76B),
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ON YOUR FIRST ORDER',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('🍃 Authentic', style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
                            Text('  |  ', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 8)),
                            const Text('🛡️ Quality', style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
                            Text('  |  ', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 8)),
                            const Text('🚚 Fresh', style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Center Ticket Stamp Box
                Expanded(
                  flex: 4,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'USE CODE',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF6B7280),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            Clipboard.setData(const ClipboardData(text: 'ROYAL10'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Coupon ROYAL10 copied!')),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'ROYAL10',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0F4D3C),
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF0F4D3C)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'A SMALL SAVING\nFOR A BIGGER FEAST',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.caveat(
                            fontSize: 11,
                            color: const Color(0xFF8B5E3C),
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right Image & Wax Seal
                Expanded(
                  flex: 3,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
                        child: SizedBox(
                          height: 195,
                          width: double.infinity,
                          child: _buildProductImage('assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg'),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD4AF37),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_rounded, color: Color(0xFF0C3D2E), size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Sub-Offer Cards Row (3 Horizontal Pastel Cards)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Card 1: Free Shipping
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF3EA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFF0F4D3C), size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Free Shipping',
                              style: GoogleFonts.philosopher(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B1B1B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'On orders above ₹599',
                              style: TextStyle(fontSize: 8, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF0F4D3C)),
                    ],
                  ),
                ),
              ),

              // Card 2: Flat ₹100 OFF
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.monetization_on_rounded, color: Color(0xFF8B5E3C), size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Flat ₹100 OFF',
                              style: GoogleFonts.philosopher(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B1B1B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'On orders above ₹999',
                              style: TextStyle(fontSize: 8, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF8B5E3C)),
                    ],
                  ),
                ),
              ),

              // Card 3: Exclusive Combos
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE8E8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite_rounded, color: Colors.red, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Exclusive Combos',
                              style: GoogleFonts.philosopher(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B1B1B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Curated savings for you',
                              style: TextStyle(fontSize: 8, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.red),
                    ],
                  ),
                ),
              ),
            ],
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

  Widget _buildValuePropsRow() {
    final props = [
      {
        'title': 'Our Origin',
        'sub': 'From farms to your table',
        'icon': Icons.eco_rounded,
        'tag': 'ORIGIN',
      },
      {
        'title': 'Premium Packaging',
        'sub': 'Freshness sealed',
        'icon': Icons.inventory_2_rounded,
        'tag': 'PACKAGING',
      },
      {
        'title': 'Fast Delivery',
        'sub': 'Straight to your doorstep',
        'icon': Icons.local_shipping_rounded,
        'tag': 'DELIVERY',
      },
      {
        'title': 'Best Sellers',
        'sub': 'Customer favourites',
        'icon': Icons.star_rounded,
        'tag': 'BEST',
      },
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: props.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = props[index];
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (item['tag'] == 'BEST') {
                AppNavigator.push(context, const ProductListingPage(category: 'Pickles'));
              } else {
                _handleStoryTap(item['tag'] as String);
              }
            },
            child: Container(
              width: 125,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'] as IconData, color: const Color(0xFF0F4D3C), size: 24),
                  const SizedBox(height: 6),
                  Text(
                    item['title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1B1B1B)),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['sub'] as String,
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularCategoriesSection() {
    final categories = [
      {'name': 'Mango Pickles', 'img': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg', 'cat': 'Pickles'},
      {'name': 'Lemon Pickles', 'img': 'assets/images/usiri_pickle_amlagooseberry_pickle.jpg', 'cat': 'Pickles'},
      {'name': 'Spicy Pickles', 'img': 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg', 'cat': 'Pickles'},
      {'name': 'Dry Fruits', 'img': 'assets/images/dry_fruits_laddu_premium_dry_fruits_laddu.jpg', 'cat': 'Sweets'},
      {'name': 'Snacks', 'img': 'assets/images/chakinalu_traditional_sankranti_spiral_snacks.jpg', 'cat': 'Snacks'},
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Popular Categories',
                style: GoogleFonts.philosopher(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1B1B1B),
                ),
              ),
              GestureDetector(
                onTap: () => MainScreen.of(context)?.setIndex(1),
                child: Row(
                  children: [
                    Text(
                      'See All',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF0F4D3C),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF0F4D3C)),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 135,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  AppNavigator.push(context, ProductListingPage(category: cat['cat']!));
                },
                child: Container(
                  width: 105,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 65,
                          width: 80,
                          child: _buildProductImage(cat['img']!),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat['name']!,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1B1B1B)),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
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

  Widget _buildBentoSection() {
    final bestSellerName = bentoConfig['best_seller_product'] ?? 'Allam Velluli Karam Podi';
    final bestSeller = allProducts.firstWhere((p) => p.name.contains('Allam') || p.name == bestSellerName, orElse: () => allProducts[0]);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Selection',
                style: GoogleFonts.philosopher(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1B1B1B),
                ),
              ),
              GestureDetector(
                onTap: () => MainScreen.of(context)?.setIndex(1),
                child: Row(
                  children: [
                    Text(
                      'See All',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF0F4D3C),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF0F4D3C)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 290,
            child: Row(
              children: [
                // Left Card (Allam Velluli Karam Podi)
                Expanded(
                  flex: 6,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18453B),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF18453B).withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BEST SELLER',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFD4AF37),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              bestSeller.name,
                              style: GoogleFonts.philosopher(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.1,
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Authentic taste\nfrom our roots',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            height: 100,
                            width: double.infinity,
                            child: _buildProductImage(bestSeller.image),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => AppNavigator.push(context, ProductDetailPage(product: bestSeller, allProducts: allProducts)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5C76B),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Shop Now', style: TextStyle(color: Color(0xFF0F4D3C), fontWeight: FontWeight.bold, fontSize: 11)),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded, color: Color(0xFF0F4D3C), size: 12),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Right Column Cards
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      // Top Card (ROYAL Spices)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5C76B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ROYAL',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF0F4D3C),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  Text(
                                    'Spices',
                                    style: GoogleFonts.philosopher(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF0F4D3C),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () => AppNavigator.push(context, const ProductListingPage(category: 'Spices')),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF0F4D3C),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                                    ),
                                  ),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 45,
                                      height: 45,
                                      child: _buildProductImage('assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12, height: 12),

                      // Bottom Card (CRUNCHY Snacks)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D1B12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CRUNCHY',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFFD4AF37),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  Text(
                                    'Snacks',
                                    style: GoogleFonts.philosopher(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () => AppNavigator.push(context, const ProductListingPage(category: 'Snacks')),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFD4AF37),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF2D1B12), size: 14),
                                    ),
                                  ),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 45,
                                      height: 45,
                                      child: _buildProductImage('assets/images/bundhi_crispy_spiced_gram_flour_droplets.jpg'),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
              
              final count = allProducts.where((p) {
                final pCat = p.category.trim().toLowerCase();
                final targetCat = label.trim().toLowerCase();
                return pCat == targetCat || 
                       pCat == "${targetCat}s" || 
                       "${pCat}s" == targetCat;
              }).length;
              
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
    final subPairings = [
      {
        'title': 'Idli + Karam\nPodi + Ghee',
        'sub': 'Simple. Traditional.\nIrresistible.',
        'img': 'assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg',
        'badge': Icons.eco_rounded,
        'prod': 'Allam Velluli Karam Podi',
      },
      {
        'title': 'Dosa + Garlic\nChutney',
        'sub': 'A classic pairing\nfor every mood.',
        'img': 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg',
        'badge': Icons.restaurant,
        'prod': 'Allam Velluli Pickle',
      },
      {
        'title': 'Upma + Mango\nPickle',
        'sub': 'Everyday food.\nExtra special.',
        'img': 'assets/images/usiri_pickle_amlagooseberry_pickle.jpg',
        'badge': Icons.nature_rounded,
        'prod': 'Usiri Pickle',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5C76B),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CURATED COMBOS',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFD4AF37),
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'The Art of Pairing',
                        style: GoogleFonts.philosopher(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1B1B1B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Perfect combinations. Richer flavors.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => MainScreen.of(context)?.setIndex(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0F4D3C),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF0F4D3C)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Main Hero Pairing Card ("The Coastal Classic")
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 215,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0C3D2E), Color(0xFF135341)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0C3D2E).withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Stack(
              children: [
                // Top Right Cursive Tag
                Positioned(
                  top: 14,
                  right: 16,
                  child: Text(
                    'Simple Food\nExtraordinary\nHappiness',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.caveat(
                      color: const Color(0xFFE5C76B),
                      fontSize: 14,
                      height: 1.1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Card Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'THE COASTAL CLASSIC',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFD4AF37),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Rice + Ghee +\nAvakaya',
                        style: GoogleFonts.philosopher(
                          color: const Color(0xFFFFF8E8),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 170,
                        child: Text(
                          'A timeless combination that brings out the best of Andhra flavors.',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 11,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () {
                          final product = allProducts.firstWhere(
                            (p) => p.name.contains('Bellam') || p.name.contains('Avakaya'),
                            orElse: () => allProducts[0],
                          );
                          AppNavigator.push(context, ProductDetailPage(product: product, allProducts: allProducts));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5C76B),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'See Details',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF0F4D3C),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, color: Color(0xFF0F4D3C), size: 12),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Right Image
                Positioned(
                  right: 12,
                  bottom: 12,
                  width: 140,
                  height: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _buildProductImage('assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg'),
                  ),
                ),

                // Pagination Dots Bottom Left
                Positioned(
                  left: 20,
                  bottom: 12,
                  child: Row(
                    children: List.generate(3, (i) => Container(
                      margin: const EdgeInsets.only(right: 5),
                      width: i == 0 ? 14 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == 0 ? const Color(0xFFE5C76B) : Colors.white30,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    )),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Sub-Cards Horizontal Row (3 Pairing Cards)
        SizedBox(
          height: 215,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: subPairings.length,
            itemBuilder: (context, index) {
              final item = subPairings[index];
              final String prodName = item['prod'] as String;
              final matchingProduct = allProducts.firstWhere(
                (p) => p.name.contains(prodName.split(' ').first),
                orElse: () => allProducts[index % allProducts.length],
              );

              return GestureDetector(
                onTap: () => AppNavigator.push(context, ProductDetailPage(product: matchingProduct, allProducts: allProducts)),
                child: Container(
                  width: 155,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: SizedBox(
                              height: 110,
                              width: double.infinity,
                              child: _buildProductImage(item['img'] as String),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: Color(0xFF0F4D3C),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(item['badge'] as IconData, color: Colors.white, size: 12),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              style: GoogleFonts.philosopher(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: const Color(0xFF1B1B1B),
                                height: 1.1,
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item['sub'] as String,
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500, height: 1.2),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => AppNavigator.push(context, ProductDetailPage(product: matchingProduct, allProducts: allProducts)),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0F4D3C),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                              ),
                            ),
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
    );
  }

  Widget _buildSection(String title, String category) {
    final products = allProducts.where((p) {
      final pCat = p.category.trim().toLowerCase();
      final targetCat = category.trim().toLowerCase();
      // ULTRA ROBUST MATCHING
      return pCat == targetCat || 
             pCat == "${targetCat}s" || 
             "${pCat}s" == targetCat ||
             pCat.contains(targetCat) ||
             targetCat.contains(pCat);
    }).toList();

    if (products.isEmpty) {
      // DEBUG: If a category row is hidden, show why in the console
      debugPrint('DEBUG: Section "$title" (Target: "$category") is empty. All Categories in memory: ${allProducts.map((p) => p.category).toSet().toList()}');
      return const SizedBox.shrink();
    }
    
    String? sub;
    if (title == 'Most Loved Pickles') sub = 'Customer favorites, always!';
    if (title == 'Traditional Snacks') sub = 'Crispy heritage delights';
    if (title == 'Fresh Ground Spices') sub = 'Pure & aromatic blends';
    if (title == 'Authentic Sweets') sub = 'Ghee-soaked traditional memories';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: title, subtitle: sub, onSeeAll: () => AppNavigator.push(context, ProductListingPage(category: category))),
        SizedBox(
          height: 440, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal, 
            physics: const BouncingScrollPhysics(), 
            padding: const EdgeInsets.symmetric(horizontal: 12), 
            itemCount: products.length, 
            itemBuilder: (context, index) {
              final p = products[index];
              return _PremiumProductCard(
                product: p, 
                allProducts: allProducts, 
                threshold: inventoryThreshold
              ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.2, end: 0);
            }
          )
        ),
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
        // Section Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'NEW ARRIVALS',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFD4AF37),
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 30, height: 1, color: const Color(0xFFD4AF37)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Fresh Picks, Just for You',
                    style: GoogleFonts.philosopher(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1B1B1B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Discover our latest additions, crafted with tradition.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => AppNavigator.push(context, const ProductListingPage(category: 'Pickles')),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View All',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF0F4D3C),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF0F4D3C)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'New Flavors\nSame Tradition ♡',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.caveat(
                      color: const Color(0xFFD4AF37),
                      fontSize: 12,
                      height: 1.1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Horizontal List of Cards
        SizedBox(
          height: 310,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: allProducts.length > 6 ? 6 : allProducts.length,
            itemBuilder: (context, index) {
              final product = allProducts[index];
              return _NewArrivalCard(
                product: product,
                allProducts: allProducts,
                index: index,
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Bottom Carousel Indicators (— • •)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFF0F4D3C),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 6),
            Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
          ],
        ),

        const SizedBox(height: 20),
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
    if (path.isEmpty) return const AssetImage('assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg');
    if (path.startsWith('http')) return NetworkImage(path);
    String assetPath = path;
    if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/images/$path';
    }
    return AssetImage(assetPath);
  }

  Widget _buildMakingProcessSection() {
    final steps = [
      {
        'num': '01',
        'title': 'Sun Drying',
        'desc': 'Ingredients dried under peak coastal sun to lock in natural flavors.',
        'icon': Icons.wb_sunny_outlined,
        'img': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
      },
      {
        'num': '02',
        'title': 'Stone Grinding',
        'desc': 'Spices ground in traditional stone mortars for authentic taste and aroma.',
        'icon': Icons.soup_kitchen_outlined,
        'img': 'assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg',
      },
      {
        'num': '03',
        'title': 'Natural Fermentation',
        'desc': 'Blended and matured the traditional way for richer, deeper flavors.',
        'icon': Icons.inventory_2_outlined,
        'img': 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'OUR TRADITION',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFD4AF37),
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 30, height: 1, color: const Color(0xFFD4AF37)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'The Art of\nPickle Making',
                    style: GoogleFonts.philosopher(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1B1B1B),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Time-honored methods. Unmatched flavors.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Same\nTradition\nBigger\nHappiness ♡',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.caveat(
                      color: const Color(0xFFD4AF37),
                      fontSize: 12,
                      height: 1.1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                    ),
                    child: const Icon(Icons.verified_rounded, color: Color(0xFFD4AF37), size: 14),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Process Cards Horizontal List
        SizedBox(
          height: 310,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              return Container(
                width: 165,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Image Area
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          child: SizedBox(
                            height: 140,
                            width: double.infinity,
                            child: _buildProductImage(step['img'] as String),
                          ),
                        ),

                        // Top Left Step Number Badge (01, 02, 03)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F4D3C),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              step['num'] as String,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Card Content
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(step['icon'] as IconData, color: const Color(0xFF8B5E3C), size: 22),
                          const SizedBox(height: 6),
                          Text(
                            step['title'] as String,
                            style: GoogleFonts.philosopher(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: const Color(0xFF0F4D3C),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step['desc'] as String,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade600,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Carousel Indicators (— • • •) & Crafted with Care Tagline
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 40),
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F4D3C),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
                ],
              ),
              Text(
                'Crafted\nwith Care',
                textAlign: TextAlign.right,
                style: GoogleFonts.caveat(
                  color: const Color(0xFFD4AF37),
                  fontSize: 14,
                  height: 1.1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
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

  Widget _buildTrustReassuranceBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildReassuranceItem(Icons.eco_rounded, 'Farm Fresh\nIngredients'),
          Container(width: 1, height: 25, color: const Color(0xFFD4AF37).withOpacity(0.3)),
          _buildReassuranceItem(Icons.verified_rounded, 'Authentic\nAndhra Recipes'),
          Container(width: 1, height: 25, color: const Color(0xFFD4AF37).withOpacity(0.3)),
          _buildReassuranceItem(Icons.favorite_rounded, 'Loved by\nThousands'),
        ],
      ),
    );
  }

  Widget _buildReassuranceItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0F4D3C), size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B1B1B),
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSnacksSection() {
    final snackProducts = allProducts.where((p) {
      final cat = p.category.trim().toLowerCase();
      return cat == 'snacks' || cat == 'snack';
    }).toList();

    if (snackProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TRADITIONAL SNACKS',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFD4AF37),
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Snacks with a Story',
                    style: GoogleFonts.philosopher(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1B1B1B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Time-honored recipes, perfect for every craving.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => AppNavigator.push(context, const ProductListingPage(category: 'Snacks')),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0F4D3C),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF0F4D3C)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Trust Reassurance Badges Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSnackTrustItem(Icons.eco_rounded, 'Authentic\nIngredients'),
              Container(width: 1, height: 20, color: Colors.grey.shade300),
              _buildSnackTrustItem(Icons.soup_kitchen_rounded, 'Traditional\nRecipes'),
              Container(width: 1, height: 20, color: Colors.grey.shade300),
              _buildSnackTrustItem(Icons.verified_user_rounded, 'No\nPreservatives'),
              Container(width: 1, height: 20, color: Colors.grey.shade300),
              _buildSnackTrustItem(Icons.favorite_rounded, 'Loved by\nThousands'),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Cards List
        SizedBox(
          height: 315,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: snackProducts.length,
            itemBuilder: (context, index) {
              final product = snackProducts[index];
              return _SnackProductCard(
                product: product,
                allProducts: allProducts,
                index: index,
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSnackTrustItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF8B5E3C), size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF1B1B1B), height: 1.1),
        ),
      ],
    );
  }

  Widget _buildSweetsSection() {
    final sweetProducts = allProducts.where((p) {
      final cat = p.category.trim().toLowerCase();
      return cat == 'sweets' || cat == 'sweet';
    }).toList();

    if (sweetProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AUTHENTIC SWEETS',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFD4AF37),
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Traditional Sweets,\nTimeless Joy',
                    style: GoogleFonts.philosopher(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1B1B1B),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Made with pure ingredients, just like home.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => AppNavigator.push(context, const ProductListingPage(category: 'Sweets')),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0F4D3C),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF0F4D3C)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Trust Reassurance Badges Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSweetTrustItem(Icons.eco_rounded, 'Pure\nIngredients'),
              Container(width: 1, height: 20, color: Colors.grey.shade300),
              _buildSweetTrustItem(Icons.soup_kitchen_rounded, 'Traditional\nRecipes'),
              Container(width: 1, height: 20, color: Colors.grey.shade300),
              _buildSweetTrustItem(Icons.verified_user_rounded, 'No Artificial\nFlavors'),
              Container(width: 1, height: 20, color: Colors.grey.shade300),
              _buildSweetTrustItem(Icons.favorite_rounded, 'A Taste of\nHome'),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Sweets Cards Horizontal List
        SizedBox(
          height: 350,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: sweetProducts.length,
            itemBuilder: (context, index) {
              final product = sweetProducts[index];
              return _SweetProductCard(
                product: product,
                allProducts: allProducts,
                index: index,
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Carousel Indicators (— • •)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFF0F4D3C),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 6),
            Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
          ],
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSweetTrustItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF8B5E3C), size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF1B1B1B), height: 1.1),
        ),
      ],
    );
  }

  Widget _buildSweetsQuoteBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  '"SWEET TRADITIONS BRING HAPPIER DAYS"',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.philosopher(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF8B5E3C),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 40, height: 1, color: const Color(0xFFD4AF37)),
                    const SizedBox(width: 8),
                    const Icon(Icons.local_florist_rounded, size: 14, color: Color(0xFFD4AF37)),
                    const SizedBox(width: 8),
                    Container(width: 40, height: 1, color: const Color(0xFFD4AF37)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 80,
              height: 70,
              child: _buildProductImage('assets/images/dry_fruits_laddu_premium_dry_fruits_laddu.jpg'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String path) {
    if (path.isEmpty) {
      return Container(color: Colors.grey.shade50, child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)));
    }
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)));
    }
    String assetPath = path;
    if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/images/$path';
    }
    return Image.asset(assetPath, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)));
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

class _SnackProductCard extends StatefulWidget {
  final Product product;
  final List<Product> allProducts;
  final int index;
  const _SnackProductCard({required this.product, required this.allProducts, required this.index});

  @override
  State<_SnackProductCard> createState() => _SnackProductCardState();
}

class _SnackProductCardState extends State<_SnackProductCard> {
  late String _selectedWeight;

  @override
  void initState() {
    super.initState();
    _selectedWeight = widget.product.defaultWeight;
  }

  String _getSnackTagline(String name) {
    if (name.contains('Chakinalu')) return 'Crispy. Traditional. Addictive.';
    if (name.contains('Bundhi')) return 'Light. Crispy. Timeless.';
    if (name.contains('Chips') || name.contains('Aratikaya')) return 'Thin. Crispy. Irresistible.';
    return 'Authentic. Crispy. Fresh.';
  }

  @override
  Widget build(BuildContext context) {
    final weights = widget.product.weightPriceMap.keys.toList();
    if (!weights.contains(_selectedWeight)) {
      _selectedWeight = weights.isNotEmpty ? weights.first : '500g';
    }

    final priceStr = widget.product.getPriceForWeight(_selectedWeight);

    return GestureDetector(
      onTap: () => AppNavigator.push(context, ProductDetailPage(product: widget.product, allProducts: widget.allProducts)),
      child: Container(
        width: 165,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image Container
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: _buildProductImage(widget.product.image),
                  ),
                ),

                // Top Left Bestseller Badge
                if (widget.index == 0 || widget.product.isBestSeller)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFE5C76B), size: 10),
                          const SizedBox(width: 3),
                          Text(
                            'Bestseller',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Top Right Heart Icon
                Positioned(
                  top: 10,
                  right: 10,
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
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFav ? Colors.red : Colors.grey,
                            size: 14,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // Card Details
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: GoogleFonts.philosopher(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: const Color(0xFF0F4D3C),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getSnackTagline(widget.product.name),
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Weight Dropdown Selector
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedWeight,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF1B1B1B)),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B1B1B)),
                        items: weights.map((String v) => DropdownMenuItem<String>(value: v, child: Text(v))).toList(),
                        onChanged: (v) => setState(() => _selectedWeight = v!),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Price & Plus Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        priceStr,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1B1B1B),
                        ),
                      ),
                      ListenableBuilder(
                        listenable: CartManager(),
                        builder: (context, _) {
                          int qty = CartManager().getProductQuantity(widget.product.name, _selectedWeight);
                          if (qty > 0) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F4D3C),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$qty in cart',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9),
                              ),
                            );
                          }
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              CartManager().addToCart(widget.product, weight: _selectedWeight);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F4D3C),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SweetProductCard extends StatefulWidget {
  final Product product;
  final List<Product> allProducts;
  final int index;
  const _SweetProductCard({required this.product, required this.allProducts, required this.index});

  @override
  State<_SweetProductCard> createState() => _SweetProductCardState();
}

class _SweetProductCardState extends State<_SweetProductCard> {
  late String _selectedWeight;

  @override
  void initState() {
    super.initState();
    _selectedWeight = widget.product.defaultWeight;
  }

  String _getSweetTagline(String name) {
    if (name.contains('Dry Fruits') || name.contains('Fruit')) return 'A wholesome blend of nuts, ghee and natural sweetness.';
    if (name.contains('Gondh')) return 'Ancient recipe for strength and wellness.';
    if (name.contains('Besan')) return 'Soft, rich and melt-in-mouth aromatic bliss.';
    return 'Made with pure ghee and ancestral love.';
  }

  String _getSweetBadge(int idx, String name) {
    if (idx == 0 || name.contains('Dry Fruits')) return '👑 Bestseller';
    if (idx == 1 || name.contains('Gondh')) return '🍃 Traditional';
    return '🍃 Pure Ghee';
  }

  @override
  Widget build(BuildContext context) {
    final weights = widget.product.weightPriceMap.keys.toList();
    if (!weights.contains(_selectedWeight)) {
      _selectedWeight = weights.isNotEmpty ? weights.first : '500g';
    }

    final priceStr = widget.product.getPriceForWeight(_selectedWeight);

    return GestureDetector(
      onTap: () => AppNavigator.push(context, ProductDetailPage(product: widget.product, allProducts: widget.allProducts)),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image Area
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: SizedBox(
                    height: 155,
                    width: double.infinity,
                    child: _buildProductImage(widget.product.image),
                  ),
                ),

                // Top Left Pill Badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F4D3C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getSweetBadge(widget.index, widget.product.name),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Top Right Wishlist Icon
                Positioned(
                  top: 10,
                  right: 10,
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
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFav ? Colors.red : Colors.grey,
                            size: 14,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // Card Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: GoogleFonts.philosopher(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFF0F4D3C),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _getSweetTagline(widget.product.name),
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade500,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Weight Dropdown Selector
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedWeight,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF1B1B1B)),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B1B1B)),
                        items: weights.map((String v) => DropdownMenuItem<String>(value: v, child: Text(v))).toList(),
                        onChanged: (v) => setState(() => _selectedWeight = v!),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Price & Add Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        priceStr,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1B1B1B),
                        ),
                      ),
                      ListenableBuilder(
                        listenable: CartManager(),
                        builder: (context, _) {
                          int qty = CartManager().getProductQuantity(widget.product.name, _selectedWeight);
                          if (qty > 0) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F4D3C),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$qty in cart',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9),
                              ),
                            );
                          }
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              CartManager().addToCart(widget.product, weight: _selectedWeight);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F4D3C),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Add',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewArrivalCard extends StatefulWidget {
  final Product product;
  final List<Product> allProducts;
  final int index;
  const _NewArrivalCard({required this.product, required this.allProducts, required this.index});

  @override
  State<_NewArrivalCard> createState() => _NewArrivalCardState();
}

class _NewArrivalCardState extends State<_NewArrivalCard> {
  late String _selectedWeight;

  @override
  void initState() {
    super.initState();
    _selectedWeight = widget.product.defaultWeight;
  }

  String _getArrivalTagline(String name) {
    if (name.contains('Bellam')) return 'The classic, now even better.';
    if (name.contains('Allam') || name.contains('Garlic')) return 'A bold blend of ginger & garlic.';
    if (name.contains('Usiri') || name.contains('Amla')) return 'Tangy. Healthy. Timeless.';
    return 'Crafted fresh with ancestral love.';
  }

  @override
  Widget build(BuildContext context) {
    final weights = widget.product.weightPriceMap.keys.toList();
    if (!weights.contains(_selectedWeight)) {
      _selectedWeight = weights.isNotEmpty ? weights.first : '500g';
    }

    final priceStr = widget.product.getPriceForWeight(_selectedWeight);

    return GestureDetector(
      onTap: () => AppNavigator.push(context, ProductDetailPage(product: widget.product, allProducts: widget.allProducts)),
      child: Container(
        width: 165,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image Area
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: SizedBox(
                    height: 145,
                    width: double.infinity,
                    child: _buildProductImage(widget.product.image),
                  ),
                ),

                // Top Left "NEW" Pill Badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F4D3C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.eco_rounded, color: Colors.white, size: 10),
                        const SizedBox(width: 3),
                        Text(
                          'NEW',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top Right Wishlist Icon
                Positioned(
                  top: 10,
                  right: 10,
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
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFav ? Colors.red : Colors.grey,
                            size: 14,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // Card Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: GoogleFonts.philosopher(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: const Color(0xFF0F4D3C),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getArrivalTagline(widget.product.name),
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Bottom Row: Weight Selector + Price + Square Plus Button
                  Row(
                    children: [
                      // Weight Selector Dropdown
                      Expanded(
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedWeight,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 12, color: Color(0xFF1B1B1B)),
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1B1B1B)),
                              items: weights.map((String v) => DropdownMenuItem<String>(value: v, child: Text(v))).toList(),
                              onChanged: (v) => setState(() => _selectedWeight = v!),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      Text(
                        priceStr,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1B1B1B),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Square Plus Button
                      ListenableBuilder(
                        listenable: CartManager(),
                        builder: (context, _) {
                          int qty = CartManager().getProductQuantity(widget.product.name, _selectedWeight);
                          if (qty > 0) {
                            return Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F4D3C),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$qty',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                              ),
                            );
                          }
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              CartManager().addToCart(widget.product, weight: _selectedWeight);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F4D3C),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
  final String? subtitle;
  final VoidCallback onSeeAll;
  const _SectionTitle({required this.title, this.subtitle, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.philosopher(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1B1B1B),
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onSeeAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF0F4D3C),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF0F4D3C)),
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
    final weights = widget.product.weightPriceMap.keys.toList();
    if (!weights.contains(_selectedWeight)) {
      _selectedWeight = weights.isNotEmpty ? weights.first : '500g';
    }

    final rawPrice = widget.product.getRawPriceForWeight(_selectedWeight);
    final oldPrice = (rawPrice * 1.15).round();

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
          width: 235,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Image Area
              SizedBox(
                height: 185,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: SizedBox(
                        height: 185,
                        width: double.infinity,
                        child: Hero(
                          tag: widget.product.name,
                          child: _buildProductImage(widget.product.image),
                        ),
                      ),
                    ),

                    // Top Left Bestseller / Badge
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.product.isBestSeller
                                ? [const Color(0xFFE5C76B), const Color(0xFFD4AF37)]
                                : [const Color(0xFF0F4D3C), const Color(0xFF185D4A)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            )
                          ],
                        ),
                        child: Text(
                          widget.product.isBestSeller ? '#1 Bestseller' : '♥ Most Loved',
                          style: TextStyle(
                            color: widget.product.isBestSeller ? const Color(0xFF2D1B12) : Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),

                    // Top Right Heart Wishlist Icon
                    Positioned(
                      top: 10,
                      right: 10,
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
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isFav ? Colors.red : Colors.grey,
                                size: 16,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Cursive Script Overlay
                    Positioned(
                      bottom: 8,
                      right: 12,
                      child: Text(
                        'A Taste of Tradition',
                        style: GoogleFonts.caveat(
                          color: const Color(0xFFE5C76B),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            const Shadow(blurRadius: 4, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Product Info Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.name,
                            style: GoogleFonts.philosopher(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: const Color(0xFF0F4D3C),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'The Royal Sweet & Spicy Classic',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF8B5E3C),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'A perfect blend of sun-ripened ingredients and traditional Andhra spices.',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),

                          // Trust Badges
                          Row(
                            children: [
                              const Text('🍃 100% Natural', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF1B1B1B))),
                              Text('  |  ', style: TextStyle(fontSize: 8, color: Colors.grey.shade400)),
                              const Text('🥣 No Preservatives', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF1B1B1B))),
                            ],
                          ),
                        ],
                      ),

                      // Weight Selector Chips
                      Row(
                        children: weights.map((w) {
                          bool isSel = _selectedWeight == w;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedWeight = w),
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFF0F4D3C) : const Color(0xFFFFF8E8),
                                borderRadius: BorderRadius.circular(10),
                                border: isSel ? null : Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                w,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSel ? Colors.white : const Color(0xFF1B1B1B),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // Price Row
                      Row(
                        children: [
                          Text(
                            '₹${rawPrice.round()}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1B1B1B),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '₹$oldPrice',
                            style: TextStyle(
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3D6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '12% OFF',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8B5E3C),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Add to Cart Button
                      ListenableBuilder(
                        listenable: CartManager(),
                        builder: (context, _) {
                          int qty = CartManager().getProductQuantity(widget.product.name, _selectedWeight);
                          bool isOut = widget.product.isOutOfStock;

                          if (isOut) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: const Text('OUT OF STOCK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                            );
                          }

                          if (qty > 0) {
                            return Container(
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F4D3C),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      CartManager().decrementProductQuantity(widget.product.name, _selectedWeight);
                                    },
                                    child: const Icon(Icons.remove_rounded, color: Colors.white, size: 18),
                                  ),
                                  Text(
                                    '$qty in cart',
                                    style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 12),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      CartManager().addToCart(widget.product, weight: _selectedWeight);
                                    },
                                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                                  ),
                                ],
                              ),
                            );
                          }

                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              CartManager().addToCart(widget.product, weight: _selectedWeight);
                            },
                            child: Container(
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F4D3C),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text('Add to Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
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
    if (path.isEmpty) return const AssetImage('assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg');
    if (path.startsWith('http')) return NetworkImage(path);
    String assetPath = path;
    if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/images/$path';
    }
    return AssetImage(assetPath);
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
      return Container(height: height, width: width, color: Colors.grey.shade50, child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)));
    }
    if (path.startsWith('http')) {
      return Image.network(
        path, height: height, width: width, fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(height: height, width: width, color: Colors.grey.shade50, child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey))),
      );
    }
    String assetPath = path;
    if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/images/$path';
    }
    return Image.asset(
      assetPath, height: height, width: width, fit: BoxFit.cover,
      errorBuilder: (c, e, s) => Container(height: height, width: width, color: Colors.grey.shade50, child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey))),
    );
  }
}

Widget _buildProductImage(String path) {
  if (path.isEmpty) {
    return const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey));
  }
  if (path.startsWith('http')) {
    return Image.network(
      path, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
      errorBuilder: (c, e, s) => const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey)),
    );
  }
  String assetPath = path;
  if (!assetPath.startsWith('assets/')) {
    assetPath = 'assets/images/$path';
  }
  return Image.asset(
    assetPath, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
    errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)),
  );
}
