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
import 'package:adhvaitha_pickles_app/app_config_repository.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'cart_manager.dart';
import 'cloud_function_manager.dart';
import 'payment_manager.dart';
import 'main.dart';

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
  final TextEditingController _secondaryPhoneController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _giftNoteController = TextEditingController();

  bool _isLoadingLocation = false;
  bool _isProcessing = false;
  bool _isGift = false;
  int _currentStep = 0;
  String _selectedPayment = 'UPI (Google Pay / PhonePe)';
  String _addressType = 'Home';
  List<String> _serviceablePincodes = [];

  @override
  void initState() {
    super.initState();
    _loadServiceability();
    PaymentManager().setupCallbacks(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
  }

  void _loadServiceability() {
    AppConfigRepository().getServiceablePincodesStream().listen((list) {
      if (mounted) setState(() => _serviceablePincodes = list);
    });
  }

  bool _isPincodeServiceable() {
    if (_serviceablePincodes.isEmpty) return true;
    return _serviceablePincodes.contains(_pincodeController.text);
  }

  @override
  void dispose() {
    _pincodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _addressController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _secondaryPhoneController.dispose();
    _areaController.dispose();
    _giftNoteController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final pId = response.paymentId ?? 'N/A';
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _placeFinalOrder(paymentId: pId);
      }
    });
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
      packingFee: cart.packingFee,
      gstAmount: cart.gstAmount,
      discountAmount: cart.discountAmount,
      total: cart.total,
      shippingAddress: '${_addressController.text}, ${_areaController.text}',
      city: _cityController.text,
      state: _stateController.text,
      pincode: _pincodeController.text,
      paymentMethod: _selectedPayment + (paymentId != null ? ' (ID: $paymentId)' : ''),
    );

    setState(() => _isProcessing = false);

    if (!mounted) return;
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

  Future<void> _autoFillLocation(String pincode) async {
    try {
      final response = await http.get(Uri.parse('https://api.postalpincode.in/pincode/$pincode'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data[0]['Status'] == 'Success') {
          final postOffice = data[0]['PostOffice'][0];
          if (mounted) {
            setState(() {
              _cityController.text = postOffice['District'] ?? '';
              _stateController.text = postOffice['State'] ?? '';
            });
          }
        }
      }
    } catch (_) {}
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
        desiredAccuracy: LocationAccuracy.high,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location Error: ${e.toString()}')));
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartManager();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      body: Stack(
        children: [
          // 1. Background Image (fits 100% inside screen bounds)
          Positioned.fill(
            child: Image.asset(
              'assets/images/cart_bg_screen.png',
              fit: BoxFit.fill,
              alignment: Alignment.topCenter,
              errorBuilder: (c, e, s) => Container(color: const Color(0xFFFFF8E8)),
            ),
          ),

          // 2. Foreground Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                _buildStepProgressBar(),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_currentStep == 0) _buildAddressStep(),
                          if (_currentStep == 1) _buildReviewStep(cart),
                          if (_currentStep == 2) _buildPaymentStep(),

                          const SizedBox(height: 20),
                          _buildPrimaryButton(cart),

                          if (_currentStep > 0) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _currentStep--);
                                },
                                child: Text(
                                  '← BACK TO ${_stepName(_currentStep - 1)}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _stepName(int step) {
    if (step == 0) return 'ADDRESS';
    if (step == 1) return 'BILLING';
    return 'PAYMENT';
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Back Button
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEFEFE2), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back, color: Color(0xFF0F382C), size: 20),
                onPressed: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep--);
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    MainScreen.of(context)?.setIndex(0);
                  }
                },
              ),
            ),
          ),

          // Title & Subtitle in Center
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.eco_rounded, size: 16, color: Color(0xFF0F382C)),
              Text(
                'Checkout',
                style: GoogleFonts.philosopher(
                  color: const Color(0xFF0F382C),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'From our kitchen to your home',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF555555),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('💛', style: TextStyle(fontSize: 9)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Authentic • Fresh • Always Special',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF888888),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          // Top Right Cursive Text
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                'Good\nFood\nHappier\nDays ♡',
                textAlign: TextAlign.center,
                style: GoogleFonts.satisfy(
                  color: const Color(0xFF0F382C),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  height: 1.05,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          _stepCircle(0, 'ADDRESS'),
          _stepLine(0),
          _stepCircle(1, 'BILLING'),
          _stepLine(1),
          _stepCircle(2, 'PAYMENT'),
        ],
      ),
    );
  }

  Widget _stepCircle(int step, String label) {
    bool isCompleted = _currentStep > step;
    bool isActive = _currentStep == step;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFFE0A328)
                : (isActive ? const Color(0xFF0F382C) : Colors.white),
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFFE0A328)
                  : (isActive ? const Color(0xFF0F382C) : const Color(0xFFEFEFE2)),
              width: 1.5,
            ),
            boxShadow: isActive || isCompleted
                ? [
                    BoxShadow(
                      color: (isCompleted ? const Color(0xFFE0A328) : const Color(0xFF0F382C)).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text(
                  '${step + 1}',
                  style: GoogleFonts.poppins(
                    color: isActive ? Colors.white : Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isActive || isCompleted ? const Color(0xFF0F382C) : Colors.grey.shade500,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(int stepIndex) {
    bool isPassed = _currentStep > stepIndex;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16, left: 6, right: 6),
        decoration: BoxDecoration(
          color: isPassed ? const Color(0xFFD4AF37) : const Color(0xFFE5E5DB),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildAddressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Contact Information Card
        _buildCardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                icon: Icons.person_outline_rounded,
                title: 'Contact Information',
                subtitle: "We'll use this to keep you updated",
              ),
              const SizedBox(height: 16),
              _buildTextField('Full Name', _nameController, Icons.person_outline_rounded),
              Row(
                children: [
                  Expanded(child: _buildTextField('Phone Number', _phoneController, Icons.phone_android_rounded, keyboardType: TextInputType.phone)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Secondary Number', _secondaryPhoneController, Icons.phone_android_rounded, required: false, keyboardType: TextInputType.phone)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Delivery Address Card
        _buildCardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                icon: Icons.location_on_outlined,
                title: 'Delivery Address',
                subtitle: 'Where should we deliver your order?',
                trailing: GestureDetector(
                  onTap: _isLoadingLocation ? null : _getCurrentLocation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
                    ),
                    child: Row(
                      children: [
                        if (_isLoadingLocation)
                          const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32)))
                        else
                          const Icon(Icons.my_location, size: 12, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 5),
                        Text(
                          _isLoadingLocation ? 'Locating...' : 'Use Current Location',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: TextFormField(
                        controller: _pincodeController,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1A1A1A)),
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        onChanged: (v) {
                          if (v.length == 6) _autoFillLocation(v);
                        },
                        decoration: _inputDecoration('Pincode', Icons.pin_drop_outlined),
                        validator: (v) => (v == null || v.length < 6) ? 'Invalid' : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('City', _cityController, Icons.location_city_outlined)),
                ],
              ),
              _buildTextField('State', _stateController, Icons.map_outlined),
              _buildTextField('House No / Building Name', _addressController, Icons.home_rounded),
              _buildTextField('Road Name / Area / Colony', _areaController, Icons.edit_road_rounded),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3. Address Type Card
        _buildCardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                icon: Icons.home_outlined,
                title: 'Address Type',
                subtitle: 'Help us serve you better',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _addressTypeChip('Home', Icons.home_rounded),
                  const SizedBox(width: 8),
                  _addressTypeChip('Office', Icons.work_rounded),
                  const SizedBox(width: 8),
                  _addressTypeChip('Other', Icons.location_on_rounded),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 4. Gift Section Card
        _buildGiftSection(),
        const SizedBox(height: 16),

        // Trust Badges
        _buildTrustBadges(),
      ],
    ).animate().fadeIn();
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0EFE6), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF8E7),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFFE0A328), size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFF0F382C),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _addressTypeChip(String type, IconData icon) {
    bool isSelected = _addressType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _addressType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F382C) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? const Color(0xFF0F382C) : const Color(0xFFEFEFE2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: isSelected ? Colors.white : Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                type,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF444444),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 10, color: Colors.white),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGiftSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5C778), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF8E7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Color(0xFFE0A328),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send as a Royal Gift?',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: const Color(0xFF0F382C),
                      ),
                    ),
                    Text(
                      'Add a personalized note for your loved ones.',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isGift,
                onChanged: (v) => setState(() => _isGift = v),
                activeThumbColor: const Color(0xFFE0A328),
              ),
            ],
          ),
          if (_isGift) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _giftNoteController,
              maxLines: 2,
              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1A1A1A)),
              decoration: _inputDecoration('Write your message here...', Icons.edit_note_rounded),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrustBadges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _trustItem(Icons.verified_user_rounded, '100% Secure Payments'),
        Container(width: 1, height: 12, color: Colors.grey.shade400, margin: const EdgeInsets.symmetric(horizontal: 10)),
        _trustItem(Icons.local_shipping_rounded, 'Fresh Delivery Across India'),
        Container(width: 1, height: 12, color: Colors.grey.shade400, margin: const EdgeInsets.symmetric(horizontal: 10)),
        _trustItem(Icons.eco_rounded, 'Authentic Andhra Flavours'),
      ],
    );
  }

  Widget _trustItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFFE0A328)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    bool required = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1A1A1A)),
        decoration: _inputDecoration(label, icon),
        validator: (v) => (required && (v == null || v.isEmpty)) ? 'Required' : null,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      counterText: "",
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF0F382C)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEFEFE2), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEFEFE2), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0F382C), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  Widget _buildReviewStep(CartManager cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Delivering To Card
        _buildDeliveringToCard(),
        const SizedBox(height: 14),

        // 2. Gift Preview (if applicable)
        if (_isGift) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5C778)),
            ),
            child: Row(
              children: [
                const Icon(Icons.card_giftcard_rounded, color: Color(0xFFE0A328), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ROYAL GIFT MESSAGE',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 10, color: const Color(0xFF0F382C), letterSpacing: 1),
                      ),
                      Text(
                        _giftNoteController.text.isEmpty ? 'Best wishes from ${_nameController.text}' : _giftNoteController.text,
                        style: GoogleFonts.poppins(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // 3. Order Summary Card
        _buildOrderSummaryCard(cart),
        const SizedBox(height: 14),

        // 4. Billing Details Card
        _buildBillingDetailsCard(cart),
        const SizedBox(height: 14),

        // 5. Promo Code Card
        _buildPromoCodeSection(context, cart),
        const SizedBox(height: 16),

        // Trust Badges
        _buildTrustBadges(),
      ],
    ).animate().fadeIn();
  }

  Widget _buildDeliveringToCard() {
    String name = _nameController.text.trim();
    if (name.isEmpty) name = 'HEMANTH';
    String address = '${_addressController.text}, ${_areaController.text}, ${_cityController.text} - ${_pincodeController.text}'.trim();
    if (address.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').isEmpty) {
      address = 'main road, bus stand, Srikakulam - 532404';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F9F6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCECE4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFE2F0E8),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.home_rounded, color: Color(0xFF0F382C), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivering to',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: const Color(0xFF555555),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  name.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: const Color(0xFF0F382C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF555555),
                    fontSize: 11,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _currentStep = 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF0F382C), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined, size: 12, color: Color(0xFF0F382C)),
                  const SizedBox(width: 4),
                  Text(
                    'CHANGE',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F382C),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(CartManager cart) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0EFE6), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8E7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_rounded, color: Color(0xFFE0A328), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Order Summary',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: const Color(0xFF0F382C),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${cart.items.length} ${cart.items.length == 1 ? 'Item' : 'Items'}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: const Color(0xFFA67C1E),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: cart.items.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAF5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEFEFE2)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildProductImage(item.product.image),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.weight} • Qty: ${item.quantity}',
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${(item.product.getRawPriceForWeight(item.weight) * item.quantity).toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F382C),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingDetailsCard(CartManager cart) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0EFE6), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF2E7D32), size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Billing Details',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFF0F382C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _summaryRow('Items Total', '₹${cart.subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _summaryRow(
            'Delivery Charges',
            cart.deliveryFee == 0 ? 'FREE' : '₹${cart.deliveryFee.toStringAsFixed(0)}',
            isDiscount: cart.deliveryFee == 0,
          ),
          if (cart.packingFee > 0) ...[
            const SizedBox(height: 8),
            _summaryRow('Secure Packaging', '₹${cart.packingFee.toStringAsFixed(0)}'),
          ],
          if (cart.gstPercentage > 0) ...[
            const SizedBox(height: 8),
            _summaryRow('GST (${cart.gstPercentage.toStringAsFixed(0)}%)', '₹${cart.gstAmount.toStringAsFixed(0)}'),
          ],
          if (cart.discountAmount > 0) ...[
            const SizedBox(height: 8),
            _summaryRow('Promo Discount (${cart.appliedPromoCode})', '-₹${cart.discountAmount.toStringAsFixed(0)}', isDiscount: true),
          ],
          const Divider(height: 24, color: Color(0xFFEEEEEE)),
          _summaryRow('Total Amount', '₹${cart.total.toStringAsFixed(0)}', isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPromoCodeSection(BuildContext context, CartManager cart) {
    final TextEditingController couponController = TextEditingController();
    final bool hasCode = cart.appliedPromoCode.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F9F6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F382C),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.confirmation_num_outlined, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Have a Promo Code?',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: const Color(0xFF0F382C),
                      ),
                    ),
                    Text(
                      'Apply and save more on your favorites!',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEFEFE2)),
                  ),
                  alignment: Alignment.center,
                  child: TextField(
                    controller: couponController,
                    style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
                    decoration: InputDecoration(
                      hintText: hasCode ? cart.appliedPromoCode : 'Enter promo code',
                      hintStyle: GoogleFonts.poppins(color: hasCode ? const Color(0xFF0F382C) : Colors.grey.shade400, fontSize: 12.5),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  if (hasCode) {
                    cart.removePromoCode();
                  } else if (couponController.text.isNotEmpty) {
                    if (cart.applyPromoCode(couponController.text)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coupon Applied!'), backgroundColor: Color(0xFF0F382C)));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Coupon'), backgroundColor: Colors.red));
                    }
                  }
                },
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F382C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    hasCode ? 'REMOVE' : 'APPLY',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStep() {
    final cart = CartManager();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Hero Banner
        _buildPaymentBanner(),
        const SizedBox(height: 16),

        // 2. Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PAYMENT METHODS',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.2,
                color: Colors.grey.shade600,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.lock_outline_rounded, size: 12, color: Color(0xFF0F382C)),
                const SizedBox(width: 4),
                Text(
                  'Your payment information is safe with us.',
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0F382C),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Option 1: UPI
        _paymentTile(
          'UPI (Google Pay / PhonePe / Paytm)',
          Icons.account_balance_wallet_rounded,
          'Fast, secure and hassle-free payment',
          badge: 'Recommended',
        ),

        // Option 2: Credit / Debit Card
        _paymentTile(
          'Credit / Debit Card',
          Icons.credit_card_rounded,
          'Visa, Mastercard, RuPay & more',
        ),

        // Option 3: Net Banking
        _paymentTile(
          'Net Banking',
          Icons.account_balance_rounded,
          'Pay securely via 40+ banks',
        ),

        // Option 4: Cash on Delivery
        _paymentTile(
          'Cash on Delivery',
          Icons.payments_rounded,
          'Pay when your order arrives',
          trailingBadge: 'Available in selected locations',
        ),
        const SizedBox(height: 16),

        // 3. Order Summary & Promo Card
        _buildPaymentOrderSummaryCard(cart),
        const SizedBox(height: 16),

        // 4. Footer Trust Info
        _buildFooterSSLBadges(),
      ],
    ).animate().fadeIn();
  }

  Widget _buildPaymentBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E7), Color(0xFFFFF3D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5C778), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tradition in Every Jar ♥',
                  style: GoogleFonts.satisfy(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F382C),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Secure Payment\nSafe Delivery\nHappier You!',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF444444),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bannerBadge(Icons.verified_user_rounded, '100% Secure Payments'),
                const SizedBox(height: 6),
                _bannerBadge(Icons.local_shipping_rounded, 'Fresh Delivery Across India'),
                const SizedBox(height: 6),
                _bannerBadge(Icons.eco_rounded, 'Trusted by 10,000+ Families'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerBadge(IconData icon, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Color(0xFF0F382C),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFFE0A328), size: 10),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F382C),
            ),
          ),
        ),
      ],
    );
  }

  Widget _paymentTile(
    String title,
    IconData icon,
    String subtitle, {
    String? badge,
    String? trailingBadge,
  }) {
    bool isSelected = _selectedPayment == title;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedPayment = title);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF3F9F6) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F382C) : const Color(0xFFEFEFE2),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.04 : 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0F382C) : const Color(0xFFFAFAF5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : const Color(0xFF0F382C), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: const Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3C4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFA67C1E),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (trailingBadge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2EC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 10, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      trailingBadge,
                      style: GoogleFonts.poppins(fontSize: 8.5, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF0F382C) : Colors.grey.shade400,
                  width: isSelected ? 6 : 1.5,
                ),
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOrderSummaryCard(CartManager cart) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0EFE6), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8E7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Summary',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: const Color(0xFF0F382C),
                  ),
                ),
                Text(
                  '${cart.items.length} ${cart.items.length == 1 ? 'Item' : 'Items'}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: const Color(0xFFA67C1E),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _summaryRow('Items Total', '₹${cart.subtotal.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                _summaryRow(
                  'Delivery Charges',
                  cart.deliveryFee == 0 ? 'FREE' : '₹${cart.deliveryFee.toStringAsFixed(0)}',
                  isDiscount: cart.deliveryFee == 0,
                ),
                if (cart.discountAmount > 0) ...[
                  const SizedBox(height: 8),
                  _summaryRow('Promo Discount (${cart.appliedPromoCode})', '-₹${cart.discountAmount.toStringAsFixed(0)}', isDiscount: true),
                ],
                const Divider(height: 24, color: Color(0xFFEEEEEE)),
                _summaryRow('Total Amount', '₹${cart.total.toStringAsFixed(0)}', isTotal: true),
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDF0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5C778), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.card_giftcard_rounded, color: Color(0xFFE0A328), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Have a promo code?',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                                color: const Color(0xFF0F382C),
                              ),
                            ),
                            Text(
                              'Apply and save more on your order',
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'APPLY >',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: const Color(0xFF0F382C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSSLBadges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF2E7D32)),
        const SizedBox(width: 4),
        Text(
          'SSL Secured',
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        Container(width: 1, height: 10, color: Colors.grey.shade400, margin: const EdgeInsets.symmetric(horizontal: 10)),
        Text(
          'Powered by Razorpay',
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        Container(width: 1, height: 10, color: Colors.grey.shade400, margin: const EdgeInsets.symmetric(horizontal: 10)),
        Text(
          'Your Trust, Our Priority',
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String val, {bool isTotal = false, bool isFree = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 16 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? const Color(0xFF0F382C) : const Color(0xFF333333),
          ),
        ),
        Text(
          val,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 22 : 14,
            fontWeight: FontWeight.bold,
            color: isDiscount || isFree
                ? const Color(0xFF2E7D32)
                : (isTotal ? const Color(0xFF0F382C) : const Color(0xFF1A1A1A)),
          ),
        ),
      ],
    );
  }

  Widget _buildProductImage(String path) {
    if (path.isEmpty) {
      return Container(width: 52, height: 52, color: Colors.grey.shade100, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 20));
    }
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(width: 52, height: 52, color: Colors.grey.shade100, child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 20)),
      );
    }
    String assetPath = path;
    if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/images/$path';
    }
    return Image.asset(
      assetPath,
      width: 52,
      height: 52,
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) => Container(width: 52, height: 52, color: Colors.grey.shade100, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 20)),
    );
  }

  Widget _buildPrimaryButton(CartManager cart) {
    String buttonText = 'Continue to Billing';
    if (_currentStep == 1) buttonText = 'Continue to Payment';
    if (_currentStep == 2) buttonText = 'PROCEED TO PAY ₹${cart.total.toStringAsFixed(0)}';

    return Column(
      children: [
        GestureDetector(
          onTap: _isProcessing ? null : () async {
            HapticFeedback.mediumImpact();
            if (_currentStep < 2) {
              if (_currentStep == 0) {
                if (!_formKey.currentState!.validate()) return;
                if (!_isPincodeServiceable()) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('We currently do not ship to this pincode. Please try another address.'),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }
              }
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
          child: Container(
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0F382C),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F382C).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      Text(
                        buttonText,
                        style: GoogleFonts.philosopher(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE0A328),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Good food brings people together 💛',
          style: GoogleFonts.satisfy(
            color: const Color(0xFF8A6B22),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showSuccess() {
    final checkoutContext = context;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (dialogContext, anim1, anim2) => Scaffold(
        backgroundColor: const Color(0xFF0F382C),
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
                    child: const Icon(Icons.check_rounded, size: 80, color: Color(0xFF0F382C)),
                  ).animate().scale(curve: Curves.elasticOut, duration: 1.seconds),
                  const SizedBox(height: 40),
                  Text('ORDER PLACED!', style: GoogleFonts.philosopher(color: const Color(0xFFD4AF37), fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 4)),
                  const SizedBox(height: 15),
                  Text('Your traditional flavors are on the way.', style: GoogleFonts.poppins(color: Colors.white60, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 40),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
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
                            foregroundColor: const Color(0xFF0F382C),
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Text('TRACK MY ROYAL ORDER', style: GoogleFonts.philosopher(fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                        const SizedBox(height: 15),
                        TextButton(
                          onPressed: () {
                            final mainScreen = MainScreen.of(checkoutContext);
                            Navigator.pop(dialogContext);
                            Navigator.pop(checkoutContext);
                            mainScreen?.setIndex(0);
                          },
                          child: Text(
                            'CONTINUE SHOPPING',
                            style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 11),
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
          decoration: BoxDecoration(color: const Color(0xFFD4AF37).withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: const Color(0xFFD4AF37), size: 18),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(desc, style: GoogleFonts.poppins(color: Colors.white30, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}
