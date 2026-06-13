import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        title: Text('PRIVACY POLICY', style: GoogleFonts.philosopher(fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Last Updated: May 2024', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Text(
              'At Adhvaitha Foods, we are committed to protecting your privacy. This policy explains how we collect, use, and safeguard your personal information when you use our mobile application.',
              style: TextStyle(fontSize: 14, color: const Color(0xFF2D1B12).withOpacity(0.7), height: 1.6),
            ),
            const SizedBox(height: 40),
            _buildSection('1. DATA WE COLLECT', 'We collect information necessary to provide you with a premium shopping experience, including:\n\n• Name and contact details (email, phone number).\n• Shipping and billing addresses.\n• Device information and usage statistics.\n• Order history and preferences.'),
            _buildSection('2. HOW WE USE YOUR DATA', 'Your information is used to:\n\n• Process and deliver your royal orders.\n• Personalize your flavor recommendations.\n• Send you updates regarding your delivery status.\n• Improve our handmade process based on your feedback.'),
            _buildSection('3. THIRD-PARTY SHARING', 'Adhvaitha Foods does not sell your data. We only share information with trusted partners required for service delivery, such as logistics providers and payment gateways.'),
            _buildSection('4. DATA SECURITY', 'We implement industry-standard encryption and security measures to ensure your personal and payment information remains confidential and protected from unauthorized access.'),
            _buildSection('5. YOUR RIGHTS', 'You have the right to access, correct, or delete your personal data. You can manage these settings directly within the "Edit Profile" section of the app.'),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF18453B).withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF18453B).withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Have questions about your privacy?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF18453B)),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Contact our Data Protection Officer at privacy@adhvaitha.com',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
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
