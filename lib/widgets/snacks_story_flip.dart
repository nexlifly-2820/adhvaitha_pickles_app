import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'love_button.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../product_listing_page.dart';
import '../navigation_util.dart';
import '../app_config_repository.dart';
import '../image_util.dart';
import '../product_lookup.dart';

class Ingredient {
  final String name, image;
  const Ingredient(this.name, this.image);
}

class StorySnack {
  final String id, name, story;
  final String image;
  final String? backArt;
  final int price;
  final List<Ingredient> ingredients;
  final String? since;
  final bool wished;

  const StorySnack({
    required this.id,
    required this.name,
    required this.image,
    required this.story,
    required this.price,
    this.ingredients = const [],
    this.since,
    this.backArt,
    this.wished = false,
  });

  factory StorySnack.fromJson(Map<String, dynamic> j) => StorySnack(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        image: j['image'] ?? '',
        story: j['story'] ?? '',
        price: (j['price'] ?? 0).round(),
        since: j['since'],
        backArt: j['backArt'],
        wished: j['wished'] ?? false,
        ingredients: ((j['ingredients'] ?? []) as List)
            .map((e) => Ingredient(e['name'] ?? '', e['image'] ?? ''))
            .toList(),
      );
}

class SnacksStoryFlip extends StatefulWidget {
  final List<StorySnack> items;
  final ValueChanged<StorySnack>? onAdd;
  final ValueChanged<StorySnack>? onWishlist;
  final VoidCallback? onViewAll;

  const SnacksStoryFlip({
    super.key,
    required this.items,
    this.onAdd,
    this.onWishlist,
    this.onViewAll,
  });

  @override
  State<SnacksStoryFlip> createState() => _SnacksStoryFlipState();
}

class _SnacksStoryFlipState extends State<SnacksStoryFlip> {
  StreamSubscription? _sub;
  List<StorySnack> _liveItems = [];

  @override
  void initState() {
    super.initState();
    _listenToStorySnacks();
  }

  void _listenToStorySnacks() {
    _sub = AppConfigRepository().getStorySnacksStream().listen((data) {
      if (!mounted) return;
      if (data.isNotEmpty) {
        final parsed = data.map((e) => StorySnack.fromJson(e)).toList();
        if (parsed.isNotEmpty) {
          setState(() => _liveItems = parsed);
        }
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<StorySnack> get _effectiveItems {
    if (_liveItems.isNotEmpty) {
      return _liveItems;
    }
    if (widget.items.isNotEmpty) {
      return widget.items;
    }
    return defaultSnacks;
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size.width / 390;
    final displayItems = _effectiveItems;

    return CustomPaint(
      painter: _KraftPainter(),
      child: Padding(
        padding: EdgeInsets.only(top: 6 * s, bottom: 22 * s),
        child: Column(children: <Widget>[
          Text('Served hot in a newspaper potlam — tap to read its story',
              textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 10.5 * s, color: const Color(0xFF7A5A3A))),
          SizedBox(height: 18 * s),
          SizedBox(
            height: 458 * s,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20 * s),
              itemCount: displayItems.length,
              separatorBuilder: (_, __) => SizedBox(width: 16 * s),
              itemBuilder: (_, int i) => _PotlamCard(item: displayItems[i], s: s, index: i, onAdd: widget.onAdd),
            ),
          ),
          SizedBox(height: 4 * s),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (widget.onViewAll != null) {
                widget.onViewAll!();
              } else {
                AppNavigator.push(context, const ProductListingPage(category: 'Snacks'));
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 18 * s, vertical: 9 * s),
              decoration: BoxDecoration(color: _kMaroon, borderRadius: BorderRadius.circular(20 * s)),
              child: Text('View all snacks ›', style: GoogleFonts.poppins(fontSize: 12 * s, fontWeight: FontWeight.w700, color: const Color(0xFFFFE7B8))),
            ),
          ),
        ]),
      ),
    );
  }

  static const List<StorySnack> defaultSnacks = [
    StorySnack(
      id: 'murukku',
      name: 'Kara Murukku',
      image: 'assets/images/karam_janthukalu_murukku_strings_snack.jpg',
      price: 129,
      story: 'A crispy spiral snack made from rice flour and urad dal, prepared in our family kitchen for festive evenings.',
      since: '1985',
      ingredients: [
        Ingredient('Rice Flour', 'assets/images/rice_papad_crispy_rice_flour_papadums.jpg'),
        Ingredient('Urad Dal', 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg'),
        Ingredient('Spices', 'assets/images/special_kura_karam_podi_all-purpose_curry_powder.jpg'),
      ],
    ),
    StorySnack(
      id: 'mixture',
      name: 'Khara Mixture',
      image: 'assets/images/khara_mixture_assorted_crunchy_savory_mix.jpg',
      price: 149,
      story: 'A delicious assortment of spiced boondi, peanuts, and sev tossed with roasted curry leaves in pure oil.',
      since: '1992',
      ingredients: [
        Ingredient('Gram Flour', 'assets/images/bundhi_crispy_spiced_gram_flour_droplets.jpg'),
        Ingredient('Peanuts', 'assets/images/palli_patti_peanut_and_jaggery_chikki.jpg'),
        Ingredient('Curry Leaves', 'assets/images/karvepaku_karam_podi_curry_leaves_powder.jpg'),
      ],
    ),
    StorySnack(
      id: 'sunnunda',
      name: 'Sunnunda Laddu',
      image: 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg',
      price: 199,
      story: 'Traditional roasted urad dal laddus sweetened with organic bellam (jaggery) and rich cow ghee.',
      since: '1978',
      ingredients: [
        Ingredient('Urad Dal', 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg'),
        Ingredient('Pure Ghee', 'assets/images/good_food_text.png'),
        Ingredient('Bellam', 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg'),
      ],
    ),
    StorySnack(
      id: 'chips',
      name: 'Banana Chips',
      image: 'assets/images/allu_chips_thinly_sliced_indian_potato_chips.jpg',
      price: 119,
      story: 'Thinly sliced raw bananas fried in cold-pressed coconut oil and sprinkled with sea salt & black pepper.',
      since: '1998',
      ingredients: [
        Ingredient('Raw Banana', 'assets/images/allu_chips_thinly_sliced_indian_potato_chips.jpg'),
        Ingredient('Coconut Oil', 'assets/images/good_food_text.png'),
        Ingredient('Sea Salt', 'assets/images/uppava_traditional_salted_pickle.jpg'),
      ],
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Newspaper "potlam" card: the snack heaped in a rolled newspaper cone.
// Tap the cone → it flips into a little newspaper story page. Weight chips + Add below.
// ─────────────────────────────────────────────────────────────────────────────
class _Wt {
  final String label;
  final double price;
  const _Wt(this.label, this.price);
}

const Color _kMaroon = Color(0xFF7A1426);
const Color _kInk = Color(0xFF2A2018);
const Color _kPaper = Color(0xFFEFE6D3);

class _PotlamCard extends StatefulWidget {
  final StorySnack item;
  final double s;
  final int index;
  final ValueChanged<StorySnack>? onAdd;
  const _PotlamCard({required this.item, required this.s, required this.index, this.onAdd});

  @override
  State<_PotlamCard> createState() => _PotlamCardState();
}

class _PotlamCardState extends State<_PotlamCard> with TickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  late final AnimationController _sway = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400))
    ..value = (widget.index * .47) % 1
    ..repeat(reverse: true);
  late final List<_Wt> _weights = _weightsFor(widget.item);
  int _sel = 0;
  bool _added = false;

  @override
  void dispose() {
    _flip.dispose();
    _sway.dispose();
    super.dispose();
  }

  /// real weights from the product list when available, otherwise sensible packs from the base price
  static List<_Wt> _weightsFor(StorySnack it) {
    final Map<String, double> m = findCatalogProduct(it.name)?.weightPriceMap ?? const <String, double>{};
    if (m.length >= 2) {
      return m.entries.take(3).map((MapEntry<String, double> e) => _Wt(e.key, e.value)).toList();
    }
    final double p = it.price > 0 ? it.price.toDouble() : 129;
    return <_Wt>[_Wt('250g', p), _Wt('500g', (p * 1.9).roundToDouble()), _Wt('1kg', (p * 3.6).roundToDouble())];
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    _flip.isCompleted || _flip.value > .5 ? _flip.reverse() : _flip.forward();
  }

  void _add() {
    HapticFeedback.mediumImpact();
    final _Wt w = _weights[_sel];
    if (widget.onAdd != null) {
      widget.onAdd!(widget.item);
    } else {
      addToCartByName(widget.item.name, image: widget.item.image, weight: w.label, price: w.price, category: 'Snacks');
    }
    setState(() => _added = true);
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _added = false);
    });
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF2A1410),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text('${widget.item.name} (${w.label}) added to cart',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
      ));
  }

  String _rs(double v) => '₹${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final double s = widget.s;
    return SizedBox(
      width: 166 * s,
      child: Column(children: <Widget>[
        SizedBox(
          height: 338 * s,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggle,
            child: AnimatedBuilder(
              animation: _flip,
              builder: (BuildContext c, _) {
                final double t = Curves.easeInOutCubic.transform(_flip.value);
                final double angle = t * math.pi;
                final bool back = angle > math.pi / 2;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateY(angle),
                  child: back
                      ? Transform(alignment: Alignment.center, transform: Matrix4.identity()..rotateY(math.pi), child: _back(s))
                      : _front(s),
                );
              },
            ),
          ),
        ),
        SizedBox(height: 8 * s),
        _foot(s),
      ]),
    );
  }

  // ---------- front: cone ----------
  Widget _front(double s) {
    final StorySnack it = widget.item;
    return Stack(clipBehavior: Clip.none, children: <Widget>[
      AnimatedBuilder(
        animation: _sway,
        builder: (_, Widget? child) => Transform.rotate(
          angle: (Curves.easeInOut.transform(_sway.value) - .5) * .052,
          alignment: Alignment.bottomCenter,
          child: child,
        ),
        child: SizedBox(
          width: 166 * s,
          height: 312 * s,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: <Widget>[
            // soft shadow under the tip
            Positioned(
              top: 302 * s,
              child: Container(
                width: 60 * s,
                height: 10 * s,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: <BoxShadow>[BoxShadow(color: const Color(0x55603000), blurRadius: 8 * s)],
                ),
              ),
            ),
            // snack heaped on top
            Positioned(
              top: 6 * s,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.elliptical(74 * s, 62 * s),
                  bottom: Radius.elliptical(74 * s, 26 * s),
                ),
                child: SizedBox(
                  width: 148 * s,
                  height: 106 * s,
                  child: Stack(fit: StackFit.expand, children: <Widget>[
                    Transform.scale(scale: 1.65, child: _img(it.image)),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Color(0x00000000), Color(0x00000000), Color(0x66301500)], stops: <double>[0, .6, 1]),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            // newspaper cone
            Positioned(
              top: 80 * s,
              child: CustomPaint(
                size: Size(162 * s, 228 * s),
                painter: _NewspaperConePainter(seed: it.name.hashCode, s: s),
              ),
            ),
            // name tag
            Positioned(
              top: 162 * s,
              child: Transform.rotate(
                angle: -.07,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 5 * s),
                  decoration: BoxDecoration(
                    color: _kMaroon,
                    borderRadius: BorderRadius.circular(4 * s),
                    boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withOpacity(.3), blurRadius: 8 * s, offset: Offset(0, 4 * s))],
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 136 * s),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(it.name, style: GoogleFonts.playfairDisplay(fontSize: 15 * s, fontWeight: FontWeight.w700, color: const Color(0xFFFFE7B8))),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
      // heart
      Positioned(
        right: 2 * s,
        top: 4 * s,
        child: Container(
          decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withOpacity(.18), blurRadius: 8 * s, offset: Offset(0, 3 * s))]),
          child: LoveButton(
            name: it.name,
            image: it.image,
            price: _weights[_sel].price,
            category: 'Snacks',
            size: 15 * s,
            box: 30 * s,
            circleColor: Colors.white,
          ),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Text('↻ tap to unfold the story',
            textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 9.5 * s, fontWeight: FontWeight.w600, color: const Color(0xFF7A5A3A))),
      ),
    ]);
  }

  // ---------- back: newspaper story ----------
  Widget _back(double s) {
    final StorySnack it = widget.item;
    final String place = <String>['VIJAYAWADA', 'GUNTUR', 'RAJAHMUNDRY', 'NELLORE'][widget.index % 4];
    return Container(
      width: 166 * s,
      height: 338 * s,
      padding: EdgeInsets.fromLTRB(11 * s, 12 * s, 11 * s, 10 * s),
      decoration: BoxDecoration(
        color: _kPaper,
        borderRadius: BorderRadius.circular(6 * s),
        boxShadow: <BoxShadow>[BoxShadow(color: const Color(0x73603000), blurRadius: 18 * s, offset: Offset(0, 10 * s), spreadRadius: -8 * s)],
        gradient: const RadialGradient(center: Alignment(.7, -.7), radius: 1.2, colors: <Color>[Color(0xFFF2E3C4), _kPaper]),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
        Container(
          padding: EdgeInsets.only(bottom: 3 * s),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _kInk, width: 2))),
          child: Text('THE AMMA TIMES', textAlign: TextAlign.center, style: GoogleFonts.playfairDisplay(fontSize: 11 * s, fontWeight: FontWeight.w900, letterSpacing: 1, color: _kInk)),
        ),
        Container(
          padding: EdgeInsets.symmetric(vertical: 2 * s),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _kInk, width: .8))),
          child: Text('$place · SINCE ${it.since ?? '1982'} · ${_rs(_weights[_sel].price)}',
              textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 7.5 * s, color: const Color(0xFF7A6A55))),
        ),
        SizedBox(height: 7 * s),
        Text(it.name, maxLines: 2, style: GoogleFonts.playfairDisplay(fontSize: 17 * s, height: 1.1, fontWeight: FontWeight.w700, color: _kInk)),
        SizedBox(height: 6 * s),
        ClipRect(
          child: SizedBox(
            height: 70 * s,
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                .393, .769, .189, 0, 0, //
                .349, .686, .168, 0, 0, //
                .272, .534, .131, 0, 0, //
                0, 0, 0, 1, 0,
              ]),
              child: _img(it.image),
            ),
          ),
        ),
        SizedBox(height: 6 * s),
        Expanded(
          child: Text(
            it.story.isNotEmpty ? it.story : 'Made by hand in small batches, the way Amma learnt it from her mother.',
            overflow: TextOverflow.fade,
            style: GoogleFonts.poppins(fontSize: 9.5 * s, height: 1.45, color: const Color(0xFF3A2E22)),
          ),
        ),
        Text('“Best with evening chai.”', style: GoogleFonts.kalam(fontSize: 12 * s, fontWeight: FontWeight.w700, color: const Color(0xFFB0202F))),
      ]),
    );
  }

  // ---------- weights + price + add ----------
  Widget _foot(double s) {
    return Container(
      padding: EdgeInsets.fromLTRB(9 * s, 9 * s, 9 * s, 10 * s),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(16 * s),
        boxShadow: <BoxShadow>[BoxShadow(color: const Color(0x66603000), blurRadius: 12 * s, offset: Offset(0, 6 * s), spreadRadius: -6 * s)],
      ),
      child: Column(children: <Widget>[
        Row(children: <Widget>[
          for (int i = 0; i < _weights.length; i++) ...<Widget>[
            if (i > 0) SizedBox(width: 4 * s),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _sel = i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: EdgeInsets.symmetric(vertical: 5 * s),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: i == _sel ? _kMaroon : const Color(0xFFF7E6DA), borderRadius: BorderRadius.circular(9 * s)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(_weights[i].label,
                        style: GoogleFonts.poppins(fontSize: 10 * s, fontWeight: FontWeight.w700, color: i == _sel ? Colors.white : _kMaroon)),
                  ),
                ),
              ),
            ),
          ],
        ]),
        SizedBox(height: 8 * s),
        Row(children: <Widget>[
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (Widget c, Animation<double> a) => ScaleTransition(scale: Tween<double>(begin: 1.25, end: 1).animate(a), child: FadeTransition(opacity: a, child: c)),
              child: Text(_rs(_weights[_sel].price),
                  key: ValueKey<int>(_sel), style: GoogleFonts.poppins(fontSize: 15 * s, fontWeight: FontWeight.w700, color: const Color(0xFF3B1F0E))),
            ),
          ),
          GestureDetector(
            onTap: _add,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 7 * s),
              decoration: BoxDecoration(color: _added ? const Color(0xFF2F8A4E) : _kMaroon, borderRadius: BorderRadius.circular(12 * s)),
              child: Text(_added ? '✓ Added' : '🛒 Add', style: GoogleFonts.poppins(fontSize: 11 * s, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _img(String u) {
    final String p = u.trim();
    return buildSmartImage(bestImageFor(widget.item.name, p), fit: BoxFit.cover);
  }
}

/// Draws a rolled newspaper cone: torn top, printed columns, round shading, seam, crease, oil spots.
class _NewspaperConePainter extends CustomPainter {
  final int seed;
  final double s;
  _NewspaperConePainter({required this.seed, required this.s});

  @override
  void paint(Canvas c, Size z) {
    final double w = z.width, h = z.height;
    final math.Random r = math.Random(seed);
    final Path cone = Path()
      ..moveTo(0, h * .03)
      ..lineTo(w * .08, 0)
      ..lineTo(w * .22, h * .04)
      ..lineTo(w * .38, h * .01)
      ..lineTo(w * .55, h * .04)
      ..lineTo(w * .72, 0)
      ..lineTo(w * .90, h * .03)
      ..lineTo(w, h * .01)
      ..lineTo(w * .57, h)
      ..lineTo(w * .43, h)
      ..close();

    c.drawShadow(cone, const Color(0xFF603000), 10 * s, false);
    c.save();
    c.clipPath(cone);
    c.drawRect(Offset.zero & z, Paint()..color = _kPaper);

    // masthead
    final TextPainter mast = TextPainter(
      text: TextSpan(text: 'The Amma Times', style: GoogleFonts.playfairDisplay(fontSize: 13.5 * s, fontWeight: FontWeight.w700, color: _kInk.withOpacity(.85))),
      textDirection: TextDirection.ltr,
    )..layout();
    mast.paint(c, Offset((w - mast.width) / 2, 19 * s));
    final Paint rule = Paint()
      ..color = _kInk.withOpacity(.5)
      ..strokeWidth = 1;
    c.drawLine(Offset(14 * s, 38 * s), Offset(w - 14 * s, 38 * s), rule);

    // three columns of tiny print
    final Paint print = Paint()..color = _kInk.withOpacity(.38);
    final double colW = (w - 20 * s - 12 * s) / 3;
    for (int col = 0; col < 3; col++) {
      final double x0 = 10 * s + col * (colW + 6 * s);
      for (double y = 44 * s; y < h; y += 7 * s) {
        final double len = colW * (.55 + r.nextDouble() * .45);
        c.drawRect(Rect.fromLTWH(x0, y, len, 2.2 * s), print);
      }
      if (col > 0) c.drawLine(Offset(x0 - 3 * s, 42 * s), Offset(x0 - 3 * s, h), Paint()..color = _kInk.withOpacity(.2)..strokeWidth = .6);
    }
    // faded photo block
    c.drawRect(Rect.fromLTWH(w * .19, 66 * s, w * .34, 34 * s), Paint()..color = const Color(0xFF6E6252).withOpacity(.6));

    // round shading (dark edges, light middle)
    c.drawRect(
      Offset.zero & z,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0x61603C14), Color(0x2EFFFFFF), Color(0x0DFFFFFF), Color(0x1A603C14), Color(0x73402810)],
          stops: <double>[0, .3, .45, .62, 1],
        ).createShader(Offset.zero & z),
    );
    // overlap seam where the paper is rolled
    c.save();
    c.translate(w * .58, 0);
    c.skew(-.3, 0);
    c.drawRect(
      Rect.fromLTWH(0, 0, 30 * s, h),
      Paint()..shader = const LinearGradient(colors: <Color>[Color(0x2E000000), Color(0x40FFFFFF), Color(0x00FFFFFF)], stops: <double>[0, .4, 1]).createShader(Rect.fromLTWH(0, 0, 30 * s, h)),
    );
    c.restore();
    // crease
    c.save();
    c.translate(w / 2, h * .44);
    c.rotate(-.14);
    c.drawLine(Offset(-w * .4, 0), Offset(w * .4, 0), Paint()..color = Colors.black.withOpacity(.14)..strokeWidth = 1);
    c.drawLine(Offset(-w * .4, 1.2), Offset(w * .4, 1.2), Paint()..color = Colors.white.withOpacity(.35)..strokeWidth = 1);
    c.restore();
    // oil spots soaking through
    for (int i = 0; i < 2; i++) {
      final Offset o = Offset(w * (.3 + r.nextDouble() * .4), h * (.42 + r.nextDouble() * .3));
      final double rad = (i == 0 ? 17 : 9) * s;
      c.drawCircle(o, rad, Paint()..shader = RadialGradient(colors: <Color>[const Color(0x52C88C28), const Color(0x1FC88C28), const Color(0x00C88C28)], stops: const <double>[0, .6, 1]).createShader(Rect.fromCircle(center: o, radius: rad)));
    }
    // folded top rim
    c.drawRect(
      Rect.fromLTWH(0, 0, w, 15 * s),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Color(0xFFD8CBB0), Color(0x00EFE6D3)]).createShader(Rect.fromLTWH(0, 0, w, 15 * s)),
    );
    c.restore();

    // crumbs by the tip
    final Paint crumb = Paint()..color = const Color(0xFFB0701E);
    c.drawOval(Rect.fromCenter(center: Offset(w * .36, h + 4 * s), width: 6 * s, height: 4 * s), crumb);
    c.drawOval(Rect.fromCenter(center: Offset(w * .6, h + 7 * s), width: 5 * s, height: 3.5 * s), crumb);
  }

  @override
  bool shouldRepaint(covariant _NewspaperConePainter o) => o.seed != seed || o.s != s;
}

/// kraft-paper background with a fine cross-hatch
class _KraftPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size z) {
    c.drawRect(Offset.zero & z, Paint()..color = const Color(0xFFE9D3AE));
    final Paint p = Paint()
      ..color = const Color(0x0F78501E)
      ..strokeWidth = 2;
    for (double d = -z.height; d < z.width; d += 7) {
      c.drawLine(Offset(d, 0), Offset(d + z.height, z.height), p);
      c.drawLine(Offset(d + z.height, 0), Offset(d, z.height), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _WaveTop extends CustomClipper<Path> {
  @override
  Path getClip(Size z) => Path()
    ..moveTo(0, z.height * .22)
    ..cubicTo(z.width * .3, -z.height * .05, z.width * .55, z.height * .3, z.width, z.height * .06)
    ..lineTo(z.width, z.height)
    ..lineTo(0, z.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}
