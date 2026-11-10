import 'package:flutter/material.dart';
import 'widgets/combo_box_section.dart';
import 'cart_manager.dart';
import 'product_manager.dart';

class KitchenStoryPage extends StatelessWidget {
  const KitchenStoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ComboBoxScreen(
      apiBase: 'https://admin.adhvaithafoods.in/api',
      logoAsset: 'assets/images/AMBHUJAKSHI  logo.png',
      onAdded: () {
        CartManager().refreshProductData(ProductManager().products);
        Navigator.pop(context);
      },
      onBack: () => Navigator.maybePop(context),
    );
  }
}
