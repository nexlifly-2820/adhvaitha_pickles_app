import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(title: Text('MY REWARDS', style: GoogleFonts.philosopher(fontWeight: FontWeight.w900))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // REWARDS CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF18453B), Color(0xFF276357)]),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: const Color(0xFF18453B).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stars_rounded, color: Color(0xFFD4AF37), size: 40),
                      const SizedBox(width: 10),
                      const Text('450', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
                      const SizedBox(width: 8),
                      const Text('Coins', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Text('100 Coins = ₹10', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),

            const SizedBox(height: 40),

            _buildSectionTitle('HOW TO EARN'),
            const SizedBox(height: 20),
            _buildEarnCard(Icons.shopping_bag_outlined, 'Place an Order', 'Earn 1 Coin for every ₹10 spent'),
            _buildEarnCard(Icons.star_outline_rounded, 'Review Products', 'Earn 50 Coins for every photo review'),
            _buildEarnCard(Icons.person_add_alt_1_outlined, 'Refer a Friend', 'Earn 200 Coins when they order'),

            const SizedBox(height: 40),
            
            _buildSectionTitle('LATEST TRANSACTIONS'),
            const SizedBox(height: 20),
            _buildTransaction('Order #AP1042', '+45', '2 days ago', true),
            _buildTransaction('Review: Bellam Avakaya', '+50', '5 days ago', true),
            _buildTransaction('Referral Bonus', '+200', '1 week ago', true),
            _buildTransaction('Order #AP0988', '-150', '2 weeks ago', false),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Color(0xFF18453B))),
    );
  }

  Widget _buildEarnCard(IconData icon, String title, String sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF18453B).withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF18453B), size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(sub, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildTransaction(String title, String val, String date, bool isAdd) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          Text(val, style: TextStyle(color: isAdd ? Colors.green : Colors.red, fontWeight: FontWeight.w900, fontSize: 16)),
        ],
      ),
    );
  }
}
