class OrderItem {
  final dynamic productId;
  final String name;
  final String category;
  final String weight;
  final int qty;
  final double price;
  final String imageUrl;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.category,
    required this.weight,
    required this.qty,
    required this.price,
    required this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) {
        final cleaned = val.replaceAll(RegExp(r'[^0-9.]'), '');
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    int parseQty(dynamic val) {
      if (val == null) return 1;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 1;
      return 1;
    }

    return OrderItem(
      productId: json['product_id'] ?? json['productId'] ?? json['id'] ?? '',
      name: json['name']?.toString() ?? 'Homemade Product',
      category: json['category']?.toString() ?? 'Pickles',
      weight: json['weight']?.toString() ?? '500g',
      qty: parseQty(json['qty'] ?? json['quantity']),
      price: parsePrice(json['price']),
      imageUrl: json['image_url']?.toString() ??
          json['imageUrl']?.toString() ??
          json['image']?.toString() ??
          '',
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'name': name,
        'category': category,
        'weight': weight,
        'qty': qty,
        'price': price,
        'image_url': imageUrl,
      };
}
