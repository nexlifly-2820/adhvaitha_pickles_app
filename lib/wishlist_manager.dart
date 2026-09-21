import 'package:flutter/material.dart';
import 'models.dart';
import 'product_repository.dart';

class WishlistManager extends ChangeNotifier {
  static final WishlistManager _instance = WishlistManager._internal();
  factory WishlistManager() => _instance;

  final List<Product> _wishlist = [];

  WishlistManager._internal() {
    _seedInitialFavorites();
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
}
