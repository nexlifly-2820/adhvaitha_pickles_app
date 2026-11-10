// combo_box_screen.dart — "Amma's Combo Box" (matches combo_box_sizes.mp4)
// Pick a box size → tap jars: each flies into the 3D kraft box (banana-leaf spaces) → discount tags unlock & swing →
// box full: lid folds down, ribbon ties, gold seal + confetti, "For you, with love" tag → Add box to cart.
// ✕ on a jar sends it back; "✎ Edit box" opens a sealed box again. Everything comes from the admin dashboard:
//   combo_box_backend.js → GET /api/combo-box, POST /api/combo-box/cart
//
// pubspec.yaml:  http: ^1.2.0   google_fonts: ^6.2.1      flutter: assets: - assets/logo_full.png
//
// Usage:
//   Navigator.push(context, MaterialPageRoute(builder: (_) => ComboBoxScreen(
//     apiBase: 'https://your-api.com/api', headers: {'Authorization': 'Bearer $token'},
//     onAdded: () { CartService.instance.refresh(); Navigator.pushNamed(context, '/cart'); },
//   )));

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

const Color _ink = Color(0xFF2A0A10);
const Color _yellow = Color(0xFFFFE45C);
const Color _pinkText = Color(0xFFD6336C);
const double _dw = 390.0; // design width
const double _dh = 744.0; // design height (above the bottom bar)

// ───────────── data ─────────────
class ComboPrice {
  final String variantId;
  final double price, mrp;
  final bool inStock;
  ComboPrice(this.variantId, this.price, this.mrp, this.inStock);
}

class ComboProduct {
  final String id, productId, name, image;
  final Color c1, c2;
  final Map<String, ComboPrice> prices;
  ComboProduct(this.id, this.productId, this.name, this.image, this.c1, this.c2, this.prices);
}

class ComboTier {
  final int jars;
  final double percent;
  ComboTier(this.jars, this.percent);
}

Color _hex(dynamic v, Color fb) {
  final String s = '${v ?? ''}'.replaceAll('#', '');
  if (s.length != 6) return fb;
  final int? n = int.tryParse(s, radix: 16);
  return n == null ? fb : Color(0xFF000000 | n);
}

double _num(dynamic v) => (v is num) ? v.toDouble() : (double.tryParse('$v') ?? 0.0);
String _rs(double v) => '₹${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(2)}';

// ───────────── screen ─────────────
class ComboBoxScreen extends StatefulWidget {
  final String apiBase;
  final Map<String, String>? headers;
  final String logoAsset;
  final VoidCallback? onAdded;
  final VoidCallback? onBack;
  const ComboBoxScreen({super.key, required this.apiBase, this.headers, this.logoAsset = 'assets/logo_full.png', this.onAdded, this.onBack});
  @override
  State<ComboBoxScreen> createState() => _ComboBoxScreenState();
}

class _Flight {
  final String image;
  final Offset from, to;
  final double up;
  _Flight(this.image, this.from, this.to, this.up);
}

class _ComboBoxScreenState extends State<ComboBoxScreen> with TickerProviderStateMixin {
  // settings
  String _eyebrow = 'BUILD YOUR BOX', _t1 = "Amma's", _t2 = 'Combo Box', _boxLabel = "Amma's Combo";
  String _lidText = 'Made with love,\npacked by Amma', _tagText = 'For you, with love 💛';
  int _jars = 4;
  List<String> _sizes = <String>[];
  List<ComboTier> _tiers = <ComboTier>[];
  List<ComboProduct> _products = <ComboProduct>[];
  bool _loading = true, _adding = false;
  String? _error;

  // state
  int _size = 0;
  List<String?> _slots = <String?>[]; // product id per space, null = empty
  bool _sealed = false;
  String _toast = '';
  bool _toastOn = false;
  Timer? _toastTimer;

  // animation
  late AnimationController _loop; // glow / next-slot pulse / CTA pulse
  late AnimationController _fly; // one jar flying
  late AnimationController _seal; // 0 → 1 over 2.4 s
  late AnimationController _land; // bounce of the jar that just landed
  final List<AnimationController> _swing = <AnimationController>[];
  _Flight? _flight;
  int _landSlot = -1;
  final List<List<double>> _sparks = <List<double>>[];

  // keys for flight positions
  final GlobalKey _stageKey = GlobalKey();
  final Map<String, GlobalKey> _cardImgKeys = <String, GlobalKey>{};
  final List<GlobalKey> _slotKeys = <GlobalKey>[];

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _fly = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _seal = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    _land = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    final math.Random r = math.Random(5);
    for (int k = 0; k < 34; k++) {
      final double a = k / 34 * math.pi * 2, d = 80 + r.nextDouble() * 110;
      _sparks.add(<double>[math.cos(a) * d, math.sin(a) * d - 30, r.nextDouble() * 9, (k % 5).toDouble()]);
    }
    _load();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _loop.dispose();
    _fly.dispose();
    _seal.dispose();
    _land.dispose();
    for (final AnimationController c in _swing) {
      c.dispose();
    }
    super.dispose();
  }

  String _abs(String u) {
    if (u.isEmpty || u.startsWith('http')) return u;
    final String origin = widget.apiBase.replaceAll(RegExp(r'/api/?$'), '');
    return u.startsWith('/') ? '$origin$u' : '$origin/$u';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final fallbackJson = <String, dynamic>{
      "settings": {
        "enabled": true,
        "eyebrow": "BUILD YOUR BOX",
        "titleStart": "Amma's",
        "titleAccent": "Combo Box",
        "boxLabel": "Amma's Combo",
        "lidText": "Made with love,\npacked by Amma",
        "tagText": "For you, with love 💛",
        "jars": 4,
        "sizes": ["250g", "500g", "1kg"],
        "tiers": [
          {"jars": 2, "percent": 10},
          {"jars": 3, "percent": 15},
          {"jars": 4, "percent": 25}
        ]
      },
      "products": [
        {
          "id": "p1", "productId": "avakaya", "name": "Bellam Avakaya", "image": "assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg",
          "color1": "#E8432B", "color2": "#9E1424",
          "prices": {
            "250g": {"variantId": "v1", "price": 120, "mrp": 150, "inStock": true},
            "500g": {"variantId": "v2", "price": 228, "mrp": 280, "inStock": true},
            "1kg": {"variantId": "v3", "price": 440, "mrp": 540, "inStock": true}
          }
        },
        {
          "id": "p2", "productId": "gongura", "name": "Gongura Pickle", "image": "assets/images/gongura_pickle.png",
          "color1": "#1E7A46", "color2": "#0F3F33",
          "prices": {
            "250g": {"variantId": "v4", "price": 130, "mrp": 160, "inStock": true},
            "500g": {"variantId": "v5", "price": 245, "mrp": 299, "inStock": true},
            "1kg": {"variantId": "v6", "price": 479, "mrp": 580, "inStock": true}
          }
        },
        {
          "id": "p3", "productId": "idli_karam", "name": "Idli Karam Podi", "image": "assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg",
          "color1": "#F59E2B", "color2": "#C2410C",
          "prices": {
            "250g": {"variantId": "v7", "price": 139, "mrp": 170, "inStock": true},
            "500g": {"variantId": "v8", "price": 320, "mrp": 380, "inStock": true}
          }
        },
        {
          "id": "p4", "productId": "sunnunda", "name": "Sunnunda Laddu", "image": "assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg",
          "color1": "#8B4513", "color2": "#6A320A",
          "prices": {
            "250g": {"variantId": "v9", "price": 199, "mrp": 240, "inStock": true},
            "500g": {"variantId": "v10", "price": 380, "mrp": 450, "inStock": true}
          }
        },
        {
          "id": "p5", "productId": "murukku", "name": "Kara Murukku", "image": "assets/images/karam_janthukalu_murukku_strings_snack.jpg",
          "color1": "#1E4F8F", "color2": "#12345E",
          "prices": {
            "250g": {"variantId": "v11", "price": 129, "mrp": 155, "inStock": true},
            "500g": {"variantId": "v12", "price": 249, "mrp": 299, "inStock": true}
          }
        }
      ]
    };

    void parseAndApply(Map<String, dynamic> j) {
      final Map<String, dynamic> s = (j['settings'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final List<ComboProduct> ps = <ComboProduct>[];
      for (final dynamic raw in (j['products'] as List?) ?? <dynamic>[]) {
        final Map<String, dynamic> m = raw as Map<String, dynamic>;
        final Map<String, ComboPrice> prices = <String, ComboPrice>{};
        final Map<String, dynamic> pm = (m['prices'] as Map<String, dynamic>?) ?? <String, dynamic>{};
        pm.forEach((String k, dynamic v) {
          final Map<String, dynamic> x = v as Map<String, dynamic>;
          prices[k] = ComboPrice('${x['variantId']}', _num(x['price']), _num(x['mrp']), x['inStock'] != false);
        });
        ps.add(ComboProduct('${m['id']}', '${m['productId']}', '${m['name'] ?? ''}', _abs('${m['image'] ?? ''}'),
            _hex(m['color1'], const Color(0xFFFF9F43)), _hex(m['color2'], const Color(0xFFF2542D)), prices));
      }
      final List<ComboTier> tiers = <ComboTier>[];
      for (final dynamic t in (s['tiers'] as List?) ?? <dynamic>[]) {
        final Map<String, dynamic> x = t as Map<String, dynamic>;
        tiers.add(ComboTier(_num(x['jars']).round(), _num(x['percent'])));
      }
      final int jars = math.max(2, math.min(4, _num(s['jars'] ?? 4).round()));
      for (final AnimationController c in _swing) {
        c.dispose();
      }
      _swing.clear();
      for (int i = 0; i < tiers.length; i++) {
        _swing.add(AnimationController(vsync: this, duration: const Duration(milliseconds: 1000)));
      }
      if (mounted) {
        setState(() {
          _eyebrow = '${s['eyebrow'] ?? _eyebrow}';
          _t1 = '${s['titleStart'] ?? _t1}';
          _t2 = '${s['titleAccent'] ?? _t2}';
          _boxLabel = '${s['boxLabel'] ?? _boxLabel}';
          _lidText = '${s['lidText'] ?? _lidText}';
          _tagText = '${s['tagText'] ?? _tagText}';
          _jars = jars;
          _sizes = ((s['sizes'] as List?) ?? <dynamic>[]).map((dynamic e) => '$e').toList();
          _tiers = tiers;
          _products = ps;
          _slots = List<String?>.filled(jars, null);
          _slotKeys
            ..clear()
            ..addAll(List<GlobalKey>.generate(jars, (int i) => GlobalKey()));
          _size = 0;
          _sealed = false;
          _loading = false;
          _error = null;
        });
        _seal.value = 0;
      }
    }

    parseAndApply(fallbackJson);

    try {
      final http.Response r = await http.get(Uri.parse('${widget.apiBase}/combo-box'), headers: widget.headers).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (r.statusCode == 200 && !r.body.trim().startsWith('<!DOCTYPE') && !r.body.trim().startsWith('<html')) {
        final Map<String, dynamic> j = jsonDecode(r.body) as Map<String, dynamic>;
        if ((j['settings'] as Map?)?['enabled'] != false && (j['products'] as List? ?? []).isNotEmpty) {
          parseAndApply(j);
        }
      }
    } catch (_) {}
  }

  // ───────── helpers ─────────
  String get _sz => _sizes.isEmpty ? '' : _sizes[_size];
  ComboProduct? _p(String? id) {
    if (id == null) return null;
    for (final ComboProduct p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  double _price(ComboProduct p) => p.prices[_sz]?.price ?? 0.0;
  List<String> get _filled => _slots.whereType<String>().toList();
  int get _n => _filled.length;
  double get _sum => _filled.fold<double>(0.0, (double a, String id) => a + _price(_p(id)!));
  double _pctFor(int n) {
    double p = 0;
    for (final ComboTier t in _tiers) {
      if (n >= t.jars) p = t.percent;
    }
    return p;
  }

  double get _off => (_sum * _pctFor(_n) / 100).roundToDouble();

  void _say(String t) {
    _toastTimer?.cancel();
    setState(() {
      _toast = t;
      _toastOn = true;
    });
    _toastTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _toastOn = false);
    });
  }

  Offset? _centerOf(GlobalKey k) {
    final RenderBox? stage = _stageKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? box = k.currentContext?.findRenderObject() as RenderBox?;
    if (stage == null || box == null) return null;
    return stage.globalToLocal(box.localToGlobal(box.size.center(Offset.zero)));
  }

  void _swingTiers(int before, int after) {
    for (int i = 0; i < _tiers.length && i < _swing.length; i++) {
      if (before < _tiers[i].jars && after >= _tiers[i].jars) _swing[i].forward(from: 0);
    }
  }

  // ───────── actions ─────────
  Future<void> _pick(ComboProduct p) async {
    if (_sealed || _flight != null || _seal.isAnimating) return;
    if (_slots.contains(p.id)) {
      _say('${p.name} is already in your box');
      return;
    }
    final ComboPrice? pr = p.prices[_sz];
    if (pr == null || !pr.inStock) {
      _say('${p.name} ($_sz) is out of stock');
      return;
    }
    final int k = _slots.indexOf(null);
    if (k < 0) return;
    HapticFeedback.selectionClick();
    final GlobalKey? cardKey = _cardImgKeys[p.id];
    final Offset? from = cardKey == null ? null : _centerOf(cardKey);
    final Offset? to = _centerOf(_slotKeys[k]);
    if (from != null && to != null) {
      setState(() => _flight = _Flight(p.image, from, to, 100));
      await _fly.forward(from: 0);
      if (!mounted) return;
    }
    final int before = _n;
    setState(() {
      _flight = null;
      _slots[k] = p.id;
      _landSlot = k;
    });
    _land.forward(from: 0);
    _swingTiers(before, _n);
    HapticFeedback.lightImpact();
    if (_n == _jars) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      _doSeal();
    } else if (_pctFor(_n) > _pctFor(before)) {
      final double next = _pctFor(_n + 1);
      _say(next > _pctFor(_n) ? '🎉 ${_pctFor(_n).toStringAsFixed(0)}% off · one more jar for ${next.toStringAsFixed(0)}%!' : '🎉 ${_pctFor(_n).toStringAsFixed(0)}% off unlocked');
    }
  }

  Future<void> _remove(int k) async {
    if (_sealed || _flight != null) return;
    final ComboProduct? p = _p(_slots[k]);
    if (p == null) return;
    HapticFeedback.selectionClick();
    final Offset? from = _centerOf(_slotKeys[k]);
    final GlobalKey? cardKey = _cardImgKeys[p.id];
    final Offset? to = cardKey == null ? null : _centerOf(cardKey);
    setState(() => _slots[k] = null);
    if (from != null && to != null) {
      setState(() => _flight = _Flight(p.image, from, to, 60));
      await _fly.forward(from: 0);
      if (!mounted) return;
      setState(() => _flight = null);
    }
    _say('${p.name} removed · pick another jar');
  }

  void _doSeal() {
    setState(() => _sealed = true);
    _seal.forward(from: 0);
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted || !_sealed) return;
      HapticFeedback.heavyImpact();
      _say('Box packed! You save ${_rs(_off)} 🎁');
    });
  }

  void _edit() {
    if (!_sealed) return;
    HapticFeedback.selectionClick();
    _seal.animateBack(0, duration: const Duration(milliseconds: 700), curve: Curves.easeIn).then((_) {
      if (mounted) _say('Tap ✕ on a jar to swap it');
    });
    setState(() => _sealed = false);
  }

  void _setSize(int i) {
    if (i == _size) return;
    HapticFeedback.selectionClick();
    setState(() => _size = i);
    // jars not sold in the new size are taken out
    final List<String> dropped = <String>[];
    for (int k = 0; k < _slots.length; k++) {
      final ComboProduct? p = _p(_slots[k]);
      if (p != null && (p.prices[_sz] == null || !p.prices[_sz]!.inStock)) {
        dropped.add(p.name);
        _slots[k] = null;
      }
    }
    if (dropped.isNotEmpty && _sealed) _edit();
    _say(dropped.isEmpty ? 'Switched to $_sz jars · your picks stay' : '${dropped.join(', ')} not available in $_sz — removed');
  }

  Future<void> _addToCart() async {
    if (_n < _jars || _adding) return;
    setState(() => _adding = true);
    try {
      final List<String> ids = _filled.map((String id) => _p(id)!.productId).toList();
      final http.Response r = await http.post(Uri.parse('${widget.apiBase}/combo-box/cart'),
          headers: <String, String>{'Content-Type': 'application/json', ...?widget.headers}, body: jsonEncode(<String, dynamic>{'size': _sz, 'productIds': ids}));
      if (!mounted) return;
      final Map<String, dynamic> j = r.body.isEmpty ? <String, dynamic>{} : jsonDecode(r.body) as Map<String, dynamic>;
      if (r.statusCode != 200) {
        _say('${j['error'] ?? 'Could not add the box. Please try again.'}');
        setState(() => _adding = false);
        return;
      }
      HapticFeedback.mediumImpact();
      _say('Box added to cart 🎁');
      setState(() => _adding = false);
      widget.onAdded?.call();
    } catch (_) {
      if (mounted) {
        setState(() => _adding = false);
        _say('No internet. Please try again.');
      }
    }
  }

  double _seg(double a, double b, [Curve c = Curves.easeInOut]) => c.transform(((_seal.value * 2.4 - a) / (b - a)).clamp(0.0, 1.0));

  // ───────── build ─────────
  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF2386B),
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: _Background()),
          if (_loading) const Center(child: CircularProgressIndicator(color: Colors.white)),
          if (!_loading && _error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                  Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TextButton(onPressed: _load, child: Text('Try again', style: GoogleFonts.poppins(color: _yellow, fontWeight: FontWeight.w800))),
                  TextButton(onPressed: widget.onBack ?? () => Navigator.maybePop(context), child: Text('Go back', style: GoogleFonts.poppins(color: Colors.white70))),
                ]),
              ),
            ),
          if (!_loading && _error == null)
            Column(
              children: <Widget>[
                SizedBox(height: mq.padding.top),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.topCenter,
                      child: SizedBox(width: _dw, height: _dh, child: _content()),
                    ),
                  ),
                ),
                _bottomBar(mq.padding.bottom),
              ],
            ),
        ],
      ),
    );
  }

  Widget _content() {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_loop, _fly, _seal, _land, ..._swing]),
      builder: (BuildContext c, Widget? child) {
        return Stack(
          key: _stageKey,
          clipBehavior: Clip.none,
          children: <Widget>[
            // top row
            Positioned(
              left: 18,
              top: 10,
              child: GestureDetector(
                onTap: widget.onBack ?? () => Navigator.maybePop(context),
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.5))),
                  child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
            Positioned(
              left: 60,
              right: 60,
              top: 20,
              child: Text(_eyebrow, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 2.6, color: const Color(0xFFFFF3B0))),
            ),
            Positioned(
              left: 10,
              right: 10,
              top: 48,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(
                  TextSpan(children: <InlineSpan>[
                    TextSpan(text: '$_t1 ', style: GoogleFonts.rozhaOne(fontSize: 31, color: Colors.white)),
                    TextSpan(text: _t2, style: GoogleFonts.yatraOne(fontSize: 31, color: _yellow)),
                  ]),
                  style: const TextStyle(shadows: <Shadow>[Shadow(color: Color(0x59780A3C), blurRadius: 14, offset: Offset(0, 4))]),
                ),
              ),
            ),
            // size chips
            Positioned(left: 0, right: 0, top: 92, child: _sizeChips()),
            // the box
            Positioned(left: 0, right: 0, top: 134, height: 262, child: _boxStage()),
            // discount tags
            Positioned(left: 18, right: 18, top: 400, height: 92, child: _tierRow()),
            // products
            Positioned(left: 12, right: 12, top: 500, bottom: 0, child: _grid()),
            // flying jar
            if (_flight != null) _flyingJar(),
            // toast
            Positioned(
              left: 0,
              right: 0,
              top: 10,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _toastOn ? 1.0 : 0.0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x80500028), blurRadius: 18, offset: Offset(0, 8), spreadRadius: -6)]),
                      child: Text(_toast, style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFFC2185B))),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sizeChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < _sizes.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => _setSize(i),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 300),
                scale: i == _size ? 1.06 : 1.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                  decoration: BoxDecoration(
                    color: i == _size ? Colors.white : Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: i == _size ? Colors.white : Colors.white.withOpacity(0.5)),
                    boxShadow: i == _size ? const <BoxShadow>[BoxShadow(color: Color(0x99500028), blurRadius: 14, offset: Offset(0, 6), spreadRadius: -6)] : null,
                  ),
                  child: Text('${_sizes[i]} box', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: i == _size ? _pinkText : Colors.white)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ───────── 3D box ─────────
  // Stage is 390 × 262. The tray (270 × 200) is tilted back; its projected edges are computed so the
  // flat parts (standing lid at the back, front wall) line up with it.
  static const double _trayW = 270, _trayH = 200, _tilt = -0.94, _persp = 0.0012;

  Matrix4 get _trayMatrix => Matrix4.identity()
    ..setEntry(3, 2, _persp)
    ..rotateX(_tilt);

  // projected y and half-width of the tray edge at local y (relative to tray centre)
  Offset _edge(double y) {
    final double z = y * math.sin(_tilt);
    final double w = 1 + _persp * z;
    return Offset(_trayW / 2 / w, y * math.cos(_tilt) / w);
  }

  Widget _boxStage() {
    const double cx = _dw / 2, cy = 140;
    final Offset top = _edge(-_trayH / 2), bot = _edge(_trayH / 2);
    final double topY = cy + top.dy, botY = cy + bot.dy;
    final double lidDrop = _seg(0, 0.45, Curves.easeIn); // standing lid folds down
    final double lidIn = _seg(0.42, 0.6); // closed lid appears
    final double rv = _seg(0.95, 1.35), rh = _seg(1.25, 1.65);
    final double sealK = _seg(1.8, 2.25, Curves.elasticOut);
    final double tagK = _seg(2.05, 2.4, Curves.easeOutBack);
    final double flashK = _seg(1.8, 2.4, Curves.easeOut);
    final double glow = 0.5 + 0.5 * math.sin(_loop.value * math.pi * 2);
    final int next = _sealed ? -1 : _slots.indexOf(null);

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        // warm glow + shadow
        Positioned(
          left: cx - 180,
          top: cy - 90,
          child: Container(width: 360, height: 180, decoration: BoxDecoration(gradient: RadialGradient(colors: <Color>[Color.fromRGBO(255, 240, 170, 0.6 + 0.15 * glow), const Color(0x00FFF0AA)]))),
        ),
        Positioned(
          left: cx - 165,
          top: botY + 30,
          child: Container(width: 330, height: 46, decoration: const BoxDecoration(gradient: RadialGradient(colors: <Color>[Color(0x73500A28), Color(0x00500A28)]))),
        ),
        // standing lid (inside print) behind the box
        if (lidDrop < 1)
          Positioned(
            left: cx - top.dx - 2,
            top: topY - 80,
            width: (top.dx + 2) * 2,
            height: 80,
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0016)
                ..rotateX(-0.21 - 1.33 * lidDrop),
              child: Opacity(opacity: (1 - lidDrop * 1.2).clamp(0.0, 1.0), child: _lidInside()),
            ),
          ),
        // tray
        Positioned(
          left: cx - _trayW / 2,
          top: cy - _trayH / 2,
          width: _trayW,
          height: _trayH,
          child: Transform(
            alignment: Alignment.center,
            transform: _trayMatrix,
            child: _tray(next, glow),
          ),
        ),
        // front wall
        Positioned(
          left: cx - bot.dx,
          top: botY,
          width: bot.dx * 2,
          height: 46,
          child: _front(),
        ),
        // closed lid (same tilt, slightly bigger)
        if (lidIn > 0)
          Positioned(
            left: cx - _trayW / 2 - 7,
            top: cy - _trayH / 2 - 6,
            width: _trayW + 14,
            height: _trayH + 12,
            child: Opacity(opacity: lidIn, child: Transform(alignment: Alignment.center, transform: _trayMatrix, child: _lidOutside(rv, rh, sealK))),
          ),
        // flash ring + confetti
        if (flashK > 0 && flashK < 1)
          Positioned(left: cx, top: cy + 10, child: IgnorePointer(child: CustomPaint(painter: _BurstPainter(flashK, _sparks)))),
        // tag
        if (tagK > 0)
          Positioned(
            right: 22,
            top: 30,
            child: Transform.rotate(
              angle: -0.16,
              child: Transform.scale(
                scale: tagK,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 6, 11, 4),
                  decoration: BoxDecoration(color: const Color(0xFFFFF6E8), borderRadius: BorderRadius.circular(6), boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 6))]),
                  child: Text(_tagText, style: GoogleFonts.kalam(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
                ),
              ),
            ),
          ),
        // edit button
        Positioned(
          left: 18,
          top: 18,
          child: IgnorePointer(
            ignoring: !_sealed || _seal.value < 1,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 350),
              opacity: _sealed && _seal.value >= 1 ? 1.0 : 0.0,
              child: GestureDetector(
                onTap: _edit,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.55))),
                  child: Text('✎ Edit box', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tray(int next, double glow) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[Color(0xFFE9BD80), Color(0xFFC9934F), Color(0xFFB07A3C)], stops: <double>[0.0, 0.6, 1.0]),
        border: Border.all(color: const Color(0x73FFF0D2), width: 2),
      ),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 9,
        crossAxisSpacing: 9,
        childAspectRatio: ((_trayW - 24 - 9) / 2) / ((_trayH - 24 - 9) / 2),
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: <Widget>[for (int k = 0; k < _slots.length && k < 4; k++) _slot(k, k == next, glow)],
      ),
    );
  }

  Widget _slot(int k, bool isNext, double glow) {
    final ComboProduct? p = _p(_slots[k]);
    final double landT = k == _landSlot ? Curves.elasticOut.transform(_land.value) : 1.0;
    return Container(
      key: _slotKeys[k],
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[Color(0xFF4FA046), Color(0xFF2D7330), Color(0xFF1F5A25)], stops: <double>[0.0, 0.6, 1.0]),
        boxShadow: isNext ? <BoxShadow>[BoxShadow(color: _yellow.withOpacity(0.5 + 0.4 * glow), blurRadius: 14, spreadRadius: 1)] : null,
        border: isNext ? Border.all(color: _yellow, width: 2) : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          Positioned.fill(child: CustomPaint(painter: _LeafPainter())),
          if (p == null)
            Transform.scale(
              scale: isNext ? 1 + 0.15 * glow : 1.0,
              child: Text('${k + 1}', style: GoogleFonts.rozhaOne(fontSize: 24, color: Colors.white.withOpacity(isNext ? 0.7 : 0.22))),
            ),
          if (p != null) ...<Widget>[
            Positioned(left: 14, right: 14, top: 18, bottom: 4, child: Container(decoration: const BoxDecoration(gradient: RadialGradient(colors: <Color>[Color(0x73000000), Color(0x00000000)])))),
            Transform.scale(scale: 1.25 - 0.25 * landT, child: _img(p.image, 104, 80)),
            if (!_sealed)
              Positioned(
                right: -5,
                top: -5,
                child: GestureDetector(
                  onTap: () => _remove(k),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: <BoxShadow>[BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))]),
                    child: const Text('✕', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6E1426))),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _front() {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Color(0xFFB9803F), Color(0xFF9A6430), Color(0xFF7E4E22)], stops: <double>[0.0, 0.55, 1.0]),
        boxShadow: <BoxShadow>[BoxShadow(color: Color(0x40000000), blurRadius: 10, offset: Offset(0, 6))],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          const Positioned(left: 0, right: 0, top: 0, height: 3, child: ColoredBox(color: Color(0x73FFE1B4))),
          Positioned(left: 0, right: 0, top: 22, height: 2, child: Container(color: const Color(0xCCE7D3A8))),
          Positioned(left: 0, top: 0, bottom: 0, width: 20, child: CustomPaint(painter: _CornerPainter(true))),
          Positioned(right: 0, top: 0, bottom: 0, width: 20, child: CustomPaint(painter: _CornerPainter(false))),
          Container(
            padding: const EdgeInsets.fromLTRB(7, 3, 12, 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3DC),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFFC9A06A)),
              boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x59000000), blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              Image.asset(widget.logoAsset, width: 24, height: 24, errorBuilder: (BuildContext c, Object e, StackTrace? s) => const SizedBox(width: 4)),
              const SizedBox(width: 7),
              Text(_sz.isEmpty ? _boxLabel : '$_boxLabel · $_sz', style: GoogleFonts.yatraOne(fontSize: 14, color: const Color(0xFF6E1426))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _lidInside() {
    return ClipPath(
      clipper: _TrapClipper(0.04),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Color(0xFF93233A), Color(0xFF5A0F1E), Color(0xFF470A17)], stops: <double>[0.0, 0.7, 1.0]),
          border: Border(top: BorderSide(color: Color(0xFFC9934F), width: 7)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Positioned.fill(child: CustomPaint(painter: _DotsPainter(const Color(0x40FFD58A), 15))),
            Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              ColorFiltered(
                colorFilter: const ColorFilter.mode(Color(0xFFFFD58A), BlendMode.srcATop),
                child: Image.asset(widget.logoAsset, width: 38, height: 38, errorBuilder: (BuildContext c, Object e, StackTrace? s) => const SizedBox()),
              ),
              const SizedBox(width: 8),
              Text(_lidText, style: GoogleFonts.kalam(fontSize: 13.5, height: 1.15, fontWeight: FontWeight.w700, color: const Color(0xFFFFE1B0))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _lidOutside(double rv, double rh, double sealK) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[Color(0xFFE6B676), Color(0xFFC79152), Color(0xFFB07A3E)], stops: <double>[0.0, 0.55, 1.0]),
        border: Border.all(color: const Color(0x73FFF0D2), width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            top: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(heightFactor: rv, child: Container(width: 20, decoration: const BoxDecoration(gradient: LinearGradient(colors: <Color>[Color(0xFF8A0F22), Color(0xFFD93448), Color(0xFF8A0F22)])))),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(widthFactor: rh, child: Container(height: 20, decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Color(0xFF8A0F22), Color(0xFFD93448), Color(0xFF8A0F22)])))),
            ),
          ),
          if (sealK > 0)
            Transform.scale(
              scale: sealK,
              child: Container(
                width: 70,
                height: 70,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(center: Alignment(-0.3, -0.4), colors: <Color>[Color(0xFFFFF0B8), Color(0xFFF2B530), Color(0xFFA86E0C)], stops: <double>[0.0, 0.5, 1.0]),
                  boxShadow: <BoxShadow>[BoxShadow(color: Color(0x73000000), blurRadius: 12, offset: Offset(0, 6)), BoxShadow(color: Color(0x80FFF0BE), spreadRadius: 3)],
                ),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(Color(0xFF5A3406), BlendMode.srcATop),
                  child: Image.asset(widget.logoAsset, width: 44, height: 44, errorBuilder: (BuildContext c, Object e, StackTrace? s) => const SizedBox()),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ───────── discount tags ─────────
  static const List<List<Color>> _tierCols = <List<Color>>[
    <Color>[Color(0xFF3FD68A), Color(0xFF17A35B)],
    <Color>[Color(0xFF4FC3FF), Color(0xFF1A7FE0)],
    <Color>[Color(0xFFFFE45C), Color(0xFFFFB21E)],
    <Color>[Color(0xFFFF8FC7), Color(0xFFE0347E)],
  ];

  Widget _tierRow() {
    final double pct = _pctFor(_n);
    final String sub = _n < (_tiers.isEmpty ? 1 : _tiers.first.jars)
        ? 'add ${_tiers.isEmpty ? _jars : _tiers.first.jars} to start saving'
        : (_n >= _jars ? 'max saving unlocked 🎉' : '${pct.toStringAsFixed(0)}% off unlocked');
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          left: 0,
          top: 0,
          child: Text.rich(TextSpan(children: <InlineSpan>[
            TextSpan(text: '$_n of $_jars jars', style: const TextStyle(color: Colors.white)),
            TextSpan(text: ' · $sub', style: const TextStyle(color: _yellow)),
          ]), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        Positioned(left: 0, right: 0, top: 26, child: CustomPaint(size: const Size(354, 14), painter: _StringPainter())),
        for (int i = 0; i < _tiers.length; i++) _tierTag(i, _tiers.length),
      ],
    );
  }

  Widget _tierTag(int i, int count) {
    final ComboTier t = _tiers[i];
    final bool on = _n >= t.jars;
    final double sw = i < _swing.length ? _swing[i].value : 0.0;
    final double ang = sw == 0 ? 0.0 : math.sin(sw * math.pi * 3) * 0.25 * (1 - sw);
    final List<Color> cols = _tierCols[i % _tierCols.length];
    final double x = count == 1 ? 0.5 : 0.18 + (0.64 * i / (count - 1));
    return Positioned(
      left: 354 * x - 39,
      top: 30,
      child: Transform.rotate(
        angle: ang,
        alignment: const Alignment(0, -1.3),
        child: Column(
          children: <Widget>[
            Container(width: 2, height: 9, color: Colors.white.withOpacity(0.7)),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 78,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8), bottom: Radius.circular(10)),
                color: on ? null : Colors.white.withOpacity(0.18),
                gradient: on ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: cols) : null,
                border: Border.all(color: on ? Colors.white : Colors.white.withOpacity(0.6), width: on ? 2 : 1),
                boxShadow: on ? <BoxShadow>[BoxShadow(color: cols[1].withOpacity(0.8), blurRadius: 16, offset: const Offset(0, 8), spreadRadius: -6)] : null,
              ),
              child: Column(children: <Widget>[
                Text('${t.percent % 1 == 0 ? t.percent.toInt() : t.percent}%', style: GoogleFonts.rozhaOne(fontSize: 16, height: 1.1, color: on && i % _tierCols.length == 2 ? const Color(0xFF7A2A00) : Colors.white.withOpacity(on ? 1.0 : 0.85))),
                Text('${t.jars} JARS', style: GoogleFonts.poppins(fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: on && i % _tierCols.length == 2 ? const Color(0xFF8A3A00) : Colors.white.withOpacity(on ? 1.0 : 0.85))),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // ───────── product cards ─────────
  Widget _grid() {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 14, bottom: 12),
      clipBehavior: Clip.none,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 14, crossAxisSpacing: 9, mainAxisExtent: 112),
      itemCount: _products.length,
      itemBuilder: (BuildContext c, int i) => _card(_products[i]),
    );
  }

  Widget _card(ComboProduct p) {
    final GlobalKey key = _cardImgKeys.putIfAbsent(p.id, () => GlobalKey());
    final bool sel = _slots.contains(p.id);
    final ComboPrice? pr = p.prices[_sz];
    final bool unavailable = pr == null || !pr.inStock;
    final bool off = unavailable || (_n >= _jars && !sel);
    return GestureDetector(
      onTap: () => _pick(p),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: off ? 0.45 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[p.c1, p.c2]),
            boxShadow: <BoxShadow>[
              if (sel) const BoxShadow(color: Colors.white, spreadRadius: 3),
              if (sel) BoxShadow(color: _yellow.withOpacity(0.9), spreadRadius: 6),
              const BoxShadow(color: Color(0x993C0028), blurRadius: 22, offset: Offset(0, 12), spreadRadius: -12),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: <Widget>[
              Positioned(top: -6, child: Container(width: 70, height: 70, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.35)))),
              Positioned(top: -10, child: SizedBox(key: key, width: 82, height: 64, child: Opacity(opacity: (_flight != null && _flight!.image == p.image && !sel) ? 0.0 : 1.0, child: _img(p.image, 82, 64)))),
              Positioned(
                right: 7,
                top: 7,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: sel ? _yellow : Colors.white, borderRadius: BorderRadius.circular(9)),
                  child: Text(sel ? '✓' : '+', style: TextStyle(fontSize: sel ? 12 : 15, fontWeight: FontWeight.w800, color: sel ? const Color(0xFF7A2A00) : const Color(0xFFE0234E))),
                ),
              ),
              Positioned(
                left: 4,
                right: 4,
                top: 56,
                child: Column(children: <Widget>[
                  Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white, shadows: const <Shadow>[Shadow(color: Color(0x40000000), blurRadius: 3, offset: Offset(0, 1))])),
                  const SizedBox(height: 2),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget w, Animation<double> a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero).animate(a), child: w)),
                    child: Container(
                      key: ValueKey<String>('${p.id}-$_sz'),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Text(pr == null ? '—' : _rs(pr.price), style: GoogleFonts.rozhaOne(fontSize: 14, height: 1.25, color: _ink)),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(unavailable ? (pr == null ? 'not in $_sz' : 'out of stock') : '$_sz jar', style: GoogleFonts.poppins(fontSize: 8.5, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.9))),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _flyingJar() {
    final _Flight f = _flight!;
    final double t = Curves.easeInOut.transform(_fly.value);
    final double arc = math.sin(t * math.pi);
    final Offset pos = Offset.lerp(f.from, f.to, t)! + Offset(0, -f.up * arc);
    return Positioned(
      left: pos.dx - 46,
      top: pos.dy - 36,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: -0.24 * arc,
          child: Transform.scale(scale: 1 + 0.3 * arc, child: _img(f.image, 92, 72)),
        ),
      ),
    );
  }

  // ───────── bottom bar (real layout, always at the bottom) ─────────
  Widget _bottomBar(double safe) {
    final bool ready = _n >= _jars && _sealed;
    final double total = _sum - _off;
    return AnimatedBuilder(
      animation: _loop,
      builder: (BuildContext c, Widget? child) {
        final double pulse = ready ? 1 + 0.03 * math.sin(_loop.value * math.pi * 2) : 1.0;
        return Container(
          padding: EdgeInsets.fromLTRB(18, 14, 18, 14 + safe),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: <BoxShadow>[BoxShadow(color: Color(0x666E280A), blurRadius: 24, offset: Offset(0, -10), spreadRadius: -14)],
          ),
          child: Row(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: <Widget>[
                    Text(_rs(total), style: GoogleFonts.rozhaOne(fontSize: 26, height: 1.0, color: _ink)),
                    if (_off > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 6, bottom: 2),
                        child: Text(_rs(_sum), style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFB09A88), decoration: TextDecoration.lineThrough, decorationColor: const Color(0xFFB09A88))),
                      ),
                  ]),
                  const SizedBox(height: 2),
                  Text(_off > 0 ? 'You save ${_rs(_off)}' : ' ', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF17A35B))),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: GestureDetector(
                  onTap: ready ? _addToCart : null,
                  child: Transform.scale(
                    scale: pulse,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        color: ready ? null : const Color(0xFFF6ECE0),
                        gradient: ready ? const LinearGradient(colors: <Color>[Color(0xFFFF7A2F), Color(0xFFFF2D87)]) : null,
                        boxShadow: ready ? const <BoxShadow>[BoxShadow(color: Color(0xCCFF2D87), blurRadius: 24, offset: Offset(0, 12), spreadRadius: -10)] : null,
                      ),
                      child: _adding
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Text(
                              _n < _jars ? 'Pick ${_jars - _n} more jar${_jars - _n > 1 ? 's' : ''}' : (ready ? 'Add $_sz box · ${_rs(total)}' : 'Packing your box…'),
                              style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w800, color: ready ? Colors.white : const Color(0xFFB09A88)),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _img(String url, double w, double h) {
    if (url.isEmpty) return SizedBox(width: w, height: h);
    return Image.network(url, width: w, height: h, fit: BoxFit.contain, gaplessPlayback: true, errorBuilder: (BuildContext c, Object e, StackTrace? s) => SizedBox(width: w, height: h));
  }
}

// ───────────────────────────── painters & pieces ─────────────────────────────
class _Background extends StatelessWidget {
  const _Background();
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.4, -1),
          end: Alignment(0.4, 1),
          colors: <Color>[Color(0xFFFFB03A), Color(0xFFFF6A3D), Color(0xFFF2386B), Color(0xFFA42BB8)],
          stops: <double>[0.0, 0.3, 0.62, 1.0],
        ),
      ),
      child: Stack(children: <Widget>[
        Positioned(left: -60, top: 40, child: _blob(260, const Color(0x47FFFFFF))),
        Positioned(right: -80, top: 260, child: _blob(300, const Color(0x47FFE678))),
        Positioned(left: -90, bottom: 80, child: _blob(320, const Color(0x3878DCFF))),
        Positioned.fill(child: CustomPaint(painter: _DotsPainter(const Color(0x38FFFFFF), 26))),
      ]),
    );
  }

  static Widget _blob(double s, Color c) => Container(width: s, height: s * 0.75, decoration: BoxDecoration(gradient: RadialGradient(colors: <Color>[c, c.withOpacity(0)])));
}

class _DotsPainter extends CustomPainter {
  final Color color;
  final double gap;
  _DotsPainter(this.color, this.gap);
  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()..color = color;
    int row = 0;
    for (double y = 0; y < size.height; y += gap / 2) {
      final double off = row.isOdd ? gap / 2 : 0.0;
      for (double x = off; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1.2, p);
      }
      row++;
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter o) => o.color != color || o.gap != gap;
}

class _LeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint vein = Paint()
      ..color = const Color(0x12FFFFFF)
      ..strokeWidth = 1;
    for (double x = -size.height; x < size.width; x += 9) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height * 0.18, 0), vein);
    }
    canvas.drawLine(Offset(size.width / 2, 6), Offset(size.width / 2, size.height - 6), Paint()
      ..color = const Color(0x40DCFFC8)
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CornerPainter extends CustomPainter {
  final bool left;
  _CornerPainter(this.left);
  @override
  void paint(Canvas canvas, Size size) {
    final Path p = left
        ? (Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width, size.height * 0.3)
          ..lineTo(size.width * 0.4, size.height)
          ..lineTo(0, size.height)
          ..close())
        : (Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(size.width * 0.6, size.height)
          ..lineTo(0, size.height * 0.3)
          ..close());
    canvas.drawPath(p, Paint()..shader = const LinearGradient(colors: <Color>[Color(0xFFF7D58C), Color(0xFFC8913F), Color(0xFF8E5E1E)], stops: <double>[0.0, 0.6, 1.0]).createShader(Offset.zero & size));
  }

  @override
  bool shouldRepaint(covariant _CornerPainter o) => o.left != left;
}

class _StringPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Path p = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size.width / 2, size.height, size.width, 0);
    canvas.drawPath(p, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xB3FFFFFF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TrapClipper extends CustomClipper<Path> {
  final double inset;
  _TrapClipper(this.inset);
  @override
  Path getClip(Size s) => Path()
    ..moveTo(s.width * inset, 0)
    ..lineTo(s.width * (1 - inset), 0)
    ..lineTo(s.width, s.height)
    ..lineTo(0, s.height)
    ..close();
  @override
  bool shouldReclip(covariant _TrapClipper o) => o.inset != inset;
}

class _BurstPainter extends CustomPainter {
  final double k;
  final List<List<double>> sparks;
  _BurstPainter(this.k, this.sparks);
  static const List<Color> _cols = <Color>[Color(0xFFFFE3A0), Color(0xFFF2B33D), Colors.white, Color(0xFFD93448), Color(0xFF7FD39A)];
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(Offset.zero, 20 + 160 * k, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFFFE3A0).withOpacity(1 - k));
    final double e = const Cubic(0.1, 0.7, 0.3, 1.0).transform(k);
    for (final List<double> s in sparks) {
      canvas.save();
      canvas.translate(s[0] * e, s[1] * e);
      canvas.rotate(s[2] * e);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-3, -3, 6, 6), const Radius.circular(2)), Paint()..color = _cols[s[3].toInt()].withOpacity(1 - k));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter o) => o.k != k;
}
