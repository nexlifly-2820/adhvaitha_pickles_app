// sweets_thali_section.dart
// "Traditional sweets, timeless joy" — Mithai Thali.

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

class SwVariant {
  final String id, label;
  final num price, mrp;
  final bool inStock;

  const SwVariant(this.id, this.label, this.price, this.mrp, this.inStock);

  factory SwVariant.fromJson(Map j) => SwVariant(
        '${j['id'] ?? ''}',
        j['label'] ?? '',
        j['price'] ?? 0,
        j['mrp'] ?? j['price'] ?? 0,
        j['inStock'] ?? true,
      );
}

class SwProduct {
  final String id, name, tagline, image;
  final List<String> tags;
  final bool giftBox;
  final List<SwVariant> variants;

  const SwProduct({
    required this.id,
    required this.name,
    required this.tagline,
    required this.image,
    required this.tags,
    required this.giftBox,
    required this.variants,
  });

  factory SwProduct.fromJson(Map j) => SwProduct(
        id: '${j['id'] ?? ''}',
        name: j['name'] ?? '',
        tagline: j['tagline'] ?? '',
        image: j['image'] ?? '',
        tags: ((j['tags'] ?? []) as List)
            .map((e) => '$e')
            .take(2)
            .toList(),
        giftBox: j['giftBox'] ?? false,
        variants: ((j['variants'] ?? []) as List)
            .map((e) => SwVariant.fromJson(e))
            .toList(),
      );
}

class SweetsData {
  final bool enabled;
  final String kicker, title, titleAccent, subtitle, giftTag;
  final List<String> badges;
  final int intervalMs;
  final List<SwProduct> products;

  const SweetsData({
    this.enabled = true,
    this.kicker = 'MITHAI THALI',
    this.title = 'Traditional sweets,',
    this.titleAccent = 'timeless joy',
    this.subtitle = 'Pure ghee. Jaggery. Just like Ammamma made.',
    this.giftTag = '🎁 Gift box available',
    this.badges = const ['🧈 Pure desi ghee', 'No preservatives'],
    this.intervalMs = 2800,
    this.products = const [],
  });

  factory SweetsData.fromJson(Map j) {
    final s = (j['settings'] ?? {}) as Map;
    return SweetsData(
      enabled: s['enabled'] ?? true,
      kicker: s['kicker'] ?? 'MITHAI THALI',
      title: s['title'] ?? 'Traditional sweets,',
      titleAccent: s['titleAccent'] ?? 'timeless joy',
      subtitle: s['subtitle'] ?? 'Pure ghee. Jaggery. Just like Ammamma made.',
      giftTag: s['giftTag'] ?? '🎁 Gift box available',
      badges: ((s['badges'] ?? ['🧈 Pure desi ghee', 'No preservatives']) as List)
          .map((e) => '$e')
          .take(3)
          .toList(),
      intervalMs: math.max(2000, ((s['intervalMs'] as num?)?.toInt()) ?? 2800),
      products: ((j['products'] ?? []) as List)
          .take(10)
          .map((e) => SwProduct.fromJson(e))
          .toList(),
    );
  }
}

// ============================ SECTION ============================

const _gold = Color(0xFFFFD27A);
const _rani = Color(0xFFC2185B);
const _plum = Color(0xFF8E0E45);
const _stageH = 290.0;
const _wheelY = 352.0;
const _radius = 215.0;

class SweetsThaliSection extends StatefulWidget {
  final SweetsData? data;
  final ValueChanged<SwProduct>? onOpen;
  final Future<void> Function(SwProduct, SwVariant)? onAdd;
  final ValueChanged<SwProduct>? onWishlist;
  final Set<String> wishlisted;
  final VoidCallback? onViewAll;

  const SweetsThaliSection({
    super.key,
    this.data,
    this.onOpen,
    this.onAdd,
    this.onWishlist,
    this.wishlisted = const {},
    this.onViewAll,
  });

  @override
  State<SweetsThaliSection> createState() => _SweetsThaliSectionState();
}

class _SweetsThaliSectionState extends State<SweetsThaliSection>
    with TickerProviderStateMixin {
  int _cur = 0;
  Timer? _timer;
  double _fromRot = 0, _toRot = 0;
  final Map<String, int> _variant = {};
  String? _added;

  late final _turn =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000), value: 1);
  late final _pop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700), value: 1);
  late final _card =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 350), value: 1);
  late final _loop =
      AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();
  late final _fast =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  StreamSubscription? _sub;
  SweetsData _liveData = defaultSweetsData;

  @override
  void initState() {
    super.initState();
    _listenToSweetsConfig();
    _schedule();
  }

  void _listenToSweetsConfig() {
    _sub = AppConfigRepository().getSweetsStream().listen((data) {
      if (!mounted) return;
      if (data.isNotEmpty) {
        final parsed = SweetsData.fromJson(data);
        if (parsed.products.isNotEmpty) {
          setState(() {
            _liveData = parsed;
            if (_cur >= _liveData.products.length) _cur = 0;
          });
          _schedule();
        }
      }
    });
  }

  SweetsData get _effectiveData =>
      widget.data != null && widget.data!.products.isNotEmpty
          ? widget.data!
          : _liveData;

  List<SwProduct> get _p => _effectiveData.products;
  int get _n => _p.length;

  @override
  void didUpdateWidget(covariant SweetsThaliSection old) {
    super.didUpdateWidget(old);
    if (_cur >= _n) _cur = 0;
    _schedule();
  }

  void _schedule([Duration? d]) {
    _timer?.cancel();
    if (_n < 2) return;
    _timer = Timer(
        d ?? Duration(milliseconds: _effectiveData.intervalMs),
        () => _go(_cur + 1));
  }

  Future<void> _go(int i, {bool user = false}) async {
    if (!mounted || _n < 2) return;
    final next = (i % _n + _n) % _n;
    final steps = i - _cur;
    if (steps == 0) return;
    _fromRot = _rotNow;
    _toRot = _toRot - steps * 2 * math.pi / _n;
    _card.reverse();
    setState(() => _cur = next);
    _turn.forward(from: 0);
    _pop.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _card.forward();
    });
    _schedule(
        user ? Duration(milliseconds: _effectiveData.intervalMs + 4000) : null);
  }

  double get _rotNow =>
      _fromRot + (_toRot - _fromRot) * Curves.easeOutBack.transform(_turn.value);

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    for (final c in [_turn, _pop, _card, _loop, _fast]) {
      c.dispose();
    }
    super.dispose();
  }

  void _openProductDetail(SwProduct p) {
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const RadialGradient(
          center: Alignment(0, -.4),
          radius: 1.1,
          colors: [_rani, _plum, Color(0xFF4A0624)],
          stops: [0, .45, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _loop,
                builder: (_, __) =>
                    CustomPaint(painter: _BackdropPainter(_loop.value)),
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(
                height: 66,
                child: AnimatedBuilder(
                  animation: _fast,
                  builder: (_, __) => CustomPaint(
                    size: const Size(double.infinity, 66),
                    painter: _GarlandPainter(_fast.value),
                  ),
                ),
              ),
              _header(d),
              _stage(p),
              Transform.translate(
                  offset: const Offset(0, -30), child: _productCard(p, d)),
              Transform.translate(
                offset: const Offset(0, -20),
                child: Column(
                  children: [
                    if (_n > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < _n; i++)
                            GestureDetector(
                              onTap: () =>
                                  _go(_cur + _shortest(i), user: true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                width: i == _cur ? 20 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  color: i == _cur
                                      ? _gold
                                      : Colors.white.withOpacity(.35),
                                ),
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (widget.onViewAll != null) {
                          widget.onViewAll!();
                        } else {
                          AppNavigator.push(
                            context,
                            const ProductListingPage(category: 'Sweets'),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                              colors: [_gold, Color(0xFFFFF3C4)]),
                        ),
                        child: Text(
                          'View all sweets →',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4A0624),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _header(SweetsData d) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
        child: Column(
          children: [
            Text(
              '✦ ${d.kicker} ✦',
              style: GoogleFonts.poppins(
                fontSize: 9.5,
                letterSpacing: 3,
                fontWeight: FontWeight.w700,
                color: _gold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              d.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.fraunces(
                  fontSize: 26, height: 1.08, color: Colors.white),
            ),
            AnimatedBuilder(
              animation: _fast,
              builder: (_, __) => ShaderMask(
                shaderCallback: (r) => LinearGradient(
                  colors: const [_gold, Color(0xFFFFF3C4), Color(0xFFE9B44C)],
                  transform: GradientRotation(_fast.value * 2 * math.pi),
                ).createShader(r),
                child: Text(
                  d.titleAccent,
                  style: GoogleFonts.fraunces(
                    fontSize: 26,
                    height: 1.08,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (d.subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  d.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: const Color(0xFFF8C8DA)),
                ),
              ),
          ],
        ),
      );

  Widget _stage(SwProduct p) {
    return SizedBox(
      height: _stageH,
      child: GestureDetector(
        onHorizontalDragEnd: (e) {
          final v = e.primaryVelocity ?? 0;
          if (v.abs() > 200) _go(v < 0 ? _cur + 1 : _cur - 1, user: true);
        },
        child: LayoutBuilder(
          builder: (_, box) {
            final cx = box.maxWidth / 2;
            return AnimatedBuilder(
              animation: Listenable.merge([_turn, _pop, _loop, _fast]),
              builder: (_, __) {
                final rot = _rotNow;
                final pop = Curves.elasticOut.transform(_pop.value);
                final bob = math.sin(_fast.value * 2 * math.pi) * 5;
                final heroY = _wheelY - _radius - 26 * pop;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: cx - 125,
                      top: -10,
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Color.fromRGBO(
                                  255,
                                  215,
                                  130,
                                  .45 +
                                      .1 *
                                          math.sin(_fast.value * 2 * math.pi)),
                              const Color(0x00FFD782)
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: cx - 270,
                      top: _wheelY - 270,
                      child: const CustomPaint(
                        size: Size(540, 540),
                        painter: _ThaliPainter(),
                      ),
                    ),
                    Positioned(
                      left: cx - 118,
                      top: heroY - 118 + 10,
                      child: Transform.rotate(
                        angle: _loop.value * 2 * math.pi / 2,
                        child: const CustomPaint(
                          size: Size(236, 236),
                          painter: _MandalaPainter(),
                        ),
                      ),
                    ),
                    Positioned(
                      left: cx - 128,
                      top: heroY - 128 + 10,
                      child: Transform.rotate(
                        angle: _loop.value * 2 * math.pi,
                        child: Transform.scale(
                          scale: 1 + .05 * math.sin(_loop.value * 2 * math.pi),
                          child: const CustomPaint(
                            size: Size(256, 256),
                            painter: _LotusPainter(),
                          ),
                        ),
                      ),
                    ),
                    for (var i = 0; i < _n; i++)
                      _sweetOnRim(i, cx, rot, pop, bob),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter:
                              _DustPainter(_fast.value, Offset(cx, heroY)),
                        ),
                      ),
                    ),
                    Positioned(left: 22, top: 250, child: _Diya(t: _fast.value)),
                    Positioned(
                        right: 22, top: 250, child: _Diya(t: _fast.value + .3)),
                    if (p.tags.isNotEmpty)
                      Positioned(
                        left: 14,
                        top: 30 + bob * .6,
                        child: _tag(p.tags[0], const Color(0xFFFFF3C4), _plum,
                            -.12, pop),
                      ),
                    if (p.tags.length > 1)
                      Positioned(
                        right: 14,
                        top: 120 - bob * .6,
                        child: _tag(p.tags[1], const Color(0xFF2E7D32),
                            Colors.white, .1, pop),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _sweetOnRim(
      int i, double cx, double rot, double pop, double bob) {
    final a = i * 2 * math.pi / _n - math.pi / 2 + rot;
    final x = cx + math.cos(a) * _radius, y = _wheelY + math.sin(a) * _radius;
    final isOn = i == _cur;
    final scale = isOn ? 1 + .42 * pop : 1.0;
    final lift = isOn ? -26 * pop + bob : 0.0;
    return Positioned(
      left: x - 55,
      top: y - 55,
      child: GestureDetector(
        onTap: () => isOn
            ? _openProductDetail(_p[i])
            : _go(_cur + _shortest(i), user: true),
        child: Transform.translate(
          offset: Offset(0, lift),
          child: Transform.scale(
            scale: scale,
            child: ColorFiltered(
              colorFilter: isOn
                  ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                  : const ColorFilter.matrix([
                      .82, 0, 0, 0, 0,
                      0, .82, 0, 0, 0,
                      0, 0, .82, 0, 0,
                      0, 0, 0, 1, 0
                    ]),
              child: SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x803C0A14),
                              blurRadius: 16,
                              offset: Offset(0, 10),
                              spreadRadius: -18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned.fill(child: _buildImg(_p[i].image)),
                    if (isOn)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ShaderMask(
                            blendMode: BlendMode.srcATop,
                            shaderCallback: (r) => LinearGradient(
                              begin: Alignment(-1.5 + 3 * _fast.value, -.3),
                              end: Alignment(-.9 + 3 * _fast.value, .3),
                              colors: const [
                                Color(0x00FFFFFF),
                                Color(0x66FFFFFF),
                                Color(0x00FFFFFF)
                              ],
                            ).createShader(r),
                            child: _buildImg(_p[i].image),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _shortest(int i) {
    var d = i - _cur;
    if (d > _n / 2) d -= _n;
    if (d < -_n / 2) d += _n;
    return d;
  }

  Widget _tag(String text, Color bg, Color fg, double angle, double pop) =>
      Opacity(
        opacity: pop.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: .4 + .6 * pop,
          child: Transform.rotate(
            angle: angle,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x59000000),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
            ),
          ),
        ),
      );

  Widget _productCard(SwProduct p, SweetsData d) {
    final vi =
        (_variant[p.id] ?? 0).clamp(0, math.max(0, p.variants.length - 1));
    final v = p.variants.isEmpty ? null : p.variants[vi];
    final off = v != null && v.mrp > v.price
        ? ((1 - v.price / v.mrp) * 100).round()
        : 0;
    final added = v != null && _added == '${p.id}-${v.id}';
    final wished = widget.wishlisted.contains(p.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: () => _openProductDetail(p),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F0),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE9C46A), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xB328000F),
                    blurRadius: 30,
                    offset: Offset(0, 18),
                    spreadRadius: -12,
                  ),
                ],
              ),
              child: FadeTransition(
                opacity: _card,
                child: SlideTransition(
                  position:
                      Tween(begin: const Offset(0, .06), end: Offset.zero)
                          .animate(_card),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: GoogleFonts.fraunces(
                                    fontSize: 22,
                                    height: 1.1,
                                    color: const Color(0xFF2A1A12),
                                  ),
                                ),
                                Text(
                                  p.tagline,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    color: const Color(0xFF8A7660),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              if (widget.onWishlist != null) {
                                widget.onWishlist!(p);
                              }
                            },
                            child: Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFCE4EC),
                              ),
                              child: Icon(
                                wished
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 18,
                                color: _rani,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (d.badges.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              for (var k = 0; k < d.badges.length; k++)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: k == 0
                                        ? const Color(0xFFFFF3C4)
                                        : const Color(0xFFFCE4EC),
                                  ),
                                  child: Text(
                                    d.badges[k],
                                    style: GoogleFonts.poppins(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: k == 0
                                          ? const Color(0xFF8A5A16)
                                          : _plum,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (p.variants.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 4,
                            children: [
                              for (var k = 0; k < p.variants.length; k++)
                                GestureDetector(
                                  onTap: () => setState(() => _variant[p.id] = k),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: k == vi
                                          ? _plum
                                          : const Color(0xFFF7EDE4),
                                    ),
                                    child: Text(
                                      p.variants[k].label,
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: !p.variants[k].inStock
                                            ? Colors.black26
                                            : k == vi
                                                ? Colors.white
                                                : const Color(0xFF6B5A48),
                                        decoration: p.variants[k].inStock
                                            ? null
                                            : TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (v != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(text: '₹${v.price}'),
                                          if (off > 0)
                                            TextSpan(
                                              text: '  ₹${v.mrp}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFFA89A88),
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                            ),
                                        ],
                                      ),
                                      style: GoogleFonts.poppins(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF2A1A12),
                                      ),
                                    ),
                                    if (off > 0)
                                      Text(
                                        '$off% OFF',
                                        style: GoogleFonts.poppins(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF2E7D32),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
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
                                              rating: 4.9,
                                              image: p.image,
                                              color: const Color(0xFF8E0E45),
                                              category: 'Sweets',
                                              secretIngredient:
                                                  IngredientDetail(
                                                name: 'Pure Desi Ghee',
                                                description:
                                                    'Traditional preparation',
                                                image: p.image,
                                              ),
                                            ),
                                          );
                                          CartManager().addToCart(match,
                                              weight: v.label);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  '${p.name} (${v.label}) added to cart!'),
                                              duration:
                                                  const Duration(seconds: 1),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                        if (!mounted) return;
                                        setState(
                                            () => _added = '${p.id}-${v.id}');
                                        Future.delayed(
                                            const Duration(seconds: 2), () {
                                          if (mounted) {
                                            setState(() => _added = null);
                                          }
                                        });
                                      },
                                child: AnimatedBuilder(
                                  animation: _fast,
                                  builder: (_, __) => Container(
                                    clipBehavior: Clip.antiAlias,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      gradient: LinearGradient(
                                        colors: !v.inStock
                                            ? [
                                                Colors.grey,
                                                Colors.grey.shade700
                                              ]
                                            : added
                                                ? const [
                                                    Color(0xFF2E7D32),
                                                    Color(0xFF1B5E20)
                                                  ]
                                                : const [_rani, _plum],
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x998E0E45),
                                          blurRadius: 16,
                                          offset: Offset(0, 8),
                                          spreadRadius: -6,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      !v.inStock
                                          ? 'Notify me'
                                          : added
                                              ? '✓ Added'
                                              : '+ ADD',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            top: -6,
            child: CustomPaint(
              size: const Size(double.infinity, 12),
              painter: _ScallopPainter(),
            ),
          ),
          if (p.giftBox && d.giftTag.isNotEmpty)
            Positioned(
              right: -6,
              top: -14,
              child: Transform.rotate(
                angle: .07,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                        colors: [_gold, Color(0xFFE9B44C)]),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4D000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    d.giftTag,
                    style: GoogleFonts.poppins(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF4A0624),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImg(String u) {
    if (u.isEmpty) {
      return const SizedBox();
    }
    if (u.startsWith('http')) {
      return Image.network(
        u,
        fit: BoxFit.contain,
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

  static const SweetsData defaultSweetsData = SweetsData(
    enabled: true,
    kicker: 'MITHAI THALI',
    title: 'Traditional sweets,',
    titleAccent: 'timeless joy',
    subtitle: 'Pure ghee. Jaggery. Just like Ammamma made.',
    intervalMs: 2800,
    badges: ['🧈 Pure desi ghee', 'No preservatives'],
    giftTag: '🎁 Gift box available',
    products: [
      SwProduct(
        id: 'p1',
        name: 'Sunnunda Laddu',
        tagline: 'roasted urad dal & organic jaggery',
        image: 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg',
        tags: ['🧈 Pure Desi Ghee', 'No Sugar'],
        giftBox: true,
        variants: [
          SwVariant('v1', '250g', 199, 220, true),
          SwVariant('v2', '500g', 380, 420, true),
        ],
      ),
      SwProduct(
        id: 'p2',
        name: 'Dry Fruits Laddu',
        tagline: 'almonds, cashews, dates & pistachios',
        image: 'assets/images/dry_fruits_laddu_premium_dry_fruits_laddu.jpg',
        tags: ['🥜 Loaded with nuts', 'Energy Rich'],
        giftBox: true,
        variants: [
          SwVariant('v3', '250g', 240, 275, true),
          SwVariant('v4', '500g', 460, 520, true),
        ],
      ),
      SwProduct(
        id: 'p3',
        name: 'Gondh Laddu',
        tagline: 'edible gum, ghee & wholesome dry fruits',
        image: 'assets/images/gondh_laddu_edible_gum_laddu.jpg',
        tags: ['💪 Immunity Boost', 'Winter Special'],
        giftBox: false,
        variants: [
          SwVariant('v5', '250g', 210, 235, true),
          SwVariant('v6', '500g', 410, 450, true),
        ],
      ),
      SwProduct(
        id: 'p4',
        name: 'Gulab Jamun Kova',
        tagline: 'rich khoya gulab jamun in cardamom syrup',
        image: 'assets/images/kova_gulam_jamun_rich_gulab_jamun_sweet.jpg',
        tags: ['🍯 Melt in mouth', 'Khoya Made'],
        giftBox: false,
        variants: [
          SwVariant('v7', '250g', 180, 200, true),
          SwVariant('v8', '500g', 340, 380, true),
        ],
      ),
    ],
  );
}

// ============================ PAINTERS ============================

class _Diya extends StatelessWidget {
  final double t;

  const _Diya({required this.t});

  @override
  Widget build(BuildContext context) {
    final f = 1 + .25 * math.sin(t * 2 * math.pi * 6);
    return SizedBox(
      width: 26,
      height: 30,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 12,
            child: Transform.scale(
              scaleY: f,
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 7,
                height: 12,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(6), bottom: Radius.circular(3)),
                  gradient: RadialGradient(
                    center: Alignment(0, .5),
                    colors: [
                      Color(0xFFFFF6C0),
                      Color(0xFFFFB12B),
                      Color(0x00FFB12B)
                    ],
                    stops: [0, .6, 1],
                  ),
                  boxShadow: [
                    BoxShadow(color: Color(0xAAFFB12B), blurRadius: 12)
                  ],
                ),
              ),
            ),
          ),
          const Text('🪔', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

class _ThaliPainter extends CustomPainter {
  const _ThaliPainter();

  @override
  void paint(Canvas c, Size s) {
    final ctr = Offset(s.width / 2, s.height / 2), r = s.width / 2;
    final rect = Rect.fromCircle(center: ctr, radius: r);
    c.drawCircle(
      ctr,
      r + 4,
      Paint()
        ..color = Colors.black.withOpacity(.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
    c.drawCircle(
      ctr,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: [
            Color(0xFFF6D27A),
            Color(0xFFE2A93A),
            Color(0xFFB07A1E),
            Color(0xFFF2C866),
            Color(0xFF8A5A16),
            Color(0xFFE2B04A),
            Color(0xFFC9963A)
          ],
          stops: [0, .4, .58, .6, .62, .64, 1],
        ).createShader(rect),
    );
    c.drawCircle(
      ctr,
      r - 3,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = const Color(0xFFF6D27A),
    );
    c.drawCircle(
      ctr,
      r - 8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0xFF8A5A16),
    );

    c.drawCircle(
      ctr,
      r,
      Paint()
        ..shader = SweepGradient(
          colors: [
            Colors.white.withOpacity(.35),
            Colors.transparent,
            Colors.transparent,
            Colors.white.withOpacity(.25),
            Colors.transparent
          ],
          stops: const [0, .15, .5, .6, .75],
        ).createShader(rect),
    );

    final eng = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0x596E3C0A);
    for (final rr in [250.0, 140.0]) {
      c.drawCircle(ctr, rr * r / 270, eng);
    }
    for (var a = 0; a < 360; a += 20) {
      c.save();
      c.translate(ctr.dx, ctr.dy);
      c.rotate(a * math.pi / 180);
      final k = r / 270;
      c.drawPath(
        Path()
          ..moveTo(0, -140 * k)
          ..cubicTo(14 * k, -165 * k, 14 * k, -190 * k, 0, -215 * k)
          ..cubicTo(-14 * k, -190 * k, -14 * k, -165 * k, 0, -140 * k),
        eng,
      );
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _LotusPainter extends CustomPainter {
  const _LotusPainter();

  @override
  void paint(Canvas c, Size s) {
    final k = s.width / 220;
    c.translate(s.width / 2, s.height / 2);
    c.scale(k);
    for (var i = 0; i < 12; i++) {
      c.save();
      c.rotate(i * math.pi / 6);
      final path = Path()
        ..moveTo(0, 0)
        ..cubicTo(-22, -30, -18, -70, 0, -92)
        ..cubicTo(18, -70, 22, -30, 0, 0);
      c.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: i.isOdd
                ? const [Color(0xFFFF8FB8), Color(0xFFFFE3EE)]
                : const [Color(0xFFE5397A), Color(0xFFFFB3CF)],
          ).createShader(const Rect.fromLTWH(-22, -92, 44, 92)),
      );
      c.restore();
    }
    c.drawCircle(Offset.zero, 24, Paint()..color = const Color(0xE6FFD27A));
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _MandalaPainter extends CustomPainter {
  const _MandalaPainter();

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .9
      ..color = _gold.withOpacity(.55);
    c.translate(s.width / 2, s.height / 2);
    final r = s.width / 2;
    for (var a = 0; a < 180; a += 15) {
      c.save();
      c.rotate(a * math.pi / 180);
      c.drawOval(
          Rect.fromCenter(
              center: Offset.zero, width: r * 1.8, height: r * .46),
          p);
      c.restore();
    }
    c.drawCircle(Offset.zero, r * .95, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _DustPainter extends CustomPainter {
  final double t;
  final Offset origin;

  _DustPainter(this.t, this.origin);

  @override
  void paint(Canvas c, Size s) {
    for (var i = 0; i < 14; i++) {
      final r = math.Random(i + 3);
      final dur = 2 + r.nextDouble() * 2,
          x0 = (r.nextDouble() - .5) * 120,
          dx = (r.nextDouble() - .5) * 60;
      final life = ((t * 2.4) / dur + r.nextDouble()) % 1;
      final op = life < .2 ? life / .2 : 1 - life;
      final p = origin + Offset(x0 + dx * life, 20 - 130 * life);
      c.drawCircle(
        p,
        4,
        Paint()
          ..color = _gold.withOpacity(.4 * op)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      c.drawCircle(
          p, 1.5, Paint()..color = const Color(0xFFFFE9A8).withOpacity(op));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => true;
}

class _BackdropPainter extends CustomPainter {
  final double t;

  _BackdropPainter(this.t);

  static const _petals = [
    Color(0xFFFF8A3D),
    Color(0xFFFFC24D),
    Color(0xFFFF5A7A),
    Color(0xFFFFE08A)
  ];

  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.translate(s.width / 2, 90);
    c.rotate(t * 2 * math.pi / 3);
    final rg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _gold.withOpacity(.12);
    c.drawCircle(Offset.zero, 190, rg);
    c.drawCircle(Offset.zero, 160, rg);
    c.drawCircle(Offset.zero, 50, rg);
    for (var a = 0; a < 12; a++) {
      c.save();
      c.rotate(a * math.pi / 6);
      c.drawPath(
          Path()
            ..moveTo(0, -50)
            ..cubicTo(34, -90, 34, -125, 0, -160)
            ..cubicTo(-34, -125, -34, -90, 0, -50),
          rg);
      c.restore();
    }
    c.restore();

    final r = math.Random(7);
    for (var i = 0; i < 12; i++) {
      final p = Offset(r.nextDouble() * s.width, 60 + r.nextDouble() * 360);
      final w = 4 + r.nextDouble() * 9;
      final ph = math.sin((t * 3 + r.nextDouble()) * 2 * math.pi);
      c.drawCircle(
        p + Offset(0, -8 * ph),
        w * (1 + .1 * ph),
        Paint()
          ..shader = RadialGradient(
                  colors: const [Color(0x8CFFD78C), Color(0x00FFD78C)])
              .createShader(Rect.fromCircle(center: p, radius: w)),
      );
    }

    for (var i = 0; i < 16; i++) {
      final dur = 6 + r.nextDouble() * 5,
          x = r.nextDouble() * s.width,
          dx = (r.nextDouble() - .5) * 80;
      final life = ((t * 16) / dur + r.nextDouble()) % 1;
      c.save();
      c.translate(x + dx * life, -20 + (s.height + 40) * life);
      c.rotate(life * 9.4);
      c.drawPath(
          Path()
            ..moveTo(-6, 0)
            ..quadraticBezierTo(-6, -8, 6, -8)
            ..quadraticBezierTo(6, 0, -6, 0)
            ..close(),
          Paint()..color = _petals[i % 4].withOpacity(.85));
      c.drawPath(
          Path()
            ..moveTo(-6, 0)
            ..quadraticBezierTo(6, 0, 6, 8)
            ..quadraticBezierTo(-6, 8, -6, 0)
            ..close(),
          Paint()..color = _petals[i % 4].withOpacity(.85));
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter o) => o.t != t;
}

class _GarlandPainter extends CustomPainter {
  final double t;

  _GarlandPainter(this.t);

  @override
  void paint(Canvas c, Size s) {
    final k = s.width / 390;
    for (final (x, ph) in [
      (6.0, 0.0),
      (97.5, .25),
      (195.0, .45),
      (292.5, .12),
      (384.0, .38)
    ]) {
      c.save();
      c.translate(x * k, 6);
      c.rotate(math.sin((t + ph) * 2 * math.pi) * .14);
      c.drawLine(Offset.zero, const Offset(0, 38),
          Paint()..color = const Color(0xFFC9963A)..strokeWidth = 1.2);
      c.drawPath(
          Path()
            ..moveTo(-8, 52)
            ..quadraticBezierTo(-8, 38, 0, 38)
            ..quadraticBezierTo(8, 38, 8, 52)
            ..close(),
          Paint()
            ..shader = const LinearGradient(colors: [
              Color(0xFF8A5A16),
              Color(0xFFFFE7A6),
              Color(0xFFB07A1E)
            ]).createShader(const Rect.fromLTWH(-8, 38, 16, 14)));
      c.drawCircle(
          const Offset(0, 54), 2.4, Paint()..color = const Color(0xFF8A5A16));
      c.restore();
    }

    for (var i = 0; i < 4; i++) {
      final x0 = i * 97.5 * k, x1 = x0 + 97.5 * k;
      for (var j = 0; j <= 12; j++) {
        final f = j / 12,
            x = x0 + (x1 - x0) * f,
            y = 6 + 34 * math.sin(math.pi * f);
        c.drawCircle(
            Offset(x, y),
            5.2,
            Paint()
              ..color = const [
                Color(0xFFFF8A1F),
                Color(0xFFFFB22E),
                Color(0xFFFF6A1A)
              ][j % 3]);
        c.drawCircle(
            Offset(x, y), 2.2, Paint()..color = const Color(0xFFFFD66B));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GarlandPainter o) => o.t != t;
}

class _ScallopPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = const Color(0xFFFFF8F0);
    for (var x = 6.0; x < s.width; x += 12) {
      c.drawCircle(Offset(x, 6), 5, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
