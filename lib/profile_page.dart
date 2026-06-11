import 'package:flutter/material.dart';
import 'main.dart';
import 'order_history_page.dart';
import 'shipping_address_page.dart';
import 'coupons_page.dart';
import 'contact_us_page.dart';
import 'navigation_util.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(title: const Text('MY PROFILE')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          children: [
            // PROFILE HEADER
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF18453B),
                    child: Icon(Icons.person_rounded, size: 50, color: Color(0xFFD4AF37)),
                  ),
                  const SizedBox(height: 15),
                  const Text('HEMANTH SILLA', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF18453B))),
                  Text('hemanth.s@example.com', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Stat(label: 'Orders', val: '12', onTap: () => AppNavigator.push(context, const OrderHistoryPage())),
                      _Stat(label: 'Wishlist', val: '5', onTap: () => MainScreen.of(context)?.setIndex(2)),
                      _Stat(label: 'Rewards', val: '450', onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rewards Page coming soon!')));
                      }),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 35),
            
            // MENU ITEMS
            _MenuSection(title: 'ACCOUNT SETTINGS', items: [
              _MenuItem(icon: Icons.person_outline_rounded, label: 'Edit Profile', onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit Profile coming soon!')));
              }),
              _MenuItem(icon: Icons.location_on_outlined, label: 'Saved Addresses', onTap: () => AppNavigator.push(context, const ShippingAddressPage())),
              _MenuItem(icon: Icons.local_offer_outlined, label: 'Coupons & Offers', onTap: () => AppNavigator.push(context, const CouponsPage())),
              _MenuItem(icon: Icons.payment_rounded, label: 'Payment Methods', onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Methods coming soon!')));
              }),
            ]),

            const SizedBox(height: 25),
            _MenuSection(title: 'SUPPORT', items: [
              _MenuItem(icon: Icons.chat_bubble_outline_rounded, label: 'Contact Us', onTap: () => AppNavigator.push(context, const ContactUsPage())),
              _MenuItem(icon: Icons.info_outline_rounded, label: 'About Adhvaitha', onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('About Us coming soon!')));
              }),
              _MenuItem(icon: Icons.notifications_none_rounded, label: 'Notifications', onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification Settings coming soon!')));
              }),
              _MenuItem(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Privacy Policy coming soon!')));
              }),
            ]),

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
                backgroundColor: const Color(0xFF18453B),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, val;
  final VoidCallback onTap;
  const _Stat({required this.label, required this.val, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF18453B))),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 12),
          child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFF18453B).withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF18453B), size: 20),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }
}
