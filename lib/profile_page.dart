import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';
import 'order_history_page.dart';
import 'shipping_address_page.dart';
import 'coupons_page.dart';
import 'contact_us_page.dart';
import 'navigation_util.dart';
import 'edit_profile_page.dart';
import 'rewards_page.dart';
import 'payment_methods_page.dart';
import 'notification_settings_page.dart';
import 'privacy_policy_page.dart';
import 'kitchen_story_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildStatsBar(context),
                  const SizedBox(height: 40),
                  
                  _buildMenuSection(context, 'ACCOUNT SETTINGS', [
                    _MenuTile(icon: Icons.person_outline_rounded, label: 'Edit Profile', onTap: () => AppNavigator.push(context, const EditProfilePage())),
                    _MenuTile(icon: Icons.location_on_outlined, label: 'Saved Addresses', onTap: () => AppNavigator.push(context, const ShippingAddressPage())),
                    _MenuTile(icon: Icons.local_offer_outlined, label: 'Coupons & Offers', onTap: () => AppNavigator.push(context, const CouponsPage())),
                    _MenuTile(icon: Icons.payment_rounded, label: 'Payment Methods', onTap: () => AppNavigator.push(context, const PaymentMethodsPage())),
                  ]),

                  const SizedBox(height: 30),

                  _buildMenuSection(context, 'SUPPORT & LEGAL', [
                    _MenuTile(icon: Icons.chat_bubble_outline_rounded, label: 'Contact Us', onTap: () => AppNavigator.push(context, const ContactUsPage())),
                    _MenuTile(icon: Icons.auto_awesome_outlined, label: 'Our Story', onTap: () => AppNavigator.push(context, const KitchenStoryPage())),
                    _MenuTile(icon: Icons.notifications_none_rounded, label: 'Notifications', onTap: () => AppNavigator.push(context, const NotificationSettingsPage())),
                    _MenuTile(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () => AppNavigator.push(context, const PrivacyPolicyPage())),
                  ]),

                  const SizedBox(height: 50),
                  _buildLogoutButton(context),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: const Color(0xFF18453B),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFF18453B)),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Hero(
                    tag: 'profile_avatar',
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
                      ),
                      child: const CircleAvatar(
                        backgroundColor: Color(0xFF18453B),
                        child: Icon(Icons.person_rounded, size: 60, color: Color(0xFFD4AF37)),
                      ),
                    ),
                  ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
                  const SizedBox(height: 20),
                  Text(
                    'HEMANTH SILLA',
                    style: GoogleFonts.philosopher(fontSize: 26, fontWeight: FontWeight.w900, color: const Color(0xFFD4AF37), letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Royal Member since 2023',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'ORDERS', val: '12', onTap: () => AppNavigator.push(context, const OrderHistoryPage())),
          _StatItem(label: 'WISHLIST', val: '5', onTap: () => MainScreen.of(context)?.setIndex(2)),
          _StatItem(label: 'COINS', val: '450', onTap: () => AppNavigator.push(context, const RewardsPage())),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildMenuSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 15),
          child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2)),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            clipBehavior: Clip.antiAlias,
            child: Column(children: items),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        _showLogoutDialog(context);
      },
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.shade100, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: const Text('LOGOUT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 13)),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8E8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to end your royal session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out successfully')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, val;
  final VoidCallback onTap;
  const _StatItem({required this.label, required this.val, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF18453B))),
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFF18453B).withOpacity(0.05), shape: BoxShape.circle),
        child: Icon(icon, color: const Color(0xFF18453B), size: 18),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
