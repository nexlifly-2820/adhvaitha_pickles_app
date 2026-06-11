import 'package:flutter/material.dart';
import 'cart_manager.dart';
import 'checkout_page.dart';
import 'main.dart';
import 'models.dart';
import 'navigation_util.dart';

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
      appBar: AppBar(title: const Text('SHOPPING CART')),
      body: cart.items.isEmpty 
        ? Center(
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
          )
        : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return _CartItemTile(item: item);
                  },
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
    return Dismissible(
      key: Key(item.product.name + item.weight),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        CartManager().removeFromCart(item);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(item.product.image, width: 80, height: 80, fit: BoxFit.cover),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(item.weight, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 10),
                  Text(item.product.getPriceForWeight(item.weight), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF18453B))),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(onPressed: () => CartManager().removeFromCart(item), icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20)),
                Row(
                  children: [
                    _QtyBtn(icon: Icons.remove, onTap: () => CartManager().updateQuantity(item, -1)),
                    const SizedBox(width: 10),
                    Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    _QtyBtn(icon: Icons.add, onTap: () => CartManager().updateQuantity(item, 1)),
                  ],
                ),
              ],
            ),
          ],
        ),
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
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: const Color(0xFF18453B).withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: const Color(0xFF18453B)),
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
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -10))],
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', '₹${cart.subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 12),
          _summaryRow('Delivery Fee', '₹${cart.deliveryFee.toStringAsFixed(0)}'),
          const Divider(height: 30),
          _summaryRow('Total', '₹${cart.total.toStringAsFixed(0)}', isTotal: true),
          const SizedBox(height: 30),
          GestureDetector(
            onTap: () => AppNavigator.push(context, const CheckoutPage()),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF18453B), Color(0xFF276357)]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: const Color(0xFF18453B).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              alignment: Alignment.center,
              child: const Text('PROCEED TO CHECKOUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String val, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isTotal ? 18 : 14, fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500)),
        Text(val, style: TextStyle(fontSize: isTotal ? 24 : 16, fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold, color: isTotal ? const Color(0xFF18453B) : Colors.black)),
      ],
    );
  }
}
