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
        // Use a FREE reverse geocoding API for Web (Nominatim)
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
        } else {
          throw 'Failed to fetch address from web API.';
        }
      } else {
        // Use native geocoding for Android/iOS
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

  Future<void> _lookupPincode(String pincode) async {
    if (pincode.length != 6) return;
    
    setState(() => _isLoadingPincode = true);
    try {
      final response = await http.get(Uri.parse('https://api.postalpincode.in/pincode/$pincode'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty && data[0]['Status'] == 'Success') {
          final postOffices = data[0]['PostOffice'];
          if (postOffices != null && postOffices.isNotEmpty) {
            final postOffice = postOffices[0];
            setState(() {
              _cityController.text = postOffice['District'] ?? '';
              _stateController.text = postOffice['State'] ?? '';
            });
          }
        }
      }
    } catch (e) {
      // Silent error
    } finally {
      setState(() => _isLoadingPincode = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartManager();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('CHECKOUT', style: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.w900)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Shipping Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              _buildTextField('Full Name', _nameController, Icons.person_outline),
              _buildTextField('Phone Number', _phoneController, Icons.phone_android_outlined, isPhone: true),
              
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                  icon: _isLoadingLocation 
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD35400)))
                      : const Icon(Icons.my_location, size: 18),
                  label: Text(_isLoadingLocation ? 'FETCHING LOCATION...' : 'USE MY CURRENT LOCATION'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD35400),
                    side: const BorderSide(color: Color(0xFFD35400)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildTextField('Pincode', _pincodeController, Icons.pin_drop_outlined, isPincode: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('City', _cityController, Icons.location_city_outlined, isLoading: _isLoadingPincode)),
                ],
              ),
              _buildTextField('State', _stateController, Icons.map_outlined),
              _buildTextField('House No / Area / Street', _addressController, Icons.home_outlined, maxLines: 2),

              const SizedBox(height: 30),
              const Text('Order Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _summaryRow('Subtotal', '₹${cart.subtotal.toStringAsFixed(0)}'),
                    const SizedBox(height: 10),
                    _summaryRow('Delivery', '₹${cart.deliveryFee.toStringAsFixed(0)}'),
                    const Divider(height: 30),
                    _summaryRow('Total Amount', '₹${cart.total.toStringAsFixed(0)}', isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      OrderManager().addOrder(cart.items, cart.total);
                      cart.clearCart();
                      _showSuccessDialog();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD35400),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('CONFIRM ORDER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isPhone = false, bool isPincode = false, int maxLines = 1, bool isLoading = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: (isPhone || isPincode) ? TextInputType.number : TextInputType.text,
        onChanged: isPincode ? (val) => _lookupPincode(val) : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: isLoading 
              ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2)))
              : Icon(icon, color: const Color(0xFF2C3E50)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFD35400))),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        validator: (value) => (value == null || value.isEmpty) ? '$label is required' : null,
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.w900 : FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: isBold ? 20 : 16, fontWeight: isBold ? FontWeight.w900 : FontWeight.bold, color: isBold ? const Color(0xFFD35400) : Colors.black87)),
      ],
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 60),
            ),
            const SizedBox(height: 30),
            const Text('ORDER PLACED!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF2C3E50))),
            const SizedBox(height: 10),
            const Text('Your delicious pickles are being packed with care.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Close Checkout page
                  MainScreen.of(context)?.setIndex(0); // Switch to Home tab
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C3E50), padding: const EdgeInsets.all(15)),
                child: const Text('BACK TO HOME'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
