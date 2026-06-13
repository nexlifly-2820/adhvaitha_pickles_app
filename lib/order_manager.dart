import 'package:flutter/material.dart';
import 'models.dart';

class OrderManager extends ChangeNotifier {
  static final OrderManager _instance = OrderManager._internal();
  factory OrderManager() => _instance;
  OrderManager._internal();

  final List<Order> _orders = [];
  List<Order> get orders => _orders;

  void addOrder({
    required List<CartItem> items,
    required double subtotal,
    required double deliveryFee,
    required double discountAmount,
    required double total,
    required String shippingAddress,
    required String paymentMethod,
  }) {
    final newOrder = Order(
      id: '#ADH${1000 + _orders.length}',
      items: List.from(items),
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discountAmount: discountAmount,
      total: total,
      date: DateTime.now(),
      status: 'Placed',
      estimatedDelivery: DateTime.now().add(const Duration(days: 4)),
      shippingAddress: shippingAddress,
      paymentMethod: paymentMethod,
      batchId: 'BCH-${DateTime.now().year}${100 + _orders.length}',
      preparationDate: DateTime.now().subtract(const Duration(days: 2)),
      spiceOrigin: 'Guntur & Warangal Markets',
    );
    _orders.insert(0, newOrder);
    notifyListeners();
  }
}
