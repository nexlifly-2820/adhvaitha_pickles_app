import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RefundPolicyPage extends StatelessWidget {
  const RefundPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        title: Text('REFUND & RETURNS', style: GoogleFonts.philosopher(fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Last Updated: May 2024', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withOpacity(0.1)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red),
                  SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      'IMPORTANT: Food items are non-returnable due to hygiene and food safety standards.',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildSection('1. NON-RETURNABLE PRODUCTS', 'For the health and safety of our customers, we cannot accept returns of any food products (Pickles, Snacks, Spices, Sweets) once they have been delivered, regardless of whether the seal is broken.'),
            _buildSection('2. DAMAGED OR WRONG ITEMS', 'In the rare event that you receive a damaged jar or the wrong product, please contact us within 24 hours of delivery. We will require an unboxing video and clear photographs to process a replacement or refund.'),
            _buildSection('3. CANCELLATION POLICY', 'Orders can only be cancelled within 1 hour of placement, as we process fresh batches immediately to ensure royal quality. Once an order is "Packed" or "Shipped," cancellation is no longer possible.'),
            _buildSection('4. REFUND PROCESS', 'Approved refunds for damaged items will be processed within 5-7 business days back to your original payment method (Bank Account, UPI, or Credit Card).'),
            _buildSection('5. SHIPPING LOSS', 'If your package is lost in transit, we will initiate a full replacement or refund after verification with our logistics partner.'),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: const Color(0xFF18453B),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                children: [
                  const Text(
                    'Need assistance with an order?',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to contact us
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: const Color(0xFF18453B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('CONTACT ROYAL SUPPORT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF18453B), letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Text(content, style: TextStyle(fontSize: 14, color: const Color(0xFF2D1B12).withOpacity(0.8), height: 1.7)),
        const SizedBox(height: 35),
      ],
    );
  }
}
