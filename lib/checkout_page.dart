import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'cart_manager.dart';
import 'order_manager.dart';
import 'main.dart';
import 'models.dart';

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
  int _currentStep = 0;
  String _selectedPayment = 'UPI (Google Pay / PhonePe)';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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

              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  if (_currentStep < 2) {
                    if (_currentStep == 0 && !_formKey.currentState!.validate()) return;
                    setState(() => _currentStep++);
                  } else {
                    OrderManager().addOrder(cart.items, cart.total);
                    cart.clearCart();
                    _showSuccess();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF18453B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(_currentStep == 2 ? 'PLACE ROYAL ORDER' : 'CONTINUE', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
        const Text('SHIPPING DETAILS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 25),
        _buildTextField('Full Name', _nameController, Icons.person_outline_rounded),
        _buildTextField('Phone Number', _phoneController, Icons.phone_android_rounded),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoadingLocation ? null : _getCurrentLocation,
            icon: _isLoadingLocation ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location, size: 18, color: Color(0xFF18453B)),
            label: Text(_isLoadingLocation ? 'FETCHING...' : 'USE MY CURRENT LOCATION', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF18453B),
              side: const BorderSide(color: Color(0xFF18453B), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ),
        const SizedBox(height: 25),
        Row(
          children: [
            Expanded(child: _buildTextField('Pincode', _pincodeController, Icons.pin_drop_outlined)),
            const SizedBox(width: 15),
            Expanded(child: _buildTextField('City', _cityController, Icons.location_city_outlined)),
          ],
        ),
        _buildTextField('State', _stateController, Icons.map_outlined),
        _buildTextField('House No / Area', _addressController, Icons.home_rounded, maxLines: 2),
      ],
    ).animate().fadeIn();
  }

  Widget _buildPaymentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SELECT PAYMENT METHOD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 25),
        _paymentTile('UPI (Google Pay / PhonePe)', Icons.account_balance_wallet_rounded),
        _paymentTile('Credit / Debit Card', Icons.credit_card_rounded),
        _paymentTile('Net Banking', Icons.account_balance_rounded),
        _paymentTile('Cash on Delivery', Icons.payments_rounded),
      ],
    ).animate().fadeIn();
  }

  Widget _buildReviewStep(CartManager cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('FINAL REVIEW', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 25),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
          ),
          child: Column(
            children: [
              _summaryRow('Items (${cart.items.length})', '₹${cart.subtotal.toStringAsFixed(0)}'),
              const SizedBox(height: 12),
              _summaryRow('Delivery Charges', '₹${cart.deliveryFee.toStringAsFixed(0)}'),
              if (cart.discountAmount > 0) ...[
                const SizedBox(height: 12),
                _summaryRow('Promo Discount', '-₹${cart.discountAmount.toStringAsFixed(0)}', isDiscount: true),
              ],
              const Divider(height: 40),
              _summaryRow('Total Amount', '₹${cart.total.toStringAsFixed(0)}', isTotal: true),
            ],
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _stepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        AnimatedContainer(
          duration: 300.ms,
          height: 28, width: 28,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF18453B) : Colors.grey.shade300,
            shape: BoxShape.circle,
            boxShadow: isActive ? [BoxShadow(color: const Color(0xFF18453B).withOpacity(0.3), blurRadius: 10)] : [],
          ),
          alignment: Alignment.center,
          child: Text('${step + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 10, color: isActive ? const Color(0xFF18453B) : Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _stepLine(bool isActive) {
    return Expanded(child: Container(height: 2, color: isActive ? const Color(0xFF18453B) : Colors.grey.shade200, margin: const EdgeInsets.only(bottom: 20)));
  }

  Widget _paymentTile(String title, IconData icon) {
    bool isSelected = _selectedPayment == title;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedPayment = title);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFF18453B)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (context, anim1, anim2) => Scaffold(
        backgroundColor: const Color(0xFF18453B),
        body: Center(
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
              const SizedBox(height: 60),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Dialog
                    Navigator.pop(context); // Checkout
                    MainScreen.of(context)?.setIndex(3); // Go to Orders
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF8E8),
                    foregroundColor: const Color(0xFF18453B),
                    minimumSize: const Size(double.infinity, 64),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('TRACK MY ROYAL ORDER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
