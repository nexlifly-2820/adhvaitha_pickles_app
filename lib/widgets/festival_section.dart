// festival_section.dart
// Backend-driven festival / occasion section (Blinkit "Celebrate Karwa Chauth" style).
// Same design for every occasion - only the JSON from your backend changes.

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

// ============================ MODELS ============================

/// A link = product filter, e.g. {"tag":"pindi-vantalu"} or {"category":"sweets"} or {"maxPrice":299}
typedef ProductLink = Map<String, dynamic>;

class FestivalTile {
  final String title;
  final String image;  // transparent PNG cut-out of the main product
  final String image2; // optional smaller second product (bottom-right)
  final ProductLink link;
  FestivalTile.fromJson(Map<String, dynamic> j)
      : title = j['title'] ?? '',
        image = j['image'] ?? '',
        image2 = j['image2'] ?? '',
        link = Map<String, dynamic>.from(j['link'] ?? {});
}

class FestivalTheme {
  final Color bgTop, bgBottom, tile, tileBorder, title, kicker, strip, chipBg, accent;
  FestivalTheme.fromJson(Map<String, dynamic> j)
      : bgTop = _hex(j['bgTop'], const Color(0xFFFAE3B9)),
        bgBottom = _hex(j['bgBottom'], const Color(0xFFF5D39B)),
        tile = _hex(j['tile'], const Color(0xFFB5203F)),
        tileBorder = _hex(j['line'] ?? j['tileBorder'], const Color(0xFFECD08F)),
        title = _hex(j['title'], const Color(0xFF7C1443)),
        kicker = _hex(j['kicker'], const Color(0xFF5C1532)),
        strip = _hex(j['strip'], const Color(0xFFD8932F)),
        chipBg = _hex(j['chipBg'], const Color(0xFFFDF3DC)),
        accent = _hex(j['accent'], const Color(0xFFE9952C));
}

class FestivalConfig {
  final String id, kicker, title, subtitle, art, chipsTitle;
  final FestivalTheme theme;
  final List<FestivalTile> tiles, chips;
  final List<String> strip;
  final ProductLink products; // default product row filter
  FestivalConfig.fromJson(Map<String, dynamic> j)
      : id = j['id'] ?? '',
        kicker = j['kicker'] ?? 'CELEBRATE',
        title = j['title'] ?? '',
        subtitle = j['subtitle'] ?? '',
        art = j['art'] ?? '',
        chipsTitle = j['chipsTitle'] ?? 'FESTIVE SPECIALS',
        theme = FestivalTheme.fromJson(Map<String, dynamic>.from(j['theme'] ?? {})),
        tiles = ((j['tiles'] ?? []) as List).map((e) => FestivalTile.fromJson(e)).toList(),
        chips = ((j['chips'] ?? []) as List).map((e) => FestivalTile.fromJson(e)).toList(),
        strip = List<String>.from(j['strip'] ?? const []),
        products = Map<String, dynamic>.from(j['products'] ?? {});
}

class Product {
  final String id, name, image, unit;
  final int price;
  final String? badge;
  Product.fromJson(Map<String, dynamic> j)
      : id = '${j['id'] ?? ''}',
        name = j['name'] ?? '',
        image = j['image'] ?? '',
        unit = j['unit'] ?? '',
        price = ((j['price'] as num?)?.round()) ?? 0,
        badge = j['badge'];
}

Color _hex(dynamic v, Color fallback) {
  if (v is! String || v.isEmpty) return fallback;
  final h = v.replaceFirst('#', '');
  return Color(int.parse(h.length == 6 ? 'FF$h' : h, radix: 16));
}

// ============================ API ============================

class FestivalApi {
  final String baseUrl;
  FestivalApi(this.baseUrl);

  /// Returns the active festival config, or null when no festival is running.
  Future<FestivalConfig?> activeFestival() async {
    try {
      final endpoint = baseUrl.endsWith('/api') ? '$baseUrl/home/festival' : '$baseUrl/api/home/festival';
      final r = await http.get(Uri.parse(endpoint));
      if (r.statusCode != 200) return null;
      final body = jsonDecode(r.body);
      if (body == null || body['festival'] == null) return null;
      return FestivalConfig.fromJson(Map<String, dynamic>.from(body['festival']));
    } catch (_) {
      return null;
    }
  }

  /// GET /api/products?tag=..&category=..&maxPrice=..&limit=..
  Future<List<Product>> products(ProductLink link, {int limit = 10}) async {
    try {
      final endpoint = baseUrl.endsWith('/api') ? '$baseUrl/products' : '$baseUrl/api/products';
      final q = {...link.map((k, v) => MapEntry(k, '$v')), 'limit': '${link['limit'] ?? limit}'};
      final r = await http.get(Uri.parse(endpoint).replace(queryParameters: q));
      if (r.statusCode != 200) return [];
      final list = (jsonDecode(r.body)['products'] ?? []) as List;
      return list.map((e) => Product.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }
}

// ============================ WIDGET ============================
// All sizes are in "design units" on a 390-wide screen (s = screenWidth / 390),
// measured from the Blinkit reference so the layout matches it 1:1.

class FestivalSection extends StatefulWidget {
  final FestivalApi api;
  final void Function(String title, ProductLink link)? onOpenProducts;
  final ValueChanged<Product>? onAddToCart;
  final ValueChanged<Product>? onProductTap;
  final ValueChanged<Product>? onWishlist;

  const FestivalSection({
    super.key,
    required this.api,
    this.onOpenProducts,
    this.onAddToCart,
    this.onProductTap,
    this.onWishlist,
  });

  @override
  State<FestivalSection> createState() => _FestivalSectionState();
}

class _FestivalSectionState extends State<FestivalSection> {
  FestivalConfig? _cfg;
  List<Product> _products = [];
  int _chip = 0;
  bool _loadingProducts = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      FestivalConfig? cfg = await widget.api.activeFestival();
      if (cfg == null) {
        cfg = FestivalConfig.fromJson({
          "id": "festive_special",
          "kicker": "FESTIVAL OF HARVEST",
          "title": "Sankranti Feast & Delicacies",
          "subtitle": "Celebrate the harvest with authentic home-made festival sweets & pickles.",
          "theme": {
            "bgTop": "#C3132F",
            "bgBottom": "#8A0F2A",
            "tile": "#C3132F",
            "tileBorder": "#F3C06C",
            "title": "#FFFFFF",
            "kicker": "#FFE39A",
            "strip": "#E9952C",
            "chipBg": "#FDF1DC",
            "accent": "#F6C453"
          },
          "art": "assets/images/chakinalu_traditional_sankranti_spiral_snacks.jpg",
          "chipsTitle": "FESTIVE SPECIALS",
          "tiles": [
            {
              "title": "Pindi Vantalu",
              "image": "assets/images/snacks.png",
              "link": {"category": "Snacks"}
            },
            {
              "title": "Festive Sweets",
              "image": "assets/images/sweets.png",
              "link": {"category": "Sweets"}
            },
            {
              "title": "Gifting Corner",
              "image": "assets/images/combos.png",
              "link": {"category": "Combos"}
            },
            {
              "title": "Pickles & Podis",
              "image": "assets/images/pickles.png",
              "link": {"category": "Pickles"}
            }
          ],
          "chips": [
            {"title": "Pickles", "image": "assets/images/avakaya_pickle.png", "link": {"category": "Pickles"}},
            {"title": "Sweets", "image": "assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg", "link": {"category": "Sweets"}},
            {"title": "Snacks", "image": "assets/images/karam_janthukalu_murukku_strings_snack.jpg", "link": {"category": "Snacks"}}
          ],
          "strip": ["🚚 Free Delivery on Festive Combos", "🎁 Free Gift Box on orders above ₹999"],
          "products": {"category": "Pickles"}
        });
      }
      if (!mounted) return;
      setState(() => _cfg = cfg);
      await _loadProducts(cfg.chips.isNotEmpty ? cfg.chips.first.link : cfg.products);
    } catch (_) {}
  }

  Future<void> _loadProducts(ProductLink link) async {
    setState(() => _loadingProducts = true);
    try {
      List<Product> list = await widget.api.products(link);
      if (list.isEmpty) {
        list = [
          Product.fromJson({"id": "1", "name": "Bellam Avakaya", "image": "assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg", "unit": "500g", "price": 228, "badge": "BESTSELLER"}),
          Product.fromJson({"id": "2", "name": "Idli Karam Podi", "image": "assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg", "unit": "200g", "price": 139, "badge": "HOT"}),
          Product.fromJson({"id": "3", "name": "Kara Murukku", "image": "assets/images/karam_janthukalu_murukku_strings_snack.jpg", "unit": "250g", "price": 129, "badge": "CRISPY"}),
          Product.fromJson({"id": "4", "name": "Sunnunda Laddu", "image": "assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg", "unit": "250g", "price": 199, "badge": "GHEE"}),
        ];
      }
      if (mounted) setState(() => _products = list);
    } finally {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg;
    if (cfg == null) return const SizedBox.shrink(); // hidden when no active festival
    final s = MediaQuery.of(context).size.width / 390;
    final t = cfg.theme;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _hero(cfg, t, s),
        if (cfg.strip.isNotEmpty) _strip(cfg, t, s),
        if (cfg.chips.isNotEmpty) _chips(cfg, t, s),
        _productRow(s),
      ]),
    );
  }

  // ---------------- HERO (246 units tall) ----------------
  Widget _hero(FestivalConfig cfg, FestivalTheme t, double s) {
    return SizedBox(
      height: 246 * s,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(child: CustomPaint(painter: _HeroBgPainter(t))),
        if (cfg.art.isNotEmpty)
          Positioned(
            right: 12 * s, top: 20 * s, width: 112 * s, height: 82 * s,
            child: _img(cfg.art, fit: BoxFit.contain),
          ),
        Positioned(
          left: 20 * s, top: 32 * s, right: 125 * s,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cfg.kicker,
                  style: GoogleFonts.poppins(
                      color: t.kicker, fontSize: 11.6 * s, fontWeight: FontWeight.w600, letterSpacing: 4 * s)),
              SizedBox(height: 2 * s),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(cfg.title,
                    style: GoogleFonts.cinzelDecorative(
                        color: t.title, fontSize: 30 * s, fontWeight: FontWeight.w700, height: 1.1, letterSpacing: .3)),
              ),
            ],
          ),
        ),
        for (var i = 0; i < cfg.tiles.length && i < 4; i++)
          Positioned(
            left: (10 + i * 95.0) * s, top: 114 * s, width: 85 * s, height: 117 * s,
            child: _tile(cfg.tiles[i], t, s),
          ),
      ]),
    );
  }

  Widget _tile(FestivalTile tile, FestivalTheme t, double s) {
    return GestureDetector(
      onTap: () => widget.onOpenProducts?.call(tile.title.replaceAll('\n', ' '), tile.link),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10 * s),
        child: DecoratedBox(
          // crimson with a soft lighter glow in the middle (like the reference)
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -.16),
              radius: .95,
              colors: [
                Color.lerp(t.tile, Colors.white, .03)!,
                Color.lerp(t.tile, Colors.black, .09)!,
                Color.lerp(t.tile, Colors.black, .21)!,
              ],
              stops: const [0, .55, 1],
            ),
          ),
          child: Stack(clipBehavior: Clip.none, children: [
            // main product cut-out sits ON the red (colour stays visible around it)
            Positioned(
              left: 1 * s, bottom: 14 * s, width: 74 * s, height: 60 * s,
              child: _img(tile.image, fit: BoxFit.contain, alignment: Alignment.bottomCenter),
            ),
            // second product, layered bottom-right
            if (tile.image2.isNotEmpty)
              Positioned(
                right: 2 * s, bottom: 4 * s, width: 46 * s, height: 34 * s,
                child: _img(tile.image2, fit: BoxFit.contain, alignment: Alignment.bottomRight),
              ),
            Positioned(
              left: 2 * s, right: 2 * s, top: 8 * s,
              child: Text(tile.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12.4 * s,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                      shadows: const [Shadow(color: Color(0x40000000), blurRadius: 2)])),
            ),
          ]),
        ),
      ),
    );
  }

  // ---------------- STRIP (21 units) ----------------
  Widget _strip(FestivalConfig cfg, FestivalTheme t, double s) {
    const cream = Color(0xFFF8E4C0);
    final styles = [
      GoogleFonts.fraunces(color: cream, fontSize: 8.6 * s, fontWeight: FontWeight.w600, letterSpacing: .3),
      GoogleFonts.poppins(color: cream, fontSize: 8.4 * s, fontWeight: FontWeight.w700, letterSpacing: .4),
      GoogleFonts.poppins(color: cream, fontSize: 8.6 * s, fontWeight: FontWeight.w500, letterSpacing: 1.6),
    ];
    final end = TextStyle(color: cream.withOpacity(.9), fontSize: 6.5 * s, letterSpacing: 2.5);
    final kids = <Widget>[Text('◆ ·', style: end)];
    for (var i = 0; i < cfg.strip.length; i++) {
      if (i > 0) kids.add(Text('●', style: TextStyle(color: cream.withOpacity(.85), fontSize: 3.5 * s)));
      kids.add(Text(cfg.strip[i], style: styles[i % styles.length]));
    }
    kids.add(Text('· ◆', style: end));
    return Container(
      height: 21 * s,
      color: t.strip,
      padding: EdgeInsets.symmetric(horizontal: 7 * s),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: kids),
    );
  }

  // ---------------- FESTIVE SPECIALS TABS ----------------
  Widget _chips(FestivalConfig cfg, FestivalTheme t, double s) {
    // slot positions: selected tab = 16 (left foot) + 110.5 + 6 ; others = 87
    final lefts = <double>[];
    double x = 0;
    for (var i = 0; i < cfg.chips.length; i++) {
      if (i == _chip) {
        x += 16;
        lefts.add(x);
        x += 110.5 + 6;
      } else {
        lefts.add(x);
        x += 87;
      }
    }
    final totalW = math.max(390.0, x + 16);

    return Container(
      color: t.chipBg,
      padding: EdgeInsets.only(top: 12 * s),
      child: Column(children: [
        Text.rich(TextSpan(children: [
          TextSpan(text: '• ◆  ', style: TextStyle(color: t.accent, fontSize: 7 * s, letterSpacing: 2)),
          TextSpan(
              text: cfg.chipsTitle,
              style: GoogleFonts.poppins(
                  color: const Color(0xFF6B1A27),
                  fontSize: 12.6 * s,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.7 * s,
                  height: 16 / 12.6)),
          TextSpan(text: '  ◆ •', style: TextStyle(color: t.accent, fontSize: 7 * s, letterSpacing: 2)),
        ])),
        SizedBox(height: 6 * s),
        SizedBox(
          height: 111 * s,
          child: Stack(children: [
            Positioned(left: 0, right: 0, bottom: 0, height: 1.4, child: ColoredBox(color: t.tileBorder)),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: totalW * s,
                height: 111 * s,
                child: Stack(clipBehavior: Clip.none, children: [
                  for (var i = 0; i < cfg.chips.length; i++)
                    Positioned(
                      left: lefts[i] * s,
                      top: 0,
                      width: (i == _chip ? 110.5 : 87) * s,
                      height: 111 * s,
                      child: _chipItem(cfg.chips[i], i == _chip, t, s, () {
                        setState(() => _chip = i);
                        _loadProducts(cfg.chips[i].link);
                      }),
                    ),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _chipItem(FestivalTile c, bool on, FestivalTheme t, double s, VoidCallback onTap) {
    final label = Positioned(
      left: 0, right: 0, top: 68 * s,
      child: Text(c.title,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: GoogleFonts.poppins(
              color: on ? const Color(0xFF333333) : const Color(0xFF474747),
              fontSize: 12.2 * s,
              height: 15.6 / 12.2,
              fontWeight: FontWeight.w500)),
    );

    if (on) {
      return GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          painter: _TabPainter(fill: const Color(0xFFFFFAEF), line: t.tileBorder, s: s),
          child: Stack(children: [
            Positioned(
              left: 0, right: 0, top: 3 * s,
              child: Center(
                child: SizedBox(width: 66 * s, height: 56 * s, child: _img(c.image, fit: BoxFit.contain)),
              ),
            ),
            label,
          ]),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(children: [
        Positioned(
          left: 0, right: 0, top: 2 * s,
          child: Center(
            child: Container(
              width: 57 * s,
              height: 57 * s,
              padding: EdgeInsets.all(4 * s),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEFE0C2)),
              child: _img(c.image, fit: BoxFit.contain),
            ),
          ),
        ),
        label,
      ]),
    );
  }

  // ---------------- PRODUCT ROW ----------------
  Widget _productRow(double s) {
    if (_loadingProducts && _products.isEmpty) {
      return SizedBox(height: 210 * s, child: const Center(child: CircularProgressIndicator()));
    }
    return Container(
      color: Colors.white,
      height: 214 * s,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(10 * s, 14 * s, 10 * s, 0),
        itemCount: _products.length,
        separatorBuilder: (_, __) => SizedBox(width: 10 * s),
        itemBuilder: (_, i) => _productCard(_products[i], s),
      ),
    );
  }

  Widget _productCard(Product p, double s) {
    return GestureDetector(
      onTap: () => widget.onProductTap?.call(p),
      child: SizedBox(
        width: 112 * s,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 112 * s,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12 * s),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11 * s),
              child: Stack(fit: StackFit.expand, children: [
                _img(p.image),
                if (p.badge != null)
                  Positioned(
                    left: 0, top: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 7 * s, vertical: 2 * s),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(bottomRight: Radius.circular(8 * s))),
                      child: Text(p.badge!,
                          style: GoogleFonts.poppins(
                              color: const Color(0xFFC3132F), fontSize: 9 * s, fontWeight: FontWeight.w600)),
                    ),
                  ),
                Positioned(
                  right: 4 * s, top: 2 * s,
                  child: GestureDetector(
                    onTap: () => widget.onWishlist?.call(p),
                    child: Icon(Icons.favorite_border, color: Colors.white, size: 18 * s,
                        shadows: const [Shadow(color: Colors.black45, blurRadius: 3)]),
                  ),
                ),
              ]),
            ),
          ),
          SizedBox(height: 6 * s),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(p.unit, style: GoogleFonts.poppins(color: const Color(0xFF555555), fontSize: 11 * s)),
            GestureDetector(
              onTap: () => widget.onAddToCart?.call(p),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 3 * s),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF1F8A3A), width: 1.5),
                  borderRadius: BorderRadius.circular(8 * s),
                ),
                child: Text('ADD',
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF1F8A3A), fontSize: 12 * s, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
          SizedBox(height: 4 * s),
          Text('₹${p.price}',
              style: GoogleFonts.poppins(
                  color: const Color(0xFF1B1B1B), fontSize: 16 * s, fontWeight: FontWeight.w700)),
          Text(p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(color: const Color(0xFF333333), fontSize: 11.5 * s)),
        ]),
      ),
    );
  }

  String _abs(String u) {
    if (u.isEmpty || u.startsWith('http') || u.startsWith('assets/')) return u;
    const origin = 'https://admin.adhvaithafoods.in';
    return u.startsWith('/') ? '$origin$u' : '$origin/$u';
  }

  Widget _img(String url, {BoxFit fit = BoxFit.cover, Alignment alignment = Alignment.center}) {
    if (url.isEmpty) return const SizedBox();
    final fullUrl = _abs(url);
    return fullUrl.startsWith('http')
        ? Image.network(fullUrl, fit: fit, alignment: alignment, width: double.infinity, height: double.infinity,
            errorBuilder: (_, __, ___) => Image.asset('assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg', fit: fit, alignment: alignment, errorBuilder: (_, __, ___) => const SizedBox()))
        : Image.asset(fullUrl, fit: fit, alignment: alignment, width: double.infinity, height: double.infinity,
            errorBuilder: (_, __, ___) => Image.asset('assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg', fit: fit, alignment: alignment, errorBuilder: (_, __, ___) => const SizedBox()));
  }
}

// ============================ PAINTERS ============================

/// Peach background with the wavy dome edge, dotted edge line,
/// diamond trellis behind the art and small flower rosettes.
class _HeroBgPainter extends CustomPainter {
  final FestivalTheme t;
  _HeroBgPainter(this.t);

  static Path _edge(double k, double dy) {
    Offset o(double x, double y) => Offset(x * k, (y + dy) * k);
    final p = Path()..moveTo(0, o(0, 22).dy);
    void c(List<double> v) {
      final a = o(v[0], v[1]), b = o(v[2], v[3]), e = o(v[4], v[5]);
      p.cubicTo(a.dx, a.dy, b.dx, b.dy, e.dx, e.dy);
    }
    void q(List<double> v) {
      final a = o(v[0], v[1]), e = o(v[2], v[3]);
      p.quadraticBezierTo(a.dx, a.dy, e.dx, e.dy);
    }
    c([25, 14, 45, 12, 60, 14]);
    c([85, 17, 105, 22, 125, 21]);
    c([150, 20, 170, 15, 182, 11]);
    q([192, 6, 195, 6]);
    q([198, 6, 208, 11]);
    c([220, 15, 240, 20, 265, 21]);
    c([285, 22, 305, 17, 330, 14]);
    c([345, 12, 365, 14, 390, 22]);
    return p;
  }

  @override
  void paint(Canvas c, Size z) {
    final k = z.width / 390;

    // peach body
    final body = _edge(k, 0)
      ..lineTo(z.width, z.height)
      ..lineTo(0, z.height)
      ..close();
    c.drawPath(
        body,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [t.bgTop, Color.lerp(t.bgTop, t.bgBottom, .5)!, t.bgBottom],
            stops: const [0, .55, 1],
          ).createShader(Offset.zero & z));

    // dotted line under the edge
    final dot = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE9B867);
    for (final m in _edge(k, 5).computeMetrics()) {
      for (double d = 0; d < m.length; d += 3.6 * k) {
        c.drawPath(m.extractPath(d, d + .1), dot);
      }
    }

    // diamond trellis (rhombus centred at 308,70)
    const cx = 308.0, cy = 70.0, hw = 74.0, hh = 48.0;
    final lat = Paint()..color = Colors.white.withOpacity(.6);
    final seen = <String>{};
    for (var kk = -14; kk <= 14; kk++) {
      for (var tt = -60; tt <= 60; tt += 2) {
        for (final sg in [1, -1]) {
          final x = cx + tt * 1.9;
          final y = cy + sg * (tt * 1.9) * .62 + kk * 9.0;
          if ((x - cx).abs() / hw + (y - cy).abs() / hh > 1) continue;
          if (!seen.add('${x.toStringAsFixed(1)},${y.toStringAsFixed(1)}')) continue;
          c.drawCircle(Offset(x * k, y * k), .75 * k, lat);
        }
      }
    }
    final rim = Paint()..color = Colors.white.withOpacity(.75);
    for (var i = 0; i < 90; i++) {
      final a = i * 2 * math.pi / 90;
      final d = math.cos(a).abs() + math.sin(a).abs();
      c.drawCircle(
          Offset((cx + hw * math.cos(a) / d * 1.05) * k, (cy + hh * math.sin(a) / d * 1.05) * k), 1.2 * k, rim);
    }

    // flower rosettes
    void rosette(double x, double y, double r, double o) {
      final petal = Paint()..color = Colors.white.withOpacity(o);
      for (var a = 0; a < 8; a++) {
        c.drawCircle(
            Offset((x + 4.6 * math.cos(a * .785)) * k, (y + 4.6 * math.sin(a * .785)) * k), r * k, petal);
      }
      c.drawCircle(Offset(x * k, y * k), r * 1.15 * k, Paint()..color = const Color(0xFFF4B968).withOpacity(o));
    }
    rosette(9, 96, 1.9, 1);
    rosette(5, 74, 1.5, .5);
    rosette(240, 52, 1.7, 1);
    rosette(376, 98, 1.7, 1);
    rosette(8, 165, 1.4, .45);
    rosette(377, 165, 1.4, .45);
  }

  @override
  bool shouldRepaint(covariant _HeroBgPainter old) => old.t != t;
}

/// Selected tab: rounded top corners + curved feet that run into the baseline.
class _TabPainter extends CustomPainter {
  final Color fill, line;
  final double s;
  _TabPainter({required this.fill, required this.line, required this.s});

  @override
  void paint(Canvas c, Size z) {
    final w = z.width, h = z.height, r = 14 * s, f = 16 * s;
    final body = Path()
      ..moveTo(0, h + 1)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, h + 1)
      ..close();
    c.drawPath(body, Paint()..color = fill); // hides the baseline under the tab

    final outline = Path()
      ..moveTo(-f, h - .7)
      ..quadraticBezierTo(0, h - .7, 0, h - f)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, .7, r, .7)
      ..lineTo(w - r, .7)
      ..quadraticBezierTo(w, .7, w, r)
      ..lineTo(w, h - f)
      ..quadraticBezierTo(w, h - .7, w + f, h - .7);
    c.drawPath(
        outline,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = line);
  }

  @override
  bool shouldRepaint(covariant _TabPainter old) => old.fill != fill || old.line != line || old.s != s;
}
