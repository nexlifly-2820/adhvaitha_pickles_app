import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(title: const Text('PRIVACY POLICY')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Last Updated: January 2024', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 24),
            _buildSection('1. Information Collection', 'We collect information you provide directly to us, such as when you create an account, place an order, or contact customer support.'),
            _buildSection('2. How We Use Information', 'We use the information we collect to process your orders, provide customer support, and send you updates about our products and services.'),
            _buildSection('3. Information Sharing', 'We do not share your personal information with third parties except as necessary to fulfill your orders (e.g., sharing your address with delivery partners).'),
            _buildSection('4. Data Security', 'We take reasonable measures to help protect information about you from loss, theft, misuse, and unauthorized access.'),
            _buildSection('5. Your Choices', 'You can update your account information at any time through your profile settings.'),
            const SizedBox(height: 40),
            const Text('For any questions regarding this policy, please contact us at support@adhvaitha.com', style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF18453B))),
        const SizedBox(height: 10),
        Text(content, style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.6)),
        const SizedBox(height: 30),
      ],
    );
  }
}
