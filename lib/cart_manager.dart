import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'product_lookup.dart';
import 'shop_catalog.dart';
import 'user_manager.dart';
import 'models.dart';
import 'widgets/cart_bar.dart';
import 'widgets/offers_section.dart';
import 'order_manager.dart';

// ---------- Amma's Combo Box in the cart ----------
// A combo box is ONE cart line. Its jars live in chefNote as "COMBO:{size, ids, jars}";
// the server works out the real price from the Combo Box settings at checkout.
const String kComboNote = 'COMBO:';

Map<String, dynamic>? comboSpec(CartItem i) {
  final String n = i.chefNote ?? '';
  if (!n.startsWith(kComboNote)) return null;
  try {
    final dynamic j = jsonDecode(n.substring(kComboNote.length));
    if (j is Map) return Map<String, dynamic>.from(j);
  } catch (_) {}
  return null;
}

List<String> comboJars(CartItem i) {
  final Map<String, dynamic>? p = pairSpec(i);
  if (p != null) return <String>['${p['a'] ?? ''}', '${p['b'] ?? ''}'];
  return ((comboSpec(i)?['jars'] as List?) ?? const <dynamic>[]).map((dynamic e) => '$e').toList();
}

// Art of Pairing couple = ONE line ("A + B", combo price). chefNote = "PAIR:{id, label, a, b}"
const String kPairNote = 'PAIR:';
Map<String, dynamic>? pairSpec(CartItem i) {
  final String n = i.chefNote ?? '';
  if (!n.startsWith(kPairNote)) return null;
  try {
    final dynamic j = jsonDecode(n.substring(kPairNote.length));
    if (j is Map) return Map<String, dynamic>.from(j);
  } catch (_) {}
  return null;
}
bool isBundle(CartItem i) => comboSpec(i) != null || pairSpec(i) != null;

Product comboProduct({required String name, required String image, required String size, required double price}) => Product(
      name: name,
      description: 'Combo box',
      weightPriceMap: <String, double>{size: price},
      rating: 5,
      image: image,
      color: const Color(0xFF7A1426),
      category: 'Combo',
      secretIngredient: IngredientDetail(name: '', description: '', image: ''),
    );

class CartManager extends ChangeNotifier {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  // ───── every customer has their own cart: saved on the phone + on our server (same on every phone) ─────
  static const String _api = 'https://admin.adhvaithafoods.in/api/me/cart';
  Timer? _saveTimer;
  bool _restoring = false;
  String _owner = '';

  String get _key => 'cart_${UserManager().currentUserId}';

  List<Map<String, dynamic>> _toJson() => _items
      .map((CartItem i) => <String, dynamic>{
            'name': i.product.name,
            'image': i.product.image,
            'weight': i.weight,
            'qty': i.quantity,
            'price': i.product.weightPriceMap[i.weight] ?? (i.product.weightPriceMap.isEmpty ? 0 : i.product.weightPriceMap.values.first),
            'category': i.product.category,
            'tempering': i.isTemperingRequested,
            'note': i.chefNote ?? '',
            if (comboSpec(i) != null) 'combo': comboSpec(i),
            if (pairSpec(i) != null) 'pair': pairSpec(i),
          })
      .toList();

  /// Rebuild a product from what was saved (latest catalogue data first, so prices are current).
  Product _productFor(Map<dynamic, dynamic> x) {
    final String name = '${x['name']}';
    final double price = x['price'] is num ? (x['price'] as num).toDouble() : 0;
    final String weight = '${x['weight'] ?? ''}';
    final Product? live = ShopCatalog.product(name) ?? findCatalogProduct(name);
    if (live != null) {
      if (weight.isEmpty || live.weightPriceMap.containsKey(weight) || price <= 0) return live;
      return live.copyWith(weightPriceMap: <String, double>{...live.weightPriceMap, weight: price});
    }
    return productFor(name,
        image: '${x['image'] ?? ''}',
        price: price,
        weights: weight.isEmpty || price <= 0 ? const <String, double>{} : <String, double>{weight: price},
        category: '${x['category'] ?? 'Specials'}');
  }

  List<CartItem> _fromJson(List<dynamic> list) {
    final List<CartItem> out = <CartItem>[];
    for (final dynamic x in list) {
      if (x is! Map || '${x['name'] ?? ''}'.trim().isEmpty) continue;
      final int q = x['qty'] is num ? (x['qty'] as num).toInt() : int.tryParse('${x['qty']}') ?? 1;
      final bool isCombo = '${x['note'] ?? ''}'.startsWith(kComboNote) || '${x['note'] ?? ''}'.startsWith(kPairNote);
      out.add(CartItem(
        product: isCombo
            ? comboProduct(name: '${x['name']}', image: '${x['image'] ?? ''}', size: '${x['weight'] ?? ''}', price: x['price'] is num ? (x['price'] as num).toDouble() : 0)
            : _productFor(x),
        quantity: q.clamp(1, 50),
        weight: '${x['weight'] ?? '500g'}',
        isTemperingRequested: x['tempering'] == true,
        chefNote: '${x['note'] ?? ''}'.isEmpty ? null : '${x['note']}',
      ));
    }
    return out;
  }

  static String _k(CartItem i) => '${i.product.name.toLowerCase()}|${i.weight}|${i.isTemperingRequested}|${i.chefNote ?? ''}';

  /// Loads this customer's cart: the phone copy + the server copy, merged (nothing is lost).
  Future<void> loadForUser() async {
    final String uid = UserManager().currentUserId;
    _restoring = true;
    try {
      await ShopCatalog.load();
      final SharedPreferences sp = await SharedPreferences.getInstance();
      final List<CartItem> merged = <CartItem>[];
      void addAll(List<CartItem> list) {
        for (final CartItem i in list) {
          final int at = merged.indexWhere((CartItem m) => _k(m) == _k(i));
          if (at < 0) {
            merged.add(i);
          } else if (i.quantity > merged[at].quantity) {
            merged[at].quantity = i.quantity;
          }
        }
      }
      // items added on this phone before logging in (guest cart) are kept
      if (_owner.isNotEmpty && _owner != uid) _items.clear();
      addAll(List<CartItem>.from(_items));
      final String? raw = sp.getString(_key);
      if (raw != null && raw.isNotEmpty) addAll(_fromJson(jsonDecode(raw) as List<dynamic>));
      if (UserManager().hasSession) {
        try {
          final http.Response r = await http.get(Uri.parse(_api), headers: UserManager().authHeaders).timeout(const Duration(seconds: 15));
          if (r.statusCode == 200) {
            final dynamic j = jsonDecode(r.body);
            if (j is Map && j['items'] is List) addAll(_fromJson(j['items'] as List<dynamic>));
          }
        } catch (_) {}
      }
      _owner = uid;
      _items
        ..clear()
        ..addAll(merged);
      if (_appliedPromoCode.isNotEmpty) applyPromoCode(_appliedPromoCode);
    } catch (_) {}
    _restoring = false;
    notifyListeners(); // saves the merged cart to the phone and the server
  }

  /// On logout: empty this phone's cart (it stays saved on the server for that customer).
  void resetForLogout() {
    _saveTimer?.cancel();
    _restoring = true;
    _items.clear();
    _discountAmount = 0;
    _appliedPromoCode = '';
    _owner = '';
    _restoring = false;
    super.notifyListeners();
    try {
      globalCartBar.sync(count: 0, total: 0, images: const <String>[]);
    } catch (_) {}
  }

  void _scheduleSave() {
    if (_restoring) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 700), () async {
      final List<Map<String, dynamic>> data = _toJson();
      try {
        final SharedPreferences sp = await SharedPreferences.getInstance();
        await sp.setString(_key, jsonEncode(data));
      } catch (_) {}
      if (!UserManager().hasSession) return;
      try {
        await http.put(Uri.parse(_api), headers: UserManager().authHeaders, body: jsonEncode(<String, dynamic>{'items': data})).timeout(const Duration(seconds: 15));
      } catch (_) {}
    });
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    _scheduleSave();
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

  /// Switch a cart line to another size (merges with an existing line of that size).
  void changeWeight(CartItem item, String weight) {
    if (item.weight == weight || !_items.contains(item)) return;
    final int other = _items.indexWhere((CartItem x) =>
        !identical(x, item) && x.product.name == item.product.name && x.weight == weight &&
        x.isTemperingRequested == item.isTemperingRequested && x.chefNote == item.chefNote);
    if (other != -1) {
      _items[other].quantity = (_items[other].quantity + item.quantity).clamp(1, 50);
      _items.remove(item);
    } else {
      item.weight = weight;
    }
    if (_appliedPromoCode.isNotEmpty) applyPromoCode(_appliedPromoCode);
    notifyListeners();
  }

  /// The coupon that saves the most on this cart right now, or null.
  ({HomeOffer offer, double saving})? bestOffer() {
    ({HomeOffer offer, double saving})? best;
    for (final HomeOffer o in HomeOffersStore.items.value) {
      if (promoProblem(o.code) != null) continue;
      final double? d = o.discountFor(subtotal, deliveryFee);
      if (d == null || d <= 0) continue;
      if (best == null || d > best.saving) best = (offer: o, saving: d);
    }
    return best;
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
