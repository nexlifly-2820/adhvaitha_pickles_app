import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'product_lookup.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'models.dart';
import 'product_manager.dart';
import 'user_manager.dart';

class OrderManager extends ChangeNotifier {
  static final OrderManager _instance = OrderManager._internal();
  factory OrderManager() => _instance;
  OrderManager._internal();

  List<Order> _orders = [];
  List<Order> get orders => _orders;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _orderSequence = 1;

  String generateNextOrderId() {
    final year = DateTime.now().year;
    final currentCount = _orders.length + _orderSequence;
    _orderSequence++;
    return 'AMBJ$year$currentCount';
  }

  Timer? _pollingTimer;

  void startOrderListener() {
    ensureLoaded().then((_) => syncStatuses());
    fetchOrders();
    // Poll for order updates every 30 seconds
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchOrders(showLoading: false);
      syncStatuses();
    });
  }

  Future<void> fetchOrders({bool showLoading = true}) async {
    final userId = UserManager().currentUserId;

    if (showLoading && _orders.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final rawOrders = await ApiService.getUserOrders(userId);
      if (rawOrders.isNotEmpty) {
        final fetchedOrders = rawOrders.map((json) => _mapJsonToOrder(json)).toList();
        final existingIds = _orders.map((o) => o.id).toSet();
        for (var fo in fetchedOrders) {
          if (!existingIds.contains(fo.id)) {
            _orders.add(fo);
          }
        }
        _orders.sort((a, b) => b.date.compareTo(a.date));
      }
    } catch (e) {
      print('Error fetching orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addOrder(Order order) {
    if (!_orders.any((o) => o.id == order.id)) {
      _orders.insert(0, order);
      notifyListeners();
      _saveLocal();
    }
  }

  // ───────── orders placed on this phone (kept so "My Orders" always shows them) ─────────
  static const String _localKey = 'placed_orders_v1';
  Future<void>? _loading;
  Future<void> ensureLoaded() => _loading ??= _loadLocal();

  Future<void> _loadLocal() async {
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      final String? raw = sp.getString(_localKey);
      if (raw == null || raw.isEmpty) return;
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      for (final dynamic j in list) {
        if (j is! Map) continue;
        final Order o = _fromLocal(Map<String, dynamic>.from(j));
        if (!_orders.any((Order x) => x.id == o.id)) _orders.add(o);
      }
      _orders.sort((Order a, Order b) => b.date.compareTo(a.date));
      notifyListeners();
    } catch (e) {
      debugPrint('Local orders load failed: $e');
    }
  }

  Future<void> _saveLocal() async {
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> list = _orders.take(50).map(_toLocal).toList();
      await sp.setString(_localKey, jsonEncode(list));
    } catch (_) {}
  }

  static Map<String, dynamic> _toLocal(Order o) => <String, dynamic>{
        'id': o.id,
        'date': o.date.toIso8601String(),
        'status': o.status,
        'subtotal': o.subtotal,
        'deliveryFee': o.deliveryFee,
        'discountAmount': o.discountAmount,
        'total': o.total,
        'address': o.shippingAddress,
        'payment': o.paymentMethod,
        'items': o.items
            .map((CartItem c) => <String, dynamic>{
                  'name': c.product.name,
                  'image': bestImageFor(c.product.name, c.product.image),
                  'weight': c.weight,
                  'qty': c.quantity,
                  'price': c.product.getRawPriceForWeight(c.weight),
                  'category': c.product.category,
                })
            .toList(),
      };

  static double _dd(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

  static Order _fromLocal(Map<String, dynamic> j) {
    final List<CartItem> items = <CartItem>[
      for (final dynamic it in (j['items'] as List?) ?? const <dynamic>[])
        if (it is Map)
          CartItem(
            product: productFor('${it['name']}', image: '${it['image'] ?? ''}', weights: <String, double>{'${it['weight'] ?? '250g'}': _dd(it['price'])}, price: _dd(it['price']), category: '${it['category'] ?? 'Specials'}'),
            quantity: (_dd(it['qty'])).round().clamp(1, 99),
            weight: '${it['weight'] ?? '250g'}',
          ),
    ];
    final DateTime date = DateTime.tryParse('${j['date']}') ?? DateTime.now();
    return Order(
      id: '${j['id']}',
      items: items,
      subtotal: _dd(j['subtotal']),
      deliveryFee: _dd(j['deliveryFee']),
      discountAmount: _dd(j['discountAmount']),
      total: _dd(j['total']),
      date: date,
      status: '${j['status'] ?? 'Placed'}',
      estimatedDelivery: date.add(const Duration(days: 4)),
      shippingAddress: '${j['address'] ?? ''}',
      paymentMethod: '${j['payment'] ?? ''}',
      batchId: '',
      spiceOrigin: 'Guntur',
    );
  }

  // admin status -> what the app shows (wording matters: My Orders sorts by these words)
  static String _appStatus(String s) {
    switch (s.trim().toLowerCase()) {
      case 'pending':
      case 'placed':
        return 'Placed';
      case 'accepted':
        return 'In kitchen';
      case 'packing':
      case 'processing':
        return 'Sealed & packed';
      case 'shipped':
        return 'Shipped';
      case 'out_for_delivery':
      case 'out for delivery':
        return 'Shipped · out today';
      case 'delivered':
        return 'Delivered';
      case 'rejected':
      case 'cancelled':
        return 'Cancelled';
      default:
        return s.isEmpty ? 'Placed' : s;
    }
  }

  /// Pulls the latest status the admin set for orders placed on this phone.
  Future<void> syncStatuses() async {
    await ensureLoaded();
    if (_orders.isEmpty) return;
    try {
      final String ids = _orders.take(50).map((Order o) => Uri.encodeComponent(o.id)).join(',');
      final http.Response r = await http
          .get(Uri.parse('https://admin.adhvaithafoods.in/api/app-orders/status?ids=$ids'))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return;
      final List<dynamic> list = ((jsonDecode(r.body) as Map)['orders'] as List?) ?? const <dynamic>[];
      bool changed = false;
      for (final dynamic j in list) {
        if (j is! Map) continue;
        final int i = _orders.indexWhere((Order o) => o.id == '${j['id']}');
        if (i < 0) continue;
        final String st = _appStatus('${j['status'] ?? ''}');
        final String pay = '${j['paymentMethod'] ?? ''}'.trim();
        final Order o = _orders[i];
        if (st != o.status || (pay.isNotEmpty && pay != o.paymentMethod)) {
          _orders[i] = Order(
            id: o.id, items: o.items, subtotal: o.subtotal, deliveryFee: o.deliveryFee, discountAmount: o.discountAmount, total: o.total,
            date: o.date, status: st, estimatedDelivery: o.estimatedDelivery, shippingAddress: o.shippingAddress,
            paymentMethod: pay.isNotEmpty ? pay : o.paymentMethod, batchId: o.batchId, preparationDate: o.preparationDate,
            spiceOrigin: o.spiceOrigin, trackingId: o.trackingId, courierName: o.courierName,
          );
          changed = true;
        }
      }
      if (changed) {
        notifyListeners();
        _saveLocal();
      }
    } catch (e) {
      debugPrint('Order status sync failed: $e');
    }
  }

  /// Call right after a successful checkout (before the cart is cleared).
  Future<void> recordPlacedOrder({
    required String id,
    required List<CartItem> items,
    required double subtotal,
    required double deliveryFee,
    required double discount,
    required double total,
    required String address,
    required String paymentMethod,
  }) async {
    await ensureLoaded();
    final List<CartItem> copy = items
        .map((CartItem c) => CartItem(product: c.product, quantity: c.quantity, weight: c.weight, isTemperingRequested: c.isTemperingRequested, chefNote: c.chefNote))
        .toList();
    final DateTime now = DateTime.now();
    addOrder(Order(
      id: id,
      items: copy,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discountAmount: discount,
      total: total,
      date: now,
      status: 'Placed',
      estimatedDelivery: now.add(const Duration(days: 4)),
      shippingAddress: address,
      paymentMethod: paymentMethod,
      batchId: '',
      spiceOrigin: 'Guntur',
    ));
    // the order itself is saved on the server by checkout (Razorpay verify / Cash on Delivery)
  }

  void stopOrderListener() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Order _mapJsonToOrder(Map<String, dynamic> data) {
    final List<dynamic> rawItems = data['items'] is List ? data['items'] : [];
    
    final List<CartItem> items = rawItems.map((itemData) {
      final productName = itemData['name']?.toString() ?? 'Pickle';
      final product = ProductManager().getProductByName(productName) ?? Product(
        name: productName,
        description: '',
        weightPriceMap: {itemData['weight']?.toString() ?? '500g': (itemData['price'] as num?)?.toDouble() ?? 250.0},
        rating: 5.0,
        image: 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg',
        color: Colors.green,
        category: '',
        secretIngredient: IngredientDetail(name: '', description: '', image: ''),
      );
      
      return CartItem(
        product: product,
        quantity: (itemData['quantity'] as num?)?.toInt() ?? 1,
        weight: itemData['weight']?.toString() ?? '500g',
        isTemperingRequested: itemData['tempering'] == true,
        chefNote: itemData['chefNote']?.toString(),
      );
    }).toList();

    DateTime parsedDate = DateTime.now();
    if (data['date'] != null) {
      parsedDate = DateTime.tryParse(data['date'].toString()) ?? DateTime.now();
    }

    return Order(
      id: data['orderId']?.toString() ?? data['order_id']?.toString() ?? data['id']?.toString() ?? 'AMBJ${DateTime.now().year}1',
      items: items,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (data['discountAmount'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      date: parsedDate,
      status: data['status']?.toString() ?? 'Placed',
      shippingAddress: data['shippingAddress']?.toString() ?? '',
      paymentMethod: data['paymentMethod']?.toString() ?? 'COD',
      batchId: data['batchId']?.toString() ?? '',
      spiceOrigin: data['spiceOrigin']?.toString() ?? 'Guntur',
      trackingId: data['trackingId']?.toString(),
      courierName: data['courierName']?.toString(),
    );
  }
}
