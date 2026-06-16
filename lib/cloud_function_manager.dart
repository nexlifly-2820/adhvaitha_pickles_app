import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'address_manager.dart';
import 'models.dart';

class CloudFunctionManager {
  static final CloudFunctionManager _instance = CloudFunctionManager._internal();
  factory CloudFunctionManager() => _instance;
  CloudFunctionManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // DIRECT FIRESTORE FIX: Saving address directly to avoid Cloud Function deployment issues
  Future<bool> saveAddress({required String title, required String fullAddress}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final docRef = _firestore.collection('users').doc(user.uid).collection('addresses').doc();
      await docRef.set({
        'id': docRef.id,
        'title': title,
        'fullAddress': fullAddress,
        'isDefault': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      AddressManager().addAddress(title, fullAddress);
      return true;
    } catch (e) {
      print('Error saving address: $e');
      return false;
    }
  }

  // DIRECT FIRESTORE FIX: Placing order directly to avoid Cloud Function deployment issues
  Future<Map<String, dynamic>> placeOrder({
    required List<CartItem> items,
    required double subtotal,
    required double deliveryFee,
    required double discountAmount,
    required double total,
    required String shippingAddress,
    required String paymentMethod,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'success': false, 'message': 'User not logged in'};

    try {
      final String orderId = 'ADH-${DateTime.now().millisecondsSinceEpoch}';
      
      final formattedItems = items.map((item) => {
        'name': item.product.name,
        'quantity': item.quantity,
        'weight': item.weight,
        'price': item.product.getRawPriceForWeight(item.weight),
        'tempering': item.isTemperingRequested,
        'chefNote': item.chefNote,
      }).toList();

      final orderData = {
        'orderId': orderId,
        'userId': user.uid,
        'items': formattedItems,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'discountAmount': discountAmount,
        'total': total,
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
        'status': "Placed",
        'date': FieldValue.serverTimestamp(),
        'estimatedDelivery': Timestamp.fromDate(DateTime.now().add(const Duration(days: 5))),
        'batchId': 'BCH-${DateTime.now().year}${DateTime.now().month}${DateTime.now().day}',
        'spiceOrigin': "Guntur Royal Markets",
      };

      await _firestore.collection('orders').doc(orderId).set(orderData);

      // Update User Summary
      await _firestore.collection('users').doc(user.uid).set({
        'lastOrderAt': FieldValue.serverTimestamp(),
        'totalOrders': FieldValue.increment(1),
        'totalSpent': FieldValue.increment(total)
      }, SetOptions(merge: true));

      return {
        'success': true,
        'orderId': orderId,
        'message': "Royal order placed successfully!"
      };
    } catch (e) {
      print('Error placing order: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // DIRECT FIRESTORE FIX: Submitting inquiry directly
  Future<bool> submitInquiry({required String name, required String email, required String phone, required String message}) async {
    try {
      await _firestore.collection('inquiries').add({
        'name': name,
        'email': email,
        'phone': phone,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'status': "New"
      });
      return true;
    } catch (e) {
      print('Error submitting inquiry: $e');
      return false;
    }
  }

  // Simplified for test mode
  Future<bool> verifyPayment({required String orderId, required String paymentId, required String signature}) async {
    return true; // Auto-verify in test mode
  }

  // Placeholder for stats (will require dashboard login later)
  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    return {};
  }

  Future<bool> adminUpdateProduct({required String productId, required Map<String, dynamic> updates}) async {
    try {
      await _firestore.collection('products').doc(productId).update(updates);
      return true;
    } catch (e) {
      return false;
    }
  }
}
