// category_lazy_susan.dart — "Spin Amma's lazy susan" Shop-by-category section, 100% Flutter (no WebView)
// Replaces category_turntable_section.dart. Same backend: categories_backend.js → GET /api/shop/categories
//
// • bowls sit on a wooden/brass turntable in 3D perspective — front bowl big, back bowls small & dim
// • swipe to spin (with momentum + snap), tap any bowl or name tab to bring it to the front, ‹ › arrows
// • background colour changes to the chosen category, name animates in, Explore button, product strip

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../shop_catalog.dart';
import '../models.dart';
import '../navigation_util.dart';
import '../product_detail_page.dart';
import '../product_manager.dart';

Color _hex(String? h, Color f) {
  final s = (h ?? '').replaceFirst('#', '');
  return s.length == 6 ? Color(int.parse('FF$s', radix: 16)) : f;
}

class _Cat {
  final String id, slug, name, label, subtitle, image;
  final Color c1, c2, c3;
  final int count;
  final List<Map<String, dynamic>> products;
  _Cat(Map<String, dynamic> j)
      : id = '${j['id']}', slug = j['slug'] ?? '', name = j['name'] ?? '', label = j['label'] ?? '', subtitle = j['subtitle'] ?? '',
        image = j['image'] ?? '', count = ((j['count'] ?? 0) as num).toInt(),
        c1 = _hex(j['color1'], const Color(0xFFE8432B)), c2 = _hex(j['color2'], const Color(0xFF9E1424)), c3 = _hex(j['color3'], const Color(0xFF4A0A0E)),
        products = ((j['products'] as List?) ?? []).cast<Map<String, dynamic>>();
}

/// Network image with a soft placeholder; relative URLs ("/uploads/x.png") are joined to the API host.
Widget _img(String url, String apiUrl, {double? w, double? h, BoxFit fit = BoxFit.contain}) {
  if (url.isEmpty) return SizedBox(width: w, height: h);
  if (url.startsWith('assets/')) {
    return Image.asset(url, width: w, height: h, fit: fit, gaplessPlayback: true,
        errorBuilder: (_, __, ___) => Image.asset('assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg', width: w, height: h, fit: fit,
            errorBuilder: (_, __, ___) => SizedBox(width: w, height: h, child: const Icon(Icons.rice_bowl_rounded, color: Colors.white54))));
  }
  final full = url.startsWith('http') ? url : Uri.parse(apiUrl).resolve(url).toString();
  return Image.network(full, width: w, height: h, fit: fit, gaplessPlayback: true, filterQuality: FilterQuality.medium,
      loadingBuilder: (_, child, p) => p == null ? child : SizedBox(width: w, height: h, child: const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)))),
      errorBuilder: (_, __, ___) => Image.asset('assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg', width: w, height: h, fit: fit,
          errorBuilder: (_, __, ___) => SizedBox(width: w, height: h, child: const Icon(Icons.rice_bowl_rounded, color: Colors.white54))));
}

// ───────────── Built-in sample data (shown instantly; replaced by your server data when it loads) ─────────────
const Map<String, dynamic> kCategoryFallback = <String, dynamic>{
  'settings': <String, dynamic>{
    'enabled': true, 'eyebrow': 'SHOP BY CATEGORY', 'titleStart': "Spin Amma's", 'titleAccent': 'lazy susan',
    'hint': '👆 Tap a bowl, a name or swipe to choose', 'products': true,
  },
  'categories': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': '1', 'slug': 'pickle', 'name': 'Pickles', 'label': 'BESTSELLERS', 'subtitle': 'Sun-cured in jaadis',
      'image': 'assets/images/avakaya_pickle.png', 'color1': '#E8432B', 'color2': '#9E1424', 'color3': '#4A0A0E', 'count': 4,
      'products': <Map<String, dynamic>>[
        <String, dynamic>{'id': 'p1', 'name': 'Bellam Avakaya', 'image': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg', 'price': 120},
        <String, dynamic>{'id': 'p6', 'name': 'Allam Pickle', 'image': 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg', 'price': 140},
        <String, dynamic>{'id': 'p7', 'name': 'Usiri Pickle', 'image': 'assets/images/usiri_pickle_amlagooseberry_pickle.jpg', 'price': 130},
        <String, dynamic>{'id': 'p11', 'name': 'Avakaya', 'image': 'assets/images/avakaya_pickle.png', 'price': 150},
      ],
    },
    <String, dynamic>{
      'id': '2', 'slug': 'snack', 'name': 'Snacks', 'label': 'CRISPY', 'subtitle': 'Crunchy, tea-time ready',
      'image': 'assets/images/murukku_rings.png', 'color1': '#F59E2B', 'color2': '#C2410C', 'color3': '#5A1E04', 'count': 3,
      'products': <Map<String, dynamic>>[
        <String, dynamic>{'id': 'p4', 'name': 'Kara Murukku', 'image': 'assets/images/karam_janthukalu_murukku_strings_snack.jpg', 'price': 129},
        <String, dynamic>{'id': 'p5', 'name': 'Khara Mixture', 'image': 'assets/images/khara_mixture_assorted_crunchy_savory_mix.jpg', 'price': 149},
        <String, dynamic>{'id': 'p12', 'name': 'Murukku Rings', 'image': 'assets/images/murukku_rings.png', 'price': 119},
      ],
    },
    <String, dynamic>{
      'id': '3', 'slug': 'podi', 'name': 'Powders', 'label': 'MADE DAILY', 'subtitle': 'Stone-ground fresh',
      'image': 'assets/images/karivepaku_podi.png', 'color1': '#3FA34D', 'color2': '#1D6B33', 'color3': '#0A2E16', 'count': 3,
      'products': <Map<String, dynamic>>[
        <String, dynamic>{'id': 'p2', 'name': 'Idli Karam Podi', 'image': 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg', 'price': 139},
        <String, dynamic>{'id': 'p8', 'name': 'Allam Podi', 'image': 'assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg', 'price': 145},
        <String, dynamic>{'id': 'p9', 'name': 'Karvepaku Podi', 'image': 'assets/images/karvepaku_karam_podi_curry_leaves_powder.jpg', 'price': 135},
      ],
    },
    <String, dynamic>{
      'id': '4', 'slug': 'sweet', 'name': 'Sweets', 'label': 'FESTIVE', 'subtitle': 'Pure ghee & jaggery',
      'image': 'assets/images/dry_fruit_laddu.png', 'color1': '#E0579A', 'color2': '#9D174D', 'color3': '#4A0A26', 'count': 2,
      'products': <Map<String, dynamic>>[
        <String, dynamic>{'id': 'p3', 'name': 'Sunnunda Laddu', 'image': 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg', 'price': 199},
        <String, dynamic>{'id': 'p10', 'name': 'Dry Fruits Laddu', 'image': 'assets/images/dry_fruit_laddu.png', 'price': 299},
      ],
    },
  ],
};

class CategoryLazySusan extends StatefulWidget {
  final String apiUrl;
  final Map<String, String>? headers;
  final void Function(String categoryId, String slug)? onExplore;
  final ValueChanged<String>? onProduct, onSelect;
  final String? initialSlug;
  final Map<String, dynamic>? fallback;
  final double reservedHeight;
  /// extra coloured space at the very top (status bar + page header drawn over it)
  final double topInset;
  const CategoryLazySusan({super.key, required this.apiUrl, this.headers, this.onExplore, this.onProduct, this.onSelect, this.initialSlug, this.fallback, this.reservedHeight = 150, this.topInset = 0});
  @override
  State<CategoryLazySusan> createState() => _CategoryLazySusanState();
}

class _CategoryLazySusanState extends State<CategoryLazySusan> with TickerProviderStateMixin {
  List<_Cat> _cats = [];
  Map<String, dynamic> _s = {};
  bool _hidden = false;
  late AnimationController _rot;
  late AnimationController _rays;
  int _sel = 0;
  final _tabs = ScrollController();

  @override
  void initState() {
    super.initState();
    _rot = AnimationController.unbounded(vsync: this);
    _rays = AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeat();
    _rot.addListener(_onRot);
    _apply(widget.fallback ?? ShopCatalog.forLazySusan(), first: true);
    _load();
  }

  @override
  void dispose() { _rot.dispose(); _rays.dispose(); _tabs.dispose(); super.dispose(); }

  void _apply(Map<String, dynamic> j, {bool first = false}) {
    final List<_Cat> cats = ((j['categories'] as List?) ?? <dynamic>[]).map((dynamic e) => _Cat(e as Map<String, dynamic>)).toList();
    if (cats.isEmpty) return;
    final String? keepSlug = _cats.isEmpty ? widget.initialSlug : _cats[_sel].slug;
    final int start = keepSlug == null ? 0 : math.max(0, cats.indexWhere((_Cat c) => c.slug == keepSlug));
    void set() {
      _cats = cats;
      _s = (j['settings'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      _sel = start;
      _hidden = false;
    }
    if (first) {
      set();
    } else {
      setState(set);
    }
    _rot.stop();
    _rot.value = start.toDouble();
  }

  Future<void> _load() async {
    // Categories and products come from the admin's Shop Catalog (doc "shop_catalog").
    try {
      final Map<String, dynamic> d = await ShopCatalog.load();
      if (!mounted) return;
      if ((d['settings'] as Map?)?['enabled']?.toString() == 'false') {
        setState(() => _hidden = true);
        return;
      }
      final Map<String, dynamic> j = ShopCatalog.forLazySusan(d);
      if (((j['categories'] as List?) ?? const <dynamic>[]).isEmpty) return;
      for (final dynamic e in j['categories'] as List) {
        final String img = '${(e as Map)['image'] ?? ''}';
        if (img.startsWith('http')) precacheImage(NetworkImage(img), context).catchError((Object _) {});
      }
      _apply(j);
    } catch (e) {
      debugPrint('Category section failed: $e');
    }
  }

  int get _n => _cats.length;
  int _wrap(int i) => ((i % _n) + _n) % _n;

  void _onRot() {
    final s = _wrap(_rot.value.round());
    if (s != _sel) {
      HapticFeedback.selectionClick();
      setState(() => _sel = s);
      widget.onSelect?.call(_cats[s].id);
      _scrollTab(s);
    }
  }

  void _scrollTab(int i) {
    if (!_tabs.hasClients) return;
    _tabs.animateTo((i * 92.0 - 120).clamp(0.0, _tabs.position.maxScrollExtent), duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
  }

  void _goTo(double target, {double velocity = 0}) {
    final sim = SpringSimulation(const SpringDescription(mass: 1, stiffness: 120, damping: 17), _rot.value, target, velocity);
    _rot.animateWith(sim);
  }

  void _select(int i) {
    final cur = _rot.value;
    var diff = (i - cur) % _n;
    if (diff > _n / 2) diff -= _n;
    if (diff < -_n / 2) diff += _n;
    _goTo((cur + diff).roundToDouble());
  }

  void _step(int d) { HapticFeedback.lightImpact(); _goTo(_rot.value.roundToDouble() + d); }

  void _dragUpdate(DragUpdateDetails d) { _rot.stop(); _rot.value -= d.delta.dx / 90; }
  void _dragEnd(DragEndDetails d) {
    final v = -d.velocity.pixelsPerSecond.dx / 90;
    final target = (_rot.value + v * .28).roundToDouble();
    _goTo(target, velocity: v);
  }

  static const double designW = 374;
  bool get _anyProducts => _s['products'] != false && _cats.any((_Cat c) => c.products.isNotEmpty);
  double _stageH = 300;
  bool _compact = false;
  double _topD = 0;
  double get _designH => (_anyProducts ? 760.0 : 630.0) - (300.0 - _stageH) - (_compact ? 30.0 : 0.0) + 8.0;

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth.isFinite ? box.maxWidth : MediaQuery.of(context).size.width;
      final double scale = w / designW;
      final MediaQueryData mq = MediaQuery.of(context);
      final double avail = (box.maxHeight.isFinite ? box.maxHeight : mq.size.height - mq.padding.top - mq.padding.bottom - widget.reservedHeight) - widget.topInset;
      _topD = widget.topInset / scale;
      final double fullH = (_anyProducts ? 760.0 : 630.0) + 8.0;
      final double over = fullH - avail / scale;
      _compact = over > 90;
      final double over2 = over - (_compact ? 30.0 : 0.0);
      _stageH = over2 > 0 ? math.max(160.0, 300.0 - over2) : 300.0;
      if (_cats.isEmpty) {
        return SizedBox(height: 300 * scale, child: const Center(child: CircularProgressIndicator(color: Color(0xFF9E1424))));
      }
      return SizedBox(
        width: w,
        height: (_designH + _topD) * scale,
        child: FittedBox(
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
          child: SizedBox(width: designW, height: _designH + _topD, child: _section()),
        ),
      );
    });
  }

  Widget _section() {
    final c = _cats[_sel];
    return TweenAnimationBuilder<_Pal>(
      tween: _PalTween(end: _Pal(c.c1, c.c2, c.c3)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (_, pal, __) => ClipRect(
        child: Container(
          decoration: BoxDecoration(gradient: RadialGradient(center: const Alignment(0, -.2), radius: 1.1, colors: [pal.a, pal.b, pal.c], stops: const [0, .6, 1])),
          child: Stack(children: [
            Positioned(left: 0, right: 0, top: 40, height: 420, child: IgnorePointer(child: AnimatedBuilder(
              animation: _rays,
              builder: (_, __) => Transform.rotate(angle: _rays.value * 2 * math.pi, child: CustomPaint(painter: _RaysPainter())),
            ))),
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (_topD > 0) SizedBox(height: _topD),
              _header(),
              _tabRow(pal.b),
              if (!_compact) ...<Widget>[
                const SizedBox(height: 6),
              Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: Colors.black.withOpacity(.25), borderRadius: BorderRadius.circular(14)),
                child: Text(_s['hint'] ?? '👆 Tap a bowl, a name or swipe to choose', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              )),
              ],
              _stage(pal.b),
              _dots(),
              _info(c, pal.b),
              if (_anyProducts) (c.products.isNotEmpty ? _strip(c) : const SizedBox(height: 128)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_s['eyebrow'] ?? 'SHOP BY CATEGORY', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 2.6, color: Colors.white70)),
          const SizedBox(height: 3),
          Text.rich(TextSpan(children: [
            TextSpan(text: '${_s['titleStart'] ?? "Spin Amma's"} ', style: GoogleFonts.rozhaOne(fontSize: 27, height: 1.05, color: Colors.white)),
            TextSpan(text: _s['titleAccent'] ?? 'lazy susan', style: GoogleFonts.yatraOne(fontSize: 27, height: 1.05, color: const Color(0xFFFFD58A))),
          ])),
        ]),
      );

  Widget _tabRow(Color main) => SizedBox(
        height: 34,
        child: ListView.separated(
          controller: _tabs, scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: _n, separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final on = i == _sel;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _select(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 11),
                decoration: BoxDecoration(color: on ? Colors.white : Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(14),
                    boxShadow: on ? [BoxShadow(color: Colors.black.withOpacity(.4), blurRadius: 12, offset: const Offset(0, 6), spreadRadius: -4)] : null),
                child: Row(children: [
                  _img(_cats[i].image, widget.apiUrl, w: 18, h: 18),
                  const SizedBox(width: 5),
                  Text(_cats[i].name, style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: on ? main : Colors.white)),
                ]),
              ),
            );
          },
        ),
      );

  Widget _stage(Color main) => SizedBox(
        height: _stageH,
        child: FittedBox(fit: BoxFit.contain, child: SizedBox(width: designW, height: 300, child: _stageInner(main))),
      );

  Widget _stageInner(Color main) => LayoutBuilder(builder: (_, box) {
        final w = designW, h = 300.0;
        final cx = w / 2, cy = 150.0;
        final rx = math.min(w * .36, 150.0), ry = rx * .36;
        return SizedBox(
          height: h,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) => _rot.stop(),
            onHorizontalDragUpdate: _dragUpdate,
            onHorizontalDragEnd: _dragEnd,
            child: AnimatedBuilder(
              animation: _rot,
              builder: (_, __) {
                final rot = _rot.value;
                final placed = <({int i, double depth, Offset at, double scale})>[];
                for (int i = 0; i < _n; i++) {
                  final a = (i - rot) / _n * 2 * math.pi;
                  final depth = math.cos(a);
                  final scale = .5 + .5 * ((depth + 1) / 2) * ((depth + 1) / 2) + (depth > .9 ? .12 * ((depth - .9) / .1) : 0);
                  placed.add((i: i, depth: depth, at: Offset(cx + rx * math.sin(a), cy + ry * depth - 18), scale: scale));
                }
                placed.sort((p, q) => p.depth.compareTo(q.depth));
                return Stack(clipBehavior: Clip.none, children: [
                  Positioned.fill(child: CustomPaint(painter: _TurntablePainter(Offset(cx, cy + 22), rx + 46, ry + 26, rot))),
                  for (final p in placed) _bowl(p.i, p.at, p.scale, p.depth, main),
                  Positioned(left: 12, top: 132, child: _arrow('‹', () => _step(-1), main)),
                  Positioned(right: 12, top: 132, child: _arrow('›', () => _step(1), main)),
                ]);
              },
            ),
          ),
        );
      });

  Widget _bowl(int i, Offset at, double scale, double depth, Color main) {
    const base = 150.0;
    final size = base * scale;
    final front = i == _sel && depth > .8;
    final dim = (.45 + .55 * ((depth + 1) / 2)).clamp(0.0, 1.0);
    return Positioned(
      left: at.dx - size / 2, top: at.dy - size * .62,
      width: size, height: size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () { HapticFeedback.selectionClick(); front ? widget.onExplore?.call(_cats[i].id, _cats[i].slug) : _select(i); },
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
          Positioned(bottom: size * .02, child: Container(width: size * .7, height: size * .14,
              decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.elliptical(size * .35, size * .07)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.45 * dim), blurRadius: 14, spreadRadius: 2)]))),
          ColorFiltered(
            colorFilter: ColorFilter.matrix(<double>[dim, 0, 0, 0, 0, 0, dim, 0, 0, 0, 0, 0, dim, 0, 0, 0, 0, 0, 1, 0]),
            child: _img(_cats[i].image, widget.apiUrl, w: size, h: size),
          ),
          Positioned(top: -6, child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(horizontal: front ? 12 : 8, vertical: front ? 5 : 3),
            decoration: BoxDecoration(color: front ? Colors.white : Colors.black.withOpacity(.45), borderRadius: BorderRadius.circular(10),
                boxShadow: front ? [BoxShadow(color: Colors.white.withOpacity(.35), spreadRadius: 3)] : null),
            child: Text(_cats[i].name, style: GoogleFonts.poppins(fontSize: front ? 12.5 : 9.5, fontWeight: FontWeight.w800, color: front ? main : Colors.white)),
          )),
        ]),
      ),
    );
  }

  Widget _arrow(String t, VoidCallback onTap, Color main) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(width: 42, height: 42, alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withOpacity(.95), shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.5), blurRadius: 16, offset: const Offset(0, 8), spreadRadius: -6)]),
            child: Text(t, style: TextStyle(fontSize: 24, height: 1, fontWeight: FontWeight.w800, color: main))),
      );

  Widget _dots() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (int i = 0; i < _n; i++)
          AnimatedContainer(duration: const Duration(milliseconds: 400), margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _sel ? 20 : 6, height: 6,
              decoration: BoxDecoration(color: Colors.white.withOpacity(i == _sel ? 1 : .35), borderRadius: BorderRadius.circular(3))),
      ]);

  Widget _info(_Cat c, Color main) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          transitionBuilder: (w, a) => FadeTransition(opacity: a, child: SlideTransition(
              position: Tween(begin: const Offset(0, .15), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)), child: w)),
          child: Column(key: ValueKey(c.id), children: [
            if (c.label.isNotEmpty)
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Text(c.label, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 2, color: main))),
            const SizedBox(height: 6),
            Text(c.name, style: GoogleFonts.rozhaOne(fontSize: 38, height: 1, color: Colors.white,
                shadows: [Shadow(color: Colors.black.withOpacity(.35), blurRadius: 16, offset: const Offset(0, 4))])),
            if (c.subtitle.isNotEmpty) Text(c.subtitle, style: GoogleFonts.kalam(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(.9))),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () { HapticFeedback.lightImpact(); widget.onExplore?.call(c.id, c.slug); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.6), blurRadius: 22, offset: const Offset(0, 12), spreadRadius: -10)]),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Explore ${c.name}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: main)),
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: main, borderRadius: BorderRadius.circular(8)),
                      child: Text('${c.count}', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white))),
                ]),
              ),
            ),
          ]),
        ),
      );

  Widget _strip(_Cat c) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: SizedBox(
          height: 112,
          child: ListView.separated(
            key: ValueKey('strip${c.id}'),
            scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: c.products.length, separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final p = c.products[i];
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1), duration: Duration(milliseconds: 400 + i * 80), curve: Curves.easeOutBack,
                builder: (_, v, child) => Opacity(opacity: v.clamp(0.0, 1.0), child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child)),
                child: GestureDetector(
                  onTap: () {
                    final Product? cp = ShopCatalog.product('${p['id']}');
                    if (cp != null) {
                      AppNavigator.push(context, ProductDetailPage(product: cp, allProducts: ProductManager().products));
                    } else {
                      widget.onProduct?.call('${p['id']}');
                    }
                  },
                  child: Container(
                    width: 104, padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(.2))),
                    child: Column(children: [
                      _img((p['image'] ?? '').toString(), widget.apiUrl, w: 70, h: 56),
                      const SizedBox(height: 2),
                      Text(p['name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                      Text('₹${(p['price'] as num?)?.round() ?? ''}', style: GoogleFonts.rozhaOne(fontSize: 14, color: const Color(0xFFFFD58A))),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      );
}

class _TurntablePainter extends CustomPainter {
  final Offset c;
  final double rx, ry, rot;
  _TurntablePainter(this.c, this.rx, this.ry, this.rot);
  @override
  void paint(Canvas canvas, Size s) {
    final top = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
    canvas.drawOval(top.shift(const Offset(0, 26)).inflate(6), Paint()..color = Colors.black.withOpacity(.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));
    for (double d = 14; d > 0; d -= 1) {
      canvas.drawOval(top.shift(Offset(0, d)), Paint()..color = Color.lerp(const Color(0xFF5A2E0E), const Color(0xFF8A4A1A), 1 - d / 14)!);
    }
    canvas.drawOval(top, Paint()..shader = const RadialGradient(center: Alignment(-.2, -.5), radius: .9,
        colors: [Color(0xFFE9B872), Color(0xFFC0843E), Color(0xFF8E5523)]).createShader(top));
    canvas.drawOval(top.deflate(5), Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = const Color(0xFFFFE0A0).withOpacity(.55));
    final ring = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = const Color(0xFF6E3A12).withOpacity(.28);
    for (int k = 1; k <= 3; k++) {
      final r = top.deflate(k * rx * .2);
      canvas.drawOval(r, ring);
    }
    final spoke = Paint()..strokeWidth = 1.4..color = const Color(0xFF6E3A12).withOpacity(.22);
    for (int k = 0; k < 8; k++) {
      final a = (k / 8 + rot / 8) * 2 * math.pi;
      final p1 = Offset(c.dx + rx * .25 * math.sin(a), c.dy + ry * .25 * math.cos(a));
      final p2 = Offset(c.dx + rx * .85 * math.sin(a), c.dy + ry * .85 * math.cos(a));
      canvas.drawLine(p1, p2, spoke);
    }
    canvas.drawOval(Rect.fromCenter(center: c, width: 34, height: 12), Paint()..shader = const LinearGradient(colors: [Color(0xFFFFE6A8), Color(0xFFB7791F)])
        .createShader(Rect.fromCenter(center: c, width: 34, height: 12)));
  }
  @override
  bool shouldRepaint(covariant _TurntablePainter o) => o.rot != rot || o.rx != rx || o.c != c;
}

class _RaysPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final o = s.center(Offset.zero), r = s.longestSide;
    final p = Paint()..shader = RadialGradient(colors: [Colors.white.withOpacity(.08), Colors.white.withOpacity(0)]).createShader(Rect.fromCircle(center: o, radius: r * .6));
    for (int i = 0; i < 18; i++) {
      final a = i / 18 * 2 * math.pi;
      final path = Path()
        ..moveTo(o.dx, o.dy)
        ..lineTo(o.dx + r * math.cos(a), o.dy + r * math.sin(a))
        ..lineTo(o.dx + r * math.cos(a + .12), o.dy + r * math.sin(a + .12))
        ..close();
      c.drawPath(path, p);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _Pal {
  final Color a, b, c;
  const _Pal(this.a, this.b, this.c);
}

class _PalTween extends Tween<_Pal> {
  _PalTween({required _Pal end}) : super(begin: end, end: end);
  @override
  _Pal lerp(double t) => _Pal(Color.lerp(begin!.a, end!.a, t)!, Color.lerp(begin!.b, end!.b, t)!, Color.lerp(begin!.c, end!.c, t)!);
}
