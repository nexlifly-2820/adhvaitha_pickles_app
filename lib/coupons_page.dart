import 'package:flutter/material.dart';

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
      appBar: AppBar(title: const Text('AVAILABLE COUPONS')),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: coupons.length,
        itemBuilder: (context, index) {
          final c = coupons[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['title']!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF18453B))),
                      Text(c['sub']!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text('Min order value: ${c['min']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFF18453B), borderRadius: BorderRadius.circular(10)),
                      child: Text(c['code']!, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 12)),
                    ),
                    const SizedBox(height: 8),
                    const Text('COPY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF18453B), letterSpacing: 1)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
