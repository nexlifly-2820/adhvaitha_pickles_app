import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'order_manager.dart';
import 'cart_manager.dart';
import 'models.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(title: Text('MY ORDERS', style: GoogleFonts.philosopher(fontWeight: FontWeight.w900))),
      body: ListenableBuilder(
        listenable: OrderManager(),
        builder: (context, _) {
          final orders = OrderManager().orders;
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined, size: 120, color: const Color(0xFF18453B).withOpacity(0.1)),
                  const SizedBox(height: 24),
                  Text('No orders yet', style: GoogleFonts.philosopher(fontSize: 22, color: const Color(0xFF2D1B12), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Your delicious journey starts here.', style: TextStyle(color: Colors.grey)),
                ],
              ).animate().fadeIn().scale(),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: orders.length,
            itemBuilder: (context, index) => _OrderCard(order: orders[index]).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1, end: 0),
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
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(order.id, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF18453B), fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      child: Text(order.status.toUpperCase(), style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(item.product.image, width: 45, height: 45, fit: BoxFit.cover)),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(item.weight, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                      Text('x${item.quantity}', style: const TextStyle(color: Color(0xFF18453B), fontSize: 14, fontWeight: FontWeight.w900)),
                    ],
                  ),
                )),
                const Divider(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('dd MMM, yyyy').format(order.date), style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('₹${order.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF18453B))),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        for (var item in order.items) {
                          CartManager().addToCart(item.product, quantity: item.quantity, weight: item.weight);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Items added to cart!'), behavior: SnackBarBehavior.floating));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF18453B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('REORDER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // TRACKING TIMELINE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(color: const Color(0xFF18453B).withOpacity(0.03), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30))),
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
        Icon(isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 18, color: isDone ? const Color(0xFF18453B) : Colors.grey.shade300),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isDone ? const Color(0xFF18453B) : Colors.grey, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _timelineLine(bool isDone) {
    return Expanded(child: Container(height: 2, color: isDone ? const Color(0xFF18453B) : Colors.grey.shade200, margin: const EdgeInsets.only(bottom: 20)));
  }
}
