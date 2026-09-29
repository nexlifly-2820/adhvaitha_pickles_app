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
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/otp_bg_screen.png',
              fit: BoxFit.cover,
            ),
          ),

          // Main Screen Foreground Overlay
          SafeArea(
            child: Column(
              children: [
                // Top Navigation Row (Back Button & Cursive Greeting)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.6),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.chevron_left_rounded,
                            color: Color(0xFF0F4D3C),
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox.shrink(), // Removed Good Food text to match new design
                    ],
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Main Brand Logo
                        Image.asset(
                          'assets/images/AMBHUJAKSHI  logo.png',
                          height: 220,
                          fit: BoxFit.contain,
                        ).animate().fadeIn().scale(),

                        const SizedBox(height: 12),

                        // Title
                        Text(
                          widget.isEmailOtp ? 'Verify Your Email' : 'Verify Mobile Number',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.philosopher(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F4D3C),
                          ),
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 6),

                        // Subtitle
                        Text(
                          widget.isEmailOtp
                              ? "We've sent a 6-digit code to\nyour email address."
                              : "We've sent a 6-digit code to\nyour mobile number.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF4A5568),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Destination Pill Box (Email/Phone + Edit)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.isEmailOtp ? Icons.mark_email_read_outlined : Icons.phone_android_rounded,
                                color: const Color(0xFF0F4D3C),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getMaskedDestination(),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: const Color(0xFF1B1B1B),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(width: 1, height: 14, color: Colors.grey.shade300),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Text(
                                  'Edit',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: const Color(0xFF0F4D3C),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 300.ms),

                        const SizedBox(height: 24),

                        // 6 OTP Box Inputs
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) => _otpBox(index)),
                        ).animate().fadeIn(delay: 400.ms),

                        const SizedBox(height: 20),

                        // Timer & Resend Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 42,
                                    height: 42,
                                    child: CircularProgressIndicator(
                                      value: _resendSeconds / 28.0,
                                      strokeWidth: 2.5,
                                      color: const Color(0xFF0F4D3C),
                                      backgroundColor: const Color(0xFF0F4D3C).withValues(alpha: 0.15),
                                    ),
                                  ),
                                  Text(
                                    '00:${_resendSeconds.toString().padLeft(2, '0')}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F4D3C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Didn't receive the code?",
                                  style: GoogleFonts.poppins(
                                    color: Colors.black87,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                _resendSeconds > 0
                                    ? Text(
                                      'Resend in 00:${_resendSeconds.toString().padLeft(2, '0')}',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF0F4D3C),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
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
                                          'Resend Code',
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF0F4D3C),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                          ],
                        ).animate().fadeIn(delay: 500.ms),

                        const SizedBox(height: 24),

                        // Continue Button
                        GestureDetector(
                          onTap: _isLoading ? null : _verifyOtp,
                          child: Container(
                            height: 54,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0C3D2E), Color(0xFF0F4D3C)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: const Color(0xFFE5C76B).withValues(alpha: 0.6),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0C3D2E).withValues(alpha: 0.35),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                )
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _isLoading
                                ? const Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Color(0xFFE5C76B),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : Row(
                                    children: [
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'CONTINUE',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1.5,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.eco_outlined, color: Color(0xFFE5C76B), size: 20),
                                    ],
                                  ),
                          ),
                        ).animate().fadeIn(delay: 600.ms),

                        const SizedBox(height: 28),

                        // 3 Feature Badges Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  const Icon(Icons.eco_outlined, color: Color(0xFF2E3A20), size: 26),
                                  const SizedBox(height: 4),
                                  Text(
                                    'PURE\nINGREDIENTS',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF2E3A20),
                                      letterSpacing: 0.5,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(height: 32, width: 1, color: const Color(0xFF2E3A20).withValues(alpha: 0.25)),
                            Expanded(
                              child: Column(
                                children: [
                                  const Icon(Icons.soup_kitchen_outlined, color: Color(0xFF2E3A20), size: 26),
                                  const SizedBox(height: 4),
                                  Text(
                                    'TRADITIONAL\nRECIPES',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF2E3A20),
                                      letterSpacing: 0.5,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(height: 32, width: 1, color: const Color(0xFF2E3A20).withValues(alpha: 0.25)),
                            Expanded(
                              child: Column(
                                children: [
                                  const Icon(Icons.favorite_border_rounded, color: Color(0xFF2E3A20), size: 26),
                                  const SizedBox(height: 4),
                                  Text(
                                    'A HAPPIER\nYOU',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF2E3A20),
                                      letterSpacing: 0.5,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 700.ms),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Bottom Footer Bar (SAFE | TRUSTED | SINCE 1985)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFF2E3A20)),
                          const SizedBox(width: 4),
                          Text(
                            'SAFE',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E3A20),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Container(height: 14, width: 1, color: const Color(0xFF2E3A20).withValues(alpha: 0.3)),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.eco_outlined, size: 16, color: Color(0xFF2E3A20)),
                          const SizedBox(width: 4),
                          Text(
                            'TRUSTED',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E3A20),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Container(height: 14, width: 1, color: const Color(0xFF2E3A20).withValues(alpha: 0.3)),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.groups_outlined, size: 16, color: Color(0xFF2E3A20)),
                          const SizedBox(width: 4),
                          Text(
                            'SINCE 1985',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E3A20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(delay: 800.ms),
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
      width: 45,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (hasFocus || hasValue) ? const Color(0xFF0F4D3C) : Colors.white,
          width: (hasFocus || hasValue) ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0F4D3C),
        ),
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
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
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: '-',
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFF0F4D3C).withValues(alpha: 0.3),
            fontSize: 22,
            fontWeight: FontWeight.w400,
          ),
        ),
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
