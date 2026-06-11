import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
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
  bool _isLoadingPincode = false;
  int _currentStep = 0;

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
        title: const Text('CHECKOUT'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20, left: 30, right: 30),
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
              if (_currentStep == 0) ...[
                const Text('SHIPPING ADDRESS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Color(0xFF18453B))),
                const SizedBox(height: 25),
                _buildTextField('Full Name', _nameController, Icons.person_outline),
                _buildTextField('Phone Number', _phoneController, Icons.phone_android_outlined),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                    icon: _isLoadingLocation ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location, size: 18),
                    label: Text(_isLoadingLocation ? 'FETCHING...' : 'USE MY CURRENT LOCATION'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF18453B),
                      side: const BorderSide(color: Color(0xFF18453B)),
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
                _buildTextField('House No / Area', _addressController, Icons.home_outlined, maxLines: 2),
              ] else if (_currentStep == 1) ...[
                const Text('SELECT PAYMENT METHOD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Color(0xFF18453B))),
                const SizedBox(height: 25),
                _paymentTile('UPI (Google Pay / PhonePe)', Icons.account_balance_wallet_rounded, true),
                _paymentTile('Credit / Debit Card', Icons.credit_card_rounded, false),
                _paymentTile('Net Banking', Icons.account_balance_rounded, false),
                _paymentTile('Cash on Delivery', Icons.payments_rounded, false),
              ] else ...[
                const Text('ORDER SUMMARY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Color(0xFF18453B))),
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
                  child: Column(
                    children: [
                      _summaryRow('Subtotal', '₹${cart.subtotal.toStringAsFixed(0)}'),
                      const SizedBox(height: 12),
                      _summaryRow('Delivery', '₹${cart.deliveryFee.toStringAsFixed(0)}'),
                      const Divider(height: 40),
                      _summaryRow('Amount to Pay', '₹${cart.total.toStringAsFixed(0)}', isTotal: true),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
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
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Text(_currentStep == 2 ? 'PLACE ORDER' : 'CONTINUE', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ),
              ),
              if (_currentStep > 0)
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _currentStep--),
                    child: const Text('BACK', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          height: 24, width: 24,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF18453B) : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text('${step + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: isActive ? const Color(0xFF18453B) : Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _stepLine(bool isActive) {
    return Expanded(child: Container(height: 2, color: isActive ? const Color(0xFF18453B) : Colors.grey.shade200, margin: const EdgeInsets.only(bottom: 15)));
  }

  Widget _paymentTile(String title, IconData icon, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent, width: 2),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF18453B)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFFD4AF37)) : const Icon(Icons.circle_outlined, color: Colors.grey),
        onTap: () {},
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF18453B))),
        ),
        validator: (v) => v!.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _summaryRow(String label, String val, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500)),
        Text(val, style: TextStyle(fontSize: isTotal ? 24 : 16, fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold, color: isTotal ? const Color(0xFF18453B) : Colors.black)),
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
                padding: const EdgeInsets.all(30),
                decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, size: 80, color: Color(0xFF18453B)),
              ),
              const SizedBox(height: 40),
              const Text('ORDER PLACED!', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 4)),
              const SizedBox(height: 10),
              const Text('Your traditional flavors are on the way.', style: TextStyle(color: Colors.white70)),
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
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text('TRACK MY ORDER', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
