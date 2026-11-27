import 'package:flutter/material.dart';
import 'royal_cart_screen.dart';
import 'cart_manager.dart';
import 'models.dart';
import 'product_manager.dart';
import 'checkout_page.dart';
import 'navigation_util.dart';
import 'product_detail_page.dart';
import 'product_detail_screen.dart';
import 'main.dart';
import 'cart_integration.dart';
import 'product_lookup.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cartService = ManagerCartService();
    return RoyalCartScreen(
      cart: cartService,
      onCheckout: (bill) {
        AppNavigator.push(context, const CheckoutPage());
      },
      onOpenProduct: (pid) {
        if (pid.toLowerCase().contains('combo box') || pid.contains(' + ')) return; // combo boxes and pairs have no product page
        try {
          final product = ProductManager().products.firstWhere((p) => p.name.toLowerCase().replaceAll(' ', '-') == pid.toLowerCase());
          AppNavigator.push(context, ProductDetailPage(product: product, allProducts: ProductManager().products));
        } catch (_) {
          AppNavigator.push(context, ProductDetailScreen(
            apiBase: 'https://admin.adhvaithafoods.in/api',
            productId: pid,
            onAddToCart: (pid, vid, qty) async => true,
            onCart: () => AppNavigator.push(context, const CartPage()),
          ));
        }
      },
      onShop: () => MainScreen.of(context)?.setIndex(1),
      // opened as a page → go back; opened as the Cart tab → go to Home
      onBack: () {
        final NavigatorState nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.pop();
        } else {
          MainScreen.of(context)?.selectTab('home');
        }
      },
    );
  }
}

class ManagerCartService extends CartService {
  ManagerCartService() : super(apiBase: 'https://admin.adhvaithafoods.in/api') {
    CartManager().addListener(_sync);
    _sync();
  }

  void _sync() {
    bar.sync(
      count: CartManager().itemCount,
      total: CartManager().subtotal,
      images: CartManager().items.map((e) => bestImageFor(e.product.name, e.product.image)).toList(),
    );
    notifyListeners();
  }

  // the cart screen sends variantId = "weight::note" so each line (size / combo) is matched exactly
  static bool _same(CartItem i, String pid, String vid) {
    final bool name = i.product.name.toLowerCase() == pid.toLowerCase() || i.product.name.toLowerCase().replaceAll(' ', '-') == pid.toLowerCase();
    if (!name) return false;
    if (!vid.contains('::')) return true;
    return vid == '${i.weight}::${i.chefNote ?? ''}';
  }

  @override
  int qtyOf(String pid, String vid) {
    try {
      final item = CartManager().items.firstWhere((i) => _same(i, pid, vid));
      return item.quantity;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<String?> setQty(String pid, String vid, int qty) async {
    try {
      final item = CartManager().items.firstWhere((i) => _same(i, pid, vid));
      if (qty <= 0) {
        CartManager().removeFromCart(item);
      } else {
        item.quantity = qty;
        CartManager().notifyListeners();
      }
      _sync();
      return null;
    } catch (_) {
      if (qty > 0) {
        try {
          final product = ProductManager().products.firstWhere((p) => p.name.toLowerCase() == pid.toLowerCase() || p.name.toLowerCase().replaceAll(' ', '-') == pid.toLowerCase());
          CartManager().addToCart(product, quantity: qty);
          _sync();
          return null;
        } catch (_) {}
      }
      return 'Could not update cart';
    }
  }
}
