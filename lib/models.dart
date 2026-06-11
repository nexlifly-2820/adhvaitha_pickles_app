import 'package:flutter/material.dart';

class Review {
  final String userName;
  final String comment;
  final double rating;
  final String date;

  Review({
    required this.userName,
    required this.comment,
    required this.rating,
    required this.date,
  });
}

class Product {
  final String name;
  final String description;
  final Map<String, double> weightPriceMap;
  final double rating;
  final String image;
  final Color color;
  final String category;
  final int spiceLevel; // 1 to 5
  final List<String> pairings;
  final List<Review> reviews;
  final bool isBestSeller;
  final String origin;
  final List<String> ingredients;
  final String preparationMethod;
  final String shelfLife;

  Product({
    required this.name,
    required this.description,
    required this.weightPriceMap,
    required this.rating,
    required this.image,
    required this.color,
    required this.category,
    this.spiceLevel = 3,
    this.pairings = const ['Rice', 'Idli', 'Dosa'],
    this.reviews = const [],
    this.isBestSeller = false,
    this.origin = 'Coastal Andhra, India',
    this.ingredients = const ['Fresh Produce', 'Cold Pressed Oil', 'Sea Salt', 'Traditional Spices'],
    this.preparationMethod = 'Handmade in small batches using traditional sun-drying and stone-grinding techniques.',
    this.shelfLife = '6 Months from date of manufacture',
  });

  // Helper to get formatted price for a specific weight
  String getPriceForWeight(String weight) {
    double price = weightPriceMap[weight] ?? 0;
    return '₹${price.toStringAsFixed(0)}';
  }

  // Helper to get raw price for calculations
  double getRawPriceForWeight(String weight) {
    return weightPriceMap[weight] ?? 0;
  }

  // Get default price (usually first weight in map)
  String get defaultPrice => getPriceForWeight(weightPriceMap.keys.first);
  String get defaultWeight => weightPriceMap.keys.first;
}

class CartItem {
  final Product product;
  int quantity;
  String weight;

  CartItem({required this.product, this.quantity = 1, this.weight = '500g'});
}

class Order {
  final String id;
  final List<CartItem> items;
  final double total;
  final DateTime date;
  final String status;

  Order({
    required this.id,
    required this.items,
    required this.total,
    required this.date,
    required this.status,
  });
}
