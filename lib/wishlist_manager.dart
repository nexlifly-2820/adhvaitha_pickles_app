import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'user_manager.dart';
import 'models.dart';
import 'product_repository.dart';
import 'product_manager.dart';
import 'product_lookup.dart';

class WishlistManager extends ChangeNotifier {
  static final WishlistManager _instance = WishlistManager._internal();
  factory WishlistManager() => _instance;

  final List<Product> _wishlist = [];

  WishlistManager._internal() {
    _loadLocal();
  }

  // ───── saved on the phone + on our server (same on every phone) ─────
  static const String _api = 'https://admin.adhvaithafoods.in/api/me/wishlist';
  String get _key => 'wishlist_${UserManager().currentUserId}';
  String _loadedFor = '';

  List<Map<String, dynamic>> _toJson() => _wishlist
      .map((Product p) => <String, dynamic>{'name': p.name, 'image': p.image, 'price': p.weightPriceMap.isEmpty ? 0 : p.weightPriceMap.values.first, 'category': p.category})
      .toList();

  void _fromJson(List<dynamic> items) {
    _wishlist.clear();
    for (final dynamic x in items) {
      if (x is! Map) continue;
      final String name = '${x['name'] ?? ''}'.trim();
      if (name.isEmpty || isFavoriteName(name)) continue;
      _addByName(name, image: '${x['image'] ?? ''}', price: (x['price'] is num) ? (x['price'] as num).toDouble() : 0, category: '${x['category'] ?? 'Specials'}');
    }
  }

  Future<void> _loadLocal() async {
    try {
      final String uid = UserManager().currentUserId;
      _loadedFor = uid;
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? raw = p.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        _fromJson(jsonDecode(raw) as List<dynamic>);
        super.notifyListeners();
      }
    } catch (_) {}
    syncFromServer();
  }

  Future<void> _saveAll() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(_key, jsonEncode(_toJson()));
    } catch (_) {}
    if (!UserManager().hasSession) return;
    try {
      await http.put(Uri.parse(_api), headers: UserManager().authHeaders, body: jsonEncode(<String, dynamic>{'items': _toJson()})).timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  /// Gets the wishlist from our server after login (keeps hearts added on this phone too).
  Future<void> syncFromServer() async {
    if (!UserManager().hasSession) return;
    if (_loadedFor != UserManager().currentUserId) {
      _loadedFor = UserManager().currentUserId;
      _wishlist.clear();
    }
    try {
      final http.Response r = await http.get(Uri.parse(_api), headers: UserManager().authHeaders).timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) return;
      final dynamic j = jsonDecode(r.body);
      final List<dynamic> server = (j is Map && j['items'] is List) ? j['items'] as List<dynamic> : <dynamic>[];
      final List<Map<String, dynamic>> local = _toJson();
      _fromJson(server);
      bool added = false;
      for (final Map<String, dynamic> x in local) {
        if (!isFavoriteName('${x['name']}')) {
          _addByName('${x['name']}', image: '${x['image'] ?? ''}', price: (x['price'] as num?)?.toDouble() ?? 0, category: '${x['category'] ?? 'Specials'}');
          added = true;
        }
      }
      super.notifyListeners();
      if (added || server.isEmpty) _saveAll();
    } catch (_) {}
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    _saveAll();
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
    _addByName(name, image: image, price: price, category: category);
    notifyListeners();
    return true;
  }

  void _addByName(String name, {String image = '', double price = 0, String category = 'Specials'}) {
    final String n = _norm(name);
    Product? match = findCatalogProduct(name);
    // keep the photo the customer actually saw if the catalogue one has none
    // and keep the name the customer saw, so the heart stays filled everywhere
    if (match != null && (_norm(match.name) != n || (match.image.trim().isEmpty && image.trim().isNotEmpty))) {
      final Product m = match;
      match = Product(
        name: name,
        description: m.description,
        weightPriceMap: m.weightPriceMap.isNotEmpty ? m.weightPriceMap : <String, double>{'250g': price > 0 ? price : 199},
        rating: m.rating,
        image: image.trim().isNotEmpty ? image : m.image,
        color: m.color,
        category: m.category,
        secretIngredient: m.secretIngredient,
      );
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
  }
}
