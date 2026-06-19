import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'models.dart';
import 'product_detail_page.dart';
import 'cart_manager.dart';
import 'navigation_util.dart';
import 'product_repository.dart';
import 'app_config_repository.dart';
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
            (c) => c['label'].toString().toLowerCase() == widget.category.toLowerCase(),
            orElse: () => {},
          );
        });
      }
    });

    // 2. Fetch Products
    ProductRepository().getProductsStream().listen((products) {
      if (mounted) {
        setState(() {
          allCategoryProducts = products.where((p) {
            if (widget.category == 'All') return true;
            if (widget.category == 'Bestsellers') return p.isBestSeller;
            return p.category.toLowerCase() == widget.category.toLowerCase();
          }).toList();
          _applyFilters();
          _isLoading = false;
        });
      }
    });
  }

  void _applyFilters() {
    setState(() {
      displayedProducts = allCategoryProducts.where((p) {
        final bool matchesVeg = showVegOnly == null || (showVegOnly! ? p.isVeg : !p.isVeg);
        final bool matchesSub = activeSubCategory == null || p.subCategory == activeSubCategory;
        return matchesVeg && matchesSub;
      }).toList();
      _sortProducts(currentSort);
    });
  }

  void _sortProducts(String sort) {
    setState(() {
      currentSort = sort;
      if (sort == "Price: Low to High") {
        displayedProducts.sort((a, b) => a.getRawPriceForWeight(a.defaultWeight).compareTo(b.getRawPriceForWeight(b.defaultWeight)));
      } else if (sort == "Price: High to Low") {
        displayedProducts.sort((a, b) => b.getRawPriceForWeight(b.defaultWeight).compareTo(a.getRawPriceForWeight(a.defaultWeight)));
      } else {
        displayedProducts.sort((a, b) => b.rating.compareTo(a.rating));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final subCategories = allCategoryProducts.map((p) => p.subCategory).toSet().toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          if (!_isLoading) ...[
            _buildCategoryHero(),
            _buildStickyFilterBar(subCategories),
            _buildProductGrid(),
          ] else
            _buildShimmerGrid(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: const Color(0xFFFFF8E8),
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
      ),
      title: Text(
        widget.category.toUpperCase(),
        style: GoogleFonts.philosopher(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1),
      ),
      actions: [
        _buildSortButton(),
        const GlobalCartBadge(),
      ],
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<String>(
      onSelected: _sortProducts,
      icon: const Icon(Icons.sort_rounded),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      itemBuilder: (context) => [
        const PopupMenuItem(value: "Best Selling", child: Text("Best Selling")),
        const PopupMenuItem(value: "Price: Low to High", child: Text("Price: Low to High")),
        const PopupMenuItem(value: "Price: High to Low", child: Text("Price: High to Low")),
      ],
    );
  }

  Widget _buildCategoryHero() {
    final bannerImg = categoryMeta?['banner_img']?.toString() ?? categoryMeta?['img']?.toString() ?? '';
    final tagline = categoryMeta?['tagline']?.toString() ?? 'Authentic Heritage Recipes';
    final description = categoryMeta?['description']?.toString() ?? 'Experience the ancestral flavors of Coastal Andhra, preserved using traditional methods.';

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 220,
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                children: [
                  Positioned.fill(child: _buildBannerImage(bannerImg)),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                          colors: [const Color(0xFF18453B).withOpacity(0.9), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tagline.toUpperCase(), style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2)),
                        const SizedBox(height: 4),
                        Text(widget.category, style: GoogleFonts.philosopher(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 8),
                        Text(description, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
        ],
      ),
    );
  }

  Widget _buildStickyFilterBar(List<String> subCategories) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyFilterDelegate(
        child: Container(
          color: const Color(0xFFFFF8E8),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Veg/Non-Veg Toggle
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
                    const VerticalDivider(width: 20, color: Colors.grey),
                    // Dynamic Subcategories
                    ...subCategories.map((s) => _FilterChip(
                      label: s,
                      isSelected: activeSubCategory == s,
                      onTap: () => setState(() {
                        activeSubCategory = (activeSubCategory == s) ? null : s;
                        _applyFilters();
                      }),
                    )),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 10, 25, 0),
                child: Row(
                  children: [
                    Text(
                      '${displayedProducts.length} AUTHENTIC VARIETIES', 
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)
                    ),
                    const Spacer(),
                    if (showVegOnly != null || activeSubCategory != null)
                      GestureDetector(
                        onTap: () => setState(() {
                          showVegOnly = null;
                          activeSubCategory = null;
                          _applyFilters();
                        }),
                        child: const Text('CLEAR ALL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFD4AF37), letterSpacing: 1)),
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

  Widget _buildProductGrid() {
    if (displayedProducts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 100),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 60, color: const Color(0xFF18453B).withOpacity(0.1)),
              const SizedBox(height: 15),
              const Text('No flavors match these filters.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.55,
          crossAxisSpacing: 15,
          mainAxisSpacing: 25,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _ProductCard(product: displayedProducts[index]).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0),
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
          childAspectRatio: 0.55,
          crossAxisSpacing: 15,
          mainAxisSpacing: 25,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => Shimmer.fromColors(
            baseColor: Colors.white,
            highlightColor: const Color(0xFFFFF8E8),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
            ),
          ),
          childCount: 6,
        ),
      ),
    );
  }

  Widget _buildBannerImage(String path) {
    if (path.isEmpty) return Container(color: const Color(0xFF18453B));
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: const Color(0xFF18453B)));
    }
    return Image.asset(path, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: const Color(0xFF18453B)));
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF18453B) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? const Color(0xFF18453B) : const Color(0xFF18453B).withOpacity(0.1)),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF18453B).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF18453B)), const SizedBox(width: 8)],
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF18453B))),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppNavigator.push(context, ProductDetailPage(product: widget.product)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: Center(child: _buildImage(widget.product.image)),
                    ),
                  ),
                  if (widget.product.isBestSeller)
                    Positioned(
                      top: 10, left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFE5C76B)]),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('BEST SELLER', style: TextStyle(color: Color(0xFF18453B), fontSize: 7, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  Positioned(
                    top: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: widget.product.isVeg ? Colors.green : Colors.red, width: 1),
                      ),
                      child: Icon(Icons.circle, size: 6, color: widget.product.isVeg ? Colors.green : Colors.red),
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
                  Text(widget.product.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF2D1B12)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 12, color: Color(0xFFD4AF37)),
                      Text(' ${widget.product.rating}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedWeight,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 14),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                        items: widget.product.weightPriceMap.keys.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                        onChanged: (val) => setState(() => _selectedWeight = val!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.product.getPriceForWeight(_selectedWeight), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF18453B))),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          CartManager().addToCart(widget.product, weight: _selectedWeight);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF18453B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 14),
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
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported_outlined, color: Colors.grey));
    }
    return Image.asset(path, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported_outlined, color: Colors.grey));
  }
}

class _StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickyFilterDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  double get maxExtent => 100;
  @override
  double get minExtent => 100;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}
