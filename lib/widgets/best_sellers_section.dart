// best_sellers_section.dart
// "Best sellers" champions podium. Category tabs auto-rotate; each shows its top 3 on gold/silver/bronze
// steps with medals, plus ranks #4.. as rows. Everything comes from the admin dashboard via the backend.

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

class BSItem {
  final String id, variantId, name, image, sold, move;
  final num price, mrp, rating;
  final int moveBy;

  const BSItem({
    required this.id,
    required this.variantId,
    required this.name,
    required this.image,
    required this.sold,
    required this.move,
    required this.price,
    required this.mrp,
    required this.rating,
    required this.moveBy,
  });

  factory BSItem.fromJson(Map j) => BSItem(
        id: '${j['id'] ?? ''}',
        variantId: '${j['variantId'] ?? ''}',
        name: j['name'] ?? '',
        image: j['image'] ?? '',
        sold: '${j['sold'] ?? ''}',
        move: j['move'] ?? '',
        price: j['price'] ?? 0,
        mrp: j['mrp'] ?? 0,
        rating: j['rating'] ?? 0,
        moveBy: ((j['moveBy'] as num?)?.toInt()) ?? 0,
      );
}

class BSCategory {
  final String id, name, emoji;
  final List<BSItem> items;

  const BSCategory(this.id, this.name, this.emoji, this.items);

  factory BSCategory.fromJson(Map j) => BSCategory(
        '${j['id'] ?? ''}',
        j['name'] ?? '',
        j['emoji'] ?? '',
        ((j['items'] ?? []) as List).map((e) => BSItem.fromJson(e)).toList(),
      );
}

class BestSellersData {
  final bool enabled;
  final String kicker, title, titleAccent, subtitle;
  final int intervalMs, rows;
  final List<BSCategory> categories;

  const BestSellersData({
    this.enabled = true,
    this.kicker = "THIS MONTH'S CHAMPIONS",
    this.title = 'Best',
    this.titleAccent = 'sellers',
    this.subtitle = 'Ranked by real orders from 12,000+ homes',
    this.intervalMs = 4000,
    this.rows = 3,
    this.categories = const [],
  });

  factory BestSellersData.fromJson(Map j) {
    final s = (j['settings'] ?? {}) as Map;
    return BestSellersData(
      enabled: s['enabled'] ?? true,
      kicker: s['kicker'] ?? "THIS MONTH'S CHAMPIONS",
      title: s['title'] ?? 'Best',
      titleAccent: s['titleAccent'] ?? 'sellers',
      subtitle: s['subtitle'] ?? 'Ranked by real orders from 12,000+ homes',
      intervalMs: math.max(2500, ((s['intervalMs'] as num?)?.toInt()) ?? 4000),
      rows: ((s['rows'] as num?)?.toInt()) ?? 3,
      categories: ((j['categories'] ?? []) as List)
          .map((e) => BSCategory.fromJson(e))
          .where((c) => c.items.isNotEmpty)
          .toList(),
    );
  }
}

// ============================ COLOURS ============================

const _gold = Color(0xFFF6C453);
const _green = Color(0xFF0E3B2A);
const _medal = {
  1: [Color(0xFFFFF1BF), Color(0xFFF6C453), Color(0xFFB8801E)],
  2: [Color(0xFFFFFFFF), Color(0xFFC9D0D7), Color(0xFF848D97)],
  3: [Color(0xFFFFE0C6), Color(0xFFD98E55), Color(0xFF8E5024)],
};
const _step = {
  1: [Color(0xFFFBE39A), Color(0xFFE1AC40), Color(0xFFA8721A)],
  2: [Color(0xFFF4F6F8), Color(0xFFBCC3CB), Color(0xFF848D97)],
  3: [Color(0xFFF6CBA4), Color(0xFFCC844C), Color(0xFF8E5024)],
};

// ============================ SECTION ============================

class BestSellersSection extends StatefulWidget {
  final BestSellersData? data;
  final ValueChanged<BSItem>? onOpen;
  final Future<void> Function(BSItem)? onAdd;
  final ValueChanged<BSCategory>? onSeeAll;

  const BestSellersSection({
    super.key,
    this.data,
    this.onOpen,
    this.onAdd,
    this.onSeeAll,
  });

  @override
  State<BestSellersSection> createState() => _BestSellersSectionState();
}

class _BestSellersSectionState extends State<BestSellersSection>
    with TickerProviderStateMixin {
  int _cat = 0;
  Timer? _timer;
  final Set<String> _added = {};
  late final _in =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  late final _out =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  late final _loop =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  late final _slow =
      AnimationController(vsync: this, duration: const Duration(seconds: 26))..repeat();
  late final _progress = AnimationController(vsync: this);
  final _tabKeys = <GlobalKey>[];

  StreamSubscription? _sub;
  BestSellersData _liveData = defaultBestSellersData;

  @override
  void initState() {
    super.initState();
    _in.forward();
    _listenToBestSellersConfig();
    _schedule();
  }

  void _listenToBestSellersConfig() {
    _sub = AppConfigRepository().getBestSellersStream().listen((data) {
      if (!mounted) return;
      if (data.isNotEmpty) {
        final parsed = BestSellersData.fromJson(data);
        if (parsed.categories.isNotEmpty) {
          setState(() {
            _liveData = parsed;
            if (_cat >= _liveData.categories.length) _cat = 0;
          });
          _schedule();
        }
      }
    });
  }

  BestSellersData get _effectiveData =>
      widget.data != null && widget.data!.categories.isNotEmpty
          ? widget.data!
          : _liveData;

  List<BSCategory> get _cats => _effectiveData.categories;

  @override
  void didUpdateWidget(covariant BestSellersSection old) {
    super.didUpdateWidget(old);
    if (_cat >= _cats.length) _cat = 0;
    _schedule();
  }

  void _schedule([Duration? d]) {
    _timer?.cancel();
    if (_cats.length < 2) return;
    final dur = d ?? Duration(milliseconds: _effectiveData.intervalMs);
    _progress
      ..duration = dur
      ..forward(from: 0);
    _timer = Timer(dur, () => _switch((_cat + 1) % _cats.length));
  }

  Future<void> _switch(int i, {bool user = false}) async {
    if (!mounted || i == _cat || _out.isAnimating) return;
    _timer?.cancel();
    await _out.forward(from: 0);
    if (!mounted) return;
    setState(() => _cat = i);
    _out.value = 0;
    _in.forward(from: 0);
    _schedule(user ? Duration(milliseconds: _effectiveData.intervalMs + 4000) : null);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    for (final c in [_in, _out, _loop, _slow, _progress]) {
      c.dispose();
    }
    super.dispose();
  }

  double _seg(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0);

  void _openProductDetail(BSItem item) {
    HapticFeedback.lightImpact();
    if (widget.onOpen != null) {
      widget.onOpen!(item);
      return;
    }

    final allProducts = ProductManager().products;
    final cleanName = item.name.toLowerCase().trim();

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
      AppNavigator.push(context, ProductListingPage(category: item.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeData = _effectiveData;
    if (!activeData.enabled || _cats.isEmpty) return const SizedBox.shrink();
    final cat = _cats[_cat];
    final items = cat.items;
    final rows = items.skip(3).take(activeData.rows).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const RadialGradient(
          center: Alignment(0, -.1),
          radius: 1.1,
          colors: [Color(0xFF1C6A4A), _green, Color(0xFF071B13)],
          stops: [0, .45, 1],
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x660B2A1F), blurRadius: 30, offset: Offset(0, 16))
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: Listenable.merge([_loop, _slow]),
                builder: (_, __) =>
                    CustomPaint(painter: _StagePainter(_slow.value, _loop.value)),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: _gold.withOpacity(.45), width: 1.5),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 22, 14, 18),
            child: Column(
              children: [
                _header(activeData),
                if (_cats.length > 1) ...[const SizedBox(height: 14), _tabs()],
                const SizedBox(height: 14),
                _podium(items),
                Container(
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF0A2318), Color(0xFF04110B)],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                for (var k = 0; k < rows.length; k++) _row(rows[k], k + 4, k),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (widget.onSeeAll != null) {
                      widget.onSeeAll!(cat);
                    } else {
                      AppNavigator.push(
                        context,
                        ProductListingPage(
                          category: cat.id == 'all' ? 'Pickles' : cat.name,
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient:
                          const LinearGradient(colors: [_gold, Color(0xFFFFE39A)]),
                      boxShadow: [
                        BoxShadow(
                          color: _gold.withOpacity(.5),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                          spreadRadius: -6,
                        ),
                      ],
                    ),
                    child: Text(
                      'See all ${cat.id == 'all' ? 'bestsellers' : cat.name.toLowerCase()} →',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _green,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BestSellersData activeData) => Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _gold.withOpacity(.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _gold.withOpacity(.35)),
            ),
            child: Text(
              '🏆 ${activeData.kicker}',
              style: GoogleFonts.poppins(
                fontSize: 9.5,
                letterSpacing: 2.6,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFFE39A),
              ),
            ),
          ),
          const SizedBox(height: 6),
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
                            _gold,
                            Color(0xFFFFF1BF),
                            Color(0xFFE2A93A)
                          ],
                          transform:
                              GradientRotation(_loop.value * 2 * math.pi),
                        ).createShader(const Rect.fromLTWH(0, 0, 120, 34)),
                    ),
                  ),
                ],
              ),
              style:
                  GoogleFonts.fraunces(fontSize: 31, fontWeight: FontWeight.w600),
            ),
          ),
          if (activeData.subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                activeData.subtitle,
                style: GoogleFonts.poppins(
                    fontSize: 10.5, color: const Color(0xFFBFD8C8)),
              ),
            ),
        ],
      );

  Widget _tabs() {
    while (_tabKeys.length < _cats.length) {
      _tabKeys.add(GlobalKey());
    }
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withOpacity(.18)),
      ),
      child: LayoutBuilder(
        builder: (_, box) {
          final w = box.maxWidth / _cats.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutBack,
                left: w * _cat,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient:
                        const LinearGradient(colors: [_gold, Color(0xFFFFE39A)]),
                    boxShadow: [
                      BoxShadow(
                        color: _gold.withOpacity(.6),
                        blurRadius: 12,
                        spreadRadius: -2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.bottomLeft,
                  child: AnimatedBuilder(
                    animation: _progress,
                    builder: (_, __) => Container(
                      height: 3,
                      width: w * _progress.value,
                      color: _green.withOpacity(.5),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < _cats.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _switch(i, user: true),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${_cats[i].emoji} ${_cats[i].name}',
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: i == _cat
                                    ? _green
                                    : const Color(0xFFBFD8C8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _podium(List<BSItem> items) {
    final order = [2, 1, 3];
    return SizedBox(
      height: 352,
      child: AnimatedBuilder(
        animation: Listenable.merge([_in, _out, _loop]),
        builder: (_, __) => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final r in order)
              Expanded(
                flex: r == 1 ? 112 : 106,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: r <= items.length
                      ? _column(items[r - 1], r)
                      : const SizedBox(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _column(BSItem it, int rank) {
    final t = _in.value, o = _out.value;
    final stepDelay = {3: .0, 2: .07, 1: .14}[rank]!;
    final dropDelay = {3: .16, 2: .23, 1: .32}[rank]!;
    final rise = Curves.easeOutBack
            .transform(_seg(t, stepDelay, stepDelay + .32)) *
        (1 - Curves.easeIn.transform(_seg(o, .3, 1)));
    final drop = _seg(t, dropDelay, dropDelay + .34);
    final dropY = -260 * (1 - Curves.elasticOut.transform(drop));
    final outY = -200 * Curves.easeInBack.transform(_seg(o, 0, .9));
    final medalT =
        _seg(t, rank == 1 ? .52 : .45, (rank == 1 ? .52 : .45) + .36);
    final swing = math.sin(_loop.value * 2 * math.pi) * .12;
    final bob = math.sin((_loop.value + rank / 3) * 2 * math.pi) * 5;
    final big = rank == 1;
    final stepH = {1: 146.0, 2: 118.0, 3: 106.0}[rank]!;
    final added = _added.contains(it.id);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () => _openProductDetail(it),
          child: Opacity(
            opacity: (drop * 2).clamp(0.0, 1.0) * (1 - _seg(o, 0, .8)),
            child: Transform.translate(
              offset: Offset(0, dropY + outY + bob),
              child: Transform.rotate(
                angle: -.4 * (1 - drop) + .5 * _seg(o, 0, 1),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    Column(
                      children: [
                        _buildImg(it.image, big ? 142 : 100, big ? 110 : 78),
                        Container(
                          width: big ? 96 : 68,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x88000000), blurRadius: 6)
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          it.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.fraunces(
                            fontSize: big ? 15.5 : 12.5,
                            color: Colors.white,
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '₹${it.price}'),
                              if (it.mrp > it.price)
                                TextSpan(
                                  text: ' ₹${it.mrp}',
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Color(0xFF8FB7A0),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                            ],
                          ),
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _gold),
                        ),
                        const SizedBox(height: 7),
                      ],
                    ),
                    Positioned(
                      right: big ? -10 : -8,
                      top: big ? -18 : -6,
                      child: Opacity(
                        opacity: medalT.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(
                              0,
                              -140 *
                                  (1 - Curves.easeOutBack.transform(medalT))),
                          child: Transform.rotate(
                            alignment: Alignment.topCenter,
                            angle: medalT < 1 ? -3 * (1 - medalT) : swing,
                            child: CustomPaint(
                              size: Size(big ? 46 : 32, (big ? 46 : 32) * 1.3),
                              painter: _MedalPainter(rank),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (big)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                              painter: _BurstPainter(_seg(t, .5, .95))),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.diagonal3Values(1, rise.clamp(0.0, 1.2), 1),
          child: Container(
            height: stepH,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12), bottom: Radius.circular(4)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _step[rank]!,
                stops: const [0, .55, 1],
              ),
              boxShadow: [
                if (big)
                  BoxShadow(
                    color: _gold.withOpacity(.35),
                    blurRadius: 26,
                    offset: const Offset(0, -8),
                  )
              ],
            ),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(
                        -160 + 400 * ((_loop.value + rank * .33) % 1), 0),
                    child: Transform(
                      transform: Matrix4.skewX(-.3),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0),
                                Colors.white.withOpacity(.55),
                                Colors.white.withOpacity(0)
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      '$rank',
                      style: GoogleFonts.fraunces(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        color: (rank == 2
                                ? const Color(0xFF28323C)
                                : const Color(0xFF5A2D00))
                            .withOpacity(.55),
                      ),
                    ),
                    Text(
                      '${it.sold} SOLD',
                      style: GoogleFonts.poppins(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: (rank == 2
                                ? const Color(0xFF1E2832)
                                : const Color(0xFF3C1E00))
                            .withOpacity(.7),
                      ),
                    ),
                  ],
                ),
                Positioned(bottom: 9, child: _plus(it, big, added)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _plus(BSItem it, bool big, bool added) {
    final sz = big ? 38.0 : 32.0;
    return GestureDetector(
      onTap: () => _add(it),
      child: AnimatedBuilder(
        animation: _loop,
        builder: (_, __) => Container(
          width: sz,
          height: sz,
          decoration: BoxDecoration(
            color: added
                ? const Color(0xFF2F9462)
                : big
                    ? _green
                    : Colors.white,
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              const BoxShadow(
                  color: Color(0x55000000), blurRadius: 10, offset: Offset(0, 4)),
              if (big)
                BoxShadow(
                  color: _green.withOpacity(.55 * (1 - _loop.value)),
                  spreadRadius: 9 * _loop.value,
                ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            added ? '✓' : '+',
            style: TextStyle(
              fontSize: big ? 21 : 19,
              fontWeight: FontWeight.w800,
              color: added ? Colors.white : big ? _gold : _green,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _add(BSItem it) async {
    HapticFeedback.mediumImpact();
    if (widget.onAdd != null) {
      await widget.onAdd!(it);
    } else {
      final allProducts = ProductManager().products;
      final match = allProducts.firstWhere(
        (prod) => prod.name.toLowerCase().contains(it.name.toLowerCase()),
        orElse: () => Product(
          name: it.name,
          description: 'Best seller item',
          weightPriceMap: {'500g': it.price.toDouble()},
          rating: it.rating.toDouble(),
          image: it.image,
          color: const Color(0xFF18453B),
          category: 'Pickles',
          secretIngredient: IngredientDetail(
            name: 'Traditional Spices',
            description: 'Aromatic hand-ground blend',
            image: it.image,
          ),
        ),
      );
      CartManager().addToCart(match, weight: '500g');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${it.name} added to cart!'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    if (!mounted) return;
    setState(() => _added.add(it.id));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _added.remove(it.id));
    });
  }

  Widget _row(BSItem it, int rank, int k) {
    return AnimatedBuilder(
      animation: Listenable.merge([_in, _out]),
      builder: (_, child) {
        final a = Curves.easeOutBack
            .transform(_seg(_in.value, .25 + k * .06, .55 + k * .06));
        final o = _seg(_out.value, k * .1, .7 + k * .1);
        return Opacity(
          opacity: (a * (1 - o)).clamp(0.0, 1.0),
          child: Transform.translate(
              offset: Offset(60 * (1 - a) - 60 * o, 0), child: child),
        );
      },
      child: GestureDetector(
        onTap: () => _openProductDetail(it),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(colors: [
              Colors.white.withOpacity(.09),
              Colors.white.withOpacity(.03)
            ]),
            border: Border.all(color: _gold.withOpacity(.2)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: Text(
                  '$rank',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fraunces(fontSize: 19, color: _gold),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 50,
                height: 44,
                decoration: BoxDecoration(
                    color: _gold.withOpacity(.1),
                    borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: _buildImg(it.image, 46, 40),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            it.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ),
                        if (it.move.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 5),
                            child: Text(
                              it.move == 'new'
                                  ? 'NEW'
                                  : '${it.move == 'up' ? '▲' : '▼'}${it.moveBy}',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: it.move == 'up'
                                    ? const Color(0xFF5FD38A)
                                    : it.move == 'down'
                                        ? const Color(0xFFFF7B6B)
                                        : const Color(0xFFFFE39A),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      '${it.sold} sold${it.rating > 0 ? ' · ★ ${it.rating}' : ''}',
                      style: GoogleFonts.poppins(
                          fontSize: 9.5, color: const Color(0xFF9FC2AE)),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${it.price}',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _add(it),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: _added.contains(it.id)
                        ? const Color(0xFF2F9462)
                        : Colors.transparent,
                    border: Border.all(
                      color: _added.contains(it.id)
                          ? const Color(0xFF2F9462)
                          : _gold,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _added.contains(it.id) ? '✓' : 'ADD',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _added.contains(it.id) ? Colors.white : _gold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
}

// ============================ PAINTERS ============================

class _MedalPainter extends CustomPainter {
  final int rank;

  _MedalPainter(this.rank);

  @override
  void paint(Canvas c, Size s) {
    final k = s.width / 60;
    c.scale(k);
    final cols = _medal[rank]!;
    c.drawPath(
        Path()
          ..moveTo(16, 40)
          ..lineTo(8, 76)
          ..lineTo(19, 69)
          ..lineTo(26, 78)
          ..lineTo(30, 46)
          ..close(),
        Paint()..color = const Color(0xFFB71C2C));
    c.drawPath(
        Path()
          ..moveTo(44, 40)
          ..lineTo(52, 76)
          ..lineTo(41, 69)
          ..lineTo(34, 78)
          ..lineTo(30, 46)
          ..close(),
        Paint()..color = const Color(0xFF8E1B2B));
    final grad = Paint()
      ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: cols)
          .createShader(const Rect.fromLTWH(0, 0, 60, 60));

    for (var a = 0; a < 12; a++) {
      c.save();
      c.translate(30, 30);
      c.rotate(a * math.pi / 6);
      c.drawPath(
          Path()
            ..moveTo(0, -29)
            ..lineTo(5, -24)
            ..lineTo(0, -19)
            ..lineTo(-5, -24)
            ..close(),
          grad);
      c.restore();
    }
    c.drawCircle(const Offset(30, 30), 22, grad);
    c.drawCircle(
        const Offset(30, 30),
        22,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withOpacity(.7));
    final tp = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: '$rank',
        style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xCC502800)),
      ),
    )..layout();
    tp.paint(c, Offset(30 - tp.width / 2, 30 - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MedalPainter o) => o.rank != rank;
}

class _BurstPainter extends CustomPainter {
  final double t;

  _BurstPainter(this.t);

  static const _cols = [
    _gold,
    Color(0xFFE2574C),
    Colors.white,
    Color(0xFF5FD38A),
    Color(0xFFFFB37A)
  ];

  @override
  void paint(Canvas c, Size s) {
    if (t <= 0 || t >= 1) return;
    final ctr = Offset(s.width / 2, 50);
    for (final (d, col) in [
      (0.0, const Color(0xFFFFE39A)),
      (.15, Colors.white)
    ]) {
      final tt = ((t - d) / .7).clamp(0.0, 1.0);
      if (tt > 0 && tt < 1) {
        c.drawCircle(
            ctr,
            10 + 130 * tt,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = col.withOpacity(1 - tt));
      }
    }
    final rnd = math.Random(3);
    final e = Curves.easeOut.transform(t);
    for (var k = 0; k < 22; k++) {
      final a = k / 22 * 2 * math.pi, dist = 80 + rnd.nextDouble() * 110;
      c.save();
      c.translate(
          ctr.dx + math.cos(a) * dist * e, ctr.dy + (math.sin(a) * dist - 30) * e);
      c.rotate(t * 12 + k);
      c.drawRect(
          const Rect.fromLTWH(-3.5, -5, 7, 10),
          Paint()..color = _cols[k % 5].withOpacity(1 - t));
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter o) => o.t != t;
}

class _StagePainter extends CustomPainter {
  final double slow, loop;

  _StagePainter(this.slow, this.loop);

  static const _cols = [
    _gold,
    Color(0xFFE2574C),
    Colors.white,
    Color(0xFF5FD38A),
    Color(0xFFFFB37A)
  ];

  @override
  void paint(Canvas c, Size s) {
    final ctr = Offset(s.width / 2, 345);
    final g = 1 + .12 * math.sin(loop * 2 * math.pi);
    c.drawCircle(
        ctr,
        130 * g,
        Paint()
          ..shader = RadialGradient(
                  colors: const [Color(0x73FFD66E), Color(0x00FFD66E)])
              .createShader(Rect.fromCircle(center: ctr, radius: 130 * g)));

    final rays = Paint()
      ..shader = RadialGradient(
              colors: [_gold.withOpacity(.14), _gold.withOpacity(0)],
              stops: const [.2, 1])
          .createShader(Rect.fromCircle(center: ctr, radius: 280));
    for (var i = 0; i < 18; i++) {
      final a = slow * 2 * math.pi + i * 2 * math.pi / 18;
      c.drawPath(
          Path()
            ..moveTo(ctr.dx, ctr.dy)
            ..lineTo(ctr.dx + 280 * math.cos(a), ctr.dy + 280 * math.sin(a))
            ..lineTo(ctr.dx + 280 * math.cos(a + .12),
                ctr.dy + 280 * math.sin(a + .12))
            ..close(),
          rays);
    }

    void beam(double x, double baseAngle, double amp, double op) {
      c.save();
      c.translate(x, -30);
      c.rotate(baseAngle + amp * math.sin(loop * 2 * math.pi));
      final r = const Rect.fromLTWH(-65, 0, 130, 500);
      c.drawPath(
          Path()
            ..moveTo(-8, 0)
            ..lineTo(8, 0)
            ..lineTo(65, 500)
            ..lineTo(-65, 500)
            ..close(),
          Paint()
            ..shader = LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromRGBO(255, 232, 160, .4 * op),
                      const Color.fromRGBO(255, 232, 160, 0)
                    ],
                    stops: const [0, .82]).createShader(r)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      c.restore();
    }

    beam(s.width / 2, 0, .08, 1);
    beam(55, -.33, .12, .7);
    beam(s.width - 55, .33, -.12, .7);

    final rnd = math.Random(11);
    for (var k = 0; k < 16; k++) {
      final x = rnd.nextDouble() * s.width,
          speed = .6 + rnd.nextDouble() * .5,
          off = rnd.nextDouble();
      final p = (slow * 26 / (6 + 4 * rnd.nextDouble()) * speed + off) % 1;
      c.save();
      c.translate(x, -20 + p * (s.height + 40));
      c.rotate(p * 12);
      c.drawRect(
          const Rect.fromLTWH(-3, -4.5, 6, 9),
          Paint()..color = _cols[k % 5].withOpacity(.7));
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _StagePainter o) => true;
}

static const BestSellersData defaultBestSellersData = BestSellersData(
  enabled: true,
  kicker: "THIS MONTH'S CHAMPIONS",
  title: 'Best',
  titleAccent: 'sellers',
  subtitle: 'Ranked by real orders from 12,000+ homes',
  intervalMs: 4000,
  rows: 3,
  categories: [
    BSCategory(
      'all',
      'All',
      '🔥',
      [
        BSItem(
          id: 'p1',
          variantId: 'v1',
          name: 'Bellam Avakaya',
          image: 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
          price: 120,
          mrp: 136,
          sold: '12K+',
          rating: 4.8,
          move: 'up',
          moveBy: 2,
        ),
        BSItem(
          id: 'p2',
          variantId: 'v4',
          name: 'Idli Karam Podi',
          image: 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg',
          price: 139,
          mrp: 150,
          sold: '9.8K+',
          rating: 4.9,
          move: 'up',
          moveBy: 1,
        ),
        BSItem(
          id: 'p3',
          variantId: 'v8',
          name: 'Sunnunda Laddu',
          image: 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg',
          price: 199,
          mrp: 220,
          sold: '8.4K+',
          rating: 4.9,
          move: 'new',
          moveBy: 0,
        ),
        BSItem(
          id: 'p4',
          variantId: 'v6',
          name: 'Kara Murukku',
          image: 'assets/images/karam_janthukalu_murukku_strings_snack.jpg',
          price: 129,
          mrp: 140,
          sold: '6.2K+',
          rating: 4.7,
          move: 'up',
          moveBy: 3,
        ),
        BSItem(
          id: 'p5',
          variantId: 'v10',
          name: 'Khara Mixture',
          image: 'assets/images/khara_mixture_assorted_crunchy_savory_mix.jpg',
          price: 149,
          mrp: 165,
          sold: '5.5K+',
          rating: 4.6,
          move: 'down',
          moveBy: 1,
        ),
      ],
    ),
    BSCategory(
      'pickles',
      'Pickles',
      '🥭',
      [
        BSItem(
          id: 'p1',
          variantId: 'v1',
          name: 'Bellam Avakaya',
          image: 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
          price: 120,
          mrp: 136,
          sold: '12K+',
          rating: 4.8,
          move: 'up',
          moveBy: 2,
        ),
        BSItem(
          id: 'p6',
          variantId: 'v11',
          name: 'Allam Pickle',
          image: 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg',
          price: 140,
          mrp: 160,
          sold: '7.1K+',
          rating: 4.7,
          move: 'up',
          moveBy: 1,
        ),
        BSItem(
          id: 'p7',
          variantId: 'v12',
          name: 'Usiri Pickle',
          image: 'assets/images/usiri_pickle_amlagooseberry_pickle.jpg',
          price: 130,
          mrp: 145,
          sold: '5.8K+',
          rating: 4.6,
          move: '',
          moveBy: 0,
        ),
      ],
    ),
    BSCategory(
      'powders',
      'Powders',
      '🌶️',
      [
        BSItem(
          id: 'p2',
          variantId: 'v4',
          name: 'Idli Karam Podi',
          image: 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg',
          price: 139,
          mrp: 150,
          sold: '9.8K+',
          rating: 4.9,
          move: 'up',
          moveBy: 1,
        ),
        BSItem(
          id: 'p8',
          variantId: 'v13',
          name: 'Allam Karam Podi',
          image: 'assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg',
          price: 145,
          mrp: 160,
          sold: '6.4K+',
          rating: 4.8,
          move: 'up',
          moveBy: 2,
        ),
        BSItem(
          id: 'p9',
          variantId: 'v14',
          name: 'Karvepaku Podi',
          image: 'assets/images/karvepaku_karam_podi_curry_leaves_powder.jpg',
          price: 135,
          mrp: 150,
          sold: '4.9K+',
          rating: 4.7,
          move: 'new',
          moveBy: 0,
        ),
      ],
    ),
  ],
);
