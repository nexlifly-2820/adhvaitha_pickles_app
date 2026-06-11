import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'product_detail_page.dart';
import 'product_listing_page.dart';
import 'cart_manager.dart';
import 'cart_page.dart';
import 'wishlist_manager.dart';
import 'models.dart';
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
  final PageController _bannerController = PageController(viewportFraction: 0.9);
  int _currentBanner = 0;
  late Timer _bannerTimer;

  final List<Product> allProducts = ProductRepository.allProducts;

  final List<Map<String, String>> banners = [
    {'title': 'LUXURY HANDMADE', 'sub': 'The Purest Flavors of Tradition', 'img': 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg'},
    {'title': 'FESTIVAL OF GOLD', 'sub': 'Flat ₹100 Off on All Sweets', 'img': 'assets/images/gondh_laddu_edible_gum_laddu.jpg'},
    {'title': 'ROYAL COMBOS', 'sub': 'Curated Packs for Your Family', 'img': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg'},
  ];

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_bannerController.hasClients) {
        setState(() {
          _currentBanner = (_currentBanner + 1) % banners.length;
        });
        _bannerController.animateToPage(_currentBanner, 
          duration: const Duration(milliseconds: 1200), 
          curve: Curves.easeInOutExpo);
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      floatingActionButton: _buildWhatsAppFAB(),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildStickyHeader(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBentoSection(),
                const SizedBox(height: 30),
                _buildAnimatedHeroBanners(),
                _buildCategoryScroll(),
                _buildSection('Popular Pickles', 'Pickles'),
                _buildOfferBanner(),
                _buildSection('Traditional Snacks', 'Snacks'),
                _buildSection('Fresh Ground Spices', 'Spices'),
                _buildComboSection(),
                _buildTrustPromise(),
                _buildTestimonials(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
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
              BoxShadow(color: const Color(0xFF25D366).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildStickyHeader() {
    return SliverAppBar(
      expandedHeight: 140,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ADHVAITHA', style: TextStyle(fontFamily: 'Philosopher', fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF18453B), letterSpacing: 2)),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Color(0xFFD4AF37)),
                  const SizedBox(width: 4),
                  Text('Madhapur, Hyderabad', style: TextStyle(fontSize: 10, color: const Color(0xFF2D1B12).withOpacity(0.6), fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _HeaderIcon(icon: Icons.notifications_none_rounded, onTap: () => HapticFeedback.lightImpact()),
              const SizedBox(width: 12),
              _buildCartBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartBadge() {
    return ListenableBuilder(
      listenable: CartManager(),
      builder: (context, _) {
        int count = CartManager().items.length;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _HeaderIcon(icon: Icons.shopping_bag_outlined, onTap: () {
              HapticFeedback.lightImpact();
              AppNavigator.push(context, const CartPage());
            }),
            if (count > 0)
              Positioned(
                right: -4, top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
              const VerticalDivider(indent: 15, endIndent: 15, width: 30),
              const Icon(Icons.mic_none_rounded, color: Color(0xFFD4AF37), size: 22),
            ],
          ),
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
            height: 200,
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
                          title: 'New',
                          sub: 'Combos',
                          icon: Icons.auto_awesome,
                          color: const Color(0xFFD4AF37),
                          isDarkText: true,
                          onTap: () => AppNavigator.push(context, const ProductListingPage(category: 'All')),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _BentoCard(
                          title: 'Offers',
                          sub: '30% OFF',
                          icon: Icons.local_offer_rounded,
                          color: const Color(0xFF2D1B12),
                          onTap: () => MainScreen.of(context)?.setIndex(1),
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

  Widget _buildAnimatedHeroBanners() {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: banners.length,
            onPageChanged: (idx) => setState(() => _currentBanner = idx),
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _bannerController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_bannerController.position.hasContentDimensions) {
                    value = (_bannerController.page! - index).abs();
                    value = (1 - (value * 0.15)).clamp(0.0, 1.0);
                  }
                  return Center(
                    child: Transform.scale(
                      scale: value,
                      child: Opacity(opacity: value, child: child),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
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
                        Image.asset(banners[index]['img']!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [const Color(0xFF18453B).withOpacity(0.9), Colors.transparent], begin: Alignment.bottomLeft),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(25),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(banners[index]['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 1.5)),
                              Text(banners[index]['sub']!, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 6, width: _currentBanner == index ? 24 : 6,
            decoration: BoxDecoration(
              color: _currentBanner == index ? const Color(0xFF18453B) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          )),
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
              );
            },
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
          height: 330,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _PremiumProductCard(product: products[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOfferBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          children: [
            Positioned(right: -20, top: -20, child: Icon(Icons.stars_rounded, size: 150, color: Colors.white.withOpacity(0.2))),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('WEEKEND SPECIAL', style: TextStyle(color: Color(0xFF18453B), fontWeight: FontWeight.w900, fontSize: 18)),
                        Text('Get 20% cashback on UPI payments', style: TextStyle(color: Color(0xFF18453B), fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => HapticFeedback.mediumImpact(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(color: const Color(0xFF18453B), borderRadius: BorderRadius.circular(15)),
                      child: const Text('CLAIM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComboSection() {
    return Column(
      children: [
        _SectionTitle(title: 'Elite Combo Packs', onSeeAll: () => AppNavigator.push(context, const ProductListingPage(category: 'All'))),
        _ComboHeroCard(
          title: 'ANDHRA SPECIAL COMBO',
          subtitle: 'Pickle + Snack + Sweet + Spice',
          price: '₹499',
          img: 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
          onTap: () {
            HapticFeedback.heavyImpact();
            CartManager().addToCart(allProducts[0]);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Royal Combo added to cart!')));
          },
        ),
      ],
    );
  }

  Widget _buildTrustPromise() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 60),
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF18453B),
        boxShadow: [BoxShadow(color: const Color(0xFF18453B).withOpacity(0.3), blurRadius: 40)],
      ),
      child: Column(
        children: [
          const Text('THE ADHVAITHA PROMISE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, color: Color(0xFFD4AF37), fontSize: 14)),
          const SizedBox(height: 40),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _PromiseItem(icon: Icons.home_filled, label: 'HOMEMADE'),
              _PromiseItem(icon: Icons.eco, label: 'PURE'),
              _PromiseItem(icon: Icons.no_food, label: 'NO CHEMICALS'),
              _PromiseItem(icon: Icons.flash_on, label: 'FAST'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonials() {
    return Column(
      children: [
        _SectionTitle(title: 'What Royalty Says', onSeeAll: () {}),
        SizedBox(
          height: 200,
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
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Icon(icon, color: const Color(0xFF18453B), size: 22),
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
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF18453B))),
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
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
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
                    const SizedBox(height: 5),
                    Row(
                      children: List.generate(5, (idx) => Icon(
                        idx < widget.product.rating.floor() ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 14, color: const Color(0xFFD4AF37),
                      )),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedWeight,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                          items: widget.product.weightPriceMap.keys.map((String v) => DropdownMenuItem<String>(value: v, child: Text(v))).toList(),
                          onChanged: (v) => setState(() => _selectedWeight = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.product.getPriceForWeight(_selectedWeight), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF18453B))),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            CartManager().addToCart(widget.product, weight: _selectedWeight);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.product.name} added!'), behavior: SnackBarBehavior.floating));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF18453B), Color(0xFF276357)],
                                begin: Alignment.topLeft, end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: const Color(0xFF18453B).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                            ),
                            child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
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
    );
  }
}

class _BentoCard extends StatelessWidget {
  final String title, sub;
  final String? img;
  final IconData? icon;
  final Color color;
  final bool isDarkText;
  final VoidCallback onTap;

  const _BentoCard({required this.title, required this.sub, this.img, this.icon, required this.color, this.isDarkText = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
          image: img != null ? DecorationImage(image: AssetImage(img!), fit: BoxFit.cover, opacity: 0.4) : null,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: img != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, color: isDarkText ? const Color(0xFF18453B) : Colors.white, size: 32),
            if (icon != null) const SizedBox(height: 10),
            Text(title.toUpperCase(), style: TextStyle(color: isDarkText ? const Color(0xFF18453B) : Colors.white70, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2)),
            const SizedBox(height: 4),
            Text(sub, textAlign: img != null ? TextAlign.left : TextAlign.center, style: TextStyle(color: isDarkText ? const Color(0xFF18453B) : Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _ComboHeroCard extends StatefulWidget {
  final String title, subtitle, price, img;
  final VoidCallback onTap;
  const _ComboHeroCard({required this.title, required this.subtitle, required this.price, required this.img, required this.onTap});

  @override
  State<_ComboHeroCard> createState() => _ComboHeroCardState();
}

class _ComboHeroCardState extends State<_ComboHeroCard> {
  bool _isPressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 160, margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            image: DecorationImage(image: AssetImage(widget.img), fit: BoxFit.cover),
            boxShadow: [BoxShadow(color: const Color(0xFF18453B).withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(colors: [Color(0xFF2D1B12), Colors.transparent], begin: Alignment.centerLeft),
            ),
            padding: const EdgeInsets.all(25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.title, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5)),
                    Text(widget.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 15),
                    Text(widget.price, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFE5C76B)]),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: const Text('ADD TO CART', style: TextStyle(color: Color(0xFF18453B), fontWeight: FontWeight.w900, fontSize: 10)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PromiseItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PromiseItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: const Color(0xFFD4AF37), size: 28),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFD4AF37), letterSpacing: 1.5)),
      ],
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
