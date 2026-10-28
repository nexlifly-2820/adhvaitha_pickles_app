// most_loved_section.dart
// "Most loved products" spotlight. Auto-changes every N seconds with a fly-out / drop-in animation.

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cart_manager.dart';
import '../product_detail_page.dart';
import '../product_listing_page.dart';
import '../navigation_util.dart';
import '../product_manager.dart';
import '../app_config_repository.dart';

// ============================ MODELS ============================

Color _hex(String h) {
  try {
    return Color(int.parse('FF${h.replaceAll('#', '')}', radix: 16));
  } catch (_) {
    return const Color(0xFFF7B733);
  }
}

class MLVariant {
  final String id, label;
  final num price, mrp;
  final bool inStock;

  const MLVariant(this.id, this.label, this.price, this.mrp, this.inStock);

  factory MLVariant.fromJson(Map j) => MLVariant(
        '${j['id'] ?? ''}',
        j['label'] ?? '',
        j['price'] ?? 0,
        j['mrp'] ?? j['price'] ?? 0,
        j['inStock'] ?? true,
      );
}

class MLProduct {
  final String id, name, short, tagline, image, loves, badge;
  final List<Color> colors;
  final num rating;
  final int soldToday, spice;
  final List<MLVariant> variants;

  const MLProduct({
    required this.id,
    required this.name,
    required this.short,
    required this.tagline,
    required this.image,
    required this.loves,
    required this.badge,
    required this.colors,
    required this.rating,
    required this.soldToday,
    required this.spice,
    required this.variants,
  });

  factory MLProduct.fromJson(Map j) => MLProduct(
        id: '${j['id'] ?? ''}',
        name: j['name'] ?? '',
        short: j['short'] ?? j['name'] ?? '',
        tagline: j['tagline'] ?? '',
        image: j['image'] ?? '',
        loves: '${j['loves'] ?? ''}',
        badge: j['badge'] ?? '',
        colors: ((j['colors'] ?? ['#F7B733', '#E2722B']) as List)
            .map((e) => _hex('$e'))
            .toList(),
        rating: j['rating'] ?? 0,
        soldToday: j['soldToday'] ?? 0,
        spice: (j['spice'] ?? 0).clamp(0, 3),
        variants: ((j['variants'] ?? []) as List)
            .map((e) => MLVariant.fromJson(e))
            .toList(),
      );
}

class MostLovedData {
  final bool enabled;
  final String kicker, title, titleAccent;
  final int intervalMs;
  final List<MLProduct> products;

  const MostLovedData({
    this.enabled = true,
    this.kicker = 'THE LOVE CHART',
    this.title = 'Most loved',
    this.titleAccent = 'products',
    this.intervalMs = 2500,
    this.products = const [],
  });

  factory MostLovedData.fromJson(Map j) {
    final s = (j['settings'] ?? {}) as Map;
    final max = s['maxItems'] ?? 10;
    return MostLovedData(
      enabled: s['enabled'] ?? true,
      kicker: s['kicker'] ?? 'THE LOVE CHART',
      title: s['title'] ?? 'Most loved',
      titleAccent: s['titleAccent'] ?? 'products',
      intervalMs: math.max(1200, (s['intervalMs'] ?? 2500) as int),
      products: ((j['products'] ?? []) as List)
          .take(max)
          .map((e) => MLProduct.fromJson(e))
          .toList(),
    );
  }
}

// ============================ SECTION ============================

const _gold = Color(0xFFF6C453);
const _dark = Color(0xFF1E0A07);
const _maroon = Color(0xFF8E1B2B);

class MostLovedSection extends StatefulWidget {
  final MostLovedData? data;
  final ValueChanged<MLProduct>? onOpen;
  final Future<void> Function(MLProduct, MLVariant)? onAdd;
  final VoidCallback? onSeeAll;

  const MostLovedSection({
    super.key,
    this.data,
    this.onOpen,
    this.onAdd,
    this.onSeeAll,
  });

  @override
  State<MostLovedSection> createState() => _MostLovedSectionState();
}

class _MostLovedSectionState extends State<MostLovedSection>
    with TickerProviderStateMixin {
  int _cur = 0, _prev = -1;
  Timer? _timer;
  final Map<String, int> _variant = {};
  final Set<String> _added = {};
  final _rail = ScrollController();

  late final _ch =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final _loop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
        ..repeat();
  late final _rays =
      AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
  late final _progress = AnimationController(vsync: this);

  StreamSubscription? _sub;
  MostLovedData _liveData = defaultMostLovedData;

  @override
  void initState() {
    super.initState();
    _ch.value = 1;
    _listenToMostLovedConfig();
    _start();
  }

  void _listenToMostLovedConfig() {
    _sub = AppConfigRepository().getMostLovedStream().listen((data) {
      if (!mounted) return;
      if (data.isNotEmpty) {
        final parsed = MostLovedData.fromJson(data);
        if (parsed.products.isNotEmpty) {
          setState(() {
            _liveData = parsed;
            if (_cur >= _liveData.products.length) _cur = 0;
          });
          _start();
        }
      }
    });
  }

  MostLovedData get _effectiveData =>
      widget.data != null && widget.data!.products.isNotEmpty
          ? widget.data!
          : _liveData;

  List<MLProduct> get _p => _effectiveData.products;

  @override
  void didUpdateWidget(covariant MostLovedSection old) {
    super.didUpdateWidget(old);
    if (_cur >= _p.length) _cur = 0;
    _start();
  }

  void _start([Duration? delay]) {
    _timer?.cancel();
    if (_p.length < 2) return;
    final d = Duration(milliseconds: _effectiveData.intervalMs);
    _progress
      ..duration = delay ?? d
      ..forward(from: 0);
    _timer = Timer(delay ?? d, () => _go((_cur + 1) % _p.length));
  }

  void _go(int i, {bool user = false}) {
    if (!mounted || i == _cur) return;
    setState(() {
      _prev = _cur;
      _cur = i;
    });
    _ch.forward(from: 0);
    _centerRail(i);
    _start(user ? const Duration(seconds: 5) : null);
  }

  void _centerRail(int i) {
    if (!_rail.hasClients) return;
    const w = 82.0;
    final target = (i * w + 16 + 36 - _rail.position.viewportDimension / 2)
        .clamp(0.0, _rail.position.maxScrollExtent);
    _rail.animateTo(target,
        duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    for (final c in [_ch, _loop, _rays, _progress]) {
      c.dispose();
    }
    _rail.dispose();
    super.dispose();
  }

  double _seg(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0);

  void _openProductDetail(MLProduct p) {
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
    final activeData = _effectiveData;
    if (!activeData.enabled || _p.isEmpty) return const SizedBox.shrink();
    final p = _p[_cur];
    final vi =
        (_variant[p.id] ?? 0).clamp(0, math.max(0, p.variants.length - 1));
    final v = p.variants.isEmpty ? null : p.variants[vi];

    return Listener(
      onPointerDown: (_) {
        _timer?.cancel();
        _progress.stop();
      },
      onPointerUp: (_) => _start(const Duration(seconds: 4)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const RadialGradient(
            center: Alignment(0, -.4),
            radius: 1.2,
            colors: [Color(0xFF3A1410), _dark],
            stops: [0, .7],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _rays,
                builder: (_, __) =>
                    CustomPaint(painter: _RaysPainter(_rays.value)),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 20),
                // Header
                AnimatedBuilder(
                  animation: _loop,
                  builder: (_, __) {
                    final k = math.sin(_loop.value * math.pi);
                    return Text(
                      '✦ ${activeData.kicker} ✦',
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3 + k,
                        color: Color.lerp(_gold, const Color(0xFFFFE39A), k),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                AnimatedBuilder(
                  animation: _loop,
                  builder: (_, __) => Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                            text: '${activeData.title} ',
                            style: const TextStyle(color: Colors.white)),
                        TextSpan(
                          text: activeData.titleAccent,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            foreground: Paint()
                              ..shader = LinearGradient(
                                colors: const [
                                  Color(0xFFFFB37A),
                                  Color(0xFFFFE39A),
                                  Color(0xFFFFB37A)
                                ],
                                transform: GradientRotation(
                                    _loop.value * 2 * math.pi),
                              ).createShader(const Rect.fromLTWH(0, 0, 120, 30)),
                          ),
                        ),
                      ],
                    ),
                    style: GoogleFonts.fraunces(
                        fontSize: 27, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),
                // Spotlight
                GestureDetector(
                  onTap: () => _openProductDetail(p),
                  child: _spotlight(),
                ),
                const SizedBox(height: 26),
                // Info
                GestureDetector(
                  onTap: () => _openProductDetail(p),
                  child: AnimatedBuilder(
                    animation: _ch,
                    builder: (_, __) {
                      final t = Curves.easeOutBack
                          .transform(_seg(_ch.value, .35, .85));
                      return Opacity(
                        opacity: _seg(_ch.value, .35, .7),
                        child: Transform.translate(
                          offset: Offset(0, 24 * (1 - t)),
                          child: SizedBox(
                            height: 86,
                            child: Column(
                              children: [
                                Text(
                                  p.name,
                                  style: GoogleFonts.fraunces(
                                      fontSize: 28, color: Colors.white),
                                ),
                                Text(
                                  p.tagline,
                                  style: GoogleFonts.fraunces(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: const Color(0xFFFFCF9A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '★ ${p.rating}',
                                        style: const TextStyle(
                                            color: _gold,
                                            fontWeight: FontWeight.w700),
                                      ),
                                      if (p.soldToday > 0)
                                        TextSpan(
                                            text: ' · ${p.soldToday} sold today'),
                                    ],
                                  ),
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: const Color(0xFFE8D4C2)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Buy bar
                if (v != null) _buyBar(p, v, vi),
                // Rail
                if (_p.length > 1) _railView(),
                const SizedBox(height: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _spotlight() {
    return SizedBox(
      width: 290,
      height: 268,
      child: AnimatedBuilder(
        animation: Listenable.merge([_ch, _loop]),
        builder: (_, __) {
          final t = _ch.value;
          final p = _p[_cur];
          final old = _prev >= 0 && _prev < _p.length ? _p[_prev] : null;
          final wipe = Curves.easeInOutCubic.transform(_seg(t, .25, .6));
          final drop = _seg(t, .3, 1);
          final dropY = -230 * (1 - Curves.elasticOut.transform(drop));
          final flip = (1 - Curves.easeOut.transform(_seg(t, .3, .6))) * math.pi;
          final outT = Curves.easeInBack.transform(_seg(t, 0, .35));
          final bob = math.sin(_loop.value * 2 * math.pi) * 4;
          final shake = t > .55 && t < .7 ? math.sin(t * 120) * 2.5 : 0.0;
          final tagIn = Curves.elasticOut.transform(_seg(t, .55, 1));

          return Transform.translate(
            offset: Offset(shake, 0),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  left: 20,
                  right: 20,
                  top: 0,
                  bottom: 6,
                  child: _Arch(
                    colors: old?.colors ?? p.colors,
                    wipe: old == null ? 1 : wipe,
                    newColors: p.colors,
                  ),
                ),
                Positioned(
                  top: 4,
                  child: Opacity(
                    opacity: .2 * _seg(t, .3, .6),
                    child: Transform.translate(
                      offset: Offset(
                          0,
                          60 *
                              (1 -
                                  Curves.easeOutBack
                                      .transform(_seg(t, .3, .7)))),
                      child: Text(
                        '#${_cur + 1}',
                        style: GoogleFonts.fraunces(
                          fontSize: 130,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                        painter: _ImpactPainter(_seg(t, .5, 1))),
                  ),
                ),
                if (old != null && t < .35)
                  Positioned(
                    bottom: -16,
                    child: Opacity(
                      opacity: 1 - outT.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(-260 * outT, 40 * outT),
                        child: Transform.rotate(
                          angle: -2 * outT,
                          child: Transform.scale(
                              scale: 1 - .7 * outT, child: _bowl(old)),
                        ),
                      ),
                    ),
                  ),
                if (t >= .3 || old == null)
                  Positioned(
                    bottom: -16,
                    child: Opacity(
                      opacity: old == null ? 1 : _seg(t, .3, .4),
                      child: Transform.translate(
                        offset: Offset(0, (old == null ? 0 : dropY) + bob),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, .001)
                            ..rotateY(old == null ? 0 : flip),
                          child: _bowl(p),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 22,
                  left: 0,
                  child: _tag(
                    Transform.rotate(
                      angle: -.14,
                      child: _chip(
                        _cur == 0
                            ? '👑 No.1 this week'
                            : (p.badge.isNotEmpty
                                ? p.badge
                                : '${_cur < 3 ? '🏅 ' : ''}No.${_cur + 1} loved'),
                        Colors.white,
                        _maroon,
                      ),
                    ),
                    tagIn,
                    bob,
                  ),
                ),
                if (p.loves.isNotEmpty)
                  Positioned(
                    top: 44,
                    right: 0,
                    child: _tag(
                      Transform.rotate(
                        angle: .12,
                        child: _chip('♥ ${p.loves} love it',
                            const Color(0xFFC2273A), Colors.white),
                      ),
                      tagIn,
                      -bob,
                    ),
                  ),
                if (p.spice > 0)
                  Positioned(
                    bottom: 60,
                    left: 0,
                    child: _tag(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: _dark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _gold, width: 1.5),
                        ),
                        child: Text(
                          '${'🌶' * p.spice}  ${['Mild', 'Medium', 'Hot'][p.spice - 1]}',
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: const Color(0xFFFFE39A)),
                        ),
                      ),
                      tagIn,
                      bob * .6,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tag(Widget child, double t, double bob) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, bob * .8),
          child: Transform.scale(scale: .4 + .6 * t, child: child),
        ),
      );

  Widget _chip(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Color(0x55000000), blurRadius: 12, offset: Offset(0, 6))
          ],
        ),
        child: Text(text,
            style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w800, color: fg)),
      );

  Widget _bowl(MLProduct p) => Container(
        width: 235,
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
                color: Color(0x66000000),
                blurRadius: 30,
                offset: Offset(0, 22),
                spreadRadius: -16)
          ],
        ),
        child: _buildImg(p.image, 235),
      );

  Widget _buildImg(String u, double w, {double? h}) {
    if (u.isEmpty) {
      return SizedBox(width: w, height: h);
    }
    if (u.startsWith('http')) {
      return Image.network(
        u,
        width: w,
        height: h,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => SizedBox(width: w, height: h),
      );
    }
    String assetPath = u.startsWith('assets/') ? u : 'assets/images/$u';
    return Image.asset(
      assetPath,
      width: w,
      height: h,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => SizedBox(width: w, height: h),
    );
  }

  Widget _buyBar(MLProduct p, MLVariant v, int vi) {
    final off = v.mrp > v.price ? ((1 - v.price / v.mrp) * 100).round() : 0;
    final added = _added.contains('${p.id}-${v.id}');
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(6),
      decoration:
          BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          for (var k = 0; k < p.variants.length && k < 3; k++)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _variant[p.id] = k),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: k == vi ? const Color(0xFFFDEBD3) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    p.variants[k].label,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: !p.variants[k].inStock
                          ? Colors.black26
                          : k == vi
                              ? _maroon
                              : const Color(0xFF6B5A48),
                      decoration: p.variants[k].inStock
                          ? null
                          : TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ),
            ),
          _AddButton(
            label: v.inStock
                ? (added ? '✓ Added' : 'Add · ₹${v.price}')
                : 'Notify me',
            sub: off > 0 ? '₹${v.mrp}  $off% off' : null,
            onTap: !v.inStock
                ? null
                : () async {
                    HapticFeedback.mediumImpact();
                    if (widget.onAdd != null) {
                      await widget.onAdd!(p, v);
                    } else {
                      // Default Add to Cart
                      CartManager().addItem({
                        'id': p.id,
                        'name': p.name,
                        'variant': v.label,
                        'price': v.price,
                        'image': p.image,
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${p.name} (${v.label}) added to cart!'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                    if (!mounted) return;
                    setState(() => _added.add('${p.id}-${v.id}'));
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) setState(() => _added.remove('${p.id}-${v.id}'));
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget _railView() => SizedBox(
        height: 102,
        child: ListView(
          controller: _rail,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          children: [
            for (var i = 0; i < _p.length; i++)
              GestureDetector(
                onTap: () => _go(i, user: true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: 72,
                  margin: const EdgeInsets.only(right: 10),
                  transform:
                      Matrix4.translationValues(0, i == _cur ? -4 : 0, 0),
                  decoration: BoxDecoration(
                    color: i == _cur
                        ? _gold.withOpacity(.18)
                        : Colors.white.withOpacity(.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: i == _cur ? _gold : _gold.withOpacity(.25)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 3,
                        left: 7,
                        child: Text(
                          '${i + 1}',
                          style: GoogleFonts.fraunces(
                            fontWeight: FontWeight.w800,
                            fontSize: i < 3 ? 15 : 12,
                            color: i < 3 ? _gold : const Color(0xFFE8D4C2),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildImg(_p[i].image, 58, h: 46),
                          Text(
                            _p[i].short,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFF3E2D0),
                            ),
                          ),
                        ],
                      ),
                      if (i == _cur)
                        Positioned(
                          left: 0,
                          bottom: 0,
                          child: AnimatedBuilder(
                            animation: _progress,
                            builder: (_, __) => Container(
                              width: 72 * _progress.value,
                              height: 3,
                              color: _gold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (widget.onSeeAll != null) {
                  widget.onSeeAll!();
                } else {
                  AppNavigator.push(
                    context,
                    const ProductListingPage(category: 'Pickles'),
                  );
                }
              },
              child: Container(
                width: 72,
                margin: const EdgeInsets.only(bottom: 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _gold, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  'See all\n→',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _gold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  static const MostLovedData defaultMostLovedData = MostLovedData(
    enabled: true,
    kicker: 'THE LOVE CHART',
    title: 'Most loved',
    titleAccent: 'products',
    intervalMs: 2500,
    products: [
      MLProduct(
        id: 'p1',
        name: 'Bellam Avakaya',
        short: 'Avakaya',
        tagline: 'sweet jaggery meets fiery mango',
        image: 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
        colors: [Color(0xFFF7B733), Color(0xFFE2722B)],
        rating: 4.8,
        soldToday: 320,
        loves: '2.1k',
        spice: 2,
        badge: '👑 No.1 this week',
        variants: [
          MLVariant('v1', '250g', 120, 136, true),
          MLVariant('v2', '500g', 230, 260, true),
          MLVariant('v3', '1kg', 440, 500, true),
        ],
      ),
      MLProduct(
        id: 'p2',
        name: 'Idli Karam Podi',
        short: 'Karam Podi',
        tagline: 'authentic gun powder spice blend',
        image: 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg',
        colors: [Color(0xFF8E1B2B), Color(0xFF5C0A0D)],
        rating: 4.9,
        soldToday: 280,
        loves: '1.8k',
        spice: 3,
        badge: '🔥 Bestseller',
        variants: [
          MLVariant('v4', '200g', 139, 150, true),
          MLVariant('v5', '500g', 320, 350, true),
        ],
      ),
      MLProduct(
        id: 'p3',
        name: 'Kara Murukku',
        short: 'Murukku',
        tagline: 'crispy spiral festive savory',
        image: 'assets/images/karam_janthukalu_murukku_strings_snack.jpg',
        colors: [Color(0xFF18453B), Color(0xFF235D4E)],
        rating: 4.7,
        soldToday: 195,
        loves: '1.4k',
        spice: 1,
        badge: '✨ Crunchy',
        variants: [
          MLVariant('v6', '250g', 129, 140, true),
          MLVariant('v7', '500g', 249, 270, true),
        ],
      ),
      MLProduct(
        id: 'p4',
        name: 'Sunnunda Laddu',
        short: 'Sunnunda',
        tagline: 'roasted urad dal & pure cow ghee',
        image: 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg',
        colors: [Color(0xFF8B4513), Color(0xFFB8860B)],
        rating: 4.9,
        soldToday: 210,
        loves: '1.9k',
        spice: 0,
        badge: '🍯 Ghee Special',
        variants: [
          MLVariant('v8', '250g', 199, 220, true),
          MLVariant('v9', '500g', 380, 420, true),
        ],
      ),
    ],
  );
}

// ============================ PIECES ============================

class _Arch extends StatelessWidget {
  final List<Color> colors, newColors;
  final double wipe;

  const _Arch({
    required this.colors,
    required this.newColors,
    required this.wipe,
  });

  @override
  Widget build(BuildContext context) {
    const r = BorderRadius.only(
      topLeft: Radius.circular(125),
      topRight: Radius.circular(125),
      bottomLeft: Radius.circular(22),
      bottomRight: Radius.circular(22),
    );
    return Container(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [
          const BoxShadow(color: _dark, spreadRadius: 5),
          BoxShadow(color: _gold.withOpacity(.55), spreadRadius: 7),
          BoxShadow(
            color: newColors.last.withOpacity(.5),
            blurRadius: 50,
            offset: const Offset(0, 30),
            spreadRadius: -10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: colors,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: ClipPath(
                clipper: _CircleClip(wipe),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: newColors,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(115),
                    topRight: Radius.circular(115),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.all(
                      color: Colors.white.withOpacity(.45), width: 1.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleClip extends CustomClipper<Path> {
  final double t;

  _CircleClip(this.t);

  @override
  Path getClip(Size s) => Path()
    ..addOval(Rect.fromCircle(
        center: Offset(s.width / 2, s.height * .85), radius: s.height * 1.5 * t));

  @override
  bool shouldReclip(covariant _CircleClip o) => o.t != t;
}

class _ImpactPainter extends CustomPainter {
  final double t;

  _ImpactPainter(this.t);

  @override
  void paint(Canvas c, Size s) {
    if (t <= 0 || t >= 1) return;
    final ctr = Offset(s.width / 2, s.height * .62);
    for (final (d, col) in [
      (0.0, const Color(0xFFFFE39A)),
      (.15, Colors.white)
    ]) {
      final tt = ((t - d) / .6).clamp(0.0, 1.0);
      if (tt <= 0 || tt >= 1) continue;
      c.drawCircle(
        ctr,
        10 + 140 * tt,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = col.withOpacity(1 - tt),
      );
    }
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (var k = 0; k < 12; k++) {
      final a = k / 12 * 2 * math.pi, dist = 110 + (k % 3) * 18.0;
      final tt = Curves.easeOut.transform(t);
      tp.text = TextSpan(
        text: '✦',
        style: TextStyle(
            fontSize: 14, color: const Color(0xFFFFE39A).withOpacity(1 - t)),
      );
      tp.layout();
      tp.paint(
          c, ctr + Offset(math.cos(a), math.sin(a)) * dist * tt - const Offset(7, 7));
    }
  }

  @override
  bool shouldRepaint(covariant _ImpactPainter o) => o.t != t;
}

class _RaysPainter extends CustomPainter {
  final double t;

  _RaysPainter(this.t);

  @override
  void paint(Canvas c, Size s) {
    final ctr = Offset(s.width / 2, s.height * .32), r = s.longestSide * 1.2;
    final p = Paint()..color = _gold.withOpacity(.07);
    for (var i = 0; i < 20; i++) {
      final a = t * 2 * math.pi + i * 2 * math.pi / 20;
      c.drawPath(
        Path()
          ..moveTo(ctr.dx, ctr.dy)
          ..lineTo(ctr.dx + r * math.cos(a), ctr.dy + r * math.sin(a))
          ..lineTo(
              ctr.dx + r * math.cos(a + .1), ctr.dy + r * math.sin(a + .1))
          ..close(),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RaysPainter o) => o.t != t;
}

class _AddButton extends StatefulWidget {
  final String label;
  final String? sub;
  final Future<void> Function()? onTap;

  const _AddButton({required this.label, this.sub, this.onTap});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton>
    with SingleTickerProviderStateMixin {
  late final _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  bool _busy = false, _down = false;

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap == null || _busy
          ? null
          : () async {
              setState(() => _busy = true);
              try {
                await widget.onTap!();
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
      child: AnimatedScale(
        scale: _down ? .94 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          constraints: const BoxConstraints(minWidth: 112),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: widget.onTap == null
                  ? [Colors.grey, Colors.grey.shade700]
                  : const [Color(0xFFC2273A), _maroon],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          widget.label,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                  if (widget.sub != null)
                    Text(
                      widget.sub!,
                      style: GoogleFonts.poppins(
                          fontSize: 9.5, color: Colors.white70),
                    ),
                ],
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _shine,
                    builder: (_, __) {
                      final x = -1.6 +
                          3.2 *
                              Curves.easeInOut.transform(
                                  (_shine.value / .6).clamp(0.0, 1.0));
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(x - .4, 0),
                            end: Alignment(x + .4, 0),
                            colors: const [
                              Colors.transparent,
                              Color(0x80FFFFFF),
                              Colors.transparent
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
