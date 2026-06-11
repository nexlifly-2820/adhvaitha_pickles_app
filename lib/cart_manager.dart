import 'package:flutter/material.dart';
import 'models.dart';

class CartManager extends ChangeNotifier {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<CartItem> _items = [];
  double _discountAmount = 0;
  String _appliedPromoCode = "";

  List<CartItem> get items => _items;
  double get discountAmount => _discountAmount;
  String get appliedPromoCode => _appliedPromoCode;

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

  void addToCart(Product product, {int quantity = 1, String weight = '500g'}) {
    int index = _items.indexWhere((item) => item.product.name == product.name && item.weight == weight);
    
    if (index != -1) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity, weight: weight));
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

  double get subtotal {
    double total = 0;
    for (var item in _items) {
      double price = double.parse(item.product.price.replaceAll('₹', ''));
      total += price * item.quantity;
    }
    return total;
  }

  double get deliveryFee => _items.isEmpty ? 0 : 40;
  double get total => (subtotal - _discountAmount) + deliveryFee;
}
