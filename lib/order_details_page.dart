import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'batch_genealogy_page.dart';
import 'navigation_util.dart';

class OrderDetailsPage extends StatelessWidget {
  final Order order;
  const OrderDetailsPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        title: Text('ORDER DETAILS', style: GoogleFonts.philosopher(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading Invoice...')));
            },
            icon: const Icon(Icons.download_for_offline_outlined),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 30),
            _buildSectionTitle('ITEMS ORDERED'),
            const SizedBox(height: 15),
            ...order.items.map((item) => _buildItemTile(item)),
            const SizedBox(height: 40),
            _buildSectionTitle('DELIVERY ADDRESS'),
            const SizedBox(height: 15),
            _buildInfoCard(Icons.location_on_outlined, order.shippingAddress),
            const SizedBox(height: 40),
            _buildSectionTitle('PAYMENT INFORMATION'),
            const SizedBox(height: 15),
            _buildInfoCard(Icons.payment_rounded, order.paymentMethod),
            const SizedBox(height: 40),
            _buildSectionTitle('BILLING SUMMARY'),
            const SizedBox(height: 15),
            _buildBillingCard(),
            const SizedBox(height: 50),
            _buildGenealogyButton(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF18453B),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.id, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
                const SizedBox(height: 6),
                Text(
                  'Placed on ${DateFormat('dd MMM yyyy, hh:mm a').format(order.date)}',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFD4AF37), borderRadius: BorderRadius.circular(12)),
            child: Text(
              order.status.toUpperCase(),
              style: const TextStyle(color: Color(0xFF18453B), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 11, color: Colors.grey),
    );
  }

  Widget _buildItemTile(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(item.product.image, width: 60, height: 60, fit: BoxFit.cover),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text('${item.weight} • Qty: ${item.quantity}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(
            '₹${(item.product.getRawPriceForWeight(item.weight) * item.quantity).toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF18453B), fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF18453B), size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
      ),
      child: Column(
        children: [
          _billingRow('Items Subtotal', '₹${order.subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 12),
          _billingRow('Delivery Charges', '₹${order.deliveryFee.toStringAsFixed(0)}'),
          if (order.discountAmount > 0) ...[
            const SizedBox(height: 12),
            _billingRow('Promo Discount', '-₹${order.discountAmount.toStringAsFixed(0)}', isDiscount: true),
          ],
          const Divider(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              Text(
                '₹${order.total.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF18453B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _billingRow(String label, String val, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
        Text(
          val,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDiscount ? Colors.green : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildGenealogyButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        AppNavigator.push(context, BatchGenealogyPage(order: order));
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFE5C76B)]),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_edu_rounded, color: Color(0xFF18453B)),
            SizedBox(width: 15),
            Text(
              'VIEW BATCH GENEALOGY',
              style: TextStyle(color: Color(0xFF18453B), fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
