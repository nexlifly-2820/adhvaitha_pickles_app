import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RoyalLoadingSpinner extends StatelessWidget {
  final String message;
  final double size;
  final Color? color;
  final bool isFullScreen;

  const RoyalLoadingSpinner({
    super.key,
    this.message = 'Loading Fresh Heritage Flavors...',
    this.size = 54.0,
    this.color,
    this.isFullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? const Color(0xFF18453B);
    const goldColor = Color(0xFFD4AF37);

    if (isFullScreen) {
      return Container(
        color: const Color(0xFFF6F6F6),
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/ambhujakshi_loading_fullscreen.gif',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => _buildFallbackSpinner(themeColor, goldColor),
            ),
          ],
        ),
      );
    }

    return _buildFallbackSpinner(themeColor, goldColor);
  }

  Widget _buildFallbackSpinner(Color themeColor, Color goldColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                    backgroundColor: goldColor.withOpacity(0.25),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: goldColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: goldColor,
                    size: 20,
                  ),
                ),
              ],
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.philosopher(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 24, height: 1.2, color: goldColor.withOpacity(0.6)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.circle, size: 4, color: goldColor),
                  ),
                  Container(width: 24, height: 1.2, color: goldColor.withOpacity(0.6)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
