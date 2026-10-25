import 'dart:math' as math;
import 'package:flutter/material.dart';

class ConfettiBurst extends StatelessWidget {
  final double progress;

  const ConfettiBurst({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    if (progress <= 0.0 || progress >= 1.0) return const SizedBox.shrink();

    return SizedBox(
      width: 280,
      height: 280,
      child: CustomPaint(
        painter: _ConfettiPainter(progress: progress),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;

  _ConfettiPainter({required this.progress});

  static const colors = [
    Color(0xFFF59E0B),
    Color(0xFFC2410C),
    Color(0xFF16A34A),
    Color(0xFFDC2626),
    Color(0xFFFACC15),
    Color(0xFFEA580C),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    const distances = [90.0, 108.0, 126.0];

    for (int i = 0; i < 14; i++) {
      final color = colors[i % colors.length].withOpacity(opacity);
      final paint = Paint()..color = color;

      final angle = (i / 14.0) * 2 * math.pi;
      final maxDist = distances[i % distances.length];
      final currentDist = maxDist * Curves.decelerate.transform(progress.clamp(0.0, 1.0));

      final px = center.dx + math.cos(angle) * currentDist;
      final py = center.dy + math.sin(angle) * currentDist;

      final rotationAngle = (i * 47.0 * math.pi / 180.0) + (progress * math.pi);

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rotationAngle);

      if (i % 2 == 0) {
        canvas.drawCircle(Offset.zero, 5, paint);
      } else {
        final rect = Rect.fromCenter(center: Offset.zero, width: 10, height: 10);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2.5)), paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
