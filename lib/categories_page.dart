import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'product_listing_page.dart';
import 'navigation_util.dart';
import 'main.dart';
import 'app_config_repository.dart';
import 'product_manager.dart';
import 'search_page.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  int _currentParentIndex = 0;

  @override
  void initState() {
    super.initState();
    ProductManager().addListener(_onProductsUpdated);
  }

  @override
  void dispose() {
    ProductManager().removeListener(_onProductsUpdated);
    super.dispose();
  }

  void _onProductsUpdated() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = ProductManager().products;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/shop_bg_screen.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 1. PINNED HEADER & SEARCH BAR
              _buildHeaderSection(),
              _buildSearchSection(),

              // 2. SCROLLABLE CONTENT (Parent Ad Banners Carousel + Categories Grid)
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: AppConfigRepository().getCategoriesStream(),
                  builder: (context, catSnapshot) {
                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: AppConfigRepository().getCategoryParentCardsStream(),
                      builder: (context, parentSnapshot) {
                        final rawData = catSnapshot.data ?? [];
                        final categories = rawData.map((e) => Map<String, dynamic>.from(e)).toList();

                        final rawParents = parentSnapshot.data ?? [];
                        final parentCards = rawParents.map((e) => Map<String, dynamic>.from(e)).toList();
                        if (_currentParentIndex >= parentCards.length && parentCards.isNotEmpty) {
                          _currentParentIndex = 0;
                        }

                        return CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            const SliverToBoxAdapter(child: SizedBox(height: 6)),

                            // Parent Cards (Ads / Banners Carousel at Top - Image Only)
                            if (parentCards.isNotEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: Stack(
                                        children: [
                                          PageView.builder(
                                            physics: const BouncingScrollPhysics(),
                                            onPageChanged: (index) {
                                              setState(() {
                                                _currentParentIndex = index;
                                              });
                                            },
                                            itemCount: parentCards.length,
                                            itemBuilder: (context, index) {
                                              final card = parentCards[index];
                                              final imgPath = card['img'] ?? card['image'] ?? '';
                                              return Container(
                                                width: double.infinity,
                                                height: 200,
                                                decoration: BoxDecoration(
                                                  image: DecorationImage(
                                                    image: imgPath.startsWith('http')
                                                        ? NetworkImage(imgPath) as ImageProvider
                                                        : AssetImage(imgPath.startsWith('assets/') ? imgPath : 'assets/images/$imgPath'),
                                                    fit: BoxFit.cover,
                                                    alignment: Alignment.center,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),

                                          // Pagination Dots
                                          Positioned(
                                            left: 20,
                                            bottom: 12,
                                            child: Row(
                                              children: List.generate(
                                                parentCards.length,
                                                (i) => AnimatedContainer(
                                                  duration: const Duration(milliseconds: 300),
                                                  margin: const EdgeInsets.only(right: 5),
                                                  width: _currentParentIndex == i ? 14 : 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    color: _currentParentIndex == i
                                                        ? const Color(0xFFE5C76B)
                                                        : Colors.white30,
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            const SliverToBoxAdapter(child: SizedBox(height: 16)),
                            _buildCategorySectionHeader(),

                            // Categories Grid (2 per row - Pickles, Snacks, Spices, Sweets)
                            if (categories.isNotEmpty)
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    childAspectRatio: 1.12,
                                  ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final cat = categories[index];
                                      final label = cat['label'] ?? '';
                                      final rawImg = cat['img'] ?? cat['image'] ?? '';
                                      final badge = cat['badge'] ?? '';

                                      final count = allProducts.where((p) {
                                        final pCat = p.category.trim().toLowerCase();
                                        final targetCat = label.trim().toLowerCase();
                                        return pCat == targetCat ||
                                            pCat == "${targetCat}s" ||
                                            "${pCat}s" == targetCat;
                                      }).length;

                                      return _CategoryGridCard(
                                        title: label,
                                        img: rawImg,
                                        badge: badge,
                                        count: count,
                                        index: index,
                                        onTap: () {
                                          HapticFeedback.mediumImpact();
                                          AppNavigator.push(
                                            context,
                                            ProductListingPage(category: label),
                                          );
                                        },
                                      );
                                    },
                                    childCount: categories.length,
                                  ),
                                ),
                              ),

                            const SliverToBoxAdapter(child: SizedBox(height: 120)),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A TASTE OF TRADITION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF9E7B3B),
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Heritage Catalog',
                  style: GoogleFonts.philosopher(
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    color: const Color(0xFF0F382C),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Explore our authentic flavors,\ncrafted with love and tradition.',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF5E5343),
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const GlobalCartBadge(),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: GestureDetector(
        onTap: () => AppNavigator.push(context, const SearchPage()),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F382C).withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                color: Color(0xFF0F382C),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search in all departments...',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF8C827A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF0F382C),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySectionHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SHOP BY CATEGORY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF9E7B3B),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Discover Our Range',
                    style: GoogleFonts.philosopher(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F382C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Handpicked goodness from our kitchens to your home.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: const Color(0xFF5E5343),
                      fontWeight: FontWeight.w500,
                    ),
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

class _CategoryCardTheme {
  final Color bgColor;
  final Color textColor;
  final Color subtitleColor;
  final Color buttonBgColor;
  final Color buttonIconColor;
  final IconData icon;

  const _CategoryCardTheme({
    required this.bgColor,
    required this.textColor,
    required this.subtitleColor,
    required this.buttonBgColor,
    required this.buttonIconColor,
    required this.icon,
  });
}

_CategoryCardTheme _getCategoryTheme(String label, int index) {
  final l = label.toLowerCase();
  if (l.contains('pickle')) {
    return const _CategoryCardTheme(
      bgColor: Color(0xFF0D372B),
      textColor: Colors.white,
      subtitleColor: Color(0xFFC7DC3A),
      buttonBgColor: Color(0xFFE5C158),
      buttonIconColor: Color(0xFF0D372B),
      icon: Icons.takeout_dining_outlined,
    );
  }
  if (l.contains('snack')) {
    return const _CategoryCardTheme(
      bgColor: Color(0xFFF7E8CE),
      textColor: Color(0xFF2C1E11),
      subtitleColor: Color(0xFF6B5847),
      buttonBgColor: Color(0xFF0D372B),
      buttonIconColor: Colors.white,
      icon: Icons.cookie_outlined,
    );
  }
  if (l.contains('spice')) {
    return const _CategoryCardTheme(
      bgColor: Color(0xFF1E2F23),
      textColor: Color(0xFFE5C158),
      subtitleColor: Color(0xFFD6C3A5),
      buttonBgColor: Color(0xFF0D372B),
      buttonIconColor: Colors.white,
      icon: Icons.eco_outlined,
    );
  }
  if (l.contains('sweet')) {
    return const _CategoryCardTheme(
      bgColor: Color(0xFFF8E5D8),
      textColor: Color(0xFF2C1E11),
      subtitleColor: Color(0xFF6B5847),
      buttonBgColor: Color(0xFF0D372B),
      buttonIconColor: Colors.white,
      icon: Icons.cake_outlined,
    );
  }

  final fallbacks = [
    const _CategoryCardTheme(
      bgColor: Color(0xFF0D372B),
      textColor: Colors.white,
      subtitleColor: Color(0xFFC7DC3A),
      buttonBgColor: Color(0xFFE5C158),
      buttonIconColor: Color(0xFF0D372B),
      icon: Icons.grid_view_rounded,
    ),
    const _CategoryCardTheme(
      bgColor: Color(0xFFF7E8CE),
      textColor: Color(0xFF2C1E11),
      subtitleColor: Color(0xFF6B5847),
      buttonBgColor: Color(0xFF0D372B),
      buttonIconColor: Colors.white,
      icon: Icons.grid_view_rounded,
    ),
  ];
  return fallbacks[index % fallbacks.length];
}

String _resolveCategoryImage(String label, String rawImg) {
  final l = label.toLowerCase();
  if (l.contains('pickle')) {
    return 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg';
  }
  if (l.contains('snack')) {
    return 'assets/images/chakinalu_traditional_sankranti_spiral_snacks.jpg';
  }
  if (l.contains('spice')) {
    return 'assets/images/garam_masala_powder_traditional_warm_spice_blend.jpg';
  }
  if (l.contains('sweet')) {
    return 'assets/images/kova_gulam_jamun_rich_gulab_jamun_sweet.jpg';
  }
  if (rawImg.isNotEmpty) return rawImg;
  return 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg';
}

class _CategoryGridCard extends StatefulWidget {
  final String title, img, badge;
  final int count, index;
  final VoidCallback onTap;

  const _CategoryGridCard({
    required this.title,
    required this.img,
    required this.badge,
    required this.count,
    required this.index,
    required this.onTap,
  });

  @override
  State<_CategoryGridCard> createState() => _CategoryGridCardState();
}

class _CategoryGridCardState extends State<_CategoryGridCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = _getCategoryTheme(widget.title, widget.index);
    final resolvedImage = _resolveCategoryImage(widget.title, widget.img);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: BoxDecoration(
            color: theme.bgColor,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D372B).withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  top: -5,
                  bottom: -5,
                  width: 115,
                  child: ShaderMask(
                    shaderCallback: (rect) {
                      return LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                          Colors.black,
                        ],
                        stops: const [0.0, 0.35, 1.0],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstIn,
                    child: _buildImage(resolvedImage),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.textColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          theme.icon,
                          color: theme.textColor,
                          size: 18,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title.toUpperCase(),
                            style: GoogleFonts.philosopher(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: theme.textColor,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${widget.count} ITEMS',
                            style: TextStyle(
                              fontSize: 9,
                              color: theme.subtitleColor,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.buttonBgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: theme.buttonIconColor,
                              size: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.badge.isNotEmpty)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: widget.badge == 'HOT'
                            ? Colors.red
                            : const Color(0xFFD4AF37),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.isEmpty) {
      return Container(
        color: Colors.transparent,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
        ),
      );
    }
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(color: Colors.grey),
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) => Container(color: Colors.grey),
    );
  }
}
