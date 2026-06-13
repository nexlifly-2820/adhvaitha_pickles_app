import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        title: Text('HELP CENTER', style: GoogleFonts.philosopher(fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('FREQUENTLY ASKED QUESTIONS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 25),
            _buildFaqItem('How long do your pickles last?', 'Our pickles generally have a shelf life of 6-12 months when stored in a cool, dry place. Always use a dry spoon and ensure the oil layer remains on top.'),
            _buildFaqItem('Why is there no return policy?', 'To maintain strict food safety and hygiene standards, we cannot accept returns once a food item is delivered. However, we offer replacements for damaged items.'),
            _buildFaqItem('Do you ship internationally?', 'Currently, we ship only within India. We are working on bringing our royal flavors to global markets soon!'),
            _buildFaqItem('Are there any artificial colors?', 'Absolutely not. We use only natural ingredients like Guntur chillies for color and cold-pressed oils for preservation.'),
            _buildFaqItem('What is a Batch Genealogy?', 'It is a transparency document that tells you exactly when your jar was prepared, who the chef was, and where the spices were sourced from.'),
            const SizedBox(height: 40),
            _buildContactCard(),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)],
      ),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF18453B))),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        expandedAlignment: Alignment.topLeft,
        shape: const Border(),
        children: [
          Text(answer, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFF18453B),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          const Icon(Icons.support_agent_rounded, color: Color(0xFFD4AF37), size: 40),
          const SizedBox(height: 20),
          const Text('Still need help?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          Text(
            'Our royal support team is available 24/7 for your assistance.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: const Color(0xFF18453B),
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text('CHAT WITH US', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
