import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/order_item.dart';
import '../utils/cloudinary.dart';

class FallingProduct extends StatelessWidget {
  final OrderItem item;
  final double progress;
  final double xOffset;

  const FallingProduct({
    super.key,
    required this.item,
    required this.progress,
    required this.xOffset,
  });

  @override
  Widget build(BuildContext context) {
    if (progress <= 0.0) return const SizedBox.shrink();

    const curve = Cubic(0.5, 0.0, 0.7, 1.0);
    final curvedProgress = curve.transform(progress.clamp(0.0, 1.0));

    final yPos = -30.0 + (curvedProgress * 155.0);
    final rotation = -0.21 + (curvedProgress * 0.35);

    double opacity = 1.0;
    if (curvedProgress < 0.15) {
      opacity = curvedProgress / 0.15;
    } else if (curvedProgress > 0.80) {
      opacity = (1.0 - curvedProgress) / 0.20;
    }
    opacity = opacity.clamp(0.0, 1.0);

    double scale = 1.0;
    if (curvedProgress > 0.70) {
      scale = 1.0 - ((curvedProgress - 0.70) / 0.30) * 0.5;
    }

    final thumbUrl = cloudinaryThumb(item.imageUrl, size: 160);
    final catColor = getCategoryColor(item.category);
    final firstLetter = item.name.isNotEmpty ? item.name[0].toUpperCase() : 'P';

    return Positioned(
      left: xOffset - 24,
      top: yPos,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: rotation,
          child: Transform.scale(
            scale: scale,
            child: Semantics(
              label: 'Falling ${item.name}',
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x297C2D12),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: thumbUrl.isNotEmpty && thumbUrl.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: thumbUrl,
                          width: 42,
                          height: 42,
                          fit: BoxFit.cover,
                          errorWidget: (c, e, s) => _fallbackBadge(catColor, firstLetter),
                          placeholder: (c, u) => Container(
                            color: catColor.withOpacity(0.2),
                            alignment: Alignment.center,
                            child: Text(
                              firstLetter,
                              style: TextStyle(
                                color: catColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      : _fallbackBadge(catColor, firstLetter),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallbackBadge(Color catColor, String letter) {
    return Container(
      color: catColor,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
    );
  }
}
