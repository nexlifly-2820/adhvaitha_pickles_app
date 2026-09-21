import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models.dart';
import 'cart_manager.dart';
import 'wishlist_manager.dart';
import 'checkout_page.dart';
import 'navigation_util.dart';
import 'product_repository.dart';
import 'cloud_function_manager.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final List<Product> allProducts;
  const ProductDetailPage({super.key, required this.product, this.allProducts = const []});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int quantity = 1;
  late String selectedWeight;
  int _selectedImageIndex = 0;
  bool isTemperingRequested = false;
  final TextEditingController _chefNoteController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Accordion Expansion States
  bool _isIngredientsExpanded = false;
  bool _isBehindJarExpanded = false;
  bool _isMasterArtisanExpanded = false;
  bool _isRoyalRecipesExpanded = false;
  bool _isUserReviewsExpanded = false;

  late List<String> _galleryImages;

  @override
  void initState() {
    super.initState();
    selectedWeight = widget.product.defaultWeight;
    ProductRepository.addToRecentlyViewed(widget.product);

    // Prepare gallery images
    _galleryImages = [
      widget.product.image,
      'assets/images/usiri_pickle_amlagooseberry_pickle.jpg',
      'assets/images/palli_patti_peanut_and_jaggery_chikki.jpg',
      'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
      'assets/images/uppava_traditional_salted_pickle.jpg',
    ];
  }

  @override
  void dispose() {
    _chefNoteController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _subtitle {
    if (widget.product.name.toLowerCase().contains('bellam')) {
      return 'Sweet Jaggery Mango Pickle';
    } else if (widget.product.name.toLowerCase().contains('allam')) {
      return 'Spicy Ginger Garlic Pickle';
    } else if (widget.product.name.toLowerCase().contains('usiri')) {
      return 'Traditional Amla Gooseberry Pickle';
    }
    return '${widget.product.category} Special';
  }

  double get _originalPrice {
    double current = widget.product.getRawPriceForWeight(selectedWeight);
    if (current <= 0) return 450.0;
    return (current * 1.28).roundToDouble();
  }

  int get _discountPercentage {
    double orig = _originalPrice;
    double current = widget.product.getRawPriceForWeight(selectedWeight);
    if (orig <= current) return 20;
    return (((orig - current) / orig) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = WishlistManager();
    final bool isFav = wishlist.isFavorite(widget.product);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF2),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(isFav, wishlist),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnails Row below Hero image
                      _buildThumbnailsRow(),
                      const SizedBox(height: 16),

                      // Social proof & Bestseller badge
                      _buildSocialProofTickerAndBadge(),
                      const SizedBox(height: 12),

                      // Category & Rating
                      _buildCategoryAndRating(),
                      const SizedBox(height: 12),

                      // Title & Subtitle
                      _buildProductTitleAndSubtitle(),
                      const SizedBox(height: 12),

                      // Price, Strike Price & Discount Tag
                      _buildPriceSection(),
                      const SizedBox(height: 20),

                      // Description Section
                      _buildDescriptionSection(),
                      const SizedBox(height: 20),

                      // Feature Pills (Zero Preservatives, Sun-Dried, Traditional Taste)
                      _buildFeaturePills(),
                      const SizedBox(height: 24),

                      // Select Weight & Quantity Selector
                      _buildWeightAndQuantitySection(),
                      const SizedBox(height: 28),

                      // Chef Customization (Tempering) if enabled
                      if (widget.product.canRequestTempering) ...[
                        _buildChefCustomization(),
                        const SizedBox(height: 20),
                      ],

                      // DROPDOWNS / ACCORDION SECTIONS
                      _buildAccordionsSection(),
                      const SizedBox(height: 28),

                      // Footer Banner
                      _buildFooterBanner(),
                      const SizedBox(height: 120), // Bottom padding for sticky bar
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Fixed Bottom Action Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildFixedBottomBar(),
          ),
        ],
      ),
    );
  }

  // SLIVER APP BAR / HERO IMAGE
  Widget _buildSliverAppBar(bool isFav, WishlistManager wishlist) {
    return SliverAppBar(
      expandedHeight: 380,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFFFFFBF2),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF18453B), size: 18),
          ),
        ),
      ),
      actions: [
        CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          child: IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              wishlist.toggleFavorite(widget.product);
              setState(() {});
            },
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? Colors.red : const Color(0xFF18453B),
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          child: IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Clipboard.setData(ClipboardData(text: 'Check out ${widget.product.name} on Adhvaitha Pickles!'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Product link copied to clipboard!'),
                  backgroundColor: Color(0xFF18453B),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.share_outlined, color: Color(0xFF18453B), size: 20),
          ),
        ),
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Main Product Image
            Container(
              margin: const EdgeInsets.fromLTRB(12, 50, 12, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: AnimatedSwitcher(
                  duration: 300.ms,
                  child: _buildMainImageWidget(_galleryImages[_selectedImageIndex]),
                ),
              ),
            ),

            // Top Left Text Overlay: "Tradition in Every Morsel"
            Positioned(
              top: 70,
              left: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tradition in Every',
                    style: GoogleFonts.alexBrush(
                      fontSize: 26,
                      color: Colors.white,
                      shadows: [
                        const Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(1, 1)),
                      ],
                    ),
                  ),
                  Text(
                    'Morsel',
                    style: GoogleFonts.alexBrush(
                      fontSize: 26,
                      color: Colors.white,
                      shadows: [
                        const Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(1, 1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Top Right Circular Seal Badge: "AUTHENTIC ANDHRA PICKLES"
            Positioned(
              top: 65,
              right: 28,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2A1C15).withValues(alpha: 0.85),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded, color: Color(0xFFD4AF37), size: 14),
                    const SizedBox(height: 2),
                    Text(
                      'AUTHENTIC\nANDHRA\nPICKLES',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.philosopher(
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFFFF8E8),
                        height: 1.1,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Right Overlay: "Sweet Spicy Memorable"
            Positioned(
              bottom: 60,
              right: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Sweet Spicy',
                    style: GoogleFonts.alexBrush(
                      fontSize: 24,
                      color: Colors.white,
                      shadows: [
                        const Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(1, 1)),
                      ],
                    ),
                  ),
                  Text(
                    'Memorable',
                    style: GoogleFonts.alexBrush(
                      fontSize: 24,
                      color: Colors.white,
                      shadows: [
                        const Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(1, 1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Overlay Pills on Bottom Left of main photo: (100% Natural, Traditional Recipe, No Preservatives)
            Positioned(
              bottom: 24,
              left: 24,
              child: Row(
                children: [
                  _buildTrustBadgePill(Icons.eco_outlined, '100%\nNatural'),
                  const SizedBox(width: 8),
                  _buildTrustBadgePill(Icons.rice_bowl_outlined, 'Traditional\nRecipe'),
                  const SizedBox(width: 8),
                  _buildTrustBadgePill(Icons.verified_outlined, 'No\nPreservatives'),
                ],
              ),
            ),

            // Image Counter Pill on Bottom Right
            Positioned(
              bottom: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedImageIndex + 1} / ${_galleryImages.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustBadgePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w600, height: 1.1),
          ),
        ],
      ),
    );
  }

  // THUMBNAILS ROW
  Widget _buildThumbnailsRow() {
    return SizedBox(
      height: 65,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _galleryImages.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedImageIndex;
          final isVideo = index == 3;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedImageIndex = index);
            },
            child: Container(
              width: 65,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFF18453B) : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildMainImageWidget(_galleryImages[index]),
                    if (isVideo)
                      Container(
                        color: Colors.black26,
                        child: const Center(
                          child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // SOCIAL PROOF & BESTSELLER
  Widget _buildSocialProofTickerAndBadge() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3D6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_up_rounded, size: 16, color: Color(0xFFC38D29)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.product.viewCount} royal guests viewed this today',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8C6211),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.product.isBestSeller) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE2F3EC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_rounded, size: 15, color: Color(0xFF18453B)),
                SizedBox(width: 4),
                Text(
                  'Bestseller',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF18453B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // CATEGORY & RATING
  Widget _buildCategoryAndRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE2F3EC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.eco_rounded, size: 14, color: Color(0xFF18453B)),
              const SizedBox(width: 6),
              Text(
                widget.product.category.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF18453B),
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFD4AF37), size: 20),
            Text(
              ' ${widget.product.rating}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2A1C15)),
            ),
            const SizedBox(width: 4),
            Text('(120+)', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  // TITLE & SUBTITLE
  Widget _buildProductTitleAndSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.name,
          style: GoogleFonts.philosopher(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF18453B),
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _subtitle,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF5A483C),
          ),
        ),
      ],
    );
  }

  // PRICE SECTION
  Widget _buildPriceSection() {
    final currentPrice = widget.product.getPriceForWeight(selectedWeight);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          currentPrice,
          style: GoogleFonts.philosopher(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF18453B),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '₹${_originalPrice.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 16,
            decoration: TextDecoration.lineThrough,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFECEC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$_discountPercentage% OFF',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFFE53935),
            ),
          ),
        ),
      ],
    );
  }

  // DESCRIPTION SECTION
  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'DESCRIPTION',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 12,
                color: Color(0xFF18453B),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 1,
                color: const Color(0xFF18453B).withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.eco_outlined, size: 14, color: Color(0xFF18453B)),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 1,
                color: const Color(0xFF18453B).withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _showSecretIngredient,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 12, color: Color(0xFFC38D29)),
                    SizedBox(width: 4),
                    Text(
                      'SECRET',
                      style: TextStyle(color: Color(0xFFC38D29), fontWeight: FontWeight.w900, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          widget.product.description.isEmpty
              ? 'Sweet jaggery mango pickle. A perfect blend of juicy raw mangoes, pure jaggery and traditional Andhra spices, prepared with love and time-honored methods.'
              : widget.product.description,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF5A483C),
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // FEATURE PILLS
  Widget _buildFeaturePills() {
    final features = [
      'Zero Preservatives',
      'Sun-Dried',
      'Traditional Taste',
    ];

    return Row(
      children: features.map((feature) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8DFD0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFFC38D29)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    feature,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2A1C15),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // SELECT WEIGHT & QUANTITY SELECTOR
  Widget _buildWeightAndQuantitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SELECT WEIGHT',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 11,
            color: Color(0xFF18453B),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Weight options
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.product.weightPriceMap.keys.map((w) {
                  final isSelected = selectedWeight == w;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => selectedWeight = w);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF18453B) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF18453B) : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        w,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF2A1C15),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(width: 12),

            // Quantity selector: - 1 +
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      if (quantity > 1) {
                        HapticFeedback.lightImpact();
                        setState(() => quantity--);
                      }
                    },
                    icon: const Icon(Icons.remove, size: 16, color: Color(0xFF18453B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '$quantity',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF18453B),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => quantity++);
                    },
                    icon: const Icon(Icons.add, size: 16, color: Color(0xFF18453B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ACCORDIONS SECTION
  Widget _buildAccordionsSection() {
    return Column(
      children: [
        // 1. INGREDIENTS ACCORDION
        _buildAccordionItem(
          icon: Icons.eco_outlined,
          title: 'INGREDIENTS',
          isExpanded: _isIngredientsExpanded,
          onToggle: () => setState(() => _isIngredientsExpanded = !_isIngredientsExpanded),
          expandedChild: _buildExpandedIngredients(),
        ),
        const SizedBox(height: 12),

        // 2. BEHIND THE JAR ACCORDION
        _buildAccordionItem(
          icon: Icons.info_outline_rounded,
          title: 'BEHIND THE JAR',
          isExpanded: _isBehindJarExpanded,
          onToggle: () => setState(() => _isBehindJarExpanded = !_isBehindJarExpanded),
          expandedChild: _buildExpandedBehindTheJar(),
        ),
        const SizedBox(height: 12),

        // 3. MASTER ARTISAN ACCORDION
        _buildAccordionItem(
          icon: Icons.person_outline_rounded,
          title: 'MASTER ARTISAN',
          isExpanded: _isMasterArtisanExpanded,
          onToggle: () => setState(() => _isMasterArtisanExpanded = !_isMasterArtisanExpanded),
          expandedChild: _buildExpandedMasterArtisan(),
        ),
        const SizedBox(height: 12),

        // 4. ROYAL RECIPES ACCORDION
        _buildAccordionItem(
          icon: Icons.menu_book_rounded,
          title: 'ROYAL RECIPES',
          isExpanded: _isRoyalRecipesExpanded,
          onToggle: () => setState(() => _isRoyalRecipesExpanded = !_isRoyalRecipesExpanded),
          expandedChild: _buildExpandedRoyalRecipes(),
        ),
        const SizedBox(height: 12),

        // 5. USER REVIEWS ACCORDION
        _buildAccordionItem(
          icon: Icons.star_border_rounded,
          title: 'USER REVIEWS (${widget.product.reviews.length + 120})',
          actionWidget: GestureDetector(
            onTap: _showReviewDialog,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_note_rounded, size: 14, color: Color(0xFFC38D29)),
                SizedBox(width: 4),
                Text(
                  'WRITE A REVIEW',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFC38D29),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          isExpanded: _isUserReviewsExpanded,
          onToggle: () => setState(() => _isUserReviewsExpanded = !_isUserReviewsExpanded),
          expandedChild: _buildExpandedUserReviews(),
        ),
      ],
    );
  }

  // ACCORDION ITEM CONTAINER
  Widget _buildAccordionItem({
    required IconData icon,
    required String title,
    Widget? actionWidget,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget expandedChild,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECE7DE)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onToggle();
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, color: const Color(0xFF18453B), size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 11,
                        color: Color(0xFF18453B),
                      ),
                    ),
                  ),
                  if (actionWidget != null) ...[
                    actionWidget,
                    const SizedBox(width: 12),
                  ],
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: 250.ms,
                    child: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF18453B), size: 20),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(height: 1, color: Color(0xFFF0EBE1)),
                  const SizedBox(height: 16),
                  expandedChild,
                ],
              ),
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: 250.ms,
          ),
        ],
      ),
    );
  }

  // EXPANDED 1: INGREDIENTS
  Widget _buildExpandedIngredients() {
    final ingredientsList = [
      {'name': 'Raw Mangoes', 'image': 'assets/images/usiri_pickle_amlagooseberry_pickle.jpg'},
      {'name': 'Pure Jaggery', 'image': 'assets/images/palli_patti_peanut_and_jaggery_chikki.jpg'},
      {'name': 'Red Chilli Powder', 'image': 'assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg'},
      {'name': 'Mustard Seeds', 'image': 'assets/images/putnala_karam_podi_roasted_gram_spice_powder.jpg'},
      {'name': 'Fenugreek Seeds', 'image': 'assets/images/menthi_podi_fenugreek_powder.jpg'},
      {'name': 'Rock Salt', 'image': 'assets/images/haldi_powder_pure_turmeric_powder.jpg'},
      {'name': 'Sesame Oil', 'image': 'assets/images/thill_patti_sesame_seed_and_jaggery_sweet.jpg'},
      {'name': 'Spices', 'image': 'assets/images/garam_masala_powder_traditional_warm_spice_blend.jpg'},
    ];

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ingredientsList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final item = ingredientsList[index];
            return Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8DFD0)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      item['image']!,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Icon(Icons.eco, color: Color(0xFF18453B)),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item['name']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF2A1C15)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9EE),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5D5BA)),
          ),
          child: const Row(
            children: [
              Icon(Icons.eco_outlined, size: 14, color: Color(0xFFC38D29)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '"Simple ingredients. Extraordinary taste."',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8C6211),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // EXPANDED 2: BEHIND THE JAR
  Widget _buildExpandedBehindTheJar() {
    final timelineItems = [
      {
        'icon': Icons.location_on_rounded,
        'title': 'Origin',
        'subtitle': widget.product.origin,
        'desc': 'Sourced from the finest mango farms.',
      },
      {
        'icon': Icons.eco_rounded,
        'title': 'Process',
        'subtitle': 'Handmade & Sun-dried',
        'desc': widget.product.preparationMethod.isNotEmpty
            ? widget.product.preparationMethod
            : 'Sun-dried and mixed with traditional spices.',
      },
      {
        'icon': Icons.soup_kitchen_rounded,
        'title': 'Prepared In',
        'subtitle': 'Artisanal Kitchen',
        'desc': 'Small batches, with care and hygiene.',
      },
      {
        'icon': Icons.takeout_dining_rounded,
        'title': 'Storage',
        'subtitle': 'Glass Jars',
        'desc': widget.product.storageInstructions.isNotEmpty
            ? widget.product.storageInstructions
            : 'Stored in food-grade, airtight jars.',
      },
      {
        'icon': Icons.hourglass_top_rounded,
        'title': 'Shelf Life',
        'subtitle': widget.product.shelfLife.isNotEmpty ? widget.product.shelfLife : '12 Months',
        'desc': 'Best before 12 months from packing date.',
      },
    ];

    return Column(
      children: timelineItems.asMap().entries.map((entry) {
        final idx = entry.key;
        final item = entry.value;
        final isLast = idx == timelineItems.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3D6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item['icon'] as IconData, color: const Color(0xFFC38D29), size: 16),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 36,
                    color: const Color(0xFFE5D5BA),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF18453B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['subtitle'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2A1C15)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['desc'] as String,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.3),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // EXPANDED 3: MASTER ARTISAN
  Widget _buildExpandedMasterArtisan() {
    return Column(
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                widget.product.artisanImage.isNotEmpty
                    ? widget.product.artisanImage
                    : 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  width: 64,
                  height: 64,
                  color: const Color(0xFFFFF3D6),
                  child: const Icon(Icons.person, color: Color(0xFFC38D29)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.artisanName,
                    style: GoogleFonts.philosopher(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF18453B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.product.artisanDescription,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9EE),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5D5BA)),
          ),
          child: const Row(
            children: [
              Icon(Icons.eco_outlined, size: 14, color: Color(0xFFC38D29)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '"Four decades of tradition in every jar."',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8C6211),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // EXPANDED 4: ROYAL RECIPES
  Widget _buildExpandedRoyalRecipes() {
    final recipeCards = [
      {
        'title': 'Avakaya with Hot Rice',
        'desc': 'A timeless classic.',
        'image': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
      },
      {
        'title': 'Avakaya Paratha',
        'desc': 'A spicy twist.',
        'image': 'assets/images/chakinalu_traditional_sankranti_spiral_snacks.jpg',
      },
      {
        'title': 'Avakaya Curd Rice',
        'desc': 'Simple & delicious.',
        'image': 'assets/images/usiri_pickle_amlagooseberry_pickle.jpg',
      },
      {
        'title': 'Avakaya Dosa',
        'desc': 'Perfect combo.',
        'image': 'assets/images/karam_janthukalu_murukku_strings_snack.jpg',
      },
    ];

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recipeCards.length,
        itemBuilder: (context, index) {
          final recipe = recipeCards[index];
          return Container(
            width: 130,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8DFD0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Image.asset(
                    recipe['image']!,
                    height: 90,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe['title']!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF18453B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        recipe['desc']!,
                        style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // EXPANDED 5: USER REVIEWS
  Widget _buildExpandedUserReviews() {
    final mockReviewsList = [
      {
        'name': 'Rohith K.',
        'time': '2 days ago',
        'rating': 5,
        'comment': 'Absolutely loved the taste! Reminds me of home.',
        'image': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
      },
      {
        'name': 'Sneha M.',
        'time': '1 week ago',
        'rating': 5,
        'comment': 'Perfect balance of sweetness and spice.',
        'image': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
      },
      {
        'name': 'Venkatesh R.',
        'time': '2 weeks ago',
        'rating': 5,
        'comment': 'Best Avakaya I have ever had. Highly recommended!',
        'image': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
      },
    ];

    return Column(
      children: [
        ...mockReviewsList.map((rev) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8DFD0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF18453B),
                  child: Text(
                    rev['name'].toString()[0],
                    style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            rev['name'].toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF18453B)),
                          ),
                          Text(
                            rev['time'].toString(),
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: List.generate(
                          5,
                          (i) => const Icon(Icons.star_rounded, size: 12, color: Color(0xFFD4AF37)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        rev['comment'].toString(),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF2A1C15), height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    rev['image'].toString(),
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            HapticFeedback.lightImpact();
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF18453B)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'View All Reviews (120+)',
                style: TextStyle(color: Color(0xFF18453B), fontWeight: FontWeight.bold, fontSize: 11),
              ),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF18453B)),
            ],
          ),
        ),
      ],
    );
  }

  // FOOTER BANNER
  Widget _buildFooterBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE2F3EC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFE0D3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco_outlined, color: Color(0xFF18453B), size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '"Bringing Andhra\'s authentic flavors to your home."',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF18453B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FIXED BOTTOM ACTION BAR
  Widget _buildFixedBottomBar() {
    final currentPrice = widget.product.getPriceForWeight(selectedWeight);

    return ListenableBuilder(
      listenable: CartManager(),
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, -4),
              )
            ],
          ),
          child: Row(
            children: [
              // Price & Weight label on left
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentPrice,
                    style: GoogleFonts.philosopher(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF18453B),
                    ),
                  ),
                  Text(
                    selectedWeight,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Action Buttons: Add to Cart + Buy Now
              Expanded(
                child: Row(
                  children: [
                    // Add to Cart Button (Outlined)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          CartManager().addToCart(
                            widget.product,
                            quantity: quantity,
                            weight: selectedWeight,
                            isTemperingRequested: isTemperingRequested,
                            chefNote: isTemperingRequested ? _chefNoteController.text : null,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Added to Cart!'),
                              backgroundColor: Color(0xFF18453B),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.shopping_cart_outlined, size: 16, color: Color(0xFF18453B)),
                        label: const Text(
                          'Add to Cart',
                          style: TextStyle(color: Color(0xFF18453B), fontWeight: FontWeight.w900, fontSize: 11),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF18453B), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Buy Now Button (Solid Gold/Amber)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          CartManager().addToCart(
                            widget.product,
                            quantity: quantity,
                            weight: selectedWeight,
                            isTemperingRequested: isTemperingRequested,
                            chefNote: isTemperingRequested ? _chefNoteController.text : null,
                          );
                          AppNavigator.push(context, const CheckoutPage());
                        },
                        icon: const Icon(Icons.bolt_rounded, size: 16, color: Colors.white),
                        label: const Text(
                          'Buy Now',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC38D29),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // CHEF CUSTOMIZATION
  Widget _buildChefCustomization() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8DFD0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.soup_kitchen_rounded, color: Color(0xFFC38D29), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('REQUEST THE CHEF', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF18453B), letterSpacing: 1)),
                    Text('Freshly tempered before packing', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Switch(
                value: isTemperingRequested,
                onChanged: (v) {
                  HapticFeedback.lightImpact();
                  setState(() {
                    isTemperingRequested = v;
                    if (!v) _chefNoteController.clear();
                  });
                },
                activeTrackColor: const Color(0xFF18453B).withValues(alpha: 0.2),
                activeThumbColor: const Color(0xFF18453B),
              ),
            ],
          ),
          if (isTemperingRequested) ...[
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                '• Added fresh curry leaves, mustard seeds & dry chillies.',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _chefNoteController,
              maxLines: 2,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Add a note (e.g., Extra spicy, less salt...)',
                hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0xFF18453B), size: 18),
                filled: true,
                fillColor: const Color(0xFFFFFBF2),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // SECRET INGREDIENT MODAL
  void _showSecretIngredient() {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFFFFFBF2),
          borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('THE SECRET BEHIND THE JAR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(widget.product.secretIngredient.image, height: 220, width: double.infinity, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 24),
                    Text(widget.product.secretIngredient.name, textAlign: TextAlign.center, style: GoogleFonts.philosopher(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFF18453B))),
                    const SizedBox(height: 12),
                    Text(
                      widget.product.secretIngredient.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF5A483C), height: 1.6),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF18453B).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_user_rounded, color: Color(0xFF18453B)),
                          SizedBox(width: 12),
                          Expanded(child: Text('This ingredient is sourced personally by our family for purity.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF18453B)))),
                        ],
                      ),
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

  // REVIEW DIALOG
  void _showReviewDialog() {
    int selectedStars = 5;
    final TextEditingController reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFFFFFBF2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Rate this Flavor', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF18453B))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                  onPressed: () => setDialogState(() => selectedStars = i + 1),
                  icon: Icon(Icons.star_rounded, size: 28, color: i < selectedStars ? const Color(0xFFD4AF37) : Colors.grey.shade300),
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reviewController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe the taste...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(dialogContext);

                final bool success = await CloudFunctionManager().submitReview(
                  productId: widget.product.name,
                  userName: user?.displayName ?? 'Anonymous',
                  rating: selectedStars.toDouble(),
                  comment: reviewController.text,
                );

                navigator.pop();
                messenger.showSnackBar(SnackBar(
                  content: Text(success ? 'Review submitted for royal approval!' : 'Failed to submit review.'),
                  backgroundColor: const Color(0xFF18453B),
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF18453B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('SUBMIT'),
            ),
          ],
        ),
      ),
    );
  }

  // IMAGE HELPER
  Widget _buildMainImageWidget(String path) {
    if (path.isEmpty) {
      return Container(color: Colors.grey.shade100, child: const Icon(Icons.image_not_supported_outlined, size: 60, color: Colors.grey));
    }
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (c, e, s) => Container(color: Colors.grey.shade100, child: const Icon(Icons.broken_image_outlined, size: 60, color: Colors.grey)),
      );
    }
    String assetPath = path;
    if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/images/$path';
    }
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (c, e, s) => Container(color: Colors.grey.shade100, child: const Icon(Icons.image_not_supported_outlined, size: 60, color: Colors.grey)),
    );
  }
}
