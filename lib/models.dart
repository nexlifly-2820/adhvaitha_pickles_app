import 'package:flutter/material.dart';

class Review {
  final String? id;
  final String userName;
  final String comment;
  final double rating;
  final String date;
  final String status; // "pending", "approved", "rejected"

  Review({
    this.id,
    required this.userName,
    required this.comment,
    required this.rating,
    required this.date,
    this.status = 'approved',
  });
}

class IngredientDetail {
  final String name;
  final String description;
  final String image;

  IngredientDetail({required this.name, required this.description, required this.image});
}

class SommelierPairing {
  final String title;
  final String description;
  final IconData icon;

  SommelierPairing({required this.title, required this.description, required this.icon});
}

class Product {
  final String name;
  final String description;
  final Map<String, double> weightPriceMap;
  final double rating;
  final String image;
  final Color color;
  final String category;
  final List<String> pairings;
  final List<Review> reviews;
  final bool isBestSeller;
  final String origin;
  final List<String> ingredients;
  final String preparationMethod;
  final String shelfLife;
  final String storageInstructions;
  final String servingSuggestion;
  final IngredientDetail secretIngredient;
  final bool canRequestTempering;
  final List<SommelierPairing> sommelierPairings;
  final bool isOutOfStock;
  final int stockCount;
  final bool isVeg;
  final String subCategory;
  final int viewCount;
  final int purchaseCount;
  final List<String> trustBadges;
  final String artisanName;
  final String artisanImage;
  final String artisanDescription;
  final List<Map<String, String>> recipes;

  Product({
    required this.name,
    required this.description,
    required this.weightPriceMap,
    required this.rating,
    required this.image,
    required this.color,
    required this.category,
    this.pairings = const ['Rice', 'Idli', 'Dosa'],
    this.reviews = const [],
    this.isBestSeller = false,
    this.origin = 'Coastal Andhra, India',
    this.ingredients = const ['Fresh Produce', 'Cold Pressed Oil', 'Sea Salt', 'Traditional Spices'],
    this.preparationMethod = 'Handmade in small batches using traditional sun-drying and stone-grinding techniques. No heat is used in the spice grinding process to preserve essential oils.',
    this.shelfLife = '6 Months from date of manufacture',
    this.storageInstructions = 'Store in a cool, dry place. Use a dry spoon only. Ensure the oil layer covers the pickle for longevity.',
    this.servingSuggestion = 'Pairs best with steaming hot rice and a dollop of ghee. Also complements breakfast items like Idli and Dosa.',
    required this.secretIngredient,
    this.canRequestTempering = false,
    this.sommelierPairings = const [],
    this.isOutOfStock = false,
    this.stockCount = 100,
    this.isVeg = true,
    this.subCategory = 'Classic',
    this.viewCount = 42,
    this.purchaseCount = 15,
    this.trustBadges = const ['Zero Preservatives', 'Sun-Dried', 'Hand-Sorted', 'Stone-Pounded'],
    this.artisanName = 'Smt. Annapurna',
    this.artisanImage = 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
    this.artisanDescription = 'Our Master Pickle Maker with over 40 years of experience in traditional preservation.',
    this.recipes = const [
      {'title': 'The Coastal Classic', 'instruction': 'Mix with steaming hot rice and a generous dollop of Desi Ghee for the most authentic experience.'},
      {'title': 'Spicy Marinade', 'instruction': 'Use 2 tablespoons as a marinade for grilled prawns or paneer to add a deep, tangy kick.'}
    ],
  });

  Product copyWith({
    String? name,
    String? description,
    Map<String, double>? weightPriceMap,
    double? rating,
    String? image,
    Color? color,
    String? category,
    List<String>? pairings,
    List<Review>? reviews,
    bool? isBestSeller,
    String? origin,
    List<String>? ingredients,
    String? preparationMethod,
    String? shelfLife,
    String? storageInstructions,
    String? servingSuggestion,
    IngredientDetail? secretIngredient,
    bool? canRequestTempering,
    List<SommelierPairing>? sommelierPairings,
    bool? isOutOfStock,
    int? stockCount,
    bool? isVeg,
    String? subCategory,
    int? viewCount,
    int? purchaseCount,
    List<String>? trustBadges,
    String? artisanName,
    String? artisanImage,
    String? artisanDescription,
    List<Map<String, String>>? recipes,
  }) {
    return Product(
      name: name ?? this.name,
      description: description ?? this.description,
      weightPriceMap: weightPriceMap ?? this.weightPriceMap,
      rating: rating ?? this.rating,
      image: image ?? this.image,
      color: color ?? this.color,
      category: category ?? this.category,
      pairings: pairings ?? this.pairings,
      reviews: reviews ?? this.reviews,
      isBestSeller: isBestSeller ?? this.isBestSeller,
      origin: origin ?? this.origin,
      ingredients: ingredients ?? this.ingredients,
      preparationMethod: preparationMethod ?? this.preparationMethod,
      shelfLife: shelfLife ?? this.shelfLife,
      storageInstructions: storageInstructions ?? this.storageInstructions,
      servingSuggestion: servingSuggestion ?? this.servingSuggestion,
      secretIngredient: secretIngredient ?? this.secretIngredient,
      canRequestTempering: canRequestTempering ?? this.canRequestTempering,
      sommelierPairings: sommelierPairings ?? this.sommelierPairings,
      isOutOfStock: isOutOfStock ?? this.isOutOfStock,
      stockCount: stockCount ?? this.stockCount,
      isVeg: isVeg ?? this.isVeg,
      subCategory: subCategory ?? this.subCategory,
      viewCount: viewCount ?? this.viewCount,
      purchaseCount: purchaseCount ?? this.purchaseCount,
      trustBadges: trustBadges ?? this.trustBadges,
      artisanName: artisanName ?? this.artisanName,
      artisanImage: artisanImage ?? this.artisanImage,
      artisanDescription: artisanDescription ?? this.artisanDescription,
      recipes: recipes ?? this.recipes,
    );
  }

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
  bool isTemperingRequested;
  String? chefNote;

  CartItem({
    required this.product, 
    this.quantity = 1, 
    this.weight = '500g',
    this.isTemperingRequested = false,
    this.chefNote,
  });
}

class Order {
  final String id;
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discountAmount;
  final double total;
  final DateTime date;
  final String status;
  final DateTime? estimatedDelivery;
  final String shippingAddress;
  final String paymentMethod;
  final String batchId;
  final DateTime? preparationDate;
  final String spiceOrigin;
  final String? trackingId;
  final String? courierName;

  Order({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.discountAmount,
    required this.total,
    required this.date,
    required this.status,
    this.estimatedDelivery,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.batchId,
    this.preparationDate,
    required this.spiceOrigin,
    this.trackingId,
    this.courierName,
  });
}
