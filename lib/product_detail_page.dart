import 'package:flutter/material.dart';
import 'product_detail_screen.dart';
import 'models.dart';
import 'cart_manager.dart';
import 'navigation_util.dart';
import 'cart_page.dart';
import 'recently_viewed_store.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;
  final List<Product> allProducts;
  
  const ProductDetailPage({super.key, required this.product, this.allProducts = const []});

  @override
  Widget build(BuildContext context) {
    RecentlyViewedStore().record(product);
    return ProductDetailScreen(
      apiBase: 'https://admin.adhvaithafoods.in/api',
      productId: product.name.toLowerCase().replaceAll(' ', '-'),
      onAddToCart: (pid, vid, qty) async {
        CartManager().addToCart(product, quantity: qty);
        return true;
      },
      onCart: () => AppNavigator.push(context, const CartPage()),
    );
  }
}
