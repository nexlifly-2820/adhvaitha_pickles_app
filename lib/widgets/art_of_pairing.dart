// art_of_pairing.dart — "The Art of Pairing" (matches art_of_pairing_explained.mp4)
//   • PairingHomeCard   → the compact card on the home page (couples change every few seconds, opens the full page)
//   • PairingScreen     → full-screen page: two product cards meet, heart + "Best with" meal, "Made for each other",
//                         weight toggle, View combo sheet, Add the couple → − In cart · n +, swipe / "More perfect couples".
// Everything comes from the admin dashboard: pairing_backend.js → GET /api/pairing
//
// pubspec.yaml:  http: ^1.2.0   google_fonts: ^6.2.1

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../cart_manager.dart';

const Color _maroon = Color(0xFF7A1426);
const Color _rose = Color(0xFFC2185B);
const Color _roseText = Color(0xFFA0506A);
const Color _gold = Color(0xFFC9963F);
const Color _goldLine = Color(0xFFEBCB8B);
const Color _ink = Color(0xFF2A1A14);
const Color _brown = Color(0xFF8A6A52);
const Color _bgA = Color(0xFFFFFFFF), _bgB = Color(0xFFFFF4EC), _bgC = Color(0xFFF9E3D6);

// ───────────── data ─────────────
class PairSide {
  final String productId, name, bio, image;
  final List<String> tags;
  PairSide(this.productId, this.name, this.bio, this.image, this.tags);
}

class PairWeight {
  final String label, aVariantId, bVariantId;
  final double price, mrp;
  PairWeight(this.label, this.price, this.mrp, this.aVariantId, this.bVariantId);
}

class PairCouple {
  final String id, name, tag, mealIcon, mealName, lovedText, tip;
  final PairSide a, b;
  final List<PairWeight> weights;
  PairCouple(this.id, this.name, this.tag, this.mealIcon, this.mealName, this.lovedText, this.a, this.b, this.weights, [this.tip = '']);
}

class PairSettings {
  String eyebrow = 'CURATED COMBOS', title = 'The Art of', titleAccent = 'Pairing', subtitle = "Amma's rishta — flavours made for each other";
  String explainText = '2 jars Amma pairs together · one combo price';
  String matchText = 'Made for each other', buttonText = "Meet Amma's perfect couples", moreText = 'MORE PERFECT COUPLES';
  bool enabled = true;
}

class PairingData {
  final PairSettings settings;
  final List<PairCouple> couples;
  PairingData(this.settings, this.couples);
}

typedef PairAdd = Future<bool> Function(PairCouple couple, PairWeight weight, int qtyChange);

double _n(dynamic v) => (v is num) ? v.toDouble() : (double.tryParse('$v') ?? 0.0);
String _rs(double v) => '₹${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(2)}';

String _abs(String apiBase, String u) {
  if (u.isEmpty || u.startsWith('http') || u.startsWith('assets/')) return u;
  final String origin = apiBase.replaceAll(RegExp(r'/api/?$'), '');
  return u.startsWith('/') ? '$origin$u' : '$origin/$u';
}

Future<PairingData?> _fetch(String apiBase, Map<String, String>? headers) async {
  List<PairCouple> remoteCs = [];
  PairSettings st = PairSettings();
  try {
    final http.Response r = await http.get(Uri.parse('$apiBase/pairing'), headers: headers).timeout(const Duration(seconds: 8));
    if (r.statusCode == 200 && !r.body.trim().startsWith('<!DOCTYPE') && !r.body.trim().startsWith('<html')) {
      final Map<String, dynamic> j = jsonDecode(r.body) as Map<String, dynamic>;
      final Map<String, dynamic> s = (j['settings'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      st = PairSettings()
        ..enabled = s['enabled'] != false
        ..eyebrow = '${s['eyebrow'] ?? 'CURATED COMBOS'}'
        ..title = '${s['title'] ?? 'The Art of'}'
        ..titleAccent = '${s['titleAccent'] ?? 'Pairing'}'
        ..subtitle = '${s['subtitle'] ?? "Amma's rishta — flavours made for each other"}'
        ..explainText = '${s['explainText'] ?? '2 jars Amma pairs together · one combo price'}'
        ..matchText = '${s['matchText'] ?? 'Made for each other'}'
        ..buttonText = '${s['buttonText'] ?? "Meet Amma's perfect couples"}'
        ..moreText = '${s['moreText'] ?? 'MORE PERFECT COUPLES'}';
      PairSide side(dynamic raw) {
        final Map<String, dynamic> m = (raw as Map<String, dynamic>?) ?? <String, dynamic>{};
        return PairSide('${m['productId'] ?? ''}', '${m['name'] ?? ''}', '${m['bio'] ?? ''}', _abs(apiBase, '${m['image'] ?? ''}'),
            ((m['tags'] as List?) ?? <dynamic>[]).map((dynamic e) => '$e').toList());
      }

      for (final dynamic raw in (j['couples'] as List?) ?? <dynamic>[]) {
        final Map<String, dynamic> m = raw as Map<String, dynamic>;
        final List<PairWeight> ws = <PairWeight>[];
        for (final dynamic w in (m['weights'] as List?) ?? <dynamic>[]) {
          final Map<String, dynamic> x = w as Map<String, dynamic>;
          ws.add(PairWeight('${x['label'] ?? ''}', _n(x['price']), _n(x['mrp']), '${x['aVariantId'] ?? ''}', '${x['bVariantId'] ?? ''}'));
        }
        if (ws.isEmpty || m['enabled'] == false) continue;
        remoteCs.add(PairCouple('${m['id']}', '${m['name'] ?? ''}', '${m['tag'] ?? ''}', '${m['mealIcon'] ?? ''}', '${m['mealName'] ?? ''}', '${m['lovedText'] ?? ''}',
            side(m['a']), side(m['b']), ws, '${m['tip'] ?? ''}'));
      }
    }
  } catch (_) {}

  // Local fallback: the 6 built-in couples (used only when the admin has saved nothing)
  final fallbackJson = <String, dynamic>{
    "couples": [
  {
    "id": "c1",
    "name": "Bellam Avakaya + Idli Karam Podi",
    "tag": "PICKLE & PODI",
    "mealIcon": "🌅",
    "mealName": "BREAKFAST",
    "lovedText": "Sweet & fiery",
    "tip": "Mix the podi with ghee, add a spoon of avakaya on the side of hot idlis.",
    "a": {
      "productId": "",
      "name": "Bellam Avakaya",
      "bio": "Raw mango in jaggery-chilli masala",
      "image": "assets/images/pair_bellam_avakaya.png",
      "tags": [
        "SWEET",
        "TANGY"
      ]
    },
    "b": {
      "productId": "",
      "name": "Idli Karam Podi",
      "bio": "Roasted urad dal & red chilli",
      "image": "assets/images/pair_idli_karam_podi.png",
      "tags": [
        "SPICY",
        "CRUNCHY"
      ]
    },
    "weights": [
      {
        "label": "250 g each",
        "price": 379,
        "mrp": 419,
        "aVariantId": "250g",
        "bVariantId": "250g"
      },
      {
        "label": "500 g each",
        "price": 701,
        "mrp": 775,
        "aVariantId": "500g",
        "bVariantId": "500g"
      }
    ]
  },
  {
    "id": "c2",
    "name": "Gongura Pickle + Karivepaku Podi",
    "tag": "ANDHRA CLASSICS",
    "mealIcon": "🍚",
    "mealName": "LUNCH",
    "lovedText": "The Andhra classic",
    "tip": "Hot rice, ghee, karivepaku podi first — gongura to finish.",
    "a": {
      "productId": "",
      "name": "Gongura Pickle",
      "bio": "Sorrel leaves, garlic & sesame oil",
      "image": "assets/images/pair_gongura_pickle.png",
      "tags": [
        "TANGY",
        "SPICY"
      ]
    },
    "b": {
      "productId": "",
      "name": "Karivepaku Podi",
      "bio": "Curry-leaf spice powder",
      "image": "assets/images/pair_karivepaku_podi.png",
      "tags": [
        "HERBY",
        "AROMATIC"
      ]
    },
    "weights": [
      {
        "label": "250 g each",
        "price": 349,
        "mrp": 399,
        "aVariantId": "250g",
        "bVariantId": "250g"
      },
      {
        "label": "500 g each",
        "price": 646,
        "mrp": 738,
        "aVariantId": "500g",
        "bVariantId": "500g"
      }
    ]
  },
  {
    "id": "c3",
    "name": "Kara Murukku + Sunnunda Laddu",
    "tag": "SNACK & SWEET",
    "mealIcon": "☕",
    "mealName": "EVENING TEA",
    "lovedText": "The ultimate tea-time combo",
    "tip": "Crunchy murukku with chai, sunnunda to finish.",
    "a": {
      "productId": "",
      "name": "Kara Murukku",
      "bio": "Crispy spiral festive snack",
      "image": "assets/images/pair_kara_murukku.png",
      "tags": [
        "CRISPY",
        "SPICY"
      ]
    },
    "b": {
      "productId": "",
      "name": "Sunnunda Laddu",
      "bio": "Roasted urad dal & pure ghee",
      "image": "assets/images/pair_sunnunda_laddu.png",
      "tags": [
        "PURE GHEE",
        "TRADITIONAL"
      ]
    },
    "weights": [
      {
        "label": "250 g each",
        "price": 319,
        "mrp": 395,
        "aVariantId": "250g",
        "bVariantId": "250g"
      },
      {
        "label": "500 g each",
        "price": 590,
        "mrp": 731,
        "aVariantId": "500g",
        "bVariantId": "500g"
      }
    ]
  },
  {
    "id": "c4",
    "name": "Allam Velluli Pickle + Munagaku Podi",
    "tag": "HEALTHY HEAT",
    "mealIcon": "🍛",
    "mealName": "LUNCH",
    "lovedText": "Good for you, full of flavour",
    "tip": "Moringa podi with rice and ghee, ginger-garlic pickle on the side.",
    "a": {
      "productId": "",
      "name": "Allam Velluli Pickle",
      "bio": "Ginger & garlic in chilli oil",
      "image": "assets/images/pair_allam_velluli_pickle.png",
      "tags": [
        "ZESTY",
        "SPICY"
      ]
    },
    "b": {
      "productId": "",
      "name": "Munagaku Podi",
      "bio": "Moringa-leaf spice powder",
      "image": "assets/images/pair_munagaku_podi.png",
      "tags": [
        "HEALTHY",
        "IRON-RICH"
      ]
    },
    "weights": [
      {
        "label": "250 g each",
        "price": 369,
        "mrp": 419,
        "aVariantId": "250g",
        "bVariantId": "250g"
      },
      {
        "label": "500 g each",
        "price": 683,
        "mrp": 775,
        "aVariantId": "500g",
        "bVariantId": "500g"
      }
    ]
  },
  {
    "id": "c5",
    "name": "Chakinalu + Palli Patti",
    "tag": "FESTIVE PAIR",
    "mealIcon": "🪔",
    "mealName": "SANKRANTI",
    "lovedText": "A Sankranti tradition",
    "tip": "Share a box with family during the festival.",
    "a": {
      "productId": "",
      "name": "Chakinalu",
      "bio": "Rice-flour sesame spirals",
      "image": "assets/images/pair_chakinalu.png",
      "tags": [
        "CRISPY",
        "SESAME"
      ]
    },
    "b": {
      "productId": "",
      "name": "Palli Patti",
      "bio": "Peanut & jaggery chikki",
      "image": "assets/images/pair_palli_patti.png",
      "tags": [
        "SWEET",
        "CRUNCHY"
      ]
    },
    "weights": [
      {
        "label": "250 g each",
        "price": 299,
        "mrp": 349,
        "aVariantId": "250g",
        "bVariantId": "250g"
      },
      {
        "label": "500 g each",
        "price": 553,
        "mrp": 646,
        "aVariantId": "500g",
        "bVariantId": "500g"
      }
    ]
  },
  {
    "id": "c6",
    "name": "Lemon Pickle + Putnala Podi",
    "tag": "CURD-RICE PARTNERS",
    "mealIcon": "🥣",
    "mealName": "DINNER",
    "lovedText": "Light, tangy, comforting",
    "tip": "Perfect with curd rice on a hot evening.",
    "a": {
      "productId": "",
      "name": "Lemon Pickle",
      "bio": "Lemons in chilli masala",
      "image": "assets/images/pair_lemon_pickle.png",
      "tags": [
        "TANGY",
        "ZESTY"
      ]
    },
    "b": {
      "productId": "",
      "name": "Putnala Podi",
      "bio": "Roasted-gram spice powder",
      "image": "assets/images/pair_putnala_podi.png",
      "tags": [
        "MILD",
        "NUTTY"
      ]
    },
    "weights": [
      {
        "label": "250 g each",
        "price": 299,
        "mrp": 339,
        "aVariantId": "250g",
        "bVariantId": "250g"
      },
      {
        "label": "500 g each",
        "price": 553,
        "mrp": 627,
        "aVariantId": "500g",
        "bVariantId": "500g"
      }
    ]
  }
]
  };

  PairSide side(dynamic raw) {
    final Map<String, dynamic> m = (raw as Map<String, dynamic>?) ?? <String, dynamic>{};
    return PairSide('${m['productId'] ?? ''}', '${m['name'] ?? ''}', '${m['bio'] ?? ''}', _abs(apiBase, '${m['image'] ?? ''}'),
        ((m['tags'] as List?) ?? <dynamic>[]).map((dynamic e) => '$e').toList());
  }

  final List<PairCouple> fallbackCs = <PairCouple>[];
  for (final dynamic raw in (fallbackJson['couples'] as List?) ?? <dynamic>[]) {
    final Map<String, dynamic> m = raw as Map<String, dynamic>;
    final List<PairWeight> ws = <PairWeight>[];
    for (final dynamic w in (m['weights'] as List?) ?? <dynamic>[]) {
      final Map<String, dynamic> x = w as Map<String, dynamic>;
      ws.add(PairWeight('${x['label'] ?? ''}', _n(x['price']), _n(x['mrp']), '${x['aVariantId'] ?? ''}', '${x['bVariantId'] ?? ''}'));
    }
    if (ws.isEmpty) continue;
    fallbackCs.add(PairCouple('${m['id']}', '${m['name'] ?? ''}', '${m['tag'] ?? ''}', '${m['mealIcon'] ?? ''}', '${m['mealName'] ?? ''}', '${m['lovedText'] ?? ''}',
        side(m['a']), side(m['b']), ws, '${m['tip'] ?? ''}'));
  }

  final List<PairCouple> finalCs = remoteCs.isNotEmpty ? remoteCs : fallbackCs;

  return PairingData(st, finalCs);
}

Widget _bowl(String url, double w) {
  if (url.isEmpty) return SizedBox(width: w, height: w * 0.8);
  final Widget fallback = Image.asset(
    'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
    width: w,
    height: w * 0.8,
    fit: BoxFit.contain,
    errorBuilder: (_, __, ___) => SizedBox(width: w, height: w * 0.8),
  );
  if (url.startsWith('assets/')) {
    return Image.asset(url, width: w, height: w * 0.8, fit: BoxFit.contain, errorBuilder: (BuildContext c, Object e, StackTrace? s) => fallback);
  }
  return Image.network(url, width: w, height: w * 0.8, fit: BoxFit.contain, gaplessPlayback: true, errorBuilder: (BuildContext c, Object e, StackTrace? s) => fallback);
}

const BoxDecoration _bg = BoxDecoration(
  gradient: RadialGradient(center: Alignment(0, -0.15), radius: 0.95, colors: <Color>[_bgA, _bgB, _bgC], stops: <double>[0.0, 0.45, 1.0]),
);

Widget _title(PairSettings s, double size) => Text.rich(
      TextSpan(children: <InlineSpan>[
        TextSpan(text: '${s.title} ', style: GoogleFonts.playfairDisplay(fontSize: size, fontWeight: FontWeight.w700, color: _maroon)),
        TextSpan(text: s.titleAccent, style: GoogleFonts.greatVibes(fontSize: size * 1.33, color: _gold)),
      ]),
      textAlign: TextAlign.center,
    );

class _Heart extends StatelessWidget {
  final double size;
  const _Heart(this.size);
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size * 0.94, child: const CustomPaint(painter: _HeartPainter()));
}

class _HeartPainter extends CustomPainter {
  const _HeartPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final double k = size.width / 64;
    canvas.scale(k, k);
    final Path outer = Path()
      ..moveTo(32, 56)
      ..cubicTo(14, 42, 2, 32, 2, 18)
      ..cubicTo(2, 9, 9, 2, 18, 2)
      ..cubicTo(24, 2, 29, 5, 32, 10)
      ..cubicTo(35, 5, 40, 2, 46, 2)
      ..cubicTo(55, 2, 62, 9, 62, 18)
      ..cubicTo(62, 32, 50, 42, 32, 56)
      ..close();
    canvas.drawShadow(outer, const Color(0x66C2185B), 4, false);
    canvas.drawPath(outer, Paint()..color = Colors.white);
    canvas.drawPath(outer, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = _gold);
    final Path inner = Path()
      ..moveTo(32, 46)
      ..cubicTo(20, 37, 12, 30, 12, 21)
      ..cubicTo(12, 16, 16, 12, 21, 12)
      ..cubicTo(25, 12, 29, 14, 32, 18)
      ..cubicTo(35, 14, 39, 12, 43, 12)
      ..cubicTo(48, 12, 52, 16, 52, 21)
      ..cubicTo(52, 30, 44, 37, 32, 46)
      ..close();
    canvas.drawPath(inner, Paint()..color = const Color(0xFFD6336C));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═════════════════════════════ HOME CARD ═════════════════════════════
class PairingHomeCard extends StatefulWidget {
  final String apiBase;
  final Map<String, String>? headers;
  final PairAdd? onAddCouple;
  final void Function(PairCouple couple, PairWeight weight)? onViewCombo;
  final VoidCallback? onCart;
  const PairingHomeCard({super.key, required this.apiBase, this.headers, this.onAddCouple, this.onViewCombo, this.onCart});
  @override
  State<PairingHomeCard> createState() => _PairingHomeCardState();
}

class _PairingHomeCardState extends State<PairingHomeCard> with SingleTickerProviderStateMixin {
  PairingData? _data;
  int _i = 0;
  int _dir = 1; // 1 = next (slides in from the right), -1 = previous
  Timer? _timer;
  late AnimationController _beat;

  @override
  void initState() {
    super.initState();
    _beat = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _beat.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final PairingData? d = await _fetch(widget.apiBase, widget.headers);
      if (!mounted || d == null) return;
      setState(() => _data = d);
      // no auto-change: the couple only changes when the customer taps an arrow or swipes
    } catch (_) {}
  }

  void _step(int dir) {
    final PairingData? d = _data;
    if (d == null || d.couples.length < 2) return;
    HapticFeedback.selectionClick();
    setState(() {
      _dir = dir;
      _i = (_i + dir + d.couples.length) % d.couples.length;
    });
  }

  Widget _arrow(IconData icon, VoidCallback onTap) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0x8CC9963F), width: 1.2),
            boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: Icon(icon, size: 20, color: _rose),
        ),
      );

  void _open() {
    final PairingData? d = _data;
    if (d == null) return;
    HapticFeedback.selectionClick();
    Navigator.of(context).push(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (BuildContext c, Animation<double> a, Animation<double> b) =>
          PairingScreen(data: d, initialIndex: _i, onAddCouple: widget.onAddCouple, onViewCombo: widget.onViewCombo, onCart: widget.onCart),
      transitionsBuilder: (BuildContext c, Animation<double> a, Animation<double> b, Widget child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final PairingData? d = _data;
    if (d == null || !d.settings.enabled || d.couples.isEmpty) return const SizedBox.shrink();
    final PairCouple c = d.couples[_i % d.couples.length];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(d.settings.eyebrow, style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 3, color: _gold)),
          ),
          GestureDetector(
            onTap: _open,
            onHorizontalDragEnd: (DragEndDetails e) {
              final double v = e.primaryVelocity ?? 0;
              if (v.abs() > 150) _step(v < 0 ? 1 : -1);
            },
            child: LayoutBuilder(builder: (BuildContext ctx, BoxConstraints bc) {
              final double w = bc.maxWidth;
              return SizedBox(
                width: w,
                height: w * 378 / 366,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: SizedBox(
                    width: 366,
                    height: 378,
                    child: Container(
                      decoration: _bg.copyWith(
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: const Color(0x8CC9963F), width: 1.5),
                        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x807A1426), blurRadius: 36, offset: Offset(0, 20), spreadRadius: -22)],
                      ),
                      child: Stack(
                        children: <Widget>[
                          Positioned(
                            right: 14,
                            top: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: const Color(0xFFFDE8EC), borderRadius: BorderRadius.circular(10)),
                              child: Text(d.couples.length > 1 ? '${_i % d.couples.length + 1} of ${d.couples.length} couples' : '1 couple', style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w700, color: _rose)),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 30,
                            child: Column(children: <Widget>[
                              _title(d.settings, 27),
                              const SizedBox(height: 2),
                              Text(d.settings.subtitle, style: GoogleFonts.kalam(fontSize: 13.5, fontWeight: FontWeight.w700, color: _roseText)),
                            ]),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 108,
                            height: 160,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 520),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              // smooth side slide: new couple glides in from the arrow's side, old one glides out the other way
                              transitionBuilder: (Widget ch, Animation<double> a) {
                                final bool incoming = ch.key == ValueKey<String>(c.id);
                                final double from = (incoming ? _dir : -_dir) * 0.55;
                                return FadeTransition(
                                  opacity: a,
                                  child: SlideTransition(
                                    position: Tween<Offset>(begin: Offset(from, 0), end: Offset.zero).animate(a),
                                    child: ScaleTransition(scale: Tween<double>(begin: 0.9, end: 1).animate(a), child: ch),
                                  ),
                                );
                              },
                              child: Stack(key: ValueKey<String>(c.id), children: <Widget>[
                                Positioned(left: 68, top: 10, child: Transform.rotate(angle: -0.14, child: _mini(c.a))),
                                Positioned(right: 68, top: 10, child: Transform.rotate(angle: 0.14, child: _mini(c.b))),
                              ]),
                            ),
                          ),
                          if (d.couples.length > 1) ...<Widget>[
                            Positioned(left: 12, top: 172, child: _arrow(Icons.chevron_left_rounded, () => _step(-1))),
                            Positioned(right: 12, top: 172, child: _arrow(Icons.chevron_right_rounded, () => _step(1))),
                          ],
                          Positioned(
                            left: 161,
                            top: 166,
                            child: AnimatedBuilder(
                              animation: _beat,
                              builder: (BuildContext c2, Widget? ch) {
                                final double t = _beat.value;
                                final double s = t < 0.15 ? 1 + t : (t < 0.3 ? 1.15 - (t - 0.15) : (t < 0.45 ? 1 + (t - 0.3) * 0.66 : math.max(1.0, 1.1 - (t - 0.45))));
                                return Transform.scale(scale: s, child: ch);
                              },
                              child: const _Heart(44),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 262,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 420),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (Widget ch, Animation<double> a) {
                                final bool incoming = ch.key == ValueKey<String>('n${c.id}');
                                return FadeTransition(
                                  opacity: a,
                                  child: SlideTransition(
                                    position: Tween<Offset>(begin: Offset((incoming ? _dir : -_dir) * 0.25, 0), end: Offset.zero).animate(a),
                                    child: ch,
                                  ),
                                );
                              },
                              child: Text(c.name, key: ValueKey<String>('n${c.id}'), textAlign: TextAlign.center, style: GoogleFonts.greatVibes(fontSize: 28, color: _rose)),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 298,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: Text.rich(
                                TextSpan(children: <InlineSpan>[
                                  TextSpan(text: '2 jars · ${_rs(c.weights.first.price)}'),
                                  if (c.weights.first.mrp > c.weights.first.price)
                                    TextSpan(text: ' · Save ${_rs(c.weights.first.mrp - c.weights.first.price)}', style: const TextStyle(color: Color(0xFF1F8A4C))),
                                ]),
                                key: ValueKey<String>('s${c.id}'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: _maroon),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 324,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  gradient: const LinearGradient(colors: <Color>[Color(0xFFD6336C), _maroon]),
                                  boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x99C2185B), blurRadius: 20, offset: Offset(0, 10), spreadRadius: -8)],
                                ),
                                child: Text('💞 ${d.settings.buttonText}  ›', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _mini(PairSide s) => Container(
        width: 112,
        height: 140,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _goldLine, width: 1.5),
          boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x807A1426), blurRadius: 24, offset: Offset(0, 14), spreadRadius: -14)],
        ),
        child: Column(children: <Widget>[
          Container(
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const RadialGradient(center: Alignment(0, 0.2), colors: <Color>[Color(0xFFFFF4E4), Color(0xFFF6DDBE)])),
            child: _bowl(s.image, 90),
          ),
          const SizedBox(height: 6),
          FittedBox(fit: BoxFit.scaleDown, child: Text(s.name, maxLines: 1, style: GoogleFonts.playfairDisplay(fontSize: 14, fontWeight: FontWeight.w700, color: _maroon))),
        ]),
      );
}

// ═════════════════════════════ FULL PAGE ═════════════════════════════
class PairingScreen extends StatefulWidget {
  final PairingData data;
  final int initialIndex;
  final PairAdd? onAddCouple;
  final void Function(PairCouple couple, PairWeight weight)? onViewCombo;
  final VoidCallback? onCart;
  const PairingScreen({super.key, required this.data, this.initialIndex = 0, this.onAddCouple, this.onViewCombo, this.onCart});
  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> with TickerProviderStateMixin {
  int _cur = 0, _w = 0, _qty = 0;
  bool _busy = false, _switching = false;
  late AnimationController _in; // cards fly in & meet (0..1, 1.6 s)
  late AnimationController _out; // cards leave (0..1)
  late AnimationController _beat;
  late AnimationController _burst;
  final List<List<double>> _conf = <List<double>>[];
  final Map<String, int> _cartQty = <String, int>{}; // "coupleId|weight" → qty added from this page

  List<PairCouple> get _cs => widget.data.couples;
  PairCouple get _c => _cs[_cur];
  PairWeight get _wt => _c.weights[math.max(0, math.min(_w, _c.weights.length - 1))];
  String get _key => '${_c.id}|$_w';

  @override
  void initState() {
    super.initState();
    _cur = math.max(0, math.min(widget.initialIndex, _cs.length - 1));
    _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _out = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _beat = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    final math.Random r = math.Random(9);
    for (int k = 0; k < 30; k++) {
      final double a = k / 30 * math.pi * 2, d = 70 + r.nextDouble() * 110;
      _conf.add(<double>[math.cos(a) * d, math.sin(a) * d - 40, r.nextDouble() * 10, (k % 5).toDouble()]);
    }
    _in.addListener(() {
      if (_in.value >= 0.72 && _burst.status == AnimationStatus.dismissed) {
        HapticFeedback.lightImpact();
        _burst.forward(from: 0);
        _beat.repeat();
      }
    });
    _in.forward(from: 0);
  }

  @override
  void dispose() {
    _in.dispose();
    _out.dispose();
    _beat.dispose();
    _burst.dispose();
    super.dispose();
  }

  Future<void> _goTo(int i) async {
    if (_switching || i == _cur || _cs.isEmpty) return;
    _switching = true;
    HapticFeedback.selectionClick();
    _beat.stop();
    await _out.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _cur = i;
      _w = 0;
      _qty = _cartQty[_key] ?? 0;
    });
    _out.value = 0;
    _burst.value = 0;
    _burst.reset();
    await _in.forward(from: 0);
    _switching = false;
  }

  Future<void> _change(int delta) async {
    if (_busy) return;
    final int next = math.max(0, math.min(20, _qty + delta));
    if (next == _qty) return;
    setState(() => _busy = true);
    bool ok = true;
    if (widget.onAddCouple != null) ok = await widget.onAddCouple!(_c, _wt, next - _qty);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) {
        _qty = next;
        _cartQty[_key] = next;
      }
    });
    if (ok && delta > 0) {
      HapticFeedback.mediumImpact();
      if (next == 1) _burst.forward(from: 0);
    }
    if (!ok) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update the cart. Please try again.')));
  }

  void _viewCombo() {
    if (widget.onViewCombo != null) {
      widget.onViewCombo!(_c, _wt);
      return;
    }
    final PairCouple c = _c;
    final PairWeight w = _wt;
    final double each = (w.price / 2).roundToDouble();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (BuildContext ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFEAD3C4), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 10),
            Text(c.name, style: GoogleFonts.playfairDisplay(fontSize: 19, fontWeight: FontWeight.w700, color: _maroon)),
            Text("WHAT'S INSIDE", style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: _gold)),
            for (final PairSide s in <PairSide>[c.a, c.b])
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFFFF7F0), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFF3E2D2))),
                child: Row(children: <Widget>[
                  SizedBox(width: 52, height: 46, child: _bowl(s.image, 52)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                      Text(s.name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
                      Text('${w.label.replaceAll(' each', '')}${s.tags.isEmpty ? '' : ' · ${s.tags.join(' · ').toLowerCase()}'}', style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF9A7F6A))),
                    ]),
                  ),
                  Text(_rs(each), style: GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.w700, color: _maroon)),
                ]),
              ),
            const SizedBox(height: 8),
            Center(child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _roseText)))),
          ]),
        ),
      ),
    );
  }

  double _seg(double t, double a, double b, [Curve c = Curves.easeOut]) => c.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: _bgB,
      body: DecoratedBox(
        decoration: _bg,
        child: Padding(
          padding: EdgeInsets.only(top: mq.padding.top, bottom: mq.padding.bottom),
          // fill the full screen width (no empty side gaps); scroll if the screen is short
          child: LayoutBuilder(builder: (BuildContext ctx, BoxConstraints box) {
            final double scale = box.maxWidth / 390;
            final double pageH = math.max(_cs.length > 1 ? 1110.0 : 960.0, box.maxHeight / scale); // room for the couples cards
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: box.maxWidth,
                height: pageH * scale,
                child: FittedBox(fit: BoxFit.fill, alignment: Alignment.topCenter, child: SizedBox(width: 390, height: pageH, child: _page())),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _page() {
    final PairSettings s = widget.data.settings;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        // top bar
        Positioned(
          left: 16,
          right: 16,
          top: 16,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
            _roundBtn(Icons.chevron_left_rounded, () => Navigator.maybePop(context)),
            // cart button with the live item count
            ListenableBuilder(
              listenable: CartManager(),
              builder: (BuildContext c, _) {
                final int n = CartManager().itemCount;
                return Stack(clipBehavior: Clip.none, children: <Widget>[
                  _roundBtn(Icons.shopping_bag_outlined, widget.onCart),
                  if (n > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: IgnorePointer(child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        height: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: const Color(0xFFD62839), borderRadius: BorderRadius.circular(9), border: Border.all(color: Colors.white, width: 1.5)),
                        child: Text(n > 99 ? '99+' : '$n', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
                      )),
                    ),
                ]);
              },
            ),
          ]),
        ),
        // header
        Positioned(
          left: 0,
          right: 0,
          top: 72,
          child: Column(children: <Widget>[
            Text(s.eyebrow, style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 4, color: _gold)),
            const SizedBox(height: 4),
            _title(s, 30),
            const SizedBox(height: 2),
            Text(s.subtitle, style: GoogleFonts.kalam(fontSize: 14, fontWeight: FontWeight.w700, color: _roseText)),
            if (s.explainText.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xBFFFFFFF), borderRadius: BorderRadius.circular(10), border: Border.all(color: _goldLine)),
                child: Text(s.explainText, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _maroon)),
              ),
          ]),
        ),
        // couple stage (swipe here)
        Positioned(
          left: 0,
          right: 0,
          top: 196,
          height: 380,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (DragEndDetails d) {
              final double v = d.primaryVelocity ?? 0.0;
              if (v.abs() < 150 || _cs.length < 2) return;
              _goTo(v < 0 ? (_cur + 1) % _cs.length : (_cur - 1 + _cs.length) % _cs.length);
            },
            child: AnimatedBuilder(animation: Listenable.merge(<Listenable>[_in, _out, _beat, _burst]), builder: (BuildContext c, Widget? ch) => _stage(s)),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 584,
          child: Text('‹ swipe for more couples ›', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w600, letterSpacing: 1, color: const Color(0xFFC9A0A8))),
        ),
        // couple card
        Positioned(left: 16, right: 16, top: 610, child: AnimatedBuilder(animation: _in, builder: (BuildContext c, Widget? ch) {
          final double v = _seg(_in.value, 0.78, 1.0);
          return Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: ch));
        }, child: _card())),
        // more couples
        if (_cs.length > 1) Positioned(left: 0, right: 0, top: 818, child: _more(s)),
      ],
    );
  }

  Widget _roundBtn(IconData i, VoidCallback? onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: <BoxShadow>[BoxShadow(color: Color(0x807A1426), blurRadius: 12, offset: Offset(0, 4), spreadRadius: -6)]),
          child: Icon(i, color: _maroon, size: 20),
        ),
      );

  Widget _stage(PairSettings s) {
    final double t = _in.value, o = _out.value;
    final double inL = _seg(t, 0.0, 0.5, const Cubic(0.3, 1.25, 0.5, 1.0));
    final double inR = _seg(t, 0.1, 0.6, const Cubic(0.3, 1.25, 0.5, 1.0));
    final double meet = _seg(t, 0.62, 0.75);
    final double pop = _seg(t, 0.72, 0.85, Curves.elasticOut);
    final double text = _seg(t, 0.8, 0.95, const Cubic(0.3, 1.6, 0.5, 1.0));
    final double beat = _beat.isAnimating ? (1 + 0.12 * math.max(0.0, math.sin(_beat.value * math.pi * 2))) : 1.0;
    final double outE = Curves.easeIn.transform(o);
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          left: 25,
          right: 25,
          top: 90,
          height: 240,
          child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(colors: <Color>[const Color(0x59FFAABE).withOpacity(0.35 * meet), const Color(0x00FFAABE)])))),
        ),
        // left card
        Positioned(
          left: 10,
          top: 30,
          child: Opacity(
            opacity: (1 - outE).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(-260 * (1 - inL) - 120 * outE, 60 * outE),
              child: Transform.rotate(angle: (-0.52 * (1 - inL)) + (-0.14 + 0.07 * meet) * inL - 0.35 * outE, child: _bigCard(_c.a)),
            ),
          ),
        ),
        // right card
        Positioned(
          right: 10,
          top: 30,
          child: Opacity(
            opacity: (1 - outE).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(260 * (1 - inR) + 120 * outE, 60 * outE),
              child: Transform.rotate(angle: (0.52 * (1 - inR)) + (0.14 - 0.07 * meet) * inR + 0.35 * outE, child: _bigCard(_c.b)),
            ),
          ),
        ),
        // heart
        Positioned(
          left: 172,
          top: 44,
          child: Opacity(opacity: (pop * (1 - outE)).clamp(0.0, 1.0), child: Transform.scale(scale: pop * beat, child: const _Heart(46))),
        ),
        // meal badge
        if (_c.mealName.isNotEmpty || _c.mealIcon.isNotEmpty)
          Positioned(
            left: 167,
            top: 96,
            child: Opacity(
              opacity: (pop * (1 - outE)).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.5 + 0.5 * pop,
                child: SizedBox(
                  width: 56,
                  child: Column(children: <Widget>[
                    Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: _goldLine, width: 2),
                        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x807A1426), blurRadius: 16, offset: Offset(0, 8), spreadRadius: -8)],
                      ),
                      child: Text(_c.mealIcon, style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(height: 6),
                    Text('BEST WITH\n${_c.mealName}', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 8, height: 1.25, fontWeight: FontWeight.w700, color: _maroon)),
                  ]),
                ),
              ),
            ),
          ),
        // "Made for each other"
        Positioned(
          left: 0,
          right: 0,
          top: 282,
          child: Opacity(
            opacity: (text * (1 - outE)).clamp(0.0, 1.0),
            child: Transform.scale(scale: 0.6 + 0.4 * text, child: Text(s.matchText, textAlign: TextAlign.center, style: GoogleFonts.greatVibes(fontSize: 36, color: _rose))),
          ),
        ),
        // serving tip
        if (_c.tip.isNotEmpty)
          Positioned(
            left: 28,
            right: 28,
            top: 330,
            child: Opacity(
              opacity: (_seg(t, 0.88, 1.0) * (1 - outE)).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, 8 * (1 - _seg(t, 0.88, 1.0))),
                child: Text(_c.tip, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.kalam(fontSize: 13, height: 1.25, fontWeight: FontWeight.w700, color: const Color(0xFF8A5A44))),
              ),
            ),
          ),
        // confetti
        if (_burst.value > 0 && _burst.value < 1)
          Positioned(left: 195, top: 80, child: IgnorePointer(child: CustomPaint(painter: _ConfettiPainter(_burst.value, _conf)))),
      ],
    );
  }

  Widget _bigCard(PairSide p) {
    return Container(
      width: 150,
      height: 240,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _goldLine, width: 1.5),
        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x737A1426), blurRadius: 30, offset: Offset(0, 18), spreadRadius: -16)],
      ),
      child: Column(children: <Widget>[
        Container(
          height: 126,
          alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: const RadialGradient(center: Alignment(0, 0.2), colors: <Color>[Color(0xFFFFF4E4), Color(0xFFF6DDBE)])),
          child: _bowl(p.image, 120),
        ),
        const SizedBox(height: 8),
        FittedBox(fit: BoxFit.scaleDown, child: Text(p.name, maxLines: 1, style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: _maroon))),
        const SizedBox(height: 2),
        Text(p.bio, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: GoogleFonts.kalam(fontSize: 13.5, height: 1.2, fontWeight: FontWeight.w700, color: const Color(0xFF9A6A52))),
        const Spacer(),
        // tags shrink to fit the card instead of overflowing
        FittedBox(fit: BoxFit.scaleDown, child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
          for (final String t in p.tags.take(2))
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: _goldLine)),
              child: Text(t, maxLines: 1, style: GoogleFonts.poppins(fontSize: 8.5, fontWeight: FontWeight.w700, color: _roseText)),
            ),
        ])),
      ]),
    );
  }

  Widget _card() {
    final PairCouple c = _c;
    final PairWeight w = _wt;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0D9B0), width: 1.5),
        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x807A1426), blurRadius: 30, offset: Offset(0, 16), spreadRadius: -18)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: <Widget>[
        Row(children: <Widget>[
          if (c.tag.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), gradient: const LinearGradient(colors: <Color>[Color(0xFF9E1B32), Color(0xFF6A1022)])),
              child: Text(c.tag, style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: Colors.white)),
            ),
          const SizedBox(width: 10),
          if (c.lovedText.isNotEmpty)
            Expanded(
              child: Text('💗 ${c.lovedText}', maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: _gold)),
            )
          else
            const Spacer(),
        ]),
        const SizedBox(height: 10),
        Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: _ink)),
        const SizedBox(height: 12),
        Row(children: <Widget>[
          if (c.weights.length > 1) Expanded(child: _weightToggle(c)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _viewCombo,
            child: Container(
              padding: const EdgeInsets.only(bottom: 1),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF2A9BF), width: 1.5))),
              child: Text('View combo ›', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: _rose)),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: <Widget>[
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: <Widget>[
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(_rs(w.price), key: ValueKey<String>(_key), style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: _ink)),
                ),
                if (w.mrp > w.price)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Text(_rs(w.mrp), style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFFB8A493), decoration: TextDecoration.lineThrough, decorationColor: const Color(0xFFB8A493))),
                  ),
              ]),
              if (w.mrp > w.price) Text('Save ${_rs(w.mrp - w.price)}', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF1F8A4C))),
            ]),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 155, height: 44, child: _addButton()),
        ]),
      ]),
    );
  }

  Widget _weightToggle(PairCouple c) {
    const double segW = 76;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: const Color(0xFFF7EADB), borderRadius: BorderRadius.circular(12)),
        child: Stack(children: <Widget>[
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            left: segW * _w,
            top: 0,
            bottom: 0,
            width: segW,
            child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9), boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x737A1426), blurRadius: 8, offset: Offset(0, 3), spreadRadius: -4)])),
          ),
          Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
            for (int k = 0; k < c.weights.length && k < 3; k++)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (k == _w) return;
                  HapticFeedback.selectionClick();
                  setState(() {
                    _w = k;
                    _qty = _cartQty[_key] ?? 0;
                  });
                },
                child: SizedBox(
                  width: segW,
                  height: 28,
                  child: Center(child: Text(c.weights[k].label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: k == _w ? _maroon : const Color(0xFFA08A78)))),
                ),
              ),
          ]),
        ]),
      ),
    );
  }

  Widget _addButton() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _qty == 0
          ? GestureDetector(
              key: const ValueKey<String>('add'),
              onTap: () => _change(1),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(colors: <Color>[Color(0xFFD6336C), _maroon]),
                  boxShadow: const <BoxShadow>[BoxShadow(color: Color(0xB3C2185B), blurRadius: 18, offset: Offset(0, 10), spreadRadius: -8)],
                ),
                child: _busy
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Text('💞 Add both · ${_rs(_wt.price)}', maxLines: 1, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            )
          : Container(
              key: const ValueKey<String>('qty'),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), gradient: const LinearGradient(colors: <Color>[Color(0xFF22A35A), Color(0xFF178048)])),
              child: Row(children: <Widget>[
                IconButton(onPressed: () => _change(-1), icon: const Icon(Icons.remove_rounded, color: Colors.white, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
                Expanded(child: Center(child: Text('In cart · $_qty', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)))),
                IconButton(onPressed: () => _change(1), icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
              ]),
            ),
    );
  }

  final ScrollController _moreCtrl = ScrollController();

  Widget _circlePhoto(String url, double d) {
    final Widget ph = Container(width: d, height: d, color: const Color(0xFFFBEFDF), child: const Icon(Icons.restaurant, color: _rose, size: 22));
    final Widget img = url.isEmpty
        ? ph
        : url.startsWith('assets/')
            ? Image.asset(url, width: d, height: d, fit: BoxFit.cover, cacheWidth: 200, errorBuilder: (_, __, ___) => ph)
            : Image.network(url, width: d, height: d, fit: BoxFit.cover, cacheWidth: 200, gaplessPlayback: true, errorBuilder: (_, __, ___) => ph);
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x59000000), blurRadius: 10, offset: Offset(0, 6), spreadRadius: -4)],
      ),
      child: ClipOval(child: img),
    );
  }

  /// "More perfect couples" — one clear card per couple: both photos, tag, name, price, View
  Widget _more(PairSettings s) {
    const double cardW = 150, gap = 12;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: <Widget>[
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text('SWIPE TO EXPLORE', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2.6, color: const Color(0xFFB0263A))),
              Text.rich(TextSpan(children: <InlineSpan>[
                TextSpan(text: 'More perfect ', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF3A0E16))),
                TextSpan(text: 'couples', style: GoogleFonts.dancingScript(fontSize: 25, fontWeight: FontWeight.w700, color: _gold)),
              ])),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('${_cs.length} couples ›', style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF7A5A50))),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 238,
        child: ListView.separated(
          controller: _moreCtrl,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
          clipBehavior: Clip.none,
          itemCount: _cs.length,
          separatorBuilder: (BuildContext c, int i) => const SizedBox(width: gap),
          itemBuilder: (BuildContext c, int k) {
            final PairCouple cp = _cs[k];
            final bool on = k == _cur;
            final PairWeight? w = cp.weights.isNotEmpty ? cp.weights.first : null;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _goTo(k);
                // keep the chosen card in view
                if (_moreCtrl.hasClients) {
                  final double target = (k * (cardW + gap) - (390 - cardW) / 2 + 18).clamp(0.0, _moreCtrl.position.maxScrollExtent);
                  _moreCtrl.animateTo(target, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                width: cardW,
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: on ? const Color(0xFFC2273A) : Colors.transparent, width: 1.5),
                  boxShadow: <BoxShadow>[
                    if (on) const BoxShadow(color: Color(0x1FC2273A), spreadRadius: 3),
                    BoxShadow(color: on ? const Color(0x997A1426) : const Color(0x737A1426), blurRadius: 18, offset: const Offset(0, 10), spreadRadius: -12),
                  ],
                ),
                child: Column(children: <Widget>[
                  SizedBox(
                    width: 120,
                    height: 72,
                    child: Stack(clipBehavior: Clip.none, children: <Widget>[
                      Positioned(left: 0, top: 2, child: Transform.rotate(angle: -0.1, child: _circlePhoto(cp.a.image, 68))),
                      Positioned(right: 0, top: 2, child: Transform.rotate(angle: 0.1, child: _circlePhoto(cp.b.image, 68))),
                      Positioned(
                        left: 48,
                        top: 24,
                        child: Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: <BoxShadow>[BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 3))]),
                          child: const Icon(Icons.favorite_rounded, color: Color(0xFFE0245E), size: 14),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  if (cp.tag.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFFDE8EC), borderRadius: BorderRadius.circular(7)),
                      child: Text(cp.tag.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 7.5, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: const Color(0xFFB0263A))),
                    ),
                  const SizedBox(height: 4),
                  Text('${cp.a.name} + ${cp.b.name}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(fontSize: 13.5, height: 1.15, fontWeight: FontWeight.w700, color: const Color(0xFF3A0E16))),
                  const Spacer(),
                  if (w != null) ...<Widget>[
                    Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: <Widget>[
                      Text(_rs(w.price), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _maroon)),
                      if (w.mrp > w.price) ...<Widget>[
                        const SizedBox(width: 5),
                        Text(_rs(w.mrp), style: GoogleFonts.poppins(fontSize: 9.5, color: const Color(0xFFA89380), decoration: TextDecoration.lineThrough)),
                      ],
                    ]),
                    if (w.mrp > w.price)
                      Text('Save ${_rs(w.mrp - w.price)}', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF1F8A4C))),
                  ],
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: on ? const Color(0xFFC2273A) : const Color(0xFFFDE8EC), borderRadius: BorderRadius.circular(10)),
                    child: Text(on ? '✓ Now viewing' : 'View',
                        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: on ? Colors.white : const Color(0xFFB0263A))),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        for (int k = 0; k < _cs.length; k++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: k == _cur ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: k == _cur ? const Color(0xFFC2273A) : const Color(0x40B0263A)),
          ),
      ]),
    ]);
  }
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  final List<List<double>> parts;
  _ConfettiPainter(this.t, this.parts);
  static const List<Color> _cols = <Color>[Color(0xFFFF6B8E), Color(0xFFF6C453), Color(0xFFC2185B), Colors.white, Color(0xFF7FD39A)];
  @override
  void paint(Canvas canvas, Size size) {
    final double e = const Cubic(0.1, 0.7, 0.3, 1.0).transform(t);
    for (final List<double> p in parts) {
      canvas.save();
      canvas.translate(p[0] * e, p[1] * e);
      canvas.rotate(p[2] * e);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-3.5, -5, 7, 10), const Radius.circular(2)), Paint()..color = _cols[p[3].toInt()].withOpacity(1 - t));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter o) => o.t != t;
}
