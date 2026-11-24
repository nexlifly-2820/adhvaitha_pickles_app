import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/category_lazy_susan.dart';
import 'category_deck_screen.dart';
import 'cart_manager.dart';
import 'cart_page.dart';
import 'product_detail_page.dart';
import 'product_detail_screen.dart';
import 'product_manager.dart';
import 'navigation_util.dart';
import 'main.dart';
import 'search_page.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.of(context).padding.top;
    const double bar = 46;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      body: Stack(
          children: [
            // colour now runs right up to the top of the screen
            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
              child: CategoryLazySusan(
                topInset: top + bar,
                apiUrl: 'https://admin.adhvaithafoods.in/api/shop/categories',
                onExplore: (categoryId, slug) {
                  AppNavigator.push(context, CategoryDeckScreen(
                    apiBase: 'https://admin.adhvaithafoods.in/api',
                    slug: slug,
                    cartCount: ValueNotifier<int>(CartManager().itemCount),
                    onAdd: (productId, variantId, qty) async {
                      try {
                        final product = ProductManager().products.firstWhere((p) => p.name.toLowerCase().replaceAll(' ', '-') == productId.toLowerCase());
                        if (qty > 0) {
                          CartManager().addToCart(product, quantity: qty);
                        }
                        return Future.value(true);
                      } catch (_) {
                        return Future.value(false);
                      }
                    },
                    onWishlist: (productId) async {
                      return Future.value(true);
                    },
                    onOpen: (productId) {
                      try {
                        final product = ProductManager().products.firstWhere((p) => p.name.toLowerCase().replaceAll(' ', '-') == productId.toLowerCase());
                        AppNavigator.push(context, ProductDetailPage(product: product, allProducts: ProductManager().products));
                      } catch (_) {
                        AppNavigator.push(context, ProductDetailScreen(
                          apiBase: 'https://admin.adhvaithafoods.in/api',
                          productId: productId,
                          onAddToCart: (pid, vid, qty) async => true,
                          onCart: () => AppNavigator.push(context, const CartPage()),
                        ));
                      }
                    },
                    onCart: () => AppNavigator.push(context, const CartPage()),
                  ));
                },
                onProduct: (productId) {
                  try {
                    final product = ProductManager().products.firstWhere((p) => p.name.toLowerCase().replaceAll(' ', '-') == productId.toLowerCase());
                    AppNavigator.push(context, ProductDetailPage(product: product, allProducts: ProductManager().products));
                  } catch (_) {
                    AppNavigator.push(context, ProductDetailScreen(
                      apiBase: 'https://admin.adhvaithafoods.in/api',
                      productId: productId,
                      onAddToCart: (pid, vid, qty) async => true,
                      onCart: () => AppNavigator.push(context, const CartPage()),
                    ));
                  }
                },
              ),
              ),
            ),
            // logo + search + cart, floating on the coloured background
            Positioned(
              top: top,
              left: 0,
              right: 0,
              height: bar,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          MainScreen.of(context)?.setIndex(0); // back to Home tab
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF18453B), size: 18),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => AppNavigator.push(context, const SearchPage()),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: const Icon(Icons.search_rounded, color: Color(0xFF18453B), size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const GlobalCartBadge(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
