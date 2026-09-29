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
import 'terms_of_service_page.dart';
import 'refund_policy_page.dart';
import 'faq_page.dart';
import 'kitchen_story_page.dart';
import 'account_deletion_page.dart';
import 'app_update_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      body: Stack(
        children: [
          // 1. Full-screen background image matching profile_bg_screen.png
          Positioned.fill(
            child: Image.asset(
              'assets/images/profile_bg_screen.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (c, e, s) => Container(color: const Color(0xFF18453B)),
            ),
          ),

          // 2. Main Scrollable Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header Bar: Script Text (Left) & Actions (Right)
                  _buildTopHeaderBar(context),

                  // Profile Header Row: Name & Badges (Left) and Profile Picture (Right)
                  _buildProfileHeader(context),

                  const SizedBox(height: 16),

                  // Stats Glass Card: Orders, Wishlist
                  _buildStatsCard(context),

                  const SizedBox(height: 16),

                  // Account Settings Section
                  _buildSectionHeader('ACCOUNT SETTINGS', 'Manage Your Account'),
                  const SizedBox(height: 6),
                  _buildMenuCard(
                    icon: Icons.person_outline_rounded,
                    title: 'Edit Profile',
                    subtitle: 'Update your personal information',
                    onTap: () => AppNavigator.push(context, const EditProfilePage()),
                  ),
                  _buildMenuCard(
                    icon: Icons.location_on_outlined,
                    title: 'Saved Addresses',
                    subtitle: 'Manage your delivery addresses',
                    onTap: () => AppNavigator.push(context, const ShippingAddressPage()),
                  ),
                  _buildMenuCard(
                    icon: Icons.local_offer_outlined,
                    title: 'Coupons & Offers',
                    subtitle: 'View and apply exciting offers',
                    onTap: () => AppNavigator.push(context, const CouponsPage()),
                  ),
                  _buildMenuCard(
                    icon: Icons.payment_rounded,
                    title: 'Payment Methods',
                    subtitle: 'Manage your cards, UPI & wallets',
                    onTap: () => AppNavigator.push(context, const PaymentMethodsPage()),
                  ),

                  const SizedBox(height: 20),

                  // Support & Legal Section
                  _buildSectionHeader('SUPPORT & LEGAL', "We're Here to Help"),
                  const SizedBox(height: 6),
                  _buildMenuCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Contact Us',
                    subtitle: 'Get in touch with our team',
                    onTap: () => AppNavigator.push(context, const ContactUsPage()),
                  ),
                  _buildMenuCard(
                    icon: Icons.help_outline_rounded,
                    title: 'Help Center (FAQ)',
                    subtitle: 'Find answers to common questions',
                    onTap: () => AppNavigator.push(context, const FaqPage()),
                  ),
                  _buildMenuCard(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Our Story',
                    subtitle: 'Know more about our journey',
                    onTap: () => AppNavigator.push(context, const KitchenStoryPage()),
                  ),
                  _buildMenuCard(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    subtitle: 'Manage your notification preferences',
                    onTap: () => AppNavigator.push(context, const NotificationSettingsPage()),
                  ),
                  _buildMenuCard(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'How we protect your data',
                    onTap: () => AppNavigator.push(context, const PrivacyPolicyPage()),
                  ),
                  _buildMenuCard(
                    icon: Icons.gavel_rounded,
                    title: 'Terms of Service',
                    subtitle: 'Terms & conditions for using our app',
                    onTap: () => AppNavigator.push(context, const TermsOfServicePage()),
                  ),
                  _buildMenuCard(
                    icon: Icons.assignment_return_outlined,
                    title: 'Refund & Returns',
                    subtitle: 'Order cancellation & refund policy',
                    onTap: () => AppNavigator.push(context, const RefundPolicyPage()),
                  ),
                  _buildMenuCard(
                    icon: Icons.system_update_alt_rounded,
                    title: 'Check for Updates',
                    subtitle: 'Ensure you have the latest app version',
                    onTap: () => AppNavigator.push(context, const AppUpdatePage()),
                  ),
                  _buildMenuCard(
                    icon: Icons.no_accounts_rounded,
                    title: 'Delete Account',
                    subtitle: 'Permanently remove profile & data',
                    onTap: () => AppNavigator.push(context, const AccountDeletionPage()),
                  ),

                  const SizedBox(height: 24),

                  // Logout Button
                  _buildLogoutButton(context),

                  const SizedBox(height: 28),

                  // Powered by Nexlifly branding
                  _buildNexliflyBranding(),

                  const SizedBox(height: 110),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeaderBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Script branding text top-left removed

          const Spacer(), // Pushes the icons to the right

          // Actions top-right: Settings & Global Cart Badge
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  AppNavigator.push(context, const EditProfilePage());
                },
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    size: 20,
                    color: Color(0xFF18453B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const GlobalCartBadge(),
            ],
          ).animate().fadeIn(duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Welcome Back, Name, Member since, Quote
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  'Welcome Back',
                  style: GoogleFonts.philosopher(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFFE5C158),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'HEMANTH SILLA',
                  style: GoogleFonts.philosopher(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Member since 2023',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Right Column: Avatar with Gold Ring
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with Glowing Gold Ring
              Hero(
                tag: 'profile_avatar',
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE5C158), width: 3.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Container(
                      color: const Color(0xFF152A22),
                      child: const Center(
                        child: Icon(
                          Icons.person_rounded,
                          size: 70,
                          color: Color(0xFFF3E5AB),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildStatsCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF232E27),
            Color(0xFF121A16),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatColumn(
            context: context,
            icon: Icons.shopping_bag_outlined,
            value: '12',
            title: 'Orders',
            subtitle: 'Tastes Ordered',
            onTap: () => AppNavigator.push(context, const OrderHistoryPage()),
          ),
          _buildVerticalDivider(),
          _buildStatColumn(
            context: context,
            icon: Icons.favorite_border_rounded,
            value: '5',
            title: 'Wishlist',
            subtitle: 'Your Favorites',
            onTap: () => MainScreen.of(context)?.setIndex(2),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 48,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }

  Widget _buildStatColumn({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E3D34),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4), width: 0.8),
                ),
                child: Icon(icon, color: const Color(0xFFE5C158), size: 18),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: GoogleFonts.philosopher(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFF8E8),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFF5A5A5A),
              letterSpacing: 1.5,
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              height: 1,
              color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.satisfy(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF18453B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1E9D6), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF4F0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: const Color(0xFF18453B), size: 19),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF332020),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.heavyImpact();
            _showLogoutDialog(context);
          },
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'LOGOUT',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 350.ms);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8E8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to end your royal session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );
  }

  Widget _buildNexliflyBranding() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 1,
              width: 30,
              color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
            ),
            const SizedBox(width: 15),
            Text(
              'POWERED BY',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Colors.grey.withValues(alpha: 0.6),
                letterSpacing: 3,
              ),
            ),
            const SizedBox(width: 15),
            Container(
              height: 1,
              width: 30,
              color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'NEXLIFLY',
          style: GoogleFonts.philosopher(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF18453B).withValues(alpha: 0.4),
            letterSpacing: 4,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }
}
