import 'package:flutter/material.dart';
import 'models.dart';
import 'cart_manager.dart';
import 'wishlist_manager.dart';
import 'checkout_page.dart';
import 'navigation_util.dart';
import 'product_repository.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int quantity = 1;
  late String selectedWeight;

  @override
  void initState() {
    super.initState();
    selectedWeight = widget.product.defaultWeight;
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = WishlistManager();
    final bool isFav = wishlist.isFavorite(widget.product);

    // Filter products for recommendations
    final recommendations = ProductRepository.allProducts.where((p) =>
      widget.product.pairings.contains(p.name)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 450,
            pinned: true,
            backgroundColor: const Color(0xFFFFF8E8),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: widget.product.name,
                child: Container(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Image.asset(widget.product.image, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_not_supported_outlined, size: 100, color: Colors.grey))),
                ),
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.9),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF18453B), size: 18),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: IconButton(
                    onPressed: () {
                      wishlist.toggleFavorite(widget.product);
                      setState(() {});
                    },
                    icon: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? Colors.red : const Color(0xFF18453B),
                      size: 20),
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF8E8),
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFF18453B).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text(widget.product.category.toUpperCase(), style: const TextStyle(color: Color(0xFF18453B), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFD4AF37), size: 20),
                          Text(' ${widget.product.rating}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(' (120+ Reviews)', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(widget.product.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF18453B), fontFamily: 'Philosopher')),
                  const SizedBox(height: 10),
                  Text(widget.product.getPriceForWeight(selectedWeight), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFFD4AF37))),
                  const SizedBox(height: 25),
                  const Text('DESCRIPTION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Color(0xFF18453B))),
                  const SizedBox(height: 10),
                  Text(widget.product.description, style: TextStyle(fontSize: 15, color: const Color(0xFF2D1B12).withOpacity(0.7), height: 1.6)),
                  
                  const SizedBox(height: 30),
                  const Text('SELECT WEIGHT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Color(0xFF18453B))),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 12,
                    children: widget.product.weightPriceMap.keys.map((w) => _WeightOption(
                      label: w, 
                      isSelected: selectedWeight == w, 
                      onTap: () => setState(() => selectedWeight = w)
                    )).toList(),
                  ),

                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
                        child: Row(
                          children: [
                            IconButton(onPressed: () => setState(() => quantity > 1 ? quantity-- : null), icon: const Icon(Icons.remove, size: 20)),
                            Text('$quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(onPressed: () => setState(() => quantity++), icon: const Icon(Icons.add, size: 20)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            CartManager().addToCart(widget.product, quantity: quantity, weight: selectedWeight);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('${widget.product.name} added to cart!'),
                              backgroundColor: const Color(0xFF18453B),
                              behavior: SnackBarBehavior.floating,
                            ));
                          },
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF18453B), Color(0xFF276357)]),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [BoxShadow(color: const Color(0xFF18453B).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                            ),
                            alignment: Alignment.center,
                            child: const Text('ADD TO CART', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // PAIR WITH RECOMMENDATIONS
                  if (recommendations.isNotEmpty) ...[
                    const SizedBox(height: 45),
                    const Text('PERFECT WITH', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Color(0xFF18453B))),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: recommendations.length,
                        itemBuilder: (context, index) {
                          final p = recommendations[index];
                          return GestureDetector(
                            onTap: () => AppNavigator.push(context, ProductDetailPage(product: p)),
                            child: Container(
                              width: 250,
                              margin: const EdgeInsets.only(right: 15),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(p.image, width: 80, height: 80, fit: BoxFit.cover),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text(p.defaultPrice, style: const TextStyle(color: Color(0xFF18453B), fontWeight: FontWeight.w900)),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                  const Text('INGREDIENTS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Color(0xFF18453B))),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 10,
                    children: widget.product.ingredients.map((i) => Chip(
                      label: Text(i, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: const Color(0xFF18453B).withOpacity(0.1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    )).toList(),
                  ),

                  const SizedBox(height: 45),
                  const Text('BEHIND THE JAR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Color(0xFF18453B))),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
                      boxShadow: [BoxShadow(color: const Color(0xFF18453B).withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      children: [
                        _BehindItem(icon: Icons.place_rounded, title: 'Origin', value: widget.product.origin),
                        const Divider(height: 40),
                        _BehindItem(icon: Icons.auto_awesome, title: 'Preparation', value: widget.product.preparationMethod),
                        const Divider(height: 40),
                        _BehindItem(icon: Icons.hourglass_bottom_rounded, title: 'Shelf Life', value: widget.product.shelfLife),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
        color: const Color(0xFFFFF8E8),
        child: GestureDetector(
          onTap: () {
            CartManager().addToCart(widget.product, quantity: quantity, weight: selectedWeight);
            AppNavigator.push(context, const CheckoutPage());
          },
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFE5C76B)]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            alignment: Alignment.center,
            child: const Text('BUY NOW', style: TextStyle(color: Color(0xFF18453B), fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}

class _WeightOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _WeightOption({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF18453B) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? const Color(0xFF18453B) : Colors.grey.shade200),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _BehindItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _BehindItem({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF18453B).withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFFD4AF37), size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 10, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D1B12), height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
