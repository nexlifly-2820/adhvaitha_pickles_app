import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'otp_verification_page.dart';
import 'main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      body: Stack(
        children: [
          // Background Aesthetic
          Positioned(
            top: -100, right: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  // Logo / Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18453B),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: const Color(0xFF18453B).withOpacity(0.2), blurRadius: 20)],
                    ),
                    child: const Icon(Icons.shield_moon_rounded, color: Color(0xFFD4AF37), size: 40),
                  ).animate().fadeIn().scale(),
                  
                  const SizedBox(height: 40),
                  Text(
                    'ROYAL\nACCESS',
                    style: GoogleFonts.philosopher(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF18453B),
                      height: 1.0,
                      letterSpacing: 2,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),
                  
                  const SizedBox(height: 15),
                  const Text(
                    'Enter your mobile number to unlock the elite collection of Adhvaitha Foods.',
                    style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.6, fontWeight: FontWeight.w500),
                  ).animate().fadeIn(delay: 400.ms),
                  
                  const SizedBox(height: 50),
                  
                  // Phone Input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)],
                    ),
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                      decoration: InputDecoration(
                        hintText: '98765 43210',
                        hintStyle: TextStyle(color: Colors.grey.shade300, letterSpacing: 2),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          child: Text('+91', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF18453B), fontSize: 16)),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 40),
                  
                  // Action Button
                  GestureDetector(
                    onTap: _isLoading ? null : _handleLogin,
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF18453B),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: const Color(0xFF18453B).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      alignment: Alignment.center,
                      child: _isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFFD4AF37), strokeWidth: 2))
                        : const Text(
                            'GET OTP CODE',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13),
                          ),
                    ),
                  ).animate().fadeIn(delay: 800.ms),
                  
                  const SizedBox(height: 30),
                  Center(
                    child: Text(
                      'By continuing, you agree to our Terms & Privacy Policy',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold),
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

  void _handleLogin() async {
    if (_phoneController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid 10-digit number.')));
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91${_phoneController.text}',
        verificationCompleted: (PhoneAuthCredential credential) async {
          // AUTO-VERIFICATION (Android only)
          UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
          User? user = userCredential.user;

          if (user != null) {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
              'phoneNumber': _phoneController.text,
              'lastLogin': FieldValue.serverTimestamp(),
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(builder: (_) => const MainScreen()),
                (route) => false
              );
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Verification Failed')));
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _isLoading = false);
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => OtpVerificationPage(
              phone: _phoneController.text, 
              verificationId: verificationId,
            ))
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
