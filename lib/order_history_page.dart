import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'order_manager.dart';
import 'cart_manager.dart';
import 'models.dart';
import 'main.dart';
import 'order_details_page.dart';
import 'navigation_util.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OrderManager().startOrderListener();
    });
  }

  @override
  void dispose() {
    // We can keep it listening or stop it here. Usually, keeping it live for the session is fine.
    // OrderManager().stopOrderListener(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('MY ORDERS', style: GoogleFonts.philosopher(fontWeight: FontWeight.w900)),
        ),
        actions: [const GlobalCartBadge()],
      ),
      body: ListenableBuilder(
        listenable: OrderManager(),
        builder: (context, _) {
          final manager = OrderManager();
          final orders = manager.orders;

          if (manager.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF18453B)));
          }

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
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        AppNavigator.push(context, OrderDetailsPage(order: order));
      },
      child: Container(
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
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(order.id, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF18453B), fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                        child: Text(order.status.toUpperCase(), style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (order.trackingId != null) ...[
                    Container(
                      padding: const EdgeInsets.all(15),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.blue.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_shipping_outlined, color: Colors.blue, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${order.courierName ?? 'Courier'}: ${order.trackingId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                                const Text('Tap to track your royal package', style: TextStyle(fontSize: 10, color: Colors.blueGrey)),
                              ],
                            ),
                          ),
                          const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.blue),
                        ],
                      ),
                    ),
                  ],
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('dd MMM, yyyy').format(order.date), style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('₹${order.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF18453B))),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
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
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Estimated Delivery: ${order.estimatedDelivery != null ? DateFormat('dd MMM').format(order.estimatedDelivery!) : 'TBD'}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'NON-RETURNABLE',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black26, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Support...')));
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 14, color: const Color(0xFF18453B).withOpacity(0.4)),
                        const SizedBox(width: 8),
                        Text(
                          'Need help with this order? Chat with us',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF18453B).withOpacity(0.4)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // TRACKING TIMELINE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              decoration: BoxDecoration(color: const Color(0xFF18453B).withOpacity(0.03), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _timelineDot('Placed', _isStatusReached(order.status, 'Placed')),
                  _timelineLine(_isStatusReached(order.status, 'Preparing')),
                  _timelineDot('Kitchen', _isStatusReached(order.status, 'Preparing')),
                  _timelineLine(_isStatusReached(order.status, 'Quality Sealed')),
                  _timelineDot('Sealed', _isStatusReached(order.status, 'Quality Sealed')),
                  _timelineLine(_isStatusReached(order.status, 'Shipped')),
                  _timelineDot('Shipped', _isStatusReached(order.status, 'Shipped')),
                  _timelineLine(_isStatusReached(order.status, 'Delivered')),
                  _timelineDot('Delivered', _isStatusReached(order.status, 'Delivered')),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  bool _isStatusReached(String currentStatus, String targetStatus) {
    const statuses = ['Placed', 'Preparing', 'Quality Sealed', 'Shipped', 'Delivered'];
    int currentIndex = statuses.indexOf(currentStatus);
    int targetIndex = statuses.indexOf(targetStatus);
    if (currentIndex == -1) return false;
    return currentIndex >= targetIndex;
  }

  Widget _timelineDot(String label, bool isDone) {
    return SizedBox(
      width: 45,
      child: Column(
        children: [
          Icon(isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 16, color: isDone ? const Color(0xFF18453B) : Colors.grey.shade300),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: isDone ? const Color(0xFF18453B) : Colors.grey, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _timelineLine(bool isDone) {
    return Expanded(child: Container(height: 1.5, color: isDone ? const Color(0xFF18453B) : Colors.grey.shade200, margin: const EdgeInsets.only(bottom: 20)));
  }
}
