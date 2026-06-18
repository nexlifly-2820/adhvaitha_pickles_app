import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';
import 'product_detail_page.dart';
import 'cart_manager.dart';
import 'navigation_util.dart';
import 'product_repository.dart';
import 'main.dart';

class ProductListingPage extends StatefulWidget {
  final String category;
  const ProductListingPage({super.key, required this.category});

  @override
  State<ProductListingPage> createState() => _ProductListingPageState();
}

class _ProductListingPageState extends State<ProductListingPage> {
  String currentSort = "Best Selling";
  late List<Product> filteredProducts;

  @override
  void initState() {
    super.initState();
    _applyFilter();
  }

  void _applyFilter() {
    setState(() {
      if (widget.category == 'All' || widget.category == 'Bestsellers' || widget.category == 'Combos') {
        filteredProducts = List.from(ProductRepository.allProducts);
        if (widget.category == 'Bestsellers') {
          filteredProducts = filteredProducts.where((p) => p.isBestSeller).toList();
        }
      } else {
        filteredProducts = ProductRepository.allProducts
            .where((p) => p.category.toLowerCase() == widget.category.toLowerCase())
            .toList();
      }
      _sortProducts(currentSort);
    });
  }

  void _sortProducts(String sort) {
    setState(() {
      currentSort = sort;
      if (sort == "Price: Low to High") {
        filteredProducts.sort((a, b) => a.getRawPriceForWeight(a.defaultWeight).compareTo(b.getRawPriceForWeight(b.defaultWeight)));
      } else if (sort == "Price: High to Low") {
        filteredProducts.sort((a, b) => b.getRawPriceForWeight(b.defaultWeight).compareTo(a.getRawPriceForWeight(a.defaultWeight)));
      } else {
        filteredProducts.sort((a, b) => b.rating.compareTo(a.rating));
      }
    });
  }

  Widget _buildSortDropdown() {
    return PopupMenuButton<String>(
      onSelected: _sortProducts,
      icon: const Icon(Icons.sort_rounded),
      itemBuilder: (context) => [
        const PopupMenuItem(value: "Best Selling", child: Text("Best Selling")),
        const PopupMenuItem(value: "Price: Low to High", child: Text("Price: Low to High")),
        const PopupMenuItem(value: "Price: High to Low", child: Text("Price: High to Low")),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(widget.category.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        ),
        actions: [
          _buildSortDropdown(),
          const GlobalCartBadge(),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(label: 'Veg Only', icon: Icons.eco_rounded, onTap: () {}),
                _FilterChip(label: 'Non-Veg', icon: Icons.kebab_dining_rounded, onTap: () {}),
                _FilterChip(label: 'Top Rated', icon: Icons.star_rounded, onTap: () {
                  setState(() {
                    filteredProducts = filteredProducts.where((p) => p.rating >= 4.8).toList();
                  });
                }),
              ],
            ),
          ),
          Expanded(
            child: filteredProducts.isEmpty
              ? const Center(child: Text('No products found in this category.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.58,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 25,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    return _ProductCard(product: filteredProducts[index]);
                  },
                ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10, top: 10, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF18453B).withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF18453B)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
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
                      padding: const EdgeInsets.all(15),
                      child: _buildProductImage(widget.product.image),
                    ),
                  ),
                  if (widget.product.isBestSeller)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFE5C76B)]),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)],
                        ),
                        child: const Text(
                          'BEST SELLER',
                          style: TextStyle(color: Color(0xFF18453B), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
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
                  Text(widget.product.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(5, (index) => Icon(
                      index < widget.product.rating.floor() ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 14,
                      color: const Color(0xFFD4AF37),
                    )),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedWeight,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                        items: widget.product.weightPriceMap.keys.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedWeight = val!;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.product.getPriceForWeight(_selectedWeight), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF18453B))),
                      ListenableBuilder(
                        listenable: CartManager(),
                        builder: (context, _) {
                          int qty = CartManager().getProductQuantity(widget.product.name, _selectedWeight);
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              CartManager().addToCart(widget.product, weight: _selectedWeight);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: qty > 0 ? 10 : 8, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF18453B), Color(0xFF276357)],
                                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [BoxShadow(color: const Color(0xFF18453B).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add, color: Colors.white, size: 14),
                                  if (qty > 0) ...[
                                    const SizedBox(width: 4),
                                    Text('$qty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }
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
}

Widget _buildProductImage(String path) {
  if (path.startsWith('http')) {
    return Image.network(
      path, 
      width: double.infinity, 
      height: double.infinity, 
      fit: BoxFit.contain, 
      errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_not_supported_outlined))
    );
  }
  return Image.asset(
    path, 
    width: double.infinity, 
    height: double.infinity, 
    fit: BoxFit.contain, 
    errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_not_supported_outlined))
  );
}
