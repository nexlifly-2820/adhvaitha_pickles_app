import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';

class PaymentManager {
  static final PaymentManager _instance = PaymentManager._internal();
  factory PaymentManager() => _instance;
  
  // Persistent Razorpay instance to prevent "Something went wrong" errors
  final Razorpay _razorpay = Razorpay();
  bool _isInitialized = false;

  static const String _razorpayKeyId = "rzp_test_RsIb2qtwvvKvbV";

  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onFailure;
  Function(ExternalWalletResponse)? onExternalWallet;

  PaymentManager._internal();

  void setupCallbacks({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) {
    this.onSuccess = onSuccess;
    this.onFailure = onFailure;
    this.onExternalWallet = onExternalWallet;

    if (!_isInitialized) {
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
      _isInitialized = true;
    }
  }

  void openCheckout({
    required double amount,
    required String contact,
    required String email,
    required String description,
  }) {
    int amountInPaise = (amount * 100).round();

    var options = {
      'key': _razorpayKeyId,
      'amount': amountInPaise,
      'name': 'Adhvaitha Foods',
      'description': description,
      'prefill': {
        'contact': contact,
        'email': email
      },
      'external': {
        'wallets': ['paytm']
      },
      'upi': {
        'enable': true,
        'app': 'com.google.android.apps.nbu.paisa.user' // Default to GPay if available
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    onFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    onExternalWallet?.call(response);
  }
}
