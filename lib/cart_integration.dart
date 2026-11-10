// cart_integration.dart — everything that connects "Add" buttons to the floating cart bar (uses cart_bar.dart)
//
//   CartService      → talks to cart_backend.js and keeps the bar in sync
//   AddToCartButton  → "ADD" that turns into "− 1 +" (with the flying photo)
//   AppShell         → your main screen: pages + floating cart bar + bottom menu with cart count
//
// pubspec.yaml:  http: ^1.2.0   google_fonts: ^6.2.1
//
// main.dart:
//   final cart = CartService(apiBase: 'https://your-api.com/api', headers: {'Authorization': 'Bearer $token'});
//   runApp(MaterialApp(home: AppShell(cart: cart, pages: [HomePage(), ShopPage(), WishlistPage(), CartPage(), ProfileDiaryScreen(...)])));
//
// In any product card / list row / product page:
//   final imgKey = GlobalKey();
//   Image.network(p.imageUrl, key: imgKey)
//   AddToCartButton(cart: cart, productId: p.id, variantId: p.variantId, name: p.name, imageUrl: p.imageUrl, price: p.price, imageKey: imgKey)
//   (get `cart` with an InheritedWidget/Provider, or pass it down — same single instance everywhere)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'widgets/cart_bar.dart';

const _red = Color(0xFF9E1424);

// ───────────────────────────── cart service ─────────────────────────────
class CartService extends ChangeNotifier {
  final String apiBase;
  final Map<String, String>? headers;
  final bar = CartBarController();
  final Map<String, int> _qty = {}; // key "productId:variantId" → qty
  CartService({required this.apiBase, this.headers}) { refresh(); }

  Map<String, String> get _h => {...?headers, 'Content-Type': 'application/json'};
  int qtyOf(String pid, String vid) => _qty['$pid:$vid'] ?? 0;

  void _apply(Map<String, dynamic> j) {
    _qty.clear();
    final items = (j['items'] as List? ?? []);
    for (final it in items) { _qty['${it['productId']}:${it['variantId']}'] = it['qty']; }
    bar.sync(
      count: j['count'] ?? 0,
      total: (j['total'] as num? ?? 0).toDouble(),
      images: items.map((e) => '${e['imageUrl']}').toList(),
    );
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      final r = await http.get(Uri.parse('$apiBase/cart'), headers: headers);
      if (r.statusCode == 200) _apply(jsonDecode(r.body));
    } catch (_) {}
  }

  /// qty = new quantity for this product (0 removes it)
  Future<String?> setQty(String pid, String vid, int qty) async {
    final old = qtyOf(pid, vid);
    _qty['$pid:$vid'] = qty; // instant UI
    notifyListeners();
    try {
      final r = await http.put(Uri.parse('$apiBase/cart/items'), headers: _h, body: jsonEncode({'productId': pid, 'variantId': vid, 'qty': qty}));
      final j = jsonDecode(r.body);
      if (r.statusCode != 200) { _qty['$pid:$vid'] = old; notifyListeners(); return j['error'] ?? 'Could not update cart'; }
      _apply(j);
      return null;
    } catch (_) {
      _qty['$pid:$vid'] = old;
      notifyListeners();
      return 'No internet connection';
    }
  }
}

// ───────────────────────────── ADD → − n + button ─────────────────────────────
class AddToCartButton extends StatelessWidget {
  final CartService cart;
  final String productId, variantId, name, imageUrl;
  final double price;
  final GlobalKey? imageKey; // the product photo, so it can fly into the bar
  const AddToCartButton({super.key, required this.cart, required this.productId, required this.variantId, required this.name,
      required this.imageUrl, required this.price, this.imageKey});

  Future<void> _change(BuildContext context, int to, {bool added = false}) async {
    HapticFeedback.selectionClick();
    final err = await cart.setQty(productId, variantId, to);
    if (!context.mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), behavior: SnackBarBehavior.floating));
      return;
    }
    // server already synced count/total; this plays the fly + bounce + toast
    if (added) cart.bar.added(context, name: name, imageUrl: imageUrl, price: 0, qty: 0, fromKey: imageKey);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: cart,
        builder: (context, _) {
          final q = cart.qtyOf(productId, variantId);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 36,
            constraints: const BoxConstraints(minWidth: 84),
            decoration: BoxDecoration(
              color: q > 0 ? _red : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _red, width: 1.5),
            ),
            child: q == 0
                ? InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _change(context, 1, added: true),
                    child: Center(child: Text('ADD', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: _red))),
                  )
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    _btn(Icons.remove_rounded, () => _change(context, q - 1)),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (w, a) => ScaleTransition(scale: a, child: w),
                      child: Text('$q', key: ValueKey(q), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                    _btn(Icons.add_rounded, () => _change(context, q + 1, added: true)),
                  ]),
          );
        },
      );

  Widget _btn(IconData i, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: SizedBox(width: 30, height: 36, child: Icon(i, size: 17, color: Colors.white)),
      );
}

// ───────────────────────────── main shell: pages + cart bar + bottom menu ─────────────────────────────
class AppShell extends StatefulWidget {
  final CartService cart;
  final List<Widget> pages; // Home, Shop, Wishlist, Cart, Profile
  const AppShell({super.key, required this.cart, required this.pages});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;
  static const _cartTab = 3;
  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.shopping_bag_rounded, 'Shop'),
    (Icons.favorite_border_rounded, 'Wishlist'),
    (Icons.shopping_cart_rounded, 'Cart'),
    (Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EF),
      body: Stack(children: [
        IndexedStack(index: _tab, children: widget.pages),
        // floating cart bar — hidden on the Cart tab itself
        if (_tab != _cartTab)
          Positioned(left: 12, right: 12, bottom: 90 + bottom,
              child: CartBar(controller: widget.cart.bar, onViewCart: () => setState(() => _tab = _cartTab))),
        Positioned(left: 12, right: 12, bottom: 12 + bottom, child: _menu()),
      ]),
    );
  }

  Widget _menu() => Container(
        height: 66,
        decoration: BoxDecoration(color: const Color(0xFF2A0A10), borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.6), blurRadius: 26, offset: const Offset(0, 14), spreadRadius: -12)]),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          for (int i = 0; i < _items.length; i++)
            GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); setState(() => _tab = i); if (i == _cartTab) widget.cart.refresh(); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: i == _tab ? const LinearGradient(colors: [Color(0xFFFFD27A), Color(0xFFF2A93B)]) : null,
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Stack(clipBehavior: Clip.none, children: [
                    Icon(_items[i].$1, size: 20, color: i == _tab ? const Color(0xFF2A0A10) : const Color(0xFFC9A98A)),
                    if (i == _cartTab) Positioned(right: -10, top: -6, child: CartCountBadge(controller: widget.cart.bar)),
                  ]),
                  Text(_items[i].$2, style: GoogleFonts.poppins(fontSize: 10, fontWeight: i == _tab ? FontWeight.w700 : FontWeight.w500,
                      color: i == _tab ? const Color(0xFF2A0A10) : const Color(0xFFC9A98A))),
                ]),
              ),
            ),
        ]),
      );
}
