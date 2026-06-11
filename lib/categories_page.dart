import 'package:flutter/material.dart';
import 'product_listing_page.dart';
import 'navigation_util.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {'title': 'Pickles', 'icon': '🥭', 'color': const Color(0xFFE67E22)},
      {'title': 'Snacks', 'icon': '🍘', 'color': const Color(0xFFF1C40F)},
      {'title': 'Spices', 'icon': '🌶️', 'color': const Color(0xFFC0392B)},
      {'title': 'Sweets', 'icon': '🍬', 'color': const Color(0xFF9B59B6)},
      {'title': 'Combos', 'icon': '🎁', 'color': const Color(0xFF27AE60)},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        title: const Text('CATEGORIES'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.1,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return GestureDetector(
            onTap: () {
              AppNavigator.push(context, ProductListingPage(category: cat['title']));
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      color: cat['color'].withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(cat['icon'], style: const TextStyle(fontSize: 32)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    cat['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Color(0xFF18453B),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
