import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'api_service.dart';
import 'otp_verification_page.dart';
import 'privacy_policy_page.dart';
import 'terms_of_service_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isEmailInputMode = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendEmailOtp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name.')),
      );
      return;
    }
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
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
              name: name,
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

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF0F5C45),
      body: Stack(
        children: [
          // Background Template
          Positioned.fill(
            child: Image.asset(
              'assets/images/otp_bg_screen.png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Bar (Back button if in email mode only)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _isEmailInputMode
                          ? GestureDetector(
                              onTap: () => setState(() => _isEmailInputMode = false),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.35),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
                                ),
                                child: const Icon(Icons.chevron_left_rounded, color: Color(0xFF0F4D3C), size: 26),
                              ),
                            )
                          : const SizedBox(width: 38),
                      const SizedBox(width: 38),
                    ],
                  ),
                ),

                // Center Illustration / Logo Area (shrinks/hides when keyboard is open)
                if (!isKeyboardOpen)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/AMBHUJAKSHI  logo.png',
                            height: 140,
                            fit: BoxFit.contain,
                          ).animate().fadeIn().scale(),
                          const SizedBox(height: 8),
                          Text(
                            'Great taste delivered\nat lowest rate',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ).animate().fadeIn(delay: 200.ms),
                        ],
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 10),

                // Bottom White Sheet Card wrapped in SingleChildScrollView to prevent overflow
                Expanded(
                  flex: isKeyboardOpen ? 1 : 0,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 20,
                              offset: Offset(0, -5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isEmailInputMode) ...[
                              // Email Input Mode
                              Text(
                                'Enter your email address to\nmanage orders',
                                style: GoogleFonts.philosopher(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF1B1B1B),
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Full Name Input Field Container
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Full Name',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F5C45),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFF0F5C45), width: 1.5),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.person_outline_rounded, color: Color(0xFF0F5C45), size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextField(
                                            controller: _nameController,
                                            keyboardType: TextInputType.name,
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF1B1B1B),
                                            ),
                                            onChanged: (v) => setState(() {}),
                                            decoration: InputDecoration(
                                              hintText: 'Enter your full name',
                                              hintStyle: GoogleFonts.poppins(
                                                color: Colors.grey.shade400,
                                                fontSize: 13,
                                                fontWeight: FontWeight.normal,
                                              ),
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Email Input Field Container
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Email Address',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F5C45),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFF0F5C45), width: 1.5),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.email_outlined, color: Color(0xFF0F5C45), size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextField(
                                            controller: _emailController,
                                            keyboardType: TextInputType.emailAddress,
                                            autofocus: false,
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF1B1B1B),
                                            ),
                                            onChanged: (v) => setState(() {}),
                                            decoration: InputDecoration(
                                              hintText: 'Enter your email address',
                                              hintStyle: GoogleFonts.poppins(
                                                color: Colors.grey.shade400,
                                                fontSize: 13,
                                                fontWeight: FontWeight.normal,
                                              ),
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Continue Button
                              GestureDetector(
                                onTap: (_isLoading || _nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty || !_emailController.text.contains('@'))
                                    ? null
                                    : _sendEmailOtp,
                                child: Container(
                                  height: 54,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: (_nameController.text.trim().isNotEmpty && _emailController.text.trim().isNotEmpty && _emailController.text.contains('@'))
                                        ? const Color(0xFF0F5C45)
                                        : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(27),
                                  ),
                                  alignment: Alignment.center,
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : Text(
                                          'Continue',
                                          style: GoogleFonts.poppins(
                                            color: (_nameController.text.trim().isNotEmpty && _emailController.text.trim().isNotEmpty && _emailController.text.contains('@'))
                                                ? Colors.white
                                                : Colors.grey.shade600,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                ),
                              ),
                            ] else ...[
                              // Initial Button Mode ("Log in with email")
                              GestureDetector(
                                onTap: () => setState(() => _isEmailInputMode = true),
                                child: Container(
                                  height: 54,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F5C45),
                                    borderRadius: BorderRadius.circular(27),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0F5C45).withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Log in with email',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Terms and Privacy Policy Footer
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'By tapping, I accept the ',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage())),
                                    child: Text(
                                      'privacy policy',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF0F4D3C),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    ' and ',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfServicePage())),
                                    child: Text(
                                      'terms of use',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF0F4D3C),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
