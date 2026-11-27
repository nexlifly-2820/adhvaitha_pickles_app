// royal_cart_screen.dart — AmbhuJakshi "Royal Thali Cart" (matches royal_thali_cart.mp4)
// Brass thali with product bowls (drop in + ×qty badge), cart total in the centre, free-delivery ring with 🛵 on the rim
// (green + confetti when unlocked), item cards with − n + and delete, Add more flavours, live freshness countdown,
// promo ticket, torn-paper bill with savings, slide-to-checkout.
// Data: cart_page_backend.js → GET /api/cart/page   (quantity changes go through CartService from cart_integration.dart)
//
// pubspec.yaml:  http: ^1.2.0   google_fonts: ^6.2.1
//
// Usage (as the Cart tab in AppShell pages):
//   RoyalCartScreen(
//     cart: cart,                                        // the same CartService used everywhere
//     onCheckout: (bill) => Navigator.pushNamed(context, '/checkout', arguments: bill),
//     onOpenProduct: (pid) => Navigator.pushNamed(context, '/product', arguments: pid),
//     onShop: () => goToShopTab(),                        // "Start shopping" when empty
//   )

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'cart_integration.dart';
import 'cart_manager.dart';
import 'product_lookup.dart';
import 'image_util.dart';
import 'widgets/cart_bar.dart' show cartScreensOpen;
import 'widgets/bundle_sheet.dart';
import 'widgets/cart_upsell.dart';
import 'widgets/offers_section.dart' show HomeOffersStore, HomeOffer;
import 'order_manager.dart';
import 'shop_catalog.dart';
import 'models.dart';

const _red = Color(0xFF9E1424), _maroon = Color(0xFF6A1220), _ink = Color(0xFF2A1A12), _bg = Color(0xFFFBF6EF);
const _green = Color(0xFF1E7A46), _muted = Color(0xFF9A8670), _faint = Color(0xFF9A7B58);
String _rs(num v) => '₹${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(2)}';
double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;

Widget _royalImage(String url, {double? width, double? height, BoxFit fit = BoxFit.contain}) {
  // url may hold several candidate photos separated by "|": try each in turn, exactly the way
  // the home sections load photos (buildSmartImage: admin site first, then the app's own assets)
  final List<String> c = url.split('|').map((String e) => e.trim()).where((String e) => e.isNotEmpty).toSet().toList();
  Widget out = SizedBox(width: width, height: height, child: const Icon(Icons.rice_bowl_rounded, color: Colors.brown));
  for (final String u in c.reversed) {
    out = buildSmartImage(u, width: width, height: height, fit: fit, errorWidget: out);
  }
  return out;
}

class RoyalCartScreen extends StatefulWidget {
  final CartService cart;
  final void Function(Map<String, dynamic> bill)? onCheckout;
  final ValueChanged<String>? onOpenProduct;
  final VoidCallback? onShop;
  /// back arrow: go back (or to Home when the cart is a bottom-bar tab)
  final VoidCallback? onBack;
  const RoyalCartScreen({super.key, required this.cart, this.onCheckout, this.onOpenProduct, this.onShop, this.onBack});
  @override
  State<RoyalCartScreen> createState() => _RoyalCartScreenState();
}

class _RoyalCartScreenState extends State<RoyalCartScreen> with TickerProviderStateMixin {
  Map<String, dynamic>? _p;
  bool _wasFree = false;
  final _promo = TextEditingController();
  late final AnimationController _confetti = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  Timer? _clock;
  Duration _left = Duration.zero;

  String get _api => widget.cart.apiBase;
  Map<String, String> get _h => {...?widget.cart.headers, 'Content-Type': 'application/json'};

  @override
  void initState() {
    super.initState();
    _load();
    HomeOffersStore.load().then((_) { if (mounted) _applyLocalCart(); });
    WidgetsBinding.instance.addPostFrameCallback((_) => cartScreensOpen.value++); // hide the floating "View cart" bar here
    widget.cart.addListener(_onCartChanged);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  int _lastCount = -1;
  void _onCartChanged() {
    if (widget.cart.bar.count != _lastCount) { _lastCount = widget.cart.bar.count; _load(); }
  }

  @override
  void dispose() {
    widget.cart.removeListener(_onCartChanged);
    final int open = cartScreensOpen.value - 1;
    WidgetsBinding.instance.addPostFrameCallback((_) => cartScreensOpen.value = open < 0 ? 0 : open);
    _clock?.cancel();
    _confetti.dispose();
    _promo.dispose();
    super.dispose();
  }

  void _applyLocalCart() {
    final managerItems = CartManager().items;
    final itemsList = managerItems.map((ci) => {
      "productId": ci.product.name,
      // unique per line (same product in two sizes, or two different combo boxes)
      "variantId": "${ci.weight}::${ci.chefNote ?? ''}",
      "name": ci.product.name,
      "label": comboSpec(ci) != null ? "${ci.weight} box · ${comboJars(ci).join(', ')}" : pairSpec(ci) != null ? "Pair · ${ci.weight}" : "${ci.weight} · ${ci.product.category}",
      "imageUrl": <String>[bestImageFor(ci.product.name, ci.product.image), ci.product.image, findCatalogProduct(ci.product.name)?.image ?? ''].join('|'),
      "price": ci.product.getRawPriceForWeight(ci.weight),
      "mrp": ci.product.getRawPriceForWeight(ci.weight) * 1.2,
      "qty": ci.quantity,
    }).toList();

    final sub = CartManager().subtotal;
    final freeAt = 500.0;
    final free = sub >= freeAt;

    if (mounted) {
      setState(() {
        _p = {
          "settings": { "dispatchCutoff": "14:00" },
          "bill": {
            "subtotal": sub,
            "freeDeliveryAt": freeAt,
            "freeDelivery": free,
            "deliveryFee": free ? 0 : 40,
            "baseDeliveryFee": 40,
            "discount": CartManager().discountAmount,
            "totalSaving": CartManager().discountAmount + (free ? 40 : 0),
            "total": CartManager().total,
            if (CartManager().appliedPromoCode.isNotEmpty)
              "promo": {
                "code": CartManager().appliedPromoCode,
                "title": HomeOffersStore.find(CartManager().appliedPromoCode)?.title ?? '',
              },
          },
          "items": itemsList,
          "suggestions": [
            {
              "productId": "idli_karam",
              "variantId": "v3",
              "name": "Idli Karam Podi",
              "imageUrl": "assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg",
              "price": 139
            }
          ],
          "offers": [
            for (final HomeOffer o in HomeOffersStore.items.value)
              {
                "code": o.code,
                "title": o.title,
                "note": CartManager().promoProblem(o.code) ?? o.sub,
                "eligible": CartManager().promoProblem(o.code) == null,
              }
          ]
        };
      });
    }
  }

  Future<void> _load() async {
    _applyLocalCart();
    try {
      final r = await http.get(Uri.parse('$_api/cart/page'), headers: widget.cart.headers);
      if (r.statusCode == 200 && mounted) {
        final j = jsonDecode(r.body) as Map<String, dynamic>;
        setState(() {
          if (_p != null) {
            if (j['suggestions'] != null) _p!['suggestions'] = j['suggestions'];
          }
        });
      }
    } catch (_) {}
    _tick();
  }

  void _tick() {
    final cut = (_p?['settings']?['dispatchCutoff'] ?? '14:00').toString().split(':');
    final now = DateTime.now();
    final c = DateTime(now.year, now.month, now.day, int.tryParse(cut[0]) ?? 14, int.tryParse(cut.length > 1 ? cut[1] : '0') ?? 0);
    if (mounted) setState(() => _left = c.isAfter(now) ? c.difference(now) : Duration.zero);
  }

  Future<void> _qty(Map it, int q) async {
    HapticFeedback.selectionClick();
    // remember the line so "UNDO" can put it back
    final CartItem? before = q <= 0 ? _lineFor(it) : null;
    final ({Product product, int qty, String weight, bool tempering, String? note})? saved = before == null
        ? null
        : (product: before.product, qty: before.quantity, weight: before.weight, tempering: before.isTemperingRequested, note: before.chefNote);
    final err = await widget.cart.setQty('${it['productId']}', '${it['variantId']}', q);
    if (err != null && mounted) return _snack(err);
    if (saved != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _ink,
          duration: const Duration(seconds: 4),
          content: Text('Removed ${saved.product.name}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: const Color(0xFFFFD27A),
            onPressed: () {
              CartManager().addToCart(saved.product, quantity: saved.qty, weight: saved.weight, isTemperingRequested: saved.tempering, chefNote: saved.note);
              _applyLocalCart();
            },
          ),
        ));
    }
  }

  /// the CartManager line behind a cart card
  CartItem? _lineFor(Map it) {
    for (final CartItem c in CartManager().items) {
      if (c.product.name == '${it['name']}' && '${c.weight}::${c.chefNote ?? ''}' == '${it['variantId']}') return c;
    }
    return null;
  }

  /// "250g ▾" → pick another size for this line
  void _sizeSheet(CartItem c) {
    final List<MapEntry<String, double>> sizes = c.product.weightPriceMap.entries.where((MapEntry<String, double> e) => e.value > 0).toList();
    if (sizes.length < 2) return;
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (BuildContext sc) => SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5D8C9), borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 12),
          Text('Choose size', style: GoogleFonts.rozhaOne(fontSize: 20, color: _maroon)),
          Text(c.product.name, style: GoogleFonts.poppins(fontSize: 12, color: _muted)),
          const SizedBox(height: 10),
          for (final MapEntry<String, double> e in sizes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.pop(sc);
                  CartManager().changeWeight(c, e.key);
                  _applyLocalCart();
                  HapticFeedback.mediumImpact();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: e.key == c.weight ? const Color(0xFFFFF3E0) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: e.key == c.weight ? _red : const Color(0xFFEADCCA), width: e.key == c.weight ? 1.6 : 1),
                  ),
                  child: Row(children: [
                    Icon(e.key == c.weight ? Icons.radio_button_checked : Icons.radio_button_off, size: 18, color: e.key == c.weight ? _red : _muted),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.key, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: _ink))),
                    Text(_rs(e.value), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
                  ]),
                ),
              ),
            ),
        ]),
      )),
    );
  }

  /// best coupon for this cart, with one tap to apply
  Widget _bestCoupon() {
    if (CartManager().appliedPromoCode.isNotEmpty) return const SizedBox.shrink();
    final best = CartManager().bestOffer();
    if (best == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(color: const Color(0xFFFFF3D6), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFD9A441), width: 1.3)),
        child: Row(children: [
          const Text('💡', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text.rich(TextSpan(children: [
            const TextSpan(text: 'Use '),
            TextSpan(text: best.offer.code, style: const TextStyle(color: _red, fontWeight: FontWeight.w800)),
            TextSpan(text: ' to save ${_rs(best.saving.roundToDouble())}'),
          ]), style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF5A3A00)))),
          GestureDetector(
            onTap: () => _applyPromo(best.offer.code),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: const Color(0xFF3A0612), borderRadius: BorderRadius.circular(10)),
              child: Text('APPLY', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFFFFD27A))),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _addSuggestion(Map s) async {
    HapticFeedback.lightImpact();
    final err = await widget.cart.setQty('${s['productId']}', '${s['variantId']}', 1);
    if (!mounted) return;
    if (err != null) return _snack(err);
    widget.cart.bar.added(context, name: s['name'], imageUrl: s['imageUrl'], price: 0, qty: 0);
  }

  // coupons = the admin "Home Offers" (same rules as checkout; the server checks again at payment)
  Future<void> _applyPromo(String code, {bool fromSheet = false}) async {
    final String c = code.trim().toUpperCase();
    if (c.isEmpty) return;
    final bool ok = CartManager().applyPromoCode(c);
    if (!mounted) return;
    if (!ok) return _snack(CartManager().promoProblem(c) ?? 'This coupon code is not valid');
    HapticFeedback.mediumImpact();
    if (fromSheet) Navigator.of(context).maybePop();
    _applyLocalCart();
    _snack('$c applied 🎉');
  }

  Future<void> _removePromo() async {
    CartManager().removePromoCode();
    _applyLocalCart();
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    final p = _p;
    if (p == null) return const Material(color: _bg, child: Center(child: CircularProgressIndicator(color: _red)));
    final items = (p['items'] as List);
    final bill = p['bill'] as Map<String, dynamic>;
    final top = MediaQuery.of(context).padding.top, bottom = MediaQuery.of(context).padding.bottom;
    return Material( // Material ancestor = no yellow underlines under text
      color: _bg,
      child: Stack(children: [
        RefreshIndicator(
          color: _red,
          onRefresh: _load,
          child: ListView(padding: EdgeInsets.fromLTRB(16, top + 12, 16, 110 + bottom), children: [
            _header(items.length),
            if (items.isEmpty) _empty() else ...[
              const SizedBox(height: 10),
              _thali(items, bill, p['settings']),
              _head('YOUR ITEMS'),
              for (final it in items) _item(it),
              const SizedBox(height: 4),
              _bestCoupon(),
              _ticket(bill), // promo code, right under the items
              // free delivery row · goes well with your order · browse by category
              CartUpsell(freeAt: _d(bill['freeDeliveryAt']) > 0 ? _d(bill['freeDeliveryAt']) : 500),
              const SizedBox(height: 12),
              _freshness(),
              const SizedBox(height: 16),
              _receipt(bill),
            ],
          ]),
        ),
        // confetti over the thali when free delivery unlocks
        Positioned(left: 0, right: 0, top: top + 60, height: 380, child: IgnorePointer(child: AnimatedBuilder(
          animation: _confetti, builder: (_, __) => CustomPaint(painter: _ConfettiPainter(_confetti.value))))),
        // soft fade so the list slides under the checkout bar
        if (items.isNotEmpty)
          Positioned(left: 0, right: 0, bottom: 0, height: 96 + bottom, child: IgnorePointer(child: DecoratedBox(
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [_bg.withOpacity(0), _bg.withOpacity(.92), _bg]))))),
        // docked just above the bottom bar
        if (items.isNotEmpty)
          Positioned(left: 12, right: 12, bottom: 12 + bottom, child: _SlideToCheckout(
            label: 'Slide to checkout · ${_rs(_d(bill['total']))}',
            onDone: () => widget.onCheckout?.call(bill),
          )),
      ]),
    );
  }

  Widget _header(int n) => Row(children: [
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFEAD7C4), width: 1.2)),
          elevation: 3,
          shadowColor: Colors.black26,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              HapticFeedback.selectionClick();
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.maybePop(context);
              }
            },
            child: const SizedBox(width: 44, height: 44, child: Icon(Icons.arrow_back_rounded, size: 22, color: _maroon)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Royal Cart', style: GoogleFonts.rozhaOne(fontSize: 26, height: 1, color: _maroon)),
          Text('Your favourite flavours, one step closer', style: GoogleFonts.poppins(fontSize: 11, color: _muted)),
        ])),
        if (n > 0)
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: const Color(0xFFFFE9EE), borderRadius: BorderRadius.circular(11)),
              child: Text('$n ${n == 1 ? 'item' : 'items'}', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, color: _red))),
      ]);

  Widget _head(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 20, 0, 10),
        child: Row(children: [
          Text(t, style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: _faint)),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1.5, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFEAD9BF), Colors.transparent])))),
        ]),
      );

  Widget _empty() => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(children: [
          SizedBox(width: 220, height: 220, child: CustomPaint(painter: _PlatePainter())),
          const SizedBox(height: 16),
          Text('Your thali is empty', style: GoogleFonts.rozhaOne(fontSize: 24, color: _maroon)),
          Text('Fill it with Andhra flavours', style: GoogleFonts.poppins(fontSize: 12, color: _muted)),
          const SizedBox(height: 16),
          _buyAgain(),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _red, padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: widget.onShop,
            child: Text('Start shopping', style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
          ),
        ]),
      );

  /// empty cart → their last order, one tap to put it all back
  Widget _buyAgain() {
    Order? last;
    for (final Order o in OrderManager().orders) {
      if (o.items.isNotEmpty && !RegExp('fail|pending', caseSensitive: false).hasMatch(o.status)) { last = o; break; }
    }
    if (last == null) return const SizedBox.shrink();
    final Order o = last;
    final String names = o.items.map((CartItem c) => c.product.name).join(', ');
    final CartItem first = o.items.first;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(left: 2, bottom: 8), child: Text('🔁  BUY AGAIN', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2.2, color: const Color(0xFF9C7A4A)))),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: const Color(0xFF501E00).withOpacity(.14), blurRadius: 24, offset: const Offset(0, 14), spreadRadius: -18)]),
          child: Row(children: [
            Container(width: 70, height: 70, padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: _tints[0], borderRadius: BorderRadius.circular(18)),
                child: _royalImage(<String>[bestImageFor(first.product.name, first.product.image), first.product.image].join('|'), fit: BoxFit.contain)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Last order · ${o.date.day} ${months[o.date.month - 1]}', style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: _ink)),
              Text(names, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11, color: _muted)),
              Text('${o.items.length} item${o.items.length > 1 ? 's' : ''}', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _faint)),
            ])),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _red, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => _reorder(o),
              child: Text('Reorder', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 12.5)),
            ),
          ]),
        ),
      ]),
    );
  }

  void _reorder(Order o) {
    HapticFeedback.mediumImpact();
    int added = 0;
    for (final CartItem c in o.items) {
      // today's price for normal products; combo boxes / pairs keep their bundle line
      Product p = c.product;
      if (!isBundle(c)) {
        final Product? live = ShopCatalog.product(c.product.name);
        if (live != null && live.weightPriceMap.containsKey(c.weight)) p = live;
      }
      CartManager().addToCart(p, quantity: c.quantity, weight: c.weight, isTemperingRequested: c.isTemperingRequested, chefNote: c.chefNote);
      added++;
    }
    _applyLocalCart();
    _snack(added > 0 ? 'Your last order is back in the cart 🫙' : 'Could not add those items');
  }

  // ───────── thali ─────────
  static const _slots = [Offset(150, 58), Offset(230, 108), Offset(230, 192), Offset(150, 242), Offset(70, 192), Offset(70, 108)];

  Widget _thali(List items, Map bill, Map s) {
    final sub = _d(bill['subtotal']), freeAt = _d(s['freeDeliveryAt']);
    final progress = freeAt <= 0 ? 1.0 : (sub / freeAt).clamp(0.0, 1.0);
    final free = bill['freeDelivery'] == true;
    return Column(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(colors: free ? const [_green, Color(0xFF0F4A2B)] : const [_red, Color(0xFF5A0818)])),
        child: Text.rich(free
            ? TextSpan(children: [const TextSpan(text: '🎉 Yay! '), TextSpan(text: 'FREE royal delivery', style: TextStyle(color: Color(0xFFC9F5DB), fontWeight: FontWeight.w800)), const TextSpan(text: ' unlocked')])
            : TextSpan(children: [const TextSpan(text: 'Add '), TextSpan(text: '${_rs(math.max(0, freeAt - sub))} more', style: const TextStyle(color: Color(0xFFFFD27A), fontWeight: FontWeight.w800)), const TextSpan(text: ' for FREE royal delivery')]),
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      const SizedBox(height: 8),
      SizedBox(height: 230, child: FittedBox(child: SizedBox(
        width: 300, height: 300,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: progress), duration: const Duration(milliseconds: 1200), curve: Curves.easeOutCubic,
          builder: (_, v, __) {
            final ang = -math.pi / 2 + v * 2 * math.pi;
            return Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(child: CustomPaint(painter: _RingPainter(v, free))),
              const Positioned(left: 20, top: 20, right: 20, bottom: 20, child: CustomPaint(painter: _PlatePainter())),
              for (int i = 0; i < math.min(items.length, 6); i++) _bowl(items[i], _slots[i]),
              Center(child: Container(
                width: 92, height: 92,
                decoration: BoxDecoration(color: const Color(0xFFFFF8E8), shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: const Color(0xFF502800).withOpacity(.5), blurRadius: 12, offset: const Offset(0, 6), spreadRadius: -4)]),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('CART TOTAL', style: GoogleFonts.poppins(fontSize: 7.5, fontWeight: FontWeight.w800, letterSpacing: 1, color: const Color(0xFFA88B68))),
                  Text(_rs(sub), style: GoogleFonts.rozhaOne(fontSize: 22, height: 1.1, color: _red)),
                  Text('${widget.cart.bar.count} items', style: GoogleFonts.poppins(fontSize: 9.5, color: const Color(0xFF7A5A44))),
                ]),
              )),
              Positioned(left: 150 + 140 * math.cos(ang) - 14, top: 150 + 140 * math.sin(ang) - 14,
                  child: const Text('🛵', style: TextStyle(fontSize: 22))),
            ]);
          },
        ),
      ))),
    ]);
  }

  Widget _bowl(Map it, Offset at) => Positioned(
        left: at.dx - 39, top: at.dy - 39,
        child: GestureDetector(
          onTap: () => _openItem(it),
          child: TweenAnimationBuilder<double>(
            key: ValueKey('${it['productId']}:${it['variantId']}:${it['qty']}'), // replays on add
            tween: Tween(begin: 0, end: 1), duration: const Duration(milliseconds: 700), curve: Curves.easeOutBack,
            builder: (_, v, child) => Opacity(opacity: v.clamp(0, 1), child: Transform.translate(offset: Offset(0, -120 * (1 - v)), child: child)),
            child: SizedBox(width: 78, height: 78, child: Stack(children: [
              Positioned.fill(child: Container(
                decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF3C1400).withOpacity(.45), blurRadius: 10, offset: const Offset(0, 8), spreadRadius: -4)]),
                child: _royalImage(it['imageUrl'] ?? '', fit: BoxFit.contain),
              )),
              Positioned(right: 0, top: 0, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: _red, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFFF8E8), width: 2)),
                child: Text('×${it['qty']}', style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
              )),
            ])),
          ),
        ),
      );

  // ───────── item cards ─────────
  static const _tints = [Color(0xFFFFE9EE), Color(0xFFE3F6F2), Color(0xFFFFF1D6), Color(0xFFECE6FF)];
  /// the cart line for a combo box / pairing (null for normal products)
  CartItem? _bundleFor(Map it) {
    for (final CartItem c in CartManager().items) {
      if (c.product.name == '${it['name']}' && '${c.weight}::${c.chefNote ?? ''}' == '${it['variantId']}' && isBundle(c)) return c;
    }
    return null;
  }

  void _openItem(Map it) {
    final CartItem? b = _bundleFor(it);
    if (b != null) {
      showBundleSheet(context, b);
    } else {
      widget.onOpenProduct?.call('${it['productId']}');
    }
  }

  Widget _item(Map it) {
    final i = (_p!['items'] as List).indexOf(it), q = it['qty'] as int;
    final bool bundle = _bundleFor(it) != null;
    return Dismissible(
      key: ValueKey('${it['productId']}:${it['variantId']}'),
      direction: DismissDirection.endToStart,
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 24), margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: const Color(0xFFFFE1E4), borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.delete_rounded, color: Color(0xFFC62828))),
      onDismissed: (_) => _qty(it, 0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: const Color(0xFF501E00).withOpacity(.14), blurRadius: 24, offset: const Offset(0, 14), spreadRadius: -18)]),
        child: Row(children: [
          GestureDetector(
            onTap: () => _openItem(it),
            child: Container(width: 88, height: 88, padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: _tints[i % _tints.length], borderRadius: BorderRadius.circular(20)),
                child: _royalImage(it['imageUrl'] ?? '', fit: BoxFit.contain)),
          ),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: bundle ? () => _openItem(it) : null, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(it['name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
            Text(it['label'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11, color: _muted)),
            if (bundle) Text("See what's inside ›", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: _red)),
            if (!bundle) Builder(builder: (_) {
              final CartItem? line = _lineFor(it);
              if (line == null || line.product.weightPriceMap.values.where((double v) => v > 0).length < 2) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 3),
                child: GestureDetector(
                  onTap: () => _sizeSheet(line),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0xFFEADCCA))),
                    child: Text('${line.weight} ▾', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: _maroon)),
                  ),
                ),
              );
            }),
            const SizedBox(height: 4),
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text(_rs(_d(it['price']) * q), style: GoogleFonts.rozhaOne(fontSize: 19)),
              if (_d(it['mrp']) > _d(it['price'])) ...[
                const SizedBox(width: 5),
                Text(_rs(_d(it['mrp']) * q), style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFFB8A58A), decoration: TextDecoration.lineThrough)),
              ],
            ]),
          ]))),
          SizedBox(height: 88, child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            GestureDetector(onTap: () => _qty(it, 0), child: Container(width: 30, height: 30, alignment: Alignment.center,
                decoration: BoxDecoration(color: const Color(0xFFFFF0F1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.delete_outline_rounded, size: 17, color: Color(0xFFC62828)))),
            Container(
              height: 34,
              decoration: BoxDecoration(color: _red, borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _stepBtn(Icons.remove_rounded, () => _qty(it, q - 1)),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (w, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(0, -.5), end: Offset.zero).animate(a), child: w)),
                  child: Text('$q', key: ValueKey(q), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                _stepBtn(Icons.add_rounded, () => _qty(it, q + 1)),
              ]),
            ),
          ])),
        ]),
      ),
    );
  }

  Widget _stepBtn(IconData i, VoidCallback onTap) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(width: 30, height: 34, child: Icon(i, size: 17, color: Colors.white)),
      );

  // ───────── add more flavours ─────────
  Widget _suggestions(List s) => SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal, itemCount: s.length, separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final it = s[i] as Map;
            final inCart = widget.cart.qtyOf('${it['productId']}', '${it['variantId']}') > 0;
            return GestureDetector(
              onTap: () => widget.onOpenProduct?.call('${it['productId']}'),
              child: Container(
                width: 118, padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: _tints[(i + 2) % _tints.length], borderRadius: BorderRadius.circular(20)),
                child: Stack(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(height: 70, width: double.infinity, child: _royalImage(it['imageUrl'] ?? '', fit: BoxFit.contain)),
                    const SizedBox(height: 3),
                    Padding(padding: const EdgeInsets.only(right: 26),
                        child: Text(it['name'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11.5, height: 1.2, fontWeight: FontWeight.w700))),
                    Text(_rs(_d(it['price'])), style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF7A5A44))),
                  ]),
                  Positioned(right: 0, bottom: 0, child: GestureDetector(
                    onTap: inCart ? null : () => _addSuggestion(it),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28, height: 28, alignment: Alignment.center,
                      decoration: BoxDecoration(color: inCart ? _green : Colors.white, borderRadius: BorderRadius.circular(9), border: Border.all(color: inCart ? _green : _red, width: 1.5)),
                      child: Icon(inCart ? Icons.check_rounded : Icons.add_rounded, size: 17, color: inCart ? Colors.white : _red),
                    ),
                  )),
                ]),
              ),
            );
          },
        ),
      );

  // ───────── freshness countdown ─────────
  Widget _freshness() {
    final open = _left > Duration.zero;
    String two(int n) => n.toString().padLeft(2, '0');
    final total = 8 * 3600; // ring shows the last 8 hours before cut-off
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [Color(0xFFE3F6F2), Color(0xFFC9EEE4)])),
      child: Row(children: [
        SizedBox(width: 46, height: 46, child: Stack(alignment: Alignment.center, children: [
          Container(decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          CircularProgressIndicator(value: open ? (_left.inSeconds / total).clamp(0.0, 1.0) : 0, strokeWidth: 4, color: _green, backgroundColor: const Color(0xFFC9EEE4)),
          const Text('⏱️', style: TextStyle(fontSize: 17)),
        ])),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('FRESHNESS GUARANTEED', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: .8, color: const Color(0xFF0F4A2B))),
          Text(open ? 'Order now for same-day dispatch' : 'Order now for tomorrow\'s first dispatch', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF2E6B50))),
        ])),
        if (open)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Text('${two(_left.inHours)}:${two(_left.inMinutes % 60)}:${two(_left.inSeconds % 60)}',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.white, fontFeatures: const [FontFeature.tabularFigures()])),
              Text('LEFT', style: GoogleFonts.poppins(fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: 1, color: Colors.white70)),
            ]),
          ),
      ]),
    );
  }

  // ───────── promo ticket ─────────
  Widget _ticket(Map bill) {
    final applied = bill['promo'] as Map?;
    return GestureDetector(
      onTap: applied == null ? _promoSheet : null,
      child: ClipPath(
        clipper: _TicketClipper(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(gradient: LinearGradient(colors: applied == null ? const [Color(0xFFFFE3A0), Color(0xFFF7B733)] : const [Color(0xFFC9EEE4), Color(0xFF7FD3B0)])),
          child: Row(children: [
            const Text('🎟️', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            CustomPaint(size: const Size(2, 42), painter: _DashV()),
            const SizedBox(width: 12),
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(applied == null ? 'Apply Royal Promo Code' : '${applied['code']} applied',
                  style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF3A2400))),
              Text(applied == null ? 'Tap to see available offers' : applied['title'] ?? '',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF3A2400).withOpacity(.75))),
            ])),
            GestureDetector(
              onTap: applied == null ? _promoSheet : _removePromo,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: const Color(0xFF3A0612), borderRadius: BorderRadius.circular(11)),
                child: Text(applied == null ? 'APPLY' : '✕ REMOVE', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFFFFD27A))),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _promoSheet() {
    final offers = (_p!['offers'] as List? ?? []);
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (c) => Container(
        padding: EdgeInsets.fromLTRB(18, 16, 18, 18 + MediaQuery.of(c).viewInsets.bottom),
        decoration: const BoxDecoration(color: _bg, borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFDCC9AE), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          Text('Royal offers', style: GoogleFonts.rozhaOne(fontSize: 22, color: _maroon)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(
              controller: _promo, textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(hintText: 'Enter promo code', filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
            )),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _red, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: () => _applyPromo(_promo.text.trim(), fromSheet: true),
              child: Text('Apply', style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
            ),
          ]),
          const SizedBox(height: 12),
          for (final o in offers)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF2E3C8))),
              child: Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(border: Border.all(color: _red, width: 1.3), borderRadius: BorderRadius.circular(8)),
                    child: Text(o['code'], style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1, color: _red))),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(o['title'] ?? '', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  if ((o['note'] ?? '').toString().isNotEmpty) Text(o['note'], style: GoogleFonts.poppins(fontSize: 10.5, color: _muted)),
                ])),
                TextButton(onPressed: o['eligible'] == true ? () => _applyPromo('${o['code']}', fromSheet: true) : null,
                    child: Text('APPLY', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: o['eligible'] == true ? _red : Colors.grey))),
              ]),
            ),
        ]),
      ),
    );
  }

  // ───────── bill receipt ─────────
  Widget _receipt(Map bill) {
    final fee = _d(bill['deliveryFee']), baseFee = _d(bill['baseDeliveryFee']), disc = _d(bill['discount']), saving = _d(bill['totalSaving']);
    Widget row(String l, Widget r) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
          Text(l, style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF5A4636))), const Spacer(), r]));
    final b = GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: _ink);
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Your bill 🧾', style: GoogleFonts.kalam(fontSize: 17, fontWeight: FontWeight.w700, color: _maroon)),
          const SizedBox(height: 4),
          row('Subtotal', Text(_rs(_d(bill['subtotal'])), style: b)),
          if (disc > 0) row('Promo (${bill['promo']?['code'] ?? ''})', Text('−${_rs(disc)}', style: b.copyWith(color: _green))),
          row('Delivery fee', fee == 0 && baseFee > 0
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_rs(baseFee), style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFB8A58A), decoration: TextDecoration.lineThrough)),
                  const SizedBox(width: 6),
                  Text('FREE', style: b.copyWith(color: _green, fontWeight: FontWeight.w800)),
                ])
              : Text(_rs(fee), style: b)),
          const SizedBox(height: 8),
          CustomPaint(size: const Size(double.infinity, 2), painter: _DashH()),
          const SizedBox(height: 10),
          Row(children: [
            Text('Total pay', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text(_rs(_d(bill['total'])), style: GoogleFonts.rozhaOne(fontSize: 26, color: _red)),
          ]),
          if (saving > 0)
            TweenAnimationBuilder<double>(
              key: ValueKey(saving), tween: Tween(begin: .7, end: 1), duration: const Duration(milliseconds: 450), curve: Curves.easeOutBack,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: double.infinity, margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(6), alignment: Alignment.center,
                decoration: BoxDecoration(color: const Color(0xFFE3F6F2), borderRadius: BorderRadius.circular(10)),
                child: Text('🎉 You\'re saving ${_rs(saving)} on this order', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: _green)),
              ),
            ),
        ]),
      ),
      SizedBox(height: 10, width: double.infinity, child: CustomPaint(painter: _ZigZag())),
    ]);
  }
}

// ───────────────────────────── slide to checkout ─────────────────────────────
class _SlideToCheckout extends StatefulWidget {
  final String label;
  final VoidCallback onDone;
  const _SlideToCheckout({required this.label, required this.onDone});
  @override
  State<_SlideToCheckout> createState() => _SlideToCheckoutState();
}

class _SlideToCheckoutState extends State<_SlideToCheckout> with TickerProviderStateMixin {
  double _x = 0;
  bool _done = false;
  late final AnimationController _back = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
  late final AnimationController _shine = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();

  @override
  void dispose() { _back.dispose(); _shine.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, c) {
        final max = c.maxWidth - 64;
        return Container(
          height: 62, clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(colors: [Color(0xFFB3122A), Color(0xFF8A0F22), Color(0xFF5A0818)], stops: [0, .55, 1]),
              boxShadow: [BoxShadow(color: const Color(0xFF780A1E).withOpacity(.8), blurRadius: 30, offset: const Offset(0, 18), spreadRadius: -14)]),
          child: Stack(children: [
            AnimatedBuilder(animation: _shine, builder: (_, __) {
              final k = _shine.value / .4;
              return k > 1 ? const SizedBox.shrink() : Positioned.fill(child: FractionallySizedBox(
                  alignment: Alignment(-1.6 + 3.2 * k, 0), widthFactor: .28,
                  child: Transform(transform: Matrix4.skewX(-.35), child: const DecoratedBox(decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.transparent, Color(0x40FFFFFF), Colors.transparent]))))));
            }),
            Center(child: Opacity(
              opacity: (1 - _x / max * 1.4).clamp(0.0, 1.0),
              child: Padding(padding: const EdgeInsets.only(left: 60), child: Text('${widget.label}  »»',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFFFFE3C2)))),
            )),
            Positioned(
              left: 6 + _x, top: 6,
              child: GestureDetector(
                onHorizontalDragUpdate: _done ? null : (d) => setState(() => _x = (_x + d.delta.dx).clamp(0, max)),
                onHorizontalDragEnd: _done ? null : (_) {
                  if (_x > max * .8) {
                    HapticFeedback.heavyImpact();
                    setState(() { _x = max; _done = true; });
                    widget.onDone();
                    Future.delayed(const Duration(milliseconds: 900), () { if (mounted) setState(() { _x = 0; _done = false; }); });
                  } else {
                    final from = _x;
                    _back.forward(from: 0);
                    _back.addListener(() { if (mounted) setState(() => _x = from * (1 - Curves.easeOut.transform(_back.value))); });
                  }
                },
                child: Container(
                  width: 52, height: 50, alignment: Alignment.center,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(15),
                      gradient: const LinearGradient(colors: [Color(0xFFFFE3A0), Color(0xFFF2A93B)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                  child: Text(_done ? '✓' : '🛵', style: const TextStyle(fontSize: 24, color: Color(0xFF3A0612), fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ]),
        );
      });
}

// ───────────────────────────── painters ─────────────────────────────
class _PlatePainter extends CustomPainter {
  const _PlatePainter();
  @override
  void paint(Canvas c, Size s) {
    final o = s.center(Offset.zero), r = s.shortestSide / 2;
    c.drawCircle(o + const Offset(0, 14), r * .96, Paint()..color = const Color(0xFF5A2800).withOpacity(.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
    c.drawCircle(o, r, Paint()..shader = const RadialGradient(center: Alignment(-.3, -.4), colors: [
      Color(0xFFFFF1C4), Color(0xFFE9C36A), Color(0xFFC9952F), Color(0xFFA8741C), Color(0xFFD9A441), Color(0xFF8A5A12)], stops: [0, .3, .62, .8, .92, 1])
        .createShader(Rect.fromCircle(center: o, radius: r)));
    c.drawCircle(o, r - 6, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = const Color(0xFFFFECB4).withOpacity(.4));
    final inner = r - 34;
    c.drawCircle(o, inner, Paint()..shader = const RadialGradient(center: Alignment(-.2, -.3), colors: [Color(0xFFF3D58A), Color(0xFFC9952F), Color(0xFFB07D22)], stops: [0, .7, 1])
        .createShader(Rect.fromCircle(center: o, radius: inner)));
    c.drawCircle(o, inner, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = const Color(0xFF7A4A0A).withOpacity(.35));
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _RingPainter extends CustomPainter {
  final double v;
  final bool free;
  _RingPainter(this.v, this.free);
  @override
  void paint(Canvas c, Size s) {
    final rect = Rect.fromCircle(center: s.center(Offset.zero), radius: 140);
    c.drawArc(rect, 0, 2 * math.pi, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 9..color = const Color(0xFFEAD9BF));
    if (v <= 0) return;
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 9..strokeCap = StrokeCap.round;
    p.shader = free
        ? null
        : const SweepGradient(startAngle: -math.pi / 2, endAngle: 3 * math.pi / 2, colors: [Color(0xFFF7B733), Color(0xFFE8486B)], transform: GradientRotation(-math.pi / 2)).createShader(rect);
    if (free) p.color = _green;
    c.drawArc(rect, -math.pi / 2, 2 * math.pi * v, false, p);
  }
  @override
  bool shouldRepaint(covariant _RingPainter o) => o.v != v || o.free != free;
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  _ConfettiPainter(this.t);
  static final _rnd = math.Random(7);
  static final _bits = List.generate(46, (_) => [_rnd.nextDouble(), _rnd.nextDouble(), _rnd.nextDouble(), _rnd.nextInt(5).toDouble()]);
  static const _cols = [Color(0xFFFFD27A), Color(0xFF9EE6BC), Color(0xFFFF6B8A), Color(0xFFA47BFF), Color(0xFF4FA3F7)];
  @override
  void paint(Canvas c, Size s) {
    if (t == 0 || t == 1) return;
    for (final b in _bits) {
      final k = ((t - b[2] * .2) / .8).clamp(0.0, 1.0);
      if (k <= 0) continue;
      final x = b[0] * s.width + math.sin(k * 6 + b[1] * 6) * 18, y = -10 + k * (s.height * (.6 + b[1] * .4));
      c.save();
      c.translate(x, y);
      c.rotate(k * 12 * (b[1] - .5));
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-3.5, -5, 7, 10), const Radius.circular(2)),
          Paint()..color = _cols[b[3].toInt()].withOpacity(1 - k));
      c.restore();
    }
  }
  @override
  bool shouldRepaint(covariant _ConfettiPainter o) => o.t != t;
}

class _TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final p = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(16)));
    final holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, s.height / 2), radius: 9))
      ..addOval(Rect.fromCircle(center: Offset(s.width, s.height / 2), radius: 9));
    return Path.combine(PathOperation.difference, p, holes);
  }
  @override
  bool shouldReclip(covariant CustomClipper<Path> o) => false;
}

class _ZigZag extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Path()..moveTo(0, 0);
    for (double x = 0; x < s.width; x += 14) { p..lineTo(x + 7, s.height)..lineTo(math.min(x + 14, s.width), 0); }
    p.close();
    c.drawPath(p, Paint()..color = Colors.white);
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _DashH extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = const Color(0xFFE6D6BC)..strokeWidth = 1.5;
    for (double x = 0; x < s.width; x += 8) { c.drawLine(Offset(x, 1), Offset(math.min(x + 4, s.width), 1), p); }
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _DashV extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = const Color(0xFF3A2400).withOpacity(.35)..strokeWidth = 1.5;
    for (double y = 0; y < s.height; y += 7) { c.drawLine(Offset(1, y), Offset(1, math.min(y + 4, s.height)), p); }
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
