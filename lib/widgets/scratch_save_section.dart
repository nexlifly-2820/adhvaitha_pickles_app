// scratch_save_section.dart
// "Scratch & Save" — order-ladder scratch cards (one card to scratch, rest locked).

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_config_repository.dart';

// ============================ MODELS ============================

class RewardCard {
  final String id, status, title, subtitle, code, image;
  final int step, unlockAfter, validDays;
  final bool big;

  const RewardCard({
    required this.id,
    required this.status,
    this.title = '',
    this.subtitle = '',
    this.code = '',
    this.image = '',
    this.step = 1,
    this.unlockAfter = 0,
    this.validDays = 7,
    this.big = false,
  });

  factory RewardCard.fromJson(Map<String, dynamic> j) => RewardCard(
        id: '${j['id'] ?? ''}',
        status: j['status'] ?? 'locked',
        title: j['title'] ?? '',
        subtitle: j['subtitle'] ?? '',
        code: j['code'] ?? '',
        image: j['image'] ?? '',
        step: j['step'] ?? 1,
        unlockAfter: j['unlockAfter'] ?? 0,
        validDays: j['validDays'] ?? 7,
        big: j['big'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'title': title,
        'subtitle': subtitle,
        'code': code,
        'image': image,
        'step': step,
        'unlockAfter': unlockAfter,
        'validDays': validDays,
        'big': big,
      };
}

class RewardsData {
  final int ordersDone;
  final List<RewardCard> cards;

  const RewardsData({required this.ordersDone, required this.cards});

  factory RewardsData.fromJson(Map<String, dynamic> j) => RewardsData(
        ordersDone: j['ordersDone'] ?? 0,
        cards: ((j['cards'] ?? []) as List)
            .map((e) => RewardCard.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

// ============================ COLOURS ============================

const _gold = Color(0xFFF6C453);
const _maroon = Color(0xFF8E1B2B);
const _foil = [
  Color(0xFFF9E19A),
  Color(0xFFE2A93A),
  Color(0xFFFBE8A8),
  Color(0xFFC98A1E),
  Color(0xFFF3CF73)
];
const _foilStops = [0.0, .35, .5, .7, 1.0];

// ============================ SECTION ============================

class ScratchSaveSection extends StatefulWidget {
  final RewardsData? data;
  final Future<RewardCard> Function(RewardCard card)? onScratch;
  final ValueChanged<String>? onCopy;
  final VoidCallback? onViewRewards;

  const ScratchSaveSection({
    super.key,
    this.data,
    this.onScratch,
    this.onCopy,
    this.onViewRewards,
  });

  @override
  State<ScratchSaveSection> createState() => _ScratchSaveSectionState();
}

class _ScratchSaveSectionState extends State<ScratchSaveSection>
    with TickerProviderStateMixin {
  late RewardsData _rewardsData = widget.data ?? defaultRewardsData;
  late final AnimationController _twinkle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _listenToRewardsConfig();
  }

  void _listenToRewardsConfig() {
    _sub = AppConfigRepository().getRewardsStream().listen((data) {
      if (!mounted) return;
      if (data.isNotEmpty) {
        final parsed = RewardsData.fromJson(data);
        if (parsed.cards.isNotEmpty) {
          setState(() => _rewardsData = parsed);
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant ScratchSaveSection old) {
    super.didUpdateWidget(old);
    if (widget.data != null) {
      _rewardsData = widget.data!;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _twinkle.dispose();
    super.dispose();
  }

  RewardCard? get _active => _rewardsData.cards
      .where((c) => c.status == 'new' || c.status == 'revealed')
      .cast<RewardCard?>()
      .firstWhere((_) => true, orElse: () => null);

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size.width / 390;
    final active = _active;
    final locked = _rewardsData.cards.where((c) => c.status == 'locked').toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(8 * s, 40 * s, 8 * s, 12 * s),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main Panel
          Container(
            padding: EdgeInsets.fromLTRB(16 * s, 34 * s, 16 * s, 18 * s),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26 * s),
              gradient: const RadialGradient(
                center: Alignment(0, -1),
                radius: 1.3,
                colors: [Color(0xFFB3243A), Color(0xFF7A0F1E), Color(0xFF55070F)],
                stops: [0, .55, 1],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x595A0A14),
                  blurRadius: 26,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '✦ ROYAL PRIVILEGES ✦',
                  style: GoogleFonts.poppins(
                    fontSize: 9.5 * s,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3 * s,
                    color: _gold,
                  ),
                ),
                Text(
                  'Scratch & Save',
                  style: GoogleFonts.fraunces(
                    fontSize: 24 * s,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFFF3D6),
                  ),
                ),
                SizedBox(height: 6 * s),
                ClipPath(
                  clipper: _RibbonClip(),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 18 * s, vertical: 4 * s),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFE39A), Color(0xFFE9B44C)],
                      ),
                    ),
                    child: Text(
                      'Order to unlock bigger rewards',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5 * s,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5A0A14),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16 * s),
                _steps(s),
                SizedBox(height: 14 * s),
                if (active != null)
                  _ActiveCard(
                    key: ValueKey(active.id + active.status),
                    card: active,
                    s: s,
                    onScratch: (c) async {
                      if (widget.onScratch != null) {
                        final revealed = await widget.onScratch!(c);
                        final updatedCards = _rewardsData.cards
                            .map((x) => x.id == c.id ? revealed : x)
                            .toList();
                        setState(() {
                          _rewardsData = RewardsData(
                            ordersDone: _rewardsData.ordersDone,
                            cards: updatedCards,
                          );
                        });
                        return revealed;
                      } else {
                        // Default mock scratch reveal
                        final revealed = RewardCard(
                          id: c.id,
                          status: 'revealed',
                          title: c.title.isNotEmpty ? c.title : '₹100 OFF',
                          subtitle: c.subtitle.isNotEmpty
                              ? c.subtitle
                              : 'on orders above ₹799',
                          code: c.code.isNotEmpty ? c.code : 'ROYAL100',
                          image: c.image.isNotEmpty
                              ? c.image
                              : 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
                          validDays: c.validDays,
                          step: c.step,
                        );
                        final updatedCards = _rewardsData.cards
                            .map((x) => x.id == c.id ? revealed : x)
                            .toList();
                        setState(() {
                          _rewardsData = RewardsData(
                            ordersDone: _rewardsData.ordersDone,
                            cards: updatedCards,
                          );
                        });
                        return revealed;
                      }
                    },
                    onCopy: (code) {
                      HapticFeedback.lightImpact();
                      Clipboard.setData(ClipboardData(text: code));
                      if (widget.onCopy != null) {
                        widget.onCopy!(code);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Coupon code "$code" copied!'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  )
                else
                  _allDone(s),
                if (locked.isNotEmpty) ...[
                  SizedBox(height: 12 * s),
                  Row(
                    children: [
                      for (var i = 0; i < locked.length && i < 3; i++) ...[
                        if (i > 0) SizedBox(width: 10 * s),
                        Expanded(child: _lockedCard(locked[i], s)),
                      ],
                    ],
                  ),
                ],
                if (widget.onViewRewards != null) ...[
                  SizedBox(height: 12 * s),
                  GestureDetector(
                    onTap: widget.onViewRewards,
                    child: Text(
                      'View my rewards →',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5 * s,
                        fontWeight: FontWeight.w600,
                        color: _gold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Gold Inner Frame Border
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                margin: EdgeInsets.all(7 * s),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20 * s),
                  border: Border.all(color: _gold.withOpacity(.65), width: 1.5),
                ),
              ),
            ),
          ),

          // Twinkling Sparkles
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _twinkle,
                builder: (_, __) =>
                    CustomPaint(painter: _SparklePainter(_twinkle.value)),
              ),
            ),
          ),

          // Lotus Crown Header Artwork
          Positioned(
            top: -40 * s,
            left: 0,
            right: 0,
            child: Center(
              child: CustomPaint(
                size: Size(110 * s, 52 * s),
                painter: _CrownPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _steps(double s) {
    final done = _rewardsData.ordersDone;
    final items = <Widget>[];
    final cards = _rewardsData.cards;

    for (var i = 0; i < cards.length; i++) {
      final c = cards[i];
      final isDone = c.status == 'used' ||
          c.status == 'revealed' ||
          (c.status == 'new' && i == 0);
      final isNow =
          c.status == 'locked' && (i == 0 || cards[i - 1].status != 'locked');
      final label = i == 0
          ? 'Card 1'
          : c.big
              ? 'Big prize'
              : '${math.max(0, c.unlockAfter - done)} order${c.unlockAfter - done == 1 ? '' : 's'}';

      if (i > 0) {
        items.add(Expanded(
          child: Container(
            height: 2,
            margin: EdgeInsets.only(left: 4 * s, right: 4 * s, bottom: 14 * s),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDone || isNow
                    ? [_gold, Colors.white.withOpacity(.18)]
                    : [Colors.white.withOpacity(.18), Colors.white.withOpacity(.18)],
              ),
            ),
          ),
        ));
      }

      items.add(Column(
        children: [
          _StepDot(
            s: s,
            done: isDone,
            now: isNow,
            text: c.big ? '🎁' : isDone ? '✓' : '${i + 1}',
          ),
          SizedBox(height: 3 * s),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 8.5 * s,
              color: const Color(0xFFF3C9B8),
            ),
          ),
        ],
      ));
    }
    return Row(children: items);
  }

  Widget _lockedCard(RewardCard c, double s) {
    final left = math.max(0, c.unlockAfter - _rewardsData.ordersDone);
    return Container(
      height: 96 * s,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14 * s),
        border: Border.all(color: _gold.withOpacity(.55), width: 1.5),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _foil,
          stops: _foilStops,
        ),
      ),
      foregroundDecoration: c.big
          ? null
          : BoxDecoration(
              borderRadius: BorderRadius.circular(13 * s),
              color: const Color(0xFF4A3A2A).withOpacity(.45),
            ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 30 * s,
            height: 30 * s,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x8C5A0A14),
              border: Border.all(color: Colors.white.withOpacity(.4)),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.lock, size: 14 * s, color: Colors.white),
          ),
          SizedBox(height: 3 * s),
          Text(
            c.big ? 'Big prize 🎁' : 'Card ${c.step}',
            style: GoogleFonts.poppins(
              fontSize: 13 * s,
              fontWeight: FontWeight.w700,
              color: c.big ? const Color(0xFF5A0A14) : Colors.white,
            ),
          ),
          Text(
            'After $left more order${left == 1 ? '' : 's'}',
            style: GoogleFonts.poppins(
              fontSize: 9 * s,
              color: c.big ? const Color(0xFF5A0A14) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _allDone(double s) => Container(
        height: 120 * s,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.08),
          borderRadius: BorderRadius.circular(18 * s),
        ),
        child: Text(
          'Place an order to unlock your next card 🎉',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 12 * s, color: const Color(0xFFFFE9C9)),
        ),
      );

  static const RewardsData defaultRewardsData = RewardsData(
    ordersDone: 1,
    cards: [
      RewardCard(
        id: 'c1',
        step: 1,
        status: 'new',
        title: '₹100 OFF',
        subtitle: 'on orders above ₹799',
        code: 'ROYAL100',
        image: 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
        validDays: 7,
        unlockAfter: 0,
      ),
      RewardCard(
        id: 'c2',
        step: 2,
        status: 'locked',
        title: '15% OFF',
        subtitle: 'on all pickles & powders',
        code: 'HERITAGE15',
        image: 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg',
        validDays: 10,
        unlockAfter: 1,
      ),
      RewardCard(
        id: 'c3',
        step: 3,
        status: 'locked',
        title: 'FREE SWEET BOX',
        subtitle: 'Sunnunda Laddu on ₹999+',
        code: 'FREESWEET',
        image: 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg',
        validDays: 14,
        unlockAfter: 2,
      ),
      RewardCard(
        id: 'c4',
        step: 4,
        status: 'locked',
        title: '₹500 OFF BUMPER',
        subtitle: 'Royal privilege gift box',
        code: 'BUMPER500',
        image: 'assets/images/karam_janthukalu_murukku_strings_snack.jpg',
        validDays: 30,
        unlockAfter: 3,
        big: true,
      ),
    ],
  );
}

class _StepDot extends StatefulWidget {
  final double s;
  final bool done, now;
  final String text;

  const _StepDot({
    required this.s,
    required this.done,
    required this.now,
    required this.text,
  });

  @override
  State<_StepDot> createState() => _StepDotState();
}

class _StepDotState extends State<_StepDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        width: 26 * s,
        height: 26 * s,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.done
              ? _gold
              : widget.now
                  ? Colors.white
                  : Colors.white.withOpacity(.12),
          border: Border.all(
            color: widget.done
                ? Colors.white
                : _gold.withOpacity(widget.now ? 1 : .4),
            width: 1.5,
          ),
          boxShadow: widget.now
              ? [
                  BoxShadow(
                    color: _gold.withOpacity(.35 * (1 - _c.value)),
                    spreadRadius: 8 * s * _c.value,
                  )
                ]
              : null,
        ),
        child: Text(
          widget.text,
          style: GoogleFonts.poppins(
            fontSize: 11 * s,
            fontWeight: FontWeight.w700,
            color: widget.done
                ? const Color(0xFF5A0A14)
                : widget.now
                    ? _maroon
                    : const Color(0xFFF3C9B8),
          ),
        ),
      ),
    );
  }
}

// ============================ ACTIVE CARD (scratch) ============================

class _ActiveCard extends StatefulWidget {
  final RewardCard card;
  final double s;
  final Future<RewardCard> Function(RewardCard) onScratch;
  final ValueChanged<String>? onCopy;

  const _ActiveCard({
    super.key,
    required this.card,
    required this.s,
    required this.onScratch,
    this.onCopy,
  });

  @override
  State<_ActiveCard> createState() => _ActiveCardState();
}

class _ActiveCardState extends State<_ActiveCard>
    with TickerProviderStateMixin {
  late RewardCard _card = widget.card;
  final List<List<Offset>> _strokes = [];
  final Set<int> _cells = {};
  bool _cleared = false, _loading = false;

  late final AnimationController _fade =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final AnimationController _pop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  late final AnimationController _rays =
      AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  late final AnimationController _confetti =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  late final AnimationController _hand = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    if (_card.status == 'revealed') {
      _cleared = true;
      _fade.value = 1;
      _pop.value = 1;
    }
  }

  @override
  void dispose() {
    for (final c in [_fade, _pop, _rays, _confetti, _hand]) {
      c.dispose();
    }
    super.dispose();
  }

  void _add(Offset p, Size size) {
    if (_cleared) return;
    if (_strokes.isEmpty) _strokes.add([]);
    _strokes.last.add(p);
    final cx = (p.dx / size.width * 20).floor().clamp(0, 19);
    final cy = (p.dy / size.height * 12).floor().clamp(0, 11);
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        final x = cx + dx, y = cy + dy;
        if (x >= 0 && x < 20 && y >= 0 && y < 12) _cells.add(y * 20 + x);
      }
    }
    setState(() {});
    if (_cells.length / 240 >= .55) _finish();
  }

  Future<void> _finish() async {
    if (_cleared || _loading) return;
    setState(() => _loading = true);
    try {
      final revealed = await widget.onScratch(_card);
      setState(() {
        _card = revealed;
        _cleared = true;
      });
      _fade.forward();
      _pop.forward();
      _confetti.forward(from: 0);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildImg(String u, double w) {
    if (u.isEmpty) return SizedBox(width: w);
    if (u.startsWith('http')) {
      return Image.network(
        u,
        width: w,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.gif, size: w * 0.5, color: Colors.grey),
      );
    }
    String assetPath = u.startsWith('assets/') ? u : 'assets/images/$u';
    return Image.asset(
      assetPath,
      width: w,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(Icons.gif, size: w * 0.5, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return Container(
      height: 200 * s,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18 * s),
        border: Border.all(color: _gold, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x59000000), blurRadius: 18, offset: Offset(0, 8))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16 * s),
        child: LayoutBuilder(
          builder: (_, box) {
            final size = Size(box.maxWidth, box.maxHeight);
            return Stack(
              children: [
                // Reward underneath
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -.2),
                        radius: .9,
                        colors: [Color(0xFFFFF9EA), Color(0xFFFBE6B8)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 64 * s - 140 * s,
                  top: 96 * s - 140 * s,
                  width: 280 * s,
                  height: 280 * s,
                  child: AnimatedBuilder(
                    animation: _rays,
                    builder: (_, __) => Transform.rotate(
                      angle: _rays.value * 2 * math.pi,
                      child: CustomPaint(painter: _RaysPainter()),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16 * s),
                  child: AnimatedBuilder(
                    animation: _pop,
                    builder: (_, __) {
                      final a = Curves.easeOutBack.transform(_pop.value);
                      return Opacity(
                        opacity: _pop.value.clamp(0, 1),
                        child: Row(
                          children: [
                            Transform.scale(
                              scale: .6 + .4 * a,
                              child: _buildImg(_card.image, 118 * s),
                            ),
                            SizedBox(width: 10 * s),
                            Expanded(
                              child: Transform.scale(
                                scale: .6 + .4 * a,
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '🎉 YOU WON',
                                      style: GoogleFonts.poppins(
                                        fontSize: 9 * s,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 2.5 * s,
                                        color: const Color(0xFFB07A2A),
                                      ),
                                    ),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        _card.title,
                                        style: GoogleFonts.poppins(
                                          fontSize: 30 * s,
                                          fontWeight: FontWeight.w800,
                                          height: 1,
                                          color: _maroon,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 2 * s),
                                    Text(
                                      _card.subtitle,
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.5 * s,
                                        color: const Color(0xFF7A6650),
                                      ),
                                    ),
                                    SizedBox(height: 9 * s),
                                    Container(
                                      padding: EdgeInsets.fromLTRB(
                                          10 * s, 3 * s, 3 * s, 3 * s),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10 * s),
                                        border: Border.all(
                                            color: const Color(0xFFC9963A), width: 1.5),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _card.code,
                                              style: GoogleFonts.poppins(
                                                fontSize: 12.5 * s,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1,
                                                color: const Color(0xFF2A1A12),
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              if (widget.onCopy != null) {
                                                widget.onCopy!(_card.code);
                                              }
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 12 * s, vertical: 5 * s),
                                              decoration: BoxDecoration(
                                                color: _maroon,
                                                borderRadius: BorderRadius.circular(8 * s),
                                              ),
                                              child: Text(
                                                'Copy',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11 * s,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 5 * s),
                                    Text(
                                      '⏱ Valid for ${_card.validDays} days',
                                      style: GoogleFonts.poppins(
                                        fontSize: 9.5 * s,
                                        color: const Color(0xFFA0522D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Gold foil on top (scratchable)
                if (_fade.value < 1)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _fade,
                      builder: (_, __) => Opacity(
                        opacity: 1 - _fade.value,
                        child: GestureDetector(
                          onPanStart: (d) {
                            _strokes.add([]);
                            _add(d.localPosition, size);
                          },
                          onPanUpdate: (d) => _add(d.localPosition, size),
                          child: CustomPaint(
                            size: size,
                            painter: _FoilPainter(_strokes, s),
                          ),
                        ),
                      ),
                    ),
                  ),

                if (!_cleared && _strokes.isEmpty)
                  Positioned(
                    left: size.width / 2 - 14 * s,
                    top: size.height * .58,
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _hand,
                        builder: (_, __) => Transform.translate(
                          offset: Offset(
                              -14 * s * _hand.value, -8 * s * _hand.value),
                          child: Text('👆', style: TextStyle(fontSize: 26 * s)),
                        ),
                      ),
                    ),
                  ),

                if (_loading)
                  const Positioned.fill(
                    child: Center(
                      child: CircularProgressIndicator(color: _maroon),
                    ),
                  ),

                // Confetti
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _confetti,
                      builder: (_, __) =>
                          CustomPaint(painter: _ConfettiPainter(_confetti.value)),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ============================ PAINTERS ============================

class _FoilPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final double s;

  _FoilPainter(this.strokes, this.s);

  @override
  void paint(Canvas c, Size z) {
    final r = Offset.zero & z;
    c.saveLayer(r, Paint());
    c.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _foil,
          stops: _foilStops,
        ).createShader(r),
    );

    // Stars
    final rnd = math.Random(4);
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < 18; i++) {
      tp.text = TextSpan(
        text: '✦',
        style: TextStyle(
          fontSize: 13 * s,
          color: Colors.white.withOpacity(.4),
        ),
      );
      tp.layout();
      tp.paint(c, Offset(rnd.nextDouble() * z.width, rnd.nextDouble() * z.height));
    }

    // Text
    void centered(String t, TextStyle st, double dy) {
      tp.text = TextSpan(text: t, style: st);
      tp.layout();
      tp.paint(c, Offset((z.width - tp.width) / 2, z.height / 2 + dy));
    }

    centered(
      'Scratch to win',
      GoogleFonts.poppins(
        fontSize: 23 * s,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        shadows: const [Shadow(color: Color(0x66783C00), offset: Offset(0, 2))],
      ),
      -28 * s,
    );

    centered(
      'Your festive reward is waiting',
      GoogleFonts.poppins(
        fontSize: 12 * s,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF6B3A00),
      ),
      4 * s,
    );

    // Scratched areas (Eraser)
    final eraser = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.stroke
      ..strokeWidth = 36 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final st in strokes) {
      if (st.isEmpty) continue;
      if (st.length == 1) {
        c.drawCircle(st.first, 18 * s, Paint()..blendMode = BlendMode.clear);
        continue;
      }
      final p = Path()..moveTo(st.first.dx, st.first.dy);
      for (final o in st.skip(1)) {
        p.lineTo(o.dx, o.dy);
      }
      c.drawPath(p, eraser);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _FoilPainter old) => true;
}

class _RaysPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size z) {
    final ctr = z.center(Offset.zero), r = z.width / 2;
    final p = Paint()..color = const Color(0x38F6C453);
    for (var i = 0; i < 18; i++) {
      final a = i * 2 * math.pi / 18;
      final path = Path()
        ..moveTo(ctr.dx, ctr.dy)
        ..lineTo(ctr.dx + r * math.cos(a), ctr.dy + r * math.sin(a))
        ..lineTo(ctr.dx + r * math.cos(a + .14), ctr.dy + r * math.sin(a + .14))
        ..close();
      c.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _ConfettiPainter extends CustomPainter {
  final double t;

  _ConfettiPainter(this.t);

  static const _cols = [
    Color(0xFFF6C453),
    Color(0xFFC2273A),
    Color(0xFF2F9462),
    Colors.white,
    Color(0xFFE08A2A)
  ];

  @override
  void paint(Canvas c, Size z) {
    if (t <= 0 || t >= 1) return;
    final rnd = math.Random(9);
    for (var i = 0; i < 46; i++) {
      final x = rnd.nextDouble() * z.width;
      final delay = rnd.nextDouble() * .25;
      final fall = 120 + rnd.nextDouble() * 140;
      final tt = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (tt == 0) continue;
      final y = -10 + fall * Curves.easeOut.transform(tt) * 1.2;
      c.save();
      c.translate(x, y);
      c.rotate(tt * 12 + i);
      c.drawRect(
        const Rect.fromLTWH(-3.5, -5, 7, 10),
        Paint()..color = _cols[i % 5].withOpacity(1 - tt * tt),
      );
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}

class _SparklePainter extends CustomPainter {
  final double t;

  _SparklePainter(this.t);

  @override
  void paint(Canvas c, Size z) {
    final rnd = math.Random(7);
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < 16; i++) {
      final x = (.04 + rnd.nextDouble() * .9) * z.width;
      final y = (.02 + rnd.nextDouble() * .94) * z.height;
      final phase = (t + rnd.nextDouble()) % 1;
      final o = math.sin(phase * math.pi).clamp(0.0, 1.0) * .85;
      tp.text = TextSpan(
        text: '✦',
        style: TextStyle(
          fontSize: [8.0, 10.0, 12.0][i % 3],
          color: _gold.withOpacity(o),
        ),
      );
      tp.layout();
      tp.paint(c, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => old.t != t;
}

class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size z) {
    final k = z.width / 120;
    Offset o(double x, double y) => Offset(x * k, y * k);
    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFE9A8), Color(0xFFD49A2C)],
      ).createShader(Offset.zero & z);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8 * k
      ..color = const Color(0xFF8A5A10);

    Path petal(List<double> a) => Path()
      ..moveTo(o(a[0], a[1]).dx, o(a[0], a[1]).dy)
      ..cubicTo(o(a[2], a[3]).dx, o(a[2], a[3]).dy, o(a[4], a[5]).dx,
          o(a[5]).dy, o(a[6], a[7]).dx, o(a[6], a[7]).dy)
      ..cubicTo(o(a[8], a[9]).dx, o(a[8], a[9]).dy, o(a[10], a[11]).dx,
          o(a[11]).dy, o(a[0], a[1]).dx, o(a[0], a[1]).dy);

    for (final p in [
      [60, 50, 44, 44, 24, 40, 6, 42, 18, 54, 40, 56],
      [60, 50, 76, 44, 96, 40, 114, 42, 102, 54, 80, 56],
      [60, 50, 56, 34, 44, 22, 28, 18, 30, 36, 42, 46],
      [60, 50, 64, 34, 76, 22, 92, 18, 90, 36, 78, 46],
      [60, 4, 70, 16, 70, 34, 60, 50, 50, 34, 50, 16],
    ]) {
      final path = petal(p.map((e) => e.toDouble()).toList());
      c.drawShadow(path, Colors.black, 3, false);
      c.drawPath(path, fill);
      c.drawPath(path, edge);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _RibbonClip extends CustomClipper<Path> {
  @override
  Path getClip(Size z) => Path()
    ..moveTo(0, 0)
    ..lineTo(z.width, 0)
    ..lineTo(z.width * .95, z.height / 2)
    ..lineTo(z.width, z.height)
    ..lineTo(0, z.height)
    ..lineTo(z.width * .05, z.height / 2)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}
