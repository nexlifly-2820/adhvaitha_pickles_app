import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PhotoCard extends StatelessWidget {
  final String imagePath;
  final double angle;
  final bool hasPin;
  final String? label;
  final List<FloatingIcon> icons;

  const PhotoCard({
    super.key,
    required this.imagePath,
    this.angle = 0,
    this.hasPin = false,
    this.label,
    this.icons = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: CustomPaint(
              painter: CheckeredPainter(),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: JourneyImage(path: imagePath, width: 280, height: 200),
              ),
            ),
          ),
          if (hasPin)
            const Positioned(
              top: -15,
              left: 20,
              child: Icon(Icons.push_pin, color: Color(0xFFE21B23), size: 30),
            ),
          if (label != null)
            Positioned(
              bottom: -10,
              right: -10,
              child: Transform.rotate(
                angle: 0.2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE21B23),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    label!,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
              ),
            ),
          ...icons,
        ],
      ),
    );
  }
}

class CheckeredPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintYellow = Paint()..color = const Color(0xFFFFD700);
    const double squareSize = 15.0;

    for (double x = 0; x < size.width; x += squareSize) {
      for (double y = 0; y < size.height; y += squareSize) {
        if ((x / squareSize).floor() % 2 != (y / squareSize).floor() % 2) {
          canvas.drawRect(Rect.fromLTWH(x, y, squareSize, squareSize), paintYellow);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FloatingIcon extends StatelessWidget {
  final IconData icon;
  final double? top, bottom, left, right;
  final Color color;

  const FloatingIcon({super.key, required this.icon, this.top, this.bottom, this.left, this.right, required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Transform.rotate(
        angle: 0.1,
        child: Icon(icon, color: color, size: 40),
      ),
    );
  }
}

class RedBanner extends StatelessWidget {
  final String text;
  const RedBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        decoration: const BoxDecoration(
          color: Color(0xFFE21B23),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), bottomLeft: Radius.circular(30)),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
    );
  }
}

class JourneyImage extends StatelessWidget {
  final String path;
  final double? width, height;
  final BoxFit fit;

  const JourneyImage({super.key, required this.path, this.width, this.height, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      return Container(width: width, height: height, color: Colors.grey[200], child: const Icon(Icons.image_outlined));
    }
    if (path.startsWith('http')) {
      return Image.network(path, width: width, height: height, fit: fit, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image));
    }
    return Image.asset(path, width: width, height: height, fit: fit, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image));
  }
}
