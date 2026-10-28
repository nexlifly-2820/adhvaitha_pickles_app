// order_placed_screen.dart
// Order Placed screen: lotus blooms -> logo coin flips into a tick -> printer drops in -> bill prints line by line
// -> "ORDER PLACED" stamp -> petals -> delivery tracker + buttons. Tap anywhere to skip to the end.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../models/order_result.dart';
import '../image_util.dart';

Color _hex(String? h, Color fb) {
  final s = (h ?? '').replaceAll('#', '');
  return s.length == 6 ? Color(int.parse('FF$s', radix: 16)) : fb;
}

String _rs(num v) => '₹${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(2)}';

class OrderPlacedScreen extends StatefulWidget {
  final String? receiptUrl;
  final OrderResult? orderResult;
  final Map<String, String>? headers;
  final ValueChanged<String>? onTrack, onDownloadBill, onShare;
  final VoidCallback? onHome;

  const OrderPlacedScreen({
    super.key,
    this.receiptUrl,
    this.orderResult,
    this.headers,
    this.onTrack,
    this.onDownloadBill,
    this.onShare,
    this.onHome,
  });

  @override
  State<OrderPlacedScreen> createState() => _OrderPlacedScreenState();
}

class _OrderPlacedScreenState extends State<OrderPlacedScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _s, _o;
  String? _error;
  late AnimationController _t;
  late final _loop =
      AnimationController(vsync: this, duration: const Duration(seconds: 20))
        ..repeat();
  bool _shook = false;

  static const _bloom = .0,
      _coin = .1,
      _tick = .27,
      _introEnd = .42,
      _printer = .44,
      _print0 = .5,
      _print1 = .74,
      _stamp = .78,
      _petals = .82,
      _tracker = .88,
      _buttons = .93;

  @override
  void initState() {
    super.initState();
    _t = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 7000));
    _t.addListener(() {
      if (!_shook && _t.value >= _stamp + .02) {
        _shook = true;
        HapticFeedback.mediumImpact();
      }
    });
    _load();
  }

  Future<void> _load() async {
    try {
      if (widget.receiptUrl != null && widget.receiptUrl!.isNotEmpty) {
        final r = await http.get(Uri.parse(widget.receiptUrl!),
            headers: widget.headers);
        if (r.statusCode == 200) {
          final d = jsonDecode(r.body) as Map<String, dynamic>;
          _s = Map<String, dynamic>.from(d['settings'] ?? {});
          _o = Map<String, dynamic>.from(d['order'] ?? {});
        }
      }

      if (_s == null || _o == null) {
        _s = {
          "enabled": true,
          "logo": "assets/images/AMBHUJAKSHI  logo.png",
          "headline": "Order Placed!",
          "subline": "Amma has started packing with love 💛",
          "thanks": "Thank you! 💛",
          "printerLabel": "AMBHUJAKSHI KITCHEN",
          "stampText": "✓ ORDER PLACED",
          "footer": "Good food brings people together 💛",
          "showSavings": true,
          "showConfetti": true,
          "showLotus": true,
          "primaryColor": "#123B2E",
          "accentColor": "#C2273A",
          "durationMs": 7000
        };

        if (widget.orderResult != null) {
          final res = widget.orderResult!;
          _o = {
            "id": res.orderId,
            "customerName": "Customer",
            "placedAt": DateTime.now().toIso8601String(),
            "items": res.items
                .map((i) => {
                      "name": i.name,
                      "variant": i.weight,
                      "qty": i.qty,
                      "amount": i.price * i.qty
                    })
                .toList(),
            "delivery": 0,
            "discounts": [],
            "total": res.total,
            "paymentMethod": "Paid Online",
            "eta": res.deliveryDate ?? "Fri, 9 Oct",
            "status": "placed"
          };
        } else {
          _o = {
            "id": "AMBJ20261",
            "customerName": "Customer",
            "placedAt": DateTime.now().toIso8601String(),
            "items": [
              {
                "name": "Bellam Avakaya",
                "variant": "250g",
                "qty": 1,
                "amount": 120
              }
            ],
            "delivery": 40,
            "discounts": [],
            "total": 160,
            "paymentMethod": "Paid Online",
            "eta": "Fri, 9 Oct",
            "status": "placed"
          };
        }
      }

      final ms = (_s!['durationMs'] ?? 7000) as int;
      _t.duration = Duration(milliseconds: ms.clamp(4000, 12000));

      if (!mounted) return;
      setState(() {});
      HapticFeedback.lightImpact();
      _t.forward(from: (_s!['enabled'] == false) ? 1 : 0);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _t.dispose();
    _loop.dispose();
    super.dispose();
  }

  double _seg(double a, double b) =>
      ((_t.value - a) / (b - a)).clamp(0.0, 1.0);

  String _txt(String k, String fb) => (_s?[k] ?? fb)
      .toString()
      .replaceAll('{name}', '${_o?['customerName'] ?? ''}'.split(' ').first);

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle,
                    color: Color(0xFF2E7D32), size: 64),
                const SizedBox(height: 12),
                Text('Order placed!',
                    style: GoogleFonts.poppins(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                TextButton(
                    onPressed: widget.onHome,
                    child: const Text('Back to home')),
              ],
            ),
          ),
        ),
      );
    }
    if (_s == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7E8CF),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFC2273A)),
        ),
      );
    }
    final primary = _hex(_s!['primaryColor'], const Color(0xFF123B2E));
    final accent = _hex(_s!['accentColor'], const Color(0xFFC2273A));

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_t.value < 1) {
            _t.animateTo(1, duration: const Duration(milliseconds: 250));
          }
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_t, _loop]),
          builder: (_, __) {
            final shake = _t.value > _stamp + .02 && _t.value < _stamp + .05
                ? math.sin(_t.value * 900) * 2.5
                : 0.0;
            return Transform.translate(
              offset: Offset(shake, 0),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -1),
                    radius: 1.4,
                    colors: [
                      Color(0xFFFFF6E6),
                      Color(0xFFF7E8CF),
                      Color(0xFFEED8B4)
                    ],
                    stops: [0, .6, 1],
                  ),
                ),
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (_, box) => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: box.maxWidth / 2 - 350,
                          top: 150 - 350,
                          child: Transform.rotate(
                            angle: _loop.value * 2 * math.pi,
                            child: CustomPaint(
                              size: const Size(700, 700),
                              painter: _RaysPainter(),
                            ),
                          ),
                        ),
                        if (_t.value < _introEnd + .03) _intro(box, accent),
                        if (_t.value >= _printer) ..._receipt(box, primary, accent),
                        if ((_s!['showConfetti'] ?? true) && _t.value >= _petals)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _PetalPainter(
                                  _seg(_petals, 1) * 1.0 +
                                      (_t.value >= 1 ? _loop.value * 0 : 0),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _intro(BoxConstraints box, Color accent) {
    final out = _seg(_introEnd - .03, _introEnd + .03);
    final cx = box.maxWidth / 2;
    const cy = 260.0;
    final coin = Curves.easeOutBack.transform(_seg(_coin, _coin + .08));
    final flip = _seg(_tick - .05, _tick + .02);
    final tick = _seg(_tick + .02, _tick + .07);
    final rings = _seg(_tick + .01, _tick + .15);
    final word = Curves.easeOut.transform(_seg(_tick + .04, _tick + .1));
    final diya = _seg(_coin + .05, _coin + .12);
    final logo = '${_s!['logo'] ?? ''}';

    return Opacity(
      opacity: 1 - out,
      child: Transform.scale(
        scale: 1 + .3 * out,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: cx - 170,
              top: cy - 170,
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color.fromRGBO(255, 214, 140, .7 * _seg(0, .1)),
                      Colors.transparent
                    ],
                  ),
                ),
              ),
            ),
            if (_s!['showLotus'] ?? true)
              Positioned(
                left: cx - 130,
                top: cy - 130,
                child: Transform.rotate(
                  angle: _loop.value * 2 * math.pi * 3,
                  child: CustomPaint(
                    size: const Size(260, 260),
                    painter: _LotusPainter(_seg(_bloom + .02, _coin + .1)),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              top: cy - 60,
              child: Center(
                child: CustomPaint(
                  size: const Size(120, 120),
                  painter: _RingPainter(rings, accent),
                ),
              ),
            ),
            Positioned(
              left: cx - 58,
              top: cy - 58,
              child: Opacity(
                opacity: coin.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: coin,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, .002)
                      ..rotateY(math.sin(flip * math.pi) * math.pi / 2),
                    child: Container(
                      width: 116,
                      height: 116,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: flip < .5
                            ? const RadialGradient(
                                center: Alignment(-.3, -.4),
                                colors: [
                                  Color(0xFFFFF1BF),
                                  Color(0xFFF6C453),
                                  Color(0xFFB8801E)
                                ],
                                stops: [0, .55, 1],
                              )
                            : const RadialGradient(
                                center: Alignment(-.3, -.4),
                                colors: [Color(0xFF3FAF6A), Color(0xFF1F7A45)],
                              ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x668A5A16),
                            blurRadius: 30,
                            offset: Offset(0, 14),
                            spreadRadius: -8,
                          )
                        ],
                      ),
                      alignment: Alignment.center,
                      child: flip < .5
                          ? (logo.isEmpty
                              ? const SizedBox()
                              : ClipOval(
                                  child: buildSmartImage(
                                    logo,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.contain,
                                  ),
                                ))
                          : CustomPaint(
                              size: const Size(116, 116),
                              painter: _TickPainter(tick),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            for (final dx in [-170.0, 136.0])
              Positioned(
                left: cx + dx,
                top: cy - 30 - 6 * diya,
                child: Opacity(
                  opacity: diya,
                  child: const Text('🪔', style: TextStyle(fontSize: 30)),
                ),
              ),
            Positioned(
              left: 20,
              right: 20,
              top: cy + 140,
              child: Opacity(
                opacity: word,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - word)),
                  child: Column(
                    children: [
                      Text(
                        _txt('headline', 'Order Placed!'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fraunces(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF7A1A12),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _txt('subline', ''),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF9A6A3A),
                        ),
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

  List<Widget> _receipt(BoxConstraints box, Color primary, Color accent) {
    final drop = Curves.easeOutBack.transform(_seg(_printer, _printer + .05));
    final printing = _t.value > _print0 && _t.value < _print1;
    final feed = (_seg(_print0, _print1) * 20).floor() / 20;
    final settle = Curves.elasticOut.transform(_seg(_print1, _print1 + .06));
    final stamp = _seg(_stamp, _stamp + .025);
    final o = _o!;

    return [
      Positioned(
        left: 0,
        right: 0,
        top: 6,
        child: Opacity(
          opacity: _seg(_printer + .03, _printer + .08),
          child: Text(
            _txt('thanks', 'Thank you! 💛'),
            textAlign: TextAlign.center,
            style: GoogleFonts.fraunces(
              fontSize: 22,
              color: const Color(0xFF2A1A12),
            ),
          ),
        ),
      ),
      Positioned(
        left: 44,
        right: 44,
        top: 108,
        bottom: 150,
        child: ClipRect(
          child: LayoutBuilder(
            builder: (_, b) => Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      -b.maxHeight * (1 - feed) + (printing ? (feed * 40 % 2) : 0),
                    ),
                    child: Transform.rotate(
                      angle: -.017 * settle,
                      alignment: Alignment.topCenter,
                      child: _bill(o, accent, stamp, b.maxHeight),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        left: 24,
        right: 24,
        top: 52 - 160 * (1 - drop),
        child: Opacity(
          opacity: drop.clamp(0.0, 1.0),
          child: Container(
            height: 62,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20), bottom: Radius.circular(14)),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF5A1E14), Color(0xFF3A120B)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x88000000),
                  blurRadius: 24,
                  offset: Offset(0, 14),
                  spreadRadius: -10,
                )
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 14,
                  top: 6,
                  child: '${_s!['logo'] ?? ''}'.isEmpty
                      ? const SizedBox()
                      : buildSmartImage(
                          _s!['logo'],
                          height: 30,
                          fit: BoxFit.contain,
                        ),
                ),
                Positioned(
                  left: 52,
                  top: 12,
                  child: Text(
                    _txt('printerLabel', 'KITCHEN'),
                    style: GoogleFonts.fraunces(
                      fontSize: 13,
                      letterSpacing: 2,
                      color: const Color(0xFFF6C453),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: printing
                          ? const Color(0xFF5FD38A)
                          : const Color(0xFFF6C453),
                      boxShadow: [
                        BoxShadow(
                          color: printing
                              ? const Color(0xFF5FD38A)
                              : const Color(0xFFF6C453),
                          blurRadius: 8,
                        )
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 22,
                  right: 22,
                  bottom: 12,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF140604),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        left: 24,
        right: 24,
        bottom: 88,
        child: Opacity(
          opacity: _seg(_tracker, _tracker + .04),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _seg(_tracker, _tracker + .04))),
            child: _trackerCard(o, accent),
          ),
        ),
      ),
      Positioned(
        left: 18,
        right: 18,
        bottom: 22,
        child: Opacity(
          opacity: _seg(_buttons, _buttons + .05),
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - _seg(_buttons, _buttons + .05))),
            child: Row(
              children: [
                Expanded(
                  child: _btn(
                    'Track order →',
                    primary,
                    Colors.white,
                    () => widget.onTrack?.call('${o['id']}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _btn(
                    '⬇ Bill · Share',
                    Colors.white,
                    primary,
                    () => _billMenu('${o['id']}'),
                    border: primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _bill(Map o, Color accent, double stamp, double maxH) {
    final mono =
        GoogleFonts.courierPrime(fontSize: 12.5, color: const Color(0xFF2A1A12));
    final items = ((o['items'] ?? []) as List).cast<Map>();
    final discounts = ((o['discounts'] ?? []) as List).cast<Map>();
    final saved =
        discounts.fold<num>(0, (a, d) => a + (d['amount'] as num? ?? 0));

    Widget line(String l, String r, {TextStyle? st}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l,
                  style: st ?? mono,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(r, style: st ?? mono),
            ],
          ),
        );

    Widget dash() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: CustomPaint(
            size: const Size(double.infinity, 1),
            painter: _DashPainter(),
          ),
        );

    final placed = DateTime.tryParse('${o['placedAt'] ?? ''}')?.toLocal();
    final when = placed == null
        ? ''
        : '${placed.day} ${const [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec'
          ][placed.month - 1]} ${placed.year} · '
            '${((placed.hour + 11) % 12) + 1}:${placed.minute.toString().padLeft(2, '0')} ${placed.hour < 12 ? 'AM' : 'PM'}';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          clipper: _ZigZagClipper(),
          child: Container(
            color: const Color(0xFFFFFDF6),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if ('${_s!['logo'] ?? ''}'.isNotEmpty)
                  Center(
                    child: buildSmartImage(
                      _s!['logo'],
                      width: 110,
                      fit: BoxFit.contain,
                    ),
                  ),
                Text('ORDER #${o['id']}',
                    textAlign: TextAlign.center,
                    style: mono.copyWith(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                Text(when,
                    textAlign: TextAlign.center,
                    style: mono.copyWith(fontSize: 11)),
                dash(),
                for (final it in items)
                  line(
                      '${it['name']} ${it['variant'] ?? ''}${(it['qty'] ?? 1) > 1 ? ' ×${it['qty']}' : ''}',
                      _rs(it['amount'] ?? 0)),
                line('Delivery',
                    (o['delivery'] ?? 0) == 0 ? 'FREE' : _rs(o['delivery'])),
                for (final d in discounts)
                  line('${d['label']}', '-${_rs(d['amount'] ?? 0)}',
                      st: mono.copyWith(
                          color: const Color(0xFF2E7D32),
                          fontWeight: FontWeight.w700)),
                dash(),
                line('TOTAL PAID', _rs(o['total'] ?? 0),
                    st: mono.copyWith(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                line(
                    '${o['paymentMethod'] ?? ''}',
                    '${items.fold<num>(0, (a, i) => a + (i['qty'] as num? ?? 1))} item(s)',
                    st: mono.copyWith(fontSize: 11)),
                if ((_s!['showSavings'] ?? true) && saved > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4E8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '🎉 You saved ${_rs(saved)} on this order',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                dash(),
                if ('${o['eta'] ?? ''}'.isNotEmpty)
                  line('Arriving by', '${o['eta']}',
                      st: mono.copyWith(fontSize: 11)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: CustomPaint(
                    size: const Size(double.infinity, 26),
                    painter: _BarcodePainter('${o['id']}'),
                  ),
                ),
                const SizedBox(height: 64),
                Text(
                  _txt('footer', ''),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fraunces(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF8E1B2B),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (stamp > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 52,
            child: Center(
              child: Opacity(
                opacity: .9 * stamp,
                child: Transform.rotate(
                  angle: -.24,
                  child: Transform.scale(
                    scale: 3 - 2 * Curves.easeIn.transform(stamp),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: accent, width: 4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _txt('stampText', '✓ ORDER PLACED'),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _trackerCard(Map o, Color accent) {
    const steps = ['placed', 'packed', 'shipped', 'delivered'];
    final idx = math.max(0, steps.indexOf('${o['status'] ?? 'placed'}'));
    final ride = Curves.easeOut.transform(_seg(_tracker + .02, _tracker + .1));

    return Container(
      height: 56,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 20,
            offset: Offset(0, 10),
            spreadRadius: -12,
          )
        ],
      ),
      child: LayoutBuilder(
        builder: (_, b) {
          final p = (idx / 3 + .12) * ride;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              if ('${o['eta'] ?? ''}'.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Text(
                    'Arriving ${o['eta']}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                top: 24,
                child: Container(height: 3, color: const Color(0xFFEEEEEE)),
              ),
              Positioned(
                left: 0,
                top: 24,
                child: Container(
                  height: 3,
                  width: b.maxWidth * p,
                  color: accent,
                ),
              ),
              Positioned(
                left: b.maxWidth * p - 10,
                top: 4,
                child: const Text('🛵', style: TextStyle(fontSize: 18)),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 30,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < 4; i++)
                      Text(
                        ['Placed', 'Packed', 'Shipped', 'Delivered'][i],
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: i <= idx ? accent : const Color(0xFF999999),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _btn(String t, Color bg, Color fg, VoidCallback onTap, {Color? border}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(26),
            border: border == null ? null : Border.all(color: border, width: 1.5),
          ),
          child: Text(
            t,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ),
      );

  void _billMenu(String id) => showModalBottomSheet(
        context: context,
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Download bill (PDF)'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDownloadBill?.call(id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onShare?.call(id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Continue shopping'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onHome?.call();
                },
              ),
            ],
          ),
        ),
      );
}

// ============================ PAINTERS ============================

class _RaysPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final ctr = s.center(Offset.zero);
    final p = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0x2EF6C453), Color(0x00F6C453)],
        stops: const [.2, .6],
      ).createShader(Rect.fromCircle(center: ctr, radius: s.width / 2));

    for (var i = 0; i < 30; i++) {
      final a = i * 2 * math.pi / 30;
      c.drawPath(
        Path()
          ..moveTo(ctr.dx, ctr.dy)
          ..lineTo(ctr.dx + 350 * math.cos(a), ctr.dy + 350 * math.sin(a))
          ..lineTo(
              ctr.dx + 350 * math.cos(a + .14), ctr.dy + 350 * math.sin(a + .14))
          ..close(),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _LotusPainter extends CustomPainter {
  final double t;
  _LotusPainter(this.t);

  @override
  void paint(Canvas c, Size s) {
    c.translate(s.width / 2, s.height / 2);
    void ring(int n, double len, double w, double start, List<Color> a,
        List<Color> b, double offset) {
      for (var i = 0; i < n; i++) {
        final k =
            Curves.easeOutBack.transform(((t - start - i * .02) / .45).clamp(0.0, 1.0));
        if (k <= 0) continue;
        c.save();
        c.rotate(offset + i * 2 * math.pi / n);
        c.scale(k);
        final path = Path()
          ..moveTo(0, 0)
          ..cubicTo(-w, -len * .3, -w * .85, -len * .76, 0, -len)
          ..cubicTo(w * .85, -len * .76, w, -len * .3, 0, 0);
        c.drawPath(
          path,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: i.isEven ? a : b,
            ).createShader(Rect.fromLTWH(-w, -len, w * 2, len)),
        );
        c.restore();
      }
    }

    ring(12, 110, 26, 0, const [Color(0xFFE5397A), Color(0xFFFFD3E2)],
        const [Color(0xFFFF8FB8), Color(0xFFFFF0F5)], 0);
    ring(12, 72, 16, .3, const [Color(0xFFF6C453), Color(0xFFFFF3C4)],
        const [Color(0xFFF6C453), Color(0xFFFFF3C4)], math.pi / 12);
  }

  @override
  bool shouldRepaint(covariant _LotusPainter o) => o.t != t;
}

class _RingPainter extends CustomPainter {
  final double t;
  final Color accent;
  _RingPainter(this.t, this.accent);

  @override
  void paint(Canvas c, Size s) {
    if (t <= 0 || t >= 1) return;
    final ctr = s.center(Offset.zero);
    for (final pair in [(0.0, const Color(0xFFF6C453)), (.15, accent)]) {
      final d = pair.$1;
      final col = pair.$2;
      final k = ((t - d) / .85).clamp(0.0, 1.0);
      if (k > 0 && k < 1) {
        c.drawCircle(
            ctr,
            60 + 140 * k,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = col.withOpacity(1 - k));
      }
    }
    final r = math.Random(3);
    for (var i = 0; i < 10; i++) {
      final a = r.nextDouble() * 2 * math.pi, d = 80 + r.nextDouble() * 80;
      final e = Curves.easeOut.transform(t);
      c.drawCircle(
          ctr + Offset(math.cos(a), math.sin(a)) * d * e,
          4,
          Paint()
            ..color = [
              const Color(0xFFF6C453),
              accent,
              const Color(0xFF5FD38A)
            ][i % 3]
                .withOpacity(1 - t));
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter o) => o.t != t;
}

class _TickPainter extends CustomPainter {
  final double t;
  _TickPainter(this.t);

  @override
  void paint(Canvas c, Size s) {
    final k = s.width / 120;
    final path = Path()
      ..moveTo(38 * k, 62 * k)
      ..lineTo(54 * k, 78 * k)
      ..lineTo(84 * k, 44 * k);
    final m = path.computeMetrics().first;
    c.drawPath(
      m.extractPath(0, m.length * t),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9 * k
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _TickPainter o) => o.t != t;
}

class _PetalPainter extends CustomPainter {
  final double t;
  _PetalPainter(this.t);
  static const _cols = [
    Color(0xFFFF8A3D),
    Color(0xFFFFC24D),
    Color(0xFFFF5A7A),
    Color(0xFFF6C453),
    Color(0xFFE8463A)
  ];

  @override
  void paint(Canvas c, Size s) {
    final r = math.Random(11);
    for (var i = 0; i < 36; i++) {
      final x = r.nextDouble() * s.width,
          delay = r.nextDouble() * .3,
          speed = .7 + r.nextDouble() * .6;
      final k = ((t - delay) / (1 - delay) * speed).clamp(0.0, 1.0);
      if (k <= 0 || k >= 1) continue;
      c.save();
      c.translate(x + math.sin(k * 8 + i) * 14, -30 + (s.height + 60) * k);
      c.rotate(k * 9 + i);
      c.drawOval(
          const Rect.fromLTWH(-6, -9, 12, 18),
          Paint()..color = _cols[i % 5].withOpacity(.9));
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PetalPainter o) => o.t != t;
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = const Color(0xFFB8A58A)
      ..strokeWidth = 1.5;
    for (var x = 0.0; x < s.width; x += 7) {
      c.drawLine(Offset(x, 0), Offset(x + 4, 0), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _BarcodePainter extends CustomPainter {
  final String seed;
  _BarcodePainter(this.seed);

  @override
  void paint(Canvas c, Size s) {
    final r = math.Random(seed.hashCode);
    final p = Paint()..color = const Color(0xFF2A1A12);
    var x = 0.0;
    while (x < s.width) {
      final w = 1.0 + r.nextInt(3);
      c.drawRect(Rect.fromLTWH(x, 0, w, s.height), p);
      x += w + 1 + r.nextInt(3);
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodePainter o) => o.seed != seed;
}

class _ZigZagClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(s.width, 0)
      ..lineTo(s.width, s.height - 8);
    var x = s.width;
    var down = true;
    while (x > 0) {
      x -= 8;
      p.lineTo(math.max(0, x), down ? s.height : s.height - 8);
      down = !down;
    }
    return p..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> o) => false;
}
