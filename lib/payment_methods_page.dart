import 'package:flutter/material.dart';

class PaymentMethodsPage extends StatelessWidget {
  const PaymentMethodsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(title: const Text('PAYMENT METHODS')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SAVED CARDS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Color(0xFF18453B))),
            const SizedBox(height: 20),
            _buildCard('HDFC Bank', '**** **** **** 4521', '08/27', 'VISA'),
            _buildCard('ICICI Bank', '**** **** **** 9088', '12/25', 'MASTERCARD'),
            
            const SizedBox(height: 40),
            const Text('UPI & WALLETS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Color(0xFF18453B))),
            const SizedBox(height: 20),
            _buildUpiItem('Google Pay', 'hemanthsilla@okaxis', 'assets/images/gpay.png'),
            _buildUpiItem('PhonePe', '9876543210@ybl', 'assets/images/phonepe.png'),

            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded),
              label: const Text('ADD NEW PAYMENT METHOD'),
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

  Widget _buildCard(String bank, String number, String expiry, String type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: type == 'VISA' ? [const Color(0xFF1A237E), const Color(0xFF3949AB)] : [const Color(0xFF37474F), const Color(0xFF546E7A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(bank, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(type, style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 30),
          Text(number, style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CARD HOLDER', style: TextStyle(color: Colors.white54, fontSize: 10)),
                  Text('HEMANTH SILLA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('EXPIRES', style: TextStyle(color: Colors.white54, fontSize: 10)),
                  Text(expiry, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildUpiItem(String title, String id, String iconPath) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF18453B)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(id, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.check_circle_rounded, color: Colors.green),
      ),
    );
  }
}
