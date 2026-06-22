import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'product_listing_page.dart';
import 'navigation_util.dart';
import 'main.dart';
import 'app_config_repository.dart';
import 'product_manager.dart';
import 'product_repository.dart';
import 'models.dart';
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
      backgroundColor: const Color(0xFFFFF8E8),
      body: StreamBuilder<List<Map<String, dynamic>>>(
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
                  _buildSliverAppBar(),
                  _buildSearchSection(),
                  
                  // 1. THE DYNAMIC EXTRA HERO BANNER (Admin Managed)
                  _buildExtraHeroBanner(heroConfig),

                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(25, 20, 20, 15),
                      child: Text(
                        'SHOP BY CATEGORY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.grey,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),

                  // 2. ALL CATEGORIES Side-by-Side (3 per row)
                  if (categories.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final cat = categories[index];
                            final label = cat['label'] ?? '';
                            
                            final count = allProducts.where((p) {
                              final pCat = p.category.trim().toLowerCase();
                              final targetCat = label.trim().toLowerCase();
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
                                AppNavigator.push(context, ProductListingPage(category: label));
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
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      toolbarHeight: 70,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFFFFF8E8),
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      title: Text(
        'HERITAGE CATALOG',
        style: GoogleFonts.philosopher(
          fontWeight: FontWeight.w900,
          fontSize: 22,
          color: const Color(0xFF18453B),
          letterSpacing: 2,
        ),
      ),
      actions: [const GlobalCartBadge()],
    );
  }

  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: GestureDetector(
          onTap: () => AppNavigator.push(context, const SearchPage()),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: const Color(0xFF18453B).withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Color(0xFF18453B), size: 22),
                const SizedBox(width: 12),
                Text(
                  'Search in all departments...',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF2D1B12).withOpacity(0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExtraHeroBanner(Map<String, dynamic> config) {
    final title = config['hero_title'] ?? 'The Royal Summer Festival';
    final sub = config['hero_subtitle'] ?? 'Authentic sun-dried mango delicacies';
    final img = config['hero_image'] ?? 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg';
    final tag = config['hero_tag'] ?? 'FEATURED COLLECTION';

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              _buildBannerImage(img),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF18453B).withOpacity(0.9),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: GoogleFonts.philosopher(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sub,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95)),
    );
  }

  Widget _buildBannerImage(String path) {
    if (path.isEmpty) return Container(color: Colors.grey);
    if (path.startsWith('http')) {
      return Image.network(path, width: double.infinity, height: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey));
    }
    return Image.asset(path, width: double.infinity, height: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey));
  }
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
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF18453B).withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Stack(
              children: [
                Positioned.fill(child: _buildImage(widget.img)),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          const Color(0xFF18453B).withOpacity(0.9),
                          const Color(0xFF18453B).withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.badge.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: widget.badge == 'HOT' ? Colors.red : const Color(0xFFD4AF37),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.badge,
                            style: const TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.w900),
                          ),
                        ).animate(onPlay: (c) => c.repeat()).shimmer(),
                      const Spacer(),
                      Text(
                        widget.title.toUpperCase(),
                        style: GoogleFonts.philosopher(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFD4AF37),
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${widget.count} ITEMS',
                        style: TextStyle(
                          fontSize: 7,
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: (widget.index * 100).ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Widget _buildImage(String path) {
    if (path.isEmpty) {
      return Container(color: Colors.grey.shade50, child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)));
    }
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)));
    }
    return Image.asset(path, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)));
  }
}
