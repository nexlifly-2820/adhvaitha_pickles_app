import 'package:flutter/material.dart';
import 'checkout_address_screen.dart';
import 'checkout_billing_screen.dart';
import 'checkout_payment_screen.dart';
import 'order_placed_screen.dart';
import 'cart_manager.dart';
import 'navigation_util.dart';
import 'order_history_page.dart';
import 'main.dart';
import 'order_manager.dart';
import 'models.dart';
import 'product_lookup.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    const apiBase = 'https://admin.adhvaithafoods.in/api';
    return CheckoutAddressScreen(
      apiBase: apiBase,
      amountToPay: CartManager().total,
      logoAsset: 'assets/images/AMBHUJAKSHI  logo.png',
      onContinue: (address) {
        AppNavigator.push(context, CheckoutBillingScreen(
          apiBase: apiBase,
          address: address,
          logoAsset: 'assets/images/AMBHUJAKSHI  logo.png',
          onBack: () => Navigator.pop(context),
          onContinue: (bill) {
            AppNavigator.push(context, CheckoutPaymentScreen(
              apiBase: apiBase,
              address: address,
              amountToPay: (bill['total'] is num) ? (bill['total'] as num).toDouble() : CartManager().total,
              logoAsset: 'assets/images/AMBHUJAKSHI  logo.png',
              onBack: () => Navigator.pop(context),
              onSuccess: (order) {
                final orderedItems = CartManager().items.map((ci) => {
                  "name": ci.product.name,
                  "qty": ci.quantity,
                  "price": ci.product.getRawPriceForWeight(ci.weight),
                  "photo": bestImageFor(ci.product.name, ci.product.image),
                }).toList();
                final String orderId = '${order['id'] ?? order['orderId'] ?? 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}'}';
                final CartManager cm = CartManager();
                OrderManager().recordPlacedOrder(
                  id: orderId,
                  items: List<CartItem>.from(cm.items),
                  subtotal: cm.subtotal,
                  deliveryFee: cm.deliveryFee,
                  discount: cm.discountAmount,
                  total: (bill['total'] is num) ? (bill['total'] as num).toDouble() : cm.total,
                  address: _addressText(address),
                  paymentMethod: '${order['paymentMethod'] ?? order['method'] ?? 'Online'}',
                );
                CartManager().clearCart();
                // grab these BEFORE the checkout screens are removed — their context stops working after that
                final NavigatorState nav = Navigator.of(context);
                final main = MainScreen.of(context);
                nav.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => OrderPlacedScreen(
                    apiBase: apiBase,
                    orderId: orderId,
                    logoAsset: 'assets/images/AMBHUJAKSHI  logo.png',
                    initialItems: orderedItems,
                    onTrack: (id) {
                      nav.popUntil((r) => r.isFirst);
                      if (main != null) {
                        main.setIndex(3); // Orders tab
                      } else {
                        nav.push(MaterialPageRoute(builder: (_) => const OrderHistoryPage()));
                      }
                    },
                    onContinue: () {
                      nav.popUntil((r) => r.isFirst);
                      main?.setIndex(0); // back to Home to keep shopping
                    },
                  )),
                  (r) => r.isFirst,
                );
              },
            ));
          },
        ));
      },
    );
  }
}

/// "Name · phone" on the first line, the full address on the second (read back by Order details).
String _addressText(Map<String, dynamic> a) {
  String g(String k) => '${a[k] ?? ''}'.trim();
  final String who = <String>[g('name'), g('phone')].where((String e) => e.isNotEmpty).join(' · ');
  final String place = <String>[g('house'), g('road'), g('city'), g('state')].where((String e) => e.isNotEmpty).join(', ');
  final String pin = g('pincode');
  final String type = g('type');
  return '${type.isNotEmpty ? '[$type] ' : ''}$who\n$place${pin.isNotEmpty ? ' - $pin' : ''}';
}
