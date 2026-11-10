// combo_home_section.dart — "Amma's Combo Box" section for the home page (matches combo_box_complete.mp4, first part)
// The box unwraps, opens, 4 jars drop in, savings steps light up, lid closes, ribbon + bow, confetti — on loop.
// Tapping the card or the button opens ComboBoxScreen.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'combo_shared.dart';
import 'combo_box_screen.dart';

const Color _maroon = Color(0xFF7A1426);
const Color _gold = Color(0xFFC9963F);

class ComboHomeSection extends StatefulWidget {
  final String apiBase;
  final Map<String, String>? headers;
  final VoidCallback? onAdded;
  const ComboHomeSection({super.key, required this.apiBase, this.headers, this.onAdded});
  @override
  State<ComboHomeSection> createState() => _ComboHomeSectionState();
}

class _ComboHomeSectionState extends State<ComboHomeSection> with SingleTickerProviderStateMixin {
  ComboData? _data;
  late AnimationController _loop; // 10.5 s timeline, repeats
  final List<double> _aspects = <double>[1.3, 1.3, 1.3, 1.3];
  final List<List<double>> _conf = ComboConfetti.make(36, 7);
  bool _pressed = false;
  static const double _len = 10.5;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 10500));
    _load();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final ComboData? d = await fetchCombo(widget.apiBase, widget.headers);
      if (!mounted || d == null) return;
      setState(() => _data = d);
      final List<ComboProduct> show = _show(d);
      for (int k = 0; k < show.length; k++) {
        final double a = await imageAspect(show[k].image);
        if (!mounted) return;
        setState(() => _aspects[k] = a);
      }
      if (mounted) _loop.repeat();
    } catch (_) {}
  }

  List<ComboProduct> _show(ComboData d) => d.products.take(math.min(d.settings.jars, 4)).toList();

  void _open() {
    final ComboData? d = _data;
    if (d == null) return;
    HapticFeedback.selectionClick();
    Navigator.of(context).push(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (BuildContext c, Animation<double> a, Animation<double> b) =>
          ComboBoxScreen(apiBase: widget.apiBase, headers: widget.headers, initialData: d, onAdded: widget.onAdded),
      transitionsBuilder: (BuildContext c, Animation<double> a, Animation<double> b, Widget child) => FadeTransition(opacity: a, child: child),
    ));
  }

  double _seg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final ComboData? d = _data;
    if (d == null || !d.settings.enabled || d.products.length < d.settings.jars) return const SizedBox.shrink();
    final ComboSettings s = d.settings;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: <Widget>[
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text(s.eyebrow, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 3, color: _gold)),
              Text('${s.titleStart} ${s.titleAccent}', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: _maroon, height: 1.15)),
            ]),
          ),
          if (s.maxPercent > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 3),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: const Color(0xFFFDE8EC), borderRadius: BorderRadius.circular(12)),
              child: Text('Save up to ${comboPct(s.maxPercent)}', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFC2185B))),
            ),
        ]),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _open,
          child: AnimatedBuilder(animation: _loop, builder: (BuildContext c, Widget? ch) => _card(d)),
        ),
      ]),
    );
  }

  Widget _card(ComboData d) {
    final ComboSettings s = d.settings;
    final List<ComboProduct> show = _show(d);
    final int n = show.length;
    final double t = _loop.value * _len;
    // timeline
    double th = 0.0, bow = 1.0;
    bool tied = true;
    if (t > 0.9) bow = 1 - _seg(t, 0.9, 1.15);
    if (t > 1.15) tied = false;
    if (t > 1.35) th = backOut(_seg(t, 1.35, 2.25));
    final double closeAt = 2.5 + n * 0.76 + 0.5;
    if (t > closeAt) th = 1 - easeInOut(_seg(t, closeAt, closeAt + 0.85));
    final double tieAt = closeAt + 1.0;
    if (t > tieAt) {
      tied = true;
      bow = backOut(_seg(t, tieAt, tieAt + 0.45));
    }
    final double popAt = tieAt + 0.45;
    final List<String> jars = <String>[];
    final List<double> land = <double>[];
    int count = 0;
    for (int k = 0; k < 4; k++) {
      final double at = 2.5 + k * 0.76;
      if (k < n && t >= at && t < closeAt + 2.5) {
        jars.add(show[k].image);
        land.add(_seg(t, at, at + 0.5));
        if (t >= at + 0.48) count++;
      } else {
        jars.add('');
        land.add(1.0);
      }
    }
    if (t >= closeAt) count = n;
    if (t < 1.0) count = 0;
    final bool hide = t > closeAt && th < 0.45;
    final double badge = (t >= popAt && t < popAt + 0.6) ? 0.6 + 0.4 * backOut(_seg(t, popAt, popAt + 0.6)) : 1.0;
    final double conf = (t >= popAt && t < popAt + 1.3) ? _seg(t, popAt, popAt + 1.3) : 0.0;
    final double pct = s.percentFor(count);
    final BoxState bs = BoxState(th: th, tied: tied, bow: bow, next: -1, label: s.boxLabel, lidText: s.lidText);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const RadialGradient(center: Alignment(0, -0.1), radius: 0.95, colors: <Color>[Color(0xFFFFFFFF), Color(0xFFFFF4EC), Color(0xFFF9E3D6)], stops: <double>[0.0, 0.5, 1.0]),
        border: Border.all(color: const Color(0x8CC9963F), width: 1.5),
        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x737A1426), blurRadius: 36, offset: Offset(0, 22), spreadRadius: -22)],
      ),
      child: Stack(clipBehavior: Clip.none, children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Text(s.homeLine, style: GoogleFonts.kalam(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFFA0506A))),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(TextSpan(children: <InlineSpan>[
                    TextSpan(text: '${s.homeTitle} ', style: GoogleFonts.playfairDisplay(fontSize: 25, fontWeight: FontWeight.w700, color: _maroon)),
                    TextSpan(text: s.homeAccent, style: GoogleFonts.playfairDisplay(fontSize: 25, fontWeight: FontWeight.w700, color: _gold)),
                  ])),
                ),
              ]),
            ),
            const SizedBox(height: 6),
            AspectRatio(
              aspectRatio: BoxGeo.w / BoxGeo.h,
              child: Stack(clipBehavior: Clip.none, children: <Widget>[
                Positioned.fill(child: KraftBox(state: bs, jars: jars, aspects: _aspects, land: land, hideJars: hide)),
                if (conf > 0)
                  Positioned(left: 0, right: 0, top: 0, bottom: 0, child: IgnorePointer(child: Center(child: CustomPaint(painter: ComboConfetti(conf, _conf, const <Color>[Color(0xFFFF6B8E), Color(0xFFF6C453), Color(0xFFC2185B), Color(0xFF7FD39A), Color(0xFFF2A93B)]))))),
              ]),
            ),
            const SizedBox(height: 10),
            _steps(s, count, pct),
            const SizedBox(height: 12),
            _cta(s),
          ]),
        ),
        if (s.maxPercent > 0)
          Positioned(
            right: 6,
            top: 92,
            child: Transform.rotate(
              angle: -0.17,
              child: Transform.scale(
                scale: badge,
                child: Container(
                  width: 66,
                  height: 66,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[Color(0xFFD6336C), _maroon]),
                    boxShadow: <BoxShadow>[BoxShadow(color: Color(0x807A1426), blurRadius: 16, offset: Offset(0, 8), spreadRadius: -6)],
                  ),
                  child: Text.rich(
                    TextSpan(children: <InlineSpan>[
                      TextSpan(text: 'UP TO\n', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFFFFE9B0), height: 1.05)),
                      TextSpan(text: comboPct(s.maxPercent), style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, height: 1.05)),
                      TextSpan(text: '\nOFF', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFFFFE9B0), height: 1.05)),
                    ]),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _steps(ComboSettings s, int count, double pct) {
    final String msg = count < (s.tiers.isEmpty ? 2 : s.tiers.first.jars)
        ? 'Pick ${s.tiers.isEmpty ? 2 : s.tiers.first.jars} to start saving'
        : (count < s.jars ? 'You save ${comboPct(pct)} · add ${s.jars - count} more' : 'You save ${comboPct(pct)} 🎉');
    const List<List<Color>> grads = <List<Color>>[
      <Color>[Color(0xFFF2A93B), Color(0xFFE07B12)],
      <Color>[Color(0xFFE8557E), Color(0xFFC2185B)],
      <Color>[Color(0xFF9E1B32), Color(0xFF6A1022)],
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0D9B0)),
        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x807A1426), blurRadius: 20, offset: Offset(0, 10), spreadRadius: -16)],
      ),
      child: Column(children: <Widget>[
        Row(children: <Widget>[
          Text('$count of ${s.jars} jars', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF5A3A2A))),
          const Spacer(),
          Flexible(child: Text(msg, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF1F8A4C)))),
        ]),
        const SizedBox(height: 9),
        Row(children: <Widget>[
          for (int i = 0; i < s.tiers.length && i < 3; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                transform: Matrix4.translationValues(0, count >= s.tiers[i].jars ? -3 : 0, 0),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: count >= s.tiers[i].jars ? null : const Color(0xFFFBF1E6),
                  gradient: count >= s.tiers[i].jars ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: grads[i % 3]) : null,
                  border: Border.all(color: count >= s.tiers[i].jars ? Colors.transparent : const Color(0xFFF3E2D2)),
                ),
                child: Column(children: <Widget>[
                  Text(comboPct(s.tiers[i].percent),
                      style: GoogleFonts.playfairDisplay(fontSize: 17, fontWeight: FontWeight.w700, height: 1.1, color: count >= s.tiers[i].jars ? Colors.white : const Color(0xFFB49A84))),
                  Text('${s.tiers[i].jars} JARS',
                      style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w700, color: count >= s.tiers[i].jars ? Colors.white : const Color(0xFFB49A84))),
                ]),
              ),
            ),
          ],
        ]),
      ]),
    );
  }

  Widget _cta(ComboSettings s) {
    return GestureDetector(
      onTapDown: (TapDownDetails dd) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (TapUpDetails dd) => setState(() => _pressed = false),
      onTap: _open,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: <Color>[Color(0xFFD6336C), _maroon]),
            boxShadow: const <BoxShadow>[BoxShadow(color: Color(0xA6C2185B), blurRadius: 20, offset: Offset(0, 12), spreadRadius: -10)],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            Flexible(child: Text('🎁 ${s.homeButton}', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
            const SizedBox(width: 8),
            Transform.translate(
              offset: Offset(4 * math.sin(_loop.value * _len * math.pi * 2).abs(), 0),
              child: const Text('›', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ]),
        ),
      ),
    );
  }
}
