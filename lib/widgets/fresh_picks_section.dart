// fresh_picks_section.dart
// "Fresh picks, just for you" — Amma's kitchen scene. New products rise out of a brass kadai on a real-looking
// fire, one by one. Everything is managed from the admin dashboard via the backend.

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

class FPVariant {
  final String id, label;
  final num price, mrp;
  final bool inStock;

  const FPVariant(this.id, this.label, this.price, this.mrp, this.inStock);

  factory FPVariant.fromJson(Map j) => FPVariant(
        '${j['id'] ?? ''}',
        j['label'] ?? '',
        j['price'] ?? 0,
        j['mrp'] ?? j['price'] ?? 0,
        j['inStock'] ?? true,
      );
}

class FPProduct {
  final String id, name, tagline, image, madeLabel, batch, badge;
  final List<FPVariant> variants;

  const FPProduct({
    required this.id,
    required this.name,
    required this.tagline,
    required this.image,
    required this.madeLabel,
    required this.batch,
    required this.badge,
    required this.variants,
  });

  factory FPProduct.fromJson(Map j) => FPProduct(
        id: '${j['id'] ?? ''}',
        name: j['name'] ?? '',
        tagline: j['tagline'] ?? '',
        image: j['image'] ?? '',
        madeLabel: j['madeLabel'] ?? '',
        batch: j['batch'] ?? '',
        badge: j['badge'] ?? 'NEW',
        variants: ((j['variants'] ?? []) as List)
            .map((e) => FPVariant.fromJson(e))
            .toList(),
      );
}

class FreshPicksData {
  final bool enabled;
  final String kicker, title, titleAccent, subtitle;
  final int intervalMs;
  final List<FPProduct> products;

  const FreshPicksData({
    this.enabled = true,
    this.kicker = 'FRESH OFF THE STOVE',
    this.title = 'Fresh picks,',
    this.titleAccent = 'just for you',
    this.subtitle = "new from Amma's kitchen this week",
    this.intervalMs = 3400,
    this.products = const [],
  });

  factory FreshPicksData.fromJson(Map j) {
    final s = (j['settings'] ?? {}) as Map;
    return FreshPicksData(
      enabled: s['enabled'] ?? true,
      kicker: s['kicker'] ?? 'FRESH OFF THE STOVE',
      title: s['title'] ?? 'Fresh picks,',
      titleAccent: s['titleAccent'] ?? 'just for you',
      subtitle: s['subtitle'] ?? "new from Amma's kitchen this week",
      intervalMs: math.max(2500, ((s['intervalMs'] as num?)?.toInt()) ?? 3400),
      products: ((j['products'] ?? []) as List)
          .map((e) => FPProduct.fromJson(e))
          .toList(),
    );
  }
}

// ============================ SECTION ============================

const _orange = Color(0xFFE2572B);
const _brown = Color(0xFF6E2E14);
const _stageH = 346.0;

class FreshPicksSection extends StatefulWidget {
  final FreshPicksData? data;
  final ValueChanged<FPProduct>? onOpen;
  final Future<void> Function(FPProduct, FPVariant)? onAdd;
  final VoidCallback? onViewAll;

  const FreshPicksSection({
    super.key,
    this.data,
    this.onOpen,
    this.onAdd,
    this.onViewAll,
  });

  @override
  State<FreshPicksSection> createState() => _FreshPicksSectionState();
}

class _FreshPicksSectionState extends State<FreshPicksSection>
    with TickerProviderStateMixin {
  int _cur = 0;
  Timer? _timer;
  bool _sinking = false;
  final Map<String, int> _variant = {};
  String? _added;

  late final _fire =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))
        ..repeat();
  late final _sway = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 5000))
    ..repeat();
  late final _rise = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1150));
  late final _sink = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
  late final _info = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 450), value: 1);
  late final _tags = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));

  StreamSubscription? _sub;
  FreshPicksData _liveData = defaultFreshPicksData;

  @override
  void initState() {
    super.initState();
    _rise.value = 1;
    _tags.forward();
    _listenToFreshPicksConfig();
    _schedule();
  }

  void _listenToFreshPicksConfig() {
    _sub = AppConfigRepository().getFreshPicksStream().listen((data) {
      if (!mounted) return;
      if (data.isNotEmpty) {
        final parsed = FreshPicksData.fromJson(data);
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

  FreshPicksData get _effectiveData =>
      widget.data != null && widget.data!.products.isNotEmpty
          ? widget.data!
          : _liveData;

  List<FPProduct> get _p => _effectiveData.products;

  @override
  void didUpdateWidget(covariant FreshPicksSection old) {
    super.didUpdateWidget(old);
    if (_cur >= _p.length) _cur = 0;
    _schedule();
  }

  void _schedule([Duration? d]) {
    _timer?.cancel();
    if (_p.length < 2) return;
    _timer = Timer(
        d ?? Duration(milliseconds: _effectiveData.intervalMs),
        () => _go((_cur + 1) % _p.length));
  }

  Future<void> _go(int i, {bool user = false}) async {
    if (!mounted || i == _cur || _sinking) return;
    _timer?.cancel();
    setState(() => _sinking = true);
    _info.reverse();
    await _sink.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _cur = i;
      _sinking = false;
    });
    _sink.value = 0;
    _rise.forward(from: 0);
    _info.forward();
    _tags.forward(from: 0);
    _schedule(
        user ? Duration(milliseconds: _effectiveData.intervalMs + 4000) : null);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    for (final c in [_fire, _sway, _rise, _sink, _info, _tags]) {
      c.dispose();
    }
    super.dispose();
  }

  void _openProductDetail(FPProduct p) {
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const RadialGradient(
          center: Alignment(0, .05),
          radius: 1.05,
          colors: [Color(0xFFB35A2E), Color(0xFF7A3418), Color(0xFF3A1508)],
          stops: [0, .52, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: RadialGradient(
                    radius: .9,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF140600).withOpacity(.5)
                    ],
                    stops: const [.6, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: AnimatedBuilder(
                  animation: _fire,
                  builder: (_, __) => Transform.rotate(
                    angle: _fire.value * 2 * math.pi / 10,
                    child: CustomPaint(
                      size: const Size(320, 320),
                      painter: _KolamPainter(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(
                height: 48,
                child: AnimatedBuilder(
                  animation: _sway,
                  builder: (_, __) => CustomPaint(
                    size: const Size(double.infinity, 48),
                    painter: _ToranPainter(_sway.value),
                  ),
                ),
              ),
              _board(activeData),
              _stage(p),
              _card(p),
              if (_p.length > 1) _shelf(),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (widget.onViewAll != null) {
                    widget.onViewAll!();
                  } else {
                    AppNavigator.push(
                      context,
                      const ProductListingPage(category: 'Pickles'),
                    );
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                        colors: [Color(0xFFF6C453), Color(0xFFFFE39A)]),
                  ),
                  child: Text(
                    'View all fresh picks →',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3E170A),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _board(FreshPicksData activeData) => AnimatedBuilder(
        animation: _sway,
        builder: (_, child) => Transform.rotate(
          alignment: const Alignment(0, -1.6),
          angle: math.sin(_sway.value * 2 * math.pi) * .026,
          child: child,
        ),
        child: Container(
          width: 250,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFA8743C),
                Color(0xFF6B4220),
                Color(0xFFB98448),
                Color(0xFF5E3A1A)
              ],
            ),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x99000000), blurRadius: 20, offset: Offset(0, 10))
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-.4, -.6),
                radius: 1.4,
                colors: [Color(0xFF34463C), Color(0xFF1F2B25)],
              ),
            ),
            child: Column(
              children: [
                Text(
                  '✦ ${activeData.kicker} ✦',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    letterSpacing: 2.4,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF6C453),
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${activeData.title} '),
                      TextSpan(
                        text: activeData.titleAccent,
                        style: const TextStyle(color: Color(0xFFFFB37A)),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fraunces(
                    fontSize: 25,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    color: const Color(0xFFF4EFE2),
                    shadows: const [
                      Shadow(color: Color(0x40FFFFFF), blurRadius: 6)
                    ],
                  ),
                ),
                if (activeData.subtitle.isNotEmpty)
                  Text(
                    activeData.subtitle,
                    style: GoogleFonts.fraunces(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xD9CFE3D5),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

  Widget _stage(FPProduct p) {
    return SizedBox(
      height: _stageH,
      child: LayoutBuilder(
        builder: (_, box) {
          final cx = box.maxWidth / 2;
          return GestureDetector(
            onTap: () => _openProductDetail(p),
            child: AnimatedBuilder(
              animation: Listenable.merge([_fire, _rise, _sink, _tags]),
              builder: (_, __) {
                final t = _fire.value;
                final rise = Curves.easeOutCubic.transform(_rise.value);
                final sink = Curves.easeInCubic.transform(_sink.value);
                final bowlY = _sinking
                    ? 105 * sink
                    : 105 * (1 - rise) + math.sin(t * 2 * math.pi * 1.5) * 4 * rise;
                final dark = _sinking ? .4 * sink : .3 * (1 - rise);
                final tagT = Curves.elasticOut
                    .transform(((_tags.value - .3) / .7).clamp(0.0, 1.0));
                final float = math.sin(t * 2 * math.pi * 2) * 3;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: cx - 150,
                      bottom: 10,
                      child: Container(
                        width: 300,
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: const [
                              Color(0x80FF9632),
                              Color(0x00FF9632)
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: cx - 80,
                      bottom: 176,
                      child: CustomPaint(
                        size: const Size(160, 130),
                        painter: _SteamPainter(t),
                      ),
                    ),
                    Positioned(
                      left: cx - 115,
                      bottom: 36,
                      child: CustomPaint(
                        size: const Size(230, 100),
                        painter: _FirePainter(t),
                      ),
                    ),
                    Positioned(
                      left: cx - 130,
                      bottom: 66,
                      child: CustomPaint(
                        size: const Size(260, 120),
                        painter: _KadaiBackPainter(t),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom: 84,
                      child: ClipRect(
                        child: Stack(
                          children: [
                            Positioned(
                              left: cx - 88,
                              bottom: 22,
                              child: Transform.translate(
                                offset: Offset(0, bowlY),
                                child: ColorFiltered(
                                  colorFilter: ColorFilter.matrix(_darken(dark)),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x66000000),
                                          blurRadius: 18,
                                          offset: Offset(0, 14),
                                          spreadRadius: -20,
                                        ),
                                      ],
                                    ),
                                    child: _buildImg(p.image, 176, 140),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: cx - 130,
                      bottom: 66,
                      child: CustomPaint(
                        size: const Size(260, 120),
                        painter: _KadaiFrontPainter(),
                      ),
                    ),
                    Positioned(
                      left: cx - 120,
                      bottom: -4,
                      child: CustomPaint(
                        size: const Size(240, 70),
                        painter: _StovePainter(t),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _EmberPainter(t, cx),
                        ),
                      ),
                    ),
                    if (p.madeLabel.isNotEmpty)
                      Positioned(
                        left: 14,
                        top: 40 + float,
                        child: Opacity(
                          opacity: tagT.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: .3 + .7 * tagT,
                            child: Transform.rotate(
                              angle: -.14,
                              child: _tag(
                                '● ${p.madeLabel}',
                                const Color(0xFFFDF6E3),
                                _brown,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (p.batch.isNotEmpty)
                      Positioned(
                        right: 14,
                        top: 84 - float,
                        child: Opacity(
                          opacity: tagT.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: .3 + .7 * tagT,
                            child: Transform.rotate(
                              angle: .1,
                              child: _tag(
                                '🔥 ${p.batch}',
                                const Color(0xFF2E7D32),
                                Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  List<double> _darken(double d) {
    final k = 1 - d;
    return [
      k, 0, 0, 0, 0,
      0, k, 0, 0, 0,
      0, 0, k, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  Widget _tag(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
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
      );

  Widget _card(FPProduct p) {
    final vi =
        (_variant[p.id] ?? 0).clamp(0, math.max(0, p.variants.length - 1));
    final v = p.variants.isEmpty ? null : p.variants[vi];
    final off = v != null && v.mrp > v.price
        ? ((1 - v.price / v.mrp) * 100).round()
        : 0;
    final added = v != null && _added == '${p.id}-${v.id}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3E8E3A), Color(0xFF58A84A), Color(0xFF2F7A2E)],
            stops: [0, .4, 1],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 22,
              offset: Offset(0, 12),
              spreadRadius: -8,
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () => _openProductDetail(p),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF2),
              borderRadius: BorderRadius.circular(22),
            ),
            child: FadeTransition(
              opacity: _info,
              child: SlideTransition(
                position:
                    Tween(begin: const Offset(0, .08), end: Offset.zero)
                        .animate(_info),
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
                        if (p.badge.isNotEmpty)
                          AnimatedBuilder(
                            animation: _sway,
                            builder: (_, child) => Transform.scale(
                              scale: 1 +
                                  .08 *
                                      math
                                          .sin(_sway.value * 2 * math.pi * 3)
                                          .abs(),
                              child: child,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                p.badge,
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (p.variants.length > 1) ...[
                      const SizedBox(height: 10),
                      Wrap(
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
                                      ? _brown
                                      : const Color(0xFFF2EADB),
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
                    ],
                    if (v != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                          rating: 4.8,
                                          image: p.image,
                                          color: const Color(0xFF18453B),
                                          category: 'Pickles',
                                          secretIngredient: IngredientDetail(
                                            name: 'Traditional Spices',
                                            description:
                                                'Aromatic hand-ground blend',
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
                                          duration: const Duration(seconds: 1),
                                          behavior: SnackBarBehavior.floating,
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
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  colors: !v.inStock
                                      ? [Colors.grey, Colors.grey.shade700]
                                      : added
                                          ? const [
                                              Color(0xFF2E7D32),
                                              Color(0xFF1B5E20)
                                            ]
                                          : const [
                                              _orange,
                                              Color(0xFFC2410C)
                                            ],
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x66C2410C),
                                    blurRadius: 14,
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
                        ],
                      ),
                    ],
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
  }

  Widget _shelf() => Padding(
        padding: const EdgeInsets.fromLTRB(14, 22, 14, 0),
        child: Column(
          children: [
            SizedBox(
              height: 74,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                itemCount: _p.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _go(i, user: true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    margin: EdgeInsets.only(
                        top: i == _cur ? 2 : 12, bottom: i == _cur ? 10 : 0),
                    width: 52,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                                bottom: Radius.circular(10)),
                            gradient: LinearGradient(colors: [
                              Colors.white.withOpacity(.08),
                              Colors.white.withOpacity(.22),
                              Colors.white.withOpacity(.06),
                              Colors.white.withOpacity(.16)
                            ]),
                            border: Border.all(
                              color: i == _cur
                                  ? const Color(0xFFF6C453)
                                  : Colors.white.withOpacity(.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              if (i == _cur)
                                BoxShadow(
                                  color: const Color(0xFFF6C453)
                                      .withOpacity(.55),
                                  blurRadius: 18,
                                )
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _buildImg(_p[i].image, 44, 38),
                        ),
                        Positioned(
                          top: -8,
                          left: 8,
                          right: 8,
                          child: Container(
                            height: 9,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(4),
                                  bottom: Radius.circular(2)),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [_orange, Color(0xFFA83A10)],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFB07A3E), Color(0xFF7A4E22)],
                ),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 8,
                      offset: Offset(0, 6))
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildImg(String u, double w, double h) {
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

  static const FreshPicksData defaultFreshPicksData = FreshPicksData(
    enabled: true,
    kicker: 'FRESH OFF THE STOVE',
    title: 'Fresh picks,',
    titleAccent: 'just for you',
    subtitle: "new from Amma's kitchen this week",
    intervalMs: 3400,
    products: [
      FPProduct(
        id: 'p1',
        name: 'Chakinalu',
        tagline: 'Sankranti spiral snack',
        image: 'assets/images/chakinalu_traditional_sankranti_spiral_snacks.jpg',
        madeLabel: 'Made today, 6 AM',
        batch: 'Batch #24',
        badge: 'NEW',
        variants: [
          FPVariant('v1', '250g', 100, 115, true),
          FPVariant('v2', '500g', 190, 220, true),
        ],
      ),
      FPProduct(
        id: 'p2',
        name: 'Idli Karam Podi',
        tagline: 'freshly roasted & ground spice powder',
        image: 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg',
        madeLabel: 'Made today, 7 AM',
        batch: 'Batch #25',
        badge: 'HOT',
        variants: [
          FPVariant('v3', '200g', 139, 150, true),
          FPVariant('v4', '500g', 320, 350, true),
        ],
      ),
      FPProduct(
        id: 'p3',
        name: 'Sunnunda Laddu',
        tagline: 'ghee-infused roasted urad laddus',
        image: 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg',
        madeLabel: 'Made today, 5 AM',
        batch: 'Batch #22',
        badge: 'FRESH',
        variants: [
          FPVariant('v5', '250g', 199, 220, true),
          FPVariant('v6', '500g', 380, 420, true),
        ],
      ),
    ],
  );
}

// ============================ PAINTERS ============================

class _FirePainter extends CustomPainter {
  final double t;

  _FirePainter(this.t);

  static final _parts = List.generate(70, (k) {
    final r = math.Random(k * 7 + 1);
    final x = 28 + r.nextDouble() * 174, c = (x - 115).abs() / 95;
    return [
      x,
      (1 - c) * 26 + 12 + r.nextDouble() * 10,
      (r.nextDouble() - .5) * 16 + (115 - x) * .18,
      26 + (1 - c) * 44 + r.nextDouble() * 18,
      .55 + r.nextDouble() * .6,
      r.nextDouble()
    ];
  });

  @override
  void paint(Canvas c, Size s) {
    final secs = t * 6;
    c.drawOval(
      Rect.fromLTWH(10, s.height - 22, s.width - 20, 26),
      Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0xE6FFAA3C),
            Color(0x80FF5A14),
            Color(0x00FF5A14)
          ],
          stops: const [0, .55, 1],
        ).createShader(Rect.fromLTWH(10, s.height - 22, s.width - 20, 26))
        ..blendMode = BlendMode.plus,
    );
    for (final p in _parts) {
      final life = ((secs / p[4]) + p[5]) % 1;
      final op = life < .1
          ? life / .1
          : life > .55
              ? 1 - (life - .55) / .45
              : 1.0;
      final sc = 1 - .8 * life;
      final w = p[1] * sc, h = p[1] * 1.8 * sc;
      final cx = p[0] + p[2] * life, cy = s.height - h / 2 - p[3] * life;
      final rect = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
      c.drawOval(
        rect,
        Paint()
          ..blendMode = BlendMode.plus
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5)
          ..shader = RadialGradient(
            center: const Alignment(0, .2),
            colors: [
              Color.fromRGBO(255, 250, 210, op),
              Color.fromRGBO(255, 200, 60, .95 * op),
              Color.fromRGBO(255, 110, 20, .85 * op),
              Color.fromRGBO(200, 40, 10, .4 * op),
              const Color.fromRGBO(120, 20, 0, 0)
            ],
            stops: const [0, .22, .48, .7, .78],
          ).createShader(rect),
      );
    }
    for (var k = 0; k < 8; k++) {
      final f = math.sin(secs * 25 + k) * .15 + 1;
      final r = Rect.fromCenter(
          center: Offset(48 + k * 21.0, s.height - 8), width: 16, height: 12 * f);
      c.drawOval(
        r,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(
            colors: const [
              Color(0xF296BEFF),
              Color(0x993C6EFF),
              Color(0x003C6EFF)
            ],
            stops: const [0, .5, .72],
          ).createShader(r),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FirePainter o) => o.t != t;
}

class _EmberPainter extends CustomPainter {
  final double t, cx;

  _EmberPainter(this.t, this.cx);

  @override
  void paint(Canvas c, Size s) {
    for (var k = 0; k < 12; k++) {
      final r = math.Random(k + 40);
      final x = cx - 80 + r.nextDouble() * 160,
          dur = 2.2 + r.nextDouble() * 1.6,
          dx = (r.nextDouble() - .5) * 60;
      final life = ((t * 6) / dur + r.nextDouble()) % 1;
      final op = life < .15 ? life / .15 : 1 - life;
      final p = Offset(x + dx * life, s.height - 40 - 170 * life);
      c.drawCircle(
        p,
        4,
        Paint()
          ..color = const Color(0xFFFF9A2A).withOpacity(.5 * op)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      c.drawCircle(
          p, 1.5, Paint()..color = const Color(0xFFFFD27A).withOpacity(op));
    }
  }

  @override
  bool shouldRepaint(covariant _EmberPainter o) => true;
}

class _SteamPainter extends CustomPainter {
  final double t;

  _SteamPainter(this.t);

  @override
  void paint(Canvas c, Size s) {
    for (var k = 0; k < 3; k++) {
      final life = ((t * 6) / 3.4 + k / 3) % 1;
      final op = (life < .3 ? life / .3 : 1 - (life - .3) / .7) * .8;
      final x = 30.0 + k * 40 + 14 * life,
          y = s.height - 40 - 90 * life,
          sc = .6 + 1.4 * life;
      c.drawOval(
        Rect.fromCenter(
            center: Offset(x, y), width: 26 * sc, height: 70 * sc),
        Paint()
          ..color = const Color(0xFFFFF8EB).withOpacity(.32 * op)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SteamPainter o) => o.t != t;
}

const _brass = [
  Color(0xFF6B3F0C),
  Color(0xFFC8902E),
  Color(0xFFFBE3A0),
  Color(0xFFE0A841),
  Color(0xFFA86F1C),
  Color(0xFF5A320A)
];
const _brassStops = [0.0, .18, .32, .45, .7, 1.0];
const _rimCols = [
  Color(0xFF8A5A16),
  Color(0xFFFFE7A6),
  Color(0xFFE8B44E),
  Color(0xFF7A4E10)
];

class _KadaiBackPainter extends CustomPainter {
  final double t;

  _KadaiBackPainter(this.t);

  @override
  void paint(Canvas c, Size s) {
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(colors: _rimCols).createShader(Offset.zero & s);
    c.drawPath(Path()..moveTo(14, 40)..cubicTo(-6, 34, -6, 58, 14, 54), rim);
    c.drawPath(
        Path()..moveTo(246, 40)..cubicTo(266, 34, 266, 58, 246, 54), rim);
    final inside =
        Rect.fromCenter(center: const Offset(130, 44), width: 236, height: 44);
    c.drawOval(
      inside,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -.4),
          radius: .7,
          colors: [Color(0xFF3A2008), Color(0xFF1E1004), Color(0xFF0E0802)],
          stops: [0, .7, 1],
        ).createShader(inside),
    );
    c.drawArc(
      inside,
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..shader =
            const LinearGradient(colors: _rimCols).createShader(Offset.zero & s),
    );
    final f = .8 + .2 * math.sin(t * 2 * math.pi * 7);
    c.drawOval(
      Rect.fromCenter(center: const Offset(130, 46), width: 160, height: 18),
      Paint()
        ..color = Color.fromRGBO(255, 190, 100, .3 * f)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(covariant _KadaiBackPainter o) => o.t != t;
}

class _KadaiFrontPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final body = Path()
      ..moveTo(12, 44)
      ..cubicTo(18, 104, 70, 118, 130, 118)
      ..cubicTo(190, 118, 242, 104, 248, 44)
      ..cubicTo(220, 62, 40, 62, 12, 44)
      ..close();
    c.drawShadow(body, Colors.black, 10, false);
    c.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(colors: _brass, stops: _brassStops)
            .createShader(Offset.zero & s),
    );
    c.drawPath(
      Path()
        ..moveTo(40, 60)
        ..cubicTo(46, 92, 70, 104, 92, 106),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    c.drawPath(
      Path()
        ..moveTo(200, 66)
        ..cubicTo(196, 90, 180, 102, 164, 108),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = Colors.black.withOpacity(.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    c.drawArc(
      Rect.fromCenter(center: const Offset(130, 44), width: 236, height: 44),
      0,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..shader =
            const LinearGradient(colors: _rimCols).createShader(Offset.zero & s),
    );
    c.drawCircle(
        const Offset(18, 47), 2.5, Paint()..color = const Color(0xFFFBE3A0));
    c.drawCircle(
        const Offset(242, 47), 2.5, Paint()..color = const Color(0xFF8A5A16));
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _StovePainter extends CustomPainter {
  final double t;

  _StovePainter(this.t);

  @override
  void paint(Canvas c, Size s) {
    c.drawPath(
      Path()
        ..moveTo(20, 30)
        ..lineTo(40, 70)
        ..lineTo(200, 70)
        ..lineTo(220, 30)
        ..close(),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9C4A26), Color(0xFF5A2410)],
        ).createShader(Offset.zero & s),
    );
    c.drawOval(
        Rect.fromCenter(
            center: const Offset(120, 30), width: 200, height: 20),
        Paint()..color = const Color(0xFF3A1406));
    final e = Rect.fromCenter(
        center: const Offset(120, 32), width: 156, height: 14);
    c.drawOval(
      e,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -.4),
          colors: [
            Color(0xFFFF8A2A),
            Color(0xFF8A2A08),
            Color(0xFF2A0E04)
          ],
          stops: [0, .6, 1],
        ).createShader(e),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(104, 44, 32, 20), const Radius.circular(14)),
      Paint()..color = const Color(0xFF1A0602),
    );
    final f = .6 + .4 * (math.sin(t * 2 * math.pi * 5) * .5 + .5);
    c.drawOval(
      Rect.fromCenter(center: const Offset(120, 58), width: 24, height: 10),
      Paint()..color = const Color(0xFFFF7A1A).withOpacity(.8 * f),
    );
  }

  @override
  bool shouldRepaint(covariant _StovePainter o) => o.t != t;
}

class _ToranPainter extends CustomPainter {
  final double t;

  _ToranPainter(this.t);

  @override
  void paint(Canvas c, Size s) {
    final step = s.width / 14;
    c.drawPath(
      Path()
        ..moveTo(0, 6)
        ..quadraticBezierTo(s.width / 2, 12, s.width, 6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFC9963A),
    );
    for (var i = 0; i < 14; i++) {
      final x = step / 2 + i * step;
      c.save();
      c.translate(x, 6);
      c.rotate(math.sin((t + i * .07) * 2 * math.pi) * .07);
      if (i.isEven) {
        final leaf = Path()
          ..moveTo(0, 0)
          ..cubicTo(-9, 12, -7, 28, 0, 38)
          ..cubicTo(7, 28, 9, 12, 0, 0);
        c.drawPath(
          leaf,
          Paint()
            ..shader = const LinearGradient(
              colors: [
                Color(0xFF2E6B22),
                Color(0xFF4E9A3A),
                Color(0xFF2A5E1E)
              ],
            ).createShader(const Rect.fromLTWH(-9, 0, 18, 38)),
        );
        c.drawLine(
          const Offset(0, 2),
          const Offset(0, 36),
          Paint()
            ..color = const Color(0xB3A8D08D)
            ..strokeWidth = .8,
        );
      } else {
        c.drawLine(
            Offset.zero, const Offset(0, 8), Paint()..color = const Color(0xFF7A5A2A));
        for (final o in [
          const Offset(-3, 12),
          const Offset(3, 12),
          const Offset(0, 9),
          const Offset(0, 15)
        ]) {
          c.drawCircle(o, 4, Paint()..color = const Color(0xFFF7931E));
        }
        c.drawCircle(const Offset(0, 12), 3, Paint()..color = const Color(0xFFFFC94D));
        c.drawCircle(
            const Offset(0, 20), 3.5, Paint()..color = const Color(0xFFF7931E));
      }
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ToranPainter o) => o.t != t;
}

class _KolamPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFFFE3B0).withOpacity(.10);
    c.translate(s.width / 2, s.height / 2);
    for (var a = 0; a < 180; a += 22) {
      c.save();
      c.rotate(a * math.pi / 180);
      c.drawOval(
          Rect.fromCenter(
              center: Offset.zero, width: s.width * .88, height: s.width * .24),
          p);
      c.restore();
    }
    c.drawCircle(Offset.zero, 19, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
