import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../product_listing_page.dart';
import '../navigation_util.dart';
import '../app_config_repository.dart';

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

    return Container(
      color: const Color(0xFFFBF6EE),
      padding: EdgeInsets.symmetric(vertical: 20 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16 * s),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TAP · FLIP · DISCOVER',
                        style: GoogleFonts.poppins(
                          fontSize: 9.5 * s,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3 * s,
                          color: const Color(0xFFC0782E),
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          style: GoogleFonts.fraunces(
                            fontSize: 27 * s,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2B1D12),
                            height: 1.1,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Snacks',
                              style: TextStyle(color: Color(0xFF7A1020)),
                            ),
                            TextSpan(text: ' with a Story'),
                          ],
                        ),
                      ),
                      SizedBox(height: 2 * s),
                      Text(
                        'Every snack has a tradition, a story and a home-made touch.',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5 * s,
                          color: const Color(0xFF8A7864),
                        ),
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
                        const ProductListingPage(category: 'Snacks'),
                      );
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 8 * s),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20 * s),
                      border: Border.all(color: const Color(0xFFEFE2D0)),
                    ),
                    child: Text(
                      'View All ›',
                      style: GoogleFonts.poppins(
                        fontSize: 12 * s,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7A1020),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12 * s),

          // Horizontal 3D Flip Cards List
          SizedBox(
            height: 330 * s,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16 * s),
              itemCount: displayItems.length,
              separatorBuilder: (_, __) => SizedBox(width: 14 * s),
              itemBuilder: (_, i) => _FlipCard(
                item: displayItems[i],
                s: s,
                onAdd: widget.onAdd,
                onWishlist: widget.onWishlist,
              ),
            ),
          ),
        ],
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

class _FlipCard extends StatefulWidget {
  final StorySnack item;
  final double s;
  final ValueChanged<StorySnack>? onAdd, onWishlist;

  const _FlipCard({
    required this.item,
    required this.s,
    this.onAdd,
    this.onWishlist,
  });

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: Curves.easeInOutBack);

  void _toggle() {
    HapticFeedback.selectionClick();
    if (_c.isCompleted || _c.velocity > 0) {
      _c.reverse();
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _buildImg(String u, {BoxFit fit = BoxFit.cover}) {
    if (u.isEmpty) {
      return const Center(child: Icon(Icons.restaurant, color: Colors.grey));
    }
    if (u.startsWith('http')) {
      return Image.network(
        u,
        fit: fit,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
      );
    }
    String assetPath = u.startsWith('assets/') ? u : 'assets/images/$u';
    return Image.asset(
      assetPath,
      fit: fit,
      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _a,
        builder: (_, __) {
          final angle = _a.value * math.pi;
          final showBack = angle > math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            child: SizedBox(
              width: 176 * s,
              height: 300 * s,
              child: showBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(math.pi),
                      child: _back(s),
                    )
                  : _front(s),
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _box(Gradient g) => BoxDecoration(
        borderRadius: BorderRadius.circular(20 * widget.s),
        gradient: g,
        boxShadow: const [
          BoxShadow(
            color: Color(0x29462808),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      );

  Widget _addBtn(double s, {required Gradient bg, required Color fg}) => GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          if (widget.onAdd != null) {
            widget.onAdd!(widget.item);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${widget.item.name} added to cart!'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 6 * s),
          decoration: BoxDecoration(
            gradient: bg,
            borderRadius: BorderRadius.circular(12 * s),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 14 * s, color: fg),
              SizedBox(width: 4 * s),
              Text(
                'Add',
                style: GoogleFonts.poppins(
                  fontSize: 12 * s,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _heart(double s, {required bool dark}) => GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          if (widget.onWishlist != null) {
            widget.onWishlist!(widget.item);
          }
        },
        child: Container(
          width: 30 * s,
          height: 30 * s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dark ? Colors.white.withOpacity(.12) : Colors.white,
            border: dark ? Border.all(color: const Color(0xFFF2B866).withOpacity(.6)) : null,
            boxShadow: dark
                ? null
                : const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Icon(
            widget.item.wished ? Icons.favorite : Icons.favorite_border,
            size: 16 * s,
            color: dark ? Colors.white : const Color(0xFF7A1020),
          ),
        ),
      );

  Widget _lotusRule(double s, Color c) => Row(
        children: [
          Expanded(child: Container(height: 1, color: c.withOpacity(.6))),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6 * s),
            child: Icon(Icons.spa_outlined, size: 14 * s, color: c),
          ),
          Expanded(child: Container(height: 1, color: c.withOpacity(.6))),
        ],
      );

  Widget _front(double s) {
    final it = widget.item;
    return Container(
      decoration: _box(const LinearGradient(
        colors: [Color(0xFFFFF7EA), Color(0xFFFFF7EA)],
      )),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20 * s),
        child: Stack(
          children: [
            // Full Photo Cover
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 200 * s,
              child: SizedBox.expand(
                child: _buildImg(it.image, fit: BoxFit.cover),
              ),
            ),

            // Tap for Story Pill Badge
            Positioned(
              left: 8 * s,
              top: 8 * s,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 4 * s),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.92),
                  borderRadius: BorderRadius.circular(14 * s),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 12 * s, color: const Color(0xFF2B1D12)),
                    SizedBox(width: 3 * s),
                    Text(
                      'Tap for story',
                      style: GoogleFonts.poppins(
                        fontSize: 9.5 * s,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2B1D12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(right: 8 * s, top: 8 * s, child: _heart(s, dark: false)),

            // Cream Wave Bottom Panel
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 115 * s,
              child: ClipPath(
                clipper: _WaveTop(),
                child: Container(
                  color: const Color(0xFFFFF7EA),
                  padding: EdgeInsets.fromLTRB(12 * s, 18 * s, 12 * s, 10 * s),
                  child: Column(
                    children: [
                      Icon(Icons.spa_outlined, size: 14 * s, color: const Color(0xFFC9963A)),
                      SizedBox(height: 2 * s),
                      Text(
                        it.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.fraunces(
                          fontSize: 16 * s,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2B1D12),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${it.price}',
                            style: GoogleFonts.poppins(
                              fontSize: 17 * s,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF7A1020),
                            ),
                          ),
                          _addBtn(
                            s,
                            bg: const LinearGradient(
                              colors: [Color(0xFF9A1B2C), Color(0xFF6E0F1B)],
                            ),
                            fg: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _back(double s) {
    final it = widget.item;
    const gold = Color(0xFFF2B866);

    return Container(
      decoration: _box(const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF7A1F1F), Color(0xFF4A0F12)],
      )),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20 * s),
        child: Stack(
          children: [
            if (it.backArt != null)
              Positioned(
                right: -10 * s,
                top: 40 * s,
                bottom: 40 * s,
                width: 110 * s,
                child: Opacity(
                  opacity: .18,
                  child: _buildImg(it.backArt!, fit: BoxFit.cover),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(12 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _toggle,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 4 * s),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.12),
                            borderRadius: BorderRadius.circular(14 * s),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.undo, size: 12 * s, color: const Color(0xFFFDE8CF)),
                              SizedBox(width: 3 * s),
                              Text(
                                'Back',
                                style: GoogleFonts.poppins(
                                  fontSize: 10 * s,
                                  color: const Color(0xFFFDE8CF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      _heart(s, dark: true),
                    ],
                  ),
                  SizedBox(height: 6 * s),
                  Text(
                    'THE STORY',
                    style: GoogleFonts.poppins(
                      fontSize: 8.5 * s,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5 * s,
                      color: gold,
                    ),
                  ),
                  Text(
                    it.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.fraunces(
                      fontSize: 16 * s,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 3 * s),
                  _lotusRule(s, gold),
                  SizedBox(height: 4 * s),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        '"${it.story}"',
                        style: GoogleFonts.caveat(
                          fontSize: 15 * s,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          color: const Color(0xFFFFE9CF),
                        ),
                      ),
                    ),
                  ),
                  if (it.ingredients.isNotEmpty) ...[
                    SizedBox(height: 6 * s),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (final g in it.ingredients.take(3))
                          Column(
                            children: [
                              Container(
                                width: 34 * s,
                                height: 34 * s,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: gold, width: 1.2),
                                ),
                                child: ClipOval(
                                  child: _buildImg(g.image, fit: BoxFit.cover),
                                ),
                              ),
                              SizedBox(height: 2 * s),
                              Text(
                                g.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 8 * s,
                                  color: const Color(0xFFFDE8CF),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                  if (it.since != null) ...[
                    SizedBox(height: 5 * s),
                    _lotusRule(s, gold),
                    Center(
                      child: Text(
                        'MADE THE SAME WAY SINCE',
                        style: GoogleFonts.poppins(
                          fontSize: 7.5 * s,
                          letterSpacing: 1.5 * s,
                          color: const Color(0xFFF2C99A),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        '→ ${it.since} ←',
                        style: GoogleFonts.fraunces(
                          fontSize: 14 * s,
                          fontWeight: FontWeight.w700,
                          color: gold,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 6 * s),
                  Container(
                    padding: EdgeInsets.fromLTRB(10 * s, 6 * s, 6 * s, 6 * s),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.18),
                      borderRadius: BorderRadius.circular(14 * s),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${it.price}',
                          style: GoogleFonts.poppins(
                            fontSize: 15 * s,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        _addBtn(
                          s,
                          bg: const LinearGradient(
                            colors: [Color(0xFFFFE39A), Color(0xFFF2B866)],
                          ),
                          fg: const Color(0xFF3A1408),
                        ),
                      ],
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
