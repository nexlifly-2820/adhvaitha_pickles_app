// category_turntable_section.dart — drop-in replacement for the old WebView version.
// Keeps the SAME class name and parameters, so your Shop page code does not change,
// but now draws the native Flutter lazy susan from category_lazy_susan.dart (no WebView, no jumping,
// full width, fits on screen, product row with sample products).
//
// Needs category_lazy_susan.dart in the same folder.
// pubspec.yaml: you can remove webview_flutter and assets/category_turntable.html.
//               keep:  http, google_fonts, and  assets: - assets/images/

import 'package:flutter/material.dart';
import 'category_lazy_susan.dart';

class CategoryTurntableSection extends StatelessWidget {
  final String apiUrl;
  final Map<String, String>? headers;
  final ValueChanged<String>? onExplore, onProduct, onSelect;
  final String? initialCategoryId;
  final double reservedHeight; // space of your top bar + bottom menu; raise it if the product row is hidden
  const CategoryTurntableSection({super.key, required this.apiUrl, this.headers, this.onExplore, this.onProduct, this.onSelect, this.initialCategoryId, this.reservedHeight = 150});

  @override
  Widget build(BuildContext context) {
    return CategoryLazySusan(
      apiUrl: apiUrl,
      headers: headers,
      initialSlug: initialCategoryId,
      reservedHeight: reservedHeight,
      onExplore: (String id, String slug) => onExplore?.call(id),
      onProduct: onProduct,
      onSelect: onSelect,
    );
  }
}
