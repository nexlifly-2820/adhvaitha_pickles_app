import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'product_listing_page.dart';
import 'navigation_util.dart';
import 'main.dart';
import 'cart_page.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> categories = [
      {
        'title': 'Pickles',
        'sub': 'Traditional Sun-Dried Jars',
        'img': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
      },
      {
        'title': 'Snacks',
        'sub': 'Crispy Traditional Cravings',
        'img': 'assets/images/chakinalu_traditional_sankranti_spiral_snacks.jpg',
      },
      {
        'title': 'Spices',
        'sub': 'Hand-Ground Aromatic Blends',
        'img': 'assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg',
      },
      {
        'title': 'Sweets',
        'sub': 'Pure Jaggery Confections',
        'img': 'assets/images/gondh_laddu_edible_gum_laddu.jpg',
      },
      {
        'title': 'Combos',
        'sub': 'Curated Royal Collections',
        'img': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            toolbarHeight: 70, // Buffer to eliminate 14px overflow
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFFFFF8E8),
            surfaceTintColor: Colors.transparent,
            actions: [GlobalCartBadge()],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                'ROYAL COLLECTIONS',
                style: TextStyle(
                  fontFamily: 'Philosopher',
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Color(0xFF18453B),
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final cat = categories[index];
                  return _PremiumCategoryCard(
                    title: cat['title']!,
                    sub: cat['sub']!,
                    img: cat['img']!,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      AppNavigator.push(context, ProductListingPage(category: cat['title']!));
                    },
                  );
                },
                childCount: categories.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _PremiumCategoryCard extends StatefulWidget {
  final String title, sub, img;
  final VoidCallback onTap;
  const _PremiumCategoryCard({required this.title, required this.sub, required this.img, required this.onTap});

  @override
  State<_PremiumCategoryCard> createState() => _PremiumCategoryCardState();
}

class _PremiumCategoryCardState extends State<_PremiumCategoryCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 160,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF18453B).withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              children: [
                Image.asset(
                  widget.img,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF18453B).withOpacity(0.9),
                        const Color(0xFF18453B).withOpacity(0.1),
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
                      Text(
                        widget.title.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.sub,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 16,
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
}
