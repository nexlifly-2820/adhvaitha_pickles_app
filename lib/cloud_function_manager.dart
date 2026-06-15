import 'package:cloud_functions/cloud_functions.dart';
import 'address_manager.dart';
import 'models.dart';

class CloudFunctionManager {
  static final CloudFunctionManager _instance = CloudFunctionManager._internal();
  factory CloudFunctionManager() => _instance;
  CloudFunctionManager._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Add Address via Cloud Function
  Future<bool> saveAddress({required String title, required String fullAddress}) async {
    try {
      final result = await _functions.httpsCallable('saveUserAddress').call({
        'title': title,
        'address': fullAddress,
        'isDefault': false,
      });
      
      if (result.data['success'] == true) {
        // Update local manager to reflect change immediately if desired
        AddressManager().addAddress(title, fullAddress);
        return true;
      }
      return false;
    } catch (e) {
      print('Error saving address: $e');
      return false;
    }
  }

  // Place Order via Cloud Function
  Future<Map<String, dynamic>> placeOrder({
    required List<CartItem> items,
    required double subtotal,
    required double deliveryFee,
    required double discountAmount,
    required double total,
    required String shippingAddress,
    required String paymentMethod,
  }) async {
    try {
      // Format items for the backend
      final formattedItems = items.map((item) => {
        'productId': item.product.name, // Usually use an ID, using name for now
        'name': item.product.name,
        'quantity': item.quantity,
        'weight': item.weight,
        'price': item.product.getRawPriceForWeight(item.weight),
        'tempering': item.isTemperingRequested,
        'chefNote': item.chefNote,
      }).toList();

      final result = await _functions.httpsCallable('createRoyalOrder').call({
        'items': formattedItems,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'discountAmount': discountAmount,
        'total': total,
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
      });

      return {
        'success': result.data['success'],
        'orderId': result.data['orderId'],
        'message': result.data['message'] ?? '',
      };
    } catch (e) {
      print('Error placing order: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
  // Admin: Get Dashboard Stats
  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    try {
      final result = await _functions.httpsCallable('getAdminDashboardStats').call();
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      print('Error getting stats: $e');
      return {};
    }
  }

  // Admin: Update Product
  Future<bool> adminUpdateProduct({required String productId, required Map<String, dynamic> updates}) async {
    try {
      final result = await _functions.httpsCallable('adminUpdateProduct').call({
        'productId': productId,
        'updates': updates,
      });
      return result.data['success'] == true;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  // CRM: Submit Contact Inquiry
  Future<bool> submitInquiry({required String name, required String email, required String phone, required String message}) async {
    try {
      final result = await _functions.httpsCallable('submitContactInquiry').call({
        'name': name,
        'email': email,
        'phone': phone,
        'message': message,
      });
      return result.data['success'] == true;
    } catch (e) {
      print('Error submitting inquiry: $e');
      return false;
    }
  }
}
