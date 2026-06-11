import 'package:flutter/material.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(title: const Text('CONTACT US')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: Color(0xFF18453B),
              child: Icon(Icons.support_agent_rounded, size: 60, color: Color(0xFFD4AF37)),
            ),
            const SizedBox(height: 30),
            const Text('WE ARE HERE TO HELP', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF18453B), letterSpacing: 1.5)),
            const SizedBox(height: 10),
            Text('Reach out to us for any queries about our traditional flavors.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 50),
            _ContactTile(icon: Icons.chat_bubble_rounded, title: 'Chat on WhatsApp', sub: '+91 98765 43210', color: const Color(0xFF25D366), onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening WhatsApp...')));
            }),
            _ContactTile(icon: Icons.phone_rounded, title: 'Call Customer Care', sub: '1800-425-XXXX', color: const Color(0xFF18453B), onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calling Support...')));
            }),
            _ContactTile(icon: Icons.email_rounded, title: 'Email Support', sub: 'support@adhvaitha.com', color: const Color(0xFFD4AF37), onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Email...')));
            }),
            const SizedBox(height: 50),
            const Text('OPERATING HOURS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2, color: Colors.grey)),
            const SizedBox(height: 10),
            const Text('Mon - Sat: 9 AM to 8 PM', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF18453B))),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final Color color;
  final VoidCallback onTap;
  const _ContactTile({required this.icon, required this.title, required this.sub, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(sub, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF18453B))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
