import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'order_manager.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = OrderManager().orders;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('MY ORDERS', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2C3E50))),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No orders yet', style: TextStyle(color: Colors.grey, fontSize: 18)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: orders.length,
              itemBuilder: (context, index) => _OrderCard(order: orders[index]),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
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
                    Text(order.id, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        order.status.toUpperCase(),
                        style: const TextStyle(color: Color(0xFFD35400), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(order.date),
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                const Divider(height: 32),
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(item.product.image, width: 40, height: 40, fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${item.quantity} x ${item.weight}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text('₹${(double.parse(item.product.price.replaceAll('₹', '')) * item.quantity).toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                    Text('₹${order.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFFD35400))),
                  ],
                ),
              ],
            ),
          ),
          
          // HIGH LEVEL TIMELINE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TimelineStep(label: 'Placed', isActive: true, isCompleted: true),
                _TimelineStep(label: 'Preparing', isActive: true, isCompleted: false),
                _TimelineStep(label: 'Shipped', isActive: false, isCompleted: false),
                _TimelineStep(label: 'Delivered', isActive: false, isCompleted: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isCompleted;

  const _TimelineStep({required this.label, required this.isActive, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green : (isActive ? const Color(0xFFD35400) : Colors.grey.shade300),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: isActive ? [BoxShadow(color: const Color(0xFFD35400).withOpacity(0.3), blurRadius: 8)] : [],
          ),
          child: isCompleted ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(
          fontSize: 10, 
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? Colors.black87 : Colors.grey,
        )),
      ],
    );
  }
}
