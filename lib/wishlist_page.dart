import 'package:flutter/material.dart';
import 'home_page.dart';
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
  @override
  void initState() {
    super.initState();
    WishlistManager().addListener(_update);
  }

  @override
  void dispose() {
    WishlistManager().removeListener(_update);
    super.dispose();
  }

  void _update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final wishlist = WishlistManager();
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        title: const Text('MY WISHLIST'),
        actions: [
          if (wishlist.items.isNotEmpty)
            TextButton(
              onPressed: () {
                for (var item in wishlist.items) {
                  CartManager().addToCart(item);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All items added to cart!'), backgroundColor: Color(0xFF18453B)),
                );
              },
              child: const Text('ADD ALL', style: TextStyle(color: Color(0xFF18453B), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: wishlist.items.isEmpty 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_outline_rounded, size: 100, color: const Color(0xFF18453B).withOpacity(0.1)),
                const SizedBox(height: 24),
                const Text('No favorites yet ❤️', style: TextStyle(color: Color(0xFF2D1B12), fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('Start adding flavors you love!', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => MainScreen.of(context)?.setIndex(0),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF18453B), foregroundColor: Colors.white),
                  child: const Text('EXPLORE PRODUCTS'),
                ),
              ],
            ),
          )
        : GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 15,
              mainAxisSpacing: 20,
            ),
            itemCount: wishlist.items.length,
            itemBuilder: (context, index) => _WishlistCard(product: wishlist.items[index]),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.asset(product.image, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 10, right: 10,
                    child: GestureDetector(
                      onTap: () => WishlistManager().toggleFavorite(product),
                      child: const CircleAvatar(
                        backgroundColor: Colors.white, radius: 15,
                        child: Icon(Icons.favorite_rounded, size: 16, color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(product.defaultPrice, style: const TextStyle(color: Color(0xFF18453B), fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        CartManager().addToCart(product);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.name} added!')));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF18453B), foregroundColor: Colors.white,
                        padding: EdgeInsets.zero, textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('ADD TO CART'),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
