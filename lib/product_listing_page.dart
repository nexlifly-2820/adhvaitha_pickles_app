import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'models.dart';
import 'product_detail_page.dart';
import 'cart_manager.dart';
import 'wishlist_manager.dart';
import 'navigation_util.dart';
import 'product_manager.dart';
import 'app_config_repository.dart';
import 'search_page.dart';
import 'main.dart';

class ProductListingPage extends StatefulWidget {
  final String category;
  const ProductListingPage({super.key, required this.category});

  @override
  State<ProductListingPage> createState() => _ProductListingPageState();
}

class _ProductListingPageState extends State<ProductListingPage> {
  String currentSort = "Best Selling";
  String? activeSubCategory;
  bool? showVegOnly;

  List<Product> allCategoryProducts = [];
  List<Product> displayedProducts = [];
  Map<String, dynamic>? categoryMeta;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    // 1. Fetch Metadata (Banner/Description)
    AppConfigRepository().getCategoriesStream().listen((list) {
      if (mounted) {
        setState(() {
          categoryMeta = list.firstWhere(
            (c) =>
                c['label'].toString().toLowerCase() ==
                widget.category.toLowerCase(),
            orElse: () => {},
          );
        });
      }
    });

    // 2. Fetch Products
    ProductManager().addListener(_onProductsUpdated);
    _updateProducts();
  }

  void _onProductsUpdated() {
    if (mounted) {
      _updateProducts();
    }
  }

  void _updateProducts() {
    setState(() {
      allCategoryProducts = ProductManager().products.where((p) {
        if (widget.category == 'All') return true;
        if (widget.category == 'Bestsellers') return p.isBestSeller;

        final pCat = p.category.trim().toLowerCase();
        final targetCat = widget.category.trim().toLowerCase();
        return pCat == targetCat ||
            pCat == "${targetCat}s" ||
            "${pCat}s" == targetCat ||
            pCat.contains(targetCat) ||
            targetCat.contains(pCat);
      }).toList();
      _applyFilters();
      _isLoading = ProductManager().isLoading;
    });
  }

  @override
  void dispose() {
    ProductManager().removeListener(_onProductsUpdated);
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      displayedProducts = allCategoryProducts.where((p) {
        final bool matchesVeg =
            showVegOnly == null || (showVegOnly! ? p.isVeg : !p.isVeg);
        final bool matchesSub =
            activeSubCategory == null || p.subCategory == activeSubCategory;
        return matchesVeg && matchesSub;
      }).toList();
      _sortProducts(currentSort);
    });
  }

  void _sortProducts(String sort) {
    setState(() {
      currentSort = sort;
      if (sort == "Price: Low to High") {
        displayedProducts.sort((a, b) => a
            .getRawPriceForWeight(a.defaultWeight)
            .compareTo(b.getRawPriceForWeight(b.defaultWeight)));
      } else if (sort == "Price: High to Low") {
        displayedProducts.sort((a, b) => b
            .getRawPriceForWeight(a.defaultWeight)
            .compareTo(a.getRawPriceForWeight(a.defaultWeight)));
      } else {
        displayedProducts.sort((a, b) => b.rating.compareTo(a.rating));
      }
    });
  }

  String _getCategoryBgImage() {
    final cat = widget.category.toLowerCase();
    if (cat.contains('sweet')) {
      return 'assets/images/sweets_bg_screen.png';
    }
    if (cat.contains('spice')) {
      return 'assets/images/spices_bg_screen.png';
    }
    if (cat.contains('snack')) {
      return 'assets/images/snacks_bg_screen.png';
    }
    if (cat.contains('pickle')) {
      return 'assets/images/pickles_bg_screen.png';
    }
    return 'assets/images/shop_bg_screen.png';
  }

  String _getAppBarSubtitle() {
    final cat = widget.category.toLowerCase();
    if (cat.contains('sweet')) {
      return 'A Touch of Sweet Tradition';
    }
    if (cat.contains('spice')) {
      return 'Pure Spices, Rich Traditions';
    }
    if (cat.contains('snack')) {
      return 'Traditional Bites, Timeless Taste';
    }
    if (cat.contains('pickle')) {
      return 'Taste Tradition Every Day';
    }
    return 'Authentic Heritage Flavors';
  }

  @override
  Widget build(BuildContext context) {
    final subCategories =
        allCategoryProducts.map((p) => p.subCategory).toSet().toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_getCategoryBgImage()),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // FIXED TOP APP BAR
              _buildAppBarSection(),

              // SCROLLABLE BODY
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    if (!_isLoading) ...[
                      _buildCategoryHero(),
                      _buildStickyFilterBar(subCategories),
                      _buildProductGrid(),
                    ] else
                      _buildShimmerGrid(),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF0D372B),
              size: 22,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.category.toUpperCase(),
                  style: GoogleFonts.philosopher(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: const Color(0xFF0D372B),
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  _getAppBarSubtitle(),
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9E7B3B),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => AppNavigator.push(context, const SearchPage()),
            child: Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(right: 4),
              child: const Icon(
                Icons.search_rounded,
                color: Color(0xFF0D372B),
                size: 22,
              ),
            ),
          ),
          const GlobalCartBadge(),
        ],
      ),
    );
  }

  Widget _buildCategoryHero() {
    final cat = widget.category.toLowerCase();
    final isSweets = cat.contains('sweet');
    final isSpices = cat.contains('spice');
    final isSnacks = cat.contains('snack');
    final isPickles = cat.contains('pickle');

    final String tag = isSweets
        ? 'TRADITIONAL SWEETS'
        : isSpices
            ? "NATURE'S"
            : isSnacks
                ? 'CRISPY HERITAGE DELIGHTS'
                : isPickles
                    ? 'AUTHENTIC COLLECTION'
                    : 'HERITAGE COLLECTION';

    final String titleLine1 = isSweets
        ? 'Sweetness\n'
        : isSpices
            ? "NATURE'S\n"
            : 'Traditional\n';

    final String titleLine2 = isSweets
        ? 'in Every Bite'
        : isSpices
            ? 'FINEST SPICES'
            : isSnacks
                ? 'Indian Snacks'
                : isPickles
                    ? '${widget.category} Pickles'
                    : '${widget.category} Delights';

    final String sub = isSweets
        ? 'Authentic recipes made with\npure ingredients.'
        : isSpices
            ? 'The authentic taste\nthat makes every meal special.'
            : isSnacks
                ? 'Authentic flavors crafted\nwith love and tradition.'
                : isPickles
                    ? 'Prepared using time-honored\nrecipes and premium ingredients.'
                    : 'Handcrafted recipes passed\ndown through generations.';

    final String bannerImg = isSweets
        ? 'assets/images/gondh_laddu_edible_gum_laddu.jpg'
        : isSpices
            ? 'assets/images/garam_masala_powder_traditional_warm_spice_blend.jpg'
            : isSnacks
                ? 'assets/images/chakinalu_traditional_sankranti_spiral_snacks.jpg'
                : categoryMeta?['banner_img']?.toString() ??
                    categoryMeta?['img']?.toString() ??
                    'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg';

    final String sealLine1 = isSweets
        ? 'Good Food'
        : isSpices
            ? 'Good'
            : isSnacks
                ? 'Crunch'
                : 'Taste Our';

    final String sealLine2 = isSweets
        ? 'Sweeter'
        : isSpices
            ? 'Food Good'
            : isSnacks
                ? 'Happiness'
                : 'Heritage';

    final String sealLine3 = isSweets
        ? 'Moments'
        : isSpices
            ? 'Mood'
            : isSnacks
                ? 'Always'
                : '';

    final String btnText = isSweets
        ? 'Explore Sweets'
        : isSpices
            ? 'Explore Spices'
            : isSnacks
                ? 'Explore Snacks'
                : 'Shop Now';

    return SliverToBoxAdapter(
      child: Container(
        height: 215,
        margin: const EdgeInsets.fromLTRB(20, 6, 20, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFF0D372B),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Banner Image on Right Side
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 210,
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(24),
                  ),
                  child: _buildBannerImage(bannerImg),
                ),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFF0D372B),
                        const Color(0xFF0D372B).withValues(alpha: 0.95),
                        const Color(0xFF0D372B).withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 0.75, 1.0],
                    ),
                  ),
                ),
              ),

              // Heritage Circular Badge on Right
              Positioned(
                right: 14,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D372B).withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE5C158), width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.eco_outlined,
                        color: Color(0xFFE5C158),
                        size: 12,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        sealLine1,
                        style: const TextStyle(
                          color: Color(0xFFE5C158),
                          fontSize: 6,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        sealLine2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 5.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (sealLine3.isNotEmpty)
                        Text(
                          sealLine3,
                          style: const TextStyle(
                            color: Color(0xFFE5C158),
                            fontSize: 5.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Content on Left
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tag,
                          style: TextStyle(
                            color: const Color(0xFFE5C158),
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: titleLine1,
                                style: GoogleFonts.philosopher(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                              TextSpan(
                                text: titleLine2,
                                style: GoogleFonts.philosopher(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFE5C158),
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sub,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),

                    // 4 Badges Row for Sweets / 3 Badges for others + Explore Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            _buildHeroFeatureBadge(
                              icon: Icons.eco_outlined,
                              line1: 'Pure',
                              line2: 'Ingredients',
                            ),
                            const SizedBox(width: 6),
                            _buildHeroFeatureBadge(
                              icon: isSweets
                                  ? Icons.favorite_outline_rounded
                                  : Icons.restaurant_outlined,
                              line1: isSweets
                                  ? 'Made'
                                  : isSpices
                                      ? 'Pure &'
                                      : isSnacks
                                          ? 'Homemade'
                                          : 'Traditional',
                              line2: isSweets
                                  ? 'with Love'
                                  : isSpices
                                      ? 'Authentic'
                                      : isSnacks
                                          ? 'Taste'
                                          : 'Recipes',
                            ),
                            const SizedBox(width: 6),
                            _buildHeroFeatureBadge(
                              icon: isSweets
                                  ? Icons.restaurant_outlined
                                  : isSnacks
                                      ? Icons.favorite_outline_rounded
                                      : Icons.no_food_outlined,
                              line1: isSweets
                                  ? 'Traditional'
                                  : isSnacks
                                      ? 'For Every'
                                      : 'No',
                              line2: isSweets
                                  ? 'Recipes'
                                  : isSnacks
                                      ? 'Mood'
                                      : 'Preservatives',
                            ),
                            if (isSweets) ...[
                              const SizedBox(width: 6),
                              _buildHeroFeatureBadge(
                                icon: Icons.no_food_outlined,
                                line1: 'No',
                                line2: 'Preservatives',
                              ),
                            ],
                          ],
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5C158),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                btnText,
                                style: const TextStyle(
                                  color: Color(0xFF0D372B),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Color(0xFF0D372B),
                                size: 11,
                              ),
                            ],
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
      ).animate().fadeIn().scale(begin: const Offset(0.96, 0.96)),
    );
  }

  Widget _buildHeroFeatureBadge({
    required IconData icon,
    required String line1,
    required String line2,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFFE5C158).withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE5C158), width: 1),
          ),
          child: Icon(icon, color: const Color(0xFFE5C158), size: 11),
        ),
        const SizedBox(height: 3),
        Text(
          line1,
          style: TextStyle(
            color: Colors.white,
            fontSize: 6.5,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
        Text(
          line2,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 6,
            fontWeight: FontWeight.w500,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildStickyFilterBar(List<String> subCategories) {
    final cat = widget.category.toLowerCase();
    final isSweets = cat.contains('sweet');
    final isSpices = cat.contains('spice');
    final isSnacks = cat.contains('snack');

    return SliverToBoxAdapter(
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (isSweets) ...[
                  _FilterChip(
                    label: 'All Sweets',
                    icon: Icons.grid_view_rounded,
                    isSelected: showVegOnly == null && activeSubCategory == null,
                    onTap: () => setState(() {
                      showVegOnly = null;
                      activeSubCategory = null;
                      _applyFilters();
                    }),
                  ),
                  _FilterChip(
                    label: 'Laddus',
                    icon: Icons.cookie_outlined,
                    isSelected: activeSubCategory == 'Laddus',
                    onTap: () => setState(() {
                      activeSubCategory =
                          (activeSubCategory == 'Laddus') ? null : 'Laddus';
                      _applyFilters();
                    }),
                  ),
                  _FilterChip(
                    label: 'Halwas',
                    icon: Icons.bakery_dining_outlined,
                    isSelected: activeSubCategory == 'Halwas',
                    onTap: () => setState(() {
                      activeSubCategory =
                          (activeSubCategory == 'Halwas') ? null : 'Halwas';
                      _applyFilters();
                    }),
                  ),
                  _FilterChip(
                    label: 'Traditional',
                    icon: Icons.soup_kitchen_rounded,
                    isSelected: activeSubCategory == 'Traditional',
                    onTap: () => setState(() {
                      activeSubCategory = (activeSubCategory == 'Traditional')
                          ? null
                          : 'Traditional';
                      _applyFilters();
                    }),
                  ),
                  _FilterChip(
                    label: 'Festive',
                    icon: Icons.card_giftcard_rounded,
                    isSelected: activeSubCategory == 'Festive',
                    onTap: () => setState(() {
                      activeSubCategory =
                          (activeSubCategory == 'Festive') ? null : 'Festive';
                      _applyFilters();
                    }),
                  ),
                ] else if (isSpices) ...[
                  _FilterChip(
                    label: 'All Spices',
                    icon: Icons.grid_view_rounded,
                    isSelected: showVegOnly == null && activeSubCategory == null,
                    onTap: () => setState(() {
                      showVegOnly = null;
                      activeSubCategory = null;
                      _applyFilters();
                    }),
                  ),
                  _FilterChip(
                    label: 'Whole Spices',
                    icon: Icons.grain_rounded,
                    isSelected: activeSubCategory == 'Whole Spices',
                    onTap: () => setState(() {
                      activeSubCategory = (activeSubCategory == 'Whole Spices')
                          ? null
                          : 'Whole Spices';
                      _applyFilters();
                    }),
                  ),
                  _FilterChip(
                    label: 'Powders',
                    icon: Icons.soup_kitchen_rounded,
                    isSelected: activeSubCategory == 'Powders',
                    onTap: () => setState(() {
                      activeSubCategory =
                          (activeSubCategory == 'Powders') ? null : 'Powders';
                      _applyFilters();
                    }),
                  ),
                  _FilterChip(
                    label: 'Masalas',
                    icon: Icons.whatshot_rounded,
                    isSelected: activeSubCategory == 'Masalas',
                    onTap: () => setState(() {
                      activeSubCategory =
                          (activeSubCategory == 'Masalas') ? null : 'Masalas';
                      _applyFilters();
                    }),
                  ),
                  _FilterChip(
                    label: 'Organic',
                    icon: Icons.eco_rounded,
                    isSelected: activeSubCategory == 'Organic',
                    onTap: () => setState(() {
                      activeSubCategory =
                          (activeSubCategory == 'Organic') ? null : 'Organic';
                      _applyFilters();
                    }),
                  ),
                ] else if (isSnacks) ...[
                  _FilterChip(
                    label: 'All Snacks',
                    icon: Icons.grid_view_rounded,
                    isSelected: showVegOnly == null && activeSubCategory == null,
                    onTap: () => setState(() {
                      showVegOnly = null;
                      activeSubCategory = null;
                      _applyFilters();
                    }),
                  ),
                ],
                _FilterChip(
                  label: 'Pure Veg',
                  icon: Icons.eco_rounded,
                  isSelected: showVegOnly == true,
                  onTap: () => setState(() {
                    showVegOnly = (showVegOnly == true) ? null : true;
                    _applyFilters();
                  }),
                ),
                _FilterChip(
                  label: 'Non-Veg',
                  icon: Icons.kebab_dining_rounded,
                  isSelected: showVegOnly == false,
                  onTap: () => setState(() {
                    showVegOnly = (showVegOnly == false) ? null : false;
                    _applyFilters();
                  }),
                ),
                if (!isSpices && !isSweets) ...[
                  _FilterChip(
                    label: 'Traditional',
                    icon: Icons.soup_kitchen_rounded,
                    isSelected: activeSubCategory == 'Traditional',
                    onTap: () => setState(() {
                      activeSubCategory = (activeSubCategory == 'Traditional')
                          ? null
                          : 'Traditional';
                      _applyFilters();
                    }),
                  ),
                  _FilterChip(
                    label: 'Spicy',
                    icon: Icons.whatshot_rounded,
                    isSelected: activeSubCategory == 'Spicy',
                    onTap: () => setState(() {
                      activeSubCategory =
                          (activeSubCategory == 'Spicy') ? null : 'Spicy';
                      _applyFilters();
                    }),
                  ),
                ],
                ...subCategories
                    .where((s) =>
                        s != 'Traditional' &&
                        s != 'Spicy' &&
                        s != 'Whole Spices' &&
                        s != 'Powders' &&
                        s != 'Masalas' &&
                        s != 'Organic' &&
                        s != 'Laddus' &&
                        s != 'Halwas' &&
                        s != 'Festive')
                    .map(
                      (s) => _FilterChip(
                        label: s,
                        isSelected: activeSubCategory == s,
                        onTap: () => setState(() {
                          activeSubCategory =
                              (activeSubCategory == s) ? null : s;
                          _applyFilters();
                        }),
                      ),
                    ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: Row(
              children: [
                Text(
                  '${displayedProducts.length} AUTHENTIC VARIETIES',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF9E7B3B),
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: _sortProducts,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.tune_rounded,
                        size: 14,
                        color: Color(0xFF0D372B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Sort By',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0D372B),
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: Color(0xFF0D372B),
                      ),
                    ],
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: "Best Selling",
                      child: Text("Best Selling"),
                    ),
                    const PopupMenuItem(
                      value: "Price: Low to High",
                      child: Text("Price: Low to High"),
                    ),
                    const PopupMenuItem(
                      value: "Price: High to Low",
                      child: Text("Price: High to Low"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    if (displayedProducts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Column(
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 60,
                color: const Color(0xFF0D372B).withValues(alpha: 0.2),
              ),
              const SizedBox(height: 15),
              const Text(
                'No flavors match these filters.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.49,
          crossAxisSpacing: 14,
          mainAxisSpacing: 18,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _ProductCard(product: displayedProducts[index])
              .animate()
              .fadeIn(delay: (index * 40).ms)
              .slideY(begin: 0.08, end: 0),
          childCount: displayedProducts.length,
        ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.49,
          crossAxisSpacing: 14,
          mainAxisSpacing: 18,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => Shimmer.fromColors(
            baseColor: Colors.white,
            highlightColor: const Color(0xFFFFF8E8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          childCount: 4,
        ),
      ),
    );
  }

  Widget _buildBannerImage(String path) {
    if (path.isEmpty) return Container(color: const Color(0xFF0D372B));
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(color: const Color(0xFF0D372B)),
      );
    }
    String assetPath = path;
    if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/images/$path';
    }
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) => Container(color: const Color(0xFF0D372B)),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D372B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D372B).withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? const Color(0xFFE5C158)
                    : const Color(0xFF0D372B),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF0D372B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  late String _selectedWeight;

  @override
  void initState() {
    super.initState();
    _selectedWeight = widget.product.defaultWeight;
  }

  String _getSubtitle() {
    final name = widget.product.name.toLowerCase();
    if (name.contains('dry fruit')) {
      return 'Rich in Nuts & Natural Goodness';
    }
    if (name.contains('gond') || name.contains('gondh')) {
      return 'Traditional & Healthy';
    }
    if (name.contains('kaju') || name.contains('katli') || name.contains('sweet chekki') || name.contains('chikki')) {
      return 'Royal Taste, Premium Quality';
    }
    if (name.contains('besan') || name.contains('sunnunda') || name.contains('millet')) {
      return 'Classic Homemade Taste';
    }
    if (name.contains('gulab') || name.contains('jamun') || name.contains('kova')) {
      return 'Melt in Mouth Delight';
    }
    if (name.contains('chilli') || name.contains('chili') || name.contains('karam')) {
      return 'Rich Color, Bold Flavor';
    }
    if (name.contains('turmeric') || name.contains('haldi')) {
      return 'Pure & Natural';
    }
    if (name.contains('coriander') || name.contains('daniya')) {
      return 'Aromatic & Fresh';
    }
    if (name.contains('garam masala') || name.contains('masala')) {
      return 'Traditional Blend';
    }
    if (name.contains('chakinalu') || name.contains('murukku') || name.contains('janthukalu')) {
      return 'Crispy & Traditional';
    }
    if (name.contains('bundhi') || name.contains('boondi')) {
      return 'Crispy Gram Flour Bites';
    }
    if (name.contains('mixture') || name.contains('khara')) {
      return 'Classic South Indian Mix';
    }
    if (name.contains('pakoda') || name.contains('ribbon') || name.contains('chips')) {
      return 'Crunchy & Flavorful';
    }
    if (name.contains('bellam')) {
      return 'Sweet & Spicy Mango Pickle';
    }
    if (name.contains('allam')) {
      return 'Ginger Garlic Pickle';
    }
    if (name.contains('mango') || name.contains('avakaya')) {
      return 'Classic Andhra Style';
    }
    if (name.contains('lemon') || name.contains('usiri')) {
      return 'Tangy & Flavorful';
    }
    return widget.product.category;
  }

  String _getSoldCount() {
    final hash = widget.product.name.length * 150 + 200;
    if (hash > 800) return '1K+ sold';
    return '$hash+ sold';
  }

  String _resolveProductImage() {
    final p = widget.product;
    final name = p.name.toLowerCase();
    if (name.contains('dry fruit')) {
      return 'assets/images/dry_fruits_laddu_premium_dry_fruits_laddu.jpg';
    }
    if (name.contains('gond') || name.contains('gondh')) {
      return 'assets/images/gondh_laddu_edible_gum_laddu.jpg';
    }
    if (name.contains('kaju') || name.contains('chekki') || name.contains('chikki')) {
      return 'assets/images/sweet_chekki_traditional_sweet_brittle.jpg';
    }
    if (name.contains('besan') || name.contains('sunnunda')) {
      return 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg';
    }
    if (name.contains('millet')) {
      return 'assets/images/millets_laddu_wholesome_multi-millet_laddu.jpg';
    }
    if (name.contains('jamun') || name.contains('kova')) {
      return 'assets/images/kova_gulam_jamun_rich_gulab_jamun_sweet.jpg';
    }
    if (name.contains('palli') || name.contains('patti')) {
      return 'assets/images/palli_patti_peanut_and_jaggery_chikki.jpg';
    }
    if (name.contains('turmeric') || name.contains('haldi')) {
      return 'assets/images/haldi_powder_pure_turmeric_powder.jpg';
    }
    if (name.contains('coriander') || name.contains('daniya')) {
      return 'assets/images/daniya_powder_freshly_ground_coriander_powder.jpg';
    }
    if (name.contains('garam masala')) {
      return 'assets/images/garam_masala_powder_traditional_warm_spice_blend.jpg';
    }
    if (name.contains('chicken masala')) {
      return 'assets/images/chicken_masala_powder_chicken_curry_spice_blend.jpg';
    }
    if (name.contains('mutton masala')) {
      return 'assets/images/mutton_masala_powder_mutton_recipe_spice_blend.jpg';
    }
    if (name.contains('sambhar')) {
      return 'assets/images/sambhar_masala_powder_authentic_sambhar_spice_blend.jpg';
    }
    if (name.contains('karvepaku')) {
      return 'assets/images/karvepaku_karam_podi_curry_leaves_powder.jpg';
    }
    if (name.contains('munagaku')) {
      return 'assets/images/munagaku_karam_podi_moringa_leaves_spice_powder.jpg';
    }
    if (name.contains('putnala')) {
      return 'assets/images/putnala_karam_podi_roasted_gram_spice_powder.jpg';
    }
    if (name.contains('allam velluli karam')) {
      return 'assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg';
    }
    if (name.contains('idli karam') || name.contains('gun powder')) {
      return 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg';
    }
    if (name.contains('kura karam') || name.contains('chilli') || name.contains('chili')) {
      return 'assets/images/special_kura_karam_podi_all-purpose_curry_powder.jpg';
    }
    if (name.contains('chakinalu')) {
      return 'assets/images/chakinalu_traditional_sankranti_spiral_snacks.jpg';
    }
    if (name.contains('bundhi') || name.contains('boondi')) {
      return 'assets/images/bundhi_crispy_spiced_gram_flour_droplets.jpg';
    }
    if (name.contains('mixture')) {
      return 'assets/images/khara_mixture_assorted_crunchy_savory_mix.jpg';
    }
    if (name.contains('janthukalu') || name.contains('pakoda')) {
      return 'assets/images/karam_janthukalu_murukku_strings_snack.jpg';
    }
    if (name.contains('chips')) {
      return 'assets/images/allu_chips_thinly_sliced_indian_potato_chips.jpg';
    }
    if (name.contains('bellam')) {
      return 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg';
    }
    if (name.contains('allam')) {
      return 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg';
    }
    if (name.contains('usiri')) {
      return 'assets/images/usiri_pickle_amlagooseberry_pickle.jpg';
    }
    return p.image;
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _resolveProductImage();

    return GestureDetector(
      onTap: () => AppNavigator.push(
        context,
        ProductDetailPage(product: widget.product),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D372B).withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image Area with Badges & Wishlist Heart
            SizedBox(
              height: 145,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: _buildImage(imagePath),
                    ),
                  ),

                  // Bestseller Badge
                  if (widget.product.isBestSeller)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5C158),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'BESTSELLER',
                          style: TextStyle(
                            color: Color(0xFF0D372B),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                  // Wishlist Heart Button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: ListenableBuilder(
                      listenable: WishlistManager(),
                      builder: (context, _) {
                        final isFav = WishlistManager().isFavorite(widget.product);
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            WishlistManager().toggleFavorite(widget.product);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isFav
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 15,
                              color: isFav ? Colors.red : const Color(0xFF0D372B),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Text Details & Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getSubtitle(),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Rating & Sales Count
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Color(0xFFE5C158),
                      ),
                      Text(
                        ' ${widget.product.rating.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          ' (248) | ${_getSoldCount()}',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Price
                  // Weight Chips Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: widget.product.weightPriceMap.keys.map((w) {
                        bool isSel = _selectedWeight == w;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedWeight = w),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFF0F4D3C) : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(8),
                              border: isSel ? null : Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              w,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSel ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price & Add Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Text(
                        widget.product.getPriceForWeight(_selectedWeight),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      // Add Button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          CartManager().addToCart(
                            widget.product,
                            weight: _selectedWeight,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D372B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                color: Colors.white,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Add',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
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
    );
  }


  Widget _buildImage(String path) {
    if (path.isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
      );
    }
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) =>
            const Icon(Icons.broken_image_outlined, color: Colors.grey),
      );
    }
    String assetPath = path;
    if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/images/$path';
    }
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) =>
          const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
    );
  }
}
