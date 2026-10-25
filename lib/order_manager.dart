import 'dart:async';
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
    fetchOrders();
    // Poll for order updates every 30 seconds
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchOrders(showLoading: false);
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
    }
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
