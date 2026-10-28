// spice_grinder_section.dart
// "Fresh ground spices" — from whole spice to podi.

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models.dart';
import '../cart_manager.dart';
import '../product_detail_page.dart';
import '../product_listing_page.dart';
import '../navigation_util.dart';
import '../product_manager.dart';
import '../app_config_repository.dart';

// ============================ MODELS ============================

Color _hex(String? h, Color fb) {
  final s = (h ?? '').replaceAll('#', '');
  return s.length == 6 ? Color(int.parse('FF$s', radix: 16)) : fb;
}

class SpVariant {
  final String id, label;
  final num price, mrp;
  final bool inStock;

  const SpVariant(this.id, this.label, this.price, this.mrp, this.inStock);

  factory SpVariant.fromJson(Map j) => SpVariant(
        '${j['id'] ?? ''}',
        j['label'] ?? '',
        j['price'] ?? 0,
        j['mrp'] ?? j['price'] ?? 0,
        j['inStock'] ?? true,
      );
}

class SpThrow {
  final String name, size;
  final List<String> pieces;
  final int count;

  const SpThrow(this.name, this.pieces, this.count, this.size);

  factory SpThrow.fromJson(Map j) => SpThrow(
        j['name'] ?? '',
        ((j['pieces'] ?? []) as List).map((e) => '$e').toList(),
        ((j['count'] as num?)?.toInt()) ?? 2,
        j['size'] ?? 'big',
      );
}

class SpProduct {
  final String id, name, tagline, image;
  final Color powder, accent, glow;
  final int heat;
  final List<SpThrow> throwIn;
  final List<MapEntry<String, String>> chips;
  final List<SpVariant> variants;

  const SpProduct({
    required this.id,
    required this.name,
    required this.tagline,
    required this.image,
    required this.powder,
    required this.accent,
    required this.glow,
    required this.heat,
    required this.throwIn,
    required this.chips,
    required this.variants,
  });

  factory SpProduct.fromJson(Map j) => SpProduct(
        id: '${j['id'] ?? ''}',
        name: j['name'] ?? '',
        tagline: j['tagline'] ?? '',
        image: j['image'] ?? '',
        powder: _hex(j['powderColor'], const Color(0xFFB8321E)),
        accent: _hex(j['accentColor'], const Color(0xFFFF7A45)),
        glow: _hex(j['glowColor'], const Color(0xFF7A2A14)),
        heat: (((j['heat'] as num?)?.toInt()) ?? 2).clamp(1, 3),
        throwIn: ((j['throwIn'] ?? []) as List)
            .map((e) => SpThrow.fromJson(e))
            .where((t) => t.pieces.isNotEmpty)
            .toList(),
        chips: ((j['chips'] ?? []) as List)
            .take(4)
            .map((e) => MapEntry('${e['name'] ?? ''}', '${e['icon'] ?? ''}'))
            .toList(),
        variants: ((j['variants'] ?? []) as List)
            .map((e) => SpVariant.fromJson(e))
            .toList(),
      );
}

class SpiceData {
  final bool enabled;
  final String kicker, title, titleAccent, subtitle, cardTag;
  final List<SpProduct> products;

  const SpiceData({
    this.enabled = true,
    this.kicker = 'FROM WHOLE SPICE TO PODI',
    this.title = 'Fresh ground',
    this.titleAccent = 'spices',
    this.subtitle = 'Pounded in stone, the way Ammamma did.',
    this.cardTag = '🪨 STONE-GROUND TODAY',
    this.products = const [],
  });

  factory SpiceData.fromJson(Map j) {
    final s = (j['settings'] ?? {}) as Map;
    return SpiceData(
      enabled: s['enabled'] ?? true,
      kicker: s['kicker'] ?? 'FROM WHOLE SPICE TO PODI',
      title: s['title'] ?? 'Fresh ground',
      titleAccent: s['titleAccent'] ?? 'spices',
      subtitle: s['subtitle'] ?? 'Pounded in stone, the way Ammamma did.',
      cardTag: s['cardTag'] ?? '🪨 STONE-GROUND TODAY',
      products: ((j['products'] ?? []) as List)
          .map((e) => SpProduct.fromJson(e))
          .toList(),
    );
  }
}

// ============================ TIMELINE ============================

const _cycle = Duration(milliseconds: 7200);
const _kSink = .06;
const _kIntro = .22;
const _kPound = .40;
const _kGrind = .62;
const _kRise = .72;
const _kPer = (_kGrind - _kPound) / 3;
const _stageH = 250.0;

class _Piece {
  final String url;
  final double size, sx, ex, rot, delay, dur, pileX, pileY;

  _Piece(this.url, this.size, this.sx, this.ex, this.rot, this.delay, this.dur,
      this.pileX, this.pileY);
}

// ============================ SECTION ============================

class SpiceGrinderSection extends StatefulWidget {
  final SpiceData? data;
  final ValueChanged<SpProduct>? onOpen;
  final Future<void> Function(SpProduct, SpVariant)? onAdd;
  final ValueChanged<SpProduct>? onWishlist;
  final Set<String> wishlisted;
  final VoidCallback? onViewAll;

  const SpiceGrinderSection({
    super.key,
    this.data,
    this.onOpen,
    this.onAdd,
    this.onWishlist,
    this.wishlisted = const {},
    this.onViewAll,
  });

  @override
  State<SpiceGrinderSection> createState() => _SpiceGrinderSectionState();
}

class _SpiceGrinderSectionState extends State<SpiceGrinderSection>
    with TickerProviderStateMixin {
  int _cur = 0;
  late final _t = AnimationController(vsync: this, duration: _cycle);
  late final _loop = AnimationController(
      vsync: this, duration: const Duration(seconds: 6))
    ..repeat();
  final _chips = ScrollController();
  List<_Piece> _pieces = [];
  final Map<String, int> _variant = {};
  String? _added;

  StreamSubscription? _sub;
  SpiceData _liveData = defaultSpiceData;

  @override
  void initState() {
    super.initState();
    _prepare();
    _listenToSpicesConfig();
    _t.addStatusListener((s) {
      if (s == AnimationStatus.completed && _p.length > 1) {
        _goTo((_cur + 1) % _p.length);
      } else if (s == AnimationStatus.completed) {
        _t.forward(from: _kRise);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _t.forward(from: _kSink));
  }

  void _listenToSpicesConfig() {
    _sub = AppConfigRepository().getSpicesStream().listen((data) {
      if (!mounted) return;
      if (data.isNotEmpty) {
        final parsed = SpiceData.fromJson(data);
        if (parsed.products.isNotEmpty) {
          setState(() {
            _liveData = parsed;
            if (_cur >= _liveData.products.length) _cur = 0;
          });
          _prepare();
        }
      }
    });
  }

  SpiceData get _effectiveData =>
      widget.data != null && widget.data!.products.isNotEmpty
          ? widget.data!
          : _liveData;

  List<SpProduct> get _p => _effectiveData.products;

  bool _cached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cached) return;
    _cached = true;
    for (final p in _p) {
      for (final th in p.throwIn) {
        for (final u in th.pieces) {
          if (u.startsWith('http')) precacheImage(NetworkImage(u), context);
        }
      }
    }
  }

  void _goTo(int i, {bool user = false}) {
    if (!mounted || _p.isEmpty) return;
    setState(() => _cur = i % _p.length);
    _prepare();
    _t.forward(from: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chips.hasClients) return;
      final target =
          (_cur * 120.0 - 120).clamp(0.0, _chips.position.maxScrollExtent);
      _chips.animateTo(target,
          duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    });
  }

  void _prepare() {
    if (_p.isEmpty) return;
    final r = math.Random(_cur * 31 + DateTime.now().millisecond);
    final list = <_Piece>[];
    var bigIndex = 0, smallIndex = 0;
    for (final th in _p[_cur].throwIn) {
      final big = th.size != 'small';
      for (var k = 0; k < th.count.clamp(1, 16); k++) {
        final url = th.pieces[r.nextInt(th.pieces.length)];
        final side = (big ? bigIndex : smallIndex).isEven ? -1.0 : 1.0;
        list.add(_Piece(
          url,
          big ? 40 + r.nextDouble() * 12 : 15 + r.nextDouble() * 6,
          big ? side * (90 + r.nextDouble() * 60) : (r.nextDouble() - .5) * 60,
          (r.nextDouble() - .5) * (big ? 90 : 110),
          (r.nextDouble() - .5) * 9,
          big ? bigIndex * .022 : .055 + smallIndex * .0065,
          big ? .09 + r.nextDouble() * .025 : .07 + r.nextDouble() * .03,
          (r.nextDouble() - .5) * 140,
          (r.nextDouble() - .5) * 14,
        ));
        big ? bigIndex++ : smallIndex++;
      }
    }
    _pieces = list;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _t.dispose();
    _loop.dispose();
    _chips.dispose();
    super.dispose();
  }

  double _seg(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0);

  void _openProductDetail(SpProduct p) {
    HapticFeedback.lightImpact();
    if (widget.onOpen != null) {
      widget.onOpen!(p);
      return;
    }

    final allProducts = ProductManager().products;
    final cleanName = p.name.toLowerCase().trim();

    Product? match;
    if (allProducts.isNotEmpty) {
      match = allProducts.firstWhere(
        (prod) =>
            prod.name.toLowerCase().contains(cleanName) ||
            cleanName.contains(prod.name.toLowerCase()),
        orElse: () => allProducts.first,
      );
    }

    if (match != null) {
      AppNavigator.push(
          context, ProductDetailPage(product: match, allProducts: allProducts));
    } else {
      AppNavigator.push(context, ProductListingPage(category: p.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _effectiveData;
    if (!d.enabled || _p.isEmpty) return const SizedBox.shrink();
    final p = _p[_cur];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 900),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: RadialGradient(
          center: const Alignment(0, -.15),
          radius: 1.0,
          colors: [p.accent, p.glow, const Color(0xFF140A06)],
          stops: const [0, .55, 1],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 14),
        child: Column(
          children: [
            _header(d, p),
            _stage(p),
            AnimatedBuilder(
              animation: _t,
              builder: (_, __) {
                final show = Curves.easeOutBack.transform(
                        _seg(_t.value, _kRise + .05, _kRise + .15)) *
                    (1 - _seg(_t.value, 0, .05));
                return Opacity(
                  opacity: show.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - show)),
                    child: _card(p),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _chipsRow(),
          ],
        ),
      ),
    );
  }

  Widget _header(SpiceData d, SpProduct p) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✦ ${d.kicker}',
                    style: GoogleFonts.poppins(
                      fontSize: 9.5,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFFF3D6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${d.title} '),
                        TextSpan(
                          text: d.titleAccent,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFFFFF3C4),
                            shadows: [Shadow(color: p.accent, blurRadius: 18)],
                          ),
                        ),
                      ],
                    ),
                    style: GoogleFonts.fraunces(
                        fontSize: 27, height: 1.05, color: Colors.white),
                  ),
                  if (d.subtitle.isNotEmpty)
                    Text(
                      d.subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 10.5, color: const Color(0xE6FFE9D6)),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (widget.onViewAll != null) {
                  widget.onViewAll!();
                } else {
                  AppNavigator.push(
                    context,
                    const ProductListingPage(category: 'Spices'),
                  );
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'View all →',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2B1D17),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _stage(SpProduct p) {
    return SizedBox(
      height: _stageH,
      child: LayoutBuilder(
        builder: (_, box) {
          final cx = box.maxWidth / 2;
          const mW = 184.0, mH = 120.0;
          final mTop = _stageH - 20 - mH;
          final mouthY = mTop + mH * .28;
          return GestureDetector(
            onTap: () => _openProductDetail(p),
            onHorizontalDragEnd: (e) {
              final v = e.primaryVelocity ?? 0;
              if (v.abs() > 200) {
                _goTo(v < 0 ? _cur + 1 : _cur - 1 + _p.length, user: true);
              }
            },
            child: AnimatedBuilder(
              animation: Listenable.merge([_t, _loop]),
              builder: (_, __) {
                final t = _t.value;
                final pound = t < _kPound || t > _kGrind
                    ? 0.0
                    : ((t - _kPound) / _kPer) % 1;
                final hit = pound > .45 && pound < .62;
                final poundsDone = t < _kPound
                    ? 0
                    : t >= _kGrind
                        ? 3
                        : ((t - _kPound) / _kPer).floor();
                final sinceHit =
                    t < _kPound + _kPer * .45 || t > _kGrind + .02
                        ? 1.0
                        : (((t - _kPound) / _kPer - .45) % 1);
                final grind = _seg(t, _kGrind, _kRise);
                final rise =
                    Curves.easeOutBack.transform(_seg(t, _kRise, _kRise + .12));
                final sink = _seg(t, 0, _kSink);
                final burst = _seg(t, _kRise, _kRise + .14);
                final intro = t < .06 || t > _kPound
                    ? 0.0
                    : t < .19
                        ? Curves.easeOutBack.transform(_seg(t, .06, .1))
                        : 1 - _seg(t, .19, .23);
                final introDrop = _seg(t, .19, .23);
                final powderFill = t < _kPound
                    ? 0.0
                    : t >= _kRise
                        ? 1.0
                        : .25 + .25 * poundsDone + .25 * grind;
                final rest = _seg(t, _kRise, _kRise + .08);
                final shake = sinceHit < .25
                    ? math.sin(sinceHit * 60) * 3 * (1 - sinceHit / .25)
                    : 0.0;
                final bob = math.sin(_loop.value * 2 * math.pi * 2) * 4;

                double pY, pRot, pX;
                if (t < _kPound) {
                  pY = -30;
                  pRot = .3;
                  pX = 10;
                } else if (t < _kGrind) {
                  final down = pound < .5
                      ? Curves.easeInCubic.transform(pound / .5)
                      : 1 - Curves.easeOut.transform((pound - .5) / .5);
                  pY = -30 + 52 * down;
                  pRot = .3 - .23 * down;
                  pX = 10;
                } else if (t < _kRise) {
                  final a = grind * 2 * math.pi * 1.5;
                  pY = 18;
                  pRot = .07 + .12 * math.sin(a);
                  pX = 10 + 14 * math.sin(a);
                } else {
                  pY = 18 + 30 * rest;
                  pRot = .07 + .6 * rest;
                  pX = 10 + 100 * rest;
                }

                return Transform.translate(
                  offset: Offset(shake, shake.abs() * .5),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: cx - 130,
                        top: 0,
                        child: Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: const [
                                Color(0x8CFFF0D2),
                                Color(0x1FFFF0D2),
                                Colors.transparent
                              ],
                              stops: const [0, .55, 1],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: cx - 135,
                        top: -6,
                        child: Transform.rotate(
                          angle: _loop.value * 2 * math.pi / 6,
                          child: CustomPaint(
                            size: const Size(270, 270),
                            painter: _RingPainter(),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -20,
                        right: -20,
                        bottom: -26,
                        height: 92,
                        child: CustomPaint(painter: _TablePainter(p.powder)),
                      ),
                      if (burst > 0)
                        Positioned(
                          left: cx - 120,
                          top: mouthY - 150,
                          child: Opacity(
                            opacity: (1 - burst * .6).clamp(0.0, 1.0),
                            child: Container(
                              width: 240,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    p.powder.withOpacity(.75),
                                    p.powder.withOpacity(0)
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        left: cx - 78,
                        top: mouthY - 132,
                        child: ClipRect(
                          clipper: _AboveClip(mouthY - (mouthY - 132) + 4),
                          child: Transform.translate(
                            offset: Offset(
                                0,
                                t < _kSink
                                    ? 110 * Curves.easeIn.transform(sink)
                                    : t < _kRise
                                        ? 110
                                        : 110 * (1 - rise) + bob),
                            child: SizedBox(
                                width: 156, height: 136, child: _buildImg(p.image)),
                          ),
                        ),
                      ),
                      Positioned(
                        left: cx - mW / 2,
                        top: mTop + (hit ? 3 : 0),
                        child: CustomPaint(
                          size: const Size(mW, mH),
                          painter: _MortarPainter(p.powder, powderFill),
                        ),
                      ),
                      Positioned(
                        left: cx - mW / 2 + 16,
                        top: mouthY - 14,
                        width: mW - 32,
                        height: 26,
                        child: ClipOval(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              for (final pc in _pieces)
                                if (t > _kIntro + pc.delay + pc.dur &&
                                    t < _kRise - .04)
                                  Positioned(
                                    left: (mW - 32) / 2 + pc.pileX - pc.size * .4,
                                    top: 13 +
                                        pc.pileY -
                                        pc.size * .4 -
                                        12 *
                                            (1 -
                                                Curves.elasticOut.transform(
                                                    _seg(
                                                        t,
                                                        _kIntro +
                                                            pc.delay +
                                                            pc.dur,
                                                        _kIntro +
                                                            pc.delay +
                                                            pc.dur +
                                                            .05))) -
                                        (sinceHit < .3
                                            ? math.sin(sinceHit * 30 + pc.pileX) *
                                                3 *
                                                (1 - sinceHit / .3)
                                            : 0),
                                    child: Opacity(
                                      opacity: (1 - .3 * poundsDone - grind)
                                          .clamp(0.0, 1.0),
                                      child: Transform.rotate(
                                        angle: pc.rot,
                                        child: Transform.scale(
                                          scale: (1 - .28 * poundsDone)
                                              .clamp(.1, 1.0),
                                          child: SizedBox(
                                            width: pc.size * .8,
                                            height: pc.size * .8,
                                            child: _buildImg(pc.url),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ),
                      for (final pc in _pieces)
                        if (t >= _kIntro + pc.delay &&
                            t <= _kIntro + pc.delay + pc.dur)
                          Builder(builder: (_) {
                            final f = Curves.easeIn.transform(
                                ((t - _kIntro - pc.delay) / pc.dur)
                                    .clamp(0.0, 1.0));
                            final x = cx + pc.sx + (pc.ex - pc.sx) * f;
                            final y = -30 +
                                (mouthY + 30) * f -
                                math.sin(f * math.pi) * 30;
                            return Positioned(
                              left: x - pc.size / 2,
                              top: y - pc.size / 2,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    left: pc.size * .1,
                                    right: pc.size * .1,
                                    bottom: -6,
                                    height: 6,
                                    child: Opacity(
                                      opacity: .45 * f,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          color: Colors.black,
                                          boxShadow: const [
                                            BoxShadow(
                                                color: Colors.black,
                                                blurRadius: 4)
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Transform.rotate(
                                    angle: pc.rot * f,
                                    child: SizedBox(
                                      width: pc.size,
                                      height: pc.size,
                                      child: _buildImg(pc.url),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      Positioned(
                        left: cx - 23 + pX,
                        top: mTop - 120 + pY,
                        child: Transform.rotate(
                          angle: pRot,
                          alignment: Alignment.bottomCenter,
                          child: const CustomPaint(
                            size: Size(40, 150),
                            painter: _PestlePainter(),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _BurstPainter(
                              origin: Offset(cx, mouthY),
                              color: p.powder,
                              small: hit ? pound : 0,
                              big: burst,
                            ),
                          ),
                        ),
                      ),
                      if (sinceHit < 1 && t > _kPound)
                        Positioned(
                          left: cx - 140,
                          top: mouthY - 90 - 30 * sinceHit,
                          child: IgnorePointer(
                            child: Opacity(
                              opacity: (.55 * (1 - sinceHit)).clamp(0.0, 1.0),
                              child: Container(
                                width: 280,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      p.powder.withOpacity(.6),
                                      p.powder.withOpacity(0)
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (sinceHit < .7 &&
                          t > _kPound &&
                          t < _kGrind + .02 &&
                          _pieces.isNotEmpty)
                        for (var i = 0; i < 6; i++)
                          Builder(builder: (_) {
                            final pc =
                                _pieces[(i * 7 + poundsDone * 3) % _pieces.length];
                            final a = -math.pi *
                                (.15 + ((i * 37 + poundsDone * 11) % 70) / 100),
                                d = 50 + (i * 13 % 60).toDouble();
                            final e = Curves.easeOut
                                .transform((sinceHit / .7).clamp(0.0, 1.0));
                            return Positioned(
                              left: cx + math.cos(a) * d * e - 7,
                              top: mouthY +
                                  math.sin(a) * d * e +
                                  40 * e * e -
                                  7,
                              child: Opacity(
                                opacity: (1 - e).clamp(0.0, 1.0),
                                child: Transform.rotate(
                                  angle: e * 6 + i,
                                  child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: _buildImg(pc.url),
                                  ),
                                ),
                              ),
                            );
                          }),
                      if (t > _kRise + .06 && t < _kRise + .2)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _DustOffPainter(
                                _seg(t, _kRise + .06, _kRise + .2),
                                Offset(cx, mouthY - 20),
                                p.powder,
                              ),
                            ),
                          ),
                        ),
                      if (intro > 0)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 34 + 110 * introDrop * introDrop,
                          child: Opacity(
                            opacity: intro.clamp(0.0, 1.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (final c in p.chips)
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 5),
                                    child: SizedBox(
                                      width: 62,
                                      child: Column(
                                        children: [
                                          Transform.translate(
                                            offset: Offset(
                                                0,
                                                math.sin(_loop.value *
                                                        2 *
                                                        math.pi *
                                                        3) *
                                                    3),
                                            child: Transform.rotate(
                                              angle: introDrop * .7,
                                              child: SizedBox(
                                                width: 50,
                                                height: 50,
                                                child: c.value.isEmpty
                                                    ? const SizedBox()
                                                    : _buildImg(c.value),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            c.key,
                                            maxLines: 2,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.poppins(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFFFFF3D6),
                                              shadows: const [
                                                Shadow(
                                                    color: Colors.black54,
                                                    blurRadius: 3)
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      Positioned(left: 16, top: 6, child: _steps(t, p)),
                      Positioned(
                        right: 16,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                              color: Colors.black.withOpacity(.3),
                              borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            '${'🌶' * p.heat} ${['Mild', 'Medium', 'Hot'][p.heat - 1]}',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _steps(double t, SpProduct p) {
    final step = t < _kPound
        ? 0
        : t < _kGrind
            ? 1
            : t < _kRise
                ? 2
                : 3;
    const labels = [
      'ADDING WHOLE SPICES',
      'POUNDING IN STONE',
      'GRINDING FINE',
      'FRESHLY GROUND ✓'
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(.28),
          borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 4; i++)
            Container(
              width: 16,
              height: 4,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: i <= step ? p.accent : Colors.white24,
              ),
            ),
          const SizedBox(width: 4),
          Text(
            labels[step],
            style: GoogleFonts.poppins(
              fontSize: 9,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFFE3C2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(SpProduct p) {
    final vi =
        (_variant[p.id] ?? 0).clamp(0, math.max(0, p.variants.length - 1));
    final v = p.variants.isEmpty ? null : p.variants[vi];
    final added = v != null && _added == '${p.id}-${v.id}';

    return GestureDetector(
      onTap: () => _openProductDetail(p),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xF7FFF8F0),
          borderRadius: BorderRadius.circular(22),
          border: Border(top: BorderSide(color: p.powder, width: 4)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x99000000),
                blurRadius: 30,
                offset: Offset(0, 18),
                spreadRadius: -14)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: GoogleFonts.fraunces(
                            fontSize: 20,
                            height: 1.1,
                            color: const Color(0xFF2A1A12)),
                      ),
                      Text(
                        p.tagline,
                        style: GoogleFonts.poppins(
                            fontSize: 10.5, color: const Color(0xFF8A7660)),
                      ),
                      if (widget.data.cardTag.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: const Color(0xFFE6F4E8),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            widget.data.cardTag,
                            style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .6,
                                color: const Color(0xFF2E7D32)),
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (widget.onWishlist != null) {
                          widget.onWishlist!(p);
                        }
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Color(0xFFFBE9E2)),
                        child: Icon(
                          widget.wishlisted.contains(p.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 17,
                          color: const Color(0xFFC0392B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'HEAT ',
                          style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF8A5A3A)),
                        ),
                        Container(
                          width: 70,
                          height: 5,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                              color: const Color(0xFFF2E6DA),
                              borderRadius: BorderRadius.circular(3)),
                          alignment: Alignment.centerLeft,
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey(p.id),
                            tween: Tween(begin: 0, end: p.heat / 3),
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.easeOutBack,
                            builder: (_, v, __) => FractionallySizedBox(
                              widthFactor: v.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFC24D),
                                      Color(0xFFE5391E)
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            if (p.chips.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    for (final c in p.chips)
                      Container(
                        padding: const EdgeInsets.fromLTRB(5, 3, 8, 3),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF5ECE1),
                            borderRadius: BorderRadius.circular(9)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (c.value.isNotEmpty)
                              SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: _buildImg(c.value)),
                            const SizedBox(width: 4),
                            Text(
                              c.key,
                              style: GoogleFonts.poppins(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6B4A30)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            if (v != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    for (var k = 0; k < p.variants.length && k < 3; k++)
                      GestureDetector(
                        onTap: () => setState(() => _variant[p.id] = k),
                        child: Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9),
                            color: k == vi
                                ? const Color(0xFF2A1A12)
                                : const Color(0xFFF4EEE4),
                          ),
                          child: Text(
                            p.variants[k].label,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: !p.variants[k].inStock
                                  ? Colors.black26
                                  : k == vi
                                      ? Colors.white
                                      : const Color(0xFF6B5A48),
                            ),
                          ),
                        ),
                      ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${v.price}',
                          style: GoogleFonts.poppins(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              height: 1,
                              color: const Color(0xFF2A1A12)),
                        ),
                        if (v.mrp > v.price)
                          Text(
                            '₹${v.mrp}',
                            style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                color: const Color(0xFFA89A88),
                                decoration: TextDecoration.lineThrough),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: !v.inStock
                          ? null
                          : () async {
                              HapticFeedback.mediumImpact();
                              if (widget.onAdd != null) {
                                await widget.onAdd!(p, v);
                              } else {
                                final allProducts =
                                    ProductManager().products;
                                final match = allProducts.firstWhere(
                                  (prod) => prod.name
                                      .toLowerCase()
                                      .contains(p.name.toLowerCase()),
                                  orElse: () => Product(
                                    name: p.name,
                                    description: p.tagline,
                                    weightPriceMap: {
                                      v.label: v.price.toDouble()
                                    },
                                    rating: 4.8,
                                    image: p.image,
                                    color: p.powder,
                                    category: 'Spices',
                                    secretIngredient: IngredientDetail(
                                      name: 'Fresh Ingredients',
                                      description: 'Stone ground blend',
                                      image: p.image,
                                    ),
                                  ),
                                );
                                CartManager().addToCart(match,
                                    weight: v.label);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${p.name} (${v.label}) added to cart!'),
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                              if (!mounted) return;
                              setState(() => _added = '${p.id}-${v.id}');
                              Future.delayed(const Duration(seconds: 2), () {
                                if (mounted) setState(() => _added = null);
                              });
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          color: !v.inStock
                              ? Colors.grey
                              : added
                                  ? const Color(0xFF2E7D32)
                                  : p.powder,
                        ),
                        child: Text(
                          !v.inStock
                              ? 'Notify me'
                              : added
                                  ? '✓ Added'
                                  : '+ ADD',
                          style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chipsRow() => SizedBox(
        height: 34,
        child: ListView.separated(
          controller: _chips,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: _p.length,
          separatorBuilder: (_, __) => const SizedBox(width: 7),
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => _goTo(i, user: true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              padding: const EdgeInsets.fromLTRB(7, 6, 11, 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: i == _cur
                    ? const Color(0xFFFFF3D6)
                    : Colors.white.withOpacity(.14),
                border: Border.all(color: Colors.white.withOpacity(.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 14,
                      height: 14,
                      decoration:
                          BoxDecoration(shape: BoxShape.circle, color: _p[i].powder)),
                  const SizedBox(width: 6),
                  Text(
                    _p[i].name.replaceAll(' Podi', ''),
                    style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: i == _cur
                            ? const Color(0xFF2B1D17)
                            : Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildImg(String u) {
    if (u.isEmpty) {
      return const SizedBox();
    }
    if (u.startsWith('http')) {
      return Image.network(
        u,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const SizedBox(),
      );
    }
    String assetPath = u.startsWith('assets/') ? u : 'assets/images/$u';
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const SizedBox(),
    );
  }

  static const SpiceData defaultSpiceData = SpiceData(
    enabled: true,
    kicker: 'FROM WHOLE SPICE TO PODI',
    title: 'Fresh ground',
    titleAccent: 'spices',
    subtitle: 'Pounded in stone, the way Ammamma did.',
    cardTag: '🪨 STONE-GROUND TODAY',
    products: [
      SpProduct(
        id: 'p1',
        name: 'Moringa Karam Podi',
        tagline: 'Drumstick-leaf spice powder',
        image: 'assets/images/munagaku_karam_podi_moringa_leaves_spice_powder.jpg',
        powder: Color(0xFF6B7A2A),
        accent: Color(0xFFA8D86A),
        glow: Color(0xFF3A4A14),
        heat: 2,
        throwIn: [
          SpThrow('Moringa leaves',
              ['assets/images/moringa_0.png', 'assets/images/moringa_1.png'], 3, 'big'),
          SpThrow('Dry red chilli',
              ['assets/images/redchilli_0.png', 'assets/images/chillies_0.png'], 2, 'big'),
          SpThrow('Cumin',
              ['assets/images/cumin_0.png', 'assets/images/cumin_1.png'], 8, 'small'),
        ],
        chips: [
          MapEntry('Moringa leaves', 'assets/images/moringa_0.png'),
          MapEntry('Red chilli', 'assets/images/redchilli_0.png'),
          MapEntry('Cumin', 'assets/images/cumin_0.png'),
        ],
        variants: [
          SpVariant('v1', '100g', 129, 149, true),
          SpVariant('v2', '250g', 249, 280, true),
        ],
      ),
      SpProduct(
        id: 'p2',
        name: 'Idli Karam Podi',
        tagline: 'authentic gun powder spice blend',
        image: 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg',
        powder: Color(0xFFB8321E),
        accent: Color(0xFFFF7A45),
        glow: Color(0xFF7A2A14),
        heat: 3,
        throwIn: [
          SpThrow('Red chilli',
              ['assets/images/redchilli_0.png', 'assets/images/chillies_1.png'], 4, 'big'),
          SpThrow('Urad dal',
              ['assets/images/urad_0.png', 'assets/images/urad_1.png'], 6, 'small'),
          SpThrow('Chana dal',
              ['assets/images/chanadal_0.png', 'assets/images/chanadal_1.png'], 6, 'small'),
        ],
        chips: [
          MapEntry('Red chilli', 'assets/images/redchilli_0.png'),
          MapEntry('Urad dal', 'assets/images/urad_0.png'),
          MapEntry('Chana dal', 'assets/images/chanadal_0.png'),
        ],
        variants: [
          SpVariant('v3', '200g', 139, 150, true),
          SpVariant('v4', '500g', 320, 350, true),
        ],
      ),
      SpProduct(
        id: 'p3',
        name: 'Karvepaku Podi',
        tagline: 'aromatic curry leaves spice powder',
        image: 'assets/images/karvepaku_karam_podi_curry_leaves_powder.jpg',
        powder: Color(0xFF386B32),
        accent: Color(0xFF7AC96B),
        glow: Color(0xFF1E4218),
        heat: 2,
        throwIn: [
          SpThrow('Curry leaves',
              ['assets/images/curryleaf_0.png', 'assets/images/curryleaf_1.png'], 5, 'big'),
          SpThrow('Garlic & chilli',
              ['assets/images/ginger_0.png', 'assets/images/redchilli_0.png'], 3, 'big'),
          SpThrow('Sesame & cumin',
              ['assets/images/sesame_0.png', 'assets/images/cumin_0.png'], 8, 'small'),
        ],
        chips: [
          MapEntry('Curry leaves', 'assets/images/curryleaf_0.png'),
          MapEntry('Garlic', 'assets/images/ginger_0.png'),
          MapEntry('Sesame', 'assets/images/sesame_0.png'),
        ],
        variants: [
          SpVariant('v5', '100g', 119, 135, true),
          SpVariant('v6', '250g', 229, 260, true),
        ],
      ),
    ],
  );
}

// ============================ PAINTERS ============================

class _AboveClip extends CustomClipper<Rect> {
  final double bottom;

  _AboveClip(this.bottom);

  @override
  Rect getClip(Size s) => Rect.fromLTRB(-50, -200, s.width + 50, bottom);

  @override
  bool shouldReclip(covariant _AboveClip o) => o.bottom != bottom;
}

class _MortarPainter extends CustomPainter {
  final Color powder;
  final double fill;

  _MortarPainter(this.powder, this.fill);

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    c.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h - 4), width: w * .88, height: 12),
      Paint()
        ..color = Colors.black45
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    final body = Path()
      ..moveTo(w * .06, h * .27)
      ..cubicTo(w * .08, h * .75, w * .26, h * .94, w / 2, h * .94)
      ..cubicTo(w * .74, h * .94, w * .92, h * .75, w * .94, h * .27)
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.3, -.4),
          radius: .9,
          colors: [Color(0xFF8C8178), Color(0xFF5E554E), Color(0xFF2E2824)],
          stops: [0, .5, 1],
        ).createShader(Offset.zero & s),
    );

    final r = math.Random(3);
    for (var i = 0; i < 120; i++) {
      final p =
          Offset(w * (.1 + r.nextDouble() * .8), h * (.32 + r.nextDouble() * .58));
      if (body.contains(p)) {
        c.drawCircle(
            p,
            .8,
            Paint()
              ..color =
                  (i.isEven ? Colors.white : Colors.black).withOpacity(.18));
      }
    }
    c.drawPath(
      Path()
        ..moveTo(w * .15, h * .4)
        ..cubicTo(w * .18, h * .66, w * .3, h * .8, w * .42, h * .84),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(.2),
    );
    c.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * .27), width: w * .89, height: h * .29),
      Paint()..color = const Color(0xFF6E655D),
    );
    final mouth =
        Rect.fromCenter(center: Offset(w / 2, h * .28), width: w * .75, height: h * .21);
    c.drawOval(
      mouth,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -.4),
          colors: [Color(0xFF2A221E), Color(0xFF120E0B)],
        ).createShader(mouth),
    );
    if (fill > 0) {
      final r = Rect.fromCenter(
          center: Offset(w / 2, h * .29), width: w * .73 * fill, height: h * .2 * fill);
      c.drawOval(
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.1, -.5),
            radius: .8,
            colors: [
              Color.lerp(powder, Colors.white, .35)!,
              powder,
              Color.lerp(powder, Colors.black, .6)!
            ],
            stops: const [0, .55, 1],
          ).createShader(r),
      );
      final g = math.Random(9);
      for (var i = 0; i < (160 * fill).round(); i++) {
        final a = g.nextDouble() * 2 * math.pi, d = math.sqrt(g.nextDouble());
        c.drawCircle(
          r.center + Offset(math.cos(a) * d * r.width / 2, math.sin(a) * d * r.height / 2),
          .7,
          Paint()
            ..color = (i.isEven ? Colors.black : Colors.white).withOpacity(.22),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MortarPainter o) =>
      o.fill != fill || o.powder != powder;
}

class _PestlePainter extends CustomPainter {
  const _PestlePainter();

  @override
  void paint(Canvas c, Size s) {
    final g = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF3C3530),
          Color(0xFF9A8F86),
          Color(0xFF6E655D),
          Color(0xFF2E2824)
        ],
        stops: [0, .35, .6, 1],
      ).createShader(Offset.zero & s);
    c.drawPath(
      Path()
        ..moveTo(s.width * .33, 4)
        ..lineTo(s.width * .67, 4)
        ..lineTo(s.width * .78, s.height * .88)
        ..quadraticBezierTo(
            s.width / 2, s.height + 4, s.width * .22, s.height * .88)
        ..close(),
      g,
    );
    c.drawLine(
      Offset(s.width * .42, 8),
      Offset(s.width * .38, s.height * .82),
      Paint()
        ..color = Colors.white24
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _TablePainter extends CustomPainter {
  final Color tint;

  _TablePainter(this.tint);

  @override
  void paint(Canvas c, Size s) {
    final rr = RRect.fromRectAndCorners(
      Offset.zero & s,
      topLeft: Radius.elliptical(s.width / 2, 26),
      topRight: Radius.elliptical(s.width / 2, 26),
    );
    c.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC98A52), Color(0xFF9A5E2E), Color(0xFF5E3416)],
          stops: [0, .55, 1],
        ).createShader(Offset.zero & s),
    );
    c.save();
    c.clipRRect(rr);
    for (var y = 6.0; y < s.height; y += 9) {
      c.drawLine(Offset(0, y), Offset(s.width, y + 4),
          Paint()..color = Colors.black.withOpacity(.08));
    }
    c.restore();
    c.drawOval(
      Rect.fromCenter(center: Offset(s.width / 2, 18), width: s.width * .6, height: 26),
      Paint()
        ..color = tint.withOpacity(.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  @override
  bool shouldRepaint(covariant _TablePainter o) => o.tint != tint;
}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final ctr = s.center(Offset.zero);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0x59FFF0D2);
    for (var a = 0.0; a < 2 * math.pi; a += .12) {
      c.drawArc(
          Rect.fromCircle(center: ctr, radius: s.width / 2), a, .07, false, p);
    }
    c.drawCircle(
      ctr,
      s.width / 2 - 22,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x2EFFF0D2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _BurstPainter extends CustomPainter {
  final Offset origin;
  final Color color;
  final double small, big;

  _BurstPainter({
    required this.origin,
    required this.color,
    required this.small,
    required this.big,
  });

  @override
  void paint(Canvas c, Size s) {
    void puff(int n, double spread, double t, double maxSize, int seed) {
      if (t <= 0 || t >= 1) return;
      final r = math.Random(seed);
      final e = Curves.easeOut.transform(t);
      for (var i = 0; i < n; i++) {
        final a = -math.pi * r.nextDouble(),
            d = spread * (.5 + r.nextDouble() * .6),
            sz = maxSize * (.4 + r.nextDouble() * .6);
        c.drawCircle(
          origin + Offset(math.cos(a) * d * e, math.sin(a) * d * e),
          sz * (.4 + e),
          Paint()
            ..color = color.withOpacity(.9 * (1 - t))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
    }

    puff(10, 50, small, 5, 1);
    puff(30, 120, big, 10, 2);
  }

  @override
  bool shouldRepaint(covariant _BurstPainter o) =>
      o.small != small || o.big != big || o.color != color;
}

class _DustOffPainter extends CustomPainter {
  final double t;
  final Offset origin;
  final Color color;

  _DustOffPainter(this.t, this.origin, this.color);

  @override
  void paint(Canvas c, Size s) {
    final r = math.Random(4);
    for (var i = 0; i < 22; i++) {
      final x = (r.nextDouble() - .5) * 170,
          delay = r.nextDouble() * .5,
          dx = (r.nextDouble() - .5) * 30;
      final f = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (f <= 0) continue;
      c.drawCircle(
        origin + Offset(x + dx * f, -20 + 70 * f * f),
        1.6,
        Paint()..color = color.withOpacity(.9 * (1 - f)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DustOffPainter o) => o.t != t;
}
