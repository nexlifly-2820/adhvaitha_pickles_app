import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
              // 1. PINNED HEADER & SEARCH BAR (Does not scroll)
              _buildHeaderSection(),
              _buildSearchSection(),

              // 2. SCROLLABLE CONTENT (Featured Hero Banner + Categories)
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: AppConfigRepository().getCategoriesStream(),
                  builder: (context, catSnapshot) {
                    return StreamBuilder<Map<String, dynamic>>(
                      stream: AppConfigRepository().getCategoryPageConfigStream(),
                      builder: (context, configSnapshot) {
                        final categories = catSnapshot.data ?? [];
                        final heroConfig = configSnapshot.data ?? {};

                        return CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            const SliverToBoxAdapter(child: SizedBox(height: 6)),
                            _buildExtraHeroBanner(heroConfig),
                            _buildCategorySectionHeader(),

                            // ALL CATEGORIES Grid (2 per row matching target design)
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

                                      final count = allProducts.where((p) {
                                        final pCat =
                                            p.category.trim().toLowerCase();
                                        final targetCat =
                                            label.trim().toLowerCase();
                                        return pCat == targetCat ||
                                            pCat == "${targetCat}s" ||
                                            "${pCat}s" == targetCat;
                                      }).length;

                                      return _CategoryGridCard(
                                        title: label,
                                        img: cat['img'] ?? '',
                                        badge: cat['badge'] ?? '',
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

  Widget _buildExtraHeroBanner(Map<String, dynamic> config) {
    final title = config['hero_title'] ?? 'The Royal\nSummer\nFestival';
    final sub =
        config['hero_subtitle'] ?? 'Authentic sun-dried\nmango delicacies';
    final img = config['hero_image'] ??
        'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg';
    final tag = config['hero_tag'] ?? 'FEATURED COLLECTION';

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
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
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Banner image on the right side
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 200,
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(28),
                  ),
                  child: _buildBannerImage(img),
                ),
              ),

              // Left-to-right gradient overlay for text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0D372B),
                        const Color(0xFF0D372B).withValues(alpha: 0.95),
                        const Color(0xFF0D372B).withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 0.75, 1.0],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),

              // Tradition Circular Badge at Top Right
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D372B).withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFFE5C158), width: 1.5),
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
                        'TRADITION',
                        style: TextStyle(
                          color: const Color(0xFFE5C158),
                          fontSize: 6,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'IN EVERY BITE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Banner Content on Left
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tag.toUpperCase(),
                            style: TextStyle(
                              color: const Color(0xFFE5C158),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title.contains('\n')
                                ? title
                                : title.replaceAll(' ', '\n'),
                            style: GoogleFonts.philosopher(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sub,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Shop Now Pill Button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        AppNavigator.push(
                          context,
                          ProductListingPage(category: 'Pickles'),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5C158),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Shop Now',
                              style: TextStyle(
                                color: const Color(0xFF0D372B),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Color(0xFF0D372B),
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Pagination Indicators
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 16,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5C158),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 4),
                    ...List.generate(
                      3,
                      (index) => Container(
                        margin: const EdgeInsets.only(left: 4),
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Colors.white38,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.96, 0.96)),
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
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F382C).withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: const Color(0xFF0F382C),
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFF0F382C),
                      size: 13,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerImage(String path) {
    if (path.isEmpty) return Container(color: Colors.grey);
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(color: Colors.grey),
      );
    }
    return Image.asset(
      path,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) => Container(color: Colors.grey),
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

  // Dynamic fallback themes for extra categories
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
                // Food Image positioned on right side with gradient blend
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

                // Card Text and Controls on Left
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Category Icon at Top Left
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

                      // Title, Items Count and Arrow Button
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

                          // Circular Arrow Action Button
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

                // Optional HOT/NEW badge
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
                    ).animate(onPlay: (c) => c.repeat()).shimmer(),
                  ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: (widget.index * 80).ms).scale(begin: const Offset(0.92, 0.92)),
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
