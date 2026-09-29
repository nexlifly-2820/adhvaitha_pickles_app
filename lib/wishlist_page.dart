import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'wishlist_manager.dart';
import 'cart_manager.dart';
import 'models.dart';
import 'main.dart';
import 'navigation_util.dart';
import 'product_detail_page.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSort = 'Sort';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WishlistManager().addListener(_update);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    WishlistManager().removeListener(_update);
    _searchController.dispose();
    super.dispose();
  }

  void _update() => setState(() {});

  List<Product> _getFilteredItems(List<Product> items) {
    List<Product> result = List.from(items);

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      result = result.where((p) =>
        p.name.toLowerCase().contains(_searchQuery) ||
        p.category.toLowerCase().contains(_searchQuery)
      ).toList();
    }

    // Filter by category
    if (_selectedCategory != 'All') {
      result = result.where((p) =>
        p.category.toLowerCase() == _selectedCategory.toLowerCase()
      ).toList();
    }

    // Sort
    if (_selectedSort == 'Price: Low to High') {
      result.sort((a, b) => a.getRawPriceForWeight(a.defaultWeight).compareTo(b.getRawPriceForWeight(b.defaultWeight)));
    } else if (_selectedSort == 'Price: High to Low') {
      result.sort((a, b) => b.getRawPriceForWeight(b.defaultWeight).compareTo(a.getRawPriceForWeight(a.defaultWeight)));
    } else if (_selectedSort == 'Name: A-Z') {
      result.sort((a, b) => a.name.compareTo(b.name));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = WishlistManager();
    final filteredItems = _getFilteredItems(wishlist.items);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      body: Stack(
        children: [
          // 1. Background Image (fits 100% inside screen bounds without overflow/cropping)
          Positioned.fill(
            child: Image.asset(
              'assets/images/wishlist_bg_screen.png',
              fit: BoxFit.fill,
              alignment: Alignment.topCenter,
              errorBuilder: (c, e, s) => Container(color: const Color(0xFFFFF8E8)),
            ),
          ),

          // 2. Foreground Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top App Bar Header with Back Button
                _buildTopAppBar(),

                // Title Banner Space (Background graphic shows "MY COLLECTION", "My Wishlist ♡", "Foods that make me happy 🍃")
                const SizedBox(height: 70),

                // "ADD ALL TO CART" Button displayed right after the header title & heart section
                if (wishlist.items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        for (var item in wishlist.items) {
                          CartManager().addToCart(item);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All favorite items added to cart!'),
                            backgroundColor: Color(0xFF18453B),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18453B),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF18453B).withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_shopping_cart_rounded, size: 14, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'ADD ALL TO CART',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 14),

                // Controls Row: Search, Sort, Category Filter
                _buildControlsRow(),

                const SizedBox(height: 16),

                // Grid Content or Empty State
                Expanded(
                  child: filteredItems.isEmpty
                      ? _buildEmptyState(wishlist.items.isEmpty)
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.60,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) => _WishlistCard(product: filteredItems[index]),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.9),
            radius: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF18453B), size: 18),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  MainScreen.of(context)?.setIndex(0);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Search Input Field
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE8DFD0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 12, color: Color(0xFF18453B), fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  hintText: 'Search in your wishlist...',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                  prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF18453B)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Sort Button Dropdown
          PopupMenuButton<String>(
            onSelected: (val) {
              HapticFeedback.lightImpact();
              setState(() => _selectedSort = val);
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Sort', child: Text('Default Sort')),
              const PopupMenuItem(value: 'Price: Low to High', child: Text('Price: Low to High')),
              const PopupMenuItem(value: 'Price: High to Low', child: Text('Price: High to Low')),
              const PopupMenuItem(value: 'Name: A-Z', child: Text('Name: A-Z')),
            ],
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE8DFD0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_vert_rounded, size: 16, color: Color(0xFF18453B)),
                  const SizedBox(width: 4),
                  Text(
                    _selectedSort == 'Sort' ? 'Sort' : _selectedSort.split(':')[0],
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF18453B)),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF18453B)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Category Filter Dropdown
          PopupMenuButton<String>(
            onSelected: (val) {
              HapticFeedback.lightImpact();
              setState(() => _selectedCategory = val);
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Categories')),
              const PopupMenuItem(value: 'Pickles', child: Text('Pickles')),
              const PopupMenuItem(value: 'Snacks', child: Text('Snacks')),
              const PopupMenuItem(value: 'Sweets', child: Text('Sweets')),
              const PopupMenuItem(value: 'Spices', child: Text('Spices')),
            ],
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE8DFD0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.grid_view_rounded, size: 16, color: Color(0xFF18453B)),
                  const SizedBox(width: 4),
                  Text(
                    _selectedCategory,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF18453B)),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF18453B)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isWishlistEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 15),
                ],
              ),
              child: const Icon(
                Icons.favorite_outline_rounded,
                size: 64,
                color: Color(0xFFC38D29),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isWishlistEmpty ? 'Your Collection is Empty ♡' : 'No matching favorites found',
              style: GoogleFonts.philosopher(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF18453B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isWishlistEmpty
                  ? 'Explore our authentic Andhra flavors and tap the heart icon to save your favorites!'
                  : 'Try adjusting your search query or category filter.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (isWishlistEmpty) {
                  MainScreen.of(context)?.setIndex(0);
                } else {
                  setState(() {
                    _searchController.clear();
                    _selectedCategory = 'All';
                    _selectedSort = 'Sort';
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF18453B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              child: Text(
                isWishlistEmpty ? 'EXPLORE PRODUCTS' : 'RESET FILTERS',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  final Product product;
  const _WishlistCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppNavigator.push(context, ProductDetailPage(product: product)),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE8DFD0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image Area with Badge & Heart
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: AspectRatio(
                    aspectRatio: 1.15,
                    child: _buildImage(product.image),
                  ),
                ),

                // Red Heart Badge on Top Right
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      WishlistManager().toggleFavorite(product);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 6),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.red,
                        size: 16,
                      ),
                    ),
                  ),
                ),

                // Leaf Icon accent at bottom right of image
                const Positioned(
                  bottom: 6,
                  right: 10,
                  child: Icon(
                    Icons.eco_outlined,
                    color: Color(0xFF18453B),
                    size: 14,
                  ),
                ),
              ],
            ),

            // Details Section
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.philosopher(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF18453B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    product.category,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price & Add to Cart Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.defaultPrice,
                        style: GoogleFonts.philosopher(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF18453B),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          CartManager().addToCart(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.name} added to cart!'),
                              backgroundColor: const Color(0xFF18453B),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF18453B),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shopping_cart_outlined, size: 11, color: Colors.white),
                              SizedBox(width: 3),
                              Text(
                                'Add to Cart',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
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
      return Container(color: Colors.grey.shade100, child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)));
    }
    if (path.startsWith('http')) {
      return Image.network(
        path, width: double.infinity, fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(color: Colors.grey.shade100, child: const Icon(Icons.broken_image_outlined, color: Colors.grey)),
      );
    }
    String assetPath = path;
    if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/images/$path';
    }
    return Image.asset(
      assetPath, width: double.infinity, fit: BoxFit.cover,
      errorBuilder: (c, e, s) => Container(color: Colors.grey.shade100, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey)),
    );
  }
}
