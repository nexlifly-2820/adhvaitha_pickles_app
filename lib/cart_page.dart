import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'cart_manager.dart';
import 'checkout_page.dart';
import 'main.dart';
import 'models.dart';
import 'navigation_util.dart';
import 'product_manager.dart';
import 'product_repository.dart';
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
      appBar: AppBar(
        title: Text('ROYAL CART', style: GoogleFonts.philosopher(fontWeight: FontWeight.w900, letterSpacing: 1)),
        centerTitle: true,
      ),
      body: cart.items.isEmpty 
        ? _buildEmptyState()
        : Column(
            children: [
              _buildFreeDeliveryGoal(cart),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    ...cart.items.map((item) => _CartItemTile(item: item)).toList(),
                    _buildAddMoreButton(),
                    _buildDeliveryReassurance(),
                    _buildUpsellSection(),
                  ],
                ),
              ),
              _CartSummary(cart: cart),
            ],
          ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 100, color: const Color(0xFF18453B).withOpacity(0.1)),
          const SizedBox(height: 24),
          const Text('Your cart is empty', style: TextStyle(fontSize: 18, color: Color(0xFF2D1B12), fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => MainScreen.of(context)?.setIndex(0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF18453B), Color(0xFF276357)]),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: const Color(0xFF18453B).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: const Text('GO SHOPPING', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeDeliveryGoal(CartManager cart) {
    final double remaining = cart.freeThreshold - cart.subtotal;
    final double progress = (cart.subtotal / cart.freeThreshold).clamp(0.0, 1.0);
    final bool isFree = remaining <= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      color: const Color(0xFF18453B),
      child: Column(
        children: [
          Row(
            children: [
              Icon(isFree ? Icons.auto_awesome : Icons.local_shipping_rounded, color: const Color(0xFFD4AF37), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isFree 
                    ? "Congratulations! You've unlocked FREE ROYAL DELIVERY." 
                    : "Add ₹${remaining.toStringAsFixed(0)} more for FREE ROYAL DELIVERY",
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMoreButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 30),
      child: OutlinedButton.icon(
        onPressed: () {
          MainScreen.of(context)?.setIndex(1);
          if (Navigator.canPop(context)) Navigator.pop(context);
        },
        icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
        label: const Text('ADD MORE FLAVORS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF18453B),
          side: const BorderSide(color: Color(0xFF18453B), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  Widget _buildDeliveryReassurance() {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF18453B).withOpacity(0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Color(0xFFD4AF37), size: 24),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FRESHNESS GUARANTEED', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1, color: Color(0xFF18453B))),
                SizedBox(height: 2),
                Text('Order in the next 2 hrs for same-day dispatch.', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Text('FASTEST', style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildUpsellSection() {
    // Suggest pairings based on what's in cart (Simple logic: show top products not in cart)
    final cartNames = CartManager().items.map((i) => i.product.name).toList();
    final suggestions = ProductManager().products
        .where((p) => !cartNames.contains(p.name) && p.isBestSeller)
        .take(4)
        .toList();

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('COMPLETES THE EXPERIENCE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5, color: Colors.grey)),
        const SizedBox(height: 15),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final p = suggestions[index];
              return GestureDetector(
                onTap: () => AppNavigator.push(context, ProductDetailPage(product: p)),
                child: Container(
                  width: 260,
                  margin: const EdgeInsets.only(right: 15),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset(p.image, width: 60, height: 60, fit: BoxFit.cover)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(p.defaultPrice, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF18453B), fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          CartManager().addToCart(p);
                        }, 
                        icon: const Icon(Icons.add_circle, color: Color(0xFFD4AF37))
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
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(item.product.image, width: 70, height: 70, fit: BoxFit.cover),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF2D1B12))),
                Text(item.weight, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                if (item.isTemperingRequested) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.soup_kitchen_rounded, size: 10, color: Color(0xFFE65100)),
                      const SizedBox(width: 4),
                      const Text('Freshly Tempered', style: TextStyle(fontSize: 9, color: Color(0xFFE65100), fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Text(item.product.getPriceForWeight(item.weight), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF18453B), fontSize: 16)),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(onPressed: () => CartManager().removeFromCart(item), icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFFFF8E8), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    _QtyBtn(icon: Icons.remove, onTap: () => CartManager().updateQuantity(item, -1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    ),
                    _QtyBtn(icon: Icons.add, onTap: () => CartManager().updateQuantity(item, 1)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
        child: Icon(icon, size: 14, color: const Color(0xFF18453B)),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final CartManager cart;
  const _CartSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, -10))],
      ),
      child: Column(
        children: [
          _buildCouponSection(context),
          const SizedBox(height: 20),
          _summaryRow('Subtotal', '₹${cart.subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _summaryRow('Delivery Fee', cart.deliveryFee == 0 ? 'FREE' : '₹${cart.deliveryFee.toStringAsFixed(0)}', isFree: cart.deliveryFee == 0),
          const Divider(height: 30),
          _summaryRow('Total Pay', '₹${cart.total.toStringAsFixed(0)}', isTotal: true),
          const SizedBox(height: 25),
          _buildCheckoutButton(context),
          const SizedBox(height: 15),
          _buildTrustIndicators(),
        ],
      ),
    );
  }

  Widget _buildCouponSection(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Show Coupon Modal
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFD4AF37).withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2), style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            const Icon(Icons.confirmation_num_outlined, color: Color(0xFFD4AF37), size: 20),
            const SizedBox(width: 12),
            const Text('Apply Royal Promo Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF18453B))),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFD4AF37)),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => AppNavigator.push(context, const CheckoutPage()),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF18453B), Color(0xFF276357)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: const Color(0xFF18453B).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('CHECKOUT SECURELY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 14)),
            const SizedBox(width: 10),
            const Icon(Icons.lock_outline_rounded, color: Color(0xFFD4AF37), size: 16),
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(delay: 5.seconds, duration: 2.seconds);
  }

  Widget _buildTrustIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _trustItem(Icons.verified_user_rounded, 'SECURE'),
        const SizedBox(width: 20),
        _trustItem(Icons.history_edu_rounded, 'HERITAGE'),
        const SizedBox(width: 20),
        _trustItem(Icons.spa_rounded, 'NATURAL'),
      ],
    );
  }

  Widget _trustItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 10, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
      ],
    );
  }

  Widget _summaryRow(String label, String val, {bool isTotal = false, bool isFree = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isTotal ? 16 : 13, fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600, color: isTotal ? const Color(0xFF18453B) : Colors.black87)),
        Text(
          val, 
          style: TextStyle(
            fontSize: isTotal ? 22 : 14, 
            fontWeight: FontWeight.w900, 
            color: isFree ? Colors.green : (isTotal ? const Color(0xFF18453B) : Colors.black87)
          )
        ),
      ],
    );
  }
}
