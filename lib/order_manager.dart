import 'package:flutter/material.dart';
import 'cart_manager.dart';

class Order {
  final String id;
  final List<CartItem> items;
  final double total;
  final DateTime date;
  final String status; // 'Placed', 'Preparing', 'Shipped', 'Delivered'

  Order({
    required this.id,
    required this.items,
    required this.total,
    required this.date,
    required this.status,
  });
}

class OrderManager extends ChangeNotifier {
  static final OrderManager _instance = OrderManager._internal();
  factory OrderManager() => _instance;
  OrderManager._internal();

  final List<Order> _orders = [];
  List<Order> get orders => _orders;

  void addOrder(List<CartItem> items, double total) {
    final newOrder = Order(
      id: '#ADH${1000 + _orders.length}',
      items: List.from(items),
      total: total,
      date: DateTime.now(),
      status: 'Preparing',
    );
    _orders.insert(0, newOrder);
    notifyListeners();
  }
}
