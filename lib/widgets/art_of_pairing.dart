// art_of_pairing.dart
// "The Art of Pairing" - swipe the big combo card; the pairing cards below change to match it.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../product_listing_page.dart';
import '../navigation_util.dart';
import '../combo_detail_page.dart';
import '../app_config_repository.dart';

Color _hex(String h) {
  try {
    final clean = h.replaceFirst('#', '');
    return Color(int.parse(clean.length == 6 ? 'FF$clean' : clean, radix: 16));
  } catch (_) {
    return const Color(0xFF7A0F12);
  }
}

class PairItem {
  final String id, tag, imageA, imageB, name, bestWith;
  final int price;
  PairItem({
    required this.id,
    required this.tag,
    required this.imageA,
    required this.imageB,
    required this.name,
    required this.bestWith,
    required this.price,
  });

  PairItem.fromJson(Map<String, dynamic> j)
      : id = j['id']?.toString() ?? '',
        tag = j['tag']?.toString() ?? '',
        imageA = j['imageA']?.toString() ?? j['imgA']?.toString() ?? '',
        imageB = j['imageB']?.toString() ?? j['imgB']?.toString() ?? '',
        name = j['name']?.toString() ?? j['title']?.toString() ?? '',
        bestWith = j['bestWith']?.toString() ?? j['sub']?.toString() ?? '',
        price = (j['price'] is num) ? (j['price'] as num).round() : 299;
}

class HeroCombo {
  final String id, kicker, title, desc, imageA, imageB;
  final int price;
  final List<Color> colors;
  final List<PairItem> pairs;

  HeroCombo({
    required this.id,
    required this.kicker,
    required this.title,
    required this.desc,
    required this.imageA,
    required this.imageB,
    required this.price,
    required this.colors,
    required this.pairs,
  });

  HeroCombo.fromJson(Map<String, dynamic> j)
      : id = j['id']?.toString() ?? '',
        kicker = j['kicker']?.toString() ?? 'THE ROYAL COMBO',
        title = j['title']?.toString() ?? j['name']?.toString() ?? '',
        desc = j['desc']?.toString() ?? j['subtitle']?.toString() ?? '',
        imageA = j['imageA']?.toString() ?? j['imgA']?.toString() ?? '',
        imageB = j['imageB']?.toString() ?? j['imgB']?.toString() ?? '',
        price = (j['price'] is num) ? (j['price'] as num).round() : 379,
        colors = (j['colors'] is List)
            ? (j['colors'] as List).map((e) => _hex(e.toString())).toList()
            : [const Color(0xFF5C0A0D), const Color(0xFF7A0F12), const Color(0xFF9B1D22)],
        pairs = ((j['pairs'] ?? j['subs'] ?? j['subPairings'] ?? []) as List)
            .map((e) => PairItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
}

class ArtOfPairing extends StatefulWidget {
  final List<HeroCombo> combos;
  final ValueChanged<HeroCombo>? onAddHero;
  final ValueChanged<PairItem>? onAddPair;
  final ValueChanged<PairItem>? onTapPair;
  final ValueChanged<PairItem>? onWishlist;
  final VoidCallback? onViewAll;

  const ArtOfPairing({
    super.key,
    required this.combos,
    this.onAddHero,
    this.onAddPair,
    this.onTapPair,
    this.onWishlist,
    this.onViewAll,
  });

  @override
  State<ArtOfPairing> createState() => _ArtOfPairingState();
}

class _ArtOfPairingState extends State<ArtOfPairing> {
  static const cream = Color(0xFFFFF8EC);
  late final PageController _pc = PageController(viewportFraction: 362 / 390);
  int _i = 0;
  StreamSubscription? _pairingsSub;
  List<HeroCombo> _liveCombos = [];

  @override
  void initState() {
    super.initState();
    _listenToPairingsConfig();
  }

  void _listenToPairingsConfig() {
    _pairingsSub = AppConfigRepository().getPairingsStream().listen((data) {
      if (!mounted) return;
      if (data.isNotEmpty) {
        final parsed = data.map((e) => HeroCombo.fromJson(e)).where((c) => c.pairs.isNotEmpty).toList();
        if (parsed.isNotEmpty) {
          setState(() => _liveCombos = parsed);
        }
      }
    });
  }

  @override
  void dispose() {
    _pairingsSub?.cancel();
    _pc.dispose();
    super.dispose();
  }

  List<HeroCombo> get _effectiveCombos {
    if (_liveCombos.length >= 3) {
      return _liveCombos;
    }
    final valid = widget.combos.where((c) => c.pairs.isNotEmpty).toList();
    if (valid.length >= 3) {
      return valid;
    }
    return _defaultCombos;
  }

  Widget _img(String u, {double? w}) {
    if (u.isEmpty) {
      return SizedBox(width: w, child: const Icon(Icons.restaurant, color: Colors.grey));
    }
    if (u.startsWith('http')) {
      return Image.network(
        u,
        width: w,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
      );
    }
    String assetPath = u.startsWith('assets/') ? u : 'assets/images/$u';
    return Image.asset(
      assetPath,
      width: w,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size.width / 390;
    final combos = _effectiveCombos;
    if (combos.isEmpty) return const SizedBox.shrink();

    if (_i >= combos.length) _i = 0;
    final cur = combos[_i];

    return Container(
      color: cream,
      padding: EdgeInsets.symmetric(vertical: 18 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------- HEADER ----------
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14 * s),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CURATED COMBOS',
                        style: GoogleFonts.poppins(
                          fontSize: 10 * s,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.5 * s,
                          color: const Color(0xFFB8860B),
                        ),
                      ),
                      Text(
                        'The Art of Pairing',
                        style: GoogleFonts.fraunces(
                          fontSize: 24 * s,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2A1A12),
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: 2 * s),
                      Text(
                        "Pick your meal, we'll pick the perfect match",
                        style: GoogleFonts.poppins(
                          fontSize: 12 * s,
                          color: const Color(0xFF7A6A5E),
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
                      AppNavigator.push(context, const ProductListingPage(category: 'Combos'));
                    }
                  },
                  child: Text(
                    'View all ›',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5 * s,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7A0F12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14 * s),

          // ---------- HERO CAROUSEL ----------
          SizedBox(
            height: 148 * s,
            child: PageView.builder(
              controller: _pc,
              padEnds: false,
              itemCount: combos.length,
              onPageChanged: (i) => setState(() => _i = i),
              itemBuilder: (_, i) => Padding(
                padding: EdgeInsets.only(
                  left: 14 * s,
                  right: (i == combos.length - 1 ? 14 : 0) * s,
                ),
                child: _hero(combos[i], s),
              ),
            ),
          ),
          SizedBox(height: 8 * s),

          // ---------- PAGINATION DOTS ----------
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(combos.length, (k) {
              final on = k == _i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: 2.5 * s),
                width: (on ? 18 : 6) * s,
                height: 6 * s,
                decoration: BoxDecoration(
                  color: on ? const Color(0xFF7A0F12) : const Color(0xFFD9C9B0),
                  borderRadius: BorderRadius.circular(3 * s),
                ),
              );
            }),
          ),

          // ---------- "Pairs for ..." ----------
          Padding(
            padding: EdgeInsets.fromLTRB(14 * s, 12 * s, 14 * s, 0),
            child: Text.rich(
              TextSpan(
                style: GoogleFonts.poppins(fontSize: 12.5 * s, color: const Color(0xFF7A6A5E)),
                children: [
                  const TextSpan(text: 'Pairs for '),
                  TextSpan(
                    text: cur.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2A1A12)),
                  ),
                ],
              ),
            ),
          ),

          // ---------- PAIRING CARDS (ANIMATED SWITCHER) ----------
          SizedBox(
            height: 278 * s,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOutBack,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(begin: const Offset(.12, 0), end: Offset.zero).animate(a),
                  child: child,
                ),
              ),
              child: ListView.separated(
                key: ValueKey(cur.id),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(14 * s, 12 * s, 14 * s, 4 * s),
                itemCount: cur.pairs.length,
                separatorBuilder: (_, __) => SizedBox(width: 10 * s),
                itemBuilder: (_, k) => _pairCard(cur.pairs[k], s),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- HERO CARD ----------------
  Widget _hero(HeroCombo h, double s) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16 * s),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(-1, -.4),
            end: const Alignment(1, .4),
            colors: h.colors,
            stops: const [0, .6, 1],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40 * s,
              top: -40 * s,
              child: Container(
                width: 180 * s,
                height: 180 * s,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x24FFD778)),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 12 * s, 14 * s),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          h.kicker,
                          style: GoogleFonts.poppins(
                            fontSize: 9.5 * s,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6 * s,
                            color: const Color(0xFFF6C453),
                          ),
                        ),
                        SizedBox(height: 3 * s),
                        Text(
                          h.title,
                          maxLines: 2,
                          style: GoogleFonts.fraunces(
                            fontSize: 21 * s,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                        SizedBox(height: 4 * s),
                        Text(
                          '${h.desc} · 2 items',
                          style: GoogleFonts.poppins(fontSize: 11 * s, color: const Color(0xFFFFE2C8)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 9 * s),
                        Row(
                          children: [
                            Text(
                              '₹${h.price}',
                              style: GoogleFonts.poppins(
                                fontSize: 17 * s,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8 * s),
                            _addBtn(
                              s,
                              filled: true,
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                if (widget.onAddHero != null) {
                                  widget.onAddHero!(h);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${h.title} added to cart!'),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 150 * s,
                    height: 110 * s,
                    child: Stack(
                      children: [
                        Positioned(left: 0, top: 6 * s, child: _img(h.imageA, w: 100 * s)),
                        Positioned(right: 0, bottom: 0, child: _img(h.imageB, w: 86 * s)),
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

  // ---------------- PAIRING CARD ----------------
  Widget _pairCard(PairItem p, double s) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (widget.onTapPair != null) {
          widget.onTapPair!(p);
        } else {
          AppNavigator.push(context, ComboDetailPage(pairItem: p));
        }
      },
      child: Container(
        width: 160 * s,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14 * s),
          border: Border.all(color: const Color(0xFFEFE4D2)),
          boxShadow: const [BoxShadow(color: Color(0x0F502800), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Visual Header with Dual Cutouts & Plus
              Container(
                height: 112 * s,
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, .2),
                    radius: .85,
                    colors: [Color(0xFFFFF3D9), Color(0xFFFBE6C0)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(left: 4 * s, bottom: 8 * s, child: _img(p.imageA, w: 84 * s)),
                    Positioned(right: 4 * s, bottom: 8 * s, child: _img(p.imageB, w: 84 * s)),
                    Align(
                      alignment: const Alignment(0, .1),
                      child: Container(
                        width: 24 * s,
                        height: 24 * s,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [BoxShadow(color: Color(0x2E000000), blurRadius: 5, offset: Offset(0, 2))],
                        ),
                        child: Text(
                          '+',
                          style: GoogleFonts.poppins(
                            fontSize: 16 * s,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF7A0F12),
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    if (p.tag.isNotEmpty)
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 3 * s),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F8A3A),
                            borderRadius: BorderRadius.only(bottomRight: Radius.circular(10 * s)),
                          ),
                          child: Text(
                            p.tag,
                            style: GoogleFonts.poppins(
                              fontSize: 9 * s,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 6 * s,
                      top: 4 * s,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (widget.onWishlist != null) {
                            widget.onWishlist!(p);
                          }
                        },
                        child: Icon(Icons.favorite_border, size: 17 * s, color: const Color(0xFFB9A48A)),
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: EdgeInsets.fromLTRB(10 * s, 8 * s, 10 * s, 10 * s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7 * s, vertical: 1 * s),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBEAEA),
                        borderRadius: BorderRadius.circular(6 * s),
                      ),
                      child: Text(
                        '2 items',
                        style: GoogleFonts.poppins(
                          fontSize: 9.5 * s,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7A0F12),
                        ),
                      ),
                    ),
                    SizedBox(height: 4 * s),
                    SizedBox(
                      height: 33 * s,
                      child: Text(
                        p.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13 * s,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF222222),
                          height: 1.25,
                        ),
                      ),
                    ),
                    SizedBox(height: 2 * s),
                    Text.rich(
                      TextSpan(
                        style: GoogleFonts.poppins(fontSize: 10.5 * s, color: const Color(0xFF7A6A5E)),
                        children: [
                          const TextSpan(text: 'Best with '),
                          TextSpan(
                            text: p.bestWith,
                            style: const TextStyle(color: Color(0xFFB8860B), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 7 * s),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${p.price}',
                          style: GoogleFonts.poppins(
                            fontSize: 15 * s,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1B1B1B),
                          ),
                        ),
                        _addBtn(
                          s,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            if (widget.onAddPair != null) {
                              widget.onAddPair!(p);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${p.name} added to cart!'),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addBtn(double s, {bool filled = false, VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: (filled ? 16 : 14) * s, vertical: 4 * s),
          decoration: BoxDecoration(
            color: filled ? Colors.white : const Color(0xFFF2FBF4),
            borderRadius: BorderRadius.circular(8 * s),
            border: filled ? null : Border.all(color: const Color(0xFF1F8A3A), width: 1.5),
          ),
          child: Text(
            'ADD',
            style: GoogleFonts.poppins(
              fontSize: 12 * s,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F8A3A),
            ),
          ),
        ),
      );
}

// DEFAULT SAMPLE COMBOS FOR 3 UNIQUE MOMENTS
final List<HeroCombo> _defaultCombos = [
  // 1. 🔴 BREAKFAST: Dosa's Best Friends (Karam Podi + Avakaya)
  HeroCombo.fromJson({
    'id': 'breakfast',
    'kicker': 'BREAKFAST',
    'title': "Dosa's Best Friends",
    'desc': 'Karam Podi + Avakaya',
    'price': 379,
    'imageA': 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg',
    'imageB': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
    'colors': ['#5C0A0D', '#7A0F12', '#9B1D22'],
    'pairs': [
      {
        'id': 'br1',
        'tag': '',
        'imageA': 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg',
        'imageB': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
        'name': 'Karam Podi + Avakaya',
        'bestWith': 'Dosa · Idli',
        'price': 379,
      },
      {
        'id': 'br2',
        'tag': '',
        'imageA': 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg',
        'imageB': 'assets/images/palli_patti_peanut_and_jaggery_chikki.jpg',
        'name': 'Karam Podi + Masala Peanuts',
        'bestWith': 'Dosa · Idli',
        'price': 299,
      },
      {
        'id': 'br3',
        'tag': '',
        'imageA': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
        'imageB': 'assets/images/palli_patti_peanut_and_jaggery_chikki.jpg',
        'name': 'Avakaya + Masala Peanuts',
        'bestWith': 'Dosa · Upma',
        'price': 329,
      },
    ],
  }),

  // 2. 🟢 EVENING TEA: Chai's Crunchy Partners (Murukku + Banana Chips)
  HeroCombo.fromJson({
    'id': 'evening_tea',
    'kicker': 'EVENING TEA',
    'title': "Chai's Crunchy Partners",
    'desc': 'Murukku + Banana Chips',
    'price': 299,
    'imageA': 'assets/images/karam_janthukalu_murukku_strings_snack.jpg',
    'imageB': 'assets/images/allu_chips_thinly_sliced_indian_potato_chips.jpg',
    'colors': ['#18453B', '#235D4E', '#2E7563'],
    'pairs': [
      {
        'id': 'et1',
        'tag': '',
        'imageA': 'assets/images/karam_janthukalu_murukku_strings_snack.jpg',
        'imageB': 'assets/images/allu_chips_thinly_sliced_indian_potato_chips.jpg',
        'name': 'Murukku + Banana Chips',
        'bestWith': 'Evening tea',
        'price': 299,
      },
      {
        'id': 'et2',
        'tag': '',
        'imageA': 'assets/images/khara_mixture_assorted_crunchy_savory_mix.jpg',
        'imageB': 'assets/images/palli_patti_peanut_and_jaggery_chikki.jpg',
        'name': 'Spicy Mixture + Masala Peanuts',
        'bestWith': 'Evening tea',
        'price': 279,
      },
      {
        'id': 'et3',
        'tag': '',
        'imageA': 'assets/images/karam_janthukalu_murukku_strings_snack.jpg',
        'imageB': 'assets/images/khara_mixture_assorted_crunchy_savory_mix.jpg',
        'name': 'Murukku + Spicy Mixture',
        'bestWith': 'Evening tea',
        'price': 319,
      },
    ],
  }),

  // 3. 🟠 AFTER MEALS: Sweet Endings (Sunnunda Laddu + Murukku)
  HeroCombo.fromJson({
    'id': 'after_meals',
    'kicker': 'AFTER MEALS',
    'title': 'Sweet Endings',
    'desc': 'Sunnunda Laddu + Murukku',
    'price': 399,
    'imageA': 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg',
    'imageB': 'assets/images/karam_janthukalu_murukku_strings_snack.jpg',
    'colors': ['#8B4513', '#A0522D', '#B8860B'],
    'pairs': [
      {
        'id': 'am1',
        'tag': '',
        'imageA': 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg',
        'imageB': 'assets/images/karam_janthukalu_murukku_strings_snack.jpg',
        'name': 'Sunnunda Laddu + Murukku',
        'bestWith': 'After meals · Gifting',
        'price': 399,
      },
      {
        'id': 'am2',
        'tag': '',
        'imageA': 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg',
        'imageB': 'assets/images/allu_chips_thinly_sliced_indian_potato_chips.jpg',
        'name': 'Sunnunda Laddu + Banana Chips',
        'bestWith': 'After meals · Gifting',
        'price': 379,
      },
      {
        'id': 'am3',
        'tag': '',
        'imageA': 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg',
        'imageB': 'assets/images/khara_mixture_assorted_crunchy_savory_mix.jpg',
        'name': 'Sunnunda Laddu + Spicy Mixture',
        'bestWith': 'After meals · Gifting',
        'price': 389,
      },
    ],
  }),
];
