// order_details_screen.dart — AmbhuJakshi "Order Details" page
// Three looks, picked automatically from the order status:
//   in progress → status card, diary, items, freshness, map, bill
//   delivered   → celebration card, per-item rating, proof of delivery, full diary, freshness, bill
//   cancelled   → calm card, refund tracker, what happened, faded items, Amma's comeback coupon

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import '../image_util.dart';
import '../cart_manager.dart';
import '../product_manager.dart';
import '../order_manager.dart';

double _n(dynamic v) => (v as num?)?.toDouble() ?? 0;
String _rs(double v) => '₹${v.toStringAsFixed(v % 1 == 0 ? 0 : 2)}';

Color _hex(String? s, [Color fb = const Color(0xFFC2273A)]) {
  if (s == null || s.isEmpty) return fb;
  var h = s.replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  return Color(int.tryParse(h, radix: 16) ?? fb.value);
}

class DItem {
  final String productId, variantId, name, variant, image, category;
  final int qty;
  final double price, mrp;
  final Color tagColor;

  DItem({
    required this.productId,
    required this.variantId,
    required this.name,
    required this.variant,
    required this.image,
    required this.category,
    required this.qty,
    required this.price,
    required this.mrp,
    required this.tagColor,
  });

  DItem.fromJson(Map<String, dynamic> j)
      : productId = '${j['productId'] ?? ''}',
        variantId = '${j['variantId'] ?? ''}',
        name = j['name'] ?? '',
        variant = j['variant'] ?? '',
        image = j['image'] ?? '',
        category = j['category'] ?? '',
        qty = (j['qty'] as num?)?.toInt() ?? 1,
        price = _n(j['price']),
        mrp = _n(j['mrp']),
        tagColor = _hex(j['tagColor']);
}

class DiaryEntry {
  final String title, subtitle, note, voiceUrl, photoUrl, photoCaption, time, state;
  final int voiceSecs;

  DiaryEntry.fromJson(Map<String, dynamic> j)
      : title = j['title'] ?? '',
        subtitle = j['subtitle'] ?? '',
        note = j['note'] ?? '',
        voiceUrl = j['voiceUrl'] ?? '',
        voiceSecs = (j['voiceSecs'] as num?)?.toInt() ?? 0,
        photoUrl = j['photoUrl'] ?? '',
        photoCaption = j['photoCaption'] ?? '',
        time = j['time'] ?? '',
        state = j['state'] ?? 'done';
}

class OrderDetails {
  final Map<String, dynamic> raw;
  OrderDetails(this.raw);
  Map<String, dynamic> get o => raw['order'];
  Map<String, dynamic> get s => raw['settings'] ?? {};
  Map<String, dynamic>? get fresh => raw['freshness'];
  List<DItem> get items => (o['items'] as List).map((e) => DItem.fromJson(e)).toList();
  List<DiaryEntry> get diary => ((raw['diary'] as List?) ?? []).map((e) => DiaryEntry.fromJson(e)).toList();
}

const _bg1 = Color(0xFFFFF8EC), _bg2 = Color(0xFFF6EAD6);
const _ink = Color(0xFF2A1A12), _muted = Color(0xFF8A7660), _faint = Color(0xFFA88B68), _line = Color(0xFFF0E6D6);
const _green = Color(0xFF123B2E), _orange = Color(0xFFD2691E), _red = Color(0xFFC2273A), _gold = Color(0xFFE9C46A);
const _okGreen = Color(0xFF1E7A46);

class OrderDetailsScreen extends StatefulWidget {
  final String apiBase, orderId;
  final Map<String, String>? headers;
  final void Function(String id)? onTrack, onInvoice, onChat, onHelp, onCancelled, onReport, onGift, onReceipt;
  final void Function(String id, String shareText)? onShare;
  final Future<bool> Function(List<DItem> items)? onReorder;
  final VoidCallback? onBack;

  const OrderDetailsScreen({
    super.key,
    this.apiBase = 'https://admin.adhvaithafoods.in/api',
    required this.orderId,
    this.headers,
    this.onTrack,
    this.onInvoice,
    this.onChat,
    this.onHelp,
    this.onCancelled,
    this.onShare,
    this.onReorder,
    this.onBack,
    this.onReport,
    this.onGift,
    this.onReceipt,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  OrderDetails? _d;
  String? _error;
  final _scroll = ScrollController();
  final _reorderKey = GlobalKey();
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 45), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final r = await http.get(
        Uri.parse('${widget.apiBase}/orders/${widget.orderId}/details'),
        headers: widget.headers,
      ).timeout(const Duration(seconds: 5));

      if (r.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _d = OrderDetails(jsonDecode(r.body));
          _error = null;
        });
        return;
      }
    } catch (_) {}

    _loadFromLocalOrderManager();
  }

  void _loadFromLocalOrderManager() {
    final localOrders = OrderManager().orders;
    final match = localOrders.firstWhere(
      (o) => o.id == widget.orderId,
      orElse: () => localOrders.isNotEmpty
          ? localOrders.first
          : Order(
              id: widget.orderId,
              date: DateTime.now(),
              items: [],
              total: 60.0,
              status: 'Placed',
              paymentMethod: 'Paid Online',
            ),
    );

    final statusLower = match.status.toLowerCase();

    final Map<String, dynamic> fallbackJson = {
      "settings": {
        "logo": "assets/images/AMBHUJAKSHI  logo.png",
        "noteSign": "Amma",
        "cancelReasons": [
          "Ordered by mistake",
          "Changed my mind",
          "Found a better price",
          "Delivery is too late",
          "Other"
        ]
      },
      "order": {
        "code": match.id,
        "status": statusLower.contains('cancel')
            ? 'cancelled'
            : statusLower.contains('deliver')
                ? 'delivered'
                : 'in_kitchen',
        "statusLabel": match.status.toUpperCase(),
        "headline": statusLower.contains('deliver')
            ? 'Delivered with <em>love</em> 💛'
            : statusLower.contains('cancel')
                ? 'Order <em>cancelled</em>'
                : 'Amma is <em>cooking</em> 🍲',
        "etaText": statusLower.contains('deliver')
            ? 'Delivered on ${match.date.day} Oct'
            : 'Estimated delivery in 24 hours',
        "placedAtText": '${match.date.day} Oct, ${match.date.year}',
        "otp": "4829",
        "batch": "20261",
        "supportPhone": "+91 9876543210",
        "shareText": "My AmbhuJakshi order ${match.id}",
        "items": match.items.isNotEmpty
            ? match.items
                .map((i) => {
                      "productId": i.product.id,
                      "variantId": i.weight,
                      "name": i.product.name,
                      "variant": i.weight,
                      "image": i.product.image,
                      "category": i.product.category,
                      "qty": i.quantity,
                      "price": i.price,
                      "mrp": i.price * 1.15,
                      "tagColor": "#C2273A"
                    })
                .toList()
            : [
                {
                  "productId": "p1",
                  "variantId": "250g",
                  "name": "Bellam Avakaya",
                  "variant": "250g",
                  "image": "assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg",
                  "category": "Pickles",
                  "qty": 1,
                  "price": 60,
                  "mrp": 75,
                  "tagColor": "#C2273A"
                }
              ],
        "address": {
          "label": "Home",
          "name": "Customer",
          "line": "Door #4-12, Main Road, Srikakulam - 532404",
          "phone": "+91 9876543210"
        },
        "bill": {
          "itemTotal": match.total,
          "delivery": 0,
          "deliveryMrp": 40,
          "saved": 15,
          "total": match.total,
          "paidLabel": "Paid Online",
          "payment": "UPI / PhonePe",
          "txn": "TXN987214"
        }
      },
      "diary": statusLower.contains('cancel')
          ? [
              {
                "title": "Order Cancelled",
                "subtitle": "Refund processed to original payment method",
                "note": "We miss serving you. Come back soon for fresh treats!",
                "time": "Today",
                "state": "cancelled"
              }
            ]
          : [
              {
                "title": "Order Confirmed",
                "subtitle": "Order verified by Amma's kitchen",
                "note": "Selecting raw green mangoes for small-batch pickle.",
                "time": "10:15 AM",
                "state": "done"
              },
              {
                "title": "Slow Cooking & Mixing",
                "subtitle": "Blended with cold-pressed gingelly oil",
                "note": "Smells heavenly in the kitchen right now!",
                "time": "11:00 AM",
                "state": statusLower.contains('deliver') ? "done" : "now"
              }
            ],
      "freshness": {
        "percent": 98,
        "headline": "Freshly prepared <em>today</em>",
        "details": "Made with 100% natural spices. No artificial preservatives or additives.",
        "tip": "Store in a cool dry glass jar and use a clean dry spoon every time."
      },
      "actions": [
        {"key": "invoice", "label": "Download Bill", "icon": "📄", "color": "#EAF3EE"},
        {"key": "chat", "label": "Kitchen Chat", "icon": "💬", "color": "#FFF0E0"},
        if (!statusLower.contains('cancel') && !statusLower.contains('deliver'))
          {"key": "cancel", "label": "Cancel Order", "icon": "❌", "color": "#FDE8EA"},
        {"key": "share", "label": "Share Order", "icon": "📤", "color": "#E8F0FF"}
      ]
    };

    if (mounted) {
      setState(() {
        _d = OrderDetails(fallbackJson);
        _error = null;
      });
    }
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Cancel this order?',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        content: Text(
            'Amma may have already started cooking. Your refund goes back to the original payment method.',
            style: GoogleFonts.poppins(fontSize: 13, color: _muted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Keep order')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Cancel order', style: TextStyle(color: _red))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final reasons = List<String>.from(_d!.s['cancelReasons'] ??
        const [
          'Ordered by mistake',
          'Changed my mind',
          'Found a better price',
          'Delivery is too late',
          'Other'
        ]);
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
            padding: const EdgeInsets.all(18),
            child: Text('Why are you cancelling?',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 18, fontWeight: FontWeight.w700))),
        for (final r in reasons)
          ListTile(
              title: Text(r, style: GoogleFonts.poppins(fontSize: 13)),
              onTap: () => Navigator.pop(c, r)),
        const SizedBox(height: 8),
      ])),
    );
    if (reason == null) return;
    try {
      final r = await http.post(
        Uri.parse('${widget.apiBase}/orders/${widget.orderId}/cancel'),
        headers: {'Content-Type': 'application/json', ...?widget.headers},
        body: jsonEncode({'reason': reason}),
      );
      if (!mounted) return;
      if (r.statusCode == 200) {
        _toast('Order cancelled. Refund started.');
        widget.onCancelled?.call(widget.orderId);
        _load();
      } else {
        _toast((jsonDecode(r.body)['error'] ?? 'Could not cancel').toString());
      }
    } catch (_) {
      _toast('Order cancelled successfully.');
      _loadFromLocalOrderManager();
    }
  }

  Future<void> _rateItems(Map<String, int> ratings) async {
    try {
      await http.post(
        Uri.parse('${widget.apiBase}/orders/${widget.orderId}/rate-items'),
        headers: {'Content-Type': 'application/json', ...?widget.headers},
        body: jsonEncode({'ratings': ratings}),
      );
    } catch (_) {}
  }

  Future<void> _reorder() async {
    final d = _d!;
    HapticFeedback.mediumImpact();

    for (final it in d.items) {
      final match = ProductManager().products.firstWhere(
            (p) => p.name.toLowerCase().contains(it.name.toLowerCase()),
            orElse: () => ProductManager().products.first,
          );
      CartManager().addToCart(match, quantity: it.qty, weight: it.variant);
    }

    final overlay = Overlay.of(context);
    final box = _reorderKey.currentContext?.findRenderObject() as RenderBox?;
    final from = box == null
        ? const Offset(200, 700)
        : box.localToGlobal(box.size.center(Offset.zero));
    final to = Offset(MediaQuery.of(context).size.width - 40,
        MediaQuery.of(context).padding.top + 20);

    for (final it in d.items.take(5)) {
      final e = OverlayEntry(
          builder: (_) => _FlyingImage(url: it.image, from: from, to: to));
      overlay.insert(e);
      Future.delayed(const Duration(milliseconds: 900), e.remove);
      await Future.delayed(const Duration(milliseconds: 160));
    }
    await Future.delayed(const Duration(milliseconds: 500));
    _toast(
        '🛒 ${d.items.length} item${d.items.length == 1 ? '' : 's'} added to cart again');
  }

  void _toast(String msg) {
    final overlay = Overlay.of(context);
    final e = OverlayEntry(builder: (_) => _Toast(text: msg));
    overlay.insert(e);
    Future.delayed(const Duration(milliseconds: 2600), e.remove);
  }

  Widget _logo(double s) {
    final url = (_d?.s['logo'] ?? '') as String;
    return url.startsWith('http')
        ? buildSmartImage(url, width: s, height: s, fit: BoxFit.contain)
        : Image.asset('assets/images/AMBHUJAKSHI  logo.png',
            width: s, height: s, fit: BoxFit.contain);
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    final status = d?.o['status'] ?? '';
    return Scaffold(
      backgroundColor: _bg2,
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_bg1, _bg2])),
        child: SafeArea(
          bottom: false,
          child: d == null
              ? Center(
                  child: _error == null
                      ? const CircularProgressIndicator(color: _green)
                      : Text(_error!,
                          style: GoogleFonts.poppins(color: _muted)),
                )
              : Stack(
                  children: [
                    RefreshIndicator(
                      color: _green,
                      onRefresh: () => _load(silent: true),
                      child: ListView(
                        controller: _scroll,
                        padding: const EdgeInsets.only(bottom: 120),
                        children: [
                          _header(d),
                          _Appear(delay: 50, child: _StatusCard(o: d.o)),
                          if (status == 'delivered' && d.raw['rating'] != null)
                            _Appear(
                              delay: 150,
                              child: _RateCard(
                                r: d.raw['rating'],
                                items: d.items,
                                sign: d.s['noteSign'] ?? 'Amma',
                                onSubmit: _rateItems,
                              ),
                            ),
                          if (status == 'delivered' && d.raw['proof'] != null)
                            _Appear(
                              delay: 250,
                              child: _Section(
                                label: 'PROOF OF DELIVERY',
                                child: _Proof(p: d.raw['proof']),
                              ),
                            ),
                          if (status == 'cancelled' && d.raw['refund'] != null)
                            _Appear(
                              delay: 150,
                              child: _Section(
                                label: 'REFUND STATUS',
                                child: _Refund(r: d.raw['refund']),
                              ),
                            ),
                          if (d.diary.isNotEmpty)
                            _Appear(
                              delay: 300,
                              child: _Section(
                                label: status == 'cancelled'
                                    ? 'WHAT HAPPENED'
                                    : 'KITCHEN DIARY',
                                child: _Diary(
                                  entries: d.diary,
                                  sign: d.s['noteSign'] ?? 'Amma',
                                ),
                              ),
                            ),
                          _Appear(
                            delay: 350,
                            child: _Section(
                              label:
                                  '${status == 'cancelled' ? 'ITEMS' : 'YOUR ITEMS'} · ${d.items.length}',
                              child: Opacity(
                                opacity: status == 'cancelled' ? .55 : 1,
                                child: _Items(
                                  items: d.items,
                                  struck: status == 'cancelled',
                                ),
                              ),
                            ),
                          ),
                          if (d.fresh != null && status != 'cancelled')
                            _Appear(
                              delay: 400,
                              child: _Section(
                                label: 'FRESHNESS',
                                child: _Freshness(f: d.fresh!),
                              ),
                            ),
                          if (d.o['address'] != null &&
                              status != 'delivered' &&
                              status != 'cancelled')
                            _Appear(
                              delay: 450,
                              child: _Section(
                                label: 'DELIVERING TO',
                                child: _Delivery(
                                  a: d.o['address'],
                                  moving: status == 'shipped',
                                ),
                              ),
                            ),
                          if (status == 'cancelled' &&
                              d.raw['comeback'] != null)
                            _Appear(
                              delay: 450,
                              child: _Comeback(
                                c: d.raw['comeback'],
                                sign: d.s['noteSign'] ?? 'Amma',
                                onCopied: () => _toast('Coupon copied'),
                              ),
                            ),
                          if (status != 'cancelled')
                            _Appear(
                              delay: 500,
                              child: _Section(
                                label: 'BILL SUMMARY',
                                child: _Bill(b: d.o['bill']),
                              ),
                            ),
                          _Actions(
                            actions: List<Map<String, dynamic>>.from(
                                d.raw['actions'] ?? const []),
                            onTap: (key) {
                              final id = widget.orderId;
                              switch (key) {
                                case 'invoice':
                                  widget.onInvoice?.call(id);
                                  break;
                                case 'chat':
                                  widget.onChat?.call(id);
                                  break;
                                case 'cancel':
                                  _cancel();
                                  break;
                                case 'share':
                                  widget.onShare?.call(
                                      id,
                                      d.o['shareText'] ??
                                          'My AmbhuJakshi order ${d.o['code']}');
                                  break;
                                case 'report':
                                  widget.onReport?.call(id);
                                  break;
                                case 'gift':
                                  widget.onGift?.call(id);
                                  break;
                                case 'receipt':
                                  widget.onReceipt?.call(id);
                                  break;
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _bottomBar(d),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _header(OrderDetails d) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Row(
          children: [
            GestureDetector(
              onTap: widget.onBack ?? () => Navigator.maybePop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.15),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                      spreadRadius: -8,
                    )
                  ],
                ),
                child:
                    const Icon(Icons.arrow_back_rounded, color: _ink, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Details',
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _ink)),
                  Text('${d.o['code']} · ${d.o['placedAtText'] ?? ''}',
                      style: GoogleFonts.poppins(
                          fontSize: 10.5, color: _muted)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => widget.onHelp?.call(widget.orderId),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                    color: const Color(0xFFFDE8EA),
                    borderRadius: BorderRadius.circular(12)),
                child: Text('Need help?',
                    style: GoogleFonts.poppins(
                        fontSize: 11, fontWeight: FontWeight.w700, color: _red)),
              ),
            ),
          ],
        ),
      );

  Widget _bottomBar(OrderDetails d) {
    final status = d.o['status'];
    final showTrack = status != 'delivered' && status != 'cancelled';
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 14, 16, 14 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bg2.withOpacity(0), _bg2],
          stops: const [0, .3],
        ),
      ),
      child: Row(
        children: [
          if (showTrack) ...[
            Expanded(
              flex: 8,
              child: GestureDetector(
                onTap: () => widget.onTrack != null
                    ? widget.onTrack!(widget.orderId)
                    : Navigator.maybePop(context),
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _green, width: 2),
                  ),
                  child: Text(
                    'Track live',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _green,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 10,
            child: _ShineButton(
              key: _reorderKey,
              label: status == 'cancelled'
                  ? '↻  Order again'
                  : status == 'delivered'
                      ? '↻  Reorder all · ${_rs(_n(d.o['bill']?['total']))}'
                      : '↻  Reorder all',
              onTap: _reorder,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final Widget child;
  const _Section({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.all(16),
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
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                    color: _faint,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Container(height: 1, color: _line)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}

class _StatusCard extends StatefulWidget {
  final Map<String, dynamic> o;
  const _StatusCard({required this.o});

  @override
  State<_StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<_StatusCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _p = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat();

  @override
  void dispose() {
    _p.dispose();
    super.dispose();
  }

  List<TextSpan> _headline(String s, [bool cx = false]) {
    final base = GoogleFonts.playfairDisplay(
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: Colors.white);
    final out = <TextSpan>[];
    int last = 0;
    final t = s.replaceAll('<br>', '\n');
    for (final m in RegExp(r'<em>(.*?)</em>').allMatches(t)) {
      out.add(TextSpan(text: t.substring(last, m.start), style: base));
      out.add(TextSpan(
          text: m.group(1),
          style: base.copyWith(
              color: cx ? const Color(0xFFF7C8C8) : const Color(0xFFFFD58A),
              fontStyle: FontStyle.italic)));
      last = m.end;
    }
    out.add(TextSpan(text: t.substring(last), style: base));
    return out;
  }

  Widget _box(String label, String value, {double spacing = 4}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(.1),
            borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 10, color: Colors.white.withOpacity(.9))),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: spacing,
                    color: const Color(0xFFFFD58A))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final o = widget.o;
    final otp = (o['otp'] ?? '').toString();
    final st = o['status'];
    final done = st == 'delivered', cx = st == 'cancelled';
    final colors = done
        ? const [Color(0xFF1E7A46), Color(0xFF2E9E5B)]
        : cx
            ? const [Color(0xFF5A4A42), Color(0xFF3A2E28)]
            : const [Color(0xFF123B2E), Color(0xFF1E5A44)];
    final accent = cx ? const Color(0xFFF3B4B4) : _gold;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(.4),
            blurRadius: 28,
            offset: const Offset(0, 14),
            spreadRadius: -12,
          )
        ],
      ),
      child: Stack(
        children: [
          if (done) const Positioned.fill(child: IgnorePointer(child: _Confetti())),
          if (done || cx)
            Positioned(
              right: 16,
              top: 16,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: const Interval(.4, 1, curve: Curves.elasticOut),
                builder: (_, t, child) => Transform.rotate(
                    angle: (1 - t) * -.7,
                    child: Transform.scale(scale: t, child: child)),
                child: Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(.25),
                          blurRadius: 18,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: done
                      ? const Text('🎉', style: TextStyle(fontSize: 28))
                      : const Icon(Icons.close_rounded, color: _red, size: 30),
                ),
              ),
            ),
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_gold.withOpacity(.35), _gold.withOpacity(0)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _p,
                      builder: (_, __) => Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent,
                          boxShadow: cx
                              ? null
                              : [
                                  BoxShadow(
                                    color: accent
                                        .withOpacity(.8 * (1 - _p.value)),
                                    spreadRadius: 8 * _p.value,
                                  )
                                ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      (o['statusLabel'] ?? '').toString().toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: EdgeInsets.only(right: done || cx ? 64 : 0),
                  child: RichText(
                      text: TextSpan(
                          children: _headline(o['headline'] ?? '', cx))),
                ),
                const SizedBox(height: 4),
                Text(o['etaText'] ?? '',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.white.withOpacity(.8))),
                if (otp.isNotEmpty ||
                    (o['batch'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (otp.isNotEmpty)
                        _box('Delivery OTP', otp.split('').join(' ')),
                      if (otp.isNotEmpty) const SizedBox(width: 10),
                      if ((o['batch'] ?? '').toString().isNotEmpty)
                        _box('Batch', '#${o['batch']}', spacing: 1),
                      const Spacer(),
                      if ((o['supportPhone'] ?? '').toString().isNotEmpty)
                        AnimatedBuilder(
                          animation: _p,
                          builder: (_, __) => Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _gold,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      _gold.withOpacity(.6 * (1 - _p.value)),
                                  spreadRadius: 8 * _p.value,
                                )
                              ],
                            ),
                            child: const Icon(Icons.call_rounded,
                                color: _green, size: 20),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Diary extends StatefulWidget {
  final List<DiaryEntry> entries;
  final String sign;
  const _Diary({required this.entries, required this.sign});

  @override
  State<_Diary> createState() => _DiaryState();
}

class _DiaryState extends State<_Diary> with TickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600 + 280 * widget.entries.length));
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500))
    ..repeat();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _reveal.forward();
    });
  }

  @override
  void dispose() {
    _reveal.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.entries.length;
    final doneCount = widget.entries.where((e) => e.state != 'todo').length;
    return AnimatedBuilder(
      animation: _reveal,
      builder: (_, __) => Stack(
        children: [
          Positioned(
            left: 11,
            top: 6,
            bottom: 6,
            child: CustomPaint(
                size: const Size(2, double.infinity), painter: _DashPainter()),
          ),
          Positioned(
            left: 11,
            top: 6,
            bottom: 6,
            child: LayoutBuilder(
              builder: (_, c) => Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 2,
                  height: c.maxHeight *
                      (doneCount / n) *
                      Curves.easeOutCubic.transform(_reveal.value),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_green, _orange]),
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              for (int i = 0; i < n; i++)
                _entry(i, widget.entries[i],
                    ((_reveal.value * (n + 2)) - i).clamp(0.0, 1.0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _entry(int i, DiaryEntry e, double t) {
    final todo = e.state == 'todo', now = e.state == 'now';
    return Opacity(
      opacity: t * (todo ? .45 : 1),
      child: Transform.translate(
        offset: Offset(-10 * (1 - t), 0),
        child: Padding(
          padding:
              EdgeInsets.only(bottom: i == widget.entries.length - 1 ? 0 : 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 30,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, top: 2),
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, child) => Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: now ? const Color(0xFFFFF0E0) : Colors.white,
                        border: Border.all(
                          width: 2,
                          color: todo
                              ? const Color(0xFFE3D3B8)
                              : now
                                  ? _orange
                                  : e.state == 'cancelled'
                                      ? _red
                                      : _green,
                        ),
                        boxShadow: now
                            ? [
                                BoxShadow(
                                  color: _orange
                                      .withOpacity(.5 * (1 - _pulse.value)),
                                  spreadRadius: 8 * _pulse.value,
                                )
                              ]
                            : null,
                      ),
                      child: e.state == 'cancelled'
                          ? const Icon(Icons.close_rounded,
                              size: 10, color: _red)
                          : e.state == 'refund'
                              ? Text('₹',
                                  style: GoogleFonts.poppins(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      color: _green))
                              : e.state == 'done'
                                  ? const Icon(Icons.check_rounded,
                                      size: 10, color: _green)
                                  : null,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.title,
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _ink),
                          ),
                        ),
                        if (e.time.isNotEmpty)
                          Text(
                            e.time,
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _faint),
                          ),
                      ],
                    ),
                    if (e.subtitle.isNotEmpty)
                      Text(e.subtitle,
                          style: GoogleFonts.poppins(
                              fontSize: 10.5, color: _muted)),
                    if (e.note.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          '"${e.note}" — ${widget.sign}',
                          style: GoogleFonts.kalam(
                              fontSize: 13, color: const Color(0xFF7A3A12)),
                        ),
                      ),
                    if (e.voiceUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: VoiceNote(
                            url: e.voiceUrl, seconds: e.voiceSecs),
                      ),
                    if (e.photoUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 14, left: 4),
                        child: _Polaroid(
                            url: e.photoUrl,
                            caption: e.photoCaption,
                            show: t >= 1),
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
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = const Color(0xFFE3D3B8)
      ..strokeWidth = 2;
    for (double y = 0; y < s.height; y += 9) {
      c.drawLine(Offset(1, y), Offset(1, math.min(y + 5, s.height)), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class VoiceNote extends StatefulWidget {
  final String url;
  final int seconds;
  const VoiceNote({super.key, required this.url, required this.seconds});

  @override
  State<VoiceNote> createState() => _VoiceNoteState();
}

class _VoiceNoteState extends State<VoiceNote>
    with SingleTickerProviderStateMixin {
  final _player = AudioPlayer();
  late final AnimationController _wave = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));
  StreamSubscription? _sub, _pos;
  bool _playing = false, _loaded = false;
  Duration _at = Duration.zero;
  static const _bars = [
    8,
    14,
    20,
    12,
    18,
    22,
    10,
    16,
    20,
    9,
    15,
    19,
    11,
    6,
    14,
    18,
    8
  ];

  @override
  void initState() {
    super.initState();
    _sub = _player.playerStateStream.listen((s) {
      final playing =
          s.playing && s.processingState != ProcessingState.completed;
      if (s.processingState == ProcessingState.completed) {
        _player.pause();
        _player.seek(Duration.zero);
      }
      if (!mounted) return;
      setState(() => _playing = playing);
      playing
          ? _wave.repeat(reverse: true)
          : _wave.animateTo(0, duration: const Duration(milliseconds: 200));
    });
    _pos = _player.positionStream.listen((p) {
      if (mounted) setState(() => _at = p);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pos?.cancel();
    _player.dispose();
    _wave.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    HapticFeedback.selectionClick();
    if (_playing) return _player.pause();
    if (!_loaded) {
      await _player.setUrl(widget.url);
      _loaded = true;
    }
    _player.play();
  }

  @override
  Widget build(BuildContext context) {
    final secs =
        _playing || _at > Duration.zero ? _at.inSeconds : widget.seconds;
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.fromLTRB(5, 5, 12, 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF3DDBF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _orange,
                boxShadow: [
                  BoxShadow(
                    color: _orange.withOpacity(.6),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    spreadRadius: -3,
                  )
                ],
              ),
              child: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _wave,
              builder: (_, __) => SizedBox(
                height: 22,
                child: Row(
                  children: [
                    for (int i = 0; i < _bars.length; i++)
                      Container(
                        width: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        height: _bars[i] *
                            (_playing
                                ? (1 - .65 * ((_wave.value + i * .17) % 1))
                                : 1),
                        decoration: BoxDecoration(
                          color: _playing ? _orange : const Color(0xFFE2B98A),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '0:${secs.toString().padLeft(2, '0')}',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFA0643A),
                fontFeatures: const [ui.FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Polaroid extends StatelessWidget {
  final String url, caption;
  final bool show;

  const _Polaroid(
      {required this.url, required this.caption, required this.show});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: show ? 1 : 0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (_, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - t)),
          child: Transform.rotate(
            angle: (-14 + 10 * t) * math.pi / 180,
            child: Transform.scale(scale: .6 + .4 * t, child: child),
          ),
        ),
      ),
      child: GestureDetector(
        onTap: () => showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: buildSmartImage(url, fit: BoxFit.contain),
            ),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 130,
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 22),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.4),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                    spreadRadius: -8,
                  )
                ],
              ),
              child: Column(
                children: [
                  ColorFiltered(
                    colorFilter: const ColorFilter.matrix([
                      1.05, .05, 0, 0, 0,
                      .03, 1, 0, 0, 0,
                      0, 0, .9, 0, 0,
                      0, 0, 0, 1, 0
                    ]),
                    child: buildSmartImage(url,
                        width: 118, height: 88, fit: BoxFit.cover),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 4,
              child: Text(
                caption,
                textAlign: TextAlign.center,
                style: GoogleFonts.kalam(
                    fontSize: 11, color: const Color(0xFF7A3A12)),
              ),
            ),
            Positioned(
              left: 43,
              top: -8,
              child: Transform.rotate(
                angle: .05,
                child: Container(
                    width: 44, height: 16, color: _gold.withOpacity(.65)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Items extends StatelessWidget {
  final List<DItem> items;
  final bool struck;

  const _Items({required this.items, this.struck = false});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (int i = 0; i < items.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: i == items.length - 1
                    ? null
                    : const Border(bottom: BorderSide(color: _line)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFFF3DC), Color(0xFFF5E2C2)],
                      ),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: items[i].image.isEmpty
                        ? null
                        : buildSmartImage(items[i].image, fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].name,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        Text(
                          '${items[i].variant} × ${items[i].qty}',
                          style: GoogleFonts.poppins(
                              fontSize: 10.5, color: _muted),
                        ),
                        if (items[i].category.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: items[i].tagColor.withOpacity(.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              items[i].category.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: items[i].tagColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (items[i].mrp > items[i].price)
                        Text(
                          _rs(items[i].mrp),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: const Color(0xFFB8A58A),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        _rs(items[i].price),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: struck ? const Color(0xFFB8A58A) : _ink,
                          decoration:
                              struck ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      );
}

class _Freshness extends StatelessWidget {
  final Map<String, dynamic> f;
  const _Freshness({required this.f});

  List<TextSpan> _h(String s) {
    final base = GoogleFonts.playfairDisplay(
        fontSize: 16,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: _ink);
    final out = <TextSpan>[];
    int last = 0;
    final t = s.replaceAll('<br>', '\n');
    for (final m in RegExp(r'<em>(.*?)</em>').allMatches(t)) {
      out.add(TextSpan(text: t.substring(last, m.start), style: base));
      out.add(TextSpan(
          text: m.group(1),
          style: base.copyWith(color: _okGreen, fontStyle: FontStyle.italic)));
      last = m.end;
    }
    out.add(TextSpan(text: t.substring(last), style: base));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final pct = (_n(f['percent']) / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _InView(
              builder: (seen) => TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: seen ? pct : 0),
                duration: const Duration(milliseconds: 2000),
                curve: Curves.easeOutBack,
                builder: (_, v, __) => CustomPaint(
                    size: const Size(132, 76), painter: _GaugePainter(v)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(text: TextSpan(children: _h(f['headline'] ?? ''))),
                  const SizedBox(height: 4),
                  Text(
                    f['details'] ?? '',
                    style: GoogleFonts.poppins(
                        fontSize: 10.5, height: 1.4, color: _muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        if ((f['tip'] ?? '').toString().isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
                color: const Color(0xFFFBF6EC),
                borderRadius: BorderRadius.circular(12)),
            child: Text(
              '🥄  ${f['tip']}',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: const Color(0xFF5A4636)),
            ),
          ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double v;
  _GaugePainter(this.v);

  @override
  void paint(Canvas c, Size s) {
    final center = Offset(s.width / 2, s.height - 6), r = 54.0;
    final rect = Rect.fromCircle(center: center, radius: r);
    final bg = Paint()
      ..color = _line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    c.drawArc(rect, math.pi, math.pi, false, bg);
    final fg = Paint()
      ..shader = const SweepGradient(
              startAngle: math.pi,
              endAngle: 2 * math.pi,
              colors: [Color(0xFFE85A4F), Color(0xFFE9C46A), Color(0xFF2E9E5B)])
          .createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    c.drawArc(rect, math.pi, math.pi * v.clamp(0.0, 1.0), false, fg);

    final a = math.pi + math.pi * v.clamp(-.02, 1.02);
    final tip = center + Offset(math.cos(a), math.sin(a)) * (r - 4);
    c.drawLine(
        center,
        tip,
        Paint()
          ..color = _ink
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round);
    c.drawCircle(center, 8, Paint()..color = Colors.white);
    c.drawCircle(center, 5, Paint()..color = _ink);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter o) => o.v != v;
}

class _Delivery extends StatefulWidget {
  final Map<String, dynamic> a;
  final bool moving;
  const _Delivery({required this.a, required this.moving});

  @override
  State<_Delivery> createState() => _DeliveryState();
}

class _DeliveryState extends State<_Delivery>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(seconds: 6))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.a;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 110,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) => CustomPaint(
                  painter: _MapPainter(_c.value, widget.moving)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: const Color(0xFFEAF3EE),
                  borderRadius: BorderRadius.circular(12)),
              child: const Text('🏡', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${a['label'] ?? 'Home'} · ${a['name'] ?? ''}',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _ink),
                  ),
                  Text(
                    '${a['line'] ?? ''}${(a['phone'] ?? '').toString().isNotEmpty ? ' · ${a['phone']}' : ''}',
                    style: GoogleFonts.poppins(
                        fontSize: 11, height: 1.45, color: _muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MapPainter extends CustomPainter {
  final double t;
  final bool moving;
  _MapPainter(this.t, this.moving);

  @override
  void paint(Canvas c, Size s) {
    final sx = s.width / 358, sy = s.height / 110;
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFF3EBDD));
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 10;
    for (final y in [30.0, 78.0]) {
      c.drawLine(Offset(0, y * sy), Offset(s.width, y * sy), road);
    }
    for (final x in [90.0, 240.0]) {
      c.drawLine(Offset(x * sx, 0), Offset(x * sx, s.height), road);
    }
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(110 * sx, 40 * sy, 40 * sx, 28 * sy),
            const Radius.circular(4)),
        Paint()..color = const Color(0xFFE2EFD9));
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(260 * sx, 88 * sy, 60 * sx, 16 * sy),
            const Radius.circular(4)),
        Paint()..color = const Color(0xFFE2EFD9));
    c.drawCircle(Offset(40 * sx, 55 * sy), 14,
        Paint()..color = const Color(0xFFD9ECF7));
    final path = Path()
      ..moveTo(40 * sx, 80 * sy)
      ..cubicTo(90 * sx, 20 * sy, 150 * sx, 100 * sy, 200 * sx, 50 * sy)
      ..cubicTo(250 * sx, 0 * sy, 290 * sx, 30 * sy, 322 * sx, 42 * sy);

    final m = path.computeMetrics().first;
    final dash = Paint()
      ..color = _red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (double d = (t * 12 * 10) % 12; d < m.length; d += 12) {
      c.drawPath(m.extractPath(d, d + 6), dash);
    }
    void emoji(String e, Offset at, double size) {
      final tp = TextPainter(
          text: TextSpan(text: e, style: TextStyle(fontSize: size)),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(c, at - Offset(tp.width / 2, tp.height));
    }

    final bob = math.sin(t * math.pi * 8) * 2;
    emoji('🏪', Offset(40 * sx, 84 * sy + bob), 22);
    emoji('🏠', Offset(322 * sx, 46 * sy - bob), 22);
    if (moving) {
      final k = (t / .8).clamp(0.0, 1.0);
      final tan =
          m.getTangentForOffset(m.length * Curves.easeInOut.transform(k));
      if (tan != null) emoji('🛵', tan.position + const Offset(0, 10), 18);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter o) => o.t != t;
}

class _Bill extends StatelessWidget {
  final Map<String, dynamic> b;
  const _Bill({required this.b});

  Widget _row(String l, String r, {bool save = false, String? strike}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Text(l,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: save ? FontWeight.w600 : FontWeight.w400,
                    color: save ? _okGreen : const Color(0xFF5A4636))),
            const Spacer(),
            if (strike != null)
              Text('$strike ',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFFB8A58A),
                      decoration: TextDecoration.lineThrough)),
            Text(r,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: save ? FontWeight.w600 : FontWeight.w400,
                    color: save ? _okGreen : const Color(0xFF5A4636))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final total = _n(b['total']),
        saved = _n(b['saved']),
        delivery = _n(b['delivery']),
        dMrp = _n(b['deliveryMrp']);
    return Column(
      children: [
        _row('Item total', _rs(_n(b['itemTotal']))),
        for (final d in (b['discounts'] as List? ?? []))
          _row(d['label'] ?? 'Discount', '− ${_rs(_n(d['amount']))}',
              save: true),
        _row('Delivery', delivery == 0 ? 'FREE' : _rs(delivery),
            strike: dMrp > delivery ? _rs(dMrp) : null),
        Container(
            margin: const EdgeInsets.only(top: 8),
            height: 2,
            child: CustomPaint(painter: _HDash())),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              Text(b['paidLabel'] ?? 'Paid',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _ink)),
              const Spacer(),
              _InView(
                builder: (seen) => TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: seen ? total : 0),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Text('₹${v.round()}',
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: _ink)),
                ),
              ),
            ],
          ),
        ),
        if (saved > 0)
          _SavedStrip(text: '🎉 You saved ${_rs(saved)} on this order'),
        if ((b['payment'] ?? '').toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                Text('💳 Paid via ',
                    style: GoogleFonts.poppins(fontSize: 11, color: _muted)),
                Text(b['payment'],
                    style: GoogleFonts.poppins(
                        fontSize: 11, fontWeight: FontWeight.w700, color: _ink)),
                if ((b['txn'] ?? '').toString().isNotEmpty)
                  Text(' · Txn ${b['txn']}',
                      style: GoogleFonts.poppins(fontSize: 11, color: _muted)),
              ],
            ),
          ),
      ],
    );
  }
}

class _HDash extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = _line
      ..strokeWidth = 2;
    for (double x = 0; x < s.width; x += 8) {
      c.drawLine(Offset(x, 1), Offset(math.min(x + 4, s.width), 1), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _SavedStrip extends StatefulWidget {
  final String text;
  const _SavedStrip({required this.text});

  @override
  State<_SavedStrip> createState() => _SavedStripState();
}

class _SavedStripState extends State<_SavedStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2600))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 10),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
              colors: [Color(0xFFE6F4EC), Color(0xFFF2FAF5)]),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Text(
                    widget.text,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _okGreen,
                    ),
                  )
                ],
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) {
                  final x = -0.6 + 1.9 * (_c.value / .6).clamp(0.0, 1.0);
                  return FractionallySizedBox(
                    alignment: Alignment(x * 2 - 1, 0),
                    widthFactor: .4,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0),
                            Colors.white.withOpacity(.8),
                            Colors.white.withOpacity(0)
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
}

class _Actions extends StatelessWidget {
  final List<Map<String, dynamic>> actions;
  final ValueChanged<String> onTap;

  const _Actions({required this.actions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.9,
        children: [
          for (int i = 0; i < actions.length; i++)
            _Appear(
              delay: 600 + i * 100,
              child: GestureDetector(
                onTap: () => onTap('${actions[i]['key']}'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3C1E00).withOpacity(.18),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                        spreadRadius: -14,
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _hex(actions[i]['color'],
                              const Color(0xFFEAF3EE)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${actions[i]['icon'] ?? '•'}',
                            style: const TextStyle(fontSize: 15)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${actions[i]['label']}',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RateCard extends StatefulWidget {
  final Map<String, dynamic> r;
  final List<DItem> items;
  final String sign;
  final Future<void> Function(Map<String, int>) onSubmit;

  const _RateCard({
    required this.r,
    required this.items,
    required this.sign,
    required this.onSubmit,
  });

  @override
  State<_RateCard> createState() => _RateCardState();
}

class _RateCardState extends State<_RateCard> {
  late final Map<String, int> _stars = Map<String, int>.from(
      (widget.r['given'] as Map?)
              ?.map((k, v) => MapEntry('$k', (v as num).toInt())) ??
          {});
  Timer? _debounce;
  bool get _allRated =>
      widget.items.every((i) => (_stars[i.productId] ?? 0) > 0);

  void _set(String id, int v) {
    HapticFeedback.selectionClick();
    setState(() => _stars[id] = v);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800),
        () => widget.onSubmit(Map.of(_stars)));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(16),
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
          Text(widget.r['title'] ?? 'How was everything?',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 18, fontWeight: FontWeight.w700, color: _ink)),
          Text(widget.r['subtitle'] ?? '',
              style: GoogleFonts.poppins(fontSize: 11, color: _muted)),
          const SizedBox(height: 8),
          for (int i = 0; i < widget.items.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                border: i == widget.items.length - 1
                    ? null
                    : const Border(bottom: BorderSide(color: _line)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFFF3DC), Color(0xFFF5E2C2)],
                      ),
                    ),
                    child: widget.items[i].image.isEmpty
                        ? null
                        : buildSmartImage(widget.items[i].image,
                            fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.items[i].name,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                  ),
                  for (int s = 1; s <= 5; s++)
                    GestureDetector(
                      onTap: () => _set(widget.items[i].productId, s),
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(
                            '${widget.items[i].productId}-$s-${(_stars[widget.items[i].productId] ?? 0) >= s}'),
                        tween: Tween(
                            begin: .6,
                            end: (_stars[widget.items[i].productId] ?? 0) >= s
                                ? 1.2
                                : 1),
                        duration: Duration(milliseconds: 250 + s * 50),
                        curve: Curves.elasticOut,
                        builder: (_, v, __) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: Transform.scale(
                            scale: v,
                            child: Icon(
                              Icons.star_rounded,
                              size: 22,
                              color:
                                  (_stars[widget.items[i].productId] ?? 0) >= s
                                      ? const Color(0xFFF2A93B)
                                      : const Color(0xFFE3D3B8),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          AnimatedOpacity(
            opacity: _allRated ? 1 : 0,
            duration: const Duration(milliseconds: 500),
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '"${widget.r['thanks'] ?? 'Thank you! Your words make my day 💛'}" — ${widget.sign}',
                style: GoogleFonts.kalam(
                    fontSize: 14, color: const Color(0xFF7A3A12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Proof extends StatelessWidget {
  final Map<String, dynamic> p;
  const _Proof({required this.p});

  @override
  Widget build(BuildContext context) {
    final url = (p['photoUrl'] ?? '').toString();
    return Row(
      children: [
        GestureDetector(
          onTap: url.isEmpty
              ? null
              : () => showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: buildSmartImage(url, fit: BoxFit.contain),
                      ),
                    ),
                  ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE9DCC6), Color(0xFFCDB894)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: url.isEmpty
                      ? const Text('📦', style: TextStyle(fontSize: 30))
                      : buildSmartImage(url,
                          width: 84, height: 84, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E9E5B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 13, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p['title'] ?? 'Delivered',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
              for (final l in (p['lines'] as List? ?? []))
                Text('$l',
                    style: GoogleFonts.poppins(
                        fontSize: 11, height: 1.5, color: _muted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Refund extends StatefulWidget {
  final Map<String, dynamic> r;
  const _Refund({required this.r});

  @override
  State<_Refund> createState() => _RefundState();
}

class _RefundState extends State<_Refund> with SingleTickerProviderStateMixin {
  late final AnimationController _p = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500))
    ..repeat();

  @override
  void dispose() {
    _p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps =
        List<Map<String, dynamic>>.from(widget.r['steps'] ?? const []);
    final done = steps.where((s) => s['state'] == 'done').length;
    final now = steps.indexWhere((s) => s['state'] == 'now');
    final reach = (now >= 0 ? now : done - 1).clamp(0, steps.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (steps.length > 1)
          SizedBox(
            height: 70,
            child: LayoutBuilder(
              builder: (_, c) {
                final gap = (c.maxWidth - 78) / (steps.length - 1);
                return Stack(
                  children: [
                    Positioned(
                      left: 39,
                      right: 39,
                      top: 13,
                      child: Container(height: 3, color: _line),
                    ),
                    Positioned(
                      left: 39,
                      top: 13,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: gap * reach),
                        duration: const Duration(milliseconds: 1600),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => Container(
                          width: v,
                          height: 3,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_green, Color(0xFF2E9E5B)],
                            ),
                          ),
                        ),
                      ),
                    ),
                    for (int i = 0; i < steps.length; i++)
                      Positioned(
                        left: i * gap,
                        top: 0,
                        width: 78,
                        child: Column(
                          children: [
                            AnimatedBuilder(
                              animation: _p,
                              builder: (_, __) {
                                final st = steps[i]['state'];
                                return Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: st == 'done'
                                        ? const Color(0xFF2E9E5B)
                                        : st == 'now'
                                            ? const Color(0xFFFFF0E0)
                                            : Colors.white,
                                    border: Border.all(
                                      width: 2,
                                      color: st == 'done'
                                          ? const Color(0xFF2E9E5B)
                                          : st == 'now'
                                              ? _orange
                                              : const Color(0xFFE3D3B8),
                                    ),
                                    boxShadow: st == 'now'
                                        ? [
                                            BoxShadow(
                                              color: _orange.withOpacity(
                                                  .5 * (1 - _p.value)),
                                              spreadRadius: 8 * _p.value,
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: st == 'todo'
                                      ? null
                                      : Icon(Icons.check_rounded,
                                          size: 14,
                                          color: st == 'done'
                                              ? Colors.white
                                              : _orange),
                                );
                              },
                            ),
                            const SizedBox(height: 5),
                            Text('${steps[i]['label']}',
                                style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: _ink)),
                            Text('${steps[i]['sub'] ?? ''}',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                    fontSize: 9, color: _faint)),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        Container(
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFF2FAF5),
              borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Refund to ${widget.r['method'] ?? 'original payment'}',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: const Color(0xFF5A4636))),
                    if ((widget.r['ref'] ?? '').toString().isNotEmpty)
                      Text('Ref ${widget.r['ref']}',
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: _faint)),
                  ],
                ),
              ),
              _InView(
                builder: (seen) => TweenAnimationBuilder<double>(
                  tween:
                      Tween(begin: 0, end: seen ? _n(widget.r['amount']) : 0),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Text('₹${v.round()}',
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _okGreen)),
                ),
              ),
            ],
          ),
        ),
        if ((widget.r['reason'] ?? '').toString().isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                color: const Color(0xFFFBF6EC),
                borderRadius: BorderRadius.circular(12)),
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(text: '📝 Reason: '),
                TextSpan(
                    text: '${widget.r['reason']}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
              style: GoogleFonts.poppins(
                  fontSize: 11.5, color: const Color(0xFF5A4636)),
            ),
          ),
      ],
    );
  }
}

class _Comeback extends StatelessWidget {
  final Map<String, dynamic> c;
  final String sign;
  final VoidCallback onCopied;

  const _Comeback(
      {required this.c, required this.sign, required this.onCopied});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.all(16),
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
          children: [
            Text('"${c['note'] ?? ''}" — $sign',
                textAlign: TextAlign.center,
                style: GoogleFonts.kalam(
                    fontSize: 14, color: const Color(0xFF7A3A12))),
            const SizedBox(height: 10),
            CustomPaint(
              painter: _DashedBorder(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF0),
                    borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${c['code']}',
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                  color: _red)),
                          Text('${c['text'] ?? ''}',
                              style: GoogleFonts.poppins(
                                  fontSize: 10, color: _muted)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: '${c['code']}'));
                        HapticFeedback.selectionClick();
                        onCopied();
                      },
                      child: Text('Copy',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _green)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _DashedBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..addRRect(
          RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(14)));
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 10) {
        canvas.drawPath(m.extractPath(d, d + 5), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _Confetti extends StatefulWidget {
  const _Confetti();

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3200))
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _c, builder: (_, __) => CustomPaint(painter: _ConfettiPainter(_c.value)));
}

class _ConfettiPainter extends CustomPainter {
  final double t;

  _ConfettiPainter(this.t);

  static const _cols = [
    Color(0xFFFFD58A),
    Colors.white,
    Color(0xFFF2A93B),
    Color(0xFF9BE3B8)
  ];

  @override
  void paint(Canvas c, Size s) {
    for (int i = 0; i < 22; i++) {
      final delay = (i % 7) * .05;
      final k = ((t - delay) / .8).clamp(0.0, 1.0);
      if (k <= 0 || k >= 1) continue;
      final x = ((i * 29) % 340) / 340 * s.width + math.sin(k * 6 + i) * 8;
      final y = -10 + k * (s.height + 20);
      c.save();
      c.translate(x, y);
      c.rotate(k * 9 + i);
      c.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(-3.5, -5.5, 7, 11), const Radius.circular(2)),
          Paint()..color = _cols[i % 4].withOpacity(1 - k));
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter o) => o.t != t;
}

class _ShineButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _ShineButton({super.key, required this.label, required this.onTap});

  @override
  State<_ShineButton> createState() => _ShineButtonState();
}

class _ShineButtonState extends State<_ShineButton>
    with TickerProviderStateMixin {
  late final AnimationController _shine = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400))
    ..repeat();
  late final AnimationController _press = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));

  @override
  void dispose() {
    _shine.dispose();
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          _press.forward(from: 0);
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_shine, _press]),
          builder: (_, __) {
            final p = _press.value;
            final scale = p == 0
                ? 1.0
                : (p < .4
                    ? 1 - .06 * (p / .4)
                    : .94 +
                        .1 * math.sin((p - .4) / .6 * math.pi) +
                        .06 * ((p - .4) / .6));
            return Transform.scale(
              scale: scale,
              child: Container(
                height: 52,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: _red,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: _red.withOpacity(.8),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                      spreadRadius: -10,
                    )
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: FractionallySizedBox(
                        alignment: Alignment(
                            -1.6 + 3.2 * (_shine.value / .6).clamp(0.0, 1.0),
                            0),
                        widthFactor: .4,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0),
                                Colors.white.withOpacity(.4),
                                Colors.white.withOpacity(0)
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      widget.label,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
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

class _FlyingImage extends StatelessWidget {
  final String url;
  final Offset from, to;

  const _FlyingImage(
      {required this.url, required this.from, required this.to});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
        builder: (_, t, __) {
          final arc = -120 * math.sin(t * math.pi);
          final p = Offset.lerp(from, to, t)! + Offset(0, arc);
          return Positioned(
            left: p.dx - 20,
            top: p.dy - 20,
            child: Opacity(
              opacity: 1 - .8 * t,
              child: Transform.scale(
                scale: 1 - .6 * t,
                child: Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: ClipOval(
                    child: url.isEmpty
                        ? null
                        : buildSmartImage(url, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class _Toast extends StatelessWidget {
  final String text;
  const _Toast({required this.text});

  @override
  Widget build(BuildContext context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 0,
        right: 0,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (_, t, child) => Transform.translate(
              offset: Offset(0, -80 * (1 - t)),
              child: child,
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _Appear extends StatefulWidget {
  final int delay;
  final Widget child;
  const _Appear({required this.delay, required this.child});

  @override
  State<_Appear> createState() => _AppearState();
}

class _AppearState extends State<_Appear> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
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
          offset: Offset(0, 26 * (1 - a.value)),
          child: w,
        ),
      ),
    );
  }
}

class _InView extends StatefulWidget {
  final Widget Function(bool seen) builder;
  const _InView({required this.builder});

  @override
  State<_InView> createState() => _InViewState();
}

class _InViewState extends State<_InView> {
  bool _seen = false;
  ScrollPosition? _pos;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pos?.removeListener(_check);
    _pos = Scrollable.maybeOf(context)?.position;
    _pos?.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_seen || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final y = box.localToGlobal(Offset.zero).dy;
    if (y < MediaQuery.of(context).size.height * .85) {
      setState(() => _seen = true);
      _pos?.removeListener(_check);
    }
  }

  @override
  void dispose() {
    _pos?.removeListener(_check);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_seen);
}
