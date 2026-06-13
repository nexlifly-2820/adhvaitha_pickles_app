import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppUpdatePage extends StatelessWidget {
  const AppUpdatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18453B),
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
              ),
              child: const Icon(Icons.system_update_rounded, color: Color(0xFFD4AF37), size: 60),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
            const SizedBox(height: 40),
            Text(
              'NEW FLAVORS\nAWAIT YOU',
              textAlign: TextAlign.center,
              style: GoogleFonts.philosopher(
                color: Colors.white, 
                fontSize: 32, 
                fontWeight: FontWeight.w900, 
                height: 1.1,
                letterSpacing: 2
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'A fresh batch of features and seasonal collections is ready. Please update your app to continue your royal journey.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: () {
                // Link to Play Store / App Store
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: const Color(0xFF18453B),
                minimumSize: const Size(double.infinity, 64),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('UPDATE NOW', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
            ),
            const SizedBox(height: 20),
            const Text(
              'v1.0.0 → v1.1.0',
              style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
