import 'order_item.dart';

class OrderResult {
  final String status;
  final String orderId;
  final String deliveryDate;
  final double total;
  final List<OrderItem> items;
  final String? message;

  const OrderResult({
    required this.status,
    required this.orderId,
    required this.deliveryDate,
    required this.total,
    required this.items,
    this.message,
  });

  bool get isSuccess =>
      status.toLowerCase() == 'success' || status.toLowerCase() == 'ok';

  factory OrderResult.fromJson(Map<String, dynamic> json) {
    double parseTotal(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) {
        final cleaned = val.replaceAll(RegExp(r'[^0-9.]'), '');
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    final List<dynamic> rawItems =
        json['items'] is List ? json['items'] : [];
    final parsedItems = rawItems
        .map((i) => OrderItem.fromJson(Map<String, dynamic>.from(i as Map)))
        .toList();

    return OrderResult(
      status: json['status']?.toString() ?? 'success',
      orderId: json['order_id']?.toString() ??
          json['orderId']?.toString() ??
          'AMBJ${DateTime.now().year}1',
      deliveryDate: json['delivery_date']?.toString() ??
          json['deliveryDate']?.toString() ??
          'Fri, 9 Oct',
      total: parseTotal(json['total'] ?? json['total_amount']),
      items: parsedItems,
      message: json['message']?.toString(),
    );
  }
}
