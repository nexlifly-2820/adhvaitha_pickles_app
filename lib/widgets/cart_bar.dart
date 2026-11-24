// cart_bar.dart — AmbhuJakshi floating "added to cart" bar (matches cart_bar.mp4)
// The product photo flies from the Add button into the bar, the bar slides up (first item), bounces + shines,
// product circles stack (max 3), item count & total tick up, green "✓ … added" toast, "View cart ›" nudges.
//
// pubspec.yaml:  google_fonts: ^6.2.1
//
// 1) Create one controller for the whole app (e.g. in main.dart or your cart provider):
//      final cartBar = CartBarController();
//    Keep it in sync with your real cart after any change (e.g. after API reply / app start):
//      cartBar.sync(count: cart.totalQty, total: cart.total, images: cart.items.map((e) => e.imageUrl).toList());
//
// 2) Put the bar above your bottom navigation, inside the main Scaffold body Stack:
//      Stack(children: [
//        pages[currentTab],
//        Positioned(left: 12, right: 12, bottom: 90, child: CartBar(controller: cartBar, onViewCart: () => goToCartTab())),
//      ])
//
// 3) When a product is added (any screen), give the image's GlobalKey so it can fly:
//      final imgKey = GlobalKey();               // put on the product Image: Image.network(url, key: imgKey)
//      await cart.add(product.id, variantId, 1); // your existing cart call
//      cartBar.added(context, name: product.name, imageUrl: product.image, price: product.price, fromKey: imgKey);
//    When quantity is reduced/removed, just call cartBar.sync(...) again — the bar hides itself when count is 0.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

String _assetGuess(String url) {
  final String f = url.split('?').first.split('/').last;
  return f.isEmpty ? 'assets/images/_none_' : 'assets/images/$f';
}

Widget _cartBarImage(String url, {double? width, double? height, BoxFit fit = BoxFit.contain}) {
  if (url.isEmpty) return SizedBox(width: width, height: height, child: const Icon(Icons.rice_bowl_rounded, color: Colors.white54));
  
  if (url.startsWith('assets/')) {
    return Image.asset(url, width: width, height: height, fit: fit,
        errorBuilder: (_, __, ___) => Image.asset(_assetGuess(url), width: width, height: height, fit: fit,
            errorBuilder: (_, __, ___) => SizedBox(width: width, height: height, child: const Icon(Icons.rice_bowl_rounded, color: Colors.white54))));
  }
  
  if (!url.startsWith('http')) {
    final fixedUrl = url.startsWith('/') ? 'https://admin.adhvaithafoods.in$url' : 'https://admin.adhvaithafoods.in/$url';
    return Image.network(fixedUrl, width: width, height: height, fit: fit, gaplessPlayback: true,
        errorBuilder: (_, __, ___) => Image.asset(_assetGuess(url), width: width, height: height, fit: fit,
            errorBuilder: (_, __, ___) => SizedBox(width: width, height: height, child: const Icon(Icons.rice_bowl_rounded, color: Colors.white54))));
  }

  return Image.network(url, width: width, height: height, fit: fit, gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Image.asset(_assetGuess(url), width: width, height: height, fit: fit,
          errorBuilder: (_, __, ___) => SizedBox(width: width, height: height, child: const Icon(Icons.rice_bowl_rounded, color: Colors.white54))));
}

class CartBarController extends ChangeNotifier {
  int count = 0;
  double total = 0;
  final List<String> images = []; // newest last, unique
  String? toast;
  int _pulse = 0; // increments on every add → bounce/shine
  final GlobalKey _thumbsKey = GlobalKey();

  void sync({required int count, required double total, required List<String> images}) {
    this.count = count;
    this.total = total;
    this.images
      ..clear()
      ..addAll(images.toSet());
    notifyListeners();
  }

  Future<void> added(BuildContext context, {required String name, required String imageUrl, required double price, GlobalKey? fromKey, int qty = 1}) async {
    HapticFeedback.lightImpact();
    final wasHidden = count == 0;
    if (wasHidden) {
      // show the bar first, so the photo has somewhere to land
      count = qty;
      total = price * qty;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 280));
    }
    if (fromKey != null && context.mounted) await _fly(context, imageUrl, fromKey);
    if (!wasHidden) {
      count += qty;
      total += price * qty;
    }
    images.remove(imageUrl);
    images.add(imageUrl);
    toast = '✓ $name added';
    _pulse++;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 1300), () {
      toast = null;
      notifyListeners();
    });
  }

  Future<void> _fly(BuildContext context, String url, GlobalKey from) async {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final fromBox = from.currentContext?.findRenderObject() as RenderBox?;
    final toBox = _thumbsKey.currentContext?.findRenderObject() as RenderBox?;
    if (overlay == null || fromBox == null || toBox == null || !fromBox.attached || !toBox.attached) return;
    final start = fromBox.localToGlobal(Offset.zero) & fromBox.size;
    final slot = math.min(images.length, 2);
    final end = toBox.localToGlobal(Offset(slot * 28.0 + 21, 21));
    final ctrl = AnimationController(vsync: Navigator.of(context), duration: const Duration(milliseconds: 650));
    final entry = OverlayEntry(builder: (_) => AnimatedBuilder(
          animation: ctrl,
          builder: (_, __) {
            final k = ctrl.value, e = Curves.easeInOutCubic.transform(k);
            final size = start.shortestSide * (1 - .55 * k);
            final c = Offset.lerp(start.center, end, e)! - Offset(0, 140 * math.sin(math.pi * k)); // arc
            return Positioned(
              left: c.dx - size / 2, top: c.dy - size / 2, width: size, height: size,
              child: IgnorePointer(child: Transform.rotate(angle: k * 3.5, child: _cartBarImage(url, fit: BoxFit.contain))),
            );
          },
        ));
    overlay.insert(entry);
    await ctrl.forward();
    entry.remove();
    ctrl.dispose();
  }
}

class CartBar extends StatefulWidget {
  final CartBarController controller;
  final VoidCallback onViewCart;
  const CartBar({super.key, required this.controller, required this.onViewCart});
  @override
  State<CartBar> createState() => _CartBarState();
}

class _CartBarState extends State<CartBar> with TickerProviderStateMixin {
  late final AnimationController _bump = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _nudge = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  int _lastPulse = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  void _onChange() {
    if (widget.controller._pulse != _lastPulse) {
      _lastPulse = widget.controller._pulse;
      _bump.forward(from: 0);
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    _bump.dispose();
    _nudge.dispose();
    super.dispose();
  }

  String _rs(double v) => '₹${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final show = c.count > 0;
    final thumbs = c.images.reversed.take(3).toList().reversed.toList();
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // toast
      AnimatedSlide(
        offset: c.toast == null ? const Offset(0, .6) : Offset.zero,
        duration: const Duration(milliseconds: 350),
        child: AnimatedOpacity(
          opacity: c.toast == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(color: const Color(0xFF1E7A46), borderRadius: BorderRadius.circular(12)),
            child: Text(c.toast ?? '', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ),
      AnimatedSlide(
        offset: show ? Offset.zero : const Offset(0, 2.4),
        duration: const Duration(milliseconds: 600),
        curve: show ? Curves.easeOutBack : Curves.easeInCubic,
        child: AnimatedBuilder(
          animation: _bump,
          builder: (_, child) {
            final b = _bump.value;
            final scale = b < .5 ? 1 + .05 * math.sin(b / .5 * math.pi) : 1 - .02 * math.sin((b - .5) / .5 * math.pi);
            return Transform.scale(scale: scale, child: child);
          },
          child: GestureDetector(
            onTap: widget.onViewCart,
            child: Container(
              height: 70,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(colors: [Color(0xFFB3122A), Color(0xFF8A0F22), Color(0xFF5A0818)], stops: [0, .55, 1]),
                border: Border.all(color: const Color(0x59FFD27A), width: 1.5),
                boxShadow: [BoxShadow(color: const Color(0xFF780A1E).withOpacity(.8), blurRadius: 30, offset: const Offset(0, 18), spreadRadius: -14)],
              ),
              child: Stack(children: [
                // shine sweep on every add
                AnimatedBuilder(
                  animation: _bump,
                  builder: (_, __) => _bump.value == 0 || _bump.value == 1
                      ? const SizedBox.shrink()
                      : Positioned.fill(child: FractionallySizedBox(
                          alignment: Alignment(-1.6 + 3.2 * _bump.value, 0), widthFactor: .3,
                          child: Transform(transform: Matrix4.skewX(-.35), child: const DecoratedBox(decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Colors.transparent, Color(0x40FFFFFF), Colors.transparent])))),
                        )),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 10, 0),
                  child: Row(children: [
                    SizedBox(
                      key: c._thumbsKey,
                      height: 42,
                      width: thumbs.isEmpty ? 42 : 42 + (thumbs.length - 1) * 28.0,
                      child: Stack(children: [
                        for (int i = 0; i < thumbs.length; i++)
                          Positioned(left: i * 28.0, child: TweenAnimationBuilder<double>(
                            key: ValueKey(thumbs[i]),
                            tween: Tween(begin: 0, end: 1), duration: const Duration(milliseconds: 450), curve: Curves.easeOutBack,
                            builder: (_, v, child) => Transform.scale(scale: v, child: child),
                            child: Container(
                              width: 42, height: 42, padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: const Color(0xFFFFF4DC), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF8A0F22), width: 2.5)),
                              child: _cartBarImage(thumbs[i], fit: BoxFit.contain),
                            ),
                          )),
                      ]),
                    ),
                    const SizedBox(width: 10),
                    Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${c.count} ${c.count == 1 ? 'item' : 'items'} in cart',
                          style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFFFFD9A8))),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        transitionBuilder: (w, a) => FadeTransition(opacity: a, child: SlideTransition(
                            position: Tween(begin: const Offset(0, -.6), end: Offset.zero).animate(a), child: w)),
                        child: Text(_rs(c.total), key: ValueKey(c.total),
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ]),
                    const Spacer(),
                    Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: const LinearGradient(colors: [Color(0xFFFFE3A0), Color(0xFFF2A93B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.5), blurRadius: 12, offset: const Offset(0, 6), spreadRadius: -6)],
                      ),
                      child: Row(children: [
                        Text('View cart', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF3A0612))),
                        AnimatedBuilder(
                          animation: _nudge,
                          builder: (_, __) {
                            final k = _nudge.value;
                            return Transform.translate(offset: Offset(k < .6 ? 4 * math.sin(k / .6 * math.pi) : 0, 0),
                                child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF3A0612), size: 20));
                          },
                        ),
                      ]),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }
}

/// Small red count bubble for the Cart icon in your bottom navigation:
///   Stack(clipBehavior: Clip.none, children: [Icon(Icons.shopping_cart), Positioned(right: -8, top: -4, child: CartCountBadge(controller: cartBar))])
class CartCountBadge extends StatelessWidget {
  final CartBarController controller;
  const CartCountBadge({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (_, __) => AnimatedScale(
          scale: controller.count > 0 ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          child: Container(
            constraints: const BoxConstraints(minWidth: 17),
            height: 17,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFFE8486B), borderRadius: BorderRadius.circular(9)),
            child: Text('${controller.count}', style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ),
      );
}

final globalCartBar = CartBarController();
