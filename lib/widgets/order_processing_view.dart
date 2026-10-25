import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/order_item.dart';
import '../utils/cloudinary.dart';
import 'open_box_painter.dart';
import 'falling_product.dart';

class OrderProcessingView extends StatefulWidget {
  final List<OrderItem> items;
  final AnimationController animationController;
  final bool isApiLoading;

  const OrderProcessingView({
    super.key,
    required this.items,
    required this.animationController,
    required this.isApiLoading,
  });

  @override
  State<OrderProcessingView> createState() => _OrderProcessingViewState();
}

class _OrderProcessingViewState extends State<OrderProcessingView> {
  final Set<int> _hapticsTriggered = {};

  @override
  void initState() {
    super.initState();
    widget.animationController.addListener(_onAnimTick);
  }

  @override
  void dispose() {
    widget.animationController.removeListener(_onAnimTick);
    super.dispose();
  }

  void _onAnimTick() {
    if (!mounted) return;
    final totalDurationMs = widget.animationController.duration?.inMilliseconds ?? 3000;
    final currentMs = widget.animationController.value * totalDurationMs;

    final n = math.min(widget.items.length, 4);
    for (int i = 0; i < n; i++) {
      final startMs = 300 + (i * 750);
      final landMs = startMs + 600;

      if (currentMs >= landMs && !_hapticsTriggered.contains(i)) {
        _hapticsTriggered.add(i);
        HapticFeedback.lightImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayItems = widget.items;
    final fallingCount = math.min(displayItems.length, 4);
    final hiddenCount = displayItems.length > 4 ? displayItems.length - 4 : 0;

    return PopScope(
      canPop: false,
      child: AnimatedBuilder(
        animation: widget.animationController,
        builder: (context, child) {
          final totalMs = widget.animationController.duration?.inMilliseconds ?? 3000;
          final currentMs = widget.animationController.value * totalMs;

          double squashDy = 0.0;
          double squashScaleX = 1.0;

          for (int i = 0; i < fallingCount; i++) {
            final startMs = 300 + (i * 750);
            final landMs = startMs + 600;
            if (currentMs >= landMs && currentMs < landMs + 250) {
              final squashProgress = (currentMs - landMs) / 250.0;
              final squashSin = math.sin(squashProgress * math.pi);
              squashDy = squashSin * 4.0;
              squashScaleX = 1.0 + (squashSin * 0.03);
              break;
            }
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                Text(
                  'Placing your order…',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.baloo2(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF7C2D12),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Packing each item fresh for you',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: const Color(0xFF6B4A36),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: 200,
                  height: 190,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      for (int i = 0; i < fallingCount; i++) ...[
                        _buildFallingItem(i, fallingCount, currentMs, displayItems[i]),
                      ],
                      Positioned(
                        bottom: 0,
                        left: 30,
                        child: OpenBoxWidget(
                          squashDy: squashDy,
                          squashScaleX: squashScaleX,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                Container(
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    children: [
                      for (int i = 0; i < displayItems.length; i++) ...[
                        _buildItemRow(i, currentMs, displayItems[i]),
                        if (i < displayItems.length - 1) const Divider(height: 16, color: Color(0xFFFFF7ED)),
                      ],
                      if (hiddenCount > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEDD5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+$hiddenCount more items in this box',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFC2410C),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 8,
                    child: widget.isApiLoading && widget.animationController.value >= 0.98
                        ? const LinearProgressIndicator(
                            backgroundColor: Color(0xFFFFEDD5),
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEA580C)),
                          )
                        : LinearProgressIndicator(
                            value: widget.animationController.value,
                            backgroundColor: const Color(0xFFFFEDD5),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEA580C)),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Confirming payment & sealing your box',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B4A36),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFallingItem(
      int i, int totalFalling, double currentMs, OrderItem item) {
    final startMs = 300 + (i * 750);
    final dropDuration = 900;
    final itemProgress = ((currentMs - startMs) / dropDuration).clamp(0.0, 1.0);

    final xCenter = 100.0;
    final spacing = 28.0;
    final xOffset = xCenter + (i - (totalFalling - 1) / 2.0) * spacing;

    return FallingProduct(
      item: item,
      progress: itemProgress,
      xOffset: xOffset,
    );
  }

  Widget _buildItemRow(int i, double currentMs, OrderItem item) {
    final landMs = 300 + (i * 750) + 600;
    final isLanded = i < 4 ? currentMs >= landMs : currentMs >= (300 + 3 * 750 + 600);

    final thumbUrl = cloudinaryThumb(item.imageUrl, size: 160);
    final catColor = getCategoryColor(item.category);
    final firstLetter = item.name.isNotEmpty ? item.name[0].toUpperCase() : 'P';

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isLanded ? 1.0 : 0.35,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              color: const Color(0xFFFFF7ED),
              child: thumbUrl.isNotEmpty && thumbUrl.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: thumbUrl,
                      width: 40,
                      height: 40,
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

          SizedBox(
            width: 26,
            height: 26,
            child: isLanded
                ? AnimatedScale(
                    scale: isLanded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF16A34A),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  )
                : const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEA580C)),
                    ),
                  ),
          ),
        ],
      ),
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
          fontSize: 14,
        ),
      ),
    );
  }
}
