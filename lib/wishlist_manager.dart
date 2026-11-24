import 'package:flutter/material.dart';
import 'models.dart';
import 'product_repository.dart';
import 'product_manager.dart';

class WishlistManager extends ChangeNotifier {
  static final WishlistManager _instance = WishlistManager._internal();
  factory WishlistManager() => _instance;

  final List<Product> _wishlist = [];

  WishlistManager._internal() {
  }

  void _seedInitialFavorites() {
    if (_wishlist.isEmpty && ProductRepository.allProducts.isNotEmpty) {
      _wishlist.addAll(ProductRepository.allProducts.take(6));
    }
  }

  List<Product> get items => _wishlist;

  void toggleFavorite(Product product) {
    if (_wishlist.contains(product)) {
      _wishlist.remove(product);
    } else {
      _wishlist.add(product);
    }
    notifyListeners();
  }

  bool isFavorite(Product product) => _wishlist.contains(product);

  // ───── name based helpers (home sections use their own product models) ─────
  static String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  bool isFavoriteName(String name) {
    final String n = _norm(name);
    if (n.isEmpty) return false;
    return _wishlist.any((Product p) => _norm(p.name) == n);
  }

  /// Adds / removes a product by its name. Uses the real catalog product when it can be found,
  /// otherwise creates a light product so it still shows on the Wishlist page.
  /// Returns true when the product is now in the wishlist.
  bool toggleByName(String name, {String image = '', double price = 0, String category = 'Specials'}) {
    final String n = _norm(name);
    if (n.isEmpty) return false;
    final int at = _wishlist.indexWhere((Product p) => _norm(p.name) == n);
    if (at >= 0) {
      _wishlist.removeAt(at);
      notifyListeners();
      return false;
    }
    final List<Product> catalog = <Product>[...ProductManager().products, ...ProductRepository.allProducts];
    Product? match;
    for (final Product p in catalog) {
      if (_norm(p.name) == n) { match = p; break; }
    }
    if (match == null) {
      for (final Product p in catalog) {
        final String pn = _norm(p.name);
        if (pn.isNotEmpty && (pn.contains(n) || n.contains(pn))) { match = p; break; }
      }
    }
    match ??= Product(
      name: name,
      description: '',
      weightPriceMap: <String, double>{'250g': price > 0 ? price : 199},
      rating: 4.8,
      image: image,
      color: const Color(0xFF7A1426),
      category: category,
      secretIngredient: IngredientDetail(name: '', description: '', image: ''),
    );
    _wishlist.add(match);
    notifyListeners();
    return true;
  }
}
