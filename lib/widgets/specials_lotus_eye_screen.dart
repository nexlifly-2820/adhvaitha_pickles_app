// specials_lotus_eye_screen.dart — "Ambhujakshi Specials · Seen through the Lotus Eye" (matches specials_lotus_eye_v8.mp4)
// Intro (gold logo + lotus on water) → product page: the special sits inside the gold lotus-eye frame,
// eyelids open with a blink; swipe or tap "More specials" → the eye blinks to the next special.
// Weights, price, % off, Add to Cart → "Added to Cart" + quantity + Go to Cart.
// All content comes from the admin dashboard: specials_backend.js → GET /api/specials
//
// pubspec.yaml
//   dependencies:  http: ^1.2.0   google_fonts: ^6.2.1
//   flutter:
//     assets:
//       - assets/lotus_eye_frame.png
//       - assets/lotus_on_water.png
//
// Open it from your home "Ambhujakshi Specials" tiles:
//   Navigator.push(context, PageRouteBuilder(
//     transitionDuration: const Duration(milliseconds: 500),
//     pageBuilder: (_, __, ___) => SpecialsLotusEyeScreen(
//       apiBase: 'https://your-api.com/api',
//       initialId: tappedSpecial.id,             // or initialName: 'Karam Podi'
//       cartCount: CartService.instance.count,
//       onAdd: (SpecialItem item, SpecialVariant v, int qty) async {
//         await CartService.instance.add(item.productId, variantId: v.id, qty: qty);
//         return true;                             // return false if adding failed
//       },
//       onGoToCart: () => Navigator.pushNamed(context, '/cart'),
//     ),
//     transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
//   ));

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

const Color _goldLight = Color(0xFFFFF0C2);
const Color _gold = Color(0xFFF6DA9A);
const Color _goldDeep = Color(0xFFE9B44C);
const Color _cream = Color(0xFFFFF3DF);
const Color _creamSoft = Color(0xFFFBE3C2);
const Color _ink = Color(0xFF3A1A08);
const double _dw = 390.0, _dh = 754.0;

// Eye frame image is 1536 × 1024. Inner opening measured on that image:
const double _imgW = 1536.0, _imgH = 1024.0;
const double _cxL = 190.0, _cxR = 1346.0, _cy = 588.0, _ctrlTop = 247.0, _ctrlBot = 929.0, _ctrlX1 = 470.0, _ctrlX2 = 1066.0;

// ───────────── data ─────────────
class SpecialVariant {
  final String id, label;
  final double price, mrp;
  SpecialVariant(this.id, this.label, this.price, this.mrp);
}

class SpecialFeature {
  final String icon, text;
  SpecialFeature(this.icon, this.text);
}

class SpecialItem {
  final String id, productId, name, story, image;
  final List<SpecialFeature> features;
  final List<SpecialVariant> variants;
  final int defaultVariant;
  SpecialItem(this.id, this.productId, this.name, this.story, this.image, this.features, this.variants, this.defaultVariant);
}

double _n(dynamic v) => (v is num) ? v.toDouble() : (double.tryParse('$v') ?? 0.0);
String _rs(double v) => '₹${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(2)}';

IconData _icon(String k) {
  switch (k) {
    case 'recipe':
      return Icons.soup_kitchen_outlined;
    case 'leaf':
      return Icons.eco_outlined;
    case 'jar':
      return Icons.inventory_2_outlined;
    case 'sun':
      return Icons.wb_sunny_outlined;
    case 'fire':
      return Icons.local_fire_department_outlined;
    case 'hand':
      return Icons.back_hand_outlined;
    case 'ghee':
      return Icons.water_drop_outlined;
    case 'heart':
      return Icons.favorite_border_rounded;
    case 'truck':
      return Icons.local_shipping_outlined;
    default:
      return Icons.star_border_rounded;
  }
}

// ───────────── screen ─────────────
class SpecialsLotusEyeScreen extends StatefulWidget {
  final String apiBase;
  final Map<String, String>? headers;
  final String? initialId;
  final String? initialName;
  final int cartCount;
  final Future<bool> Function(SpecialItem item, SpecialVariant variant, int qty)? onAdd;
  final VoidCallback? onGoToCart;
  final String frameAsset, lotusAsset;
  const SpecialsLotusEyeScreen({
    super.key,
    required this.apiBase,
    this.headers,
    this.initialId,
    this.initialName,
    this.cartCount = 0,
    this.onAdd,
    this.onGoToCart,
    this.frameAsset = 'assets/images/lotus_eye_frame.png',
    this.lotusAsset = 'assets/images/lotus_on_water.png',
  });
  @override
  State<SpecialsLotusEyeScreen> createState() => _SpecialsLotusEyeScreenState();
}

class _SpecialsLotusEyeScreenState extends State<SpecialsLotusEyeScreen> with TickerProviderStateMixin {
  // settings
  String _title = 'AMBHUJAKSHI', _subtitle = 'SPECIALS', _tagline = 'Seen through the Lotus Eye', _tagText = "AMMA'S SPECIAL", _moreText = 'MORE SPECIALS';
  bool _showIntro = true;
  List<SpecialItem> _items = <SpecialItem>[];
  bool _loading = true;
  String? _error;

  // state
  int _cur = 0, _w = 0, _qty = 1, _cart = 0;
  final ScrollController _moreCtrl = ScrollController();
  bool _added = false, _adding = false, _blinking = false;

  // animation
  late AnimationController _intro; // 0..1 intro reveal
  late AnimationController _introOut; // fades intro away
  late AnimationController _lid; // 0 open .. 1 closed
  late AnimationController _loop; // shimmer / glow
  late AnimationController _pill; // "Added to Cart" pop
  late AnimationController _bowl; // bowl swap scale

  @override
  void initState() {
    super.initState();
    _cart = widget.cartCount;
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _introOut = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _lid = AnimationController(vsync: this, duration: const Duration(milliseconds: 300), value: 1.0);
    _loop = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _pill = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _bowl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300), value: 1.0);
    _load();
  }

  @override
  void dispose() {
    _intro.dispose();
    _introOut.dispose();
    _moreCtrl.dispose();
    _lid.dispose();
    _loop.dispose();
    _pill.dispose();
    _bowl.dispose();
    super.dispose();
  }

  String _abs(String u) {
    if (u.isEmpty || u.startsWith('http') || u.startsWith('assets/')) return u;
    final String origin = widget.apiBase.replaceAll(RegExp(r'/api/?$'), '');
    return u.startsWith('/') ? '$origin$u' : '$origin/$u';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final fallbackJson = <String, dynamic>{
      "settings": {"enabled": true, "title": "AMBHUJAKSHI", "subtitle": "SPECIALS", "tagline": "Seen through the Lotus Eye", "tagText": "AMMA'S SPECIAL", "moreText": "MORE SPECIALS", "showIntro": true},
      "items": [
        {
          "id": "gongura_pickle",
          "productId": "",
          "name": "Gongura Pickle",
          "image": "assets/images/special_gongura_pickle.png",
          "story": "Tangy sorrel leaves slow-cooked with garlic and Guntur chillies in sesame oil — the pride of Andhra.",
          "features": [
            {
              "icon": "leaf",
              "text": "Fresh gongura leaves"
            },
            {
              "icon": "jar",
              "text": "Cold-pressed sesame oil"
            },
            {
              "icon": "recipe",
              "text": "Amma's recipe"
            }
          ],
          "variants": [
            {
              "id": "250g",
              "label": "250g",
              "price": 189,
              "mrp": 220
            },
            {
              "id": "500g",
              "label": "500g",
              "price": 359,
              "mrp": 418
            },
            {
              "id": "1kg",
              "label": "1kg",
              "price": 680,
              "mrp": 792
            }
          ],
          "defaultVariant": 0,
          "enabled": true
        },
        {
          "id": "tomato_pickle",
          "productId": "",
          "name": "Tomato Pickle",
          "image": "assets/images/special_tomato_pickle.png",
          "story": "Ripe country tomatoes cooked down with mustard and red chilli until rich, glossy and tangy.",
          "features": [
            {
              "icon": "sun",
              "text": "Sun-ripened tomatoes"
            },
            {
              "icon": "fire",
              "text": "Slow cooked"
            },
            {
              "icon": "heart",
              "text": "No preservatives"
            }
          ],
          "variants": [
            {
              "id": "250g",
              "label": "250g",
              "price": 169,
              "mrp": 199
            },
            {
              "id": "500g",
              "label": "500g",
              "price": 321,
              "mrp": 378
            },
            {
              "id": "1kg",
              "label": "1kg",
              "price": 608,
              "mrp": 716
            }
          ],
          "defaultVariant": 0,
          "enabled": true
        },
        {
          "id": "kandi_podi",
          "productId": "",
          "name": "Kandi Podi",
          "image": "assets/images/special_kandi_podi.png",
          "story": "Roasted toor dal, chillies and cumin stone-ground into the classic hot-rice-and-ghee podi.",
          "features": [
            {
              "icon": "fire",
              "text": "Slow roasted"
            },
            {
              "icon": "ghee",
              "text": "Best with ghee"
            },
            {
              "icon": "hand",
              "text": "Stone ground"
            }
          ],
          "variants": [
            {
              "id": "250g",
              "label": "250g",
              "price": 149,
              "mrp": 175
            },
            {
              "id": "500g",
              "label": "500g",
              "price": 283,
              "mrp": 332
            },
            {
              "id": "1kg",
              "label": "1kg",
              "price": 536,
              "mrp": 630
            }
          ],
          "defaultVariant": 0,
          "enabled": true
        },
        {
          "id": "chekkalu",
          "productId": "",
          "name": "Chekkalu",
          "image": "assets/images/special_chekkalu.png",
          "story": "Crisp rice-flour crackers with chana dal, sesame and curry leaves — a Sankranti favourite.",
          "features": [
            {
              "icon": "hand",
              "text": "Hand-pressed"
            },
            {
              "icon": "leaf",
              "text": "Curry leaf & sesame"
            },
            {
              "icon": "heart",
              "text": "Tea-time crunch"
            }
          ],
          "variants": [
            {
              "id": "250g",
              "label": "250g",
              "price": 139,
              "mrp": 165
            },
            {
              "id": "500g",
              "label": "500g",
              "price": 264,
              "mrp": 314
            },
            {
              "id": "1kg",
              "label": "1kg",
              "price": 500,
              "mrp": 594
            }
          ],
          "defaultVariant": 0,
          "enabled": true
        },
        {
          "id": "ariselu",
          "productId": "",
          "name": "Ariselu",
          "image": "assets/images/special_ariselu.png",
          "story": "Soft jaggery-rice sweets fried golden and topped with sesame, made the traditional way.",
          "features": [
            {
              "icon": "ghee",
              "text": "Pure ghee"
            },
            {
              "icon": "recipe",
              "text": "Festival classic"
            },
            {
              "icon": "hand",
              "text": "Handmade"
            }
          ],
          "variants": [
            {
              "id": "250g",
              "label": "250g",
              "price": 229,
              "mrp": 260
            },
            {
              "id": "500g",
              "label": "500g",
              "price": 435,
              "mrp": 494
            },
            {
              "id": "1kg",
              "label": "1kg",
              "price": 824,
              "mrp": 936
            }
          ],
          "defaultVariant": 0,
          "enabled": true
        },
        {
          "id": "kaju_mixture",
          "productId": "",
          "name": "Kaju Mixture",
          "image": "assets/images/special_kaju_mixture.png",
          "story": "Crunchy sev, peanuts and whole cashews tossed with curry leaves and a gentle spice.",
          "features": [
            {
              "icon": "heart",
              "text": "Loaded with cashews"
            },
            {
              "icon": "leaf",
              "text": "Curry leaf tempered"
            },
            {
              "icon": "jar",
              "text": "Fresh every batch"
            }
          ],
          "variants": [
            {
              "id": "250g",
              "label": "250g",
              "price": 179,
              "mrp": 210
            },
            {
              "id": "500g",
              "label": "500g",
              "price": 340,
              "mrp": 399
            },
            {
              "id": "1kg",
              "label": "1kg",
              "price": 644,
              "mrp": 756
            }
          ],
          "defaultVariant": 0,
          "enabled": true
        }
      ]
    };

    bool first = true;
    void parseAndApply(Map<String, dynamic> j) {
      final Map<String, dynamic> s = (j['settings'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final List<SpecialItem> items = <SpecialItem>[];
      for (final dynamic raw in (j['items'] as List?) ?? <dynamic>[]) {
        final Map<String, dynamic> m = raw as Map<String, dynamic>;
        final List<SpecialFeature> fs = <SpecialFeature>[];
        for (final dynamic f in (m['features'] as List?) ?? <dynamic>[]) {
          final Map<String, dynamic> x = f as Map<String, dynamic>;
          fs.add(SpecialFeature('${x['icon'] ?? 'star'}', '${x['text'] ?? ''}'));
        }
        final List<SpecialVariant> vs = <SpecialVariant>[];
        for (final dynamic v in (m['variants'] as List?) ?? <dynamic>[]) {
          final Map<String, dynamic> x = v as Map<String, dynamic>;
          vs.add(SpecialVariant('${x['id'] ?? ''}', '${x['label'] ?? ''}', _n(x['price']), _n(x['mrp'])));
        }
        if (vs.isEmpty) continue;
        items.add(SpecialItem('${m['id']}', '${m['productId'] ?? ''}', '${m['name'] ?? ''}', '${m['story'] ?? ''}', _abs('${m['image'] ?? ''}'), fs, vs,
            _n(m['defaultVariant']).round()));
      }
      if (!first && items.isEmpty) return;
      if (items.isNotEmpty && mounted) {
        int start = 0;
        final String keep = (!first && _items.isNotEmpty) ? _it.name.toLowerCase() : '';
        for (int i = 0; i < items.length; i++) {
          final it = items[i];
          final idMatch = widget.initialId != null && (it.id.toLowerCase() == widget.initialId!.toLowerCase() || it.productId.toLowerCase() == widget.initialId!.toLowerCase() || it.name.toLowerCase().contains(widget.initialId!.toLowerCase()) || widget.initialId!.toLowerCase().contains(it.name.toLowerCase()));
          final nameMatch = widget.initialName != null && (it.name.toLowerCase().contains(widget.initialName!.toLowerCase()) || widget.initialName!.toLowerCase().contains(it.name.toLowerCase()) || it.id.toLowerCase().contains(widget.initialName!.toLowerCase()) ||
              (widget.initialName!.toLowerCase().contains('karam') && it.name.toLowerCase().contains('karam')) ||
              (widget.initialName!.toLowerCase().contains('murukku') && it.name.toLowerCase().contains('murukku')) ||
              (widget.initialName!.toLowerCase().contains('sunnunda') && it.name.toLowerCase().contains('sunnunda')) ||
              (widget.initialName!.toLowerCase().contains('mixture') && it.name.toLowerCase().contains('mixture')) ||
              (widget.initialName!.toLowerCase().contains('chips') && it.name.toLowerCase().contains('chips')) ||
              (widget.initialName!.toLowerCase().contains('avakaya') && it.name.toLowerCase().contains('avakaya')));
          final bool keepMatch = keep.isNotEmpty && it.name.toLowerCase() == keep;
          if (keep.isNotEmpty ? keepMatch : (idMatch || nameMatch)) {
            start = i;
            break;
          }
        }
        setState(() {
          _title = '${s['title'] ?? _title}';
          _subtitle = '${s['subtitle'] ?? _subtitle}';
          _tagline = '${s['tagline'] ?? _tagline}';
          _tagText = '${s['tagText'] ?? _tagText}';
          _moreText = '${s['moreText'] ?? _moreText}';
          _showIntro = s['showIntro'] != false;
          _items = items;
          _loading = false;
          _error = null;
        });
        _select(start, animate: false);
        if (first) _runIntro();
        first = false;
      }
    }

    parseAndApply(fallbackJson);

    // what the admin saved for Ambhujakshi Specials (tiles + details in one place)
    try {
      final Map<String, dynamic> cfg = await ApiService.getAppConfig('specials_light');
      if (!mounted) return;
      final List<dynamic> list = (cfg['list'] as List?) ?? <dynamic>[];
      final List<dynamic> ready = list.where((dynamic e) => e is Map && e['enabled'] != false && (e['variants'] as List? ?? <dynamic>[]).isNotEmpty).toList();
      if (ready.isNotEmpty) {
        final Map<String, dynamic> st = (cfg['settings'] is Map) ? Map<String, dynamic>.from(cfg['settings'] as Map) : <String, dynamic>{};
        parseAndApply(<String, dynamic>{'settings': st, 'items': ready.map((dynamic e) => Map<String, dynamic>.from(e as Map)).toList()});
        return;
      }
    } catch (_) {}

    // Old /specials server data is no longer used — the admin "Ambhujakshi Specials" tab is the only source.
  }

  Future<void> _runIntro() async {
    if (_showIntro) {
      await _intro.forward(from: 0);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      await _introOut.forward(from: 0);
    } else {
      _intro.value = 1;
      _introOut.value = 1;
    }
    if (!mounted) return;
    // eye wakes up: half open, small blink, fully open
    await _lid.animateTo(0.55, duration: const Duration(milliseconds: 700), curve: Curves.easeInOutCubic);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    await _lid.animateTo(0.9, duration: const Duration(milliseconds: 160), curve: Curves.easeInCubic);
    if (!mounted) return;
    await _lid.animateTo(0.0, duration: const Duration(milliseconds: 650), curve: Curves.easeOutCubic);
  }

  SpecialItem get _it => _items[_cur];
  SpecialVariant get _v => _it.variants[math.max(0, math.min(_w, _it.variants.length - 1))];

  void _select(int i, {bool animate = true}) {
    setState(() {
      _cur = i;
      _w = math.max(0, math.min(_items[i].defaultVariant, _items[i].variants.length - 1));
      _qty = 1;
      _added = false;
    });
    _pill.value = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_moreCtrl.hasClients) return;
      const double card = 96.0, gap = 10.0;
      final double target = (16 + i * (card + gap) + card / 2 - _moreCtrl.position.viewportDimension / 2).clamp(0.0, _moreCtrl.position.maxScrollExtent);
      _moreCtrl.animateTo(target, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    });
  }

  Future<void> _blinkTo(int i) async {
    if (_blinking || i == _cur || _items.isEmpty) return;
    _blinking = true;
    HapticFeedback.selectionClick();
    _bowl.animateTo(0.0, duration: const Duration(milliseconds: 170), curve: Curves.easeIn);
    await _lid.animateTo(1.0, duration: const Duration(milliseconds: 170), curve: Curves.easeInCubic);
    if (!mounted) return;
    _select(i);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    if (!mounted) return;
    _bowl.animateTo(1.0, duration: const Duration(milliseconds: 320), curve: Curves.easeOutBack);
    await _lid.animateTo(0.0, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    _blinking = false;
  }

  Future<void> _add() async {
    if (_adding) return;
    setState(() => _adding = true);
    bool ok = true;
    if (widget.onAdd != null) ok = await widget.onAdd!(_it, _v, _qty);
    if (!mounted) return;
    setState(() {
      _adding = false;
      if (ok) {
        _added = true;
        _cart += _qty;
      }
    });
    if (ok) {
      HapticFeedback.mediumImpact();
      _pill.forward(from: 0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not add to cart. Please try again.')));
    }
  }

  void _changeQty(int d) {
    final int q = math.max(1, math.min(20, _qty + d));
    if (q == _qty) return;
    HapticFeedback.selectionClick();
    final int diff = q - _qty;
    setState(() => _qty = q);
    if (_added && widget.onAdd != null) {
      // keep the cart in sync: add or remove the difference
      widget.onAdd!(_it, _v, diff).then((bool ok) {
        if (mounted && ok) setState(() => _cart = math.max(0, _cart + diff));
      });
    }
  }

  // ───────── build ─────────
  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF2A0612),
      body: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(center: Alignment(0, -0.25), radius: 1.0, colors: <Color>[Color(0xFF7A1E3A), Color(0xFF4E0F24), Color(0xFF2A0612)], stops: <double>[0.0, 0.5, 1.0]),
              ),
            ),
          ),
          if (_loading) const Center(child: CircularProgressIndicator(color: _gold)),
          if (!_loading && _error != null) _errorView(),
          if (!_loading && _error == null)
            Padding(
              padding: EdgeInsets.only(top: mq.padding.top, bottom: mq.padding.bottom),
              child: Column(children: <Widget>[
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(width: _dw, height: _dh, child: _page()),
                    ),
                  ),
                ),
                // full-width strip, edge to edge (outside the scaled page)
                if (_items.length > 1) SizedBox(height: 166, child: _more()),
              ]),
            ),
          if (!_loading && _error == null)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge(<Listenable>[_intro, _introOut]),
                builder: (BuildContext c, Widget? ch) {
                  if (_introOut.value >= 1.0) return const SizedBox.shrink();
                  return IgnorePointer(ignoring: _introOut.value > 0.5, child: Opacity(opacity: 1 - _introOut.value, child: _introView(mq)));
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: _cream, fontSize: 14)),
          const SizedBox(height: 12),
          TextButton(onPressed: _load, child: Text('Try again', style: GoogleFonts.poppins(color: _gold, fontWeight: FontWeight.w700))),
          TextButton(onPressed: () => Navigator.maybePop(context), child: Text('Go back', style: GoogleFonts.poppins(color: Colors.white70))),
        ]),
      ),
    );
  }

  Widget _goldText(String t, TextStyle st) {
    return AnimatedBuilder(
      animation: _loop,
      builder: (BuildContext c, Widget? ch) {
        final double p = _loop.value;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (Rect r) => LinearGradient(
            colors: const <Color>[Color(0xFFB07E2E), _gold, Color(0xFFFFF6D8), Color(0xFFE9C47A), Color(0xFFB07E2E)],
            stops: const <double>[0.0, 0.3, 0.45, 0.6, 1.0],
            begin: Alignment(-3 + 5 * p, 0),
            end: Alignment(-1 + 5 * p, 0),
          ).createShader(r),
          child: Text(t, textAlign: TextAlign.center, style: st.copyWith(color: Colors.white)),
        );
      },
    );
  }

  Widget _emblem(double w) => SizedBox(width: w, height: w * 0.46, child: const CustomPaint(painter: _EmblemPainter()));

  // ───────── intro ─────────
  Widget _introView(MediaQueryData mq) {
    final double t = _intro.value;
    double step(double a, double b) => Curves.easeOut.transform(((t - a) / (b - a)).clamp(0.0, 1.0));
    Widget rise(double a, Widget w) => Opacity(opacity: step(a, a + 0.35), child: Transform.translate(offset: Offset(0, 14 * (1 - step(a, a + 0.35))), child: w));
    final double lotus = Curves.easeOutCubic.transform(step(0.0, 0.7));
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(center: Alignment(0, -0.4), radius: 0.9, colors: <Color>[Color(0xFF6E1A34), Color(0xFF3E0B1C), Color(0xFF22050E)], stops: <double>[0.0, 0.6, 1.0]),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Opacity(
              opacity: lotus,
              child: Transform.translate(
                offset: Offset(0, 60 * (1 - lotus)),
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (Rect r) => const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Colors.transparent, Colors.black], stops: <double>[0.0, 0.3]).createShader(r),
                  child: Image.asset(widget.lotusAsset, width: mq.size.width * 1.1, fit: BoxFit.fitWidth, errorBuilder: (BuildContext c, Object e, StackTrace? s) => const SizedBox()),
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.42),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                rise(0.05, _emblem(150)),
                const SizedBox(height: 6),
                // title: centred, one word per line, never runs off the edge
                rise(0.2, Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: _goldText(_title.trim().replaceAll(RegExp(r'\s+'), '\n'),
                      GoogleFonts.cinzel(fontSize: 40, height: 1.12, fontWeight: FontWeight.w700, letterSpacing: 2)),
                )),
                const SizedBox(height: 10),
                // subtitle: centred on one line, shrinks on small phones
                rise(0.32, Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('— $_subtitle —', maxLines: 1, textAlign: TextAlign.center,
                        style: GoogleFonts.cinzel(fontSize: 15, letterSpacing: 4, color: _gold, fontWeight: FontWeight.w700)),
                  ),
                )),
                const SizedBox(height: 16),
                rise(0.42, _ornament()),
                const SizedBox(height: 12),
                rise(0.5, Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Text(_tagline.replaceFirst(' the ', '\nthe '), textAlign: TextAlign.center, style: GoogleFonts.kalam(fontSize: 22, height: 1.35, fontWeight: FontWeight.w700, color: _gold)),
                )),
                const SizedBox(height: 12),
                rise(0.6, _ornament()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ornament() => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(width: 60, height: 1, decoration: const BoxDecoration(gradient: LinearGradient(colors: <Color>[Colors.transparent, _gold]))),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('◆', style: TextStyle(color: _gold, fontSize: 9))),
          Container(width: 60, height: 1, decoration: const BoxDecoration(gradient: LinearGradient(colors: <Color>[_gold, Colors.transparent]))),
        ],
      );

  // ───────── product page (390 × 844 design) ─────────
  Widget _page() {
    final SpecialItem it = _it;
    final SpecialVariant v = _v;
    final int off = v.mrp > v.price ? ((1 - v.price / v.mrp) * 100).round() : 0;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        // top bar
        Positioned(
          left: 16,
          right: 16,
          top: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Color(0xFFFFEDB5), _goldDeep]),
                    boxShadow: <BoxShadow>[BoxShadow(color: Color(0x88000000), blurRadius: 10, offset: Offset(0, 4)), BoxShadow(color: Color(0x55E9B44C), blurRadius: 14, spreadRadius: 1)],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF5A0E1C), size: 19),
                ),
              ),
              GestureDetector(
                onTap: widget.onGoToCart,
                child: Stack(clipBehavior: Clip.none, children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Color(0xFFFFEDB5), _goldDeep]),
                    boxShadow: <BoxShadow>[BoxShadow(color: Color(0x88000000), blurRadius: 10, offset: Offset(0, 4)), BoxShadow(color: Color(0x55E9B44C), blurRadius: 14, spreadRadius: 1)],
                  ),
                    child: const Icon(Icons.shopping_cart_rounded, color: Color(0xFF5A0E1C), size: 21),
                  ),
                  if (_cart > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        height: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: const Color(0xFFE8302A), borderRadius: BorderRadius.circular(9)),
                        child: Text('$_cart', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                ]),
              ),
            ],
          ),
        ),
        // header
        Positioned(
          left: 16,
          right: 16,
          top: 58,
          child: Column(children: <Widget>[
            FittedBox(
              fit: BoxFit.scaleDown,
              child: _goldText(_title, GoogleFonts.cinzel(fontSize: 27, fontWeight: FontWeight.w700, height: 1.0)),
            ),
            const SizedBox(height: 4),
            const SizedBox(height: 4),
            // subtitle shown in full (shrinks to fit), with short gold lines
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Container(width: 28, height: 1.2, decoration: const BoxDecoration(gradient: LinearGradient(colors: <Color>[Colors.transparent, _gold]))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(_subtitle, maxLines: 1, style: GoogleFonts.cinzel(fontSize: 12, letterSpacing: 3, color: _gold, fontWeight: FontWeight.w700)),
                ),
                Container(width: 28, height: 1.2, decoration: const BoxDecoration(gradient: LinearGradient(colors: <Color>[_gold, Colors.transparent]))),
              ]),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(_tagline, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: GoogleFonts.kalam(fontSize: 13.5, height: 1.25, fontWeight: FontWeight.w700, color: _creamSoft)),
            ),
          ]),
        ),
        // the eye
        Positioned(
          left: -10,
          top: 152,
          width: 410,
          height: 410 * _imgH / _imgW,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (DragEndDetails d) {
              final double vx = d.primaryVelocity ?? 0.0;
              if (vx.abs() < 150 || _items.length < 2) return;
              _blinkTo(vx < 0 ? (_cur + 1) % _items.length : (_cur - 1 + _items.length) % _items.length);
            },
            child: _eye(it),
          ),
        ),
        // ‹ › arrows to move between specials
        if (_items.length > 1) ...<Widget>[
          Positioned(left: 10, top: 372, child: _arrow(Icons.chevron_left_rounded, () => _blinkTo((_cur - 1 + _items.length) % _items.length))),
          Positioned(right: 10, top: 372, child: _arrow(Icons.chevron_right_rounded, () => _blinkTo((_cur + 1) % _items.length))),
        ],
        // info
        Positioned(
          left: 20,
          right: 20,
          top: 412,
          child: Column(children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Color(0xFFFFE9AE), _goldDeep])),
              child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Text(_tagText, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: _ink)),
                if (_items.length > 1) ...<Widget>[
                  const SizedBox(width: 8),
                  for (int d = 0; d < _items.length; d++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      width: d == _cur ? 14 : 5,
                      height: 5,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: d == _cur ? _ink : const Color(0x663A1A08)),
                    ),
                ],
              ]),
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget w, Animation<double> a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(a), child: w)),
              child: Column(
                key: ValueKey<String>(it.id),
                children: <Widget>[
                  FittedBox(fit: BoxFit.scaleDown, child: Text(it.name, maxLines: 1, style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w700, color: _cream, height: 1.15))),
                  Text(it.story, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: GoogleFonts.kalam(fontSize: 14, fontWeight: FontWeight.w700, color: _creamSoft)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 56,
              child: Stack(alignment: Alignment.center, children: <Widget>[
                AnimatedOpacity(duration: const Duration(milliseconds: 300), opacity: _added ? 0.0 : 1.0, child: _features(it)),
                AnimatedBuilder(
                  animation: _pill,
                  builder: (BuildContext c, Widget? ch) {
                    final double p = Curves.easeOutBack.transform(_pill.value);
                    if (_pill.value == 0) return const SizedBox.shrink();
                    return Transform.scale(scale: 0.6 + 0.4 * p, child: Opacity(opacity: _pill.value.clamp(0.0, 1.0), child: ch));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Color(0xFF2FA14E), Color(0xFF17702F)]),
                      border: Border.all(color: const Color(0x80A0F0AA), width: 1.5),
                      boxShadow: const <BoxShadow>[BoxShadow(color: Color(0xCC1E8C3C), blurRadius: 24, offset: Offset(0, 10), spreadRadius: -8)],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                      const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text('Added to Cart', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    ]),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (int k = 0; k < it.variants.length; k++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () {
                          if (k == _w) return;
                          HapticFeedback.selectionClick();
                          setState(() {
                            _w = k;
                            _added = false;
                            _qty = 1;
                          });
                          _pill.value = 0;
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 78,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: k == _w ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Color(0xFFFFE9AE), _goldDeep]) : null,
                            border: Border.all(color: k == _w ? Colors.transparent : const Color(0x8CF6DA9A), width: 1.5),
                            boxShadow: k == _w ? const <BoxShadow>[BoxShadow(color: Color(0xCCE9B44C), blurRadius: 16, offset: Offset(0, 6), spreadRadius: -6)] : null,
                          ),
                          child: Text(it.variants[k].label, style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: k == _w ? FontWeight.w700 : FontWeight.w600, color: k == _w ? _ink : _cream)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(_rs(v.price), key: ValueKey<String>('${it.id}-$_w'), style: GoogleFonts.playfairDisplay(fontSize: 27, fontWeight: FontWeight.w700, color: _cream)),
                  ),
                  if (v.mrp > v.price) ...<Widget>[
                    const SizedBox(width: 12),
                    Text(_rs(v.mrp), style: GoogleFonts.poppins(fontSize: 15, color: const Color(0xFFE6B8A8), decoration: TextDecoration.lineThrough, decorationColor: const Color(0xFFE6B8A8))),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFD8302A), borderRadius: BorderRadius.circular(5)),
                      child: Text('$off% OFF', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ],
                ],
              ),
            ),
          ]),
        ),
        // CTA
        Positioned(left: 24, right: 24, top: 690, height: 52, child: _cta()),
        // more specials
      ],
    );
  }

  Widget _features(SpecialItem it) {
    if (it.features.isEmpty) return const SizedBox.shrink();
    return Row(
      children: <Widget>[
        for (int k = 0; k < it.features.length; k++)
          Expanded(
            child: Container(
              decoration: BoxDecoration(border: k == 0 ? null : const Border(left: BorderSide(color: Color(0x4DF6DA9A)))),
              child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Icon(_icon(it.features[k].icon), color: _gold, size: 26),
                const SizedBox(height: 2),
                Text(it.features[k].text.replaceFirst(' ', '\n'), textAlign: TextAlign.center, maxLines: 2, style: GoogleFonts.poppins(fontSize: 10.5, height: 1.25, fontWeight: FontWeight.w600, color: _cream)),
              ]),
            ),
          ),
      ],
    );
  }

  Widget _goldButton(String label, IconData icon, VoidCallback? onTap, {bool busy = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[_goldLight, Color(0xFFF2C25E), Color(0xFFC9963F)], stops: <double>[0.0, 0.55, 1.0]),
          boxShadow: const <BoxShadow>[BoxShadow(color: Color(0xCCE9B44C), blurRadius: 26, offset: Offset(0, 12), spreadRadius: -10)],
        ),
        child: busy
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: _ink))
            : Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Icon(icon, color: _ink, size: 20),
                const SizedBox(width: 10),
                Text(label, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
              ]),
      ),
    );
  }

  Widget _cta() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: !_added
          ? SizedBox.expand(key: const ValueKey<String>('add'), child: _goldButton('Add to Cart', Icons.shopping_cart_outlined, _add, busy: _adding))
          : Row(
              key: const ValueKey<String>('after'),
              children: <Widget>[
                Container(
                  width: 120,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0x99F6DA9A), width: 1.5)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[
                    GestureDetector(onTap: () => _changeQty(-1), child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.remove_rounded, color: _cream, size: 20))),
                    Text('$_qty', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600, color: _cream)),
                    GestureDetector(onTap: () => _changeQty(1), child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.add_rounded, color: _cream, size: 20))),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(child: SizedBox(height: 52, child: _goldButton('Go to Cart', Icons.shopping_cart_outlined, widget.onGoToCart))),
              ],
            ),
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x40000000),
            border: Border.all(color: const Color(0xAAF6DA9A), width: 1.5),
            boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x55000000), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Icon(icon, color: _gold, size: 24),
        ),
      );

  // "Explore other specials" — cream strip with clear cards; current one is highlighted.
  Widget _more() {
    const Color maroon = Color(0xFF7A0F12);
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8EC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: <BoxShadow>[BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, -4))],
      ),
      padding: const EdgeInsets.only(top: 10),
      child: Column(children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: <Widget>[
            Expanded(child: Text(_moreText.toUpperCase() == 'MORE SPECIALS' ? 'Explore other specials' : _moreText, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF4A0B1D)))),
            Text('Tap to view ›', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF9A6A3A))),
          ]),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            controller: _moreCtrl,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (BuildContext c, int k) {
              final SpecialItem s = _items[k];
              final bool on = k == _cur;
              final SpecialVariant v0 = s.variants[math.max(0, math.min(s.defaultVariant, s.variants.length - 1))];
              return GestureDetector(
                onTap: () => _blinkTo(k),
                child: Stack(clipBehavior: Clip.none, children: <Widget>[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 96,
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                    decoration: BoxDecoration(
                      color: on ? const Color(0xFFFFF1D6) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: on ? const Color(0xFFC9963A) : const Color(0x14000000), width: on ? 2 : 1),
                      boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))],
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                      SizedBox(height: 44, width: 64, child: _img(s.image, BoxFit.contain)),
                      const SizedBox(height: 3),
                      SizedBox(
                        height: 26,
                        child: Center(child: Text(s.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 10.5, height: 1.15, fontWeight: FontWeight.w600, color: const Color(0xFF4A0B1D)))),
                      ),
                      Text(_rs(v0.price), style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: maroon)),
                    ]),
                  ),
                  if (on)
                    Positioned(
                      top: -7,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
                          decoration: BoxDecoration(color: maroon, borderRadius: BorderRadius.circular(10)),
                          child: Text('Viewing', style: GoogleFonts.poppins(fontSize: 8.5, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                    ),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _img(String u, BoxFit fit) {
    if (u.isEmpty) return const SizedBox();
    if (u.startsWith('assets/')) return Image.asset(u, fit: fit, gaplessPlayback: true, errorBuilder: (BuildContext c, Object e, StackTrace? s) => const SizedBox());
    return Image.network(u, fit: fit, gaplessPlayback: true, errorBuilder: (BuildContext c, Object e, StackTrace? s) => const SizedBox());
  }

  // The eye is drawn in the frame image's own pixel space (1536 × 1024) and scaled down,
  // so the eyelids and the bowl line up exactly with the gold ring.
  Widget _eye(SpecialItem it) {
    return FittedBox(
      fit: BoxFit.fill,
      child: SizedBox(
        width: _imgW,
        height: _imgH,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _loop,
                builder: (BuildContext c, Widget? ch) {
                  final double g = 1 + 0.12 * (0.5 - 0.5 * math.cos(_loop.value * math.pi * 4));
                  return ColorFiltered(colorFilter: ColorFilter.matrix(<double>[g, 0, 0, 0, 0, 0, g, 0, 0, 0, 0, 0, g, 0, 0, 0, 0, 0, 1, 0]), child: ch);
                },
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (Rect r) => const RadialGradient(center: Alignment(0, 0.04), radius: 0.62, colors: <Color>[Colors.black, Colors.black, Colors.transparent], stops: <double>[0.0, 0.7, 1.0]).createShader(r),
                  child: Image.asset(widget.frameAsset, fit: BoxFit.fill, errorBuilder: (BuildContext c, Object e, StackTrace? s) => const SizedBox()),
                ),
              ),
            ),
            Positioned.fill(
              child: ClipPath(
                clipper: _AlmondClipper(),
                child: Stack(
                  children: <Widget>[
                    const Positioned.fill(
                      child: DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(radius: 0.55, colors: <Color>[Color(0xFF7A1E36), Color(0xFF3A0A18)]))),
                    ),
                    Positioned(
                      left: 468,
                      top: 710,
                      width: 600,
                      height: 100,
                      child: Container(decoration: const BoxDecoration(gradient: RadialGradient(colors: <Color>[Color(0x59000000), Color(0x00000000)]))),
                    ),
                    Positioned(
                      left: 478,
                      top: 318,
                      width: 580,
                      height: 510,
                      child: AnimatedBuilder(
                        animation: _bowl,
                        builder: (BuildContext c, Widget? ch) => Opacity(opacity: _bowl.value.clamp(0.0, 1.0), child: Transform.scale(scale: 0.6 + 0.4 * _bowl.value, child: ch)),
                        child: KeyedSubtree(key: ValueKey<String>(it.image), child: _img(it.image, BoxFit.contain)),
                      ),
                    ),
                    Positioned.fill(child: AnimatedBuilder(animation: _lid, builder: (BuildContext c, Widget? ch) => CustomPaint(painter: _LidPainter(_lid.value)))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── painters ─────────────────────────────
Path _almond() => Path()
  ..moveTo(_cxL, _cy)
  ..cubicTo(_ctrlX1, _ctrlTop, _ctrlX2, _ctrlTop, _cxR, _cy)
  ..cubicTo(_ctrlX2, _ctrlBot, _ctrlX1, _ctrlBot, _cxL, _cy)
  ..close();

class _AlmondClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _almond();
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _LidPainter extends CustomPainter {
  final double t; // 0 open → 1 closed
  _LidPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0.001) return;
    const double meet = 640.0;
    final double uc = _ctrlTop + (meet + 40 - _ctrlTop) * t;
    final double lc = _ctrlBot - (_ctrlBot - (meet + 10)) * t;
    final Path upper = Path()
      ..moveTo(0, 0)
      ..lineTo(_imgW, 0)
      ..lineTo(_imgW, _cy)
      ..lineTo(_cxR, _cy)
      ..cubicTo(_ctrlX2, uc, _ctrlX1, uc, _cxL, _cy)
      ..lineTo(0, _cy)
      ..close();
    final Path lower = Path()
      ..moveTo(0, _imgH)
      ..lineTo(_imgW, _imgH)
      ..lineTo(_imgW, _cy)
      ..lineTo(_cxR, _cy)
      ..cubicTo(_ctrlX2, lc, _ctrlX1, lc, _cxL, _cy)
      ..lineTo(0, _cy)
      ..close();
    const Rect r = Rect.fromLTWH(0, 0, _imgW, _imgH);
    canvas.drawPath(upper, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment(0, 0.3), colors: <Color>[Color(0xFF2A0612), Color(0xFF6E1C34)]).createShader(r));
    canvas.drawPath(lower, Paint()..shader = const LinearGradient(begin: Alignment.bottomCenter, end: Alignment(0, 0.1), colors: <Color>[Color(0xFF2A0612), Color(0xFF5A1428)]).createShader(r));
    final Path ue = Path()
      ..moveTo(_cxL, _cy)
      ..cubicTo(_ctrlX1, uc, _ctrlX2, uc, _cxR, _cy);
    final Path le = Path()
      ..moveTo(_cxL, _cy)
      ..cubicTo(_ctrlX1, lc, _ctrlX2, lc, _cxR, _cy);
    canvas.drawPath(ue, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = const Color(0xE6F6DA9A));
    canvas.drawPath(le, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = const Color(0x8CF6DA9A));
  }

  @override
  bool shouldRepaint(covariant _LidPainter o) => o.t != t;
}

class _EmblemPainter extends CustomPainter {
  const _EmblemPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 96;
    canvas.scale(s, s);
    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(colors: <Color>[Color(0xFFB07E2E), Color(0xFFFFF0C2), Color(0xFFE9C47A), Color(0xFFB07E2E)], stops: <double>[0.0, 0.45, 0.6, 1.0]).createShader(const Rect.fromLTWH(0, 0, 96, 44));
    canvas.drawPath(Path()..moveTo(48, 4)..cubicTo(56, 12, 56, 26, 48, 36)..cubicTo(40, 26, 40, 12, 48, 4), p);
    canvas.drawPath(Path()..moveTo(48, 36)..cubicTo(52, 24, 60, 16, 70, 14)..cubicTo(69, 26, 60, 33, 48, 36), p);
    canvas.drawPath(Path()..moveTo(48, 36)..cubicTo(44, 24, 36, 16, 26, 14)..cubicTo(27, 26, 36, 33, 48, 36), p);
    canvas.drawPath(Path()..moveTo(48, 36)..cubicTo(58, 30, 72, 28, 82, 32)..cubicTo(74, 38, 60, 39, 48, 36), p);
    canvas.drawPath(Path()..moveTo(48, 36)..cubicTo(38, 30, 24, 28, 14, 32)..cubicTo(22, 38, 36, 39, 48, 36), p);
    canvas.drawLine(const Offset(8, 40), const Offset(40, 40), p);
    canvas.drawLine(const Offset(56, 40), const Offset(88, 40), p);
    canvas.drawCircle(const Offset(48, 40), 2, p..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
