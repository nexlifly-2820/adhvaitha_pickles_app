import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'checkout_page.dart';
import 'navigation_util.dart';

class ShippingAddressPage extends StatelessWidget {
  const ShippingAddressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(title: const Text('SAVED ADDRESSES')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _AddressCard(title: 'Home', address: 'Plot 42, Hitech City, Hyderabad, Telangana - 500081', isDefault: true),
            _AddressCard(title: 'Office', address: 'Madhapur Road, Jubilee Hills, Hyderabad, Telangana - 500033', isDefault: false),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                AppNavigator.push(context, const CheckoutPage());
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('ADD NEW ADDRESS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF18453B),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final String title, address;
  final bool isDefault;
  const _AddressCard({required this.title, required this.address, required this.isDefault});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
        border: Border.all(color: isDefault ? const Color(0xFFD4AF37) : Colors.transparent, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF18453B), letterSpacing: 2, fontSize: 12)),
              if (isDefault) 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
                  decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.2), borderRadius: BorderRadius.circular(10)), 
                  child: const Text('DEFAULT', style: TextStyle(color: Color(0xFF18453B), fontWeight: FontWeight.bold, fontSize: 10))
                ),
            ],
          ),
          const SizedBox(height: 15),
          Text(address, style: TextStyle(color: Colors.grey.shade700, height: 1.6, fontSize: 14)),
          const Divider(height: 40),
          Row(
            children: [
              _ActionBtn(icon: Icons.edit_outlined, label: 'Edit', onTap: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit feature coming soon!')));
              }),
              const SizedBox(width: 30),
              _ActionBtn(icon: Icons.delete_outline_rounded, label: 'Delete', onTap: () {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delete feature coming soon!')));
              }),
            ],
          )
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF18453B)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF18453B))),
        ],
      ),
    );
  }
}
