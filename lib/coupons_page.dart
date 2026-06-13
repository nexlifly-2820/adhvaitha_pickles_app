import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cart_manager.dart';

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
      body: ListenableBuilder(
        listenable: CartManager(),
        builder: (context, _) {
          final appliedCode = CartManager().appliedPromoCode;
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              final c = coupons[index];
              final bool isApplied = appliedCode == c['code'];
              
              return GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  if (CartManager().items.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add items to cart first!'), backgroundColor: Colors.red));
                    return;
                  }
                  if (isApplied) {
                    CartManager().removePromoCode();
                  } else {
                    CartManager().applyPromoCode(c['code']!);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Coupon ${c['code']} applied successfully!'),
                      backgroundColor: const Color(0xFF18453B),
                    ));
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isApplied ? const Color(0xFF18453B).withOpacity(0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
                    border: Border.all(color: isApplied ? const Color(0xFF18453B) : const Color(0xFFD4AF37).withOpacity(0.2), width: isApplied ? 2 : 1),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: isApplied 
                                ? const LinearGradient(colors: [Colors.grey, Colors.grey])
                                : const LinearGradient(colors: [Color(0xFF18453B), Color(0xFF276357)]),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: isApplied ? [] : [BoxShadow(color: const Color(0xFF18453B).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                            ),
                            child: Text(
                              isApplied ? 'REMOVE' : c['code']!, 
                              style: TextStyle(color: isApplied ? Colors.white : const Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isApplied ? 'APPLIED' : 'TAP TO APPLY', 
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isApplied ? Colors.green : const Color(0xFF18453B), letterSpacing: 1)
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
            },
          );
        }
      ),
    );
  }
}
