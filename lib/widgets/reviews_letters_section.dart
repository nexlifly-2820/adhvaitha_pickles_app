// reviews_letters_section.dart — "Letters from Home" customer reviews for the AmbhuJakshi home screen.
// Emerald wall · jute thoranam with mango leaves & marigolds · letters on wooden clothespins that swing with
// real pendulum physics · handwriting reveal · Polaroid photo with tape · VERIFIED BUYER postmark ·
// gold rating medal · endless auto-slide + swipe.
// Everything comes from the admin dashboard via reviews_backend.js  (GET /api/home/reviews).
//
// pubspec.yaml
//   dependencies:
//     http: ^1.2.0
//     google_fonts: ^6.2.1
//
// Usage on the home page:
//   ReviewsLettersSection(
//     apiUrl: 'https://your-api.com/api/home/reviews',
//     onAdd: (productId) async => cart.add(productId),           // "Add +" on a letter
//     onOpenProduct: (productId) => Navigator.pushNamed(context, '/product', arguments: productId),
//     onSeeAll: () => Navigator.pushNamed(context, '/reviews'),
//     onWrite: () => Navigator.pushNamed(context, '/write-review'),
//   )

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../api_service.dart';

Color _hex(String? s, Color fb) {
  if (s == null || s.isEmpty) return fb;
  var h = s.replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  return Color(int.tryParse(h, radix: 16) ?? fb.value);
}

// ───────────────────────────── models ─────────────────────────────
class ReviewLetter {
  final String id, productId, productName, text, name, meta, photoUrl, photoCaption;
  final int stars;
  final bool verified;
  final Color tagBg, tagFg;
  ReviewLetter.fromJson(Map<String, dynamic> j)
      : id = '${j['id']}',
        productId = '${j['productId']}',
        productName = j['productName'] ?? '',
        text = j['text'] ?? '',
        name = j['name'] ?? '',
        meta = j['meta'] ?? '',
        photoUrl = j['photoUrl'] ?? '',
        photoCaption = j['photoCaption'] ?? '',
        stars = (int.tryParse('${j['stars'] ?? 5}') ?? 5).clamp(1, 5).toInt(),
        verified = '${j['verified'] ?? true}' != 'false',
        tagBg = _hex(j['tagBg'], const Color(0xFFFDE8EA)),
        tagFg = _hex(j['tagFg'], const Color(0xFFC2273A));
}

class ReviewsSettings {
  final String eyebrow, title, titleAccent, subtitle, seeAllLabel, writeLabel, ringText;
  final Color wallTop, wallMid, wallBottom, accent, gold;
  final int autoplayMs;
  ReviewsSettings.fromJson(Map<String, dynamic> j)
      : eyebrow = j['eyebrow'] ?? 'LETTERS FROM HOME',
        title = j['title'] ?? 'What families',
        titleAccent = j['titleAccent'] ?? 'write to Amma',
        subtitle = j['subtitle'] ?? 'Real notes from real kitchens 💌',
        seeAllLabel = j['seeAllLabel'] ?? 'See all',
        writeLabel = j['writeLabel'] ?? '✍️ Write to Amma',
        ringText = j['ringText'] ?? '',
        wallTop = _hex(j['wallTop'], const Color(0xFF1F6B55)),
        wallMid = _hex(j['wallMid'], const Color(0xFF0F3F33)),
        wallBottom = _hex(j['wallBottom'], const Color(0xFF082520)),
        accent = _hex(j['accent'], const Color(0xFFFFD58A)),
        gold = _hex(j['gold'], const Color(0xFFE9C46A)),
        autoplayMs = (j['autoplayMs'] as num?)?.toInt() ?? 4200;
}

// ───────────────────────────── section ─────────────────────────────
class ReviewsLettersSection extends StatefulWidget {
  final String apiUrl;
  final Map<String, String>? headers;
  final Future<bool> Function(String productId)? onAdd;
  final ValueChanged<String>? onOpenProduct;
  final VoidCallback? onSeeAll, onWrite;
  const ReviewsLettersSection({super.key, required this.apiUrl, this.headers, this.onAdd, this.onOpenProduct, this.onSeeAll, this.onWrite});
  @override
  State<ReviewsLettersSection> createState() => _ReviewsLettersSectionState();
}

class _ReviewsLettersSectionState extends State<ReviewsLettersSection> with TickerProviderStateMixin {
  ReviewsSettings? _s;
  List<ReviewLetter> _items = [];
  double _avg = 0;
  int _count = 0;
  bool _hidden = false;

  // physics
  late final Ticker _ticker;
  Duration _lastT = Duration.zero;
  double _time = 0, _x = 0, _v = 0, _prevV = 0, _target = 0, _acc = 0;
  int _idx = 0; // can grow forever; item = _idx % n
  final Map<int, double> _th = {}, _om = {};
  final Map<int, double> _revealStart = {}; // slot → time when its handwriting started
  Timer? _auto;
  bool _dragging = false;
  static const double _step = 226; // card width 206 + gap 20

  late final AnimationController _score = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  late final AnimationController _ring = AnimationController(vsync: this, duration: const Duration(seconds: 22))..repeat();
  late final AnimationController _shine = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500))..repeat();

  static final Map<String, dynamic> _defaultReviewsData = {
    "settings": {
      "enabled": true,
      "eyebrow": "LETTERS FROM HOME",
      "title": "What families",
      "titleAccent": "write to Amma",
      "subtitle": "Real notes from real kitchens 💌",
      "seeAllLabel": "See all",
      "writeLabel": "✍️ Write to Amma"
    },
    "summary": { "average": 4.9, "count": 128 },
    "reviews": [
      {
        "id": "1",
        "productId": "mango_avakaya",
        "productName": "Bellam Avakaya Pickle",
        "text": "The jaggery and chilli balance is absolute perfection. Tastes just like my grandmother's summer pickle!",
        "name": "Sujatha Reddy",
        "meta": "Verified Buyer · Hyderabad",
        "photoUrl": "assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg",
        "photoCaption": "Sent with hot steaming rice & ghee",
        "stars": 5,
        "verified": true,
        "tagBg": "#FDE8EA",
        "tagFg": "#C2273A"
      },
      {
        "id": "2",
        "productId": "idli_karam",
        "productName": "Idli Karam Podi",
        "text": "Morning idlis are incomplete without this podi now. The aroma of roasted garlic and lentils is divine.",
        "name": "Kiranmayi V.",
        "meta": "Verified Buyer · Bengaluru",
        "photoUrl": "assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg",
        "photoCaption": "Freshly ground stone-ground goodness",
        "stars": 5,
        "verified": true,
        "tagBg": "#E3F6F2",
        "tagFg": "#1E7A46"
      },
      {
        "id": "3",
        "productId": "sunnundalu",
        "productName": "Bellam Sunnundalu",
        "text": "Pure desi ghee aroma hits you the moment you open the jar. Melts in the mouth instantly!",
        "name": "Ramesh Rao",
        "meta": "Verified Buyer · Chennai",
        "photoUrl": "assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg",
        "photoCaption": "Made with pure jaggery",
        "stars": 5,
        "verified": true,
        "tagBg": "#FFF1D6",
        "tagFg": "#8A5A10"
      }
    ]
  };

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    _applyData(_defaultReviewsData);
    _load();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _auto?.cancel();
    _score.dispose(); _ring.dispose(); _shine.dispose();
    super.dispose();
  }

  void _applyData(Map<String, dynamic> j) {
    final items = ((j['reviews'] as List?) ?? []).map((e) => ReviewLetter.fromJson(e)).toList();
    if (!mounted || items.isEmpty) return;
    setState(() {
      _s = ReviewsSettings.fromJson(j['settings'] ?? {});
      _items = items;
      _avg = (j['summary']?['average'] as num?)?.toDouble() ?? 4.9;
      _count = (j['summary']?['count'] as num?)?.toInt() ?? items.length;
      _idx = items.length * 1000;
      _target = _x = -_idx * _step;
      _revealStart[_idx] = _time + .5;
      _hidden = false;
    });
    _score.forward(from: 0);
    _startAuto();
  }

  Future<void> _load() async {
    // Letters saved in admin (App Content -> Letters from Home) plus customer
    // letters the admin approved in Reviews. Only approved letters are in this doc.
    try {
      final Map<String, dynamic> j = await ApiService.getAppConfig('reviews');
      if (j.isEmpty) return;
      final Map settings = (j['settings'] is Map) ? j['settings'] as Map : const {};
      if (settings['enabled']?.toString() == 'false') {
        if (mounted) setState(() => _hidden = true);
        return;
      }
      final List list = (j['reviews'] as List?) ?? const [];
      final List<Map<String, dynamic>> letters = <Map<String, dynamic>>[
        for (final e in list)
          if (e is Map && e['enabled']?.toString() != 'false' && (e['text'] ?? '').toString().trim().isNotEmpty) Map<String, dynamic>.from(e),
      ];
      if (letters.isEmpty) return;
      final Map<String, dynamic> base = _defaultReviewsData;
      _applyData(<String, dynamic>{
        'settings': <String, dynamic>{...(base['settings'] as Map<String, dynamic>), ...Map<String, dynamic>.from(settings)},
        'summary': (j['summary'] is Map) ? j['summary'] : base['summary'],
        'reviews': letters,
      });
    } catch (e) {
      debugPrint('Reviews fetch failed, using built-in letters: $e');
    }
  }

  void _startAuto() {
    _auto?.cancel();
    if (_items.length < 2) return;
    _auto = Timer.periodic(Duration(milliseconds: _s?.autoplayMs ?? 4200), (_) { if (!_dragging) _goTo(_idx + 1); });
  }

  void _goTo(int i) {
    _idx = i;
    _target = -_idx * _step;
    _revealStart[_idx] = _time + .6;
  }

  void _tick(Duration t) {
    final dt = math.min(.033, (t - _lastT).inMicroseconds / 1e6);
    _lastT = t;
    if (dt <= 0) return;
    _time += dt;
    if (!_dragging) {
      // critically damped spring for the string
      const k = 26.0;
      final c = 2 * math.sqrt(k);
      final a = k * (_target - _x) - c * _v;
      _v += a * dt;
      _x += _v * dt;
    }
    _acc = (_v - _prevV) / dt;
    _prevV = _v;
    // pendulum per visible slot: gravity + damping + reaction to string acceleration + soft breeze
    for (int s = _idx - 3; s <= _idx + 3; s++) {
      final th = _th[s] ?? 0, om = _om[s] ?? 0;
      final wind = math.sin(_time * 1.1 + s * 1.7) * .9 + math.sin(_time * 2.3 + s * 2.2) * .35;
      final f = -14 * th - 1.6 * om - _acc * .0065 + wind * .9;
      _om[s] = om + f * dt;
      _th[s] = th + _om[s]! * dt;
    }
    _th.removeWhere((k, _) => (k - _idx).abs() > 6);
    _om.removeWhere((k, _) => (k - _idx).abs() > 6);
    if (mounted && !_hidden) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.shrink();
    final s = _s;
    if (s == null) return const SizedBox(height: 462);
    final w = MediaQuery.of(context).size.width;
    final n = _items.length;
    final center = (w - 206) / 2;
    return SizedBox(
      height: 462,
      child: Stack(clipBehavior: Clip.hardEdge, children: [
        // wall
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(
            center: const Alignment(0, -1), radius: 1.4, colors: [s.wallTop, s.wallMid, s.wallBottom], stops: const [0, .48, 1])))),
        Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _WallPainter(_time, s.accent)))),
        // header
        Positioned(left: 18, right: 18, top: 18, child: Row(children: [
          _medal(s),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.eyebrow, style: GoogleFonts.poppins(fontSize: 8.5, letterSpacing: 2.2, fontWeight: FontWeight.w700, color: s.gold)),
            const SizedBox(height: 3),
            Text(s.title, style: GoogleFonts.playfairDisplay(fontSize: 23, height: 1.12, fontWeight: FontWeight.w700, color: const Color(0xFFFBEFDC))),
            Text(s.titleAccent, style: GoogleFonts.playfairDisplay(fontSize: 23, height: 1.12, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, color: s.accent)),
            const SizedBox(height: 5),
            Text(s.subtitle, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white.withOpacity(.65))),
          ])),
        ])),
        // letters on the string (swipeable)
        Positioned(left: 0, right: 0, top: 118, height: 300, child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: (_) { _dragging = true; },
          onHorizontalDragUpdate: (d) { _x += d.delta.dx; _v = d.delta.dx * 60; },
          onHorizontalDragEnd: (d) {
            _dragging = false;
            final vx = d.primaryVelocity ?? 0;
            final near = (-_x / _step).round();
            _goTo(vx < -300 ? math.max(near, _idx + 1) : vx > 300 ? math.min(near, _idx - 1) : near);
            _startAuto();
          },
          child: Stack(clipBehavior: Clip.none, children: [
            for (int slot = _idx - 2; slot <= _idx + 2; slot++)
              Positioned(
                left: center + slot * _step + _x,
                top: 0, width: 206, height: 300,
                child: Transform.rotate(
                  angle: (_th[slot] ?? 0) * math.pi / 180,
                  alignment: const Alignment(0, -.8), // pivot at the clothespin
                  child: _Letter(
                    r: _items[((slot % n) + n) % n],
                    tilt: slot.isOdd ? 1.6 : -1.4,
                    current: slot == _idx,
                    reveal: ((_time - (_revealStart[slot] ?? -99)) / 1.6).clamp(0.0, 1.0),
                    shadowX: -(_th[slot] ?? 0) * 1.6,
                    onAdd: () async {
                      HapticFeedback.lightImpact();
                      await widget.onAdd?.call(_items[((slot % n) + n) % n].productId);
                    },
                    onOpen: () => widget.onOpenProduct?.call(_items[((slot % n) + n) % n].productId),
                  ),
                ),
              ),
          ]),
        )),
        // jute string + leaves + marigolds (drawn above the letters, like a real thoranam)
        Positioned(left: 0, right: 0, top: 118, height: 60, child: IgnorePointer(child: CustomPaint(painter: _ThoranamPainter(_time)))),
        // footer
        Positioned(left: 18, right: 18, bottom: 14, child: Row(children: [
          Row(children: [
            for (int i = 0; i < n; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                margin: const EdgeInsets.only(right: 5),
                width: i == ((_idx % n) + n) % n ? 18 : 6, height: 6,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(3),
                    color: i == ((_idx % n) + n) % n ? s.gold : Colors.white.withOpacity(.22)),
              ),
          ]),
          const Spacer(),
          GestureDetector(onTap: widget.onSeeAll ?? () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ReviewsAllPage(
                    settings: s, items: _items, avg: _avg, count: _count, onWrite: widget.onWrite)));
              },
              child: Text('${s.seeAllLabel} ${_fmt(_count)} →', style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: s.gold))),
          const SizedBox(width: 14),
          _ShineButton(label: s.writeLabel, shine: _shine, onTap: widget.onWrite ?? () => showWriteToAmmaSheet(context, products: _items.map((ReviewLetter r) => r.productName).toList())),
        ])),
      ]),
    );
  }

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k'.replaceAll('.0k', 'k') : '$n';

  Widget _medal(ReviewsSettings s) {
    final ring = s.ringText.isNotEmpty ? s.ringText : '★ ${_fmt(_count)} REVIEWS ★ MADE WITH LOVE ★ ';
    return SizedBox(
      width: 88, height: 88,
      child: Stack(alignment: Alignment.center, children: [
        RotationTransition(turns: _ring, child: CustomPaint(size: const Size.square(88), painter: _RingTextPainter(ring, s.gold))),
        Container(
          width: 62, height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(startAngle: 3.5, colors: [Color(0xFFB8862E), Color(0xFFFFE7A8), Color(0xFFD9A441), Color(0xFFFFF1C4), Color(0xFFB8862E), Color(0xFFF6D27A), Color(0xFFB8862E)]),
            boxShadow: [
              const BoxShadow(color: Color(0xFF7A5418), spreadRadius: 2),
              BoxShadow(color: Colors.black.withOpacity(.6), blurRadius: 18, offset: const Offset(0, 10), spreadRadius: -4),
              BoxShadow(color: const Color(0xFFFFBE5A).withOpacity(.25), blurRadius: 30, spreadRadius: 6),
            ],
          ),
          padding: const EdgeInsets.all(5),
          child: ClipOval(child: Stack(children: [
            Container(decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment(-.2, -.4),
                colors: [Color(0xFFFFF4D2), Color(0xFFE8BE62), Color(0xFFC9963A)], stops: [0, .7, 1]))),
            AnimatedBuilder(animation: _shine, builder: (_, __) => Positioned.fill(child: FractionallySizedBox(
              alignment: Alignment(3 - 6 * (_shine.value / .5).clamp(0.0, 1.0), 0), widthFactor: .35,
              child: Transform.rotate(angle: .4, child: Container(decoration: BoxDecoration(gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0), Colors.white.withOpacity(.6), Colors.white.withOpacity(0)]))))))),
            Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedBuilder(animation: _score, builder: (_, __) => Text(
                  (_avg * Curves.easeOutCubic.transform(_score.value)).toStringAsFixed(1),
                  style: GoogleFonts.playfairDisplay(fontSize: 22, height: 1, fontWeight: FontWeight.w700, color: const Color(0xFF4A2A10)))),
              Text('★★★★★', style: TextStyle(fontSize: 7.5, letterSpacing: .5, color: const Color(0xFF8A5A10).withOpacity(.9))),
            ])),
          ])),
        ),
      ]),
    );
  }
}

// ───────────────────────────── one letter ─────────────────────────────
class _Letter extends StatelessWidget {
  final ReviewLetter r;
  final double tilt, reveal, shadowX;
  final bool current;
  final VoidCallback onAdd, onOpen;
  const _Letter({required this.r, required this.tilt, required this.current, required this.reveal, required this.shadowX, required this.onAdd, required this.onOpen});

  Widget _masked(double p, Widget child) => ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (b) => LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: const [Colors.black, Colors.black, Colors.transparent, Colors.transparent],
            stops: [0, p.clamp(0.0, 1.0), (p + .18).clamp(0.0, 1.0), 1]).createShader(b),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final textP = current ? math.min(1.0, reveal * 1.25) : 1.0;
    final nameP = current ? ((reveal - .75) * 4).clamp(0.0, 1.0) : 1.0;
    return Stack(clipBehavior: Clip.none, children: [
      // clothespin
      Positioned(left: 95, top: 14, child: CustomPaint(size: const Size(16, 48), painter: _PinPainter())),
      // paper
      Positioned(left: 0, top: 50, width: 206, child: Transform.rotate(
        angle: tilt * math.pi / 180,
        child: GestureDetector(
          onTap: onOpen,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 600),
            opacity: 1,
            child: Stack(clipBehavior: Clip.none, children: [
              // soft shadow on the wall (moves with the swing)
              Positioned(left: 6 + shadowX, right: 6 - shadowX, top: 18, bottom: -16, child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(4),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.45), blurRadius: 22, offset: const Offset(0, 10))]))),
              ColorFiltered(
                colorFilter: current ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                    : const ColorFilter.matrix([.82, 0, 0, 0, 0, 0, .82, 0, 0, 0, 0, 0, .82, 0, 0, 0, 0, 0, 1, 0]),
                child: ClipPath(
                  clipper: _TornClipper(),
                  child: CustomPaint(
                    painter: _PaperPainter(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 14, 14, 20),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('★' * r.stars + '☆' * (5 - r.stars),
                            style: const TextStyle(fontSize: 13, letterSpacing: 1.5, color: Color(0xFFE39B1C))),
                        SizedBox(width: 128, child: _masked(textP, Text(r.text,
                            style: GoogleFonts.kalam(fontSize: 13.5, height: 22 / 13.5, color: const Color(0xFF24325E))))),
                        const SizedBox(height: 2),
                        _masked(nameP, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('— ${r.name}', style: GoogleFonts.dancingScript(fontSize: 18, height: 1, fontWeight: FontWeight.w700, color: const Color(0xFF1F3A8A))),
                          Text(r.meta, style: GoogleFonts.poppins(fontSize: 8.5, color: const Color(0xFF8A7660))),
                        ])),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: onAdd,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: r.tagBg, borderRadius: BorderRadius.circular(8)),
                            child: Text('${r.productName}  ·  Add +', style: GoogleFonts.poppins(fontSize: 8.5, fontWeight: FontWeight.w700, color: r.tagFg)),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
              // verified postmark — stamps on after the handwriting finishes
              if (r.verified)
                Positioned(right: 10, bottom: 40, child: _Postmark(show: !current || reveal >= 1)),
              // polaroid with tape
              if (r.photoUrl.isNotEmpty)
                Positioned(right: -12, top: -16, child: Transform.rotate(angle: 7 * math.pi / 180, child: _Polaroid(url: r.photoUrl, caption: r.photoCaption))),
            ]),
          ),
        ),
      )),
    ]);
  }
}

class _Postmark extends StatelessWidget {
  final bool show;
  const _Postmark({required this.show});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: show ? 1 : 0),
        duration: Duration(milliseconds: show ? 420 : 0),
        curve: Curves.easeInCubic,
        builder: (_, t, __) => Opacity(
          opacity: .8 * t,
          child: Transform.rotate(angle: -16 * math.pi / 180,
              child: Transform.scale(scale: 1.8 - .8 * t, child: CustomPaint(size: const Size(48, 48), painter: _PostmarkPainter()))),
        ),
      );
}

Widget _reviewImage(String url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
  if (url.isEmpty) return SizedBox(width: width, height: height);
  if (url.startsWith('assets/')) {
    return Image.asset(url, width: width, height: height, fit: fit,
        errorBuilder: (_, __, ___) => SizedBox(width: width, height: height, child: const Icon(Icons.image)));
  }
  return Image.network(url, width: width, height: height, fit: fit, gaplessPlayback: true,
      errorBuilder: (_, __, ___) => SizedBox(width: width, height: height, child: const Icon(Icons.image)));
}

class _Polaroid extends StatelessWidget {
  final String url, caption;
  const _Polaroid({required this.url, required this.caption});
  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 78,
          padding: const EdgeInsets.fromLTRB(5, 5, 5, 15),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.35), blurRadius: 10, offset: const Offset(0, 8), spreadRadius: -2),
            BoxShadow(color: Colors.black.withOpacity(.2), blurRadius: 2, offset: const Offset(0, 1)),
          ]),
          child: Container(
            height: 56,
            decoration: const BoxDecoration(gradient: RadialGradient(colors: [Color(0xFFFFF0D6), Color(0xFFD9B98A)])),
            child: ClipRect(child: Transform.scale(scale: 1.25, child: ColorFiltered(
              colorFilter: const ColorFilter.matrix([1.12, .04, 0, 0, -6, .02, 1.06, 0, 0, -4, 0, 0, .95, 0, 0, 0, 0, 0, 1, 0]),
              child: _reviewImage(url, width: 68, height: 56, fit: BoxFit.cover)))),
          ),
        ),
        Positioned(left: 0, right: 0, bottom: 1, child: Text(caption, textAlign: TextAlign.center,
            style: GoogleFonts.kalam(fontSize: 8.5, color: const Color(0xFF7A3A12)))),
        // washi tape
        Positioned(left: 18, top: -8, child: Transform.rotate(angle: -6 * math.pi / 180,
            child: Container(width: 40, height: 14, decoration: BoxDecoration(color: const Color(0xFFFFECAA).withOpacity(.6),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 2, offset: const Offset(0, 1))])))),
      ]);
}

class _ShineButton extends StatelessWidget {
  final String label;
  final Animation<double> shine;
  final VoidCallback? onTap;
  const _ShineButton({required this.label, required this.shine, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFE6A6), Color(0xFFE2AE4E)]),
            boxShadow: [BoxShadow(color: const Color(0xFFE9B75A).withOpacity(.9), blurRadius: 18, offset: const Offset(0, 10), spreadRadius: -8)],
          ),
          child: Stack(children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF3B1F14)))),
            Positioned.fill(child: AnimatedBuilder(animation: shine, builder: (_, __) => FractionallySizedBox(
              alignment: Alignment(-2 + 4 * (shine.value / .4).clamp(0.0, 1.0), 0), widthFactor: .4,
              child: Container(decoration: BoxDecoration(gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0), Colors.white.withOpacity(.7), Colors.white.withOpacity(0)])))))),
          ]),
        ),
      );
}

// ───────────────────────────── painters ─────────────────────────────
class _WallPainter extends CustomPainter {
  final double t;
  final Color accent;
  _WallPainter(this.t, this.accent);
  @override
  void paint(Canvas c, Size s) {
    // warm lamp from the top
    final lamp = Paint()..shader = RadialGradient(colors: [const Color(0xFFFFD68C).withOpacity(.30 * (.85 + .15 * math.sin(t * 1.3))), Colors.transparent])
        .createShader(Rect.fromCircle(center: Offset(s.width / 2, -40), radius: 260));
    c.drawRect(Offset.zero & s, lamp);
    // bokeh lights
    for (int i = 0; i < 9; i++) {
      final r = (8 + (i * 7) % 18) / 2;
      final o = (.3 + (i % 4) * .1) * (.6 + .4 * math.sin(t * 2 + i));
      final p = Offset(((i * 47 + 20) % 380) / 390 * s.width, ((i * 61) % 420 + 10).toDouble());
      c.drawCircle(p, r, Paint()..shader = RadialGradient(colors: [const Color(0xFFFFD28C).withOpacity(o * .55), Colors.transparent])
          .createShader(Rect.fromCircle(center: p, radius: r)));
    }
    // vignette
    c.drawRect(Offset.zero & s, Paint()..shader = RadialGradient(radius: .9, colors: [Colors.transparent, Colors.black.withOpacity(.45)], stops: const [.55, 1])
        .createShader(Offset.zero & s));
  }
  @override
  bool shouldRepaint(covariant _WallPainter o) => true;
}

class _ThoranamPainter extends CustomPainter {
  final double t;
  _ThoranamPainter(this.t);
  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    double sag(double x) => 8 + math.sin(x / w * math.pi) * 20;
    final path = Path()..moveTo(8, 8)..quadraticBezierTo(w / 2, 48, w - 8, 8);
    // shadow + twisted jute
    c.drawPath(path.shift(const Offset(0, 5)), Paint()..color = Colors.black.withOpacity(.35)..strokeWidth = 3..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    c.drawPath(path, Paint()..color = const Color(0xFFC9A27A)..strokeWidth = 2.6..style = PaintingStyle.stroke);
    final m = path.computeMetrics().first;
    final twist = Paint()..color = const Color(0xFFA9825A)..strokeWidth = 1.2;
    for (double d = 0; d < m.length; d += 5) {
      final tg = m.getTangentForOffset(d)!;
      final n = Offset(-tg.vector.dy, tg.vector.dx) * 1.3;
      c.drawLine(tg.position - n + tg.vector * 1.2, tg.position + n - tg.vector * 1.2, twist);
    }
    // nails
    for (final x in [8.0, w - 8]) {
      c.drawCircle(Offset(x, 10), 5, Paint()..color = Colors.black.withOpacity(.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
      c.drawCircle(Offset(x, 8), 5, Paint()..shader = const RadialGradient(center: Alignment(-.3, -.4), colors: [Color(0xFFE8E2D8), Color(0xFF7A6E60)])
          .createShader(Rect.fromCircle(center: Offset(x, 8), radius: 5)));
    }
    // leaves + marigolds
    final count = (w / 15.6).floor();
    for (int i = 0; i < count; i++) {
      final x = 14 + i * 15.6, y = sag(x) + .5;
      if (i % 3 == 1) {
        _marigold(c, Offset(x, y + 4));
      } else {
        final sway = math.sin(t * (2 * math.pi / (2.6 + (i % 4) * .3)) - i * .2) * 3.5;
        _leaf(c, Offset(x, y), (i.isOdd ? -6 : 7) + sway);
      }
    }
  }

  void _leaf(Canvas c, Offset at, double deg) {
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(deg * math.pi / 180);
    final p = Path()..moveTo(0, 0)..cubicTo(-6, 8, -6, 22, 0, 34)..cubicTo(6, 22, 6, 8, 0, 0)..close();
    c.drawPath(p.shift(const Offset(1.5, 2)), Paint()..color = Colors.black.withOpacity(.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
    c.drawPath(p, Paint()..shader = const LinearGradient(colors: [Color(0xFF1F5A1E), Color(0xFF3E8A2E), Color(0xFF4E9F3A), Color(0xFF2A6B24)], stops: [0, .45, .55, 1])
        .createShader(const Rect.fromLTWH(-6, 0, 12, 34)));
    final vein = Paint()..color = const Color(0xFF9BD67A).withOpacity(.6)..strokeWidth = .7;
    c.drawLine(const Offset(0, 1), const Offset(0, 32), vein);
    for (final v in [8.0, 13.0, 18.0, 23.0]) {
      c.drawLine(Offset(0, v), Offset(-3.5, v - 3), vein..strokeWidth = .4);
      c.drawLine(Offset(0, v), Offset(3.5, v - 3), vein);
    }
    c.drawPath(Path()..moveTo(-2, 4)..cubicTo(-4, 12, -3, 20, -1, 28),
        Paint()..color = Colors.white.withOpacity(.28)..strokeWidth = 1.2..style = PaintingStyle.stroke);
    c.restore();
  }

  void _marigold(Canvas c, Offset at) {
    c.drawCircle(at + const Offset(1, 2), 5.5, Paint()..color = Colors.black.withOpacity(.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
    final petal = Paint()..shader = const RadialGradient(colors: [Color(0xFFFFD15C), Color(0xFFFFA41B), Color(0xFFE37800)], stops: [0, .6, 1])
        .createShader(Rect.fromCircle(center: at, radius: 6));
    for (int k = 0; k < 10; k++) {
      c.save();
      c.translate(at.dx, at.dy);
      c.rotate(k * 36 * math.pi / 180);
      c.drawOval(Rect.fromCenter(center: const Offset(0, -3), width: 4.8, height: 10), petal);
      c.restore();
    }
    c.drawCircle(at, 2.6, Paint()..color = const Color(0xFFC25E00));
    c.drawCircle(at, 1.2, Paint()..color = const Color(0xFF8A3A00));
  }

  @override
  bool shouldRepaint(covariant _ThoranamPainter o) => true;
}

class _PinPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final wood = Paint()..shader = const LinearGradient(colors: [Color(0xFF9C6A36), Color(0xFFE2B37A), Color(0xFFD8A468), Color(0xFF8F5E2E)], stops: [0, .4, .6, 1])
        .createShader(const Rect.fromLTWH(0, 0, 7, 48));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(1, 2, 14, 48), const Radius.circular(3)), Paint()..color = Colors.black.withOpacity(.45)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(1, 0, 6.6, 48), const Radius.circular(2.5)), wood);
    c.save(); c.translate(7.4, 0);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(1, 0, 6.6, 48), const Radius.circular(2.5)), wood);
    c.restore();
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 20, 16, 6), const Radius.circular(1.5)), Paint()..color = const Color(0xFFB9B4AC));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 20, 16, 2), const Radius.circular(1)), Paint()..color = const Color(0xFFEAE6DF));
    c.drawCircle(const Offset(8, 23), 2.4, Paint()..color = const Color(0xFF8D877E)..style = PaintingStyle.stroke..strokeWidth = 1);
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _PaperPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    c.drawRect(r, Paint()..color = const Color(0xFFFBF4E4));
    c.drawRect(r, Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: const Alignment(.2, .2),
        colors: [Colors.white.withOpacity(.55), Colors.white.withOpacity(0)]).createShader(r));
    final line = Paint()..color = const Color(0xFF466EAA).withOpacity(.16)..strokeWidth = 1;
    for (double y = 21; y < s.height; y += 22) { c.drawLine(Offset(0, y), Offset(s.width, y), line); }
    c.drawLine(const Offset(22, 0), Offset(22, s.height), Paint()..color = const Color(0xFFD25050).withOpacity(.28)..strokeWidth = 1);
    // crease across the middle
    final cy = s.height * .46;
    c.drawRect(Rect.fromLTWH(0, cy, s.width, 14), Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.black.withOpacity(.06), Colors.white.withOpacity(.4), Colors.black.withOpacity(.03)]).createShader(Rect.fromLTWH(0, cy, s.width, 14)));
    // folded top-right corner
    final fold = Path()..moveTo(s.width - 26, 0)..lineTo(s.width, 26)..lineTo(s.width - 26, 26)..close();
    c.drawPath(Path()..moveTo(s.width - 26, 0)..lineTo(s.width, 0)..lineTo(s.width, 26)..close(), Paint()..color = const Color(0xFF0F3F33));
    c.drawShadow(fold, Colors.black, 2, false);
    c.drawPath(fold, Paint()..shader = const LinearGradient(colors: [Color(0xFFE8DCC2), Color(0xFFF7EED9)]).createShader(Rect.fromLTWH(s.width - 26, 0, 26, 26)));
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _TornClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final p = Path()..moveTo(0, 0)..lineTo(s.width, 0)..lineTo(s.width, s.height * .96);
    const pts = [.97, .93, .89, .85, .80, .76, .71, .66, .61, .56, .51, .46, .41, .36, .31, .26, .21, .16, .11, .06, .02, 0.0];
    for (int i = 0; i < pts.length; i++) {
      p.lineTo(s.width * pts[i], s.height * (i.isEven ? .984 : .968));
    }
    return p..close();
  }
  @override
  bool shouldReclip(covariant CustomClipper<Path> o) => false;
}

class _PostmarkPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    const g = Color(0xFF2E8B57);
    final ctr = s.center(Offset.zero);
    c.drawCircle(ctr, 22, Paint()..color = g..style = PaintingStyle.stroke..strokeWidth = 1.6);
    c.drawCircle(ctr, 13, Paint()..color = g..style = PaintingStyle.stroke..strokeWidth = .8);
    const text = 'VERIFIED BUYER · AMBHUJAKSHI · ';
    final step = 2 * math.pi / text.length;
    for (int i = 0; i < text.length; i++) {
      final tp = TextPainter(text: TextSpan(text: text[i], style: const TextStyle(fontSize: 5.6, fontWeight: FontWeight.w800, color: g)), textDirection: TextDirection.ltr)..layout();
      final a = -math.pi / 2 + i * step;
      c.save();
      c.translate(ctr.dx + 17.5 * math.cos(a), ctr.dy + 17.5 * math.sin(a));
      c.rotate(a + math.pi / 2);
      tp.paint(c, Offset(-tp.width / 2, -tp.height / 2));
      c.restore();
    }
    c.drawPath(Path()..moveTo(ctr.dx - 6, ctr.dy)..lineTo(ctr.dx - 2, ctr.dy + 4)..lineTo(ctr.dx + 6, ctr.dy - 5),
        Paint()..color = g..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _RingTextPainter extends CustomPainter {
  final String text;
  final Color color;
  _RingTextPainter(this.text, this.color);
  @override
  void paint(Canvas c, Size s) {
    final ctr = s.center(Offset.zero);
    final chars = text.characters.toList();
    final step = 2 * math.pi / chars.length;
    for (int i = 0; i < chars.length; i++) {
      final tp = TextPainter(text: TextSpan(text: chars[i], style: GoogleFonts.poppins(fontSize: 7.2, fontWeight: FontWeight.w700, color: color)),
          textDirection: TextDirection.ltr)..layout();
      final a = -math.pi / 2 + i * step;
      c.save();
      c.translate(ctr.dx + 38 * math.cos(a), ctr.dy + 38 * math.sin(a));
      c.rotate(a + math.pi / 2);
      tp.paint(c, Offset(-tp.width / 2, -tp.height / 2));
      c.restore();
    }
  }
  @override
  bool shouldRepaint(covariant _RingTextPainter o) => o.text != text || o.color != color;
}


// ───────────────────────────── "See all" page ─────────────────────────────
/// "Every letter we got" — same emerald wall + thoranam; rating summary, filters and
/// every review as a swinging letter on a clothespin (2 staggered columns).
class ReviewsAllPage extends StatefulWidget {
  final ReviewsSettings settings;
  final List<ReviewLetter> items;
  final double avg;
  final int count;
  final VoidCallback? onWrite;
  const ReviewsAllPage({super.key, required this.settings, required this.items, required this.avg, required this.count, this.onWrite});
  @override
  State<ReviewsAllPage> createState() => _ReviewsAllPageState();
}

class _ReviewsAllPageState extends State<ReviewsAllPage> with TickerProviderStateMixin {
  late final AnimationController _swing = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400))..repeat();
  late final AnimationController _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
  String _filter = 'all'; // all | five | photos | product:<name>

  @override
  void dispose() {
    _swing.dispose();
    _in.dispose();
    super.dispose();
  }

  List<ReviewLetter> get _shown {
    final List<ReviewLetter> all = widget.items;
    if (_filter == 'five') return all.where((ReviewLetter r) => r.stars >= 5).toList();
    if (_filter == 'photos') return all.where((ReviewLetter r) => r.photoUrl.isNotEmpty).toList();
    if (_filter.startsWith('product:')) {
      final String p = _filter.substring(8);
      return all.where((ReviewLetter r) => r.productName == p).toList();
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final ReviewsSettings s = widget.settings;
    final double top = MediaQuery.of(context).padding.top;
    final List<ReviewLetter> shown = _shown;
    final List<ReviewLetter> left = <ReviewLetter>[for (int i = 0; i < shown.length; i += 2) shown[i]];
    final List<ReviewLetter> right = <ReviewLetter>[for (int i = 1; i < shown.length; i += 2) shown[i]];
    return Scaffold(
      backgroundColor: s.wallBottom,
      body: Stack(children: <Widget>[
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[s.wallTop, s.wallMid, s.wallBottom], stops: const <double>[0, .4, 1]),
            ),
          ),
        ),
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: <Widget>[
            SliverToBoxAdapter(child: SizedBox(height: top + 6)),
            SliverToBoxAdapter(child: AnimatedBuilder(animation: _swing, builder: (_, __) => SizedBox(height: 40, child: CustomPaint(painter: _ToranPainter(_swing.value))))),
            SliverToBoxAdapter(child: _header(s)),
            SliverToBoxAdapter(child: _summary(s)),
            SliverToBoxAdapter(child: _chips(s)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 30, 12, 0),
                child: shown.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text('No letters here yet', textAlign: TextAlign.center, style: GoogleFonts.kalam(fontSize: 16, color: const Color(0xFFC9DCD3))),
                      )
                    : Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                        Expanded(child: Column(children: <Widget>[for (int i = 0; i < left.length; i++) _letter(left[i], i * 2)])),
                        const SizedBox(width: 12),
                        Expanded(child: Padding(padding: const EdgeInsets.only(top: 36), child: Column(children: <Widget>[for (int i = 0; i < right.length; i++) _letter(right[i], i * 2 + 1)]))),
                      ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                child: Column(children: <Widget>[
                  Text('That\'s every letter so far — thank you for writing to us 💛', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFC9DCD3))),
                  const SizedBox(height: 12),
                  _writeBtn(s, big: true),
                ]),
              ),
            ),
          ],
        ),
        Positioned(
          top: top + 8,
          left: 14,
          child: GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(.3), border: Border.all(color: s.gold, width: 1.5)),
              child: Icon(Icons.chevron_left_rounded, color: s.gold, size: 26),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _writeBtn(ReviewsSettings s, {bool big = false}) => GestureDetector(
        onTap: widget.onWrite ?? () => showWriteToAmmaSheet(context, products: widget.items.map((ReviewLetter r) => r.productName).toList()),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: big ? 22 : 14, vertical: big ? 12 : 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(big ? 16 : 14),
            gradient: const LinearGradient(colors: <Color>[Color(0xFFFFE6A6), Color(0xFFE2AE4E)]),
            boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x66000000), blurRadius: 14, offset: Offset(0, 6), spreadRadius: -6)],
          ),
          child: Text(big ? s.writeLabel : '✍️ Write a letter', style: GoogleFonts.poppins(fontSize: big ? 13 : 11, fontWeight: FontWeight.w700, color: const Color(0xFF4A2A10))),
        ),
      );

  Widget _header(ReviewsSettings s) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
        child: Column(children: <Widget>[
          Text(s.eyebrow, style: GoogleFonts.poppins(fontSize: 9.5, letterSpacing: 3, fontWeight: FontWeight.w700, color: s.accent)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(TextSpan(children: <InlineSpan>[
              TextSpan(text: 'Every ', style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, color: const Color(0xFFFBEFDC))),
              TextSpan(text: 'letter', style: GoogleFonts.playfairDisplay(fontSize: 28, fontStyle: FontStyle.italic, fontWeight: FontWeight.w700, color: s.accent)),
              TextSpan(text: ' we got', style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, color: const Color(0xFFFBEFDC))),
            ])),
          ),
          const SizedBox(height: 8),
          _writeBtn(s),
        ]),
      );

  Widget _summary(ReviewsSettings s) {
    final int n = widget.items.length;
    int c(int k) => widget.items.where((ReviewLetter r) => r.stars == k).length;
    final double avg = widget.avg > 0 ? widget.avg : (n == 0 ? 0 : widget.items.fold<int>(0, (int a, ReviewLetter r) => a + r.stars) / n);
    final int total = widget.count > 0 ? widget.count : n;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black.withOpacity(.25), borderRadius: BorderRadius.circular(18), border: Border.all(color: s.gold.withOpacity(.3))),
      child: Row(children: <Widget>[
        Container(
          width: 74,
          height: 74,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(colors: <Color>[Color(0xFFB8862E), Color(0xFFFFE7A8), Color(0xFFD9A441), Color(0xFFFFF1C4), Color(0xFFB8862E)]),
            boxShadow: <BoxShadow>[BoxShadow(color: const Color(0xFFFFBE5A).withOpacity(.3), blurRadius: 24)],
          ),
          child: Container(
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: <Color>[Color(0xFFFFF4D2), Color(0xFFE8BE62), Color(0xFFC9963A)], stops: <double>[0, .7, 1])),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              Text(avg.toStringAsFixed(1), style: GoogleFonts.playfairDisplay(fontSize: 22, height: 1, fontWeight: FontWeight.w700, color: const Color(0xFF4A2A10))),
              Text('★★★★★', style: TextStyle(fontSize: 7.5, color: const Color(0xFF8A5A10).withOpacity(.9))),
            ]),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            for (final int k in <int>[5, 4, 3, 2])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: <Widget>[
                  SizedBox(width: 18, child: Text('$k★', style: GoogleFonts.poppins(fontSize: 9.5, color: const Color(0xFFFBEFDC)))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        height: 5,
                        child: Stack(children: <Widget>[
                          Container(color: Colors.white.withOpacity(.15)),
                          FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: n == 0 ? 0 : (c(k) / n * _in.value).clamp(0.0, 1.0), child: Container(color: s.gold)),
                        ]),
                      ),
                    ),
                  ),
                  SizedBox(width: 34, child: Text('${n == 0 ? 0 : (c(k) * 100 / n).round()}%', textAlign: TextAlign.right, style: GoogleFonts.poppins(fontSize: 9.5, color: const Color(0xFFC9DCD3)))),
                ]),
              ),
            const SizedBox(height: 3),
            Text('from ${total.toString()} verified buyers', style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFFC9DCD3))),
          ]),
        ),
      ]),
    );
  }

  Widget _chips(ReviewsSettings s) {
    final List<String> products = <String>[];
    for (final ReviewLetter r in widget.items) {
      if (r.productName.isNotEmpty && !products.contains(r.productName)) products.add(r.productName);
    }
    final List<MapEntry<String, String>> chips = <MapEntry<String, String>>[
      const MapEntry<String, String>('all', 'All'),
      const MapEntry<String, String>('five', '5★ only'),
      if (widget.items.any((ReviewLetter r) => r.photoUrl.isNotEmpty)) const MapEntry<String, String>('photos', '📷 With photos'),
      for (final String p in products.take(6)) MapEntry<String, String>('product:$p', p),
    ];
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        children: <Widget>[
          for (final MapEntry<String, String> c in chips)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _filter = c.key);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _filter == c.key ? s.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _filter == c.key ? Colors.transparent : s.gold.withOpacity(.35)),
                  ),
                  child: Text(c.value, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _filter == c.key ? s.wallMid : const Color(0xFFFBEFDC))),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _letter(ReviewLetter r, int i) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_swing, _in]),
      builder: (_, Widget? child) {
        final double appear = Curves.easeOut.transform(((_in.value - math.min(i, 8) * .06) / .5).clamp(0.0, 1.0));
        final double ang = math.sin((_swing.value + i * .23) * 2 * math.pi) * 2.2 * math.pi / 180;
        return Opacity(
          opacity: appear,
          child: Transform.rotate(angle: ang, alignment: const Alignment(0, -1.1), child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: Stack(clipBehavior: Clip.none, children: <Widget>[
          ClipPath(
            clipper: _TornEdge(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 16),
              decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Color(0xFFFFFBF1), Color(0xFFFBF0DA)])),
              child: CustomPaint(
                painter: _RulePainter(),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  if (r.productName.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: r.tagBg, borderRadius: BorderRadius.circular(6)),
                      child: Text(r.productName.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.w700, color: r.tagFg)),
                    ),
                  const SizedBox(height: 4),
                  Text('★' * r.stars.clamp(1, 5), style: const TextStyle(fontSize: 11, letterSpacing: 1, color: Color(0xFFE39B1C))),
                  const SizedBox(height: 3),
                  Text(r.text, style: GoogleFonts.kalam(fontSize: 12.5, height: 1.45, color: const Color(0xFF24325E))),
                  if (r.photoUrl.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Center(child: Transform.rotate(angle: -3 * math.pi / 180, child: _Polaroid(url: r.photoUrl, caption: r.photoCaption))),
                  ],
                  const SizedBox(height: 6),
                  Text('— ${r.name}', style: GoogleFonts.dancingScript(fontSize: 17, height: 1, fontWeight: FontWeight.w700, color: const Color(0xFF1F3A8A))),
                  if (r.meta.isNotEmpty) Text(r.meta, style: GoogleFonts.poppins(fontSize: 8.5, color: const Color(0xFF8A7660))),
                ]),
              ),
            ),
          ),
          // wooden clothespin
          Positioned(
            top: -16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 13,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(2), bottom: Radius.circular(4)),
                  gradient: const LinearGradient(colors: <Color>[Color(0xFF8C5A2B), Color(0xFFD9A866), Color(0xFFA8743C)], stops: <double>[0, .45, 1]),
                  boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withOpacity(.4), blurRadius: 3, offset: const Offset(0, 2))],
                ),
              ),
            ),
          ),
          if (r.verified)
            Positioned(
              right: 6,
              top: 6,
              child: Transform.rotate(
                angle: -14 * math.pi / 180,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF2E7D32).withOpacity(.8), width: 1.3)),
                  alignment: Alignment.center,
                  child: Text('VERIFIED\nBUYER', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 5.5, height: 1.1, fontWeight: FontWeight.w700, color: const Color(0xFF2E7D32))),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

class _TornEdge extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final Path p = Path()..lineTo(s.width, 0)..lineTo(s.width, s.height - 6);
    const int n = 8;
    for (int i = n; i >= 0; i--) {
      p.lineTo(s.width * i / n, i.isEven ? s.height : s.height - 6);
    }
    return p..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _RulePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final Paint p = Paint()..color = const Color(0x1424325E)..strokeWidth = 1;
    for (double y = 22; y < s.height; y += 22) {
      c.drawLine(Offset(0, y), Offset(s.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ToranPainter extends CustomPainter {
  final double t;
  _ToranPainter(this.t);
  @override
  void paint(Canvas c, Size s) {
    final Rect bar = Rect.fromLTWH(0, 0, s.width, 6);
    c.drawRect(bar, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Color(0xFFD8B47A), Color(0xFF9C7440)]).createShader(bar));
    const int n = 13;
    for (int i = 0; i < n; i++) {
      final double x = 10 + (s.width - 20) * i / (n - 1);
      final double sway = math.sin((t + i * .15) * 2 * math.pi) * .14;
      c.save();
      c.translate(x, 5);
      c.rotate(sway);
      if (i % 3 == 2) {
        c.drawCircle(const Offset(0, 10), 8, Paint()..shader = const RadialGradient(colors: <Color>[Color(0xFFFFD54F), Color(0xFFFB8C00), Color(0xFFE65100)], stops: <double>[0, .7, 1]).createShader(Rect.fromCircle(center: const Offset(0, 10), radius: 8)));
      } else {
        final Path leaf = Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(9, 12, 0, 28)
          ..quadraticBezierTo(-9, 12, 0, 0);
        c.drawPath(leaf, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Color(0xFF5DBB63), Color(0xFF1F7A35)]).createShader(const Rect.fromLTWH(-9, 0, 18, 28)));
        c.drawLine(const Offset(0, 2), const Offset(0, 26), Paint()..color = const Color(0x553A6B2A)..strokeWidth = .8);
      }
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ToranPainter o) => o.t != t;
}


// ───────────────────────────── write to Amma ─────────────────────────────
// Sends the letter to the admin dashboard. It shows in the app only after the admin approves it.
const String _kSubmitUrl = 'https://admin.adhvaithafoods.in/api/reviews/submit';

Future<void> showWriteToAmmaSheet(BuildContext context, {List<String> products = const <String>[]}) {
  HapticFeedback.lightImpact();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _WriteSheet(products: products.where((String p) => p.trim().isNotEmpty).toSet().toList()),
  );
}

class _WriteSheet extends StatefulWidget {
  final List<String> products;
  const _WriteSheet({required this.products});
  @override
  State<_WriteSheet> createState() => _WriteSheetState();
}

class _WriteSheetState extends State<_WriteSheet> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _text = TextEditingController();
  String? _product;
  int _stars = 5;
  bool _sending = false;
  bool _sent = false;
  String? _error;

  static const Color _paper = Color(0xFFFBF3E2);
  static const Color _ink = Color(0xFF3A2414);
  static const Color _maroon = Color(0xFF7A1426);

  @override
  void dispose() {
    _name.dispose(); _city.dispose(); _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String name = _name.text.trim(), text = _text.text.trim();
    if (name.length < 2) { setState(() => _error = 'Please write your name'); return; }
    if (text.length < 10) { setState(() => _error = 'Please write a few more words for Amma'); return; }
    setState(() { _sending = true; _error = null; });
    try {
      final http.Response r = await http
          .post(Uri.parse(_kSubmitUrl),
              headers: const <String, String>{'Content-Type': 'application/json'},
              body: jsonEncode(<String, dynamic>{'name': name, 'city': _city.text.trim(), 'productName': _product ?? '', 'stars': _stars, 'text': text}))
          .timeout(const Duration(seconds: 15));
      Map<String, dynamic> j = <String, dynamic>{};
      try { j = jsonDecode(r.body) as Map<String, dynamic>; } catch (_) {}
      if (r.statusCode == 200 && j['success'] != false) {
        if (mounted) setState(() { _sent = true; _sending = false; });
      } else {
        if (mounted) setState(() { _error = (j['error'] ?? 'Could not send. Please try again.').toString(); _sending = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _error = 'No internet? Please try again.'; _sending = false; });
    }
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFA8957F)),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE6D6BC))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE6D6BC))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _maroon, width: 1.4)),
      );

  @override
  Widget build(BuildContext context) {
    final double bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .9),
        decoration: const BoxDecoration(color: _paper, borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: _sent ? _thanks() : _form(),
          ),
        ),
      ),
    );
  }

  Widget _thanks() => Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        _grip(),
        const SizedBox(height: 18),
        const Text('💌', style: TextStyle(fontSize: 46)),
        const SizedBox(height: 10),
        Text('Thank you!', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: _ink)),
        const SizedBox(height: 6),
        Text('Amma will read your letter. Once approved, it will appear in Letters from Home.',
            textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, height: 1.45, color: const Color(0xFF6B5442))),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: _maroon, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: Text('Done', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ]);

  Widget _grip() => Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFD9C6A8), borderRadius: BorderRadius.circular(2))));

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 14),
        child: Text(t, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B5442))),
      );

  Widget _form() => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: <Widget>[
        _grip(),
        const SizedBox(height: 14),
        Text('Dear Amma,', style: GoogleFonts.dancingScript(fontSize: 30, fontWeight: FontWeight.w700, color: _maroon)),
        Text('Tell us how it tasted at your home', style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF8A7360))),
        _label('Your rating'),
        Row(children: <Widget>[
          for (int i = 1; i <= 5; i++)
            GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); setState(() => _stars = i); },
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded, size: 34, color: const Color(0xFFE2A93B)),
              ),
            ),
        ]),
        if (widget.products.isNotEmpty) ...<Widget>[
          _label('Which product? (optional)'),
          Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
            for (final String p in widget.products)
              ChoiceChip(
                label: Text(p, style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: _product == p ? Colors.white : _ink)),
                selected: _product == p,
                selectedColor: _maroon,
                backgroundColor: Colors.white,
                showCheckmark: false,
                side: BorderSide(color: _product == p ? _maroon : const Color(0xFFE6D6BC)),
                onSelected: (bool v) => setState(() => _product = v ? p : null),
              ),
          ]),
        ],
        _label('Your letter'),
        TextField(controller: _text, maxLines: 5, maxLength: 600, textCapitalization: TextCapitalization.sentences, style: GoogleFonts.poppins(fontSize: 13.5, color: _ink), decoration: _dec('The avakaya reminded me of my grandmother…')),
        Row(children: <Widget>[
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            _label('Your name'),
            TextField(controller: _name, maxLength: 40, textCapitalization: TextCapitalization.words, style: GoogleFonts.poppins(fontSize: 13.5, color: _ink), decoration: _dec('Sujatha').copyWith(counterText: '')),
          ])),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            _label('City'),
            TextField(controller: _city, maxLength: 40, textCapitalization: TextCapitalization.words, style: GoogleFonts.poppins(fontSize: 13.5, color: _ink), decoration: _dec('Hyderabad').copyWith(counterText: '')),
          ])),
        ]),
        if (_error != null) Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(_error!, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFB42318))),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _sending ? null : _send,
            style: ElevatedButton.styleFrom(backgroundColor: _maroon, disabledBackgroundColor: _maroon.withOpacity(.6), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: _sending
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : Text('Send to Amma 💌', style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 8),
        Center(child: Text('Your letter appears in the app after our team reads it.', style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF9A8470)))),
      ]);
}
