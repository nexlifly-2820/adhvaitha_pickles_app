import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cart_manager.dart';

class CouponsPage extends StatelessWidget {
  const CouponsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> coupons = [
      {
        'code': 'FIRST30',
        'title': '30% OFF',
        'badge': 'FIRST ORDER',
        'sub': 'A Special Welcome Offer',
        'min': '₹500',
        'bannerColor': const Color(0xFF0D3823),
        'color': const Color(0xFF0D3823),
      },
      {
        'code': 'PICKLE100',
        'title': '₹100 OFF',
        'badge': 'PICKLE SPECIAL',
        'sub': 'Flat Discount on All Pickles',
        'min': '₹999',
        'bannerColor': const Color(0xFF8B1E1E),
        'color': const Color(0xFF8B1E1E),
      },
      {
        'code': 'FESTIVE20',
        'title': '20% OFF',
        'badge': 'FESTIVE OFFER',
        'sub': 'Special Festive Season Discount',
        'min': '₹1500',
        'bannerColor': const Color(0xFFB8860B),
        'color': const Color(0xFFB8860B),
      },
      {
        'code': 'FREESHIP',
        'title': 'FREE DELIVERY',
        'badge': 'LIMITED TIME',
        'sub': 'On All Orders (No Minimum)',
        'min': '₹0',
        'icon': Icons.local_shipping_outlined,
        'bannerColor': const Color(0xFF1E513B),
        'color': const Color(0xFF1E513B),
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAF5E8),
      body: Stack(
        children: [
          // 1. Full-screen background image matching coupon_bg_screen.png
          Positioned.fill(
            child: Image.asset(
              'assets/images/coupon_bg_screen.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFFFF8E8),
              ),
            ),
          ),

          // 2. Main Scrollable Content Area inside SafeArea
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),

                // Header Bar (Back button + Title/Subtitle)
                _buildHeaderBar(context)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.2, end: 0),

                const SizedBox(height: 10),

                // Coupons List
                Expanded(
                  child: ListenableBuilder(
                    listenable: CartManager(),
                    builder: (context, _) {
                      final appliedCode = CartManager().appliedPromoCode;
                      return ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 14,
                          right: 14,
                          top: 4,
                          bottom: 120,
                        ),
                        physics: const BouncingScrollPhysics(),
                        itemCount: coupons.length,
                        itemBuilder: (context, index) {
                          final c = coupons[index];
                          final String code = c['code'] as String;
                          final bool isApplied = appliedCode == code;

                          return _CouponTicketCard(
                            coupon: c,
                            isApplied: isApplied,
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              Clipboard.setData(ClipboardData(text: code));

                              if (isApplied) {
                                CartManager().removePromoCode();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Coupon $code removed',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFF8B1E1E),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                CartManager().applyPromoCode(code);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Coupon $code applied successfully!',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFF0D3823),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          )
                              .animate()
                              .fadeIn(delay: (index * 100).ms, duration: 400.ms)
                              .slideY(begin: 0.1, end: 0);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered Header Title & Subtitle
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'My Coupons',
                style: GoogleFonts.philosopher(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0D3823),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'Save More, Enjoy Good Food',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5C5046),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 1,
                    color: const Color(0xFF0D3823).withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.favorite_outline_rounded,
                    size: 10,
                    color: Color(0xFF8B1E1E),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 30,
                    height: 1,
                    color: const Color(0xFF0D3823).withValues(alpha: 0.4),
                  ),
                ],
              ),
            ],
          ),

          // White Circular Back Button on Top Left
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 18),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 22,
                    color: Color(0xFF0D3823),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponTicketCard extends StatelessWidget {
  final Map<String, dynamic> coupon;
  final bool isApplied;
  final VoidCallback onTap;

  const _CouponTicketCard({
    required this.coupon,
    required this.isApplied,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = coupon['color'] as Color;
    final Color bannerColor = coupon['bannerColor'] as Color;
    final String code = coupon['code'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipPath(
        clipper: const TicketClipper(holeRadius: 9),
        child: Container(
          color: const Color(0xFFFFFDF8),
          constraints: const BoxConstraints(minHeight: 115),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Left Section: Banner with discount title & badge
                SizedBox(
                  width: 98,
                  child: Container(
                    color: bannerColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            coupon['title'] as String,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.philosopher(
                              fontSize:
                                  coupon['title'].toString().contains('FREE')
                                      ? 14
                                      : 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ),
                        if (coupon['icon'] != null) ...[
                          const SizedBox(height: 2),
                          Icon(
                            coupon['icon'] as IconData,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5C158),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              coupon['badge'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0D3823),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Dashed Vertical Divider
                CustomPaint(
                  size: const Size(1, double.infinity),
                  painter: DashedLinePainter(color: Colors.grey.shade300),
                ),

                // 3. Middle Section: Offer Subtitle & Min Order
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          coupon['sub'] as String,
                          style: GoogleFonts.philosopher(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D1B12),
                            fontStyle: FontStyle.italic,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 12,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                coupon['min'] == '₹0'
                                    ? 'No minimum order'
                                    : 'Min order: ${coupon['min']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Right Section: Use Code Box & Apply Arrow
                Padding(
                  padding: const EdgeInsets.only(right: 8, left: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Use Code',
                          style: GoogleFonts.poppins(
                            fontSize: 8.5,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: onTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isApplied ? Colors.green.shade800 : primaryColor,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isApplied ? 'APPLIED' : code,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFE5C158),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  isApplied
                                      ? Icons.check_circle_rounded
                                      : Icons.content_copy_rounded,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        GestureDetector(
                          onTap: onTap,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color:
                                  isApplied ? Colors.green.shade800 : bannerColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isApplied
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const double dashHeight = 4;
    const double dashSpace = 4;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class TicketClipper extends CustomClipper<Path> {
  final double holeRadius;

  const TicketClipper({this.holeRadius = 10.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    const cornerRadius = 14.0;

    path.moveTo(cornerRadius, 0);
    path.lineTo(size.width - cornerRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);

    final rightHoleY = size.height / 2;
    path.lineTo(size.width, rightHoleY - holeRadius);
    path.arcToPoint(
      Offset(size.width, rightHoleY + holeRadius),
      radius: Radius.circular(holeRadius),
      clockwise: false,
    );
    path.lineTo(size.width, size.height - cornerRadius);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - cornerRadius,
      size.height,
    );

    path.lineTo(cornerRadius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);

    final leftHoleY = size.height / 2;
    path.lineTo(0, leftHoleY + holeRadius);
    path.arcToPoint(
      Offset(0, leftHoleY - holeRadius),
      radius: Radius.circular(holeRadius),
      clockwise: false,
    );
    path.lineTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
