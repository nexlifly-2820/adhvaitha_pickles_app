import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';
import 'notification_manager.dart';
import 'main.dart';

class OtpVerificationPage extends StatefulWidget {
  final String? phone;
  final String? email;
  final String? verificationId;
  final bool isEmailOtp;

  const OtpVerificationPage({
    super.key,
    this.phone,
    this.email,
    this.verificationId,
    this.isEmailOtp = false,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

  int _resendSeconds = 28;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendSeconds = 28;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds > 0) {
        if (mounted) setState(() => _resendSeconds--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String _getMaskedDestination() {
    if (widget.isEmailOtp && widget.email != null) {
      final parts = widget.email!.split('@');
      if (parts.first.length > 2) {
        final prefix = parts.first.substring(0, 2);
        return '$prefix****@${parts.last}';
      }
      return widget.email!;
    }
    if (widget.phone != null && widget.phone!.length == 10) {
      return '+91 ${widget.phone!.substring(0, 2)}******${widget.phone!.substring(8)}';
    }
    return widget.phone ?? 'your device';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C3D2E),
      body: Stack(
        children: [
          // Header Row: Back Button, Mascot Logo, Cursive Text
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Image.asset(
                        'assets/images/adhvaitha_logo.png',
                        height: 75,
                        fit: BoxFit.contain,
                      ),
                      Text(
                        'Good\nFood\nHappier\nDays ♡',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.caveat(
                          color: const Color(0xFFE5C76B),
                          fontSize: 12,
                          height: 1.1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Floating White Card Overlay
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF8E8),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 25),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),

                          // Top Card Icon: Envelope with Leaf Badge
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                )
                              ],
                            ),
                            child: const Icon(Icons.mark_email_read_outlined, color: Color(0xFF0F4D3C), size: 28),
                          ).animate().fadeIn().scale(),

                          const SizedBox(height: 16),

                          // Title
                          Text(
                            widget.isEmailOtp ? 'Verify Your Email' : 'Verify Mobile Number',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.philosopher(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F4D3C),
                            ),
                          ).animate().fadeIn(delay: 200.ms),

                          const SizedBox(height: 6),

                          Text(
                            "We've sent a 6-digit code to",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Email / Phone Display Box + Edit Button
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _getMaskedDestination(),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: const Color(0xFF1B1B1B),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Text(
                                    'Edit',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: const Color(0xFF0F4D3C),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 300.ms),

                          const SizedBox(height: 25),

                          // 6 OTP Box Inputs
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(6, (index) => _otpBox(index)),
                          ).animate().fadeIn(delay: 400.ms),

                          const SizedBox(height: 20),

                          // Resend Note
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Didn't receive the code? ",
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF6B7280),
                                  fontSize: 11,
                                ),
                              ),
                              _resendSeconds > 0
                                  ? Text(
                                      'Resend in 00:${_resendSeconds.toString().padLeft(2, '0')}',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF0F4D3C),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    )
                                  : GestureDetector(
                                      onTap: () {
                                        _startResendTimer();
                                        if (widget.isEmailOtp && widget.email != null) {
                                          ApiService.sendEmailOtp(widget.email!);
                                        }
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('A new OTP has been sent.')),
                                        );
                                      },
                                      child: Text(
                                        'Resend Now',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF0F4D3C),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                            ],
                          ),

                          const SizedBox(height: 25),

                          // Continue Button
                          GestureDetector(
                            onTap: _isLoading ? null : _verifyOtp,
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
                                          'CONTINUE',
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

                          const SizedBox(height: 25),

                          // Bottom Trust Note
                          Column(
                            children: [
                              Text(
                                'REAL INGREDIENTS',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF8B5E3C),
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                'REAL TRADITIONS',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF8B5E3C),
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                'A HAPPIER YOU',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF8B5E3C),
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(width: 30, height: 1, color: const Color(0xFFD4AF37)),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.local_florist_rounded, size: 12, color: Color(0xFFD4AF37)),
                                  const SizedBox(width: 6),
                                  Container(width: 30, height: 1, color: const Color(0xFFD4AF37)),
                                ],
                              ),
                            ],
                          ),
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

  Widget _otpBox(int index) {
    bool hasFocus = _focusNodes[index].hasFocus;
    bool hasValue = _controllers[index].text.isNotEmpty;

    return Container(
      width: 44,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (hasFocus || hasValue) ? const Color(0xFF0F4D3C) : Colors.grey.shade300,
          width: (hasFocus || hasValue) ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
          )
        ],
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF0F4D3C)),
        inputFormatters: [LengthLimitingTextInputFormatter(1), FilteringTextInputFormatter.digitsOnly],
        onChanged: (v) {
          setState(() {});
          if (v.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (v.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          if (v.isNotEmpty && index == 5) {
            _verifyOtp();
          }
        },
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
      ),
    );
  }

  void _verifyOtp() async {
    String code = _controllers.map((c) => c.text).join();
    if (code.length != 6) return;

    setState(() => _isLoading = true);
    HapticFeedback.heavyImpact();

    try {
      if (widget.isEmailOtp && widget.email != null) {
        // Verify Email 6-digit OTP
        final verified = await ApiService.verifyEmailOtp(
          email: widget.email!,
          otp: code,
        );

        if (verified) {
          final String userId = 'USER-${widget.email!.replaceAll('@', '_').replaceAll('.', '_')}';
          await ApiService.saveUser(
            userId: userId,
            phone: widget.email!,
          );
          await NotificationManager().updateToken();

          if (mounted) {
            setState(() => _isLoading = false);
            Navigator.pushAndRemoveUntil(
              context, 
              MaterialPageRoute(builder: (_) => const MainScreen()),
              (route) => false
            );
          }
          return;
        } else {
          throw Exception('Invalid OTP code');
        }
      }

      // Verify Phone OTP via Firebase
      if (widget.verificationId != null) {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: widget.verificationId!, 
          smsCode: code
        );

        UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        User? user = userCredential.user;

        if (user != null) {
          await ApiService.saveUser(
            userId: user.uid,
            phone: widget.phone ?? 'User',
          );
          await NotificationManager().updateToken();

          if (mounted) {
            setState(() => _isLoading = false);
            Navigator.pushAndRemoveUntil(
              context, 
              MaterialPageRoute(builder: (_) => const MainScreen()),
              (route) => false,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Invalid OTP code. Please enter 6-digit OTP.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }
}
