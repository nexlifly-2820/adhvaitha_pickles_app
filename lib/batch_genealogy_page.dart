import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'models.dart';

class BatchGenealogyPage extends StatelessWidget {
  final Order order;
  const BatchGenealogyPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18453B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: Color(0xFFD4AF37), size: 28),
        ),
        title: Text(
          'BATCH CERTIFICATE',
          style: GoogleFonts.philosopher(color: const Color(0xFFD4AF37), fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            _buildCertificateHeader(),
            const SizedBox(height: 40),
            _buildMetadataGrid(),
            const SizedBox(height: 50),
            _buildArtisanalStamp(),
            const SizedBox(height: 60),
            _buildOriginStory(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3), width: 1),
          ),
          child: const Icon(Icons.verified_user_rounded, color: Color(0xFFD4AF37), size: 60),
        ),
        const SizedBox(height: 24),
        Text(
          order.batchId,
          style: GoogleFonts.philosopher(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
        ),
        const SizedBox(height: 8),
        const Text(
          'OFFICIAL QUALITY AUTHENTICATION',
          style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 3),
        ),
      ],
    );
  }

  Widget _buildMetadataGrid() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _metaRow('Preparation Date', DateFormat('dd MMMM, yyyy').format(order.preparationDate)),
          const Divider(height: 40, color: Colors.white10),
          _metaRow('Chef in Charge', 'Chef Lakshmi Amma'),
          const Divider(height: 40, color: Colors.white10),
          _metaRow('Spice Sourcing', order.spiceOrigin),
          const Divider(height: 40, color: Colors.white10),
          _metaRow('Oil Profile', 'Cold-Pressed Groundnut'),
          const Divider(height: 40, color: Colors.white10),
          _metaRow('Salt Origin', 'Tuticorin Sea Salt'),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildArtisanalStamp() {
    return Column(
      children: [
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5), width: 2),
          ),
          alignment: Alignment.center,
          child: Transform.rotate(
            angle: -0.2,
            child: Text(
              'APPROVED\nADHVAITHA',
              textAlign: TextAlign.center,
              style: GoogleFonts.philosopher(color: const Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
            ),
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          'Digitally Verified Artisanal Batch',
          style: TextStyle(color: Colors.white24, fontSize: 10, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildOriginStory() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 24),
          const SizedBox(height: 15),
          const Text(
            'THE BATCH PROMISE',
            style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(
            'This specific batch was crafted during the peak sun hours to ensure perfect dehydration of spices. No artificial heat was introduced, preserving the heirloom probiotics of the coastal Andhra soil.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }
}
