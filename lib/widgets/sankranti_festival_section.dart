import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models.dart';
import '../cart_manager.dart';
import '../wishlist_manager.dart';
import '../product_detail_page.dart';
import '../product_listing_page.dart';
import '../navigation_util.dart';

class SankrantiFestivalSection extends StatefulWidget {
  final List<Product> allProducts;

  const SankrantiFestivalSection({super.key, required this.allProducts});

  @override
  State<SankrantiFestivalSection> createState() => _SankrantiFestivalSectionState();
}

class _SankrantiFestivalSectionState extends State<SankrantiFestivalSection> {
  int _selectedFilterIndex = 0;

  final List<Map<String, String>> _filters = const [
    {
      'label': 'Sankranti\nSpecials',
      'img': 'assets/images/gondh_laddu_edible_gum_laddu.jpg',
    },
    {
      'label': 'Under\n₹299',
      'img': 'assets/images/chakinalu_traditional_sankranti_spiral_snacks.jpg',
    },
    {
      'label': 'Gift\nCombos',
      'img': 'assets/images/dry_fruits_laddu_premium_dry_fruits_laddu.jpg',
    },
    {
      'label': 'Best\nSellers',
      'img': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
    },
    {
      'label': 'New\nArrivals',
      'img': 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg',
    },
  ];

  List<Product> _getFilteredProducts() {
    if (widget.allProducts.isEmpty) return [];

    switch (_selectedFilterIndex) {
      case 0: // Sankranti Specials
        return widget.allProducts
            .where((p) =>
                p.category == 'Sweets' ||
                p.category == 'Snacks' ||
                p.name.contains('Laddu') ||
                p.name.contains('Chakinalu') ||
                p.name.contains('Sunnunda') ||
                p.name.contains('Avakaya'))
            .toList();
      case 1: // Under ₹299
        return widget.allProducts.where((p) {
          final price = p.getRawPriceForWeight(p.defaultWeight);
          return price > 0 && price <= 299;
        }).toList();
      case 2: // Gift Combos
        final combos = widget.allProducts.where((p) => p.category == 'Combos' || p.name.contains('Laddu') || p.name.contains('Combo')).toList();
        return combos.isNotEmpty ? combos : widget.allProducts;
      case 3: // Best Sellers
        final best = widget.allProducts.where((p) => p.isBestSeller).toList();
        return best.isNotEmpty ? best : widget.allProducts;
      case 4: // New Arrivals
        final podis = widget.allProducts.where((p) => p.category == 'Podis' || p.isFreshPick).toList();
        return podis.isNotEmpty ? podis : widget.allProducts;
      default:
        return widget.allProducts;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _getFilteredProducts();

    return Container(
      color: const Color(0xFFFFF8EC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Banner with Scallop Top & Kites
          _buildHeader(),

          const SizedBox(height: 16),

          // 2. 4 Arched Red Category Cards
          _buildTopCategoryCards(context),

          const SizedBox(height: 16),

          // 3. Orange Ribbon Bar
          _buildOrangeRibbonBar(),

          // 4. Festive Specials Section Title
          _buildFestiveSpecialsHeader(),

          const SizedBox(height: 12),

          // 5. Circular Category Filter Chips
          _buildFilterChips(),

          const SizedBox(height: 18),

          // 6. Horizontal Product List
          _buildProductList(filteredProducts),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // HEADER BANNER
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF6E5), Color(0xFFFDE7BA)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Scallops Top Line
          Positioned(
            top: -12,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 12),
              painter: _ScallopTopPainter(),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 6),
              // CELEBRATE Small Spaced Tag
              Text(
                'C E L E B R A T E',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF8B0000),
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sankranti',
                        style: GoogleFonts.philosopher(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF8B0000),
                          height: 1.0,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        height: 2,
                        width: 140,
                        color: const Color(0xFF8B0000).withOpacity(0.4),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Kites Illustration
                  SizedBox(
                    width: 54,
                    height: 48,
                    child: CustomPaint(painter: _KitesPainter()),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Pindi vantalu, sweets & gift boxes, made fresh',
                textAlign: TextAlign.center,
                style: GoogleFonts.philosopher(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5C0A0D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4 TOP RED ARCHED CARDS
  Widget _buildTopCategoryCards(BuildContext context) {
    final items = [
      {
        'title': 'Pindi\nVantalu',
        'img': 'assets/images/chakinalu_traditional_sankranti_spiral_snacks.jpg',
        'category': 'Snacks',
      },
      {
        'title': 'Festive\nSweets',
        'img': 'assets/images/gondh_laddu_edible_gum_laddu.jpg',
        'category': 'Sweets',
      },
      {
        'title': 'Gift\nBoxes',
        'img': 'assets/images/dry_fruits_laddu_premium_dry_fruits_laddu.jpg',
        'category': 'Combos',
      },
      {
        'title': 'Pickles\n& Podis',
        'img': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
        'category': 'Pickles',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items.map((it) {
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                AppNavigator.push(
                  context,
                  ProductListingPage(category: it['category']!),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 155,
                decoration: BoxDecoration(
                  color: const Color(0xFFB81D24),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF6C453), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10, left: 4, right: 4),
                      child: Text(
                        it['title']!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFF6C453), width: 2),
                        ),
                        child: ClipOval(
                          child: _buildImage(it['img']!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ORANGE RIBBON BAR
  Widget _buildOrangeRibbonBar() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEE801D),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'HOMEMADE  ◆  STONE-GROUND  ◆  FRESH BATCHES  ◆  PAN-INDIA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FESTIVE SPECIALS HEADER
  Widget _buildFestiveSpecialsHeader() {
    return Container(
      color: const Color(0xFFFAF0D7),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('◆  ', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10)),
          Text(
            'F E S T I V E   S P E C I A L S',
            style: GoogleFonts.montserrat(
              color: const Color(0xFF8B0000),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
            ),
          ),
          const Text('  ◆', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10)),
        ],
      ),
    );
  }

  // FILTER CHIPS ROW
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = index == _selectedFilterIndex;
          final item = _filters[index];

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedFilterIndex = index);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? const Color(0xFF8B0000) : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFFD4AF37).withOpacity(0.5),
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF8B0000).withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [],
                    ),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: ClipOval(
                        child: _buildImage(item['img']!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['label']!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      color: isSelected ? const Color(0xFF8B0000) : const Color(0xFF4A0A0C),
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // PRODUCT LISTING HORIZONTAL CARDS
  Widget _buildProductList(List<Product> products) {
    if (products.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('No products available in this section.'),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final p = products[index];
          return _buildFestiveProductCard(p);
        },
      ),
    );
  }

  // INDIVIDUAL PRODUCT CARD
  Widget _buildFestiveProductCard(Product p) {
    return GestureDetector(
      onTap: () {
        AppNavigator.push(
          context,
          ProductDetailPage(product: p, allProducts: widget.allProducts),
        );
      },
      child: Container(
        width: 158,
        margin: const EdgeInsets.only(right: 12, top: 4, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack with Badge & Heart
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: 125,
                    width: double.infinity,
                    child: _buildImage(p.image),
                  ),
                ),

                // Top Left Bestseller Badge
                Positioned(
                  top: 8,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE21B23),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p.isBestSeller ? 'Bestseller' : 'Fresh',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),

                // Top Right Wishlist Button
                Positioned(
                  top: 6,
                  right: 6,
                  child: ListenableBuilder(
                    listenable: WishlistManager(),
                    builder: (context, _) {
                      final isFav = WishlistManager().isFavorite(p);
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          WishlistManager().toggleFavorite(p);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFav ? Colors.red : Colors.grey.shade600,
                            size: 16,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // Card Body (Weight, ADD button, Price, Name)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weight & ADD Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        p.defaultWeight,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          CartManager().addToCart(p, weight: p.defaultWeight);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${p.name} added to cart!'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF18453B), width: 1.5),
                          ),
                          child: const Text(
                            'ADD',
                            style: TextStyle(
                              color: Color(0xFF18453B),
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Price
                  Text(
                    p.defaultPrice,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF18453B),
                    ),
                  ),

                  const SizedBox(height: 2),

                  // Product Title
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.philosopher(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D1B12),
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

  // IMAGE HELPER
  Widget _buildImage(String path) {
    if (path.isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        child: const Center(child: Icon(Icons.restaurant, color: Colors.grey)),
      );
    }
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade100,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
    String assetPath = path.startsWith('assets/') ? path : 'assets/images/$path';
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade100,
        child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
      ),
    );
  }
}

// SCALLOP PAINTER FOR TOP HEADER
class _ScallopTopPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE29227).withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final path = Path();
    double radius = 8;
    double x = 0;
    path.moveTo(0, size.height);

    while (x < size.width) {
      path.relativeArcToPoint(
        Offset(radius * 2, 0),
        radius: Radius.circular(radius),
        clockwise: false,
      );
      x += radius * 2;
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// KITES PAINTER FOR FESTIVAL HEADER
class _KitesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Yellow Kite
    final yellowPaint = Paint()..color = const Color(0xFFF6C453);
    final kite1 = Path()
      ..moveTo(22, 0)
      ..lineTo(40, 14)
      ..lineTo(22, 32)
      ..lineTo(4, 14)
      ..close();
    canvas.drawPath(kite1, yellowPaint);

    // Yellow Kite Line
    final linePaint = Paint()
      ..color = const Color(0xFF8B0000).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(const Offset(22, 32), const Offset(12, 48), linePaint);

    // Red/Teal Kite
    final redPaint = Paint()..color = const Color(0xFFE21B23);
    final kite2 = Path()
      ..moveTo(38, 12)
      ..lineTo(54, 24)
      ..lineTo(38, 38)
      ..lineTo(22, 24)
      ..close();
    canvas.drawPath(kite2, redPaint);
    canvas.drawLine(const Offset(38, 38), const Offset(28, 48), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
