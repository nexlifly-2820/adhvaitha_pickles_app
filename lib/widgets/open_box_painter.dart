import 'package:flutter/material.dart';

class OpenBoxWidget extends StatelessWidget {
  final double squashDy;
  final double squashScaleX;

  const OpenBoxWidget({
    super.key,
    this.squashDy = 0.0,
    this.squashScaleX = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, squashDy),
      child: Transform.scale(
        scaleX: squashScaleX,
        child: const SizedBox(
          width: 140,
          height: 92,
          child: CustomPaint(
            painter: OpenBoxPainter(),
          ),
        ),
      ),
    );
  }
}

class OpenBoxPainter extends CustomPainter {
  const OpenBoxPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const boxColor = Color(0xFFD97706);
    const boxShadowColor = Color(0xFFB45309);
    const flapColor = Color(0xFFF59E0B);
    const labelBg = Color(0xFFFFF7ED);
    const labelLine = Color(0xFFEA580C);

    final width = size.width;
    final height = size.height;

    // 1. Shadow beneath box
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromLTWH(10, height - 10, width - 20, 14),
      shadowPaint,
    );

    // 2. Open Flaps
    final flapPaint = Paint()
      ..color = flapColor
      ..style = PaintingStyle.fill;

    final flapBorderPaint = Paint()
      ..color = boxColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Left Flap
    final leftFlap = Path()
      ..moveTo(0, 30)
      ..lineTo(-22, 6)
      ..lineTo(25, -2)
      ..lineTo(40, 30)
      ..close();
    canvas.drawPath(leftFlap, flapPaint);
    canvas.drawPath(leftFlap, flapBorderPaint);

    // Right Flap
    final rightFlap = Path()
      ..moveTo(width, 30)
      ..lineTo(width + 22, 6)
      ..lineTo(width - 25, -2)
      ..lineTo(width - 40, 30)
      ..close();
    canvas.drawPath(rightFlap, flapPaint);
    canvas.drawPath(rightFlap, flapBorderPaint);

    // 3. Main Box Body
    final bodyPath = Path()
      ..moveTo(0, 30)
      ..lineTo(width, 30)
      ..lineTo(width, height - 12)
      ..quadraticBezierTo(width, height, width - 12, height)
      ..lineTo(12, height)
      ..quadraticBezierTo(0, height, 0, height - 12)
      ..close();

    final bodyPaint = Paint()
      ..color = boxColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(bodyPath, bodyPaint);

    // Side Shadow on Box
    final sideShadow = Paint()
      ..color = boxShadowColor.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    final sidePath = Path()
      ..moveTo(width - 25, 30)
      ..lineTo(width, 30)
      ..lineTo(width, height - 12)
      ..quadraticBezierTo(width, height, width - 12, height)
      ..lineTo(width - 25, height)
      ..close();
    canvas.drawPath(sidePath, sideShadow);

    // Top Rim
    final rimPaint = Paint()
      ..color = flapColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawLine(const Offset(0, 30), Offset(width, 30), rimPaint);

    // 4. Cream Label
    const labelWidth = 48.0;
    const labelHeight = 28.0;
    final labelLeft = (width - labelWidth) / 2;
    const labelTop = 46.0;

    final labelRRect = RRect.fromLTRBAndCorners(
      labelLeft,
      labelTop,
      labelLeft + labelWidth,
      labelTop + labelHeight,
      topLeft: const Radius.circular(6),
      topRight: const Radius.circular(6),
      bottomLeft: const Radius.circular(6),
      bottomRight: const Radius.circular(6),
    );

    canvas.drawRRect(labelRRect, Paint()..color = labelBg);

    // 2 Orange lines on label
    final linePaint = Paint()
      ..color = labelLine
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(labelLeft + 10, labelTop + 10),
      Offset(labelLeft + labelWidth - 10, labelTop + 10),
      linePaint,
    );
    canvas.drawLine(
      Offset(labelLeft + 14, labelTop + 18),
      Offset(labelLeft + labelWidth - 14, labelTop + 18),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
