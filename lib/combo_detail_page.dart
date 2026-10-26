import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models.dart';
import 'cart_manager.dart';
import 'wishlist_manager.dart';
import 'navigation_util.dart';
import 'product_listing_page.dart';
import 'product_detail_page.dart';
import 'product_manager.dart';
import 'widgets/art_of_pairing.dart';

class ComboDetailPage extends StatefulWidget {
  final PairItem pairItem;

  const ComboDetailPage({super.key, required this.pairItem});

  @override
  State<ComboDetailPage> createState() => _ComboDetailPageState();
}

class _ComboDetailPageState extends State<ComboDetailPage> {
  late String _partA;
  late String _partB;

  @override
  void initState() {
    super.initState();
    _parseNames();
  }

  void _parseNames() {
    final parts = widget.pairItem.name.split('+');
    if (parts.length >= 2) {
      _partA = parts[0].trim();
      _partB = parts[1].trim();
    } else {
      _partA = widget.pairItem.name;
      _partB = 'Side Choice';
    }
  }

  Widget _buildImage(String path, {double width = 110}) {
    if (path.isEmpty) {
      return SizedBox(width: width, child: const Icon(Icons.restaurant, color: Colors.grey));
    }
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: width,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
      );
    }
    String assetPath = path.startsWith('assets/') ? path : 'assets/images/$path';
    return Image.asset(
      assetPath,
      width: width,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.pairItem;
    final priceA = (item.price * 0.45).round();
    final priceB = item.price - priceA;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8EC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2A1A12)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Combo details',
          style: GoogleFonts.poppins(
            color: const Color(0xFF2A1A12),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded, color: Color(0xFF2A1A12)),
            onPressed: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Combo saved to wishlist!'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. HERO COMBO HEADER IMAGE CARD
                  Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const RadialGradient(
                        center: Alignment(0, 0.2),
                        radius: 0.85,
                        colors: [Color(0xFFFFF3D9), Color(0xFFFBE6C0)],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Dual Cutout Bowls
                        Positioned.fill(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildImage(item.imageA, width: 120),
                              const SizedBox(width: 10),
                              Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                                  ],
                                ),
                                child: Text(
                                  '+',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF7A0F12),
                                    height: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              _buildImage(item.imageB, width: 120),
                            ],
                          ),
                        ),

                        // Top Left Tag Badge
                        if (item.tag.isNotEmpty)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F8A3A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.tag,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. COMBO TITLE & SUBTITLE
                  Text(
                    item.name,
                    style: GoogleFonts.fraunces(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2A1A12),
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF7A6A5E)),
                      children: [
                        const TextSpan(text: 'Best with '),
                        TextSpan(
                          text: item.bestWith,
                          style: const TextStyle(color: Color(0xFFB8860B), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // PRICE FOR 2 ITEMS
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹${item.price}',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1B1B1B),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'for 2 items',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF7A6A5E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 3. WHAT'S INSIDE SECTION
                  Text(
                    "What's inside",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2A1A12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Item 1 Card
                  _buildInsideItemCard(
                    title: _partA,
                    weight: '200 g',
                    price: '₹$priceA',
                    imgPath: item.imageA,
                  ),

                  const SizedBox(height: 10),

                  // Item 2 Card
                  _buildInsideItemCard(
                    title: _partB,
                    weight: '500 g',
                    price: '₹$priceB',
                    imgPath: item.imageB,
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // 4. BOTTOM STICKY BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${item.price}',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1B1B1B),
                        ),
                      ),
                      Text(
                        '2 items',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item.name} combo added to cart!'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F8A3A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Add combo to cart',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsideItemCard({
    required String title,
    required String weight,
    required String price,
    required String imgPath,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE4D2)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3D9),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFBE6C0)),
            ),
            child: ClipOval(
              child: _buildImage(imgPath, width: 50),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: const Color(0xFF2A1A12),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  weight,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  price,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B1B1B),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => openProductDetailByName(context, title),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF8B0000),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF8B0000)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// QUICK BOTTOM SHEET MODAL (Right Screen in image)
void showComboQuickBottomSheet(BuildContext context, PairItem item) {
  HapticFeedback.lightImpact();
  final priceA = (item.price * 0.45).round();
  final priceB = item.price - priceA;

  final parts = item.name.split('+');
  final partA = parts.length >= 1 ? parts[0].trim() : item.name;
  final partB = parts.length >= 2 ? parts[1].trim() : 'Side Item';

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Title & Subtitle
            Text(
              item.name,
              style: GoogleFonts.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2A1A12),
              ),
            ),
            const SizedBox(height: 2),
            Text.rich(
              TextSpan(
                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF7A6A5E)),
                children: [
                  const TextSpan(text: 'Best with '),
                  TextSpan(
                    text: item.bestWith,
                    style: const TextStyle(color: Color(0xFFB8860B), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2 Side-by-Side Product Cards
            Row(
              children: [
                Expanded(
                  child: _buildMiniCard(context, partA, '200 g · ₹$priceA', item.imageA),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniCard(context, partB, '500 g · ₹$priceB', item.imageB),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Bottom Sticky Action Bar
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹${item.price}',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1B1B1B),
                      ),
                    ),
                    Text(
                      '2 items',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.name} combo added to cart!'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F8A3A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Add combo to cart',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

void openProductDetailByName(BuildContext context, String title) {
  HapticFeedback.lightImpact();
  final allProducts = ProductManager().products;
  if (allProducts.isEmpty) {
    AppNavigator.push(context, ProductListingPage(category: title));
    return;
  }

  final cleanTitle = title.toLowerCase().trim();
  final matchingProduct = allProducts.firstWhere(
    (p) {
      final pName = p.name.toLowerCase();
      return pName.contains(cleanTitle) || cleanTitle.contains(pName) ||
             (cleanTitle.contains('karam') && pName.contains('karam')) ||
             (cleanTitle.contains('avakaya') && pName.contains('avakaya')) ||
             (cleanTitle.contains('sunnunda') && pName.contains('sunnunda')) ||
             (cleanTitle.contains('palli') && pName.contains('palli')) ||
             (cleanTitle.contains('murukku') && (pName.contains('murukku') || pName.contains('janthukalu'))) ||
             (cleanTitle.contains('mixture') && pName.contains('mixture')) ||
             (cleanTitle.contains('chips') && pName.contains('chips'));
    },
    orElse: () => allProducts.first,
  );

  AppNavigator.push(
    context,
    ProductDetailPage(
      product: matchingProduct,
      allProducts: allProducts,
    ),
  );
}

Widget _buildMiniCard(BuildContext context, String title, String subtitle, String imgPath) {
  Widget imgWidget;
  if (imgPath.isEmpty) {
    imgWidget = const Icon(Icons.restaurant, color: Colors.grey);
  } else if (imgPath.startsWith('http')) {
    imgWidget = Image.network(imgPath, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image));
  } else {
    String assetPath = imgPath.startsWith('assets/') ? imgPath : 'assets/images/$imgPath';
    imgWidget = Image.asset(assetPath, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported));
  }

  return GestureDetector(
    onTap: () {
      Navigator.pop(context); // Close bottom sheet
      openProductDetailByName(context, title);
    },
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE4D2)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: imgWidget,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: const Color(0xFF2A1A12),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    ),
  );
}
