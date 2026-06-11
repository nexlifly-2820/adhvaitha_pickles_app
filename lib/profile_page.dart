import 'package:flutter/material.dart';
import 'main.dart';
import 'order_history_page.dart';
import 'shipping_address_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(title: const Text('MY ACCOUNT')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // Advanced User Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFD35400), width: 3),
                        ),
                        child: const CircleAvatar(
                          radius: 50,
                          backgroundColor: Color(0xFFF1F2F3),
                          backgroundImage: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200'),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Color(0xFFD35400), shape: BoxShape.circle),
                          child: const Icon(Icons.edit, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Hemanth Silla', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2C3E50))),
                  const Text('hemanthsilla555@gmail.com', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('12', 'Orders'),
                      _buildStatLine(),
                      _buildStatItem('5', 'Reviews'),
                      _buildStatLine(),
                      _buildStatItem('₹450', 'Wallet'),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Modern Menu Grid
            _buildSectionTitle('Order Management'),
            const SizedBox(height: 16),
            _ProfileMenuTile(
              icon: Icons.list_alt_rounded, 
              title: 'My Orders',
              subtitle: 'Check order status & history',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderHistoryPage())),
            ),
            _ProfileMenuTile(
              icon: Icons.favorite_border_rounded, 
              title: 'Wishlist',
              subtitle: 'View your favorite flavors',
              onTap: () => MainScreen.of(context)?.setIndex(1),
            ),
            _ProfileMenuTile(
              icon: Icons.location_on_outlined, 
              title: 'Shipping Address',
              subtitle: 'Manage your delivery locations',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ShippingAddressPage())),
            ),
            
            const SizedBox(height: 32),
            _buildSectionTitle('Settings & Support'),
            const SizedBox(height: 16),
            _ProfileMenuTile(
              icon: Icons.payment_rounded, 
              title: 'Payment Methods', 
              subtitle: 'Saved cards & UPI', 
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment feature coming soon!')))
            ),
            _ProfileMenuTile(
              icon: Icons.notifications_none_rounded, 
              title: 'Notifications', 
              subtitle: 'Customize alerts', 
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications settings coming soon!')))
            ),
            _ProfileMenuTile(
              icon: Icons.help_outline_rounded, 
              title: 'Help & Support', 
              subtitle: 'Get expert assistance', 
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Our support team will contact you soon!')))
            ),
            
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out successfully')));
                        }, 
                        child: const Text('LOGOUT', style: TextStyle(color: Colors.red))
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('LOGOUT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C3E50),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Colors.grey.shade400,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFD35400))),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatLine() {
    return Container(height: 30, width: 1, color: Colors.grey.shade200);
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFD35400).withOpacity(0.08),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: const Color(0xFFD35400), size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF2C3E50))),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade300),
        onTap: onTap,
      ),
    );
  }
}
