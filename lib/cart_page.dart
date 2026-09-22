import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cart_manager.dart';
import 'checkout_page.dart';
import 'coupons_page.dart';
import 'main.dart';
import 'models.dart';
import 'navigation_util.dart';
import 'product_manager.dart';
import 'product_detail_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    CartManager().addListener(_update);
  }

  @override
  void dispose() {
    CartManager().removeListener(_update);
    super.dispose();
  }

  void _update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final cart = CartManager();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      body: Stack(
        children: [
          // 1. Background Image (fits 100% inside screen bounds)
          Positioned.fill(
            child: Image.asset(
              'assets/images/cart_bg_screen.png',
              fit: BoxFit.fill,
              alignment: Alignment.topCenter,
              errorBuilder: (c, e, s) => Container(color: const Color(0xFFFFF8E8)),
            ),
          ),

          // 2. Foreground Content
          SafeArea(
            child: Column(
              children: [
                // Top App Bar Header
                _buildHeader(context),

                Expanded(
                  child: cart.items.isEmpty
                      ? _buildEmptyState()
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          children: [
                            // Free Delivery Goal Card
                            _buildFreeDeliveryGoal(cart),
                            const SizedBox(height: 16),

                            // Cart Item Tiles
                            ...cart.items.map((item) => _CartItemTile(item: item)),

                            // Add More Flavors Button
                            _buildAddMoreButton(context),
                            const SizedBox(height: 12),

                            // Freshness Guaranteed Reassurance Card
                            _buildFreshnessGuaranteedCard(),
                            const SizedBox(height: 12),

                            // Apply Royal Promo Code Card
                            _buildPromoCodeCard(context, cart),
                            const SizedBox(height: 16),

                            // Upsell Recommendations
                            _buildUpsellSection(),
                            const SizedBox(height: 16),

                            // Bill Summary Box
                            _buildBillSummaryCard(cart),
                            const SizedBox(height: 18),

                            // Checkout Securely Button
                            _buildCheckoutButton(context, cart),
                            const SizedBox(height: 14),

                            // Trust Badges Row
                            _buildTrustIndicators(),
                            const SizedBox(height: 30),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Back Button on Top Left
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEFEFE2), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back, color: Color(0xFF0F382C), size: 20),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    MainScreen.of(context)?.setIndex(0);
                  }
                },
              ),
            ),
          ),

          // Title & Subtitle in Center
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ROYAL CART',
                style: GoogleFonts.philosopher(
                  color: const Color(0xFF0F382C),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Your favourite flavours, one step closer',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF555555),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 20, height: 1, color: const Color(0xFFD4AF37)),
                  const SizedBox(width: 5),
                  const Icon(Icons.eco_rounded, size: 9, color: Color(0xFFD4AF37)),
                  const SizedBox(width: 5),
                  Container(width: 20, height: 1, color: const Color(0xFFD4AF37)),
                ],
              ),
            ],
          ),

          // Top Right Cursive Text
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                'Good\nFood\nHappier\nDays ♡',
                textAlign: TextAlign.center,
                style: GoogleFonts.satisfy(
                  color: const Color(0xFF0F382C),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  height: 1.05,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFF0F382C).withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: Color(0xFF0F382C).withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Royal Cart is Empty',
              style: GoogleFonts.philosopher(
                fontSize: 22,
                color: const Color(0xFF0F382C),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Discover traditional homemade delicacies & authentic flavors.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () {
                MainScreen.of(context)?.setIndex(1);
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F382C),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F382C).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'GO SHOPPING',
                  style: GoogleFonts.philosopher(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeDeliveryGoal(CartManager cart) {
    final double remaining = cart.freeThreshold - cart.subtotal;
    final double progress = (cart.subtotal / cart.freeThreshold).clamp(0.0, 1.0);
    final bool isFree = remaining <= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF08372A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF08372A).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_rounded, color: Color(0xFFE5C778), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: isFree
                            ? "Congratulations! You've unlocked "
                            : "Add ₹${remaining.toStringAsFixed(0)} more for ",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: "FREE ROYAL DELIVERY",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFF3C74B),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 26,
                color: Colors.white.withValues(alpha: 0.2),
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.workspace_premium_rounded, color: Color(0xFFE5C778), size: 16),
                  const SizedBox(height: 2),
                  Text(
                    'Good Food\nTravels Farther ♡',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.satisfy(
                      color: const Color(0xFFE5C778),
                      fontSize: 9.5,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar Track
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE5C778)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 5),

          // Labels under Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹0',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '₹${cart.freeThreshold.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddMoreButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        MainScreen.of(context)?.setIndex(1);
        if (Navigator.canPop(context)) Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0F382C), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 22),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0F382C), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'ADD MORE FLAVORS',
                    style: GoogleFonts.philosopher(
                      color: const Color(0xFF0F382C),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.eco_rounded, color: Color(0xFF0F382C), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildFreshnessGuaranteedCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFE2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8E7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.access_time_filled_rounded,
              color: Color(0xFFE0A328),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FRESHNESS GUARANTEED',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.8,
                    color: const Color(0xFF0F382C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Order in the next 2 hrs for same-day dispatch.',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'FASTEST',
              style: GoogleFonts.poppins(
                color: const Color(0xFF2E7D32),
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodeCard(BuildContext context, CartManager cart) {
    final hasCode = cart.appliedPromoCode.isNotEmpty;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        AppNavigator.push(context, const CouponsPage());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasCode ? const Color(0xFF0F382C) : const Color(0xFFEFEFE2),
            width: hasCode ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.confirmation_num_outlined,
              color: Color(0xFFE0A328),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasCode ? 'Promo Code: ${cart.appliedPromoCode}' : 'Apply Royal Promo Code',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: const Color(0xFF0F382C),
                ),
              ),
            ),
            if (hasCode)
              GestureDetector(
                onTap: () => cart.removePromoCode(),
                child: const Icon(Icons.close_rounded, color: Colors.red, size: 18),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFE0A328),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpsellSection() {
    final cartNames = CartManager().items.map((i) => i.product.name).toList();
    final suggestions = ProductManager().products
        .where((p) => !cartNames.contains(p.name) && p.isBestSeller)
        .take(4)
        .toList();

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMPLETES THE EXPERIENCE',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 1.2,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final p = suggestions[index];
              return GestureDetector(
                onTap: () => AppNavigator.push(context, ProductDetailPage(product: p)),
                child: Container(
                  width: 250,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF0EFE6)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildImage(p.image, 65),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              p.name,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              p.defaultPrice,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F382C),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          CartManager().addToCart(p);
                        },
                        icon: const Icon(Icons.add_circle_rounded, color: Color(0xFFE0A328), size: 24),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBillSummaryCard(CartManager cart) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0EFE6), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', '₹${cart.subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _summaryRow(
            'Delivery Fee',
            cart.deliveryFee == 0 ? 'FREE' : '₹${cart.deliveryFee.toStringAsFixed(0)}',
            isFree: cart.deliveryFee == 0,
          ),
          if (cart.discountAmount > 0) ...[
            const SizedBox(height: 8),
            _summaryRow(
              'Discount',
              '-₹${cart.discountAmount.toStringAsFixed(0)}',
              isDiscount: true,
            ),
          ],
          const Divider(height: 24, color: Color(0xFFEEEEEE)),
          _summaryRow('Total Pay', '₹${cart.total.toStringAsFixed(0)}', isTotal: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String val, {bool isTotal = false, bool isFree = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 16 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? const Color(0xFF0F382C) : const Color(0xFF333333),
          ),
        ),
        Text(
          val,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 22 : 14,
            fontWeight: FontWeight.bold,
            color: isDiscount || isFree
                ? const Color(0xFF2E7D32)
                : (isTotal ? const Color(0xFF0F382C) : const Color(0xFF1A1A1A)),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutButton(BuildContext context, CartManager cart) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        AppNavigator.push(context, const CheckoutPage());
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF0F382C),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F382C).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'CHECKOUT SECURELY',
              style: GoogleFonts.philosopher(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.lock_rounded, color: Color(0xFFE5B842), size: 16),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _trustItem(Icons.verified_user_rounded, 'SECURE'),
        Container(width: 1, height: 12, color: Colors.grey.shade400, margin: const EdgeInsets.symmetric(horizontal: 16)),
        _trustItem(Icons.history_edu_rounded, 'HERITAGE'),
        Container(width: 1, height: 12, color: Colors.grey.shade400, margin: const EdgeInsets.symmetric(horizontal: 16)),
        _trustItem(Icons.eco_rounded, 'NATURAL'),
      ],
    );
  }

  Widget _trustItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade600),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildImage(String path, double size) {
    if (path.isEmpty) {
      return Container(width: size, height: size, color: Colors.grey.shade100, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey));
    }
    if (path.startsWith('http')) {
      return Image.network(
        path, width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(width: size, height: size, color: Colors.grey.shade100, child: const Icon(Icons.broken_image_outlined, color: Colors.grey)),
      );
    }
    String assetPath = path;
    if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/images/$path';
    }
    return Image.asset(
      assetPath, width: size, height: size, fit: BoxFit.cover,
      errorBuilder: (c, e, s) => Container(width: size, height: size, color: Colors.grey.shade100, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey)),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0EFE6), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _buildImage(item.product.image, 76),
          ),
          const SizedBox(width: 14),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.product.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: const Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.weight,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.isTemperingRequested) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.soup_kitchen_rounded, size: 11, color: Color(0xFFE65100)),
                      const SizedBox(width: 4),
                      Text(
                        'Freshly Tempered',
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          color: const Color(0xFFE65100),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  item.product.getPriceForWeight(item.weight),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F382C),
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),

          // Right Action Column (Delete & Quantity)
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  CartManager().removeFromCart(item);
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5ED),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _QtyBtn(
                      icon: Icons.remove,
                      onTap: () => CartManager().updateQuantity(item, -1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${item.quantity}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: const Color(0xFF0F382C),
                        ),
                      ),
                    ),
                    _QtyBtn(
                      icon: Icons.add,
                      onTap: () => CartManager().updateQuantity(item, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String path, double size) {
    if (path.isEmpty) {
      return Container(width: size, height: size, color: Colors.grey.shade100, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey));
    }
    if (path.startsWith('http')) {
      return Image.network(
        path, width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(width: size, height: size, color: Colors.grey.shade100, child: const Icon(Icons.broken_image_outlined, color: Colors.grey)),
      );
    }
    String assetPath = path;
    if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/images/$path';
    }
    return Image.asset(
      assetPath, width: size, height: size, fit: BoxFit.cover,
      errorBuilder: (c, e, s) => Container(width: size, height: size, color: Colors.grey.shade100, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey)),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, size: 12, color: const Color(0xFF0F382C)),
      ),
    );
  }
}
