import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'cart_manager.dart';
import 'order_manager.dart';
import 'cloud_function_manager.dart';
import 'payment_manager.dart';
import 'main.dart';
import 'models.dart';
import 'coupons_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoadingLocation = false;
  bool _isProcessing = false;
  int _currentStep = 0;
  String _selectedPayment = 'UPI (Google Pay / PhonePe)';
  String _addressType = 'Home';

  @override
  void initState() {
    super.initState();
    PaymentManager().init(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
  }

  @override
  void dispose() {
    PaymentManager().dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _addressController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _placeFinalOrder(paymentId: response.paymentId);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Payment Failed: ${response.message}'),
      backgroundColor: Colors.red,
    ));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('External Wallet Selected: ${response.walletName}'),
    ));
  }

  Future<void> _placeFinalOrder({String? paymentId}) async {
    final cart = CartManager();
    final result = await CloudFunctionManager().placeOrder(
      items: cart.items,
      subtotal: cart.subtotal,
      deliveryFee: cart.deliveryFee,
      discountAmount: cart.discountAmount,
      total: cart.total,
      shippingAddress: '${_addressController.text}, ${_cityController.text}, ${_stateController.text} - ${_pincodeController.text}',
      paymentMethod: _selectedPayment + (paymentId != null ? ' (ID: $paymentId)' : ''),
    );

    setState(() => _isProcessing = false);

    if (result['success'] == true) {
      cart.clearCart();
      _showSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Order failed. Please try again.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Permission denied.';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      if (kIsWeb) {
        final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1';
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final address = data['address'];
          if (address != null) {
            setState(() {
              _pincodeController.text = address['postcode']?.toString() ?? '';
              _cityController.text = address['city'] ?? address['town'] ?? address['village'] ?? address['county'] ?? '';
              _stateController.text = address['state'] ?? '';
              _addressController.text = data['display_name'] ?? '';
            });
          }
        }
      } else {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          setState(() {
            _pincodeController.text = place.postalCode ?? '';
            _cityController.text = place.locality ?? place.subAdministrativeArea ?? '';
            _stateController.text = place.administrativeArea ?? '';
            String street = place.street ?? '';
            String area = place.subLocality ?? '';
            _addressController.text = area.isEmpty ? street : '$street, $area';
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location Error: ${e.toString()}')));
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartManager();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        title: Text('CHECKOUT', style: GoogleFonts.philosopher(fontWeight: FontWeight.w900)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 25, left: 30, right: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _stepIndicator(0, 'Address', _currentStep >= 0),
                _stepLine(_currentStep >= 1),
                _stepIndicator(1, 'Payment', _currentStep >= 1),
                _stepLine(_currentStep >= 2),
                _stepIndicator(2, 'Review', _currentStep >= 2),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_currentStep == 0) _buildAddressStep(),
              if (_currentStep == 1) _buildPaymentStep(),
              if (_currentStep == 2) _buildReviewStep(cart),

              const SizedBox(height: 30),
              if (_currentStep == 2) 
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Colors.amber.shade900, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Please note: Food items are non-returnable to maintain hygiene and safety standards.',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              ElevatedButton(
                onPressed: _isProcessing ? null : () async {
                  HapticFeedback.mediumImpact();
                  if (_currentStep < 2) {
                    if (_currentStep == 0 && !_formKey.currentState!.validate()) return;
                    setState(() => _currentStep++);
                  } else {
                    setState(() => _isProcessing = true);
                    
                    if (_selectedPayment == 'Cash on Delivery') {
                      await _placeFinalOrder();
                    } else {
                      final user = FirebaseAuth.instance.currentUser;
                      PaymentManager().openCheckout(
                        amount: cart.total,
                        contact: _phoneController.text,
                        email: user?.email ?? 'customer@adhvaitha.com',
                        description: 'Payment for Royal Pickles Order',
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF18453B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: _isProcessing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_currentStep == 2 ? 'PLACE ROYAL ORDER' : 'CONTINUE', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
              if (_currentStep > 0)
                Center(
                  child: TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _currentStep--);
                    },
                    child: const Text('BACK', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CONTACT INFORMATION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 20),
        _buildTextField('Full Name', _nameController, Icons.person_outline_rounded),
        _buildTextField('Phone Number', _phoneController, Icons.phone_android_rounded),
        
        const SizedBox(height: 10),
        const Divider(height: 40),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('DELIVERY ADDRESS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 10, color: Colors.grey)),
            GestureDetector(
              onTap: _isLoadingLocation ? null : _getCurrentLocation,
              child: Row(
                children: [
                  if (_isLoadingLocation) 
                    const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    const Icon(Icons.my_location, size: 14, color: Color(0xFFD4AF37)),
                  const SizedBox(width: 6),
                  Text(
                    _isLoadingLocation ? 'LOCATING...' : 'USE CURRENT', 
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildTextField('Pincode', _pincodeController, Icons.pin_drop_outlined)),
            const SizedBox(width: 15),
            Expanded(child: _buildTextField('City', _cityController, Icons.location_city_outlined)),
          ],
        ),
        _buildTextField('State', _stateController, Icons.map_outlined),
        _buildTextField('House No / Building Name', _addressController, Icons.home_rounded),
        _buildTextField('Road Name / Area / Colony', TextEditingController(), Icons.edit_road_rounded),

        const SizedBox(height: 10),
        const Text('ADDRESS TYPE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 15),
        Row(
          children: [
            _addressTypeChip('Home', Icons.home_rounded),
            const SizedBox(width: 10),
            _addressTypeChip('Office', Icons.work_rounded),
            const SizedBox(width: 10),
            _addressTypeChip('Other', Icons.location_on_rounded),
          ],
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _addressTypeChip(String type, IconData icon) {
    bool isSelected = _addressType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _addressType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF18453B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? const Color(0xFF18453B) : Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(width: 8),
              Text(type, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CHOOSE PAYMENT METHOD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 25),
        _paymentTile(
          'UPI (Google Pay / PhonePe)', 
          Icons.account_balance_wallet_rounded,
          'Pay instantly from your bank account'
        ),
        _paymentTile(
          'Credit / Debit Card', 
          Icons.credit_card_rounded,
          'Visa, Mastercard, RuPay supported'
        ),
        _paymentTile(
          'Net Banking', 
          Icons.account_balance_rounded,
          'Secure payment via 40+ banks'
        ),
        _paymentTile(
          'Cash on Delivery', 
          Icons.payments_rounded,
          'Pay when your royal jar arrives'
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildReviewStep(CartManager cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ORDER SUMMARY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cart.items.length,
          itemBuilder: (context, index) {
            final item = cart.items[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(item.product.image, width: 50, height: 50, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('${item.weight} • Qty: ${item.quantity}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text('₹${(item.product.getRawPriceForWeight(item.weight) * item.quantity).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF18453B))),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 30),
        const Text('BILLING DETAILS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
          ),
          child: Column(
            children: [
              _summaryRow('Items Total', '₹${cart.subtotal.toStringAsFixed(0)}'),
              const SizedBox(height: 12),
              _summaryRow('Delivery Charges', '₹${cart.deliveryFee.toStringAsFixed(0)}'),
              if (cart.discountAmount > 0) ...[
                const SizedBox(height: 12),
                _summaryRow('Promo Discount (${cart.appliedPromoCode})', '-₹${cart.discountAmount.toStringAsFixed(0)}', isDiscount: true),
              ],
              const Divider(height: 30),
              _buildCouponSection(context),
              const Divider(height: 30),
              _summaryRow('Total Amount', '₹${cart.total.toStringAsFixed(0)}', isTotal: true),
            ],
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildCouponSection(BuildContext context) {
    final cart = CartManager();
    final TextEditingController _couponController = TextEditingController();
    bool hasCoupon = cart.appliedPromoCode.isNotEmpty;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_offer_outlined, color: Color(0xFF18453B), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _couponController,
                  decoration: const InputDecoration(
                    hintText: 'Enter promo code',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (_couponController.text.isNotEmpty) {
                    if (cart.applyPromoCode(_couponController.text)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coupon Applied!'), backgroundColor: Colors.green));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Coupon'), backgroundColor: Colors.red));
                    }
                  }
                },
                child: const Text('APPLY', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF18453B))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CouponsPage()));
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Browse available offers', style: TextStyle(fontSize: 12, color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
              const Icon(Icons.arrow_right_alt_rounded, size: 16, color: Color(0xFFD4AF37)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepIndicator(int step, String label, bool isActive) {
    bool isCompleted = _currentStep > step;
    return Column(
      children: [
        AnimatedContainer(
          duration: 300.ms,
          height: 32, width: 32,
          decoration: BoxDecoration(
            color: isCompleted ? const Color(0xFFD4AF37) : (isActive ? const Color(0xFF18453B) : Colors.grey.shade200),
            shape: BoxShape.circle,
            boxShadow: isActive ? [BoxShadow(color: (isCompleted ? const Color(0xFFD4AF37) : const Color(0xFF18453B)).withOpacity(0.3), blurRadius: 10)] : [],
          ),
          alignment: Alignment.center,
          child: isCompleted 
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text('${step + 1}', style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(), 
          style: TextStyle(
            fontSize: 9, 
            color: isActive || isCompleted ? const Color(0xFF18453B) : Colors.grey, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 1
          )
        ),
      ],
    );
  }

  Widget _stepLine(bool isActive) {
    return Expanded(child: Container(height: 2, color: isActive ? const Color(0xFF18453B) : Colors.grey.shade200, margin: const EdgeInsets.only(bottom: 20)));
  }

  Widget _paymentTile(String title, IconData icon, String subtitle) {
    bool isSelected = _selectedPayment == title;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedPayment = title);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFFD4AF37) : Colors.grey.shade100, width: 2),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.1), blurRadius: 10)] : [],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF18453B).withOpacity(isSelected ? 1 : 0.05), shape: BoxShape.circle),
            child: Icon(icon, color: isSelected ? Colors.white : const Color(0xFF18453B), size: 20),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFFD4AF37)) : const Icon(Icons.circle_outlined, color: Colors.grey, size: 20),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF18453B)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF18453B), width: 1)),
        ),
        validator: (v) => v!.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _summaryRow(String label, String val, {bool isTotal = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isTotal ? 17 : 14, fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500)),
        Text(val, style: TextStyle(fontSize: isTotal ? 24 : 16, fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold, color: isDiscount ? Colors.green : (isTotal ? const Color(0xFF18453B) : Colors.black))),
      ],
    );
  }

  void _showSuccess() {
    // Capture the context of the CheckoutPage before opening the dialog
    final checkoutContext = context;
    
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (dialogContext, anim1, anim2) => Scaffold(
        backgroundColor: const Color(0xFF18453B),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(35),
                    decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, size: 80, color: Color(0xFF18453B)),
                  ).animate().scale(curve: Curves.elasticOut, duration: 1.seconds),
                  const SizedBox(height: 40),
                  Text('ORDER PLACED!', style: GoogleFonts.philosopher(color: const Color(0xFFD4AF37), fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 4)),
                  const SizedBox(height: 15),
                  const Text('Your traditional flavors are on the way.', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 40),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        _successStep(Icons.auto_awesome_outlined, 'Authentic Preparation', 'Chef is assigning your fresh batch.'),
                        const SizedBox(height: 15),
                        _successStep(Icons.inventory_2_outlined, 'Quality Seal', 'Jar will be vacuum sealed for purity.'),
                        const SizedBox(height: 15),
                        _successStep(Icons.local_shipping_outlined, 'Royal Dispatch', 'Estimated arrival in 3-5 days.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            final mainScreen = MainScreen.of(checkoutContext);
                            Navigator.pop(dialogContext);
                            Navigator.pop(checkoutContext);
                            mainScreen?.setIndex(3);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFF8E8),
                            foregroundColor: const Color(0xFF18453B),
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('TRACK MY ROYAL ORDER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                        const SizedBox(height: 15),
                        TextButton(
                          onPressed: () {
                            final mainScreen = MainScreen.of(checkoutContext);
                            Navigator.pop(dialogContext);
                            Navigator.pop(checkoutContext);
                            mainScreen?.setIndex(0); // Go to Home
                          },
                          child: const Text(
                            'CONTINUE SHOPPING', 
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 11)
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _successStep(IconData icon, String title, String desc) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: const Color(0xFFD4AF37), size: 18),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(desc, style: const TextStyle(color: Colors.white30, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}
