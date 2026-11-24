import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'category_deck_screen.dart';
import 'cart_manager.dart';
import 'product_manager.dart';
import 'product_lookup.dart';
import 'navigation_util.dart';
import 'cart_page.dart';
import 'product_detail_page.dart';
import 'product_detail_screen.dart';
import 'main.dart';

class ProductListingPage extends StatefulWidget {
  final String category;
  const ProductListingPage({super.key, required this.category});

  @override
  State<ProductListingPage> createState() => _ProductListingPageState();
}

class _ProductListingPageState extends State<ProductListingPage> {
  late final ValueNotifier<int> _cartCount;

  @override
  void initState() {
    super.initState();
    _cartCount = ValueNotifier(CartManager().itemCount);
    CartManager().addListener(_onCartChanged);
  }

  @override
  void dispose() {
    CartManager().removeListener(_onCartChanged);
    _cartCount.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    _cartCount.value = CartManager().itemCount;
  }

  @override
  Widget build(BuildContext context) {
    final slug = widget.category.toLowerCase().replaceAll(' & ', '-').replaceAll(' ', '-');
    return CategoryDeckScreen(
      apiBase: 'https://admin.adhvaithafoods.in/api',
      slug: slug,
      cartCount: _cartCount,
      onAdd: (productId, variantId, qty) async {
        try {
          final product = findCatalogProduct(productId.replaceAll('-', ' '))!;
          if (qty > 0) {
            CartManager().addToCart(product, quantity: qty);
          }
          return Future.value(true);
        } catch (_) {
          if (qty > 0) addToCartByName(productId.replaceAll('-', ' ').trim(), quantity: qty);
          return Future.value(true);
        }
      },
      onWishlist: (productId) async {
        return Future.value(true);
      },
      onOpen: (productId) {
        try {
          final product = findCatalogProduct(productId.replaceAll('-', ' '))!;
          AppNavigator.push(context, ProductDetailPage(product: product, allProducts: ProductManager().products));
        } catch (_) {
          AppNavigator.push(context, ProductDetailScreen(
            apiBase: 'https://admin.adhvaithafoods.in/api',
            productId: productId,
                        onCart: () => AppNavigator.push(context, const CartPage()),
          ));
        }
      },
      onCart: () => AppNavigator.push(context, const CartPage()),
    );
  }
}
