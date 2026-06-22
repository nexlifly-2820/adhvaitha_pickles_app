import 'package:flutter/material.dart';
import 'models.dart';
import 'product_repository.dart';
import 'cart_manager.dart';
import 'dart:async';

class ProductManager extends ChangeNotifier {
  static final ProductManager _instance = ProductManager._internal();
  factory ProductManager() => _instance;
  ProductManager._internal();

  List<Product> _products = [];
  List<Product> get products => _products.isEmpty ? ProductRepository.allProducts : _products;
  
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  StreamSubscription? _subscription;

  void init() {
    _subscription?.cancel();
    _subscription = ProductRepository().getProductsStream().listen((firestoreProducts) {
      debugPrint('DEBUG: ProductManager received ${firestoreProducts.length} products from Firestore.');
      
      // MERGE LOGIC: Firestore products OVERRIDE hardcoded products with same name
      final Map<String, Product> mergedMap = {};
      
      // 1. Load Hardcoded (Baseline Catalog)
      for (var p in ProductRepository.allProducts) {
        final key = p.name.trim().toLowerCase();
        mergedMap[key] = p;
      }
      
      // 2. Apply Firestore Overrides (Dashboard Edits)
      for (var p in firestoreProducts) {
        if (p.category != 'Error') {
          final key = p.name.trim().toLowerCase();
          mergedMap[key] = p;
        }
      }
      
      _products = mergedMap.values.toList();
      _isLoading = false;
      
      ProductRepository.refreshRecentlyViewed(_products);
      CartManager().refreshProductData(_products);
      notifyListeners();
    }, onError: (e) {
      debugPrint('DEBUG: ProductManager stream error: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Product? getProductByName(String name) {
    try {
      return _products.firstWhere((p) => p.name == name);
    } catch (e) {
      return null;
    }
  }
}
