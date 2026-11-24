// product_detail_screen.dart — AmbhuJakshi product page (matches product_living_photo.mp4)
// Living-photo gallery (sliding real photos + soft steam + oil glints + slow breathing + captions + ▶ video),
// thumbnails, viewers chip, name & rating, size boxes + quantity, about, ingredients grid, "Behind the jar"
// timeline, master artisan, royal recipes, reviews (summary bars + list + write), brand banner,
// sticky bar (price · cart · Buy now).
// Data: product_detail_backend.js → GET /api/products/:id/detail
//
// pubspec.yaml:  http: ^1.2.0   google_fonts: ^6.2.1
//
// Usage:
//   Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(
//     apiBase: 'https://your-api.com/api', productId: id, headers: {'Authorization': 'Bearer $token'},
//     onAddToCart: (pid, vid, qty) async => cart.add(pid, vid, qty),     // return true when added
//     onBuyNow: (pid, vid, qty) => checkout.buyNow(pid, vid, qty),
//     onWishlist: (pid, saved) => wishlist.set(pid, saved),
//     onShare: (pid, name) => Share.share('Try $name from AmbhuJakshi!'),
//     onPlayVideo: (url) => openVideoPlayer(url),                      // e.g. video_player / youtube
//     onWriteReview: (pid) => Navigator.pushNamed(context, '/write-review', arguments: pid),
//     onAllReviews: (pid) => Navigator.pushNamed(context, '/reviews', arguments: pid),
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
import 'recently_viewed_store.dart';
import 'models.dart';
import 'product_manager.dart';
import 'product_repository.dart';
import 'product_lookup.dart';
import 'cart_manager.dart';

const _red = Color(0xFF9E1424), _ink = Color(0xFF2A1A12), _muted = Color(0xFF8A7660), _bg = Color(0xFFFBF6EF);
const _green = Color(0xFF1E7A46), _line = Color(0xFFEFE4D2), _faint = Color(0xFFA88B68);
String _rs(num v) => '₹${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(2)}';
double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;

class _Photo {
  final String url, caption;
  final List<Offset> glints; // 0..1 positions of shiny spots
  _Photo(Map<String, dynamic> j)
      : url = j['url'] ?? '',
        caption = j['caption'] ?? '',
        glints = ((j['glints'] as List?) ?? []).map((g) => Offset(_d(g[0]), _d(g[1]))).toList();
}

class _Variant {
  final String id, label;
  final double price, mrp;
  _Variant(Map<String, dynamic> j) : id = '${j['id']}', label = j['label'] ?? '', price = _d(j['price']), mrp = _d(j['mrp']);
}

class ProductDetailScreen extends StatefulWidget {
  final String apiBase, productId;
  final Map<String, String>? headers;
  final Future<bool> Function(String pid, String vid, int qty)? onAddToCart;
  final void Function(String pid, String vid, int qty)? onBuyNow;
  final void Function(String pid, bool saved)? onWishlist;
  final void Function(String pid, String name)? onShare;
  final ValueChanged<String>? onPlayVideo, onWriteReview, onAllReviews;
  final VoidCallback? onCart;
  final bool initiallySaved;
  final Product? product; // the product that was tapped (used until/unless the server sends details)
  const ProductDetailScreen({super.key, required this.apiBase, required this.productId, this.product, this.headers, this.onAddToCart, this.onBuyNow,
      this.onWishlist, this.onShare, this.onPlayVideo, this.onWriteReview, this.onAllReviews, this.onCart, this.initiallySaved = false});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map<String, dynamic>? _p;
  List<_Photo> _photos = [];
  List<_Variant> _variants = [];
  int _v = 0, _qty = 1;
  bool _added = false;
  late bool _saved = widget.initiallySaved;

  @override
  void initState() {
    super.initState();
    RecentlyViewedStore().recordSlug(widget.productId);
    _local = widget.product ?? _findLocal(widget.productId);
    _applyData(_local != null ? _fromProduct(_local!) : _defaultProduct);
    _load();
  }

  Product? _local;

  static String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static Product? _findLocal(String slug) {
    final String n = _norm(slug);
    if (n.isEmpty) return null;
    final List<Product> all = <Product>[...ProductManager().products, ...ProductRepository.allProducts];
    for (final Product p in all) {
      if (_norm(p.name) == n) return p;
    }
    for (final Product p in all) {
      final String pn = _norm(p.name);
      if (pn.isNotEmpty && (pn.contains(n) || n.contains(pn))) return p;
    }
    return null;
  }

  /// Builds the page data from the app's own product, so every product opens with its own name, photo and prices.
  static Map<String, dynamic> _fromProduct(Product p) {
    final List<MapEntry<String, double>> w = p.weightPriceMap.entries.toList();
    final List<Review> rv = p.reviews.where((Review r) => r.status == 'approved').toList();
    final List<double> bars = <double>[0, 0, 0, 0, 0];
    for (final Review r in rv) {
      final int k = (5 - r.rating.round()).clamp(0, 4);
      bars[k] += 1;
    }
    final double total = rv.isEmpty ? 1 : rv.length.toDouble();
    return <String, dynamic>{
      'id': p.name,
      'name': p.name,
      'categoryLabel': p.subCategory.isNotEmpty && p.subCategory != 'Classic' ? '${p.category} · ${p.subCategory}' : p.category,
      'rating': p.rating,
      'reviewCount': rv.length,
      'soldText': p.purchaseCount > 0 ? '${p.purchaseCount}+ sold' : '',
      'spice': 3,
      'spiceLabel': 'Medium',
      'viewersToday': p.viewCount,
      'photos': <Map<String, dynamic>>[
        <String, dynamic>{'url': p.image, 'caption': p.origin, 'glints': <List<double>>[]},
        if (p.storyImage.isNotEmpty) <String, dynamic>{'url': p.storyImage, 'caption': 'Made in small batches', 'glints': <List<double>>[]},
      ],
      'videoUrl': '',
      'variants': <Map<String, dynamic>>[
        for (int i = 0; i < w.length; i++)
          <String, dynamic>{'id': 'v${i + 1}', 'label': w[i].key, 'price': w[i].value, 'mrp': (w[i].value * 1.25).roundToDouble()},
      ],
      'defaultVariantId': 'v1',
      'description': p.description,
      'highlight': p.secretIngredient.name,
      'features': p.trustBadges.take(3).toList(),
      'ingredients': p.ingredients.map((Map<String, String> m) => <String, dynamic>{'name': m['name'] ?? '', 'image': m['image'] ?? ''}).toList(),
      'journey': <Map<String, dynamic>>[
        <String, dynamic>{'icon': '📍', 'label': 'Origin', 'title': p.origin, 'text': 'Sourced from trusted local farms'},
        <String, dynamic>{'icon': '🫙', 'label': 'Process', 'title': 'Handmade', 'text': p.preparationMethod},
        <String, dynamic>{'icon': '🗓️', 'label': 'Shelf life', 'title': p.shelfLife, 'text': p.storageInstructions},
      ],
      'artisan': <String, dynamic>{'name': p.artisanName, 'since': '1982', 'quote': p.artisanDescription, 'photo': p.artisanImage},
      'recipes': <dynamic>[],
      'ratingBars': bars.map((double b) => rv.isEmpty ? 0.0 : b / total).toList(),
      'reviews': rv
          .take(5)
          .map((Review r) => <String, dynamic>{'name': r.userName, 'stars': r.rating.round(), 'text': r.comment, 'ago': r.date})
          .toList(),
      'brandLine': "Bringing Andhra's authentic flavours to your home.",
      'logo': 'assets/images/AMBHUJAKSHI  logo.png',
    };
  }

  static final Map<String, dynamic> _defaultProduct = {
    "id": "101",
    "name": "Bellam Avakaya Pickle",
    "categoryLabel": "Pickles Special",
    "rating": 4.8,
    "reviewCount": 248,
    "soldText": "1K+ sold",
    "spice": 3,
    "spiceLabel": "Hot",
    "viewersToday": 14,
    "photos": [
      {
        "url": "assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg",
        "caption": "Tossed by hand in small batches",
        "glints": [[0.52, 0.45], [0.38, 0.60]]
      }
    ],
    "videoUrl": "",
    "variants": [
      { "id": "v1", "label": "250g", "price": 120, "mrp": 154 },
      { "id": "v2", "label": "500g", "price": 240, "mrp": 300 },
      { "id": "v3", "label": "1kg", "price": 460, "mrp": 580 }
    ],
    "defaultVariantId": "v1",
    "description": "Traditional sun-dried raw mango pickle mixed with organic jaggery, Guntur chillies, and cold-pressed sesame oil. Prepared in small artisanal batches.",
    "highlight": "organic jaggery & wood-pressed sesame oil",
    "features": ["100% Natural", "Traditional Recipe", "No Preservatives"],
    "ingredients": [
      { "name": "Raw Mango", "image": "assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg" },
      { "name": "Guntur Chilli", "image": "assets/images/chilli.png" }
    ],
    "journey": [
      { "icon": "📍", "label": "Origin", "title": "Guntur farms", "text": "Sourced from the finest local farms" },
      { "icon": "☀️", "label": "Process", "title": "Sun-dried", "text": "Cured under the sun for 21 days" }
    ],
    "artisan": {
      "name": "Lakshmi Amma",
      "since": "1982",
      "quote": "Made with the same love as I make for my family.",
      "photo": "assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg"
    },
    "recipes": [],
    "ratingBars": [0.8, 0.1, 0.05, 0.0, 0.05],
    "reviews": [
      { "name": "Siri M.", "stars": 5, "text": "Tastes exactly like my grandmother used to make!", "ago": "2 days ago" }
    ],
    "brandLine": "Bringing Andhra's authentic flavours to your home.",
    "logo": "assets/images/AMBHUJAKSHI  logo.png"
  };

  Future<void> _load() async {
    try {
      final r = await http.get(Uri.parse('${widget.apiBase}/products/${widget.productId}/detail'), headers: widget.headers);
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body) as Map<String, dynamic>;
        // only use the server data if it is really for this product (never show another product's page)
        final String got = _norm('${j['name'] ?? ''}');
        final String want = _norm(_local?.name ?? widget.productId);
        final bool same = got.isNotEmpty && (got == want || got.contains(want) || want.contains(got));
        if (j.isNotEmpty && same && ((j['variants'] as List?)?.isNotEmpty ?? false)) {
          _applyData(j);
        }
      }
    } catch (e) {
      debugPrint('Product detail network fetch failed, using fallback: $e');
    }
  }

  void _applyData(Map<String, dynamic> j) {
    if (!mounted) return;
    setState(() {
      _p = j;
      _photos = ((j['photos'] as List?) ?? []).map((e) => _Photo(e)).toList();
      _variants = ((j['variants'] as List?) ?? []).map((e) => _Variant(e)).toList();
      _v = math.max(0, _variants.indexWhere((x) => x.id == '${j['defaultVariantId']}'));
    });
  }

  _Variant? get _var => _variants.isEmpty ? null : _variants[_v];

  Future<void> _add() async {
    final v = _var;
    if (v == null) return;
    HapticFeedback.lightImpact();
    bool ok;
    if (widget.onAddToCart != null) {
      ok = await widget.onAddToCart!(widget.productId, v.id, _qty);
    } else {
      // add exactly this product with the weight the customer picked
      final String name = (_local?.name ?? '${_p?['name'] ?? widget.productId}').trim();
      final String img = _local?.image ?? (_photos.isNotEmpty ? '${(_p?['photos'] as List?)?.first?['url'] ?? ''}' : '');
      Product prod = _local ?? productFor(name, image: img, weights: <String, double>{v.label: v.price}, price: v.price);
      if (!prod.weightPriceMap.containsKey(v.label)) {
        prod = prod.copyWith(weightPriceMap: <String, double>{...prod.weightPriceMap, v.label: v.price});
      }
      CartManager().addToCart(prod, quantity: _qty, weight: v.label);
      ok = true;
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)
          ?..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            content: Text('$name (${v.label}) × $_qty added to cart'),
            action: widget.onCart == null ? null : SnackBarAction(label: 'VIEW CART', onPressed: widget.onCart!),
          ));
      }
    }
    if (ok && mounted) setState(() => _added = true);
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    if (p == null) return const Scaffold(backgroundColor: _bg, body: Center(child: CircularProgressIndicator(color: _red)));
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(children: [
        ListView(padding: EdgeInsets.fromLTRB(16, top + 8, 16, 120), children: [
          _nav(p),
          const SizedBox(height: 8),
          _LivingGallery(photos: _photos, videoUrl: p['videoUrl'] ?? '', onVideo: widget.onPlayVideo),
          if ((p['viewersToday'] ?? 0) > 0) ...[
            const SizedBox(height: 12),
            _chip('👀 ${p['viewersToday']} royal guests viewed this today', const Color(0xFFFFF4DC), const Color(0xFF8A5A10)),
          ],
          const SizedBox(height: 10),
          Row(children: [_chip((p['categoryLabel'] ?? '').toString().toUpperCase(), const Color(0xFFE6F4EC), _green, small: true)]),
          const SizedBox(height: 8),
          Text(p['name'] ?? '', style: GoogleFonts.rozhaOne(fontSize: 27, height: 1.05, color: _ink)),
          const SizedBox(height: 8),
          _meta(p),
          _card(label: 'CHOOSE SIZE', trailing: _savingText(), child: _sizes()),
          _card(label: 'ABOUT THIS PICKLE', child: _about(p)),
          if ((p['ingredients'] as List? ?? []).isNotEmpty)
            _card(label: 'INGREDIENTS', trailing: Text('${(p['ingredients'] as List).length} natural', style: _lblStyle), accent: const Color(0xFF3FA34D), child: _ingredients(p)),
          if ((p['journey'] as List? ?? []).isNotEmpty) _card(label: 'BEHIND THE JAR', accent: const Color(0xFFF2A93B), child: _journey(p)),
          if (p['artisan'] != null) _card(label: 'MASTER ARTISAN', accent: const Color(0xFFC2185B), child: _artisan(p['artisan'])),
          if ((p['recipes'] as List? ?? []).isNotEmpty) _card(label: 'ROYAL RECIPES', accent: const Color(0xFF1E4F8F), child: _recipes(p)),
          _card(label: 'REVIEWS (${p['reviewCount'] ?? 0})', trailing: _writeBtn(), child: _reviews(p)),
          if ((p['brandLine'] ?? '').toString().isNotEmpty) _brand(p),
        ]),
        Positioned(left: 0, right: 0, bottom: 0, child: _bar()),
      ]),
    );
  }

  TextStyle get _lblStyle => GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: _faint);

  Widget _round(Widget c, VoidCallback onTap) => GestureDetector(onTap: onTap, child: Container(width: 38, height: 38, alignment: Alignment.center,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.3), blurRadius: 10, offset: const Offset(0, 4), spreadRadius: -6)]), child: c));

  Widget _nav(Map p) => Row(children: [
        _round(const Icon(Icons.arrow_back_rounded, size: 19, color: _ink), () => Navigator.maybePop(context)),
        const Spacer(),
        _round(Icon(_saved ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 18, color: _saved ? const Color(0xFFE8486B) : _ink), () {
          HapticFeedback.selectionClick();
          setState(() => _saved = !_saved);
          widget.onWishlist?.call(widget.productId, _saved);
        }),
        const SizedBox(width: 8),
        _round(const Icon(Icons.ios_share_rounded, size: 18, color: _ink), () => widget.onShare?.call(widget.productId, p['name'] ?? '')),
        const SizedBox(width: 8),
        _round(const Icon(Icons.shopping_bag_outlined, size: 18, color: _ink), () => widget.onCart?.call()),
      ]);

  Widget _chip(String t, Color bg, Color fg, {bool small = false}) => Container(
        padding: EdgeInsets.symmetric(horizontal: small ? 9 : 10, vertical: small ? 3 : 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Text(t, style: GoogleFonts.poppins(fontSize: small ? 9 : 10.5, fontWeight: small ? FontWeight.w800 : FontWeight.w600, letterSpacing: small ? 1 : 0, color: fg)),
      );

  Widget _chillies(int n, double s) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (int i = 0; i < 5; i++) Opacity(opacity: i < n ? 1 : .25, child: Text('🌶️', style: TextStyle(fontSize: s))),
      ]);

  Widget _meta(Map p) => Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 4, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(8)),
            child: Text('★ ${_d(p['rating']).toStringAsFixed(1)}', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white))),
        Text('${p['reviewCount'] ?? 0} reviews', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF7A5A44))),
        if ((p['soldText'] ?? '').toString().isNotEmpty) Text('· ${p['soldText']}', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF7A5A44))),
        if ((p['spice'] ?? 0) > 0) Row(mainAxisSize: MainAxisSize.min, children: [
          Text('· ', style: GoogleFonts.poppins(fontSize: 11, color: _muted)), _chillies(p['spice'], 11),
          Text(' ${p['spiceLabel'] ?? ''}', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF7A5A44))),
        ]),
      ]);

  Widget _card({required String label, Widget? trailing, Color? accent, required Widget child}) => Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22),
            border: accent == null ? null : Border(top: BorderSide(color: accent, width: 3)),
            boxShadow: [BoxShadow(color: const Color(0xFF501E00).withOpacity(.12), blurRadius: 22, offset: const Offset(0, 10), spreadRadius: -12)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text(label, style: _lblStyle), const Spacer(), if (trailing != null) trailing]),
          const SizedBox(height: 10),
          child,
        ]),
      );

  Widget? _savingText() {
    final v = _var;
    if (v == null || _v == 0 || _variants.isEmpty) return null;
    final base = _variants.first;
    final perUnitSave = base.price * (_parseGrams(v.label) / math.max(1, _parseGrams(base.label))) - v.price;
    return perUnitSave > 0 ? Text('✓ Saving ${_rs(perUnitSave.round())}', style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: _green)) : null;
  }

  double _parseGrams(String l) {
    final m = RegExp(r'([\d.]+)\s*(kg|g)', caseSensitive: false).firstMatch(l);
    if (m == null) return 1;
    final n = double.tryParse(m.group(1)!) ?? 1;
    return m.group(2)!.toLowerCase() == 'kg' ? n * 1000 : n;
  }

  Widget _sizes() => Column(children: [
        Row(children: [
          for (int i = 0; i < _variants.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); setState(() { _v = i; _added = false; }); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: i == _v ? const Color(0xFFFFF3F1) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: i == _v ? _red : const Color(0xFFEDE0CC), width: 1.5),
                  boxShadow: i == _v ? [BoxShadow(color: _red.withOpacity(.1), spreadRadius: 3)] : null,
                ),
                child: Column(children: [
                  Text(_variants[i].label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: i == _v ? _red : _ink)),
                  Text(_rs(_variants[i].price), style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF7A5A44))),
                  if (i > 0) Builder(builder: (_) {
                    final b = _variants.first, save = b.price * (_parseGrams(_variants[i].label) / math.max(1, _parseGrams(b.label))) - _variants[i].price;
                    return save > 0 ? Text('Save ${_rs(save.round())}', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: _green)) : const SizedBox.shrink();
                  }),
                ]),
              ),
            )),
          ],
        ]),
        Container(margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: _line))),
            child: Row(children: [
              Text('QUANTITY', style: _lblStyle),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(color: const Color(0xFFFBF3E6), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  IconButton(onPressed: _qty > 1 ? () => setState(() { _qty--; _added = false; }) : null, icon: const Icon(Icons.remove_rounded, color: _red, size: 18)),
                  Text('$_qty', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800)),
                  IconButton(onPressed: () => setState(() { _qty++; _added = false; }), icon: const Icon(Icons.add_rounded, color: _red, size: 18)),
                ]),
              ),
            ])),
      ]);

  Widget _about(Map p) {
    final text = (p['description'] ?? '').toString();
    final hl = (p['highlight'] ?? '').toString();
    final i = hl.isEmpty ? -1 : text.toLowerCase().indexOf(hl.toLowerCase());
    final base = GoogleFonts.poppins(fontSize: 12, height: 1.55, color: const Color(0xFF5A4636));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text.rich(i < 0 ? TextSpan(text: text, style: base) : TextSpan(style: base, children: [
        TextSpan(text: text.substring(0, i)),
        TextSpan(text: text.substring(i, i + hl.length), style: const TextStyle(color: _red, fontWeight: FontWeight.w700)),
        TextSpan(text: text.substring(i + hl.length)),
      ])),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final f in (p['features'] as List? ?? []))
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: const Color(0xFFFBF3E6), borderRadius: BorderRadius.circular(20)),
              child: Text('$f', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600))),
      ]),
    ]);
  }

  Widget _ingredients(Map p) => GridView.count(
        crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, childAspectRatio: 1.05,
        children: [
          for (final g in (p['ingredients'] as List))
            Column(children: [
              Container(width: 54, height: 54, padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Colors.white, Color(0xFFFBF0DE)])),
                  child: Image.network(g['image'] ?? '', fit: BoxFit.contain)),
              const SizedBox(height: 4),
              Text(g['name'] ?? '', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600)),
            ]),
        ],
      );

  static const _jColors = [Color(0xFFE6F4EC), Color(0xFFFFF4DC), Color(0xFFFDE8EA), Color(0xFFE8F0FF), Color(0xFFF3E8FF)];
  Widget _journey(Map p) {
    final js = p['journey'] as List;
    return Column(children: [
      for (int i = 0; i < js.length; i++)
        IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            Container(width: 36, height: 36, alignment: Alignment.center,
                decoration: BoxDecoration(color: _jColors[i % _jColors.length], borderRadius: BorderRadius.circular(12)),
                child: Text(js[i]['icon'] ?? '•', style: const TextStyle(fontSize: 16))),
            if (i < js.length - 1) Expanded(child: CustomPaint(size: const Size(2, double.infinity), painter: _DashV())),
          ]),
          const SizedBox(width: 12),
          Expanded(child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((js[i]['label'] ?? '').toString().toUpperCase(), style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1, color: _faint)),
              Text(js[i]['title'] ?? '', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700)),
              Text(js[i]['text'] ?? '', style: GoogleFonts.poppins(fontSize: 10.5, color: _muted)),
            ]),
          )),
        ])),
    ]);
  }

  Widget _artisan(Map a) => Row(children: [
        Container(width: 70, height: 70, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Color(0xFFFFD27A), spreadRadius: 3)],
            image: DecorationImage(image: NetworkImage(a['photo'] ?? ''), fit: BoxFit.cover))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a['name'] ?? '', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
          Text(a['since'] ?? '', style: GoogleFonts.poppins(fontSize: 10, color: _muted)),
          const SizedBox(height: 3),
          Text('"${a['quote'] ?? ''}"', style: GoogleFonts.kalam(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF6A1220))),
        ])),
      ]);

  Widget _recipes(Map p) => SizedBox(
        height: 150,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final r in (p['recipes'] as List))
            Container(
              width: 150, margin: const EdgeInsets.only(right: 10), clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: const Color(0xFFFBF3E6), borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Image.network(r['image'] ?? '', width: 150, height: 96, fit: BoxFit.cover),
                Padding(padding: const EdgeInsets.fromLTRB(9, 7, 9, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  Text(r['subtitle'] ?? '', maxLines: 1, style: GoogleFonts.poppins(fontSize: 9.5, color: _muted)),
                ])),
              ]),
            ),
        ]),
      );

  Widget _writeBtn() => GestureDetector(
        onTap: () => widget.onWriteReview?.call(widget.productId),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), border: Border.all(color: _red, width: 1.5)),
            child: Text('✍ Write a review', style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: _red))),
      );

  Widget _reviews(Map p) {
    final dist = (p['ratingBars'] as List? ?? [0, 0, 0, 0, 0]).map((e) => _d(e)).toList(); // [5★,4★,3★,2★,1★] as 0..1
    final list = p['reviews'] as List? ?? [];
    return Column(children: [
      Row(children: [
        Column(children: [
          Text(_d(p['rating']).toStringAsFixed(1), style: GoogleFonts.rozhaOne(fontSize: 30, height: 1)),
          Text('★★★★★', style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFFE39B1C))),
          Text('${p['reviewCount'] ?? 0} reviews', style: GoogleFonts.poppins(fontSize: 9.5, color: _muted)),
        ]),
        const SizedBox(width: 14),
        Expanded(child: Column(children: [
          for (int i = 0; i < 5; i++)
            Padding(padding: const EdgeInsets.symmetric(vertical: 1.5), child: Row(children: [
              Text('${5 - i}', style: GoogleFonts.poppins(fontSize: 9, color: _muted)),
              const SizedBox(width: 5),
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(
                  value: i < dist.length ? dist[i] : 0, minHeight: 5, backgroundColor: const Color(0xFFF0E4D2), color: const Color(0xFFE39B1C)))),
            ])),
        ])),
      ]),
      for (final r in list)
        Container(
          margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.only(top: 12),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF3EADB)))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(radius: 16, backgroundColor: const Color(0xFFFFE1D6),
                child: Text((r['name'] ?? '?').toString().substring(0, 1), style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: _red))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(r['name'] ?? '', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(width: 4),
                Text('★' * ((r['stars'] ?? 5) as int), style: const TextStyle(fontSize: 11, color: Color(0xFFE39B1C))),
                const Spacer(),
                Text(r['ago'] ?? '', style: GoogleFonts.poppins(fontSize: 9.5, color: _faint)),
              ]),
              Text('"${r['text'] ?? ''}"', style: GoogleFonts.kalam(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF4A3020))),
            ])),
          ]),
        ),
      GestureDetector(
        onTap: () => widget.onAllReviews?.call(widget.productId),
        child: Padding(padding: const EdgeInsets.only(top: 10),
            child: Text('See all ${p['reviewCount'] ?? 0} reviews →', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: _red))),
      ),
    ]);
  }

  Widget _brand(Map p) => Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(colors: [Color(0xFF123B2E), Color(0xFF1E5A44)])),
        child: Row(children: [
          if ((p['logo'] ?? '').toString().isNotEmpty)
            Container(width: 44, height: 44, padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: ClipOval(child: Image.network(p['logo']))),
          const SizedBox(width: 10),
          Expanded(child: Text('"${p['brandLine']}"', style: GoogleFonts.kalam(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
        ]),
      );

  Widget _bar() {
    final v = _var;
    final off = v != null && v.mrp > v.price ? ((v.mrp - v.price) / v.mrp * 100).round() : 0;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.3), blurRadius: 22, offset: const Offset(0, -10), spreadRadius: -14)]),
      child: Row(children: [
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(v == null ? '' : _rs(v.price * _qty), style: GoogleFonts.rozhaOne(fontSize: 24, height: 1)),
          if (off > 0) Row(children: [
            Text(_rs(v!.mrp * _qty), style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFFB8A58A), decoration: TextDecoration.lineThrough)),
            const SizedBox(width: 4),
            Text('$off% off', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: _green)),
          ]),
        ]),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _added ? widget.onCart : _add,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 52, height: 52, alignment: Alignment.center,
            decoration: BoxDecoration(color: _added ? _green : Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _added ? _green : _red, width: 2)),
            child: Icon(_added ? Icons.check_rounded : Icons.add_shopping_cart_rounded, color: _added ? Colors.white : _red, size: 22),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: GestureDetector(
          onTap: () { final v = _var; if (v != null) widget.onBuyNow?.call(widget.productId, v.id, _qty); },
          child: Container(
            height: 52, alignment: Alignment.center,
            decoration: BoxDecoration(color: _red, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: _red.withOpacity(.9), blurRadius: 18, offset: const Offset(0, 10), spreadRadius: -10)]),
            child: Text('⚡ Buy now', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        )),
      ]),
    );
  }
}

// ───────────────────────────── living-photo gallery ─────────────────────────────
class _LivingGallery extends StatefulWidget {
  final List<_Photo> photos;
  final String videoUrl;
  final ValueChanged<String>? onVideo;
  const _LivingGallery({required this.photos, required this.videoUrl, this.onVideo});
  @override
  State<_LivingGallery> createState() => _LivingGalleryState();
}

class _LivingGalleryState extends State<_LivingGallery> with TickerProviderStateMixin {
  final _pc = PageController();
  late final AnimationController _life = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat(); // steam, glints, breathing
  Timer? _auto;
  int _i = 0;
  bool _touch = false;

  @override
  void initState() {
    super.initState();
    _auto = Timer.periodic(const Duration(milliseconds: 4200), (_) {
      if (_touch || widget.photos.length < 2 || !_pc.hasClients) return;
      _pc.animateToPage((_i + 1) % widget.photos.length, duration: const Duration(milliseconds: 800), curve: Curves.easeInOutCubic);
    });
  }

  @override
  void dispose() { _auto?.cancel(); _pc.dispose(); _life.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ph = widget.photos;
    if (ph.isEmpty) return const SizedBox(height: 330);
    return Column(children: [
      Container(
        height: 330, clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), color: const Color(0xFF1A0805),
            boxShadow: [BoxShadow(color: const Color(0xFF3C0A00).withOpacity(.9), blurRadius: 32, offset: const Offset(0, 20), spreadRadius: -20)]),
        child: Listener(
          onPointerDown: (_) => _touch = true,
          onPointerUp: (_) => _touch = false,
          child: Stack(fit: StackFit.expand, children: [
            PageView.builder(
              controller: _pc,
              itemCount: ph.length,
              onPageChanged: (i) { HapticFeedback.selectionClick(); setState(() => _i = i); },
              itemBuilder: (_, i) => AnimatedBuilder(
                animation: _life,
                builder: (_, child) {
                  final t = _life.value * 2 * math.pi;
                  return Stack(fit: StackFit.expand, children: [
                    Transform.scale(scale: 1.0 + .025 * (1 - math.cos(t)), child: child), // slow breathing
                    CustomPaint(painter: _SteamPainter(_life.value)),
                    CustomPaint(painter: _GlintPainter(_life.value * 18, ph[i].glints)),
                  ]);
                },
                child: Image.network(ph[i].url, fit: BoxFit.cover),
              ),
            ),
            const IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0x66000000), Colors.transparent, Colors.transparent, Color(0xBF140400)], stops: [0, .28, .68, 1])))),
            Positioned(right: 12, top: 12, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10)),
              child: Text('${_i + 1} / ${ph.length}', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
            )),
            Positioned(left: 16, bottom: 16, right: 130, child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (w, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(0, .3), end: Offset.zero).animate(a), child: w)),
              child: Text(ph[_i].caption, key: ValueKey(_i),
                  style: GoogleFonts.kalam(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFFFFE7C2),
                      shadows: [Shadow(color: Colors.black.withOpacity(.7), blurRadius: 8, offset: const Offset(0, 2))])),
            )),
            if (widget.videoUrl.isNotEmpty)
              Positioned(right: 12, bottom: 14, child: GestureDetector(
                onTap: () => widget.onVideo?.call(widget.videoUrl),
                child: ClipRRect(borderRadius: BorderRadius.circular(14), child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white38)),
                    child: Text('▶ Watch it made', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                )),
              )),
          ]),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(height: 56, child: ListView(scrollDirection: Axis.horizontal, children: [
        for (int i = 0; i < ph.length; i++)
          GestureDetector(
            onTap: () => _pc.animateToPage(i, duration: const Duration(milliseconds: 700), curve: Curves.easeInOutCubic),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 56, margin: const EdgeInsets.only(right: 8), clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: i == _i ? _red : Colors.transparent, width: 2)),
              child: Opacity(opacity: i == _i ? 1 : .7, child: Image.network(ph[i].url, fit: BoxFit.cover)),
            ),
          ),
        if (widget.videoUrl.isNotEmpty)
          GestureDetector(
            onTap: () => widget.onVideo?.call(widget.videoUrl),
            child: Container(width: 56, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
                child: Stack(fit: StackFit.expand, children: [
                  Image.network(ph.last.url, fit: BoxFit.cover),
                  Container(color: Colors.black38, alignment: Alignment.center, child: const Icon(Icons.play_arrow_rounded, color: Colors.white)),
                ])),
          ),
      ])),
    ]);
  }
}

class _SteamPainter extends CustomPainter {
  final double t;
  _SteamPainter(this.t);
  @override
  void paint(Canvas c, Size s) {
    const lanes = [[.18, -10.0, 0.0], [.46, 8.0, .33], [.70, 14.0, .66]];
    for (final l in lanes) {
      final k = ((t * 3.3) + l[2]) % 1; // ~5.5 s per puff
      final op = k < .35 ? k / .35 : (1 - k) / .65;
      final center = Offset(s.width * l[0] + l[1] * k, s.height * .6 - (40 - 130 * k));
      c.drawOval(Rect.fromCenter(center: center, width: 70 * (.6 + k), height: 120 * (.6 + k)),
          Paint()..color = const Color(0xFFFFFAF0).withOpacity(.22 * op)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
    }
  }
  @override
  bool shouldRepaint(covariant _SteamPainter o) => o.t != t;
}

class _GlintPainter extends CustomPainter {
  final double t; // seconds
  final List<Offset> pts;
  _GlintPainter(this.t, this.pts);
  @override
  void paint(Canvas c, Size s) {
    for (int i = 0; i < pts.length; i++) {
      final ph = ((t + i * .53) % 3.2) / 3.2;
      final a = ph < .45 ? ph / .45 : ph < .6 ? (.6 - ph) / .15 : 0.0;
      if (a <= .02) continue;
      final o = Offset(pts[i].dx * s.width, pts[i].dy * s.height), r = 8 * a;
      final p = Paint()..color = Colors.white.withOpacity(.85 * a)..strokeWidth = 1.1..strokeCap = StrokeCap.round..blendMode = BlendMode.screen;
      c.save(); c.translate(o.dx, o.dy); c.rotate(ph);
      c.drawLine(Offset(-r, 0), Offset(r, 0), p);
      c.drawLine(Offset(0, -r), Offset(0, r), p);
      c.restore();
      c.drawCircle(o, 1.6 * a, Paint()..color = Colors.white.withOpacity(a));
    }
  }
  @override
  bool shouldRepaint(covariant _GlintPainter o) => o.t != t;
}

class _DashV extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = const Color(0xFFE9C9A0)..strokeWidth = 2;
    for (double y = 2; y < s.height; y += 7) { c.drawLine(Offset(1, y), Offset(1, math.min(y + 4, s.height)), p); }
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
