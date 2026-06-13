import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        title: Text('TERMS OF SERVICE', style: GoogleFonts.philosopher(fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Effective Date: May 2024', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Text(
              'By accessing the Adhvaitha Foods mobile application, you agree to be bound by these Terms of Service. Please read them carefully before placing a royal order.',
              style: TextStyle(fontSize: 14, color: const Color(0xFF2D1B12).withOpacity(0.7), height: 1.6),
            ),
            const SizedBox(height: 40),
            _buildSection('1. ACCEPTANCE OF TERMS', 'Your use of this app constitutes acceptance of these terms and conditions. We reserve the right to update these terms at any time without prior notice.'),
            _buildSection('2. ELIGIBILITY', 'To place an order, you must be at least 18 years of age or accessing the app under the supervision of a parent or guardian.'),
            _buildSection('3. PRODUCT ACCURACY', 'We strive to provide accurate images and descriptions of our handmade products. However, as these are artisanal items made in small batches, slight variations in color and texture may occur.'),
            _buildSection('4. PRICING & PAYMENT', 'All prices are inclusive of applicable taxes unless stated otherwise. Delivery charges are calculated based on your shipping location. Payments must be completed at the time of order through our integrated secure gateways.'),
            _buildSection('5. INTELLECTUAL PROPERTY', 'All content, including the "Adhvaitha" brand name, logos, and product descriptions, is the property of Adhvaitha Foods and is protected by copyright laws.'),
            _buildSection('6. LIMITATION OF LIABILITY', 'Adhvaitha Foods shall not be liable for any indirect, incidental, or consequential damages arising from the use of our products or the mobile application.'),
            const SizedBox(height: 40),
            Center(
              child: Text(
                '© 2024 Adhvaitha Foods. All rights reserved.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.bold),
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
