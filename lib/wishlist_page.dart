import 'package:flutter/material.dart';
import 'home_page.dart';
import 'wishlist_manager.dart';
import 'cart_manager.dart';
import 'models.dart';
import 'main.dart';

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
                  const SnackBar(content: Text('All items added to cart!'), backgroundColor: Color(0xFFD35400)),
                );
              },
              child: const Text('ADD ALL TO CART', style: TextStyle(color: Color(0xFFD35400), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: wishlist.items.isEmpty 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_outline, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('Your wishlist is empty', style: TextStyle(color: Colors.grey, fontSize: 18)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => MainScreen.of(context)?.setIndex(0),
                  child: const Text('EXPLORE PRODUCTS'),
                ),
              ],
            ),
          )
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.62,
              crossAxisSpacing: 16,
              mainAxisSpacing: 20,
            ),
            itemCount: wishlist.items.length,
            itemBuilder: (context, index) => AdvanceProductCard(product: wishlist.items[index]),
          ),
    );
  }
}
