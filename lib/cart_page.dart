import 'package:flutter/material.dart';
import 'cart_manager.dart';
import 'checkout_page.dart';
import 'main.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final cart = CartManager();

  @override
  void initState() {
    super.initState();
    cart.addListener(_update);
  }

  @override
  void dispose() {
    cart.removeListener(_update);
    super.dispose();
  }

  void _update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'MY CART',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Your cart is empty', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => MainScreen.of(context)?.setIndex(0),
                    child: const Text('GO SHOPPING'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      ...cart.items.map((item) => _CartItemTile(item: item)),
                      const SizedBox(height: 10),
                      _PromoCodeSection(cart: cart),
                    ],
                  ),
                ),
                _CartSummary(cart: cart),
              ],
            ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(item.product.image, width: 80, height: 80, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 40)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50)),
                ),
                const SizedBox(height: 4),
                Text(item.weight, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 8),
                Text(
                  item.product.price,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFFD35400)),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _QuantityBtn(icon: Icons.remove, onTap: () => CartManager().updateQuantity(item, -1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              _QuantityBtn(icon: Icons.add, onTap: () => CartManager().updateQuantity(item, 1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QuantityBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: Colors.black87),
      ),
    );
  }
}

class _PromoCodeSection extends StatefulWidget {
  final CartManager cart;
  const _PromoCodeSection({required this.cart});

  @override
  State<_PromoCodeSection> createState() => _PromoCodeSectionState();
}

class _PromoCodeSectionState extends State<_PromoCodeSection> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Have a Promo Code?', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (widget.cart.appliedPromoCode.isEmpty)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter code (e.g. FIRST30)',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    bool success = widget.cart.applyPromoCode(_controller.text);
                    if (!success) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Code')));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C3E50)),
                  child: const Text('APPLY'),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Code Applied: ${widget.cart.appliedPromoCode}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () => widget.cart.removePromoCode(), child: const Text('REMOVE', style: TextStyle(color: Colors.red))),
              ],
            ),
        ],
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -10)),
        ],
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Subtotal', value: '₹${cart.subtotal.toStringAsFixed(0)}'),
          if (cart.discountAmount > 0) ...[
            const SizedBox(height: 12),
            _SummaryRow(label: 'Discount', value: '-₹${cart.discountAmount.toStringAsFixed(0)}', isDiscount: true),
          ],
          const SizedBox(height: 12),
          _SummaryRow(label: 'Delivery Fee', value: '₹${cart.deliveryFee.toStringAsFixed(0)}'),
          const Divider(height: 32),
          _SummaryRow(label: 'Total', value: '₹${cart.total.toStringAsFixed(0)}', isBold: true),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CheckoutPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD35400),
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text(
                'CHECKOUT',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isDiscount;

  const _SummaryRow({required this.label, required this.value, this.isBold = false, this.isDiscount = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 18 : 15,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w500,
            color: isBold ? const Color(0xFF2C3E50) : (isDiscount ? Colors.green : Colors.grey),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 22 : 16,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
            color: isBold ? const Color(0xFFD35400) : (isDiscount ? Colors.green : Colors.black87),
          ),
        ),
      ],
    );
  }
}
