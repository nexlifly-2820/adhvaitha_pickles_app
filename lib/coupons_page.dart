import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class CouponsPage extends StatelessWidget {
  const CouponsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> coupons = [
      {'code': 'FIRST30', 'title': '30% OFF', 'sub': 'On your first order', 'min': '₹500'},
      {'code': 'PICKLE100', 'title': '₹100 OFF', 'sub': 'Flat discount on all pickles', 'min': '₹999'},
      {'code': 'FESTIVE20', 'title': '20% OFF', 'sub': 'Special festive season discount', 'min': '₹1500'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(title: const Text('MY COUPONS')),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: coupons.length,
        itemBuilder: (context, index) {
          final c = coupons[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c['title']!, 
                        style: GoogleFonts.philosopher(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF18453B)),
                      ),
                      const SizedBox(height: 4),
                      Text(c['sub']!, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Text('Min order value: ${c['min']}', style: const TextStyle(fontSize: 11, color: Colors.grey, letterSpacing: 1)),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Clipboard.setData(ClipboardData(text: c['code']!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Code ${c['code']} copied!'), backgroundColor: const Color(0xFF18453B))
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF18453B), Color(0xFF276357)]),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [BoxShadow(color: const Color(0xFF18453B).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: Text(c['code']!, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('TAP TO COPY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF18453B), letterSpacing: 1)),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
        },
      ),
    );
  }
}
