import 'package:flutter/material.dart';
import 'checkout_address_screen.dart';
import 'checkout_billing_screen.dart';
import 'checkout_payment_screen.dart';
import 'order_placed_screen.dart';
import 'cart_manager.dart';
import 'navigation_util.dart';
import 'order_history_page.dart';

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
                  "photo": ci.product.image,
                }).toList();
                CartManager().clearCart();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => OrderPlacedScreen(
                    apiBase: apiBase,
                    orderId: '${order['id'] ?? 'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}'}',
                    logoAsset: 'assets/images/AMBHUJAKSHI  logo.png',
                    initialItems: orderedItems,
                    onTrack: (id) => AppNavigator.push(context, const OrderHistoryPage()),
                    onContinue: () => Navigator.popUntil(context, (r) => r.isFirst),
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
