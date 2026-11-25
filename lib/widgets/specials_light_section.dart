import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models.dart';
import '../product_detail_page.dart';
import '../product_listing_page.dart';
import '../navigation_util.dart';
import '../product_manager.dart';
import '../product_lookup.dart';
import '../app_config_repository.dart';
import '../image_util.dart';
import 'specials_lotus_eye_screen.dart';
import '../cart_manager.dart';
import '../cart_page.dart';

class LotusItem {
  final String id, name, image;
  const LotusItem({required this.id, required this.name, required this.image});

  factory LotusItem.fromJson(Map<String, dynamic> j) =>
      LotusItem(id: '${j['id'] ?? ''}', name: '${j['name'] ?? ''}', image: '${j['image'] ?? ''}');
}

class SpecialsLightSection extends StatefulWidget {
  final List<LotusItem> items;
  final ValueChanged<LotusItem>? onTap;
  final String background;

  const SpecialsLightSection({
    super.key,
    required this.items,
    this.onTap,
    this.background = 'assets/images/ambhujakshi_specials_light_background.png',
  });

  @override
  State<SpecialsLightSection> createState() => _SpecialsLightSectionState();
}

class _SpecialsLightSectionState extends State<SpecialsLightSection> {
  static const _imgW = 1312.0, _imgH = 1199.0;
  static const _cols = [
    [66.0, 442.0],
    [472.0, 844.0],
    [874.0, 1248.0]
  ];
  static const _rows = [
    [507.0, 790.0],
    [817.0, 1106.0]
  ];

  StreamSubscription? _sub;
  List<LotusItem> _liveItems = [];

  @override
  void initState() {
    super.initState();
    _listenToSpecialsConfig();
  }

  void _listenToSpecialsConfig() {
    _sub = AppConfigRepository().getSpecialsLightStream().listen((data) {
      if (!mounted) return;
      if (data.isNotEmpty) {
        // Only use what the new admin manager saved (it always has sizes/prices).
        // Old saves (name + image only) are ignored so the built-in specials show.
        final parsed = data
            .where((e) => e['enabled'] != false && '${e['name'] ?? ''}'.isNotEmpty && (e['variants'] is List) && (e['variants'] as List).isNotEmpty)
            .map((e) => LotusItem.fromJson(e))
            .toList();
        if (parsed.isNotEmpty) {
          setState(() => _liveItems = parsed);
        }
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<LotusItem> get _effectiveItems {
    if (_liveItems.isNotEmpty) {
      return _liveItems;
    }
    if (widget.items.isNotEmpty) {
      return widget.items;
    }
    return _defaultItems;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final k = w / _imgW;
    final h = _imgH * k;
    final s = w / 390;

    final displayItems = _effectiveItems;

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              widget.background,
              fit: BoxFit.fill,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFFFF8EC),
              ),
            ),
          ),
          for (var i = 0; i < displayItems.length && i < 6; i++)
            Positioned(
              left: _cols[i % 3][0] * k,
              top: _rows[i ~/ 3][0] * k,
              width: (_cols[i % 3][1] - _cols[i % 3][0]) * k,
              height: (_rows[i ~/ 3][1] - _rows[i ~/ 3][0]) * k,
              child: _Tile(
                item: displayItems[i],
                s: s,
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (widget.onTap != null) {
                    widget.onTap!(displayItems[i]);
                  } else {
                    _openItemProduct(context, displayItems[i]);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  void _openItemProduct(BuildContext context, LotusItem item) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => SpecialsLotusEyeScreen(
          apiBase: 'https://admin.adhvaithafoods.in/api',
          initialId: item.id,
          initialName: item.name,
          frameAsset: 'assets/images/lotus_eye_frame.png',
          lotusAsset: 'assets/images/lotus_on_water.png',
          cartCount: CartManager().itemCount,
          onAdd: (specialItem, variant, qty) async {
            try {
              final match = productFor(specialItem.name, weights: {variant.label: variant.price.toDouble()}, category: 'Specials');
              CartManager().addToCart(match, quantity: qty, weight: variant.label);
              return true;
            } catch (_) {
              return false;
            }
          },
          onGoToCart: () => AppNavigator.push(context, const CartPage()),
        ),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ),
    );
  }

  static const List<LotusItem> _defaultItems = [
    LotusItem(id: 'gongura_pickle', name: 'Gongura Pickle', image: 'assets/images/special_gongura_pickle.png'),
    LotusItem(id: 'tomato_pickle', name: 'Tomato Pickle', image: 'assets/images/special_tomato_pickle.png'),
    LotusItem(id: 'kandi_podi', name: 'Kandi Podi', image: 'assets/images/special_kandi_podi.png'),
    LotusItem(id: 'chekkalu', name: 'Chekkalu', image: 'assets/images/special_chekkalu.png'),
    LotusItem(id: 'ariselu', name: 'Ariselu', image: 'assets/images/special_ariselu.png'),
    LotusItem(id: 'kaju_mixture', name: 'Kaju Mixture', image: 'assets/images/special_kaju_mixture.png'),
  ];
}

class _Tile extends StatelessWidget {
  final LotusItem item;
  final double s;
  final VoidCallback onTap;

  const _Tile({required this.item, required this.s, required this.onTap});

  Widget _img(String u) =>
      buildSmartImage(u, fit: BoxFit.contain);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: LayoutBuilder(
          builder: (_, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;

            return Stack(
              children: [
                // 1. Small Gold Lotus Mark
                Positioned(
                  top: h * 0.03,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CustomPaint(
                      size: Size(w * 0.18, h * 0.1),
                      painter: _LotusMark(),
                    ),
                  ),
                ),

                // 2. Product Cutout Image
                Positioned(
                  top: h * 0.14,
                  left: w * 0.08,
                  right: w * 0.08,
                  height: h * 0.52,
                  child: Center(
                    child: _img(item.image),
                  ),
                ),

                // 3. Name & Maroon Circular Arrow Button
                Positioned(
                  left: w * 0.05,
                  right: w * 0.05,
                  bottom: h * 0.04,
                  height: h * 0.26,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name.replaceAll('\n', ' '),
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.fraunces(
                            fontSize: (h * 0.115).clamp(9.0, 12.0),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6B1020),
                            height: 1.0,
                          ),
                        ),
                      ),
                      SizedBox(width: w * 0.02),
                      Container(
                        width: h * 0.22,
                        height: h * 0.22,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF7A0F12),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1.5))
                          ],
                        ),
                        child: Icon(Icons.chevron_right, size: h * 0.15, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LotusMark extends CustomPainter {
  @override
  void paint(Canvas c, Size z) {
    final k = z.width / 40;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * k
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFC9963A);
    Offset o(double x, double y) => Offset(x * k, y * k);
    final mid = Path()
      ..moveTo(o(20, 3).dx, o(20, 3).dy)
      ..cubicTo(o(25, 8).dx, o(25, 8).dy, o(25, 15).dx, o(25, 15).dy, o(20, 21).dx, o(20, 21).dy)
      ..cubicTo(o(15, 15).dx, o(15, 15).dy, o(15, 8).dx, o(15, 8).dy, o(20, 3).dx, o(20, 3).dy);
    final r = Path()
      ..moveTo(o(20, 21).dx, o(20, 21).dy)
      ..cubicTo(o(22, 14).dx, o(22, 14).dy, o(27, 9).dx, o(27, 9).dy, o(33, 8).dx, o(33, 8).dy)
      ..cubicTo(o(32, 15).dx, o(32, 15).dy, o(27, 19).dx, o(27, 19).dy, o(20, 21).dx, o(20, 21).dy);
    final l = Path()
      ..moveTo(o(20, 21).dx, o(20, 21).dy)
      ..cubicTo(o(18, 14).dx, o(18, 14).dy, o(13, 9).dx, o(13, 9).dy, o(7, 8).dx, o(7, 8).dy)
      ..cubicTo(o(8, 15).dx, o(8, 15).dy, o(13, 19).dx, o(13, 19).dy, o(20, 21).dx, o(20, 21).dy);
    c.drawPath(mid, p);
    c.drawPath(r, p);
    c.drawPath(l, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
