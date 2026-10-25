import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/order_result.dart';
import '../models/order_item.dart';
import '../utils/cloudinary.dart';
import 'confetti_burst.dart';

class OrderPlacedView extends StatefulWidget {
  final OrderResult orderResult;
  final VoidCallback onTrackOrder;
  final VoidCallback onContinueShopping;

  const OrderPlacedView({
    super.key,
    required this.orderResult,
    required this.onTrackOrder,
    required this.onContinueShopping,
  });

  @override
  State<OrderPlacedView> createState() => _OrderPlacedViewState();
}

class _OrderPlacedViewState extends State<OrderPlacedView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _hapticTriggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    _controller.addListener(() {
      final currentMs = _controller.value * 3800;
      if (currentMs >= 750 && !_hapticTriggered) {
        _hapticTriggered = true;
        HapticFeedback.mediumImpact();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.maybeOf(context)?.disableAnimations == true) {
        _controller.value = 1.0;
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final currentMs = _controller.value * 3800;

        final circleProgress =
            ((currentMs - 200) / 500).clamp(0.0, 1.0);
        final circleScale = Curves.elasticOut.transform(circleProgress);

        final ringProgress1 =
            ((currentMs - 500) % 1400) / 1400.0;
        final ringProgress2 =
            ((currentMs - 1200) % 1400) / 1400.0;

        final confettiProgress =
            ((currentMs - 550) / 1100).clamp(0.0, 1.0);

        final checkProgress =
            ((currentMs - 750) / 500).clamp(0.0, 1.0);

        double getSectionOpacity(int index) {
          final startMs = 1000 + (index * 200);
          return ((currentMs - startMs) / 600).clamp(0.0, 1.0);
        }

        double getSectionOffset(int index) {
          final opacity = getSectionOpacity(index);
          return (1.0 - opacity) * 24.0;
        }

        final scooterTime =
            currentMs >= 2200 ? ((currentMs - 2200) % 4000) / 4000.0 : 0.0;
        final wheelBob = math.sin(scooterTime * math.pi * 16) * 1.0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              SizedBox(
                width: 220,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    if (currentMs >= 500)
                      Transform.scale(
                        scale: 0.6 + (ringProgress1 * 1.3),
                        child: Opacity(
                          opacity: (1.0 - ringProgress1) * 0.7,
                          child: Container(
                            width: 132,
                            height: 132,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFF59E0B),
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      ),

                    if (currentMs >= 1200)
                      Transform.scale(
                        scale: 0.6 + (ringProgress2 * 1.3),
                        child: Opacity(
                          opacity: (1.0 - ringProgress2) * 0.7,
                          child: Container(
                            width: 132,
                            height: 132,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFF59E0B),
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      ),

                    ConfettiBurst(progress: confettiProgress),

                    Transform.scale(
                      scale: circleScale,
                      child: Container(
                        width: 132,
                        height: 132,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFC2410C),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x66EA580C),
                              blurRadius: 28,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: _CheckmarkPainter(checkProgress),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Transform.translate(
                offset: Offset(0, getSectionOffset(0)),
                child: Opacity(
                  opacity: getSectionOpacity(0),
                  child: Column(
                    children: [
                      Text(
                        'Order Placed!',
                        style: GoogleFonts.baloo2(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF7C2D12),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your homemade goodies are being packed with love.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          color: const Color(0xFF6B4A36),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEDD5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ORDER #${widget.orderResult.orderId}',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: const Color(0xFF9A3412),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Transform.translate(
                offset: Offset(0, getSectionOffset(1)),
                child: Opacity(
                  opacity: getSectionOpacity(1),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x147C2D12),
                          blurRadius: 18,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Arriving by ${widget.orderResult.deliveryDate}',
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2A1A10),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Confirmed',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          height: 36,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final roadWidth = constraints.maxWidth;
                              final scooterX = scooterTime * (roadWidth - 36);

                              return Stack(
                                children: [
                                  Positioned(
                                    top: 24,
                                    left: 0,
                                    right: 0,
                                    child: CustomPaint(
                                      size: Size(roadWidth, 2),
                                      painter: _DashedLinePainter(),
                                    ),
                                  ),
                                  Positioned(
                                    left: scooterX,
                                    top: 4,
                                    child: SizedBox(
                                      width: 36,
                                      height: 28,
                                      child: CustomPaint(
                                        painter:
                                            _ScooterPainter(wheelBob: wheelBob),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            height: 6,
                            child: LinearProgressIndicator(
                              value: (currentMs >= 2000
                                      ? ((currentMs - 2000) / 1200)
                                          .clamp(0.0, 1.0) *
                                          0.28
                                      : 0.0),
                              backgroundColor: const Color(0xFFFFEDD5),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFEA580C),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _progressLabel('Placed', isHighlight: true),
                            _progressLabel('Packed', isHighlight: false),
                            _progressLabel('Shipped', isHighlight: false),
                            _progressLabel('Delivered', isHighlight: false),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Transform.translate(
                offset: Offset(0, getSectionOffset(2)),
                child: Opacity(
                  opacity: getSectionOpacity(2),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x147C2D12),
                          blurRadius: 18,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR ORDER',
                          style: GoogleFonts.baloo2(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: const Color(0xFF7C2D12),
                          ),
                        ),
                        const SizedBox(height: 14),

                        for (int i = 0; i < widget.orderResult.items.length; i++) ...[
                          _buildOrderSummaryRow(
                              widget.orderResult.items[i], currencyFormatter),
                          if (i < widget.orderResult.items.length - 1)
                            const Divider(height: 20, color: Color(0xFFFFF7ED)),
                        ],

                        const Divider(height: 24, thickness: 1, color: Color(0xFFFFEDD5)),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Paid',
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2A1A10),
                              ),
                            ),
                            Text(
                              currencyFormatter.format(widget.orderResult.total),
                              style: GoogleFonts.baloo2(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFC2410C),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Transform.translate(
                offset: Offset(0, getSectionOffset(3)),
                child: Opacity(
                  opacity: getSectionOpacity(3),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: widget.onTrackOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC2410C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Track Order',
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: widget.onContinueShopping,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF7C2D12),
                            side: const BorderSide(
                                color: Color(0xFFEA580C), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Continue Shopping',
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _progressLabel(String text, {required bool isHighlight}) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
        color: isHighlight ? const Color(0xFFC2410C) : const Color(0xFF6B4A36),
      ),
    );
  }

  Widget _buildOrderSummaryRow(OrderItem item, NumberFormat formatter) {
    final thumbUrl = cloudinaryThumb(item.imageUrl, size: 160);
    final catColor = getCategoryColor(item.category);
    final firstLetter = item.name.isNotEmpty ? item.name[0].toUpperCase() : 'P';

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            color: const Color(0xFFFFF7ED),
            child: thumbUrl.isNotEmpty && thumbUrl.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: thumbUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorWidget: (c, e, s) => _rowFallback(catColor, firstLetter),
                  )
                : _rowFallback(catColor, firstLetter),
          ),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2A1A10),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${item.category} · ${item.weight}${item.qty > 1 ? ' ×${item.qty}' : ''}',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: const Color(0xFF6B4A36),
                ),
              ),
            ],
          ),
        ),

        Text(
          formatter.format(item.price * item.qty),
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2A1A10),
          ),
        ),
      ],
    );
  }

  Widget _rowFallback(Color catColor, String letter) {
    return Container(
      color: catColor,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;

  _CheckmarkPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.68)
      ..lineTo(size.width * 0.72, size.height * 0.36);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final pathMetric = metrics.first;
    final extractPath =
        pathMetric.extractPath(0.0, pathMetric.length * progress.clamp(0.0, 1.0));

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFDBA74)
      ..strokeWidth = 2.0;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = 0.0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(math.min(startX + dashWidth, size.width), 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScooterPainter extends CustomPainter {
  final double wheelBob;

  _ScooterPainter({required this.wheelBob});

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = const Color(0xFFC2410C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final parcelPaint = Paint()
      ..color = const Color(0xFFFFF7ED)
      ..style = PaintingStyle.fill;

    final parcelBorder = Paint()
      ..color = const Color(0xFF9A3412)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final wheelPaint = Paint()
      ..color = const Color(0xFF2A1A10)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(4, 16)
      ..quadraticBezierTo(10, 12, 16, 16)
      ..lineTo(22, 16)
      ..lineTo(26, 8)
      ..lineTo(32, 8);

    canvas.drawPath(path, bodyPaint);

    final parcelRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(2, 6, 10, 9),
      const Radius.circular(2),
    );
    canvas.drawRRect(parcelRect, parcelPaint);
    canvas.drawRRect(parcelRect, parcelBorder);

    canvas.drawCircle(Offset(8, 20 + wheelBob), 3.5, wheelPaint);
    canvas.drawCircle(Offset(24, 20 + wheelBob), 3.5, wheelPaint);
  }

  @override
  bool shouldRepaint(covariant _ScooterPainter oldDelegate) =>
      oldDelegate.wheelBob != wheelBob;
}
