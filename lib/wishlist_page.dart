// wishlist_pantry_screen.dart — "Amma's pantry for you" Wishlist page (matches wishlist_pantry_v2.mp4)
// Warm kitchen wall · twinkling fairy lights under a fixed header · wooden shelves with gold trim ·
// saved products sitting on the shelves with a heart · kraft price tags hanging on strings that sway ·
// price-drop / back-in-stock notes · tap a product to lift it · Add → product flies into the woven basket ·
// remove with Undo · "Fill my basket" adds everything · Share my shelf.
// Data comes from wishlist_backend.js.
//
// pubspec.yaml
//   dependencies:
//     http: ^1.2.0
//     google_fonts: ^6.2.1
//
// Usage (as the Wishlist tab):
//   WishlistPantryScreen(
//     apiBase: 'https://your-api.com/api',
//     headers: {'Authorization': 'Bearer $token'},
//     onAddToCart: (productId, variantId) async => cart.add(productId, variantId),     // return true when added
//     onAddAll: (items) async { for (final i in items) await cart.add(i.productId, i.variantId); return true; },
//     onOpen: (productId) => Navigator.pushNamed(context, '/product', arguments: productId),
//     onShare: (link) => Share.share('My AmbhuJakshi favourites 💗 $link'),           // share_plus, optional
//   )

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'wishlist_manager.dart';
import 'models.dart';

class WishItem {
  final String productId, variantId, name, image, note; // note: "₹40 OFF" / "BACK!" / ""
  final double price, mrp, addedPrice;
  final bool inStock;
  WishItem.fromJson(Map<String, dynamic> j)
      : productId = '${j['productId']}',
        variantId = '${j['variantId'] ?? ''}',
        name = j['name'] ?? '',
        image = j['image'] ?? '',
        note = j['note'] ?? '',
        price = (j['price'] as num?)?.toDouble() ?? 0,
        mrp = (j['mrp'] as num?)?.toDouble() ?? 0,
        addedPrice = (j['addedPrice'] as num?)?.toDouble() ?? 0,
        inStock = j['inStock'] ?? true;

  factory WishItem.fromProduct(Product p) {
    final price = p.weightPriceMap.values.isNotEmpty ? p.weightPriceMap.values.first : 299.0;
    return WishItem._(
      productId: p.name,
      variantId: 'v1',
      name: p.name,
      image: p.image,
      note: p.isBestSeller ? '👑 BESTSELLER' : '',
      price: price,
      mrp: price * 1.2,
      addedPrice: price,
      inStock: !p.isOutOfStock,
    );
  }

  WishItem._({required this.productId, required this.variantId, required this.name, required this.image, required this.note, required this.price, required this.mrp, required this.addedPrice, required this.inStock});
}

Widget _wishImage(String url, {Key? key, double? width, double? height, BoxFit fit = BoxFit.contain}) {
  if (url.startsWith('assets/')) {
    return Image.asset(url, key: key, width: width, height: height, fit: fit,
        errorBuilder: (_, __, ___) => SizedBox(width: width, height: height, child: const Icon(Icons.rice_bowl_rounded)));
  }
  return Image.network(url, key: key, width: width, height: height, fit: fit,
      errorBuilder: (_, __, ___) => SizedBox(width: width, height: height, child: const Icon(Icons.rice_bowl_rounded)));
}

String _rs(double v) {
  final s = v.round().toString();
  if (s.length <= 3) return '₹$s';
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) { parts.insert(0, rest.substring(rest.length - 2)); rest = rest.substring(0, rest.length - 2); }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '₹${parts.join(',')},$last3';
}

const _ink = Color(0xFF2A1A12);
const _pink = Color(0xFFC2185B);
const _rose = Color(0xFFB3123A);
const _wall = Color(0xFFFBE9D2);

class WishlistPage extends StatefulWidget {
  final String apiBase;
  final Map<String, String>? headers;
  final Future<bool> Function(String productId, String variantId)? onAddToCart;
  final Future<bool> Function(List<WishItem> items)? onAddAll;
  final ValueChanged<String>? onOpen, onShare;
  final VoidCallback? onBack;
  const WishlistPage({super.key, this.apiBase = 'https://admin.adhvaithafoods.in/api', this.headers, this.onAddToCart, this.onAddAll, this.onOpen, this.onShare, this.onBack});
  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> with TickerProviderStateMixin {
  List<WishItem> _items = [];
  Map<String, dynamic> _s = {};
  bool _loading = true;
  final Set<String> _added = {}, _removing = {};
  String? _lifted;
  int _basket = 0;
  final _basketKey = GlobalKey();
  final Map<String, GlobalKey> _imgKeys = {};
  late final AnimationController _sway = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();
  late final AnimationController _twinkle = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  late final AnimationController _basketPop = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

  @override
  void initState() {
    super.initState();
    WishlistManager().addListener(_syncWishlist);
    _syncWishlist();
    _load();
  }

  @override
  void dispose() {
    WishlistManager().removeListener(_syncWishlist);
    _sway.dispose();
    _twinkle.dispose();
    _basketPop.dispose();
    super.dispose();
  }

  void _syncWishlist() {
    if (!mounted) return;
    final localItems = WishlistManager().items.map((p) => WishItem.fromProduct(p)).toList();
    setState(() {
      if (localItems.isNotEmpty) {
        _items = localItems;
      }
      _loading = false;
    });
  }

  Map<String, String> get _jsonHeaders => {'Content-Type': 'application/json', ...?widget.headers};

  Future<void> _load() async {
    try {
      final r = await http.get(Uri.parse('${widget.apiBase}/wishlist'), headers: widget.headers);
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body) as Map<String, dynamic>;
        if (!mounted) return;
        final netItems = ((j['items'] as List?) ?? []).map((e) => WishItem.fromJson(e)).toList();
        setState(() {
          _s = Map<String, dynamic>.from(j['settings'] ?? {});
          if (netItems.isNotEmpty && _items.isEmpty) {
            _items = netItems;
          }
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _total => _items.where((i) => i.inStock).fold(0, (a, i) => a + i.price);
  double get _save => _items.where((i) => i.inStock).fold(0, (a, i) => a + math.max(0, (i.mrp > i.price ? i.mrp : i.addedPrice) - i.price));

  // product photo flies from the shelf into the basket
  Future<void> _fly(WishItem it) async {
    final from = _imgKeys[it.productId]?.currentContext?.findRenderObject() as RenderBox?;
    final to = _basketKey.currentContext?.findRenderObject() as RenderBox?;
    if (from == null || to == null || !mounted) return;
    final a = from.localToGlobal(from.size.center(Offset.zero));
    final b = to.localToGlobal(to.size.center(Offset.zero));
    final entry = OverlayEntry(builder: (_) => _Flyer(url: it.image, from: a, to: b));
    Overlay.of(context).insert(entry);
    await Future.delayed(const Duration(milliseconds: 720));
    entry.remove();
    if (!mounted) return;
    setState(() => _basket++);
    _basketPop.forward(from: 0);
  }

  Future<void> _add(WishItem it) async {
    if (_added.contains(it.productId) || !it.inStock) return;
    HapticFeedback.lightImpact();
    setState(() => _lifted = it.productId);
    final ok = await (widget.onAddToCart?.call(it.productId, it.variantId) ?? Future.value(false));
    if (!ok || !mounted) { setState(() => _lifted = null); return; }
    setState(() => _added.add(it.productId));
    _toast('🧺 ${it.name} in your basket');
    await _fly(it);
    if (mounted) setState(() => _lifted = null);
  }

  Future<void> _fillBasket() async {
    final todo = _items.where((i) => i.inStock && !_added.contains(i.productId)).toList();
    if (todo.isEmpty) return;
    HapticFeedback.mediumImpact();
    final ok = await (widget.onAddAll?.call(todo) ?? Future.value(false));
    if (!ok || !mounted) return;
    for (final it in todo) {
      setState(() => _added.add(it.productId));
      unawaited(_fly(it));
      await Future.delayed(const Duration(milliseconds: 260));
    }
    _toast('🎉 Basket filled · ${todo.length} items in cart');
  }

  Future<void> _remove(WishItem it) async {
    HapticFeedback.selectionClick();
    setState(() => _removing.add(it.productId));
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    try {
      final p = WishlistManager().items.firstWhere((x) => x.name == it.name);
      WishlistManager().toggleFavorite(p);
    } catch (_) {}
    final index = _items.indexOf(it);
    setState(() { _items.remove(it); _removing.remove(it.productId); });
    http.delete(Uri.parse('${widget.apiBase}/wishlist/${it.productId}'), headers: widget.headers);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF123B2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text('💔 ${it.name} removed', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        action: SnackBarAction(label: 'UNDO', textColor: const Color(0xFFFFD27A), onPressed: () {
          setState(() => _items.insert(index.clamp(0, _items.length), it));
          http.post(Uri.parse('${widget.apiBase}/wishlist'), headers: _jsonHeaders,
              body: jsonEncode({'productId': it.productId, 'variantId': it.variantId, 'addedPrice': it.addedPrice}));
        }),
      ));
  }

  Future<void> _share() async {
    try {
      final r = await http.post(Uri.parse('${widget.apiBase}/wishlist/share'), headers: widget.headers);
      final link = jsonDecode(r.body)['link'] as String?;
      if (link != null) widget.onShare?.call(link);
    } catch (_) {}
  }

  void _toast(String msg) {
    final e = OverlayEntry(builder: (_) => _Toast(text: msg));
    Overlay.of(context).insert(e);
    Future.delayed(const Duration(milliseconds: 1800), e.remove);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    const headerH = 168.0;
    final rows = <List<WishItem>>[];
    for (int i = 0; i < _items.length; i += 2) { rows.add(_items.sublist(i, math.min(i + 2, _items.length))); }
    return Scaffold(
      backgroundColor: _wall,
      body: Stack(children: [
        const Positioned.fill(child: CustomPaint(painter: _WallPainter())),
        // shelves
        if (_loading)
          const Center(child: CircularProgressIndicator(color: _pink))
        else if (_items.isEmpty)
          _empty(top + headerH)
        else
          RefreshIndicator(
            color: _pink,
            edgeOffset: top + headerH,
            onRefresh: _load,
            child: ListView.builder(
              padding: EdgeInsets.only(top: top + headerH + 34, bottom: 120),
              itemCount: rows.length,
              itemBuilder: (_, r) => _Appear(delay: 150 + r * 150, child: _shelf(rows[r], r)),
            ),
          ),
        // fixed header
        Positioned(left: 0, right: 0, top: 0, child: Container(
          padding: EdgeInsets.fromLTRB(18, top + 12, 18, 46),
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [_wall, _wall, _wall.withOpacity(0)], stops: const [0, .9, 1])),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _chip(const Icon(Icons.arrow_back_rounded, size: 20, color: _ink), widget.onBack ?? () => Navigator.maybePop(context), square: true),
              const Spacer(),
              _chip(Text(_s['shareLabel'] ?? '↗ Share my shelf',
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: _rose)), _share),
            ]),
            const SizedBox(height: 10),
            Text(_s['eyebrow'] ?? 'MY WISHLIST', style: GoogleFonts.poppins(fontSize: 9, letterSpacing: 2.4, fontWeight: FontWeight.w800, color: _rose)),
            const SizedBox(height: 3),
            Text.rich(TextSpan(children: [
              TextSpan(text: '${_s['titleStart'] ?? "Amma's"} ', style: GoogleFonts.rozhaOne(fontSize: 30, height: 1, color: _ink)),
              TextSpan(text: _s['titleAccent'] ?? 'pantry', style: GoogleFonts.yatraOne(fontSize: 30, height: 1, color: _pink)),
              TextSpan(text: ' ${_s['titleEnd'] ?? 'for you'}', style: GoogleFonts.rozhaOne(fontSize: 30, height: 1, color: _ink)),
            ])),
            const SizedBox(height: 2),
            Text('${_items.length} favourite${_items.length == 1 ? '' : 's'} waiting on your shelf 💗',
                style: GoogleFonts.kalam(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF8A4A3A))),
          ]),
        )),
        // fairy lights
        if (_s['fairyLights'] != false)
          Positioned(left: 0, right: 0, top: top + headerH - 2, height: 30,
              child: IgnorePointer(child: AnimatedBuilder(animation: _twinkle, builder: (_, __) => CustomPaint(painter: _LightsPainter(_twinkle.value))))),
        // basket bar
        if (_items.isNotEmpty)
          Positioned(left: 12, right: 12, bottom: 12 + MediaQuery.of(context).padding.bottom, child: _basketBar()),
      ]),
    );
  }

  Widget _chip(Widget child, VoidCallback onTap, {bool square = false}) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38, width: square ? 38 : null,
          padding: square ? null : const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.35), blurRadius: 14, offset: const Offset(0, 6), spreadRadius: -8)]),
          child: child,
        ),
      );

  Widget _shelf(List<WishItem> row, int r) {
    return SizedBox(
      height: 262,
      child: LayoutBuilder(builder: (_, c) {
        final w = c.maxWidth;
        return Stack(clipBehavior: Clip.none, children: [
          // brackets
          Positioned(left: 40, bottom: 76, child: _bracket()),
          Positioned(right: 40, bottom: 76, child: _bracket()),
          // plank with gold trim
          Positioned(left: 10, right: 10, bottom: 94, height: 16, child: CustomPaint(painter: _PlankPainter())),
          for (int j = 0; j < row.length; j++) _product(row[j], left: j == 0 ? w * .06 : w * .51, width: w * .43, phase: (r * 2 + j) * .19),
        ]);
      }),
    );
  }

  Widget _bracket() => Container(width: 10, height: 22, decoration: const BoxDecoration(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
      gradient: LinearGradient(colors: [Color(0xFF5A3A1A), Color(0xFF8A5A2A)])));

  Widget _product(WishItem it, {required double left, required double width, required double phase}) {
    final gone = _removing.contains(it.productId);
    final lifted = _lifted == it.productId;
    final added = _added.contains(it.productId);
    final key = _imgKeys.putIfAbsent(it.productId, () => GlobalKey());
    return Positioned(
      left: left, width: width, bottom: 0, top: 0,
      child: AnimatedOpacity(
        opacity: gone ? 0 : 1, duration: const Duration(milliseconds: 400),
        child: AnimatedSlide(
          offset: gone ? const Offset(0, -.25) : Offset.zero, duration: const Duration(milliseconds: 450), curve: Curves.easeIn,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
            // product on the shelf
            Positioned(bottom: 106, left: 0, right: 0, child: GestureDetector(
              onTap: () => widget.onOpen?.call(it.productId),
              child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
                Positioned(bottom: -2, child: Container(width: width * .6, height: 12,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), boxShadow: [BoxShadow(color: const Color(0xFF3C1400).withOpacity(.5), blurRadius: 10)]))),
                AnimatedSlide(
                  offset: lifted ? const Offset(0, -.1) : Offset.zero, duration: const Duration(milliseconds: 500), curve: Curves.easeOutBack,
                  child: AnimatedScale(
                    scale: lifted ? 1.06 : 1, duration: const Duration(milliseconds: 500), curve: Curves.easeOutBack,
                    child: Opacity(opacity: it.inStock ? 1 : .55, child: _wishImage(it.image, key: key, width: width * .8, fit: BoxFit.contain)),
                  ),
                ),
                Positioned(right: width * .1, top: 4, child: GestureDetector(
                  onTap: () => _remove(it),
                  child: _BeatingHeart(),
                )),
              ]),
            )),
            // hanging kraft tag
            Positioned(top: 262 - 94 - 4, child: AnimatedBuilder(
              animation: _sway,
              builder: (_, child) => Transform.rotate(
                angle: math.sin((_sway.value + phase) * 2 * math.pi) * .07, alignment: Alignment.topCenter, child: child),
              child: _Tag(item: it, added: added, onAdd: () => _add(it)),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _basketBar() => Container(
        height: 72,
        padding: const EdgeInsets.fromLTRB(8, 0, 10, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF5A2E14), Color(0xFF3B1C0B)]),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.6), blurRadius: 30, offset: const Offset(0, 18), spreadRadius: -12)],
        ),
        child: Row(children: [
          AnimatedBuilder(
            animation: _basketPop,
            builder: (_, child) => Transform.scale(scale: 1 + .15 * math.sin(_basketPop.value * math.pi), child: child),
            child: SizedBox(key: _basketKey, width: 72, height: 56, child: Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(child: CustomPaint(painter: _BasketPainter())),
              Positioned(right: -2, top: -2, child: Container(
                width: 20, height: 20, alignment: Alignment.center,
                decoration: const BoxDecoration(color: Color(0xFFE8486B), shape: BoxShape.circle),
                child: Text('$_basket', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
              )),
            ])),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${_items.length} items · ${_rs(_total)}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            if (_save > 0) Text('You save ${_rs(_save)} today', style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFFE8C9A8))),
          ])),
          _ShineButton(label: _s['fillLabel'] ?? 'Fill my basket', onTap: _fillBasket),
        ]),
      );

  Widget _empty(double top) => Padding(
        padding: EdgeInsets.only(top: top + 60, left: 30, right: 30),
        child: Column(children: [
          const Text('🫙', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text('Your shelf is empty', style: GoogleFonts.rozhaOne(fontSize: 22, color: _ink)),
          const SizedBox(height: 6),
          Text('Tap the ♥ on any pickle, podi or sweet to keep it here for later.', textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF8A6A4A))),
        ]),
      );
}

// ───────────────────────────── pieces ─────────────────────────────
class _Tag extends StatelessWidget {
  final WishItem item;
  final bool added;
  final VoidCallback onAdd;
  const _Tag({required this.item, required this.added, required this.onAdd});
  @override
  Widget build(BuildContext context) {
    final drop = item.note.isNotEmpty;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 1.5, height: 14, color: const Color(0xFF8A6A44)),
      Stack(clipBehavior: Clip.none, children: [
        ClipPath(
          clipper: _TagClipper(),
          child: Container(
            width: 100,
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
            decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFFF6E2C2), Color(0xFFE2BC88), Color(0xFFD4A76E)], stops: [0, .6, 1])),
            child: CustomPaint(
              painter: _TagStitchPainter(),
              child: Column(children: [
                Text(item.name, textAlign: TextAlign.center, maxLines: 2,
                    style: GoogleFonts.poppins(fontSize: 10.5, height: 1.15, fontWeight: FontWeight.w700, color: const Color(0xFF3B1F14))),
                const SizedBox(height: 2),
                Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                  Text(_rs(item.price), style: GoogleFonts.rozhaOne(fontSize: 16, color: const Color(0xFF7A1626))),
                  if (item.mrp > item.price) ...[
                    const SizedBox(width: 3),
                    Text(_rs(item.mrp), style: GoogleFonts.poppins(fontSize: 9, color: const Color(0xFF9A7A5A), decoration: TextDecoration.lineThrough)),
                  ],
                ]),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: item.inStock ? onAdd : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
                        color: !item.inStock ? const Color(0xFF9A8A7A) : added ? const Color(0xFFE8486B) : const Color(0xFF123B2E)),
                    child: Text(!item.inStock ? 'Sold out' : added ? '✓ Added' : '+ Add',
                        style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 4),
              ]),
            ),
          ),
        ),
        // eyelet
        Positioned(left: 46.5, top: 5, child: Container(width: 7, height: 7, decoration: BoxDecoration(
            shape: BoxShape.circle, color: const Color(0xFFF3D7B3), border: Border.all(color: const Color(0xFFA07A4A), width: 1.5)))),
        if (drop)
          Positioned(right: -6, top: 6, child: Transform.rotate(angle: .17, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFF2E8B57), borderRadius: BorderRadius.circular(6)),
            child: Text(item.note, style: GoogleFonts.poppins(fontSize: 7.5, fontWeight: FontWeight.w800, color: Colors.white)),
          ))),
      ]),
    ]);
  }
}

class _TagClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..moveTo(s.width * .18, 0)..lineTo(s.width * .82, 0)..lineTo(s.width, s.height * .16)..lineTo(s.width, s.height - 8)
    ..quadraticBezierTo(s.width, s.height, s.width - 8, s.height)..lineTo(8, s.height)..quadraticBezierTo(0, s.height, 0, s.height - 8)
    ..lineTo(0, s.height * .16)..close();
  @override
  bool shouldReclip(covariant CustomClipper<Path> o) => false;
}

class _TagStitchPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = const Color(0xFF784620).withOpacity(.35)..strokeWidth = 1..style = PaintingStyle.stroke;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTRB(-5, -13, s.width + 5, s.height + 5), const Radius.circular(4)));
    for (final m in path.computeMetrics()) { for (double d = 0; d < m.length; d += 6) { c.drawPath(m.extractPath(d, d + 3), p); } }
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _BeatingHeart extends StatefulWidget {
  @override
  State<_BeatingHeart> createState() => _BeatingHeartState();
}

class _BeatingHeartState extends State<_BeatingHeart> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.scale(scale: _c.value < .2 ? 1 + .15 * math.sin(_c.value / .2 * math.pi) : 1, child: child),
        child: Container(
          width: 30, height: 30, alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.2), blurRadius: 10, offset: const Offset(0, 4))]),
          child: const Icon(Icons.favorite_rounded, size: 16, color: Color(0xFFE8486B)),
        ),
      );
}

class _ShineButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _ShineButton({required this.label, required this.onTap});
  @override
  State<_ShineButton> createState() => _ShineButtonState();
}

class _ShineButtonState extends State<_ShineButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: widget.onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15),
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFD27A), Color(0xFFE9A23B)])),
          child: Stack(children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                child: Text(widget.label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800, color: _ink))),
            Positioned.fill(child: AnimatedBuilder(animation: _c, builder: (_, __) => FractionallySizedBox(
              alignment: Alignment(-2 + 4 * (_c.value / .4).clamp(0.0, 1.0), 0), widthFactor: .4,
              child: Container(decoration: BoxDecoration(gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0), Colors.white.withOpacity(.7), Colors.white.withOpacity(0)])))))),
          ]),
        ),
      );
}

class _Flyer extends StatelessWidget {
  final String url;
  final Offset from, to;
  const _Flyer({required this.url, required this.from, required this.to});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1), duration: const Duration(milliseconds: 700), curve: Curves.easeInOutCubic,
        builder: (_, t, __) {
          final p = Offset.lerp(from, to, t)! + Offset(0, -110 * math.sin(t * math.pi));
          final size = 60 - 34 * t;
          return Positioned(left: p.dx - size / 2, top: p.dy - size / 2, child: IgnorePointer(child: _wishImage(url, width: size, height: size)));
        },
      );
}

class _Toast extends StatelessWidget {
  final String text;
  const _Toast({required this.text});
  @override
  Widget build(BuildContext context) => Positioned(
        top: MediaQuery.of(context).padding.top + 14, left: 0, right: 0,
        child: Center(child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1), duration: const Duration(milliseconds: 500), curve: Curves.elasticOut,
          builder: (_, t, child) => Transform.translate(offset: Offset(0, -90 * (1 - t)), child: child),
          child: Material(color: Colors.transparent, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFF123B2E), borderRadius: BorderRadius.circular(14)),
            child: Text(text, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
          )),
        )),
      );
}

class _Appear extends StatefulWidget {
  final int delay;
  final Widget child;
  const _Appear({required this.delay, required this.child});
  @override
  State<_Appear> createState() => _AppearState();
}

class _AppearState extends State<_Appear> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  @override
  void initState() { super.initState(); Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _c.forward(); }); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final a = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
    return AnimatedBuilder(animation: _c, child: widget.child,
        builder: (_, w) => Opacity(opacity: _c.value, child: Transform.translate(offset: Offset(0, 30 * (1 - a.value)), child: w)));
  }
}

// ───────────────────────────── painters ─────────────────────────────
class _WallPainter extends CustomPainter {
  const _WallPainter();
  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    c.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFFFBE9D2), Color(0xFFF1D2A8)]).createShader(r));
    c.drawRect(r, Paint()..shader = RadialGradient(center: const Alignment(0, -.85), radius: .8,
        colors: [Colors.white.withOpacity(.7), Colors.white.withOpacity(0)]).createShader(r));
    final line = Paint()..color = const Color(0xFFAA6E32).withOpacity(.12)..strokeWidth = 1;
    for (double y = 46; y < s.height; y += 47) { c.drawLine(Offset(0, y), Offset(s.width, y), line); }
    for (double x = 92; x < s.width; x += 93) { c.drawLine(Offset(x, 0), Offset(x, s.height), line..color = const Color(0xFFAA6E32).withOpacity(.1)); }
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _PlankPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final rr = RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(4));
    c.drawShadow(Path()..addRRect(rr), const Color(0xFF461E05), 8, false);
    c.drawRRect(rr, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFFD49A62), Color(0xFFA8693A), Color(0xFF7A4520)], stops: [0, .5, 1]).createShader(Offset.zero & s));
    final grain = Paint()..color = const Color(0xFF3C1905).withOpacity(.35)..strokeWidth = 1;
    for (double x = 40; x < s.width; x += 87) { c.drawLine(Offset(x, 0), Offset(x, s.height), grain); }
    c.drawLine(const Offset(0, 1.5), Offset(s.width, 1.5), Paint()..color = const Color(0xFFFFDCAA).withOpacity(.45)..strokeWidth = 2);
    // gold trim on the front edge
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, -3, s.width, 3), const Radius.circular(2)), Paint()..shader = const LinearGradient(
        colors: [Color(0xFFB8862E), Color(0xFFFFE7A8), Color(0xFFD9A441), Color(0xFFFFF1C4), Color(0xFFB8862E)]).createShader(Rect.fromLTWH(0, -3, s.width, 3)));
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _LightsPainter extends CustomPainter {
  final double t;
  _LightsPainter(this.t);
  static const _cols = [Color(0xFFFFD27A), Color(0xFFFF8A8A), Color(0xFF8AD7FF), Color(0xFFB6F28A)];
  @override
  void paint(Canvas c, Size s) {
    final n = (s.width / 28).floor();
    for (int i = 0; i < n; i++) {
      final x = 10 + i * 28.0, y = 8 + 6 * math.sin(i / (n - 1) * math.pi);
      final on = .35 + .65 * (.5 + .5 * math.cos((t + i * .13) * 2 * math.pi));
      final col = _cols[i % 4];
      c.drawCircle(Offset(x + 4, y + 5), 9, Paint()..color = col.withOpacity(.45 * on)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      c.drawOval(Rect.fromLTWH(x, y, 8, 11), Paint()..color = col.withOpacity(.4 + .6 * on));
    }
  }
  @override
  bool shouldRepaint(covariant _LightsPainter o) => o.t != t;
}

class _BasketPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    // handle
    c.drawArc(Rect.fromLTWH(12, 2, s.width - 24, 52), math.pi, math.pi, false,
        Paint()..color = const Color(0xFFA06A34)..style = PaintingStyle.stroke..strokeWidth = 4);
    // woven body
    final body = RRect.fromRectAndCorners(Rect.fromLTWH(4, s.height - 36, s.width - 8, 34),
        topLeft: const Radius.circular(4), topRight: const Radius.circular(4), bottomLeft: const Radius.circular(14), bottomRight: const Radius.circular(14));
    c.save();
    c.clipRRect(body);
    c.drawRRect(body, Paint()..color = const Color(0xFFC98B52));
    final weave = Paint()..color = const Color(0xFFA06A34)..strokeWidth = 5;
    for (double x = -40; x < s.width + 40; x += 10) { c.drawLine(Offset(x, s.height), Offset(x + 40, s.height - 40), weave); }
    c.restore();
    c.drawLine(Offset(6, s.height - 35), Offset(s.width - 6, s.height - 35), Paint()..color = const Color(0xFFE8B47A)..strokeWidth = 3);
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
