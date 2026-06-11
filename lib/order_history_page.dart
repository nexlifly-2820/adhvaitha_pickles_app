import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'order_manager.dart';
import 'cart_manager.dart';
import 'models.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(title: const Text('MY ORDERS')),
      body: ListenableBuilder(
        listenable: OrderManager(),
        builder: (context, _) {
          final orders = OrderManager().orders;
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined, size: 100, color: const Color(0xFF18453B).withOpacity(0.1)),
                  const SizedBox(height: 24),
                  const Text('No orders yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Your delicious journey starts here.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: orders.length,
            itemBuilder: (context, index) => _OrderCard(order: orders[index]),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(order.id, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF18453B))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(order.status.toUpperCase(), style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset(item.product.image, width: 40, height: 40, fit: BoxFit.cover)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      Text('x${item.quantity}', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
                const Divider(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('dd MMM, yyyy').format(order.date), style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    ElevatedButton(
                      onPressed: () {
                        for (var item in order.items) {
                          CartManager().addToCart(item.product, quantity: item.quantity, weight: item.weight);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Items added to cart!')));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF18453B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('REORDER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    Text('Total: ₹${order.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
          // TRACKING TIMELINE
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF18453B).withOpacity(0.03), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(25))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _timelineDot('Placed', true),
                _timelineLine(true),
                _timelineDot('Packed', true),
                _timelineLine(false),
                _timelineDot('Shipped', false),
                _timelineLine(false),
                _timelineDot('Delivered', false),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _timelineDot(String label, bool isDone) {
    return Column(
      children: [
        Icon(isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 16, color: isDone ? const Color(0xFF18453B) : Colors.grey.shade300),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: isDone ? const Color(0xFF18453B) : Colors.grey)),
      ],
    );
  }

  Widget _timelineLine(bool isDone) {
    return Expanded(child: Container(height: 2, color: isDone ? const Color(0xFF18453B) : Colors.grey.shade200, margin: const EdgeInsets.only(bottom: 15)));
  }
}
