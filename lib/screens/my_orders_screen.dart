// my_orders_screen.dart — AmbhuJakshi "My Orders" page
// Live banner (flip-clock countdown + spinning seal + typing food tips), tabs, order cards with
// kitchen tracker, Amma's note, step-change sparkle and star rating.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../order_manager.dart';
import '../models.dart' as app_models;
import '../image_util.dart';
import 'order_placed_screen.dart';
import '../navigation_util.dart';

Color _hex(String? s, [Color fb = const Color(0xFFE85A4F)]) {
  if (s == null || s.isEmpty) return fb;
  var h = s.replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  return Color(int.tryParse(h, radix: 16) ?? fb.value);
}

class LiveInfo {
  final String orderId, code, category, titleHtml, seal;
  final List<String> tips;
  final DateTime? etaAt;
  final Color color;

  LiveInfo.fromJson(Map<String, dynamic> j)
      : orderId = '${j['orderId'] ?? ''}',
        code = j['code'] ?? '',
        category = j['category'] ?? '',
        titleHtml = j['title'] ?? '',
        seal = j['seal'] ?? 'MADE FRESH · HOMEMADE · ',
        tips = List<String>.from(j['tips'] ?? const []),
        etaAt = j['etaAt'] != null ? DateTime.tryParse(j['etaAt']) : null,
        color = _hex(j['color']);
}

class OrderItem {
  final String id, code, title, subtitle, image, status, note, message;
  final double amount;
  final int step;
  int rating;

  OrderItem({
    required this.id,
    required this.code,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.status,
    required this.note,
    required this.message,
    required this.amount,
    required this.step,
    this.rating = 0,
  });

  OrderItem.fromJson(Map<String, dynamic> j)
      : id = '${j['id'] ?? ''}',
        code = j['code'] ?? '',
        title = j['title'] ?? '',
        subtitle = j['subtitle'] ?? '',
        image = j['image'] ?? '',
        status = j['status'] ?? 'placed',
        note = j['note'] ?? '',
        message = j['message'] ?? '',
        amount = (j['amount'] as num?)?.toDouble() ?? 0,
        step = (j['step'] as num?)?.toInt() ?? 0,
        rating = (j['rating'] as num?)?.toInt() ?? 0;
}

class StepDef {
  final String label, icon;
  const StepDef(this.label, this.icon);
}

class OrdersSettings {
  final bool liveEnabled, showNotes, showRating;
  final String logo, tipsLabel, noteSign;
  final List<StepDef> steps;

  OrdersSettings.fromJson(Map<String, dynamic> j)
      : liveEnabled = j['liveEnabled'] ?? true,
        showNotes = j['showNotes'] ?? true,
        showRating = j['showRating'] ?? true,
        logo = j['logo'] ?? '',
        tipsLabel = j['tipsLabel'] ?? 'WHILE YOU WAIT',
        noteSign = j['noteSign'] ?? 'Amma',
        steps = ((j['steps'] as List?) ?? const [])
            .map((e) => StepDef(e['label'] ?? '', e['icon'] ?? '•'))
            .toList();

  OrdersSettings.defaultSettings()
      : liveEnabled = true,
        showNotes = true,
        showRating = true,
        logo = 'assets/images/AMBHUJAKSHI  logo.png',
        tipsLabel = 'WHILE YOU WAIT',
        noteSign = 'Amma',
        steps = const [
          StepDef('Placed', '🛒'),
          StepDef('Kitchen', '👩‍🍳'),
          StepDef('Sealed', '🏺'),
          StepDef('Shipped', '🚚'),
          StepDef('Delivered', '🏡'),
        ];
}

const _bg1 = Color(0xFFFFF8EC), _bg2 = Color(0xFFF6EAD6);
const _ink = Color(0xFF2A1A12), _muted = Color(0xFF8A7660);
const _green = Color(0xFF123B2E),
    _orange = Color(0xFFD2691E),
    _red = Color(0xFFC2273A);
const _cream = Color(0xFFFFE7B8), _gold = Color(0xFFE9C46A);

class MyOrdersScreen extends StatefulWidget {
  final String apiBase;
  final Map<String, String>? headers;
  final ValueChanged<String>? onViewBill, onOpenOrder;

  const MyOrdersScreen({
    super.key,
    this.apiBase = 'https://admin.adhvaithafoods.in/api',
    this.headers,
    this.onViewBill,
    this.onOpenOrder,
  });

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  static const _tabs = ['active', 'delivered', 'cancelled'];
  int _tab = 0;
  bool _loading = true;
  String? _error;
  OrdersSettings _s = OrdersSettings.defaultSettings();
  LiveInfo? _live;
  List<OrderItem> _orders = [];
  Map<String, int> _counts = {};
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(
        const Duration(seconds: 30), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final r = await http.get(
        Uri.parse('${widget.apiBase}/my-orders?tab=${_tabs[_tab]}'),
        headers: widget.headers,
      ).timeout(const Duration(seconds: 5));

      if (r.statusCode == 200) {
        final j = jsonDecode(r.body) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          if (j['settings'] != null) {
            _s = OrdersSettings.fromJson(j['settings']);
          }
          _live = j['live'] != null ? LiveInfo.fromJson(j['live']) : null;
          _orders = ((j['orders'] as List?) ?? [])
              .map((e) => OrderItem.fromJson(e))
              .toList();
          _counts = Map<String, int>.from(j['counts'] ?? {});
          _loading = false;
          _error = null;
        });
        return;
      }
    } catch (_) {
      // Fallback to local OrderManager
    }

    _loadFromOrderManager();
  }

  void _loadFromOrderManager() {
    final localOrders = OrderManager().orders;
    final List<OrderItem> mapped = [];

    for (final o in localOrders) {
      final statusLower = o.status.toLowerCase();
      bool isActive = statusLower.contains('placed') ||
          statusLower.contains('prepar') ||
          statusLower.contains('seal') ||
          statusLower.contains('ship') ||
          statusLower.contains('kitchen');
      bool isDelivered = statusLower.contains('deliver');
      bool isCancelled = statusLower.contains('cancel');

      if ((_tab == 0 && isActive) ||
          (_tab == 1 && isDelivered) ||
          (_tab == 2 && isCancelled)) {
        final firstItem = o.items.isNotEmpty ? o.items.first : null;
        int stepVal = 0;
        if (statusLower.contains('kitchen') || statusLower.contains('prepar')) {
          stepVal = 1;
        } else if (statusLower.contains('seal')) {
          stepVal = 2;
        } else if (statusLower.contains('ship')) {
          stepVal = 3;
        } else if (statusLower.contains('deliver')) {
          stepVal = 4;
        }

        mapped.add(OrderItem(
          id: o.id,
          code: o.id,
          title: firstItem != null
              ? firstItem.product.name
              : 'AmbhuJakshi Delights',
          subtitle: firstItem != null
              ? '${firstItem.weight} · ${o.items.length} item(s)'
              : '${o.items.length} item(s)',
          image: firstItem != null ? firstItem.product.image : '',
          status: o.status,
          note: 'Amma is packing your homemade delicacies with extra love 💛',
          message: 'Estimated delivery: ${o.estimatedDelivery != null ? "${o.estimatedDelivery!.day} Oct" : "TBD"}',
          amount: o.total,
          step: stepVal,
        ));
      }
    }

    int activeCount = localOrders.where((o) => !o.status.toLowerCase().contains('deliver') && !o.status.toLowerCase().contains('cancel')).length;
    int deliveredCount = localOrders.where((o) => o.status.toLowerCase().contains('deliver')).length;
    int cancelledCount = localOrders.where((o) => o.status.toLowerCase().contains('cancel')).length;

    if (mapped.isNotEmpty && _live == null) {
      final activeOrder = mapped.first;
      _live = LiveInfo.fromJson({
        'orderId': activeOrder.id,
        'code': activeOrder.id,
        'category': 'FRESH ORDER',
        'title': 'Amma is preparing your <em>${activeOrder.title}</em>',
        'seal': 'MADE FRESH · HOMEMADE · ',
        'tips': [
          'Slow roasting spices on low flame preserves natural essential oils.',
          'Sun-drying raw mangoes enhances traditional South Indian crunch.',
          'Stone-pounding Podis keeps rich aromas intact.'
        ],
        'etaAt': DateTime.now().add(const Duration(hours: 36)).toIso8601String(),
        'color': '#C2273A'
      });
    }

    if (mounted) {
      setState(() {
        _orders = mapped;
        _counts = {
          'active': activeCount,
          'delivered': deliveredCount,
          'cancelled': cancelledCount,
        };
        _loading = false;
        _error = null;
      });
    }
  }

  Future<void> _rate(OrderItem o, int stars) async {
    HapticFeedback.selectionClick();
    setState(() => o.rating = stars);
    try {
      await http.post(
        Uri.parse('${widget.apiBase}/my-orders/${o.id}/rate'),
        headers: {'Content-Type': 'application/json', ...?widget.headers},
        body: jsonEncode({'stars': stars}),
      );
    } catch (_) {}
  }

  Widget _logo(double size) {
    final url = _s.logo;
    return url.startsWith('http')
        ? buildSmartImage(url, width: size, height: size, fit: BoxFit.contain)
        : Image.asset('assets/images/AMBHUJAKSHI  logo.png',
            width: size, height: size, fit: BoxFit.contain);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_bg1, _bg2])),
      child: SafeArea(
        child: RefreshIndicator(
          color: _green,
          onRefresh: () => _load(silent: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Row(
                  children: [
                    Text(
                      'MY ORDERS',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                        letterSpacing: .5,
                      ),
                    ),
                    const Spacer(),
                    const Text('🛍️', style: TextStyle(fontSize: 20)),
                  ],
                ),
              ),
              if (_s.liveEnabled && _live != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                  child: GestureDetector(
                    onTap: () => widget.onOpenOrder != null
                        ? widget.onOpenOrder!(_live!.orderId)
                        : _openReceiptScreen(_live!.orderId),
                    child: LiveBanner(
                        info: _live!,
                        logo: _logo(64),
                        tipsLabel: _s.tipsLabel),
                  ),
                ),
              _TabBar(
                index: _tab,
                labels: [
                  'Active${(_counts['active'] ?? 0) > 0 ? ' · ${_counts['active']}' : ''}',
                  'Delivered',
                  'Cancelled',
                ],
                onTap: (i) {
                  if (i != _tab) {
                    setState(() => _tab = i);
                    _load();
                  }
                },
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(color: _green),
                  ),
                )
              else if (_error != null && _orders.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text(_error!, style: const TextStyle(color: _muted)),
                  ),
                )
              else if (_orders.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      'No orders here yet',
                      style: GoogleFonts.poppins(color: _muted),
                    ),
                  ),
                )
              else
                for (int i = 0; i < _orders.length; i++)
                  _Entrance(
                    key: ValueKey('${_tabs[_tab]}-${_orders[i].id}'),
                    delay: Duration(milliseconds: 80 * i),
                    child: OrderCard(
                      order: _orders[i],
                      steps: _s.steps,
                      showNote: _s.showNotes,
                      showRating: _s.showRating,
                      noteSign: _s.noteSign,
                      logo: _logo(24),
                      onViewBill: () => widget.onViewBill != null
                          ? widget.onViewBill!(_orders[i].id)
                          : _openReceiptScreen(_orders[i].id),
                      onTap: () => widget.onOpenOrder != null
                          ? widget.onOpenOrder!(_orders[i].id)
                          : _openReceiptScreen(_orders[i].id),
                      onRate: (s) => _rate(_orders[i], s),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  void _openReceiptScreen(String orderId) {
    AppNavigator.push(
      context,
      OrderPlacedScreen(
        receiptUrl: 'https://admin.adhvaithafoods.in/api/orders/$orderId/receipt',
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final int index;
  final List<String> labels;
  final ValueChanged<int> onTap;

  const _TabBar(
      {required this.index, required this.labels, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 6, 18, 12),
      padding: const EdgeInsets.all(4),
      height: 46,
      decoration: BoxDecoration(
          color: const Color(0xFFEFE2CC),
          borderRadius: BorderRadius.circular(14)),
      child: LayoutBuilder(
        builder: (_, c) {
          final w = c.maxWidth / labels.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutBack,
                left: w * index,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: _green.withOpacity(.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (int i = 0; i < labels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onTap(i),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 250),
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: i == index
                                  ? Colors.white
                                  : const Color(0xFF8A7660),
                            ),
                            child: Text(labels[i]),
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
}

class LiveBanner extends StatefulWidget {
  final LiveInfo info;
  final Widget logo;
  final String tipsLabel;

  const LiveBanner({
    super.key,
    required this.info,
    required this.logo,
    required this.tipsLabel,
  });

  @override
  State<LiveBanner> createState() => _LiveBannerState();
}

class _LiveBannerState extends State<LiveBanner>
    with TickerProviderStateMixin {
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(seconds: 14))
        ..repeat();
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat();
  late final AnimationController _beat = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat(reverse: true);
  Timer? _clock, _typer;
  Duration _left = Duration.zero;
  int _tipIndex = 0, _chars = 0;

  @override
  void initState() {
    super.initState();
    _tickClock();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => _tickClock());
    _startTyping();
  }

  @override
  void didUpdateWidget(covariant LiveBanner old) {
    super.didUpdateWidget(old);
    if (old.info.orderId != widget.info.orderId ||
        old.info.tips.join() != widget.info.tips.join()) {
      _tipIndex = 0;
      _startTyping();
    }
  }

  void _tickClock() {
    final eta = widget.info.etaAt;
    final left = eta == null ? Duration.zero : eta.difference(DateTime.now());
    if (mounted) setState(() => _left = left.isNegative ? Duration.zero : left);
  }

  void _startTyping() {
    _typer?.cancel();
    if (widget.info.tips.isEmpty) return;
    _chars = 0;
    int hold = 0;
    _typer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      final tip = widget.info.tips[_tipIndex % widget.info.tips.length];
      final total = tip.characters.length;
      if (_chars < total) {
        setState(() => _chars++);
      } else if (++hold > 80) {
        hold = 0;
        setState(() {
          _tipIndex++;
          _chars = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    _beat.dispose();
    _clock?.cancel();
    _typer?.cancel();
    super.dispose();
  }

  List<TextSpan> _title(String html, Color acc) {
    final base = GoogleFonts.playfairDisplay(
      fontSize: 19,
      height: 1.2,
      color: const Color(0xFFFBEFDC),
      fontWeight: FontWeight.w600,
    );
    final spans = <TextSpan>[];
    final re = RegExp(r'<em>(.*?)</em>');
    int last = 0;
    final s = html.replaceAll('<br>', '\n');
    for (final m in re.allMatches(s)) {
      spans.add(TextSpan(text: s.substring(last, m.start), style: base));
      spans.add(TextSpan(
          text: m.group(1),
          style: base.copyWith(color: acc, fontStyle: FontStyle.italic)));
      last = m.end;
    }
    spans.add(TextSpan(text: s.substring(last), style: base));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final acc = widget.info.color;
    final d = _left.inDays, h = _left.inHours % 24, m = _left.inMinutes % 60;
    final tip = widget.info.tips.isEmpty
        ? ''
        : widget.info.tips[_tipIndex % widget.info.tips.length];

    return AspectRatio(
      aspectRatio: 362 / 216,
      child: LayoutBuilder(
        builder: (_, c) {
          final k = c.maxWidth / 362;
          return ClipRRect(
            borderRadius: BorderRadius.circular(26 * k),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(.7, -.6),
                  radius: 1.3,
                  colors: [
                    Color(0xFF5B3322),
                    Color(0xFF2C1810),
                    Color(0xFF1D100A)
                  ],
                  stops: [0, .55, 1],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -40 * k,
                    top: -30 * k,
                    width: 240 * k,
                    height: 240 * k,
                    child: AnimatedContainer(
                      duration: const Duration(seconds: 1),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [acc.withOpacity(.42), acc.withOpacity(0)],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _beat,
                      builder: (_, __) => CustomPaint(
                        painter: _StarsPainter(_beat.value),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20 * k,
                    top: 16 * k,
                    child: Row(
                      children: [
                        AnimatedBuilder(
                          animation: _pulse,
                          builder: (_, __) => Container(
                            width: 6 * k,
                            height: 6 * k,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFF5A3C),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF5A3C).withOpacity(
                                      .7 * (1 - _pulse.value)),
                                  spreadRadius: 7 * k * _pulse.value,
                                )
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 7 * k),
                        Text(
                          'LIVE · ${widget.info.code}',
                          style: GoogleFonts.poppins(
                            fontSize: 9 * k,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFD9B98A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 20 * k,
                    top: 36 * k,
                    width: 210 * k,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (w, a) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, .2),
                            end: Offset.zero,
                          ).animate(a),
                          child: w,
                        ),
                      ),
                      child: MediaQuery(
                        key: ValueKey(widget.info.titleHtml),
                        data: MediaQuery.of(context)
                            .copyWith(textScaler: TextScaler.linear(k)),
                        child: RichText(
                          text: TextSpan(
                              children: _title(widget.info.titleHtml, acc)),
                          textScaler: TextScaler.linear(k),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20 * k,
                    top: 92 * k,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FlipTile(value: '$d', label: 'DAY', k: k),
                        _Colon(k: k, anim: _beat),
                        _FlipTile(
                            value: h.toString().padLeft(2, '0'),
                            label: 'HRS',
                            k: k),
                        _Colon(k: k, anim: _beat),
                        _FlipTile(
                            value: m.toString().padLeft(2, '0'),
                            label: 'MIN',
                            k: k),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 16 * k,
                    top: 26 * k,
                    width: 124 * k,
                    height: 124 * k,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        RotationTransition(
                          turns: _spin,
                          child: CustomPaint(
                            size: Size.square(124 * k),
                            painter: _SealTextPainter(
                                widget.info.seal, 9.6 * k, 52 * k),
                          ),
                        ),
                        RotationTransition(
                          turns: ReverseAnimation(_spin),
                          child: CustomPaint(
                            size: Size.square(96 * k),
                            painter:
                                _DashCirclePainter(_gold.withOpacity(.35)),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _beat,
                          builder: (_, child) => Transform.scale(
                              scale: 1 + .04 * _beat.value, child: child),
                          child: Container(
                            width: 76 * k,
                            height: 76 * k,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                center: Alignment(-.2, -.3),
                                colors: [
                                  Color(0xFFFFF8EC),
                                  Color(0xFFF1E2C8)
                                ],
                              ),
                              border: Border.all(color: acc, width: 3 * k),
                              boxShadow: [
                                BoxShadow(
                                  color: acc.withOpacity(.45),
                                  blurRadius: 24 * k,
                                  spreadRadius: 4 * k,
                                )
                              ],
                            ),
                            padding: EdgeInsets.all(6 * k),
                            child: FittedBox(child: widget.logo),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 14 * k,
                    right: 14 * k,
                    bottom: 12 * k,
                    height: 38 * k,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12 * k),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.06),
                        borderRadius: BorderRadius.circular(14 * k),
                        border: Border.all(color: _cream.withOpacity(.08)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            widget.tipsLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 7.5 * k,
                              letterSpacing: 1.3,
                              fontWeight: FontWeight.w700,
                              color: acc,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 16 * k,
                            margin:
                                EdgeInsets.symmetric(horizontal: 10 * k),
                            color: _cream.withOpacity(.15),
                          ),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                      text: tip.characters
                                          .take(_chars)
                                          .toString()),
                                  TextSpan(
                                    text: (DateTime.now().millisecond < 500)
                                        ? '|'
                                        : ' ',
                                    style: TextStyle(
                                        color: acc,
                                        fontStyle: FontStyle.normal),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 12.5 * k,
                                fontStyle: FontStyle.italic,
                                color: _cream,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FlipTile extends StatelessWidget {
  final String value, label;
  final double k;

  const _FlipTile(
      {required this.value, required this.label, required this.k});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 38 * k,
          height: 42 * k,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            transitionBuilder: (child, a) => AnimatedBuilder(
              animation: a,
              child: child,
              builder: (_, w) {
                final t = a.value;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, .004)
                    ..rotateX((1 - t) * math.pi / 2),
                  child: Opacity(opacity: t < .5 ? 0 : 1, child: w),
                );
              },
            ),
            child: Container(
              key: ValueKey(value),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9 * k),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF4E2F20),
                    Color(0xFF4E2F20),
                    Color(0xFF3E2418),
                    Color(0xFF3E2418)
                  ],
                  stops: [0, .5, .5, 1],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.45),
                    blurRadius: 10 * k,
                    offset: Offset(0, 6 * k),
                  )
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 21 * k,
                      fontWeight: FontWeight.w700,
                      color: _cream,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 21 * k,
                    child: Container(
                      height: 1,
                      color: Colors.black.withOpacity(.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 3 * k),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 7.5 * k,
            letterSpacing: 1.2,
            color: const Color(0xFFA88B68),
          ),
        ),
      ],
    );
  }
}

class _Colon extends StatelessWidget {
  final double k;
  final Animation<double> anim;

  const _Colon({required this.k, required this.anim});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 14 * k,
        height: 42 * k,
        child: Center(
          child: FadeTransition(
            opacity: Tween(begin: .3, end: 1.0).animate(anim),
            child: Text(
              ':',
              style: TextStyle(
                fontSize: 20 * k,
                color: const Color(0xFF7A5A44),
              ),
            ),
          ),
        ),
      );
}

class _SealTextPainter extends CustomPainter {
  final String text;
  final double fontSize, radius;

  _SealTextPainter(this.text, this.fontSize, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final chars = text.characters.toList();
    if (chars.isEmpty) return;
    final step = 2 * math.pi / chars.length;
    for (int i = 0; i < chars.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: chars[i],
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: _gold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final a = -math.pi / 2 + i * step;
      canvas.save();
      canvas.translate(
          c.dx + radius * math.cos(a), c.dy + radius * math.sin(a));
      canvas.rotate(a + math.pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SealTextPainter o) =>
      o.text != text || o.fontSize != fontSize;
}

class _DashCirclePainter extends CustomPainter {
  final Color color;

  _DashCirclePainter(this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final r = s.width / 2, c = s.center(Offset.zero);
    for (int i = 0; i < 48; i++) {
      final a = i * 2 * math.pi / 48;
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: r), a, math.pi / 72, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _StarsPainter extends CustomPainter {
  final double t;

  _StarsPainter(this.t);

  @override
  void paint(Canvas canvas, Size s) {
    for (int i = 0; i < 16; i++) {
      final x = ((i * 53) % 360) / 362 * s.width,
          y = ((i * 29) % 150) / 216 * s.height;
      final o = (.3 + (i % 3) * .2) * (i.isEven ? (.4 + .6 * t) : (1 - .6 * t));
      canvas.drawCircle(
          Offset(x, y), 1, Paint()..color = _cream.withOpacity(o.clamp(0, 1)));
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter o) => o.t != t;
}

class OrderCard extends StatefulWidget {
  final OrderItem order;
  final List<StepDef> steps;
  final bool showNote, showRating;
  final String noteSign;
  final Widget logo;
  final VoidCallback onViewBill, onTap;
  final ValueChanged<int> onRate;

  const OrderCard({
    super.key,
    required this.order,
    required this.steps,
    required this.showNote,
    required this.showRating,
    required this.noteSign,
    required this.logo,
    required this.onViewBill,
    required this.onTap,
    required this.onRate,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat();
  late final AnimationController _spark = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didUpdateWidget(covariant OrderCard old) {
    super.didUpdateWidget(old);
    if (widget.order.step > old.order.step) {
      HapticFeedback.lightImpact();
      _spark.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _spark.dispose();
    super.dispose();
  }

  ({String text, Color fg, Color bg}) get _chip {
    switch (widget.order.status.toLowerCase()) {
      case 'kitchen':
      case 'preparing':
        return (
          text: 'IN KITCHEN',
          fg: _orange,
          bg: const Color(0xFFFFF0E0)
        );
      case 'packed':
      case 'sealed':
      case 'quality sealed':
        return (text: 'PACKED', fg: _orange, bg: const Color(0xFFFFF0E0));
      case 'shipped':
        return (
          text: 'SHIPPED',
          fg: const Color(0xFF2E5BD2),
          bg: const Color(0xFFE8F0FF)
        );
      case 'delivered':
        return (
          text: 'DELIVERED',
          fg: const Color(0xFF1E7A46),
          bg: const Color(0xFFE6F4EC)
        );
      case 'cancelled':
        return (text: 'CANCELLED', fg: _red, bg: const Color(0xFFFDE8EA));
      default:
        return (text: 'PLACED', fg: _green, bg: const Color(0xFFEAF3EE));
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order, chip = _chip;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3C1E00).withOpacity(.18),
              blurRadius: 28,
              offset: const Offset(0, 14),
              spreadRadius: -12,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFFF3DC), Color(0xFFF5E2C2)],
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: o.image.isEmpty
                      ? const SizedBox()
                      : buildSmartImage(o.image, fit: BoxFit.contain),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      Text(
                        o.subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          color: _muted,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: chip.bg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FadeTransition(
                              opacity:
                                  Tween(begin: .3, end: 1.0).animate(_pulse),
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: chip.fg,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              chip.text,
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .8,
                                color: chip.fg,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${o.amount.toStringAsFixed(o.amount % 1 == 0 ? 0 : 2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: widget.onViewBill,
                      child: Text(
                        'View bill',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: _red,
                          decoration: TextDecoration.underline,
                          decorationColor: _red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (widget.showNote && o.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Transform.rotate(
                  angle: -.017,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 24, height: 24, child: widget.logo),
                      const SizedBox(width: 6),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Text(
                            '"${o.note}" — ${widget.noteSign}',
                            key: ValueKey(o.note),
                            style: GoogleFonts.kalam(
                              fontSize: 13,
                              color: const Color(0xFF7A3A12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (o.message.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  o.message,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF24408E),
                  ),
                ),
              ),
            if (o.step >= 0 && o.step < 4 && widget.steps.length == 5)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _Tracker(
                  step: o.step,
                  steps: widget.steps,
                  pulse: _pulse,
                  spark: _spark,
                ),
              ),
            if (widget.showRating &&
                o.status.toLowerCase().contains('deliver'))
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Text(
                      o.rating > 0 ? 'Thanks for rating!' : 'How was it?',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                    const Spacer(),
                    for (int s = 1; s <= 5; s++)
                      GestureDetector(
                        onTap: () => widget.onRate(s),
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey('$s-${o.rating >= s}'),
                          tween: Tween(begin: o.rating >= s ? .5 : 1, end: 1),
                          duration: Duration(milliseconds: 300 + s * 60),
                          curve: Curves.elasticOut,
                          builder: (_, v, __) => Transform.scale(
                            scale: v,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: Icon(
                                o.rating >= s
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 26,
                                color: o.rating >= s
                                    ? const Color(0xFFF2A93B)
                                    : const Color(0xFFD8C8B0),
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
    );
  }
}

class _Tracker extends StatelessWidget {
  final int step;
  final List<StepDef> steps;
  final Animation<double> pulse, spark;

  const _Tracker({
    required this.step,
    required this.steps,
    required this.pulse,
    required this.spark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: LayoutBuilder(
        builder: (_, c) {
          final w = c.maxWidth, gap = (w - 40) / 4;
          double x(int i) => 20 + i * gap;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 20,
                right: 20,
                top: 19,
                child: Container(height: 3, color: const Color(0xFFF0E6D6)),
              ),
              Positioned(
                left: 20,
                top: 19,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: gap * step),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Container(
                    width: v,
                    height: 3,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [_green, _orange]),
                    ),
                  ),
                ),
              ),
              for (int i = 0; i < 5; i++)
                Positioned(
                  left: x(i) - 30,
                  top: 0,
                  width: 60,
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: pulse,
                        builder: (_, child) => Container(
                          decoration: i == step
                              ? BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _orange.withOpacity(
                                          .35 * (1 - pulse.value)),
                                      spreadRadius: 10 * pulse.value,
                                    )
                                  ],
                                )
                              : null,
                          child: child,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutBack,
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < step
                                ? const Color(0xFFEAF3EE)
                                : i == step
                                    ? const Color(0xFFFFF0E0)
                                    : Colors.white,
                            border: Border.all(
                              width: 2,
                              color: i < step
                                  ? _green
                                  : i == step
                                      ? _orange
                                      : const Color(0xFFF0E6D6),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Opacity(
                            opacity: i <= step ? 1 : .45,
                            child: ColorFiltered(
                              colorFilter: i <= step
                                  ? const ColorFilter.mode(
                                      Colors.transparent, BlendMode.dst)
                                  : const ColorFilter.matrix([
                                      .33, .33, .33, 0, 0,
                                      .33, .33, .33, 0, 0,
                                      .33, .33, .33, 0, 0,
                                      0, 0, 0, 1, 0
                                    ]),
                              child: Text(
                                steps[i].icon,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[i].label,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight:
                              i == step ? FontWeight.w700 : FontWeight.w500,
                          color: i <= step ? _ink : const Color(0xFFB8A58A),
                        ),
                      ),
                    ],
                  ),
                ),
              Positioned(
                left: x(step) - 40,
                top: -20,
                width: 80,
                height: 80,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: spark,
                    builder: (_, __) =>
                        CustomPaint(painter: _SparkPainter(spark.value)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final double t;

  _SparkPainter(this.t);

  @override
  void paint(Canvas canvas, Size s) {
    if (t == 0 || t == 1) return;
    final c = s.center(Offset.zero);
    for (int i = 0; i < 10; i++) {
      final a = i / 10 * 2 * math.pi, r = 10 + 30 * Curves.easeOut.transform(t);
      final p = c + Offset(math.cos(a) * r, math.sin(a) * r);
      final paint = Paint()
        ..color = (i.isEven ? _gold : _orange).withOpacity(1 - t);
      final path = Path()
        ..moveTo(p.dx, p.dy - 4)
        ..lineTo(p.dx + 1.2, p.dy - 1.2)
        ..lineTo(p.dx + 4, p.dy)
        ..lineTo(p.dx + 1.2, p.dy + 1.2)
        ..lineTo(p.dx, p.dy + 4)
        ..lineTo(p.dx - 1.2, p.dy + 1.2)
        ..lineTo(p.dx - 4, p.dy)
        ..lineTo(p.dx - 1.2, p.dy - 1.2)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter o) => o.t != t;
}

class _Entrance extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _Entrance({super.key, required this.child, required this.delay});

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
    return AnimatedBuilder(
      animation: a,
      child: widget.child,
      builder: (_, w) => Opacity(
        opacity: _c.value,
        child: Transform.translate(
          offset: Offset(0, 30 * (1 - a.value)),
          child: w,
        ),
      ),
    );
  }
}
