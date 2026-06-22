import 'package:flutter/material.dart';
import 'models.dart';

class CartManager extends ChangeNotifier {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<CartItem> _items = [];
  double _discountAmount = 0;
  String _appliedPromoCode = "";
  double _baseDeliveryFee = 40;
  double _freeThreshold = 500;
  double _packingFee = 0;
  double _gstPercentage = 0;

  List<CartItem> get items => _items;
  double get discountAmount => _discountAmount;
  String get appliedPromoCode => _appliedPromoCode;
  double get packingFee => _packingFee;
  double get gstPercentage => _gstPercentage;

  void setDeliveryConfig(double base, double threshold, double packing, double gst) {
    _baseDeliveryFee = base;
    _freeThreshold = threshold;
    _packingFee = packing;
    _gstPercentage = gst;
    notifyListeners();
  }

  bool applyPromoCode(String code) {
    if (code.toUpperCase() == "FIRST30") {
      _discountAmount = subtotal * 0.30;
      _appliedPromoCode = "FIRST30";
      notifyListeners();
      return true;
    } else if (code.toUpperCase() == "PICKLE100") {
      _discountAmount = 100;
      _appliedPromoCode = "PICKLE100";
      notifyListeners();
      return true;
    }
    return false;
  }

  void removePromoCode() {
    _discountAmount = 0;
    _appliedPromoCode = "";
    notifyListeners();
  }

  void addToCart(Product product, {int quantity = 1, String weight = '500g', bool isTemperingRequested = false, String? chefNote}) {
    int index = _items.indexWhere((item) => 
      item.product.name == product.name && 
      item.weight == weight &&
      item.isTemperingRequested == isTemperingRequested &&
      item.chefNote == chefNote
    );
    
    if (index != -1) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(
        product: product, 
        quantity: quantity, 
        weight: weight,
        isTemperingRequested: isTemperingRequested,
        chefNote: chefNote,
      ));
    }
    if (_appliedPromoCode.isNotEmpty) applyPromoCode(_appliedPromoCode);
    notifyListeners();
  }

  void removeFromCart(CartItem item) {
    _items.remove(item);
    if (_items.isEmpty) removePromoCode();
    else if (_appliedPromoCode.isNotEmpty) applyPromoCode(_appliedPromoCode);
    notifyListeners();
  }

  void updateQuantity(CartItem item, int delta) {
    item.quantity += delta;
    if (item.quantity <= 0) {
      _items.remove(item);
    }
    if (_items.isEmpty) removePromoCode();
    else if (_appliedPromoCode.isNotEmpty) applyPromoCode(_appliedPromoCode);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    removePromoCode();
    notifyListeners();
  }

  int getProductQuantity(String name, String weight) {
    int index = _items.indexWhere((item) => item.product.name == name && item.weight == weight);
    return index != -1 ? _items[index].quantity : 0;
  }

  double get subtotal {
    double total = 0;
    for (var item in _items) {
      double price = item.product.getRawPriceForWeight(item.weight);
      total += price * item.quantity;
    }
    return total;
  }

  double get deliveryFee {
    if (_items.isEmpty) return 0;
    return subtotal >= _freeThreshold ? 0 : _baseDeliveryFee;
  }

  double get freeThreshold => _freeThreshold;

  double get gstAmount {
    if (_items.isEmpty) return 0;
    return (subtotal - _discountAmount) * (_gstPercentage / 100);
  }

  double get total {
    if (_items.isEmpty) return 0;
    return (subtotal - _discountAmount) + deliveryFee + _packingFee + gstAmount;
  }

  void refreshProductData(List<Product> latestProducts) {
    bool changed = false;
    for (int i = 0; i < _items.length; i++) {
      try {
        final latest = latestProducts.firstWhere((p) => p.name == _items[i].product.name);
        if (latest != _items[i].product) {
          _items[i] = CartItem(
            product: latest,
            quantity: _items[i].quantity,
            weight: _items[i].weight,
            isTemperingRequested: _items[i].isTemperingRequested,
            chefNote: _items[i].chefNote,
          );
          changed = true;
        }
      } catch (e) {
        // Product might have been deleted, keep as is or handle
      }
    }
    if (changed) notifyListeners();
  }
}
