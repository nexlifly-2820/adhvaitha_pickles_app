// category_deck_screen.dart — Category page with "✨ Taste deck" (swipe cards) and "☰ List view"
// Matches tastedeck_list.mp4:
//  • Deck: full-height photo cards stacked & tilted, photos crossfade (close-up ↔ spoon), colour theme per product,
//    swipe or ‹ › to move, ↶ undo, Add turns into − n + stepper (card stays), ♥ wishlist, pack sizes change price,
//    tap card → product page.
//  • List: glass rows with photo, name, description, chilli meter, rating, price, Add → ✓ Added.
// Data from category_page_backend.js → GET /api/category/:slug/products
//
// pubspec.yaml:  http: ^1.2.0   google_fonts: ^6.2.1
//
// Usage (from the category section's onExplore):
//   Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryDeckScreen(
//     apiBase: 'https://your-api.com/api',
//     slug: 'pickle',
//     headers: {'Authorization': 'Bearer $token'},
//     cartCount: cart.count,                                                     // ValueListenable<int>
//     onAdd: (productId, variantId, qty) async => cart.setQty(productId, variantId, qty),   // qty 0 = remove
//     onWishlist: (productId) => wishlist.toggle(productId),
//     onOpen: (productId) => Navigator.pushNamed(context, '/product', arguments: productId),
//     onCart: () => Navigator.pushNamed(context, '/cart'),
//   )));

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'shop_catalog.dart';
import 'cart_manager.dart';
import 'models.dart';
import 'navigation_util.dart';
import 'product_detail_page.dart';
import 'product_manager.dart';

Color _hex(String? s, Color fb) {
  if (s == null || s.isEmpty) return fb;
  var h = s.replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  return Color(int.tryParse(h, radix: 16) ?? fb.value);
}

class DeckVariant {
  final String id, label;
  final double price, mrp;
  DeckVariant.fromJson(Map<String, dynamic> j)
      : id = '${j['id']}', label = j['label'] ?? '', price = (j['price'] as num?)?.toDouble() ?? 0, mrp = (j['mrp'] as num?)?.toDouble() ?? 0;
}

class DeckProduct {
  final String id, name, description, tag, cureNote, thumb;
  final List<String> photos;
  final double rating;
  final int spice;
  final Color c1, c2;
  final List<DeckVariant> variants;
  DeckProduct.fromJson(Map<String, dynamic> j)
      : id = '${j['id']}',
        name = j['name'] ?? '',
        description = j['description'] ?? '',
        tag = j['tag'] ?? '',
        cureNote = j['cureNote'] ?? '',
        thumb = j['thumb'] ?? '',
        photos = List<String>.from(j['photos'] ?? const []),
        rating = (j['rating'] as num?)?.toDouble() ?? 0,
        spice = ((j['spice'] as num?)?.toInt() ?? 0).clamp(0, 5),
        c1 = _hex(j['color1'], const Color(0xFF8A1A10)),
        c2 = _hex(j['color2'], const Color(0xFF2A0806)),
        variants = ((j['variants'] as List?) ?? []).map((e) => DeckVariant.fromJson(e)).toList();
}

String _rs(double v) => '₹${v.toStringAsFixed(v % 1 == 0 ? 0 : 2)}';
const _gold = Color(0xFFFFD27A);

class CategoryDeckScreen extends StatefulWidget {
  final String apiBase, slug;
  final Map<String, String>? headers;
  final ValueNotifier<int>? cartCount;
  final Future<bool> Function(String productId, String variantId, int qty)? onAdd;
  final ValueChanged<String>? onWishlist, onOpen;
  final VoidCallback? onCart;
  final Set<String> wishlistIds;
  const CategoryDeckScreen({super.key, required this.apiBase, required this.slug, this.headers, this.cartCount, this.onAdd,
      this.onWishlist, this.onOpen, this.onCart, this.wishlistIds = const {}});
  @override
  State<CategoryDeckScreen> createState() => _CategoryDeckScreenState();
}

class _CategoryDeckScreenState extends State<CategoryDeckScreen> with TickerProviderStateMixin {
  List<DeckProduct> _items = [];
  String _title = '', _eyebrow = '';
  bool _loading = true, _list = false;
  int _cur = 0;
  final Map<String, int> _variant = {}; // productId → selected variant index
  final Map<String, int> _qty = {};     // productId → qty in cart (this page)
  late final Set<String> _wish = {...widget.wishlistIds};
  double _drag = 0;
  late final AnimationController _fly = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  int _flyDir = 0;
  Timer? _photoTimer;
  bool _alt = false;

  @override
  void initState() {
    super.initState();
    _applyDeck(ShopCatalog.forDeck(widget.slug) ?? _getDefaultDeckForSlug(widget.slug));
    _load();
    _photoTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) { if (mounted) setState(() => _alt = !_alt); });
  }

  static Map<String, dynamic> _getDefaultDeckForSlug(String slug) {
    final s = slug.toLowerCase();
    if (s.contains('snack')) {
      return {
        "category": { "slug": "snack", "name": "Crunchy Snacks" },
        "products": [
          {
            "id": "janthukalu",
            "name": "Karam Janthukalu",
            "description": "Crispy golden spirals spiced with ajwain and authentic red chilli.",
            "tag": "🔥 CRISPY",
            "cureNote": "✨ Fried in cold-pressed oil",
            "spice": 3,
            "rating": 4.9,
            "thumb": "assets/images/karam_janthukalu_murukku_strings_snack.jpg",
            "photos": ["assets/images/karam_janthukalu_murukku_strings_snack.jpg"],
            "variants": [{"id": "v1", "label": "250g", "price": 140, "mrp": 160}]
          },
          {
            "id": "mixture",
            "name": "Andhra Mixture",
            "description": "Crunchy sev, boondi, peanuts, and curry leaves tossed in spice.",
            "tag": "👑 TEA-TIME FAV",
            "cureNote": "🥜 Freshly roasted",
            "spice": 2,
            "rating": 4.8,
            "thumb": "assets/images/bundhi_crispy_spiced_gram_flour_droplets.jpg",
            "photos": ["assets/images/bundhi_crispy_spiced_gram_flour_droplets.jpg"],
            "variants": [{"id": "v2", "label": "250g", "price": 150, "mrp": 175}]
          }
        ]
      };
    } else if (s.contains('podi') || s.contains('powder')) {
      return {
        "category": { "slug": "podi", "name": "Traditional Podis" },
        "products": [
          {
            "id": "idli_karam",
            "name": "Idli Karam Podi",
            "description": "Authentic stone-ground gun powder spice blend with garlic and roasted chana dal.",
            "tag": "🪨 STONE-GROUND",
            "cureNote": "⚡ Freshly ground daily",
            "spice": 4,
            "rating": 4.9,
            "thumb": "assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg",
            "photos": ["assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg"],
            "variants": [{"id": "v3", "label": "200g", "price": 139, "mrp": 150}]
          },
          {
            "id": "munagaku_podi",
            "name": "Munagaku Podi",
            "description": "Nutritious drumstick leaves (moringa) blended with lentils and spices.",
            "tag": "🌿 HEALTHY",
            "cureNote": "🌱 Organic moringa leaves",
            "spice": 2,
            "rating": 4.7,
            "thumb": "assets/images/munagaku_karam_podi_moringa_leaves_spice_powder.jpg",
            "photos": ["assets/images/munagaku_karam_podi_moringa_leaves_spice_powder.jpg"],
            "variants": [{"id": "v4", "label": "200g", "price": 149, "mrp": 170}]
          }
        ]
      };
    } else if (s.contains('sweet')) {
      return {
        "category": { "slug": "sweet", "name": "Traditional Sweets" },
        "products": [
          {
            "id": "sunnundalu",
            "name": "Bellam Sunnundalu",
            "description": "Roasted urad dal and organic jaggery rolled with pure desi ghee.",
            "tag": "👑 PURE GHEE",
            "cureNote": "🍯 Organic jaggery",
            "spice": 0,
            "rating": 5.0,
            "thumb": "assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg",
            "photos": ["assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg"],
            "variants": [{"id": "v5", "label": "250g", "price": 199, "mrp": 230}]
          }
        ]
      };
    } else {
      return {
        "category": { "slug": "pickle", "name": "Traditional Pickles" },
        "products": [
          {
            "id": "mango_avakaya",
            "name": "Bellam Avakaya",
            "description": "Sweet jaggery meets fiery Guntur chilli in wood-pressed sesame oil.",
            "tag": "👑 BESTSELLER",
            "cureNote": "☀️ 21 days sun-cured",
            "spice": 3,
            "rating": 4.8,
            "thumb": "assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg",
            "photos": ["assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg"],
            "variants": [
              { "id": "v1", "label": "250g", "price": 120, "mrp": 136 },
              { "id": "v2", "label": "500g", "price": 230, "mrp": 260 },
              { "id": "v3", "label": "1kg", "price": 440, "mrp": 500 }
            ]
          },
          {
            "id": "gongura_pickle",
            "name": "Andhra Gongura",
            "description": "Tangy sorrel leaves pickled with garlic and red chillies in pure groundnut oil.",
            "tag": "🔥 AUTHENTIC",
            "cureNote": "🍃 Farm fresh sorrel",
            "spice": 4,
            "rating": 4.9,
            "thumb": "assets/images/gongura_pickle.png",
            "photos": ["assets/images/gongura_pickle.png"],
            "variants": [
              { "id": "v6", "label": "250g", "price": 130, "mrp": 150 },
              { "id": "v7", "label": "500g", "price": 250, "mrp": 290 }
            ]
          }
        ]
      };
    }
  }

  @override
  void dispose() { _photoTimer?.cancel(); _fly.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final Map<String, dynamic> d = await ShopCatalog.load();
      final Map<String, dynamic>? deck = ShopCatalog.forDeck(widget.slug, d);
      if (deck != null) {
        _applyDeck(deck);
        return;
      }
    } catch (_) {}
    try {
      final r = await http.get(Uri.parse('${widget.apiBase}/category/${widget.slug}/products'), headers: widget.headers);
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body) as Map<String, dynamic>;
        if ((j['products'] as List? ?? []).isNotEmpty) {
          _applyDeck(j);
        }
      }
    } catch (e) {
      debugPrint('Category deck network fetch failed, using fallback: $e');
    }
  }

  void _applyDeck(Map<String, dynamic> j) {
    if (!mounted) return;
    setState(() {
      _title = j['category']?['name'] ?? widget.slug.toUpperCase();
      _eyebrow = '${(j['products'] as List?)?.length ?? 0} VARIETIES';
      _items = ((j['products'] as List?) ?? []).map((e) => DeckProduct.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      if (_items.isNotEmpty && _cur >= _items.length) _cur = 0;
      _loading = false;
    });
  }

  // transparent cut-outs (the new bowl photos) are PNGs; old full photos are JPGs
  static bool _isCutout(String url) => url.toLowerCase().split('?').first.endsWith('.png');

  Widget _smartImage(String url, {double? width, double? height, BoxFit? fit}) {
    if (url.startsWith('assets/')) {
      return Image.asset(url, width: width, height: height, fit: fit,
          errorBuilder: (_, __, ___) => Container(width: width, height: height, color: Colors.grey.shade300, child: const Icon(Icons.image)));
    }
    if (url.isEmpty) {
      return Container(width: width, height: height, color: Colors.grey.shade300, child: const Icon(Icons.image));
    }
    return Image.network(url, width: width, height: height, fit: fit,
        errorBuilder: (_, __, ___) => Container(width: width, height: height, color: Colors.grey.shade300, child: const Icon(Icons.image)));
  }
  DeckProduct get _p => _items[_cur % _items.length];
  DeckVariant? _v(DeckProduct p) => p.variants.isEmpty ? null : p.variants[(_variant[p.id] ?? 0).clamp(0, p.variants.length - 1)];

  Future<void> _move(int dir) async {
    if (_items.length < 2 || _fly.isAnimating) return;
    HapticFeedback.selectionClick();
    setState(() => _flyDir = dir);
    await _fly.forward(from: 0);
    setState(() { _cur = (_cur + dir + _items.length) % _items.length; _drag = 0; _flyDir = 0; });
    _fly.value = 0;
  }

  Future<void> _setQty(DeckProduct p, int q) async {
    final v = _v(p);
    if (v == null) return;
    q = q.clamp(0, 20);
    HapticFeedback.lightImpact();
    final before = _qty[p.id] ?? 0;
    setState(() => _qty[p.id] = q);
    final Product? cp = ShopCatalog.product(p.id);
    bool ok;
    if (cp != null) {
      // catalogue product: put exactly this size in the cart (q is the total wanted)
      final String w = v.label.isNotEmpty ? v.label : (cp.weightPriceMap.keys.isNotEmpty ? cp.weightPriceMap.keys.first : '250g');
      if (q > before) {
        CartManager().addToCart(cp, quantity: q - before, weight: w);
      } else {
        for (int k = 0; k < before - q; k++) {
          CartManager().decrementProductQuantity(cp.name, w);
        }
      }
      widget.cartCount?.value = CartManager().itemCount;
      ok = true;
    } else {
      ok = await (widget.onAdd?.call(p.id, v.id, q) ?? Future.value(true));
    }
    if (!ok && mounted) { setState(() => _qty[p.id] = before); return; }
    if (before == 0 && q > 0 && mounted) _toast('🛒 ${p.name} added');
  }

  void _open(DeckProduct p) {
    final Product? cp = ShopCatalog.product(p.id);
    if (cp != null) {
      AppNavigator.push(context, ProductDetailPage(product: cp, allProducts: ProductManager().products));
    } else {
      widget.onOpen?.call(p.id);
    }
  }

  void _toast(String t) {
    final e = OverlayEntry(builder: (_) => Positioned(
      top: MediaQuery.of(context).padding.top + 66, left: 0, right: 0,
      child: Center(child: Material(color: Colors.transparent, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Text(t, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF2A0806))),
      ))),
    ));
    Overlay.of(context).insert(e);
    Future.delayed(const Duration(milliseconds: 1500), e.remove);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final p = _items.isEmpty ? null : _p;
    return Scaffold(
      body: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: p?.c1 ?? const Color(0xFF7A1A10)), duration: const Duration(milliseconds: 800),
        builder: (_, a, child) => TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: p?.c2 ?? const Color(0xFF2A0806)), duration: const Duration(milliseconds: 800),
          builder: (_, b, __) => DecoratedBox(
            decoration: BoxDecoration(gradient: RadialGradient(center: const Alignment(0, -.4), radius: 1.2, colors: [a!, b!])),
            child: child,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _gold))
            : Padding(
                padding: EdgeInsets.only(top: top + 12),
                child: Column(children: [
                  _header(),
                  const SizedBox(height: 10),
                  _segment(),
                  const SizedBox(height: 14),
                  Expanded(child: _items.isEmpty
                      ? Center(child: Text('Coming soon', style: GoogleFonts.poppins(color: Colors.white70)))
                      : AnimatedSwitcher(duration: const Duration(milliseconds: 350), child: _list ? _listView() : _deckView())),
                ]),
              ),
      ),
    );
  }

  Widget _glassBtn(Widget child, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(width: 40, height: 40, alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white.withOpacity(.2))),
            child: child),
      );

  Widget _header() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          _glassBtn(const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20), () => Navigator.maybePop(context)),
          Expanded(child: Column(children: [
            Text(_eyebrow, style: GoogleFonts.poppins(fontSize: 9, letterSpacing: 2.4, fontWeight: FontWeight.w800, color: _gold)),
            Text(_title, style: GoogleFonts.rozhaOne(fontSize: 24, height: 1, color: Colors.white)),
          ])),
          _glassBtn(Stack(clipBehavior: Clip.none, children: [
            const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
            if (widget.cartCount != null)
              Positioned(right: -8, top: -8, child: ValueListenableBuilder<int>(
                valueListenable: widget.cartCount!,
                builder: (_, n, __) => Container(width: 18, height: 18, alignment: Alignment.center,
                    decoration: const BoxDecoration(color: _gold, shape: BoxShape.circle),
                    child: Text('$n', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF3B1F00)))),
              )),
          ]), () => widget.onCart?.call()),
        ]),
      );

  Widget _segment() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.black.withOpacity(.25), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          for (final (i, label) in [(0, '✨ Taste deck'), (1, '☰ List view')])
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _list = i == 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: (_list ? 1 : 0) == i ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(11)),
                alignment: Alignment.center,
                child: Text(label, style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700,
                    color: (_list ? 1 : 0) == i ? const Color(0xFF2A0806) : Colors.white70)),
              ),
            )),
        ]),
      );

  // ───────────── deck ─────────────
  Widget _deckView() {
    final n = _items.length;
    return Column(key: const ValueKey('deck'), children: [
      Expanded(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: LayoutBuilder(builder: (_, c) => Stack(clipBehavior: Clip.none, children: [
          for (int k = math.min(2, n - 1); k >= 0; k--) _stackCard(k, c),
        ])),
      )),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (int i = 0; i < n; i++)
          AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: i == _cur ? 18 : 6, height: 6,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: i == _cur ? Colors.white : Colors.white30)),
      ]),
      const SizedBox(height: 12),
      _actions(),
      const SizedBox(height: 8),
      Text('Swipe to see next · tap Add to add · tap card for details', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white60)),
      SizedBox(height: 12 + MediaQuery.of(context).padding.bottom),
    ]);
  }

  Widget _stackCard(int k, BoxConstraints c) {
    final p = _items[(_cur + k) % _items.length];
    if (k == 0) {
      return AnimatedBuilder(
        animation: _fly,
        builder: (_, child) {
          final dx = _drag + _flyDir * 480 * Curves.easeIn.transform(_fly.value);
          return Opacity(
            opacity: (1 - _fly.value).clamp(0, 1),
            child: Transform(
              alignment: const Alignment(0, 1.4),
              transform: Matrix4.identity()..translate(dx)..rotateZ(dx / 1200),
              child: child,
            ),
          );
        },
        child: GestureDetector(
          onTap: () => _open(p),
          onHorizontalDragUpdate: (d) => setState(() => _drag += d.delta.dx),
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (_drag.abs() > 90 || v.abs() > 700) {
              _move((_drag + v / 10) < 0 ? 1 : -1);
            } else {
              setState(() => _drag = 0);
            }
          },
          child: _card(p, c),
        ),
      );
    }
    // cards waiting behind
    final t = 1 - (_flyDir != 0 ? _fly.value : 0) * (k == 1 ? 1 : 0);
    return AnimatedBuilder(animation: _fly, builder: (_, child) {
      final kk = k - (_flyDir != 0 ? _fly.value : 0);
      return Transform.translate(offset: Offset(0, -16.0 * kk),
          child: Transform.scale(scale: 1 - .06 * kk, child: Transform.rotate(angle: (k.isOdd ? 3 : -3) * math.pi / 180 * kk.clamp(0, 1), child: child)));
    }, child: Opacity(opacity: t > 0 ? 1 : 0, child: IgnorePointer(child: _card(p, c))));
  }

  Widget _card(DeckProduct p, BoxConstraints c) {
    final v = _v(p);
    final photo = p.photos.isEmpty ? p.thumb : p.photos[(_alt && p.photos.length > 1) ? 1 : 0];
    return Container(
      width: c.maxWidth, height: c.maxHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.8), blurRadius: 40, offset: const Offset(0, 30), spreadRadius: -20)]),
      child: Stack(fit: StackFit.expand, children: [
        if (_isCutout(photo))
          DecoratedBox(
            decoration: BoxDecoration(gradient: RadialGradient(center: const Alignment(0, -.25), radius: 1.05, colors: <Color>[Color.lerp(p.c1, Colors.white, .18)!, p.c1, p.c2], stops: const <double>[0, .45, 1])),
            child: Align(
              alignment: const Alignment(0, -.42),
              child: FractionallySizedBox(widthFactor: .86, heightFactor: .6, child: _smartImage(photo, fit: BoxFit.contain)),
            ),
          )
        else
          AnimatedSwitcher(duration: const Duration(milliseconds: 800),
              child: _smartImage(photo, fit: BoxFit.cover, width: c.maxWidth, height: c.maxHeight)),
        const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0x59000000), Colors.transparent, Colors.transparent, Color(0xEB140400)], stops: [0, .25, .45, 1]))),
        if (p.tag.isNotEmpty)
          Positioned(left: 16, top: 16, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(10)),
            child: Text(p.tag.toUpperCase(), style: GoogleFonts.poppins(fontSize: 9, letterSpacing: 1.4, fontWeight: FontWeight.w800, color: const Color(0xFF3B1F00))),
          )),
        if (p.rating > 0)
          Positioned(right: 16, top: 16, child: ClipRRect(borderRadius: BorderRadius.circular(10), child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), color: Colors.white24,
                child: Text('★ ${p.rating.toStringAsFixed(1)}', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white))),
          ))),
        if (v != null)
          Positioned(right: 18, bottom: 68, child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_rs(v.price), style: GoogleFonts.rozhaOne(fontSize: 30, color: _gold)),
            if (v.mrp > v.price) Text(_rs(v.mrp), style: GoogleFonts.poppins(fontSize: 11, color: Colors.white60, decoration: TextDecoration.lineThrough)),
          ])),
        Positioned(left: 18, right: 18, bottom: 18, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.name, style: GoogleFonts.rozhaOne(fontSize: 34, height: 1, color: Colors.white)),
          Padding(padding: const EdgeInsets.only(right: 90),
              child: Text(p.description, maxLines: 2, style: GoogleFonts.kalam(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(.9)))),
          const SizedBox(height: 8),
          Row(children: [
            _chillies(p.spice, 16, dark: true),
            if (p.cureNote.isNotEmpty) ...[
              const SizedBox(width: 10),
              Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(.15), borderRadius: BorderRadius.circular(12)),
                  child: Text(p.cureNote, style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w600, color: Colors.white))),
            ],
          ]),
          const SizedBox(height: 12),
          Row(children: [
            for (int i = 0; i < p.variants.length; i++)
              GestureDetector(
                onTap: () => setState(() { _variant[p.id] = i; _qty[p.id] = 0; }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                      color: (_variant[p.id] ?? 0) == i ? Colors.white : Colors.white.withOpacity(.14),
                      border: Border.all(color: Colors.white24)),
                  child: Text(p.variants[i].label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700,
                      color: (_variant[p.id] ?? 0) == i ? const Color(0xFF2A0806) : Colors.white)),
                ),
              ),
          ]),
        ])),
      ]),
    );
  }

  Widget _round(Widget child, VoidCallback onTap, {double size = 46}) => GestureDetector(
        onTap: onTap,
        child: Container(width: size, height: size, alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.6), blurRadius: 20, offset: const Offset(0, 12), spreadRadius: -8)]),
            child: child),
      );

  Widget _actions() {
    final p = _p, q = _qty[p.id] ?? 0, wished = _wish.contains(p.id);
    const ink = Color(0xFF2A0806);
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _round(const Icon(Icons.chevron_left_rounded, color: ink, size: 26), () => _move(-1)),
      const SizedBox(width: 12),
      _round(const Icon(Icons.undo_rounded, color: ink, size: 20), () => _move(-1)), // ↶ back to the previous pickle
      const SizedBox(width: 12),
      AnimatedContainer(
        duration: const Duration(milliseconds: 350), curve: Curves.easeOutBack,
        width: q > 0 ? 120 : 72, height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          gradient: q > 0 ? null : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_gold, Color(0xFFE9A23B)]),
          color: q > 0 ? const Color(0xFF1E7A46) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.6), blurRadius: 20, offset: const Offset(0, 12), spreadRadius: -8)],
        ),
        child: q == 0
            ? GestureDetector(onTap: () => _setQty(p, 1), behavior: HitTestBehavior.opaque,
                child: Center(child: Text('Add\n🛒', textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 13, height: 1.1, fontWeight: FontWeight.w800, color: const Color(0xFF3B1F00)))))
            : Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                GestureDetector(onTap: () => _setQty(p, q - 1), child: const Icon(Icons.remove_rounded, color: Colors.white)),
                Text('$q', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                GestureDetector(onTap: () => _setQty(p, q + 1), child: const Icon(Icons.add_rounded, color: Colors.white)),
              ]),
      ),
      const SizedBox(width: 12),
      _round(Icon(wished ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: const Color(0xFFE8486B), size: 20), () {
        HapticFeedback.selectionClick();
        setState(() => wished ? _wish.remove(p.id) : _wish.add(p.id));
        widget.onWishlist?.call(p.id);
      }),
      const SizedBox(width: 12),
      _round(const Icon(Icons.chevron_right_rounded, color: ink, size: 26), () => _move(1)),
    ]);
  }

  // ───────────── list ─────────────
  Widget _listView() => ListView.builder(
        key: const ValueKey('list'),
        padding: EdgeInsets.fromLTRB(14, 4, 14, 24 + MediaQuery.of(context).padding.bottom),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final p = _items[i], v = _v(p), q = _qty[p.id] ?? 0;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1), duration: Duration(milliseconds: 450 + i * 120), curve: Curves.easeOutBack,
            builder: (_, t, child) => Opacity(opacity: t.clamp(0, 1), child: Transform.translate(offset: Offset(0, 20 * (1 - t)), child: child)),
            child: GestureDetector(
              onTap: () => _open(p),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(.1), borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(.15))),
                child: Row(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(16),
                      child: Builder(builder: (_) { final String t = p.thumb.isNotEmpty ? p.thumb : (p.photos.isEmpty ? '' : p.photos.first); return _isCutout(t) ? Container(width: 92, height: 92, padding: const EdgeInsets.all(6), decoration: BoxDecoration(gradient: RadialGradient(colors: <Color>[p.c1, p.c2])), child: _smartImage(t, fit: BoxFit.contain)) : _smartImage(t, width: 92, height: 92, fit: BoxFit.cover); })),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.name, style: GoogleFonts.rozhaOne(fontSize: 19, height: 1, color: Colors.white)),
                    Text(p.description, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.kalam(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70)),
                    const SizedBox(height: 4),
                    Row(children: [
                      _chillies(p.spice, 12, dark: true),
                      const SizedBox(width: 6),
                      if (p.rating > 0) Text('★ ${p.rating.toStringAsFixed(1)}', style: GoogleFonts.poppins(fontSize: 9.5, color: Colors.white)),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      if (v != null) Text(_rs(v.price), style: GoogleFonts.rozhaOne(fontSize: 18, color: _gold)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _setQty(p, q > 0 ? q : 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: q > 0 ? const Color(0xFF1E7A46) : _gold, borderRadius: BorderRadius.circular(10)),
                          child: Text(q > 0 ? '✓ Added' : 'Add +', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800,
                              color: q > 0 ? Colors.white : const Color(0xFF3B1F00))),
                        ),
                      ),
                    ]),
                  ])),
                ]),
              ),
            ),
          );
        },
      );

  Widget _chillies(int n, double size, {bool dark = false}) => Row(children: [
        for (int i = 0; i < 5; i++)
          Padding(
            padding: const EdgeInsets.only(right: 1),
            child: Transform.rotate(angle: -.5, child: Opacity(opacity: i < n ? 1 : .3,
                child: Text('🌶️', style: TextStyle(fontSize: size * .8)))),
          ),
      ]);
}
