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
  final String price;
  final String weight;
  final double rating;
  final String image;
  final Color color;
  final String category;
  final int spiceLevel; // 1 to 5
  final List<String> pairings;
  final List<Review> reviews;
  final bool isBestSeller;

  Product({
    required this.name,
    required this.description,
    required this.price,
    required this.weight,
    required this.rating,
    required this.image,
    required this.color,
    required this.category,
    this.spiceLevel = 3,
    this.pairings = const ['Rice', 'Idli', 'Dosa'],
    this.reviews = const [],
    this.isBestSeller = false,
  });
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
