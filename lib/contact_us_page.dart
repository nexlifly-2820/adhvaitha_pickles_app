import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cloud_function_manager.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);
    HapticFeedback.mediumImpact();

    final success = await CloudFunctionManager().submitInquiry(
      name: _nameController.text,
      email: _emailController.text,
      phone: FirebaseAuth.instance.currentUser?.phoneNumber ?? 'N/A',
      message: _messageController.text,
    );

    setState(() => _isSending = false);

    if (success) {
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Message sent to our royal kitchen!'),
        backgroundColor: Color(0xFF18453B),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to send message. Please try again.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(title: const Text('CONTACT US')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.2), blurRadius: 30, spreadRadius: 5)
                ],
              ),
              child: const CircleAvatar(
                radius: 60,
                backgroundColor: Color(0xFF18453B),
                child: Icon(Icons.support_agent_rounded, size: 60, color: Color(0xFFD4AF37)),
              ),
            ).animate().scale(curve: Curves.elasticOut, duration: 1.seconds),
            const SizedBox(height: 30),
            Text(
              'WE ARE HERE TO HELP', 
              style: GoogleFonts.philosopher(
                fontSize: 24, 
                fontWeight: FontWeight.w900, 
                color: const Color(0xFF18453B), 
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Text('Reach out to us for any queries about our traditional flavors.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5)),
            
            const SizedBox(height: 40),
            
            // QUICK CONTACT TILES
            _ContactTile(icon: Icons.chat_bubble_rounded, title: 'Chat on WhatsApp', sub: '+91 98765 43210', color: const Color(0xFF25D366), onTap: () {
              HapticFeedback.mediumImpact();
            }),
            
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 30),
            
            // INQUIRY FORM
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SEND US A MESSAGE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2, color: Colors.grey)),
                  const SizedBox(height: 20),
                  _buildField('Your Name', _nameController, Icons.person_outline),
                  _buildField('Email Address', _emailController, Icons.email_outlined),
                  _buildField('Message', _messageController, Icons.edit_note_rounded, maxLines: 4),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isSending ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18453B),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isSending 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('SUBMIT INQUIRY', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50),
            const Text('OPERATING HOURS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2, color: Colors.grey)),
            const SizedBox(height: 10),
            const Text('Mon - Sat: 9 AM to 8 PM', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF18453B))),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF18453B)),
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
        validator: (v) => v!.isEmpty ? 'Required' : null,
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final Color color;
  final VoidCallback onTap;
  const _ContactTile({required this.icon, required this.title, required this.sub, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(30), 
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))]
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12), 
              decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle), 
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(sub, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF18453B))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }
}
