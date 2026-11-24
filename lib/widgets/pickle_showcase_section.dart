// pickle_showcase_section.dart — AmbhuJakshi "Pickles showcase" (matches pickles_professional.mp4)
// Full-width, no borders. Photos cross-fade with a slow camera move and fade into the dark background,
// round thumbnails with progress rings, badge, name letter-rise, cure tag, weight chips, price, Add to cart.
// Everything (photos, captions, texts, weights, prices, order) comes from the admin dashboard:
//   pickle_showcase_backend.js → GET /api/showcase/pickles
//
// pubspec.yaml:  http: ^1.2.0   google_fonts: ^6.2.1
//
// Usage on the home page (inside your scroll view / ListView):
//   PickleShowcaseSection(
//     apiBase: 'https://your-api.com/api',
//     onAddToCart: (ShowcaseItem item, ShowcaseVariant v) => CartService.instance.add(item.productId, weight: v.label, price: v.price),
//     onOpenProduct: (ShowcaseItem item) => Navigator.pushNamed(context, '/product', arguments: item.productId),
//     onViewAll: () => Navigator.pushNamed(context, '/category', arguments: 'pickle'),
//   )

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'love_button.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

const Color _bgTop = Color(0xFF2A1C14);
const Color _bgBot = Color(0xFF120B08);
const Color _cream = Color(0xFFF6EBDD);
const Color _muted = Color(0xFFCBB8A6);
const Color _dim = Color(0xFF8E7B6C);
const Color _ink = Color(0xFF1A110C);

const double _dw = 390.0; // design width
const double _dh = 575.0; // design height
const double _winH = 300.0;
const int _fadeMs = 550;

class ShowcaseVariant {
  final String id, label;
  final double price, mrp;
  ShowcaseVariant(this.id, this.label, this.price, this.mrp);
}

class ShowcaseShot {
  final String image, caption;
  final int ms;
  ShowcaseShot(this.image, this.caption, this.ms);
}

class ShowcaseItem {
  final String id, productId, name, badge, description, cureText, thumb;
  final List<ShowcaseShot> shots;
  final List<ShowcaseVariant> variants;
  ShowcaseItem(this.id, this.productId, this.name, this.badge, this.description, this.cureText, this.thumb, this.shots, this.variants);
  int get totalMs => shots.fold<int>(0, (int a, ShowcaseShot s) => a + s.ms);
}

class PickleShowcaseSection extends StatefulWidget {
  final String apiBase;
  final String sectionKey;
  final Map<String, String>? headers;
  final void Function(ShowcaseItem item, ShowcaseVariant variant)? onAddToCart;
  final void Function(ShowcaseItem item)? onOpenProduct;
  final VoidCallback? onViewAll;
  const PickleShowcaseSection({super.key, required this.apiBase, this.sectionKey = 'pickles', this.headers, this.onAddToCart, this.onOpenProduct, this.onViewAll});
  @override
  State<PickleShowcaseSection> createState() => _PickleShowcaseSectionState();
}

class _PickleShowcaseSectionState extends State<PickleShowcaseSection> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _last = Duration.zero;
  double _ms = 0; // playback clock
  double _holdMs = 0; // pause after the user taps a weight
  int _cur = 0; // product shown — changes only when the user taps a thumbnail / swipes
  bool _firstPass = true;
  final Map<int, int> _sel = <int, int>{}; // item index → chosen weight
  List<ShowcaseItem> _items = <ShowcaseItem>[];
  String _eyebrow = 'PICKLES · HAND-MIXED';
  String _viewAll = 'View all →';
  bool _enabled = true, _loaded = false, _precached = false;

  static const List<List<double>> _moves = <List<double>>[
    <double>[1.16, 1.02, -3, 2, 2, -1],
    <double>[1.02, 1.16, 3, -2, -1, 2],
    <double>[1.14, 1.0, 0, 0, -2, 0],
    <double>[1.0, 1.12, 2, -2, 0, -2],
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _load();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  String _abs(String u) {
    if (u.isEmpty || u.startsWith('http')) return u;
    final String origin = widget.apiBase.replaceAll(RegExp(r'/api/?$'), '');
    return u.startsWith('/') ? '$origin$u' : '$origin/$u';
  }

  double _n(dynamic v) => (v is num) ? v.toDouble() : (double.tryParse('$v') ?? 0.0);

  Future<void> _load() async {
    final fallbackItems = <ShowcaseItem>[
      ShowcaseItem(
        '1', 'mango_avakaya', 'Bellam Avakaya', 'TRADITIONAL · 2026',
        'Sweet and spicy Andhra mango pickle made with fresh raw mangoes and pure jaggery.',
        'Matured in sun-kissed ceramic jars', 'assets/images/avakaya_pickle.png',
        [ShowcaseShot('assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg', 'Traditional cut raw mangoes', 4000)],
        [ShowcaseVariant('v1', '250g', 120, 150), ShowcaseVariant('v2', '500g', 228, 280)]
      ),
      ShowcaseItem(
        '2', 'idli_karam', 'Special Idli Karam', 'GUNPOWDER · SPICY',
        'Gunpowder spice for idlis, dosas and hot rice with pure sesame oil.',
        'Stone-ground aromatic spices', 'assets/images/special_idli_karam_podi.png',
        [ShowcaseShot('assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg', 'Freshly ground spices', 4000)],
        [ShowcaseVariant('v1', '250g', 110, 140)]
      )
    ];

    setState(() {
      _items = fallbackItems;
      _loaded = true;
    });
    if (_items.isNotEmpty && !_ticker.isActive) _ticker.start();

    try {
      final http.Response r = await http.get(Uri.parse('${widget.apiBase}/showcase/${widget.sectionKey}'), headers: widget.headers).timeout(const Duration(seconds: 4));
      if (!mounted) return;
      if (r.statusCode != 200 || r.body.trim().startsWith('<!DOCTYPE') || r.body.trim().startsWith('<html')) return;
      final Map<String, dynamic> j = jsonDecode(r.body) as Map<String, dynamic>;
      final Map<String, dynamic> s = (j['settings'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final List<ShowcaseItem> items = <ShowcaseItem>[];
      for (final dynamic raw in (j['items'] as List?) ?? <dynamic>[]) {
        final Map<String, dynamic> m = raw as Map<String, dynamic>;
        final List<ShowcaseShot> shots = <ShowcaseShot>[];
        for (final dynamic sh in (m['shots'] as List?) ?? <dynamic>[]) {
          final Map<String, dynamic> x = sh as Map<String, dynamic>;
          final String img = _abs('${x['image'] ?? ''}');
          if (img.isNotEmpty) shots.add(ShowcaseShot(img, '${x['caption'] ?? ''}', (_n(x['ms']) <= 0 ? 2100.0 : _n(x['ms'])).round()));
        }
        final List<ShowcaseVariant> vs = <ShowcaseVariant>[];
        for (final dynamic v in (m['variants'] as List?) ?? <dynamic>[]) {
          final Map<String, dynamic> x = v as Map<String, dynamic>;
          vs.add(ShowcaseVariant('${x['id'] ?? ''}', '${x['label'] ?? ''}', _n(x['price']), _n(x['mrp'])));
        }
        if (shots.isEmpty || vs.isEmpty) continue;
        items.add(ShowcaseItem('${m['id']}', '${m['productId'] ?? ''}', '${m['name'] ?? ''}', '${m['badge'] ?? ''}', '${m['description'] ?? ''}', '${m['cureText'] ?? ''}',
            _abs('${m['thumb'] ?? ''}'), shots, vs));
      }
      if (items.isNotEmpty && mounted) {
        setState(() {
          _enabled = s['enabled'] != false;
          _eyebrow = '${s['eyebrow'] ?? _eyebrow}';
          _viewAll = '${s['viewAllText'] ?? _viewAll}';
          _items = items;
          _loaded = true;
        });
      }
    } catch (_) {}
  }

  ImageProvider _img(String url, int w) {
    if (url.startsWith('assets/')) {
      return AssetImage(url);
    }
    return ResizeImage(NetworkImage(url), width: w);
  }

  void _precache() {
    if (_precached || _items.isEmpty) return;
    _precached = true;
    for (final ShowcaseItem it in _items) {
      if (it.thumb.isNotEmpty) precacheImage(_img(it.thumb, 160), context).catchError((Object e) {});
      for (final ShowcaseShot s in it.shots) {
        precacheImage(_img(s.image, 900), context).catchError((Object e) {});
      }
    }
  }

  void _tick(Duration elapsed) {
    final double dt = (elapsed - _last).inMicroseconds / 1000.0;
    _last = elapsed;
    if (_holdMs > 0) {
      _holdMs -= dt;
    } else {
      _ms += dt;
    }
    // stay on the current product: its own photos keep their slow camera move,
    // but it never moves on to the next product by itself
    if (_items.isNotEmpty) {
      if (_cur >= _items.length) _cur = 0;
      final ShowcaseItem it = _items[_cur];
      final double start = _startOf(_cur).toDouble();
      final double end = start + it.totalMs;
      if (_ms >= end) {
        if (it.shots.length > 1) {
          // loop this product's photos (skip the intro so the name doesn't re-animate)
          final double loopStart = start + it.shots.first.ms;
          final double loopLen = end - loopStart;
          _ms = loopStart + ((_ms - end) % loopLen);
        } else {
          _ms = end - 1;
        }
      }
    }
    if (mounted) setState(() {});
  }

  int get _cycle => _items.fold<int>(0, (int a, ShowcaseItem i) => a + i.totalMs);

  int _startOf(int idx) {
    int s = 0;
    for (int i = 0; i < idx; i++) {
      s += _items[i].totalMs;
    }
    return s;
  }

  void _jump(int idx) {
    if (_items.isEmpty) return;
    idx = (idx % _items.length + _items.length) % _items.length;
    setState(() {
      _cur = idx;
      _ms = _startOf(idx).toDouble();
      _holdMs = 0;
      _firstPass = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox(height: 0.0);
    if (!_enabled || _items.isEmpty) return const SizedBox.shrink();
    _precache();
    // where are we?
    int p = 0;
    double acc = 0;
    while (p < _items.length - 1 && _ms >= acc + _items[p].totalMs) {
      acc += _items[p].totalMs;
      p++;
    }
    final ShowcaseItem it = _items[p];
    final double since = _ms - acc;
    int s = 0;
    double sAcc = 0;
    while (s < it.shots.length - 1 && since >= sAcc + it.shots[s].ms) {
      sAcc += it.shots[s].ms;
      s++;
    }
    final double ls = since - sAcc;

    return LayoutBuilder(builder: (BuildContext c, BoxConstraints bc) {
      final double w = bc.maxWidth.isFinite ? bc.maxWidth : MediaQuery.of(context).size.width;
      return SizedBox(
        width: w,
        height: w * _dh / _dw,
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(
            width: _dw,
            height: _dh,
            child: _stage(p, it, since, s, ls),
          ),
        ),
      );
    });
  }

  Widget _stage(int p, ShowcaseItem it, double since, int s, double ls) {
    // previous shot (for the cross-fade)
    ShowcaseShot? prevShot;
    int prevIdx = 0;
    double prevLocal = 0;
    if (s > 0) {
      prevShot = it.shots[s - 1];
      prevIdx = s - 1;
      prevLocal = prevShot.ms + ls;
    } else if (!(_firstPass && p == 0)) {
      final ShowcaseItem pi = _items[(p - 1 + _items.length) % _items.length];
      prevShot = pi.shots.last;
      prevIdx = pi.shots.length - 1;
      prevLocal = prevShot.ms + ls;
    }
    final ShowcaseShot cur = it.shots[s];
    final double curOp = (ls / _fadeMs).clamp(0.0, 1.0);

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: <Widget>[
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(center: Alignment(0, 1), radius: 1.1, colors: <Color>[_bgTop, _bgBot]),
            ),
          ),
        ),
        // photo window, fading into the background
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: _winH,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onOpenProduct?.call(it),
            // swipe left / right to change product
            onHorizontalDragEnd: (DragEndDetails d) {
              final double v = d.primaryVelocity ?? 0;
              if (v.abs() > 200 && _items.length > 1) _jump(v < 0 ? p + 1 : p - 1);
            },
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (Rect r) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Colors.black, Colors.black, Colors.transparent],
                stops: <double>[0.0, 0.62, 1.0],
              ).createShader(r),
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    if (prevShot != null && curOp < 1.0) _shot(prevShot, prevIdx, prevLocal),
                    Opacity(opacity: curOp, child: _shot(cur, s, ls)),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[Color(0x8C140500), Color(0x00140500), Color(0x00140500), Color(0x8C140500)],
                          stops: <double>[0.0, 0.28, 0.7, 1.0],
                        ),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(radius: 0.9, colors: <Color>[Color(0x00000000), Color(0x00000000), Color(0x66000000)], stops: <double>[0.0, 0.55, 1.0]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // progress bars
        Positioned(
          left: 16,
          right: 16,
          top: 14,
          child: Row(
            children: <Widget>[
              for (int k = 0; k < _items.length; k++) ...<Widget>[
                if (k > 0) const SizedBox(width: 5),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Container(
                      height: 3,
                      color: Colors.white.withOpacity(0.28),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: k < p ? 1.0 : (k == p ? (since / it.totalMs).clamp(0.0, 1.0) : 0.0),
                        child: Container(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        // eyebrow + view all
        Positioned(
          left: 16,
          right: 16,
          top: 26,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _eyebrow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 2.6, color: const Color(0xE6E2B46A), shadows: const <Shadow>[Shadow(color: Color(0x99000000), blurRadius: 4, offset: Offset(0, 1))]),
                ),
              ),
              GestureDetector(
                onTap: widget.onViewAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.18))),
                  child: Text(_viewAll, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
        // caption
        Positioned(
          right: 22,
          left: 120,
          top: 222,
          child: Opacity(
            opacity: ((ls - 300) / 700).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 6 * (1 - ((ls - 300) / 700).clamp(0.0, 1.0))),
              child: Text(
                cur.caption,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.yatraOne(fontSize: 13, color: _cream, shadows: const <Shadow>[Shadow(color: Color(0xB3000000), blurRadius: 8, offset: Offset(0, 2))]),
              ),
            ),
          ),
        ),
        // thumbnails
        Positioned(
          left: 0,
          right: 0,
          top: 268,
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (int k = 0; k < _items.length; k++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: () => _jump(k),
                    child: _thumb(_items[k], k == p, k < p ? 1.0 : (k == p ? (since / it.totalMs).clamp(0.0, 1.0) : 0.0)),
                  ),
                ),
            ],
          ),
        ),
        // info
        Positioned(left: 16, right: 16, bottom: 16, child: _info(p, it, since)),
      ],
    );
  }

  Widget _shot(ShowcaseShot sh, int idx, double local) {
    final List<double> m = _moves[idx % _moves.length];
    final double k = (local / (sh.ms + 700)).clamp(0.0, 1.0);
    final double e = k < 0.5 ? 2 * k * k : 1 - math.pow(-2 * k + 2, 2).toDouble() / 2;
    final double sc = m[0] + (m[1] - m[0]) * e;
    final double x = m[2] + (m[3] - m[2]) * e;
    final double y = m[4] + (m[5] - m[4]) * e;
    return Transform.scale(
      scale: sc,
      child: Transform.translate(
        offset: Offset(x * _dw / 100, y * _winH / 100),
        child: Image(
          image: _img(sh.image, 900),
          fit: BoxFit.cover,
          width: _dw,
          height: _winH,
          gaplessPlayback: true,
          errorBuilder: (BuildContext c, Object e, StackTrace? st) => const ColoredBox(color: _bgTop),
        ),
      ),
    );
  }

  Widget _thumb(ShowcaseItem item, bool on, double prog) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 400),
      scale: on ? 1.12 : 1.0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 400),
        offset: Offset(0, on ? -0.08 : 0.0),
        child: SizedBox(
          width: 52,
          height: 52,
          child: CustomPaint(
            painter: _RingPainter(prog, on),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _bgBot, width: 2)),
                clipBehavior: Clip.antiAlias,
                foregroundDecoration: on ? null : const BoxDecoration(shape: BoxShape.circle, color: Color(0x59000000)),
                child: item.thumb.isEmpty
                    ? const ColoredBox(color: _bgTop)
                    : Image(image: _img(item.thumb, 160), fit: BoxFit.cover, errorBuilder: (BuildContext c, Object e, StackTrace? st) => const ColoredBox(color: _bgTop)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _in(double since, double delay, [double dur = 500]) => Curves.easeOutCubic.transform(((since - delay) / dur).clamp(0.0, 1.0));

  Widget _block(double v, Widget child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: child));

  Widget _info(int p, ShowcaseItem it, double since) {
    final int vi = math.max(0, math.min(_sel[p] ?? 0, it.variants.length - 1));
    final ShowcaseVariant v = it.variants[vi];
    String rs(double x) => '₹${x % 1 == 0 ? x.toInt() : x.toStringAsFixed(2)}';
    final List<String> letters = it.name.split('');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _block(
          _in(since, 450),
          GestureDetector(
            onTap: () => widget.onOpenProduct?.call(it),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (it.badge.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0x99E2B46A))),
                    child: Text(it.badge.toUpperCase(), style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: const Color(0xFFE2B46A))),
                  ),
                const SizedBox(height: 7),
                SizedBox(
                  height: 36,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        for (int k = 0; k < letters.length; k++)
                          Builder(builder: (BuildContext c) {
                            final double t = ((since - 500 - k * 45) / 450).clamp(0.0, 1.0);
                            final double e = Curves.easeOutBack.transform(t);
                            return Opacity(
                              opacity: t,
                              child: Transform.translate(
                                offset: Offset(0, 14 * (1 - e)),
                                child: Transform.rotate(
                                  angle: 0.105 * (1 - e),
                                  child: Text(
                                    letters[k],
                                    style: GoogleFonts.rozhaOne(fontSize: 30, height: 1.1, color: _cream, shadows: const <Shadow>[Shadow(color: Color(0x99000000), blurRadius: 12, offset: Offset(0, 3))]),
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(it.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11, color: _muted)),
              ],
            ),
          ),
        ),
        if (it.cureText.isNotEmpty)
          _block(
            _in(since, 580),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.18))),
                child: Text(it.cureText, style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w600, color: const Color(0xFFE6D6C4))),
              ),
            ),
          ),
        _block(
          _in(since, 710),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: <Widget>[
                for (int k = 0; k < it.variants.length; k++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _sel[p] = k;
                        _holdMs = 6000; // let the customer look at the price
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: k == vi ? _cream : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: k == vi ? _cream : Colors.white.withOpacity(0.16)),
                        ),
                        child: Text(it.variants[k].label, style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: k == vi ? _ink : _muted)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        _block(
          _in(since, 840),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Text(rs(v.price), key: ValueKey<String>('${it.id}-${v.label}'), style: GoogleFonts.rozhaOne(fontSize: 26, height: 1.0, color: _cream)),
                          ),
                          if (v.mrp > v.price)
                            Padding(
                              padding: const EdgeInsets.only(left: 5, bottom: 3),
                              child: Text(rs(v.mrp), style: GoogleFonts.poppins(fontSize: 11, color: _dim, decoration: TextDecoration.lineThrough, decorationColor: _dim)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('per ${v.label}', style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w600, color: _dim)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: LoveButton(
                    name: it.name,
                    image: it.shots.isNotEmpty ? it.shots.first.image : it.thumb,
                    price: v.price,
                    category: 'Pickles',
                    size: 20,
                    box: 40,
                    circleColor: const Color(0x22FFFFFF),
                    fillColor: const Color(0xFFFF4D7E),
                    outlineColor: _cream,
                  ),
                ),
                GestureDetector(
                  onTap: () => widget.onAddToCart?.call(it, v),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Color(0xFFE9BE76), Color(0xFFC8913F)]),
                      boxShadow: const <BoxShadow>[BoxShadow(color: Color(0xB3E2B46A), blurRadius: 18, offset: Offset(0, 8), spreadRadius: -10)],
                    ),
                    child: Text('Add to cart', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w800, color: _ink)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double p;
  final bool on;
  _RingPainter(this.p, this.on);
  @override
  void paint(Canvas canvas, Size size) {
    final Rect r = Offset.zero & size;
    canvas.drawCircle(r.center, size.width / 2, Paint()..color = const Color(0x40FFFFFF));
    if (p > 0) {
      canvas.drawArc(r, -math.pi / 2, math.pi * 2 * p, true, Paint()..color = const Color(0xFFE2B46A));
    }
    if (on) {
      canvas.drawCircle(r.center, size.width / 2 + 1, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x66E2B46A));
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter o) => o.p != p || o.on != on;
}
