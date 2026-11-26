import 'package:flutter/material.dart';
import 'models.dart';
import 'widgets/cart_bar.dart';
import 'widgets/offers_section.dart';
import 'order_manager.dart';

class CartManager extends ChangeNotifier {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  @override
  void notifyListeners() {
    super.notifyListeners();
    try {
      globalCartBar.sync(
        count: itemCount,
        total: total,
        images: _items.map((i) => i.product.image).toList(),
      );
    } catch (_) {}
  }

  final List<CartItem> _items = [];
  double _discountAmount = 0;
  String _appliedPromoCode = "";
  double _baseDeliveryFee = 40;
  double _freeThreshold = 500;
  double _packingFee = 0;
  double _gstPercentage = 0;

  List<CartItem> get items => _items;
  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);
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

  /// Coupons come from the admin "Home Offers" list (same cards as the home screen).
  /// Returns false when the code doesn't exist or the cart is below its minimum.
  bool applyPromoCode(String code) {
    final HomeOffer? o = HomeOffersStore.find(code);
    final double? d = (o == null || promoProblem(code) != null) ? null : o.discountFor(subtotal, deliveryFee);
    if (o == null || d == null) {
      if (_appliedPromoCode.isNotEmpty && _appliedPromoCode == code.trim().toUpperCase()) {
        _discountAmount = 0;
        _appliedPromoCode = "";
        notifyListeners();
      }
      return false;
    }
    _discountAmount = d;
    _appliedPromoCode = o.code;
    notifyListeners();
    return true;
  }

  /// Why a code can't be used right now (null = it can).
  String? promoProblem(String code) {
    final HomeOffer? o = HomeOffersStore.find(code);
    if (o == null) return 'This coupon code is not valid';
    final String? d = o.dateProblem();
    if (d != null) return d;
    if (o.firstOrderOnly && OrderManager().orders.any((Order x) => !RegExp('fail|cancel|pending', caseSensitive: false).hasMatch(x.status))) {
      return '${o.code} is only for your first order';
    }
    if (o.category.isNotEmpty) {
      final String c = o.category.toLowerCase().replaceAll(RegExp(r's$'), '');
      final bool has = _items.any((CartItem i) => '${i.product.category} ${i.product.name}'.toLowerCase().contains(c));
      if (!has) return '${o.code} is only for ${o.category}';
    }
    if (subtotal < o.minOrder) return 'Add ₹${(o.minOrder - subtotal).ceil()} more to use ${o.code} (min order ${o.minText})';
    return null;
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
    if (_items.isEmpty) {
      removePromoCode();
    } else if (_appliedPromoCode.isNotEmpty) {
      applyPromoCode(_appliedPromoCode);
    }
    notifyListeners();
  }

  void updateQuantity(CartItem item, int delta) {
    item.quantity += delta;
    if (item.quantity <= 0) {
      _items.remove(item);
    }
    if (_items.isEmpty) {
      removePromoCode();
    } else if (_appliedPromoCode.isNotEmpty) {
      applyPromoCode(_appliedPromoCode);
    }
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

  void decrementProductQuantity(String name, String weight) {
    int index = _items.indexWhere((item) => item.product.name == name && item.weight == weight);
    if (index != -1) {
      updateQuantity(_items[index], -1);
    }
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
