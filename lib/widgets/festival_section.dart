// festival_section.dart
// Backend-driven or local fallback festival / occasion section.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../models.dart' as app_models;
import '../cart_manager.dart';
import '../wishlist_manager.dart';
import '../product_detail_page.dart';
import '../product_listing_page.dart';
import '../navigation_util.dart';
import '../app_config_repository.dart';
import 'loading_spinner.dart';

typedef ProductLink = Map<String, dynamic>;

class FestivalTile {
  final String title;
  final String image;  // transparent PNG cut-out of the main product
  final String image2; // optional smaller second product (bottom-right)
  final ProductLink link;
  FestivalTile({
    required this.title,
    required this.image,
    required this.image2,
    required this.link,
  });

  FestivalTile.fromJson(Map<String, dynamic> j)
      : title = j['title'] ?? '',
        image = j['image'] ?? '',
        image2 = j['image2'] ?? '',
        link = Map<String, dynamic>.from(j['link'] ?? {});
}

class FestivalTheme {
  final Color bgTop, bgBottom, tile, tileBorder, title, kicker, strip, chipBg, accent;
  FestivalTheme({
    required this.bgTop,
    required this.bgBottom,
    required this.tile,
    required this.tileBorder,
    required this.title,
    required this.kicker,
    required this.strip,
    required this.chipBg,
    required this.accent,
  });

  FestivalTheme.fromJson(Map<String, dynamic> j)
      : bgTop = _hex(j['bgTop'], const Color(0xFFF9DFB3)),
        bgBottom = _hex(j['bgBottom'], const Color(0xFFF6D6A2)),
        tile = _hex(j['tile'], const Color(0xFFB81D3B)),
        tileBorder = _hex(j['line'] ?? j['tileBorder'], const Color(0xFFEFCF8C)),
        title = _hex(j['title'], const Color(0xFF7A1240)),
        kicker = _hex(j['kicker'], const Color(0xFF5A1030)),
        strip = _hex(j['strip'], const Color(0xFFD98F2E)),
        chipBg = _hex(j['chipBg'], const Color(0xFFFDF3DD)),
        accent = _hex(j['accent'], const Color(0xFFE9952C));
}

class FestivalConfig {
  final String id, kicker, title, subtitle, art, chipsTitle;
  final FestivalTheme theme;
  final List<FestivalTile> tiles, chips;
  final List<String> strip;
  final ProductLink products;

  FestivalConfig({
    required this.id,
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.art,
    required this.chipsTitle,
    required this.theme,
    required this.tiles,
    required this.chips,
    required this.strip,
    required this.products,
  });

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

Color _hex(dynamic v, Color fallback) {
  if (v is! String || v.isEmpty) return fallback;
  final h = v.replaceFirst('#', '');
  return Color(int.parse(h.length == 6 ? 'FF$h' : h, radix: 16));
}

// ============================ API & FALLBACK DATA ============================

class FestivalApi {
  final String baseUrl;
  FestivalApi([this.baseUrl = 'https://api.ambhujakshi.com']);

  Future<FestivalConfig?> activeFestival() async {
    try {
      if (baseUrl.isEmpty) return _defaultSankrantiConfig();
      final r = await http.get(Uri.parse('$baseUrl/api/home/festival')).timeout(const Duration(seconds: 3));
      if (r.statusCode != 200) return _defaultSankrantiConfig();
      final body = jsonDecode(r.body);
      if (body == null || body['festival'] == null) return _defaultSankrantiConfig();
      return FestivalConfig.fromJson(Map<String, dynamic>.from(body['festival']));
    } catch (_) {
      return _defaultSankrantiConfig();
    }
  }

  static FestivalConfig _defaultSankrantiConfig() {
    return FestivalConfig(
      id: 'sankranti-2027',
      kicker: 'CELEBRATE',
      title: 'Sankranti',
      subtitle: 'Pindi vantalu, sweets & gift boxes, made fresh',
      art: '',
      chipsTitle: 'FESTIVE SPECIALS',
      theme: FestivalTheme(
        bgTop: const Color(0xFFF9DFB3),
        bgBottom: const Color(0xFFF6D6A2),
        tile: const Color(0xFFB81D3B),
        tileBorder: const Color(0xFFEFCF8C),
        title: const Color(0xFF7A1240),
        kicker: const Color(0xFF5A1030),
        strip: const Color(0xFFD98F2E),
        chipBg: const Color(0xFFFDF3DD),
        accent: const Color(0xFFE9952C),
      ),
      tiles: [
        FestivalTile(
          title: 'Pindi\nVantalu',
          image: 'assets/images/snacks.png',
          image2: 'assets/images/sweets.png',
          link: {'category': 'Snacks'},
        ),
        FestivalTile(
          title: 'Festive\nSweets',
          image: 'assets/images/sweets.png',
          image2: 'assets/images/snacks.png',
          link: {'category': 'Sweets'},
        ),
        FestivalTile(
          title: 'Gifting\nCorner',
          image: 'assets/images/combos.png',
          image2: 'assets/images/pickles.png',
          link: {'category': 'Combos'},
        ),
        FestivalTile(
          title: 'Pickles\n& Podis',
          image: 'assets/images/pickles.png',
          image2: 'assets/images/spices.png',
          link: {'category': 'Pickles'},
        ),
      ],
      strip: const ['HOMEMADE', 'STONE-GROUND', 'FRESH BATCHES', 'PAN-INDIA'],
      chips: [
        FestivalTile(
          title: 'Sankranti\nEssentials',
          image: 'assets/images/sweets.png',
          image2: '',
          link: {'tag': 'sankranti'},
        ),
        FestivalTile(
          title: 'Snacks\n& More',
          image: 'assets/images/snacks.png',
          image2: '',
          link: {'category': 'Snacks'},
        ),
        FestivalTile(
          title: 'Traditional\nSweets',
          image: 'assets/images/combos.png',
          image2: '',
          link: {'category': 'Sweets'},
        ),
        FestivalTile(
          title: 'Pickles\n& Podis',
          image: 'assets/images/pickles.png',
          image2: '',
          link: {'category': 'Pickles'},
        ),
        FestivalTile(
          title: 'Under\n₹299',
          image: 'assets/images/spices.png',
          image2: '',
          link: {'maxPrice': 299},
        ),
      ],
      products: const {'tag': 'sankranti', 'limit': 10},
    );
  }
}

// ============================ MAIN WIDGET ============================

class FestivalSection extends StatefulWidget {
  final FestivalApi? api;
  final List<app_models.Product> allProducts;

  const FestivalSection({
    super.key,
    this.api,
    required this.allProducts,
  });

  @override
  State<FestivalSection> createState() => _FestivalSectionState();
}

class _FestivalSectionState extends State<FestivalSection> {
  FestivalConfig? _cfg;
  int _chip = 0;
  StreamSubscription? _configSub;

  @override
  void initState() {
    super.initState();
    _listenToConfig();
  }

  void _listenToConfig() {
    _configSub = AppConfigRepository().getFestivalConfigStream().listen((data) {
      if (!mounted) return;
      if (data.isEmpty || data['enabled'] == false) {
        setState(() => _cfg = null);
      } else {
        setState(() => _cfg = FestivalConfig.fromJson(data));
      }
    });
  }

  @override
  void dispose() {
    _configSub?.cancel();
    super.dispose();
  }

  List<app_models.Product> _filterProducts(ProductLink link) {
    if (widget.allProducts.isEmpty) return [];

    final category = link['category']?.toString().toLowerCase();
    final tag = link['tag']?.toString().toLowerCase();
    final maxPrice = link['maxPrice'] is num ? (link['maxPrice'] as num).toDouble() : null;

    return widget.allProducts.where((p) {
      if (maxPrice != null) {
        final rawPrice = p.getRawPriceForWeight(p.defaultWeight);
        if (rawPrice > maxPrice) return false;
      }
      if (category != null && category.isNotEmpty) {
        final catList = category.split(',').map((e) => e.trim()).toList();
        final pCat = p.category.toLowerCase();
        final matches = catList.any((c) => pCat.contains(c));
        if (!matches) return false;
      }
      if (tag != null && tag.isNotEmpty) {
        if (tag == 'sankranti' || tag == 'bestseller') {
          return p.isBestSeller || p.category == 'Sweets' || p.category == 'Snacks';
        }
        if (tag == 'combo' || tag == 'gift-box') {
          return p.category == 'Combos' || p.name.contains('Laddu');
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg;
    if (cfg == null) return const SizedBox.shrink();
    final s = MediaQuery.of(context).size.width / 390;
    final t = cfg.theme;

    final currentLink = (cfg.chips.isNotEmpty && _chip < cfg.chips.length)
        ? cfg.chips[_chip].link
        : cfg.products;
    final displayedProducts = _filterProducts(currentLink);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _hero(cfg, t, s),
      if (cfg.strip.isNotEmpty) _strip(cfg, t, s),
      if (cfg.chips.isNotEmpty) _chips(cfg, t, s),
      _productRow(displayedProducts, s),
    ]);
  }

  // ---------------- HERO (246 units tall) ----------------
  Widget _hero(FestivalConfig cfg, FestivalTheme t, double s) {
    return SizedBox(
      height: 246 * s,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(child: CustomPaint(painter: _HeroBgPainter(t))),
        // Top Kites Graphic
        Positioned(
          left: 270 * s,
          top: 24 * s,
          width: 100 * s,
          height: 80 * s,
          child: CustomPaint(painter: _KitesArtPainter()),
        ),
        Positioned(
          left: 25 * s, top: 39 * s,
          child: Text(cfg.kicker,
              style: GoogleFonts.poppins(
                  color: t.kicker, fontSize: 11.6 * s, fontWeight: FontWeight.w600, letterSpacing: 5.6 * s)),
        ),
        Positioned(
          left: 23 * s, top: 52 * s, right: 125 * s,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(cfg.title,
                style: GoogleFonts.philosopher(
                    color: t.title, fontSize: 36 * s, fontWeight: FontWeight.w900, height: 1.1)),
          ),
        ),
        for (var i = 0; i < cfg.tiles.length && i < 4; i++)
          Positioned(
            left: (13 + i * 94.4) * s, top: 114 * s, width: 80.8 * s, height: 117 * s,
            child: _tile(cfg.tiles[i], t, s),
          ),
      ]),
    );
  }

  Widget _tile(FestivalTile tile, FestivalTheme t, double s) {
    return GestureDetector(
      onTap: () {
        final cat = tile.link['category']?.toString() ?? 'All';
        AppNavigator.push(context, ProductListingPage(category: cat.split(',').first));
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10 * s),
        child: DecoratedBox(
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
            Positioned(
              left: 1 * s, bottom: 14 * s, width: 74 * s, height: 60 * s,
              child: _img(tile.image, fit: BoxFit.contain, alignment: Alignment.bottomCenter),
            ),
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
              physics: const BouncingScrollPhysics(),
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
  Widget _productRow(List<app_models.Product> products, double s) {
    if (products.isEmpty) {
      return SizedBox(
        height: 214 * s,
        child: const RoyalLoadingSpinner(size: 38, message: 'Loading Festive Delicacies...'),
      );
    }
    return Container(
      color: Colors.white,
      height: 214 * s,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(10 * s, 14 * s, 10 * s, 0),
        itemCount: products.length,
        separatorBuilder: (_, __) => SizedBox(width: 10 * s),
        itemBuilder: (_, i) => _productCard(products[i], s),
      ),
    );
  }

  Widget _productCard(app_models.Product p, double s) {
    return GestureDetector(
      onTap: () {
        AppNavigator.push(context, ProductDetailPage(product: p, allProducts: widget.allProducts));
      },
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
                Positioned(
                  left: 0, top: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 7 * s, vertical: 2 * s),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(bottomRight: Radius.circular(8 * s))),
                    child: Text(p.isBestSeller ? 'Bestseller' : 'Fresh',
                        style: GoogleFonts.poppins(
                            color: const Color(0xFFC3132F), fontSize: 9 * s, fontWeight: FontWeight.w600)),
                  ),
                ),
                Positioned(
                  right: 4 * s, top: 2 * s,
                  child: ListenableBuilder(
                    listenable: WishlistManager(),
                    builder: (context, _) {
                      final isFav = WishlistManager().isFavorite(p);
                      return GestureDetector(
                        onTap: () => WishlistManager().toggleFavorite(p),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? Colors.red : Colors.white,
                          size: 18 * s,
                          shadows: const [Shadow(color: Colors.black45, blurRadius: 3)],
                        ),
                      );
                    },
                  ),
                ),
              ]),
            ),
          ),
          SizedBox(height: 6 * s),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(p.defaultWeight, style: GoogleFonts.poppins(color: const Color(0xFF555555), fontSize: 11 * s)),
            GestureDetector(
              onTap: () {
                CartManager().addToCart(p, weight: p.defaultWeight);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${p.name} added to cart!'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
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
          Text(p.defaultPrice,
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

  Widget _img(String url, {BoxFit fit = BoxFit.cover, Alignment alignment = Alignment.center}) {
    if (url.isEmpty) return const SizedBox();
    if (url.startsWith('http')) {
      return Image.network(url, fit: fit, alignment: alignment, width: double.infinity, height: double.infinity,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey));
    }
    String assetPath = url.startsWith('assets/') ? url : 'assets/images/$url';
    return Image.asset(assetPath, fit: fit, alignment: alignment, width: double.infinity, height: double.infinity,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: Colors.grey));
  }
}

// ============================ PAINTERS ============================

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
    c.drawPath(body, Paint()..color = fill);

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

class _KitesArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final yellowPaint = Paint()..color = const Color(0xFFF6C453);
    final kite1 = Path()
      ..moveTo(30, 10)
      ..lineTo(60, 30)
      ..lineTo(30, 55)
      ..lineTo(0, 30)
      ..close();
    canvas.drawPath(kite1, yellowPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF8B0000).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(30, 55), const Offset(15, 75), linePaint);

    final redPaint = Paint()..color = const Color(0xFFB81D3B);
    final kite2 = Path()
      ..moveTo(55, 25)
      ..lineTo(80, 42)
      ..lineTo(55, 62)
      ..lineTo(30, 42)
      ..close();
    canvas.drawPath(kite2, redPaint);
    canvas.drawLine(const Offset(55, 62), const Offset(40, 80), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
