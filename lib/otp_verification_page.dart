import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_manager.dart';
import 'main.dart';

class OtpVerificationPage extends StatefulWidget {
  final String phone;
  final String verificationId;
  const OtpVerificationPage({super.key, required this.phone, required this.verificationId});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VERIFY\nIDENTITY',
                style: GoogleFonts.philosopher(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF18453B),
                  height: 1.0,
                  letterSpacing: 2,
                ),
              ).animate().fadeIn().slideX(begin: -0.2, end: 0),
              
              const SizedBox(height: 15),
              Text(
                'A 6-digit code has been sent to +91 ${widget.phone}. Enter it to continue.',
                style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.6, fontWeight: FontWeight.w500),
              ).animate().fadeIn(delay: 200.ms),
              
              const SizedBox(height: 60),
              
              // OTP Grid (6 digits for Firebase standard)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) => _otpBox(index)),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
              
              const SizedBox(height: 60),
              
              GestureDetector(
                onTap: _isLoading ? null : _verifyOtp,
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
                        'VERIFY & ENTER',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13),
                      ),
                ),
              ).animate().fadeIn(delay: 600.ms),
              
              const SizedBox(height: 40),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'RESEND CODE IN 00:54',
                    style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _otpBox(int index) {
    return Container(
      width: 48,
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF18453B)),
        inputFormatters: [LengthLimitingTextInputFormatter(1), FilteringTextInputFormatter.digitsOnly],
        onChanged: (v) {
          if (v.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (v.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          if (v.isNotEmpty && index == 5) {
            _verifyOtp();
          }
        },
        decoration: const InputDecoration(border: InputBorder.none),
      ),
    );
  }

  void _verifyOtp() async {
    String smsCode = _controllers.map((c) => c.text).join();
    if (smsCode.length != 6) return;

    setState(() => _isLoading = true);
    HapticFeedback.heavyImpact();

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId, 
        smsCode: smsCode
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Create user profile in Firestore if it doesn't exist
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'phoneNumber': widget.phone,
          'lastLogin': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Update Notification Token after login
        await NotificationManager().updateToken();

        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.pushAndRemoveUntil(
            context, 
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (route) => false
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Invalid code. Please try again.'),
        backgroundColor: Colors.red,
      ));
    }
  }
}
