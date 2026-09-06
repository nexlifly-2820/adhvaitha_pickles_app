import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';
import 'otp_verification_page.dart';
import 'main.dart';

enum LoginMode { email, phone }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  LoginMode _selectedMode = LoginMode.email;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EC),
      body: Stack(
        children: [
          // Background Watermarks
          Positioned.fill(
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                'assets/images/adhvaitha_logo.png',
                repeat: ImageRepeat.repeat,
                scale: 4,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Top Header Row: Mascot Logo & Cursive Script
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/adhvaitha_logo.png',
                              height: 110,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'AUTHENTIC TASTE. HOMEMADE WITH LOVE',
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF8B5E3C),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Taste\nTradition\nEveryday ♡',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.caveat(
                          color: const Color(0xFFD4AF37),
                          fontSize: 13,
                          height: 1.1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ).animate().fadeIn().scale(),

                  const SizedBox(height: 35),

                  // Header Title
                  Text(
                    'Welcome to\nAdhvaitha Foods',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.philosopher(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F4D3C),
                      height: 1.1,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 10),

                  Text(
                    _selectedMode == LoginMode.email
                        ? 'Sign in to explore authentic\nhomemade flavors crafted with love.'
                        : 'Enter your mobile number to receive\nan SMS OTP verification code.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF6B7280),
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 30),

                  // Mode Switcher Tabs
                  Container(
                    width: 220,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton(LoginMode.email, 'Email OTP'),
                        _buildTabButton(LoginMode.phone, 'Phone OTP'),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 25),

                  // Input Form Field
                  if (_selectedMode == LoginMode.email) _buildEmailForm(),
                  if (_selectedMode == LoginMode.phone) _buildPhoneForm(),

                  const SizedBox(height: 20),

                  // Send OTP Button
                  GestureDetector(
                    onTap: _isLoading ? null : _handlePrimarySubmit,
                    child: Container(
                      height: 56,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F4D3C),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F4D3C).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      alignment: Alignment.center,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Color(0xFFE5C76B),
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _selectedMode == LoginMode.email
                                      ? 'SEND OTP'
                                      : 'GET SMS OTP',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                              ],
                            ),
                    ),
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 12),

                  // Security Note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline_rounded, color: Color(0xFF6B7280), size: 13),
                      const SizedBox(width: 4),
                      Text(
                        _selectedMode == LoginMode.email
                            ? "We'll send a 6-digit code to your email"
                            : "We'll send a 6-digit code via SMS",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF6B7280),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),

                  // Trust Badges Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTrustBadge(Icons.eco_outlined, 'Homemade\nRecipes'),
                      _buildTrustBadge(Icons.soup_kitchen_outlined, 'Traditional\nMethods'),
                      _buildTrustBadge(Icons.verified_outlined, 'Premium\nQuality'),
                      _buildTrustBadge(Icons.local_shipping_outlined, 'Fast\nDelivery'),
                    ],
                  ).animate().fadeIn(delay: 800.ms),

                  const SizedBox(height: 30),

                  // Bottom Cursive Tagline
                  Text(
                    'From Our Kitchen to Your Home ♡',
                    style: GoogleFonts.caveat(
                      color: const Color(0xFF8B5E3C),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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

  Widget _buildTabButton(LoginMode mode, String label) {
    bool isSelected = _selectedMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _selectedMode = mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F4D3C) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B1B1B)),
        decoration: InputDecoration(
          hintText: 'Enter your email address',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.normal),
          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF0F4D3C), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildPhoneForm() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xFF1B1B1B)),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10)
        ],
        decoration: InputDecoration(
          hintText: 'Enter 10-digit number',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13, letterSpacing: 1, fontWeight: FontWeight.normal),
          prefixIcon: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text(
              '+91',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F4D3C),
                fontSize: 15,
              ),
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E8),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
          ),
          child: Icon(icon, color: const Color(0xFF0F4D3C), size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B1B1B),
            height: 1.2,
          ),
        ),
      ],
    );
  }

  void _handlePrimarySubmit() {
    if (_selectedMode == LoginMode.email) {
      _sendEmailOtp();
    } else {
      _sendPhoneOtp();
    }
  }

  // 1. Send Email OTP via BigRock API
  Future<void> _sendEmailOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final res = await ApiService.sendEmailOtp(email);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'OTP sent to $email')),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationPage(
              email: email,
              isEmailOtp: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending Email OTP: $e')),
        );
      }
    }
  }

  // 2. Send Phone SMS OTP via Firebase Auth
  void _sendPhoneOtp() async {
    if (_phoneController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit number.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91${_phoneController.text}',
        timeout: const Duration(seconds: 30),
        verificationCompleted: (PhoneAuthCredential credential) async {
          UserCredential userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);
          User? user = userCredential.user;

          if (user != null) {
            await ApiService.saveUser(
              userId: user.uid,
              phone: _phoneController.text,
            );

            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainScreen()),
                (route) => false,
              );
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  e.message ?? 'Verification Failed. Check SHA-1 in Firebase Console.',
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() => _isLoading = false);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OtpVerificationPage(
                  phone: _phoneController.text,
                  verificationId: verificationId,
                  isEmailOtp: false,
                ),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (mounted && _isLoading) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('OTP timeout. Please check your phone or try again.'),
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
