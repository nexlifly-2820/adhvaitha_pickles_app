import 'package:flutter/material.dart';
import 'screens/my_orders_screen.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: MyOrdersScreen(),
    );
  }
}
