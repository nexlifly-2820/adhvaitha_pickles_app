import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'models.dart';
import 'product_manager.dart';
import 'product_repository.dart';

class OrderManager extends ChangeNotifier {
  static final OrderManager _instance = OrderManager._internal();
  factory OrderManager() => _instance;
  OrderManager._internal();

  List<Order> _orders = [];
  List<Order> get orders => _orders;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription? _ordersSubscription;

  void startOrderListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    _ordersSubscription?.cancel();
    _ordersSubscription = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      _orders = snapshot.docs.map((doc) => _mapToOrder(doc)).toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      print('Error listening to orders: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  void stopOrderListener() {
    _ordersSubscription?.cancel();
    _ordersSubscription = null;
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }

  Order _mapToOrder(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Map items from raw data
    final List<CartItem> items = (data['items'] as List).map((itemData) {
      final productName = itemData['name'];
      final product = ProductManager().getProductByName(productName) ?? Product(
        name: productName,
        description: '',
        weightPriceMap: {itemData['weight'].toString(): (itemData['price'] as num).toDouble()},
        rating: 5.0,
        image: 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg',
        color: Colors.green,
        category: '',
        secretIngredient: IngredientDetail(name: '', description: '', image: ''),
      );
      
      return CartItem(
        product: product,
        quantity: itemData['quantity'],
        weight: itemData['weight'].toString(),
        isTemperingRequested: itemData['tempering'] ?? false,
        chefNote: itemData['chefNote'],
      );
    }).toList();

    return Order(
      id: data['orderId'],
      items: items,
      subtotal: (data['subtotal'] as num).toDouble(),
      deliveryFee: (data['deliveryFee'] as num).toDouble(),
      discountAmount: (data['discountAmount'] as num).toDouble(),
      total: (data['total'] as num).toDouble(),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'],
      estimatedDelivery: (data['estimatedDelivery'] as Timestamp?)?.toDate(),
      shippingAddress: data['shippingAddress'],
      paymentMethod: data['paymentMethod'],
      batchId: data['batchId'],
      preparationDate: (data['preparationDate'] as Timestamp?)?.toDate(),
      spiceOrigin: data['spiceOrigin'],
      trackingId: data['trackingId'],
      courierName: data['courierName'],
    );
  }
}
