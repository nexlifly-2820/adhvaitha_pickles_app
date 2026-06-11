import 'package:flutter/material.dart';
import 'models.dart';

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
