import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models.dart';
import '../product_detail_page.dart';
import '../product_listing_page.dart';
import '../navigation_util.dart';
import '../product_manager.dart';
import '../app_config_repository.dart';

class LotusItem {
  final String id, name, image;
  const LotusItem({required this.id, required this.name, required this.image});

  factory LotusItem.fromJson(Map<String, dynamic> j) =>
      LotusItem(id: j['id'] ?? '', name: j['name'] ?? '', image: j['image'] ?? '');
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
        final parsed = data.map((e) => LotusItem.fromJson(e)).toList();
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
    final allProducts = ProductManager().products;
    final cleanName = item.name.toLowerCase().trim();

    Product? match;
    if (allProducts.isNotEmpty) {
      match = allProducts.firstWhere(
        (p) {
          final pName = p.name.toLowerCase();
          return pName.contains(cleanName) ||
                 cleanName.contains(pName) ||
                 (cleanName.contains('avakaya') && pName.contains('avakaya')) ||
                 (cleanName.contains('karam') && pName.contains('karam')) ||
                 (cleanName.contains('murukku') && (pName.contains('murukku') || pName.contains('janthukalu'))) ||
                 (cleanName.contains('sunnunda') && pName.contains('sunnunda')) ||
                 (cleanName.contains('mixture') && pName.contains('mixture')) ||
                 (cleanName.contains('banana') && pName.contains('chips'));
        },
        orElse: () => allProducts.first,
      );
    }

    if (match != null) {
      AppNavigator.push(context, ProductDetailPage(product: match, allProducts: allProducts));
    } else {
      AppNavigator.push(context, ProductListingPage(category: item.name));
    }
  }

  static const List<LotusItem> _defaultItems = [
    LotusItem(
      id: 'avakaya',
      name: 'Avakaya',
      image: 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
    ),
    LotusItem(
      id: 'karam_podi',
      name: 'Karam Podi',
      image: 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg',
    ),
    LotusItem(
      id: 'murukku',
      name: 'Murukku',
      image: 'assets/images/karam_janthukalu_murukku_strings_snack.jpg',
    ),
    LotusItem(
      id: 'sunnunda',
      name: 'Sunnunda',
      image: 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg',
    ),
    LotusItem(
      id: 'mixture',
      name: 'Mixture',
      image: 'assets/images/khara_mixture_assorted_crunchy_savory_mix.jpg',
    ),
    LotusItem(
      id: 'banana_chips',
      name: 'Banana Chips',
      image: 'assets/images/allu_chips_thinly_sliced_indian_potato_chips.jpg',
    ),
  ];
}

class _Tile extends StatelessWidget {
  final LotusItem item;
  final double s;
  final VoidCallback onTap;

  const _Tile({required this.item, required this.s, required this.onTap});

  Widget _img(String u) {
    if (u.isEmpty) {
      return const Center(child: Icon(Icons.restaurant, color: Colors.grey, size: 18));
    }
    if (u.startsWith('http')) {
      return Image.network(u, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey, size: 18));
    }
    String assetPath = u.startsWith('assets/') ? u : 'assets/images/$u';
    return Image.asset(assetPath, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey, size: 18));
  }

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
